class_name StageRetheme
extends Node3D
## Turns an original 3D Fighter stage into an AI Showdown stage: removes the props that
## don't fit and builds new ones from simple shapes (cosmetic only: no collision, nothing
## the simulation reads). Added as a child of the stage root in the AI Showdown stage
## scenes, which inherit the original stages:
##   server_farm.tscn (rooftop): rows of GPU racks with blinking lights, cooling units.
##   mensa.tscn (dojo): a university cafeteria: tiled floor, tables, trays, the counter.
##   senate.tscn (ring): a hearing room: carpet, the committee's dais, a railing.
##   foundry.tscn (market): an advanced semiconductor fabrication cleanroom.

enum Look { SERVER_FARM, MENSA, SENATE, FOUNDRY }

@export var look: Look = Look.SERVER_FARM

var _materials := {}
## Blinking rack lights: [material, base energy, rate, phase].
var _blinkers: Array = []
## Press camera flashes: [light, base energy].
var _flashers: Array = []
var _flash_timer := 0.0
var _time := 0.0


func _ready() -> void:
	match look:
		Look.SERVER_FARM:
			_build_server_farm()
		Look.MENSA:
			_build_mensa()
		Look.SENATE:
			_build_senate()
		Look.FOUNDRY:
			_build_foundry()
	set_process(not _blinkers.is_empty() or not _flashers.is_empty())


func _process(delta: float) -> void:
	_time += delta
	for blinker: Array in _blinkers:
		var on := sin(_time * blinker[2] + blinker[3]) > -0.3
		(blinker[0] as StandardMaterial3D).emission_energy_multiplier = blinker[1] if on else blinker[1] * 0.15
	if not _flashers.is_empty():
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			_flash_timer = randf_range(1.6, 4.2)
			var flasher: Array = _flashers[randi() % _flashers.size()]
			var light: OmniLight3D = flasher[0]
			light.light_energy = flasher[1] * 4.5
			if light.has_meta(&"flash_tween"):
				var prev_tw = light.get_meta(&"flash_tween")
				if is_instance_valid(prev_tw) and prev_tw.is_running():
					prev_tw.kill()
			var tw := create_tween()
			light.set_meta(&"flash_tween", tw)
			tw.tween_property(light, "light_energy", 0.0, 0.14).set_ease(Tween.EASE_OUT)


# --- Server Farm (the rooftop) ---------------------------------------------------------

func _build_server_farm() -> void:
	var stage := get_parent()
	_relabel(stage, "NeonFight", "GPU FARM")
	_relabel(stage, "NeonNight", "ZONE 7")
	# Strip rooftop rain, residential water tank, old AC units, patio string lights, and helipad batches.
	for node_name in [
		"Rain", "Sound", "DoorLamp",
		"WaterTank", "WaterTankRoof", "TankBand34", "TankBand43", "TankBand52",
		"Fan11", "@MeshInstance3D@2", "@MeshInstance3D@3", "@MeshInstance3D@4",
		"Geometry/Batch1", "Geometry/Batch4", "Geometry/Batch5"
	]:
		_remove(stage, node_name)
	_ambience("res://assets/audio/ambience/city_traffic.ogg", -26.0)

	# Keep server_farm.tscn's environment (sky, SSR, fog, tonemap); duplicate so Settings can tweak it.
	var we := stage.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if we and we.environment:
		we.environment = we.environment.duplicate()

	_server_farm_build_floor()
	_server_farm_build_racks()
	_server_farm_build_cable_trays()
	_server_farm_build_cooling()
	_server_farm_build_consoles()
	_server_farm_build_skyline()

	# Focused rooftop datacenter lighting (kept lean for 60 fps on integrated GPUs)
	_light(Vector3(0.0, 3.2, -3.6), Color(0.70, 0.88, 1.0), 2.0, 11.0)
	_light(Vector3(-4.8, 2.4, -4.0), Color(0.10, 0.78, 1.0), 1.8, 7.5)
	_light(Vector3(4.8, 2.4, -4.0), Color(0.10, 0.85, 0.65), 1.8, 7.5)
	_light(Vector3(0.0, 2.2, -8.5), Color(0.25, 0.65, 1.0), 1.6, 8.5)


func _server_farm_build_floor() -> void:
	# Wet anti-skid raised floor using rooftop's wet_deck shader for organic mirror puddles.
	var floor_mat := ShaderMaterial.new()
	floor_mat.shader = load("res://assets/stages/rooftop/wet_deck.gdshader")
	var diff_path := _resolve_tex_path("res://assets/stage_props/server_farm/Textures/anti_skid_tiles_diff_1k.jpg")
	var nor_path := _resolve_tex_path("res://assets/stage_props/server_farm/Textures/anti_skid_tiles_nor_1k.jpg")
	var rough_path := _resolve_tex_path("res://assets/stage_props/server_farm/Textures/anti_skid_tiles_rough_1k.jpg")
	if not diff_path.is_empty():
		floor_mat.set_shader_parameter("albedo_tex", load(diff_path))
	if not nor_path.is_empty():
		floor_mat.set_shader_parameter("normal_tex", load(nor_path))
	if not rough_path.is_empty():
		floor_mat.set_shader_parameter("rough_tex", load(rough_path))
	floor_mat.set_shader_parameter("textured", true)
	floor_mat.set_shader_parameter("tint", Color(0.56, 0.62, 0.72))
	floor_mat.set_shader_parameter("tiling", 0.65)
	floor_mat.set_shader_parameter("dry_roughness", 0.52)
	floor_mat.set_shader_parameter("ao_strength", 0.0)
	floor_mat.set_shader_parameter("wetness", 0.65)
	floor_mat.set_shader_parameter("puddles", 0.52)
	floor_mat.set_shader_parameter("ripples", 0.05)
	_box(Vector3(24.0, 0.02, 20.0), Vector3(0.0, 0.01, -2.0), floor_mat)

	# Raised floor tile seam grid
	var seam_mat := _mat(Color(0.05, 0.06, 0.08), 0.45, 0.65)
	for x in range(-10, 11, 2):
		_box(Vector3(0.025, 0.024, 18.0), Vector3(x, 0.012, -2.0), seam_mat)
	for z in range(-10, 7, 2):
		_box(Vector3(22.0, 0.024, 0.025), Vector3(0.0, 0.012, z), seam_mat)

	# Cold-aisle floor grating strip in front of the rack pods
	var grate_frame := _mat(Color(0.14, 0.16, 0.19), 0.35, 0.8)
	var under_glow := _glow(Color(0.08, 0.78, 1.0), 1.8)
	for gx in [-5.1, 5.1]:
		_box(Vector3(4.8, 0.018, 0.75), Vector3(gx, 0.013, -4.15), grate_frame)
		_box(Vector3(4.6, 0.01, 0.06), Vector3(gx, 0.018, -4.15), under_glow)
		for slat in range(-10, 11):
			_box(Vector3(0.03, 0.022, 0.70), Vector3(gx + slat * 0.22, 0.013, -4.15), seam_mat)

	# Subtle wet-deck safety edge markings (fight zone boundary)
	var strip_cyan := _glow(Color(0.1, 0.8, 1.0), 1.9)
	var strip_amber := _glow(Color(1.0, 0.62, 0.1), 1.7)
	_box(Vector3(16.0, 0.01, 0.045), Vector3(0.0, 0.02, -3.6), strip_cyan)
	_box(Vector3(16.0, 0.01, 0.045), Vector3(0.0, 0.02, 3.6), strip_cyan)
	for x in [-7.8, 7.8]:
		_box(Vector3(0.045, 0.01, 7.2), Vector3(x, 0.02, 0.0), strip_amber)


func _server_farm_build_racks() -> void:
	# Shared blinking LED materials (kept to 8 for low draw/state overhead)
	var led_colors := [
		Color(0.10, 1.00, 0.35),
		Color(0.10, 0.80, 1.00),
		Color(1.00, 0.65, 0.10),
		Color(0.15, 0.95, 0.65),
		Color(1.00, 0.22, 0.15),
		Color(0.20, 0.72, 1.00),
	]
	var led_mats: Array = []
	for i in 8:
		var m := _glow(led_colors[i % led_colors.size()], 3.4, true)
		_blinkers.append([m, 3.4, 2.0 + i * 1.15, i * 1.37])
		led_mats.append(m)

	var steady_cyan := _glow(Color(0.12, 0.85, 1.0), 2.6)
	var steady_green := _glow(Color(0.15, 0.95, 0.4), 2.4)
	var cabinet_mat := _mat(Color(0.07, 0.08, 0.10), 0.38, 0.75)
	var recess_mat := _mat(Color(0.04, 0.045, 0.055), 0.55, 0.4)
	var blade_dark := _mat(Color(0.13, 0.145, 0.17), 0.28, 0.82)
	var blade_light := _mat(Color(0.20, 0.22, 0.26), 0.25, 0.85)
	var rail_mat := _mat(Color(0.42, 0.45, 0.50), 0.22, 0.90)
	var bay_mat := _mat(Color(0.06, 0.065, 0.075), 0.45, 0.6)
	var port_blue := _mat(Color(0.10, 0.55, 0.95), 0.3, 0.4)
	var port_red := _mat(Color(0.88, 0.22, 0.14), 0.3, 0.4)

	# Front Row A: Left Pod & Right Pod leaving an open central corridor
	var rack_idx := 0
	var front_xs := [-6.85, -5.65, -4.45, -3.25, 3.25, 4.45, 5.65, 6.85]
	for x in front_xs:
		_server_farm_rack(
			Vector3(x, 0.0, -5.2), rack_idx, led_mats,
			cabinet_mat, recess_mat, blade_dark, blade_light,
			rail_mat, bay_mat, steady_cyan, steady_green)
		rack_idx += 1

	# Back Row B behind Pods A & B for real hot-aisle depth
	var back_xs := [-6.25, -5.05, -3.85, 3.85, 5.05, 6.25]
	for x in back_xs:
		_server_farm_rack(
			Vector3(x, 0.0, -7.6), rack_idx, led_mats,
			cabinet_mat, recess_mat, blade_dark, blade_light,
			rail_mat, bay_mat, steady_cyan, steady_green)
		rack_idx += 1

	# Liquid-cooling vertical CDU manifolds on the inner aisle ends of Pods A & B
	for side_x in [-2.60, 2.60]:
		_box(Vector3(0.24, 2.05, 0.88), Vector3(side_x, 1.025, -5.2), cabinet_mat)
		_cylinder(0.045, 2.1, Vector3(side_x, 1.05, -4.85), port_blue)
		_cylinder(0.045, 2.1, Vector3(side_x, 1.05, -5.00), port_red)
		_box(Vector3(0.14, 0.22, 0.02), Vector3(side_x, 1.45, -4.75), steady_cyan)

	# Lightly tinted cold-aisle glass containment doors framing the central walkway (leaves center open)
	var glass_mat := _mat(Color(0.55, 0.82, 1.0, 0.13), 0.05, 0.1)
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for gx: float in [-2.35, 2.35]:
		var dir: float = 1.0 if gx < 0.0 else -1.0
		_box(Vector3(0.05, 2.15, 0.06), Vector3(gx, 1.075, -4.72), rail_mat)
		_box(Vector3(0.52, 2.08, 0.02), Vector3(gx + dir * 0.27, 1.04, -4.72), glass_mat)
	# Overhead pod nameplates mounted directly to the front pod headers
	for pod_x: float in [-5.05, 5.05]:
		var is_a: bool = pod_x < 0.0
		_box(Vector3(3.4, 0.26, 0.06), Vector3(pod_x, 2.24, -4.72), cabinet_mat)
		_box(Vector3(3.4, 0.02, 0.07), Vector3(pod_x, 2.11, -4.72), steady_cyan)
		var pod_text: String = "GPU POD A // H100 CLUSTER" if is_a else "GPU POD B // 800Gb/s RoCE"
		_label(pod_text, Vector3(pod_x, 2.24, -4.68), 0.14, Color(0.55, 0.94, 1.0), true)

	# Central network core & liquid-cooling manifold (compact so flanking chillers read clearly)
	_box(Vector3(0.95, 1.48, 0.82), Vector3(0.0, 0.74, -7.7), cabinet_mat)
	_box(Vector3(1.02, 0.05, 0.88), Vector3(0.0, 1.50, -7.7), rail_mat)
	for b in 5:
		var sy: float = 0.28 + b * 0.24
		_box(Vector3(0.78, 0.18, 0.03), Vector3(0.0, sy, -7.28), blade_dark if b % 2 == 0 else blade_light)
		_box(Vector3(0.32, 0.022, 0.015), Vector3(-0.16, sy, -7.26), steady_cyan if b % 2 == 0 else steady_green)
		_box(Vector3(0.18, 0.022, 0.015), Vector3(0.20, sy, -7.26), led_mats[b % led_mats.size()])
	for mx in [-0.58, 0.58]:
		_cylinder(0.04, 1.52, Vector3(mx, 0.76, -7.5), port_blue if mx < 0.0 else port_red)
	_box(Vector3(2.1, 0.30, 0.05), Vector3(0.0, 1.70, -7.55), cabinet_mat)
	_label("CRITICAL INFRASTRUCTURE\nDO NOT INTERRUPT TRAINING RUN", Vector3(0.0, 1.70, -7.51), 0.10, Color(1.0, 0.84, 0.22), true)


