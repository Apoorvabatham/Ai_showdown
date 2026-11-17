extends VictoryScene
## Donald Tarrif's victory (docs/ROADMAP.md §2, owner-approved): on the stage itself, golden
## statues of him rise out of the floor around the map, USA flags pop up everywhere, gold
## confetti rains down and the crowd chants. The fighters stay where they are.

const STATUE_COUNT := 5
const STATUE_SCALE := 1.35
const FLAG_SPOTS := [
	Vector2(-9.5, 1.5), Vector2(9.5, 1.5), Vector2(-8.5, -3.0), Vector2(8.5, -3.0),
	Vector2(-5.2, -6.2), Vector2(5.2, -6.2), Vector2(-3.4, 3.6), Vector2(3.4, 3.6),
]

var winner: ScenePuppet # unused: the real fighters are on the stage
var statues: Array[ScenePuppet] = []
var flags: Array[Node3D] = []
var _gold: StandardMaterial3D
var _centre := Vector3.ZERO
var _time := 0.0


func _init() -> void:
	own_set = false


func build() -> void:
	_centre = (attacker.global_position + defender.global_position) * 0.5
	_centre.x = 0.0 if absf(_centre.x) > 6.0 else _centre.x
	_gold = SuperStandins.metal(Color(1.0, 0.76, 0.2), 1.0, 0.22)
	_gold.emission_enabled = true
	_gold.emission = Color(0.9, 0.6, 0.1)
	_gold.emission_energy_multiplier = 0.35
	for i in STATUE_COUNT:
		var t := float(i) / float(STATUE_COUNT - 1)
		var spot := Vector3(lerpf(-7.0, 7.0, t), 0.0, -4.0)
		var base := Node3D.new() # pedestal + statue, rises together
		base.name = "StatueBase%d" % i
		add_child(base)
		base.global_position = _centre + spot - Vector3(0, 2.6, 0)
		base.add_child(SuperStandins.box(Vector3(1.3, 0.8, 1.3), Vector3(0, 0.4, 0), SuperStandins.metal(Color(0.9, 0.88, 0.82), 0.0, 0.5)))
		base.add_child(SuperStandins.box(Vector3(1.45, 0.14, 1.45), Vector3(0, 0.07, 0), _gold))
		var statue := puppet(attacker, base)
		statue.position = Vector3(0, 0.8, 0)
		statue.scale = Vector3.ONE * STATUE_SCALE
		statue.rotation.y = PI + (0.5 - t) * 0.5 # facing the camera, a little inward
		statue.hold(&"fight/victory_point", 0.7)
		statue.face = &"grin"
		_goldify(statue)
		statues.append(statue)
	for spot: Vector2 in FLAG_SPOTS:
		var flag := prop("donald/us_flag", _flag_standin)
		flag.global_position = _centre + Vector3(spot.x, 0.0, spot.y)
		flag.scale = Vector3.ONE * 0.001
		flags.append(flag)


