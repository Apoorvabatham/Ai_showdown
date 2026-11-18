extends RefCounted
## Dario Amoday's stand-in set: the neoclassical constitutional hall of "Constitutional Scroll" (the super).

const K := preload("res://tools/super_set_kit.gd")


## Set name -> builder.
static func sets() -> Dictionary:
	return {"constitution_hall": constitution_hall}


# Neoclassical constitutional archive hall: marble rotunda, fluted columns, golden dais,
# warm stately lighting, pedestals with constitutional tablets.
# `Attacker` (facing the opponent) stands on the left of the dais, `Opponent` stands in the center,
# `Scroll` / `Stamp` is where the giant scroll and wax seal stamp appear.
static func constitution_hall() -> Node3D:
	var root := Node3D.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.12, 0.14, 0.18)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.92, 0.88, 0.80)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	root.add_child(K._environment(env, 0.0))
	root.add_child(K._sun(Vector3(-45, 35, 0), Color(1.0, 0.94, 0.82), 0.9))

	# Stately warm hall illumination
	var warm := OmniLight3D.new()
	warm.position = Vector3(0, 9, 2)
	warm.omni_range = 32.0
	warm.light_energy = 0.85
	warm.light_color = Color(1.0, 0.92, 0.78)
	root.add_child(warm)

	var marble := K._mat(Color(0.88, 0.86, 0.82), 0.25)
	marble.metallic = 0.08
	var dark_stone := K._mat(Color(0.18, 0.19, 0.22), 0.35)
	var gold := K._glow(Color(1.0, 0.82, 0.3), 1.2)
	var mahogany := K._mat(Color(0.35, 0.18, 0.1), 0.6)

	# Polished floor and circular golden dais
	root.add_child(K._plane(Vector2(28, 22), Vector3(0, 0, 0), dark_stone))
	root.add_child(K._cylinder(6.5, 0.12, Vector3(0, 0.06, 0), marble))
	root.add_child(K._cylinder(4.8, 0.14, Vector3(0, 0.08, 0), K._mat(Color(0.28, 0.12, 0.12), 0.4))) # dark red center dais
	root.add_child(K._cylinder(4.9, 0.02, Vector3(0, 0.15, 0), gold)) # gold inlaid ring

	# Colonnade of marble pillars in a curved arc behind
	for i in 8:
		var angle := deg_to_rad(-70.0 + i * 20.0)
		var px := sin(angle) * 10.5
		var pz := -cos(angle) * 10.5 + 2.0
		var col := K._cylinder(0.5, 11.0, Vector3(px, 5.5, pz), marble)
		root.add_child(col)
		# Capital and base
		root.add_child(K._box(Vector3(1.3, 0.6, 1.3), Vector3(px, 0.3, pz), marble))
		root.add_child(K._box(Vector3(1.3, 0.6, 1.3), Vector3(px, 10.7, pz), marble))

	# Classical architrave beam above colonnade
	root.add_child(K._box(Vector3(22, 1.2, 2.5), Vector3(0, 11.6, -7.0), marble))

	# Wall panels behind
	root.add_child(K._box(Vector3(26, 13, 0.4), Vector3(0, 6.5, -9.5), mahogany))
	# Stately golden banner on back wall
	root.add_child(K._box(Vector3(7.0, 6.0, 0.1), Vector3(0, 7.0, -9.2), K._mat(Color(0.18, 0.08, 0.08), 0.9)))
	root.add_child(K._box(Vector3(7.2, 0.2, 0.15), Vector3(0, 10.0, -9.18), gold))
	root.add_child(K._box(Vector3(7.2, 0.2, 0.15), Vector3(0, 4.0, -9.18), gold))

	# Decorative pedestals with constitutional books on flanks
	for side: float in [-1.0, 1.0]:
		root.add_child(K._box(Vector3(1.0, 1.4, 1.0), Vector3(5.5 * side, 0.7, -1.0), marble))
		root.add_child(K._box(Vector3(0.6, 0.2, 0.8), Vector3(5.5 * side, 1.5, -1.0), gold))

	# Markers
	K._marker(root, "Attacker", Vector3(-1.4, 0.15, 0.1), 75.0)
	K._marker(root, "Opponent", Vector3(0.5, 0.15, 0.0), -75.0)
	K._marker(root, "Scroll", Vector3(0.5, 1.05, 0.0))
	K._marker(root, "Stamp", Vector3(0.5, 1.05, 0.0))
	K._marker(root, "Cam_Wide", Vector3(0.0, 2.1, 5.5))
	K._marker(root, "Cam_Scroll", Vector3(0.5, 1.5, 3.4))
	K._marker(root, "Cam_Stamp", Vector3(0.4, 1.7, 3.2))
	K._marker(root, "Cam_Wrap", Vector3(0.5, 1.4, 3.2))
	return root
