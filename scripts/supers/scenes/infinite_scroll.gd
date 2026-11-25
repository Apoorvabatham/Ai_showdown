extends SuperScene
## AGI (algorithm)'s super "Infinite Scroll" (docs/ROADMAP.md §2, owner-approved):
## In a surreal cyberspace void, AGI summons a towering monolithic smartphone;
## the opponent is pulled by algorithm gravity and sucked into the phone screen;
## trapped inside, they tumble helplessly through a dizzying vertical endless scroll;
## the screen flashes and spats them out, slamming flat onto the stage floor.
##
## Timeline: ~4.5 s (270 ticks); MoveData.cinematic_ticks covers it.

const INTRO_TIME := 1.10
const SUCK_TIME := 1.10
const SCROLL_TIME := 1.10
const SPAT_TIME := 1.20

var agi: ScenePuppet
var victim: ScenePuppet
var _shake := 0.0
var _floor_y := 0.22
var _knockdown := false


func build() -> void:
	var phone_set := load_set("giant_phone")
	agi = puppet(attacker, phone_set)
	agi.global_transform = marker("giant_phone", "Attacker")
	agi.play(&"ual1/Idle")
	agi.face = &"smile"

	victim = puppet(defender, phone_set)
	victim.global_transform = marker("giant_phone", "Opponent")
	victim.play(&"ual1/Idle")
	victim.face = &"surprise"


func run() -> void:
	show_set("giant_phone")
	var phone := marker("giant_phone", "Phone").origin
	var opp := marker("giant_phone", "Opponent").origin
	_floor_y = opp.y
	var portal := marker("giant_phone", "ScreenPortal").origin

	# 1. Cyberspace Intro: AGI summons the Giant Phone
	shot("giant_phone", "Cam_Wide", Vector3(-0.7, phone.y - 1.6, phone.z + 1.5))
	sound("victory")
	agi.play(&"fight/focus_stance")
	agi.face = &"smile"
	victim.play(&"ual1/Idle")
	victim.face = &"surprise"
	big_text("RECOMMENDED FOR YOU", agi.global_position + Vector3(0.4, 2.5, 0.4), Color(0.25, 0.95, 1.0), 0.78, INTRO_TIME - 0.15)
	await wait(INTRO_TIME)

	# 2. Opponent is sucked into the phone screen
	shot("giant_phone", "Cam_Suck", portal + Vector3(0, 0.4, 0))
	sound("teleport")
	_shake = 0.28
	victim.play(&"fight/thrown", 1.4)
	victim.face = &"pain"

	var suck := create_tween().set_parallel(true)
	suck.tween_property(victim, "global_position", portal, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	suck.tween_property(victim, "scale", Vector3.ONE * 0.42, 0.75)

	big_text("ENDLESS SCROLL!", portal + Vector3(0, 1.9, 0.4), Color(1.0, 0.35, 0.8), 0.78, SUCK_TIME - 0.1)
	await wait(SUCK_TIME)

	# 3. Dizzying Infinite Scroll inside the timeline
	shot("giant_phone", "Cam_Scroll", portal + Vector3(0, 0.1, 0))
	_shake = 0.35

	var tumble := create_tween()
	tumble.tween_property(victim, "rotation:z", TAU * 2.0, SCROLL_TIME)

	big_text("OPTIMISING ATTENTION...", portal + Vector3(0, 1.4, 0.3), Color(0.9, 0.95, 1.0), 0.72, SCROLL_TIME - 0.1)
	await wait(SCROLL_TIME)

	# 4. Spat Out & Crash Landing
	victim.scale = Vector3.ONE
	victim.rotation = Vector3.ZERO
	victim.global_position = opp + Vector3(0, 7.0, -0.8)
	shot("giant_phone", "Cam_Spat", opp + Vector3(0, 0.65, 0))

	var spit := create_tween()
	spit.tween_property(victim, "global_position", opp, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await wait(0.28)

	sound("shockwave", 2.0)
	_shake = 0.55
	_knockdown = true
	victim.play(&"ual2/Hit_Knockback")
	victim.face = &"pain"

	big_text("SCREEN TIME LIMIT EXCEEDED.", opp + Vector3(0, 1.85, 0.6), Color(0.25, 0.95, 0.95), 0.74, 2.0)
	await wait(SPAT_TIME - 0.28)


func _process(delta: float) -> void:
	super._process(delta)
	if _knockdown:
		keep_head_above_floor(victim, _floor_y, 0.16)
	if camera and _shake > 0.0:
		_shake = maxf(0.0, _shake - delta * 1.6)
		camera.h_offset = randf_range(-_shake, _shake) * 0.08
		camera.v_offset = randf_range(-_shake, _shake) * 0.08
