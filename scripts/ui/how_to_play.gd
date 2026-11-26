extends CanvasLayer
## The friendly "how to play" card: shown once before the very first fight, and again
## from the pause menu whenever the player asks for it. It reads P1's real bindings from
## InputSetup, so remapped keys and gamepad buttons are shown correctly.
## Skippable with any button or key; runs while the tree is paused.

signal closed

const HINT := "Press any button to start"
const ROW_NAMES := ["Move", "Punch / Kick", "Power", "Super", "Block", "Sidestep"]

var _closed := false
var _armed := false
var _values := {} # row name -> its value Label


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	# Ignore the input that opened the card (e.g. the pause-menu button) for one frame.
	await get_tree().process_frame
	_armed = true


func _build() -> void:
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.012, 0.02, 0.78)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiStyle.glass_panel(46.0))
	panel.custom_minimum_size = Vector2(900, 0)
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	panel.add_child(box)

	var title := Label.new()
	title.text = "HOW TO PLAY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 58)
	title.add_theme_color_override("font_color", Color.WHITE)
	UiStyle.use_display_font([title])
	box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "A quick look at the controls before your first fight."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 24)
	subtitle.add_theme_color_override("font_color", Color(0.78, 0.82, 0.9))
	box.add_child(subtitle)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 48)
	grid.add_theme_constant_override("v_separation", 14)
	box.add_child(grid)

	var rows := _rows()
	for row_name: String in ROW_NAMES:
		var name_label := Label.new()
		name_label.text = row_name
		name_label.add_theme_font_size_override("font_size", 28)
		name_label.add_theme_color_override("font_color", UiStyle.ACCENT)
		grid.add_child(name_label)
		var value_label := Label.new()
		value_label.text = rows.get(row_name, "")
		value_label.add_theme_font_size_override("font_size", 28)
		value_label.add_theme_color_override("font_color", Color(0.95, 0.96, 1.0))
		value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		value_label.custom_minimum_size = Vector2(540, 0)
		grid.add_child(value_label)
		_values[row_name] = value_label

	var hint := Label.new()
	hint.name = "Hint"
	hint.text = HINT
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 22)
	hint.add_theme_color_override("font_color", Color(0.72, 0.76, 0.82))
	box.add_child(hint)


## The card's text from P1's current bindings: "Move WASD / Left stick", etc.
func _rows() -> Dictionary:
	# Looked up at run time: this script also compiles where autoload names aren't known.
	var InputSetup: Node = (Engine.get_main_loop() as SceneTree).root.get_node("InputSetup")
	var b: Dictionary = InputSetup.bindings.p1
	var move := "%s%s%s%s" % [
		InputSetup.key_name(b.up.key), InputSetup.key_name(b.left.key),
		InputSetup.key_name(b.down.key), InputSetup.key_name(b.right.key)]
	var punches := "%s %s %s %s" % [
		InputSetup.key_name(b.lp.key), InputSetup.key_name(b.hp.key),
		InputSetup.key_name(b.lk.key), InputSetup.key_name(b.hk.key)]
	var pad_punches := "%s %s %s %s" % [
		InputSetup.pad_name(b.lp.pad), InputSetup.pad_name(b.hp.pad),
		InputSetup.pad_name(b.lk.pad), InputSetup.pad_name(b.hk.pad)]
	return {
		"Move": "%s   /   Left stick" % move,
		"Punch / Kick": "%s   /   %s" % [punches, pad_punches],
		"Power": "%s   /   %s    (add forward, back or down for other specials)" % [
			InputSetup.key_name(b.power.key), InputSetup.pad_name(b.power.pad)],
		"Super": "%s   /   %s    (when the SUPER meter is full)" % [
			InputSetup.key_name(b.super.key), InputSetup.pad_name(b.super.pad)],
		"Block": "Hold back",
		"Sidestep": "%s   /   %s" % [InputSetup.key_name(b.sidestep.key), InputSetup.pad_name(b.sidestep.pad)],
	}


func _input(event: InputEvent) -> void:
	if _closed or not _armed:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		close()
	elif event is InputEventJoypadButton and event.pressed:
		close()
	elif event is InputEventMouseButton and event.pressed:
		close()
	elif event is InputEventScreenTouch and event.pressed:
		close()


## Dismisses the card. Safe to call more than once (a button and a test may both).
func close() -> void:
	if _closed:
		return
	_closed = true
	get_viewport().set_input_as_handled()
	closed.emit()
	queue_free()


## All rows as one string, for tests and accessibility.
func body_text() -> String:
	var parts: Array[String] = []
	for row_name: String in ROW_NAMES:
		parts.append("%s %s" % [row_name, (_values[row_name] as Label).text])
	return "\n".join(parts)
