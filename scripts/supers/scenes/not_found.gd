extends SuperScene
## Sundar Pickai's super "404 Not Found" (docs/ROADMAP.md §2, owner-approved): the opponent
## is trapped inside a giant browser window while Sundar types; the page loads, shows
## "404 NOT FOUND", and the opponent is pixelated away. Then he reloads the page and they
## are back for the fight.
##
## Timeline: about 5.1 s; MoveData.cinematic_ticks must cover it (tools/showdown_movesets.gd).

const TYPE_TIME := 1.0
const LOAD_TIME := 0.9
const ERROR_TIME := 0.8
const GLITCH_TIME := 0.35
const SCATTER_TIME := 1.0
const EMPTY_TIME := 0.35
const RELOAD_TIME := 0.7
const LENGTH := TYPE_TIME + LOAD_TIME + ERROR_TIME + GLITCH_TIME + SCATTER_TIME + EMPTY_TIME + RELOAD_TIME

const URL := "https://www.skill-issue.com/you/are/here"
const PAGE_COLOR := Color(0.62, 0.72, 0.9)
const VICTIM_IN_PAGE_SCALE := Vector3(0.76, 0.76, 0.76)

var window: Node3D
var victim: ScenePuppet
var sundar: ScenePuppet
var keyboard: Node3D
var pixels: Node3D
var _url_label: Label3D
var _progress: Node3D
var _page_error: Node3D
var _page_loading: Node3D
var _page_tint: MeshInstance3D
var _bits: Array[MeshInstance3D] = []
var _glitching := false
var _typing := false
var _time := 0.0


func build() -> void:
	var void_set := load_set("browser_void")
	window = prop("sundar/browser_window", browser_window, void_set)
	window.global_transform = marker("browser_void", "Window")
	window.scale = Vector3.ONE * 1.18
	_url_label = window.find_child("Url", true, false) as Label3D
	_progress = window.find_child("Progress", true, false) as Node3D
	_page_error = window.find_child("PageError", true, false) as Node3D
	_page_loading = window.find_child("PageLoading", true, false) as Node3D
	_page_tint = window.find_child("PageTint", true, false) as MeshInstance3D
	if _url_label:
		_url_label.text = ""
	if _page_error:
		_page_error.visible = false
	if _progress:
		_progress.scale.x = 0.001
	# The opponent, stuck inside the page, scaled and nudged forward so their head stays clear of the backing.
	var inside := window.find_child("Inside", true, false) as Node3D
	victim = puppet(defender, window)
	victim.position = (inside.position if inside else Vector3(0, 0.3, -0.3)) + Vector3(0, -0.04, 0.20)
	victim.scale = VICTIM_IN_PAGE_SCALE
	victim.rotation.y = PI # faces the viewer
	victim.hold(&"fight/wall_splat", 0.15)
	victim.face = &"pain"
	# Sundar, off to the side, typing on a floating keyboard.
	sundar = puppet(attacker, void_set)
	sundar.global_transform = marker("browser_void", "Sundar")
	sundar.play(&"ual1/Interact")
	sundar.face = &"grin"
	keyboard = floating_keyboard()
	void_set.add_child(keyboard)
	keyboard.global_position = sundar.global_position + sundar.global_transform.basis * Vector3(0, 1.15, -0.55)
	keyboard.look_at(window.global_position + Vector3(0, 1.4, 0))
	keyboard.rotate_object_local(Vector3.RIGHT, -0.5)
	pixels = Node3D.new()
	pixels.visible = false
	pixels.scale = VICTIM_IN_PAGE_SCALE
	window.add_child(pixels)
	build_pixels()


