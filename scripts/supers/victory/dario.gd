extends VictoryScene
## Dario Amodei's victory (docs/ROADMAP.md §2): on the stage itself, an ancient golden
## scroll unrolls above the arena displaying "Safe and helpful victory" with a golden aura.

var scroll_root: Node3D
var roller_left: Node3D
var roller_right: Node3D
var parchment: Node3D
var banner_label: Label3D
var seal: Node3D
var _centre := Vector3.ZERO
var _time := 0.0
var _gold_mat: StandardMaterial3D
var _parchment_mat: StandardMaterial3D


func _init() -> void:
	own_set = false


func build() -> void:
	_centre = (attacker.global_position + defender.global_position) * 0.5
	if absf(_centre.x) > 6.0:
		_centre.x = 0.0

	_gold_mat = SuperStandins.metal(Color(1.0, 0.8, 0.22), 0.95, 0.2)
	_gold_mat.emission_enabled = true
	_gold_mat.emission = Color(0.9, 0.7, 0.15)
	_gold_mat.emission_energy_multiplier = 0.6

	_parchment_mat = StandardMaterial3D.new()
	_parchment_mat.albedo_color = Color(0.96, 0.91, 0.76)
	_parchment_mat.roughness = 0.85
	_parchment_mat.emission_enabled = true
	_parchment_mat.emission = Color(0.98, 0.92, 0.7)
	_parchment_mat.emission_energy_multiplier = 0.2

	scroll_root = Node3D.new()
	scroll_root.name = "GoldenScroll"
	add_child(scroll_root)
	scroll_root.global_position = _centre + Vector3(0.0, 3.8, -2.5)

	# Central unrolling parchment sheet (width = 6.4 m, height = 2.2 m).
	parchment = SuperStandins.box(Vector3(6.4, 2.2, 0.05), Vector3.ZERO, _parchment_mat, "Parchment")
	scroll_root.add_child(parchment)
	# Gold border frames top and bottom.
	parchment.add_child(SuperStandins.box(Vector3(6.4, 0.1, 0.08), Vector3(0, 1.05, 0), _gold_mat))
	parchment.add_child(SuperStandins.box(Vector3(6.4, 0.1, 0.08), Vector3(0, -1.05, 0), _gold_mat))

	# Left and right wooden / golden scroll rollers.
	roller_left = _make_roller("RollerLeft")
	roller_right = _make_roller("RollerRight")
	scroll_root.add_child(roller_left)
	scroll_root.add_child(roller_right)

	# The golden motto text.
	banner_label = Label3D.new()
	banner_label.name = "Slogan"
	banner_label.font = preload("res://assets/fonts/InterDisplay-BlackItalic.otf")
	banner_label.text = "CONSTITUTIONAL VICTORY"
	banner_label.font_size = 96
	banner_label.pixel_size = 0.0055
	banner_label.modulate = Color(0.25, 0.12, 0.02)
	banner_label.outline_size = 14
	banner_label.outline_modulate = Color(1.0, 0.88, 0.35)
	banner_label.shaded = false
	banner_label.position = Vector3(0.0, 0.2, 0.06)
	parchment.add_child(banner_label)

	var sub_motto := Label3D.new()
	sub_motto.font = preload("res://assets/fonts/InterDisplay-BlackItalic.otf")
	sub_motto.text = "★ 100% HELPFUL & HARMLESS ★"
	sub_motto.font_size = 60
	sub_motto.pixel_size = 0.005
	sub_motto.modulate = Color(0.4, 0.22, 0.05)
	sub_motto.outline_size = 10
	sub_motto.outline_modulate = Color(1.0, 0.88, 0.4)
	sub_motto.shaded = false
	sub_motto.position = Vector3(0.0, -0.42, 0.06)
	parchment.add_child(sub_motto)

	# Gold/Red Constitutional Seal.
	seal = Node3D.new()
	seal.name = "SafetySeal"
	var seal_body := MeshInstance3D.new()
	var seal_cyl := CylinderMesh.new()
	seal_cyl.top_radius = 0.38
	seal_cyl.bottom_radius = 0.38
	seal_cyl.height = 0.08
	seal_body.mesh = seal_cyl
	seal_body.material_override = SuperStandins.metal(Color(0.85, 0.15, 0.15), 0.2, 0.4)
	seal_body.rotation.x = PI * 0.5
	seal.add_child(seal_body)

	var seal_text := Label3D.new()
	seal_text.font = preload("res://assets/fonts/InterDisplay-BlackItalic.otf")
	seal_text.text = "RLHF\nSAFE"
	seal_text.font_size = 54
	seal_text.pixel_size = 0.005
	seal_text.modulate = Color(1.0, 0.88, 0.2)
	seal_text.outline_size = 8
	seal_text.outline_modulate = Color(0.3, 0.02, 0.02)
	seal_text.position.z = 0.05
	seal.add_child(seal_text)
	seal.position = Vector3(2.4, -0.65, 0.06)
	parchment.add_child(seal)

	# Initial closed state: rollers touch in the middle, parchment scale.x is near zero.
	parchment.scale = Vector3(0.001, 1.0, 1.0)
	roller_left.position = Vector3(0.0, 0.0, 0.0)
	roller_right.position = Vector3(0.0, 0.0, 0.0)
	seal.scale = Vector3.ZERO


