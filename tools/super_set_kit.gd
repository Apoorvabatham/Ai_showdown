extends RefCounted
## Building blocks for stand-in super-scene sets (tools/super_sets/*.gd): sky, sun, plain
## shapes, Marker3D anchors. Static; used by tools/build_super_sets.gd.


static func _environment(env: Environment, sky_energy: float) -> WorldEnvironment:
	if env.background_mode == Environment.BG_SKY:
		env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		env.ambient_light_energy = maxf(sky_energy, 0.3)
		env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
		env.glow_enabled = true
	var world := WorldEnvironment.new()
	world.environment = env
	return world


static func _sky(top: Color, horizon: Color, ground: Color) -> Environment:
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


static func _sun(rotation_degrees_: Vector3, color: Color, energy: float) -> DirectionalLight3D:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = rotation_degrees_
	sun.light_color = color
	sun.light_energy = energy
	sun.shadow_enabled = true
	return sun


static func _marker(root: Node3D, marker_name: String, position: Vector3, yaw := 0.0) -> void:
	var marker := Marker3D.new()
	marker.name = marker_name
	marker.position = position
	marker.rotation_degrees.y = yaw
	root.add_child(marker)


static func _mat(color: Color, roughness: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	return m


static func _glow(color: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


static func _box(size: Vector3, position: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _instance(mesh, position, material)


static func _plane(size: Vector2, position: Vector3, material: Material) -> MeshInstance3D:
	var mesh := PlaneMesh.new()
	mesh.size = size
	return _instance(mesh, position, material)


static func _cylinder(radius: float, height: float, position: Vector3, material: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	return _instance(mesh, position, material)


static func _sphere(radius: float, position: Vector3, material: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	return _instance(mesh, position, material)


static func _instance(mesh: Mesh, position: Vector3, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = position
	node.material_override = material
	return node
