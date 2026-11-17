extends RefCounted
## Sundar Pickai's stand-in set: the pastel void around the giant browser window of his
## super "404 Not Found". (His victory plays on the stage itself.)

const K := preload("res://tools/super_set_kit.gd")


## Set name -> builder.
static func sets() -> Dictionary:
	return {"browser_void": browser_void}


# The window (a prop) stands at `Window`, facing +Z; Sundar stands at `Sundar` and types at it.
static func browser_void() -> Node3D:
	var root := Node3D.new()
	root.add_child(K._environment(K._sky(Color(0.12, 0.3, 0.7), Color(0.55, 0.75, 0.95), Color(0.1, 0.2, 0.45)), 0.6))
	root.add_child(K._sun(Vector3(-45, -30, 0), Color(1.0, 0.98, 0.95), 1.1))
	root.add_child(K._plane(Vector2(200, 200), Vector3.ZERO, K._mat(Color(0.22, 0.32, 0.55), 0.5)))
	# Floating primary-coloured cubes: the internet, far away.
	var rng := RandomNumberGenerator.new()
	rng.seed = 404
	var colors := [Color(0.26, 0.52, 0.96), Color(0.92, 0.26, 0.21), Color(0.98, 0.74, 0.02), Color(0.2, 0.66, 0.33)]
	for i in 28:
		var size := rng.randf_range(0.5, 2.2)
		var cube := K._box(Vector3.ONE * size, Vector3(rng.randf_range(-30, 30), rng.randf_range(1, 18), rng.randf_range(-45, -12)), K._mat(colors[i % 4], 0.5))
		cube.rotation = Vector3(rng.randf() * TAU, rng.randf() * TAU, 0.0)
		root.add_child(cube)
	K._marker(root, "Window", Vector3(0, 0, 0))
	K._marker(root, "Sundar", Vector3(-3.3, 0, 1.7), -62.0)
	K._marker(root, "Cam_Wide", Vector3(-1.0, 2.0, 6.2))
	K._marker(root, "Cam_Close", Vector3(0.1, 1.7, 5.0))
	K._marker(root, "Cam_Final", Vector3(0.0, 1.9, 6.2))
	return root
