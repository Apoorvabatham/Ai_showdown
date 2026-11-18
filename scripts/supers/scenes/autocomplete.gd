extends SuperScene
## Yann LeCant's super "It's Just Autocomplete" (docs/ROADMAP.md §2, owner-approved):
## The opponent is trapped inside a giant prompt text box in a cyber terminal.
## Autocomplete predicts and types "you lose", followed by a cascade of massive,
## heavy 3D letter blocks tumbling from the sky to crush the opponent.
##
## Timeline: 4.5 s (270 ticks).

const WIDE_TIME := 0.7
const TYPE_TIME := 0.8
const SUGGEST_TIME := 0.7
const DROP_TIME := 0.8
const PILE_TIME := 0.7
const AFTER_TIME := 0.8
const LENGTH := WIDE_TIME + TYPE_TIME + SUGGEST_TIME + DROP_TIME + PILE_TIME + AFTER_TIME

var yann: ScenePuppet
var victim: ScenePuppet
var terminal_set: Node3D
var cursor: Node3D
var suggest_box: Node3D
var letters_root: Node3D
var letter_nodes: Array[Node3D] = []
var _shake := 0.0


func build() -> void:
	terminal_set = load_set("prompt_terminal")

	yann = puppet(attacker, terminal_set)
	yann.global_transform = marker("prompt_terminal", "Attacker")
	yann.play(&"fight/focus_stance")
	yann.face = &"smirk"

	victim = puppet(defender, terminal_set)
	victim.global_transform = marker("prompt_terminal", "Opponent")
	victim.play(&"fight/crouch_guard")
	victim.face = &"pain"

	cursor = terminal_set.find_child("BlinkingCursor", true, false) as Node3D
	suggest_box = terminal_set.find_child("SuggestBox", true, false) as Node3D
	if suggest_box:
		suggest_box.visible = false

	# Build heavy 3D letter blocks
	letters_root = prop("yann/heavy_letters", _letters_standin, terminal_set)
	letters_root.name = "HeavyLetters"
	letters_root.visible = false


func run() -> void:
	show_set("prompt_terminal")
	var box_spot := marker("prompt_terminal", "PromptBox").origin

	# 1. Wide shot: Opponent trapped in giant text box, Yann at podium
	shot("prompt_terminal", "Cam_Wide", box_spot + Vector3(0.0, 0.6, 0.0))
	sound("victory")
	big_text("PROMPT: PREDICT NEXT TOKEN", box_spot + Vector3(0, 1.4, 0), Color(0.3, 0.85, 1.0), 0.6, WIDE_TIME + TYPE_TIME)
	await wait(WIDE_TIME)

	# 2. Camera cuts to opponent in text box, typing starts
	shot("prompt_terminal", "Cam_Opponent", box_spot + Vector3(0.0, 0.5, 0.0))
	victim.play(&"fight/crouch_guard")
	victim.face = &"pain"
	
	# Typed text prompt appears
	big_text("> you lose_", box_spot + Vector3(0, 1.3, -1.0), Color(0.95, 0.95, 0.4), 1.0, 2.2)
	sound("keyboard_typing")
	await wait(TYPE_TIME)

	# 3. Autocomplete suggestion popup highlights
	shot("prompt_terminal", "Cam_Type", box_spot + Vector3(0.4, 0.8, -0.4))
	if suggest_box:
		suggest_box.visible = true
	_shake = 0.25
	await wait(SUGGEST_TIME)

	# 4. Angled up: Heavy letters fall from the sky onto opponent
	shot("prompt_terminal", "Cam_Drop", box_spot + Vector3(0.0, 1.8, -0.2))
	letters_root.visible = true

	# Animate heavy letter blocks crashing down onto opponent
	var letter_targets: Array[Vector3] = [
		box_spot + Vector3(-1.0, 0.35, -0.3), # Y
		box_spot + Vector3(-0.4, 0.35, -0.3), # O
		box_spot + Vector3(0.2, 0.35, -0.3),  # U
		box_spot + Vector3(-0.9, 0.35, 0.5),  # L
		box_spot + Vector3(-0.3, 0.35, 0.5),  # O
		box_spot + Vector3(0.3, 0.35, 0.5),   # S
		box_spot + Vector3(0.9, 0.35, 0.5),   # E
	]

	var tween := create_tween().set_parallel(true)
	for i in letter_nodes.size():
		var node := letter_nodes[i]
		var target: Vector3 = letter_targets[i % letter_targets.size()]
		# Start high above
		node.global_position = target + Vector3(0, 8.0 + i * 0.4, 0)
		var delay := i * 0.06
		tween.tween_property(node, "global_position", target, 0.44).set_delay(delay).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(node, "rotation_degrees", Vector3(randf_range(-15, 15), randf_range(-25, 25), randf_range(-10, 10)), 0.44).set_delay(delay)

	await wait(0.4)
	# Impact shockwave
	_shake = 0.7
	sound("stamp_thud")
	victim.hold(&"ual2/Hit_Knockback", 0.1)
	victim.face = &"pain"
	if victim.model:
		victim.model.flash(Color(1.0, 0.3, 0.2), 0.4)
	await wait(DROP_TIME - 0.4)

	# 5. Pile view: Opponent flattened under the letters in the text box
	shot("prompt_terminal", "Cam_Pile", box_spot + Vector3(0.0, 0.4, 0.0))
	_shake = 0.1
	await wait(PILE_TIME)

	# 6. Sceptical resolution: Yann at podium facing camera, "IT'S JUST AUTOCOMPLETE!"
	shot("prompt_terminal", "Cam_Yann", yann.global_position + Vector3(0, 1.1, 0))
	yann.play(&"fight/victory_bow")
	yann.face = &"smirk"
	big_text("IT'S JUST AUTOCOMPLETE!", yann.global_position + Vector3(0.7, 1.6, 0), Color(1.0, 0.35, 0.35), 0.65, AFTER_TIME)
	await wait(AFTER_TIME)


