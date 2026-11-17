class_name SuperScenePlayer
extends Node
## Plays super scenes (SuperScene) for FightManager: when a super with a scene hits
## (FightManager.cinematic_started), the fight is frozen for MoveData.cinematic_ticks; this
## hides the stage, fighters and HUD, plays scripts/supers/scenes/<cinematic>.gd far below
## the stage, and puts everything back when the freeze ends. Cosmetic only.

const SCENE_DIR := "res://scripts/supers/scenes/"
## Where scenes are built: far from the stage, so nothing of the fight shows in them.
const SCENE_ORIGIN := Vector3(0.0, -400.0, 0.0)

var fight: Node
var scene: SuperScene
var _hidden: Array[Node] = []


func setup(fight_manager: Node) -> void:
	fight = fight_manager
	fight.cinematic_started.connect(_on_cinematic_started)


func _on_cinematic_started(attacker: Fighter, defender: Fighter, move: MoveData) -> void:
	var path := SCENE_DIR + String(move.cinematic) + ".gd"
	if not ResourceLoader.exists(path):
		push_warning("No super scene %s" % path)
		return
	end_scene()
	scene = (load(path) as GDScript).new()
	scene.name = "SuperScene"
	fight.add_child(scene)
	scene.position = SCENE_ORIGIN
	scene.setup(fight, attacker, defender, move)
	_hide_fight()
	scene.start()


func _process(_delta: float) -> void:
	if scene and fight.freeze_ticks <= 0:
		end_scene()


func end_scene() -> void:
	if scene == null:
		return
	var finished := scene
	scene = null
	for node in _hidden:
		if is_instance_valid(node):
			node.visible = true
	_hidden.clear()
	fight.camera.make_current()
	finished.aftermath()
	finished.queue_free()


func _hide_fight() -> void:
	var nodes: Array[Node] = [fight.stage, fight.hud]
	for fighter: Fighter in fight.fighters:
		nodes.append(fighter)
		nodes.append_array(fighter.projectiles)
	for node in nodes:
		if node and node.visible:
			node.visible = false
			_hidden.append(node)
