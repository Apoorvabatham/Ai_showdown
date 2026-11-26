extends SceneTree
## Renders the AI Showdown key art: the whole roster lined up in their fight stances, lit
## cyan and magenta, on a transparent background (assets/ui/source/key_art_fighters.png).
## tools/build_showdown_art.py then composes the splash, wallpaper and logo around it.
##
## Run WINDOWED (needs the renderer): godot --path . -s res://tools/render_key_art.gd

const OUT := "res://assets/ui/source/key_art_fighters.png"
const SIZE := Vector2i(1920, 1080)
## Lineup slots (x, z, scale) by roster order: six in front, four behind, and AGI (boss)
## looming large in the center back. The back rank stands in the gaps between the front
## one (not behind a front fighter, which read as two fighters inside each other) and far
## enough back that its silhouettes clear the front rank at 1920x1080 and 1280x720.
const SLOTS := [
	Vector3(-4.0, 0.0, 1.0), Vector3(-2.4, 0.0, 1.0), Vector3(-0.8, 0.0, 1.0),
	Vector3(0.8, 0.0, 1.0), Vector3(2.4, 0.0, 1.0), Vector3(4.0, 0.0, 1.0),
	Vector3(-4.174, 3.1, 1.0), Vector3(-2.086, 3.1, 1.0),
	Vector3(2.086, 3.1, 1.0), Vector3(4.174, 3.1, 1.0),
	Vector3(0.0, 3.4, 1.5),
]


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.get_base_dir()))
	await process_frame
	var settings: Node = root.get_node("Settings")
	settings.graphics = settings.Graphics.HIGH
	settings.resolution = settings.RESOLUTIONS.size() - 1
	settings.apply_graphics(root)
	var roster: Array = root.get_node("GameState").roster

	var vp := SubViewport.new()
	vp.size = SIZE
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_4X
	root.add_child(vp)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.52, 0.65)
	env.ambient_light_energy = 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	vp.add_child(world_env)
	var target := Vector3(0, 1.1, 1.0)
	for light_spec: Array in [[Vector3(0.5, 3.0, -4.0), Color(1.0, 0.95, 0.9), 1.4],
			[Vector3(-4.0, 2.0, 3.0), Color(0.2, 0.9, 1.0), 2.6], [Vector3(4.0, 2.0, 3.0), Color(1.0, 0.25, 0.8), 2.6]]:
		var light := DirectionalLight3D.new()
		light.light_color = light_spec[1]
		light.light_energy = light_spec[2]
		vp.add_child(light)
		light.look_at_from_position(light_spec[0], target)

	var models: Array = []
	for i in mini(roster.size(), SLOTS.size()):
		var character: CharacterData = roster[i]
		var model := FighterModel.new()
		vp.add_child(model)
		model.build(character)
		var slot: Vector3 = SLOTS[i]
		model.position = Vector3(slot.x, 0, slot.y)
		model.scale = Vector3.ONE * slot.z
		# Fighters face -Z, toward the camera; turn each a little toward the middle.
		model.rotation.y = -slot.x * 0.06
		models.append([model, character])
	for frame in 4:
		for entry: Array in models:
			var character: CharacterData = entry[1]
			(entry[0] as FighterModel).show_clip(&"fight/guard", 0.5, 1.0, 1.0 / 60.0)
		await process_frame
	var camera := Camera3D.new()
	camera.fov = 30.0
	vp.add_child(camera)
	camera.look_at_from_position(Vector3(0, 0.9, -10.0), Vector3(0, 2.1, 1.0))
	camera.current = true
	for frame in 6:
		await process_frame
	vp.get_texture().get_image().save_png(OUT)
	print("saved ", OUT)
	quit()