func run() -> void:
	show_set("browser_void")
	# Wide: Sundar types the address, the page starts loading.
	shot("browser_void", "Cam_Wide", window.global_position + Vector3(0, 1.6, 0))
	sound("keyboard_typing")
	_typing = true
	if _url_label:
		type_out(_url_label, URL, TYPE_TIME * 0.8)
	var shake := create_tween().set_loops()
	shake.tween_property(victim, "position:x", 0.1, 0.07)
	shake.tween_property(victim, "position:x", -0.1, 0.07)
	await wait(TYPE_TIME)

	# Close: the page loads, the trapped opponent bangs on the glass.
	_typing = false
	shot("browser_void", "Cam_Close", window.global_position + Vector3(0, 1.4, 0))
	var push := create_tween()
	push.tween_property(camera, "global_position", camera.global_position + Vector3(0, 0, -0.5), LOAD_TIME)
	if _progress:
		var load_bar := create_tween()
		load_bar.tween_property(_progress, "scale:x", 1.0, LOAD_TIME).set_trans(Tween.TRANS_QUAD)
	await wait(LOAD_TIME)

	# Error: 404 NOT FOUND slams in.
	shake.kill()
	victim.position.x = 0.0
	sound("error_beep")
	if _page_loading:
		_page_loading.visible = false
	if _page_error:
		_page_error.visible = true
		_page_error.scale = Vector3.ONE * 0.3
		var slam := create_tween()
		slam.tween_property(_page_error, "scale", Vector3.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if _page_tint:
		(_page_tint.material_override as StandardMaterial3D).albedo_color = Color(1.0, 0.82, 0.82)
	shot("browser_void", "Cam_Wide", window.global_position + Vector3(0, 1.6, 0))
	victim.face = &"shout"
	await wait(ERROR_TIME)

	# Glitch: they flicker and stutter...
	_glitching = true
	await wait(GLITCH_TIME)
	_glitching = false

	# ...and are pixelated away.
	victim.visible = false
	victim.scale = VICTIM_IN_PAGE_SCALE
	pixels.visible = true
	big_text("404: SKILL NOT FOUND!", window.global_position + Vector3(0, 4.1, 0.8), Color(1.0, 0.3, 0.3), 0.56, 1.0)
	scatter_pixels()
	await wait(SCATTER_TIME)
	await wait(EMPTY_TIME)

	# Reload: the page flashes and the opponent comes back.
	for bit in _bits:
		bit.visible = false
	if _page_error:
		_page_error.visible = false
	if _page_loading:
		_page_loading.visible = true
	if _page_tint:
		(_page_tint.material_override as StandardMaterial3D).albedo_color = PAGE_COLOR
	if _progress:
		_progress.scale.x = 0.001
		var reload := create_tween()
		reload.tween_property(_progress, "scale:x", 1.0, RELOAD_TIME * 0.6)
	big_text("SYSTEM RESTORED!", window.global_position + Vector3(0, 4.1, 0.8), Color(0.28, 0.95, 0.55), 0.56, 0.5)
	victim.visible = true
	victim.scale = Vector3.ONE * 0.05
	victim.face = &"pain"
	victim.play(&"fight/thrown", 1.0)
	victim.model.flash(Color(1, 1, 1), 0.4)
	var back := create_tween()
	back.tween_property(victim, "scale", VICTIM_IN_PAGE_SCALE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await wait(RELOAD_TIME)


func _process(delta: float) -> void:
	super(delta)
	_time += delta
	if _typing and sundar:
		# Fingers hammering: the keyboard jitters a little.
		keyboard.scale = Vector3.ONE * (1.0 + 0.015 * sin(_time * 40.0))
	if _glitching and victim:
		var flick := int(_time * 30.0) % 3
		victim.scale = VICTIM_IN_PAGE_SCALE * Vector3(1.0 + 0.25 * (flick - 1), 1.0 - 0.15 * (flick - 1), 1.0)
		victim.visible = int(_time * 24.0) % 4 != 0


## Back in the fight: the opponent has a faint glitch flash.
func aftermath() -> void:
	if is_instance_valid(defender) and defender.model:
		defender.model.flash(Color(0.3, 0.6, 1.0), 0.6)


## Types `full` into `label` over `seconds` (Label3D has no visible_characters).
func type_out(label: Label3D, full: String, seconds: float) -> void:
	var tween := create_tween()
	tween.tween_method(func(t: float) -> void: label.text = full.substr(0, int(round(t * full.length()))), 0.0, 1.0, seconds)


# --- Pixels: the opponent as a cluster of cubes ----------------------------------------

func build_pixels() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12
	var inside := victim.position
	var cell := 0.17
	for iy in 11:
		for ix in 5:
			for iz in 2:
				var y := 0.1 + iy * cell
				var width := 3 if (iy < 5) else 5 # legs narrower than the torso
				if iy >= 9:
					width = 3 # head
				if absi(ix - 2) > width / 2:
					continue
				var color := Color(0.9, 0.7, 0.55) if iy >= 9 else (Color(0.25, 0.4, 0.8) if iy >= 5 else Color(0.2, 0.2, 0.25))
				color = color.lightened(rng.randf_range(-0.12, 0.12))
				var bit := MeshInstance3D.new()
				var shape := BoxMesh.new()
				shape.size = Vector3.ONE * cell * 0.92
				bit.mesh = shape
				var material := StandardMaterial3D.new()
				material.albedo_color = color
				material.roughness = 0.6
				bit.material_override = material
				bit.position = inside + Vector3((ix - 2) * cell, y, (iz - 0.5) * cell)
				bit.set_meta(&"home", bit.position)
				pixels.add_child(bit)
				_bits.append(bit)


func scatter_pixels() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	for bit in _bits:
		var home: Vector3 = bit.get_meta(&"home")
		var target := home + Vector3(rng.randf_range(-1.6, 1.6), rng.randf_range(-0.2, 1.8), rng.randf_range(-0.4, 1.4))
		var delay := rng.randf_range(0.0, 0.35)
		var tween := create_tween().set_parallel(true)
		var span := SCATTER_TIME - delay
		tween.tween_property(bit, "position", target, span).set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(bit, "scale", Vector3.ONE * 0.05, span * 0.6).set_delay(delay + span * 0.4)
		tween.tween_property(bit, "rotation", Vector3(rng.randf() * 6.0, rng.randf() * 6.0, rng.randf() * 6.0), span).set_delay(delay)


# --- Stand-ins -------------------------------------------------------------------------

## A ~4 x 3 m browser window facing +Z (back at z = -0.5). Children the scene looks for:
## `Url` (Label3D in the address bar), `Progress` (loading bar, scaled in x), `PageLoading` and
## `PageError` (page contents), `PageTint` (page backing), `Inside` (Marker3D: where the
## trapped fighter's feet stand).
static func browser_window() -> Node3D:
	var root := Node3D.new()
	root.name = "BrowserWindow"
	var frame_mat := flat(Color(0.16, 0.18, 0.24))
	var y0 := 0.15 # bottom of the window
	# Page backing and frame (title bar, toolbar, border).
	var tint := SuperStandins.box(Vector3(3.8, 2.2, 0.04), Vector3(0, y0 + 1.1, -0.5), flat(PAGE_COLOR), "PageTint")
	root.add_child(tint)
	root.add_child(SuperStandins.box(Vector3(4.0, 0.4, 0.14), Vector3(0, y0 + 2.8, 0), flat(Color(0.1, 0.12, 0.18)), "TitleBar"))
	root.add_child(SuperStandins.box(Vector3(4.0, 0.36, 0.14), Vector3(0, y0 + 2.42, 0), frame_mat, "Toolbar"))
	for side in [-1.0, 1.0]:
		root.add_child(SuperStandins.box(Vector3(0.1, 2.2, 0.14), Vector3(1.95 * side, y0 + 1.1, 0), frame_mat))
	root.add_child(SuperStandins.box(Vector3(4.0, 0.1, 0.14), Vector3(0, y0 + 0.0, 0), frame_mat))
	# Close, maximise, minimise.
	for i in 3:
		var colors := [Color(0.95, 0.3, 0.28), Color(0.3, 0.8, 0.35), Color(0.98, 0.78, 0.2)]
		var dot := MeshInstance3D.new()
		var disc := CylinderMesh.new()
		disc.top_radius = 0.11
		disc.bottom_radius = 0.11
		disc.height = 0.04
		dot.mesh = disc
		dot.material_override = SuperStandins.glow(colors[i], 0.6)
		dot.rotation.x = PI * 0.5
		dot.position = Vector3(1.55 - 0.32 * i, y0 + 2.8, 0.09)
		root.add_child(dot)
	root.add_child(label("404 Not Found", 0.16, Color(0.9, 0.92, 1.0), Vector3(-1.1, y0 + 2.8, 0.09)))
	# Address bar with a funny URL, back and reload arrows.
	root.add_child(SuperStandins.box(Vector3(3.0, 0.24, 0.03), Vector3(0.35, y0 + 2.42, 0.09), flat(Color(1, 1, 1)), "AddressBar"))
	var url := label("", 0.13, Color(0.15, 0.2, 0.55), Vector3(-1.1, y0 + 2.42, 0.115))
	url.name = "Url"
	url.text = URL
	url.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	root.add_child(url)
	root.add_child(label("<  >  C", 0.17, Color(0.8, 0.82, 0.9), Vector3(-1.72, y0 + 2.42, 0.09)))
	var bar := SuperStandins.box(Vector3(3.0, 0.04, 0.03), Vector3(0.0, 0.0, 0.0), SuperStandins.glow(Color(0.26, 0.52, 0.96), 1.0), "ProgressBar")
	var progress := Node3D.new()
	progress.name = "Progress"
	progress.position = Vector3(-1.15, y0 + 2.27, 0.1)
	bar.position = Vector3(1.5, 0, 0)
	progress.add_child(bar)
	root.add_child(progress)
	# Page contents: "Loading..." first, then the error.
	var loading := Node3D.new()
	loading.name = "PageLoading"
	loading.add_child(label("Loading...", 0.28, Color(0.45, 0.45, 0.5), Vector3(0, y0 + 1.1, -0.44)))
	root.add_child(loading)
	var error := Node3D.new()
	error.name = "PageError"
	error.position = Vector3(0, y0 + 1.4, 0.06)
	error.add_child(label("404", 0.9, Color(0.95, 0.18, 0.18), Vector3(0, 0.45, 0)))
	error.add_child(label("SKILL NOT FOUND", 0.38, Color(0.9, 0.2, 0.2), Vector3(0, -0.25, 0)))
	error.add_child(label(":( Opponent encountered a fatal skill issue", 0.16, Color(0.35, 0.35, 0.4), Vector3(0, -0.62, 0)))
	root.add_child(error)
	var inside := Marker3D.new()
	inside.name = "Inside"
	inside.position = Vector3(0, y0 + 0.12, -0.25)
	root.add_child(inside)
	return root


static func floating_keyboard() -> Node3D:
	var root := Node3D.new()
	root.name = "Keyboard"
	root.add_child(SuperStandins.box(Vector3(1.2, 0.05, 0.4), Vector3.ZERO, SuperStandins.metal(Color(0.15, 0.16, 0.2), 0.6, 0.4)))
	var key_mat := SuperStandins.metal(Color(0.85, 0.87, 0.9), 0.1, 0.5)
	for row in 3:
		for col in 10:
			root.add_child(SuperStandins.box(Vector3(0.09, 0.03, 0.09), Vector3(-0.5 + col * 0.111, 0.04, -0.12 + row * 0.12), key_mat))
	root.add_child(SuperStandins.box(Vector3(1.22, 0.02, 0.42), Vector3(0, -0.04, 0), SuperStandins.glow(Color(0.26, 0.52, 0.96), 2.0)))
	return root


static func flat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.7
	return m


static func label(text: String, size: float, color: Color, position: Vector3) -> Label3D:
	var l := Label3D.new()
	l.font = preload("res://assets/fonts/InterDisplay-BlackItalic.otf")
	l.text = text
	l.font_size = 96
	l.pixel_size = size * 0.01
	l.modulate = color
	l.shaded = false
	l.outline_size = 8
	l.outline_modulate = Color(0.05, 0.05, 0.08)
	l.position = position
	return l
