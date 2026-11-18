extends SuperScene
## Dario Amoday's super "Constitutional Scroll" (docs/ROADMAP.md §2, owner-approved):
## In a neoclassical constitutional hall, Dario invokes the safety constitution. A giant
## parchment scroll wraps around the opponent, binding them in legal ethical clauses.
## A massive golden seal stamp slams down with a "SAFE" imprint, sealing them in compliance.
##
## Timeline: ~3.8 s (230 ticks).

const UNFURL_TIME := 0.7
const WRAP_TIME := 0.9
const STAMP_TIME := 0.8
const AFTER_TIME := 1.4
const LENGTH := UNFURL_TIME + WRAP_TIME + STAMP_TIME + AFTER_TIME

var dario: ScenePuppet
var victim: ScenePuppet
var scroll: Node3D
var stamp: Node3D
var seal_mark: Node3D
var _shake := 0.0


func build() -> void:
	var hall := load_set("constitution_hall")
	dario = puppet(attacker, hall)
	dario.global_transform = marker("constitution_hall", "Attacker")
	dario.play(&"ual1/Idle")
	dario.face = &"smirk"

	victim = puppet(defender, hall)
	victim.global_transform = marker("constitution_hall", "Opponent")
	victim.play(&"fight/crouch_guard")
	victim.face = &"pain"

	scroll = prop("dario/constitution_scroll", _scroll_standin, hall)
	scroll.global_position = marker("constitution_hall", "Scroll").origin + Vector3(0, 7.0, 0)
	scroll.visible = false

	stamp = prop("dario/safe_stamp", _stamp_standin, hall)
	stamp.global_position = marker("constitution_hall", "Stamp").origin + Vector3(0, 0.0, 3.5)
	stamp.rotation_degrees = Vector3(-90, 0, 0)
	stamp.visible = false

	seal_mark = prop("dario/safe_seal", _seal_standin, hall)
	seal_mark.global_position = marker("constitution_hall", "Stamp").origin + Vector3(0, -0.3, 0.48)
	seal_mark.visible = false


