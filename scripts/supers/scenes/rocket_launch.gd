extends SuperScene
## tesla man's super "Rocket Launch" (docs/ROADMAP.md §2, owner-approved): he drives up in
## his steel pickup, the opponent is chained to a rocket, 3-2-1, liftoff, across space above
## the Earth, then the opponent falls back and burns up on re-entry (cartoon soot, no gore).
##
## Timeline: about 6.6 s; MoveData.cinematic_ticks must cover it (tools/showdown_movesets.gd).

const DRIVE_TIME := 1.1
const POINT_TIME := 0.7
const COUNT_STEP := 0.35
const LIFTOFF_TIME := 1.5
const SPACE_TIME := 1.1
const REENTRY_TIME := 1.25
const LENGTH := DRIVE_TIME + POINT_TIME + COUNT_STEP * 3 + LIFTOFF_TIME + SPACE_TIME + REENTRY_TIME

var truck: Node3D
var rocket: Node3D
var elon: ScenePuppet
var victim: ScenePuppet
var _wheels_spinning := false


func build() -> void:
	var pad := load_set("launch_pad")
	load_set("space", Vector3(0, 0, -300))
	truck = prop("tesla/steel_pickup", SuperStandins.steel_pickup, pad)
	truck.global_transform = marker("launch_pad", "Truck_Start")
	rocket = prop("tesla/rocket", SuperStandins.rocket, pad)
	rocket.global_transform = marker("launch_pad", "Rocket")
	# The opponent chained by their back to the rocket, pinned pose, in pain.
	var chain_point := rocket.find_child("ChainPoint", true, false) as Node3D
	victim = puppet(defender, rocket)
	victim.position = chain_point.position if chain_point else Vector3(0, 1.6, 0.85)
	victim.position.y -= 1.0
	victim.rotation.y = PI # faces away from the hull
	victim.hold(&"fight/wall_splat", 0.25)
	victim.face = &"pain"
	rocket.add_child(SuperStandins.chains(0.95, [victim.position.y + 1.05, victim.position.y + 1.35], 0.45))
	elon = puppet(attacker, pad)
	elon.visible = false


func run() -> void:
	show_set("launch_pad")
	shot("launch_pad", "Cam_Wide", rocket.global_position + Vector3(0, 3, 0))
	sound("engine")
	_wheels_spinning = true
	var drive := create_tween()
	drive.tween_property(truck, "global_position", marker("launch_pad", "Truck_Stop").origin, DRIVE_TIME) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await wait(DRIVE_TIME)
	_wheels_spinning = false

	# He hops out and points at the rocket.
	elon.global_transform = marker("launch_pad", "Attacker")
	elon.visible = true
	var look := rocket.global_position
	look.y = elon.global_position.y
	elon.look_at(look)
	elon.play(&"fight/victory_point")
	elon.face = &"grin"
	shot("launch_pad", "Cam_Attacker", elon.global_position + Vector3(0, 1.5, 0))
	sound("chain")
	await wait(POINT_TIME)

	# 3, 2, 1.
	shot("launch_pad", "Cam_Wide", rocket.global_position + Vector3(0, 3, 0))
	for n in ["3", "2", "1"]:
		big_text(n, rocket.global_position + Vector3(2.5, 6.5, 2.0), Color(1, 0.9, 0.3), 1.2, COUNT_STEP - 0.12)
		await wait(COUNT_STEP)

	# Liftoff: the camera stays low and follows the rocket up.
	var flame := rocket.find_child("Flame", true, false) as Node3D
	if flame:
		flame.visible = true
	big_text("LIFTOFF!", rocket.global_position + Vector3(0, 9, 3), Color(1, 0.6, 0.2), 1.0, 0.8)
	sound("launch")
	shot("launch_pad", "Cam_Launch")
	track = rocket
	track_offset = Vector3(0, 3, 0)
	var rise := create_tween()
	rise.tween_property(rocket, "global_position", rocket.global_position + Vector3(0, 60, 0), LIFTOFF_TIME) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await wait(LIFTOFF_TIME)

	# Space: the rocket crosses above the Earth, the opponent flailing on its chain.
	rise.kill()
	show_set("space")
	var start := marker("space", "Rocket_Start")
	var end := marker("space", "Rocket_End")
	rocket.reparent(_sets["space"])
	rocket.global_position = start.origin
	rocket.rotation = Vector3(0, 0, -PI * 0.42) # nose toward the end point
	victim.play(&"fight/thrown", 1.5)
	shot("space", "Cam_Space")
	track = rocket
	track_offset = Vector3.ZERO
	sound("whoosh")
	var cross := create_tween()
	cross.tween_property(rocket, "global_position", end.origin, SPACE_TIME)
	await wait(SPACE_TIME)

	# Re-entry: the opponent falls back alone, burning up (cartoon: fire, smoke, soot flashes).
	cross.kill()
	victim.reparent(_sets["space"])
	victim.global_position = marker("space", "Reentry_Start").origin
	victim.rotation = Vector3(PI * 0.5, 0, 0)
	rocket.visible = false
	var fire := SuperStandins.fire_particles(2.5)
	victim.add_child(fire)
	fire.position = Vector3(0, -0.5, 0)
	var smoke := SuperStandins.smoke_particles(1.5, 1.5)
	victim.add_child(smoke)
	sound("burn")
	track = victim
	track_offset = Vector3.ZERO
	var fall := create_tween()
	fall.tween_property(victim, "global_position", marker("space", "Reentry_End").origin, REENTRY_TIME) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	for i in 4:
		victim.model.flash(Color(1.0, 0.4, 0.05), 0.3)
		await wait(REENTRY_TIME / 4.0)


func _process(delta: float) -> void:
	super(delta)
	if _wheels_spinning and truck:
		for wheel in ["Wheel_FL", "Wheel_FR", "Wheel_RL", "Wheel_RR"]:
			var node := truck.find_child(wheel, true, false) as Node3D
			if node:
				node.rotate_object_local(Vector3.UP, -12.0 * delta)


## Back in the fight: the burnt opponent smokes for a few seconds.
func aftermath() -> void:
	if not is_instance_valid(defender):
		return
	var smoke := SuperStandins.smoke_particles(0.35, 1.0)
	smoke.position = Vector3(0, 1.2, 0)
	defender.add_child(smoke)
	defender.get_tree().create_timer(3.5).timeout.connect(smoke.queue_free)
	if defender.model:
		defender.model.flash(Color(0.6, 0.25, 0.05), 1.0)
