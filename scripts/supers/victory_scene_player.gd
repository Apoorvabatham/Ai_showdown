class_name VictoryScenePlayer
extends Node
## Plays the match winner's victory scene (docs/ROADMAP.md §2): when FightManager emits
## match_won, it runs scripts/supers/victory/<winner id>.gd if it exists (a VictoryScene).
## The scene keeps going behind the result menu and ends when the next match starts.
## Cosmetic only; the HUD (winner title, quote, result menu) stays on screen.

const VICTORY_DIR := "res://scripts/supers/victory/"

var fight: Node
var scene: VictoryScene
var _hidden: Array[Node] = []


func setup(fight_manager: Node) -> void:
	fight = fight_manager
	fight.match_won.connect(_on_match_won)


func _on_match_won(winner: Fighter) -> void:
	var path := VICTORY_DIR + String(winner.data.id) + ".gd"
	if not ResourceLoader.exists(path):
		return
	end_scene()
	scene = (load(path) as GDScript).new()
	scene.name = "VictoryScene"
	fight.add_child(scene)
	if scene.own_set:
		scene.position = SuperScenePlayer.SCENE_ORIGIN
		_hide_fight()
	scene.setup(fight, winner, winner.opponent, null)
	scene.start()


func _process(_delta: float) -> void:
	if scene and fight.phase != fight.Phase.MATCH_OVER:
		end_scene() # rematch or a new match


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
	finished.queue_free()


func _hide_fight() -> void:
	var nodes: Array[Node] = [fight.stage]
	for fighter: Fighter in fight.fighters:
		nodes.append(fighter)
		nodes.append_array(fighter.projectiles)
	for node in nodes:
		if node and node.visible:
			node.visible = false
			_hidden.append(node)
