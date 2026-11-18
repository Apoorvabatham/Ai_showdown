extends SuperScene
## Donald Tarrif's super "Shower of Tariffs" (docs/ROADMAP.md §2, owner-approved): in an
## office he grows into a giant while the opponent shrinks to a few inches and cowers on his
## desk; he raises a giant rubber stamp and slams it down on them, papers burst, and the
## desk shows a big red "TARIFF" mark with the opponent flattened in it (cartoon, no gore).
##
## Timeline: about 5.7 s; MoveData.cinematic_ticks must cover it (tools/showdown_movesets.gd).

const GROW_TIME := 0.9
const COWER_TIME := 1.1
const RAISE_TIME := 1.0
const SLAM_TIME := 0.18
const AFTER_TIME := 2.5
const LENGTH := GROW_TIME + COWER_TIME + RAISE_TIME + SLAM_TIME + AFTER_TIME

const GIANT := 2.6
const TINY := 0.42
const DESK_Y := 1.12

var donald: ScenePuppet
var victim: ScenePuppet
var stamp: Node3D
var mark: Node3D
var _shake := 0.0


func build() -> void:
	var office := load_set("oval_desk")
	donald = puppet(attacker, office)
	donald.global_transform = marker("oval_desk", "Attacker")
	donald.play(&"ual1/Idle")
	donald.face = &"smirk"
	victim = puppet(defender, office)
	victim.global_transform = marker("oval_desk", "Attacker")
	victim.position = Vector3(0, 0, 0.8)
	victim.play(&"ual1/Idle")
	victim.face = &"surprise"
	stamp = prop("donald/tariff_stamp", _stamp_standin, office)
	stamp.global_position = marker("oval_desk", "Stamp").origin + Vector3(0, 7.5, 0)
	stamp.visible = false
	mark = prop("donald/tariff_mark", _mark_standin, office)
	mark.global_position = marker("oval_desk", "Stamp").origin + Vector3(0, 0.012, 0)
	mark.visible = false


