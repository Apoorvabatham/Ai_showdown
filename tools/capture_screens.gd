extends SceneTree
## Visual QA capture: real 1920x1080 screenshots of every player-facing screen, saved as
## JPG into docs/review/qa/ (title, menus, selects, loading screen, a fight on each
## AI Showdown stage with the HUD, pause + move list, training, supers, victories).
## Builds on tools/render_screenshots.gd (the README shots). Cosmetic only.
##
## Run windowed (needs a GPU renderer, not --headless):
##   godot --path . -s res://tools/capture_screens.gd [-- victories]

const OUT_DIR := "res://docs/review/qa/"
## [file, p1 id, p2 id, stage, ticks of CPU fighting before the shot]
const FIGHTS := [
	["fight_server_farm", &"jensen", &"sundar", "res://scenes/stages/server_farm.tscn", 420],
	["fight_mensa", &"dario", &"ram", "res://scenes/stages/mensa.tscn", 600],
	["fight_senate", &"donald", &"xi", "res://scenes/stages/senate.tscn", 500],
	["fight_foundry", &"tesla", &"zuckerbot", "res://scenes/stages/foundry.tscn", 500],
]
## [file, p1 id, p2 id, stage, frames into the scene]
const SUPERS := [
	["super_jacket_tornado", &"jensen", &"geoff", "res://scenes/stages/foundry.tscn", 90],
	["super_tariff_stamp", &"donald", &"zuckerbot", "res://scenes/stages/senate.tscn", 90],
	["super_lecture_hall", &"geoff", &"yann", "res://scenes/stages/mensa.tscn", 90],
]
const VICTORIES := [
	["victory_tesla", &"tesla", &"jensen", "res://scenes/stages/server_farm.tscn"],
	["victory_xi", &"xi", &"sundar", "res://scenes/stages/senate.tscn"],
	["victory_dario", &"dario", &"ram", "res://scenes/stages/mensa.tscn"],
]

var gs


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	await process_frame
	var settings: Node = root.get_node("Settings")
	settings.graphics = settings.Graphics.HIGH
	settings.auto_graphics = false
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
	if "victories" in OS.get_cmdline_user_args(): # -- victories: only the victory shots
		for shot: Array in VICTORIES:
			await _victory(shot)
		quit()
		return

	change_scene_to_file("res://scenes/title.tscn")
	await _frames(20)
	_save("title")
	await _frames(90)
	_save("title_later")
	var frames := 0
	while (current_scene == null or current_scene.scene_file_path != "res://scenes/main_menu.tscn") and frames < 2400:
		await process_frame
		frames += 1
	await _frames(150)
	_save("main_menu")

	gs.mode = gs.Mode.VS_CPU
	gs.player_character = gs.find_character(&"ram")
	change_scene_to_file("res://scenes/character_select.tscn")
	await _frames(120)
	_save("character_select_ram")
	gs.player_character = gs.find_character(&"dario")
	change_scene_to_file("res://scenes/character_select.tscn")
	await _frames(120)
	_save("character_select_dario")

	gs.p2_character = gs.find_character(&"sundar")
	gs.stage_path = gs.FOUNDRY_STAGE
	change_scene_to_file("res://scenes/stage_select.tscn")
	await _frames(40)
	_save("stage_select")

	# Loading screen: the real path into a fight.
	gs.mode = gs.Mode.VS_CPU
	gs.player_character = gs.find_character(&"jensen")
	gs.p2_character = gs.find_character(&"sundar")
	gs.stage_path = gs.SERVER_FARM_STAGE
	gs.go_to_fight(self)
	await _frames(6)
	_save("loading_screen")
	frames = 0
	while (current_scene == null or current_scene.scene_file_path != "res://scenes/fight.tscn") and frames < 2400:
		await process_frame
		frames += 1
	await _frames(30)
	_save("fight_start_round")

	for shot: Array in FIGHTS:
		await _fight(shot)
	await _pause()
	await _training()
	for shot: Array in SUPERS:
		await _super(shot)
	for shot: Array in VICTORIES:
		await _victory(shot)
	quit()


