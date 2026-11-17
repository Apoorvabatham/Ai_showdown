extends Node
## Global game state: roster, current selections, match settings.

## The AI Showdown roster.
const CHARACTER_DIR := "res://data/characters/"
## The original 3D Fighter cast: the kits the roster is built on (CharacterData.kit), and
## the roster the engine regression tests run against (use_engine_content).
const KIT_DIR := "res://data/kits/"
const DEFAULT_STAGE := "res://scenes/stages/ring.tscn"
const DOJO_STAGE := "res://scenes/stages/dojo.tscn"
const ROOFTOP_STAGE := "res://scenes/stages/rooftop.tscn"
const TEMPLE_STAGE := "res://scenes/stages/temple.tscn"
const BEACH_STAGE := "res://scenes/stages/beach.tscn"
const MARKET_STAGE := "res://scenes/stages/market.tscn"
const TRAIN_STAGE := "res://scenes/stages/train.tscn"
const COURTYARD_STAGE := "res://scenes/stages/courtyard.tscn"
## AI Showdown's stages: original stages rethemed (scripts/stages/stage_retheme.gd).
const SERVER_FARM_STAGE := "res://scenes/stages/server_farm.tscn"
const MENSA_STAGE := "res://scenes/stages/mensa.tscn"
const SENATE_STAGE := "res://scenes/stages/senate.tscn"
const FOUNDRY_STAGE := "res://scenes/stages/foundry.tscn"
## Selectable stages: scene, display name, select-screen thumbnail (rendered by
## tools/render_stage_thumbs.gd) and a one-line description.
const STAGES := [
	{path = SERVER_FARM_STAGE, name = "Server Farm", thumb = "res://assets/ui/stages/server_farm.png",
		blurb = "A rooftop full of humming GPU racks. Mind the liquid cooling."},
	{path = MENSA_STAGE, name = "Mensa", thumb = "res://assets/ui/stages/mensa.png",
		blurb = "The university cafeteria at lunch rush. Today's special: alignment soup."},
	{path = SENATE_STAGE, name = "Senate Hearing Room", thumb = "res://assets/ui/stages/senate.png",
		blurb = "A televised hearing on AI oversight. Everyone is under oath."},
	{path = FOUNDRY_STAGE, name = "GPU Foundry", thumb = "res://assets/ui/stages/foundry.png",
		blurb = "Where 3nm wafers meet 3-frame jabs. Don't touch the EUV scanner."},
]
## The original 3D Fighter stages (still in the project: the AI Showdown stages build on
## them), used by the engine regression tests.
const ENGINE_STAGES := [
	{path = DEFAULT_STAGE, name = "Boxing Ring", thumb = "res://assets/ui/stages/ring.png",
		blurb = "Under the arena lights, in front of a packed house."},
	{path = DOJO_STAGE, name = "Dojo", thumb = "res://assets/ui/stages/dojo.png",
		blurb = "Tatami, paper screens and a hall full of students."},
	{path = ROOFTOP_STAGE, name = "Rooftop", thumb = "res://assets/ui/stages/rooftop.png",
		blurb = "A helipad high above the city lights."},
	{path = TEMPLE_STAGE, name = "Temple", thumb = "res://assets/ui/stages/temple.png",
		blurb = "A mountain courtyard at sunset, under falling blossom."},
	{path = BEACH_STAGE, name = "Beach", thumb = "res://assets/ui/stages/beach.png",
		blurb = "Sun, sand and turquoise surf, ringed by tiki torches."},
	{path = MARKET_STAGE, name = "Night Market", thumb = "res://assets/ui/stages/market.png",
		blurb = "A Manila street at dusk: grill smoke, jeepneys and fiesta flags."},
	{path = TRAIN_STAGE, name = "Express", thumb = "res://assets/ui/stages/train.png",
		blurb = "On the roof of an express train racing through the hills at sunset."},
	{path = COURTYARD_STAGE, name = "Kowloon Courtyard", thumb = "res://assets/ui/stages/courtyard.png",
		blurb = "An old tenement courtyard at dawn. The neighbours wake up as the sun climbs."},
]

## The stages in play (STAGES, or ENGINE_STAGES under use_engine_content), and the one
## Arcade's boss fight is held on.
var stages: Array = STAGES
var boss_stage := SENATE_STAGE

## Arcade's final boss when the player picked someone else (see ArcadeRun.create).
const FINAL_BOSS := &"algorithm"
const ROUNDS_TO_WIN := 2
const ROUND_TIME_SECONDS := 99

