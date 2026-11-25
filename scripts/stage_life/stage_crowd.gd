class_name StageCrowd
extends Node3D
## Stage life: people who react to the fight, speech bubbles with shouts (and voice files),
## and scripted events. Data: res://data/stage_life/<stage>.json (docs/TASKS.md 3.3).
## Strictly cosmetic: it listens to FightManager's signals, reads nothing back into the
## simulation, uses its own RandomNumberGenerator and does nothing while the manager is
## resimulating (rollback). Add it with StageCrowd.attach(manager).
##
## Shout/event keys: big_hit, super, ko, round_start, plus the optional throw and wall_hit.
## An event entry in "events" is a name or {"event": name, "pos": [x, y, z]}.

const LIFE_DIR := "res://data/stage_life/"
const AUDIO_DIR := "res://assets/audio/stage/"
const MAX_ACTORS := 20
const MAX_BUBBLES := 2
const BUBBLE_GAP := 0.7 # seconds an older bubble keeps its place before a newer one may replace it
const KEY_COOLDOWN := 1.5 # per shout key
const VOICE_DB := -6.0
## What each key makes the people do (first one the actor supports; others pick from their own list).
const KEY_REACTIONS := {
	"big_hit": [&"gasp", &"cheer", &"point"],
	"super": [&"photo", &"cheer", &"gasp"],
	"ko": [&"stand_up", &"cheer", &"clap"],
	"round_start": [&"cheer", &"clap"],
	"throw": [&"gasp", &"point"],
	"wall_hit": [&"gasp", &"bang_table"],
}
const REACT_SHARE := 0.6
const KEY_HEAVY_DAMAGE := 100
const BIG_COMBO := 5

var manager: Node
var stage_name := ""
var actors: Array[StageActor] = []
var shouts := {} # key -> Array of lines
var events := {} # key -> Array of String or Dictionary
var event_runner: StageEvents
## Tests and the stage can force stand-ins (the default in headless).
var use_models := true
## Last shout shown: {"key", "line", "index"}; empty before any.
var last_shout := {}
var shouts_shown := 0

var _rng := RandomNumberGenerator.new()
var _bubbles: Array[ShoutBubble] = []
var _key_time := {} # key -> seconds when last shouted
var _time := 0.0
var _last_phase := -1


## Adds a StageCrowd to `manager` when data/stage_life/<stage>.json exists for the loaded
## stage. Returns it, or null.
static func attach(manager_: Node) -> StageCrowd:
	var stage_path: String = manager_.stage.scene_file_path if manager_.stage else ""
	var path := json_path_for(stage_path)
	if path == "" or not FileAccess.file_exists(path):
		return null
	var crowd := StageCrowd.new()
	crowd.name = "StageCrowd"
	manager_.add_child(crowd)
	crowd.setup(manager_, path)
	return crowd


## res://data/stage_life/<scene file basename>.json for a stage scene path.
static func json_path_for(stage_path: String) -> String:
	if stage_path == "":
		return ""
	return LIFE_DIR + stage_path.get_file().get_basename() + ".json"


func _init() -> void:
	_rng.randomize()


## Loads `path` and (with a manager) connects to its signals. Returns false if the file
## is missing or malformed; the crowd then stays empty and harmless.
func setup(manager_: Node, path: String) -> bool:
	manager = manager_
	use_models = DisplayServer.get_name() != "headless"
	if manager and "stage" in manager and manager.stage:
		stage_name = manager.stage.scene_file_path.get_file().get_basename()
	else:
		stage_name = path.get_file().get_basename()
	var ok := load_file(path)
	if manager:
		_connect(manager)
	return ok