func _server_farm_rack(
	base_pos: Vector3,
	rack_idx: int,
	led_mats: Array,
	cabinet_mat: Material,
	recess_mat: Material,
	blade_dark: Material,
	blade_light: Material,
	rail_mat: Material,
	bay_mat: Material,
	steady_cyan: Material,
	steady_green: Material
) -> void:
	# Cabinet shell: 1.04m wide x 2.10m tall x 1.00m deep, recessed front bay so blades/LEDs pop
	_box(Vector3(1.04, 2.10, 0.92), base_pos + Vector3(0.0, 1.05, -0.04), cabinet_mat)
	_box(Vector3(0.94, 1.96, 0.02), base_pos + Vector3(0.0, 1.04, 0.43), recess_mat)

	# Brushed steel vertical side posts & top/bottom door frame bars (no opaque panel covering blades!)
	for rx in [-0.49, 0.49]:
		_box(Vector3(0.05, 2.08, 0.08), base_pos + Vector3(rx, 1.05, 0.44), rail_mat)
	_box(Vector3(1.04, 0.08, 0.10), base_pos + Vector3(0.0, 2.06, 0.44), cabinet_mat)
	_box(Vector3(1.04, 0.08, 0.10), base_pos + Vector3(0.0, 0.04, 0.44), cabinet_mat)

	# 8 stacked 2U/4U GPU compute blades inside the open front bay
	for b in 8:
		var by := 0.20 + b * 0.21
		var b_mat := blade_dark if (b % 2 == 0) else blade_light
		_box(Vector3(0.88, 0.17, 0.04), base_pos + Vector3(0.0, by, 0.44), b_mat)
		# Drive bays / cooling intake louver block on left half
		_box(Vector3(0.42, 0.11, 0.015), base_pos + Vector3(-0.20, by, 0.465), bay_mat)
		for d in 3:
			_box(Vector3(0.015, 0.09, 0.01), base_pos + Vector3(-0.34 + d * 0.11, by, 0.472), rail_mat)
		# Crisp status LED cluster on right half
		_box(Vector3(0.05, 0.022, 0.012), base_pos + Vector3(0.08, by + 0.03, 0.466), steady_green)
		for k in 3:
			var led_mat: Material = led_mats[(rack_idx * 3 + b * 2 + k) % led_mats.size()]
			_box(Vector3(0.042, 0.020, 0.012), base_pos + Vector3(0.17 + k * 0.075, by + (0.03 if k % 2 == 0 else -0.025), 0.466), led_mat)

	# Top-of-Rack (ToR) network switch at U42 with dense cyan/green link LEDs
	_box(Vector3(0.88, 0.11, 0.05), base_pos + Vector3(0.0, 1.91, 0.445), rail_mat)
	for p in 5:
		var p_mat := steady_cyan if (p % 2 == 0) else steady_green
		_box(Vector3(0.032, 0.022, 0.012), base_pos + Vector3(-0.32 + p * 0.075, 1.91, 0.474), p_mat)
	# Vertical patch-cable management bundle running up right side of bay
	_box(Vector3(0.03, 1.65, 0.025), base_pos + Vector3(0.43, 1.04, 0.46), steady_cyan)


func _server_farm_build_cable_trays() -> void:
	var tray_mat := _mat(Color(0.30, 0.33, 0.38), 0.32, 0.85)
	var post_mat := _mat(Color(0.18, 0.20, 0.23), 0.4, 0.8)
	var fiber_cyan := _mat(Color(0.06, 0.78, 1.0), 0.28)
	var fiber_yellow := _mat(Color(0.98, 0.78, 0.12), 0.28)
	var power_orange := _mat(Color(0.95, 0.34, 0.08), 0.32)

	# Overhead ladder cable trays directly above Pods A & B (leaves central GPU FARM sign clear)
	for pod in [[-5.05, 4.9], [5.05, 4.9]]:
		var px: float = pod[0]
		var pw: float = pod[1]
		for row_z: float in [-5.2, -7.6]:
			# Side rails of ladder tray
			for sz: float in [-0.26, 0.26]:
				_box(Vector3(pw, 0.07, 0.04), Vector3(px, 2.50, row_z + sz), tray_mat)
			# Ladder cross-rungs every 0.45m
			var rung_count := int(pw / 0.45)
			for r in rung_count:
				var rx: float = px - pw * 0.46 + r * 0.45
				_box(Vector3(0.035, 0.035, 0.52), Vector3(rx, 2.48, row_z), tray_mat)
			# Stanchion posts anchoring tray to rack roofs
			for sx: float in [-pw * 0.42, 0.0, pw * 0.42]:
				_box(Vector3(0.05, 0.40, 0.05), Vector3(px + sx, 2.30, row_z), post_mat)
			# Colored fiber-optic & power cable looms inside the tray
			_box(Vector3(pw - 0.1, 0.045, 0.07), Vector3(px, 2.53, row_z - 0.13), fiber_cyan)
			_box(Vector3(pw - 0.1, 0.045, 0.07), Vector3(px, 2.53, row_z), fiber_yellow)
			_box(Vector3(pw - 0.1, 0.045, 0.07), Vector3(px, 2.53, row_z + 0.13), power_orange)
		# Transverse bridge trays connecting front Row A to back Row B over each pod
		for bx: float in [px - 1.2, px + 1.2]:
			_box(Vector3(0.48, 0.05, 2.4), Vector3(bx, 2.54, -6.4), tray_mat)
			_box(Vector3(0.07, 0.04, 2.4), Vector3(bx - 0.11, 2.57, -6.4), fiber_cyan)
			_box(Vector3(0.07, 0.04, 2.4), Vector3(bx + 0.11, 2.57, -6.4), fiber_yellow)

	# Vertical fiber waterfall drops from tray into the rack tops
	for dx: float in [-6.5, -5.3, -4.1, -2.9, 2.9, 4.1, 5.3, 6.5]:
		_box(Vector3(0.065, 0.42, 0.055), Vector3(dx, 2.31, -5.05), fiber_cyan)
		_box(Vector3(0.055, 0.42, 0.055), Vector3(dx + 0.08, 2.31, -5.05), fiber_yellow)

	# Low floor-level armored cable trench linking Pods A & B to the central manifold (unobstructed sky)
	_box(Vector3(5.6, 0.04, 0.36), Vector3(0.0, 0.02, -7.7), tray_mat)
	_box(Vector3(5.4, 0.02, 0.06), Vector3(0.0, 0.045, -7.64), fiber_cyan)
	_box(Vector3(5.4, 0.02, 0.06), Vector3(0.0, 0.045, -7.76), power_orange)


func _server_farm_build_cooling() -> void:
	var chiller_mat := _mat(Color(0.32, 0.35, 0.40), 0.35, 0.78)
	var trim_mat := _mat(Color(0.14, 0.16, 0.19), 0.35, 0.85)
	var louver_mat := _mat(Color(0.07, 0.08, 0.09), 0.55, 0.6)
	var frost_pipe := _mat(Color(0.76, 0.82, 0.88), 0.25, 0.85)
	var cold_band := _mat(Color(0.12, 0.62, 0.95), 0.3, 0.5)
	var hazard_mat := _mat(Color(0.95, 0.65, 0.08), 0.45)
	var beacon_amber := _glow(Color(1.0, 0.55, 0.05), 3.6, true)
	var beacon_red := _glow(Color(1.0, 0.12, 0.10), 3.6, true)
	_blinkers.append([beacon_amber, 3.6, 3.4, 0.0])
	_blinkers.append([beacon_red, 3.6, 4.1, 1.4])

	# Twin flanking rooftop CRAC chiller towers visible on the left/right edges
	for x: float in [-7.9, 7.9]:
		var inward: float = 1.0 if x < 0.0 else -1.0
		_server_farm_chiller_unit(
			Vector3(x, 0.0, -6.3), Vector3(1.55, 2.20, 2.0), inward,
			chiller_mat, trim_mat, louver_mat, hazard_mat, beacon_amber, beacon_red)
		# Insulated chilled-water pipe run feeding into Pods A & B
		_cylinder(0.14, 1.85, Vector3(x + inward * 0.88, 0.95, -5.2), frost_pipe)
		_cylinder(0.155, 0.12, Vector3(x + inward * 0.88, 1.45, -5.2), cold_band)
		_box(Vector3(1.1, 0.18, 0.18), Vector3(x + inward * 1.05, 1.82, -5.2), frost_pipe)

	# Twin industrial rooftop cooling towers visible in the central corridor beside the manifold
	for bx: float in [-1.25, 1.25]:
		_server_farm_chiller_unit(
			Vector3(bx, 0.0, -8.3), Vector3(1.15, 1.72, 1.25), 0.0,
			chiller_mat, trim_mat, louver_mat, hazard_mat, beacon_amber, beacon_red)
		_cylinder(0.09, 1.3, Vector3(bx * 0.62, 0.68, -7.9), frost_pipe)
		_cylinder(0.105, 0.09, Vector3(bx * 0.62, 0.98, -7.9), cold_band)


func _server_farm_chiller_unit(
	pos: Vector3,
	size: Vector3,
	inward: float,
	body_mat: Material,
	trim_mat: Material,
	louver_mat: Material,
	hazard_mat: Material,
	beacon_a: Material,
	beacon_b: Material
) -> void:
	# Concrete/steel equipment plinth
	_box(Vector3(size.x + 0.16, 0.14, size.z + 0.16), pos + Vector3(0, 0.07, 0), trim_mat)
	_box(Vector3(size.x + 0.18, 0.05, size.z + 0.18), pos + Vector3(0, 0.14, 0), hazard_mat)
	# Main insulated housing
	_box(size, pos + Vector3(0, size.y * 0.5 + 0.14, 0), body_mat)
	# Front & inward intake louver slats
	var slat_y0 := pos.y + 0.42
	for s in 7:
		_box(Vector3(size.x * 0.78, 0.06, 0.04), Vector3(pos.x, slat_y0 + s * 0.18, pos.z + size.z * 0.51), louver_mat)
		if absf(inward) > 0.1:
			_box(Vector3(0.04, 0.06, size.z * 0.76), Vector3(pos.x + inward * size.x * 0.51, slat_y0 + s * 0.18, pos.z), louver_mat)

	# Twin top exhaust fan shrouds with blades, warning beacons, and billowing steam plumes
	var top_y: float = pos.y + size.y + 0.14
	var fan_offsets: Array = [Vector3(0, 0, -size.z * 0.24), Vector3(0, 0, size.z * 0.24)] if absf(inward) > 0.1 else [Vector3(-size.x * 0.24, 0, 0), Vector3(size.x * 0.24, 0, 0)]
	for idx in fan_offsets.size():
		var fpos: Vector3 = pos + Vector3(0, top_y, 0) + (fan_offsets[idx] as Vector3)
		_cylinder(0.42, 0.22, fpos + Vector3(0, 0.11, 0), trim_mat)
		_cylinder(0.36, 0.04, fpos + Vector3(0, 0.18, 0), louver_mat)
		# Fan hub and cross-blades inside shroud
		_cylinder(0.10, 0.08, fpos + Vector3(0, 0.21, 0), body_mat)
		for b in 2:
			var blade := _box(Vector3(0.66, 0.02, 0.08), fpos + Vector3(0, 0.21, 0), body_mat)
			blade.rotation_degrees = Vector3(12, b * 90.0 + 25.0, 0)
		# Strobe beacon on shroud rim
		var b_pos: Vector3 = fpos + Vector3(inward * 0.38 if absf(inward) > 0.1 else 0.0, 0.28, 0.32 if absf(inward) < 0.1 else 0.0)
		_cylinder(0.055, 0.14, b_pos, beacon_a if idx == 0 else beacon_b)
		# Dense visible steam plume
		_server_farm_steam(fpos + Vector3(0, 0.25, 0))


