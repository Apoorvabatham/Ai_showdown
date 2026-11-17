class_name StageRetheme
extends Node3D
## Turns an original 3D Fighter stage into an AI Showdown stage: removes the props that
## don't fit and builds new ones from simple shapes (cosmetic only: no collision, nothing
## the simulation reads). Added as a child of the stage root in the AI Showdown stage
## scenes, which inherit the original stages:
##   server_farm.tscn (rooftop): rows of GPU racks with blinking lights, cooling units.
##   mensa.tscn (dojo): a university cafeteria: tiled floor, tables, trays, the counter.
##   senate.tscn (ring): a hearing room: carpet, the committee's dais, a railing.
##   foundry.tscn (market): an advanced semiconductor fabrication cleanroom.

enum Look { SERVER_FARM, MENSA, SENATE, FOUNDRY }

@export var look: Look = Look.SERVER_FARM

var _materials := {}
## Blinking rack lights: [material, base energy, rate, phase].
var _blinkers: Array = []
## Press camera flashes: [light, base energy].
var _flashers: Array = []
var _flash_timer := 0.0
var _time := 0.0


func _ready() -> void:
	match look:
		Look.SERVER_FARM:
			_build_server_farm()
		Look.MENSA:
			_build_mensa()
		Look.SENATE:
			_build_senate()
		Look.FOUNDRY:
			_build_foundry()
	set_process(not _blinkers.is_empty() or not _flashers.is_empty())


func _process(delta: float) -> void:
	_time += delta
	for blinker: Array in _blinkers:
		var on := sin(_time * blinker[2] + blinker[3]) > -0.3
		(blinker[0] as StandardMaterial3D).emission_energy_multiplier = blinker[1] if on else blinker[1] * 0.15
	if not _flashers.is_empty():
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			_flash_timer = randf_range(1.6, 4.2)
			var flasher: Array = _flashers[randi() % _flashers.size()]
			var light: OmniLight3D = flasher[0]
			light.light_energy = flasher[1] * 4.5
			if light.has_meta(&"flash_tween"):
				var prev_tw = light.get_meta(&"flash_tween")
				if is_instance_valid(prev_tw) and prev_tw.is_running():
					prev_tw.kill()
			var tw := create_tween()
			light.set_meta(&"flash_tween", tw)
			tw.tween_property(light, "light_energy", 0.0, 0.14).set_ease(Tween.EASE_OUT)


# --- Server Farm (the rooftop) ---------------------------------------------------------

