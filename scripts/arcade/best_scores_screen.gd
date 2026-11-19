extends Control
## Arcade best scores (main menu): one row per fighter with portrait, best score, stages
## cleared, clear time, continues and perfects. The overall top score gets a gold
## frame. Back or confirm returns to the main menu.

const MAIN_MENU_SCENE := "res://scenes/main_menu.tscn"
const WALLPAPER := "res://assets/ui/wallpaper.png"
const GOLD := Color(1.0, 0.82, 0.3)
const PORTRAIT := 56.0
const NAME_WIDTH := 340.0
const ROW_WIDTH := 1420.0
const COLUMNS := ["SCORE", "STAGES", "TIME", "CONTINUES", "PERFECTS"]

var _rows: Array[Control] = []


func _ready() -> void:
	Audio.music(&"menu")
	var background := ColorRect.new()
	background.color = Color(0.03, 0.03, 0.05)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var art := TextureRect.new()
	art.texture = load(WALLPAPER)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.modulate = Color(0.22, 0.22, 0.28)
	add_child(art)
	art.hide() # the shared backdrop replaces the old key art
	UiStyle.add_backdrop(self, background)

	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 8)
	add_child(column)
	var heading := _label("ARCADE BEST SCORES", 56, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	UiStyle.use_display_font([heading])
	column.add_child(heading)

	var header := _row_box(false)
	(header.get_theme_stylebox("panel") as StyleBoxFlat).bg_color.a = 0.0
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(PORTRAIT, 0) # portrait column
	header.get_child(0).add_child(spacer)
	header.get_child(0).add_child(_cell("FIGHTER", 20, Color(0.6, 0.62, 0.7), NAME_WIDTH, HORIZONTAL_ALIGNMENT_LEFT))
	for title: String in COLUMNS:
		header.get_child(0).add_child(_cell(title, 20, Color(0.6, 0.62, 0.7), 190))
	column.add_child(header)

	var top_score := 0
	for character in GameState.roster:
		top_score = maxi(top_score, ArcadeRun.best_score(character))
	for character in GameState.roster:
		var run := ArcadeRun.best_run(character)
		var score := int(run.get("score", 0))
		var row := _row_box(score > 0 and score == top_score)
		var line: HBoxContainer = row.get_child(0)
		var portrait := TextureRect.new()
		portrait.texture = character.portrait
		portrait.custom_minimum_size = Vector2(PORTRAIT, PORTRAIT)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		line.add_child(portrait)
		line.add_child(_cell(character.display_name.to_upper(), 26, Color.WHITE, NAME_WIDTH, HORIZONTAL_ALIGNMENT_LEFT))
		if score == 0:
			line.add_child(_cell("no clear yet", 22, Color(0.5, 0.52, 0.58), 190 * COLUMNS.size()))
		else:
			var stages := "%d / %d" % [run.stages, GameState.roster.size()] if run.has("stages") else "—"
			if run.get("cleared", false):
				stages = "ALL ✓"
			line.add_child(_cell("%07d" % score, 28, UiStyle.ACCENT if score == top_score else Color.WHITE, 190))
			line.add_child(_cell(stages, 30, Color.WHITE, 190))
			line.add_child(_cell(ArcadeRun.time_text(run.ticks) if run.has("ticks") else "—", 30, Color.WHITE, 190))
			line.add_child(_cell(str(run.continues) if run.has("continues") else "—", 30, Color.WHITE, 190))
			line.add_child(_cell(str(run.perfects) if run.has("perfects") else "—", 30, Color.WHITE, 190))
		column.add_child(row)
		_rows.append(row)
	column.add_child(_label("Enter / A or Esc to return", 22, Color(0.55, 0.55, 0.6), HORIZONTAL_ALIGNMENT_CENTER))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		Audio.sfx(&"ui_back", -4.0)
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)


## A centered panel holding one HBox row; `highlight` gives it a gold frame.
func _row_box(highlight: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.custom_minimum_size.x = ROW_WIDTH # every row the same width: the columns line up
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.04, 0.055, 0.82)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(6)
	style.content_margin_left = 14
	style.set_border_width_all(2 if highlight else 0)
	style.border_color = UiStyle.ACCENT
	panel.add_theme_stylebox_override("panel", style)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 12)
	line.alignment = BoxContainer.ALIGNMENT_BEGIN
	panel.add_child(line)
	return panel


func _cell(text: String, size: int, color: Color, width: float, align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var label := _label(text, size, color, align)
	label.custom_minimum_size.x = width
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


func _label(text: String, size: int, color: Color, align: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.horizontal_alignment = align
	return label
