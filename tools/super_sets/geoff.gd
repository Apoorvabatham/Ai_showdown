extends RefCounted
## Geoff Hintoff's stand-in set: the 1980s university lecture hall for "I Regret Nothing… Wait" (the super).

const K := preload("res://tools/super_set_kit.gd")


## Set name -> builder.
static func sets() -> Dictionary:
	return {"lecture_hall": lecture_hall}


## 1986 University amphitheatre: oak lecture dais, tiered auditorium benches,
## large green chalkboard with neural net diagrams and gradient descent formulas,
## oak lectern with brass gooseneck microphone and green banker's lamp.
## `Attacker` (Geoff) stands at the podium on the left; `Opponent` stands in front of the chalkboard;
## `Board` is where the neural network diagram comes to life and zaps.
static func lecture_hall() -> Node3D:
	var root := Node3D.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.06, 0.05, 0.04)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.95, 0.86, 0.72)
	env.ambient_light_energy = 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	root.add_child(K._environment(env, 0.0))
	root.add_child(K._sun(Vector3(-40, 25, 0), Color(1.0, 0.92, 0.78), 0.85))

	# Stage spotlights
	var warm_spot := SpotLight3D.new()
	warm_spot.position = Vector3(-3.0, 6.0, 2.5)
	warm_spot.rotation_degrees = Vector3(-65, -15, 0)
	warm_spot.light_energy = 1.4
	warm_spot.light_color = Color(1.0, 0.92, 0.75)
	warm_spot.spot_range = 14.0
	warm_spot.spot_angle = 38.0
	root.add_child(warm_spot)

	var board_spot := SpotLight3D.new()
	board_spot.position = Vector3(0.5, 6.5, 2.0)
	board_spot.rotation_degrees = Vector3(-60, 0, 0)
	board_spot.light_energy = 1.6
	board_spot.light_color = Color(0.95, 0.95, 1.0)
	board_spot.spot_range = 15.0
	board_spot.spot_angle = 48.0
	root.add_child(board_spot)

	# Materials
	var dark_oak := K._mat(Color(0.24, 0.15, 0.09), 0.35)
	dark_oak.metallic = 0.05
	var mahogany := K._mat(Color(0.38, 0.20, 0.11), 0.45)
	var chalkboard_green := K._mat(Color(0.07, 0.15, 0.11), 0.85)
	var chalk_white := K._glow(Color(0.92, 0.95, 0.92), 1.2)
	var brass := K._mat(Color(0.85, 0.72, 0.35), 0.2)
	brass.metallic = 0.8
	var wall_plaster := K._mat(Color(0.28, 0.25, 0.22), 0.7)

	# Main floor & back wall
	root.add_child(K._plane(Vector2(26, 20), Vector3(0, 0, 0), dark_oak))
	root.add_child(K._box(Vector3(26, 12, 0.5), Vector3(0, 6, -5.2), wall_plaster))

	# Raised lecturer's stage / dais
	root.add_child(K._box(Vector3(14, 0.22, 7.5), Vector3(-0.5, 0.11, -1.5), mahogany))
	root.add_child(K._box(Vector3(14.2, 0.04, 7.7), Vector3(-0.5, 0.22, -1.5), K._mat(Color(0.48, 0.26, 0.14), 0.3)))

	# --- The Giant Blackboard ---
	var board_pos := Vector3(0.5, 2.4, -3.2)
	# Oak frame
	root.add_child(K._box(Vector3(9.2, 3.8, 0.12), board_pos, mahogany))
	# Green chalkboard surface
	root.add_child(K._box(Vector3(8.8, 3.4, 0.04), board_pos + Vector3(0, 0, 0.05), chalkboard_green))
	# Chalk ledge / tray
	root.add_child(K._box(Vector3(9.0, 0.08, 0.22), board_pos + Vector3(0, -1.74, 0.1), dark_oak))

	# Blackboard Diagrams & Chalk Text
	var title := Label3D.new()
	title.text = "BACKPROPAGATION (1986)"
	title.font_size = 48
	title.pixel_size = 0.004
	title.modulate = Color(0.95, 0.95, 0.85, 0.9)
	title.outline_modulate = Color(0.05, 0.08, 0.06, 0.8)
	title.position = board_pos + Vector3(0, 1.35, 0.08)
	root.add_child(title)

	var formula1 := Label3D.new()
	formula1.text = "w := w - η (∂Loss / ∂w)"
	formula1.font_size = 40
	formula1.pixel_size = 0.0035
	formula1.modulate = Color(0.85, 0.95, 0.9, 0.85)
	formula1.outline_modulate = Color(0.05, 0.08, 0.06, 0.8)
	formula1.position = board_pos + Vector3(-2.5, -1.2, 0.08)
	root.add_child(formula1)

	var formula2 := Label3D.new()
	formula2.text = "Loss = ½ Σ (y - t)²"
	formula2.font_size = 40
	formula2.pixel_size = 0.0035
	formula2.modulate = Color(0.95, 0.85, 0.6, 0.85)
	formula2.outline_modulate = Color(0.05, 0.08, 0.06, 0.8)
	formula2.position = board_pos + Vector3(2.5, -1.2, 0.08)
	root.add_child(formula2)

	# Chalk neural network diagram on the board:
	# Layer 0 (Input, x = -2.4): 3 nodes
	# Layer 1 (Hidden 1, x = -0.8): 4 nodes
	# Layer 2 (Hidden 2, x = 0.8): 4 nodes
	# Layer 3 (Output, x = 2.4): 2 nodes
	var layer_cols := [
		Color(0.3, 0.8, 1.0),
		Color(1.0, 0.85, 0.3),
		Color(1.0, 0.5, 0.2),
		Color(0.4, 1.0, 0.4)
	]
	var layers := [
		[-0.8, 0.0, 0.8],             # Input 3
		[-1.1, -0.37, 0.37, 1.1],     # Hidden1 4
		[-1.1, -0.37, 0.37, 1.1],     # Hidden2 4
		[-0.5, 0.5]                   # Output 2
	]
	var xs := [-2.2, -0.7, 0.7, 2.2]

	for l in layers.size():
		var lx: float = xs[l]
		var col: Color = layer_cols[l]
		var node_mat := K._glow(col, 1.5)
		for y_off: float in layers[l]:
			var n_pos := board_pos + Vector3(lx, y_off + 0.1, 0.08)
			# Chalk circle node
			root.add_child(K._cylinder(0.12, 0.02, n_pos, node_mat))

	# Connecting lines between adjacent layers (thin chalk bars)
	for l in layers.size() - 1:
		var x1: float = xs[l]
		var x2: float = xs[l + 1]
		var line_mat := K._mat(Color(0.85, 0.9, 0.85, 0.4), 0.9)
		for y1: float in layers[l]:
			for y2: float in layers[l + 1]:
				var p1 := board_pos + Vector3(x1, y1 + 0.1, 0.07)
				var p2 := board_pos + Vector3(x2, y2 + 0.1, 0.07)
				var mid := (p1 + p2) * 0.5
				var diff := p2 - p1
				var bar := K._box(Vector3(0.015, diff.length(), 0.01), mid, line_mat)
				bar.rotation.z = -atan2(diff.x, diff.y)
				root.add_child(bar)

	# --- Academic Podium / Lectern ---
	var podium_pos := Vector3(-3.2, 0.22, 0.2)
	# Wooden base & column
	root.add_child(K._box(Vector3(1.1, 0.12, 0.8), podium_pos + Vector3(0, 0.06, 0), dark_oak))
	root.add_child(K._box(Vector3(0.85, 1.0, 0.65), podium_pos + Vector3(0, 0.62, 0), dark_oak))
	# Slanted desk top
	var top := K._box(Vector3(1.15, 0.08, 0.85), podium_pos + Vector3(0, 1.18, 0), mahogany)
	top.rotation_degrees = Vector3(15, 0, 0)
	root.add_child(top)
	# Brass microphone
	var mic_stem := K._cylinder(0.012, 0.35, podium_pos + Vector3(0.3, 1.35, -0.1), brass)
	mic_stem.rotation_degrees = Vector3(-20, 0, 15)
	root.add_child(mic_stem)
	var mic_head := K._sphere(0.032, podium_pos + Vector3(0.25, 1.52, -0.05), K._mat(Color(0.2, 0.2, 0.2), 0.3))
	root.add_child(mic_head)
	# Green banker's lamp
	var lamp_base := K._cylinder(0.06, 0.18, podium_pos + Vector3(-0.35, 1.28, -0.15), brass)
	root.add_child(lamp_base)
	var lamp_shade := K._cylinder(0.055, 0.16, podium_pos + Vector3(-0.35, 1.38, -0.15), K._glow(Color(0.1, 0.65, 0.3), 1.8))
	lamp_shade.rotation_degrees = Vector3(0, 0, 90)
	root.add_child(lamp_shade)

	# Paper thesis sheets on lectern
	var papers := K._box(Vector3(0.35, 0.015, 0.45), podium_pos + Vector3(0.0, 1.22, 0.02), K._mat(Color(0.96, 0.94, 0.88), 0.9))
	papers.rotation_degrees = Vector3(15, 5, 0)
	root.add_child(papers)

	# --- Tiered Student Seating (Background Auditorium) ---
	for tier in 4:
		var tz := 3.5 + tier * 2.2
		var ty := 0.22 + tier * 0.65
		# Riser step
		root.add_child(K._box(Vector3(18, 0.65, 2.2), Vector3(0, ty - 0.325, tz), wall_plaster))
		# Wooden desk row
		root.add_child(K._box(Vector3(16, 0.08, 0.6), Vector3(0, ty + 0.72, tz - 0.3), dark_oak))
		# Bench seat
		root.add_child(K._box(Vector3(16, 0.06, 0.4), Vector3(0, ty + 0.45, tz + 0.4), mahogany))
		# Desk supports
		for sx in [-6.0, -2.0, 2.0, 6.0]:
			root.add_child(K._cylinder(0.035, 0.72, Vector3(sx, ty + 0.36, tz - 0.3), K._mat(Color(0.15, 0.15, 0.15), 0.4)))

	# --- Markers ---
	# Attacker (Geoff at the podium)
	K._marker(root, "Attacker", podium_pos + Vector3(0.0, 0.0, 0.65), 160.0)
	# Opponent (in front of the blackboard)
	K._marker(root, "Opponent", Vector3(0.5, 0.22, -0.8), 180.0)
	# Board center
	K._marker(root, "Board", board_pos)
	# Podium top
	K._marker(root, "Podium", podium_pos + Vector3(0, 1.2, 0))

	# Cameras
	# Cam_Wide: full establishing view showing Geoff at podium on left, Opponent on right, chalkboard behind
	K._marker(root, "Cam_Wide", Vector3(-1.35, 1.9, 5.2))
	# Cam_Board: medium shot on opponent & chalkboard diagram
	K._marker(root, "Cam_Board", Vector3(0.5, 1.5, 2.4))
	# Cam_Geoff: close-up on Geoff at lectern
	K._marker(root, "Cam_Geoff", Vector3(-2.1, 1.35, 1.9))
	# Cam_Zap: dynamic medium blast shot
	K._marker(root, "Cam_Zap", Vector3(-0.4, 1.6, 3.8))

	return root
