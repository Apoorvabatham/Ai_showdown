extends SuperScene
## Mark Zuckerbot's super "Metaverse Trap" (docs/ROADMAP.md §2, owner-approved): VR goggles
## fly onto the opponent's face, a glitch cut takes them to a cartoon metaverse where their
## legs are "not found", and his big-headed avatar punches them (LIKE, SHARE, ...) before a
## big glitch-out.
##
## Timeline: about 6.1 s; MoveData.cinematic_ticks must cover it (tools/showdown_movesets.gd).

const Fx := preload("res://scripts/supers/zuckerbot_fx.gd")

const INTRO_TIME := 0.35
const FLY_TIME := 0.35
const WEAR_TIME := 0.8
const CUT_TIME := 0.3
const WELCOME_TIME := 0.7
const LEGS_TIME := 1.0
const PUNCH_TIME := 0.38
const PUNCHES := 5
const OUT_TIME := 0.7
const LENGTH := INTRO_TIME + FLY_TIME + WEAR_TIME + CUT_TIME + WELCOME_TIME + LEGS_TIME + PUNCH_TIME * PUNCHES + OUT_TIME

const LEG_FLICKER := [1.0, 0.55, 1.0, 0.3, 0.7, 0.1, 0.4, 0.0]
const HIT_WORDS := ["LIKE", "SHARE", "FOLLOW", "ENGAGE", "BLOCKED!"]

var zuck: ScenePuppet
var victim: ScenePuppet
var goggles: Node3D
var glitch: Fx.Glitch
var _legs := 1.0
var _head := 1.0


func _init() -> void:
	process_priority = 50 # after the puppets animate: legs and head scale are set on top


func build() -> void:
	load_set("vr_lobby", Vector3(0, 0, 300))
	load_set("metaverse", Vector3(0, 0, -300))
	glitch = Fx.Glitch.new()
	add_child(glitch)
	victim = puppet(defender, _sets["vr_lobby"])
	victim.global_transform = marker("vr_lobby", "Victim")
	victim.hold(&"fight/guard", 0.0)
	zuck = puppet(attacker, _sets["vr_lobby"])
	zuck.global_transform = marker("vr_lobby", "Attacker")
	zuck.hold(&"fight/victory_point", 0.0)
	zuck.face = &"grin"
	goggles = prop("zuckerbot/vr_goggles", Fx.goggles)
	goggles.visible = false


func _process(delta: float) -> void:
	super(delta)
	if victim and victim.model:
		Fx.legs(victim.model, _legs)
	if zuck and zuck.model:
		Fx.big_head(zuck.model, _head)