func _server_farm_steam(pos: Vector3) -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 0.24
	mat.direction = Vector3(0.06, 1.0, 0.0)
	mat.spread = 16.0
	mat.initial_velocity_min = 0.65
	mat.initial_velocity_max = 1.20
	mat.gravity = Vector3(0.03, 0.08, 0.0)
	mat.scale_min = 0.7
	mat.scale_max = 1.65
	var grad := Gradient.new()
	grad.set_color(0, Color(0.76, 0.88, 1.0, 0.0))
	grad.add_point(0.20, Color(0.80, 0.91, 1.0, 0.28))
	grad.add_point(0.60, Color(0.72, 0.85, 1.0, 0.14))
	grad.set_color(1, Color(0.65, 0.80, 1.0, 0.0))
	var ramp := GradientTexture1D.new()
	ramp.gradient = grad
	mat.color_ramp = ramp
	particles.process_material = mat
	particles.amount = 22
	particles.lifetime = 2.4
	particles.preprocess = 1.8

	# Soft radial cloud sprite texture so steam puffs look wispy instead of hard circles
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	for py in 32:
		for px in 32:
			var dx: float = (px + 0.5) / 16.0 - 1.0
			var dy: float = (py + 0.5) / 16.0 - 1.0
			var r2: float = clampf(dx * dx + dy * dy, 0.0, 1.0)
			var falloff: float = pow(1.0 - r2, 2.4)
			img.set_pixel(px, py, Color(1.0, 1.0, 1.0, falloff))
	var puff_tex := ImageTexture.create_from_image(img)

	var quad := QuadMesh.new()
	quad.size = Vector2(1.05, 1.05)
	var smat := StandardMaterial3D.new()
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	smat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	smat.billboard_keep_scale = true
	smat.vertex_color_use_as_albedo = true
	smat.albedo_texture = puff_tex
	smat.albedo_color = Color(0.85, 0.93, 1.0, 0.9)
	quad.material = smat
	particles.draw_pass_1 = quad
	particles.position = pos
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(particles)
	return particles


func _server_farm_build_consoles() -> void:
	# Sleek dark-anodized rolling NOC diagnostic workstations flanking the stage (near sysadmins at x=±8.4, z=-4.2)
	var cart_mat := _mat(Color(0.11, 0.12, 0.14), 0.32, 0.82)
	var trim_mat := _mat(Color(0.35, 0.38, 0.42), 0.25, 0.88)
	var screen_glow := _glow(Color(0.08, 0.82, 0.98), 2.1)
	for cx: float in [-7.55, 7.55]:
		var yaw: float = 24.0 if cx < 0.0 else -24.0
		var pivot := Node3D.new()
		pivot.position = Vector3(cx, 0.0, -3.75)
		pivot.rotation_degrees = Vector3(0.0, yaw, 0.0)
		add_child(pivot)
		_box(Vector3(0.95, 0.88, 0.56), Vector3(0.0, 0.48, 0.0), cart_mat, pivot)
		_box(Vector3(1.0, 0.04, 0.60), Vector3(0.0, 0.94, 0.0), trim_mat, pivot)
		# Dual angled telemetry monitors
		_box(Vector3(0.68, 0.40, 0.03), Vector3(0.0, 1.24, -0.10), cart_mat, pivot)
		_box(Vector3(0.62, 0.34, 0.015), Vector3(0.0, 1.24, -0.08), screen_glow, pivot)
		_box(Vector3(0.45, 0.02, 0.16), Vector3(0.0, 0.97, 0.10), trim_mat, pivot)
		var lbl := _label("CLUSTER ONLINE\nPUE: 1.09 | 14°C\n40960 GPUs SYNCED", Vector3(0.0, 1.24, -0.068), 0.06, Color(0.92, 1.0, 1.0), true)
		lbl.get_parent().remove_child(lbl)
		pivot.add_child(lbl)


func _server_farm_build_skyline() -> void:
	# Distant silhouetted city towers flanking the rooftop with subtle sparse window lights
	var tower_mat := _mat(Color(0.025, 0.035, 0.06), 0.85, 0.15)
	var win_warm := _glow(Color(1.0, 0.76, 0.42), 1.05)
	var win_cyan := _glow(Color(0.32, 0.78, 1.0), 0.95)
	var beacon_mat := _glow(Color(1.0, 0.14, 0.10), 3.2)

	var towers := [
		[-14.2, -23.0, 3.8, 11.5, 3.0, true],
		[-10.4, -26.0, 3.2, 12.8, 2.8, false],
		[10.6, -25.0, 3.2, 13.0, 2.8, true],
		[14.4, -22.5, 3.8, 11.0, 3.0, false],
	]
	for t: Array in towers:
		var tx: float = t[0]
		var tz: float = t[1]
		var tw: float = t[2]
		var th: float = t[3]
		var td: float = t[4]
		var warm: bool = t[5]
		_box(Vector3(tw, th, td), Vector3(tx, th * 0.5 - 4.5, tz), tower_mat)
		var wmat: Material = win_warm if warm else win_cyan
		# Irregular tiny office window lights
		for row in 7:
			var wy: float = 1.0 + row * 0.9
			if wy > th - 4.8:
				continue
			for col in 4:
				if ((row * 3 + col * 5) % 7) > 2:
					continue
				var wx: float = tx + (col - 1.5) * (tw * 0.21)
				_box(Vector3(0.20, 0.09, 0.04), Vector3(wx, wy, tz + td * 0.5 + 0.02), wmat)
		if th >= 12.5:
			_cylinder(0.04, 1.2, Vector3(tx, th - 4.0, tz), tower_mat)
			_box(Vector3(0.15, 0.15, 0.15), Vector3(tx, th - 3.35, tz), beacon_mat)

	# Rooftop parapet edge security markers along the rear safety wall
	var edge_amber := _glow(Color(1.0, 0.52, 0.08), 1.6)
	for rx in range(-10, 11, 4):
		_box(Vector3(0.14, 0.08, 0.14), Vector3(rx, 1.16, -12.8), edge_amber)


# --- Mensa (the dojo) ------------------------------------------------------------------

func _build_mensa() -> void:
	var stage := get_parent()
	for name in ["ScrollKanji", "ScrollSeal", "TaikoDrum", "TaikoSkin1", "TaikoSkin2", "Students0", "Students1", "Students3",
			"IncenseSmoke", "Lantern00", "Lantern01", "Lantern10", "Lantern11",
			"AndonL", "AndonR", "LanternLight00", "LanternLight01", "LanternLight10", "LanternLight11", "CandleFlicker"]:
		_remove(stage, name)

	# Respect Settings graphics presets without a compile-time autoload dependency (sim_test).
	var we := stage.get_node_or_null("WorldEnvironment") as WorldEnvironment
	var settings := get_node_or_null("/root/Settings")
	if we and we.environment and settings and int(settings.get("graphics")) != 2:
		we.environment = we.environment.duplicate()
		we.environment.ssao_enabled = false

	# Reflection probe for linoleum/ceramic floor and brushed steel counter reflections
	var probe := ReflectionProbe.new()
	probe.name = "MensaReflectionProbe"
	probe.size = Vector3(26.0, 8.0, 22.0)
	probe.origin_offset = Vector3(0.0, 2.5, -4.0)
	probe.update_mode = ReflectionProbe.UPDATE_ONCE
	probe.intensity = 0.75
	probe.max_distance = 30.0
	probe.ambient_mode = ReflectionProbe.AMBIENT_COLOR
	probe.ambient_color = Color(0.18, 0.19, 0.21)
	add_child(probe)

	# Linoleum / ceramic tiles over the tatami (PBR with normal and roughness maps).
	var tiles: StandardMaterial3D = _pbr_texture_mat(
		"res://assets/stage_props/mensa/floor/floor_tiles_06_diff_1k.jpg",
		"res://assets/stage_props/mensa/floor/floor_tiles_06_nor_1k.jpg",
		"res://assets/stage_props/mensa/floor/floor_tiles_06_rough_1k.jpg",
		Vector3(14, 12, 1), 0.38)
	tiles.albedo_color = Color(0.76, 0.74, 0.70)
	if tiles.albedo_texture == null:
		tiles.albedo_texture = _checker(Color(0.62, 0.6, 0.55), Color(0.55, 0.56, 0.54))
		tiles.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
		tiles.uv1_scale = Vector3(44, 36, 1)
	_box(Vector3(22.0, 0.02, 18.0), Vector3(0, 0.01, -1.0), tiles)
	# Subtle floor zone trim separating the fight arena from the dining rows
	_box(Vector3(18.0, 0.004, 0.10), Vector3(0, 0.022, -4.15), _mat(Color(0.28, 0.24, 0.21), 0.75))

	_mensa_backdrop()
	_mensa_counter()
	_mensa_tables()
	_mensa_lighting()
	_ambience("res://assets/audio/ambience/market_chatter.ogg", -20.0)


func _mensa_backdrop() -> void:
	# Architectural back wall: warm oak paneling + dark slate cafeteria header fascia (covers dojo scroll & shrine)
	var oak := _mat(Color(0.42, 0.26, 0.15), 0.6)
	var slate := _mat(Color(0.13, 0.14, 0.16), 0.75)
	var trim := _mat(Color(0.62, 0.64, 0.67), 0.28, 0.85)
	_box(Vector3(5.4, 3.4, 0.16), Vector3(0.0, 1.7, -9.72), oak)
	_box(Vector3(18.0, 1.45, 0.22), Vector3(0.0, 4.12, -9.62), slate)
	_box(Vector3(18.0, 0.06, 0.26), Vector3(0.0, 3.38, -9.60), trim)
	_box(Vector3(18.0, 0.06, 0.26), Vector3(0.0, 4.86, -9.60), trim)
	# Warm glowing fascia accent & main MENSA sign
	_box(Vector3(4.6, 0.05, 0.06), Vector3(0.0, 3.56, -9.48), _glow(Color(1.0, 0.62, 0.22), 1.6))
	_label("MENSA", Vector3(0, 4.18, -9.45), 1.15, Color(1.0, 0.56, 0.22), true)

	# Framed menu & campus notice boards cleanly fitted inside the wall bays
	_mensa_board("TODAY'S MENU",
		"Pasta Pomodoro ........ 2,80\nVegan Lentil Curry .... 3,10\nCurrywurst & Fries .... 2,50\nAlignment Soup .... ask staff",
		Vector3(-3.6, 2.38, -9.60), Color(0.84, 0.36, 0.16))
	_mensa_board("EXAM SEASON",
		"Free espresso for anyone\nwho can explain\nbackpropagation clearly",
		Vector3(3.6, 2.38, -9.60), Color(0.24, 0.52, 0.42))
	_mensa_board("NEURIPS NOTICE",
		"Registration is full.\nPlease do not spar\nover poster slots.\nCoffee for authors only.",
		Vector3(-7.3, 2.38, -9.60), Color(0.28, 0.42, 0.62))
	_mensa_board("LOST & FOUND",
		"1x Quantum State\nAnswers to 'Schrodinger'\nReward: 8x H100 hours",
		Vector3(7.3, 2.38, -9.60), Color(0.72, 0.52, 0.18))


