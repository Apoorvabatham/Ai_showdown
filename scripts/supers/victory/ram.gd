extends VictoryScene
## Rama's victory (docs/ROADMAP.md §2): a massive "AGI ACHIEVED" banner unfurls
## across the arena with an extravagant fireworks display celebrating the breakthrough.

var banner_root: Node3D
var banner_cloth: Node3D
var banner_label: Label3D
var _centre := Vector3.ZERO
var _time := 0.0
var _banner_mat: StandardMaterial3D
var _frame_mat: StandardMaterial3D


func _init() -> void:
	own_set = false


func build() -> void:
	_centre = (attacker.global_position + defender.global_position) * 0.5
	if absf(_centre.x) > 6.0:
		_centre.x = 0.0

	_banner_mat = StandardMaterial3D.new()
	_banner_mat.albedo_color = Color(0.08, 0.1, 0.16)
	_banner_mat.roughness = 0.4
	_banner_mat.emission_enabled = true
	_banner_mat.emission = Color(0.05, 0.2, 0.35)
	_banner_mat.emission_energy_multiplier = 0.8

	_frame_mat = SuperStandins.glow(Color(0.2, 0.85, 1.0), 2.0)

	banner_root = Node3D.new()
	banner_root.name = "AgiBanner"
	add_child(banner_root)
	banner_root.global_position = _centre + Vector3(0.0, 9.5, -2.8) # Starts high above

	# Large hanging banner (width = 9.2 m, height = 2.4 m).
	banner_cloth = SuperStandins.box(Vector3(9.2, 2.4, 0.06), Vector3.ZERO, _banner_mat, "Cloth")
	banner_root.add_child(banner_cloth)

	# Neon tech frame glowing around the banner edges.
	banner_cloth.add_child(SuperStandins.box(Vector3(9.3, 0.08, 0.09), Vector3(0.0, 1.22, 0.0), _frame_mat))
	banner_cloth.add_child(SuperStandins.box(Vector3(9.3, 0.08, 0.09), Vector3(0.0, -1.22, 0.0), _frame_mat))
	banner_cloth.add_child(SuperStandins.box(Vector3(0.08, 2.4, 0.09), Vector3(-4.62, 0.0, 0.0), _frame_mat))
	banner_cloth.add_child(SuperStandins.box(Vector3(0.08, 2.4, 0.09), Vector3(4.62, 0.0, 0.0), _frame_mat))

	# Huge "AGI ACHIEVED" typography.
	banner_label = Label3D.new()
	banner_label.name = "AgiLabel"
	banner_label.text = "AGI ACHIEVED"
	banner_label.font_size = 180
	banner_label.pixel_size = 0.008
	banner_label.modulate = Color(1.0, 0.9, 0.25)
	banner_label.outline_size = 32
	banner_label.outline_modulate = Color(0.1, 0.5, 0.8)
	banner_label.shaded = false
	banner_label.position = Vector3(0.0, 0.0, 0.06)
	banner_cloth.add_child(banner_label)

	# Subtitle ticker.
	var sub_label := Label3D.new()
	sub_label.text = "COMPUTE SCALING LAW COMPLETE"
	sub_label.font_size = 54
	sub_label.pixel_size = 0.008
	sub_label.modulate = Color(0.4, 0.9, 1.0)
	sub_label.outline_size = 10
	sub_label.outline_modulate = Color(0.02, 0.05, 0.1)
	sub_label.shaded = false
	sub_label.position = Vector3(0.0, -0.85, 0.06)
	banner_cloth.add_child(sub_label)


func run() -> void:
	camera.fov = 58.0
	camera.global_position = _centre + Vector3(0.0, 2.2, 8.8)
	camera.look_at(_centre + Vector3(0.0, 3.2, -2.8))
	sound("victory")

	# Huge banner drops down into position with dramatic impact.
	var drop := create_tween()
	drop.tween_property(banner_root, "global_position:y", _centre.y + 4.2, 0.85).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	await wait(0.85)

	# Fireworks barrage around the triumphant banner.
	var colors := [Color(0.2, 0.85, 1.0), Color(1.0, 0.8, 0.2), Color(1.0, 0.2, 0.5), Color(0.4, 1.0, 0.5)]
	for i in 8:
		var side := -5.5 if i % 2 == 0 else 5.5
		var fx_pos := _centre + Vector3(side + randf_range(-1.5, 1.5), randf_range(5.0, 8.5), randf_range(-4.0, -1.0))
		_firework(fx_pos, colors[i % colors.size()])
		await wait(0.35)

	big_text("SINGULARITY UNLOCKED", _centre + Vector3(0.0, 6.2, -2.0), Color(0.3, 0.9, 1.0), 0.28)


func _process(delta: float) -> void:
	super(delta)
	_time += delta
	if banner_cloth:
		banner_cloth.rotation.y = sin(_time * 1.8) * 0.05
		banner_cloth.rotation.x = cos(_time * 1.4) * 0.03
	if camera and _time > 0.1 and attacker:
		camera.global_position.x = _centre.x + sin(_time * 0.2) * 0.8
		camera.look_at(_centre + Vector3(0.0, 3.2, -2.8))


func _firework(at: Vector3, color: Color) -> void:
	var flash := OmniLight3D.new()
	flash.light_color = color
	flash.light_energy = 4.5
	flash.omni_range = 15.0
	add_child(flash)
	flash.global_position = at

	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process.emission_sphere_radius = 0.25
	process.direction = Vector3.UP
	process.spread = 180.0
	process.initial_velocity_min = 5.0
	process.initial_velocity_max = 9.5
	process.gravity = Vector3(0, -3.2, 0)
	process.color = color

	var spark_mesh := QuadMesh.new()
	spark_mesh.size = Vector2(0.14, 0.14)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 3.5
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	spark_mesh.material = mat

	var particles := GPUParticles3D.new()
	particles.process_material = process
	particles.draw_pass_1 = spark_mesh
	particles.amount = 80
	particles.lifetime = 1.3
	particles.one_shot = true
	particles.explosiveness = 0.95
	particles.emitting = true
	add_child(particles)
	particles.global_position = at

	var tween := flash.create_tween()
	tween.tween_property(flash, "light_energy", 0.0, 0.9)
	tween.tween_callback(flash.queue_free)
	get_tree().create_timer(2.0).timeout.connect(particles.queue_free)
