extends SceneTree
## Writes the stand-in super- and victory-scene sets (res://scenes/supers/sets/<set>.tscn) that
## do not exist yet: plain shapes, a sky and the Marker3D anchors the scene scripts use.
## Gemini then makes them look real (docs/TASKS.md §3.5); this tool never overwrites an
## existing set. Each fighter's sets live in tools/super_sets/<fighter id>.gd, a script with
## `static func sets() -> Dictionary` (set name -> Callable returning a Node3D), built with
## the static helpers in tools/super_set_kit.gd.
##
## Run: godot --headless --path . -s res://tools/build_super_sets.gd

const DIR := "res://scenes/supers/sets/"
const SOURCES := "res://tools/super_sets/"


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	for file in DirAccess.get_files_at(SOURCES):
		if file.ends_with(".gd"):
			var builders: Dictionary = load(SOURCES + file).sets()
			for set_name: String in builders:
				_write(set_name, builders[set_name])
	quit()


func _write(set_name: String, builder: Callable) -> void:
	var path := DIR + set_name + ".tscn"
	if ResourceLoader.exists(path):
		print("%-14s exists, kept" % set_name)
		return
	var root: Node3D = builder.call()
	root.name = set_name
	_own(root, root)
	var scene := PackedScene.new()
	scene.pack(root)
	var err := ResourceSaver.save(scene, path)
	print("%-14s %s" % [set_name, "written" if err == OK else "ERROR %d" % err])
	root.free()


func _own(node: Node, owner_node: Node) -> void:
	for child in node.get_children():
		child.owner = owner_node
		_own(child, owner_node)