func _mensa_board(title: String, body: String, position_: Vector3, accent: Color) -> void:
	var frame := _mat(Color(0.36, 0.23, 0.14), 0.55)
	var board_mat := _mat(Color(0.06, 0.09, 0.08), 0.88)
	_box(Vector3(2.96, 1.48, 0.07), position_, frame)
	_box(Vector3(2.80, 1.32, 0.08), position_, board_mat)
	_box(Vector3(2.80, 0.24, 0.09), position_ + Vector3(0, 0.54, 0.0), _mat(accent, 0.5))

	var head := _label(title, position_ + Vector3(0.0, 0.54, 0.055), 0.14, Color(1.0, 0.96, 0.88), true)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var text_lbl := _label(body, position_ + Vector3(-1.26, -0.06, 0.055), 0.115, Color(0.94, 0.93, 0.86), true)
	text_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	text_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_lbl.width = 1050.0
	text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _mensa_counter() -> void:
	var steel := _mat(Color(0.68, 0.70, 0.73), 0.28, 0.85)
	var dark_steel := _mat(Color(0.20, 0.22, 0.25), 0.38, 0.75)
	var wood_front := _mat(Color(0.38, 0.24, 0.14), 0.58)

	# Modular kitchenBar cabinetry along the serving counter + warm oak front & stainless top
	for i in 7:
		_prop("res://assets/stage_props/mensa/kitchenBar.glb", Vector3(-3.8 + i * 1.03, 0.02, -8.32), Vector3.ZERO, Vector3(2.4, 2.2, 2.4))
	_prop("res://assets/stage_props/mensa/kitchenBarEnd.glb", Vector3(3.41, 0.02, -8.32), Vector3.ZERO, Vector3(2.4, 2.2, 2.4))
	_box(Vector3(7.6, 0.90, 0.06), Vector3(-0.1, 0.47, -8.30), wood_front)
	_box(Vector3(8.6, 0.06, 0.82), Vector3(0.1, 0.95, -8.56), steel)

	# Brushed steel tray slide rail along the front of the serving line
	for ry in [0.76, 0.82]:
		_box(Vector3(7.8, 0.02, 0.03), Vector3(-0.2, ry, -8.06), steel)
	for rx in [-3.8, -1.9, 0.0, 1.9, 3.6]:
		_box(Vector3(0.04, 0.03, 0.22), Vector3(rx, 0.78, -8.17), dark_steel)

	# Recessed bain-marie food wells & vivid dishes under a glass sneeze guard + warm heat lamp
	_box(Vector3(5.8, 0.03, 0.56), Vector3(-0.6, 0.97, -8.58), dark_steel)
	var foods := [
		Color(0.85, 0.28, 0.12), # tomato pasta
		Color(0.92, 0.72, 0.22), # schnitzel & fries
		Color(0.26, 0.58, 0.22), # fresh salad
		Color(0.88, 0.54, 0.14), # lentil curry
		Color(0.93, 0.90, 0.82), # mashed potatoes
		Color(0.68, 0.22, 0.30), # berry compote
	]
	for i in 6:
		var fx := -3.0 + i * 0.96
		_box(Vector3(0.84, 0.05, 0.44), Vector3(fx, 0.99, -8.58), steel)
		_box(Vector3(0.74, 0.06, 0.36), Vector3(fx, 1.00, -8.58), _mat(foods[i], 0.52))

	# Sneeze guard posts, angled glass shield, and warm under-canopy heat strip
	for px in [-3.5, -1.2, 1.2, 3.5]:
		_cylinder(0.025, 0.62, Vector3(px, 1.28, -8.24), steel)
	var glass := _mat(Color(0.82, 0.92, 1.0, 0.22), 0.05)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var shield := _box(Vector3(7.2, 0.44, 0.02), Vector3(0.0, 1.32, -8.22), glass)
	shield.rotation_degrees = Vector3(-16, 0, 0)
	_box(Vector3(7.2, 0.05, 0.24), Vector3(0.0, 1.56, -8.32), dark_steel)
	_box(Vector3(6.9, 0.025, 0.10), Vector3(0.0, 1.53, -8.34), _glow(Color(1.0, 0.78, 0.44), 2.2))

	# Tray pickup stack at left end of counter
	var tray_colors := [Color(0.22, 0.42, 0.54), Color(0.68, 0.32, 0.22), Color(0.28, 0.48, 0.36)]
	for ti in 6:
		_box(Vector3(0.46, 0.02, 0.32), Vector3(-3.95, 0.99 + ti * 0.025, -8.46), _mat(tray_colors[ti % tray_colors.size()], 0.45))
	for pi in 3:
		_prop("res://assets/stage_props/mensa/plate-dinner.glb", Vector3(-3.95, 0.98 + pi * 0.03, -8.80), Vector3.ZERO, Vector3(0.26, 0.26, 0.26))

	# Coffee & checkout station at the right end of counter (clear of cashier at x=4.2, z=-8.4)
	_prop("res://assets/stage_props/mensa/kitchenCoffeeMachine.glb", Vector3(3.0, 0.98, -8.38), Vector3(0, 180, 0), Vector3(2.3, 2.3, 2.3))
	_prop("res://assets/stage_props/mensa/cup-coffee.glb", Vector3(3.55, 0.98, -8.35), Vector3.ZERO, Vector3(0.42, 0.42, 0.42))
	_prop("res://assets/stage_props/mensa/cup-coffee.glb", Vector3(3.75, 0.98, -8.48), Vector3.ZERO, Vector3(0.42, 0.42, 0.42))
	_prop("res://assets/stage_props/mensa/plate-dinner.glb", Vector3(2.4, 0.98, -8.36), Vector3.ZERO, Vector3(0.28, 0.28, 0.28))
	_box(Vector3(0.46, 0.26, 0.34), Vector3(4.05, 1.10, -8.68), dark_steel)
	_box(Vector3(0.30, 0.16, 0.03), Vector3(4.05, 1.24, -8.52), _glow(Color(0.45, 0.90, 0.65), 1.4))

	# Cafeteria waste bins, potted plants, and supply boxes
	_prop("res://assets/stage_props/mensa/trashcan.glb", Vector3(-6.4, 0.02, -8.6), Vector3.ZERO, Vector3(2.0, 2.0, 2.0))
	_prop("res://assets/stage_props/mensa/trashcan.glb", Vector3(6.4, 0.02, -8.6), Vector3.ZERO, Vector3(2.0, 2.0, 2.0))
	_prop("res://assets/stage_props/mensa/pottedPlant.glb", Vector3(-8.4, 0.02, -7.1), Vector3.ZERO, Vector3(2.1, 2.1, 2.1))
	_prop("res://assets/stage_props/mensa/pottedPlant.glb", Vector3(8.4, 0.02, -7.1), Vector3.ZERO, Vector3(2.1, 2.1, 2.1))
	_prop("res://assets/stage_props/mensa/pottedPlant.glb", Vector3(-9.1, 0.02, 1.4), Vector3.ZERO, Vector3(2.0, 2.0, 2.0))
	_prop("res://assets/stage_props/mensa/pottedPlant.glb", Vector3(9.1, 0.02, 1.4), Vector3.ZERO, Vector3(2.0, 2.0, 2.0))
	_prop("res://assets/stage_props/mensa/cardboardBoxClosed.glb", Vector3(-8.8, 0.02, -8.4), Vector3(0, 22, 0), Vector3(1.9, 1.9, 1.9))


func _mensa_tables() -> void:
	var table_top := _mat(Color(0.86, 0.80, 0.70), 0.45)
	var steel := _mat(Color(0.66, 0.68, 0.72), 0.3, 0.82)
	var lamp_shade := _mat(Color(0.24, 0.22, 0.20), 0.35, 0.55)
	var lamp_rim := _mat(Color(0.85, 0.68, 0.40), 0.28, 0.8)
	var bulb_mat := _glow(Color(1.0, 0.88, 0.65), 2.4)
	var tray_colors := [Color(0.24, 0.42, 0.56), Color(0.68, 0.34, 0.24), Color(0.28, 0.48, 0.36)]
	var rng := RandomNumberGenerator.new()
	rng.seed = 7

	# Three long Mensa tables at the back row (aligned with stage_life student seats)
	for spot: Vector3 in [Vector3(-4.5, 0, -6.0), Vector3(0.0, 0, -6.0), Vector3(4.5, 0, -6.0)]:
		_prop("res://assets/stage_props/mensa/table.glb", spot + Vector3(-1.51, 0.02, 0.40), Vector3.ZERO, Vector3(1.8, 2.25, 1.8))
		_prop("res://assets/stage_props/mensa/table.glb", spot + Vector3(0.0, 0.02, 0.40), Vector3.ZERO, Vector3(1.8, 2.25, 1.8))
		_box(Vector3(3.08, 0.045, 0.88), spot + Vector3(0, 0.745, 0), table_top)
		_mensa_pendant(spot, lamp_shade, lamp_rim, bulb_mat)

		# Table condiment caddy with visible ketchup & mustard bottles
		_box(Vector3(0.18, 0.05, 0.22), spot + Vector3(0, 0.785, 0), steel)
		_prop("res://assets/stage_props/mensa/bottle-ketchup.glb", spot + Vector3(-0.045, 0.80, 0), Vector3.ZERO, Vector3(0.42, 0.42, 0.42))
		_prop("res://assets/stage_props/mensa/bottle-musterd.glb", spot + Vector3(0.045, 0.80, 0), Vector3.ZERO, Vector3(0.42, 0.42, 0.42))

		for k in 4:
			for side in [-1, 1]:
				var sx := -1.14 + k * 0.76
				var seat := spot + Vector3(sx, 0.02, side * 0.70)
				var chair_model := "res://assets/stage_props/mensa/chair.glb" if (k % 2 == 0) else "res://assets/stage_props/mensa/chairRounded.glb"
				# Chair GLBs have origin at (0,0,-0.2) corner, size 0.2x0.47x0.2 -> offset by half-width to center
				var cx_off := -0.22 if side == -1 else 0.22
				var cz_off := 0.22 if side == -1 else -0.22
				_prop(chair_model, seat + Vector3(cx_off, 0.0, cz_off), Vector3(0, 0 if side == -1 else 180, 0), Vector3(2.2, 1.9, 2.2))

				# Tray and tableware resting flush on tabletop (y = 0.768)
				var tray_pos := spot + Vector3(sx, 0.778, side * 0.24)
				_box(Vector3(0.46, 0.02, 0.32), tray_pos, _mat(tray_colors[(k + (1 if side > 0 else 0)) % tray_colors.size()], 0.48))
				_prop("res://assets/stage_props/mensa/plate-dinner.glb", tray_pos + Vector3(-0.04, 0.01, 0), Vector3.ZERO, Vector3(0.26, 0.26, 0.26))
				if rng.randf() < 0.65:
					_prop("res://assets/stage_props/mensa/cup-coffee.glb", tray_pos + Vector3(0.14, 0.01, 0.06), Vector3.ZERO, Vector3(0.40, 0.40, 0.40))
				if rng.randf() < 0.45:
					_prop("res://assets/stage_props/mensa/bowl.glb", tray_pos + Vector3(0.13, 0.01, -0.07), Vector3.ZERO, Vector3(0.30, 0.30, 0.30))

	# Two clean round cafe tables on the flanks (clear of standing stage_life students at z=-3.2)
	for side_x in [-7.4, 7.4]:
		var rspot := Vector3(side_x, 0.0, -1.6)
		_prop("res://assets/stage_props/mensa/tableRound.glb", rspot + Vector3(-0.69, 0.56, 0.80), Vector3.ZERO, Vector3(2.0, 2.0, 2.0))
		_mensa_pendant(rspot, lamp_shade, lamp_rim, bulb_mat)
		_prop("res://assets/stage_props/mensa/chairRounded.glb", rspot + Vector3(-0.78, 0.02, 0.22), Vector3(0, 90, 0), Vector3(2.1, 1.9, 2.1))
		_prop("res://assets/stage_props/mensa/chairRounded.glb", rspot + Vector3(0.78, 0.02, -0.22), Vector3(0, -90, 0), Vector3(2.1, 1.9, 2.1))
		_prop("res://assets/stage_props/mensa/cup-coffee.glb", rspot + Vector3(-0.22, 0.75, 0.12), Vector3.ZERO, Vector3(0.42, 0.42, 0.42))
		_prop("res://assets/stage_props/mensa/plate-dinner.glb", rspot + Vector3(0.20, 0.75, -0.10), Vector3.ZERO, Vector3(0.26, 0.26, 0.26))
		_prop("res://assets/stage_props/mensa/bottle-ketchup.glb", rspot + Vector3(0.0, 0.75, 0.22), Vector3.ZERO, Vector3(0.40, 0.40, 0.40))

	# Tray return trolley at the left flank (clear of student_8 at -8.2, -4.0)
	_box(Vector3(1.1, 1.4, 0.65), Vector3(-8.9, 0.72, -5.6), steel)
	for ty in [0.42, 0.77, 1.12]:
		_box(Vector3(0.92, 0.03, 0.52), Vector3(-8.9, ty, -5.6), _mat(Color(0.22, 0.30, 0.40)))
		_prop("res://assets/stage_props/mensa/plate.glb", Vector3(-8.9, ty + 0.02, -5.6), Vector3.ZERO, Vector3(0.28, 0.28, 0.28))
	_cylinder(0.14, 0.45, Vector3(-8.9, 1.65, -5.6), _mat(Color(0.85, 0.92, 0.98, 0.6), 0.1))


func _mensa_pendant(spot: Vector3, shade: Material, rim: Material, bulb: Material) -> void:
	_cylinder(0.012, 3.45, spot + Vector3(0, 4.25, 0), shade)
	_cylinder(0.26, 0.14, spot + Vector3(0, 2.52, 0), shade)
	_cylinder(0.28, 0.03, spot + Vector3(0, 2.44, 0), rim)
	_cylinder(0.14, 0.04, spot + Vector3(0, 2.43, 0), bulb)


