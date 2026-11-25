extends SceneTree
## Generates each fighter's clothing from their base body mesh and saves it into the
## character data. Run: godot_console --headless --path . -s res://tools/build_outfits.gd
## (append `-- <id> ...` to rebuild only those fighters)
##
## A garment is the part of the body surface inside a region, pushed out along the normals
## by the garment's thickness. Regions are signed-distance functions of the T-pose
## position (positive inside), built from the skeleton's bone landmarks; triangles that
## cross a region's edge are clipped exactly at the zero line, so hems, necklines and
## sleeve ends are clean lines instead of stair-steps. Every vertex keeps (or blends) the
## body's bone weights, so the cloth deforms exactly with the skin under it.
## Layering comes from thickness (a gi jacket sits outside its pants, the belt outside
## both). Trims are split off the same way into their own colour slot: a dobok's black V
## collar, a singlet's gold edging along every opening. Belt knots and tails are small
## boxes bound to the pelvis.
## The body is saved again without the skin triangles a garment fully covers (1.5 cm
## inset), so nothing pokes through and no gap opens at the hems, and with the facial
## expression blend shapes (tools/face_shapes.gd).
## Outfit references: karate gi (cross-over jacket with a V opening, belt, headband),
## Tae Kwon Do dobok (closed V-neck pullover, black collar for black belts), kickboxing
## gear, pro-wrestling singlet with knee pads and boots, brawler tank top and work pants,
## street gear (sleeveless zip-up, track pants with side stripes, fingerless gloves,
## sneakers), Wing Chun uniform (short-sleeved kung fu jacket with a standing collar and a
## contrast placket, loose pants, cloth shoes with white soles).
## Detailed outfits (`detailed = true`) also carry vertex colours: the cloth darkens a
## little toward every hem and opening, and a stitch line runs along each hem (the
## polygons are cut along it, so it stays a crisp line). Their body gets a second UV set
## for the skin pore detail map (FighterModel).

const OUT_DIR := "res://assets/characters/outfits/"
const CHARACTER_DIR := "res://data/characters/"
const KIT_DIR := "res://data/kits/" # the original 3D Fighter cast
const NPC_DIR := "res://data/npcs/" # stage and super-scene people (tools/build_npcs.gd)
const HIDE_INSET := 0.015 # body skin this far inside a garment's edge is removed
const NECK_RADIUS := 0.072 # the neck hole of tops and jackets
const ARM_LIMIT := 0.35 # |x| beyond this (T-pose) is arm, never legs or torso
## Detailed outfits: the stitch line runs between these distances inside a hem, and the
## cloth shades from HEM_SHADE at the edge to full brightness HEM_SHADE_DEPTH inside.
const MIN_TRIANGLE_AREA := 1e-9 # (twice the area, m²) smaller triangles are dropped
const STITCH_NEAR := 0.007
const STITCH_FAR := 0.0095
const STITCH_SHADE := 0.62
const HEM_SHADE := 0.8
const HEM_SHADE_DEPTH := 0.035

const TAIL_JOINTS := 3 # spring bones down each belt or headband tail, so it bends as it swings
const TAIL_ROOT_FADE := 0.12 # share of a tail's length, from the knot, still partly held by the knot's bone
const TAIL_PREFIX := "cloth_tail_"
const HEM_FULL_AT := 0.5 # share of a hem chain's length, from its root, where its bones take over fully

enum Slot { MAIN, TRIM, ACCENT, EXTRA, DETAIL }

var _body_skin: Skin
var _pelvis_bind := 0
var _skeleton: Skeleton3D
var _to_skeleton := Transform3D() # body mesh space -> skeleton rest space
var _tails: Array = [] # this outfit's tail chains (the outfit mesh's "spring_tails" meta)


func _initialize() -> void:
	await process_frame
	var specs := _specs()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var only := OS.get_cmdline_user_args() # e.g. `-- mira`: rebuild just these fighters
	for id: String in specs:
		if not only.is_empty() and id not in only:
			continue
		var spec: Dictionary = specs[id]
		var data_path := CHARACTER_DIR + id + ".tres"
		if not ResourceLoader.exists(data_path):
			data_path = KIT_DIR + id + ".tres"
		if not ResourceLoader.exists(data_path):
			data_path = NPC_DIR + id + ".tres"
		var data := load(data_path) as CharacterData
		if data == null:
			push_error("No character data for %s" % id)
			continue
		var result := _build(data.model_scene, spec, data.face_shape)
		data.detailed_textures = spec.get("detailed", false)
		var outfit_path := OUT_DIR + id + "_outfit.res"
		var body_path := OUT_DIR + id + "_body.res"
		ResourceSaver.save(result.outfit, outfit_path)
		ResourceSaver.save(result.body, body_path)
		data.outfit_mesh = load(outfit_path)
		data.outfit_body_mesh = load(body_path)
		data.outfit_colors = spec.colors
		data.alt_outfit_colors = spec.alt_colors
		data.variant_outfit_colors.assign(spec.get("variants", []))
		data.outfit_fabrics.assign(spec.fabrics)
		ResourceSaver.save(data, data.resource_path)
		print("%-7s outfit: %d surfaces, %d triangles; body %d -> %d triangles" % [id, result.outfit.get_surface_count(),
			result.outfit_triangles, result.body_before, result.body_after])
	quit()


# --- Outfits -------------------------------------------------------------------------

## Per character: pieces, colours, alt colours and fabrics per slot. A piece has a slot,
## a thickness (`offset`), a `region` func(p: Vector3, n: Vector3) -> float (signed
## distance, positive inside; `offset` may also be a func(n: Vector3) -> float) and optionally a `trim` func of the same shape (positive =
## trim slot), `hide = false` (don't remove skin under it) and `flat_soles`. In detailed
## outfits, `stitches = false` leaves the stitch line off thin bands (belts, headbands),
## where cutting along both edges leaves gaps.
func _specs() -> Dictionary:
	var specs := _kit_specs()
	specs.merge(_showdown_specs())
	specs.merge(_npc_specs())
	return specs


## The original 3D Fighter cast (res://data/kits/).
func _kit_specs() -> Dictionary:
	return {
		"kenji": {
			detailed = true,
			pieces = func(L: Dictionary) -> Array:
				var v_bottom: float = L.chest - 0.07
				var belt_lo: float = L.hip + 0.04
				var belt_hi: float = L.hip + 0.085
				var hem: float = L.hip - 0.1
				var sleeve_end: float = L.elbow + (L.wrist - L.elbow) * 0.45
				var jacket := func(p, n): return minf(_top(p, L, hem, sleeve_end), -_v_cut(p, n, L, v_bottom, 0.075))
				var collar := func(p, n): return _gi_collar(p, n, L, v_bottom, 0.075, belt_hi)
				# The belt cinches the jacket and the pants.
				var cinch := func(p: Vector3) -> bool: return p.y > belt_lo - 0.012 and p.y < belt_hi + 0.012 and absf(p.x) < ARM_LIMIT
				# Fine triangles also along the collar, which is about one skin triangle wide.
				var jacket_drape := _top_drape(L, {base = 0.026, sleeve_end = sleeve_end, cuff_flare = 0.028, sag = 0.022,
					skirt_from = belt_lo, skirt_flare = 0.03, blouse_at = belt_hi, fine_below = belt_hi + 0.16, pin = cinch,
					fine = func(p: Vector3) -> bool: return _gi_collar(p, Vector3.BACK, L, v_bottom, 0.075, belt_hi) > -0.035})
				var collar_drape := jacket_drape.duplicate()
				collar_drape.extra = 0.007 # (same folds as the jacket, so it never sinks under them)
				return [
					# Gi jacket: loose, past the hips, wide sleeves to mid-forearm, a deep V
					# at the chest, blousing over the belt and pleating below it.
					{slot = Slot.MAIN, offset = 0.026, drape = jacket_drape,
						hem = {top = belt_lo - 0.012, bottom = hem, chains = 8, joints = 2},
						region = func(p, n): return minf(jacket.call(p, n), -collar.call(p, n))},
					# The collar: a stiff quilted band around the neck and down the left
					# panel's edge, which crosses over to the right hip.
					{slot = Slot.MAIN, offset = 0.026, drape = collar_drape,
						stitch_region = func(p, n): return _gi_collar(p, n, L, v_bottom, 0.075, belt_hi, true),
						stitch_rows = [[0.005, 0.0068], [0.011, 0.0128], [0.017, 0.0188], [0.023, 0.0248], [0.029, 0.0308], [0.035, 0.0368]],
						region = func(p, n): return minf(jacket.call(p, n), collar.call(p, n))},
					# Loose gi pants to just above the ankle, fuller toward the hem.
					{slot = Slot.MAIN, offset = 0.02, region = func(p, n): return _legs(p, L.ankle + 0.07, L.waist - 0.02),
						drape = _pants_drape(L, {base = 0.02, flare = 0.022, hem = L.ankle + 0.07, pin = cinch,
							cover = hem, cover_max = 0.021})},
					# Black belt.
					{slot = Slot.TRIM, offset = 0.036, hide = false, stitches = false, region = func(p, n): return _legs(p, belt_lo, belt_hi)},
					# Red headband: snug on the forehead, standing off over the hair at the sides
					# and back.
					{slot = Slot.ACCENT, offset = func(n: Vector3) -> float: return lerpf(0.02, 0.009, clampf(n.z * 1.6 - 0.4, 0.0, 1.0)),
						hide = false, stitches = false, region = func(p, n):
						return minf(minf(p.y - (L.head_top - 0.078), (L.head_top - 0.05) - p.y), 0.15 - absf(p.x))},
				],
			belt_knot = {slot = Slot.TRIM, y = 0.0625, offset = 0.036, tied = true},
			headband_knot = {slot = Slot.ACCENT, y = 0.064, offset = 0.02},
			colors = [Color(0.8, 0.79, 0.76), Color(0.07, 0.07, 0.08), Color(0.78, 0.07, 0.07)],
			alt_colors = [Color(0.15, 0.16, 0.2), Color(0.42, 0.24, 0.1), Color(0.8, 0.8, 0.78)],
			fabrics = [&"cotton", &"cotton", &"cotton"],
		},
		"jin": {
			detailed = true,
			pieces = func(L: Dictionary) -> Array:
				var v_bottom: float = L.chest
				var belt_lo: float = L.hip + 0.04
				var belt_hi: float = L.hip + 0.085
				var hem: float = L.hip - 0.05
				var cinch := func(p: Vector3) -> bool: return p.y > belt_lo - 0.012 and p.y < belt_hi + 0.012 and absf(p.x) < ARM_LIMIT
				return [
					# Dobok: a loose V-neck pullover to the hips, long sleeves a little wider at
					# the cuff, black V collar, bloused over the belt.
					{slot = Slot.MAIN, offset = 0.022, trim_slot = Slot.TRIM,
						trim = func(p, n): return _v_cut(p, n, L, v_bottom - 0.035, 0.08) + 0.03,
						region = func(p, n): return minf(_top(p, L, hem, L.wrist - 0.05), -_v_cut(p, n, L, v_bottom, 0.08)),
						drape = _top_drape(L, {base = 0.022, sleeve_end = L.wrist - 0.05, cuff_flare = 0.014, sag = 0.016,
							skirt_from = belt_lo, skirt_flare = 0.02, blouse_at = belt_hi, amount = 0.9,
							fine_below = belt_hi + 0.16, pin = cinch,
							fine = func(p: Vector3) -> bool: return _v_cut(p, Vector3.BACK, L, v_bottom - 0.035, 0.08) > -0.06}),
						hem = {top = belt_lo - 0.012, bottom = hem, chains = 8, joints = 1}},
					# Loose pants, fuller toward the ankle.
					{slot = Slot.MAIN, offset = 0.016, region = func(p, n): return _legs(p, L.ankle + 0.05, L.waist - 0.02),
						drape = _pants_drape(L, {base = 0.016, flare = 0.02, hem = L.ankle + 0.05, pin = cinch,
							cover = hem, cover_max = 0.018})},
					{slot = Slot.TRIM, offset = 0.032, hide = false, stitches = false, region = func(p, n): return _legs(p, belt_lo, belt_hi)},
				],
			belt_knot = {slot = Slot.TRIM, y = 0.0625, offset = 0.032, tied = true},
			colors = [Color(0.8, 0.8, 0.8), Color(0.06, 0.06, 0.07), Color(0.0, 0.0, 0.0)],
			alt_colors = [Color(0.1, 0.1, 0.11), Color(0.72, 0.1, 0.1), Color(0.0, 0.0, 0.0)],
			fabrics = [&"cotton", &"cotton", &"cotton"],
		},
		"rhea": {
			detailed = true,
			pieces = func(L: Dictionary) -> Array:
				return [
					# Sports crop top: under the bust to the shoulders, scooped neck, sleeveless.
					{slot = Slot.MAIN, offset = 0.005, region = func(p, n):
						return minf(_sleeveless(p, L, L.chest - 0.11, L.shoulder * 0.95), -_scoop(p, L, 0.10, 0.07))},
					# Fight shorts to mid-thigh, covering the waistband: loose Muay Thai legs,
					# wider at the hem, the waistband snug.
					{slot = Slot.TRIM, offset = 0.006, region = func(p, n): return _legs(p, L.knee + 0.2, L.waist + 0.03),
						drape = _pants_drape(L, {base = 0.006, flare = 0.024, hem = L.knee + 0.2, flare_top = L.hip,
							flare_span = L.hip - (L.knee + 0.2), amount = 0.6, leg_fall = 6, max = 0.06,
							pin = func(p: Vector3) -> bool: return p.y > L.waist - 0.01}),
						hem = {legs = true, top = L.hip - 0.08, bottom = L.knee + 0.2, chains = 6, joints = 2}},
					# Hand wraps over the wrists and palms.
					{slot = Slot.ACCENT, offset = 0.004, region = func(p, n):
						return minf(minf(p.y - (L.arm_y - 0.12), absf(p.x) - (L.wrist - 0.08)), (L.wrist + 0.07) - absf(p.x))},
				],
			colors = [Color(0.8, 0.12, 0.16), Color(0.08, 0.08, 0.1), Color(0.8, 0.79, 0.75)],
			alt_colors = [Color(0.12, 0.32, 0.78), Color(0.8, 0.8, 0.82), Color(0.15, 0.15, 0.18)],
			fabrics = [&"stretch", &"stretch", &"cotton"],
		},
		"valka": {
			detailed = true,
			pieces = func(L: Dictionary) -> Array:
				var singlet := func(p, n):
					return minf(_sleeveless(p, L, L.knee + 0.24, L.shoulder * 0.95), -_scoop(p, L, 0.11, 0.06))
				return [
					# Wrestling singlet: short legs, scooped neck front and back, gold edging
					# along every opening.
					{slot = Slot.MAIN, offset = 0.006, trim_slot = Slot.TRIM, region = singlet,
						trim = func(p, n): return 0.014 - singlet.call(p, n)},
					# Knee pads and wrestling boots.
					{slot = Slot.ACCENT, offset = 0.028, region = func(p, n): return _legs(p, L.knee - 0.065, L.knee + 0.065)},
					{slot = Slot.ACCENT, offset = 0.012, flat_soles = true, region = func(p, n): return _legs(p, -1.0, L.ankle + 0.22)},
				],
			colors = [Color(0.08, 0.1, 0.3), Color(0.88, 0.67, 0.2), Color(0.06, 0.06, 0.07)],
			alt_colors = [Color(0.55, 0.05, 0.08), Color(0.78, 0.78, 0.82), Color(0.06, 0.06, 0.07)],
			fabrics = [&"stretch", &"stretch", &"leather"],
		},
		"brutus": {
			detailed = true,
			pieces = func(L: Dictionary) -> Array:
				return [
					# Tank top, tucked into the pants (held at the skin there) and bloused
					# a little above the waistband.
					{slot = Slot.MAIN, offset = 0.009, region = func(p, n):
						return minf(_sleeveless(p, L, L.waist - 0.1, L.shoulder * 0.85), -_scoop(p, L, 0.09, 0.07)),
						drape = _top_drape(L, {base = 0.009, blouse_at = L.waist + 0.01, amount = 0.7, chest_fall = 10,
							fine_below = L.waist + 0.14, pin = func(p: Vector3) -> bool: return p.y < L.waist + 0.01})},
					# Loose work pants over the boot tops, snug at the waistband.
					{slot = Slot.TRIM, offset = 0.016, region = func(p, n): return _legs(p, L.ankle + 0.17, L.waist),
						drape = _pants_drape(L, {base = 0.016, flare = 0.014, hem = L.ankle + 0.17, amount = 0.85,
							pin = func(p: Vector3) -> bool: return p.y > L.waist - 0.035})},
					{slot = Slot.ACCENT, offset = 0.014, flat_soles = true, region = func(p, n): return _legs(p, -1.0, L.ankle + 0.21)},
				],
			colors = [Color(0.34, 0.37, 0.2), Color(0.15, 0.18, 0.26), Color(0.08, 0.06, 0.05)],
			alt_colors = [Color(0.52, 0.52, 0.54), Color(0.22, 0.32, 0.52), Color(0.27, 0.16, 0.08)],
			fabrics = [&"cotton", &"denim", &"leather"],
		},
		"mira": {
			detailed = true,
			pieces = func(L: Dictionary) -> Array:
				var hem: float = L.waist - 0.07
				return [
					# Sleeveless zip-up to the waist, closed at the neck, with a contrast zip
					# down the front and a contrast band at the hem.
					{slot = Slot.MAIN, offset = 0.014, trim_slot = Slot.TRIM,
						region = func(p, n): return _sleeveless(p, L, hem, L.shoulder * 0.9),
						trim = func(p, n): return maxf(_zip(p, n, 0.007), (hem + 0.022) - p.y),
						drape = _top_drape(L, {base = 0.014, amount = 0.6, chest_fall = 8, fine_below = hem + 0.1})},
					# Track pants with contrast stripes down the outside of each leg, gathered
					# by elastic at the waist and the ankles.
					{slot = Slot.ACCENT, offset = 0.010, trim_slot = Slot.TRIM,
						region = func(p, n): return _legs(p, L.ankle + 0.06, L.waist + 0.005),
						trim = func(p, n): return signf(p.x) * n.x - 0.93,
						drape = _pants_drape(L, {base = 0.010, flare = 0.014, hem = L.ankle + 0.06, amount = 0.8,
							cover = hem, cover_max = 0.012,
							pin = func(p: Vector3) -> bool: return p.y > L.waist - 0.03 or p.y < L.ankle + 0.085})},
					# Fingerless gloves: wrist to knuckles.
					{slot = Slot.ACCENT, offset = 0.004, region = func(p, n):
						return minf(minf(p.y - (L.arm_y - 0.12), absf(p.x) - (L.wrist - 0.06)), (L.wrist + 0.085) - absf(p.x))},
					# Leather sneakers over the ankle with a contrast sole, soles flat on the floor.
					{slot = Slot.EXTRA, offset = 0.018, flat_soles = true, trim_slot = Slot.TRIM,
						region = func(p, n): return _legs(p, -1.0, L.ankle + 0.07),
						trim = func(p, n): return 0.03 - p.y},
				],
			colors = [Color(0.13, 0.13, 0.14), Color(0.86, 0.62, 0.12), Color(0.05, 0.05, 0.06), Color(0.82, 0.81, 0.78)],
			alt_colors = [Color(0.8, 0.8, 0.78), Color(0.75, 0.08, 0.08), Color(0.11, 0.11, 0.12), Color(0.72, 0.08, 0.08)],
			fabrics = [&"cotton", &"stretch", &"stretch", &"leather"],
		},
		"lian": {
			detailed = true,
			pieces = func(L: Dictionary) -> Array:
				var hem: float = L.hip - 0.05
				var sleeve: float = L.shoulder + (L.elbow - L.shoulder) * 0.55
				return [
					# Kung fu jacket: to the hips, short sleeves, the collar standing at the neck;
					# contrast trim on the collar, the front placket, the hem and the cuffs.
					{slot = Slot.MAIN, offset = 0.02, trim_slot = Slot.TRIM,
						region = func(p, n): return _top(p, L, hem, sleeve),
						trim = func(p, n): return maxf(maxf(_placket(p, 0.009), p.y - (L.neck - 0.012)),
							maxf((hem + 0.02) - p.y, absf(p.x) - (sleeve - 0.02))),
						# The standing collar stays at the neck (draped, it bridged out to the
						# shoulders).
						drape = _top_drape(L, {base = 0.02, sleeve_end = sleeve, cuff_flare = 0.02, sag = 0.012,
							amount = 0.7, fine_below = hem + 0.12, pin = func(p: Vector3) -> bool: return p.y > L.neck - 0.03,
							fine = func(p: Vector3) -> bool: return _placket(p, 0.04) > 0.0})},
					# Loose pants to the ankle, gathered there and at the waist.
					{slot = Slot.ACCENT, offset = 0.017, region = func(p, n): return _legs(p, L.ankle + 0.04, L.waist - 0.02),
						drape = _pants_drape(L, {base = 0.017, flare = 0.03, hem = L.ankle + 0.04, cover = hem, cover_max = 0.017,
							pin = func(p: Vector3) -> bool: return p.y > L.waist - 0.04 or p.y < L.ankle + 0.06})},
					# Cloth shoes with white soles, flat on the floor.
					{slot = Slot.EXTRA, offset = 0.01, flat_soles = true, trim_slot = Slot.TRIM,
						region = func(p, n): return _legs(p, -1.0, L.ankle + 0.03),
						trim = func(p, n): return 0.022 - p.y},
				],
			colors = [Color(0.1, 0.36, 0.29), Color(0.84, 0.75, 0.52), Color(0.06, 0.06, 0.07), Color(0.07, 0.07, 0.08)],
			alt_colors = [Color(0.8, 0.79, 0.75), Color(0.08, 0.08, 0.09), Color(0.5, 0.06, 0.06), Color(0.08, 0.08, 0.09)],
			fabrics = [&"cotton", &"cotton", &"cotton", &"cotton"],
		},
	}