func run() -> void:
	# 1. Neutral room: he throws the goggles, they land on the opponent's face.
	show_set("vr_lobby")
	var victim_eyes := victim.global_position + Vector3(0, 1.55, 0)
	shot("vr_lobby", "Cam_Face", victim_eyes + Vector3(-0.3, -0.1, 0))
	victim.play(&"fight/guard")
	zuck.play(&"ual1/Interact")
	await wait(INTRO_TIME)
	sound("vr_powerup")
	goggles.visible = true
	goggles.global_position = zuck.global_position + Vector3(0.0, 1.4, 0.4)
	goggles.scale = Vector3.ONE * 2.0
	var fly := create_tween().set_parallel()
	if victim.model.has_gaze():
		victim_eyes = victim.model.eye_position()
	fly.tween_property(goggles, "global_position", victim_eyes + Vector3(0, 0, 0.0), FLY_TIME) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fly.tween_property(goggles, "rotation_degrees:y", -90.0, FLY_TIME)
	await wait(FLY_TIME)
	fly.kill()
	goggles.visible = true
	Fx.wear(victim.model, goggles)
	sound("digital_glitch")
	victim.face = &"pain"
	victim.hold(&"ual1/Hit_Head", 0.2)
	victim.model.flash(Color(0.3, 0.9, 1.0), 0.5)
	glitch.burst(0.25)
	Fx.pixels(self, victim_eyes, 12, 1.2)
	big_text("LOADING...", victim_eyes + Vector3(-0.2, 0.45, 0.4), Color(0.4, 0.95, 1.0), 0.15, WEAR_TIME - 0.1)
	await wait(WEAR_TIME)

	# 2. Glitch cut to the metaverse.
	glitch.burst(CUT_TIME)
	await wait(CUT_TIME * 0.5)
	show_set("metaverse")
	victim.reparent(_sets["metaverse"])
	victim.global_transform = marker("metaverse", "Victim")
	zuck.reparent(_sets["metaverse"])
	zuck.global_transform = marker("metaverse", "Attacker")
	zuck.visible = false # his avatar logs in later
	victim.play(&"ual1/Idle")
	victim.face = &"neutral"
	var spot := victim.global_position
	shot("metaverse", "Cam_Welcome", spot + Vector3(0, 0.5, 0))
	sound("teleport", -4.0)
	await wait(CUT_TIME * 0.5)
	big_text("WELCOME TO THE METAVERSE", spot + Vector3(-0.5, 2.5, 0), Color(1.0, 0.75, 0.9), 0.14, WELCOME_TIME - 0.1)
	await wait(WELCOME_TIME)

	# 3. The legs go missing.
	shot("metaverse", "Cam_Legs", spot + Vector3(0, 1.0, 0))
	victim.face = &"pain"
	sound("digital_glitch", -3.0)
	for value: float in LEG_FLICKER:
		_legs = value
		if value <= 0.5:
			Fx.pixels(self, spot + Vector3(0, 0.4, 0), 5, 1.0)
		await wait(LEGS_TIME * 0.5 / LEG_FLICKER.size())
	big_text("404", spot + Vector3(0.0, 1.7, 0.6), Color(1.0, 0.45, 0.6), 0.3, LEGS_TIME * 0.5)
	big_text("LEGS NOT FOUND", spot + Vector3(0.0, 1.5, 0.6), Color(1.0, 1.0, 1.0), 0.12, LEGS_TIME * 0.5)
	# His avatar logs in (bigger head), in a puff of pixels.
	await wait(LEGS_TIME * 0.5)
	zuck.visible = true
	_head = 1.3
	zuck.play(&"fight/guard")
	zuck.face = &"grin"
	sound("teleport", -2.0)
	glitch.burst(0.15)
	Fx.pixels(self, zuck.global_position + Vector3(0, 1.2, 0), 16, 1.8)

	# 4. The avatar punches them: jab, cross, jab, cross, ...
	var clips := [&"ual1/Punch_Jab", &"ual1/Punch_Cross", &"ual1/Punch_Jab", &"ual1/Punch_Cross", &"fight/uppercut"]
	var cams := ["Cam_Side", "Cam_Side", "Cam_Hit", "Cam_Hit", "Cam_Side"]
	var heights := [1.35, 1.15, 1.4, 1.2, 1.1]
	for i in PUNCHES:
		shot("metaverse", cams[i], spot + Vector3(-0.45, 1.1, 0))
		_punch(clips[i], i)
		var hit_at: Vector3 = spot + Vector3(-0.3, heights[i], 0.0)
		await wait(PUNCH_TIME * 0.45)
		_hit(i, hit_at)
		await wait(PUNCH_TIME * 0.55)

	# 5. Glitch-out: they are flung away and the world breaks up.
	sound("digital_glitch")
	glitch.burst(OUT_TIME)
	victim.play(&"fight/thrown", 1.3)
	var away := create_tween().set_parallel()
	away.tween_property(victim, "global_position", victim.global_position + Vector3(3.0, 1.2, -2.0), OUT_TIME * 0.7) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	Fx.pixels(self, victim.global_position + Vector3(0, 1.0, 0), 24, 2.5)
	await wait(OUT_TIME * 0.6)
	glitch.cover(true)
	await wait(OUT_TIME * 0.4)


## The avatar throws `clip`: its time runs from 0 to a bit over the strike, fast.
func _punch(clip: StringName, index: int) -> void:
	zuck.look_at(zuck.global_position + Vector3(1, 0, 0))
	var reach := minf(zuck.model.clip_length(clip), 0.6)
	var tween := create_tween()
	tween.tween_method(func(t: float) -> void: zuck.hold(clip, t), 0.0, reach, PUNCH_TIME * 0.9)
	if index % 2 == 0:
		zuck.face = &"grin"


## The punch lands: flash, pixels, a word, recoil.
func _hit(index: int, at: Vector3) -> void:
	var color: Color = Fx.PASTELS[index % Fx.PASTELS.size()]
	victim.model.flash(color, 0.3)
	Fx.pixels(self, at, 10, 1.3)
	glitch.burst(0.08)
	big_text(HIT_WORDS[index], at + Vector3(-0.1, 0.5, 0.9), color, 0.16, PUNCH_TIME)
	var home := marker("metaverse", "Victim").origin
	var clip := &"ual1/Hit_Head" if index % 2 == 0 else &"ual1/Hit_Chest"
	var tween := create_tween()
	tween.tween_method(func(t: float) -> void: victim.hold(clip, t), 0.0, minf(victim.model.clip_length(clip), 0.5), PUNCH_TIME * 0.5)
	var nudge := create_tween()
	nudge.tween_property(victim, "global_position:x", home.x + 0.18, 0.06)
	nudge.tween_property(victim, "global_position:x", home.x, 0.2)


## Back in the fight: a few cyan pixels of glitch on the opponent.
func aftermath() -> void:
	if is_instance_valid(defender) and defender.model:
		defender.model.flash(Color(0.4, 0.95, 1.0), 0.8)