func run() -> void:
	camera.fov = 55.0
	camera.global_position = _centre + Vector3(0.0, 2.3, 8.2)
	camera.look_at(_centre + Vector3(0.0, 2.8, -2.5))
	sound("victory")

	# Scroll drops down into view while unrolling.
	var drop := create_tween().set_parallel()
	drop.tween_property(roller_left, "position:x", -3.2, 0.85).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	drop.tween_property(roller_right, "position:x", 3.2, 0.85).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	drop.tween_property(parchment, "scale:x", 1.0, 0.85).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await wait(0.9)

	# Seal stamps onto the scroll with a fanfare punch.
	var stamp := create_tween()
	stamp.tween_property(seal, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_gold_sparkles(_centre + Vector3(0.0, 3.8, -2.5))

	await wait(0.5)
	big_text("SAFETY COMPLIANT!", _centre + Vector3(0.0, 5.2, -2.0), Color(1.0, 0.88, 0.25), 0.8)


func _process(delta: float) -> void:
	super(delta)
	_time += delta
	if scroll_root:
		scroll_root.position.y = 3.8 + sin(_time * 1.6) * 0.08
	if camera and _time > 0.1 and attacker:
		camera.global_position.x = _centre.x + sin(_time * 0.22) * 0.8
		camera.look_at(_centre + Vector3(0.0, 2.8, -2.5))


func _make_roller(node_name: String) -> Node3D:
	var r := Node3D.new()
	r.name = node_name

	# Main roller spindle.
	var rod := MeshInstance3D.new()
	var rod_mesh := CylinderMesh.new()
	rod_mesh.top_radius = 0.12
	rod_mesh.bottom_radius = 0.12
	rod_mesh.height = 2.5
	rod.mesh = rod_mesh
	rod.material_override = _gold_mat
	r.add_child(rod)

	# Top and bottom finials.
	for y_off in [1.32, -1.32]:
		var knob := MeshInstance3D.new()
		var knob_sphere := SphereMesh.new()
		knob_sphere.radius = 0.18
		knob_sphere.height = 0.36
		knob.mesh = knob_sphere
		knob.material_override = _gold_mat
		knob.position.y = y_off
		r.add_child(knob)

	return r


func _gold_sparkles(at: Vector3) -> void:
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.85, 0.3)
	light.light_energy = 3.5
	light.omni_range = 8.0
	add_child(light)
	light.global_position = at

	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(3.2, 1.1, 0.2)
	process.direction = Vector3.UP
	process.spread = 45.0
	process.initial_velocity_min = 0.5
	process.initial_velocity_max = 2.0
	process.gravity = Vector3(0, -0.5, 0)
	process.color = Color(1.0, 0.9, 0.35)

	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.09, 0.09)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.85, 0.3)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.85, 0.3)
	mat.emission_energy_multiplier = 2.0
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mesh.material = mat

	var particles := GPUParticles3D.new()
	particles.process_material = process
	particles.draw_pass_1 = mesh
	particles.amount = 60
	particles.lifetime = 2.0
	particles.one_shot = true
	particles.emitting = true
	add_child(particles)
	particles.global_position = at

	var tween := light.create_tween()
	tween.tween_property(light, "light_energy", 0.8, 1.2)
	get_tree().create_timer(3.0).timeout.connect(particles.queue_free)