# --- AI Showdown outfits (all on the male base body) ----------------------------------

## The AI Showdown roster's clothes: suits, sweaters, a leather jacket, a hoodie, a
## cardigan and AGI's glowing bodysuit. Plain, generic garments: no logos.
func _showdown_specs() -> Dictionary:
	var navy := Color(0.07, 0.09, 0.2)
	var white_shirt := Color(0.82, 0.82, 0.8)
	var black_leather := Color(0.035, 0.035, 0.04)
	return {
		"ram": _tee_spec(Color(0.12, 0.12, 0.13), Color(0.14, 0.18, 0.28), Color(0.08, 0.08, 0.09),
			Color(0.85, 0.85, 0.88), Color(0.10, 0.10, 0.12), Color(0.12, 0.12, 0.14)),
		"tesla": _tee_spec(Color(0.05, 0.05, 0.06), Color(0.11, 0.13, 0.2), Color(0.06, 0.06, 0.06),
			Color(0.75, 0.75, 0.75), Color(0.25, 0.27, 0.32), Color(0.8, 0.8, 0.78)),
		"dario": _tee_spec(Color(0.82, 0.33, 0.14), Color(0.14, 0.16, 0.22), Color(0.86, 0.86, 0.82),
			Color(0.90, 0.88, 0.82), Color(0.10, 0.10, 0.12), Color(0.12, 0.12, 0.12)),
		"zuckerbot": _hoodie_spec(Color(0.42, 0.43, 0.45), Color(0.15, 0.2, 0.32), Color(0.16, 0.19, 0.26),
			Color(0.1, 0.18, 0.42), Color(0.08, 0.08, 0.1), Color(0.75, 0.75, 0.75)),
		"jensen": _leather_jacket_spec(black_leather, Color(0.2, 0.2, 0.21), Color(0.08, 0.08, 0.09),
			Color(0.3, 0.18, 0.1), Color(0.12, 0.12, 0.13), Color(0.2, 0.2, 0.22)),
		"yann": _blazer_spec(Color(0.16, 0.16, 0.18), Color(0.68, 0.74, 0.85), Color(0.11, 0.14, 0.22),
			Color(0.24, 0.15, 0.10), Color(0.30, 0.32, 0.35), Color(0.10, 0.10, 0.12)),
		"geoff": _cardigan_spec(Color(0.16, 0.34, 0.22), Color(0.10, 0.22, 0.14), Color(0.22, 0.23, 0.26), Color(0.80, 0.86, 0.92),
			Color(0.40, 0.13, 0.16), Color(0.13, 0.13, 0.15), Color(0.22, 0.13, 0.07), Color(0.06, 0.06, 0.07)),
		"sundar": _tee_spec(Color(0.12, 0.12, 0.13), Color(0.18, 0.22, 0.28), Color(0.08, 0.08, 0.08),
			Color(0.9, 0.9, 0.92), Color(0.12, 0.12, 0.14), Color(0.12, 0.12, 0.12)),
		"donald": _suit_spec(navy, white_shirt, Color(0.75, 0.06, 0.08), Color(0.05, 0.05, 0.05),
			Color(0.12, 0.12, 0.13), Color(0.12, 0.2, 0.55), true),
		"xi": _zhongshan_spec(Color(0.12, 0.13, 0.16), Color(0.05, 0.05, 0.05),
			Color(0.18, 0.22, 0.19), Color(0.06, 0.06, 0.06)),
		"algorithm": _bodysuit_spec(Color(0.04, 0.045, 0.06), Color(0.15, 0.95, 1.0), Color(1.0, 0.25, 0.85), [
			[Color(0.03, 0.075, 0.045), Color(0.45, 1.0, 0.3)],
			[Color(0.12, 0.02, 0.03), Color(1.0, 0.15, 0.05)],
		]),
	}


# --- Stage and super-scene NPCs (all on the male base body) ---------------------------

## Xi's helpers (O5): plain tee, jeans and sneakers; the chest print reading Qwen,
## Alibaba or Kimi comes from tools/build_prints.py. The tee colour here is the fallback
## for the alternate outfit (the print covers the main one).
func _npc_specs() -> Dictionary:
	return {
		"helper_qwen": _tee_spec(Color(0.13, 0.11, 0.3), Color(0.13, 0.16, 0.24), Color(0.86, 0.86, 0.82),
			Color(0.85, 0.85, 0.9), Color(0.1, 0.1, 0.12), Color(0.12, 0.12, 0.14)),
		"helper_alibaba": _tee_spec(Color(0.86, 0.35, 0.07), Color(0.16, 0.17, 0.2), Color(0.1, 0.1, 0.1),
			Color(0.2, 0.2, 0.22), Color(0.12, 0.12, 0.14), Color(0.9, 0.9, 0.88)),
		"helper_kimi": _tee_spec(Color(0.07, 0.08, 0.1), Color(0.17, 0.2, 0.25), Color(0.9, 0.9, 0.9),
			Color(0.75, 0.78, 0.82), Color(0.1, 0.1, 0.12), Color(0.12, 0.12, 0.14)),

		# --- O3: Senate (suits, offices, press) ---
		"chair": _suit_spec(Color(0.08, 0.1, 0.2), Color(0.93, 0.92, 0.88), Color(0.65, 0.06, 0.07),
			Color(0.05, 0.05, 0.05), Color(0.14, 0.14, 0.16), Color(0.2, 0.3, 0.6), true),
		"senator_1": _suit_spec(Color(0.13, 0.14, 0.16), Color(0.93, 0.91, 0.85), Color(0.6, 0.45, 0.12),
			Color(0.05, 0.05, 0.05), Color(0.25, 0.18, 0.12), Color(0.45, 0.1, 0.1)),
		"senator_2": _suit_spec(Color(0.18, 0.24, 0.36), Color(0.94, 0.94, 0.92), null,
			Color(0.06, 0.05, 0.05), Color(0.32, 0.1, 0.14), null),
		"senator_3": _suit_spec(Color(0.25, 0.16, 0.1), Color(0.92, 0.9, 0.82), Color(0.1, 0.25, 0.14),
			Color(0.08, 0.06, 0.04), Color(0.32, 0.32, 0.34), Color(0.5, 0.35, 0.1)),
		"senator_4": _suit_spec(Color(0.3, 0.08, 0.12), Color(0.94, 0.93, 0.9), null,
			Color(0.06, 0.05, 0.05), Color(0.1, 0.14, 0.28), null),
		"stenographer": _blazer_spec(Color(0.36, 0.37, 0.4), Color(0.94, 0.94, 0.92),
			Color(0.1, 0.11, 0.14), Color(0.05, 0.05, 0.05), Color(0.2, 0.22, 0.26), Color(0.16, 0.12, 0.1)),
		"press_1": _blazer_spec(Color(0.3, 0.22, 0.14), Color(0.3, 0.34, 0.2),
			Color(0.1, 0.11, 0.14), Color(0.08, 0.06, 0.04), Color(0.18, 0.18, 0.2), Color(0.2, 0.2, 0.22)),
		"press_2": _leather_jacket_spec(Color(0.08, 0.08, 0.09), Color(0.92, 0.92, 0.9),
			Color(0.1, 0.1, 0.12), Color(0.25, 0.06, 0.07), Color(0.6, 0.6, 0.6), Color(0.06, 0.06, 0.07)),
		"press_3": _cardigan_spec(Color(0.35, 0.35, 0.38), Color(0.2, 0.2, 0.22),
			Color(0.18, 0.18, 0.2), Color(0.85, 0.85, 0.8), Color(0.28, 0.3, 0.2), Color(0.24, 0.22, 0.2)),
		"aide_1": _cardigan_spec(Color(0.4, 0.42, 0.46), Color(0.22, 0.24, 0.28),
			Color(0.14, 0.16, 0.22), Color(0.93, 0.93, 0.9), Color(0.34, 0.12, 0.15), Color(0.18, 0.18, 0.2)),
		"aide_2": _blazer_spec(Color(0.12, 0.16, 0.28), Color(0.94, 0.94, 0.92),
			Color(0.12, 0.12, 0.15), Color(0.05, 0.05, 0.05), Color(0.36, 0.36, 0.38), Color(0.18, 0.16, 0.14)),
		"aide_3": _suit_spec(Color(0.38, 0.39, 0.42), Color(0.94, 0.94, 0.92), null,
			Color(0.06, 0.05, 0.05), Color(0.1, 0.14, 0.26), null),
		"citizen_1": _sweater_spec(Color(0.28, 0.32, 0.16), Color(0.18, 0.16, 0.14),
			Color(0.24, 0.16, 0.09), &"cotton", Color(0.5, 0.26, 0.1), Color(0.22, 0.2, 0.18),
			Color(0.12, 0.12, 0.12)),
		"citizen_2": _cardigan_spec(Color(0.33, 0.12, 0.16), Color(0.2, 0.08, 0.1),
			Color(0.2, 0.18, 0.16), Color(0.9, 0.88, 0.8), Color(0.16, 0.26, 0.18), Color(0.24, 0.22, 0.2)),
		"citizen_3": _tee_spec(Color(0.1, 0.32, 0.32), Color(0.16, 0.18, 0.22), Color(0.86, 0.86, 0.84),
			Color(0.75, 0.35, 0.1), Color(0.1, 0.1, 0.12), Color(0.1, 0.1, 0.1)),

		# --- O3: mensa (kitchen, students) ---
		"cook": _zhongshan_spec(Color(0.9, 0.9, 0.88), Color(0.06, 0.06, 0.06),
			Color(0.82, 0.82, 0.8), Color(0.4, 0.4, 0.42)),
		"cashier": _cardigan_spec(Color(0.16, 0.3, 0.2), Color(0.1, 0.2, 0.14),
			Color(0.2, 0.2, 0.22), Color(0.92, 0.9, 0.84), Color(0.55, 0.4, 0.12), Color(0.16, 0.16, 0.18)),
		"student_1": _hoodie_spec(Color(0.16, 0.3, 0.18), Color(0.12, 0.14, 0.18), Color(0.9, 0.9, 0.88),
			Color(0.32, 0.2, 0.45), Color(0.1, 0.1, 0.12), Color(0.2, 0.2, 0.2)),
		"student_2": _tee_spec(Color(0.88, 0.85, 0.75), Color(0.2, 0.24, 0.3), Color(0.92, 0.92, 0.9),
			Color(0.1, 0.1, 0.12), Color(0.14, 0.14, 0.16), Color(0.12, 0.12, 0.12)),
		"student_3": _sweater_spec(Color(0.32, 0.33, 0.36), Color(0.16, 0.16, 0.18),
			Color(0.1, 0.1, 0.1), &"cotton", Color(0.14, 0.2, 0.34), Color(0.22, 0.2, 0.18),
			Color(0.2, 0.15, 0.1), true),
		"student_4": _tee_spec(Color(0.6, 0.1, 0.1), Color(0.12, 0.13, 0.16), Color(0.12, 0.12, 0.12),
			Color(0.7, 0.55, 0.12), Color(0.2, 0.2, 0.22), Color(0.9, 0.9, 0.88)),
		"student_5": _hoodie_spec(Color(0.45, 0.4, 0.58), Color(0.1, 0.1, 0.12), Color(0.92, 0.92, 0.9),
			Color(0.7, 0.35, 0.5), Color(0.16, 0.16, 0.18), Color(0.2, 0.2, 0.2)),
		"student_6": _leather_jacket_spec(Color(0.08, 0.08, 0.09), Color(0.88, 0.86, 0.8),
			Color(0.1, 0.1, 0.12), Color(0.3, 0.18, 0.1), Color(0.1, 0.1, 0.1), Color(0.24, 0.24, 0.26)),
		"student_7": _hoodie_spec(Color(0.4, 0.42, 0.45), Color(0.16, 0.18, 0.2), Color(0.9, 0.9, 0.88),
			Color(0.14, 0.26, 0.18), Color(0.1, 0.1, 0.12), Color(0.12, 0.12, 0.12)),
		"student_8": _sweater_spec(Color(0.82, 0.78, 0.68), Color(0.28, 0.22, 0.16),
			Color(0.9, 0.9, 0.88), &"cotton", Color(0.3, 0.4, 0.55), Color(0.18, 0.18, 0.2),
			Color(0.12, 0.12, 0.12)),
		"student_9": _tee_spec(Color(0.12, 0.16, 0.3), Color(0.2, 0.2, 0.22), Color(0.9, 0.9, 0.88),
			Color(0.45, 0.65, 0.15), Color(0.12, 0.12, 0.14), Color(0.12, 0.12, 0.12)),
		"student_10": _cardigan_spec(Color(0.2, 0.32, 0.22), Color(0.12, 0.2, 0.14),
			Color(0.22, 0.2, 0.18), Color(0.92, 0.9, 0.84), Color(0.55, 0.24, 0.1), Color(0.18, 0.18, 0.2)),
		"grad_student": _blazer_spec(Color(0.34, 0.28, 0.2), Color(0.55, 0.65, 0.8),
			Color(0.14, 0.14, 0.16), Color(0.24, 0.16, 0.09), Color(0.2, 0.2, 0.22), Color(0.1, 0.1, 0.12)),

		# --- O3: foundry (cleanroom) ---
		"technician_1": _coverall_spec(Color(0.88, 0.89, 0.9), Color(0.5, 0.7, 0.85),
			Color(0.8, 0.82, 0.86), Color(0.35, 0.5, 0.8)),
		"technician_2": _coverall_spec(Color(0.88, 0.89, 0.9), Color(0.35, 0.5, 0.8),
			Color(0.82, 0.84, 0.88), Color(0.5, 0.7, 0.85)),
		"technician_3": _coverall_spec(Color(0.9, 0.89, 0.9), Color(0.65, 0.55, 0.8),
			Color(0.82, 0.84, 0.88), Color(0.4, 0.45, 0.55)),
		"technician_4": _coverall_spec(Color(0.88, 0.9, 0.88), Color(0.45, 0.7, 0.5),
			Color(0.8, 0.82, 0.86), Color(0.35, 0.5, 0.8)),
		"lead_architect": _zhongshan_spec(Color(0.14, 0.15, 0.17), Color(0.06, 0.06, 0.06),
			Color(0.16, 0.2, 0.18), Color(0.1, 0.1, 0.1)),
		"quality_inspector": _blazer_spec(Color(0.14, 0.18, 0.3), Color(0.94, 0.94, 0.92),
			Color(0.12, 0.13, 0.16), Color(0.05, 0.05, 0.05), Color(0.3, 0.1, 0.12), Color(0.18, 0.16, 0.14)),
		"cleanroom_guard": _suit_spec(Color(0.05, 0.05, 0.06), Color(0.9, 0.9, 0.88), Color(0.08, 0.08, 0.1),
			Color(0.04, 0.04, 0.04), Color(0.1, 0.12, 0.2), Color(0.3, 0.3, 0.34)),
		"cleanroom_aide": _coverall_spec(Color(0.87, 0.89, 0.9), Color(0.55, 0.62, 0.72),
			Color(0.8, 0.82, 0.86), Color(0.45, 0.5, 0.6)),

		# --- O3: server farm (operators, sysadmins) ---
		"sysadmin_1": _hoodie_spec(Color(0.2, 0.2, 0.22), Color(0.14, 0.14, 0.16), Color(0.1, 0.1, 0.1),
			Color(0.16, 0.24, 0.18), Color(0.1, 0.1, 0.12), Color(0.2, 0.2, 0.2)),
		"sysadmin_2": _hoodie_spec(Color(0.12, 0.16, 0.28), Color(0.1, 0.1, 0.12), Color(0.92, 0.92, 0.9),
			Color(0.35, 0.22, 0.45), Color(0.16, 0.16, 0.18), Color(0.2, 0.2, 0.2)),
		"noc_lead": _cardigan_spec(Color(0.32, 0.12, 0.14), Color(0.2, 0.08, 0.1),
			Color(0.2, 0.2, 0.22), Color(0.88, 0.88, 0.86), Color(0.12, 0.3, 0.3), Color(0.18, 0.18, 0.2)),
		"cloud_architect": _blazer_spec(Color(0.1, 0.16, 0.3), Color(0.94, 0.94, 0.92),
			Color(0.14, 0.14, 0.16), Color(0.24, 0.16, 0.09), Color(0.34, 0.34, 0.36), Color(0.1, 0.1, 0.12)),
		"devops_tech": _tee_spec(Color(0.08, 0.08, 0.09), Color(0.2, 0.22, 0.25), Color(0.08, 0.08, 0.08),
			Color(0.9, 0.9, 0.88), Color(0.12, 0.12, 0.14), Color(0.9, 0.9, 0.88)),
		"site_reliability": _sweater_spec(Color(0.3, 0.3, 0.32), Color(0.5, 0.38, 0.25),
			Color(0.16, 0.1, 0.06), &"cotton", Color(0.14, 0.2, 0.34), Color(0.24, 0.22, 0.2),
			Color(0.1, 0.1, 0.1), true),
		"intern": _hoodie_spec(Color(0.75, 0.35, 0.08), Color(0.18, 0.2, 0.24), Color(0.92, 0.92, 0.9),
			Color(0.8, 0.7, 0.12), Color(0.1, 0.1, 0.12), Color(0.2, 0.2, 0.2)),
		"field_engineer": _leather_jacket_spec(Color(0.3, 0.18, 0.1), Color(0.35, 0.36, 0.38),
			Color(0.18, 0.2, 0.22), Color(0.08, 0.08, 0.09), Color(0.88, 0.86, 0.8), Color(0.1, 0.1, 0.12)),
	}