## Parses a stage-life JSON file and spawns its actors (replacing earlier ones).
func load_file(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_warning("StageCrowd: %s is not a JSON object" % path)
		return false
	load_data(parsed)
	return true


func load_data(data: Dictionary) -> void:
	for actor in actors:
		actor.queue_free()
	actors.clear()
	var list: Array = data.get("actors", []) if data.get("actors", []) is Array else []
	for entry in list:
		if actors.size() >= MAX_ACTORS:
			break
		if not entry is Dictionary:
			continue
		var actor := StageActor.new()
		add_child(actor)
		actor.setup(entry, _rng, use_models)
		actors.append(actor)
	shouts = {}
	var raw_shouts: Variant = data.get("shouts", {})
	if raw_shouts is Dictionary:
		for key in raw_shouts:
			if raw_shouts[key] is Array and not raw_shouts[key].is_empty():
				shouts[str(key)] = raw_shouts[key]
	events = {}
	var raw_events: Variant = data.get("events", {})
	if raw_events is Dictionary:
		for key in raw_events:
			if raw_events[key] is Array:
				events[str(key)] = raw_events[key]
	if event_runner == null:
		event_runner = StageEvents.new()
		event_runner.crowd = self
		add_child(event_runner)


func _connect(m: Node) -> void:
	for fighter: Fighter in m.fighters:
		fighter.knocked_out.connect(m.cosmetic(func(_f: Fighter) -> void: trigger("ko")))
		fighter.wall_hit.connect(m.cosmetic(func(_f: Fighter) -> void: trigger("wall_hit")))
	m.hit_landed.connect(m.cosmetic(_on_hit))
	m.throw_landed.connect(m.cosmetic(func(_a: Fighter, _d: Fighter) -> void: trigger("throw")))
	m.super_flash.connect(m.cosmetic(func(_f: Fighter, _mv: MoveData) -> void: trigger("super")))


func _on_hit(_attacker: Fighter, defender: Fighter, move: MoveData, result: int) -> void:
	if result in [Fighter.HitResult.BLOCKED, Fighter.HitResult.ARMORED]:
		return
	if move.input.begins_with("~"):
		return # a super's finisher: the "super" key already fired
	var big := move.launches or move.knockdown or move.damage >= KEY_HEAVY_DAMAGE \
		or result == Fighter.HitResult.COUNTER or defender.combo_hits >= BIG_COMBO
	if big:
		trigger("big_hit")


func _process(delta: float) -> void:
	_time += delta
	# The round start is the fight phase beginning; read-only peek at the manager's phase.
	if manager and "phase" in manager:
		var phase: int = manager.phase
		if phase != _last_phase:
			if phase == manager.Phase.FIGHT and _last_phase == manager.Phase.INTRO:
				trigger("round_start")
			_last_phase = phase
	_prune_bubbles()


## Drops bubbles that were freed or are about to be (a bubble frees itself when it expires,
## which can happen between two of our frames).
func _prune_bubbles() -> void:
	var alive: Array[ShoutBubble] = []
	for b in _bubbles:
		if is_instance_valid(b) and not b.is_queued_for_deletion():
			alive.append(b)
	_bubbles = alive


## A fight moment `key` (big_hit, super, ko, round_start, throw, wall_hit): a shout bubble
## with a line of that key, reactions, and the events the JSON maps to it.
func trigger(key: String) -> void:
	if manager and "resimulating" in manager and manager.resimulating:
		return
	if _actors_empty_and_blank():
		return
	if _time - float(_key_time.get(key, -100.0)) < KEY_COOLDOWN and _time > 0.0:
		return
	_key_time[key] = _time
	if shouts.has(key):
		var lines: Array = shouts[key]
		var index := _rng.randi() % lines.size()
		shout_line(str(lines[index]), key, null, index)
	_react(key)
	for entry in events.get(key, []):
		if entry is String:
			event_runner.run(StringName(entry))
		elif entry is Dictionary:
			var pos: Array = entry.get("pos", [])
			var at := Vector3(float(pos[0]), float(pos[1]), float(pos[2])) if pos.size() >= 3 else Vector3.INF
			event_runner.run(StringName(str(entry.get("event", ""))), at)


func _actors_empty_and_blank() -> bool:
	return actors.is_empty() and shouts.is_empty() and events.is_empty()


func _react(key: String) -> void:
	var prefer: Array = KEY_REACTIONS.get(key, [])
	for actor in actors:
		if _rng.randf() > REACT_SHARE:
			continue
		var choice := &""
		for r: StringName in prefer:
			if actor.supports(r) and (actor.reacts.has(r) or actor.reacts.is_empty()):
				choice = r
				break
		if choice == &"" and not actor.reacts.is_empty():
			choice = actor.reacts[_rng.randi() % actor.reacts.size()]
		if choice != &"":
			actor.react(choice)


## Shows `line` in a bubble above `actor` (a random one if null) and plays its voice file
## (assets/audio/stage/<stage>/voice/<key>_<index>.ogg) when `index` >= 0 and one exists.
## Returns the bubble, or null if two are already up and the oldest is too fresh to replace.
func shout_line(line: String, key: String, actor: StageActor = null, index := -1) -> ShoutBubble:
	if actors.is_empty():
		return null
	_prune_bubbles()
	if _bubbles.size() >= MAX_BUBBLES:
		var oldest := _bubbles[0]
		if oldest.age < BUBBLE_GAP:
			return null
		oldest.queue_free()
		_bubbles.remove_at(0)
	if actor == null:
		actor = _free_actor()
	var bubble := ShoutBubble.new()
	actor.add_child(bubble)
	bubble.position = Vector3(0, actor.head_height + 0.4, 0)
	bubble.setup(key, line)
	_bubbles.append(bubble)
	last_shout = {"key": key, "line": line, "index": index}
	shouts_shown += 1
	if index >= 0:
		_play_voice(key, index, actor)
	return bubble


## A random person with no bubble nearby, so two bubbles don't overlap.
func _free_actor() -> StageActor:
	_prune_bubbles()
	var open: Array[StageActor] = []
	for a in actors:
		if _bubbles.all(func(b: ShoutBubble) -> bool: return b.get_parent().position.distance_to(a.position) > 2.0):
			open.append(a)
	var from := open if not open.is_empty() else actors
	return from[_rng.randi() % from.size()]


func _play_voice(key: String, index: int, actor: StageActor) -> void:
	var path := "%s%s/voice/%s_%d.ogg" % [AUDIO_DIR, stage_name, key, index]
	if not ResourceLoader.exists(path):
		return
	var stream := load(path) as AudioStream
	if stream == null or DisplayServer.get_name() == "headless":
		return
	var player := AudioStreamPlayer3D.new()
	player.stream = stream
	player.volume_db = VOICE_DB
	player.unit_size = 8.0
	actor.add_child(player)
	player.position = Vector3(0, actor.head_height, 0)
	player.finished.connect(player.queue_free)
	player.play()


func bubble_count() -> int:
	_prune_bubbles()
	return _bubbles.size()


func actor_with_role(role: String) -> StageActor:
	for actor in actors:
		if actor.role == role:
			return actor
	return null
