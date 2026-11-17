extends SceneTree
## Writes the stand-in super-scene sets (res://scenes/supers/sets/<set>.tscn) that do not
## exist yet: plain shapes, a sky and the Marker3D anchors the scene scripts use. Gemini then
## makes them look real (docs/TASKS.md §3.5); this tool never overwrites an existing set.
##
## Run: godot --headless --path . -s res://tools/build_super_sets.gd

const DIR := "res://scenes/supers/sets/"


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	_write("launch_pad", _launch_pad())
	_write("space", _space())
	_write("mars", _mars())
	quit()


func _write(set_name: String, root: Node3D) -> void:
	var path := DIR + set_name + ".tscn"
	if ResourceLoader.exists(path):
		print("%-12s exists, kept" % set_name)
		root.free()
		return
	root.name = set_name
	_own(root, root)
	var scene := PackedScene.new()
	scene.pack(root)
	var err := ResourceSaver.save(scene, path)
	print("%-12s %s" % [set_name, "written" if err == OK else "ERROR %d" % err])
	root.free()


func _own(node: Node, owner_node: Node) -> void:
	for child in node.get_children():
		child.owner = owner_node
		_own(child, owner_node)


# Elon's super, part 1: the launch pad at sunset. The rocket stands at `Rocket`.
func _launch_pad() -> Node3D:
	var root := Node3D.new()
	root.add_child(_environment(_sky(Color(0.25, 0.35, 0.6), Color(0.95, 0.55, 0.3), Color(0.25, 0.2, 0.18)), 0.6))
	root.add_child(_sun(Vector3(-25, -35, 0), Color(1.0, 0.8, 0.6), 1.3))
	root.add_child(_plane(Vector2(120, 120), Vector3.ZERO, _mat(Color(0.32, 0.31, 0.3), 0.9)))
	root.add_child(_cylinder(4.0, 0.3, Vector3(0, 0.15, 0), _mat(Color(0.5, 0.5, 0.5), 0.7)))
	root.add_child(_box(Vector3(1.2, 16, 1.2), Vector3(-3.4, 8, -1.6), _mat(Color(0.55, 0.18, 0.12), 0.6)))
	root.add_child(_box(Vector3(2.6, 0.3, 0.4), Vector3(-2.1, 9.5, -1.6), _mat(Color(0.55, 0.18, 0.12), 0.6)))
	for i in 4:
		root.add_child(_box(Vector3(3, 2.5, 3), Vector3(-30 + 15 * i, 1.25, -28), _mat(Color(0.4, 0.42, 0.45), 0.8)))
	_marker(root, "Rocket", Vector3(0, 0.3, 0))
	_marker(root, "Truck_Start", Vector3(-18, 0, 6), -90.0)
	_marker(root, "Truck_Stop", Vector3(-4.5, 0, 6), -90.0)
	_marker(root, "Attacker", Vector3(-2.4, 0, 3.6))
	_marker(root, "Cam_Wide", Vector3(9, 3.5, 15))
	_marker(root, "Cam_Attacker", Vector3(-0.6, 1.8, 7.0))
	_marker(root, "Cam_Launch", Vector3(10, 1.0, 13))
	return root


# Elon's super, part 2: space above the Earth. The rocket crosses from `Rocket_Start` to
# `Rocket_End`; the chained fighter falls back from `Reentry_Start` to `Reentry_End`.
func _space() -> Node3D:
	var root := Node3D.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.0, 0.0, 0.01)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.25, 0.27, 0.35)
	env.glow_enabled = true
	root.add_child(_environment(env, 0.0))
	root.add_child(_sun(Vector3(-20, 60, 0), Color(1, 0.97, 0.92), 1.6))
	var stars := MultiMeshInstance3D.new()
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	var star := SphereMesh.new()
	star.radius = 0.12
	star.height = 0.24
	star.radial_segments = 6
	star.rings = 3
	star.material = _glow(Color(1, 1, 1), 3.0)
	multimesh.mesh = star
	multimesh.instance_count = 500
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in multimesh.instance_count:
		var dir := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.3, 1), rng.randf_range(-1, 0.2)).normalized()
		multimesh.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * rng.randf_range(0.5, 1.6)), dir * 90.0))
	stars.multimesh = multimesh
	root.add_child(stars)
	var earth := _sphere(40.0, Vector3(0, -52, -30), _mat(Color(0.12, 0.3, 0.7), 0.6))
	(earth.material_override as StandardMaterial3D).emission_enabled = true
	(earth.material_override as StandardMaterial3D).emission = Color(0.05, 0.15, 0.4)
	root.add_child(earth)
	var air := _glow(Color(0.4, 0.7, 1.0), 1.5)
	air.albedo_color.a = 0.25
	air.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	air.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	root.add_child(_sphere(41.5, Vector3(0, -52, -30), air))
	_marker(root, "Rocket_Start", Vector3(-16, 2, 0))
	_marker(root, "Rocket_End", Vector3(16, 9, -8))
	_marker(root, "Reentry_Start", Vector3(1, 7, 2))
	_marker(root, "Reentry_End", Vector3(-1, -9, -2))
	_marker(root, "Cam_Space", Vector3(0, 3, 18))
	return root