## Two-piece suit: a jacket with a V front and lapels over a shirt (and a tie unless `tie`
## is null), two buttons, trousers in the suit's colour and leather shoes. `long_tie`
## hangs below the belt. Slots: suit, shoes, tie, shirt, buttons.
func _suit_spec(suit: Color, shirt: Color, tie: Variant, shoes: Color, alt_suit: Color, alt_tie: Variant,
		long_tie := false) -> Dictionary:
	var pieces := func(L: Dictionary) -> Array:
		var v_bottom: float = (L.chest + L.waist) * 0.5 - 0.03
		var hem: float = L.hip - 0.11
		var v_top: float = L.neck + 0.030
		var jacket := func(p, n): return minf(_top(p, L, hem, L.wrist - 0.045), -_v_cut(p, n, L, v_bottom, 0.060, v_top))
		var list := [
			# Jacket to below the hips, long sleeves, closed over the throat and open in a
			# V over the shirt lower on the chest; the front edge below the V is a placket line.
			{slot = Slot.MAIN, offset = 0.022, region = jacket},
			# Lapels: a raised band along both edges of the V, rolling over at the chest.
			# Narrow enough that the two sides leave a gap for the shirt and tie at the top.
			{slot = Slot.MAIN, offset = 0.028, hide = false, stitches = false, region = func(p, n):
				return minf(jacket.call(p, n), _v_cut(p, n, L, v_bottom, 0.060, v_top) + 0.016)},
			# Two buttons below the V.
			{slot = Slot.DETAIL, offset = 0.026, hide = false, stitches = false, region = func(p, n):
				if p.z <= 0.0 or n.z < 0.5:
					return -1.0
				var b1 := 0.009 - Vector2(p.x, p.y - (v_bottom - 0.035)).length()
				var b2 := 0.009 - Vector2(p.x, p.y - (v_bottom - 0.105)).length()
				return maxf(b1, b2)},
			# Shirt (shows in the V and at the cuffs). The front of the collar is closed:
			# the shirt wraps the neck up to the jacket collar line, so the throat never
			# shows a dark gap between the neck and the jacket's neck hole.
			{slot = Slot.EXTRA, offset = 0.010, region = func(p, n):
				var band := minf(minf(p.y - (L.waist - 0.06), (L.neck + 0.030) - p.y), (L.wrist - 0.03) - absf(p.x))
				if p.z > L.neck_z - 0.005:
					return band
				return minf(band, -_neck_hole(p, L))},
			# Tie knot: a wider block at the top of the tie, filling the collar gap.
			{slot = Slot.ACCENT, offset = 0.017, hide = false, stitches = false, region = func(p, n):
				if p.z <= 0.0:
					return -1.0
				var kx := 0.030 - absf(p.x)
				var ky := minf(p.y - (L.neck - 0.050), (L.neck + 0.018) - p.y)
				return minf(kx, ky)},
			# Trousers to the shoes, a little loose.
			{slot = Slot.MAIN, offset = 0.013, region = func(p, n): return _legs(p, L.ankle + 0.03, hem + 0.03),
				drape = _pants_drape(L, {base = 0.013, flare = 0.01, hem = L.ankle + 0.03, amount = 0.6, cover = hem, cover_max = 0.016,
					pin = func(p: Vector3) -> bool: return p.y > hem})},
		]
		if tie != null:
			var bottom: float = (L.hip - 0.06) if long_tie else (L.waist + 0.02)
			list.append({slot = Slot.ACCENT, offset = 0.014, hide = false, stitches = false, region = func(p, n):
				if p.z <= 0.02 or n.z < 0.3:
					return -1.0
				var width: float = lerpf(0.028, 0.046, clampf((L.neck - 0.03 - p.y) / 0.22, 0.0, 1.0))
				return minf(minf(width - absf(p.x), (L.neck - 0.042) - p.y), p.y - bottom)})
		return list
	return {
		detailed = true,
		pieces = pieces,
		shoes = {style = &"dress", upper = Slot.TRIM, sole = Slot.TRIM, sock = Slot.MAIN},
		colors = [suit, shoes, tie if tie != null else shirt, shirt, suit.darkened(0.5)],
		alt_colors = [alt_suit, Color(0.2, 0.12, 0.06), alt_tie if alt_tie != null else shirt,
			Color(0.85, 0.85, 0.83), alt_suit.darkened(0.5)],
		fabrics = [&"cotton", &"leather", &"stretch", &"cotton", &"leather"],
	}


## Academic blazer over an open-collared shirt with dark denim jeans and leather shoes.
## Slots: blazer (MAIN), shoes (TRIM), jeans (ACCENT), shirt (EXTRA), button (DETAIL).
func _blazer_spec(blazer: Color, shirt: Color, jeans: Color, shoes: Color,
		alt_blazer: Color, alt_jeans: Color) -> Dictionary:
	var pieces := func(L: Dictionary) -> Array:
		var v_bottom: float = (L.chest + L.waist) * 0.5 - 0.02
		var hem: float = L.hip - 0.10
		var jacket := func(p, n): return minf(_top(p, L, hem, L.wrist - 0.045), -_v_cut(p, n, L, v_bottom, 0.10))
		var shirt_region := func(p: Vector3, n: Vector3) -> float:
			var band := minf(minf(p.y - (L.waist - 0.06), (L.neck + 0.022) - p.y), (L.wrist - 0.03) - absf(p.x))
			var throat_v := _v_cut(p, n, L, L.neck - 0.04, 0.042)
			return minf(band, -throat_v)
		return [
			# Blazer to below the hips, long sleeves, open in a broad V
			{slot = Slot.MAIN, offset = 0.022, region = jacket},
			# Lapels: a raised band along both edges of the V
			{slot = Slot.MAIN, offset = 0.028, hide = false, stitches = false, region = func(p, n):
				return minf(jacket.call(p, n), _v_cut(p, n, L, v_bottom, 0.10) + 0.032)},
			# Horn button below the V
			{slot = Slot.DETAIL, offset = 0.026, hide = false, stitches = false, region = func(p, n):
				if p.z <= 0.0 or n.z < 0.5:
					return -1.0
				var b1 := 0.009 - Vector2(p.x, p.y - (v_bottom - 0.04)).length()
				return b1},
			# Open-collar dress shirt
			{slot = Slot.EXTRA, offset = 0.008, region = shirt_region},
			# Dark denim jeans
			{slot = Slot.ACCENT, offset = 0.013, region = func(p, n): return _legs(p, L.ankle + 0.03, hem + 0.03),
				drape = _pants_drape(L, {base = 0.013, flare = 0.01, hem = L.ankle + 0.03, amount = 0.6, cover = hem, cover_max = 0.016,
					pin = func(p: Vector3) -> bool: return p.y > hem})},
		]
	return {
		detailed = true,
		pieces = pieces,
		shoes = {style = &"dress", upper = Slot.TRIM, sole = Slot.TRIM, sock = Slot.MAIN},
		colors = [blazer, shoes, jeans, shirt, Color(0.12, 0.11, 0.10)],
		alt_colors = [alt_blazer, Color(0.12, 0.1, 0.08), alt_jeans, Color(0.85, 0.85, 0.88), Color(0.2, 0.2, 0.2)],
		fabrics = [&"cotton", &"leather", &"denim", &"cotton", &"leather"],
	}


