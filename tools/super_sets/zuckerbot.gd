extends RefCounted
## Mark Zuckerbot's stand-in sets: vr_lobby (the goggles shot) and metaverse (the cartoon
## world of the Metaverse Trap super and of his victory).

const K := preload("res://tools/super_set_kit.gd")

const GRID_SHADER := """shader_type spatial;
render_mode unshaded;
uniform vec4 base : source_color = vec4(0.72, 0.9, 0.85, 1.0);
uniform vec4 line : source_color = vec4(1.0, 1.0, 1.0, 1.0);
void fragment() {
	vec2 g = abs(fract(UV * 60.0 - 0.5) - 0.5) / fwidth(UV * 60.0);
	float l = 1.0 - clamp(min(g.x, g.y) - 0.5, 0.0, 1.0);
	ALBEDO = mix(base.rgb, line.rgb, l * 0.85);
}
"""


## Set name -> builder.
static func sets() -> Dictionary:
	return {"vr_lobby": vr_lobby, "metaverse": metaverse}


static func _grid(size: float, base: Color) -> MeshInstance3D:
	var shader := Shader.new()
	shader.code = GRID_SHADER
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("base", base)
	return K._plane(Vector2(size, size), Vector3.ZERO, material)


# The goggles shot: a plain grey room. `Victim` is where the opponent stands (facing +X);
# `Attacker` is Zuckerbot's spot (facing -X, i.e. toward the victim).
static func vr_lobby() -> Node3D:
	var root := Node3D.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.1, 0.11, 0.14)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.58, 0.65)
	root.add_child(K._environment(env, 0.0))
	root.add_child(K._sun(Vector3(-45, -30, 0), Color(1, 1, 1), 1.0))
	root.add_child(K._plane(Vector2(40, 40), Vector3.ZERO, K._mat(Color(0.55, 0.57, 0.62), 0.8)))
	root.add_child(K._box(Vector3(14, 6, 0.3), Vector3(0, 3, -4), K._mat(Color(0.3, 0.32, 0.38), 0.9)))
	K._marker(root, "Victim", Vector3(0.7, 0, 0), 90.0)
	K._marker(root, "Attacker", Vector3(-0.9, 0, 0), -90.0)
	K._marker(root, "Cam_Face", Vector3(0.3, 1.55, 3.2))
	K._marker(root, "Cam_Wide", Vector3(0, 1.4, 4.6))
	return root


# The cartoon metaverse: pastel sky, a grid floor, floating islands with cartoon trees,
# fluffy clouds. `Victim` (facing +X) and `Attacker` (facing -X) stand a metre or so apart
# on the grid; the cameras look at them from the side, from below and from far away.
static func metaverse() -> Node3D:
	var root := Node3D.new()
	var env := K._sky(Color(0.35, 0.6, 1.0), Color(1.0, 0.72, 0.9), Color(0.7, 0.8, 1.0))
	root.add_child(K._environment(env, 0.5))
	env.glow_enabled = false # keep the pastels from bleaching out
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	root.add_child(K._sun(Vector3(-50, -35, 0), Color(1.0, 0.97, 0.9), 1.1))
	root.add_child(_grid(160.0, Color(0.74, 0.92, 0.86)))
	# Floating islands.
	var spots := [Vector3(-9, 3, -10), Vector3(8, 5, -14), Vector3(-17, 7, -22), Vector3(15, 2, -4),
			Vector3(-13, 4, 2), Vector3(3, 9, -26), Vector3(20, 8, -20)]
	var colors := [Color(0.62, 0.95, 0.72), Color(1.0, 0.8, 0.9), Color(0.7, 0.85, 1.0), Color(1.0, 0.95, 0.65)]
	for i in spots.size():
		root.add_child(_island(spots[i], 2.2 + (i % 3) * 0.7, colors[i % colors.size()], i))
	# Clouds.
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in 14:
		var cloud := Node3D.new()
		cloud.position = Vector3(rng.randf_range(-45, 45), rng.randf_range(6, 20), rng.randf_range(-45, -12))
		for j in 3:
			cloud.add_child(K._sphere(rng.randf_range(1.2, 2.2), Vector3(j * 1.6 - 1.6, rng.randf_range(0, 0.5), 0),
					K._glow(Color(1, 1, 1), 1.0)))
		root.add_child(cloud)
	# Giant floating cubes, like old avatars.
	root.add_child(K._box(Vector3(1.4, 1.4, 1.4), Vector3(-5.5, 5.5, -6), K._mat(Color(0.7, 0.8, 1.0), 0.5)))
	root.add_child(K._box(Vector3(1.0, 1.0, 1.0), Vector3(6.5, 4.0, -7), K._mat(Color(1.0, 0.75, 0.85), 0.5)))
	K._marker(root, "Victim", Vector3(0.7, 0, 0), 90.0)
	K._marker(root, "Attacker", Vector3(-0.3, 0, 0), -90.0)
	K._marker(root, "Cam_Welcome", Vector3(-3.0, 1.7, 4.5))
	K._marker(root, "Cam_Side", Vector3(-0.1, 1.3, 3.2))
	K._marker(root, "Cam_Legs", Vector3(0.9, 0.7, 2.6))
	K._marker(root, "Cam_Hit", Vector3(-2.0, 1.5, 1.8))
	K._marker(root, "Cam_Far", Vector3(0, 2.0, 11))
	K._marker(root, "Cam_Hero", Vector3(1.2, 0.7, 3.6))
	return root


static func _island(at: Vector3, radius: float, color: Color, seed_: int) -> Node3D:
	var island := Node3D.new()
	island.position = at
	var top := K._cylinder(radius, 0.4, Vector3.ZERO, K._mat(color, 0.8))
	island.add_child(top)
	var rock := CylinderMesh.new()
	rock.top_radius = radius * 0.95
	rock.bottom_radius = 0.2
	rock.height = radius * 1.4
	rock.radial_segments = 7
	var rock_node := MeshInstance3D.new()
	rock_node.mesh = rock
	rock_node.position = Vector3(0, -radius * 0.7 - 0.2, 0)
	rock_node.material_override = K._mat(Color(0.78, 0.7, 0.9), 0.9)
	island.add_child(rock_node)
	var tree := Node3D.new()
	tree.position = Vector3(radius * 0.3, 0.2, 0)
	tree.add_child(K._cylinder(0.12, 1.2, Vector3(0, 0.6, 0), K._mat(Color(0.75, 0.55, 0.45), 0.9)))
	var leaf_colors := [Color(0.45, 0.88, 0.62), Color(1.0, 0.6, 0.78), Color(0.6, 0.78, 1.0)]
	tree.add_child(K._sphere(0.75, Vector3(0, 1.7, 0), K._mat(leaf_colors[seed_ % 3], 0.7)))
	tree.add_child(K._sphere(0.5, Vector3(0.5, 1.3, 0.2), K._mat(leaf_colors[seed_ % 3].lightened(0.15), 0.7)))
	island.add_child(tree)
	return island
