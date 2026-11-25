extends VictoryScene
## Yann LeCun's victory (docs/ROADMAP.md §2): on the stage itself, a giant stylized cat
## walks across the arena floor and sits down comfortably next to him.

var cat: Node3D
var cat_body: Node3D
var leg_fl: Node3D
var leg_fr: Node3D
var leg_bl: Node3D
var leg_br: Node3D
var tail: Node3D
var _plaque: Node3D
var _centre := Vector3.ZERO
var _walking := false
var _sitting := false
var _time := 0.0
var _fur_mat: StandardMaterial3D
var _white_fur: StandardMaterial3D
var _eye_mat: StandardMaterial3D


func _init() -> void:
	own_set = false


func build() -> void:
	_centre = (attacker.global_position + defender.global_position) * 0.5
	_centre.x = clampf(_centre.x, -2.5, 2.5)

	_fur_mat = StandardMaterial3D.new()
	_fur_mat.albedo_color = Color(0.88, 0.52, 0.22) # Orange tabby
	_fur_mat.roughness = 0.8

	_white_fur = StandardMaterial3D.new()
	_white_fur.albedo_color = Color(0.96, 0.95, 0.92) # White paws & muzzle
	_white_fur.roughness = 0.85

	_eye_mat = StandardMaterial3D.new()
	_eye_mat.albedo_color = Color(0.2, 0.85, 0.4) # Emerald cat eyes
	_eye_mat.emission_enabled = true
	_eye_mat.emission = Color(0.2, 0.9, 0.4)
	_eye_mat.emission_energy_multiplier = 1.2

	cat = _make_cat()
	add_child(cat)
	# Spawns from the left flank behind the fighters so it never clips through Yann while walking.
	cat.global_position = _centre + Vector3(-9.2, 0.0, -1.6)
	cat.look_at(cat.global_position + Vector3(1.0, 0.0, 0.0), Vector3.UP)

	var trim := SuperStandins.glow(Color(0.35, 1.0, 0.65), 1.6)
	_plaque = make_plaque("WORLD MODELS > LLMs!", "“THE CAT HAS MORE COMMON SENSE THAN YOUR LLM”", 6.2,
			Color(0.04, 0.10, 0.12), trim, Color(0.35, 1.0, 0.65))
	_plaque.name = "WorldModelPlaque"
	add_child(_plaque)
	_plaque.global_position = _centre + Vector3(0.0, 3.15, -1.6)
	_plaque.scale = Vector3(0.001, 1.0, 1.0)
	_plaque.visible = false