func _load_fight(p1: StringName, p2: StringName, stage: String, mode = null) -> Node:
	gs.mode = gs.Mode.VS_CPU if mode == null else mode
	gs.player_character = gs.find_character(p1)
	gs.p2_character = gs.find_character(p2)
	gs.stage_path = stage
	change_scene_to_file("res://scenes/fight.tscn")
	await _frames(6)
	return current_scene


func _fight(shot: Array) -> void:
	var fight = await _load_fight(shot[1], shot[2], shot[3])
	fight.set_physics_process(false)
	var p1_ai := AIController.new(AIController.Difficulty.HARD, 11)
	p1_ai.attach(fight.fighters[0])
	fight.fighters[0].controller = p1_ai
	fight.start_fight_immediately()
	for i in int(shot[4]):
		fight.step()
		if i % 4 == 0:
			await process_frame
	await _frames(12)
	_save(shot[0])


func _pause() -> void:
	var fight = await _load_fight(&"geoff", &"yann", gs.MENSA_STAGE)
	fight.start_fight_immediately()
	await _frames(60)
	paused = true
	fight.hud.show_pause()
	await _frames(20)
	_save("pause_menu")
	fight.hud.move_list_panel.visible = true
	await _frames(20)
	_save("pause_move_list")
	fight.hud.hide_pause()
	fight.hud.move_list_panel.visible = false
	paused = false


func _training() -> void:
	await _load_fight(&"sundar", &"donald", gs.SERVER_FARM_STAGE, gs.Mode.TRAINING)
	await _frames(150)
	_save("training")


func _super(shot: Array) -> void:
	var fight = await _load_fight(shot[1], shot[2], shot[3])
	fight.set_physics_process(false)
	fight.start_fight_immediately()
	var p1: Fighter = fight.fighters[0]
	var p2: Fighter = fight.fighters[1]
	p1.controller = fight.dummy
	p2.controller = fight.dummy
	fight.dummy.mode = DummyController.Mode.STAND
	p1.position.x = -0.45
	p2.position.x = 0.45
	p1.add_meter(Fighter.MAX_METER)
	var super_move: MoveData
	for mv: MoveData in p1.data.moves:
		if mv.super_move:
			super_move = mv
	var started := [false]
	fight.cinematic_started.connect(func(_a, _d, _m): started[0] = true)
	p1._start_move(super_move, false)
	var guard := 0
	while not started[0] and guard < 600:
		fight.step()
		guard += 1
		if guard % 3 == 0:
			await process_frame
	if not started[0]:
		print("no cinematic for ", shot[0])
	for i in int(shot[4]):
		fight.step()
		await process_frame
	await _frames(4)
	_save(shot[0])


func _victory(shot: Array) -> void:
	var fight = await _load_fight(shot[1], shot[2], shot[3])
	fight.set_physics_process(false)
	fight.start_fight_immediately()
	var p1: Fighter = fight.fighters[0]
	p1.controller = fight.dummy
	fight.fighters[1].controller = fight.dummy
	fight.dummy.mode = DummyController.Mode.STAND
	fight.round_wins[0] = 1
	fight.phase = fight.Phase.MATCH_OVER
	fight._start_victory(p1)
	for i in 150:
		fight.step()
		await process_frame
	_save(shot[0])
	for i in 200:
		fight.step()
		await process_frame
	_save(shot[0] + "_result")


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _save(file: String) -> void:
	var image := root.get_texture().get_image()
	if image.get_size() != Vector2i(1920, 1080):
		image.resize(1920, 1080, Image.INTERPOLATE_LANCZOS)
	var path := OUT_DIR + file + ".jpg"
	image.save_jpg(path, 0.85)
	print("saved ", path)
