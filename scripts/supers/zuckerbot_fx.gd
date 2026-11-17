extends RefCounted
## Shared stand-ins and effects of Mark Zuckerbot's scenes (Metaverse Trap super and his
## victory): chunky VR goggles, the "legs not found" trick, a screen glitch and pixel bursts.
## Cosmetic only. Used with `const Fx := preload("res://scripts/supers/zuckerbot_fx.gd")`.

const PASTELS := [Color(0.6, 0.95, 0.75), Color(1.0, 0.7, 0.88), Color(0.65, 0.82, 1.0), Color(1.0, 0.95, 0.6)]
const LEG_BONES := ["thigh_l", "thigh_r"]


## Chunky VR goggles: dark visor with a glowing lens strip and a head strap. The origin is
## the point between the eyes, +Z is the front, like the eye point of a head bone (a real
## prop at assets/props/supers/zuckerbot/vr_goggles.tscn should use the same convention).
static func goggles() -> Node3D:
	var root := Node3D.new()
	root.name = "Goggles"
	var shell := SuperStandins.metal(Color(0.12, 0.12, 0.15), 0.3, 0.4)
	root.add_child(SuperStandins.box(Vector3(0.2, 0.1, 0.085), Vector3(0, 0, 0.07), shell, "Visor"))
	root.add_child(SuperStandins.box(Vector3(0.17, 0.045, 0.01), Vector3(0, 0, 0.116), SuperStandins.glow(Color(0.3, 0.9, 1.0), 3.0), "Lens"))
	var strap := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.1
	ring.outer_radius = 0.118
	ring.rings = 20
	ring.ring_segments = 8
	strap.mesh = ring
	strap.material_override = SuperStandins.metal(Color(0.85, 0.85, 0.9), 0.0, 0.7)
	strap.position = Vector3(0, 0.0, -0.035)
	strap.scale = Vector3(1.0, 1.0, 1.2)
	root.add_child(strap)
	return root


## Parents `goggles` to the model's head bone, on its eyes. Returns the attachment node.
static func wear(model: FighterModel, goggles: Node3D) -> Node3D:
	var mount := BoneAttachment3D.new()
	mount.name = "Goggles_Mount"
	mount.bone_name = "Head"
	model.skeleton.add_child(mount)
	var holder := Node3D.new()
	holder.scale = model._head_scale
	mount.add_child(holder)
	goggles.reparent(holder, false)
	goggles.transform = Transform3D(Basis.IDENTITY, model._eye_in_head)
	return mount


## Shrinks both legs to `amount` (1 = normal, 0 = gone): call after the puppet's own
## update each frame (give the scene a late process_priority).
static func legs(model: FighterModel, amount: float) -> void:
	if model == null or model.skeleton == null:
		return
	var s := maxf(amount, 0.001)
	for bone_name: String in LEG_BONES:
		var bone := model.skeleton.find_bone(bone_name)
		if bone >= 0:
			model.skeleton.set_bone_pose_scale(bone, Vector3.ONE * s)


## Bigger head (the avatar's cartoon proportions): call each frame like legs().
static func big_head(model: FighterModel, amount: float) -> void:
	var bone := model.skeleton.find_bone("Head")
	if bone >= 0:
		model.skeleton.set_bone_pose_scale(bone, Vector3.ONE * amount)


## A burst of small coloured cubes ("pixels") at `at` (world), flying out and fading.
static func pixels(parent: Node3D, at: Vector3, count := 14, spread := 1.6) -> void:
	for i in count:
		var cube := SuperStandins.box(Vector3.ONE * randf_range(0.05, 0.13), Vector3.ZERO,
				SuperStandins.glow(PASTELS[i % PASTELS.size()], 0.6))
		parent.add_child(cube)
		cube.global_position = at
		var dir := Vector3(randf_range(-1, 1), randf_range(-0.3, 1), randf_range(-1, 1)).normalized() * randf_range(0.4, 1.0) * spread
		var tween := cube.create_tween().set_parallel()
		tween.tween_property(cube, "global_position", at + dir, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(cube, "scale", Vector3.ZERO, 0.5).set_delay(0.15)
		tween.chain().tween_callback(cube.queue_free)


## Full-screen glitch: coloured bars and a tint that flicker. Add it to the scene, then
## `burst(seconds)`; `cover(true)` holds a solid colour (the loading screen between cuts).
class Glitch extends CanvasLayer:
	var _time := 0.0
	var _hold := false
	var _bars: Array[ColorRect] = []
	var _tint: ColorRect

	func _init() -> void:
		layer = 60
		name = "Glitch"
		_tint = ColorRect.new()
		_tint.set_anchors_preset(Control.PRESET_FULL_RECT)
		_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_tint.color = Color(0, 0, 0, 0)
		add_child(_tint)
		for i in 6:
			var bar := ColorRect.new()
			bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
			bar.visible = false
			add_child(bar)
			_bars.append(bar)

	func burst(seconds: float) -> void:
		_time = seconds

	func cover(on: bool, color := Color(0.04, 0.04, 0.08)) -> void:
		_hold = on
		_tint.color = Color(color, 1.0 if on else 0.0)

	func _process(delta: float) -> void:
		var active := _time > 0.0 or _hold
		_time = maxf(_time - delta, 0.0)
		var size := get_viewport().get_visible_rect().size
		for bar in _bars:
			bar.visible = active
			if active:
				bar.color = Color(PASTELS[randi() % PASTELS.size()], 0.5) if randf() < 0.7 else Color(0.0, 0.0, 0.0, 0.5)
				bar.position = Vector2(randf_range(-0.2, 0.6) * size.x, randf() * size.y)
				bar.size = Vector2(randf_range(0.2, 1.0) * size.x, randf_range(0.01, 0.06) * size.y)
		if not _hold:
			_tint.color = Color(0.5, 1.0, 1.0, 0.25 if _time > 0.0 and randf() < 0.5 else 0.0)
