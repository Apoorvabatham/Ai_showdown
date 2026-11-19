extends RefCounted
## AGI (algorithm)'s stand-in set: the giant phone void of "Infinite Scroll" (the super).

const K := preload("res://tools/super_set_kit.gd")


## Set name -> builder.
static func sets() -> Dictionary:
	return {"giant_phone": giant_phone}


## Cyberspace void: dark reflective grid floor, towering monolithic smartphone
## with glowing social media feed cards and engagement metrics,
## optical fiber conduits, floating UI reaction glyphs.
## `Attacker` (AGI) hovers on the left;
## `Opponent` stands in front of the phone, gets sucked inside, and spat out.
static func giant_phone() -> Node3D:
	var root := Node3D.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.02, 0.05)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.7, 0.85, 1.0)
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	root.add_child(K._environment(env, 0.0))
	root.add_child(K._sun(Vector3(-45, 25, 0), Color(0.8, 0.95, 1.0), 0.9))

	# Cyber spotlights
	var spot_agi := SpotLight3D.new()
	spot_agi.position = Vector3(-3.2, 6.5, 2.5)
	spot_agi.rotation_degrees = Vector3(-65, -12, 0)
	spot_agi.light_energy = 1.6
	spot_agi.light_color = Color(0.4, 0.9, 1.0)
	spot_agi.spot_range = 14.0
	spot_agi.spot_angle = 38.0
	root.add_child(spot_agi)

	var spot_phone := SpotLight3D.new()
	spot_phone.position = Vector3(0.5, 8.0, 3.5)
	spot_phone.rotation_degrees = Vector3(-55, 0, 0)
	spot_phone.light_energy = 2.0
	spot_phone.light_color = Color(0.8, 0.6, 1.0)
	spot_phone.spot_range = 16.0
	spot_phone.spot_angle = 52.0
	root.add_child(spot_phone)

	# Materials
	var dark_glass := K._mat(Color(0.06, 0.07, 0.1), 0.2)
	dark_glass.metallic = 0.3
	var titanium := K._mat(Color(0.18, 0.20, 0.25), 0.25)
	titanium.metallic = 0.8
	var screen_black := K._mat(Color(0.01, 0.01, 0.03), 0.5)
	var glow_cyan := K._glow(Color(0.2, 0.95, 0.95), 2.5)
	var glow_magenta := K._glow(Color(1.0, 0.25, 0.65), 2.5)

	# Stage floor & back wall
	root.add_child(K._plane(Vector2(26, 20), Vector3(0, 0, 0), dark_glass))
	root.add_child(K._box(Vector3(26, 14, 0.5), Vector3(0, 7, -5.5), K._mat(Color(0.03, 0.04, 0.07), 0.8)))

	# Raised cyber dais
	root.add_child(K._box(Vector3(14, 0.22, 7.5), Vector3(-0.5, 0.11, -1.5), titanium))
	root.add_child(K._box(Vector3(14.2, 0.04, 0.08), Vector3(-0.5, 0.22, 2.25), glow_cyan))

	# --- The Towering Giant Smartphone ---
	var phone_pos := Vector3(0.5, 5.4, -3.2)
	# Titanium outer body / chassis
	root.add_child(K._box(Vector3(5.4, 10.8, 0.55), phone_pos, titanium))
	# Glossy screen glass
	root.add_child(K._box(Vector3(5.0, 10.2, 0.04), phone_pos + Vector3(0, 0, 0.26), screen_black))

	# Dynamic Island pill at top
	root.add_child(K._box(Vector3(0.9, 0.18, 0.06), phone_pos + Vector3(0, 4.6, 0.28), K._mat(Color(0.01, 0.01, 0.02), 0.1)))

	# Feed Posts on the Screen (vertical social media timeline)
	var post_defs := [
		{"y": 3.0, "color": Color(0.85, 0.2, 0.45), "tag": "#DANCE #VIRAL", "likes": "♥ 4.2M"},
		{"y": 0.8, "color": Color(0.2, 0.75, 1.0), "tag": "#ALGORITHM #AI", "likes": "♥ 1.8M"},
		{"y": -1.4, "color": Color(1.0, 0.55, 0.15), "tag": "#LIFEHACKS", "likes": "♥ 920K"},
		{"y": -3.6, "color": Color(0.65, 0.3, 0.95), "tag": "#DOOMSCROLL", "likes": "♥ 6.5M"},
	]

	for post in post_defs:
		var py: float = post["y"]
		var pcol: Color = post["color"]
		var card_center := phone_pos + Vector3(0, py, 0.28)
		# Post card background / thumbnail
		root.add_child(K._box(Vector3(4.4, 1.8, 0.02), card_center, K._mat(Color(0.08, 0.1, 0.15), 0.6)))
		# Glowing video preview area
		root.add_child(K._box(Vector3(4.1, 1.3, 0.02), card_center + Vector3(0, 0.1, 0.015), K._glow(pcol, 1.4)))
		# Avatar icon circle
		root.add_child(K._cylinder(0.12, 0.03, card_center + Vector3(-1.7, 0.55, 0.03), glow_cyan))
		# Tag label
		var tag := Label3D.new()
		tag.text = post["tag"]
		tag.font_size = 28
		tag.pixel_size = 0.004
		tag.modulate = Color(1.0, 1.0, 1.0, 0.95)
		tag.position = card_center + Vector3(-0.4, 0.55, 0.04)
		root.add_child(tag)
		# Likes label
		var likes := Label3D.new()
		likes.text = post["likes"]
		likes.font_size = 28
		likes.pixel_size = 0.004
		likes.modulate = glow_magenta.albedo_color
		likes.position = card_center + Vector3(1.4, -0.6, 0.04)
		root.add_child(likes)

	# Floating UI glyphs on sides (Heart, Share, Comment)
	var heart := K._sphere(0.22, phone_pos + Vector3(3.2, 2.5, 0.2), glow_magenta)
	root.add_child(heart)
	var comment := K._box(Vector3(0.38, 0.32, 0.1), phone_pos + Vector3(3.2, 1.4, 0.2), glow_cyan)
	root.add_child(comment)
	var share := K._cylinder(0.18, 0.1, phone_pos + Vector3(3.2, 0.3, 0.2), K._glow(Color(1.0, 0.85, 0.2), 2.2))
	root.add_child(share)

	# --- Markers ---
	# Attacker (AGI hovering on the left)
	K._marker(root, "Attacker", Vector3(-3.2, 0.6, 0.5), 160.0)
	# Opponent (in front of the giant phone screen)
	K._marker(root, "Opponent", Vector3(0.5, 0.22, -0.6), 180.0)
	# Phone center
	K._marker(root, "Phone", phone_pos)
	# Screen portal (where opponent is sucked inside)
	K._marker(root, "ScreenPortal", phone_pos + Vector3(0, 0.0, 0.3))

	# Cameras
	# Cam_Wide: full establishing view
	K._marker(root, "Cam_Wide", Vector3(-1.35, 2.4, 5.6))
	# Cam_Suck: medium shot looking up at the phone portal
	K._marker(root, "Cam_Suck", Vector3(0.5, 2.2, 3.2))
	# Cam_Scroll: close-up tracking the phone screen
	K._marker(root, "Cam_Scroll", Vector3(0.5, 4.5, 0.6))
	# Cam_Spat: ejection and crash landing shot
	K._marker(root, "Cam_Spat", Vector3(0.0, 1.6, 4.2))

	return root
