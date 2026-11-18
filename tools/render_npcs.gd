extends SceneTree
## Renders review sheets of the NPCs in res://data/npcs/.
## `helpers` (the default) renders the four panels per helper: front, side, chest, head.
## A stage name (senate, mensa, foundry, server_farm) renders the full-body grid of that
## stage's people, ids taken from res://data/stage_life/<stage>.json, with the id under
## each person. Saves to docs/review/opencode/.
##
## Run windowed (needs a renderer):
##   godot --rendering-driver opengl3 --path . -s res://tools/render_npcs.gd [-- helpers] [-- senate ...]

const NPC_DIR := "res://data/npcs/"
const STAGE_DIR := "res://data/stage_life/"
const OUT_DIR := "res://docs/review/opencode/"
const HELPERS: Array[String] = ["helper_qwen", "helper_alibaba", "helper_kimi"]
const CELL := Vector2i(300, 560)
const DETAIL_CELL := Vector2i(300, 300)
const GRID_CELL := Vector2i(420, 600)
const GRID_COLUMNS := 8


func _initialize() -> void:
	await process_frame
	var settings: Node = root.get_node("Settings")
	settings.graphics = settings.Graphics.HIGH
	settings.resolution = settings.RESOLUTIONS.size() - 1
	settings.apply_graphics(root)
	var groups := OS.get_cmdline_user_args()
	if groups.is_empty():
		groups.append("helpers")
	for group: String in groups:
		if group == "helpers":
			await _helpers_sheet()
		else:
			await _stage_sheet(group)
	quit()


func _helpers_sheet() -> void:
	var people: Array[CharacterData] = []
	for id: String in HELPERS:
		var path := NPC_DIR + id + ".tres"
		if ResourceLoader.exists(path):
			people.append(load(path))
	if people.is_empty():
		return
	var sheet := Image.create(CELL.x * people.size(), CELL.y * 2 + DETAIL_CELL.y * 2, false, Image.FORMAT_RGB8)
	sheet.fill(Color(0.16, 0.16, 0.2))
	for i in people.size():
		var person: CharacterData = people[i]
		var front := await _render(person, CELL, 0.0, 0)
		var side := await _render(person, CELL, PI / 2, 0)
		var chest := await _render(person, DETAIL_CELL, 0.0, 1)
		var head := await _render(person, DETAIL_CELL, 0.35, 2)
		sheet.blit_rect(front, Rect2i(Vector2i.ZERO, CELL), Vector2i(i * CELL.x, 0))
		sheet.blit_rect(side, Rect2i(Vector2i.ZERO, CELL), Vector2i(i * CELL.x, CELL.y))
		sheet.blit_rect(chest, Rect2i(Vector2i.ZERO, DETAIL_CELL), Vector2i(i * CELL.x, CELL.y * 2))
		sheet.blit_rect(head, Rect2i(Vector2i.ZERO, DETAIL_CELL), Vector2i(i * CELL.x, CELL.y * 2 + DETAIL_CELL.y))
		print("rendered ", person.id)
	var out := OUT_DIR + "npcs_helpers.jpg"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out.get_base_dir()))
	sheet.save_jpg(out, 0.9)
	print("saved ", out)


func _stage_sheet(stage: String) -> void:
	var people: Array[CharacterData] = []
	for id in _stage_ids(stage):
		var path := NPC_DIR + id + ".tres"
		if ResourceLoader.exists(path):
			people.append(load(path))
		else:
			print("skipped (not built): ", id)
	if people.is_empty():
		return
	var columns: int = mini(GRID_COLUMNS, people.size())
	var rows: int = ceili(float(people.size()) / columns)
	var sheet := Image.create(GRID_CELL.x * columns, GRID_CELL.y * rows, false, Image.FORMAT_RGB8)
	sheet.fill(Color(0.16, 0.16, 0.2))
	for i in people.size():
		var person: CharacterData = people[i]
		var image := await _render(person, GRID_CELL, 0.0, 0, String(person.id))
		sheet.blit_rect(image, Rect2i(Vector2i.ZERO, GRID_CELL),
			Vector2i((i % columns) * GRID_CELL.x, (i / columns) * GRID_CELL.y))
		print("rendered ", person.id)
	var out := OUT_DIR + "npcs_" + stage + ".jpg"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out.get_base_dir()))
	sheet.save_jpg(out, 0.9)
	print("saved ", out)


## The unique npc ids of a stage, in the order the stage file lists them.
func _stage_ids(stage: String) -> Array[String]:
	var ids: Array[String] = []
	var file := FileAccess.open(STAGE_DIR + stage + ".json", FileAccess.READ)
	if file == null:
		push_error("no stage file for " + stage)
		return ids
	var data: Dictionary = JSON.parse_string(file.get_as_text())
	for actor: Dictionary in data.get("actors", []):
		var id: String = actor.get("npc", "")
		if id != "" and id not in ids:
			ids.append(id)
	return ids


## close_up: 0 = full body, 1 = chest (print), 2 = head. A label renders the id under
## the feet and frames the shot a little wider to make room for it.
func _render(character: CharacterData, size: Vector2i, turn: float, close_up: int, label := "") -> Image:
	var vp := SubViewport.new()
	vp.size = size
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_4X
	root.add_child(vp)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.16, 0.16, 0.2)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.62, 0.7)
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	vp.add_child(world_env)
	var key := DirectionalLight3D.new()
	key.light_energy = 1.5
	vp.add_child(key)
	key.look_at_from_position(Vector3(1.0, 2.5, -2.0), Vector3(0, 1, 0))
	var model := FighterModel.new()
	vp.add_child(model)
	model.build(character)
	model.rotation.y = turn
	for i in 3:
		model.show_clip(&"fight/guard", 0.5, 1.0, 1.0 / 60.0)
		await process_frame
	if label != "":
		var text := Label3D.new()
		text.text = label
		text.font_size = 64
		text.pixel_size = 0.0024
		text.modulate = Color(0.92, 0.92, 0.95)
		text.shaded = false
		text.no_depth_test = true
		text.position = Vector3(0, -0.10, 0.05)
		text.rotation.y = PI
		vp.add_child(text)
	var camera := Camera3D.new()
	vp.add_child(camera)
	if close_up == 2:
		var eyes := model.eye_position()
		camera.fov = 22.0
		camera.look_at_from_position(eyes + Vector3(0, 0.0, -0.75), eyes + Vector3(0, -0.02, 0))
	elif close_up == 1:
		var chest := model.eye_position() + Vector3(0, -0.33, 0)
		camera.fov = 28.0
		camera.look_at_from_position(chest + Vector3(0, 0.0, -0.9), chest)
	else:
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.size = 2.5 if label != "" else 2.3
		camera.look_at_from_position(Vector3(0, 1.0, -5), Vector3(0, 1.0, 0))
	camera.current = true
	for i in 4:
		await process_frame
	var image := vp.get_texture().get_image()
	image.convert(Image.FORMAT_RGB8)
	vp.queue_free()
	return image
