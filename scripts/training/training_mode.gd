class_name TrainingMode
extends Node
## Training mode tools, added by FightManager when GameState.mode == TRAINING:
## endless session with health refill, dummy settings (stance, guard, CPU, record &
## playback), measured frame data for P1's attacks, input history with a live input
## display (stick + buttons), hitbox display, and a training menu. Keys:
## Tab / pad Back = menu, Backspace / L3 = reset, F6 = record, F7 = playback.

const REFILL_DELAY_TICKS := 40
const HISTORY_SIZE := 16
const HISTORY_DISPLAY_LINES := 10
const ARROWS := ["↙", "↓", "↘", "←", "•", "→", "↖", "↑", "↗"]
## [InputBuffer bit, InputSetup action, plain short name] in 2-row keyboard order.
const BUTTONS := [
	[InputBuffer.LP, "lp", "L Punch"],
	[InputBuffer.HP, "hp", "H Punch"],
	[InputBuffer.POWER, "power", "Power"],
	[InputBuffer.SUPER, "super", "Super"],
	[InputBuffer.LK, "lk", "L Kick"],
	[InputBuffer.HK, "hk", "H Kick"],
	[InputBuffer.SIDESTEP, "sidestep", "Sidestep"],
]
const ACTIONS := {
	"training_menu": [KEY_TAB, JOY_BUTTON_BACK],
	"training_reset": [KEY_BACKSPACE, JOY_BUTTON_LEFT_STICK],
	"training_record": [KEY_F6, -1],
	"training_playback": [KEY_F7, -1],
}

var manager: Node
var player: Fighter
var dummy: Fighter
var dummy_controller: TrainingDummyController

var refill_health := true
var infinite_meter := true
var show_frame_data := false
var show_input_history := true
var show_hitboxes := false

## Last measured attack: {name, startup, active, recovery, damage, result, advantage}
var last_frame_data := {}
## Input history, newest first: [packed input, ticks held].
var history: Array = []
var recording := false

var _player_controller: FighterController
var _record_buffer := PackedInt32Array()
var _pending := {} # attack being measured
var _refill_ticks := {}
var _in_combo := false
var _combo_start_health := 0
var _dummy_prev_health := 0
var _last_combo := ""

var _layer: CanvasLayer
var _status: Label
var _frame_label: Label
var _history_label: Label
var _input_display: InputDisplay
var _menu: PanelContainer
var _menu_first: Control
var _reset_button: Button
var _using_pad := false

var _guard_option: OptionButton


func setup(fight_manager: Node) -> void:
	manager = fight_manager
	process_mode = Node.PROCESS_MODE_ALWAYS
	player = manager.fighters[0]
	dummy = manager.fighters[1]
	dummy_controller = dummy.controller as TrainingDummyController
	dummy_controller.ai = manager.ai
	_player_controller = player.controller
	_dummy_prev_health = dummy.health
	_using_pad = _has_pad()
	if not Input.joy_connection_changed.is_connected(_on_joy_connection_changed):
		Input.joy_connection_changed.connect(_on_joy_connection_changed)
	_add_actions()
	_build_ui()
	manager.ticked.connect(_on_tick)
	manager.hit_landed.connect(_on_hit_landed)
	_refresh()


func _exit_tree() -> void:
	if Input.joy_connection_changed.is_connected(_on_joy_connection_changed):
		Input.joy_connection_changed.disconnect(_on_joy_connection_changed)


# --- Simulation hooks ------------------------------------------------------------

func _on_tick() -> void:
	_track_history()
	_track_frame_data()
	_track_combo()
	if refill_health:
		_refill(player)
		_refill(dummy)
	if infinite_meter:
		for fighter: Fighter in manager.fighters:
			fighter.add_meter(Fighter.MAX_METER)
	if recording:
		if _record_buffer.size() >= TrainingDummyController.MAX_RECORDING_TICKS:
			stop_recording()
		else:
			_update_status()


