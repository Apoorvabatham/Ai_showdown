extends SceneTree
## Renders the README screenshots (docs/screenshots/*.jpg, 1920×1080): the title, the
## main menu, character and stage select, CPU-vs-CPU fights on each stage and a super.
##
## Run windowed (needs a renderer; Xvfb works):
##   xvfb-run -a -s "-screen 0 1920x1080x24" godot --rendering-driver opengl3 --path . -s res://tools/render_screenshots.gd

const OUT_DIR := "res://docs/screenshots/"
## [file, p1 id, p2 id, stage, ticks of CPU fighting before the shot, p1 starts its super]
const FIGHTS := [
	["server_farm", &"jensen", &"sundar", "res://scenes/stages/server_farm.tscn", 420, false],
	["mensa", &"dario", &"ram", "res://scenes/stages/mensa.tscn", 600, false],
	["senate", &"donald", &"xi", "res://scenes/stages/senate.tscn", 500, false],
	["super", &"algorithm", &"zuckerbot", "res://scenes/stages/server_farm.tscn", 240, true],
	["super_geoff", &"geoff", &"yann", "res://scenes/stages/senate.tscn", 240, true],
]

var gs


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	await process_frame
	var settings: Node = root.get_node("Settings")
	settings.graphics = settings.Graphics.HIGH
	settings.resolution = settings.RESOLUTIONS.size() - 1
	settings.display_mode = settings.DisplayMode.WINDOWED
	settings.window_size = settings.WINDOW_SIZES.find(Vector2i(1920, 1080))
	settings.fight_intros = false
	settings.apply_display()
	for i in 10:
		await process_frame
	settings.apply_graphics(root)
	gs = root.get_node("GameState")
	ReplayRecorder.enabled = false

	change_scene_to_file("res://scenes/title.tscn")
	await _frames(20)
	_save("title")
	var frames := 0
	while (current_scene == null or current_scene.scene_file_path != "res://scenes/main_menu.tscn") and frames < 2400:
		await process_frame
		frames += 1
	await _frames(150)
	_save("main_menu")

	gs.mode = gs.Mode.VS_CPU
	gs.player_character = gs.find_character(&"jensen")
	change_scene_to_file("res://scenes/character_select.tscn")
	await _frames(120)
	_save("character_select")
	gs.p2_character = gs.find_character(&"sundar")
	gs.stage_path = gs.SENATE_STAGE
	change_scene_to_file("res://scenes/stage_select.tscn")
	await _frames(40)
	_save("stage_select")

	for shot: Array in FIGHTS:
		await _fight(shot)
	quit()


func _fight(shot: Array) -> void:
	gs.mode = gs.Mode.VS_CPU
	gs.player_character = gs.find_character(shot[1])
	gs.p2_character = gs.find_character(shot[2])
	gs.stage_path = shot[3]
	change_scene_to_file("res://scenes/fight.tscn")
	await _frames(4)
	var fight = current_scene
	fight.set_physics_process(false)
	var p1_ai := AIController.new(AIController.Difficulty.HARD, 11)
	p1_ai.attach(fight.fighters[0])
	fight.fighters[0].controller = p1_ai
	fight.start_fight_immediately()
	var ticks: int = shot[4]
	for i in ticks:
		fight.step()
		if i % 4 == 0:
			await process_frame
	if shot[5]:
		var p1: Fighter = fight.fighters[0]
		var super_move: MoveData
		for mv in p1.data.moves:
			if mv.super_move:
				super_move = mv
		p1.position.x = fight.fighters[1].position.x - 1.3 * signf(fight.fighters[1].position.x - p1.position.x)
		p1.add_meter(p1.MAX_METER)
		p1._start_move(super_move, false)
		for i in 26:
			fight.step()
			await process_frame
	await _frames(12)
	_save(shot[0])


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _save(file: String) -> void:
	var image := root.get_texture().get_image()
	if image.get_size() != Vector2i(1920, 1080):
		image.resize(1920, 1080, Image.INTERPOLATE_LANCZOS)
	var path := OUT_DIR + file + ".jpg"
	image.save_jpg(path, 0.88)
	print("saved ", path)