## Zhongshan (Mao) suit: closed-front tunic jacket with standing mandarin collar,
## Zhongshan (Mao) suit: high-collar closed tunic jacket with standing mandarin collar,
## white inner collar liner, gold buttons, red delegate badge, symmetrical chest and hip flap pockets,
## tailored trousers and leather dress shoes.
## Slots: suit (tunic & pants), shoes, red badge, white collar liner, gold buttons.
func _zhongshan_spec(suit: Color, shoes: Color, alt_suit: Color, alt_shoes: Color) -> Dictionary:
	var pieces := func(L: Dictionary) -> Array:
		var hem: float = L.hip - 0.09
		var collar_top: float = L.neck + 0.048
		var sleeve: float = L.wrist - 0.045
		# Tunic jacket: closed front, covers torso, shoulders, arms and neck up to collar_top
		var tunic := func(p: Vector3, n: Vector3) -> float:
			return minf(minf(p.y - hem, collar_top - p.y), sleeve - absf(p.x))
		# Standing mandarin collar wrapped firmly around the neck column
		var collar := func(p: Vector3, n: Vector3) -> float:
			if p.y < L.neck + 0.015 or p.y > collar_top:
				return -1.0
			var d := Vector2(p.x, (p.z - L.neck_z) * 1.1).length()
			if d > 0.11:
				return -1.0
			return minf(p.y - (L.neck + 0.015), collar_top - p.y)
		# Crisp white inner collar liner showing at the upper collar rim
		var collar_liner := func(p: Vector3, n: Vector3) -> float:
			if p.y < L.neck + 0.042 or p.y > collar_top + 0.006:
				return -1.0
			var d := Vector2(p.x, (p.z - L.neck_z) * 1.1).length()
			if d > 0.105:
				return -1.0
			return minf(p.y - (L.neck + 0.042), (collar_top + 0.006) - p.y)
		return [
			# Jacket body & sleeves: closed front, seamless up to mandarin collar rim.
			{slot = Slot.MAIN, offset = 0.024, region = tunic},
			# Standing mandarin collar band at the top of the jacket.
			{slot = Slot.MAIN, offset = 0.029, hide = false, stitches = false, region = collar},
			# White inner collar liner peeking along the collar rim.
			{slot = Slot.EXTRA, offset = 0.027, hide = false, stitches = false, region = collar_liner},
			# Center front placket band running down from collar to hem.
			{slot = Slot.MAIN, offset = 0.026, hide = false, stitches = false, region = func(p: Vector3, n: Vector3) -> float:
				if p.z <= 0.0 or n.z < 0.4:
					return -1.0
				if p.y < hem + 0.01 or p.y > L.neck + 0.045:
					return -1.0
				return minf(tunic.call(p, n), 0.013 - absf(p.x))},
			# Symmetrical breast pockets with flap outline on the chest.
			{slot = Slot.MAIN, offset = 0.027, hide = false, stitches = false, region = func(p: Vector3, n: Vector3) -> float:
				if p.z <= 0.01 or n.z < 0.35:
					return -1.0
				var px := absf(p.x)
				var in_x := minf(px - 0.040, 0.095 - px)
				var in_y := minf(p.y - (L.chest - 0.045), (L.chest + 0.035) - p.y)
				return minf(in_x, in_y)},
			# Symmetrical lower hip pockets with flaps.
			{slot = Slot.MAIN, offset = 0.027, hide = false, stitches = false, region = func(p: Vector3, n: Vector3) -> float:
				if p.z <= 0.01 or n.z < 0.35:
					return -1.0
				var px := absf(p.x)
				var in_x := minf(px - 0.040, 0.115 - px)
				var in_y := minf(p.y - (hem + 0.05), (hem + 0.14) - p.y)
				return minf(in_x, in_y)},
			# Red delegate badge pinned above left breast pocket.
			{slot = Slot.ACCENT, offset = 0.030, hide = false, stitches = false, region = func(p: Vector3, n: Vector3) -> float:
				if p.z <= 0.01 or n.z < 0.4:
					return -1.0
				var bx := minf((p.x - 0.050), 0.082 - p.x)
				var by := minf(p.y - (L.chest + 0.045), (L.chest + 0.065) - p.y)
				return minf(bx, by)},
			# Five gold/brass buttons down the front placket.
			{slot = Slot.DETAIL, offset = 0.031, hide = false, stitches = false, region = func(p: Vector3, n: Vector3) -> float:
				if p.z <= 0.01 or n.z < 0.35:
					return -1.0
				var d := -1.0
				for k in 5:
					var by := lerpf(L.neck + 0.025, hem + 0.07, float(k) / 4.0)
					var b := 0.010 - Vector2(p.x, p.y - by).length()
					d = maxf(d, b)
				return d},
			# Trousers to the shoes.
			{slot = Slot.MAIN, offset = 0.013, region = func(p, n): return _legs(p, L.ankle + 0.03, hem + 0.03),
				drape = _pants_drape(L, {base = 0.013, flare = 0.01, hem = L.ankle + 0.03, amount = 0.6, cover = hem, cover_max = 0.016,
					pin = func(p: Vector3) -> bool: return p.y > hem})},
		]
	return {
		detailed = true,
		pieces = pieces,
		shoes = {style = &"dress", upper = Slot.TRIM, sole = Slot.TRIM, sock = Slot.MAIN},
		colors = [suit, shoes, Color(0.88, 0.10, 0.10), Color(0.95, 0.95, 0.93), Color(0.88, 0.74, 0.22)],
		alt_colors = [alt_suit, alt_shoes, Color(0.88, 0.10, 0.10), Color(0.95, 0.95, 0.93), Color(0.82, 0.82, 0.85)],
		fabrics = [&"cotton", &"leather", &"cotton", &"cotton", &"metal"],
	}



## Crew-neck sweater (ribbed hem and cuffs; `quarter_zip` adds a zip at the neck) over
## trousers or jeans (`pants_fabric`), and sneakers. Slots: sweater, ribbing/zip, pants, shoes.
func _sweater_spec(sweater: Color, pants: Color, shoes: Color, pants_fabric: StringName,
		alt_sweater: Color, alt_pants: Color, alt_shoes: Color, quarter_zip := false) -> Dictionary:
	return {
		detailed = true,
		pieces = func(L: Dictionary) -> Array:
			var hem: float = L.hip - 0.04
			var cuff: float = L.wrist - 0.02
			return [
				{slot = Slot.MAIN, offset = 0.017, trim_slot = Slot.TRIM,
					region = func(p, n): return _top(p, L, hem, cuff),
					trim = func(p, n):
						var rib: float = maxf((hem + 0.035) - p.y, absf(p.x) - (cuff - 0.035))
						if quarter_zip:
							rib = maxf(rib, minf(_zip(p, n, 0.006), p.y - (L.chest - 0.05)))
						return rib,
				},
				{slot = Slot.ACCENT, offset = 0.011, region = func(p, n): return _legs(p, L.ankle + 0.05, hem + 0.03),
					drape = _pants_drape(L, {base = 0.011, flare = 0.008, hem = L.ankle + 0.05, amount = 0.7, cover = hem, cover_max = 0.014,
						pin = func(p: Vector3) -> bool: return p.y > L.waist - 0.03})},
			],
		shoes = {style = &"sneaker", upper = Slot.EXTRA, sole = Slot.TRIM, sock = Slot.EXTRA},
		colors = [sweater, sweater.darkened(0.25), pants, shoes],
		alt_colors = [alt_sweater, alt_sweater.darkened(0.25), alt_pants, alt_shoes],
		fabrics = [&"cotton", &"stretch", pants_fabric, &"leather"],
	}


## T-shirt, jeans and sneakers. Slots: tee, sole, jeans, shoes.
func _tee_spec(tee: Color, jeans: Color, shoes: Color, alt_tee: Color, alt_jeans: Color, alt_shoes: Color) -> Dictionary:
	return {
		detailed = true,
		pieces = func(L: Dictionary) -> Array:
			var hem: float = L.hip - 0.03
			var sleeve: float = L.shoulder + (L.elbow - L.shoulder) * 0.5
			return [
				{slot = Slot.MAIN, offset = 0.009, region = func(p, n): return _top(p, L, hem, sleeve),
				},
				{slot = Slot.ACCENT, offset = 0.011, region = func(p, n): return _legs(p, L.ankle + 0.05, hem + 0.03),
					drape = _pants_drape(L, {base = 0.011, flare = 0.008, hem = L.ankle + 0.05, amount = 0.7, cover = hem, cover_max = 0.012,
						pin = func(p: Vector3) -> bool: return p.y > L.waist - 0.03})},
			],
		shoes = {style = &"sneaker", upper = Slot.EXTRA, sole = Slot.TRIM, sock = Slot.EXTRA},
		colors = [tee, Color(0.8, 0.8, 0.78), jeans, shoes],
		alt_colors = [alt_tee, Color(0.1, 0.1, 0.1), alt_jeans, alt_shoes],
		fabrics = [&"cotton", &"leather", &"denim", &"leather"],
	}


## Leather biker-style jacket, open down the front with silver zip edges, a standing
## collar and a waistband, over a crew-neck tee; dark jeans and boots.
## Slots: jacket, tee, jeans, boots, zip (metal).
func _leather_jacket_spec(jacket: Color, tee: Color, jeans: Color, alt_jacket: Color, alt_tee: Color, alt_jeans: Color) -> Dictionary:
	return {
		detailed = true,
		pieces = func(L: Dictionary) -> Array:
			var hem: float = L.waist - 0.07
			var opening := func(p, n): return _placket(p, 0.055) if p.y < L.neck - 0.035 else -1.0
			var body := func(p, n): return minf(_top(p, L, hem, L.wrist - 0.035), -opening.call(p, n))
			return [
				# The jacket, its zip running down both open edges.
				{slot = Slot.MAIN, offset = 0.024, trim_slot = Slot.DETAIL, region = body,
					trim = func(p, n): return opening.call(p, n) + 0.007 if p.y > hem + 0.01 else -1.0},
				# Standing collar round the neck, open at the front.
				{slot = Slot.MAIN, offset = 0.034, hide = false, stitches = false, region = func(p, n):
					return minf(minf(p.y - (L.neck - 0.045), (L.neck + 0.022) - p.y), minf(body.call(p, n), 0.11 - absf(p.x)))},
				# Waistband and cuffs: thicker bands.
				{slot = Slot.MAIN, offset = 0.03, hide = false, stitches = false, region = func(p, n):
					return minf(body.call(p, n), maxf((hem + 0.03) - p.y, absf(p.x) - (L.wrist - 0.07)))},
				{slot = Slot.TRIM, offset = 0.008, region = func(p, n): return _top(p, L, L.hip - 0.03, L.shoulder + 0.08)},
				{slot = Slot.ACCENT, offset = 0.012, region = func(p, n): return _legs(p, L.ankle + 0.06, L.waist),
					drape = _pants_drape(L, {base = 0.012, flare = 0.006, hem = L.ankle + 0.06, amount = 0.6,
						pin = func(p: Vector3) -> bool: return p.y > L.waist - 0.03})},
			],
		shoes = {style = &"boot", upper = Slot.EXTRA, sole = Slot.EXTRA, sock = Slot.EXTRA},
		colors = [jacket, tee, jeans, Color(0.06, 0.05, 0.05), Color(0.75, 0.75, 0.78)],
		alt_colors = [alt_jacket, alt_tee, alt_jeans, Color(0.25, 0.15, 0.08), Color(0.8, 0.65, 0.3)],
		fabrics = [&"leather", &"cotton", &"denim", &"leather", &"metal"],
	}


## Pullover hoodie (the hood bunched behind the neck, a kangaroo pocket, drawstrings),
## jeans and sneakers. Slots: hoodie, hood and pocket, jeans, shoes, drawstrings.
func _hoodie_spec(hoodie: Color, jeans: Color, shoes: Color, alt_hoodie: Color, alt_jeans: Color, alt_shoes: Color) -> Dictionary:
	return {
		detailed = true,
		pieces = func(L: Dictionary) -> Array:
			var hem: float = L.hip - 0.06
			var cuff: float = L.wrist - 0.02
			var front := func(p: Vector3, n: Vector3) -> bool: return p.z > 0.03 and n.z > 0.25
			return [
				# Hoodie body and sleeves, with a snug crew neckline.
				{slot = Slot.MAIN, offset = 0.022, region = func(p, n): return _top(p, L, hem, cuff, 0.84)},
				# Ribbed crew collar, closing the neckline seam.
				{slot = Slot.TRIM, offset = 0.027, hide = false, stitches = false, region = func(p, n):
					var d := Vector2(p.x, (p.z - L.neck_z) * 1.06).length()
					var ring := minf(d - 0.055, 0.083 - d)
					var y_band := minf(p.y - (L.neck - 0.040), (L.neck + 0.008) - p.y)
					return minf(ring, y_band)},
				# The hood lying folded on the upper back: a soft raised panel (the bunched
				# roll itself is a solid rounded form, added through `hood_roll`).
				{slot = Slot.TRIM, offset = 0.030, hide = false, stitches = false, region = func(p, n):
					var dx: float = p.x / 0.108
					var dy: float = (p.y - (L.neck - 0.105)) / 0.095
					var panel: float = 1.0 - Vector2(dx, dy).length()
					var behind: float = (L.neck_z - 0.010) - p.z
					return minf(panel, behind)},
				# Kangaroo pocket on the belly.
				{slot = Slot.TRIM, offset = 0.030, hide = false, stitches = false, region = func(p, n):
					if not front.call(p, n):
						return -1.0
					var y0: float = L.hip + 0.035
					var y1: float = L.waist - 0.005
					var half: float = lerpf(0.096, 0.116, clampf((p.y - y0) / (y1 - y0), 0.0, 1.0))
					return minf(minf(p.y - y0, y1 - p.y), half - absf(p.x))},
				# Drawstrings hanging from the collar down the chest.
				{slot = Slot.DETAIL, offset = 0.031, hide = false, stitches = false, region = func(p, n):
					if not front.call(p, n):
						return -1.0
					var cord: float = 0.0055 - absf(absf(p.x) - 0.030)
					var y_band: float = minf(p.y - (L.neck - 0.195), (L.neck - 0.055) - p.y)
					return minf(cord, y_band)},
				# Jeans.
				{slot = Slot.ACCENT, offset = 0.011, region = func(p, n): return _legs(p, L.ankle + 0.05, hem + 0.03),
					drape = _pants_drape(L, {base = 0.011, flare = 0.008, hem = L.ankle + 0.05, amount = 0.7, cover = hem, cover_max = 0.014,
						pin = func(p: Vector3) -> bool: return p.y > L.waist - 0.03})},
			],
		shoes = {style = &"sneaker", upper = Slot.EXTRA, sole = Slot.DETAIL, sock = Slot.EXTRA},
		hood_roll = {slot = Slot.TRIM},
		colors = [hoodie, hoodie.darkened(0.18), jeans, shoes, Color(0.82, 0.82, 0.78)],
		alt_colors = [alt_hoodie, alt_hoodie.darkened(0.18), alt_jeans, alt_shoes, Color(0.86, 0.86, 0.82)],
		fabrics = [&"cotton", &"cotton", &"denim", &"leather", &"cotton"],
	}


## Cardigan, open in a V with ribbed trim, over a collared shirt; trousers and
## leather dress shoes. Slots: cardigan, trim ribbing, trousers, shirt, shoes.
func _cardigan_spec(cardigan: Color, band: Color, trousers: Color, shirt: Color, alt_cardigan: Color, alt_trousers: Color,
		shoes := Color(0.20, 0.12, 0.07), alt_shoes := Color(0.08, 0.08, 0.09)) -> Dictionary:
	return {
		detailed = true,
		pieces = func(L: Dictionary) -> Array:
			var v_bottom: float = L.chest - 0.08
			var hem: float = L.hip - 0.025
			var cuff: float = L.wrist - 0.035
			var card := func(p, n): return minf(_top(p, L, hem, cuff), -_front_v(p, L, v_bottom, 0.080))
			return [
				# Draped cardigan body and sleeves with clean V-opening, ribbed cuffs/hem/V-trim
				{slot = Slot.MAIN, offset = 0.018, trim_slot = Slot.TRIM,
					region = card,
					trim = func(p: Vector3, _n: Vector3) -> float:
						var v_band: float = _front_v(p, L, v_bottom - 0.024, 0.080) + 0.024
						var hem_rib: float = (hem + 0.032) - p.y
						var cuff_rib: float = absf(p.x) - (cuff - 0.032)
						return maxf(v_band, maxf(hem_rib, cuff_rib)),
					drape = _top_drape(L, {base = 0.018, sleeve_end = cuff, cuff_flare = 0.008, sag = 0.006,
						amount = 0.55, chest_fall = 10, fine_below = L.chest + 0.05,
						fine = func(p: Vector3) -> bool: return _front_v(p, L, v_bottom - 0.04, 0.080) > -0.05})},
				# Collared shirt showing cleanly in the V, closed at throat, and at cuffs
				{slot = Slot.EXTRA, offset = 0.008, region = func(p: Vector3, _n: Vector3) -> float:
					var band_r: float = minf(minf(p.y - (L.waist - 0.04), (L.neck + 0.026) - p.y), (L.wrist - 0.022) - absf(p.x))
					if p.z > L.neck_z - 0.005:
						return band_r
					return minf(band_r, -_neck_hole(p, L))},
				# Trousers
				{slot = Slot.ACCENT, offset = 0.012, region = func(p, n): return _legs(p, L.ankle + 0.03, hem + 0.05),
					drape = _pants_drape(L, {base = 0.012, flare = 0.008, hem = L.ankle + 0.03, amount = 0.5, cover = hem, cover_max = 0.014,
						pin = func(p: Vector3) -> bool: return p.y > hem})},
			],
		shoes = {style = &"dress", upper = Slot.DETAIL, sole = Slot.DETAIL, sock = Slot.ACCENT},
		colors = [cardigan, band, trousers, shirt, shoes],
		alt_colors = [alt_cardigan, alt_cardigan.darkened(0.32), alt_trousers, Color(0.85, 0.85, 0.83), alt_shoes],
		fabrics = [&"cotton", &"cotton", &"cotton", &"cotton", &"leather"],
	}


## AGI: a seamless bodysuit over everything, head included (a faceless
## figure), with glowing lines down the sides, round the chest and down the front.
## Slots: suit, glowing lines (fabric "glow": emissive, FighterModel).
## `variants` are further suit/glow palettes FighterModel.set_look_variant() can swap to
## at runtime (AGI's phases).
func _bodysuit_spec(suit: Color, glow: Color, alt_glow: Color, variants: Array = []) -> Dictionary:
	return {
		detailed = false,
		pieces = func(L: Dictionary) -> Array:
			return [
				{slot = Slot.MAIN, offset = 0.005, trim_slot = Slot.TRIM,
					region = func(p, n): return p.y - (L.ankle - 0.020),
					trim = func(p, n):
						var sides: float = signf(p.x) * n.x - 0.94 if absf(p.x) < ARM_LIMIT else n.y - 0.9
						var chest: float = 0.007 - absf(p.y - (L.chest - 0.02))
						var front: float = (0.005 - absf(p.x)) if p.z > 0.03 and p.y < L.neck - 0.02 else -1.0
						var eyes: float = (0.012 - absf(p.y - (L.head_top - 0.12))) if p.z > 0.05 and p.y > L.neck + 0.05 else -1.0
						return maxf(maxf(sides, chest), maxf(front, eyes))},
			],
		shoes = {style = &"bodysuit", upper = Slot.MAIN, sole = Slot.MAIN, sock = Slot.MAIN},
		colors = [suit, glow],
		alt_colors = [Color(0.9, 0.9, 0.92), alt_glow],
		variants = variants,
		fabrics = [&"stretch", &"glow"],
	}


