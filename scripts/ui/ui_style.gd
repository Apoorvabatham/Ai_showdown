class_name UiStyle
## Shared look for the menu screens: a dark, clean backdrop (graphite gradient, a soft
## accent glow, slow diagonal light sheens) and the display font for headings.

const DISPLAY_FONT := "res://assets/fonts/InterDisplay-ExtraBold.otf"
## The accent shared with the theme (assets/ui/theme.tres): focus bars, highlights.
const ACCENT := Color(0.2, 0.82, 1.0)

const BACKDROP_SHADER := """
shader_type canvas_item;
uniform vec4 accent : source_color = vec4(0.2, 0.82, 1.0, 1.0);
float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	vec2 uv = UV;
	vec3 col = mix(vec3(0.045, 0.05, 0.068), vec3(0.012, 0.014, 0.02), smoothstep(0.0, 1.0, uv.y));
	// soft accent glow from the upper right, a warmer one low left
	col += accent.rgb * 0.10 * exp(-length((uv - vec2(0.85, 0.15)) * vec2(1.6, 2.2)) * 2.4);
	col += vec3(1.0, 0.35, 0.3) * 0.035 * exp(-length((uv - vec2(0.1, 0.95)) * vec2(1.6, 2.0)) * 2.6);
	// slow diagonal sheens
	float d = uv.x * 0.8 + uv.y * 0.5 - TIME * 0.025;
	float sheen = smoothstep(0.0, 0.5, sin(d * 9.0)) * smoothstep(1.0, 0.5, sin(d * 9.0));
	col += vec3(0.6, 0.75, 0.9) * sheen * 0.012;
	// fine diagonal hairlines
	float lines = smoothstep(0.985, 1.0, fract((uv.x * 1.78 - uv.y) * 60.0));
	col += vec3(1.0) * lines * 0.008;
	float vignette = smoothstep(1.3, 0.3, length((uv - 0.5) * vec2(1.3, 1.0)));
	col *= mix(0.55, 1.0, vignette);
	col += (hash(uv * 1000.0) - 0.5) * 0.006; // dither
	COLOR = vec4(col, 1.0);
}
"""


## Backdrop: the screen splits on a diagonal (P1 blue, P2 red) with speed lines rushing
## toward the middle and a hot seam where the sides meet.
const VERSUS_SHADER := """
shader_type canvas_item;
uniform vec4 left_color : source_color = vec4(0.12, 0.42, 0.95, 1.0);
uniform vec4 right_color : source_color = vec4(0.95, 0.18, 0.26, 1.0);
void fragment() {
	vec2 uv = UV;
	float split = uv.x + (uv.y - 0.5) * 0.26;
	float side = step(0.5, split);
	vec3 tint = mix(left_color.rgb, right_color.rgb, side);
	float dist = abs(split - 0.5);
	vec3 base = mix(vec3(0.03, 0.035, 0.05), vec3(0.012, 0.014, 0.02), uv.y);
	base += tint * 0.32 * exp(-dist * 4.0); // each side glows toward the seam
	// a few thin, fast streaks
	float row = floor(uv.y * 90.0);
	float h = fract(sin(row * 78.233) * 43758.5);
	float dir = side * 2.0 - 1.0;
	float x = fract(uv.x * (0.8 + h) + dir * TIME * (0.6 + h * 1.2) + h * 5.0);
	float streak = smoothstep(0.93, 0.95, x) * smoothstep(1.0, 0.97, x) * step(0.7, h);
	base += tint * streak * 0.35;
	base += vec3(1.0) * exp(-dist * 260.0) * 0.9; // crisp white seam
	float vignette = smoothstep(1.3, 0.3, length((uv - 0.5) * vec2(1.3, 1.0)));
	COLOR = vec4(base * mix(0.6, 1.0, vignette), 1.0);
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


## The P1-vs-P2 look (VS and story screens): hides the flat LeftGlow/RightGlow halves,
## adds the animated diagonal split and fades both portraits out at the bottom.
static func versus_look(screen: Control, left_portrait: TextureRect, right_portrait: TextureRect) -> void:
	for glow_name in ["LeftGlow", "RightGlow"]:
		var glow := screen.get_node_or_null(glow_name) as CanvasItem
		if glow:
			glow.hide()
	var rect := ColorRect.new()
	rect.name = "Backdrop"
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = VERSUS_SHADER
	var material := ShaderMaterial.new()
	material.shader = shader
	rect.material = material
	screen.add_child(rect)
	var background := screen.get_node_or_null("Background")
	screen.move_child(rect, background.get_index() + 1 if background else 0)
	var fade := Shader.new()
	fade.code = FADE_SHADER
	for portrait in [left_portrait, right_portrait]:
		if portrait:
			var fade_material := ShaderMaterial.new()
			fade_material.shader = fade
			portrait.material = fade_material


## A full-screen backdrop ColorRect; add it right above the screen's plain background.
static func backdrop() -> ColorRect:
	var rect := ColorRect.new()
	rect.name = "Backdrop"
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = BACKDROP_SHADER
	var material := ShaderMaterial.new()
	material.shader = shader
	rect.material = material
	return rect


## Puts the backdrop just above `background` (a sibling ColorRect) in `screen`.
static func add_backdrop(screen: Control, background: Node = null) -> ColorRect:
	var rect := backdrop()
	screen.add_child(rect)
	screen.move_child(rect, background.get_index() + 1 if background else 0)
	return rect


## Dark glass panel: translucent graphite with a faint accent hairline (heavier on top).
static func glass_panel(margin := 28.0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.035, 0.04, 0.055, 0.88)
	box.set_border_width_all(1)
	box.border_width_top = 3
	box.border_color = Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.45)
	box.set_corner_radius_all(3)
	box.shadow_color = Color(0, 0, 0, 0.45)
	box.shadow_size = 18
	box.content_margin_left = margin
	box.content_margin_right = margin
	box.content_margin_top = margin * 0.8
	box.content_margin_bottom = margin * 0.8
	return box


## Puts glass_panel() on a panel (no-op for null).
static func use_glass(panel: Control, margin := 28.0) -> void:
	if panel:
		panel.add_theme_stylebox_override("panel", glass_panel(margin))


## Modern focus frame for picture tiles (fighter portraits, stage cards): a white border
## with an accent glow. `base` supplies the corner radius and background.
static func tile_focus(base: StyleBoxFlat) -> StyleBoxFlat:
	var focused := base.duplicate() as StyleBoxFlat
	focused.set_border_width_all(4)
	focused.border_color = Color(1, 1, 1)
	focused.shadow_color = Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.55)
	focused.shadow_size = 16
	return focused


## Recolours a ProgressBar's fill to the accent (keeps its other style settings).
static func accent_bar(bar: ProgressBar) -> void:
	if bar == null:
		return
	var fill := StyleBoxFlat.new()
	fill.bg_color = ACCENT
	fill.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("fill", fill)
	var back := StyleBoxFlat.new()
	back.bg_color = Color(1, 1, 1, 0.07)
	back.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("background", back)


## The heading font, or null when it is missing.
static func display_font() -> Font:
	return load(DISPLAY_FONT) if ResourceLoader.exists(DISPLAY_FONT) else null


## Sets the display font on each label (no-op without the font).
static func use_display_font(labels: Array) -> void:
	var font := display_font()
	if font == null:
		return
	for label in labels:
		if label is Control:
			(label as Control).add_theme_font_override("font", font)