func _build_server_farm() -> void:
	var stage := get_parent()
	_relabel(stage, "NeonFight", "GPU FARM")
	_relabel(stage, "NeonNight", "ZONE 7")
	# Dark raised-floor panels over the helipad, with glowing aisle markings.
	var floor_mat := _mat(Color(0.2, 0.21, 0.24), 0.35, 0.3)
	_box(Vector3(17.0, 0.02, 9.6), Vector3(0, 0.01, 0.0), floor_mat)
	for x in range(-8, 9, 2):
		_box(Vector3(0.02, 0.025, 9.6), Vector3(x, 0.012, 0.0), _mat(Color(0.06, 0.06, 0.07)))
	for z in [-3.6, 3.6]:
		_box(Vector3(17.0, 0.026, 0.07), Vector3(0, 0.013, z), _glow(Color(0.1, 0.8, 1.0), 2.0))
	# Two rows of racks behind the fighters, a cold aisle between them.
	var led_colors := [Color(0.2, 1.0, 0.4), Color(0.2, 0.6, 1.0), Color(1.0, 0.6, 0.1)]
	var led_mats: Array = []
	for i in 6:
		var m := _glow(led_colors[i % led_colors.size()], 3.0, true)
		_blinkers.append([m, 3.0, 2.0 + i * 1.3, i * 1.7])
		led_mats.append(m)
	var rack_mat := _mat(Color(0.1, 0.1, 0.12), 0.4, 0.6)
	var door_mat := _mat(Color(0.26, 0.28, 0.32), 0.25, 0.7)
	var n := 0
	for row_z in [-5.2, -7.4]:
		for i in 14:
			var x := -7.8 + i * 1.2
			_box(Vector3(1.1, 2.3, 1.0), Vector3(x, 1.15, row_z), rack_mat)
			_box(Vector3(1.0, 2.15, 0.02), Vector3(x, 1.15, row_z + 0.51), door_mat)
			for k in 7:
				var led := Vector3(x - 0.35 + (k % 3) * 0.12, 0.35 + k * 0.27, row_z + 0.53)
				_box(Vector3(0.07, 0.03, 0.01), led, led_mats[(n + k) % led_mats.size()])
			n += 1
		_label("RACK ROW %s" % ("A" if row_z > -6.0 else "B"), Vector3(-8.6, 2.6, row_z + 0.55), 0.18, Color(0.6, 0.9, 1.0))
	# Overhead cable tray along the racks and cooling units at the sides.
	_box(Vector3(17.5, 0.08, 0.5), Vector3(0, 2.75, -5.2), _mat(Color(0.25, 0.26, 0.28), 0.5, 0.7))
	# High-density fiber conduit looms (cyan, caution yellow, amber)
	_box(Vector3(17.5, 0.04, 0.05), Vector3(0, 2.85, -5.35), _mat(Color(0.05, 0.6, 0.9), 0.3))
	_box(Vector3(17.5, 0.04, 0.05), Vector3(0, 2.85, -5.20), _mat(Color(0.9, 0.75, 0.1), 0.3))
	_box(Vector3(17.5, 0.04, 0.05), Vector3(0, 2.85, -5.05), _mat(Color(0.9, 0.35, 0.1), 0.3))
	var beacon_mat := _glow(Color(1.0, 0.6, 0.1), 4.0, true)
	_blinkers.append([beacon_mat, 4.0, 4.0, 0.0])
	for x in [-9.6, 9.6]:
		_cylinder(0.75, 1.8, Vector3(x, 0.9, -3.5), _mat(Color(0.55, 0.57, 0.6), 0.4, 0.6))
		_cylinder(0.6, 0.08, Vector3(x, 1.84, -3.5), _mat(Color(0.1, 0.1, 0.12)))
		# Warning beacon light on top of cooling reservoirs
		_cylinder(0.12, 0.22, Vector3(x, 1.99, -3.5), beacon_mat)
		_light(Vector3(x, 2.2, -3.5), Color(0.2, 0.75, 1.0), 1.8, 6.0)
		_steam(Vector3(x, 2.15, -3.5))
	# Terminal diagnostic consoles at each flank
	for cx in [-8.4, 8.4]:
		_box(Vector3(0.9, 0.9, 0.6), Vector3(cx, 0.45, -3.6), _mat(Color(0.18, 0.2, 0.22), 0.4, 0.5))
		_box(Vector3(0.55, 0.35, 0.04), Vector3(cx, 1.15, -3.5), _mat(Color(0.08, 0.08, 0.1), 0.2))
		_box(Vector3(0.5, 0.3, 0.01), Vector3(cx, 1.15, -3.47), _glow(Color(0.1, 0.85, 0.95), 2.2))
		_label("NODE STATUS: 99.8%%\nTEMP: 62°C NOMINAL", Vector3(cx, 1.15, -3.45), 0.065, Color(0.9, 1.0, 1.0))
	_label("WARNING: LIQUID COOLING\nDO NOT FIGHT NEAR THE RACKS", Vector3(5.5, 2.6, -4.65), 0.13, Color(1.0, 0.85, 0.2), true)
	_light(Vector3(0, 3.2, -3.8), Color(0.55, 0.8, 1.0), 2.8, 10.0)
	_light(Vector3(-5.0, 2.8, -2.5), Color(0.2, 0.7, 1.0), 1.5, 7.0)
	_light(Vector3(5.0, 2.8, -2.5), Color(0.15, 0.85, 0.7), 1.5, 7.0)


# --- Mensa (the dojo) ------------------------------------------------------------------