## Cleanroom coverall (bunny suit) with the hood bunched at the back: jacket and trousers
## in one colour, a standing collar, a front zip with a pull, ankle cuffs and pale
## booties. Slots: suit, trim, zipper (metal), booties, pull.
func _coverall_spec(suit: Color, trim: Color, alt_suit: Color, alt_trim: Color) -> Dictionary:
	return {
		detailed = true,
		pieces = func(L: Dictionary) -> Array:
			var hem: float = L.hip - 0.06
			var cuff: float = L.wrist - 0.02
			var cover := func(p, n): return _top(p, L, hem, cuff, 0.9)
			return [
				{slot = Slot.MAIN, offset = 0.018, region = cover},
				# Standing collar: a short tube round the neck that rises above the coverall.
				{slot = Slot.TRIM, offset = 0.026, hide = false, stitches = false, region = func(p, n):
					var d := Vector2(p.x, (p.z - L.neck_z) * 1.1).length()
					if d > 0.10:
						return -1.0
					return minf(p.y - (L.neck + 0.002), (L.neck + 0.072) - p.y)},
				# Zip tape down the front.
				{slot = Slot.TRIM, offset = 0.024, hide = false, stitches = false, region = func(p, n):
					return minf(_zip(p, n, 0.007), minf(p.y - (L.waist - 0.02), (L.neck + 0.005) - p.y))},
				# Zip pull.
				{slot = Slot.DETAIL, offset = 0.026, hide = false, stitches = false, region = func(p, n):
					if p.z <= 0.0:
						return -1.0
					return 0.012 - Vector2(p.x, p.y - (L.chest - 0.06)).length()},
				# Hood panel on the upper back.
				{slot = Slot.TRIM, offset = 0.028, hide = false, stitches = false, region = func(p, n):
					var dx: float = p.x / 0.11
					var dy: float = (p.y - (L.neck - 0.10)) / 0.09
					var panel: float = 1.0 - Vector2(dx, dy).length()
					return minf(panel, (L.neck_z - 0.01) - p.z)},
				# Trousers, loose.
				{slot = Slot.MAIN, offset = 0.015, region = func(p, n): return _legs(p, L.ankle + 0.09, hem + 0.03),
					drape = _pants_drape(L, {base = 0.015, flare = 0.012, hem = L.ankle + 0.09, amount = 0.8,
						cover = hem, cover_max = 0.018, pin = func(p: Vector3) -> bool: return p.y > hem})},
				# Ankle cuffs.
				{slot = Slot.TRIM, offset = 0.018, hide = false, stitches = false,
					region = func(p, n): return _legs(p, L.ankle + 0.07, L.ankle + 0.13)},
				# Booties.
				{slot = Slot.EXTRA, offset = 0.02, flat_soles = true,
					region = func(p, n): return _legs(p, -1.0, L.ankle + 0.1)},
			],
		hood_roll = {slot = Slot.TRIM},
		colors = [suit, trim, Color(0.55, 0.58, 0.62), Color(0.9, 0.9, 0.88), Color(0.3, 0.32, 0.35)],
		alt_colors = [alt_suit, alt_trim, Color(0.4, 0.42, 0.45), Color(0.85, 0.85, 0.85),
			Color(0.2, 0.2, 0.22)],
		fabrics = [&"stretch", &"stretch", &"metal", &"leather", &"metal"],
	}


## A top with sleeves: from `y0` up over the shoulders to the base of the head, sleeves
## ending at |x| = `sleeve_end` (arms run along X in the T-pose), with a neck hole.
## `neck` scales the collar opening: below 1 it hugs the neck (a crew neck).
func _top(p: Vector3, L: Dictionary, y0: float, sleeve_end: float, neck := 1.0) -> float:
	var band := minf(minf(p.y - y0, (L.neck + 0.03) - p.y), sleeve_end - absf(p.x))
	return minf(band, -_neck_hole(p, L, neck))


## A sleeveless top from `y0`: armholes at |x| = `armhole` above the armpits, full width
## below them, with a neck hole.
func _sleeveless(p: Vector3, L: Dictionary, y0: float, armhole: float) -> float:
	var side := maxf(armhole - absf(p.x), (L.chest - 0.06) - p.y)
	var band := minf(minf(p.y - y0, (L.neck + 0.03) - p.y), minf(side, ARM_LIMIT - absf(p.x)))
	return minf(band, -_neck_hole(p, L))


## Legs (and hips) between two heights; the arms sit far out along X and are excluded.
func _legs(p: Vector3, y0: float, y1: float) -> float:
	return minf(minf(p.y - y0, y1 - p.y), ARM_LIMIT - absf(p.x))


## An elliptical hole around the neck (positive inside), so the collar line is smooth.
func _neck_hole(p: Vector3, L: Dictionary, scale := 1.0) -> float:
	var radius: float = NECK_RADIUS * scale
	var ellipse := Vector2(p.x / radius, (p.z - L.neck_z) / (radius * 0.95))
	return minf(radius * (1.0 - ellipse.length()), p.y - (L.neck - 0.035))


## The front V opening (positive inside it): from the neck down to `bottom`, `width` wide
## at the neck. Only the front of the body. `top` caps where the opening begins, so a
## jacket can close over the throat and show the V lower down the chest.
func _v_cut(p: Vector3, n: Vector3, L: Dictionary, bottom: float, width: float, top := INF) -> float:
	if p.y > top:
		return -1.0
	if p.z <= 0.0 or n.z < 0.15:
		return -1.0
	var half_width: float = width * (p.y - bottom) / (L.neck - bottom)
	return minf(half_width - absf(p.x), p.y - bottom)


## Smooth front-only V opening without normal-angle discontinuities, for draped garments.
func _front_v(p: Vector3, L: Dictionary, bottom: float, width: float) -> float:
	if p.z <= L.neck_z:
		return -1.0
	var half_width: float = width * (p.y - bottom) / (L.neck - bottom)
	return minf(half_width - absf(p.x), p.y - bottom)


## A zip down the front centre (positive on it), `half_width` either side.
func _zip(p: Vector3, n: Vector3, half_width: float) -> float:
	if p.z <= 0.0 or n.z < 0.3:
		return -1.0
	return half_width - absf(p.x)


## A front placket (positive on it), `half_width` either side of the middle, all the way
## down the front: unlike `_zip` it doesn't depend on the normal, which turns down under
## the bust and made the edges jagged on draped cloth.
func _placket(p: Vector3, half_width: float) -> float:
	return half_width - absf(p.x) if p.z > 0.02 else -1.0


## A rounded neckline front and back (positive inside it): `depth` below the neck,
## `half_width` wide.
func _scoop(p: Vector3, L: Dictionary, depth: float, half_width: float) -> float:
	return minf(p.y - (L.neck - depth), half_width - absf(p.x))


## Karate gi collar band (positive inside it, the distance to its nearer edge): along
## both edges of the V, and on along the left panel's edge from the bottom of the V
## across to the right hip at the belt (left over right). (Around the back of the neck
## the band followed the neck hole into a sunken point; the neckline there is a plain
## stitched hem.)
## `depth`: the distance from the band's outer edge instead (rises steadily across the
## band, for its stitch rows: the tent shape would fool the clipping, which assumes a
## field changes linearly along an edge).
func _gi_collar(p: Vector3, n: Vector3, L: Dictionary, v_bottom: float, width: float, belt_hi: float, depth := false) -> float:
	const BAND := 0.042
	var tent := func(d: float) -> float: return BAND * 0.5 - absf(d - BAND * 0.5)
	var candidates := [-1.0]
	if p.z > 0.0 and n.z >= 0.15:
		if p.y >= v_bottom:
			var half: float = width * (p.y - v_bottom) / (L.neck - v_bottom)
			candidates.append(absf(p.x) - half)
		elif p.y > belt_hi - 0.02:
			# The wearer's right is -X (the T-pose faces +Z).
			var start := Vector2(0.0, v_bottom)
			var along := (Vector2(-0.1, belt_hi) - start).normalized()
			var across := Vector2(-along.y, along.x)
			if across.x < 0.0:
				across = -across
			candidates.append((Vector2(p.x, p.y) - start).dot(across))
	var best: float = candidates[0]
	for d: float in candidates:
		if tent.call(d) > tent.call(best):
			best = d
	return best if depth else tent.call(best)


## Body parts for loose cloth (ClothDrape `hull`): the arms (along X in the T-pose) are
## sliced across X, smoothed over 7 cm either way; the chest falls `chest_fall` slices
## (1.5 cm each) toward the hips and the legs `leg_fall`; the hips stop the fall (separate
## parts above and below them, where a belt sits), and the neck is its own part.
func _hull_part(p: Vector3, L: Dictionary, chest_fall := 13, leg_fall := 10) -> Array:
	if absf(p.x) > L.shoulder + 0.02 and p.y > L.chest - 0.12:
		return ["arm_l" if p.x > 0.0 else "arm_r", 0, 5, 5]
	if absf(p.x) >= ARM_LIMIT:
		return []
	# The neck on its own: the chest's fall would reach up into the head and push a
	# collar out to the width of the jaw.
	if p.y > L.neck - 0.05:
		return ["neck", 1, 1, 1]
	if p.y > L.hip + 0.06:
		return ["chest", 1, chest_fall, 1]
	if p.y > L.hip - 0.04:
		return ["hips", 1, 6, 1]
	return ["leg_l" if p.x > 0.0 else "leg_r", 1, leg_fall, 1]


## ClothDrape spec for a loose top. `o`: base (thickness), sleeve_end, cuff_flare (more
## toward the cuff from the elbow), sag (below the arm), skirt_from / skirt_flare (a
## skirt flaring below that height), blouse_at (a cinch it blouses over), amount (fold
## depth), chest_fall, fine_below (subdivide below this height, plus the sleeves),
## fine (more places to subdivide), pin, max.
func _top_drape(L: Dictionary, o: Dictionary) -> Dictionary:
	var spec := {group = o.get("group", "top"), max = o.get("max", 0.09), fold_amplitude = 0.01,
		hull = func(p: Vector3) -> Array: return _hull_part(p, L, o.get("chest_fall", 13)),
		subdivide = func(p: Vector3) -> bool:
			var fine: Callable = o.get("fine", func(_p: Vector3) -> bool: return false)
			return absf(p.x) > L.shoulder - 0.02 or p.y < o.get("fine_below", -INF) or fine.call(p),
		min = func(p, n): return _loose_top_min(p, n, L, o),
		folds = func(p, n): return _loose_top_folds(p, L, o)}
	if o.has("pin"):
		spec.pin = o.pin
	return spec


## ClothDrape spec for loose pants (or shorts). `o`: base, flare (more toward the hem
## from `flare_top`, by default just above the knee), hem, cover / cover_max (a top
## over them above that height: no thicker than this there), amount, leg_fall, pin.
func _pants_drape(L: Dictionary, o: Dictionary) -> Dictionary:
	var hem: float = o.hem
	var spec := {group = o.get("group", "pants"), fold_amplitude = 0.01, keep_apart = ["leg_l", "leg_r"],
		hull = func(p: Vector3) -> Array: return _hull_part(p, L, 13, o.get("leg_fall", 10)),
		subdivide = func(p: Vector3) -> bool: return p.y < L.knee + 0.12 and p.y > L.ankle + 0.02,
		min = func(p, n):
			var top: float = o.get("flare_top", L.knee + 0.05)
			var span: float = o.get("flare_span", L.knee - L.ankle)
			return o.base + o.flare * clampf((top - p.y) / span, 0.0, 1.0),
		max = func(p, n): return o.cover_max if p.y > o.get("cover", INF) - 0.03 else o.get("max", 0.08),
		folds = func(p, n): return _loose_pants_folds(p, L, hem, o.get("cover", INF), o.get("amount", 1.0))}
	if o.has("pin"):
		spec.pin = o.pin
	return spec


## Loose top thickness before draping: sleeves wider toward the cuff and sagging below
## the arm, a skirt flaring below `skirt_from`.
func _loose_top_min(p: Vector3, n: Vector3, L: Dictionary, o: Dictionary) -> float:
	var h: float = o.base
	var ax := absf(p.x)
	if ax > L.shoulder and o.has("sleeve_end"):
		var sleeve_end: float = o.sleeve_end
		var along := clampf((ax - L.shoulder) / (sleeve_end - L.shoulder), 0.0, 1.0)
		var flare_from := minf(L.elbow, sleeve_end - 0.05)
		h += o.get("cuff_flare", 0.0) * clampf((ax - flare_from) / (sleeve_end - flare_from), 0.0, 1.0) \
			+ o.get("sag", 0.0) * maxf(-n.y, 0.0) * along
	elif p.y < o.get("skirt_from", -INF):
		h += o.get("skirt_flare", 0.0) * clampf((o.skirt_from - p.y) / 0.16, 0.0, 1.0)
	return h


## Loose top folds: rings at the elbow and cuff, lengthwise folds down the sleeve, soft
## vertical folds on the body that deepen into blousing over a cinch (`blouse_at`) and
## pleats below `skirt_from`; `amount` scales them all.
func _loose_top_folds(p: Vector3, L: Dictionary, o: Dictionary) -> float:
	const F := 13.0
	var amount: float = o.get("amount", 1.0)
	var ax := absf(p.x)
	if ax > L.shoulder + 0.02:
		var sleeve_end: float = o.get("sleeve_end", L.shoulder)
		var elbow := clampf(1.0 - absf(ax - L.elbow) / 0.08, 0.0, 1.0)
		var cuff := clampf(1.0 - (sleeve_end - ax) / 0.07, 0.0, 1.0)
		var bunched := maxf(elbow, cuff * 0.8)
		var arm := Vector2(L.arm_y, 0.0)
		var rings := ClothDrape.fold_around(p, 0, arm, 0.06, F * 0.35, F * 1.4, 0.009 * bunched * amount)
		return rings + ClothDrape.fold_around(p, 0, arm, 0.06, F, F * 0.3, 0.006 * (1.0 - bunched) * amount, 31.0)
	var blouse: float = o.get("blouse_at", -INF)
	var skirt: float = o.get("skirt_from", -INF)
	var above := 0.0
	var below := 0.0
	if p.y > blouse:
		above = clampf(1.0 - (p.y - blouse) / 0.18, 0.0, 1.0) * clampf((p.y - blouse - 0.012) / 0.03, 0.0, 1.0)
	if p.y < skirt:
		below = clampf((skirt - p.y) / 0.12, 0.0, 1.0) * clampf((skirt - 0.012 - p.y) / 0.03, 0.0, 1.0)
	return ClothDrape.fold_around(p, 1, Vector2.ZERO, 0.15, F * 1.2, F * 0.22, (0.003 + 0.008 * above + 0.011 * below) * amount, 57.0)


## Loose pants folds: rings behind and over the knee, stacked folds at the hem, long
## vertical folds between; none under a top (`cover` and up).
func _loose_pants_folds(p: Vector3, L: Dictionary, hem: float, cover: float, amount: float) -> float:
	const F := 13.0
	if p.y > cover - 0.03:
		return 0.0
	var knee := clampf(1.0 - absf(p.y - L.knee) / 0.09, 0.0, 1.0)
	var ankle := clampf(1.0 - (p.y - hem) / 0.14, 0.0, 1.0)
	var fade := clampf((cover - 0.03 - p.y) / 0.05, 0.0, 1.0)
	var leg := Vector2(0.1 if p.x > 0.0 else -0.1, 0.0)
	var rings := ClothDrape.fold_around(p, 1, leg, 0.08, F * 0.35, F * 1.5, (0.005 * knee + 0.01 * ankle) * amount, 11.0)
	var vertical := ClothDrape.fold_around(p, 1, leg, 0.08, F * 1.1, F * 0.2, 0.007 * (1.0 - maxf(knee, ankle)) * amount, 83.0)
	return fade * (rings + vertical)