func run() -> void:
	var winner_pos := attacker.global_position
	camera.fov = 48.0
	camera.global_position = _centre + Vector3(0.0, 2.0, 6.4)
	camera.look_at(_centre + Vector3(0.0, 1.35, -0.6))
	sound("victory")

	_walking = true
	var walk_dest := winner_pos + Vector3(2.2, 0.0, -1.0)
	cat.look_at(cat.global_position + (walk_dest - cat.global_position).normalized(), Vector3.UP)

	# Walk across the arena toward Yann.
	var walk := create_tween()
	walk.tween_property(cat, "global_position", walk_dest, 1.4).set_trans(Tween.TRANS_LINEAR)
	await wait(1.4)

	# Cat stops and faces the camera.
	_walking = false
	var turn := create_tween()
	turn.tween_property(cat, "rotation:y", PI * 0.15, 0.3)
	await wait(0.3)

	# Cat sits down next to Yann.
	_sit_down()
	await wait(0.3)

	_plaque.visible = true
	var pop := create_tween()
	pop.tween_property(_plaque, "scale:x", 1.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	super(delta)
	_time += delta

	if _walking:
		# Walking cycle: alternating legs swing.
		var walk_cycle := sin(_time * 8.0)
		if leg_fl and leg_br:
			leg_fl.rotation.x = walk_cycle * 0.45
			leg_br.rotation.x = walk_cycle * 0.45
		if leg_fr and leg_bl:
			leg_fr.rotation.x = -walk_cycle * 0.45
			leg_bl.rotation.x = -walk_cycle * 0.45
		if cat_body:
			cat_body.position.y = 0.9 + absf(sin(_time * 8.0)) * 0.06
		if tail:
			tail.rotation.z = sin(_time * 4.0) * 0.25

	elif _sitting:
		# Idle tail sway while seated.
		if tail:
			tail.rotation.z = sin(_time * 2.2) * 0.2
			tail.rotation.x = 0.4 + cos(_time * 1.8) * 0.1
		if cat_body:
			cat_body.position.y = 0.62 + sin(_time * 2.0) * 0.02

	if camera and _time > 0.1 and attacker:
		camera.global_position.x = _centre.x + sin(_time * 0.18) * 0.55
		camera.look_at(_centre + Vector3(0.0, 1.35, -0.6))


func _sit_down() -> void:
	_sitting = true
	var sit_tween := create_tween().set_parallel()
	# Lower rear body, hind legs fold, front legs stay upright.
	sit_tween.tween_property(cat_body, "position:y", 0.62, 0.4).set_trans(Tween.TRANS_SINE)
	sit_tween.tween_property(cat_body, "rotation:x", -0.22, 0.4).set_trans(Tween.TRANS_SINE)
	sit_tween.tween_property(leg_bl, "rotation:x", -1.2, 0.4)
	sit_tween.tween_property(leg_br, "rotation:x", -1.2, 0.4)
	sit_tween.tween_property(leg_fl, "rotation:x", 0.1, 0.4)
	sit_tween.tween_property(leg_fr, "rotation:x", 0.1, 0.4)


func _make_cat() -> Node3D:
	var root := Node3D.new()
	root.name = "GiantCat"
	root.scale = Vector3.ONE * 1.45

	cat_body = Node3D.new()
	cat_body.name = "Body"
	cat_body.position.y = 0.9
	root.add_child(cat_body)

	# Main torso (length = 1.4 m, radius = 0.42 m).
	var torso := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.38
	cap.height = 1.35
	torso.mesh = cap
	torso.material_override = _fur_mat
	torso.rotation.x = PI * 0.5
	cat_body.add_child(torso)

	# Cat head (round, with cheeks).
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.34
	sphere.height = 0.62
	head.mesh = sphere
	head.material_override = _fur_mat
	head.position = Vector3(0.0, 0.28, 0.72)
	cat_body.add_child(head)

	# Triangular ears.
	for ear_x: float in [-0.22, 0.22]:
		var ear := MeshInstance3D.new()
		var prism := PrismMesh.new()
		prism.size = Vector3(0.18, 0.24, 0.08)
		ear.mesh = prism
		ear.material_override = _fur_mat
		ear.position = Vector3(ear_x, 0.54, 0.68)
		ear.rotation.z = -0.18 if ear_x > 0 else 0.18
		cat_body.add_child(ear)

	# Glowing cat eyes.
	for eye_x: float in [-0.14, 0.14]:
		var eye := MeshInstance3D.new()
		var eye_sphere := SphereMesh.new()
		eye_sphere.radius = 0.075
		eye_sphere.height = 0.13
		eye.mesh = eye_sphere
		eye.material_override = _eye_mat
		eye.position = Vector3(eye_x, 0.34, 0.98)
		cat_body.add_child(eye)

	# Muzzle (white snout).
	var muzzle := MeshInstance3D.new()
	var muz_mesh := SphereMesh.new()
	muz_mesh.radius = 0.13
	muz_mesh.height = 0.18
	muzzle.mesh = muz_mesh
	muzzle.material_override = _white_fur
	muzzle.position = Vector3(0.0, 0.2, 0.99)
	cat_body.add_child(muzzle)

	# Tail.
	tail = Node3D.new()
	tail.name = "Tail"
	tail.position = Vector3(0.0, 0.15, -0.68)
	var tail_mesh := CylinderMesh.new()
	tail_mesh.top_radius = 0.06
	tail_mesh.bottom_radius = 0.09
	tail_mesh.height = 0.9
	var t_inst := MeshInstance3D.new()
	t_inst.mesh = tail_mesh
	t_inst.material_override = _fur_mat
	t_inst.position.y = 0.42
	t_inst.rotation.x = -0.35
	tail.add_child(t_inst)
	cat_body.add_child(tail)

	# Legs: Front Left, Front Right, Back Left, Back Right.
	leg_fl = _make_leg("LegFL", Vector3(-0.25, 0.0, 0.42))
	leg_fr = _make_leg("LegFR", Vector3(0.25, 0.0, 0.42))
	leg_bl = _make_leg("LegBL", Vector3(-0.26, 0.0, -0.42))
	leg_br = _make_leg("LegBR", Vector3(0.26, 0.0, -0.42))
	root.add_child(leg_fl)
	root.add_child(leg_fr)
	root.add_child(leg_bl)
	root.add_child(leg_br)

	return root


func _make_leg(node_name: String, offset: Vector3) -> Node3D:
	var leg_root := Node3D.new()
	leg_root.name = node_name
	leg_root.position = Vector3(offset.x, 0.85, offset.z)

	var limb := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.11
	cyl.bottom_radius = 0.09
	cyl.height = 0.75
	limb.mesh = cyl
	limb.material_override = _fur_mat
	limb.position.y = -0.37
	leg_root.add_child(limb)

	var paw := MeshInstance3D.new()
	var paw_sph := SphereMesh.new()
	paw_sph.radius = 0.12
	paw_sph.height = 0.16
	paw.mesh = paw_sph
	paw.material_override = _white_fur
	paw.position = Vector3(0.0, -0.76, 0.04)
	leg_root.add_child(paw)

	return leg_root