enum Mode { VS_CPU, VERSUS, TRAINING, ARCADE, ONLINE, DEMO, REPLAY }

var roster: Array[CharacterData] = []
## VS_CPU: P2 is the AI. VERSUS: P2 is a second local player. TRAINING: P2 is the
## training dummy (see scripts/training/training_mode.gd). ARCADE: a ladder of CPU
## opponents (see `arcade`). DEMO: two CPU fighters with no end (start_demo).
var mode: Mode = Mode.VS_CPU
var player_character: CharacterData
## P2's character (the CPU in VS_CPU mode, the second player in VERSUS).
var p2_character: CharacterData
var stage_path: String = SERVER_FARM_STAGE
## Seeds the CPU's decisions; the same seed and inputs replay the same match.
var match_seed := 1
## The Arcade run in progress (ARCADE mode), or null.
var arcade: ArcadeRun
## REPLAY: the saved match being watched.
var replay: Replay
## Stage preloaded by the loading screen, kept referenced so it stays in the resource
## cache until the fight scene loads it (the loading screen itself is freed first).
var preloaded_stage: Resource
## The stage already instantiated by the loading screen (on a worker thread: big stages
## took 200–400 ms on the main thread), for FightManager to take with take_stage_node().
var preloaded_stage_node: Node

const LOADING_SCENE := "res://scenes/loading_screen.tscn"

## The fighters' textures, loaded on background threads by the title screen and kept for
## the whole session (FighterModel.texture_paths: decoding them took ~6 s, repeated on
## every visit to character select because nothing else held them).
var _fighter_texture_paths := PackedStringArray()
var _fighter_textures: Array[Resource] = []
## Materials kept for the session so their generated shaders are too (keep_materials).
var _kept_materials := {}


func _ready() -> void:
	load_roster()


## Starts loading every roster fighter's textures in the background (once per session).
func preload_fighters() -> void:
	if not _fighter_texture_paths.is_empty():
		return
	var unique := {}
	for character in roster:
		for path in FighterModel.texture_paths(character):
			unique[path] = true
	_fighter_texture_paths = PackedStringArray(unique.keys())
	for path in _fighter_texture_paths:
		ResourceLoader.load_threaded_request(path, "", true)


## How far preload_fighters() has got (0–1). Collects and keeps the textures once all
## are loaded, so call it until it returns 1.
func fighter_preload_progress() -> float:
	if _fighter_texture_paths.is_empty() or _fighter_textures.size() == _fighter_texture_paths.size():
		return 1.0
	var done := 0.0
	var finished := true
	for path in _fighter_texture_paths:
		var progress := []
		match ResourceLoader.load_threaded_get_status(path, progress):
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				done += progress[0] if not progress.is_empty() else 0.0
				finished = false
			_: # loaded, or failed (FighterModel then loads it itself)
				done += 1.0
	if not finished:
		return done / _fighter_texture_paths.size()
	for path in _fighter_texture_paths:
		_fighter_textures.append(ResourceLoader.load_threaded_get(path))
	return 1.0


## The loading screen's instantiated stage if it is `path`'s, else null (the caller then
## instantiates it itself). Hands it over only once.
func take_stage_node(path: String) -> Node:
	var node := preloaded_stage_node
	preloaded_stage_node = null
	if node and node.scene_file_path != path:
		node.free()
		return null
	return node


## Holds one set of `materials` under `key` for the rest of the session. Godot frees a
## generated material's shader once nothing uses it, so each scene's first fighter used to
## rebuild its skin, hair and cloth shaders (~220 ms) and each fight its effect shaders,
## all while the loading screen sat frozen at 100%. FighterModel keeps one set per look,
## FightFx its particle materials.
func keep_materials(key: String, materials: Array) -> void:
	if not _kept_materials.has(key):
		_kept_materials[key] = materials


## Waits for any preload still running (quitting with loads in flight can crash on exit).
func _exit_tree() -> void:
	if preloaded_stage_node:
		preloaded_stage_node.free() # quit while the fight was about to start
	if _fighter_textures.size() < _fighter_texture_paths.size():
		for path in _fighter_texture_paths:
			ResourceLoader.load_threaded_get(path)