func _build_mensa() -> void:
	var stage := get_parent()
	for name in ["ScrollKanji", "ScrollSeal", "TaikoDrum", "TaikoSkin1", "TaikoSkin2", "Students0", "Students1", "Students3",
			"IncenseSmoke", "Lantern00", "Lantern01", "Lantern10", "Lantern11"]:
		_remove(stage, name)
	# Linoleum tiles over the tatami.
	var tiles := StandardMaterial3D.new()
	tiles.albedo_texture = _checker(Color(0.62, 0.6, 0.55), Color(0.55, 0.56, 0.54))
	tiles.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	tiles.uv1_scale = Vector3(44, 36, 1)
	tiles.roughness = 0.45
	_box(Vector3(22.0, 0.02, 18.0), Vector3(0, 0.01, -1.0), tiles)
	# The counter along the back wall: steel, a glass sneeze guard, trays of food.
	var steel := _mat(Color(0.7, 0.72, 0.74), 0.3, 0.8)
	_box(Vector3(9.0, 0.95, 0.8), Vector3(0, 0.475, -8.6), steel)
	var glass := _mat(Color(0.8, 0.9, 1.0, 0.25), 0.05)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_box(Vector3(9.0, 0.5, 0.02), Vector3(0, 1.25, -8.25), glass)
	var foods := [Color(0.85, 0.3, 0.12), Color(0.9, 0.75, 0.25), Color(0.3, 0.55, 0.2), Color(0.55, 0.35, 0.2), Color(0.92, 0.9, 0.85)]
	for i in 10:
		_box(Vector3(0.7, 0.06, 0.45), Vector3(-4.0 + i * 0.9, 0.97, -8.6), _mat(foods[i % foods.size()], 0.6))
	_label("MENSA", Vector3(0, 3.3, -9.7), 1.2, Color(0.95, 0.4, 0.15), true)
	_board("TODAY'S MENU\nPasta Pomodoro ........ 2,80\nVegan Lentil Curry .... 3,10\nCurrywurst & Fries .... 2,50\nAlignment Soup .... ask staff",
		Vector3(-3.6, 2.3, -9.75))
	_board("EXAM SEASON\nFree coffee for anyone\nwho can explain\nbackpropagation", Vector3(3.6, 2.3, -9.75))
	_board("NEURIPS NOTICE\nRegistration full.\nPlease do not spar\nover poster slots.\nCoffee for authors only.", Vector3(-7.5, 2.3, -9.75))
	_board("LOST & FOUND\n1x Quantum State\nAnswers to 'Schrodinger'\nReward: 8x H100 GPU hours", Vector3(7.5, 2.3, -9.75))
	# Espresso machine and mug stacks on the counter
	_box(Vector3(0.65, 0.5, 0.45), Vector3(3.8, 1.2, -8.6), steel)
	_cylinder(0.04, 0.15, Vector3(3.6, 1.15, -8.35), _mat(Color(0.2, 0.2, 0.2), 0.3))
	_cylinder(0.06, 0.18, Vector3(4.0, 1.05, -8.4), _mat(Color(0.95, 0.95, 0.92), 0.3))
	# Long tables with trays at the back and the sides, people having lunch.
	var table_mat := _mat(Color(0.85, 0.83, 0.78), 0.5)
	var chair_colors := [Color(0.9, 0.45, 0.1), Color(0.1, 0.55, 0.6), Color(0.85, 0.75, 0.15)]
	var shirt_colors := [Color(0.2, 0.3, 0.6), Color(0.6, 0.2, 0.2), Color(0.25, 0.5, 0.3), Color(0.5, 0.5, 0.52), Color(0.7, 0.6, 0.3)]
	var lamp_mat := _mat(Color(0.15, 0.16, 0.18), 0.3, 0.7)
	var bulb_mat := _glow(Color(1.0, 0.9, 0.72), 3.5)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for spot: Vector3 in [Vector3(-4.5, 0, -6.0), Vector3(0.0, 0, -6.0), Vector3(4.5, 0, -6.0), Vector3(-7.0, 0, -2.0), Vector3(7.0, 0, -2.0)]:
		_box(Vector3(3.2, 0.05, 1.0), spot + Vector3(0, 0.75, 0), table_mat)
		# Hanging pendant lamp over each table
		_cylinder(0.01, 1.6, spot + Vector3(0, 2.7, 0), lamp_mat)
		_cylinder(0.22, 0.14, spot + Vector3(0, 1.9, 0), lamp_mat)
		_cylinder(0.08, 0.04, spot + Vector3(0, 1.83, 0), bulb_mat)
		_light(spot + Vector3(0, 1.8, 0), Color(1.0, 0.92, 0.75), 1.6, 4.5)
		# Table condiment caddy
		_box(Vector3(0.12, 0.14, 0.12), spot + Vector3(0, 0.82, 0), steel)
		for lx in [-1.45, 1.45]:
			_box(Vector3(0.06, 0.74, 0.8), spot + Vector3(lx, 0.37, 0), steel)
		for k in 4:
			for side in [-1, 1]:
				var seat := spot + Vector3(-1.2 + k * 0.8, 0, side * 0.75)
				_box(Vector3(0.45, 0.05, 0.42), seat + Vector3(0, 0.45, 0), _mat(chair_colors[(k + side + 2) % 3], 0.5))
				_box(Vector3(0.45, 0.45, 0.05), seat + Vector3(0, 0.7, side * 0.21), _mat(chair_colors[(k + side + 2) % 3], 0.5))
				_box(Vector3(0.42, 0.02, 0.3), spot + Vector3(-1.2 + k * 0.8, 0.785, side * 0.25), _mat(Color(0.3, 0.4, 0.55), 0.5))
				_cylinder(0.11, 0.02, spot + Vector3(-1.25 + k * 0.8, 0.8, side * 0.25), _mat(Color(0.95, 0.95, 0.92), 0.3))
				if rng.randf() < 0.55:
					_person(seat + Vector3(0, 0.47, side * 0.05), shirt_colors[rng.randi() % shirt_colors.size()], rng)


	# Tray return trolley and water station at the flank
	_box(Vector3(1.1, 1.4, 0.65), Vector3(-8.8, 0.7, -4.5), steel)
	for ty in [0.4, 0.75, 1.1]:
		_box(Vector3(0.9, 0.03, 0.5), Vector3(-8.8, ty, -4.5), _mat(Color(0.2, 0.25, 0.35)))
	_cylinder(0.14, 0.45, Vector3(-8.8, 1.55, -4.5), _mat(Color(0.85, 0.9, 0.95, 0.6), 0.1))
	for cy in 3:
		_cylinder(0.05, 0.1, Vector3(-8.5, 1.48 + cy * 0.06, -4.4), _mat(Color(0.95, 0.95, 0.9)))
	_ambience("res://assets/audio/ambience/market_chatter.ogg", -20.0)


