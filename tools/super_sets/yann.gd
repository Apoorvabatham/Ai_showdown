extends RefCounted
## Yann LeCant's super set: the giant text box / prompt terminal.
## "It's Just Autocomplete" super scene: Opponent is trapped inside a giant prompt text box,
## autocomplete types "you lose", and massive heavy 3D letters plunge down.

const K := preload("res://tools/super_set_kit.gd")


static func sets() -> Dictionary:
	return {"prompt_terminal": prompt_terminal}


static func prompt_terminal() -> Node3D:
	var root := Node3D.new()

	# Cybernetic dark terminal void environment
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.07, 0.11)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.35, 0.45, 0.65)
	env.ambient_light_energy = 1.0
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	root.add_child(K._environment(env, 0.0))

	# Cool key light and top fill
	root.add_child(K._sun(Vector3(-55, 35, 0), Color(0.8, 0.9, 1.0), 1.2))

	# Spotlight on prompt text box & opponent
	var box_light := OmniLight3D.new()
	box_light.position = Vector3(0, 5.0, 0.5)
	box_light.omni_range = 18.0
	box_light.light_energy = 2.2
	box_light.light_color = Color(0.75, 0.88, 1.0)
	root.add_child(box_light)

	# Spotlight on Yann & podium
	var yann_light := OmniLight3D.new()
	yann_light.position = Vector3(-3.2, 3.5, 1.5)
	yann_light.omni_range = 12.0
	yann_light.light_energy = 2.0
	yann_light.light_color = Color(1.0, 0.95, 0.9)
	root.add_child(yann_light)

	# Materials
	var dark_floor := K._mat(Color(0.08, 0.10, 0.14), 0.6)
	var box_bezel := K._mat(Color(0.22, 0.26, 0.35), 0.3)
	box_bezel.metallic = 0.4
	var box_interior := K._mat(Color(0.12, 0.15, 0.22), 0.7)
	var glow_cyan := K._glow(Color(0.25, 0.75, 1.0), 2.2)
	var glow_blue := K._glow(Color(0.2, 0.45, 1.0), 1.5)
	var glow_green := K._glow(Color(0.25, 0.95, 0.55), 2.0)

	# Main floor plane
	root.add_child(K._plane(Vector2(40, 30), Vector3(0, 0, 0), dark_floor))

	# Floor grid lines (cyan glowing strips)
	for x in [-8, -4, 0, 4, 8]:
		root.add_child(K._box(Vector3(0.05, 0.01, 24), Vector3(x, 0.005, 0), glow_blue))
	for z in [-6, -2, 2, 6]:
		root.add_child(K._box(Vector3(24, 0.01, 0.05), Vector3(0, 0.005, z), glow_blue))

	# GIANT 3D PROMPT TEXT BOX
	var box_w := 7.4
	var box_d := 4.4
	var box_h := 0.25
	# Outer bezel borders
	root.add_child(K._box(Vector3(box_w, box_h, 0.2), Vector3(0, box_h * 0.5, -box_d * 0.5), box_bezel)) # back
	root.add_child(K._box(Vector3(box_w, box_h, 0.2), Vector3(0, box_h * 0.5, box_d * 0.5), box_bezel)) # front
	root.add_child(K._box(Vector3(0.2, box_h, box_d), Vector3(-box_w * 0.5, box_h * 0.5, 0), box_bezel)) # left
	root.add_child(K._box(Vector3(0.2, box_h, box_d), Vector3(box_w * 0.5, box_h * 0.5, 0), box_bezel)) # right

	# Glowing border accent trim
	root.add_child(K._box(Vector3(box_w + 0.08, 0.04, 0.06), Vector3(0, box_h + 0.02, -box_d * 0.5), glow_cyan))
	root.add_child(K._box(Vector3(box_w + 0.08, 0.04, 0.06), Vector3(0, box_h + 0.02, box_d * 0.5), glow_cyan))
	root.add_child(K._box(Vector3(0.06, 0.04, box_d + 0.08), Vector3(-box_w * 0.5, box_h + 0.02, 0), glow_cyan))
	root.add_child(K._box(Vector3(0.06, 0.04, box_d + 0.08), Vector3(box_w * 0.5, box_h + 0.02, 0), glow_cyan))

	# Text box sunken floor / interior pad
	root.add_child(K._box(Vector3(box_w - 0.2, 0.1, box_d - 0.2), Vector3(0, 0.05, 0), box_interior))

	# Prompt title / Header tag above the text box
	var header_bar := K._box(Vector3(3.4, 0.35, 0.08), Vector3(-box_w * 0.5 + 1.8, box_h + 0.3, -box_d * 0.5), box_bezel)
	root.add_child(header_bar)
	var header_lbl := Label3D.new()
	header_lbl.text = "PROMPT BUFFER: [AUTOREGRESSIVE]"
	header_lbl.font_size = 28
	header_lbl.pixel_size = 0.004
	header_lbl.modulate = Color(0.3, 0.85, 1.0)
	header_lbl.position = Vector3(0, 0, 0.06)
	header_bar.add_child(header_lbl)

	# Blinking cursor bar inside the text box
	var cursor_bar := K._box(Vector3(0.08, 0.8, 0.04), Vector3(-2.6, 0.5, -1.0), glow_green)
	cursor_bar.name = "BlinkingCursor"
	root.add_child(cursor_bar)

	# Autocomplete suggestion popup floating on the right
	var suggest_box := K._box(Vector3(3.0, 1.3, 0.06), Vector3(1.8, 1.5, -box_d * 0.5 - 0.2), box_interior)
	suggest_box.name = "SuggestBox"
	root.add_child(suggest_box)
	root.add_child(K._box(Vector3(3.04, 0.04, 0.08), Vector3(1.8, 2.17, -box_d * 0.5 - 0.2), glow_cyan))
	var suggest_lbl := Label3D.new()
	suggest_lbl.text = "★ 1. you lose   99.9%\n   2. you win     0.01%\n   3. hallucinate 0.01%"
	suggest_lbl.font_size = 26
	suggest_lbl.pixel_size = 0.0045
	suggest_lbl.modulate = Color(0.9, 0.95, 1.0)
	suggest_lbl.position = Vector3(0, 0, 0.05)
	suggest_box.add_child(suggest_lbl)

	# Yann's academic speaker podium on the left
	var podium_base := K._cylinder(0.6, 0.2, Vector3(-3.2, 0.1, 0), box_bezel)
	root.add_child(podium_base)
	var podium_pillar := K._cylinder(0.2, 0.9, Vector3(-3.2, 0.55, 0.3), box_bezel)
	root.add_child(podium_pillar)
	var podium_top := K._box(Vector3(0.7, 0.08, 0.5), Vector3(-3.2, 1.05, 0.3), box_bezel)
	podium_top.rotation_degrees = Vector3(-15, 0, 0)
	root.add_child(podium_top)
	var podium_trim := K._box(Vector3(0.72, 0.02, 0.04), Vector3(-3.2, 1.1, 0.55), glow_cyan)
	root.add_child(podium_trim)

	# Set markers
	K._marker(root, "Attacker", Vector3(-3.2, 0.0, 0.0), 165.0) # Yann at podium facing camera
	K._marker(root, "Opponent", Vector3(0.0, 0.1, 0.0), -90.0) # Opponent trapped in text box
	K._marker(root, "PromptBox", Vector3(0.0, 0.1, 0.0))
	K._marker(root, "LetterDrop", Vector3(0.0, 6.0, 0.0))

	# Cameras (all targeted relative to set global coords)
	K._marker(root, "Cam_Wide", Vector3(0.0, 3.2, 7.8))
	K._marker(root, "Cam_Opponent", Vector3(0.0, 1.8, 3.6))
	K._marker(root, "Cam_Type", Vector3(0.8, 2.2, 3.6))
	K._marker(root, "Cam_Drop", Vector3(0.0, 1.2, 3.2))
	K._marker(root, "Cam_Pile", Vector3(0.0, 2.4, 5.2))
	K._marker(root, "Cam_Yann", Vector3(-3.2, 1.4, 2.4))

	return root
