extends SceneTree
## Renders a model sheet of the roster: every fighter full-length in their guard, front and
## side view, with their head close-up below, side by side on one image
## (docs/screenshots/roster.jpg). Handy for checking builds, hair and accessories.
##
## Run windowed (needs a renderer; Xvfb works):
##   xvfb-run -a -s "-screen 0 1920x1080x24" godot --rendering-driver opengl3 --path . -s res://tools/render_model_sheet.gd [-- <id> ...]

var out_path := "res://docs/screenshots/roster.jpg"
var use_alt := false
const CELL := Vector2i(300, 560)
const HEAD_CELL := Vector2i(300, 300)


func _initialize() -> void:
	await process_frame
	var settings: Node = root.get_node("Settings")
	settings.graphics = settings.Graphics.HIGH
	settings.resolution = settings.RESOLUTIONS.size() - 1
	settings.apply_graphics(root)
	var only := OS.get_cmdline_user_args()
	if "alt" in only: # `-- alt <id> ...`: alternate outfits, saved to docs/review/outfits/alt_sheet.jpg
		use_alt = true
		out_path = "res://docs/review/outfits/alt_sheet.jpg"
		only.remove_at(only.find("alt"))
	var roster: Array = (root.get_node("GameState").roster as Array).filter(func(c: CharacterData) -> bool:
		return only.is_empty() or String(c.id) in only)
	var sheet := Image.create(CELL.x * roster.size(), CELL.y * 2 + HEAD_CELL.y, false, Image.FORMAT_RGB8)
	sheet.fill(Color(0.16, 0.16, 0.2))
	for i in roster.size():
		var character: CharacterData = roster[i]
		var front := await _render(character, CELL, 0.0, false)
		var side := await _render(character, CELL, PI / 2, false)
		var head := await _render(character, HEAD_CELL, 0.35, true)
		sheet.blit_rect(front, Rect2i(Vector2i.ZERO, CELL), Vector2i(i * CELL.x, 0))
		sheet.blit_rect(side, Rect2i(Vector2i.ZERO, CELL), Vector2i(i * CELL.x, CELL.y))
		sheet.blit_rect(head, Rect2i(Vector2i.ZERO, HEAD_CELL), Vector2i(i * CELL.x, CELL.y * 2))
		print("rendered ", character.id)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_path.get_base_dir()))
	sheet.save_jpg(out_path, 0.9)
	print("saved ", out_path)
	quit()


func _render(character: CharacterData, size: Vector2i, turn: float, head_only: bool) -> Image:
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
	model.build(character, use_alt)
	model.rotation.y = turn
	for i in 3:
		model.show_clip(&"fight/guard", 0.5, 1.0, 1.0 / 60.0)
		await process_frame
	var camera := Camera3D.new()
	vp.add_child(camera)
	if head_only:
		var eyes := model.eye_position()
		camera.fov = 22.0
		camera.look_at_from_position(eyes + Vector3(0, 0.0, -0.75), eyes + Vector3(0, -0.02, 0))
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
