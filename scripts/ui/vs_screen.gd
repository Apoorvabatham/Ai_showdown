extends Control
## "P1 VS P2" splash between character select and the fight. Portraits slide in from
## the sides, "VS" punches in, then the fight loads. Confirm skips it. In Arcade mode it
## also shows the stage number and the ladder, and the boss's portrait is darkened.

const HOLD_SECONDS := 2.2
const LADDER_ICON := Vector2(110, 110)
const SHADOW_TINT := Color(0.55, 0.35, 0.75)

@onready var left_portrait: TextureRect = %LeftPortrait
@onready var right_portrait: TextureRect = %RightPortrait
@onready var left_name: Label = %LeftName
@onready var right_name: Label = %RightName
@onready var vs_label: Label = %VsLabel
@onready var left_side: Control = %LeftSide
@onready var right_side: Control = %RightSide

var _leaving := false

## Backdrop: the screen splits on a diagonal (P1 blue, P2 red) with speed lines rushing
## toward the middle and a hot seam where the sides meet.
const BACKDROP_SHADER := """
shader_type canvas_item;
uniform vec4 left_color : source_color = vec4(0.10, 0.22, 0.62, 1.0);
uniform vec4 right_color : source_color = vec4(0.62, 0.08, 0.16, 1.0);
void fragment() {
	vec2 uv = UV;
	float split = uv.x + (uv.y - 0.5) * 0.22;
	float side = step(0.5, split);
	vec3 base = mix(left_color.rgb, right_color.rgb, side);
	float dist = abs(split - 0.5);
	base *= 0.35 + 0.65 * smoothstep(0.75, 0.0, dist); // darker toward the outer edges
	float row = floor(uv.y * 64.0);
	float h = fract(sin(row * 78.233) * 43758.5);
	float dir = side * 2.0 - 1.0; // lines rush toward the seam
	float x = fract(uv.x * (1.2 + h) + dir * TIME * (0.9 + h * 1.6) + h * 5.0);
	float streak = smoothstep(0.86, 0.9, x) * smoothstep(1.0, 0.95, x) * step(0.45, h);
	base += mix(left_color.rgb, right_color.rgb, side) * streak * 0.9;
	float seam = exp(-dist * 90.0);
	base += vec3(1.0, 0.85, 0.5) * seam * 1.4;
	COLOR = vec4(base, 1.0);
}
"""
## Portraits fade out at the bottom instead of ending in a hard edge.
const FADE_SHADER := """
shader_type canvas_item;
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	c.a *= smoothstep(1.0, 0.72, UV.y);
	COLOR = c * COLOR;
}
"""
const DISPLAY_FONT := "res://assets/fonts/InterDisplay-BlackItalic.otf"


func _ready() -> void:
	GameState.ensure_selections()
	_decorate()
	left_portrait.texture = GameState.player_character.portrait
	right_portrait.texture = GameState.p2_character.portrait
	var versus := GameState.mode == GameState.Mode.VERSUS or GameState.is_online()
	left_name.text = ("P1  " if versus else "") + GameState.player_character.display_name.to_upper()
	right_name.text = "%s (%s)" % [GameState.p2_character.display_name.to_upper(), "P2" if versus else "CPU"]
	if GameState.is_arcade():
		_show_arcade_ladder()
	else:
		_show_stage_name()
	# Wait a frame so containers have laid out, then animate from off-screen.
	await get_tree().process_frame
	var width := get_viewport_rect().size.x
	var left_home := left_side.position
	var right_home := right_side.position
	left_side.position.x -= width * 0.6
	right_side.position.x += width * 0.6
	vs_label.pivot_offset = vs_label.size / 2.0
	vs_label.scale = Vector2(3, 3)
	vs_label.modulate.a = 0.0
	var tween := create_tween().set_parallel()
	tween.tween_property(left_side, "position", left_home, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(right_side, "position", right_home, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(vs_label, "scale", Vector2.ONE, 0.3).set_delay(0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(vs_label, "modulate:a", 1.0, 0.15).set_delay(0.35)
	get_tree().create_timer(HOLD_SECONDS).timeout.connect(_go)


func _decorate() -> void:
	for glow_name in ["LeftGlow", "RightGlow"]:
		var glow := get_node_or_null(glow_name) as CanvasItem
		if glow:
			glow.hide()
	var backdrop := ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = BACKDROP_SHADER
	var material := ShaderMaterial.new()
	material.shader = shader
	backdrop.material = material
	add_child(backdrop)
	move_child(backdrop, 1) # just above the plain background
	var fade := Shader.new()
	fade.code = FADE_SHADER
	for portrait: TextureRect in [left_portrait, right_portrait]:
		var fade_material := ShaderMaterial.new()
		fade_material.shader = fade
		portrait.material = fade_material
	if ResourceLoader.exists(DISPLAY_FONT):
		var font: Font = load(DISPLAY_FONT)
		for label: Label in [left_name, right_name, vs_label]:
			label.add_theme_font_override("font", font)


func _show_stage_name() -> void:
	var label := Label.new()
	label.text = GameState.stage_name(GameState.stage_path).to_upper()
	label.add_theme_font_size_override("font_size", 40)
	label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	label.add_theme_constant_override("outline_size", 10)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	label.offset_bottom = -50
	add_child(label)


## Stage title above "VS" and a row of opponent portraits along the bottom: beaten
## ones dimmed, the current one framed in gold, the boss as a silhouette until reached.
func _show_arcade_ladder() -> void:
	var run := GameState.arcade
	right_name.text = run.opponent_title()
	if run.current().boss:
		right_portrait.modulate = SHADOW_TINT
		right_name.text += "\nFINAL BOSS"
		Audio.voice("prepare_yourself")
	var title := Label.new()
	title.text = "FINAL STAGE" if run.is_final() else "STAGE %d / %d" % [run.stage + 1, run.stages.size()]
	title.text += "  ·  " + GameState.stage_name(GameState.stage_path).to_upper()
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.3))
	title.add_theme_constant_override("outline_size", 12)
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.grow_horizontal = Control.GROW_DIRECTION_BOTH
	title.offset_top = 40
	add_child(title)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	row.grow_horizontal = Control.GROW_DIRECTION_BOTH
	row.grow_vertical = Control.GROW_DIRECTION_BEGIN
	row.offset_bottom = -36
	add_child(row)
	for i in run.stages.size():
		var entry: Dictionary = run.stages[i]
		var frame := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.08, 0.08, 0.12, 0.9)
		style.set_border_width_all(4 if i == run.stage else 2)
		style.border_color = Color(1.0, 0.82, 0.3) if i == run.stage else Color(0.3, 0.3, 0.36)
		frame.add_theme_stylebox_override("panel", style)
		var icon := TextureRect.new()
		icon.texture = (entry.character as CharacterData).portrait
		icon.custom_minimum_size = LADDER_ICON
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		if entry.boss:
			icon.modulate = SHADOW_TINT if i <= run.stage else Color(0.05, 0.05, 0.08)
		elif i < run.stage:
			icon.modulate = Color(0.35, 0.35, 0.35) # beaten
		frame.add_child(icon)
		row.add_child(frame)


func _unhandled_input(event: InputEvent) -> void:
	# Online, both players go on together when the timer ends (no skipping).
	if event.is_action_pressed("ui_accept") and not GameState.is_online():
		_go()


func _go() -> void:
	if _leaving:
		return
	_leaving = true
	GameState.go_to_fight(get_tree())
