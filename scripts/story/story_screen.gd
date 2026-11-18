extends Control
## Story screen: presents story intro, pre-fight dialogue, post-win dialogue,
## and ending sequence reading data/story/<fighter_id>.json.

const MAIN_MENU_SCENE := "res://scenes/main_menu.tscn"

const GOLD := Color(1.0, 0.85, 0.25)
const P1_COLOR := Color(0.55, 0.75, 1.0)
const P2_COLOR := Color(1.0, 0.55, 0.5)
const ACTIVE_MODULATE := Color.WHITE
const DIMMED_MODULATE := Color(0.38, 0.38, 0.44)

@onready var left_side: Control = %LeftSide
@onready var left_portrait: TextureRect = %LeftPortrait
@onready var left_name: Label = %LeftName

@onready var right_side: Control = %RightSide
@onready var right_portrait: TextureRect = %RightPortrait
@onready var right_name: Label = %RightName

@onready var header_title: Label = %HeaderTitle
@onready var header_subtitle: Label = %HeaderSubtitle

@onready var dialogue_panel: PanelContainer = %DialoguePanel
@onready var speaker_label: Label = %SpeakerLabel
@onready var text_label: Label = %TextLabel
@onready var prompt_label: Label = %PromptLabel
@onready var skip_label: Label = %SkipLabel

var _story: StoryRun
var _is_transitioning := false


func _ready() -> void:
	GameState.ensure_selections()
	if GameState.story == null:
		GameState.start_story(GameState.player_character)
	_story = GameState.story
	UiStyle.versus_look(self, get_node_or_null("LeftSide/LeftPortrait"), get_node_or_null("RightSide/RightPortrait"))
	UiStyle.use_display_font([get_node_or_null("Header/HeaderTitle"), get_node_or_null("LeftSide/LeftName"), get_node_or_null("RightSide/RightName")])
	
	if dialogue_panel:
		dialogue_panel.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				advance_line())
	
	_update_display()


func _update_display() -> void:
	if _story == null or _story.player == null:
		return
	
	# Default common properties
	left_portrait.texture = _story.player.portrait
	left_name.text = _story.player.display_name.to_upper()
	
	match _story.state:
		StoryRun.State.INTRO:
			_display_intro()
		StoryRun.State.PRE_FIGHT:
			_display_pre_fight()
		StoryRun.State.POST_WIN:
			_display_post_win()
		StoryRun.State.ENDING:
			_display_ending()


func _display_intro() -> void:
	right_side.visible = false
	left_side.visible = true
	left_side.modulate = ACTIVE_MODULATE
	left_side.scale = Vector2.ONE
	
	header_title.text = "PROLOGUE"
	header_subtitle.text = _story.player.display_name.to_upper()
	
	speaker_label.text = _story.player.display_name.to_upper()
	speaker_label.add_theme_color_override("font_color", P1_COLOR)
	
	var lines := _story.intro_lines
	if _story.dialogue_index < lines.size():
		text_label.text = lines[_story.dialogue_index]
	else:
		text_label.text = ""
	prompt_label.text = "▼ Press Enter / Space / A to continue"


func _display_pre_fight() -> void:
	var f := _story.current_fight()
	var opp_id := _story.current_opponent_id()
	var opp_char := GameState.find_character(opp_id)
	
	left_side.visible = true
	right_side.visible = true
	
	if opp_char:
		right_portrait.texture = opp_char.portrait
		right_name.text = opp_char.display_name.to_upper()
	
	header_title.text = "STORY MODE"
	var stage_name := GameState.stage_name(_story.current_stage_path()).to_upper()
	if _story.is_final_fight():
		header_subtitle.text = "FINAL BATTLE  ·  %s" % stage_name
	elif _story.is_rival_fight():
		header_subtitle.text = "RIVAL BATTLE  ·  %s" % stage_name
	else:
		header_subtitle.text = "STAGE %d / %d  ·  %s" % [_story.fight_index + 1, _story.fights.size(), stage_name]
	
	var raw_lines: Array = f.get("before", [])
	_show_dialogue_entry(raw_lines)
	prompt_label.text = "▼ Press Enter / Space / A to continue"


