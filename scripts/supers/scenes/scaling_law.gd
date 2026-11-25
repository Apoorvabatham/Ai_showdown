extends SuperScene
## Ram Altman's super "Scaling Law" (docs/ROADMAP.md §2, owner-approved):
## In a tech keynote amphitheatre, Ram presents the exponential Scaling Law curve;
## the opponent is swept up the curve, accelerating exponentially off the top of the chart
## into the sky; Ram delivers the keynote pitch ("AGI NEXT YEAR!"); the opponent plummets
## from above and slams into the stage floor ("7 TRILLION DOLLARS PLEASE.").
##
## Timeline: ~4.5 s (270 ticks); MoveData.cinematic_ticks covers it.

const INTRO_TIME := 1.20
const RIDE_TIME := 1.20
const KEYNOTE_TIME := 1.00
const CRASH_TIME := 1.10

var ram: ScenePuppet
var victim: ScenePuppet
var _shake := 0.0
var _floor_y := 0.22
var _knockdown := false


func build() -> void:
	var chart := load_set("scaling_chart")
	ram = puppet(attacker, chart)
	ram.global_transform = marker("scaling_chart", "Attacker")
	ram.play(&"ual1/Idle")
	ram.face = &"smile"

	victim = puppet(defender, chart)
	victim.global_transform = marker("scaling_chart", "Opponent")
	victim.play(&"ual1/Idle")
	victim.face = &"surprise"


func run() -> void:
	show_set("scaling_chart")
	var chart := marker("scaling_chart", "Chart").origin
	var podium := marker("scaling_chart", "Podium").origin
	var opp := marker("scaling_chart", "Opponent").origin
	_floor_y = opp.y
	var peak := marker("scaling_chart", "CurvePeak").origin

	# 1. Keynote Intro: Ram presents the Scaling Law
	shot("scaling_chart", "Cam_Wide", chart + Vector3(-1.4, -0.8, 2.2))
	sound("victory")
	ram.play(&"fight/focus_stance")
	ram.face = &"smile"
	victim.play(&"ual1/Idle")
	victim.face = &"surprise"
	big_text("SCALING LAWS DO NOT STOP", chart + Vector3(-1.2, 1.25, 1.6), Color(0.3, 1.0, 0.65), 0.8, INTRO_TIME - 0.1)
	await wait(INTRO_TIME)

	# 2. Opponent rides the exponential curve off the chart
	shot("scaling_chart", "Cam_Ride", chart + Vector3(1.2, 0.8, 0.0))
	sound("space_whoosh")
	_shake = 0.28
	victim.play(&"fight/thrown", 1.2)
	victim.face = &"pain"

	# Exponential acceleration up the curve
	var ride := create_tween()
	ride.tween_property(victim, "global_position", peak + Vector3(0, 4.0, 0), RIDE_TIME).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)

	big_text("MORE COMPUTE = MORE WIN", chart + Vector3(0, 0.95, 1.2), Color(1.0, 0.9, 0.3), 0.78, RIDE_TIME - 0.1)
	await wait(RIDE_TIME)

	# 3. Ram delivers the keynote pitch (hide off-screen victim so they cast no shadow on the chart)
	victim.visible = false
	shot("scaling_chart", "Cam_Ram", podium + Vector3(0, 0.2, 0.4))
	ram.play(&"fight/victory_point")
	ram.face = &"smile"
	big_text("AGI NEXT YEAR!", podium + Vector3(0, 1.7, 0.2), Color(0.25, 0.95, 1.0), 0.78, KEYNOTE_TIME - 0.1)
	await wait(KEYNOTE_TIME)

	# 4. The Plummet & Crash Landing
	victim.visible = true
	victim.global_position = opp + Vector3(0, 12.0, 0)
	shot("scaling_chart", "Cam_Fall", opp + Vector3(0, 0.6, 0))

	var fall := create_tween()
	fall.tween_property(victim, "global_position", opp, 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await wait(0.26)

	sound("shockwave", 2.0)
	_shake = 0.55
	_knockdown = true
	victim.play(&"ual2/Hit_Knockback")
	victim.face = &"pain"

	big_text("7 TRILLION DOLLARS PLEASE.", opp + Vector3(0.4, 2.05, 0.6), Color(1.0, 0.92, 0.6), 0.76, 2.0)
	await wait(CRASH_TIME - 0.26)


func _process(delta: float) -> void:
	super._process(delta)
	if _knockdown:
		keep_head_above_floor(victim, _floor_y, 0.16)
	if camera and _shake > 0.0:
		_shake = maxf(0.0, _shake - delta * 1.6)
		camera.h_offset = randf_range(-_shake, _shake) * 0.08
		camera.v_offset = randf_range(-_shake, _shake) * 0.08