# --- Building ------------------------------------------------------------------------

## `face`: CharacterData.face_shape, sculpted into the body's face first (FaceSculpt).
func _build(model_scene: PackedScene, spec: Dictionary, face_shape: Dictionary = {}) -> Dictionary:
	var scene := model_scene.instantiate()
	var skeleton := scene.find_child("Skeleton3D") as Skeleton3D
	var body_instance: MeshInstance3D
	for mi: MeshInstance3D in scene.find_children("*", "MeshInstance3D", true, false):
		var material := mi.mesh.surface_get_material(0)
		if material and material.resource_name.begins_with("MI_Superhero"):
			body_instance = mi
	_body_skin = body_instance.skin
	_pelvis_bind = _bind_index(skeleton, "pelvis")
	_skeleton = skeleton
	_to_skeleton = skeleton.get_bone_global_rest(skeleton.find_bone("pelvis")) * _body_skin.get_bind_pose(_pelvis_bind)
	_tails = []
	var L := _landmarks(skeleton, body_instance.mesh)
	var arrays := body_instance.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	if not face_shape.is_empty():
		var sculpted := FaceSculpt.apply(verts, FaceShapes.landmarks(scene), face_shape)
		# Turn each original normal as much as the surface turned there (the model's own
		# normals aren't the plain smooth ones, so replacing them leaves visible patches).
		var before := FaceShapes._smooth_normals(verts, indices)
		var after := FaceShapes._smooth_normals(sculpted, indices)
		for v in verts.size():
			if sculpted[v] != verts[v] and before[v] != after[v]:
				normals[v] = (Quaternion(before[v], after[v]) * normals[v]).normalized()
		verts = sculpted
		arrays[Mesh.ARRAY_VERTEX] = verts
		arrays[Mesh.ARRAY_NORMAL] = normals
	var pieces: Array = spec.pieces.call(L)

	var detailed: bool = spec.get("detailed", false)
	var tools: Array[SurfaceTool] = []
	var used: Array[bool] = []
	for i in Slot.size():
		used.append(false)
		var st := SurfaceTool.new()
		st.set_skin_weight_count(SurfaceTool.SKIN_4_WEIGHTS)
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		tools.append(st)
	var hidden := PackedByteArray()
	hidden.resize(indices.size() / 3)
	var triangles := 0
	# Draped pieces get twice the skin's resolution where they fold (`drape.subdivide`,
	# a func(p) -> bool at a triangle's middle): every edge of such a triangle is split,
	# for every draped piece alike, so pieces and neighbours agree and nothing cracks.
	var split_edges := {}
	for piece: Dictionary in pieces:
		if not piece.has("drape"):
			continue
		var wants: Callable = piece.drape.get("subdivide", func(_p: Vector3) -> bool: return true)
		var region: Callable = piece.region
		var inside := PackedFloat32Array()
		inside.resize(verts.size())
		for v in verts.size():
			inside[v] = region.call(verts[v], normals[v])
		for t in indices.size() / 3:
			var c := [indices[t * 3], indices[t * 3 + 1], indices[t * 3 + 2]]
			if maxf(inside[c[0]], maxf(inside[c[1]], inside[c[2]])) < 0.0:
				continue
			if not wants.call((verts[c[0]] + verts[c[1]] + verts[c[2]]) / 3.0):
				continue
			for k in 3:
				split_edges[_edge_key(verts[c[k]], verts[c[(k + 1) % 3]])] = true
	var draped_faces: Array = [] # draped pieces' triangles, finished by ClothDrape
	var surface := _Surface.new() # the outfit and body, for hanging the knots' tails on
	for piece_index in pieces.size():
		var piece: Dictionary = pieces[piece_index]
		var draped := piece.has("drape")
		var region: Callable = piece.region
		var distance := PackedFloat32Array()
		distance.resize(verts.size())
		for v in verts.size():
			distance[v] = region.call(verts[v], normals[v])
		for t in indices.size() / 3:
			var corners := [indices[t * 3], indices[t * 3 + 1], indices[t * 3 + 2]]
			var d := [distance[corners[0]], distance[corners[1]], distance[corners[2]]]
			if piece.get("hide", true) and d.min() >= HIDE_INSET:
				hidden[t] = 1
			if d.max() < 0.0:
				continue
			var polygon: Array = []
			for c: int in corners:
				polygon.append({p = verts[c], n = normals[c], uv = uvs[c],
					bones = bones.slice(c * 4, c * 4 + 4), weights = weights.slice(c * 4, c * 4 + 4)})
			var polygons := [polygon]
			if draped:
				var marked := []
				for k in 3:
					marked.append(split_edges.has(_edge_key(verts[corners[k]], verts[corners[(k + 1) % 3]])))
				polygons = ClothDrape.subdivide(polygon, marked, _blend)
			for sub: Array in polygons:
				var clipped := _clip(sub, region, d.min() >= 0.0 and not draped)
				if clipped.size() < 3:
					continue
				var parts := [[clipped, piece.slot]]
				if piece.has("trim"):
					var trim: Callable = piece.trim
					parts = [[_clip(clipped, trim, false), piece.trim_slot],
						[_clip(clipped, func(p, n): return -trim.call(p, n), false), piece.slot]]
				for part: Array in parts:
					var slot: int = part[1]
					var bands := [[part[0], false]]
					if detailed and piece.get("stitches", true):
						bands = _stitch_bands(part[0], piece.get("stitch_region", region), piece.get("stitch_rows", [[STITCH_NEAR, STITCH_FAR]]))
					for band: Array in bands:
						var poly: Array = band[0]
						for i in range(1, poly.size() - 1):
							# Cuts through a vertex leave zero-area slivers; their tangents
							# come out invalid and render as holes.
							var area: float = (poly[i].p - poly[0].p).cross(poly[i + 1].p - poly[0].p).length()
							if area < MIN_TRIANGLE_AREA:
								continue
							var shades := []
							for vertex: Dictionary in [poly[0], poly[i], poly[i + 1]]:
								var shade := 1.0
								if detailed:
									shade = STITCH_SHADE if band[1] else _hem_shade(region.call(vertex.p, vertex.n))
								shades.append(shade)
								if not draped:
									_emit(tools[slot], vertex, piece, Color(shade, shade, shade) if detailed else Color.TRANSPARENT)
							if draped:
								draped_faces.append([[poly[0], poly[i], poly[i + 1]], piece_index, slot, shades])
							used[slot] = true
							triangles += 1
	if not draped_faces.is_empty():
		var cloth := ClothDrape.process(draped_faces, pieces, verts)
		triangles += cloth.size() - draped_faces.size()
		_rig_hems(cloth, pieces)
		for tri: Array in cloth:
			for corner: Dictionary in tri[0]:
				_emit_draped(tools[tri[1]], corner, detailed)
				surface.add(corner.pos)
	for v in verts:
		surface.add(v)
	if spec.has("hood_roll"):
		var binds := [_bind_index(skeleton, "neck_01"), _bind_index(skeleton, "spine_03")]
		triangles += _add_hood_roll(tools[spec.hood_roll.slot], L, surface, binds, detailed)
		used[spec.hood_roll.slot] = true
	if spec.has("belt_knot") and spec.belt_knot.get("tied", false):
		triangles += _add_tied_belt(tools[spec.belt_knot.slot], spec.belt_knot, L, surface, detailed)
		used[spec.belt_knot.slot] = true
	elif spec.has("belt_knot"):
		triangles += _add_belt_knot(tools[spec.belt_knot.slot], spec.belt_knot, L, verts, detailed)
		used[spec.belt_knot.slot] = true
	if spec.has("headband_knot"):
		var binds := [_bind_index(skeleton, "Head"), _bind_index(skeleton, "neck_01"), _bind_index(skeleton, "spine_03")]
		triangles += _add_headband_knot(tools[spec.headband_knot.slot], spec.headband_knot, L, surface, binds, detailed)
		used[spec.headband_knot.slot] = true
	if spec.has("shoes"):
		var shoe_spec: Dictionary = spec.shoes
		var hide_y: float = L.ankle + (0.055 if shoe_spec.style == &"boot" else (0.020 if shoe_spec.style == &"bodysuit" else 0.035))
		for t in indices.size() / 3:
			var a: Vector3 = verts[indices[t * 3]]
			var b: Vector3 = verts[indices[t * 3 + 1]]
			var c: Vector3 = verts[indices[t * 3 + 2]]
			if absf(a.x) < ARM_LIMIT and a.y < hide_y and b.y < hide_y and c.y < hide_y:
				hidden[t] = 1
		triangles += _add_shoes(tools, L, shoe_spec, detailed)
		used[shoe_spec.upper] = true
		used[shoe_spec.sole] = true
		used[shoe_spec.sock] = true

	var outfit := ArrayMesh.new()
	for slot in Slot.size():
		if not used[slot]:
			continue
		tools[slot].index()
		tools[slot].generate_tangents()
		tools[slot].commit(outfit)
		outfit.surface_set_name(outfit.get_surface_count() - 1, Slot.keys()[slot].to_lower())
	if not _tails.is_empty():
		outfit.set_meta(&"spring_tails", _tails)

	# The body without the covered skin (same vertices, fewer triangles).
	var kept := PackedInt32Array()
	for t in indices.size() / 3:
		if not hidden[t]:
			kept.append_array(indices.slice(t * 3, t * 3 + 3))
	var body_arrays := arrays.duplicate()
	body_arrays[Mesh.ARRAY_INDEX] = kept
	# Custom vertex channels (the female body has some) need extra format flags to
	# re-add, and standard materials never read them.
	for channel in [Mesh.ARRAY_CUSTOM0, Mesh.ARRAY_CUSTOM1, Mesh.ARRAY_CUSTOM2, Mesh.ARRAY_CUSTOM3]:
		body_arrays[channel] = null
	if detailed:
		body_arrays[Mesh.ARRAY_TEX_UV2] = uvs # the skin pore detail map tiles over this
	var body := ArrayMesh.new()
	body.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, body_arrays)
	body.surface_set_material(0, body_instance.mesh.surface_get_material(0).duplicate())
	body.surface_set_name(0, body_instance.mesh.surface_get_name(0))
	# Facial expressions (blend shapes, an opened mouth and its interior).
	var face := FaceShapes.landmarks(scene, verts)
	body = FaceShapes.build(body, face, FaceShapes.eye_openings(verts, face), true)
	scene.free()
	return {outfit = outfit, body = body, outfit_triangles = triangles,
		body_before = indices.size() / 3, body_after = kept.size() / 3}


## Clips a polygon (vertex dictionaries) to where `field` >= 0, cutting edges at the zero
## crossing and blending every vertex attribute there.
func _clip(polygon: Array, field: Callable, all_inside: bool = false) -> Array:
	if all_inside:
		return polygon
	var values := polygon.map(func(v: Dictionary) -> float: return field.call(v.p, v.n))
	var out: Array = []
	for i in polygon.size():
		var a: Dictionary = polygon[i]
		var b: Dictionary = polygon[(i + 1) % polygon.size()]
		var da: float = values[i]
		var db: float = values[(i + 1) % polygon.size()]
		if da >= 0.0:
			out.append(a)
		if (da >= 0.0) != (db >= 0.0):
			out.append(_blend(a, b, da / (da - db)))
	return out


## Detailed outfits: a garment polygon cut along its stitch lines (`rows`: [near, far]
## distances inside the hem, in order): [[polygon, is_stitch], ...].
func _stitch_bands(polygon: Array, region: Callable, rows: Array) -> Array:
	var cuts := [-INF]
	for row: Array in rows:
		cuts.append_array(row)
	cuts.append(INF)
	var out: Array = []
	for i in cuts.size() - 1:
		var lo: float = cuts[i]
		var hi: float = cuts[i + 1]
		var part := polygon
		if lo > -INF:
			part = _clip(part, func(p, n): return region.call(p, n) - lo)
		if hi < INF:
			part = _clip(part, func(p, n): return hi - region.call(p, n))
		out.append([part, i % 2 == 1])
	return out


## Cloth brightness at `distance` inside a hem (detailed outfits).
func _hem_shade(distance: float) -> float:
	return lerpf(HEM_SHADE, 1.0, clampf(distance / HEM_SHADE_DEPTH, 0.0, 1.0))


func _blend(a: Dictionary, b: Dictionary, t: float) -> Dictionary:
	var influence := {}
	for k in 4:
		influence[a.bones[k]] = influence.get(a.bones[k], 0.0) + a.weights[k] * (1.0 - t)
		influence[b.bones[k]] = influence.get(b.bones[k], 0.0) + b.weights[k] * t
	var order := influence.keys()
	order.sort_custom(func(x, y): return influence[x] > influence[y])
	var bone_ids := PackedInt32Array()
	var bone_weights := PackedFloat32Array()
	var total := 0.0
	for k in 4:
		var bone: int = order[k] if k < order.size() else 0
		var weight: float = influence[bone] if k < order.size() else 0.0
		bone_ids.append(bone)
		bone_weights.append(weight)
		total += weight
	for k in 4:
		bone_weights[k] /= maxf(total, 0.0001)
	return {p = a.p.lerp(b.p, t), n = a.n.lerp(b.n, t).normalized(), uv = a.uv.lerp(b.uv, t),
		bones = bone_ids, weights = bone_weights}


## `shade` (detailed outfits): the vertex colour; transparent = none.
func _emit(st: SurfaceTool, vertex: Dictionary, piece: Dictionary, shade := Color.TRANSPARENT) -> void:
	var offset: float = piece.offset.call(vertex.n) if piece.offset is Callable else piece.offset
	if piece.get("flat_soles", false) and vertex.n.y < -0.6:
		offset = 0.002 # don't push boot soles into the floor
	if shade.a > 0.0:
		st.set_color(shade)
	st.set_normal(vertex.n)
	st.set_uv(vertex.uv)
	st.set_bones(vertex.bones)
	st.set_weights(vertex.weights)
	st.add_vertex(vertex.p + vertex.n * offset)


## The same key for an edge from either end (positions to 0.5 mm: the base bodies'
## halves aren't merged down the middle).
func _edge_key(a: Vector3, b: Vector3) -> String:
	var ka := Vector3i((a * 2000.0).round())
	var kb := Vector3i((b * 2000.0).round())
	return "%s%s" % [ka, kb] if [ka.x, ka.y, ka.z] < [kb.x, kb.y, kb.z] else "%s%s" % [kb, ka]


## A finished corner of draped cloth (ClothDrape.process).
func _emit_draped(st: SurfaceTool, corner: Dictionary, detailed: bool) -> void:
	if detailed:
		st.set_color(Color(corner.shade, corner.shade, corner.shade))
	st.set_normal(corner.normal)
	st.set_uv(corner.uv)
	st.set_bones(corner.bones)
	st.set_weights(corner.weights)
	st.add_vertex(corner.pos)


## Belt knot at the front centre plus two hanging tails, all bound to the pelvis.
func _add_belt_knot(st: SurfaceTool, knot: Dictionary, L: Dictionary, verts: PackedVector3Array, detailed: bool) -> int:
	var y: float = L.hip + knot.y
	var front := -INF
	for v in verts:
		if absf(v.y - y) < 0.02 and absf(v.x) < 0.04:
			front = maxf(front, v.z)
	var z: float = front + knot.offset
	var boxes := [
		[Vector3(0.0, y, z + 0.008), Vector3(0.028, 0.02, 0.012), 0.0], # knot
		[Vector3(-0.022, y - 0.1, z + 0.006), Vector3(0.016, 0.085, 0.005), -0.18], # tails
		[Vector3(0.022, y - 0.11, z + 0.006), Vector3(0.016, 0.09, 0.005), 0.22],
	]
	var triangles := 0
	for box: Array in boxes:
		var basis := Basis(Vector3.BACK, box[2])
		var center: Vector3 = box[0]
		var half: Vector3 = box[1]
		for face in 6:
			var axis := face / 2
			var side := 1.0 if face % 2 == 0 else -1.0
			var normal := Vector3.ZERO
			normal[axis] = side
			var u := Vector3.ZERO
			u[(axis + 1) % 3] = 1.0
			var w := normal.cross(u)
			var quad := [-u - w, u - w, u + w, -u + w]
			for i in [0, 1, 2, 0, 2, 3]:
				if detailed:
					st.set_color(Color.WHITE) # no hem shading on the knot
				st.set_normal(basis * normal)
				st.set_uv(Vector2(0.5, 0.5))
				st.set_bones(PackedInt32Array([_pelvis_bind, 0, 0, 0]))
				st.set_weights(PackedFloat32Array([1.0, 0.0, 0.0, 0.0]))
				st.add_vertex(center + basis * ((normal + (quad[i] as Vector3)) * half))
			triangles += 2
	return triangles