func _display_post_win() -> void:
	var f := _story.current_fight()
	var opp_id := _story.current_opponent_id()
	var opp_char := GameState.find_character(opp_id)
	
	left_side.visible = true
	right_side.visible = true
	
	if opp_char:
		right_portrait.texture = opp_char.portrait
		right_name.text = opp_char.display_name.to_upper()
	
	header_title.text = "VICTORY!"
	var stage_name := GameState.stage_name(_story.current_stage_path()).to_upper()
	header_subtitle.text = "STAGE %d / %d CLEARED  ·  %s" % [_story.fight_index + 1, _story.fights.size(), stage_name]
	
	var raw_lines: Array = f.get("after_win", [])
	_show_dialogue_entry(raw_lines)
	prompt_label.text = "▼ Press Enter / Space / A to continue"


func _display_ending() -> void:
	right_side.visible = false
	left_side.visible = true
	left_side.modulate = ACTIVE_MODULATE
	left_side.scale = Vector2.ONE
	
	header_title.text = "EPILOGUE"
	header_subtitle.text = "STORY COMPLETE  ·  %s" % _story.player.display_name.to_upper()
	
	speaker_label.text = "EPILOGUE"
	speaker_label.add_theme_color_override("font_color", GOLD)
	
	var lines := _story.ending_lines
	if _story.dialogue_index < lines.size():
		text_label.text = lines[_story.dialogue_index]
	else:
		text_label.text = "Story completed successfully!"
	prompt_label.text = "▼ Press Enter / Space / A to continue"


func _show_dialogue_entry(raw_lines: Array) -> void:
	if _story.dialogue_index < raw_lines.size():
		var entry = raw_lines[_story.dialogue_index]
		if entry is Dictionary:
			var who: String = entry.get("who", "")
			var line: String = entry.get("line", "")
			var speaker_char := GameState.find_character(StringName(who))
			var is_p1 := (who == String(_story.player.id))
			
			if speaker_char:
				speaker_label.text = speaker_char.display_name.to_upper()
			else:
				speaker_label.text = who.to_upper()
			
			if is_p1:
				speaker_label.add_theme_color_override("font_color", P1_COLOR)
				left_side.modulate = ACTIVE_MODULATE
				right_side.modulate = DIMMED_MODULATE
			else:
				speaker_label.add_theme_color_override("font_color", P2_COLOR)
				right_side.modulate = ACTIVE_MODULATE
				left_side.modulate = DIMMED_MODULATE
			
			text_label.text = line
	else:
		text_label.text = ""


func advance_line() -> void:
	if _is_transitioning:
		return
	
	var has_more := _story.advance_dialogue()
	if has_more:
		_update_display()
		return
	
	# Current section lines finished, transition to next state
	match _story.state:
		StoryRun.State.INTRO:
			_story.state = StoryRun.State.PRE_FIGHT
			_story.dialogue_index = 0
			GameState.apply_story_fight()
			_update_display()
		
		StoryRun.State.PRE_FIGHT:
			_start_fight()
		
		StoryRun.State.POST_WIN:
			_story.advance_fight()
			if _story.cleared:
				_update_display()
			else:
				GameState.apply_story_fight()
				_update_display()
		
		StoryRun.State.ENDING:
			_finish_story()


func skip() -> void:
	if _is_transitioning:
		return
	
	match _story.state:
		StoryRun.State.INTRO:
			_story.state = StoryRun.State.PRE_FIGHT
			_story.dialogue_index = 0
			GameState.apply_story_fight()
			_update_display()
		
		StoryRun.State.PRE_FIGHT:
			_start_fight()
		
		StoryRun.State.POST_WIN:
			_story.advance_fight()
			if _story.cleared:
				_update_display()
			else:
				GameState.apply_story_fight()
				_update_display()
		
		StoryRun.State.ENDING:
			_finish_story()


func _start_fight() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	GameState.apply_story_fight()
	GameState.go_to_fight(get_tree())


func _finish_story() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		advance_line()
	elif event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		skip()
