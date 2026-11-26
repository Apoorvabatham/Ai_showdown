extends Control
## Credits (main menu): a scrollable list with the title, the 3D Fighter credit, the parody
## disclaimer and the third-party asset credits read from assets/CREDITS.md at runtime.
## Esc / B (or Enter / A) returns to the main menu.

const MAIN_MENU_SCENE := "res://scenes/main_menu.tscn"
const CREDITS_FILE := "res://assets/CREDITS.md"

const TITLE := "AI Showdown"
const BASED_ON := "Based on 3D Fighter by Clint Christopher Canada (MIT / CC BY 4.0)"
const DISCLAIMER := "Parody. Not affiliated with or endorsed by any real person or company."
const LICENSE_NOTE := "Code: MIT  ·  Original assets: CC BY 4.0  ·  Third-party assets: CC0, except Aelia (CC-BY)"
const SCROLL_STEP := 80.0

var _scroll: ScrollContainer


func _ready() -> void:
	Audio.music(&"menu")
	var background := ColorRect.new()
	background.color = Color(0.03, 0.03, 0.05)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	UiStyle.add_backdrop(self, background)
	_build()


func _build() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 140)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 48)
	add_child(margin)
	_scroll = ScrollContainer.new()
	_scroll.name = "Scroll"
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(_scroll)
	var list := VBoxContainer.new()
	list.name = "Credits"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 12)
	_scroll.add_child(list)

	var title := _label(TITLE, 72, Color.WHITE)
	title.name = "Title"
	UiStyle.use_display_font([title])
	list.add_child(title)
	list.add_child(_label(BASED_ON, 26, UiStyle.ACCENT))
	list.add_child(_label(DISCLAIMER, 22, Color(0.78, 0.8, 0.86)))
	list.add_child(_gap(18))
	var heading := _label("ASSET CREDITS", 34, Color.WHITE)
	UiStyle.use_display_font([heading])
	list.add_child(heading)
	list.add_child(_label("What  —  Source  —  Licence", 20, Color(0.6, 0.64, 0.72)))
	for line in asset_credit_lines():
		list.add_child(_label(line, 20, Color(0.82, 0.84, 0.9)))
	list.add_child(_gap(18))
	list.add_child(_label(LICENSE_NOTE, 20, Color(0.6, 0.64, 0.72)))

	var hint := _label("↑ ↓  scroll     Esc / B  back", 20, Color(0.6, 0.6, 0.66))
	hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	hint.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hint.offset_right = -40
	hint.offset_bottom = -30
	add_child(hint)


## Reads assets/CREDITS.md and turns each Markdown table row into one plain line:
## "what — source — licence". `text` is for tests; by default the file is read at runtime.
static func asset_credit_lines(text := "") -> PackedStringArray:
	if text == "":
		text = FileAccess.get_file_as_string(CREDITS_FILE)
	var lines := PackedStringArray()
	for raw in text.split("\n"):
		var row := raw.strip_edges()
		if not row.begins_with("|"):
			continue
		var cells := row.split("|")
		cells.remove_at(0) # the empty cell before the first pipe
		if cells.size() > 0 and cells[cells.size() - 1].strip_edges() == "":
			cells.remove_at(cells.size() - 1)
		if cells.size() < 5:
			continue
		var what := cells[0].strip_edges()
		var author := cells[2].strip_edges()
		var url := cells[3].strip_edges()
		var licence := cells[4].strip_edges()
		if what == "" or what == "Asset" or what.replace("-", "").replace(":", "").strip_edges() == "":
			continue # empty, the header or the separator row
		var source := author
		if url != "" and url != "—" and url != "-":
			source = (author + " " + url).strip_edges() if author != "" else url
		if source == "":
			source = "—"
		lines.append("%s — %s — %s" % [what, source, licence])
	return lines


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		Audio.sfx(&"ui_back", -4.0)
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)
	elif event.is_action_pressed("ui_down"):
		_scroll.scroll_vertical += int(SCROLL_STEP)
	elif event.is_action_pressed("ui_up"):
		_scroll.scroll_vertical -= int(SCROLL_STEP)
	elif event.is_action_pressed("ui_page_down"):
		_scroll.scroll_vertical += int(_scroll.size.y * 0.8)
	elif event.is_action_pressed("ui_page_up"):
		_scroll.scroll_vertical -= int(_scroll.size.y * 0.8)


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _gap(height: int) -> Control:
	var gap := Control.new()
	gap.custom_minimum_size.y = height
	return gap