## A belt tied at the front: a rounded square knot and two tails that hang over the
## jacket's skirt, spreading and twisting a little, all bound to the pelvis.
func _add_tied_belt(st: SurfaceTool, knot: Dictionary, L: Dictionary, surface: _Surface, detailed: bool) -> int:
	var y: float = L.hip + knot.y
	var z: float = surface.front(0.0, y) + 0.004
	var pelvis := func(_t: float) -> Array:
		return [PackedInt32Array([_pelvis_bind, 0, 0, 0]), PackedFloat32Array([1.0, 0.0, 0.0, 0.0])]
	var triangles := _rounded_box(st, Vector3(0.0, y, z + 0.012), Vector3(0.03, 0.021, 0.013), Basis(Vector3.BACK, 0.12),
		pelvis, detailed)
	for side in [-1.0, 1.0]:
		var path: Array[Vector3] = []
		var widths: Array[float] = []
		var length := 0.2 if side < 0.0 else 0.22
		for i in 11:
			var t := i / 10.0
			var x: float = side * (0.01 + 0.032 * t)
			var tail_y := y - 0.012 - length * t
			path.append(Vector3(x, tail_y, maxf(z + 0.006 - 0.004 * t, surface.front(x, tail_y) + 0.007)))
			widths.append(0.019 - 0.002 * t)
		triangles += _strip(st, path, widths, 0.005, side * 0.25, _tail_chain(path, "pelvis", pelvis), detailed)
	return triangles


## A headband tied at the back of the head: a small knot and two tails that hang down
## the back of the neck. They follow the head at the knot and the upper back at their
## ends (`binds`: head, neck, upper spine).
func _add_headband_knot(st: SurfaceTool, knot: Dictionary, L: Dictionary, surface: _Surface, binds: Array, detailed: bool) -> int:
	var y: float = L.head_top - knot.y
	var z: float = surface.back(0.0, y) - knot.offset
	var skin := func(t: float) -> Array:
		var head := clampf(1.0 - t * 1.6, 0.0, 1.0)
		var spine := clampf((t - 0.45) * 1.6, 0.0, 1.0)
		var neck := maxf(1.0 - head - spine, 0.0)
		return [PackedInt32Array([binds[0], binds[1], binds[2], 0]), PackedFloat32Array([head, neck, spine, 0.0])]
	var triangles := _rounded_box(st, Vector3(0.0, y, z - 0.007), Vector3(0.017, 0.014, 0.009), Basis(Vector3.BACK, -0.2),
		skin, detailed)
	for side in [-1.0, 1.0]:
		var path: Array[Vector3] = []
		var widths: Array[float] = []
		var length := 0.24 if side < 0.0 else 0.2
		for i in 13:
			var t := i / 12.0
			var x: float = side * (0.008 + 0.035 * t)
			var tail_y := y - 0.01 - length * t
			# Straight down from the knot, unless the back of the neck or the jacket's
			# collar stands out further.
			path.append(Vector3(x, tail_y, minf(z - 0.01, surface.back(x, tail_y) - 0.006)))
			widths.append(0.013 - 0.002 * t)
		var head := func(_t: float) -> Array:
			return [PackedInt32Array([binds[0], 0, 0, 0]), PackedFloat32Array([1.0, 0.0, 0.0, 0.0])]
		triangles += _strip(st, path, widths, 0.003, side * 0.35, _tail_chain(path, "Head", head), detailed)
	return triangles


## Rigs a tail hanging along `path` (points evenly spaced along it) for spring motion:
## `TAIL_JOINTS` bones from the knot down, under `parent` (`_add_chain`). Returns the
## strip's skin: the bones' weights blend over each joint, and near the knot the knot's own
## skin (`knot_skin`) still holds it.
func _tail_chain(path: Array[Vector3], parent: String, knot_skin: Callable) -> Callable:
	var base := _add_chain(path, parent, TAIL_JOINTS, Vector3.BACK, {})
	return func(t: float) -> Array:
		var held := clampf(1.0 - t / TAIL_ROOT_FADE, 0.0, 1.0)
		var knot: Array = knot_skin.call(t)
		var joint := _chain_joints(t, TAIL_JOINTS)
		return [PackedInt32Array([knot[0][0], base + joint[0], base + joint[1], 0]),
			PackedFloat32Array([held, (1.0 - held) * (1.0 - joint[2]), (1.0 - held) * joint[2], 0.0])]


## Adds a chain of `count` spring bones along `path` (mesh space, from the root) under
## `parent`, each with +Y down the chain and +Z toward `outward`, to `_tails` with their
## rests and skin binds (appended after the body skin's binds, which FighterModel copies
## and extends) plus the `extra` fields. Returns the first joint's bind index.
func _add_chain(path: Array[Vector3], parent: String, count: int, outward: Vector3, extra: Dictionary) -> int:
	var at := func(t: float) -> Vector3:
		var f := t * (path.size() - 1)
		var i := mini(floori(f), path.size() - 2)
		return path[i].lerp(path[i + 1], f - i)
	var base := _body_skin.get_bind_count()
	for chain: Dictionary in _tails:
		base += chain.joints.size()
	var parent_rest := _skeleton.get_bone_global_rest(_skeleton.find_bone(parent))
	var joints: Array = []
	var length := 0.0
	for k in count:
		var from := _to_skeleton * (at.call(float(k) / count) as Vector3)
		var to := _to_skeleton * (at.call(float(k + 1) / count) as Vector3)
		var down := (to - from).normalized()
		var across := down.cross(_to_skeleton.basis * outward).normalized()
		var rest := Transform3D(Basis(across, down, across.cross(down)), from)
		joints.append({name = "%s%d" % [TAIL_PREFIX, base - _body_skin.get_bind_count() + k],
			rest = parent_rest.affine_inverse() * rest, bind = rest.affine_inverse() * _to_skeleton})
		parent_rest = rest
		length = from.distance_to(to)
	var chain := {parent = parent, joints = joints, length = length}
	chain.merge(extra)
	_tails.append(chain)
	return base


## Where `t` (0..1 down a chain of `count` joints) falls: [joint, next joint, blend
## toward the next]; joint k's segment is centred on k.
func _chain_joints(t: float, count: int) -> Array:
	var s := t * count - 0.5
	var k0 := clampi(floori(s), 0, count - 1)
	var k1 := mini(k0 + 1, count - 1)
	return [k0, k1, clampf(s - k0, 0.0, 1.0) if k1 != k0 else 0.0]


## Loose hems (a piece's `hem`: top, bottom, chains, joints, optional `legs` and `share`):
## a ring of spring chains hanging from `top` to `bottom` around the pelvis (a jacket's
## skirt) or around each thigh (`legs`: shorts), each on the cloth's outer surface at its
## angle, and the piece's cloth below `top` reweighted onto the two nearest chains, more
## the further down it is (fully from `HEM_FULL_AT` of the way down, times `share`; the
## rest keeps the cloth's own weights, so the hem still follows the legs).
func _rig_hems(cloth: Array, pieces: Array) -> void:
	var to_mesh := _to_skeleton.affine_inverse()
	var rest := func(bone: String) -> Vector3: return to_mesh * _skeleton.get_bone_global_rest(_skeleton.find_bone(bone)).origin
	for piece_index in pieces.size():
		var hem: Dictionary = (pieces[piece_index] as Dictionary).get("hem", {})
		if hem.is_empty():
			continue
		var top: float = hem.top
		var bottom: float = hem.bottom
		var count: int = hem.chains
		var corners: Array = []
		for tri: Array in cloth:
			if tri[2] == piece_index:
				corners.append_array(tri[0])
		# Rings: [parent bone, axis func(y) -> Vector2 (x, z), side (sign of x, 0 = both)].
		var rings: Array = []
		if hem.get("legs", false):
			for side in ["l", "r"]:
				var hip: Vector3 = rest.call("thigh_" + side)
				var knee: Vector3 = rest.call("calf_" + side)
				var axis := func(y: float) -> Vector2:
					var p := hip.lerp(knee, (hip.y - y) / (hip.y - knee.y))
					return Vector2(p.x, p.z)
				rings.append(["thigh_" + side, axis, signf(hip.x)])
		else:
			var pelvis: Vector3 = rest.call("pelvis")
			rings.append(["pelvis", func(_y: float) -> Vector2: return Vector2(pelvis.x, pelvis.z), 0.0])
		var step := TAU / count
		var bases: Array = []
		for ring: Array in rings:
			var axis: Callable = ring[1]
			var mine := corners.filter(func(c: Dictionary) -> bool: return ring[2] == 0.0 or signf(c.pos.x) == ring[2])
			var ring_bases: Array = []
			for k in count:
				var angle := step * (k + 0.5)
				var out := Vector3(sin(angle), 0.0, cos(angle))
				var path: Array[Vector3] = []
				var radius := 0.0
				for i in 5:
					var y := lerpf(top, bottom, i / 4.0)
					var center: Vector2 = axis.call(y)
					var outer := 0.0
					for c: Dictionary in mine:
						var d := Vector2(c.pos.x, c.pos.z) - center
						if absf(c.pos.y - y) < 0.015 and absf(angle_difference(atan2(d.x, d.y), angle)) < step * 0.5:
							outer = maxf(outer, d.length())
					if outer > 0.0:
						radius = outer
					path.append(Vector3(center.x + out.x * radius, y, center.y + out.z * radius))
				ring_bases.append(_add_chain(path, ring[0], hem.joints, out, {kind = &"hem", plane = ring[0]}))
			bases.append(ring_bases)
		# Every corner's new weights first: corners can be shared between triangles.
		var skins: Array = []
		for c: Dictionary in corners:
			var r := 0
			if rings.size() > 1 and signf(c.pos.x) != rings[0][2]:
				r = 1
			var d := Vector2(c.pos.x, c.pos.z) - ((rings[r][1] as Callable).call(c.pos.y) as Vector2)
			var u := fposmod(atan2(d.x, d.y) / step - 0.5, count)
			var a := floori(u) % count
			var b := (a + 1) % count
			var f := u - floorf(u)
			var t := clampf((top - c.pos.y) / (top - bottom), 0.0, 1.0)
			var share := smoothstep(0.0, HEM_FULL_AT, t) * float(hem.get("share", 1.0))
			var joint := _chain_joints(t, hem.joints)
			var map := {}
			for i in 4:
				if c.weights[i] > 0.0:
					map[c.bones[i]] = map.get(c.bones[i], 0.0) + c.weights[i] * (1.0 - share)
			for chain: Array in [[bases[r][a], 1.0 - f], [bases[r][b], f]]:
				for j in 2:
					var w: float = share * chain[1] * (1.0 - joint[2] if j == 0 else joint[2])
					if w > 0.0:
						map[chain[0] + joint[j]] = map.get(chain[0] + joint[j], 0.0) + w
			var order := map.keys()
			order.sort_custom(func(x: int, y: int) -> bool: return map[x] > map[y])
			var bones := PackedInt32Array()
			var weights := PackedFloat32Array()
			var total := 0.0
			for i in 4:
				bones.append(order[i] if i < order.size() else 0)
				weights.append(map[order[i]] if i < order.size() else 0.0)
				total += weights[i]
			for i in 4:
				weights[i] /= maxf(total, 0.0001)
			skins.append([bones, weights])
		for i in corners.size():
			corners[i].bones = skins[i][0]
			corners[i].weights = skins[i][1]


## A flat strip (a belt or headband tail) along `path`, `widths` half wide, `thickness`
## thick, its width turning by `twist` radians from start to end. `skin` gives
## [bones, weights] along it (0..1).
func _strip(st: SurfaceTool, path: Array[Vector3], widths: Array[float], thickness: float, twist: float,
		skin: Callable, detailed: bool) -> int:
	var rings: Array = [] # per point: four corners, then the facing and across directions
	for i in path.size():
		var tangent := (path[mini(i + 1, path.size() - 1)] - path[maxi(i - 1, 0)]).normalized()
		var facing := (Vector3.BACK - tangent * tangent.dot(Vector3.BACK)).normalized()
		facing = facing.rotated(tangent, twist * i / (path.size() - 1.0))
		var across := tangent.cross(facing).normalized()
		var w := across * widths[i]
		var h := facing * thickness * 0.5
		rings.append([path[i] - w + h, path[i] + w + h, path[i] + w - h, path[i] - w - h, facing, across])
	var triangles := 0
	for i in path.size() - 1:
		var a: Array = rings[i]
		var b: Array = rings[i + 1]
		var ta := float(i) / (path.size() - 1)
		var tb := float(i + 1) / (path.size() - 1)
		for k in 4:
			var normal: Vector3 = [a[4], a[5], -a[4], -a[5]][k]
			triangles += _quad(st, [a[k], a[(k + 1) % 4], b[(k + 1) % 4], b[k]], normal, [ta, ta, tb, tb], skin, detailed)
	for end in [0, path.size() - 1]:
		var r: Array = rings[end]
		var t := float(end) / (path.size() - 1)
		var outward := (path[end] - path[1 if end == 0 else end - 1]).normalized()
		triangles += _quad(st, [r[0], r[1], r[2], r[3]], outward, [t, t, t, t], skin, detailed)
	return triangles


## A hood folded down behind the neck: a soft, rounded roll of bunched fabric resting on the
## upper back and following the curve of the shoulders. Solid, closed geometry.
func _add_hood_roll(st: SurfaceTool, L: Dictionary, surface: _Surface, binds: Array, detailed: bool) -> int:
	var y: float = L.neck - 0.036
	var z: float = surface.back(0.0, y) - 0.014
	var skin := func(_t: float) -> Array:
		return [PackedInt32Array([binds[0], binds[1], 0, 0]), PackedFloat32Array([0.8, 0.2, 0.0, 0.0])]
	var triangles := 0
	# The main bunch, with a second fold lying over it at the neckline.
	triangles += _rounded_box(st, Vector3(0.0, y, z), Vector3(0.068, 0.028, 0.026),
		Basis(Vector3.RIGHT, 0.16), skin, detailed)
	triangles += _rounded_box(st, Vector3(0.0, y + 0.020, z + 0.008), Vector3(0.056, 0.016, 0.022),
		Basis(Vector3.RIGHT, -0.30), skin, detailed)
	# The ends taper down toward the shoulder blades.
	for side in [-1.0, 1.0]:
		var s: float = side
		triangles += _rounded_box(st, Vector3(s * 0.055, y - 0.014, z - 0.004), Vector3(0.038, 0.024, 0.022),
			Basis(Vector3.RIGHT, 0.22) * Basis(Vector3.BACK, -s * 0.30), skin, detailed)
	return triangles


## A box with rounded edges (a knot): a subdivided cube pushed toward a sphere.
func _rounded_box(st: SurfaceTool, center: Vector3, half: Vector3, basis: Basis, skin: Callable, detailed: bool) -> int:
	const STEPS := 4
	var triangles := 0
	for face in 6:
		var axis := face / 2
		var sign := 1.0 if face % 2 == 0 else -1.0
		var u := Vector3.ZERO
		u[(axis + 1) % 3] = 1.0
		var v := Vector3.ZERO
		v[(axis + 2) % 3] = 1.0
		var normal_axis := Vector3.ZERO
		normal_axis[axis] = sign
		for i in STEPS:
			for j in STEPS:
				var corners := []
				for c: Array in [[i, j], [i + 1, j], [i + 1, j + 1], [i, j + 1]]:
					var q: Vector3 = normal_axis + u * (c[0] * 2.0 / STEPS - 1.0) + v * (c[1] * 2.0 / STEPS - 1.0)
					var rounded := q.lerp(q.normalized() * 1.25, 0.55).clamp(-Vector3.ONE, Vector3.ONE)
					corners.append(center + basis * (rounded * half))
				var mid: Vector3 = normal_axis + u * ((i + 0.5) * 2.0 / STEPS - 1.0) + v * ((j + 0.5) * 2.0 / STEPS - 1.0)
				triangles += _quad(st, corners, basis * (mid / half).normalized(), [0.0, 0.0, 0.0, 0.0], skin, detailed)
	return triangles