# --- Senate Hearing Room (the ring) ----------------------------------------------------

func _build_senate() -> void:
	var stage := get_parent()
	var ring := stage.get_node_or_null("BoxingRing")
	if ring:
		for child in ring.get_children():
			if child.name.begins_with("Rope_") or child.name.begins_with("Corner_") or child.name.begins_with("Step_") \
					or child.name in ["LogoDisc", "LogoText"]:
				child.queue_free()
		var canvas := ring.get_node_or_null("Canvas") as MeshInstance3D
		if canvas:
			canvas.material_override = _mat(Color(0.1, 0.13, 0.32), 0.9)
		var apron := ring.get_node_or_null("Apron") as MeshInstance3D
		if apron:
			apron.material_override = _mat(Color(0.32, 0.18, 0.09), 0.5)
		var banners := ["HEARING ON AI OVERSIGHT", "PLEASE REMAIN SEATED", "NO PHOTOGRAPHY (PLEASE)", "TESTIMONY IN PROGRESS"]
		for i in 4:
			var banner := ring.get_node_or_null("ApronBanner%d" % i) as Label3D
			if banner:
				banner.text = banners[i]
	# The committee's emblem woven into the carpet (made up: not any real seal).
	_cylinder(1.25, 0.012, Vector3(0, 0.006, 0), _mat(Color(0.75, 0.6, 0.25), 0.6))
	_cylinder(1.12, 0.014, Vector3(0, 0.007, 0), _mat(Color(0.1, 0.13, 0.32), 0.9))
	var emblem := _label("COMMITTEE\nON AI", Vector3(0, 0.02, 0), 0.26, Color(0.85, 0.7, 0.3))
	emblem.rotation = Vector3(-PI / 2, 0, 0)
	# Wooden railing round the floor where the ropes were (sides hide from the camera,
	# like the ropes did).
	var wood := _mat(Color(0.35, 0.2, 0.1), 0.45)
	var sides := [[Vector3(0, 0, -4.45), Vector3(9.0, 0.08, 0.1), 0], [Vector3(0, 0, 4.45), Vector3(9.0, 0.08, 0.1), 1],
		[Vector3(-4.45, 0, 0), Vector3(0.1, 0.08, 9.0), 2], [Vector3(4.45, 0, 0), Vector3(0.1, 0.08, 9.0), 3]]
	for side: Array in sides:
		var group := Node3D.new()
		group.add_to_group(&"ring_side_%d" % side[2])
		add_child(group)
		_box(side[1], side[0] + Vector3(0, 0.95, 0), wood, group)
		var along: Vector3 = Vector3(1, 0, 0) if side[1].x > 1.0 else Vector3(0, 0, 1)
		for k in 13:
			_box(Vector3(0.06, 0.92, 0.06), side[0] + along * (-4.2 + k * 0.7) + Vector3(0, 0.46, 0), wood, group)
	# The dais: a long raised desk across the back, nameplates and microphones, the
	# committee's chairs, flags-in-spirit (plain banners) and the title on the wall.
	var desk_wood := _mat(Color(0.3, 0.16, 0.07), 0.4)
	_box(Vector3(14.0, 1.8, 1.2), Vector3(0, -0.1, -7.2), desk_wood)
	_box(Vector3(14.4, 0.08, 1.4), Vector3(0, 0.84, -7.25), _mat(Color(0.22, 0.11, 0.05), 0.35))
	var names := ["SEN. GRAY", "SEN. OKAFOR", "SEN. LINDQVIST", "CHAIR", "SEN. MORALES", "SEN. PATEL", "SEN. BROOKS"]
	var leather := _mat(Color(0.12, 0.08, 0.06), 0.4)
	for i in names.size():
		var x := -5.4 + i * 1.8
		_box(Vector3(0.8, 0.18, 0.05), Vector3(x, 0.97, -6.6), _mat(Color(0.95, 0.93, 0.88), 0.5))
		_label(names[i], Vector3(x, 0.97, -6.57), 0.09, Color(0.1, 0.1, 0.1))
		_cylinder(0.012, 0.35, Vector3(x + 0.3, 1.05, -6.85), _mat(Color(0.1, 0.1, 0.1), 0.3, 0.8))
		_box(Vector3(0.7, 1.3, 0.25), Vector3(x, 1.05, -8.1), leather)
	# Chairman's brass gavel and solid walnut sound block
	var brass := _mat(Color(0.85, 0.72, 0.32), 0.25, 0.85)
	_box(Vector3(0.24, 0.04, 0.24), Vector3(0.42, 0.90, -6.8), _mat(Color(0.25, 0.12, 0.05), 0.3))
	_cylinder(0.02, 0.26, Vector3(0.42, 0.95, -6.8), _mat(Color(0.3, 0.15, 0.07), 0.3))
	_cylinder(0.035, 0.12, Vector3(0.42, 0.97, -6.7), brass)
	# C-SPAN witness table just outside the railing
	var witness_wood := _mat(Color(0.28, 0.14, 0.06), 0.4)
	_box(Vector3(2.4, 0.85, 0.9), Vector3(0, 0.425, -4.95), witness_wood)
	_box(Vector3(0.65, 0.14, 0.04), Vector3(0, 0.92, -4.55), _mat(Color(0.95, 0.93, 0.88), 0.5))
	_label("WITNESS", Vector3(0, 0.92, -4.52), 0.08, Color(0.1, 0.1, 0.1))
	for mx in [-0.22, 0.22]:
		_cylinder(0.008, 0.30, Vector3(mx, 0.98, -4.8), _mat(Color(0.1, 0.1, 0.1), 0.3, 0.8))
	_cylinder(0.08, 0.22, Vector3(-0.6, 0.95, -4.85), _mat(Color(0.85, 0.92, 1.0, 0.4), 0.05))
	# Stacks of hearing briefing binders
	_box(Vector3(0.32, 0.12, 0.26), Vector3(0.65, 0.91, -4.85), _mat(Color(0.12, 0.2, 0.45), 0.6))
	# Broadcast television cameras on the flank wings with flash lights
	var tally_mat := _glow(Color(1.0, 0.12, 0.12), 4.5)
	var rng_senate := RandomNumberGenerator.new()
	rng_senate.seed = 42
	for cam_x in [-6.4, 6.4]:
		_cylinder(0.025, 1.3, Vector3(cam_x, 0.65, -3.8), _mat(Color(0.2, 0.2, 0.22), 0.4, 0.6))
		_box(Vector3(0.32, 0.35, 0.55), Vector3(cam_x, 1.45, -3.8), _mat(Color(0.1, 0.1, 0.12), 0.3, 0.5))
		_cylinder(0.09, 0.32, Vector3(cam_x, 1.45, -3.45), _mat(Color(0.05, 0.05, 0.06), 0.2, 0.8))
		_cylinder(0.03, 0.05, Vector3(cam_x, 1.66, -3.7), tally_mat)
		# Camera operator standing behind the rig
		_person(Vector3(cam_x, 0.0, -4.25), Color(0.12, 0.12, 0.14), rng_senate)
		# C-SPAN camera flash unit
		var flash_light := OmniLight3D.new()
		flash_light.position = Vector3(cam_x, 1.8, -3.3)
		flash_light.light_color = Color(0.9, 0.95, 1.0)
		flash_light.light_energy = 0.0
		flash_light.omni_range = 6.0
		add_child(flash_light)
		_flashers.append([flash_light, 3.5])
	# Flanking public gallery benches with observers and aides
	var bench_wood := _mat(Color(0.32, 0.16, 0.08), 0.45)
	for gx in [-7.2, 7.2]:
		for gz in [-1.5, 0.5, 2.5]:
			_box(Vector3(1.4, 0.48, 0.42), Vector3(gx, 0.24, gz), bench_wood)
			_box(Vector3(1.4, 0.45, 0.05), Vector3(gx, 0.65, gz - 0.2), bench_wood)
			_person(Vector3(gx - 0.35, 0.26, gz), Color(0.15, 0.16, 0.22), rng_senate)
			_person(Vector3(gx + 0.35, 0.26, gz), Color(0.25, 0.25, 0.28), rng_senate)
	_box(Vector3(16.0, 5.0, 0.2), Vector3(0, 1.5, -9.0), _mat(Color(0.7, 0.64, 0.54), 0.8))
	for x in [-7.0, -5.6, 5.6, 7.0]:
		_box(Vector3(0.9, 3.0, 0.04), Vector3(x, 2.2, -8.85), _mat(Color(0.12, 0.18, 0.45) if absf(x) > 6.0 else Color(0.6, 0.1, 0.12), 0.8))
	_label("SUBCOMMITTEE ON ARTIFICIAL INTELLIGENCE", Vector3(0, 3.4, -8.85), 0.36, Color(0.95, 0.78, 0.35), true)
	_light(Vector3(0, 3.0, -5.0), Color(1.0, 0.9, 0.75), 3.0, 10.0)
	_light(Vector3(-5.5, 3.2, -8.5), Color(1.0, 0.88, 0.7), 2.0, 8.0)
	_light(Vector3(5.5, 3.2, -8.5), Color(1.0, 0.88, 0.7), 2.0, 8.0)
	_label("IN SESSION", Vector3(0, 2.75, -8.85), 0.22, Color(0.95, 0.25, 0.2), true)
	_ambience("res://assets/audio/ambience/arena_crowd.ogg", -24.0)


