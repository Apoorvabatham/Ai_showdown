extends VictoryScene
## Geoffrey Hinton's victory (docs/ROADMAP.md §2): a formal medal ceremony on an Olympic
## style podium, but Geoff maintains a perpetually worried, existential-dread expression.

var podium: Node3D
var geoff_puppet: ScenePuppet
var medal: Node3D
var _plaque: Node3D
var _centre := Vector3.ZERO
var _gold_mat: StandardMaterial3D
var _silver_mat: StandardMaterial3D
var _bronze_mat: StandardMaterial3D
var _podium_mat: StandardMaterial3D
var _time := 0.0


func _init() -> void:
	own_set = false


func build() -> void:
	_centre = (attacker.global_position + defender.global_position) * 0.5
	_centre.x = clampf(_centre.x, -2.5, 2.5)

	_gold_mat = SuperStandins.metal(Color(1.0, 0.82, 0.2), 0.95, 0.2)
	_silver_mat = SuperStandins.metal(Color(0.85, 0.86, 0.9), 0.9, 0.3)
	_bronze_mat = SuperStandins.metal(Color(0.8, 0.5, 0.25), 0.85, 0.4)
	_podium_mat = SuperStandins.metal(Color(0.18, 0.2, 0.24), 0.1, 0.6)

	podium = Node3D.new()
	podium.name = "AwardPodium"
	add_child(podium)
	podium.global_position = _centre + Vector3(0.0, -2.5, -1.0) # Starts lowered

	# 1st Place (Center, 1.3m high).
	var step1 := SuperStandins.box(Vector3(1.6, 1.3, 1.4), Vector3(0.0, 0.65, 0.0), _podium_mat, "Step1")
	step1.add_child(SuperStandins.box(Vector3(1.6, 0.12, 1.4), Vector3(0.0, 1.25, 0.0), _gold_mat))
	var label1 := _make_step_label("1", Color(1.0, 0.85, 0.2))
	label1.position = Vector3(0.0, 0.65, 0.72)
	step1.add_child(label1)
	podium.add_child(step1)

	# 2nd Place (Left, 0.85m high).
	var step2 := SuperStandins.box(Vector3(1.4, 0.85, 1.4), Vector3(-1.5, 0.425, 0.0), _podium_mat, "Step2")
	step2.add_child(SuperStandins.box(Vector3(1.4, 0.1, 1.4), Vector3(-1.5, 0.82, 0.0), _silver_mat))
	var label2 := _make_step_label("2", Color(0.85, 0.88, 0.92))
	label2.position = Vector3(-1.5, 0.425, 0.72)
	step2.add_child(label2)
	podium.add_child(step2)

	# 3rd Place (Right, 0.55m high).
	var step3 := SuperStandins.box(Vector3(1.4, 0.55, 1.4), Vector3(1.5, 0.275, 0.0), _podium_mat, "Step3")
	step3.add_child(SuperStandins.box(Vector3(1.4, 0.08, 1.4), Vector3(1.5, 0.52, 0.0), _bronze_mat))
	var label3 := _make_step_label("3", Color(0.8, 0.5, 0.25))
	label3.position = Vector3(1.5, 0.275, 0.72)
	step3.add_child(label3)
	podium.add_child(step3)

	# Hide the real fighters on stage so only the podium ceremony puppets appear
	attacker.visible = false
	defender.visible = false

	# Geoff puppet atop the 1st place podium.
	geoff_puppet = puppet(attacker, podium)
	geoff_puppet.position = Vector3(0.0, 1.3, 0.0)
	geoff_puppet.rotation.y = PI # Facing camera
	geoff_puppet.play(&"ual1/Idle")
	# Signature worried / existential dread face
	geoff_puppet.face = &"pain"

	# Opponent on the 2nd place podium (silver) looking defeated
	var loser_puppet := puppet(defender, podium)
	loser_puppet.position = Vector3(-1.5, 0.85, 0.0)
	loser_puppet.rotation.y = PI
	loser_puppet.play(&"ual1/Idle")
	loser_puppet.face = &"grimace"

	# Gold Medal on ribbon around Geoff's neck.
	medal = Node3D.new()
	medal.name = "GoldMedal"
	var disk := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.16
	cyl.bottom_radius = 0.16
	cyl.height = 0.03
	disk.mesh = cyl
	disk.material_override = _gold_mat
	disk.rotation.x = PI * 0.5
	medal.add_child(disk)
	# Ribbon ribbon loop
	var ribbon := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.14
	torus.outer_radius = 0.18
	ribbon.mesh = torus
	ribbon.material_override = SuperStandins.metal(Color(0.2, 0.25, 0.75), 0.0, 0.8)
	ribbon.position.y = 0.2
	medal.add_child(ribbon)

	geoff_puppet.add_child(medal)
	medal.position = Vector3(0.0, 1.25, 0.2)
	medal.scale = Vector3.ZERO

	_plaque = make_plaque("1ST PLACE!", "“I PROFOUNDLY REGRET MY LIFE'S WORK”", 5.8,
			Color(0.06, 0.07, 0.12), _gold_mat)
	_plaque.name = "CeremonyPlaque"
	add_child(_plaque)
	_plaque.global_position = _centre + Vector3(0.0, 3.65, -1.3)
	_plaque.scale = Vector3(0.001, 1.0, 1.0)
	_plaque.visible = false


