extends SceneTree
## Step 1 of the age pass: exports the base face (vertices, UVs, landmarks) and each
## fighter's age and skin to assets/characters/aged/face_uv.json; tools/build_aged_skins.py
## (step 2) paints the age into each fighter's skin texture: forehead
## lines, crow's feet, under-eye bags, nose-to-mouth (nasolabial) and marionette lines,
## neck lines, and age spots from about 70, all stronger with age. Strokes are drawn on the
## face in 3D (placed from FaceShapes' landmarks) and mapped onto the texture through the
## base body's UVs, so they land in the right place on the shared UV layout.
## Writes res://assets/characters/aged/T_<id>_skin.png; build_showdown_roster.gd then uses
## it as the fighter's skin. Run after changing a fighter's age or skin:
##   godot --headless --path . -s res://tools/build_aged_skins.gd
##   python3 tools/build_aged_skins.py [<id> ...]
## (then --import and build_showdown_roster.gd)

const BODY := "res://assets/characters/base/Superhero_Male_FullBody.gltf"
const OUT_DIR := "res://assets/characters/aged/"
const ROSTER_TOOL := "res://tools/build_showdown_roster.gd"
const YOUNG := 35.0 # no lines before this age
const OLD := 82.0 # full strength at this age

var _verts: PackedVector3Array
var _uvs: PackedVector2Array
var _L: Dictionary


func _initialize() -> void:
	var scene := (load(BODY) as PackedScene).instantiate()
	_L = FaceShapes.landmarks(scene)
	for mi: MeshInstance3D in scene.find_children("*", "MeshInstance3D", true, false):
		var material := mi.mesh.surface_get_material(0)
		if material and material.resource_name.begins_with("MI_Superhero"):
			var arrays := mi.mesh.surface_get_arrays(0)
			_verts = arrays[Mesh.ARRAY_VERTEX]
			_uvs = arrays[Mesh.ARRAY_TEX_UV]
	scene.free()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	# Export the face (front-facing vertices with their UVs), the landmarks and the roster's
	# ages and skins for tools/build_aged_skins.py, which paints the lines.
	var eye: Vector3 = _L.eye
	var face := []
	for i in _verts.size():
		var v := _verts[i]
		if absf(v.x) < 0.085 and v.y > eye.y - 0.17 and v.y < eye.y + 0.1 and v.z > eye.z - 0.045:
			face.append([v.x, v.y, v.z, _uvs[i].x, _uvs[i].y])
	var roster_script: GDScript = load(ROSTER_TOOL)
	var skins: Dictionary = roster_script.get_script_constant_map()["SKINS"]
	var fighters := []
	for spec: Dictionary in roster_script.get_script_constant_map()["ROSTER"]:
		if spec.has("age"):
			fighters.append({id = String(spec.id), age = spec.age, skin = ProjectSettings.globalize_path(skins[spec.skin])})
	var data := {eye = [eye.x, eye.y, eye.z], eye_radius = _L.eye_radius, seam = _L.seam, corner = _L.corner,
		face = face, fighters = fighters}
	var file := FileAccess.open(OUT_DIR + "face_uv.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
	print("exported %d face vertices, %d fighters" % [face.size(), fighters.size()])
	quit()
