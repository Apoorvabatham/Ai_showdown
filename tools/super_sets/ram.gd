extends RefCounted
## Ram Altman's stand-in set: the tech keynote hall of "Scaling Law" (the super).

const K := preload("res://tools/super_set_kit.gd")


## Set name -> builder.
static func sets() -> Dictionary:
	return {"scaling_chart": scaling_chart}


## Keynote amphitheatre: glowing dark grid stage, massive wall-sized OLED chart
## displaying an exponential Scaling Law curve shooting up to infinity,
## sleek aluminum presentation stand with tablet.
## `Attacker` (Ram) stands at the keynote stand on the left;
## `Opponent` stands in front of the chart and rides the curve.
static func scaling_chart() -> Node3D:
	var root := Node3D.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.04, 0.07)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.88, 1.0)
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	root.add_child(K._environment(env, 0.0))
	root.add_child(K._sun(Vector3(-45, 30, 0), Color(0.85, 0.95, 1.0), 0.9))

	# Keynote spotlights
	var spot_ram := SpotLight3D.new()
	spot_ram.position = Vector3(-3.2, 6.5, 2.0)
	spot_ram.rotation_degrees = Vector3(-65, -10, 0)
	spot_ram.light_energy = 1.6
	spot_ram.light_color = Color(0.9, 0.95, 1.0)
	spot_ram.spot_range = 14.0
	spot_ram.spot_angle = 36.0
	root.add_child(spot_ram)

	var spot_chart := SpotLight3D.new()
	spot_chart.position = Vector3(1.0, 7.0, 2.5)
	spot_chart.rotation_degrees = Vector3(-58, 5, 0)
	spot_chart.light_energy = 1.8
	spot_chart.light_color = Color(0.7, 1.0, 0.85)
	spot_chart.spot_range = 16.0
	spot_chart.spot_angle = 50.0
	root.add_child(spot_chart)

	# Materials
	var silicon_floor := K._mat(Color(0.08, 0.09, 0.12), 0.25)
	silicon_floor.metallic = 0.2
	var stage_mat := K._mat(Color(0.12, 0.14, 0.18), 0.35)
	var screen_mat := K._mat(Color(0.02, 0.03, 0.06), 0.7)
	var neon_green := K._glow(Color(0.25, 1.0, 0.5), 2.8)
	var neon_cyan := K._glow(Color(0.2, 0.85, 1.0), 2.5)
	var aluminum := K._mat(Color(0.82, 0.84, 0.88), 0.25)
	aluminum.metallic = 0.85

	# Stage floor & back wall
	root.add_child(K._plane(Vector2(26, 20), Vector3(0, 0, 0), silicon_floor))
	root.add_child(K._box(Vector3(26, 12, 0.5), Vector3(0, 6, -5.2), K._mat(Color(0.05, 0.06, 0.09), 0.8)))

	# Keynote Stage Dais
	root.add_child(K._box(Vector3(14, 0.22, 7.5), Vector3(-0.5, 0.11, -1.5), stage_mat))
	# Glowing edge rim around stage
	root.add_child(K._box(Vector3(14.2, 0.04, 0.08), Vector3(-0.5, 0.22, 2.25), neon_cyan))

	# --- Massive Scaling Chart Screen ---
	var chart_pos := Vector3(0.5, 3.2, -3.2)
	# Aluminum frame
	root.add_child(K._box(Vector3(11.4, 5.8, 0.12), chart_pos, aluminum))
	# Dark OLED display surface
	root.add_child(K._box(Vector3(11.0, 5.4, 0.04), chart_pos + Vector3(0, 0, 0.05), screen_mat))

	# Chart Title & Header
	var chart_title := Label3D.new()
	chart_title.text = "THE SCALING HYPOTHESIS"
	chart_title.font_size = 44
	chart_title.pixel_size = 0.004
	chart_title.modulate = Color(0.4, 1.0, 0.7, 0.95)
	chart_title.outline_modulate = Color(0.02, 0.05, 0.03, 0.9)
	chart_title.position = chart_pos + Vector3(0, 2.3, 0.08)
	root.add_child(chart_title)

	# X-Axis & Label
	var x_axis := K._box(Vector3(9.6, 0.04, 0.02), chart_pos + Vector3(0, -2.1, 0.08), neon_cyan)
	root.add_child(x_axis)
	var x_label := Label3D.new()
	x_label.text = "COMPUTE (FLOPs)  →  10²²  →  10²⁴  →  10²⁶  →  10²⁸  →  $$$$"
	x_label.font_size = 28
	x_label.pixel_size = 0.0035
	x_label.modulate = Color(0.7, 0.9, 1.0, 0.85)
	x_label.position = chart_pos + Vector3(0, -2.4, 0.08)
	root.add_child(x_label)

	# Y-Axis & Label
	var y_axis := K._box(Vector3(0.04, 4.4, 0.02), chart_pos + Vector3(-4.8, 0.1, 0.08), neon_cyan)
	root.add_child(y_axis)
	var y_label := Label3D.new()
	y_label.text = "CAPABILITY / HYPE  →  AGI  →  ASI  →  ∞"
	y_label.font_size = 28
	y_label.pixel_size = 0.0035
	y_label.modulate = Color(0.7, 0.9, 1.0, 0.85)
	y_label.position = chart_pos + Vector3(-4.8, 2.4, 0.08)
	root.add_child(y_label)

	# Logarithmic grid lines (subtle)
	var grid_mat := K._mat(Color(0.2, 0.4, 0.6, 0.25), 0.9)
	for gy in 4:
		var y_val := -1.4 + gy * 0.9
		root.add_child(K._box(Vector3(9.6, 0.015, 0.01), chart_pos + Vector3(0, y_val, 0.07), grid_mat))
	for gx in 5:
		var x_val := -3.6 + gx * 1.8
		root.add_child(K._box(Vector3(0.015, 4.4, 0.01), chart_pos + Vector3(x_val, 0.1, 0.07), grid_mat))

	# The Glowing Exponential Curve (y = e^x on the chart)
	var curve_pts := [
		Vector3(-4.8, -2.0, 0.1),
		Vector3(-3.2, -1.8, 0.1),
		Vector3(-1.6, -1.4, 0.1),
		Vector3(0.0, -0.6, 0.1),
		Vector3(1.6, 0.6, 0.1),
		Vector3(3.0, 2.0, 0.1),
		Vector3(4.2, 3.8, 0.1),
		Vector3(5.2, 5.8, 0.1) # shoots off chart!
	]
	for i in curve_pts.size() - 1:
		var p1: Vector3 = chart_pos + curve_pts[i]
		var p2: Vector3 = chart_pos + curve_pts[i + 1]
		var mid := (p1 + p2) * 0.5
		var diff := p2 - p1
		var seg := K._cylinder(0.06, diff.length(), mid, neon_green)
		var up := Vector3.UP
		if absf(diff.normalized().dot(up)) > 0.95:
			up = Vector3.RIGHT
		seg.basis = Basis.looking_at(diff.normalized(), up) * Basis(Vector3.RIGHT, deg_to_rad(90))
		root.add_child(seg)
		# Glowing node marker at each point
		root.add_child(K._sphere(0.09, p1, neon_green))

	# Final rocket arrow at peak
	var arrow := K._cylinder(0.14, 0.4, chart_pos + curve_pts.back(), K._glow(Color.WHITE, 3.5))
	root.add_child(arrow)

	# --- Keynote Presentation Stand ---
	var podium_pos := Vector3(-3.2, 0.22, 0.2)
	# Aluminum column
	root.add_child(K._box(Vector3(0.5, 1.1, 0.35), podium_pos + Vector3(0, 0.55, 0), aluminum))
	# Slanted glass top
	var stand_top := K._box(Vector3(0.7, 0.04, 0.5), podium_pos + Vector3(0, 1.12, 0), K._mat(Color(0.2, 0.3, 0.4, 0.6), 0.1))
	stand_top.rotation_degrees = Vector3(15, 0, 0)
	root.add_child(stand_top)
	# Glowing iPad / tablet on stand
	var tablet := K._box(Vector3(0.32, 0.015, 0.24), podium_pos + Vector3(0, 1.15, 0), K._glow(Color(0.3, 0.7, 1.0), 1.5))
	tablet.rotation_degrees = Vector3(15, 0, 0)
	root.add_child(tablet)

	# --- Markers ---
	# Attacker (Ram at presentation stand)
	K._marker(root, "Attacker", podium_pos + Vector3(0.0, 0.0, 0.65), 160.0)
	# Opponent (in front of chart at start of curve)
	K._marker(root, "Opponent", Vector3(-1.0, 0.22, -0.6), 180.0)
	# Chart center
	K._marker(root, "Chart", chart_pos)
	# Podium top
	K._marker(root, "Podium", podium_pos + Vector3(0, 1.2, 0))
	# Curve peak (where opponent shoots off)
	K._marker(root, "CurvePeak", chart_pos + curve_pts.back())

	# Cameras
	# Cam_Wide: full establishing view
	K._marker(root, "Cam_Wide", Vector3(-1.35, 1.9, 5.2))
	# Cam_Ride: dynamic shot tracking opponent up the curve
	K._marker(root, "Cam_Ride", Vector3(0.8, 3.2, 3.8))
	# Cam_Ram: close-up on Ram presenting
	K._marker(root, "Cam_Ram", Vector3(-2.1, 1.35, 1.9))
	# Cam_Fall: impact shot as opponent falls
	K._marker(root, "Cam_Fall", Vector3(0.2, 1.6, 4.2))

	return root