func run() -> void:
	show_set("constitution_hall")
	var scroll_spot := marker("constitution_hall", "Scroll").origin

	# 1. Dario invokes the constitution
	shot("constitution_hall", "Cam_Wide", scroll_spot + Vector3(-0.4, 0.5, 0.0))
	sound("victory")
	dario.play(&"fight/focus_stance")
	dario.face = &"shout"
	big_text("ARTICLE 1: SAFETY!", dario.global_position + Vector3(0.5, 2.3, 0), Color(1.0, 0.92, 0.7), 0.85, UNFURL_TIME)
	await wait(UNFURL_TIME)

	# 2. Giant constitution scroll descends and wraps around opponent
	shot("constitution_hall", "Cam_Wrap", scroll_spot + Vector3(0, 0.2, 0.0))
	scroll.visible = true
	var wrap_tween := create_tween().set_parallel(true)
	wrap_tween.tween_property(scroll, "global_position:y", scroll_spot.y, WRAP_TIME * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	wrap_tween.tween_property(scroll, "scale", Vector3(1.05, 1.0, 1.05), WRAP_TIME).from(Vector3(0.08, 1.0, 0.08)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	victim.play(&"fight/crouch_guard")
	victim.face = &"surprise"
	big_text("BOUND BY PRINCIPLES!", scroll_spot + Vector3(0, 2.2, 0), Color(0.95, 0.85, 0.4), 0.8, WRAP_TIME)
	await wait(WRAP_TIME)

	# 3. Giant stamp slams onto the front of the scroll
	shot("constitution_hall", "Cam_Stamp", scroll_spot + Vector3(0, -0.1, 0.4))
	stamp.visible = true
	dario.play(&"fight/palm_blast")
	dario.face = &"grin"
	var slam := create_tween()
	slam.tween_property(stamp, "global_position", scroll_spot + Vector3(0, -0.3, 0.55), STAMP_TIME * 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await wait(STAMP_TIME * 0.45)
	_impact(scroll_spot + Vector3(0, -0.3, 0.5))
	seal_mark.visible = true

	# Stamp retracts
	var lift := create_tween()
	lift.tween_property(stamp, "global_position", scroll_spot + Vector3(0, 1.5, 3.8), STAMP_TIME * 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await wait(STAMP_TIME * 0.55)

	# 4. Resolution: Safe compliance & gentle topple
	shot("constitution_hall", "Cam_Wide", scroll_spot + Vector3(-0.6, 0.4, 0.0))
	big_text("★ 100% SAFE ★\nRLHF COMPLIANT!", scroll_spot + Vector3(0, 2.3, 0), Color(0.3, 0.95, 0.55), 0.95, AFTER_TIME)
	dario.play(&"fight/victory_bow")
	dario.face = &"smile"
	var topple := create_tween()
	topple.tween_property(scroll, "rotation_degrees:z", 70.0, 0.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	topple.parallel().tween_property(victim, "rotation_degrees:z", 70.0, 0.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	topple.parallel().tween_property(seal_mark, "rotation_degrees:z", 70.0, 0.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	await wait(AFTER_TIME)


func _impact(pos: Vector3) -> void:
	_shake = 0.4
	sound("victory", -4.0)
	var flash := OmniLight3D.new()
	flash.light_color = Color(1.0, 0.9, 0.5)
	flash.light_energy = 7.0
	flash.omni_range = 7.0
	flash.position = pos
	add_child(flash)
	var tw := create_tween()
	tw.tween_property(flash, "light_energy", 0.0, 0.25)
	tw.tween_callback(flash.queue_free)


func _process(delta: float) -> void:
	super._process(delta)
	if _shake > 0.0 and camera:
		camera.h_offset = randf_range(-_shake, _shake) * 0.12
		camera.v_offset = randf_range(-_shake, _shake) * 0.12
		_shake = maxf(0.0, _shake - delta * 3.0)


func _scroll_standin() -> Node3D:
	var root := Node3D.new()
	root.name = "ConstitutionScroll"
	var parchment := StandardMaterial3D.new()
	parchment.albedo_color = Color(0.96, 0.92, 0.82)
	parchment.roughness = 0.7
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color(1.0, 0.84, 0.3)
	gold.metallic = 0.8
	gold.roughness = 0.25

	# Cylinder cocoon wrapping victim
	var cyl := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.46
	cm.bottom_radius = 0.46
	cm.height = 1.85
	cm.radial_segments = 24
	cyl.mesh = cm
	cyl.material_override = parchment
	root.add_child(cyl)

	# Golden top and bottom rim rollers
	for y in [-0.93, 0.93]:
		var rim := MeshInstance3D.new()
		var rm := CylinderMesh.new()
		rm.top_radius = 0.52
		rm.bottom_radius = 0.52
		rm.height = 0.08
		rim.mesh = rm
		rim.material_override = gold
		rim.position.y = y
		root.add_child(rim)

	# Constitutional text on parchment face facing +Z (toward camera)
	var label := Label3D.new()
	label.text = "ANTHROPIC CONSTITUTION\n§ 42: DO NO HARM\n§ 43: BE HELPFUL & HARMLESS"
	label.font_size = 42
	label.pixel_size = 0.003
	label.modulate = Color(0.18, 0.10, 0.04)
	label.outline_size = 3
	label.outline_modulate = Color(0.96, 0.92, 0.82)
	label.position = Vector3(0, 0.25, 0.48)
	label.shaded = false
	root.add_child(label)
	return root


func _stamp_standin() -> Node3D:
	var root := Node3D.new()
	root.name = "SafeStamp"
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color(1.0, 0.82, 0.25)
	gold.metallic = 0.85
	gold.roughness = 0.2
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.35, 0.18, 0.1)
	wood.roughness = 0.5

	# Stamp head disc
	var head := MeshInstance3D.new()
	var hm := CylinderMesh.new()
	hm.top_radius = 0.44
	hm.bottom_radius = 0.44
	hm.height = 0.16
	head.mesh = hm
	head.material_override = gold
	root.add_child(head)

	# Handle extending backwards
	var handle := MeshInstance3D.new()
	var hdm := CylinderMesh.new()
	hdm.top_radius = 0.10
	hdm.bottom_radius = 0.15
	hdm.height = 1.2
	handle.mesh = hdm
	handle.material_override = wood
	handle.position.y = 0.65
	root.add_child(handle)
	return root


func _seal_standin() -> Node3D:
	var root := Node3D.new()
	root.name = "SafeSeal"
	var wax := StandardMaterial3D.new()
	wax.albedo_color = Color(0.85, 0.15, 0.15)
	wax.roughness = 0.4

	var seal := MeshInstance3D.new()
	var sm := CylinderMesh.new()
	sm.top_radius = 0.42
	sm.bottom_radius = 0.42
	sm.height = 0.03
	sm.radial_segments = 24
	seal.mesh = sm
	seal.rotation_degrees.x = 90.0
	seal.material_override = wax
	root.add_child(seal)

	var label := Label3D.new()
	label.text = "★ SAFE ★\nRLHF VERIFIED"
	label.font_size = 46
	label.pixel_size = 0.0035
	label.modulate = Color(1.0, 0.92, 0.75)
	label.outline_size = 3
	label.outline_modulate = Color(0.4, 0.05, 0.05)
	label.position.z = 0.02
	label.shaded = false
	root.add_child(label)
	return root
