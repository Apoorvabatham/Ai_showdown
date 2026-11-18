extends SceneTree
## Renders a review sheet of the NPCs in res://data/npcs/: front and side full length,
## the chest print and the head. Saves to docs/review/opencode/.
##
## Run windowed (needs a renderer):
##   godot --rendering-driver opengl3 --path . -s res://tools/render_npcs.gd [-- <id> ...]

const NPC_DIR := "res://data/npcs/"
const OUT := "res://docs/review/opencode/npcs_helpers.jpg"
const CELL := Vector2i(300, 560)
const DETAIL_CELL := Vector2i(300, 300)


func _initialize() -> void:
	await process_frame
	var settings: Node = root.get_node("Settings")
	settings.graphics = settings.Graphics.HIGH
	settings.resolution = settings.RESOLUTIONS.size() - 1
	settings.apply_graphics(root)
	var only := OS.get_cmdline_user_args()
	var ids := ["helper_qwen", "helper_alibaba", "helper_kimi"]
	var people: Array[CharacterData] = []
	for id: String in ids:
		if only.is_empty() or id in only:
			var path := NPC_DIR + id + ".tres"
			if ResourceLoader.exists(path):
				people.append(load(path))
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
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.get_base_dir()))
	sheet.save_jpg(OUT, 0.9)
	print("saved ", OUT)
	quit()


## close_up: 0 = full body, 1 = chest (print), 2 = head.
func _render(character: CharacterData, size: Vector2i, turn: float, close_up: int) -> Image:
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
		camera.size = 2.3
		camera.look_at_from_position(Vector3(0, 1.0, -5), Vector3(0, 1.0, 0))
	camera.current = true
	for i in 4:
		await process_frame
	var image := vp.get_texture().get_image()
	image.convert(Image.FORMAT_RGB8)
	vp.queue_free()
	return image
