extends RefCounted
## Xi's stand-in set: xi_plaza (his super: three helpers run in and beat the opponent up).

const K := preload("res://tools/super_set_kit.gd")


static func sets() -> Dictionary:
	return {"xi_plaza": xi_plaza}


## A festive plaza at dusk: red stone floor, red pillars, rows of hanging lanterns.
static func xi_plaza() -> Node3D:
	var root := Node3D.new()
	root.add_child(K._environment(K._sky(Color(0.2, 0.15, 0.35), Color(0.95, 0.5, 0.35), Color(0.2, 0.1, 0.1)), 0.6))
	root.add_child(K._sun(Vector3(-30, 40, 0), Color(1.0, 0.8, 0.65), 0.9))
	root.add_child(K._plane(Vector2(60, 60), Vector3.ZERO, K._mat(Color(0.45, 0.16, 0.12), 0.8)))
	for x in [-8.0, -4.0, 4.0, 8.0]:
		root.add_child(K._cylinder(0.35, 6.0, Vector3(x, 3.0, -6.0), K._mat(Color(0.7, 0.1, 0.08), 0.6)))
	root.add_child(K._box(Vector3(18, 0.6, 1.0), Vector3(0, 6.3, -6.0), K._mat(Color(0.2, 0.12, 0.08), 0.7)))
	for i in 9:
		var lantern := K._sphere(0.35, Vector3(-8 + 2 * i, 4.6, -5.4), K._glow(Color(1.0, 0.3, 0.1), 2.5))
		lantern.scale = Vector3(1, 1.3, 1)
		root.add_child(lantern)
		var glow := OmniLight3D.new()
		glow.light_color = Color(1.0, 0.45, 0.2)
		glow.light_energy = 0.6
		glow.omni_range = 4.0
		glow.position = Vector3(-8 + 2 * i, 4.2, -5.0)
		root.add_child(glow)
	K._marker(root, "Opponent", Vector3(0, 0, 0))
	K._marker(root, "Attacker", Vector3(-2.8, 0, 0.4))
	K._marker(root, "Helper_1_Start", Vector3(-12, 0, 3))
	K._marker(root, "Helper_2_Start", Vector3(12, 0, 3))
	K._marker(root, "Helper_3_Start", Vector3(0, 0, -14))
	K._marker(root, "Cam_Wide", Vector3(0.5, 2.6, 8.5))
	K._marker(root, "Cam_Close", Vector3(2.2, 1.4, 3.2))
	K._marker(root, "Cam_Low", Vector3(-1.0, 0.35, 4.0))
	return root