## One quad facing `normal`; `at` is each corner's position along the piece, for `skin`.
func _quad(st: SurfaceTool, corners: Array, normal: Vector3, at: Array, skin: Callable, detailed: bool) -> int:
	var order := [0, 1, 2, 0, 2, 3]
	var a: Vector3 = corners[0]
	# Wound like the body's triangles (Godot's front faces are clockwise: the cross
	# product points into the surface).
	if (corners[1] - a).cross(corners[2] - a).dot(normal) > 0.0:
		order = [0, 2, 1, 0, 3, 2]
	for k: int in order:
		var influence: Array = skin.call(at[k])
		if detailed:
			st.set_color(Color.WHITE)
		st.set_normal(normal.normalized())
		st.set_uv(Vector2(0.5, 0.5))
		st.set_bones(influence[0])
		st.set_weights(influence[1])
		st.add_vertex(corners[k])
	return 2


## The outfit and body surfaces, for hanging things on: the furthest-out point near a
## spot, at the front (+Z) or the back.
class _Surface:
	const CELL := 0.012
	var front_z := {}
	var back_z := {}


	func add(p: Vector3) -> void:
		var key := Vector2i(floori(p.x / CELL), floori(p.y / CELL))
		front_z[key] = maxf(front_z.get(key, -INF), p.z)
		back_z[key] = minf(back_z.get(key, INF), p.z)


	func front(x: float, y: float) -> float:
		var best := -INF
		for key: Vector2i in _around(x, y):
			best = maxf(best, front_z.get(key, -INF))
		return best


	func back(x: float, y: float) -> float:
		var best := INF
		for key: Vector2i in _around(x, y):
			best = minf(best, back_z.get(key, INF))
		return best


	func _around(x: float, y: float) -> Array:
		var center := Vector2i(floori(x / CELL), floori(y / CELL))
		var keys := []
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				keys.append(center + Vector2i(dx, dy))
		return keys


## Builds sculpted 3D shoes (dress shoes, sneakers, boots or smooth bodysuit feet) on
## both feet, hiding bare toes and skinning across foot / ball / calf bones.
func _add_shoes(tools: Array[SurfaceTool], L: Dictionary, shoe_spec: Dictionary, detailed: bool) -> int:
	var style: StringName = shoe_spec.style
	var st_upper: SurfaceTool = tools[shoe_spec.upper]
	var st_sole: SurfaceTool = tools[shoe_spec.sole]
	var st_sock: SurfaceTool = tools[shoe_spec.sock]
	var z_back := -0.146 if style == &"bodysuit" else -0.150
	var z_front := 0.148 if style == &"dress" else (0.144 if style == &"boot" else (0.132 if style == &"bodysuit" else 0.140))
	var y_floor := -0.010
	var is_dress := style == &"dress"
	var is_boot := style == &"boot"
	var is_body := style == &"bodysuit"
	var welt := 0.0 if is_body else (0.0025 if (is_dress or is_boot) else 0.003)

	var cx_at := func(u: float) -> float:
		return 0.120 + 0.012 * sin(PI * pow(u, 0.85))
	var hw_at := func(u: float) -> float:
		var base := 0.043
		if u < 0.14:
			base = 0.043 * sqrt(sin(PI * 0.5 * clampf(u / 0.14, 0.0, 1.0)))
		elif u < 0.40:
			var t := (u - 0.14) / 0.26
			var waist := 0.044 if is_dress else 0.050
			base = lerpf(0.043, waist, sin(PI * 0.5 * t))
		elif u < 0.70:
			var t := (u - 0.40) / 0.30
			var waist := 0.044 if is_dress else 0.050
			var ball := 0.059 if is_dress else (0.057 if is_body else 0.062)
			base = lerpf(waist, ball, smoothstep(0.0, 1.0, t))
		else:
			var t := clampf((u - 0.70) / 0.30, 0.0, 1.0)
			var ball := 0.059 if is_dress else (0.057 if is_body else 0.062)
			var exp_t := 0.72 if is_dress else 0.52
			base = ball * pow(cos(PI * 0.5 * t), exp_t)
		return maxf(base, 0.006)
	var yb_at := func(u: float) -> float:
		if is_body:
			return y_floor
		var toe_spring := 0.005 * pow(clampf((u - 0.82) / 0.18, 0.0, 1.0), 1.6)
		if is_dress or is_boot:
			var arch := smoothstep(0.26, 0.35, u) * (1.0 - smoothstep(0.42, 0.52, u))
			return y_floor + (0.010 if is_dress else 0.007) * arch + toe_spring
		return y_floor + toe_spring
	var ys_at := func(u: float) -> float:
		var yb: float = yb_at.call(u)
		if is_body:
			return yb + 0.004
		if is_dress:
			var heel_t := 1.0 - smoothstep(0.24, 0.36, u)
			return lerpf(yb + 0.011, y_floor + 0.022, heel_t)
		if is_boot:
			var heel_t := 1.0 - smoothstep(0.26, 0.38, u)
			return lerpf(yb + 0.016, y_floor + 0.024, heel_t)
		return yb + 0.022
	var yu_at := func(u: float) -> float:
		var ys: float = ys_at.call(u)
		var collar_h := 0.088 if is_body else (0.092 if is_dress else 0.106)
		if u <= 0.38:
			var dip := sin(PI * clampf(u / 0.38, 0.0, 1.0)) * (0.006 if is_body else 0.010)
			return collar_h - dip
		var t := clampf((u - 0.38) / 0.62, 0.0, 1.0)
		var arch := lerpf(collar_h, 0.062, smoothstep(0.0, 0.45, t))
		var toe := lerpf(arch, 0.042, smoothstep(0.42, 0.80, t))
		var tip := lerpf(toe, ys + 0.005, smoothstep(0.78, 1.0, t))
		return maxf(tip, ys + 0.004)

	var triangles := 0
	const NU := 18
	const NA := 10
	for leg_index in 2:
		var side := 1.0 if leg_index == 0 else -1.0
		var suffix := "l" if leg_index == 0 else "r"
		var f_bind := _bind_index(_skeleton, "foot_" + suffix)
		var b_bind := _bind_index(_skeleton, "ball_" + suffix)
		var c_bind := _bind_index(_skeleton, "calf_" + suffix)
		var skin_fn := func(p: Vector3) -> Array:
			var ball_t: float = smoothstep(0.030, 0.080, p.z)
			var calf_t: float = clampf((p.y - (float(L.ankle) + 0.015)) / 0.055, 0.0, 0.45) * (1.0 - ball_t)
			var foot_w: float = maxf(1.0 - ball_t - calf_t, 0.0)
			var tot: float = maxf(foot_w + ball_t + calf_t, 0.0001)
			return [PackedInt32Array([f_bind, b_bind, c_bind, 0]),
				PackedFloat32Array([foot_w / tot, ball_t / tot, calf_t / tot, 0.0])]

		# 1. Sole + heel (omitted as separate rim for bodysuit; bodysuit emits clean closed bottom)
		var sole_shade := 0.68 if (is_dress or is_boot) else (0.96 if not is_body else 0.90)
		var sole_slices: Array = []
		for i in NU + 1:
			var u := lerpf(0.02, 0.98, float(i) / NU)
			var z := lerpf(z_back, z_front, u)
			var cx: float = cx_at.call(u)
			var hw: float = hw_at.call(u) + welt * sin(PI * u)
			var yb: float = yb_at.call(u)
			var ys: float = ys_at.call(u)
			sole_slices.append([
				Vector3(side * (cx - hw), yb, z),
				Vector3(side * (cx + hw), yb, z),
				Vector3(side * (cx + hw), ys, z),
				Vector3(side * (cx - hw), ys, z),
			])
		for i in NU:
			var a: Array = sole_slices[i]
			var b: Array = sole_slices[i + 1]
			triangles += _shoe_quad(st_sole, [a[0], a[1], b[1], b[0]], Vector3.DOWN, skin_fn, detailed, sole_shade * 0.85)
			triangles += _shoe_quad(st_sole, [a[1], a[2], b[2], b[1]], Vector3(side, 0.0, 0.0), skin_fn, detailed, sole_shade)
			triangles += _shoe_quad(st_sole, [a[3], a[0], b[0], b[3]], Vector3(-side, 0.0, 0.0), skin_fn, detailed, sole_shade)
			triangles += _shoe_quad(st_sole, [a[2], a[3], b[3], b[2]], Vector3.UP, skin_fn, detailed, sole_shade * 0.9)
		var s0: Array = sole_slices[0]
		var s1: Array = sole_slices[NU]
		triangles += _shoe_quad(st_sole, [s0[0], s0[3], s0[2], s0[1]], Vector3.BACK, skin_fn, detailed, sole_shade)
		triangles += _shoe_quad(st_sole, [s1[0], s1[1], s1[2], s1[3]], Vector3.FORWARD, skin_fn, detailed, sole_shade)

		# 2. Smooth contoured upper (no toe grooves)
		var grid: Array = []
		var gnorm: Array = []
		for i in NU + 1:
			var u := lerpf(0.02, 0.98, float(i) / NU)
			var z := lerpf(z_back, z_front, u)
			var cx: float = cx_at.call(u)
			var hw: float = hw_at.call(u)
			var ys: float = ys_at.call(u) - 0.002
			var yu: float = yu_at.call(u)
			var row: Array[Vector3] = []
			var nrow: Array[Vector3] = []
			for j in NA + 1:
				var ang := PI * float(j) / NA
				var x := side * (cx - hw * cos(ang))
				var y := lerpf(ys, yu, pow(sin(ang), 0.78))
				row.append(Vector3(x, y, z))
				nrow.append(Vector3.ZERO)
			grid.append(row)
			gnorm.append(nrow)
		for i in NU:
			for j in NA:
				var p00: Vector3 = grid[i][j]
				var p10: Vector3 = grid[i + 1][j]
				var p11: Vector3 = grid[i + 1][j + 1]
				var p01: Vector3 = grid[i][j + 1]
				var fn := (p10 - p00).cross(p01 - p00)
				if fn.dot(Vector3(p00.x - side * cx_at.call(lerpf(0.02, 0.98, float(i) / NU)), p00.y - y_floor, 0.0)) < 0.0:
					fn = -fn
				gnorm[i][j] += fn
				gnorm[i + 1][j] += fn
				gnorm[i + 1][j + 1] += fn
				gnorm[i][j + 1] += fn
		for i in NU:
			for j in NA:
				var corners := [grid[i][j], grid[i + 1][j], grid[i + 1][j + 1], grid[i][j + 1]]
				var norms := [gnorm[i][j], gnorm[i + 1][j], gnorm[i + 1][j + 1], gnorm[i][j + 1]]
				triangles += _shoe_smooth_quad(st_upper, corners, norms, skin_fn, detailed, 1.0)
		# Close heel & toe upper ends
		for end_idx in [0, NU]:
			var end_n := Vector3.BACK if end_idx == 0 else Vector3.FORWARD
			var row: Array[Vector3] = grid[end_idx]
			var base_pt := (row[0] + row[NA]) * 0.5
			for j in NA:
				triangles += _shoe_tri(st_upper, [base_pt, row[j], row[j + 1]], end_n, skin_fn, detailed, 0.95)

		# 3. Ankle collar & sock / boot shaft (connects inside trouser hem, zero bare ankle skin)
		var sock_top: float = float(L.ankle) + (0.088 if is_boot else (0.035 if is_body else 0.055))
		var collar_top: float = float(L.ankle) + (0.022 if not is_dress else 0.008)
		var collar_bot := 0.068
		var acx := side * 0.123
		var acz := -0.084
		const NC := 12
		if not is_boot and not is_body:
			# Padded collar rim around shoe opening
			triangles += _shoe_tube(st_upper, acx, acz, 0.047, 0.051, collar_bot, collar_top, NC, skin_fn, detailed, 0.94)
		# Inner sock / boot shaft
		var shaft_rx := 0.048 if is_boot else 0.043
		var shaft_rz := 0.052 if is_boot else 0.047
		var shaft_shade := 1.0 if (is_boot or is_body) else 0.85
		triangles += _shoe_tube(st_sock, acx, acz, shaft_rx, shaft_rz, collar_bot, sock_top, NC, skin_fn, detailed, shaft_shade)
	return triangles


func _shoe_tube(st: SurfaceTool, cx: float, cz: float, rx: float, rz: float, y0: float, y1: float, segs: int,
		skin_fn: Callable, detailed: bool, shade: float) -> int:
	var triangles := 0
	var bot: Array[Vector3] = []
	var top: Array[Vector3] = []
	var norms: Array[Vector3] = []
	for k in segs + 1:
		var ang := TAU * float(k) / segs
		var nx := cos(ang)
		var nz := sin(ang)
		bot.append(Vector3(cx + rx * nx, y0, cz + rz * nz))
		top.append(Vector3(cx + rx * nx, y1, cz + rz * nz))
		norms.append(Vector3(nx / rx, 0.0, nz / rz).normalized())
	for k in segs:
		triangles += _shoe_smooth_quad(st, [bot[k], bot[k + 1], top[k + 1], top[k]],
			[norms[k], norms[k + 1], norms[k + 1], norms[k]], skin_fn, detailed, shade)
	return triangles


func _shoe_quad(st: SurfaceTool, corners: Array, normal: Vector3, skin_fn: Callable, detailed: bool, shade: float) -> int:
	var n := normal.normalized()
	return _shoe_smooth_quad(st, corners, [n, n, n, n], skin_fn, detailed, shade)


func _shoe_smooth_quad(st: SurfaceTool, corners: Array, normals: Array, skin_fn: Callable, detailed: bool, shade: float) -> int:
	var avg_n := ((normals[0] as Vector3) + (normals[1] as Vector3) + (normals[2] as Vector3) + (normals[3] as Vector3)).normalized()
	var t1 := _shoe_tri(st, [corners[0], corners[1], corners[2]], avg_n, skin_fn, detailed, shade, [normals[0], normals[1], normals[2]])
	var t2 := _shoe_tri(st, [corners[0], corners[2], corners[3]], avg_n, skin_fn, detailed, shade, [normals[0], normals[2], normals[3]])
	return t1 + t2


func _shoe_tri(st: SurfaceTool, corners: Array, face_normal: Vector3, skin_fn: Callable, detailed: bool, shade: float,
		vnormals: Array = []) -> int:
	var a: Vector3 = corners[0]
	var b: Vector3 = corners[1]
	var c: Vector3 = corners[2]
	if (b - a).cross(c - a).length() < MIN_TRIANGLE_AREA:
		return 0
	var order := [0, 1, 2]
	if (b - a).cross(c - a).dot(face_normal) > 0.0:
		order = [0, 2, 1]
	for idx: int in order:
		var pt: Vector3 = corners[idx]
		var n: Vector3 = (vnormals[idx] as Vector3).normalized() if not vnormals.is_empty() else face_normal.normalized()
		if n.length_squared() < 0.001:
			n = Vector3.UP
		var inf: Array = skin_fn.call(pt)
		if detailed:
			st.set_color(Color(shade, shade, shade))
		st.set_normal(n)
		st.set_uv(Vector2(pt.x * 2.0 + pt.z * 2.0, pt.y * 2.0))
		st.set_bones(inf[0])
		st.set_weights(inf[1])
		st.add_vertex(pt)
	return 1


## Heights and widths of the T-pose body, from the skeleton's rest pose.
func _landmarks(skeleton: Skeleton3D, mesh: Mesh) -> Dictionary:
	var rest := func(bone: String) -> Vector3: return skeleton.get_bone_global_rest(skeleton.find_bone(bone)).origin
	var top := -INF
	for v: Vector3 in mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
		top = maxf(top, v.y)
	return {hip = rest.call("pelvis").y, waist = rest.call("spine_01").y, chest = rest.call("spine_03").y,
		neck = rest.call("neck_01").y, neck_z = rest.call("neck_01").z, shoulder = rest.call("upperarm_l").x, elbow = rest.call("lowerarm_l").x,
		wrist = rest.call("hand_l").x, arm_y = rest.call("upperarm_l").y, knee = rest.call("calf_l").y,
		ankle = rest.call("foot_l").y, head_top = top}


## The skin bind for a bone (by name, or through the skeleton's bone index).
func _bind_index(skeleton: Skeleton3D, bone: String) -> int:
	for i in _body_skin.get_bind_count():
		if String(_body_skin.get_bind_name(i)) == bone:
			return i
	var bone_index := skeleton.find_bone(bone)
	for i in _body_skin.get_bind_count():
		if _body_skin.get_bind_bone(i) == bone_index:
			return i
	push_error("No skin bind for %s" % bone)
	return 0