# --- GPU Foundry (the night market) ----------------------------------------------------

func _build_foundry() -> void:
	var stage := get_parent()
	# Strip market props, stalls, street food, vehicles, and audio.
	for node_name in [
		"Jeepney0", "JeepneyRoute0", "JeepneyName0L", "JeepneyName0R",
		"Jeepney1", "JeepneyRoute1", "JeepneyName1L", "JeepneyName1R",
		"Crowd", "GrillSmoke0", "GrillSparks0", "GrillSmoke1", "GrillSparks1",
		"GrillFlicker", "NeonOpen", "NeonCross", "NeonGlow", "Ambience",
		"Sound", "StreetShadows"
	]:
		_remove(stage, node_name)
	for i in 11:
		_remove(stage, "ShopSign%d" % i)
	for i in 6:
		_remove(stage, "StallSign%d" % i)
		_remove(stage, "StallLight%d" % i)

	# 1. High-tech raised cleanroom airflow floor over the street asphalt.
	var floor_mat := _mat(Color(0.85, 0.87, 0.90), 0.25, 0.15)
	_box(Vector3(18.0, 0.02, 10.0), Vector3(0, 0.01, 0.0), floor_mat)
	# Floor grid lines (perforated tile boundaries)
	for x in range(-8, 9, 2):
		_box(Vector3(0.02, 0.025, 10.0), Vector3(x, 0.012, 0.0), _mat(Color(0.2, 0.22, 0.25)))
	for z in range(-4, 5, 2):
		_box(Vector3(18.0, 0.025, 0.02), Vector3(0, 0.012, z), _mat(Color(0.2, 0.22, 0.25)))
	# Yellow ESD caution border along the fighting bounds
	for z in [-3.6, 3.6]:
		_box(Vector3(17.0, 0.026, 0.08), Vector3(0, 0.013, z), _glow(Color(0.95, 0.75, 0.1), 2.2))
	for x in [-3.6, 3.6]:
		_box(Vector3(0.08, 0.026, 7.2), Vector3(x, 0.013, 0), _glow(Color(0.95, 0.75, 0.1), 2.2))

	# 2. Cleanroom modular wall partition along the back
	var wall_mat := _mat(Color(0.92, 0.94, 0.96), 0.3, 0.05)
	_box(Vector3(18.0, 4.2, 0.2), Vector3(0, 2.1, -6.0), wall_mat)
	for wx in range(-8, 9, 2):
		_box(Vector3(0.08, 4.2, 0.24), Vector3(wx, 2.1, -6.0), _mat(Color(0.65, 0.68, 0.72), 0.3, 0.8))

	# 3. Centerpiece: Twin EUV Photolithography Scanner & Chamber
	var scanner_mat := _mat(Color(0.12, 0.14, 0.16), 0.35, 0.7)
	_box(Vector3(5.4, 3.2, 1.8), Vector3(0, 1.6, -5.2), scanner_mat)
	_box(Vector3(5.0, 0.1, 1.6), Vector3(0, 3.25, -5.2), _mat(Color(0.3, 0.32, 0.35), 0.2, 0.8))
	# Chamber observation window with UV amber tint
	var glass := _mat(Color(1.0, 0.8, 0.2, 0.45), 0.05)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_box(Vector3(2.4, 1.4, 0.04), Vector3(0, 1.7, -4.28), glass)
	# EUV Laser Core (13.5nm pulsing violet/cyan aperture)
	var euv_core := _glow(Color(0.75, 0.25, 1.0), 5.0, true)
	_blinkers.append([euv_core, 5.0, 3.0, 0.0])
	_box(Vector3(1.2, 0.8, 0.02), Vector3(0, 1.7, -4.4), euv_core)
	# Wafer load port & 300mm silicon wafer disc
	var wafer_mat := _mat(Color(0.15, 0.4, 0.45), 0.1, 0.95)
	_box(Vector3(1.4, 0.8, 0.9), Vector3(0, 0.4, -4.3), _mat(Color(0.2, 0.22, 0.25), 0.4, 0.5))
	_cylinder(0.42, 0.02, Vector3(0, 0.82, -4.3), wafer_mat)

	# 4. AMHS (Automated Material Handling System) Overhead Monorail Track & FOUP pods
	var rail_mat := _mat(Color(0.25, 0.27, 0.3), 0.4, 0.7)
	_box(Vector3(17.5, 0.1, 0.35), Vector3(0, 3.5, -4.2), rail_mat)
	var foup_mat := _mat(Color(0.1, 0.1, 0.12), 0.2, 0.4)
	var foup_led := _glow(Color(0.2, 0.95, 0.35), 3.0)
	for fx in [-6.0, -2.5, 2.5, 6.0]:
		# Carrier clamp hanger
		_box(Vector3(0.08, 0.4, 0.1), Vector3(fx, 3.25, -4.2), rail_mat)
		# FOUP wafer container pod
		_box(Vector3(0.55, 0.45, 0.5), Vector3(fx, 2.9, -4.2), foup_mat)
		_box(Vector3(0.45, 0.04, 0.02), Vector3(fx, 2.9, -3.94), foup_led)

	# 5. Diagnostic consoles & wafer cassette racks on the flanks
	for cx in [-7.2, 7.2]:
		_box(Vector3(1.0, 0.9, 0.7), Vector3(cx, 0.45, -3.6), _mat(Color(0.18, 0.2, 0.22), 0.4, 0.5))
		_box(Vector3(0.7, 0.4, 0.04), Vector3(cx, 1.2, -3.5), _mat(Color(0.08, 0.08, 0.1), 0.2))
		_box(Vector3(0.65, 0.35, 0.01), Vector3(cx, 1.2, -3.47), _glow(Color(0.1, 0.85, 0.95), 2.2))
		_cylinder(0.25, 0.35, Vector3(cx + (0.9 if cx < 0 else -0.9), 0.45, -3.6), _mat(Color(0.3, 0.32, 0.35), 0.4, 0.7))
	_label("NODE: 1.8nm GAAS\nDEFECTS: 0.002/cm²\nYIELD: NOMINAL", Vector3(-7.2, 1.2, -3.45), 0.065, Color(0.9, 1.0, 1.0))
	_label("EUV LASER: 13.5nm\nCHAMBER: ARGON\nPURGE: 100%", Vector3(7.2, 1.2, -3.45), 0.065, Color(0.9, 1.0, 1.0))

	# 6. Cryogenic pipes, liquid argon exhaust steam
	for px in [-8.8, 8.8]:
		_cylinder(0.3, 3.6, Vector3(px, 1.8, -4.8), _mat(Color(0.6, 0.63, 0.67), 0.3, 0.8))
		_steam(Vector3(px, 3.65, -4.8))

	# 7. Bunny-suit technicians (cleanroom spectators)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	for sx in [-7.2, 7.2]:
		_bunny_person(Vector3(sx, 0.0, -4.2), rng)
	for bx in [-3.8, -1.8, 1.8, 3.8]:
		_bunny_person(Vector3(bx, 0.0, -5.6), rng)

	# 8. Satirical cleanroom signage and metrics boards
	_label("GPU FOUNDRY — FAB 4090", Vector3(0, 3.8, -5.9), 0.48, Color(0.25, 0.95, 0.4), true)
	_board("CLEANROOM PROTOCOL (CLASS 1)\n• Full bunny suit mandatory\n• No leather jackets in air shower\n• 3-frame jabs only (vibration < 0.1nm)\n• Scrapped wafers deducted from bonus\n• If laser pulses: continue fighting",
		Vector3(-5.0, 2.3, -5.85))
	_board("FAB 4090 METRICS\n• Process: 1.8nm Hype-FinFET\n• Die Yield: 88.4% (dropping)\n• EUV Uptime: 99.98%\n• Wafer Cost: $42,000 / piece\n• Today's Scrap: 12 wafers (blame P2)",
		Vector3(5.0, 2.3, -5.85))
	_label("DANGER: 13.5nm EUV BEAM\nAUTHORIZED CHIP ARCHITECTS ONLY", Vector3(0, 2.7, -4.28), 0.12, Color(1.0, 0.3, 0.2), true)

	# 9. Cleanroom Lighting
	_light(Vector3(0, 3.4, -3.0), Color(1.0, 0.9, 0.72), 2.8, 10.0)
	_light(Vector3(-5.5, 3.0, -2.5), Color(0.2, 0.8, 1.0), 1.8, 7.0)
	_light(Vector3(5.5, 3.0, -2.5), Color(0.2, 0.8, 1.0), 1.8, 7.0)
	_light(Vector3(0, 1.8, -4.5), Color(0.7, 0.25, 1.0), 2.5, 5.0)

	# 10. Ambient ventilation audio
	_ambience("res://assets/audio/ambience/wind.ogg", -24.0)