func _on_hit_landed(attacker: Fighter, defender: Fighter, move: MoveData, result: Fighter.HitResult) -> void:
	if attacker != player:
		return
	_pending = {
		name = move.name, startup = move.startup + 1, active = move.active, recovery = move.recovery,
		damage = move.damage, result = result, ticks = 0, attacker_free = -1, defender_free = -1,
		defender = defender,
	}


## Frame advantage = ticks until the defender can act minus ticks until the attacker can.
## Measured from the simulation after each tick, so cancels, pushback and hitstop all count.
func _track_frame_data() -> void:
	if _pending.is_empty():
		return
	_pending.ticks += 1
	var defender: Fighter = _pending.defender
	if defender.state == Fighter.State.KNOCKDOWN or defender.state == Fighter.State.KO:
		_finish_frame_data("KD")
		return
	if _pending.attacker_free < 0 and player.is_actionable():
		_pending.attacker_free = _pending.ticks
	if _pending.defender_free < 0 and defender.is_actionable():
		_pending.defender_free = _pending.ticks
	if _pending.attacker_free >= 0 and _pending.defender_free >= 0:
		var advantage: int = _pending.defender_free - _pending.attacker_free
		_finish_frame_data("%+d" % advantage)
	elif _pending.ticks > 240:
		_pending = {}


func _finish_frame_data(advantage: String) -> void:
	last_frame_data = _pending.duplicate()
	last_frame_data.erase("defender")
	last_frame_data.advantage = advantage
	_pending = {}
	_update_frame_label()


## Totals each combo on the dummy (hits + damage) once it ends.
func _track_combo() -> void:
	if dummy.combo_hits > 0 and not _in_combo:
		_in_combo = true
		_combo_start_health = _dummy_prev_health
	elif dummy.combo_hits > 1:
		_last_combo = "%d hits, %d dmg" % [dummy.combo_hits, _combo_start_health - dummy.health]
	elif _in_combo:
		_in_combo = false
		_update_frame_label()
	_dummy_prev_health = dummy.health


func _track_history() -> void:
	var packed := player.input.current()
	if not history.is_empty() and history[0][0] == packed:
		history[0][1] = mini(history[0][1] + 1, 99)
	else:
		history.push_front([packed, 1])
		if history.size() > HISTORY_SIZE:
			history.pop_back()
	if show_input_history:
		_history_label.text = format_history()
		_input_display.packed = player.input.current()
		_input_display.queue_redraw()


func _refill(fighter: Fighter) -> void:
	var key := fighter.get_instance_id()
	if fighter.health < fighter.data.max_health and fighter.combo_hits == 0 and fighter.is_actionable():
		_refill_ticks[key] = int(_refill_ticks.get(key, 0)) + 1
		if _refill_ticks[key] >= REFILL_DELAY_TICKS:
			fighter.health = fighter.data.max_health
			fighter.health_changed.emit(fighter.health, fighter.data.max_health)
			_refill_ticks[key] = 0
	else:
		_refill_ticks[key] = 0


# --- Record / playback / reset -----------------------------------------------------

## P1 takes control of the dummy and records its inputs (P1's own fighter stands still).
func start_recording() -> void:
	recording = true
	_record_buffer.clear()
	var recorder := RecordingController.new(_player_controller, _record_buffer)
	dummy.controller = recorder
	player.controller = FighterController.new()
	_update_status()


func stop_recording() -> void:
	if not recording:
		return
	recording = false
	var recorder := dummy.controller as RecordingController
	if recorder:
		_record_buffer = recorder.buffer
	dummy.controller = dummy_controller
	player.controller = _player_controller
	if not _record_buffer.is_empty():
		dummy_controller.recording = _record_buffer.duplicate()
		dummy_controller.stance = TrainingDummyController.Stance.PLAYBACK
		dummy_controller.restart_playback()
	_refresh()