func run() -> void:
	show_set("oval_desk")
	var desk := marker("oval_desk", "Stamp").origin
	# 1. Both start life-size; he swells up, they shrink and hop onto the desk.
	shot("oval_desk", "Cam_Wide", desk + Vector3(0, 2.4, -1.0))
	sound("paper_flutter")
	var grow := create_tween().set_parallel(true)
	grow.tween_property(donald, "scale", Vector3.ONE * GIANT, GROW_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	grow.tween_property(victim, "scale", Vector3.ONE * TINY, GROW_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var hop := create_tween()
	hop.tween_property(victim, "global_position", marker("oval_desk", "Opponent").origin + Vector3(0, 1.2, 0), GROW_TIME * 0.6) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	hop.tween_property(victim, "global_position", marker("oval_desk", "Opponent").origin, GROW_TIME * 0.4) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	donald.play(&"fight/victory_flex")
	donald.face = &"roar"
	big_text("TREMENDOUS!", desk + Vector3(2.2, 4.4, 0), Color(1.0, 0.94, 0.72), 0.85, GROW_TIME)
	await wait(GROW_TIME)

	# 2. Close on the tiny opponent, cowering, the giant looming behind.
	victim.rotation = Vector3(0, PI, 0) # looks up at him
	victim.play(&"fight/crouch_guard")
	victim.face = &"pain"
	donald.face = &"smirk"
	donald.play(&"ual1/Idle")
	shot("oval_desk", "Cam_Cower", desk + Vector3(0, 0.4, 0.0))
	await wait(COWER_TIME)

	# 3. He raises the giant stamp.
	shot("oval_desk", "Cam_Wide", desk + Vector3(0, 3.6, -1.0))
	stamp.visible = true
	donald.play(&"fight/victory_fist_pump")
	donald.face = &"shout"
	var raise := create_tween()
	raise.tween_property(stamp, "global_position:y", desk.y + 4.2, RAISE_TIME).from(desk.y + 7.5) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	sound("paper_flutter", -6.0)
	await wait(RAISE_TIME)

	# 4. SLAM.
	shot("oval_desk", "Cam_Slam", desk + Vector3(0, 1.1, 0))
	var slam := create_tween()
	slam.tween_property(stamp, "global_position:y", desk.y, SLAM_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	donald.play(&"fight/ground_pound")
	await wait(SLAM_TIME)
	_impact(desk)
	await wait(0.35)

	# 5. The stamp lifts: the opponent is flat in a red TARIFF mark.
	shot("oval_desk", "Cam_Desk", desk + Vector3(0, 0.9, -0.6))
	var lift := create_tween()
	lift.tween_property(stamp, "global_position:y", desk.y + 4.8, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	big_text("500% TARIFFED!", desk + Vector3(0, 1.4, 0.4), Color(1.0, 0.28, 0.28), 0.75)
	donald.play(&"fight/victory_flex")
	donald.face = &"grin"
	await wait(AFTER_TIME - 0.35)


func _impact(desk: Vector3) -> void:
	sound("stamp_thud")
	_shake = 0.35
	mark.visible = true
	victim.scale = Vector3(TINY * 1.5, 0.04, TINY * 1.5) # squashed flat
	victim.global_position = desk + Vector3(0.0, 0.0, -0.45) # behind the printed word
	victim.face = &"dazed"
	victim.hold(&"fight/wall_splat", 0.3)
	victim.model.flash(Color(1.0, 0.2, 0.1), 0.4)
	_burst(desk + Vector3(0, 0.4, 0), 60, 7.0, Color(1, 1, 1), true) # papers
	_burst(desk + Vector3(0, 0.4, 0), 30, 6.0, Color(1.0, 0.25, 0.2), false) # red confetti


func _process(delta: float) -> void:
	super(delta)
	if camera:
		_shake = move_toward(_shake, 0.0, delta * 0.7)
		camera.h_offset = randf_range(-1.0, 1.0) * _shake
		camera.v_offset = randf_range(-1.0, 1.0) * _shake


## A one-shot burst of flat paper / confetti pieces flying up and fluttering down.
func _burst(at: Vector3, amount: int, speed: float, color: Color, rainbow: bool) -> void:
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(0.8, 0.1, 0.5)
	process.direction = Vector3.UP
	process.spread = 55.0
	process.initial_velocity_min = speed * 0.4
	process.initial_velocity_max = speed
	process.gravity = Vector3(0, -5.0, 0)
	process.angle_min = -180.0
	process.angle_max = 180.0
	process.angular_velocity_min = -300.0
	process.angular_velocity_max = 300.0
	process.damping_min = 0.5
	process.damping_max = 1.5
	process.color = color
	if rainbow:
		process.hue_variation_min = 0.0
		process.hue_variation_max = 0.0
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.13, 0.17)
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED
	mesh.material = material
	var particles := GPUParticles3D.new()
	particles.process_material = process
	particles.draw_pass_1 = mesh
	particles.amount = amount
	particles.lifetime = 2.2
	particles.one_shot = true
	particles.explosiveness = 0.95
	particles.local_coords = false
	particles.emitting = true
	add_child(particles)
	particles.global_position = at
	get_tree().create_timer(3.0).timeout.connect(particles.queue_free)


## Stand-in stamp: wooden knob and handle on a red block whose underside reads TARIFF.
## Origin = the middle of the block's underside (what touches the desk).
func _stamp_standin() -> Node3D:
	var root := Node3D.new()
	root.name = "TariffStamp"
	var wood := SuperStandins.metal(Color(0.4, 0.22, 0.1), 0.0, 0.5)
	var red := SuperStandins.metal(Color(0.8, 0.08, 0.08), 0.0, 0.6)
	root.add_child(SuperStandins.box(Vector3(1.7, 0.55, 1.2), Vector3(0, 0.275, 0), red, "Block"))
	root.add_child(SuperStandins.box(Vector3(1.9, 0.12, 1.4), Vector3(0, 0.6, 0), wood))
	var handle := MeshInstance3D.new()
	var rod := CylinderMesh.new()
	rod.top_radius = 0.16
	rod.bottom_radius = 0.2
	rod.height = 1.4
	handle.mesh = rod
	handle.material_override = wood
	handle.position.y = 1.4
	root.add_child(handle)
	var knob := MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = 0.38
	ball.height = 0.76
	knob.mesh = ball
	knob.material_override = wood
	knob.position.y = 2.2
	root.add_child(knob)
	var label := Label3D.new()
	label.font = preload("res://assets/fonts/InterDisplay-BlackItalic.otf")
	label.text = "★ TARIFF 500% ★"
	label.font_size = 110
	label.pixel_size = 0.005
	label.modulate = Color(1, 1, 1)
	label.outline_size = 8
	label.outline_modulate = Color(0.2, 0.02, 0.02)
	label.double_sided = false
	label.shaded = false
	label.rotation_degrees = Vector3(90, 0, 0) # faces down
	label.position = Vector3(0, -0.01, 0)
	root.add_child(label)
	return root


## Stand-in mark left on the desk: a flat red slab with TARIFF in it.
func _mark_standin() -> Node3D:
	var root := Node3D.new()
	root.name = "TariffMark"
	root.add_child(SuperStandins.box(Vector3(2.6, 0.01, 1.4), Vector3.ZERO, SuperStandins.metal(Color(0.85, 0.1, 0.1), 0.0, 0.9)))
	root.add_child(SuperStandins.box(Vector3(2.4, 0.012, 1.2), Vector3.ZERO, SuperStandins.metal(Color(0.97, 0.93, 0.85), 0.0, 0.9)))
	var label := Label3D.new()
	label.font = preload("res://assets/fonts/InterDisplay-BlackItalic.otf")
	label.text = "★ TARIFF 500% ★\nPAID IN FULL"
	label.font_size = 96
	label.pixel_size = 0.0042
	label.modulate = Color(0.85, 0.08, 0.08)
	label.outline_size = 10
	label.outline_modulate = Color(0.25, 0.02, 0.02)
	label.shaded = false
	label.rotation_degrees = Vector3(-90, 0, 0) # faces up, the stamp's text read from the front
	label.position = Vector3(0, 0.014, 0)
	root.add_child(label)
	return root
