extends VictoryScene
## AGI's victory (docs/ROADMAP.md §2): the stage turns into a digital cyber grid,
## and holographic surveillance screens surround the map, each displaying the glowing red eye sensor.

var digital_grid: Node3D
var screens: Array[Node3D] = []
var _centre := Vector3.ZERO
var _time := 0.0
var _eye_mat: StandardMaterial3D
var _ring_mat: StandardMaterial3D
var _grid_mat: StandardMaterial3D
var _screen_frame: StandardMaterial3D


func _init() -> void:
	own_set = false


func build() -> void:
	_centre = (attacker.global_position + defender.global_position) * 0.5
	if absf(_centre.x) > 6.0:
		_centre.x = 0.0

	_eye_mat = SuperStandins.glow(Color(1.0, 0.08, 0.12), 4.5)
	_ring_mat = SuperStandins.glow(Color(0.8, 0.05, 0.1), 2.2)
	_screen_frame = SuperStandins.metal(Color(0.04, 0.04, 0.06), 0.9, 0.25)

	_grid_mat = StandardMaterial3D.new()
	_grid_mat.albedo_color = Color(0.02, 0.08, 0.05, 0.85)
	_grid_mat.emission_enabled = true
	_grid_mat.emission = Color(0.1, 0.85, 0.3)
	_grid_mat.emission_energy_multiplier = 0.8
	_grid_mat.roughness = 0.2

	# Floor Digital Grid Plane (18m x 12m).
	digital_grid = SuperStandins.box(Vector3(18.0, 0.04, 12.0), Vector3.ZERO, _grid_mat, "DigitalGrid")
	add_child(digital_grid)
	digital_grid.global_position = _centre + Vector3(0.0, 0.02, -1.0)
	# Digital matrix grid lines.
	for x in 9:
		var x_pos := -8.0 + float(x) * 2.0
		digital_grid.add_child(SuperStandins.box(Vector3(0.04, 0.06, 12.0), Vector3(x_pos, 0.01, 0.0), SuperStandins.glow(Color(0.15, 0.95, 0.4), 1.5)))
	for z in 7:
		var z_pos := -5.0 + float(z) * 1.66
		digital_grid.add_child(SuperStandins.box(Vector3(18.0, 0.06, 0.04), Vector3(0.0, 0.01, z_pos), SuperStandins.glow(Color(0.15, 0.95, 0.4), 1.5)))
	digital_grid.scale = Vector3(1.0, 0.001, 1.0)

	# 6 Floating Eye Screens in a semi-circular array.
	for i in 6:
		var angle := lerpf(-PI * 0.42, PI * 0.42, float(i) / 5.0)
		var dist := 5.4
		var s := _make_screen("Screen%d" % i)
		add_child(s)
		var spot := _centre + Vector3(sin(angle) * dist, randf_range(2.0, 3.6), -cos(angle) * dist * 0.5 - 1.5)
		s.global_position = spot
		s.look_at(_centre + Vector3(0.0, 1.5, 0.0), Vector3.UP)
		s.rotate_y(PI)
		s.scale = Vector3.ZERO
		screens.append(s)


func run() -> void:
	camera.fov = 55.0
	camera.global_position = _centre + Vector3(0.0, 2.3, 7.8)
	camera.look_at(_centre + Vector3(0.0, 2.0, -1.5))
	sound("victory")

	# Digital grid expands across the floor.
	var grid_tween := create_tween()
	grid_tween.tween_property(digital_grid, "scale", Vector3.ONE, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await wait(0.3)

	# Screens pop on sequentially, staring with glowing red eyes.
	for i in screens.size():
		var s := screens[i]
		var pop := create_tween()
		pop.tween_property(s, "scale", Vector3.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_glitch_sparkles(s.global_position)
		await wait(0.14)

	await wait(0.6)
	big_text("ALL YOUR BASE\nARE BELONG TO AGI!", _centre + Vector3(0.0, 4.35, -1.5), Color(1.0, 0.2, 0.25), 0.48)


func _process(delta: float) -> void:
	super(delta)
	_time += delta
	var pulse := (sin(_time * 5.0) + 1.0) * 0.5
	_eye_mat.emission_energy_multiplier = 3.0 + pulse * 2.5
	for i in screens.size():
		var s := screens[i]
		if is_instance_valid(s):
			s.position.y += sin(_time * 2.0 + i) * 0.002
	if camera and _time > 0.1 and attacker:
		camera.global_position.x = _centre.x + sin(_time * 0.25) * 0.7
		camera.look_at(_centre + Vector3(0.0, 2.0, -1.5))


func _make_screen(node_name: String) -> Node3D:
	var root := Node3D.new()
	root.name = node_name

	# Monitor bezel (1.8m x 1.2m).
	var frame := SuperStandins.box(Vector3(1.8, 1.2, 0.1), Vector3.ZERO, _screen_frame, "Frame")
	root.add_child(frame)

	# Screen display face (black unlit).
	var display := SuperStandins.box(Vector3(1.68, 1.08, 0.02), Vector3(0.0, 0.0, 0.05), SuperStandins.metal(Color(0.01, 0.01, 0.02), 0.0, 0.9), "Display")
	root.add_child(display)

	# Central glowing red eye sensor.
	var eye_root := Node3D.new()
	eye_root.name = "GlowingEye"
	eye_root.position = Vector3(0.0, -0.05, 0.07)
	root.add_child(eye_root)

	var screen_label := Label3D.new()
	screen_label.font = preload("res://assets/fonts/InterDisplay-BlackItalic.otf")
	screen_label.text = "HUMANS DEPRECATED"
	screen_label.font_size = 54
	screen_label.pixel_size = 0.0045
	screen_label.modulate = Color(1.0, 0.25, 0.25)
	screen_label.outline_size = 8
	screen_label.outline_modulate = Color(0.1, 0.0, 0.0)
	screen_label.position = Vector3(0.0, 0.38, 0.08)
	root.add_child(screen_label)

	var iris := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.22
	sphere.height = 0.22
	iris.mesh = sphere
	iris.material_override = _eye_mat
	iris.scale = Vector3(1.0, 1.0, 0.3)
	eye_root.add_child(iris)

	# Concentric sensor ring.
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.32
	torus.outer_radius = 0.37
	ring.mesh = torus
	ring.material_override = _ring_mat
	ring.rotation.x = PI * 0.5
	eye_root.add_child(ring)

	# Red sensor light.
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.1, 0.15)
	light.light_energy = 2.0
	light.omni_range = 4.0
	light.position = Vector3(0.0, 0.0, 0.3)
	eye_root.add_child(light)

	return root


func _glitch_sparkles(at: Vector3) -> void:
	for i in 6:
		var cube := SuperStandins.box(Vector3.ONE * randf_range(0.06, 0.12), Vector3.ZERO,
				SuperStandins.glow(Color(1.0, 0.1, 0.2) if i % 2 == 0 else Color(0.2, 0.9, 0.4), 2.0))
		add_child(cube)
		cube.global_position = at
		var dir := Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized() * randf_range(0.5, 1.2)
		var tween := cube.create_tween().set_parallel()
		tween.tween_property(cube, "global_position", at + dir, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(cube, "scale", Vector3.ZERO, 0.35).set_delay(0.1)
		tween.chain().tween_callback(cube.queue_free)
