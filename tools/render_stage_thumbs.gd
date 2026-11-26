extends SceneTree
## Renders the stage select thumbnails (res://assets/ui/stages/<stage>.png, 640×360)
## from the fight camera's neutral position, with the two fighters in their stances.
##
## Run windowed (needs a renderer): godot --path . -s res://tools/render_stage_thumbs.gd [-- <stage> ...]

const OUT_DIR := "res://assets/ui/stages/"
const SIZE := Vector2i(640, 360)
## Fixed, reproducible pair of roster fighters per stage (stage file basename -> ids).
const FIGHTERS := {
	"server_farm": [&"jensen", &"sundar"],
	"mensa": [&"dario", &"ram"],
	"senate": [&"donald", &"xi"],
	"foundry": [&"jensen", &"xi"],
}


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	await process_frame
	var settings: Node = root.get_node("Settings") # render at full quality whatever the player's setting
	settings.graphics = settings.Graphics.HIGH
	settings.auto_graphics = false # keep High quality for the whole render
	settings.resolution = settings.RESOLUTIONS.size() - 1 # native
	settings.display_mode = settings.DisplayMode.WINDOWED # 16:9 whatever the player's display setting
	settings.window_size = settings.WINDOW_SIZES.find(Vector2i(1920, 1080))
	settings.fight_intros = false # straight to the neutral fight view (not saved)
	settings.apply_display()
	for i in 10:
		await process_frame
	settings.apply_graphics(root)
	var gs = root.get_node("GameState")
	gs.load_roster() # real AI Showdown fighters, not the engine kit stand-ins
	var only := OS.get_cmdline_user_args() # `-- train dojo` renders just those stages
	for stage: Dictionary in gs.stages:
		var basename := String(stage.path).get_file().get_basename()
		if not only.is_empty() and not basename in only:
			continue
		var pair: Array = FIGHTERS.get(basename, [&"jensen", &"xi"])
		gs.player_character = gs.find_character(pair[0])
		gs.p2_character = gs.find_character(pair[1])
		gs.stage_path = stage.path
		change_scene_to_file("res://scenes/fight.tscn")
		for i in 4:
			await process_frame
		var manager = current_scene
		manager.set_physics_process(false)
		manager.hud.visible = false
		manager.start_fight_immediately()
		var life = manager.stage.get_node_or_null("Life") # the courtyard: show the final round's sunlight, not dawn
		if life:
			manager.round_number = 3
			life.day = 1.0
		for i in 40: # let the stance animations, reflection probe and camera settle
			await process_frame
		var image := root.get_texture().get_image()
		image.resize(SIZE.x, SIZE.y, Image.INTERPOLATE_LANCZOS)
		var file := OUT_DIR + String(stage.path).get_file().get_basename() + ".png"
		image.save_png(file)
		print("saved ", file)
	quit()
