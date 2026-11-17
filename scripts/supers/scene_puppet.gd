class_name ScenePuppet
extends Node3D
## A fighter's real model in a super or victory scene (cosmetic): plays any clip from the
## FighterModel libraries (ual1/, ual2/, fight/, later style/) and shows an expression.
## Faces -Z like a fighter.

var model: FighterModel
var clip: StringName = &"fight/guard"
## >= 0: the clip is held at this time (a pose); < 0: it free-runs at `speed`.
var clip_time := -1.0
var speed := 1.0
var face: StringName = &"neutral"


## Call once the puppet is in the scene tree.
func setup(data: CharacterData, alt: bool) -> void:
	model = FighterModel.new()
	add_child(model)
	model.build(data, alt)


## Plays `clip_name` from where it is (free-running).
func play(clip_name: StringName, play_speed := 1.0) -> void:
	clip = clip_name
	clip_time = -1.0
	speed = play_speed


## Holds `clip_name` posed at `time` seconds.
func hold(clip_name: StringName, time: float) -> void:
	clip = clip_name
	clip_time = time


func _process(delta: float) -> void:
	if model == null:
		return
	model.show_clip(clip, clip_time, speed, delta)
	model.set_face(face, delta)
