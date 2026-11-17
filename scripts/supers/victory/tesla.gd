extends VictoryScene
## tesla man's victory (docs/ROADMAP.md §2, owner-approved): on Mars he walks from his landed
## rocket and plants a flag: "CAPTURED".


var winner: ScenePuppet
var flag: Node3D


func _init() -> void:
	own_set = true


func build() -> void:
	var mars := load_set("mars")
	var rocket := prop("tesla/rocket", SuperStandins.rocket, mars)
	rocket.global_transform = marker("mars", "Rocket")
	flag = prop("tesla/mars_flag", func() -> Node3D: return SuperStandins.flag("CAPTURED", Color(0.95, 0.95, 0.95), Color(0.75, 0.1, 0.1)), mars)
	var flag_spot := marker("mars", "Flag")
	flag.global_transform = flag_spot
	flag.position.y -= 2.8 # still in the ground
	var cloth := flag.find_child("Cloth", true, false)
	if cloth and cloth.find_children("*", "Label3D").is_empty():
		var label := Label3D.new() # a real flag prop has a blank cloth: write on it
		label.text = "CAPTURED"
		label.font_size = 64
		label.pixel_size = 0.004
		label.modulate = Color(0.75, 0.1, 0.1)
		label.position.z = 0.02
		cloth.add_child(label)
	winner = puppet(attacker, mars)
	winner.global_transform = marker("mars", "Rocket")
	winner.position += Vector3(1.2, 0, 1.0)


func run() -> void:
	show_set("mars")
	var spot := marker("mars", "Winner").origin
	shot("mars", "Cam_Wide", spot + Vector3(-1.5, 1.2, -1.5))
	var look := spot
	look.y = winner.global_position.y
	winner.look_at(look)
	winner.play(&"ual1/Walk")
	sound("footsteps")
	var walk := create_tween()
	walk.tween_property(winner, "global_position", spot, 1.4)
	await wait(1.4)

	# Plant the flag.
	winner.look_at(flag.global_position * Vector3(1, 0, 1) + Vector3(0, winner.global_position.y, 0))
	winner.play(&"ual1/Interact")
	sound("flag_plant")
	var rise := create_tween()
	rise.tween_property(flag, "position:y", flag.position.y + 2.8, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var dust := SuperStandins.smoke_particles(1.0, 1.2)
	add_child(dust)
	dust.global_position = marker("mars", "Flag").origin
	await wait(0.6)

	# Hero shot, low, looking up at him and the flag.
	shot("mars", "Cam_Hero", spot + Vector3(0.4, 1.6, 0))
	var to_camera := camera.global_position
	to_camera.y = winner.global_position.y
	winner.look_at(to_camera)
	winner.play(&"fight/victory_fist_pump")
	winner.face = &"grin"
	big_text("CAPTURED", spot + Vector3(-0.6, 2.9, -1.2), Color(1.0, 0.35, 0.2), 0.3)
