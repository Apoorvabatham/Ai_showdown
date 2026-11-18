extends SceneTree
## Renders AGI's three boss-phase looks (O4) side by side: the normal bodysuit, the
## phase 2 "agent" palette and the phase 3 "superintelligence" palette, full length with
## an upper-body close-up underneath. Saves docs/review/opencode/agi_phases.jpg.
##
## Run windowed (needs a renderer):
##   godot --rendering-driver opengl3 --path . -s res://tools/render_phase_looks.gd

const CHARACTER := "res://data/characters/algorithm.tres"
const OUT := "res://docs/review/opencode/agi_phases.jpg"
const CELL := Vector2i(420, 600)
const DETAIL_CELL := Vector2i(420, 420)
const PHASES := [
	{index = -1, label = "1: assistant"},
	{index = 0, label = "2: agent (glitch)"},
	{index = 1, label = "3: superintelligence"},
]


func _initialize() -> void:
	await process_frame
	var settings: Node = root.get_node("Settings")
	settings.graphics = settings.Graphics.HIGH
	settings.resolution = settings.RESOLUTIONS.size() - 1
	settings.apply_graphics(root)
	var character := load(CHARACTER) as CharacterData
	var sheet := Image.create(CELL.x * PHASES.size(), CELL.y + DETAIL_CELL.y, false, Image.FORMAT_RGB8)
	sheet.fill(Color(0.1, 0.1, 0.13))
	for i in PHASES.size():
		var phase: Dictionary = PHASES[i]
		var front := await _render(character, CELL, 0, phase.index, phase.label)
		var chest := await _render(character, DETAIL_CELL, 1, phase.index, "")
		sheet.blit_rect(front, Rect2i(Vector2i.ZERO, CELL), Vector2i(i * CELL.x, 0))
		sheet.blit_rect(chest, Rect2i(Vector2i.ZERO, DETAIL_CELL), Vector2i(i * CELL.x, CELL.y))
		print("rendered ", phase.label)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.get_base_dir()))
	sheet.save_jpg(OUT, 0.9)
	print("saved ", OUT)
	quit()


## close_up: 0 = full body, 1 = upper body. `variant`: -1 = normal, 0.. = phase palette.
func _render(character: CharacterData, size: Vector2i, close_up: int, variant: int, label: String) -> Image:
	var vp := SubViewport.new()
	vp.size = size
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_4X
	root.add_child(vp)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.1, 0.1, 0.13)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.62, 0.7)
	env.ambient_light_energy = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	vp.add_child(world_env)
	var key := DirectionalLight3D.new()
	key.light_energy = 1.2
	vp.add_child(key)
	key.look_at_from_position(Vector3(1.0, 2.5, -2.0), Vector3(0, 1, 0))
	var rim := DirectionalLight3D.new()
	rim.light_energy = 0.7
	vp.add_child(rim)
	rim.look_at_from_position(Vector3(-1.5, 2.0, 2.5), Vector3(0, 1.2, 0))
	var model := FighterModel.new()
	vp.add_child(model)
	model.build(character)
	model.set_look_variant(variant)
	for i in 3:
		model.show_clip(&"fight/guard", 0.5, 1.0, 1.0 / 60.0)
		await process_frame
	if label != "":
		var text := Label3D.new()
		text.text = label
		text.font_size = 64
		text.pixel_size = 0.0017
		text.modulate = Color(0.92, 0.92, 0.95)
		text.shaded = false
		text.no_depth_test = true
		text.position = Vector3(0, -0.10, 0.05)
		text.rotation.y = PI
		vp.add_child(text)
	var camera := Camera3D.new()
	vp.add_child(camera)
	if close_up == 1:
		var chest := model.eye_position() + Vector3(0, -0.28, 0)
		camera.fov = 30.0
		camera.look_at_from_position(chest + Vector3(0, 0.02, -1.1), chest)
	else:
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.size = 2.5
		camera.look_at_from_position(Vector3(0, 1.0, -5), Vector3(0, 1.0, 0))
	camera.current = true
	for i in 4:
		await process_frame
	var image := vp.get_texture().get_image()
	image.convert(Image.FORMAT_RGB8)
	vp.queue_free()
	return image