## Loads the roster: every CharacterData in `dir`, by select_order.
func load_roster(dir := CHARACTER_DIR) -> void:
	roster.clear()
	# list_directory handles exported (.remap) resources, unlike DirAccess.
	for file in ResourceLoader.list_directory(dir):
		if not file.ends_with(".tres"):
			continue
		var data := load(dir + file) as CharacterData
		if data:
			roster.append(data)
	roster.sort_custom(func(a: CharacterData, b: CharacterData) -> bool: return a.select_order < b.select_order)


## Switches to the original 3D Fighter content (the 8 kit fighters, the 8 original
## stages, the dojo boss stage), which the engine regression tests are written against.
func use_engine_content() -> void:
	load_roster(KIT_DIR)
	stages = ENGINE_STAGES
	boss_stage = DOJO_STAGE
	stage_path = DEFAULT_STAGE
	player_character = null
	p2_character = null


## The roster fighter with this id, or null.
func find_character(character_id: StringName) -> CharacterData:
	for character in roster:
		if character.id == character_id:
			return character
	return null


## Random CPU opponent, preferring someone other than the player.
func pick_random_cpu() -> CharacterData:
	var others := roster.filter(func(c: CharacterData) -> bool: return c != player_character)
	if others.is_empty():
		return player_character
	return others.pick_random()


## Goes to the fight through the loading screen (wallpaper + progress bar).
func go_to_fight(tree: SceneTree) -> void:
	tree.change_scene_to_file(LOADING_SCENE)


## Demo mode: two random fighters (different ones when possible) on a random stage, both
## played by the CPU, through the loading screen. DemoMode calls it again for the next one.
func start_demo(tree: SceneTree) -> void:
	mode = Mode.DEMO
	player_character = roster.pick_random()
	p2_character = pick_random_cpu()
	stage_path = (stages.pick_random() as Dictionary).path
	match_seed = randi()
	go_to_fight(tree)


## Watches a saved replay (Replay.problem() must be empty): its fighters and stage,
## through the loading screen.
func start_replay(tree: SceneTree, saved: Replay) -> void:
	mode = Mode.REPLAY
	replay = saved
	for character in roster:
		if String(character.id) == str(saved.meta.p1):
			player_character = character
		if String(character.id) == str(saved.meta.p2):
			p2_character = character
	stage_path = str(saved.meta.stage)
	go_to_fight(tree)


## Starts an Arcade run with `character` and sets up its first opponent.
func start_arcade(character: CharacterData) -> void:
	player_character = character
	arcade = ArcadeRun.create(character, roster, Settings.ai_difficulty, randi(), arcade_arenas(), boss_stage,
		find_character(FINAL_BOSS))
	apply_arcade_stage()


func apply_arcade_stage() -> void:
	p2_character = arcade.current().character
	stage_path = arcade.current().stage_path


func stage_paths() -> Array:
	return stages.map(func(s: Dictionary) -> String: return s.path)


## Stages for Arcade's regular fights: every stage except the boss's, so a run visits
## all of them.
func arcade_arenas() -> Array:
	return stage_paths().filter(func(path: String) -> bool: return path != boss_stage)


## Display name of a stage scene (for the VS screen etc.).
func stage_name(path: String) -> String:
	for stage: Dictionary in stages:
		if stage.path == path:
			return stage.name
	return ""


func is_arcade() -> bool:
	return mode == Mode.ARCADE and arcade != null


func is_online() -> bool:
	return mode == Mode.ONLINE


func game_version() -> String:
	return str(ProjectSettings.get_setting("application/config/version", "0"))


## A hash of every character's stats and moves. Online peers must match exactly, or the
## same inputs would play out differently on each machine.
func content_hash() -> int:
	var parts := []
	for character in roster:
		parts.append(_stored_values(character))
		for move in character.moves:
			parts.append(_stored_values(move))
	return hash(var_to_bytes(parts)) & 0xFFFFFFFF


func _stored_values(resource: Resource) -> Array:
	var out := []
	for property in resource.get_property_list():
		var key: String = property.name
		if not (property.usage & PROPERTY_USAGE_STORAGE) or key.begins_with("resource_") or key == "script":
			continue
		var value: Variant = resource.get(key)
		if value is Resource:
			value = (value as Resource).resource_path
		elif value is Array:
			value = (value as Array).map(func(v: Variant) -> Variant: return v.resource_path if v is Resource else v)
		out.append([key, value])
	return out


## Fills missing selections so a scene can be run directly from the editor (F6).
func ensure_selections() -> void:
	if player_character == null and not roster.is_empty():
		player_character = roster[0]
	if p2_character == null:
		p2_character = pick_random_cpu()