func _mensa_lighting() -> void:
	# Warm ceiling light panels for overhead cafeteria rhythm
	var housing := _mat(Color(0.24, 0.25, 0.28), 0.4, 0.7)
	var panel := _glow(Color(1.0, 0.93, 0.78), 1.8)
	for cz in [-6.0, -1.5]:
		for cx in [-5.0, 0.0, 5.0]:
			_box(Vector3(2.2, 0.08, 0.75), Vector3(cx, 5.84, cz), housing)
			_box(Vector3(2.04, 0.04, 0.60), Vector3(cx, 5.79, cz), panel)

	# Warm lights over the three main dining tables & serving counter (replaces removed dojo lights)
	for lx in [-4.5, 0.0, 4.5]:
		_light(Vector3(lx, 2.35, -6.0), Color(1.0, 0.87, 0.66), 1.8, 5.2)
	for cx in [-2.0, 2.0]:
		_light(Vector3(cx, 2.25, -8.3), Color(1.0, 0.82, 0.56), 2.1, 5.5)
	# Cool-crisp window daylight bounce from the left side windows
	_light(Vector3(-8.2, 2.6, -2.5), Color(0.86, 0.93, 1.0), 1.6, 7.5)
	_light(Vector3(-8.2, 2.6, -6.5), Color(0.86, 0.93, 1.0), 1.4, 7.0)


# --- Senate Hearing Room (the ring) ----------------------------------------------------

func _build_senate() -> void:
	var stage := get_parent()
	var ring := stage.get_node_or_null("BoxingRing")
	if ring:
		for child in ring.get_children():
			if child.name.begins_with("Rope_") or child.name.begins_with("Corner_") or child.name.begins_with("Step_") \
					or child.name in ["LogoDisc", "LogoText"]:
				child.queue_free()
		var canvas := ring.get_node_or_null("Canvas") as MeshInstance3D
		if canvas:
			canvas.material_override = _mat(Color(0.1, 0.13, 0.32), 0.9)
		var apron := ring.get_node_or_null("Apron") as MeshInstance3D
		if apron:
			apron.material_override = _mat(Color(0.32, 0.18, 0.09), 0.5)
		var banners := ["HEARING ON AI OVERSIGHT", "PLEASE REMAIN SEATED", "NO PHOTOGRAPHY (PLEASE)", "TESTIMONY IN PROGRESS"]
		for i in 4:
			var banner := ring.get_node_or_null("ApronBanner%d" % i) as Label3D
			if banner:
				banner.text = banners[i]

	# The public gallery in hearing-room clothes (dark suits, a few white shirts) instead of
	# the arena's bright jerseys.
	var crowd := stage.get_node_or_null("Crowd") as Crowd
	if crowd:
		crowd.palette = PackedColorArray([Color(0.06, 0.07, 0.1), Color(0.1, 0.1, 0.12), Color(0.14, 0.12, 0.1),
			Color(0.05, 0.08, 0.16), Color(0.55, 0.55, 0.58), Color(0.2, 0.06, 0.07)])
		if crowd.multimesh:
			crowd._ready() # already built with the arena colors: rebuild

	# Environment atmosphere pass: stately hearing room fog
	var we := stage.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if we and we.environment:
		we.environment = we.environment.duplicate()
		we.environment.tonemap_mode = Environment.TONE_MAPPER_ACES
		we.environment.tonemap_exposure = 0.95
		we.environment.glow_enabled = true
		we.environment.glow_bloom = 0.18
		we.environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
		we.environment.adjustment_enabled = true
		we.environment.adjustment_contrast = 1.20
		we.environment.adjustment_saturation = 1.10
		we.environment.volumetric_fog_enabled = true
		we.environment.volumetric_fog_albedo = Color(0.85, 0.78, 0.65)
		we.environment.volumetric_fog_density = 0.0035

	# Reflection probe for polished mahogany and brass specular reflections
	var probe := ReflectionProbe.new()
	probe.name = "SenateReflectionProbe"
	probe.size = Vector3(22.0, 7.0, 18.0)
	probe.origin_offset = Vector3(0.0, 2.5, -4.0)
	probe.update_mode = ReflectionProbe.UPDATE_ONCE
	probe.intensity = 0.75
	probe.max_distance = 30.0
	probe.ambient_mode = ReflectionProbe.AMBIENT_COLOR
	probe.ambient_color = Color(0.2, 0.16, 0.12)
	add_child(probe)

	# The committee's emblem woven into the carpet (made up: not any real seal).
	_cylinder(1.25, 0.012, Vector3(0, 0.006, 0), _mat(Color(0.75, 0.6, 0.25), 0.6))
	_cylinder(1.12, 0.014, Vector3(0, 0.007, 0), _mat(Color(0.1, 0.13, 0.32), 0.9))
	var emblem := _label("COMMITTEE\nON AI", Vector3(0, 0.02, 0), 0.26, Color(0.85, 0.7, 0.3))
	emblem.rotation = Vector3(-PI / 2, 0, 0)
	# Wooden railing round the floor where the ropes were (sides hide from the camera,
	# like the ropes did).
	var wood := _pbr_texture_mat(
		"res://assets/stage_props/senate/textures/lacquered_cherry_wood_diff_1k.jpg",
		"res://assets/stage_props/senate/textures/lacquered_cherry_wood_nor_1k.jpg",
		"res://assets/stage_props/senate/textures/lacquered_cherry_wood_rough_1k.jpg",
		Vector3(4, 2, 1), 0.35)
	var sides := [[Vector3(0, 0, -4.45), Vector3(9.0, 0.08, 0.1), 0], [Vector3(0, 0, 4.45), Vector3(9.0, 0.08, 0.1), 1],
		[Vector3(-4.45, 0, 0), Vector3(0.1, 0.08, 9.0), 2], [Vector3(4.45, 0, 0), Vector3(0.1, 0.08, 9.0), 3]]
	for side: Array in sides:
		var group := Node3D.new()
		group.add_to_group(&"ring_side_%d" % side[2])
		add_child(group)
		_box(side[1], side[0] + Vector3(0, 0.95, 0), wood, group)
		var along: Vector3 = Vector3(1, 0, 0) if side[1].x > 1.0 else Vector3(0, 0, 1)
		for k in 13:
			_box(Vector3(0.06, 0.92, 0.06), side[0] + along * (-4.2 + k * 0.7) + Vector3(0, 0.46, 0), wood, group)
	# The dais: a long raised desk across the back, nameplates and microphones, the
	# committee's chairs, flags-in-spirit (plain banners) and the title on the wall.
	var desk_wood := wood
	_box(Vector3(14.0, 1.8, 1.2), Vector3(0, -0.1, -7.2), desk_wood)
	_box(Vector3(14.4, 0.08, 1.4), Vector3(0, 0.84, -7.25), _mat(Color(0.22, 0.11, 0.05), 0.35))
	var names := ["SEN. GRAY", "SEN. OKAFOR", "SEN. LINDQVIST", "CHAIR", "SEN. MORALES", "SEN. PATEL", "SEN. BROOKS"]
	var leather := _mat(Color(0.12, 0.08, 0.06), 0.4)
	for i in names.size():
		var x := -5.4 + i * 1.8
		_box(Vector3(0.8, 0.18, 0.05), Vector3(x, 0.97, -6.6), _mat(Color(0.95, 0.93, 0.88), 0.5))
		_label(names[i], Vector3(x, 0.97, -6.57), 0.09, Color(0.1, 0.1, 0.1))
		_cylinder(0.012, 0.35, Vector3(x + 0.3, 1.05, -6.85), _mat(Color(0.1, 0.1, 0.1), 0.3, 0.8))
		_box(Vector3(0.7, 1.3, 0.25), Vector3(x, 1.05, -8.1), leather)
		_prop("res://assets/stage_props/senate/chairDesk.glb", Vector3(x, 0.0, -7.8), Vector3.ZERO, Vector3(2.0, 2.0, 2.0))
		_prop("res://assets/stage_props/senate/laptop.glb", Vector3(x - 0.25, 0.88, -6.85), Vector3(0, 180, 0), Vector3(1.1, 1.1, 1.1))
		_prop("res://assets/stage_props/senate/books.glb", Vector3(x + 0.38, 0.88, -6.85), Vector3(0, 90, 0), Vector3(0.9, 0.9, 0.9))
	# Chairman's brass gavel and solid walnut sound block
	var brass := _mat(Color(0.85, 0.72, 0.32), 0.25, 0.85)
	_box(Vector3(0.24, 0.04, 0.24), Vector3(0.42, 0.90, -6.8), _mat(Color(0.25, 0.12, 0.05), 0.3))
	_cylinder(0.02, 0.26, Vector3(0.42, 0.95, -6.8), _mat(Color(0.3, 0.15, 0.07), 0.3))
	_cylinder(0.035, 0.12, Vector3(0.42, 0.97, -6.7), brass)
	# Stately planters flanking the dais
	_prop("res://assets/stage_props/senate/plantSmall1.glb", Vector3(-6.2, 0.85, -6.8), Vector3.ZERO, Vector3(1.4, 1.4, 1.4))
	_prop("res://assets/stage_props/senate/plantSmall1.glb", Vector3(6.2, 0.85, -6.8), Vector3.ZERO, Vector3(1.4, 1.4, 1.4))
	# C-SPAN witness table just outside the railing
	var witness_wood := wood
	_box(Vector3(2.4, 0.85, 0.9), Vector3(0, 0.425, -4.95), witness_wood)
	_box(Vector3(0.65, 0.14, 0.04), Vector3(0, 0.92, -4.55), _mat(Color(0.95, 0.93, 0.88), 0.5))
	_label("WITNESS", Vector3(0, 0.92, -4.52), 0.08, Color(0.1, 0.1, 0.1))
	for mx in [-0.22, 0.22]:
		_cylinder(0.008, 0.30, Vector3(mx, 0.98, -4.8), _mat(Color(0.1, 0.1, 0.1), 0.3, 0.8))
	_cylinder(0.08, 0.22, Vector3(-0.6, 0.95, -4.85), _mat(Color(0.85, 0.92, 1.0, 0.4), 0.05))
	# Brass lamp, witness laptop, legal books and swivel chair
	_prop("res://assets/stage_props/senate/lampRoundTable.glb", Vector3(-0.85, 0.85, -4.85), Vector3.ZERO, Vector3(1.4, 1.4, 1.4))
	_prop("res://assets/stage_props/senate/chairDesk.glb", Vector3(0, 0.0, -5.7), Vector3(0, 180, 0), Vector3(1.8, 1.8, 1.8))
	_prop("res://assets/stage_props/senate/laptop.glb", Vector3(0.35, 0.88, -4.85), Vector3.ZERO, Vector3(1.1, 1.1, 1.1))
	_prop("res://assets/stage_props/senate/books.glb", Vector3(-0.38, 0.88, -4.85), Vector3(0, 45, 0), Vector3(0.9, 0.9, 0.9))
	# Stacks of hearing briefing binders
	_box(Vector3(0.32, 0.12, 0.26), Vector3(0.65, 0.91, -4.85), _mat(Color(0.12, 0.2, 0.45), 0.6))
	# Official stenographer recording station (matching data/stage_life/senate.json pos [-1.8, 0.0, -5.2])
	_prop("res://assets/stage_props/senate/desk.glb", Vector3(-1.8, 0.0, -5.3), Vector3(0, 45, 0), Vector3(1.6, 1.6, 1.6))
	_prop("res://assets/stage_props/senate/chairDesk.glb", Vector3(-1.5, 0.0, -5.6), Vector3(0, 45, 0), Vector3(1.6, 1.6, 1.6))
	_prop("res://assets/stage_props/senate/laptop.glb", Vector3(-1.8, 0.62, -5.3), Vector3(0, 45, 0), Vector3(0.9, 0.9, 0.9))
	_prop("res://assets/stage_props/senate/books.glb", Vector3(-2.1, 0.62, -5.4), Vector3(0, 135, 0), Vector3(0.7, 0.7, 0.7))
	# Committee dais executive wing extensions
	_prop("res://assets/stage_props/senate/deskCorner.glb", Vector3(-7.2, 0.0, -7.5), Vector3(0, 90, 0), Vector3(1.8, 1.8, 1.8))
	_prop("res://assets/stage_props/senate/deskCorner.glb", Vector3(7.2, 0.0, -7.5), Vector3(0, 0, 0), Vector3(1.8, 1.8, 1.8))
	# Stately bookcases on the rear wall
	_prop("res://assets/stage_props/senate/bookcaseClosedWide.glb", Vector3(-6.8, 0.0, -8.7), Vector3.ZERO, Vector3(1.6, 1.6, 1.6))
	_prop("res://assets/stage_props/senate/bookcaseClosedWide.glb", Vector3(6.8, 0.0, -8.7), Vector3.ZERO, Vector3(1.6, 1.6, 1.6))
	_prop("res://assets/stage_props/senate/bookcaseClosed.glb", Vector3(-8.6, 0.0, -8.7), Vector3.ZERO, Vector3(1.6, 1.6, 1.6))
	_prop("res://assets/stage_props/senate/bookcaseClosed.glb", Vector3(8.6, 0.0, -8.7), Vector3.ZERO, Vector3(1.6, 1.6, 1.6))
	_prop("res://assets/stage_props/senate/speakerSmall.glb", Vector3(-6.0, 3.2, -8.8), Vector3(15, 0, 0), Vector3(1.5, 1.5, 1.5))
	_prop("res://assets/stage_props/senate/speakerSmall.glb", Vector3(6.0, 3.2, -8.8), Vector3(15, 0, 0), Vector3(1.5, 1.5, 1.5))
	# Broadcast television cameras on the flank wings with flash lights
	var tally_mat := _glow(Color(1.0, 0.12, 0.12), 4.5)
	var rng_senate := RandomNumberGenerator.new()
	rng_senate.seed = 42
	for cam_x in [-6.4, 6.4]:
		_cylinder(0.025, 1.3, Vector3(cam_x, 0.65, -3.8), _mat(Color(0.2, 0.2, 0.22), 0.4, 0.6))
		_box(Vector3(0.32, 0.35, 0.55), Vector3(cam_x, 1.45, -3.8), _mat(Color(0.1, 0.1, 0.12), 0.3, 0.5))
		_cylinder(0.09, 0.32, Vector3(cam_x, 1.45, -3.45), _mat(Color(0.05, 0.05, 0.06), 0.2, 0.8))
		_cylinder(0.03, 0.05, Vector3(cam_x, 1.66, -3.7), tally_mat)
		# Camera operator standing behind the rig
		_person(Vector3(cam_x, 0.0, -4.25), Color(0.12, 0.12, 0.14), rng_senate)
		# C-SPAN camera flash unit
		var flash_light := OmniLight3D.new()
		flash_light.position = Vector3(cam_x, 1.8, -3.3)
		flash_light.light_color = Color(0.9, 0.95, 1.0)
		flash_light.light_energy = 0.0
		flash_light.omni_range = 6.0
		add_child(flash_light)
		_flashers.append([flash_light, 3.5])
	# Flanking public gallery benches with observers and aides
	for gx in [-7.2, 7.2]:
		for gz in [-1.5, 0.5, 2.5]:
			_prop("res://assets/stage_props/senate/bench.glb", Vector3(gx, 0.0, gz), Vector3(0, 90 if gx < 0 else -90, 0), Vector3(1.5, 1.5, 1.5))
			_person(Vector3(gx - 0.35, 0.26, gz), Color(0.15, 0.16, 0.22), rng_senate)
			_person(Vector3(gx + 0.35, 0.26, gz), Color(0.25, 0.25, 0.28), rng_senate)
	_box(Vector3(16.0, 5.0, 0.2), Vector3(0, 1.5, -9.0), _mat(Color(0.3, 0.2, 0.14), 0.7)) # dark wood panelling: the gold title reads on it
	for x in [-7.0, -5.6, 5.6, 7.0]:
		_box(Vector3(0.9, 3.0, 0.04), Vector3(x, 2.2, -8.85), _mat(Color(0.12, 0.18, 0.45) if absf(x) > 6.0 else Color(0.6, 0.1, 0.12), 0.8))
	_label("SUBCOMMITTEE ON ARTIFICIAL INTELLIGENCE", Vector3(0, 3.4, -8.85), 0.36, Color(0.95, 0.78, 0.35), true)
	_light(Vector3(0, 3.0, -5.0), Color(1.0, 0.9, 0.75), 3.0, 10.0)
	_light(Vector3(-5.5, 3.2, -8.5), Color(1.0, 0.88, 0.7), 1.3, 8.0)
	_light(Vector3(5.5, 3.2, -8.5), Color(1.0, 0.88, 0.7), 1.3, 8.0)
	_label("IN SESSION", Vector3(0, 2.75, -8.85), 0.22, Color(0.95, 0.25, 0.2), true)
	_ambience("res://assets/audio/ambience/arena_crowd.ogg", -24.0)