func toggle_playback() -> void:
	if dummy_controller.recording.is_empty():
		return
	var playing := dummy_controller.stance == TrainingDummyController.Stance.PLAYBACK
	dummy_controller.stance = TrainingDummyController.Stance.STAND if playing else TrainingDummyController.Stance.PLAYBACK
	dummy_controller.restart_playback()
	_refresh()


func reset_positions() -> void:
	stop_recording()
	manager.start_match()
	_pending = {}
	dummy_controller.restart_playback()
	_refresh()


# --- Input & UI ------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	_track_input_device(event)
	if event.is_action_pressed("training_menu") and (_menu.visible or not get_tree().paused):
		_toggle_menu()
	elif _menu.visible:
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
			_toggle_menu()
			get_viewport().set_input_as_handled()
		return
	elif get_tree().paused:
		return
	elif event.is_action_pressed("training_reset"):
		reset_positions()
	elif event.is_action_pressed("training_record"):
		if recording:
			stop_recording()
		else:
			start_recording()
	elif event.is_action_pressed("training_playback"):
		toggle_playback()
	else:
		return
	get_viewport().set_input_as_handled()


func _track_input_device(event: InputEvent) -> void:
	var pad := _p1_pad_device()
	if event is InputEventJoypadButton and event.pressed and event.device == pad:
		_set_using_pad(true)
	elif event is InputEventJoypadMotion and absf(event.axis_value) > 0.35 and event.device == pad:
		_set_using_pad(true)
	elif event is InputEventKey and event.pressed and not event.echo and _is_p1_key(event.physical_keycode):
		_set_using_pad(false)


func _on_joy_connection_changed(_device: int, _connected: bool) -> void:
	if not _has_pad():
		_using_pad = false
	_sync_input_labels()
	_update_status()


func _set_using_pad(on: bool) -> void:
	if _using_pad == on:
		return
	_using_pad = on
	_sync_input_labels()
	_update_status()


func _toggle_menu() -> void:
	_menu.visible = not _menu.visible
	get_tree().paused = _menu.visible
	if _menu.visible:
		_menu_first.grab_focus()


func _add_actions() -> void:
	for action: String in ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		InputMap.action_erase_events(action)
		var key := InputEventKey.new()
		key.physical_keycode = ACTIONS[action][0]
		InputMap.action_add_event(action, key)
		if ACTIONS[action][1] >= 0:
			var pad := InputEventJoypadButton.new()
			pad.device = -1
			pad.button_index = ACTIONS[action][1]
			InputMap.action_add_event(action, pad)


func _refresh() -> void:
	for fighter: Fighter in manager.fighters:
		fighter.debug_draw = show_hitboxes
	_frame_label.get_parent().visible = show_frame_data
	_history_label.get_parent().visible = show_input_history
	_sync_input_labels()
	_update_status()
	_update_frame_label()


func _update_status() -> void:
	var pad_hints := _using_pad or _has_pad()
	if _reset_button:
		_reset_button.text = "Reset Positions (Backspace / L3)" if pad_hints else "Reset Positions (Backspace)"
	if recording:
		_status.text = "●  RECORDING DUMMY  %.1fs  ·  F6 to stop" % (_record_buffer.size() / 60.0)
		_status.modulate = Color(1, 0.35, 0.3)
		return
	_status.modulate = Color.WHITE
	var menu_hint := "Tab / Back: Menu" if pad_hints else "Tab: Menu"
	var reset_hint := "Backspace / L3: Reset" if pad_hints else "Backspace: Reset"
	_status.text = "TRAINING  ·  Dummy: %s  ·  Guard: %s\n%s  ·  %s  ·  F6: Record  ·  F7: Playback" % [
		dummy_controller.stance_name(), dummy_controller.guard_name(), menu_hint, reset_hint]


