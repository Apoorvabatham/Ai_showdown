class_name StageActor
extends Node3D
## One person on a stage: a real model from res://data/npcs/<npc>.tres (CharacterData built
## by FighterModel, UAL clips) or, without that file, a stand-in (capsule + sphere head in a
## muted shirt colour, reactions as tweens). Purely cosmetic: owns no simulation state.

const NPC_DIR := "res://data/npcs/"
const POSES: Array[StringName] = [&"stand", &"sit", &"lean", &"work"]
const REACTIONS: Array[StringName] = [&"cheer", &"gasp", &"clap", &"point", &"stand_up", &"bang_table", &"gavel", &"photo"]
const POSE_CLIPS := {
	&"stand": &"ual1/Idle",
	&"sit": &"ual1/Sitting_Idle",
	&"lean": &"ual2/Idle_Rail",
	&"work": &"ual1/Sitting_Talking",
}
## Real models: [clip, seconds the reaction plays].
const REACTION_CLIPS := {
	&"cheer": [&"ual1/Dance", 1.6],
	&"gasp": [&"ual1/Hit_Chest", 0.8],
	&"clap": [&"ual1/Idle_Talking", 1.4],
	&"point": [&"ual1/Interact", 1.2],
	&"stand_up": [&"ual1/Sitting_Exit", 1.2],
	&"bang_table": [&"ual1/Interact", 1.0],
	&"gavel": [&"ual1/Interact", 1.0],
	&"photo": [&"ual1/Pistol_Aim_Neutral", 1.4],
}
const SHIRTS := [Color(0.42, 0.45, 0.52), Color(0.5, 0.36, 0.34), Color(0.34, 0.45, 0.38), Color(0.55, 0.5, 0.36),
	Color(0.3, 0.34, 0.48), Color(0.45, 0.4, 0.5), Color(0.52, 0.52, 0.5), Color(0.28, 0.3, 0.32)]
const SKINS := [Color(0.85, 0.66, 0.52), Color(0.6, 0.42, 0.3), Color(0.4, 0.27, 0.18), Color(0.92, 0.75, 0.62)]

var npc := ""
var pose: StringName = &"stand"
var role := "crowd"
var reacts: Array[StringName] = []
var model: FighterModel # null for a stand-in
var reaction: StringName = &"" # the one playing now
var reaction_count := 0 # reactions started (tests)
var head_height := 1.8

var _rig: Node3D # stand-in body parts (tweened)
var _body: MeshInstance3D
var _head: MeshInstance3D
var _tween: Tween
var _clip: StringName
var _clip_until := 0.0
var _time := 0.0
var _phase := 0.0
var _animate := true


## `entry` is one "actors" element of the stage-life JSON. `use_models` false forces a
## stand-in (headless tests). `rng` is the crowd's own generator.
func setup(entry: Dictionary, rng: RandomNumberGenerator, use_models := true) -> void:
	npc = str(entry.get("npc", ""))
	role = str(entry.get("role", "crowd"))
	var p := entry.get("pos", [0, 0, 0]) as Array
	if p.size() >= 3:
		position = Vector3(float(p[0]), float(p[1]), float(p[2]))
	rotation.y = deg_to_rad(float(entry.get("yaw", 0.0)))
	for r in entry.get("reacts", []):
		if StringName(r) in REACTIONS:
			reacts.append(StringName(r))
	var wanted := StringName(str(entry.get("pose", "stand")))
	pose = wanted if wanted in POSES else &"stand"
	_phase = rng.randf() * TAU
	_animate = DisplayServer.get_name() != "headless"
	var path := NPC_DIR + npc + ".tres"
	if use_models and npc != "" and ResourceLoader.exists(path):
		var data := load(path) as CharacterData
		if data != null and data.model_scene != null:
			model = FighterModel.new()
			add_child(model)
			model.build(data, false)
			head_height = 1.75 * data.model_scale + 0.1
			_show_pose()
			return
		push_warning("StageActor: %s is not a usable CharacterData" % path)
	_build_stand_in(rng)


func is_stand_in() -> bool:
	return model == null


func supports(r: StringName) -> bool:
	return reacts.is_empty() or r in reacts


