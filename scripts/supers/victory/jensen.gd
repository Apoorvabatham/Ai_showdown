extends VictoryScene
## Jensen Wong's victory (docs/ROADMAP.md §2, owner-approved): on the keynote stage he signs
## his own leather jacket with a giant marker while graphics cards rain down like confetti.

const TornadoScene := preload("res://scripts/supers/scenes/jacket_tornado.gd")
const LOOK := Vector3(-0.4, 1.0, 0.0) # what the camera looks at, from the stage centre
const GPU_COUNT := 90
const SPAWN_RATE := 22.0 # cards per second
const FLOOR_Y := 0.12
const COLORS := [Color(0.46, 0.73, 0.0), Color(0.9, 0.2, 0.2), Color(0.2, 0.6, 1.0), Color(1.0, 0.8, 0.2)]

var winner: ScenePuppet
var jacket: Node3D
var pen: Node3D
var signature: Label3D
var _cards: Array[Dictionary] = []
var _spawned := 0
var _spawn_clock := 0.0
var _raining := false
var _time := 0.0
var _signing := false
var _pen_home := Vector3.ZERO
var _rng := RandomNumberGenerator.new()
var _stage: Node3D


func _init() -> void:
	own_set = true


func build() -> void:
	_rng.seed = 5090
	_stage = load_set("keynote_stage")
	var spot := marker("keynote_stage", "Center").origin - _stage.global_position # local to the set
	# The jacket, huge, on a stand, front to the camera.
	jacket = prop("jensen/leather_jacket", TornadoScene.leather_jacket, _stage)
	jacket.scale = Vector3.ONE * 2.3
	jacket.position = spot + Vector3(0.6, 2.3, 0.0)
	var pole := SuperStandins.box(Vector3(0.1, 1.4, 0.1), spot + Vector3(0.6, 0.7, 0.0), SuperStandins.metal(Color(0.7, 0.72, 0.75), 0.9, 0.3), "Stand")
	_stage.add_child(pole)
	# The signature, written in silver on the chest as the marker scribbles.
	signature = Label3D.new()
	signature.font = preload("res://assets/fonts/PermanentMarker-Regular.ttf")
	signature.font_size = 72
	signature.pixel_size = 0.001
	signature.modulate = Color(0.95, 0.98, 1.0)
	signature.outline_size = 8
	signature.outline_modulate = Color(0.08, 0.08, 0.12)
	signature.shaded = false
	signature.rotation.z = 0.15
	signature.position = Vector3(0.15, -0.05, 0.22)
	signature.text = ""
	jacket.add_child(signature)
	# The giant marker.
	pen = SuperStandins.box(Vector3(0.14, 1.1, 0.14), Vector3.ZERO, SuperStandins.metal(Color(0.04, 0.04, 0.05), 0.3, 0.4), "Marker")
	pen.add_child(SuperStandins.box(Vector3(0.15, 0.25, 0.15), Vector3(0, -0.62, 0), SuperStandins.glow(Color(0.9, 0.1, 0.1), 1.5)))
	pen.add_child(SuperStandins.box(Vector3(0.16, 0.12, 0.16), Vector3(0, 0.4, 0), SuperStandins.metal(Color(0.46, 0.73, 0.0), 0.4, 0.4)))
	_stage.add_child(pen)
	winner = puppet(attacker, _stage)
	winner.position = spot + Vector3(-1.45, 0, 0.5)
	winner.look_at(winner.global_position + Vector3(1.0, 0, -0.5))
	winner.face = &"grin"


func run() -> void:
	show_set("keynote_stage")
	var spot := marker("keynote_stage", "Center").origin
	shot("keynote_stage", "Cam_Wide", spot + LOOK)
	camera.global_position = spot + Vector3(-0.2, 1.8, 8.0)
	sound("victory")
	sound("whoosh", -6.0)
	winner.play(&"ual1/Interact")
	_pen_home = jacket.position + Vector3(-0.9, -0.5, 0.35)
	pen.position = _pen_home
	pen.rotation.z = -0.8
	_signing = true
	_raining = true
	var push := create_tween()
	push.tween_property(camera, "global_position", spot + Vector3(-0.2, 1.6, 6.2), 4.0).set_trans(Tween.TRANS_SINE)
	await wait(0.6)
	sound("gpu_sparks", -4.0)
	var write := create_tween()
	write.tween_method(func(t: float) -> void: signature.text = "Jensen ★".substr(0, ceili(t * 8.0)), 0.0, 1.0, 1.4)
	await wait(1.8)
	_signing = false
	# Done: the jacket flexes, the screen says it.
	pen.visible = false
	big_text("1000x PERFORMANCE!", spot + Vector3(0.0, 2.2, 1.0), Color(0.35, 0.95, 1.0), 0.5, 3.5)
	sound("gpu_sparks", -2.0)
	winner.look_at(Vector3(camera.global_position.x, winner.global_position.y, camera.global_position.z))
	winner.play(&"fight/victory_fist_pump")
	winner.face = &"grin"
	track = null


func _process(delta: float) -> void:
	super(delta)
	_time += delta
	if camera and _stage:
		camera.look_at(marker("keynote_stage", "Center").origin + LOOK)
	if _signing and pen:
		# Scribbling on the chest.
		var w := _time * 14.0
		pen.position = _pen_home + Vector3(0.5 + 0.35 * sin(w), 0.15 * sin(w * 2.1), 0.0)
	if _raining and _spawned < GPU_COUNT:
		_spawn_clock += delta * SPAWN_RATE
		while _spawn_clock >= 1.0 and _spawned < GPU_COUNT:
			_spawn_clock -= 1.0
			spawn_card()
	for card in _cards:
		if card.landed:
			continue
		var node: Node3D = card.node
		card.vy -= 11.0 * delta
		node.position.y += card.vy * delta
		node.position.x += card.vx * delta
		node.rotate(card.axis, card.spin * delta)
		if node.position.y <= FLOOR_Y:
			node.position.y = FLOOR_Y
			if card.bounces < 2:
				card.vy = -card.vy * 0.35
				card.vx *= 0.5
				card.spin *= 0.5
				card.bounces += 1
			else:
				card.landed = true
				node.rotation = Vector3(-PI * 0.5 + _rng.randf_range(-0.15, 0.15), _rng.randf() * TAU, 0.0)


func spawn_card() -> void:
	var node := ProjectileLooks.build(&"gpu", COLORS[_spawned % COLORS.size()])
	for light in node.find_children("*", "OmniLight3D", true, false):
		light.queue_free() # dozens of cards: no lights
	var spot := marker("keynote_stage", "Center").origin - _stage.global_position
	node.position = spot + Vector3(_rng.randf_range(-5.0, 5.5), _rng.randf_range(8.0, 12.0), _rng.randf_range(-3.0, 4.5))
	node.rotation = Vector3(_rng.randf() * TAU, _rng.randf() * TAU, _rng.randf() * TAU)
	node.scale = Vector3.ONE * _rng.randf_range(0.8, 1.3)
	_stage.add_child(node)
	_cards.append({node = node, vy = _rng.randf_range(-3.0, 0.0), vx = _rng.randf_range(-0.8, 0.8),
			axis = Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1), _rng.randf_range(-1, 1)).normalized(),
			spin = _rng.randf_range(2.0, 6.0), bounces = 0, landed = false})
	_spawned += 1