func run() -> void:
	camera.fov = 46.0
	camera.global_position = _centre + Vector3(0.0, 2.25, 5.8)
	camera.look_at(_centre + Vector3(-0.15, 2.05, -1.0))
	sound("victory")

	# Podium rises with Geoff from below the arena floor.
	var rise := create_tween()
	rise.tween_property(podium, "global_position:y", _centre.y, 1.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await wait(1.1)

	# Medal ceremony fanfare: medal drops into place.
	var medal_tween := create_tween()
	medal_tween.tween_property(medal, "scale", Vector3.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await wait(0.4)

	# Confetti burst celebrating the winner.
	_confetti(_centre + Vector3(0.0, 4.2, -1.0))
	await wait(0.3)

	# Geoff continues to look deeply concerned about the future.
	geoff_puppet.face = &"pain"
	_plaque.visible = true
	var pop := create_tween()
	pop.tween_property(_plaque, "scale:x", 1.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	super(delta)
	_time += delta
	if geoff_puppet:
		# Perpetually worried expression
		geoff_puppet.face = &"pain"
	if camera and _time > 0.1 and attacker:
		camera.global_position.x = _centre.x + sin(_time * 0.2) * 0.55
		camera.look_at(_centre + Vector3(-0.15, 2.05, -1.0))


func _make_step_label(num: String, color: Color) -> Label3D:
	var l := Label3D.new()
	l.font = preload("res://assets/fonts/InterDisplay-BlackItalic.otf")
	l.text = num
	l.font_size = 140
	l.pixel_size = 0.008
	l.modulate = color
	l.outline_size = 20
	l.outline_modulate = Color(0.02, 0.02, 0.05)
	l.shaded = false
	return l


func _confetti(at: Vector3) -> void:
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(4.0, 0.2, 2.0)
	process.direction = Vector3.DOWN
	process.spread = 35.0
	process.initial_velocity_min = 1.0
	process.initial_velocity_max = 2.5
	process.gravity = Vector3(0, -2.0, 0)
	process.color = Color(1.0, 0.82, 0.2)

	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.14, 0.18)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.82, 0.2)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.7, 0.15)
	mat.emission_energy_multiplier = 1.2
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mesh.material = mat

	var particles := GPUParticles3D.new()
	particles.process_material = process
	particles.draw_pass_1 = mesh
	particles.amount = 100
	particles.lifetime = 3.0
	particles.one_shot = true
	particles.emitting = true
	add_child(particles)
	particles.global_position = at


func _exit_tree() -> void:
	if attacker and is_instance_valid(attacker):
		attacker.visible = true
	if defender and is_instance_valid(defender):
		defender.visible = true