func _update_frame_label() -> void:
	if last_frame_data.is_empty():
		_frame_label.text = "FRAME DATA\nLand an attack on the dummy"
	else:
		var d := last_frame_data
		var result_name: String = Fighter.HitResult.keys()[d.result].capitalize()
		_frame_label.text = "FRAME DATA  -  %s\nStartup %d  ·  Active %d  ·  Recovery %d\nDamage %d  ·  On %s: %s" % [
			d.name.to_upper(), d.startup, d.active, d.recovery, d.damage, result_name.to_lower(), d.advantage]
	if _last_combo != "":
		_frame_label.text += "\nLast combo: " + _last_combo


func format_history() -> String:
	var lines := PackedStringArray(["RECENT INPUTS"])
	var binds := _button_bindings(_using_pad)
	for entry in history:
		var packed: int = entry[0]
		var dir := packed & 0xF
		var btn_mask := packed >> InputBuffer.BUTTON_SHIFT
		if dir == InputBuffer.NEUTRAL and btn_mask == 0:
			continue
		var buttons := PackedStringArray()
		for b in BUTTONS:
			if (btn_mask & int(b[0])) != 0:
				var key_text := str(binds.get(b[1], ""))
				buttons.append("%s (%s)" % [key_text, b[2]] if key_text != "" and key_text != b[2] else str(b[2]))
		var arrow: String = ARROWS[clampi(dir, 1, 9) - 1]
		lines.append(("%s  %s" % [arrow, " + ".join(buttons)]).strip_edges())
		if lines.size() > HISTORY_DISPLAY_LINES:
			break
	if lines.size() == 1:
		lines.append("—")
	return "\n".join(lines)


func _input_setup() -> Node:
	var tree := get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	return tree.root.get_node_or_null("InputSetup") if tree else null


func _p1_pad_device() -> int:
	var setup := _input_setup()
	return setup.pad_device("p1") if setup else 0


func _has_pad() -> bool:
	return _p1_pad_device() in Input.get_connected_joypads()


func _is_p1_key(keycode: int) -> bool:
	var setup := _input_setup()
	if not setup:
		return false
	for action: String in setup.bindings.p1:
		if setup.bindings.p1[action].key == keycode:
			return true
	return false


func _button_bindings(use_pad: bool) -> Dictionary:
	if not use_pad:
		var keys := FightHud._p1_key_names()
		if not keys.is_empty():
			return keys
	var setup := _input_setup()
	var out := {}
	if setup:
		for action: String in setup.bindings.p1:
			var binding: Dictionary = setup.bindings.p1[action]
			if use_pad and binding.has("pad"):
				out[action] = setup.pad_name(binding.pad)
			else:
				out[action] = setup.key_name(binding.key)
	return out


func _sync_input_labels() -> void:
	if _input_display:
		var binds := _button_bindings(_using_pad)
		var lamps := []
		for b in BUTTONS:
			var key_text := str(binds.get(b[1], ""))
			lamps.append([b[0], key_text if key_text != "" else b[2], b[2]])
		_input_display.lamps = lamps
		_input_display.queue_redraw()
	if _history_label:
		_history_label.text = format_history()


func _build_ui() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 2
	_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_layer)
	var mono := SystemFont.new()
	mono.font_names = PackedStringArray(["Consolas", "DejaVu Sans Mono", "Menlo", "monospace"])

	var status_panel := _panel(Vector2(0, -24), Control.PRESET_CENTER_BOTTOM)
	status_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	status_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	status_panel.offset_left = 0
	status_panel.offset_right = 0
	status_panel.offset_top = -24
	status_panel.offset_bottom = -24
	(status_panel.get_theme_stylebox("panel") as StyleBoxFlat).set_content_margin_all(10)
	_status = _label(20, null)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_panel.add_child(_status)

	var frame_panel := _panel(Vector2(40, -120), Control.PRESET_BOTTOM_LEFT) # above the super meter
	_frame_label = _label(22, mono)
	frame_panel.add_child(_frame_label)

	var history_panel := _panel(Vector2(40, 210), Control.PRESET_TOP_LEFT)
	var history_box := VBoxContainer.new()
	history_box.add_theme_constant_override("separation", 10)
	history_panel.add_child(history_box)
	_input_display = InputDisplay.new()
	history_box.add_child(_input_display)
	_history_label = _label(22, mono)
	history_box.add_child(_history_label)

	_build_menu()


