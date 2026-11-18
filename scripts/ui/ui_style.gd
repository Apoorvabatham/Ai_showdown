class_name UiStyle
## Shared look for the menu screens: the synthwave backdrop (dark purple sky, a glowing
## horizon and a perspective grid floor, matching the title screen and logo) and the
## display font for headings.

const DISPLAY_FONT := "res://assets/fonts/InterDisplay-BlackItalic.otf"

const BACKDROP_SHADER := """
shader_type canvas_item;
uniform float horizon = 0.62;
void fragment() {
	vec2 uv = UV;
	vec3 sky = mix(vec3(0.015, 0.01, 0.05), vec3(0.11, 0.03, 0.17), smoothstep(0.0, horizon, uv.y));
	float glow = exp(-abs(uv.y - horizon) * 18.0);
	vec3 col = sky + vec3(0.85, 0.2, 0.6) * glow * 0.55;
	if (uv.y > horizon) {
		float depth = (uv.y - horizon) / (1.0 - horizon); // 0 at the horizon, 1 at the bottom
		float z = 1.0 / max(depth, 0.02);
		float lines_z = smoothstep(0.92, 1.0, fract(z * 0.9 - TIME * 0.35)) ;
		float x = (uv.x - 0.5) * z;
		float lines_x = smoothstep(0.94, 1.0, fract(x * 1.6 + 0.5)) + smoothstep(0.94, 1.0, 1.0 - fract(x * 1.6 + 0.5));
		float fade = smoothstep(0.0, 0.5, depth);
		col = mix(vec3(0.02, 0.01, 0.05), vec3(0.06, 0.02, 0.1), depth);
		col += vec3(0.25, 0.75, 1.0) * clamp(lines_z + lines_x, 0.0, 1.0) * fade * 0.45;
		col += vec3(0.85, 0.2, 0.6) * glow * 0.4;
	}
	float vignette = smoothstep(1.25, 0.35, length((uv - 0.5) * vec2(1.4, 1.0)));
	COLOR = vec4(col * vignette, 1.0);
}
"""


## Backdrop: the screen splits on a diagonal (P1 blue, P2 red) with speed lines rushing
## toward the middle and a hot seam where the sides meet.
const VERSUS_SHADER := """
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