func run() -> void:
	camera.fov = 55.0
	camera.global_position = _centre + Vector3(0.0, 2.7, 9.5)
	camera.look_at(_centre + Vector3(0.0, 2.0, -3.0))
	sound("victory")
	var rise_end := 0.0
	# Flags pop up around the edges, first the near ones, then the statues rise.
	for i in flags.size():
		var pop := create_tween()
		pop.tween_interval(0.12 * i)
		pop.tween_property(flags[i], "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	sound("usa_chant", -3.0)
	await wait(0.5)
	for i in statues.size():
		var base := statues[i].get_parent() as Node3D
		var rise := create_tween()
		rise.tween_interval(0.18 * i)
		rise.tween_property(base, "global_position:y", _centre.y, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		rise_end = 0.18 * i + 0.7
		get_tree().create_timer(0.18 * i).timeout.connect(_dust.bind(base.global_position))
	_confetti()
	_goldify_all() # late model pieces (hair, accessories) get the gold too
	await wait(rise_end)
	_confetti()
	await wait(1.6)
	_confetti()
	# Held: the camera keeps drifting slowly behind the result menu (see _process).


func _process(delta: float) -> void:
	super(delta)
	_time += delta
	for i in flags.size():
		var cloth := flags[i].find_child("Cloth", true, false) as Node3D
		if cloth:
			cloth.rotation.y = sin(_time * 3.0 + i) * 0.18
	if camera and _time > 0.1 and attacker:
		camera.global_position.x = _centre.x + sin(_time * 0.25) * 1.6
		camera.look_at(_centre + Vector3(0.0, 2.0, -3.0))


func _goldify(statue: ScenePuppet) -> void:
	for mesh: MeshInstance3D in statue.find_children("*", "MeshInstance3D", true, false):
		mesh.material_override = _gold


func _goldify_all() -> void:
	for statue in statues:
		_goldify(statue)


func _dust(at: Vector3) -> void:
	var dust := SuperStandins.smoke_particles(0.8, 1.0)
	add_child(dust)
	dust.global_position = Vector3(at.x, _centre.y + 0.1, at.z)
	get_tree().create_timer(2.0).timeout.connect(dust.queue_free)


## Gold confetti raining over the whole map.
func _confetti() -> void:
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(10.0, 0.2, 5.0)
	process.direction = Vector3.DOWN
	process.spread = 25.0
	process.initial_velocity_min = 1.0
	process.initial_velocity_max = 3.0
	process.gravity = Vector3(0, -2.5, 0)
	process.angle_min = -180.0
	process.angle_max = 180.0
	process.angular_velocity_min = -240.0
	process.angular_velocity_max = 240.0
	process.color = Color(1.0, 0.8, 0.25)
	process.hue_variation_min = -0.04
	process.hue_variation_max = 0.04
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.18, 0.26)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.8, 0.25)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.7, 0.15)
	material.emission_energy_multiplier = 1.5
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.material = material
	var particles := GPUParticles3D.new()
	particles.process_material = process
	particles.draw_pass_1 = mesh
	particles.amount = 220
	particles.lifetime = 3.5
	particles.one_shot = true
	particles.explosiveness = 0.3
	particles.local_coords = false
	particles.emitting = true
	particles.visibility_aabb = AABB(Vector3(-20, -12, -20), Vector3(40, 24, 40))
	add_child(particles)
	particles.global_position = _centre + Vector3(0, 8.0, -1.5)
	get_tree().create_timer(5.0).timeout.connect(particles.queue_free)


## Stand-in USA flag: a pole with a striped cloth and a blue canton (`Cloth` waves).
func _flag_standin() -> Node3D:
	var root := Node3D.new()
	root.name = "UsaFlag"
	var pole := MeshInstance3D.new()
	var rod := CylinderMesh.new()
	rod.top_radius = 0.04
	rod.bottom_radius = 0.05
	rod.height = 4.2
	pole.mesh = rod
	pole.material_override = SuperStandins.metal(Color(0.85, 0.85, 0.88), 0.9, 0.3)
	pole.position.y = 2.1
	root.add_child(pole)
	var ball := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.09
	sphere.height = 0.18
	ball.mesh = sphere
	ball.material_override = SuperStandins.metal(Color(1.0, 0.8, 0.2), 1.0, 0.3)
	ball.position.y = 4.25
	root.add_child(ball)
	var cloth := Node3D.new() # hinged at the pole, so it can swing
	cloth.name = "Cloth"
	cloth.position = Vector3(0.0, 3.75, 0.0)
	root.add_child(cloth)
	var red := SuperStandins.metal(Color(0.8, 0.1, 0.18), 0.0, 0.8)
	var white := SuperStandins.metal(Color(0.97, 0.97, 0.97), 0.0, 0.8)
	var stripe := 1.4 / 7.0 # 7 stripes, 2.1 x 1.4 m
	for i in 7:
		cloth.add_child(SuperStandins.box(Vector3(2.1, stripe, 0.03), Vector3(1.05, 0.7 - stripe * (i + 0.5), 0.0), red if i % 2 == 0 else white))
	cloth.add_child(SuperStandins.box(Vector3(0.9, stripe * 4, 0.04), Vector3(0.45, 0.7 - stripe * 2.0, 0.0), SuperStandins.metal(Color(0.1, 0.15, 0.5), 0.0, 0.8)))
	for row in 3: # a few stars on the canton
		for col in 3:
			cloth.add_child(SuperStandins.box(Vector3(0.07, 0.07, 0.05), Vector3(0.15 + col * 0.3, 0.7 - 0.2 - row * 0.2, 0.0), white))
	return root