func _process(delta: float) -> void:
	super._process(delta)
	if camera:
		_shake = move_toward(_shake, 0.0, delta * 0.7)
		camera.h_offset = randf_range(-1.0, 1.0) * _shake
		camera.v_offset = randf_range(-1.0, 1.0) * _shake


func _letters_standin() -> Node3D:
	var root := Node3D.new()
	root.name = "HeavyLettersStandin"
	letter_nodes.clear()

	var text_chars := ["Y", "O", "U", "L", "O", "S", "E"]
	var concrete_mat := StandardMaterial3D.new()
	concrete_mat.albedo_color = Color(0.65, 0.68, 0.75)
	concrete_mat.roughness = 0.6
	concrete_mat.metallic = 0.2

	var rim_mat := StandardMaterial3D.new()
	rim_mat.albedo_color = Color(0.3, 0.8, 1.0)
	rim_mat.emission_enabled = true
	rim_mat.emission = Color(0.3, 0.8, 1.0)
	rim_mat.emission_energy_multiplier = 2.2

	for i in text_chars.size():
		var block := Node3D.new()
		block.name = "Letter_%s_%d" % [text_chars[i], i]

		# Heavy slab block (0.65m wide, 0.75m high, 0.45m thick)
		var box := MeshInstance3D.new()
		var bmesh := BoxMesh.new()
		bmesh.size = Vector3(0.65, 0.75, 0.45)
		box.mesh = bmesh
		box.material_override = concrete_mat
		block.add_child(box)

		# Glowing rim lines top and bottom
		var rim_top := MeshInstance3D.new()
		var rmesh := BoxMesh.new()
		rmesh.size = Vector3(0.67, 0.04, 0.47)
		rim_top.mesh = rmesh
		rim_top.position = Vector3(0, 0.38, 0)
		rim_top.material_override = rim_mat
		block.add_child(rim_top)

		# Front 3D Letter
		var lbl_front := Label3D.new()
		lbl_front.text = text_chars[i]
		lbl_front.font_size = 100
		lbl_front.pixel_size = 0.0055
		lbl_front.modulate = Color(1.0, 1.0, 0.95)
		lbl_front.outline_size = 8
		lbl_front.outline_modulate = Color(0.08, 0.1, 0.15)
		lbl_front.position = Vector3(0, 0, 0.24)
		block.add_child(lbl_front)

		# Back 3D Letter
		var lbl_back := Label3D.new()
		lbl_back.text = text_chars[i]
		lbl_back.font_size = 100
		lbl_back.pixel_size = 0.0055
		lbl_back.modulate = Color(1.0, 1.0, 0.95)
		lbl_back.outline_size = 8
		lbl_back.outline_modulate = Color(0.08, 0.1, 0.15)
		lbl_back.position = Vector3(0, 0, -0.24)
		lbl_back.rotation.y = PI
		block.add_child(lbl_back)

		root.add_child(block)
		letter_nodes.append(block)

	return root