# --- GPU Foundry (the night market) ----------------------------------------------------

func _build_foundry() -> void:
	var stage := get_parent()
	# Strip market props, stalls, street food, vehicles, audio, and inherited market geometry.
	# Note: Jeepney0 and Jeepney1 use jeepney.res whose 11 surfaces rely on mesh instance
	# material overrides. Calling queue_free() clears those overrides during frame capture,
	# so we hide and sink them to avoid null material errors during ReflectionProbe updates.
	for node_name in [
		"Jeepney0", "JeepneyRoute0", "JeepneyName0L", "JeepneyName0R",
		"Jeepney1", "JeepneyRoute1", "JeepneyName1L", "JeepneyName1R",
		"Crowd", "GrillSmoke0", "GrillSparks0", "GrillSmoke1", "GrillSparks1",
		"GrillFlicker", "NeonOpen", "NeonCross", "NeonGlow", "Ambience",
		"Sound", "StreetShadows"
	]:
		if node_name in ["Jeepney0", "Jeepney1"]:
			var j = stage.get_node_or_null(node_name) as VisualInstance3D
			if j:
				j.visible = false
				j.position.y = -200.0
		else:
			_remove(stage, node_name)
	for i in 11:
		_remove(stage, "ShopSign%d" % i)
	for i in 6:
		_remove(stage, "StallSign%d" % i)
		_remove(stage, "StallLight%d" % i)
	var market_geom := stage.get_node_or_null("Geometry") as Node3D
	if market_geom:
		market_geom.visible = false

	# Respect graphics presets for expensive screen-space effects (foundry.tscn holds HIGH defaults)
	var settings := get_node_or_null("/root/Settings")
	var we := stage.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if we and we.environment and settings and settings.graphics < 2:
		we.environment = we.environment.duplicate()
		we.environment.ssr_enabled = false
		if settings.graphics == 0:
			we.environment.ssao_enabled = false

	# 1. Enclosed cleanroom reflection probe + dark glossy ESD epoxy floor
	var probe := ReflectionProbe.new()
	probe.name = "FoundryReflectionProbe"
	probe.size = Vector3(26.0, 7.0, 20.0)
	probe.origin_offset = Vector3(0.0, 2.4, -2.5)
	probe.update_mode = ReflectionProbe.UPDATE_ONCE
	probe.intensity = 0.72
	probe.max_distance = 30.0
	probe.ambient_mode = ReflectionProbe.AMBIENT_COLOR
	probe.ambient_color = Color(0.05, 0.08, 0.12)
	add_child(probe)

	var floor_mat := _pbr_texture_mat(
		"res://assets/stage_props/foundry/Textures/metal_plate_02_diff_1k.jpg",
		"res://assets/stage_props/foundry/Textures/metal_plate_02_nor_1k.jpg",
		"res://assets/stage_props/foundry/Textures/metal_plate_02_rough_1k.jpg",
		Vector3(16, 12, 1), 0.26, 0.22)
	floor_mat.albedo_color = Color(0.24, 0.29, 0.37)
	_box(Vector3(26.0, 0.04, 18.0), Vector3(0, -0.01, -1.0), floor_mat)
	# Perforated cleanroom airflow tile seams
	var seam_mat := _mat(Color(0.05, 0.06, 0.08), 0.45, 0.6)
	for x in range(-10, 11, 2):
		_box(Vector3(0.03, 0.025, 16.0), Vector3(x, 0.012, -1.0), seam_mat)
	for z in range(-6, 7, 2):
		_box(Vector3(24.0, 0.025, 0.03), Vector3(0, 0.012, z), seam_mat)
	# Subtle recessed teal floor airflow grates along front & rear cleanroom bays
	var grate_glow := _glow(Color(0.06, 0.65, 0.72), 0.9)
	for gx in [-6.0, -3.0, 3.0, 6.0]:
		_box(Vector3(1.6, 0.024, 0.35), Vector3(gx, 0.012, -3.1), _mat(Color(0.07, 0.09, 0.12), 0.3, 0.7))
		_box(Vector3(1.4, 0.025, 0.05), Vector3(gx, 0.013, -3.1), grate_glow)
	# Crisp amber-gold ESD caution perimeter border (controlled bloom, no blowout)
	var esd_border := _glow(Color(0.95, 0.58, 0.06), 1.45)
	for z in [-3.6, 3.6]:
		_box(Vector3(17.2, 0.026, 0.07), Vector3(0, 0.013, z), esd_border)
	for x in [-3.6, 3.6]:
		_box(Vector3(0.07, 0.026, 7.2), Vector3(x, 0.013, 0), esd_border)
	# Corner amber hazard beacons on ESD perimeter
	var esd_corner_amber := _glow(Color(1.0, 0.48, 0.05), 3.0, true)
	_blinkers.append([esd_corner_amber, 3.0, 4.0, 0.0])
	for cx in [-3.6, 3.6]:
		for cz in [-3.6, 3.6]:
			_cylinder(0.06, 0.14, Vector3(cx, 0.07, cz), esd_corner_amber)

	# 2. Enclosed dark cleanroom shell: back wall, side walls, structural mullions, HEPA ceiling
	var wall_mat := _mat(Color(0.17, 0.21, 0.28), 0.38, 0.25)
	var strut_mat := _mat(Color(0.36, 0.40, 0.48), 0.26, 0.80)
	var dark_metal := _mat(Color(0.10, 0.12, 0.16), 0.32, 0.75)
	# Back wall & side walls (prevents market/outdoor sky leaks)
	_box(Vector3(26.0, 6.0, 0.25), Vector3(0, 3.0, -6.2), wall_mat)
	for sx in [-12.0, 12.0]:
		_box(Vector3(0.3, 6.0, 18.0), Vector3(sx, 3.0, -1.0), wall_mat)
	for wx in range(-10, 11, 2):
		_box(Vector3(0.10, 5.8, 0.28), Vector3(wx, 2.9, -6.15), strut_mat)
	# Upper cleanroom return air louvers & teal bulkhead accent line
	_box(Vector3(25.0, 0.55, 0.08), Vector3(0, 4.85, -6.04), dark_metal)
	_box(Vector3(24.0, 0.04, 0.04), Vector3(0, 4.5, -6.04), _glow(Color(0.06, 0.78, 0.85), 1.5))
	# Cleanroom ceiling with dark structural trusses and recessed HEPA LED light bays
	_box(Vector3(26.0, 0.2, 18.0), Vector3(0, 5.45, -1.0), _mat(Color(0.08, 0.10, 0.14), 0.5, 0.4))
	var hepa_cool := _glow(Color(0.40, 0.82, 0.92), 1.1)
	var hepa_amber := _glow(Color(0.95, 0.55, 0.10), 1.1)
	for tz in [-4.8, -2.8]:
		_box(Vector3(24.0, 0.18, 0.22), Vector3(0, 5.28, tz), dark_metal)
		for hx in [-6.0, -3.0, 0.0, 3.0, 6.0]:
			_box(Vector3(1.6, 0.04, 0.40), Vector3(hx, 5.34, tz + 0.5), hepa_cool if absf(hx) != 3.0 else hepa_amber)

	# 3. Centerpiece: Twin EUV Photolithography Scanner in dark gunmetal/obsidian housing
	var scanner_mat := _mat(Color(0.13, 0.15, 0.20), 0.28, 0.75)
	var trim_mat := _mat(Color(0.34, 0.38, 0.46), 0.24, 0.85)
	# Left & right structural towers flanking a true recessed chamber alcove
	_box(Vector3(1.3, 3.6, 1.7), Vector3(-1.95, 1.8, -5.05), scanner_mat)
	_box(Vector3(1.3, 3.6, 1.7), Vector3(1.95, 1.8, -5.05), scanner_mat)
	_box(Vector3(2.8, 1.0, 1.7), Vector3(0.0, 0.5, -5.05), scanner_mat)
	_box(Vector3(2.8, 1.1, 1.7), Vector3(0.0, 3.05, -5.05), scanner_mat)
	_box(Vector3(2.8, 1.55, 0.4), Vector3(0.0, 1.75, -5.65), dark_metal) # recessed chamber back wall
	_box(Vector3(5.4, 0.14, 1.8), Vector3(0.0, 3.65, -5.05), trim_mat)
	# Vertical cooling ribs inside recessed chamber back wall
	for rx in [-0.9, -0.45, 0.45, 0.9]:
		_box(Vector3(0.12, 1.35, 0.12), Vector3(rx, 1.75, -5.4), trim_mat)
	# Vertical amber/teal warning light columns on scanner flanks
	var col_teal := _glow(Color(0.05, 0.88, 0.92), 2.2)
	var col_amber := _glow(Color(1.0, 0.52, 0.06), 2.4, true)
	_blinkers.append([col_amber, 2.4, 3.4, 1.0])
	for sx in [-2.62, 2.62]:
		_box(Vector3(0.06, 2.9, 0.08), Vector3(sx, 1.85, -4.18), col_teal)
	for sx in [-1.32, 1.32]:
		_box(Vector3(0.05, 1.4, 0.06), Vector3(sx, 1.75, -4.18), col_amber)

	# Visible recessed 13.5nm EUV Laser Chamber (core + plasma sheath + optics behind UV glass)
	var euv_core := _glow(Color(0.85, 0.25, 1.0), 5.2, true)
	_blinkers.append([euv_core, 5.2, 3.0, 0.0])
	_cylinder(0.10, 1.25, Vector3(0.0, 1.75, -4.75), euv_core)
	var plasma_sheath := _mat(Color(0.65, 0.15, 0.95, 0.22), 0.1)
	plasma_sheath.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	plasma_sheath.emission_enabled = true
	plasma_sheath.emission = Color(0.65, 0.15, 0.95)
	plasma_sheath.emission_energy_multiplier = 1.8
	_cylinder(0.24, 1.22, Vector3(0.0, 1.75, -4.75), plasma_sheath)
	_cylinder(0.45, 0.22, Vector3(0.0, 2.38, -4.75), trim_mat)
	_cylinder(0.50, 0.16, Vector3(0.0, 1.10, -4.75), trim_mat)
	# Lightly tinted UV amber observation window & steel frame in front of the chamber
	var glass := _mat(Color(1.0, 0.58, 0.14, 0.12), 0.05)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_box(Vector3(2.5, 1.45, 0.04), Vector3(0.0, 1.75, -4.22), glass)
	for fy in [1.0, 2.5]:
		_box(Vector3(2.68, 0.08, 0.08), Vector3(0.0, fy, -4.20), trim_mat)
	for fx in [-1.3, 1.3]:
		_box(Vector3(0.08, 1.58, 0.08), Vector3(fx, 1.75, -4.20), trim_mat)

	# Wafer load port & 300mm silicon wafer disc in front of scanner
	var wafer_mat := _mat(Color(0.12, 0.42, 0.52), 0.06, 0.92)
	_box(Vector3(1.4, 0.78, 0.85), Vector3(0.0, 0.39, -3.95), _mat(Color(0.14, 0.17, 0.22), 0.3, 0.65))
	_cylinder(0.46, 0.02, Vector3(0.0, 0.79, -3.95), col_teal)
	_cylinder(0.42, 0.025, Vector3(0.0, 0.81, -3.95), wafer_mat)
	# Flashing amber load-port warning beacons
	var beacon_amber := _glow(Color(1.0, 0.52, 0.04), 3.4, true)
	_blinkers.append([beacon_amber, 3.4, 4.2, 0.5])
	_cylinder(0.055, 0.14, Vector3(-0.62, 0.86, -3.95), beacon_amber)
	_cylinder(0.055, 0.14, Vector3(0.62, 0.86, -3.95), beacon_amber)

	# Darkened robotic wafer transfer arms & grounded conveyors flanking load port
	var gunmetal := Color(0.48, 0.52, 0.58)
	var dark_machinery := Color(0.38, 0.42, 0.48)
	for ax in [-1.65, 1.65]:
		_box(Vector3(0.45, 0.55, 0.45), Vector3(ax, 0.275, -4.05), dark_metal)
	_foundry_tint_prop(_prop("res://assets/stage_props/foundry/robot-arm-a.glb", Vector3(-1.65, 0.55, -4.05), Vector3(0, 50, 0), Vector3(0.62, 0.62, 0.62)), gunmetal, 0.32, 0.6)
	_foundry_tint_prop(_prop("res://assets/stage_props/foundry/robot-arm-b.glb", Vector3(1.65, 0.55, -4.05), Vector3(0, -50, 0), Vector3(0.62, 0.62, 0.62)), gunmetal, 0.32, 0.6)
	_foundry_tint_prop(_prop("res://assets/stage_props/foundry/conveyor.glb", Vector3(-2.95, 0.32, -4.25), Vector3(0, 90, 0), Vector3(0.75, 0.65, 0.75)), dark_machinery, 0.38, 0.5)
	_foundry_tint_prop(_prop("res://assets/stage_props/foundry/conveyor.glb", Vector3(2.95, 0.32, -4.25), Vector3(0, 90, 0), Vector3(0.75, 0.65, 0.75)), dark_machinery, 0.38, 0.5)
	_cylinder(0.24, 0.015, Vector3(-2.95, 0.66, -4.25), wafer_mat)
	_cylinder(0.24, 0.015, Vector3(2.95, 0.66, -4.25), wafer_mat)
	# Grounded lithography track machines & inspection scanners on outer flanks (clear of boards & NPCs)
	for mx in [-7.2, 7.2]:
		_box(Vector3(1.6, 0.75, 1.3), Vector3(mx, 0.375, -5.2), dark_metal)
	_foundry_tint_prop(_prop("res://assets/stage_props/foundry/machine.glb", Vector3(-7.2, 0.75, -5.2), Vector3(0, 0, 0), Vector3(0.95, 0.95, 0.95)), dark_machinery, 0.36, 0.5)
	_foundry_tint_prop(_prop("res://assets/stage_props/foundry/machine.glb", Vector3(7.2, 0.75, -5.2), Vector3(0, 180, 0), Vector3(0.95, 0.95, 0.95)), dark_machinery, 0.36, 0.5)
	_foundry_tint_prop(_prop("res://assets/stage_props/foundry/scanner-high.glb", Vector3(-6.4, 0.0, -4.2), Vector3(0, 20, 0), Vector3(1.05, 1.05, 1.05)), gunmetal, 0.35, 0.45)
	_foundry_tint_prop(_prop("res://assets/stage_props/foundry/scanner-low.glb", Vector3(6.4, 0.0, -4.2), Vector3(0, -160, 0), Vector3(1.05, 1.05, 1.05)), gunmetal, 0.35, 0.45)
	# Amber hazard markers kept vivid for color contrast
	_foundry_tint_prop(_prop("res://assets/stage_props/foundry/warning-orange.glb", Vector3(-2.35, 0.0, -3.75), Vector3.ZERO, Vector3(0.9, 0.9, 0.9)), Color(0.95, 0.62, 0.28), 0.35, 0.3)
	_foundry_tint_prop(_prop("res://assets/stage_props/foundry/warning-orange.glb", Vector3(2.35, 0.0, -3.75), Vector3.ZERO, Vector3(0.9, 0.9, 0.9)), Color(0.95, 0.62, 0.28), 0.35, 0.3)

	# 4. AMHS Overhead Monorail Track, Catwalks & FOUP wafer pods
	var rail_mat := _mat(Color(0.22, 0.25, 0.30), 0.32, 0.8)
	_box(Vector3(20.0, 0.14, 0.36), Vector3(0, 4.05, -4.2), rail_mat)
	_box(Vector3(20.0, 0.03, 0.025), Vector3(0, 3.98, -4.01), _glow(Color(0.06, 0.85, 0.92), 2.0))
	_foundry_tint_prop(_prop("res://assets/stage_props/foundry/catwalk-straight.glb", Vector3(-5.8, 3.2, -5.5), Vector3.ZERO, Vector3(1.2, 1.2, 1.2)), dark_machinery, 0.4, 0.55)
	_foundry_tint_prop(_prop("res://assets/stage_props/foundry/catwalk-straight.glb", Vector3(5.8, 3.2, -5.5), Vector3.ZERO, Vector3(1.2, 1.2, 1.2)), dark_machinery, 0.4, 0.55)
	_foundry_tint_prop(_prop("res://assets/stage_props/foundry/catwalk-stairs.glb", Vector3(-8.8, 0.0, -5.5), Vector3(0, 90, 0), Vector3(1.2, 1.2, 1.2)), dark_machinery, 0.4, 0.55)
	_foundry_tint_prop(_prop("res://assets/stage_props/foundry/catwalk-stairs.glb", Vector3(8.8, 0.0, -5.5), Vector3(0, -90, 0), Vector3(1.2, 1.2, 1.2)), dark_machinery, 0.4, 0.55)
	# Flanking overhead monitors (never blocking center EUV title)
	_foundry_tint_prop(_prop("res://assets/stage_props/foundry/screen-hanging-wide.glb", Vector3(-3.5, 3.7, -4.25), Vector3.ZERO, Vector3(1.0, 1.0, 1.0)), Color(0.35, 0.42, 0.50), 0.3, 0.5)
	_foundry_tint_prop(_prop("res://assets/stage_props/foundry/screen-hanging-wide.glb", Vector3(3.5, 3.7, -4.25), Vector3.ZERO, Vector3(1.0, 1.0, 1.0)), Color(0.35, 0.42, 0.50), 0.3, 0.5)
	_foundry_tint_prop(_prop("res://assets/stage_props/foundry/screen-panel-wide.glb", Vector3(-7.6, 2.1, -5.9), Vector3.ZERO, Vector3(1.2, 1.2, 1.2)), gunmetal, 0.35, 0.5)
	_foundry_tint_prop(_prop("res://assets/stage_props/foundry/screen-panel-wide.glb", Vector3(7.6, 2.1, -5.9), Vector3.ZERO, Vector3(1.2, 1.2, 1.2)), gunmetal, 0.35, 0.5)
	_foundry_tint_prop(_prop("res://assets/stage_props/foundry/box-large.glb", Vector3(-9.0, 0.0, -4.0), Vector3.ZERO, Vector3(1.5, 1.5, 1.5)), dark_machinery, 0.4, 0.5)
	_foundry_tint_prop(_prop("res://assets/stage_props/foundry/box-large.glb", Vector3(9.0, 0.0, -4.0), Vector3.ZERO, Vector3(1.5, 1.5, 1.5)), dark_machinery, 0.4, 0.5)

	var foup_mat := _mat(Color(0.12, 0.14, 0.18), 0.22, 0.55)
	var foup_teal := _glow(Color(0.08, 0.90, 0.88), 2.2)
	var foup_amber := _glow(Color(1.0, 0.55, 0.06), 2.2)
	var pod_xs := [-6.2, -2.5, 2.5, 6.2]
	for i in pod_xs.size():
		var fx: float = pod_xs[i]
		_box(Vector3(0.08, 0.38, 0.1), Vector3(fx, 3.8, -4.2), rail_mat)
		_box(Vector3(0.56, 0.46, 0.5), Vector3(fx, 3.45, -4.2), foup_mat)
		_box(Vector3(0.46, 0.05, 0.02), Vector3(fx, 3.45, -3.94), foup_teal if i % 2 == 0 else foup_amber)
	# Overhead cryogenic & process gas pipelines
	_foundry_tint_prop(_prop("res://assets/stage_props/foundry/pipe-large.glb", Vector3(-5.0, 4.3, -4.5), Vector3(0, 90, 0), Vector3(1.2, 1.2, 1.2)), gunmetal, 0.35, 0.6)
	_foundry_tint_prop(_prop("res://assets/stage_props/foundry/pipe-glass-large.glb", Vector3(5.0, 4.3, -4.5), Vector3(0, 90, 0), Vector3(1.2, 1.2, 1.2)), gunmetal, 0.25, 0.5)

	# 5. Diagnostic consoles & wafer cassette racks on outer flanks
	for cx in [-7.8, 7.8]:
		_box(Vector3(1.0, 0.9, 0.7), Vector3(cx, 0.45, -3.5), _mat(Color(0.16, 0.18, 0.22), 0.38, 0.55))
		_box(Vector3(0.7, 0.4, 0.04), Vector3(cx, 1.2, -3.4), _mat(Color(0.08, 0.09, 0.12), 0.2))
		_box(Vector3(0.65, 0.35, 0.01), Vector3(cx, 1.2, -3.37), _glow(Color(0.06, 0.75, 0.85), 1.5))
		_cylinder(0.25, 0.35, Vector3(cx + (0.9 if cx < 0 else -0.9), 0.45, -3.5), _mat(Color(0.28, 0.31, 0.36), 0.35, 0.7))
	_label("NODE: 1.8nm GAAS\nDEFECTS: 0.002/cm²\nYIELD: NOMINAL", Vector3(-7.8, 1.2, -3.35), 0.065, Color(0.88, 1.0, 1.0))
	_label("EUV LASER: 13.5nm\nCHAMBER: ARGON\nPURGE: 100%", Vector3(7.8, 1.2, -3.35), 0.065, Color(0.88, 1.0, 1.0))

	# 6. Cryogenic pipes & liquid argon exhaust steam
	for px in [-9.4, 9.4]:
		_cylinder(0.3, 3.8, Vector3(px, 1.9, -4.8), _mat(Color(0.38, 0.42, 0.48), 0.3, 0.8))
		_steam(Vector3(px, 3.85, -4.8))

	# 7. Bunny-suit technicians on catwalks & clear rear alcoves (clear of StageCrowd positions)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	for sx in [-5.8, 5.8]:
		_bunny_person(Vector3(sx, 3.25, -5.5), rng)
	for bx in [-3.4, 3.4]:
		_bunny_person(Vector3(bx, 0.0, -5.5), rng)

	# 8. Satirical cleanroom signage and metrics boards (clear, legible, unobscured)
	_box(Vector3(4.6, 0.5, 0.14), Vector3(0.0, 3.38, -4.18), dark_metal)
	_label("GPU FOUNDRY — FAB 4090", Vector3(0.0, 3.38, -4.09), 0.30, Color(0.18, 0.92, 0.78), true)
	_board("CLEANROOM PROTOCOL (CLASS 1)\n• Full bunny suit mandatory\n• No leather jackets in air shower\n• 3-frame jabs only (vibration < 0.1nm)\n• Scrapped wafers deducted from bonus\n• If laser pulses: continue fighting",
		Vector3(-5.25, 2.05, -5.95))
	_board("FAB 4090 METRICS\n• Process: 1.8nm Hype-FinFET\n• Die Yield: 88.4% (dropping)\n• EUV Uptime: 99.98%\n• Wafer Cost: $42,000 / piece\n• Today's Scrap: 12 wafers (blame P2)",
		Vector3(5.25, 2.05, -5.95))
	_label("DANGER: 13.5nm EUV BEAM\nAUTHORIZED CHIP ARCHITECTS ONLY", Vector3(0.0, 2.75, -4.17), 0.115, Color(1.0, 0.45, 0.12), true)

	# 9. Coloured warning spotlights (teal/amber) with volumetric fog shafts & EUV chamber glow
	_foundry_spot(Vector3(-5.0, 4.9, -2.6), Vector3(-4.2, 0.0, -4.6), Color(0.08, 0.88, 0.92), 4.6, 11.5, 36.0, 7.5)
	_foundry_spot(Vector3(5.0, 4.9, -2.6), Vector3(4.2, 0.0, -4.6), Color(0.08, 0.88, 0.92), 4.6, 11.5, 36.0, 7.5)
	_foundry_spot(Vector3(-2.3, 4.4, -2.6), Vector3(-2.0, 0.0, -4.2), Color(1.0, 0.56, 0.08), 3.8, 10.0, 34.0, 7.0)
	_foundry_spot(Vector3(2.3, 4.4, -2.6), Vector3(2.0, 0.0, -4.2), Color(1.0, 0.56, 0.08), 3.8, 10.0, 34.0, 7.0)
	_light(Vector3(0.0, 1.75, -4.35), Color(0.76, 0.20, 1.0), 2.8, 6.0)
	_light(Vector3(0.0, 2.8, 1.5), Color(0.78, 0.86, 0.98), 1.4, 9.0)

	# 10. Ambient ventilation audio
	_ambience("res://assets/audio/ambience/wind.ogg", -24.0)


