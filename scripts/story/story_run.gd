class_name StoryRun
extends RefCounted
## One Story mode run: intro, 6 fights with pre-fight and post-win dialogue,
## rival fight, AGI finale, and ending. Saved in user://story_progress.cfg.

static var save_path := "user://story_progress.cfg"

enum State {
	INTRO,
	PRE_FIGHT,
	POST_WIN,
	ENDING,
}

var player: CharacterData
var story_data: Dictionary = {}
var fights: Array[Dictionary] = []
var fight_index: int = 0
var intro_lines: Array[String] = []
var ending_lines: Array[String] = []
var rival_id: String = ""
var cleared: bool = false
var state: State = State.INTRO

# Current dialogue line index within intro, before, after_win, or ending
var dialogue_index: int = 0


static func stage_path_for_name(stage_name: String) -> String:
	match stage_name.to_lower():
		"mensa":
			return "res://scenes/stages/mensa.tscn"
		"server_farm":
			return "res://scenes/stages/server_farm.tscn"
		"senate":
			return "res://scenes/stages/senate.tscn"
		"foundry":
			return "res://scenes/stages/foundry.tscn"
		_:
			return "res://scenes/stages/server_farm.tscn"


static func load_story_data(character_id: StringName) -> Dictionary:
	var path := "res://data/story/%s.json" % String(character_id)
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var text := file.get_as_text()
	var parsed = JSON.parse_string(text)
	return parsed if parsed is Dictionary else {}


static func create(player_character: CharacterData) -> StoryRun:
	var run := StoryRun.new()
	run.player = player_character
	run.story_data = load_story_data(player_character.id)
	run.rival_id = str(run.story_data.get("rival", ""))
	
	for line in run.story_data.get("intro", []):
		run.intro_lines.append(str(line))
	for line in run.story_data.get("ending", []):
		run.ending_lines.append(str(line))
	
	var raw_fights: Array = run.story_data.get("fights", [])
	for f in raw_fights:
		if f is Dictionary:
			run.fights.append(f)
	
	run.fight_index = 0
	run.dialogue_index = 0
	run.cleared = false
	run.state = State.INTRO
	return run


func current_fight() -> Dictionary:
	if fight_index >= 0 and fight_index < fights.size():
		return fights[fight_index]
	return {}


func current_stage_path() -> String:
	var f := current_fight()
	return stage_path_for_name(str(f.get("stage", "server_farm")))


func current_opponent_id() -> StringName:
	var f := current_fight()
	return StringName(str(f.get("opponent", "")))


func is_final_fight() -> bool:
	return fight_index == fights.size() - 1


func is_rival_fight() -> bool:
	var f := current_fight()
	return str(f.get("opponent", "")) == rival_id


func current_dialogue_lines() -> Array:
	match state:
		State.INTRO:
			return intro_lines
		State.PRE_FIGHT:
			var f := current_fight()
			return f.get("before", [])
		State.POST_WIN:
			var f := current_fight()
			return f.get("after_win", [])
		State.ENDING:
			return ending_lines
		_:
			return []


## Advances to the next dialogue line. Returns true if there are more lines in this state,
## or false if all lines for the current state are finished.
func advance_dialogue() -> bool:
	var lines := current_dialogue_lines()
	dialogue_index += 1
	return dialogue_index < lines.size()


## Called when the current fight is won and post-win dialogue concludes.
## Advances to the next fight, or marks cleared if on final fight.
func advance_fight() -> void:
	if is_final_fight():
		cleared = true
		state = State.ENDING
		dialogue_index = 0
		record_progress()
	else:
		fight_index += 1
		dialogue_index = 0
		state = State.PRE_FIGHT
		record_progress()


## Saves story progress in user://story_progress.cfg
func record_progress() -> void:
	if player == null:
		return
	var config := ConfigFile.new()
	config.load(save_path)
	var id := String(player.id)
	config.set_value("progress", id, fight_index)
	if cleared:
		config.set_value("cleared", id, true)
	config.save(save_path)


static func get_progress(character_id: String) -> int:
	var config := ConfigFile.new()
	if config.load(save_path) != OK:
		return 0
	return int(config.get_value("progress", character_id, 0))


static func is_story_cleared(character_id: String) -> bool:
	var config := ConfigFile.new()
	if config.load(save_path) != OK:
		return false
	return bool(config.get_value("cleared", character_id, false))


static func reset_progress(character_id: String) -> void:
	var config := ConfigFile.new()
	if config.load(save_path) == OK:
		if config.has_section_key("progress", character_id):
			config.erase_section_key("progress", character_id)
		if config.has_section_key("cleared", character_id):
			config.erase_section_key("cleared", character_id)
		config.save(save_path)
