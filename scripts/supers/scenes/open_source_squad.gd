extends SuperScene
## Xi's super (docs/ROADMAP.md §2, owner-approved): he calls his squad, three made-up young
## engineers in T-shirts reading Qwen, Alibaba and Kimi run in from all sides and beat the
## opponent up, then launch them together.
##
## The helpers are data/npcs/helper_qwen|helper_alibaba|helper_kimi.tres (OpenCode, task O5)
## when they exist; until then, stand-ins from the original 3D Fighter cast with the shirt
## word floating on their chest.

const HELPERS := [
	["helper_qwen", "Qwen", "res://data/kits/kenji.tres", Color(0.45, 0.35, 1.0)],
	["helper_alibaba", "Alibaba", "res://data/kits/jin.tres", Color(1.0, 0.45, 0.1)],
	["helper_kimi", "Kimi", "res://data/kits/mira.tres", Color(0.15, 0.15, 0.15)],
]
const CALL_TIME := 0.8
const RUN_TIME := 0.9
const BEAT_TIME := 2.1
const FINISH_TIME := 1.2
const LENGTH := CALL_TIME + RUN_TIME + BEAT_TIME + FINISH_TIME
## Where the helpers stand around the opponent, in the set's space: on the far side of
## them from the cameras (+Z), so their shirts face the camera.
const RING := [Vector3(-1.4, 0, -0.75), Vector3(0.15, 0, -1.3), Vector3(1.55, 0, -0.7)]
const PUNCHES := [&"ual1/Punch_Jab", &"ual1/Punch_Cross", &"fight/front_kick", &"fight/backfist"]

var xi: ScenePuppet
var victim: ScenePuppet
var helpers: Array[ScenePuppet] = []


func build() -> void:
	var plaza := load_set("xi_plaza")
	victim = puppet(defender, plaza)
	victim.global_transform = marker("xi_plaza", "Opponent")
	xi = puppet(attacker, plaza)
	xi.global_transform = marker("xi_plaza", "Attacker")
	_face(xi, victim.global_position)
	_face(victim, xi.global_position)
	victim.play(&"fight/guard")
	for i in HELPERS.size():
		var spec: Array = HELPERS[i]
		var npc := "res://data/npcs/%s.tres" % spec[0]
		var data := load(npc if ResourceLoader.exists(npc) else spec[2]) as CharacterData
		var helper := puppet_of(data, plaza)
		helper.global_transform = marker("xi_plaza", "Helper_%d_Start" % (i + 1))
		if not ResourceLoader.exists(npc):
			_shirt_word(helper, spec[1], spec[3])
		helpers.append(helper)


func run() -> void:
	show_set("xi_plaza")
	# He calls the squad.
	shot("xi_plaza", "Cam_Close", xi.global_position + Vector3(0, 1.5, 0))
	xi.play(&"fight/intro_power")
	xi.face = &"shout"
	sound("gong_strike")
	big_text("SQUAD ASSEMBLE!", xi.global_position + Vector3(0.0, 3.2, 0.0), Color(1.0, 0.2, 0.15), 0.9, CALL_TIME - 0.2)
	await wait(CALL_TIME)

	# They sprint in from all sides; the opponent looks around.
	shot("xi_plaza", "Cam_Wide", victim.global_position + Vector3(0, 1.0, 0))
	sound("footsteps_sprint")
	victim.face = &"surprise"
	for i in helpers.size():
		var helper := helpers[i]
		var spot := _ring_spot(i)
		_face(helper, spot)
		helper.play(&"ual1/Sprint")
		var run := create_tween()
		run.tween_property(helper, "global_position", spot, RUN_TIME).set_trans(Tween.TRANS_SINE)
	await wait(RUN_TIME)

	# The beat-down: everyone swings in turn, the opponent reels.
	for helper in helpers:
		_face(helper, victim.global_position)
	victim.face = &"pain"
	sound("punch_flurry")
	var beats := 9
	for n in beats:
		var helper := helpers[n % helpers.size()]
		helper.play(PUNCHES[n % PUNCHES.size()], 1.6)
		helper.face = &"effort"
		victim.hold(&"ual1/Hit_Chest" if n % 2 == 0 else &"ual1/Hit_Head", 0.15)
		victim.model.flash(Color(1, 1, 1), 0.12)
		_impact(victim.global_position + Vector3(0, 1.3, 0) + (helper.global_position - victim.global_position).normalized() * 0.3)
		if n == 3:
			shot("xi_plaza", "Cam_Close", victim.global_position + Vector3(0, 1.2, 0))
		await wait(BEAT_TIME / beats)

	# All together: the launch.
	shot("xi_plaza", "Cam_Low")
	track = victim
	track_offset = Vector3(0, 1.0, 0)
	for helper in helpers:
		helper.play(&"fight/uppercut")
		helper.face = &"shout"
	xi.play(&"fight/victory_point")
	xi.face = &"grin"
	victim.play(&"fight/thrown", 1.4)
	victim.face = &"out"
	big_text("100% OPEN SOURCE!", victim.global_position + Vector3(0, 3.5, 0), Color(1.0, 0.85, 0.2), 0.85)
	var fly := create_tween()
	fly.tween_property(victim, "global_position", victim.global_position + Vector3(0, 6.0, -1.0), FINISH_TIME) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	fly.parallel().tween_property(victim, "rotation:x", -TAU, FINISH_TIME)


## A helper's place in the ring around the opponent.
func _ring_spot(i: int) -> Vector3:
	return victim.global_position + (RING[i] as Vector3)


func _face(p: ScenePuppet, target: Vector3) -> void:
	var look := target
	look.y = p.global_position.y
	if look.distance_squared_to(p.global_position) > 0.001:
		p.look_at(look)


## Stand-in shirt print: the word floating on the helper's chest (front = -Z).
func _shirt_word(helper: ScenePuppet, word: String, color: Color) -> void:
	var label := Label3D.new()
	label.font = preload("res://assets/fonts/InterDisplay-BlackItalic.otf")
	label.text = word
	label.font_size = 96
	label.pixel_size = 0.004
	label.modulate = color.lightened(0.5)
	label.outline_size = 14
	label.outline_modulate = Color(0.05, 0.05, 0.05)
	label.position = Vector3(0, 1.3, -0.26)
	label.rotation.y = PI
	label.shaded = false
	helper.add_child(label)


## A quick star-burst at a punch.
func _impact(at: Vector3) -> void:
	var star := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.18
	mesh.height = 0.36
	star.mesh = mesh
	star.material_override = SuperStandins.glow(Color(1.0, 0.9, 0.5), 5.0, 0.9)
	add_child(star)
	star.global_position = at
	var pop := star.create_tween()
	pop.tween_property(star, "scale", Vector3.ONE * 2.2, 0.12)
	pop.parallel().tween_property(star, "transparency", 1.0, 0.12)
	pop.tween_callback(star.queue_free)