func _build_stand_in(rng: RandomNumberGenerator) -> void:
	_rig = Node3D.new()
	add_child(_rig)
	var shirt_mat := StandardMaterial3D.new()
	shirt_mat.albedo_color = SHIRTS[rng.randi() % SHIRTS.size()].lerp(Color(0.4, 0.4, 0.4), rng.randf() * 0.3)
	shirt_mat.roughness = 0.85
	var skin_mat := StandardMaterial3D.new()
	skin_mat.albedo_color = SKINS[rng.randi() % SKINS.size()]
	skin_mat.roughness = 0.6
	var body := CapsuleMesh.new()
	body.radius = 0.2
	body.height = 1.1
	_body = MeshInstance3D.new()
	_body.mesh = body
	_body.material_override = shirt_mat
	_rig.add_child(_body)
	var head := SphereMesh.new()
	head.radius = 0.12
	head.height = 0.24
	_head = MeshInstance3D.new()
	_head.mesh = head
	_head.material_override = skin_mat
	_rig.add_child(_head)
	var nose := MeshInstance3D.new() # shows which way the person faces (-Z)
	var nose_mesh := SphereMesh.new()
	nose_mesh.radius = 0.03
	nose_mesh.height = 0.06
	nose.mesh = nose_mesh
	nose.material_override = skin_mat
	nose.position = Vector3(0, -0.01, -0.12)
	_head.add_child(nose)
	for m: MeshInstance3D in [_body, _head, nose]:
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_show_pose()


## Applies the current pose: clip for a model, body and head heights for a stand-in.
func _show_pose() -> void:
	var seated := pose == &"sit" or pose == &"work"
	if model != null:
		head_height = 1.45 if seated else head_height
		_play(POSE_CLIPS[pose])
		return
	(_body.mesh as CapsuleMesh).height = 0.62 if seated else 1.1
	_body.position = Vector3(0, 0.5 if seated else 0.8, 0)
	_head.position = Vector3(0, 0.95 if seated else 1.48, 0)
	head_height = 1.2 if seated else 1.75
	_rig.rotation = Vector3.ZERO
	_rig.position = Vector3.ZERO
	_rig.scale = Vector3.ONE
	if pose == &"lean":
		_rig.rotation.x = deg_to_rad(-10.0)
	elif pose == &"work":
		_rig.rotation.x = deg_to_rad(-18.0)


func _play(clip: StringName) -> void:
	_clip = clip
	model.show_clip(clip, -1.0, 1.0, 0.0)


## Plays a reaction (see REACTIONS); unknown names are ignored. Returns true if it started.
func react(name: StringName) -> bool:
	if not name in REACTIONS:
		return false
	reaction = name
	reaction_count += 1
	if model != null:
		var spec: Array = REACTION_CLIPS[name]
		_clip_until = _time + float(spec[1])
		_play(spec[0])
		if name == &"stand_up":
			pose = &"stand"
		return true
	_react_tween(name)
	return true


func _react_tween(name: StringName) -> void:
	if _tween:
		_tween.kill()
	if name == &"stand_up":
		pose = &"stand"
	_show_pose()
	_tween = create_tween()
	var base_rx := _rig.rotation.x
	match name:
		&"cheer":
			for i in 3:
				_tween.tween_property(_rig, "position:y", 0.22, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
				_tween.tween_property(_rig, "position:y", 0.0, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		&"gasp":
			_tween.tween_property(_rig, "rotation:x", base_rx + deg_to_rad(18.0), 0.1)
			_tween.tween_interval(0.6)
			_tween.tween_property(_rig, "rotation:x", base_rx, 0.3)
		&"clap":
			for i in 5:
				_tween.tween_property(_rig, "scale", Vector3(1.06, 0.97, 1.06), 0.09)
				_tween.tween_property(_rig, "scale", Vector3.ONE, 0.09)
		&"point":
			_tween.tween_property(_rig, "rotation:z", deg_to_rad(-12.0), 0.15)
			_tween.tween_interval(0.7)
			_tween.tween_property(_rig, "rotation:z", 0.0, 0.25)
		&"stand_up":
			_tween.tween_property(_rig, "position:y", 0.12, 0.12)
			_tween.tween_property(_rig, "position:y", 0.0, 0.12)
		&"bang_table", &"gavel":
			for i in 3:
				_tween.tween_property(_rig, "rotation:x", base_rx - deg_to_rad(20.0), 0.08)
				_tween.tween_property(_rig, "rotation:x", base_rx, 0.12)
		&"photo":
			_tween.tween_property(_rig, "rotation:x", base_rx - deg_to_rad(8.0), 0.12)
			_tween.tween_interval(0.9)
			_tween.tween_property(_rig, "rotation:x", base_rx, 0.2)
	_tween.tween_callback(func() -> void: reaction = &"")


func _process(delta: float) -> void:
	_time += delta
	if model != null:
		if reaction != &"" and _time >= _clip_until:
			reaction = &""
			_play(POSE_CLIPS[pose])
		if _animate:
			model.show_clip(_clip, -1.0, 1.0, delta)
	elif _animate and reaction == &"" and _rig != null:
		var seated := pose == &"sit" or pose == &"work"
		_rig.position.y = sin(_time * 1.6 + _phase) * (0.006 if seated else 0.012)
