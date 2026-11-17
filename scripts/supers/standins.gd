class_name SuperStandins
extends RefCounted
## Simple code-built stand-ins for super-scene props, used until OpenCode's real props exist
## (assets/props/supers/, docs/TASKS.md §3.1). They keep the same child names as the
## contract (e.g. the rocket's `Flame` and `ChainPoint`, the truck's `Wheel_*`).


## Angular stainless-steel pickup (our own design, no badge). ~5.6 m long, front = -Z.
static func steel_pickup() -> Node3D:
	var root := Node3D.new()
	root.name = "SteelPickup"
	var steel := metal(Color(0.72, 0.74, 0.76), 0.9, 0.3)
	root.add_child(box(Vector3(2.0, 0.75, 5.6), Vector3(0, 0.85, 0), steel))
	# The wedge roof: a triangular prism along the truck, apex towards the front.
	var roof := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(5.6, 0.95, 1.9)
	prism.left_to_right = 0.38
	roof.mesh = prism
	roof.material_override = steel
	roof.rotation.y = PI * 0.5
	roof.position = Vector3(0, 1.7, 0)
	root.add_child(roof)
	root.add_child(box(Vector3(1.6, 0.35, 0.02), Vector3(0, 1.95, -1.1), metal(Color(0.05, 0.06, 0.08), 0.2, 0.1))) # windscreen
	root.add_child(box(Vector3(2.02, 0.05, 0.05), Vector3(0, 1.15, -2.8), glow(Color(1, 1, 1), 6.0), "Headlights"))
	root.add_child(box(Vector3(2.02, 0.05, 0.05), Vector3(0, 1.15, 2.8), glow(Color(1, 0.1, 0.1), 4.0)))
	for corner in [["Wheel_FL", -1, -1], ["Wheel_FR", 1, -1], ["Wheel_RL", -1, 1], ["Wheel_RR", 1, 1]]:
		var wheel := MeshInstance3D.new()
		wheel.name = corner[0]
		var tyre := CylinderMesh.new()
		tyre.top_radius = 0.45
		tyre.bottom_radius = 0.45
		tyre.height = 0.35
		wheel.mesh = tyre
		wheel.material_override = metal(Color(0.04, 0.04, 0.05), 0.0, 0.8)
		wheel.rotation.z = PI * 0.5
		wheel.position = Vector3(0.95 * corner[1], 0.45, 1.8 * corner[2])
		wheel.add_child(box(Vector3(0.5, 0.36, 0.08), Vector3.ZERO, metal(Color(0.5, 0.5, 0.52), 0.9, 0.3))) # spoke, shows the spin
		root.add_child(wheel)
	return root


## A ~8 m rocket, nose up. `Flame` (hidden until lit) at the nozzle; `ChainPoint` on its +Z
## side, where a fighter is chained with their back to the hull.
static func rocket() -> Node3D:
	var root := Node3D.new()
	root.name = "Rocket"
	var hull := metal(Color(0.9, 0.9, 0.92), 0.4, 0.35)
	var body := MeshInstance3D.new()
	var tube := CylinderMesh.new()
	tube.top_radius = 0.55
	tube.bottom_radius = 0.6
	tube.height = 6.0
	body.mesh = tube
	body.material_override = hull
	body.position.y = 3.6
	root.add_child(body)
	var nose := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.55
	cone.height = 1.8
	nose.mesh = cone
	nose.material_override = hull
	nose.position.y = 7.5
	root.add_child(nose)
	root.add_child(box(Vector3(1.6, 0.04, 0.04), Vector3(0, 6.2, 0), glow(Color(0.2, 0.5, 1.0), 3.0))) # a blue band
	for i in 3:
		var fin := box(Vector3(0.08, 1.2, 0.9), Vector3(0, 1.1, 0), metal(Color(0.2, 0.2, 0.22), 0.6, 0.4))
		fin.position = Vector3(0, 1.1, 0.0) + Vector3(0, 0, 0.75).rotated(Vector3.UP, TAU * i / 3.0)
		fin.rotation.y = TAU * i / 3.0
		root.add_child(fin)
	var flame := flame_node(1.2)
	flame.name = "Flame"
	flame.position.y = 0.4
	flame.visible = false
	root.add_child(flame)
	var chain_point := Marker3D.new()
	chain_point.name = "ChainPoint"
	chain_point.position = Vector3(0, 1.6, 0.85)
	root.add_child(chain_point)
	return root