func _panel(offset: Vector2, preset: int) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.55)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(14)
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(panel)
	panel.set_anchors_preset(preset)
	panel.offset_left = offset.x
	panel.offset_top = offset.y
	if preset == Control.PRESET_BOTTOM_LEFT:
		panel.grow_vertical = Control.GROW_DIRECTION_BEGIN # grows upward from the bottom offset
		panel.offset_bottom = offset.y
	return panel


func _label(size: int, font: Font) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	if font:
		label.add_theme_font_override("font", font)
	return label


func _build_menu() -> void:
	_menu = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.04, 0.06, 0.95)
	style.border_color = Color(0.95, 0.75, 0.2)
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(30)
	_menu.add_theme_stylebox_override("panel", style)
	_menu.visible = false
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(center)
	center.add_child(_menu)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	box.custom_minimum_size = Vector2(620, 0)
	_menu.add_child(box)
	var title := _label(44, null)
	title.text = "TRAINING"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 10)
	box.add_child(grid)
	_menu_first = _option(grid, "Dummy", TrainingDummyController.STANCE_NAMES, dummy_controller.stance,
		func(i: int) -> void:
			dummy_controller.stance = i as TrainingDummyController.Stance
			dummy_controller.restart_playback()
			_refresh())
	_guard_option = _option(grid, "Guard", TrainingDummyController.GUARD_NAMES, dummy_controller.guard,
		func(i: int) -> void:
			dummy_controller.guard = i as TrainingDummyController.Guard
			_refresh())
	_toggle(grid, "Health Refill", refill_health, func(on: bool) -> void: refill_health = on)
	_toggle(grid, "Infinite Meter", infinite_meter, func(on: bool) -> void: infinite_meter = on)
	_toggle(grid, "Frame data (advanced)", show_frame_data, func(on: bool) -> void:
		show_frame_data = on
		_refresh())
	_toggle(grid, "Input History", show_input_history, func(on: bool) -> void:
		show_input_history = on
		_refresh())
	_toggle(grid, "Hitboxes", show_hitboxes, func(on: bool) -> void:
		show_hitboxes = on
		_refresh())
	for item in [["Record Dummy (F6)", func() -> void:
			_toggle_menu()
			start_recording()],
		["Reset Positions (Backspace)", func() -> void:
			_toggle_menu()
			reset_positions()],
		["Close", _toggle_menu]]:
		var button := Button.new()
		button.text = item[0]
		button.custom_minimum_size = Vector2(0, 50)
		button.add_theme_font_size_override("font_size", 24)
		button.pressed.connect(item[1])
		box.add_child(button)
		if item[0].begins_with("Reset Positions"):
			_reset_button = button


func _option(grid: GridContainer, label_text: String, items: Array, selected: int, on_change: Callable) -> OptionButton:
	var label := _label(26, null)
	label.text = label_text
	grid.add_child(label)
	var option := OptionButton.new()
	option.add_theme_font_size_override("font_size", 22)
	option.custom_minimum_size = Vector2(320, 44)
	for item: String in items:
		option.add_item(item)
	option.selected = selected
	option.item_selected.connect(on_change)
	grid.add_child(option)
	return option


func _toggle(grid: GridContainer, label_text: String, value: bool, on_change: Callable) -> void:
	var label := _label(26, null)
	label.text = label_text
	grid.add_child(label)
	var check := CheckButton.new()
	check.button_pressed = value
	check.toggled.connect(on_change)
	grid.add_child(check)


