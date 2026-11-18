extends SceneTree
## Renders every super and victory scene as a 1920x720 (3x2) contact sheet
## into docs/review/gemini/scenes/.
##
## Usage:
##   godot --path . -s res://tools/render_scene_sheets.gd [-- <name> ...]

const OUT_DIR := "res://docs/review/gemini/scenes/"

const SUPERS := [
	{"id": &"tesla", "opp": &"jensen", "out": "super_rocket_launch"},
	{"id": &"donald", "opp": &"zuckerbot", "out": "super_tariff_stamp"},
	{"id": &"zuckerbot", "opp": &"tesla", "out": "super_metaverse_trap"},
	{"id": &"sundar", "opp": &"donald", "out": "super_not_found"},
	{"id": &"jensen", "opp": &"geoff", "out": "super_jacket_tornado"},
	{"id": &"xi", "opp": &"sundar", "out": "super_open_source_squad"},
]

const VICTORIES := [
	{"id": &"tesla", "opp": &"jensen", "out": "victory_tesla"},
	{"id": &"donald", "opp": &"zuckerbot", "out": "victory_donald"},
	{"id": &"zuckerbot", "opp": &"tesla", "out": "victory_zuckerbot"},
	{"id": &"sundar", "opp": &"donald", "out": "victory_sundar"},
	{"id": &"jensen", "opp": &"geoff", "out": "victory_jensen"},
	{"id": &"xi", "opp": &"sundar", "out": "victory_xi"},
	{"id": &"dario", "opp": &"ram", "out": "victory_dario"},
	{"id": &"yann", "opp": &"geoff", "out": "victory_yann"},
	{"id": &"geoff", "opp": &"yann", "out": "victory_geoff"},
	{"id": &"ram", "opp": &"dario", "out": "victory_ram"},
	{"id": &"algorithm", "opp": &"zuckerbot", "out": "victory_algorithm"},
]

var gs: Node


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
	gs.load_roster()
	gs.stages = gs.STAGES
	ReplayRecorder.enabled = false

	var only := OS.get_cmdline_user_args()
	
	# Render Supers
	for entry in SUPERS:
		if only.is_empty() or entry["out"] in only or String(entry["id"]) in only:
			print("=== Rendering super: ", entry["out"], " ===")
			await _render_super(entry["id"], entry["opp"], entry["out"])
	
	# Render Victories
	for entry in VICTORIES:
		if only.is_empty() or entry["out"] in only or String(entry["id"]) in only:
			print("=== Rendering victory: ", entry["out"], " ===")
			await _render_victory(entry["id"], entry["opp"], entry["out"])

	print("=== All scene contact sheets completed ===")
	quit(0)


func _render_super(p1_id: StringName, p2_id: StringName, out_name: String) -> void:
	gs.mode = gs.Mode.VS_CPU
	gs.player_character = gs.find_character(p1_id)
	gs.p2_character = gs.find_character(p2_id)
	change_scene_to_file("res://scenes/fight.tscn")
	for i in 6:
		await process_frame
	var fight = current_scene
	fight.set_physics_process(false)
	fight.start_match(); fight.start_fight_immediately()
	var p1: Fighter = fight.fighters[0]
	var p2: Fighter = fight.fighters[1]
	p1.controller = fight.dummy
	p2.controller = fight.dummy
	fight.dummy.mode = DummyController.Mode.STAND
	p1.position.x = -0.45
	p2.position.x = 0.45
	p1.add_meter(Fighter.MAX_METER)

	var super_move: MoveData = null
	for mv: MoveData in p1.data.moves:
		if mv.super_move:
			super_move = mv
			break
	if not super_move:
		print("No super move found for ", p1_id)
		return

	var started := [false]
	fight.cinematic_started.connect(func(_a, _d, _m): started[0] = true)
	p1._start_move(super_move, false)
	var guard := 0
	while not started[0] and guard < 600:
		fight._physics_process(1.0 / 60.0)
		guard += 1
	for i in 4:
		await process_frame

	var total_ticks: int = fight.freeze_ticks if fight.freeze_ticks > 0 else 360
	var step_ticks: int = total_ticks / 6
	var frames: Array[Image] = []
	for step in range(6):
		for t in step_ticks:
			fight._physics_process(1.0 / 60.0)
		var timer := create_timer(float(step_ticks) / 60.0)
		await timer.timeout
		for f in 4:
			await process_frame
		var img := root.get_texture().get_image()
		img.convert(Image.FORMAT_RGB8)
		img.resize(640, 360, Image.INTERPOLATE_LANCZOS)
		frames.append(img)

	_save_sheet(frames, out_name)


func _render_victory(p1_id: StringName, p2_id: StringName, out_name: String) -> void:
	gs.mode = gs.Mode.VS_CPU
	gs.player_character = gs.find_character(p1_id)
	gs.p2_character = gs.find_character(p2_id)
	change_scene_to_file("res://scenes/fight.tscn")
	for i in 6:
		await process_frame
	var fight = current_scene
	fight.set_physics_process(false)
	fight.start_match(); fight.start_fight_immediately()
	var p1: Fighter = fight.fighters[0]
	var p2: Fighter = fight.fighters[1]
	p1.controller = fight.dummy
	p2.controller = fight.dummy
	fight.dummy.mode = DummyController.Mode.STAND
	fight.phase = fight.Phase.MATCH_OVER
	fight._start_victory(p1)
	for i in 6:
		await process_frame

	var frames: Array[Image] = []
	for step in range(6):
		for t in 35:
			fight._physics_process(1.0 / 60.0)
		var timer := create_timer(0.35)
		await timer.timeout
		for f in 4:
			await process_frame
		var img := root.get_texture().get_image()
		img.convert(Image.FORMAT_RGB8)
		img.resize(640, 360, Image.INTERPOLATE_LANCZOS)
		frames.append(img)

	_save_sheet(frames, out_name)


func _save_sheet(frames: Array[Image], out_name: String) -> void:
	var sheet := Image.create(1920, 720, false, Image.FORMAT_RGB8)
	for idx in range(min(6, frames.size())):
		var col := idx % 3
		var row := idx / 3
		sheet.blit_rect(frames[idx], Rect2i(0, 0, 640, 360), Vector2i(col * 640, row * 360))
	var out_path := OUT_DIR + out_name + ".jpg"
	sheet.save_jpg(out_path, 0.9)
	print("Saved contact sheet: ", out_path)