func _foundry_tint_prop(node: Node3D, tint: Color, roughness := 0.36, metallic := 0.55) -> void:
	if node == null:
		return
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi.mesh == null:
			continue
		for surf in mi.mesh.get_surface_count():
			var base_mat := mi.get_active_material(surf)
			if base_mat is StandardMaterial3D:
				var m := (base_mat as StandardMaterial3D).duplicate() as StandardMaterial3D
				m.albedo_color = m.albedo_color * tint
				m.roughness = roughness
				m.metallic = metallic
				mi.set_surface_override_material(surf, m)


func _foundry_spot(pos: Vector3, target: Vector3, color: Color, energy: float, reach: float, angle: float, fog_energy: float) -> void:
	var spot := SpotLight3D.new()
	spot.light_color = color
	spot.light_energy = energy
	spot.spot_range = reach
	spot.spot_angle = angle
	spot.spot_attenuation = 0.85
	spot.light_volumetric_fog_energy = fog_energy
	spot.shadow_enabled = false
	add_child(spot)
	spot.look_at_from_position(pos, target, Vector3.UP)


# --- Helpers ---------------------------------------------------------------------------

func _steam(pos: Vector3) -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3.UP
	mat.spread = 18.0
	mat.initial_velocity_min = 0.6
	mat.initial_velocity_max = 1.4
	mat.gravity = Vector3(0, 0.05, 0)
	mat.scale_min = 0.25
	mat.scale_max = 0.65
	var grad := Gradient.new()
	grad.set_color(0, Color(0.85, 0.92, 1.0, 0.0))
	grad.add_point(0.25, Color(0.85, 0.92, 1.0, 0.28))
	grad.set_color(1, Color(0.85, 0.92, 1.0, 0.0))
	var ramp := GradientTexture1D.new()
	ramp.gradient = grad
	mat.color_ramp = ramp
	particles.process_material = mat
	particles.amount = 14
	particles.lifetime = 1.8
	var sphere := SphereMesh.new()
	sphere.radius = 0.16
	sphere.height = 0.32
	sphere.radial_segments = 6
	sphere.rings = 3
	var smat := StandardMaterial3D.new()
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smat.albedo_color = Color(0.85, 0.92, 1.0, 0.2)
	sphere.material = smat
	particles.draw_pass_1 = sphere
	particles.position = pos
	add_child(particles)
	return particles