## Live input: a stick gate with a dot at the held direction (facing-relative: right =
## toward the opponent) and lamps for all 7 buttons using the player's actual keys.
class InputDisplay extends Control:
	const GATE := 34.0
	const COL_W := 72.0
	const ROW_H := 50.0
	const PILL_H := 28.0
	## Each entry: [InputBuffer bit, key/pad label, plain action label].
	var lamps := [
		[InputBuffer.LP, "L Punch", "L Punch"],
		[InputBuffer.HP, "H Punch", "H Punch"],
		[InputBuffer.POWER, "Power", "Power"],
		[InputBuffer.SUPER, "Super", "Super"],
		[InputBuffer.LK, "L Kick", "L Kick"],
		[InputBuffer.HK, "H Kick", "H Kick"],
		[InputBuffer.SIDESTEP, "Sidestep", "Sidestep"],
	]
	var packed := InputBuffer.pack(InputBuffer.NEUTRAL, 0)

	func _init() -> void:
		custom_minimum_size = Vector2(GATE * 2.0 + 18.0 + COL_W * 4.0 + 4.0, ROW_H * 2.0 + 4.0)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var center := Vector2(GATE + 4.0, ROW_H)
		draw_circle(center, GATE, Color(1, 1, 1, 0.12))
		draw_arc(center, GATE, 0.0, TAU, 32, Color(1, 1, 1, 0.5), 2.0)
		var dir := packed & 0xF
		var offset := Vector2.ZERO
		if dir != InputBuffer.NEUTRAL:
			offset = Vector2(((dir - 1) % 3) - 1, 1 - ((dir - 1) / 3)).normalized() * (GATE - 10.0)
		draw_circle(center + offset, 10.0, Color(1.0, 0.82, 0.3))
		var font := ThemeDB.fallback_font
		var x_start := GATE * 2.0 + 18.0
		var pill := StyleBoxFlat.new()
		pill.set_corner_radius_all(12)
		pill.anti_aliasing = true
		for i in lamps.size():
			var lamp: Array = lamps[i]
			var on: bool = ((packed >> InputBuffer.BUTTON_SHIFT) & int(lamp[0])) != 0
			var col := i % 4
			var row := i / 4
			var col_x := x_start + col * COL_W + COL_W * 0.5
			var row_y := 4.0 + row * ROW_H
			var key_text := str(lamp[1])
			var key_size := 14
			var text_w := font.get_string_size(key_text, HORIZONTAL_ALIGNMENT_LEFT, -1, key_size).x
			if text_w > COL_W - 14.0:
				key_size = 11
				text_w = font.get_string_size(key_text, HORIZONTAL_ALIGNMENT_LEFT, -1, key_size).x
			var pill_w := clampf(text_w + 16.0, 38.0, COL_W - 6.0)
			pill.bg_color = Color(1.0, 0.45, 0.3) if on else Color(1, 1, 1, 0.16)
			draw_style_box(pill, Rect2(col_x - pill_w * 0.5, row_y, pill_w, PILL_H))
			var key_pos := Vector2(col_x - minf(text_w, pill_w - 8.0) * 0.5, row_y + PILL_H * 0.5 + key_size * 0.36)
			draw_string(font, key_pos, key_text, HORIZONTAL_ALIGNMENT_LEFT, pill_w - 8.0, key_size,
				Color.WHITE if on else Color(1, 1, 1, 0.85))
			var plain := str(lamp[2])
			var sub_w := font.get_string_size(plain, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
			var sub_pos := Vector2(col_x - sub_w * 0.5, row_y + PILL_H + 14.0)
			draw_string(font, sub_pos, plain, HORIZONTAL_ALIGNMENT_LEFT, -1, 12,
				Color.WHITE if on else Color(0.78, 0.82, 0.9, 0.85))


## Feeds P1's controls to the dummy while recording them.
class RecordingController extends FighterController:
	var source: FighterController
	var buffer: PackedInt32Array

	func _init(player_controller: FighterController, into: PackedInt32Array) -> void:
		source = player_controller
		buffer = into

	func read(fighter: Fighter) -> int:
		var packed := source.read(fighter)
		buffer.append(packed)
		return packed