# tesla man's victory: a dusty red plain on Mars. He walks from the landed rocket
# (`Rocket`) to `Flag` and plants it; `Winner` is where he ends up.
func _mars() -> Node3D:
	var root := Node3D.new()
	var env := _sky(Color(0.75, 0.55, 0.45), Color(0.95, 0.7, 0.5), Color(0.4, 0.2, 0.12))
	env.fog_enabled = true
	env.fog_light_color = Color(0.85, 0.55, 0.4)
	env.fog_density = 0.012
	root.add_child(_environment(env, 0.8))
	root.add_child(_sun(Vector3(-30, -50, 0), Color(1.0, 0.85, 0.7), 1.2))
	root.add_child(_plane(Vector2(200, 200), Vector3.ZERO, _mat(Color(0.62, 0.3, 0.17), 0.95)))
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in 40:
		var spot := Vector3(rng.randf_range(-40, 40), 0, rng.randf_range(-45, 8))
		if spot.length() < 6.0:
			continue
		var size := rng.randf_range(0.3, 1.6)
		root.add_child(_sphere(size, spot + Vector3(0, size * 0.3, 0), _mat(Color(0.45, 0.22, 0.13), 0.9)))
	for i in 3: # far hills
		root.add_child(_sphere(25.0, Vector3(-60 + 60 * i, -14, -90), _mat(Color(0.55, 0.28, 0.17), 1.0)))
	_marker(root, "Rocket", Vector3(-5, 0, -4))
	_marker(root, "Winner", Vector3(0, 0, 0))
	_marker(root, "Flag", Vector3(1.1, 0, -0.4))
	_marker(root, "Cam_Wide", Vector3(5, 2.4, 8))
	_marker(root, "Cam_Hero", Vector3(1.2, 0.6, 3.2))
	return root


# --- Builders ------------------------------------------------------------------

func _environment(env: Environment, sky_energy: float) -> WorldEnvironment:
	if env.background_mode == Environment.BG_SKY:
		env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		env.ambient_light_energy = maxf(sky_energy, 0.3)
		env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
		env.glow_enabled = true
	var world := WorldEnvironment.new()
	world.environment = env
	return world


func _sky(top: Color, horizon: Color, ground: Color) -> Environment:
	var material := ProceduralSkyMaterial.new()
	material.sky_top_color = top
	material.sky_horizon_color = horizon
	material.ground_horizon_color = horizon.darkened(0.3)
	material.ground_bottom_color = ground
	var sky := Sky.new()
	sky.sky_material = material
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	return env


func _sun(rotation_degrees_: Vector3, color: Color, energy: float) -> DirectionalLight3D:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = rotation_degrees_
	sun.light_color = color
	sun.light_energy = energy
	sun.shadow_enabled = true
	return sun


func _marker(root: Node3D, marker_name: String, position: Vector3, yaw := 0.0) -> void:
	var marker := Marker3D.new()
	marker.name = marker_name
	marker.position = position
	marker.rotation_degrees.y = yaw
	root.add_child(marker)


func _mat(color: Color, roughness: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	return m


func _glow(color: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


func _box(size: Vector3, position: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _instance(mesh, position, material)


func _plane(size: Vector2, position: Vector3, material: Material) -> MeshInstance3D:
	var mesh := PlaneMesh.new()
	mesh.size = size
	return _instance(mesh, position, material)


func _cylinder(radius: float, height: float, position: Vector3, material: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	return _instance(mesh, position, material)


func _sphere(radius: float, position: Vector3, material: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	return _instance(mesh, position, material)


func _instance(mesh: Mesh, position: Vector3, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = position
	node.material_override = material
	return node