func _mat(color: Color, roughness := 0.7, metallic := 0.0) -> StandardMaterial3D:
	var key := "%s/%s/%s" % [color, roughness, metallic]
	if _materials.has(key):
		return _materials[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	_materials[key] = m
	return m


## An emissive material; `own` = a new one (blinking lights each get theirs).
func _glow(color: Color, energy: float, own := false) -> StandardMaterial3D:
	var key := "glow/%s/%s" % [color, energy]
	if not own and _materials.has(key):
		return _materials[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	if not own:
		_materials[key] = m
	return m


func _resolve_tex_path(path: String) -> String:
	if ResourceLoader.exists(path):
		return path
	if "/textures/" in path:
		var alt := path.replace("/textures/", "/Textures/")
		if ResourceLoader.exists(alt):
			return alt
	elif "/Textures/" in path:
		var alt := path.replace("/Textures/", "/textures/")
		if ResourceLoader.exists(alt):
			return alt
	return ""


func _pbr_texture_mat(diff_path: String, nor_path: String, rough_path: String, uv_scale: Vector3, roughness_mult := 1.0, metallic := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	var d := _resolve_tex_path(diff_path)
	if not d.is_empty():
		m.albedo_texture = load(d)
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		m.uv1_scale = uv_scale
	var n := _resolve_tex_path(nor_path)
	if not n.is_empty():
		m.normal_enabled = true
		m.normal_texture = load(n)
	var r := _resolve_tex_path(rough_path)
	if not r.is_empty():
		m.roughness_texture = load(r)
		m.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	m.roughness = roughness_mult
	m.metallic = metallic
	return m


func _box(size: Vector3, position_: Vector3, material: Material, parent: Node3D = self) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _instance(mesh, position_, material, parent)


func _cylinder(radius: float, height: float, position_: Vector3, material: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 24
	return _instance(mesh, position_, material, self)


func _instance(mesh: Mesh, position_: Vector3, material: Material, parent: Node3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.position = position_
	parent.add_child(mi)
	return mi


func _prop(path: String, position_: Vector3, rotation_deg := Vector3.ZERO, scale_ := Vector3.ONE, parent: Node3D = self) -> Node3D:
	if not ResourceLoader.exists(path):
		return null
	var scene := load(path) as PackedScene
	if not scene:
		return null
	var node := scene.instantiate() as Node3D
	node.position = position_
	node.rotation_degrees = rotation_deg
	node.scale = scale_
	parent.add_child(node)
	return node


func _label(text: String, position_: Vector3, size: float, color: Color, glow := false) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position = position_
	label.pixel_size = size / 64.0
	label.font_size = 64
	label.outline_size = 0
	label.modulate = color
	label.shaded = not glow
	label.double_sided = false
	add_child(label)
	return label


func _light(position_: Vector3, color: Color, energy: float, reach: float) -> void:
	var light := OmniLight3D.new()
	light.position = position_
	light.light_color = color
	light.light_energy = energy
	light.omni_range = reach
	add_child(light)


## A menu board on the back wall: a dark panel with chalk-coloured text.
func _board(text: String, position_: Vector3) -> void:
	_box(Vector3(3.0, 1.6, 0.05), position_, _mat(Color(0.08, 0.1, 0.09), 0.9))
	var label := _label(text, position_ + Vector3(0, 0, 0.04), 0.14, Color(0.92, 0.92, 0.85), true)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.width = 1300
	label.autowrap_mode = TextServer.AUTOWRAP_OFF


## A seated diner: a capsule body and a sphere head, in `shirt`.
func _person(seat: Vector3, shirt: Color, rng: RandomNumberGenerator) -> void:
	var body := CapsuleMesh.new()
	body.radius = 0.17
	body.height = 0.62
	_instance(body, seat + Vector3(0, 0.3, 0), _mat(shirt, 0.8), self)
	var head := SphereMesh.new()
	head.radius = 0.11
	head.height = 0.22
	var skins := [Color(0.85, 0.66, 0.52), Color(0.6, 0.42, 0.3), Color(0.4, 0.27, 0.18), Color(0.92, 0.75, 0.62)]
	_instance(head, seat + Vector3(0, 0.74, 0), _mat(skins[rng.randi() % skins.size()], 0.6), self)


## A cleanroom technician in full white bunny suit, hood, and visor goggles.
func _bunny_person(seat: Vector3, rng: RandomNumberGenerator) -> void:
	var suit_mat := _mat(Color(0.96, 0.96, 0.98), 0.4, 0.0)
	var visor_mat := _glow(Color(0.2, 0.8, 1.0) if rng.randf() < 0.5 else Color(1.0, 0.85, 0.2), 2.5)
	var glove_mat := _mat(Color(0.2, 0.35, 0.75), 0.5)

	# Body in bunny suit
	var body := CapsuleMesh.new()
	body.radius = 0.19
	body.height = 0.75
	_instance(body, seat + Vector3(0, 0.42, 0), suit_mat, self)

	# Hooded head
	var head := SphereMesh.new()
	head.radius = 0.14
	head.height = 0.26
	_instance(head, seat + Vector3(0, 0.88, 0), suit_mat, self)

	# Cleanroom visor goggles
	var visor := BoxMesh.new()
	visor.size = Vector3(0.18, 0.06, 0.05)
	_instance(visor, seat + Vector3(0, 0.9, 0.12), visor_mat, self)

	# ESD Nitrile gloves
	for gx in [-0.22, 0.22]:
		var hand := SphereMesh.new()
		hand.radius = 0.05
		hand.height = 0.1
		_instance(hand, seat + Vector3(gx, 0.32, 0.1), glove_mat, self)


func _checker(a: Color, b: Color) -> ImageTexture:
	var image := Image.create(2, 2, false, Image.FORMAT_RGB8)
	image.set_pixel(0, 0, a)
	image.set_pixel(1, 1, a)
	image.set_pixel(1, 0, b)
	image.set_pixel(0, 1, b)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


func _relabel(stage: Node, node_name: String, text: String) -> void:
	var label := stage.get_node_or_null(node_name) as Label3D
	if label:
		label.text = text


func _remove(stage: Node, node_name: String) -> void:
	var node := stage.get_node_or_null(node_name)
	if node:
		node.queue_free()


func _ambience(stream_path: String, volume_db: float) -> void:
	if not ResourceLoader.exists(stream_path):
		return
	var stream: AudioStream = load(stream_path)
	if stream is AudioStreamOggVorbis:
		stream = stream.duplicate()
		(stream as AudioStreamOggVorbis).loop = true
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = &"Ambience"
	player.volume_db = volume_db
	add_child(player)
	player.play()
