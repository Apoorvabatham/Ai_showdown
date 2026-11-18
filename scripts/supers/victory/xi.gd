extends VictoryScene
## Xi Winping's victory (docs/ROADMAP.md §2): on the stage itself, festive red lanterns
## rise into the sky around the fighters while colourful fireworks burst above.

const LANTERN_COUNT := 14
const LANTERN_RADIUS := 0.28
const LANTERN_HEIGHT := 0.65

var lanterns: Array[Node3D] = []
var _lantern_speeds: Array[float] = []
var _centre := Vector3.ZERO
var _time := 0.0
var _red_paper: StandardMaterial3D
var _gold_trim: StandardMaterial3D


func _init() -> void:
	own_set = false


func build() -> void:
	_centre = (attacker.global_position + defender.global_position) * 0.5
	if absf(_centre.x) > 6.0:
		_centre.x = 0.0

	_red_paper = StandardMaterial3D.new()
	_red_paper.albedo_color = Color(0.92, 0.12, 0.12)
	_red_paper.emission_enabled = true
	_red_paper.emission = Color(1.0, 0.25, 0.1)
	_red_paper.emission_energy_multiplier = 1.4
	_red_paper.roughness = 0.5

	_gold_trim = SuperStandins.metal(Color(1.0, 0.82, 0.2), 0.9, 0.25)

	# Arrange lanterns around the arena at varying radii and angles.
	for i in LANTERN_COUNT:
		var angle := float(i) / float(LANTERN_COUNT) * TAU + randf_range(-0.15, 0.15)
		var dist := randf_range(3.2, 7.5)
		var lantern := _make_lantern()
		add_child(lantern)
		var spawn_pos := _centre + Vector3(cos(angle) * dist, randf_range(0.2, 1.2), sin(angle) * dist * 0.6 - 1.5)
		lantern.global_position = spawn_pos
		lanterns.append(lantern)
		_lantern_speeds.append(randf_range(1.4, 2.6))


func run() -> void:
	camera.fov = 58.0
	camera.global_position = _centre + Vector3(0.0, 2.5, 9.2)
	camera.look_at(_centre + Vector3(0.0, 3.2, -2.0))
	sound("victory")
	sound("gong_strike", -2.0)

	# Lanterns rise gracefully into the sky.
	for i in lanterns.size():
		var l := lanterns[i]
		var rise := create_tween()
		var target_y := l.global_position.y + randf_range(7.0, 11.0)
		var duration := randf_range(3.2, 4.8)
		rise.tween_property(l, "global_position:y", target_y, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	await wait(0.4)
	big_text("VICTORY", _centre + Vector3(0.0, 4.5, -2.0), Color(1.0, 0.85, 0.2), 0.35)

	# Sequential fireworks bursts in the night sky.
	for f in 6:
		var fx_pos := _centre + Vector3(randf_range(-6.0, 6.0), randf_range(5.5, 9.0), randf_range(-5.0, -1.0))
		var color := Color(1.0, 0.2, 0.2) if f % 2 == 0 else Color(1.0, 0.85, 0.2)
		_firework(fx_pos, color)
		await wait(0.45)


func _process(delta: float) -> void:
	super(delta)
	_time += delta
	for i in lanterns.size():
		var l := lanterns[i]
		if is_instance_valid(l):
			l.rotation.y = sin(_time * 1.2 + i * 0.7) * 0.2
			l.position.x += sin(_time * 2.0 + i) * 0.003
	if camera and _time > 0.1 and attacker:
		camera.global_position.x = _centre.x + sin(_time * 0.2) * 1.2
		camera.look_at(_centre + Vector3(0.0, 3.0, -2.0))


func _make_lantern() -> Node3D:
	var root := Node3D.new()
	root.name = "RedLantern"

	# Lantern main glowing red body.
	var body := MeshInstance3D.new()
	var body_mesh := CylinderMesh.new()
	body_mesh.top_radius = LANTERN_RADIUS * 0.75
	body_mesh.bottom_radius = LANTERN_RADIUS * 0.75
	body_mesh.height = LANTERN_HEIGHT
	body.mesh = body_mesh
	body.material_override = _red_paper
	body.position.y = LANTERN_HEIGHT * 0.5
	root.add_child(body)

	# Ribs / rings: middle bulge.
	var middle_ring := MeshInstance3D.new()
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = LANTERN_RADIUS * 0.78
	ring_mesh.outer_radius = LANTERN_RADIUS * 0.95
	middle_ring.mesh = ring_mesh
	middle_ring.material_override = _gold_trim
	middle_ring.position.y = LANTERN_HEIGHT * 0.5
	root.add_child(middle_ring)

	# Top and bottom gold caps.
	var top_cap := MeshInstance3D.new()
	var cap_mesh := CylinderMesh.new()
	cap_mesh.top_radius = LANTERN_RADIUS * 0.4
	cap_mesh.bottom_radius = LANTERN_RADIUS * 0.8
	cap_mesh.height = 0.08
	top_cap.mesh = cap_mesh
	top_cap.material_override = _gold_trim
	top_cap.position.y = LANTERN_HEIGHT + 0.04
	root.add_child(top_cap)

	var bot_cap := MeshInstance3D.new()
	var bot_mesh := CylinderMesh.new()
	bot_mesh.top_radius = LANTERN_RADIUS * 0.8
	bot_mesh.bottom_radius = LANTERN_RADIUS * 0.4
	bot_mesh.height = 0.08
	bot_cap.mesh = bot_mesh
	bot_cap.material_override = _gold_trim
	bot_cap.position.y = -0.04
	root.add_child(bot_cap)

	# Hanging golden tassel.
	var tassel := MeshInstance3D.new()
	var tassel_mesh := CylinderMesh.new()
	tassel_mesh.top_radius = 0.03
	tassel_mesh.bottom_radius = 0.06
	tassel_mesh.height = 0.26
	tassel.mesh = tassel_mesh
	tassel.material_override = _gold_trim
	tassel.position.y = -0.21
	root.add_child(tassel)

	# Warm inner light.
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.35, 0.1)
	light.light_energy = 0.8
	light.omni_range = 3.5
	light.position.y = LANTERN_HEIGHT * 0.5
	root.add_child(light)

	return root


func _firework(at: Vector3, color: Color) -> void:
	var flash := OmniLight3D.new()
	flash.light_color = color
	flash.light_energy = 4.0
	flash.omni_range = 14.0
	add_child(flash)
	flash.global_position = at

	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process.emission_sphere_radius = 0.3
	process.direction = Vector3.UP
	process.spread = 180.0
	process.initial_velocity_min = 4.0
	process.initial_velocity_max = 8.5
	process.gravity = Vector3(0, -3.5, 0)
	process.color = color

	var spark_mesh := QuadMesh.new()
	spark_mesh.size = Vector2(0.12, 0.12)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 3.0
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	spark_mesh.material = mat

	var particles := GPUParticles3D.new()
	particles.process_material = process
	particles.draw_pass_1 = spark_mesh
	particles.amount = 90
	particles.lifetime = 1.2
	particles.one_shot = true
	particles.explosiveness = 0.95
	particles.emitting = true
	add_child(particles)
	particles.global_position = at

	var tween := flash.create_tween()
	tween.tween_property(flash, "light_energy", 0.0, 0.8)
	tween.tween_callback(flash.queue_free)
	get_tree().create_timer(1.8).timeout.connect(particles.queue_free)
