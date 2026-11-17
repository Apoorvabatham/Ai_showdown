extends RefCounted
## Jensen Wong's stand-in set: a dark keynote stage (big screen, spotlights, glossy floor)
## for "Leather Jacket Tornado" and his victory.

const K := preload("res://tools/super_set_kit.gd")


## Set name -> builder.
static func sets() -> Dictionary:
	return {"keynote_stage": keynote_stage}


# Jensen stands at `Jensen` (left), the opponent at `Victim` (right), the screen behind them.
static func keynote_stage() -> Node3D:
	var root := Node3D.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.01, 0.015, 0.02)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.55, 0.6)
	env.ambient_light_energy = 1.0
	env.glow_enabled = true
	env.glow_intensity = 0.8
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	root.add_child(K._environment(env, 0.0))
	var floor_mat := K._mat(Color(0.16, 0.18, 0.2), 0.35)
	floor_mat.metallic = 0.2
	root.add_child(K._plane(Vector2(60, 40), Vector3.ZERO, floor_mat))
	# The big screen, edged in green light.
	root.add_child(K._box(Vector3(16.6, 7.0, 0.3), Vector3(0, 4.2, -7.1), K._mat(Color(0.02, 0.02, 0.02), 0.4)))
	root.add_child(K._box(Vector3(16.0, 6.4, 0.1), Vector3(0, 4.2, -6.9), K._glow(Color(0.08, 0.2, 0.1), 1.6)))
	root.add_child(K._box(Vector3(16.0, 0.12, 0.2), Vector3(0, 7.5, -6.9), K._glow(Color(0.46, 0.73, 0.0), 4.0)))
	root.add_child(K._box(Vector3(16.0, 0.12, 0.2), Vector3(0, 0.9, -6.9), K._glow(Color(0.46, 0.73, 0.0), 4.0)))
	var title := Label3D.new()
	title.text = "THE MORE YOU BUY,\nTHE MORE YOU SAVE"
	title.font_size = 120
	title.pixel_size = 0.008
	title.modulate = Color(0.55, 0.9, 0.1)
	title.shaded = false
	title.position = Vector3(0, 5.6, -6.8)
	root.add_child(title)
	# A glowing stage edge, truss and spotlights.
	root.add_child(K._box(Vector3(14, 0.2, 0.3), Vector3(0, 0.1, -5.0), K._glow(Color(0.46, 0.73, 0.0), 2.0)))
	root.add_child(K._box(Vector3(18, 0.3, 0.3), Vector3(0, 10.5, -2.0), K._mat(Color(0.12, 0.12, 0.13), 0.5)))
	for i in 3:
		var x := -5.0 + 5.0 * i
		var spot := SpotLight3D.new()
		root.add_child(spot)
		spot.position = Vector3(x, 10.3, -2.0)
		spot.basis = Basis.looking_at(Vector3(x * 0.4, 0.0, 0.0) - spot.position, Vector3.FORWARD)
		spot.spot_range = 20.0
		spot.spot_angle = 22.0
		spot.light_energy = 9.0
		spot.light_color = Color(1.0, 0.97, 0.9)
		spot.shadow_enabled = i == 1
		root.add_child(K._box(Vector3(0.5, 0.4, 0.5), Vector3(x, 10.2, -2.0), K._glow(Color(1, 1, 0.9), 2.0)))
	root.add_child(K._sun(Vector3(-25, 20, 0), Color(0.95, 0.97, 1.0), 0.9)) # front fill
	var rim := OmniLight3D.new()
	rim.position = Vector3(0, 5, -4)
	rim.light_color = Color(0.5, 0.85, 0.2)
	rim.light_energy = 3.0
	rim.omni_range = 16.0
	root.add_child(rim)
	K._marker(root, "Jensen", Vector3(-2.3, 0, 0), -90.0)
	K._marker(root, "Victim", Vector3(2.3, 0, 0), 90.0)
	K._marker(root, "Center", Vector3(1.4, 0, 0))
	K._marker(root, "Cam_Wide", Vector3(0, 2.8, 9.5))
	K._marker(root, "Cam_Low", Vector3(-4.0, 0.7, 6.0))
	K._marker(root, "Cam_Hero", Vector3(1.2, 1.5, 5.0))
	return root