# --- Helpers ---------------------------------------------------------------------------

func _steam(pos: Vector3) -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3.UP
	mat.spread = 18.0
	mat.initial_velocity_min = 0.6
	mat.initial_velocity_max = 1.4
	mat.gravity = Vector3(0, 0.05, 0)
	mat.scale_min = 0.25
	mat.scale_max = 0.65
	var grad := Gradient.new()
	grad.set_color(0, Color(0.85, 0.92, 1.0, 0.0))
	grad.add_point(0.25, Color(0.85, 0.92, 1.0, 0.28))
	grad.set_color(1, Color(0.85, 0.92, 1.0, 0.0))
	var ramp := GradientTexture1D.new()
	ramp.gradient = grad
	mat.color_ramp = ramp
	particles.process_material = mat
	particles.amount = 14
	particles.lifetime = 1.8
	var sphere := SphereMesh.new()
	sphere.radius = 0.16
	sphere.height = 0.32
	sphere.radial_segments = 6
	sphere.rings = 3
	var smat := StandardMaterial3D.new()
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smat.albedo_color = Color(0.85, 0.92, 1.0, 0.2)
	sphere.material = smat
	particles.draw_pass_1 = sphere
	particles.position = pos
	add_child(particles)
	return particles

func _mat(color: Color, roughness := 0.7, metallic := 0.0) -> StandardMaterial3D:
	var key := "%s/%s/%s" % [color, roughness, metallic]
	if _materials.has(key):
		return _materials[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	_materials[key] = m
	return m


## An emissive material; `own` = a new one (blinking lights each get theirs).
func _glow(color: Color, energy: float, own := false) -> StandardMaterial3D:
	var key := "glow/%s/%s" % [color, energy]
	if not own and _materials.has(key):
		return _materials[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	if not own:
		_materials[key] = m
	return m


func _box(size: Vector3, position_: Vector3, material: Material, parent: Node3D = self) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _instance(mesh, position_, material, parent)


func _cylinder(radius: float, height: float, position_: Vector3, material: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 24
	return _instance(mesh, position_, material, self)


func _instance(mesh: Mesh, position_: Vector3, material: Material, parent: Node3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.position = position_
	parent.add_child(mi)
	return mi


func _label(text: String, position_: Vector3, size: float, color: Color, glow := false) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position = position_
	label.pixel_size = size / 64.0
	label.font_size = 64
	label.outline_size = 0
	label.modulate = color
	label.shaded = not glow
	label.double_sided = false
	add_child(label)
	return label


func _light(position_: Vector3, color: Color, energy: float, reach: float) -> void:
	var light := OmniLight3D.new()
	light.position = position_
	light.light_color = color
	light.light_energy = energy
	light.omni_range = reach
	add_child(light)


## A menu board on the back wall: a dark panel with chalk-coloured text.
func _board(text: String, position_: Vector3) -> void:
	_box(Vector3(3.0, 1.6, 0.05), position_, _mat(Color(0.08, 0.1, 0.09), 0.9))
	var label := _label(text, position_ + Vector3(0, 0, 0.04), 0.14, Color(0.92, 0.92, 0.85), true)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.width = 1300
	label.autowrap_mode = TextServer.AUTOWRAP_OFF


## A seated diner: a capsule body and a sphere head, in `shirt`.
func _person(seat: Vector3, shirt: Color, rng: RandomNumberGenerator) -> void:
	var body := CapsuleMesh.new()
	body.radius = 0.17
	body.height = 0.62
	_instance(body, seat + Vector3(0, 0.3, 0), _mat(shirt, 0.8), self)
	var head := SphereMesh.new()
	head.radius = 0.11
	head.height = 0.22
	var skins := [Color(0.85, 0.66, 0.52), Color(0.6, 0.42, 0.3), Color(0.4, 0.27, 0.18), Color(0.92, 0.75, 0.62)]
	_instance(head, seat + Vector3(0, 0.74, 0), _mat(skins[rng.randi() % skins.size()], 0.6), self)


## A cleanroom technician in full white bunny suit, hood, and visor goggles.
func _bunny_person(seat: Vector3, rng: RandomNumberGenerator) -> void:
	var suit_mat := _mat(Color(0.96, 0.96, 0.98), 0.4, 0.0)
	var visor_mat := _glow(Color(0.2, 0.8, 1.0) if rng.randf() < 0.5 else Color(1.0, 0.85, 0.2), 2.5)
	var glove_mat := _mat(Color(0.2, 0.35, 0.75), 0.5)

	# Body in bunny suit
	var body := CapsuleMesh.new()
	body.radius = 0.19
	body.height = 0.75
	_instance(body, seat + Vector3(0, 0.42, 0), suit_mat, self)

	# Hooded head
	var head := SphereMesh.new()
	head.radius = 0.14
	head.height = 0.26
	_instance(head, seat + Vector3(0, 0.88, 0), suit_mat, self)

	# Cleanroom visor goggles
	var visor := BoxMesh.new()
	visor.size = Vector3(0.18, 0.06, 0.05)
	_instance(visor, seat + Vector3(0, 0.9, 0.12), visor_mat, self)

	# ESD Nitrile gloves
	for gx in [-0.22, 0.22]:
		var hand := SphereMesh.new()
		hand.radius = 0.05
		hand.height = 0.1
		_instance(hand, seat + Vector3(gx, 0.32, 0.1), glove_mat, self)


func _checker(a: Color, b: Color) -> ImageTexture:
	var image := Image.create(2, 2, false, Image.FORMAT_RGB8)
	image.set_pixel(0, 0, a)
	image.set_pixel(1, 1, a)
	image.set_pixel(1, 0, b)
	image.set_pixel(0, 1, b)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


func _relabel(stage: Node, node_name: String, text: String) -> void:
	var label := stage.get_node_or_null(node_name) as Label3D
	if label:
		label.text = text


func _remove(stage: Node, node_name: String) -> void:
	var node := stage.get_node_or_null(node_name)
	if node:
		node.queue_free()


func _ambience(stream_path: String, volume_db: float) -> void:
	if not ResourceLoader.exists(stream_path):
		return
	var stream: AudioStream = load(stream_path)
	if stream is AudioStreamOggVorbis:
		stream = stream.duplicate()
		(stream as AudioStreamOggVorbis).loop = true
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = &"Ambience"
	player.volume_db = volume_db
	add_child(player)
	player.play()
