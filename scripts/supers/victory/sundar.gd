extends VictoryScene
## Sundar Pickai's victory (docs/ROADMAP.md §2, owner-approved): the sky above the arena turns
## into a giant search results page: he searches "who won?" and the one result is
## "Sundar Pickai - Winner". Plays on the stage, around the real fighters.

const BOARD_W := 16.0
const BOARD_H := 9.0
const INK := Color(0.12, 0.13, 0.16)

var board: Node3D
var query: Label3D
var results: Array[Node3D] = []
var _query_text := ""


func _init() -> void:
	own_set = false


func build() -> void:
	board = prop("sundar/results_page", results_page)
	query = board.find_child("Query", true, false) as Label3D
	if query:
		_query_text = query.text
		query.text = ""
	for node in board.get_children():
		if String(node.name).begins_with("Result"):
			node.visible = false
			results.append(node)
	board.scale = Vector3.ONE * 0.1
	board.visible = false


func run() -> void:
	# Camera and board go on the side the fight camera is already on, the board behind the winner.
	var winner := attacker.global_position
	var right := attacker.forward.cross(Vector3.UP).normalized()
	var side := 1.0 if (fight.camera.global_position - winner).dot(right) >= 0.0 else -1.0
	var toward_camera := right * side
	camera.fov = 70.0
	camera.global_position = winner + toward_camera * 6.3 + Vector3(0, 1.0, 0)
	_cam_look = winner - toward_camera * 10.0 + Vector3(0, 5.2, 0)
	camera.look_at(_cam_look)
	track = null
	board.global_position = winner - toward_camera * 10.0 + Vector3(0, 7.8, 0)
	board.look_at(board.global_position - toward_camera, Vector3.UP)
	sound("victory")

	# The sky turns into a results page.
	board.visible = true
	var open := create_tween()
	open.tween_property(board, "scale", Vector3.ONE * 1.2, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var dolly := create_tween()
	dolly.tween_property(camera, "global_position", winner + toward_camera * 5.4 + Vector3(0, 1.0, 0), 5.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await wait(0.6)
	sound("keyboard_typing", -6.0)
	if query:
		var type := create_tween()
		type.tween_method(func(t: float) -> void: query.text = _query_text.substr(0, int(round(t * _query_text.length()))), 0.0, 1.0, 0.7)
	await wait(0.9)
	for i in results.size():
		results[i].visible = true
		var slide := create_tween()
		slide.tween_property(results[i], "position:x", 0.0, 0.25).from(1.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if i == 0:
			sound("search_query")
		await wait(0.35)


var _cam_look := Vector3.ZERO


func _process(delta: float) -> void:
	if camera and _cam_look != Vector3.ZERO:
		camera.look_at(_cam_look)


# --- Stand-in: the results page --------------------------------------------------------

## A 16 x 9 m search results page, front = +Z. `Query` is the typed search text; children
## named `Result*` appear one after another.
static func results_page() -> Node3D:
	var root := Node3D.new()
	root.name = "ResultsPage"
	root.add_child(SuperStandins.box(Vector3(BOARD_W + 0.4, BOARD_H + 0.4, 0.1), Vector3(0, 0, -0.08), unlit(Color(0.2, 0.22, 0.28)), "Frame"))
	root.add_child(SuperStandins.box(Vector3(BOARD_W, BOARD_H, 0.05), Vector3(0, 0, -0.02), unlit(Color(1, 1, 1)), "Page"))
	# The logo: six letters in four primary colours.
	var colors := [Color(0.26, 0.52, 0.96), Color(0.92, 0.26, 0.21), Color(0.98, 0.74, 0.02), Color(0.26, 0.52, 0.96), Color(0.2, 0.66, 0.33), Color(0.92, 0.26, 0.21)]
	for i in 6:
		root.add_child(text("Pickai"[i], 1.3, colors[i], Vector3(-6.8 + i * 0.75, 3.5, 0.0)))
	# Search bar with the query.
	root.add_child(SuperStandins.box(Vector3(7.6, 0.95, 0.04), Vector3(2.4, 3.5, 0.0), unlit(Color(0.9, 0.91, 0.94)), "SearchBar"))
	root.add_child(SuperStandins.box(Vector3(7.4, 0.8, 0.04), Vector3(2.4, 3.5, 0.02), unlit(Color(1, 1, 1))))
	var query_label := text("how to beat sundar?", 0.55, INK, Vector3(-0.9, 3.5, 0.06))
	query_label.name = "Query"
	query_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	root.add_child(query_label)
	root.add_child(text("Q", 0.7, Color(0.26, 0.52, 0.96), Vector3(5.7, 3.5, 0.06)))
	root.add_child(text("All    Images    News    Videos    Winners", 0.38, Color(0.4, 0.42, 0.46), Vector3(0, 2.5, 0.0)))
	root.add_child(SuperStandins.box(Vector3(BOARD_W, 0.04, 0.04), Vector3(0, 2.2, 0.0), unlit(Color(0.85, 0.86, 0.9))))
	root.add_child(text("About 1 result (0.0001 seconds)", 0.34, Color(0.4, 0.42, 0.46), Vector3(0, 1.7, 0.0)))
	# Result 1: the winner, highlighted.
	var first := Node3D.new()
	first.name = "Result1"
	first.add_child(SuperStandins.box(Vector3(11.5, 2.2, 0.03), Vector3(0, 0.0, -0.01), unlit(Color(0.88, 0.94, 1.0))))
	first.add_child(text("www.pickai-search.com  >  undefeated", 0.34, Color(0.15, 0.55, 0.2), Vector3(0, 0.7, 0.0)))
	first.add_child(text("Sundar Pickai - Flawless Victory!", 0.9, Color(0.1, 0.25, 0.8), Vector3(0, 0.05, 0.0)))
	first.add_child(text("Did you mean: *Opponent knocked out cold*? (0.0001s)", 0.36, Color(0.25, 0.28, 0.35), Vector3(0, -0.7, 0.0)))
	first.position = Vector3(0, 0.45, 0.04)
	root.add_child(first)
	var second := Node3D.new()
	second.name = "Result2"
	second.add_child(text("Sponsored: Emergency ice pack for your face", 0.5, Color(0.1, 0.25, 0.75), Vector3(0, 0.0, 0.0)))
	second.add_child(text("Ad  -  www.ice-for-bruises.biz", 0.3, Color(0.2, 0.5, 0.25), Vector3(0, 0.45, 0.0)))
	second.position = Vector3(0, -1.5, 0.04)
	root.add_child(second)
	var third := Node3D.new()
	third.name = "Result3"
	third.add_child(text("Tutorial: How to accept defeat gracefully", 0.5, Color(0.1, 0.25, 0.75), Vector3(0, 0.0, 0.0)))
	third.add_child(text("www.better-luck-next-round.org", 0.3, Color(0.4, 0.42, 0.46), Vector3(0, 0.45, 0.0)))
	third.position = Vector3(0, -2.8, 0.04)
	root.add_child(third)
	return root


static func text(content: String, height: float, color: Color, position: Vector3) -> Label3D:
	var l := Label3D.new()
	l.font = preload("res://assets/fonts/InterDisplay-BlackItalic.otf")
	l.text = content
	l.font_size = 96
	l.pixel_size = height * 0.012
	l.modulate = color
	l.shaded = false
	l.outline_size = 6
	l.outline_modulate = Color(0.02, 0.02, 0.05, 0.5)
	l.position = position + Vector3(0, 0, 0.06) # in front of the page and the boxes
	return l


static func unlit(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m
