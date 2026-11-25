class_name SuperScene
extends Node3D
## Base class of a super scene (docs/ROADMAP.md §2): a short animated scene played while the
## fight is frozen after a super with MoveData.cinematic hits. Cosmetic only: it never reads
## or changes the simulation. SuperScenePlayer creates it far from the stage, hides the
## fight, calls start() and frees it when the freeze ends.
##
## A scene script (scripts/supers/scenes/<cinematic>.gd) extends this and overrides
## build() (load sets, props, puppets) and run() (the timeline: `await wait(seconds)`
## between beats). Looks are stand-ins until the real ones arrive (docs/TASKS.md §3.1, §3.5):
## - sets: res://scenes/supers/sets/<set>.tscn (Gemini), placed with Marker3D anchors;
## - props: res://assets/props/supers/<path>.tscn (OpenCode), else a code-built stand-in;
## - sounds: res://assets/audio/supers/<attacker id>/<name>.ogg|.wav (Gemini), else silence.

const SET_DIR := "res://scenes/supers/sets/"
const PROP_DIR := "res://assets/props/supers/"
const SOUND_DIR := "res://assets/audio/supers/"

var fight: Node
var attacker: Fighter
var defender: Fighter
var move: MoveData
var camera: Camera3D
## The node the camera keeps looking at (null = it stays as placed).
var track: Node3D
var track_offset := Vector3(0.0, 1.0, 0.0)
var _sets := {} # name -> Node3D
var _environments := {} # set name -> Environment taken from the set's WorldEnvironment
var _big_texts: Array[Dictionary] = [] # active big_text entries kept inside the viewport


func setup(fight_manager: Node, attacking: Fighter, defending: Fighter, super_move: MoveData) -> void:
	fight = fight_manager
	attacker = attacking
	defender = defending
	move = super_move


func start() -> void:
	camera = Camera3D.new()
	camera.name = "SceneCamera"
	camera.fov = 50.0
	add_child(camera)
	camera.make_current()
	build()
	run()


## Override: sets, props, puppets.
func build() -> void:
	pass


## Override: the timeline (a coroutine).
func run() -> void:
	pass


## Override: cosmetic aftermath on the real fighters once the fight resumes (e.g. smoke).
func aftermath() -> void:
	pass


func _process(_delta: float) -> void:
	if track and is_instance_valid(track) and camera:
		var target := track.global_position + track_offset
		if target.distance_squared_to(camera.global_position) > 0.01:
			camera.look_at(target)
	_update_big_texts()


# --- Helpers ---------------------------------------------------------------------

func wait(seconds: float) -> Signal:
	return get_tree().create_timer(seconds).timeout


## Loads a set (hidden until show_set) at `offset` from the scene origin. Its
## WorldEnvironment becomes the scene camera's environment while the set is shown.
func load_set(set_name: String, offset := Vector3.ZERO) -> Node3D:
	var path := SET_DIR + set_name + ".tscn"
	var node: Node3D = (load(path) as PackedScene).instantiate() if ResourceLoader.exists(path) else Node3D.new()
	node.name = set_name
	node.position = offset
	node.visible = false
	for env: WorldEnvironment in node.find_children("*", "WorldEnvironment", true, false):
		_environments[set_name] = env.environment
		env.queue_free()
	add_child(node)
	_sets[set_name] = node
	return node


func show_set(set_name: String) -> void:
	for key: String in _sets:
		_sets[key].visible = key == set_name
	camera.environment = _environments.get(set_name)


## A Marker3D's global transform in a set (the set's own transform if it is missing).
func marker(set_name: String, marker_name: String) -> Transform3D:
	var set_node: Node3D = _sets[set_name]
	var node := set_node.find_child(marker_name, true, false) as Node3D
	return node.global_transform if node else set_node.global_transform


## Puts the camera on a set's Marker3D, looking at `target` (a point) if given.
func shot(set_name: String, marker_name: String, target := Vector3.INF) -> void:
	track = null
	camera.global_transform = marker(set_name, marker_name)
	if target != Vector3.INF:
		camera.look_at(target)


## A puppet of a fighter, added under `parent` (default: this scene).
func puppet(fighter: Fighter, parent: Node = null) -> ScenePuppet:
	var p := ScenePuppet.new()
	(parent if parent else self).add_child(p)
	p.setup(fighter.data, fighter.alt)
	return p


## A puppet of any character (NPCs, helpers): `data` built like a fighter.
func puppet_of(data: CharacterData, parent: Node = null, alt := false) -> ScenePuppet:
	var p := ScenePuppet.new()
	(parent if parent else self).add_child(p)
	p.setup(data, alt)
	return p


## The prop at assets/props/supers/<path>.tscn if it exists, else `standin.call()`.
func prop(path: String, standin: Callable, parent: Node = null) -> Node3D:
	var file := PROP_DIR + path + ".tscn"
	var node: Node3D = (load(file) as PackedScene).instantiate() if ResourceLoader.exists(file) else standin.call()
	(parent if parent else self).add_child(node)
	return node


## Plays assets/audio/supers/<attacker id>/<sound_name>.ogg (or .wav) if it exists.
func sound(sound_name: String, volume_db := 0.0) -> void:
	for ext: String in [".ogg", ".wav"]:
		var path: String = SOUND_DIR + String(attacker.data.id) + "/" + sound_name + ext
		if ResourceLoader.exists(path):
			var player := AudioStreamPlayer.new()
			player.stream = load(path)
			player.volume_db = volume_db
			player.bus = &"SFX" if AudioServer.get_bus_index(&"SFX") >= 0 else &"Master"
			add_child(player)
			player.play()
			player.finished.connect(player.queue_free)
			return


