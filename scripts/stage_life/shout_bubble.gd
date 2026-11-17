class_name ShoutBubble
extends Node3D
## A speech bubble above a stage person's head: pops in, holds, fades. Purely cosmetic.
## A billboard Label3D over a white billboard quad sized from the text.

const LIFETIME := 2.0
const FADE := 0.4
const POP := 0.12

var key := ""
var line := ""
var age := 0.0

var _label: Label3D
var _back: MeshInstance3D
var _mat: StandardMaterial3D
var _fading := false


func setup(key_: String, line_: String) -> void:
	key = key_
	line = line_
	_label = Label3D.new()
	_label.text = line_
	_label.font_size = 32
	_label.pixel_size = 0.005
	_label.outline_size = 0
	_label.modulate = Color(0.08, 0.08, 0.1)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.render_priority = 2
	_label.shaded = false
	add_child(_label)
	var font := ThemeDB.fallback_font
	var box := font.get_string_size(line_, HORIZONTAL_ALIGNMENT_CENTER, -1, _label.font_size) * _label.pixel_size
	var pad := 0.08
	var quad := QuadMesh.new()
	quad.size = Vector2(maxf(box.x, 0.3) + pad * 2.0, maxf(box.y, 0.15) + pad * 1.4)
	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.albedo_color = Color(1, 1, 1, 0.94)
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_mat.no_depth_test = true
	_mat.render_priority = 1
	_back = MeshInstance3D.new()
	_back.mesh = quad
	_back.material_override = _mat
	_back.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_back)
	scale = Vector3.ONE * 0.1
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3.ONE, POP).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	age += delta
	if age >= LIFETIME - FADE and not _fading:
		_fading = true
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(_mat, "albedo_color:a", 0.0, FADE)
		tween.tween_property(_label, "modulate:a", 0.0, FADE)
	if age >= LIFETIME:
		queue_free()