## A flag on a ~2.5 m pole; `Cloth` carries `text` on both sides.
static func flag(text: String, cloth_color: Color, text_color: Color) -> Node3D:
	var root := Node3D.new()
	root.name = "Flag"
	var pole := MeshInstance3D.new()
	var rod := CylinderMesh.new()
	rod.top_radius = 0.03
	rod.bottom_radius = 0.03
	rod.height = 2.6
	pole.mesh = rod
	pole.material_override = metal(Color(0.8, 0.8, 0.82), 0.9, 0.3)
	pole.position.y = 1.3
	root.add_child(pole)
	var cloth := box(Vector3(1.3, 0.8, 0.02), Vector3(0.68, 2.15, 0), metal(cloth_color, 0.0, 0.8), "Cloth")
	root.add_child(cloth)
	for side in [1.0, -1.0]:
		var label := Label3D.new()
		label.text = text
		label.font_size = 64
		label.pixel_size = 0.004
		label.modulate = text_color
		label.outline_size = 0
		label.position = Vector3(0, 0, 0.012 * side)
		label.rotation.y = 0.0 if side > 0.0 else PI
		cloth.add_child(label)
	return root


## Exhaust: a glowing cone pointing down plus fire and smoke particles.
static func flame_node(size: float) -> Node3D:
	var root := Node3D.new()
	var cone := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.45 * size
	mesh.bottom_radius = 0.0
	mesh.height = 2.2 * size
	cone.mesh = mesh
	cone.material_override = glow(Color(1.0, 0.55, 0.15), 6.0, 0.85)
	cone.position.y = -1.1 * size
	root.add_child(cone)
	var fire := fire_particles(size)
	fire.position.y = -0.6 * size
	root.add_child(fire)
	var smoke := smoke_particles(size * 2.0, 3.0)
	smoke.position.y = -2.0 * size
	root.add_child(smoke)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.6, 0.25)
	light.light_energy = 6.0
	light.omni_range = 10.0
	light.position.y = -1.0
	root.add_child(light)
	return root


## Chains around a fighter's chest and the rocket: two dark steel loops.
static func chains(radius: float, heights: Array, center_z: float) -> Node3D:
	var root := Node3D.new()
	root.name = "Chains"
	for h: float in heights:
		var loop := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = radius
		torus.outer_radius = radius + 0.07
		torus.rings = 24
		loop.mesh = torus
		loop.material_override = metal(Color(0.25, 0.25, 0.27), 1.0, 0.35)
		loop.position = Vector3(0, h, center_z)
		root.add_child(loop)
	return root


static func fire_particles(size: float) -> GPUParticles3D:
	return _particles(Color(1.0, 0.7, 0.2), Color(1.0, 0.15, 0.0), 60, 0.5, 0.5 * size, Vector3.DOWN * 6.0, 0.3 * size, true)


static func smoke_particles(size: float, lifetime: float) -> GPUParticles3D:
	return _particles(Color(0.75, 0.75, 0.75, 0.6), Color(0.3, 0.3, 0.3, 0.0), 50, lifetime, 0.9 * size, Vector3.DOWN * 2.0, 0.8 * size, false)


static func _particles(start: Color, end: Color, amount: int, lifetime: float, quad: float, velocity: Vector3,
		spread_box: float, additive: bool) -> GPUParticles3D:
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3.ONE * spread_box * 0.5
	process.direction = velocity.normalized() if velocity != Vector3.ZERO else Vector3.UP
	process.spread = 25.0
	process.initial_velocity_min = velocity.length() * 0.6
	process.initial_velocity_max = velocity.length()
	process.gravity = Vector3.ZERO
	process.scale_min = 0.6
	process.scale_max = 1.4
	var ramp := Gradient.new()
	ramp.set_color(0, start)
	ramp.set_color(1, end)
	var ramp_texture := GradientTexture1D.new()
	ramp_texture.gradient = ramp
	process.color_ramp = ramp_texture
	var mesh := QuadMesh.new()
	mesh.size = Vector2.ONE * quad
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if additive:
		material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.vertex_color_use_as_albedo = true
	material.albedo_texture = soft_dot()
	mesh.material = material
	var particles := GPUParticles3D.new()
	particles.process_material = process
	particles.draw_pass_1 = mesh
	particles.amount = amount
	particles.lifetime = lifetime
	particles.local_coords = false
	return particles


## A soft round dot (white centre fading out) for particle quads.
static func soft_dot() -> Texture2D:
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 1))
	fade.set_color(1, Color(1, 1, 1, 0))
	var texture := GradientTexture2D.new()
	texture.gradient = fade
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 64
	texture.height = 64
	return texture


static func box(size: Vector3, position: Vector3, material: Material, node_name := "") -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.position = position
	mesh.material_override = material
	if node_name != "":
		mesh.name = node_name
	return mesh


static func metal(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = roughness
	return m


static func glow(color: Color, energy: float, alpha := 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color, alpha)
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	return m