const FONT_PUNCH: Font = preload("res://assets/fonts/InterDisplay-BlackItalic.otf")
const FONT_MARKER: Font = preload("res://assets/fonts/PermanentMarker-Regular.ttf")


## Big billboard text that pops in (and out after `seconds`, if > 0), auto-fitted inside the viewport.
func big_text(text: String, at: Vector3, color := Color(1.0, 0.94, 0.72), size := 1.0, seconds := 0.0, marker_font := false) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font = FONT_MARKER if marker_font else FONT_PUNCH
	label.font_size = 96
	var base_pixel := 0.0055 * size
	label.pixel_size = base_pixel
	label.outline_size = maxi(6, int(round(12.0 * clampf(size, 0.4, 1.2))))
	label.modulate = color
	label.outline_modulate = Color(0.03, 0.03, 0.06, 0.98)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.shaded = false
	add_child(label)
	label.global_position = at
	var entry := {"label": label, "anchor": at, "raw": text, "base_pixel": base_pixel}
	_big_texts.append(entry)
	_fit_big_text(entry)
	label.scale = Vector3.ONE * 0.2
	var tween := label.create_tween()
	tween.tween_property(label, "scale", Vector3.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if seconds > 0.0:
		tween.tween_interval(seconds)
		tween.tween_property(label, "modulate:a", 0.0, 0.15)
		tween.tween_callback(label.queue_free)
	return label


func _update_big_texts() -> void:
	for i in range(_big_texts.size() - 1, -1, -1):
		var entry: Dictionary = _big_texts[i]
		if not is_instance_valid(entry["label"]):
			_big_texts.remove_at(i)
			continue
		var label: Label3D = entry["label"]
		if not label.is_inside_tree():
			_big_texts.remove_at(i)
			continue
		_fit_big_text(entry)


## Shrinks / wraps and clamps a billboard Label3D so it never clips outside the camera frame.
func _fit_big_text(entry: Dictionary) -> void:
	if camera == null or not is_instance_valid(camera):
		return
	var label: Label3D = entry["label"]
	var raw: String = entry["raw"]
	var base_pixel: float = entry["base_pixel"]
	var anchor: Vector3 = entry["anchor"]
	var cam_local: Vector3 = camera.global_transform.affine_inverse() * anchor
	cam_local.z = minf(cam_local.z, -0.6)
	var depth := -cam_local.z
	var vp_size := get_viewport().get_visible_rect().size if is_inside_tree() else Vector2(1920.0, 1080.0)
	var aspect := vp_size.x / maxf(vp_size.y, 1.0)
	if aspect <= 0.0:
		aspect = 16.0 / 9.0
	var half_h := depth * tan(deg_to_rad(camera.fov * 0.5))
	var half_w := half_h * aspect
	var max_w := half_w * 2.0 * 0.84
	var max_h := half_h * 2.0 * 0.42
	var text := raw
	var pad := Vector2.ONE * float(label.outline_size * 2)
	var text_px: Vector2 = label.font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, label.font_size) + pad
	if text_px.x * base_pixel > max_w * 1.28 and raw.find("\n") == -1:
		var wrapped := _wrap_balanced(raw)
		if wrapped != raw:
			text = wrapped
			text_px = label.font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, label.font_size) + pad
	if label.text != text:
		label.text = text
	var fit_pixel := base_pixel
	if text_px.x > 1.0:
		fit_pixel = minf(fit_pixel, max_w / text_px.x)
	if text_px.y > 1.0:
		fit_pixel = minf(fit_pixel, max_h / text_px.y)
	label.pixel_size = fit_pixel
	var label_half_w := text_px.x * fit_pixel * 0.5
	var label_half_h := text_px.y * fit_pixel * 0.5
	var limit_x := maxf(half_w * 0.90 - label_half_w, 0.0)
	var limit_y := maxf(half_h * 0.86 - label_half_h, 0.0)
	cam_local.x = clampf(cam_local.x, -limit_x, limit_x)
	cam_local.y = clampf(cam_local.y, -limit_y, limit_y)
	label.global_position = camera.global_transform * cam_local


static func _wrap_balanced(text: String) -> String:
	var words := text.split(" ", false)
	if words.size() < 2:
		return text
	var best_idx := 1
	var best_diff := INF
	for i in range(1, words.size()):
		var left := " ".join(words.slice(0, i))
		var right := " ".join(words.slice(i))
		var diff := absf(float(left.length() - right.length()))
		if diff < best_diff:
			best_diff = diff
			best_idx = i
	return " ".join(words.slice(0, best_idx)) + "\n" + " ".join(words.slice(best_idx))


## Ensures a knocked-down puppet's head never clips beneath `floor_y`.
func keep_head_above_floor(p: ScenePuppet, floor_y: float, clearance := 0.15) -> void:
	if p == null or not is_instance_valid(p) or p.model == null or p.model.skeleton == null:
		return
	var skel := p.model.skeleton
	var head_idx := skel.find_bone("Head")
	if head_idx < 0:
		return
	var head_y := (skel.global_transform * skel.get_bone_global_pose(head_idx)).origin.y
	if head_y < floor_y + clearance:
		p.global_position.y += (floor_y + clearance) - head_y
