extends RefCounted
## Donald Tarrif's stand-in set: the office of "Shower of Tariffs" (the super).

const K := preload("res://tools/super_set_kit.gd")


## Set name -> builder.
static func sets() -> Dictionary:
	return {"oval_desk": oval_desk}


# An office: red carpet, wood-panel walls, a big window with a skyline, a giant dark-wood
# desk. The desk top is at y = 1.1. `Attacker` (facing the camera) stands behind the desk,
# `Opponent` is on the desk top, `Stamp` is where the stamp comes down.
static func oval_desk() -> Node3D:
	var root := Node3D.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.45, 0.6, 0.8)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.8, 0.72)
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	root.add_child(K._environment(env, 0.0))
	root.add_child(K._sun(Vector3(-50, 30, 0), Color(1.0, 0.95, 0.85), 0.7))
	var warm := OmniLight3D.new()
	warm.position = Vector3(0, 8, 2)
	warm.omni_range = 30.0
	warm.light_energy = 0.6
	warm.light_color = Color(1.0, 0.9, 0.75)
	root.add_child(warm)
	var wood := K._mat(Color(0.34, 0.2, 0.1), 0.5)
	var panel := K._mat(Color(0.5, 0.33, 0.18), 0.6)
	root.add_child(K._plane(Vector2(26, 20), Vector3(0, 0, -2), K._mat(Color(0.5, 0.08, 0.1), 0.95))) # carpet
	root.add_child(K._plane(Vector2(8, 6), Vector3(0, 0.01, 0), K._mat(Color(0.75, 0.62, 0.25), 0.9))) # a gold rug
	root.add_child(K._box(Vector3(26, 12, 0.4), Vector3(0, 6, -8), panel)) # back wall
	root.add_child(K._box(Vector3(0.4, 12, 20), Vector3(-13, 6, -2), panel))
	root.add_child(K._box(Vector3(0.4, 12, 20), Vector3(13, 6, -2), panel))
	root.add_child(K._box(Vector3(26, 0.4, 20), Vector3(0, 12, -2), K._mat(Color(0.9, 0.88, 0.82), 0.9))) # ceiling
	root.add_child(K._box(Vector3(26, 0.8, 0.2), Vector3(0, 0.4, -7.7), wood)) # skirting
	# The window: sky behind a frame, on the back wall.
	root.add_child(K._box(Vector3(9, 5.5, 0.1), Vector3(0, 6.2, -7.75), K._glow(Color(0.55, 0.75, 1.0), 1.0)))
	root.add_child(K._box(Vector3(0.25, 5.8, 0.25), Vector3(0, 6.2, -7.65), wood))
	root.add_child(K._box(Vector3(9.4, 0.25, 0.25), Vector3(0, 6.2, -7.65), wood))
	root.add_child(K._box(Vector3(9.4, 0.3, 0.3), Vector3(0, 3.35, -7.6), wood))
	root.add_child(K._box(Vector3(9.4, 0.3, 0.3), Vector3(0, 9.05, -7.6), wood))
	root.add_child(K._box(Vector3(0.3, 5.8, 0.3), Vector3(-4.6, 6.2, -7.6), wood))
	root.add_child(K._box(Vector3(0.3, 5.8, 0.3), Vector3(4.6, 6.2, -7.6), wood))
	for i in 6: # a skyline in the window
		var h := 1.2 + (i * 7 % 5) * 0.5
		root.add_child(K._box(Vector3(1.0, h, 0.05), Vector3(-3.5 + i * 1.4, 3.5 + h * 0.5, -7.68), K._mat(Color(0.35, 0.42, 0.55), 1.0)))
	# Curtains either side of the window.
	root.add_child(K._box(Vector3(0.9, 6.2, 0.5), Vector3(-5.6, 6.2, -7.4), K._mat(Color(0.6, 0.08, 0.1), 0.9)))
	root.add_child(K._box(Vector3(0.9, 6.2, 0.5), Vector3(5.6, 6.2, -7.4), K._mat(Color(0.6, 0.08, 0.1), 0.9)))
	# The desk: a big dark-wood slab on two pedestals, top at y = 1.1.
	var dark := K._mat(Color(0.22, 0.11, 0.05), 0.35)
	dark.metallic = 0.15
	root.add_child(K._box(Vector3(6.6, 0.2, 2.6), Vector3(0, 1.0, 0), dark))
	root.add_child(K._box(Vector3(1.6, 0.9, 2.2), Vector3(-2.4, 0.45, 0), dark))
	root.add_child(K._box(Vector3(1.6, 0.9, 2.2), Vector3(2.4, 0.45, 0), dark))
	root.add_child(K._box(Vector3(6.6, 0.9, 0.1), Vector3(0, 0.55, -1.1), dark))
	root.add_child(K._box(Vector3(6.0, 0.02, 2.0), Vector3(0, 1.11, 0), K._mat(Color(0.12, 0.3, 0.2), 0.9))) # a green blotter
	K._marker(root, "Attacker", Vector3(0, 0, -2.9), 180.0)
	K._marker(root, "Opponent", Vector3(0, 1.12, 0.3), 0.0)
	K._marker(root, "Stamp", Vector3(0, 1.12, 0.3))
	K._marker(root, "Cam_Wide", Vector3(0, 4.2, 15.0))
	K._marker(root, "Cam_Desk", Vector3(0.0, 3.0, 4.2))
	K._marker(root, "Cam_Cower", Vector3(0.7, 1.6, 2.6))
	K._marker(root, "Cam_Slam", Vector3(-3.2, 2.2, 5.2))
	return root
