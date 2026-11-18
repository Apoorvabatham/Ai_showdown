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
	# Indoors: no rain falling between the racks (the rooftop's drizzle and rain loop).
	_remove(stage, "Rain")
	_remove(stage, "Sound")
	_ambience("res://assets/audio/ambience/city_traffic.ogg", -26.0)

	# Environment atmosphere pass: cool datacenter night rooftop lighting & volumetric haze
	var we := stage.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if we and we.environment:
		we.environment = we.environment.duplicate()
		we.environment.tonemap_mode = Environment.TONE_MAPPER_ACES
		we.environment.tonemap_exposure = 0.95
		we.environment.glow_enabled = true
		we.environment.glow_bloom = 0.22
		we.environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
		we.environment.adjustment_enabled = true
		we.environment.adjustment_contrast = 1.25
		we.environment.adjustment_saturation = 1.15
		we.environment.volumetric_fog_enabled = true
		we.environment.volumetric_fog_albedo = Color(0.20, 0.40, 0.70)
		we.environment.volumetric_fog_density = 0.006

	# Reflection probe for wet raised floor, metallic racks and LED lights
	var probe := ReflectionProbe.new()
	probe.name = "ServerFarmReflectionProbe"
	probe.size = Vector3(26.0, 8.0, 20.0)
	probe.origin_offset = Vector3(0.0, 2.5, -3.5)
	probe.update_mode = ReflectionProbe.UPDATE_ONCE
	probe.intensity = 0.95
	probe.max_distance = 32.0
	probe.ambient_mode = ReflectionProbe.AMBIENT_COLOR
	probe.ambient_color = Color(0.08, 0.10, 0.15)
	add_child(probe)

	# 1. Dark wet raised-floor panels over the helipad with PBR anti-skid tiles & reflective aisle markings
	var floor_mat := _pbr_texture_mat(
		"res://assets/stage_props/server_farm/Textures/anti_skid_tiles_diff_1k.jpg",
		"res://assets/stage_props/server_farm/Textures/anti_skid_tiles_nor_1k.jpg",
		"res://assets/stage_props/server_farm/Textures/anti_skid_tiles_rough_1k.jpg",
		Vector3(14, 8, 1), 0.25, 0.4)
	_box(Vector3(18.0, 0.02, 10.0), Vector3(0, 0.01, 0.0), floor_mat)
	# Floor grid seams with drainage channels
	for x in range(-8, 9, 2):
		_box(Vector3(0.03, 0.025, 10.0), Vector3(x, 0.012, 0.0), _mat(Color(0.03, 0.03, 0.04), 0.5, 0.8))
	for z in range(-4, 5, 2):
		_box(Vector3(18.0, 0.025, 0.03), Vector3(0, 0.012, z), _mat(Color(0.03, 0.03, 0.04), 0.5, 0.8))
	# High-gloss water puddles on the rooftop floor reflecting LEDs
	var puddle_mat := _mat(Color(0.05, 0.06, 0.08), 0.03, 0.8)
	for pz in [-1.5, 1.2]:
		_box(Vector3(4.5, 0.028, 1.8), Vector3(-3.2, 0.014, pz), puddle_mat)
		_box(Vector3(3.8, 0.028, 2.2), Vector3(3.5, 0.014, pz), puddle_mat)
	# Glowing cold aisle boundary strips
	for z in [-3.6, 3.6]:
		_box(Vector3(17.5, 0.026, 0.08), Vector3(0, 0.013, z), _glow(Color(0.1, 0.85, 1.0), 2.8))
	for x in [-8.5, 8.5]:
		_box(Vector3(0.08, 0.026, 7.2), Vector3(x, 0.013, 0), _glow(Color(1.0, 0.65, 0.1), 2.2))

	# 2. Detailed server racks: 2 rows (Row A and Row B) with 14 racks each
	var led_colors := [Color(0.1, 1.0, 0.3), Color(0.1, 0.7, 1.0), Color(1.0, 0.7, 0.1), Color(0.9, 0.2, 0.8)]
	var led_mats: Array = []
	for i in 8:
		var m := _glow(led_colors[i % led_colors.size()], 3.5, true)
		_blinkers.append([m, 3.5, 2.2 + i * 1.1, i * 1.5])
		led_mats.append(m)
	var rack_mat := _mat(Color(0.07, 0.08, 0.09), 0.35, 0.7)
	var blade_mat := _mat(Color(0.16, 0.17, 0.20), 0.25, 0.8)
	var rail_mat := _mat(Color(0.4, 0.42, 0.45), 0.2, 0.9)
	var n := 0
	for row_z in [-5.2, -7.4]:
		for i in 14:
			var x := -7.8 + i * 1.2
			# Main rack enclosure cabinet
			_box(Vector3(1.1, 2.4, 1.05), Vector3(x, 1.2, row_z), rack_mat)
			# Vertical rack corner rails (brushed metal)
			for rx in [-0.52, 0.52]:
				_box(Vector3(0.05, 2.38, 0.05), Vector3(x + rx, 1.2, row_z + 0.52), rail_mat)
			# Stacked server blade chassis (6 units per rack)
			for b in 6:
				var by := 0.25 + b * 0.36
				_box(Vector3(0.96, 0.32, 0.03), Vector3(x, by, row_z + 0.52), blade_mat)
				# Drive bay arrays and status LEDs on each server blade
				_box(Vector3(0.45, 0.22, 0.01), Vector3(x - 0.22, by, row_z + 0.54), _mat(Color(0.1, 0.11, 0.13), 0.5, 0.5))
				for k in 4:
					var led_pos := Vector3(x + 0.08 + k * 0.09, by, row_z + 0.54)
					_box(Vector3(0.05, 0.025, 0.01), led_pos, led_mats[(n + b * 2 + k) % led_mats.size()])
			# Perforated mesh door frame overlay
			_box(Vector3(1.02, 2.3, 0.01), Vector3(x, 1.2, row_z + 0.55), _mat(Color(0.12, 0.14, 0.16, 0.4), 0.2, 0.6))
			n += 1
		var is_row_a: bool = (row_z > -6.0)
		_label("GPU POD %s — H100 SXM5" % ("A" if is_row_a else "B"), Vector3(-8.6, 2.65, row_z + 0.55), 0.18, Color(0.4, 0.9, 1.0), true)
		if is_row_a: # the back row's copy lined up behind the front one on screen
			_label("ACTIVE COMPUTE // 800Gb/s RoCE", Vector3(5.2, 2.65, row_z + 0.55), 0.14, Color(0.2, 1.0, 0.5), true)

	# 3. Overhead ladder cable trays, conduit looms & inter-rack bridges
	var tray_mat := _mat(Color(0.28, 0.30, 0.33), 0.35, 0.8)
	for row_z in [-5.2, -7.4]:
		# Longitudinal ladder tray
		_box(Vector3(17.8, 0.06, 0.6), Vector3(0, 2.85, row_z), tray_mat)
		for side_x in range(-8, 9, 2):
			_box(Vector3(0.04, 0.07, 0.6), Vector3(side_x, 2.85, row_z), tray_mat)
		# Multi-coloured optical fiber & power cable looms
		_box(Vector3(17.8, 0.04, 0.05), Vector3(0, 2.95, row_z - 0.18), _mat(Color(0.05, 0.7, 1.0), 0.3))
		_box(Vector3(17.8, 0.04, 0.05), Vector3(0, 2.95, row_z - 0.06), _mat(Color(0.95, 0.75, 0.1), 0.3))
		_box(Vector3(17.8, 0.04, 0.05), Vector3(0, 2.95, row_z + 0.06), _mat(Color(0.95, 0.25, 0.1), 0.3))
		_box(Vector3(17.8, 0.04, 0.05), Vector3(0, 2.95, row_z + 0.18), _mat(Color(0.7, 0.1, 0.9), 0.3))
	# Transverse bridge cable trays crossing between Row A and Row B
	for bx in [-5.0, 0.0, 5.0]:
		_box(Vector3(0.5, 0.06, 2.2), Vector3(bx, 2.9, -6.3), tray_mat)
		_box(Vector3(0.08, 0.04, 2.2), Vector3(bx - 0.1, 2.98, -6.3), _mat(Color(0.05, 0.7, 1.0), 0.3))
		_box(Vector3(0.08, 0.04, 2.2), Vector3(bx + 0.1, 2.98, -6.3), _mat(Color(0.95, 0.75, 0.1), 0.3))
		_prop("res://assets/stage_props/server_farm/pipe.glb", Vector3(bx, 2.9, -5.2), Vector3(0, 90, 0), Vector3(1.3, 1.3, 1.3))
		_prop("res://assets/stage_props/server_farm/pipe-bend.glb", Vector3(bx, 2.9, -7.4), Vector3(0, 0, 0), Vector3(1.3, 1.3, 1.3))

	# 4. Heavy rooftop industrial cooling units & multi-plume steam exhaust
	var beacon_amber := _glow(Color(1.0, 0.55, 0.05), 4.5, true)
	var beacon_red := _glow(Color(1.0, 0.1, 0.1), 4.5, true)
	_blinkers.append([beacon_amber, 4.5, 3.5, 0.0])
	_blinkers.append([beacon_red, 4.5, 4.2, 1.5])
	var chiller_mat := _mat(Color(0.35, 0.38, 0.42), 0.35, 0.75)
	var louver_mat := _mat(Color(0.12, 0.13, 0.15), 0.4, 0.6)
	for x in [-9.8, 9.8]:
		_prop("res://assets/stage_props/server_farm/structure-panel.glb", Vector3(x, 1.0, -5.0), Vector3(0, 90 if x < 0 else -90, 0), Vector3(1.6, 1.6, 1.6))
		_prop("res://assets/stage_props/server_farm/floor-panel.glb", Vector3(x, 0.05, -3.5), Vector3.ZERO, Vector3(1.5, 1.0, 1.5))
		# Main chiller housing
		_box(Vector3(1.8, 2.2, 2.2), Vector3(x, 1.1, -3.5), chiller_mat)
		# Intake louvers on chiller sides
		_box(Vector3(0.04, 1.8, 1.8), Vector3(x + (0.92 if x < 0 else -0.92), 1.1, -3.5), louver_mat)
		# Twin top exhaust fan shrouds
		for fz in [-4.1, -2.9]:
			_cylinder(0.48, 0.25, Vector3(x, 2.3, fz), _mat(Color(0.1, 0.11, 0.13), 0.3, 0.8))
			_cylinder(0.42, 0.02, Vector3(x, 2.42, fz), _mat(Color(0.05, 0.05, 0.06), 0.2))
			# Warning strobe beacons
			_cylinder(0.08, 0.18, Vector3(x, 2.52, fz), beacon_amber if fz < -3.5 else beacon_red)
			_light(Vector3(x, 2.8, fz), Color(1.0, 0.6, 0.1) if fz < -3.5 else Color(0.2, 0.8, 1.0), 1.8, 5.0)
			# Active high-pressure steam plume venting from each cooling tower
			_steam(Vector3(x, 2.45, fz))
		# Insulated frost lines wrapping around chiller
		_cylinder(0.18, 2.2, Vector3(x + (0.8 if x < 0 else -0.8), 1.1, -2.2), _mat(Color(0.85, 0.88, 0.92), 0.2, 0.85))

	# 5. Diagnostic monitoring consoles at each flank with real computer screen & workstation models
	for cx in [-8.4, 8.4]:
		_box(Vector3(1.0, 0.9, 0.65), Vector3(cx, 0.45, -3.6), _mat(Color(0.15, 0.16, 0.18), 0.35, 0.5))
		_prop("res://assets/stage_props/server_farm/computer-screen.glb", Vector3(cx, 0.9, -3.5), Vector3(0, 180 if cx < 0 else 0, 0), Vector3(1.2, 1.2, 1.2))
		_box(Vector3(0.55, 0.35, 0.01), Vector3(cx, 1.18, -3.47), _glow(Color(0.1, 0.88, 0.98), 2.5))
		_label("GPU CLUSTER ONLINE\nPUE: 1.09 | CHILLER: 14°C\n40960 CORES SYNCED", Vector3(cx, 1.18, -3.45), 0.065, Color(0.9, 1.0, 1.0))
		# Keyboard & terminal desk accessories
		_box(Vector3(0.4, 0.02, 0.15), Vector3(cx, 0.91, -3.35), _mat(Color(0.08, 0.09, 0.1), 0.4))
	_label("CRITICAL INFRASTRUCTURE\nDO NOT INTERRUPT TRAINING RUN", Vector3(-1.2, 2.05, -4.6), 0.13, Color(1.0, 0.85, 0.2), true)

	# 6. CC0 Infrastructure models: server cabinets, power modules, display wall & barriers
	_prop("res://assets/stage_props/server_farm/container-tall.glb", Vector3(-8.8, 0.0, -6.5), Vector3(0, 90, 0), Vector3(1.4, 1.4, 1.4))
	_prop("res://assets/stage_props/server_farm/container-tall.glb", Vector3(8.8, 0.0, -6.5), Vector3(0, -90, 0), Vector3(1.4, 1.4, 1.4))
	_prop("res://assets/stage_props/server_farm/container-wide.glb", Vector3(-7.5, 0.0, -2.8), Vector3(0, 45, 0), Vector3(1.3, 1.3, 1.3))
	_prop("res://assets/stage_props/server_farm/container-wide.glb", Vector3(7.5, 0.0, -2.8), Vector3(0, -45, 0), Vector3(1.3, 1.3, 1.3))
	_prop("res://assets/stage_props/server_farm/structure-barrier.glb", Vector3(-9.2, 0.0, -0.5), Vector3(0, 90, 0), Vector3(1.4, 1.4, 1.4))
	_prop("res://assets/stage_props/server_farm/structure-barrier.glb", Vector3(9.2, 0.0, -0.5), Vector3(0, -90, 0), Vector3(1.4, 1.4, 1.4))
	_prop("res://assets/stage_props/server_farm/computer-system.glb", Vector3(-6.8, 0.0, -3.8), Vector3(0, 45, 0), Vector3(1.3, 1.3, 1.3))
	_prop("res://assets/stage_props/server_farm/computer-wide.glb", Vector3(6.8, 0.0, -3.8), Vector3(0, -45, 0), Vector3(1.3, 1.3, 1.3))
	_prop("res://assets/stage_props/server_farm/display-wall.glb", Vector3(0.0, 3.2, -7.8), Vector3.ZERO, Vector3(1.8, 1.4, 1.0))

	# 7. Cinematic Stage Lighting
	_light(Vector3(0, 3.4, -3.8), Color(0.65, 0.85, 1.0), 3.2, 12.0)
	_light(Vector3(-5.5, 3.0, -2.5), Color(0.15, 0.75, 1.0), 2.0, 8.0)
	_light(Vector3(5.5, 3.0, -2.5), Color(0.15, 0.85, 0.7), 2.0, 8.0)
	_light(Vector3(0, 1.0, -1.0), Color(0.1, 0.4, 0.8), 1.2, 6.0)


# --- Mensa (the dojo) ------------------------------------------------------------------

func _build_mensa() -> void:
	var stage := get_parent()
	for name in ["ScrollKanji", "ScrollSeal", "TaikoDrum", "TaikoSkin1", "TaikoSkin2", "Students0", "Students1", "Students3",
			"IncenseSmoke", "Lantern00", "Lantern01", "Lantern10", "Lantern11"]:
		_remove(stage, name)

	# Environment atmosphere pass: bright cafeteria lighting and warm indoor fog
	var we := stage.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if we and we.environment:
		we.environment = we.environment.duplicate()
		we.environment.tonemap_mode = Environment.TONE_MAPPER_ACES
		we.environment.tonemap_exposure = 1.05
		we.environment.glow_enabled = true
		we.environment.glow_bloom = 0.14
		we.environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
		we.environment.adjustment_enabled = true
		we.environment.adjustment_contrast = 1.15
		we.environment.adjustment_saturation = 1.10
		we.environment.volumetric_fog_enabled = true
		we.environment.volumetric_fog_albedo = Color(0.95, 0.90, 0.82)
		we.environment.volumetric_fog_density = 0.003
		we.environment.ambient_light_color = Color(0.62, 0.58, 0.52)

	# Reflection probe for realistic linoleum specular floor and cafeteria surfaces
	var probe := ReflectionProbe.new()
	probe.name = "MensaReflectionProbe"
	probe.size = Vector3(26.0, 8.0, 22.0)
	probe.origin_offset = Vector3(0.0, 2.5, -4.0)
	probe.update_mode = ReflectionProbe.UPDATE_ONCE
	probe.intensity = 0.85
	probe.max_distance = 30.0
	probe.ambient_mode = ReflectionProbe.AMBIENT_COLOR
	probe.ambient_color = Color(0.18, 0.17, 0.16)
	add_child(probe)

	# Linoleum / ceramic tiles over the tatami (PBR with normal and roughness maps).
	var tiles: StandardMaterial3D = _pbr_texture_mat(
		"res://assets/stage_props/mensa/textures/floor_tiles_06_diff_1k.jpg",
		"res://assets/stage_props/mensa/textures/floor_tiles_06_nor_1k.jpg",
		"res://assets/stage_props/mensa/textures/floor_tiles_06_rough_1k.jpg",
		Vector3(14, 12, 1), 0.35)
	if tiles.albedo_texture == null:
		tiles.albedo_texture = _checker(Color(0.62, 0.6, 0.55), Color(0.55, 0.56, 0.54))
		tiles.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
		tiles.uv1_scale = Vector3(44, 36, 1)
	_box(Vector3(22.0, 0.02, 18.0), Vector3(0, 0.01, -1.0), tiles)

	# The counter along the back wall: steel, kitchen counter bars, glass sneeze guard, food trays.
	var steel := _mat(Color(0.7, 0.72, 0.74), 0.3, 0.8)
	_box(Vector3(9.0, 0.95, 0.8), Vector3(0, 0.475, -8.6), steel)
	_prop("res://assets/stage_props/mensa/kitchenBar.glb", Vector3(-2.2, 0.0, -8.6), Vector3.ZERO, Vector3(1.6, 1.6, 1.6))
	_prop("res://assets/stage_props/mensa/kitchenBar.glb", Vector3(0.0, 0.0, -8.6), Vector3.ZERO, Vector3(1.6, 1.6, 1.6))
	_prop("res://assets/stage_props/mensa/kitchenBarEnd.glb", Vector3(2.2, 0.0, -8.6), Vector3.ZERO, Vector3(1.6, 1.6, 1.6))
	var glass := _mat(Color(0.8, 0.9, 1.0, 0.25), 0.05)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_box(Vector3(9.0, 0.5, 0.02), Vector3(0, 1.25, -8.25), glass)
	var foods := [Color(0.85, 0.3, 0.12), Color(0.9, 0.75, 0.25), Color(0.3, 0.55, 0.2), Color(0.55, 0.35, 0.2), Color(0.92, 0.9, 0.85)]
	for i in 10:
		_box(Vector3(0.7, 0.06, 0.45), Vector3(-4.0 + i * 0.9, 0.97, -8.6), _mat(foods[i % foods.size()], 0.6))
	# Counter serving plates, coffee cups, and bar stools
	for pi in [-3.5, -1.5, 0.5, 2.5]:
		_prop("res://assets/stage_props/mensa/plate-dinner.glb", Vector3(pi, 1.07, -8.35), Vector3.ZERO, Vector3(0.12, 0.12, 0.12))
		_prop("res://assets/stage_props/mensa/cup-coffee.glb", Vector3(pi + 0.3, 1.04, -8.35), Vector3.ZERO, Vector3(0.08, 0.08, 0.08))
		_prop("res://assets/stage_props/mensa/stoolBar.glb", Vector3(pi, 0.0, -7.5), Vector3.ZERO, Vector3(1.2, 1.2, 1.2))

	_label("MENSA", Vector3(0, 3.3, -9.7), 1.2, Color(0.95, 0.4, 0.15), true)
	_board("TODAY'S MENU\nPasta Pomodoro ........ 2,80\nVegan Lentil Curry .... 3,10\nCurrywurst & Fries .... 2,50\nAlignment Soup .... ask staff",
		Vector3(-3.6, 2.3, -9.75))
	_board("EXAM SEASON\nFree coffee for anyone\nwho can explain\nbackpropagation", Vector3(3.6, 2.3, -9.75))
	_board("NEURIPS NOTICE\nRegistration full.\nPlease do not spar\nover poster slots.\nCoffee for authors only.", Vector3(-7.5, 2.3, -9.75))
	_board("LOST & FOUND\n1x Quantum State\nAnswers to 'Schrodinger'\nReward: 8x H100 GPU hours", Vector3(7.5, 2.3, -9.75))

	# Professional espresso machine and mug stacks on the counter
	_prop("res://assets/stage_props/mensa/kitchenCoffeeMachine.glb", Vector3(3.8, 0.95, -8.5), Vector3(0, 180, 0), Vector3(1.3, 1.3, 1.3))
	_prop("res://assets/stage_props/mensa/cup-coffee.glb", Vector3(3.6, 1.03, -8.35), Vector3.ZERO, Vector3(0.09, 0.09, 0.09))
	_prop("res://assets/stage_props/mensa/cup-coffee.glb", Vector3(4.0, 1.03, -8.4), Vector3.ZERO, Vector3(0.09, 0.09, 0.09))
	# Cafeteria waste bins, indoor potted plants and supply boxes
	_prop("res://assets/stage_props/mensa/trashcan.glb", Vector3(-6.5, 0.0, -8.5), Vector3.ZERO, Vector3(1.4, 1.4, 1.4))
	_prop("res://assets/stage_props/mensa/trashcan.glb", Vector3(6.5, 0.0, -8.5), Vector3.ZERO, Vector3(1.4, 1.4, 1.4))
	_prop("res://assets/stage_props/mensa/pottedPlant.glb", Vector3(-8.2, 0.0, -6.5), Vector3.ZERO, Vector3(1.4, 1.4, 1.4))
	_prop("res://assets/stage_props/mensa/pottedPlant.glb", Vector3(8.2, 0.0, -6.5), Vector3.ZERO, Vector3(1.4, 1.4, 1.4))
	_prop("res://assets/stage_props/mensa/cardboardBoxClosed.glb", Vector3(-8.6, 0.0, -8.2), Vector3(0, 25, 0), Vector3(1.3, 1.3, 1.3))

	# Long tables with trays at the back and the sides, people having lunch.
	var table_mat := _mat(Color(0.85, 0.83, 0.78), 0.5)
	var lamp_mat := _mat(Color(0.15, 0.16, 0.18), 0.3, 0.7)
	var bulb_mat := _glow(Color(1.0, 0.9, 0.72), 3.5)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for spot: Vector3 in [Vector3(-4.5, 0, -6.0), Vector3(0.0, 0, -6.0), Vector3(4.5, 0, -6.0), Vector3(-7.0, 0, -2.0), Vector3(7.0, 0, -2.0)]:
		_box(Vector3(3.2, 0.05, 1.0), spot + Vector3(0, 0.75, 0), table_mat)
		if absf(spot.z) > 4.0:
			_prop("res://assets/stage_props/mensa/table.glb", spot + Vector3(-0.8, 0.0, 0), Vector3.ZERO, Vector3(1.8, 2.3, 1.8))
			_prop("res://assets/stage_props/mensa/table.glb", spot + Vector3(0.8, 0.0, 0), Vector3.ZERO, Vector3(1.8, 2.3, 1.8))
		else:
			_prop("res://assets/stage_props/mensa/tableRound.glb", spot + Vector3(0, 0.27, 0), Vector3.ZERO, Vector3(2.0, 2.0, 2.0))
		# Hanging pendant lamp over each table
		_cylinder(0.01, 1.6, spot + Vector3(0, 2.7, 0), lamp_mat)
		_cylinder(0.22, 0.14, spot + Vector3(0, 1.9, 0), lamp_mat)
		_cylinder(0.08, 0.04, spot + Vector3(0, 1.83, 0), bulb_mat)
		_light(spot + Vector3(0, 1.8, 0), Color(1.0, 0.92, 0.75), 1.6, 4.5)
		# Table condiment caddy with real ketchup and mustard bottles
		_box(Vector3(0.14, 0.06, 0.18), spot + Vector3(0, 0.78, 0), steel)
		_prop("res://assets/stage_props/mensa/bottle-ketchup.glb", spot + Vector3(-0.035, 0.87, 0), Vector3.ZERO, Vector3(0.06, 0.06, 0.06))
		_prop("res://assets/stage_props/mensa/bottle-musterd.glb", spot + Vector3(0.035, 0.87, 0), Vector3.ZERO, Vector3(0.06, 0.06, 0.06))
		for lx in [-1.45, 1.45]:
			_box(Vector3(0.06, 0.74, 0.8), spot + Vector3(lx, 0.37, 0), steel)
		for k in 4:
			for side in [-1, 1]:
				var seat := spot + Vector3(-1.2 + k * 0.8, 0, side * 0.75)
				var chair_model := "res://assets/stage_props/mensa/chair.glb" if (k % 2 == 0) else "res://assets/stage_props/mensa/chairRounded.glb"
				_prop(chair_model, seat, Vector3(0, 0 if side == -1 else 180, 0), Vector3(1.6, 1.6, 1.6))
				# Tray, plate, bowl, and coffee cup on table in front of seat
				_box(Vector3(0.42, 0.02, 0.3), spot + Vector3(-1.2 + k * 0.8, 0.785, side * 0.25), _mat(Color(0.3, 0.4, 0.55), 0.5))
				_prop("res://assets/stage_props/mensa/plate-dinner.glb", spot + Vector3(-1.25 + k * 0.8, 0.89, side * 0.25), Vector3.ZERO, Vector3(0.10, 0.10, 0.10))
				if rng.randf() < 0.6:
					_prop("res://assets/stage_props/mensa/cup-coffee.glb", spot + Vector3(-1.08 + k * 0.8, 0.86, side * 0.32), Vector3.ZERO, Vector3(0.075, 0.075, 0.075))
				if rng.randf() < 0.4:
					_prop("res://assets/stage_props/mensa/bowl.glb", spot + Vector3(-1.38 + k * 0.8, 0.87, side * 0.28), Vector3.ZERO, Vector3(0.08, 0.08, 0.08))
				# (Capsule stand-in diners used to sit here; the stage-life students are the
				# crowd now. The rolls stay so the table settings keep their layout.)
				if rng.randf() < 0.55:
					rng.randi()

	# Tray return trolley and water station at the flank
	_box(Vector3(1.1, 1.4, 0.65), Vector3(-8.8, 0.7, -4.5), steel)
	for ty in [0.4, 0.75, 1.1]:
		_box(Vector3(0.9, 0.03, 0.5), Vector3(-8.8, ty, -4.5), _mat(Color(0.2, 0.25, 0.35)))
		_prop("res://assets/stage_props/mensa/plate.glb", Vector3(-8.8, ty + 0.11, -4.5), Vector3.ZERO, Vector3(0.10, 0.10, 0.10))
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

	# The public gallery in hearing-room clothes (dark suits, a few white shirts) instead of
	# the arena's bright jerseys.
	var crowd := stage.get_node_or_null("Crowd") as Crowd
	if crowd:
		crowd.palette = PackedColorArray([Color(0.06, 0.07, 0.1), Color(0.1, 0.1, 0.12), Color(0.14, 0.12, 0.1),
			Color(0.05, 0.08, 0.16), Color(0.55, 0.55, 0.58), Color(0.2, 0.06, 0.07)])
		if crowd.multimesh:
			crowd._ready() # already built with the arena colors: rebuild

	# Environment atmosphere pass: stately hearing room fog
	var we := stage.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if we and we.environment:
		we.environment = we.environment.duplicate()
		we.environment.tonemap_mode = Environment.TONE_MAPPER_ACES
		we.environment.tonemap_exposure = 0.95
		we.environment.glow_enabled = true
		we.environment.glow_bloom = 0.18
		we.environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
		we.environment.adjustment_enabled = true
		we.environment.adjustment_contrast = 1.20
		we.environment.adjustment_saturation = 1.10
		we.environment.volumetric_fog_enabled = true
		we.environment.volumetric_fog_albedo = Color(0.85, 0.78, 0.65)
		we.environment.volumetric_fog_density = 0.0035

	# Reflection probe for polished mahogany and brass specular reflections
	var probe := ReflectionProbe.new()
	probe.name = "SenateReflectionProbe"
	probe.size = Vector3(22.0, 7.0, 18.0)
	probe.origin_offset = Vector3(0.0, 2.5, -4.0)
	probe.update_mode = ReflectionProbe.UPDATE_ONCE
	probe.intensity = 0.75
	probe.max_distance = 30.0
	probe.ambient_mode = ReflectionProbe.AMBIENT_COLOR
	probe.ambient_color = Color(0.2, 0.16, 0.12)
	add_child(probe)

	# The committee's emblem woven into the carpet (made up: not any real seal).
	_cylinder(1.25, 0.012, Vector3(0, 0.006, 0), _mat(Color(0.75, 0.6, 0.25), 0.6))
	_cylinder(1.12, 0.014, Vector3(0, 0.007, 0), _mat(Color(0.1, 0.13, 0.32), 0.9))
	var emblem := _label("COMMITTEE\nON AI", Vector3(0, 0.02, 0), 0.26, Color(0.85, 0.7, 0.3))
	emblem.rotation = Vector3(-PI / 2, 0, 0)
	# Wooden railing round the floor where the ropes were (sides hide from the camera,
	# like the ropes did).
	var wood := _pbr_texture_mat(
		"res://assets/stage_props/senate/textures/lacquered_cherry_wood_diff_1k.jpg",
		"res://assets/stage_props/senate/textures/lacquered_cherry_wood_nor_1k.jpg",
		"res://assets/stage_props/senate/textures/lacquered_cherry_wood_rough_1k.jpg",
		Vector3(4, 2, 1), 0.35)
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
	var desk_wood := wood
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
		_prop("res://assets/stage_props/senate/chairDesk.glb", Vector3(x, 0.0, -7.8), Vector3.ZERO, Vector3(2.0, 2.0, 2.0))
		_prop("res://assets/stage_props/senate/laptop.glb", Vector3(x - 0.25, 0.88, -6.85), Vector3(0, 180, 0), Vector3(1.1, 1.1, 1.1))
		_prop("res://assets/stage_props/senate/books.glb", Vector3(x + 0.38, 0.88, -6.85), Vector3(0, 90, 0), Vector3(0.9, 0.9, 0.9))
	# Chairman's brass gavel and solid walnut sound block
	var brass := _mat(Color(0.85, 0.72, 0.32), 0.25, 0.85)
	_box(Vector3(0.24, 0.04, 0.24), Vector3(0.42, 0.90, -6.8), _mat(Color(0.25, 0.12, 0.05), 0.3))
	_cylinder(0.02, 0.26, Vector3(0.42, 0.95, -6.8), _mat(Color(0.3, 0.15, 0.07), 0.3))
	_cylinder(0.035, 0.12, Vector3(0.42, 0.97, -6.7), brass)
	# Stately planters flanking the dais
	_prop("res://assets/stage_props/senate/plantSmall1.glb", Vector3(-6.2, 0.85, -6.8), Vector3.ZERO, Vector3(1.4, 1.4, 1.4))
	_prop("res://assets/stage_props/senate/plantSmall1.glb", Vector3(6.2, 0.85, -6.8), Vector3.ZERO, Vector3(1.4, 1.4, 1.4))
	# C-SPAN witness table just outside the railing
	var witness_wood := wood
	_box(Vector3(2.4, 0.85, 0.9), Vector3(0, 0.425, -4.95), witness_wood)
	_box(Vector3(0.65, 0.14, 0.04), Vector3(0, 0.92, -4.55), _mat(Color(0.95, 0.93, 0.88), 0.5))
	_label("WITNESS", Vector3(0, 0.92, -4.52), 0.08, Color(0.1, 0.1, 0.1))
	for mx in [-0.22, 0.22]:
		_cylinder(0.008, 0.30, Vector3(mx, 0.98, -4.8), _mat(Color(0.1, 0.1, 0.1), 0.3, 0.8))
	_cylinder(0.08, 0.22, Vector3(-0.6, 0.95, -4.85), _mat(Color(0.85, 0.92, 1.0, 0.4), 0.05))
	# Brass lamp, witness laptop, legal books and swivel chair
	_prop("res://assets/stage_props/senate/lampRoundTable.glb", Vector3(-0.85, 0.85, -4.85), Vector3.ZERO, Vector3(1.4, 1.4, 1.4))
	_prop("res://assets/stage_props/senate/chairDesk.glb", Vector3(0, 0.0, -5.7), Vector3(0, 180, 0), Vector3(1.8, 1.8, 1.8))
	_prop("res://assets/stage_props/senate/laptop.glb", Vector3(0.35, 0.88, -4.85), Vector3.ZERO, Vector3(1.1, 1.1, 1.1))
	_prop("res://assets/stage_props/senate/books.glb", Vector3(-0.38, 0.88, -4.85), Vector3(0, 45, 0), Vector3(0.9, 0.9, 0.9))
	# Stacks of hearing briefing binders
	_box(Vector3(0.32, 0.12, 0.26), Vector3(0.65, 0.91, -4.85), _mat(Color(0.12, 0.2, 0.45), 0.6))
	# Official stenographer recording station (matching data/stage_life/senate.json pos [-1.8, 0.0, -5.2])
	_prop("res://assets/stage_props/senate/desk.glb", Vector3(-1.8, 0.0, -5.3), Vector3(0, 45, 0), Vector3(1.6, 1.6, 1.6))
	_prop("res://assets/stage_props/senate/chairDesk.glb", Vector3(-1.5, 0.0, -5.6), Vector3(0, 45, 0), Vector3(1.6, 1.6, 1.6))
	_prop("res://assets/stage_props/senate/laptop.glb", Vector3(-1.8, 0.62, -5.3), Vector3(0, 45, 0), Vector3(0.9, 0.9, 0.9))
	_prop("res://assets/stage_props/senate/books.glb", Vector3(-2.1, 0.62, -5.4), Vector3(0, 135, 0), Vector3(0.7, 0.7, 0.7))
	# Committee dais executive wing extensions
	_prop("res://assets/stage_props/senate/deskCorner.glb", Vector3(-7.2, 0.0, -7.5), Vector3(0, 90, 0), Vector3(1.8, 1.8, 1.8))
	_prop("res://assets/stage_props/senate/deskCorner.glb", Vector3(7.2, 0.0, -7.5), Vector3(0, 0, 0), Vector3(1.8, 1.8, 1.8))
	# Stately bookcases on the rear wall
	_prop("res://assets/stage_props/senate/bookcaseClosedWide.glb", Vector3(-6.8, 0.0, -8.7), Vector3.ZERO, Vector3(1.6, 1.6, 1.6))
	_prop("res://assets/stage_props/senate/bookcaseClosedWide.glb", Vector3(6.8, 0.0, -8.7), Vector3.ZERO, Vector3(1.6, 1.6, 1.6))
	_prop("res://assets/stage_props/senate/bookcaseClosed.glb", Vector3(-8.6, 0.0, -8.7), Vector3.ZERO, Vector3(1.6, 1.6, 1.6))
	_prop("res://assets/stage_props/senate/bookcaseClosed.glb", Vector3(8.6, 0.0, -8.7), Vector3.ZERO, Vector3(1.6, 1.6, 1.6))
	_prop("res://assets/stage_props/senate/speakerSmall.glb", Vector3(-6.0, 3.2, -8.8), Vector3(15, 0, 0), Vector3(1.5, 1.5, 1.5))
	_prop("res://assets/stage_props/senate/speakerSmall.glb", Vector3(6.0, 3.2, -8.8), Vector3(15, 0, 0), Vector3(1.5, 1.5, 1.5))
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
	for gx in [-7.2, 7.2]:
		for gz in [-1.5, 0.5, 2.5]:
			_prop("res://assets/stage_props/senate/bench.glb", Vector3(gx, 0.0, gz), Vector3(0, 90 if gx < 0 else -90, 0), Vector3(1.5, 1.5, 1.5))
			_person(Vector3(gx - 0.35, 0.26, gz), Color(0.15, 0.16, 0.22), rng_senate)
			_person(Vector3(gx + 0.35, 0.26, gz), Color(0.25, 0.25, 0.28), rng_senate)
	_box(Vector3(16.0, 5.0, 0.2), Vector3(0, 1.5, -9.0), _mat(Color(0.3, 0.2, 0.14), 0.7)) # dark wood panelling: the gold title reads on it
	for x in [-7.0, -5.6, 5.6, 7.0]:
		_box(Vector3(0.9, 3.0, 0.04), Vector3(x, 2.2, -8.85), _mat(Color(0.12, 0.18, 0.45) if absf(x) > 6.0 else Color(0.6, 0.1, 0.12), 0.8))
	_label("SUBCOMMITTEE ON ARTIFICIAL INTELLIGENCE", Vector3(0, 3.4, -8.85), 0.36, Color(0.95, 0.78, 0.35), true)
	_light(Vector3(0, 3.0, -5.0), Color(1.0, 0.9, 0.75), 3.0, 10.0)
	_light(Vector3(-5.5, 3.2, -8.5), Color(1.0, 0.88, 0.7), 1.3, 8.0)
	_light(Vector3(5.5, 3.2, -8.5), Color(1.0, 0.88, 0.7), 1.3, 8.0)
	_label("IN SESSION", Vector3(0, 2.75, -8.85), 0.22, Color(0.95, 0.25, 0.2), true)
	_ambience("res://assets/audio/ambience/arena_crowd.ogg", -24.0)


# --- GPU Foundry (the night market) ----------------------------------------------------

func _build_foundry() -> void:
	var stage := get_parent()
	# Strip market props, stalls, street food, vehicles, and audio.
	# Note: Jeepney0 and Jeepney1 use jeepney.res whose 11 surfaces rely on mesh instance
	# material overrides. Calling queue_free() clears those overrides during frame capture,
	# so we hide and sink them to avoid null material errors during ReflectionProbe updates.
	for node_name in [
		"Jeepney0", "JeepneyRoute0", "JeepneyName0L", "JeepneyName0R",
		"Jeepney1", "JeepneyRoute1", "JeepneyName1L", "JeepneyName1R",
		"Crowd", "GrillSmoke0", "GrillSparks0", "GrillSmoke1", "GrillSparks1",
		"GrillFlicker", "NeonOpen", "NeonCross", "NeonGlow", "Ambience",
		"Sound", "StreetShadows"
	]:
		if node_name in ["Jeepney0", "Jeepney1"]:
			var j = stage.get_node_or_null(node_name) as VisualInstance3D
			if j:
				j.visible = false
				j.position.y = -200.0
		else:
			_remove(stage, node_name)
	for i in 11:
		_remove(stage, "ShopSign%d" % i)
	for i in 6:
		_remove(stage, "StallSign%d" % i)
		_remove(stage, "StallLight%d" % i)

	# Environment atmosphere pass: high-contrast dark cleanroom with rich cyan-violet depth
	var we := stage.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if we and we.environment:
		we.environment = we.environment.duplicate()
		we.environment.tonemap_mode = Environment.TONE_MAPPER_ACES
		we.environment.tonemap_exposure = 0.82
		we.environment.glow_enabled = true
		we.environment.glow_bloom = 0.22
		we.environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
		we.environment.adjustment_enabled = true
		we.environment.adjustment_contrast = 1.28
		we.environment.adjustment_saturation = 1.15
		we.environment.volumetric_fog_enabled = true
		we.environment.volumetric_fog_albedo = Color(0.20, 0.45, 0.75)
		we.environment.volumetric_fog_density = 0.005

	# 1. Dark high-gloss ESD epoxy floor with deep specular reflections and PBR metal plate
	var probe := ReflectionProbe.new()
	probe.name = "FoundryReflectionProbe"
	probe.size = Vector3(24.0, 8.0, 20.0)
	probe.origin_offset = Vector3(0.0, 2.5, -3.5)
	probe.update_mode = ReflectionProbe.UPDATE_ONCE
	probe.intensity = 1.0
	probe.max_distance = 32.0
	probe.ambient_mode = ReflectionProbe.AMBIENT_COLOR
	probe.ambient_color = Color(0.08, 0.10, 0.14)
	add_child(probe)

	# Glossy dark conductive epoxy floor with PBR metal plate (eliminates white washout)
	var floor_mat := _pbr_texture_mat(
		"res://assets/stage_props/foundry/Textures/metal_plate_02_diff_1k.jpg",
		"res://assets/stage_props/foundry/Textures/metal_plate_02_nor_1k.jpg",
		"res://assets/stage_props/foundry/Textures/metal_plate_02_rough_1k.jpg",
		Vector3(12, 8, 1), 0.15, 0.65)
	_box(Vector3(18.0, 0.02, 10.0), Vector3(0, 0.01, 0.0), floor_mat)
	# Perforated tile boundary grid seams (cleanroom raised airflow floor)
	for x in range(-8, 9, 2):
		_box(Vector3(0.03, 0.025, 10.0), Vector3(x, 0.012, 0.0), _mat(Color(0.08, 0.09, 0.11), 0.4, 0.6))
	for z in range(-4, 5, 2):
		_box(Vector3(18.0, 0.025, 0.03), Vector3(0, 0.012, z), _mat(Color(0.08, 0.09, 0.11), 0.4, 0.6))
	# High-contrast yellow & amber ESD caution perimeter border
	for z in [-3.6, 3.6]:
		_box(Vector3(17.2, 0.026, 0.08), Vector3(0, 0.013, z), _glow(Color(0.95, 0.70, 0.05), 2.8))
	for x in [-3.6, 3.6]:
		_box(Vector3(0.08, 0.026, 7.2), Vector3(x, 0.013, 0), _glow(Color(0.95, 0.70, 0.05), 2.8))
	# Corner hazard beacons on ESD perimeter
	var esd_corner_glow := _glow(Color(1.0, 0.2, 0.1), 3.5, true)
	_blinkers.append([esd_corner_glow, 3.5, 4.0, 0.0])
	for cx in [-3.6, 3.6]:
		for cz in [-3.6, 3.6]:
			_cylinder(0.06, 0.12, Vector3(cx, 0.06, cz), esd_corner_glow)

	# 2. Dark modular technical wall partition with brushed aluminum mullions
	var wall_mat := _mat(Color(0.14, 0.16, 0.20), 0.35, 0.25)
	_box(Vector3(18.0, 4.4, 0.2), Vector3(0, 2.2, -6.0), wall_mat)
	var strut_mat := _mat(Color(0.42, 0.45, 0.50), 0.25, 0.85)
	for wx in range(-8, 9, 2):
		_box(Vector3(0.08, 4.4, 0.24), Vector3(wx, 2.2, -6.0), strut_mat)
	# Upper cleanroom return air louvers
	_box(Vector3(18.0, 0.45, 0.05), Vector3(0, 4.1, -5.88), _mat(Color(0.08, 0.09, 0.11), 0.5, 0.5))

	# 3. Centerpiece: Twin EUV Photolithography Scanner in dark obsidian casing
	var scanner_mat := _mat(Color(0.06, 0.07, 0.09), 0.25, 0.85)
	_box(Vector3(5.4, 3.4, 1.8), Vector3(0, 1.7, -5.2), scanner_mat)
	_box(Vector3(5.0, 0.12, 1.6), Vector3(0, 3.45, -5.2), _mat(Color(0.35, 0.38, 0.42), 0.2, 0.85))
	# Chamber observation window with UV amber filter & internal glow
	var glass := _mat(Color(1.0, 0.65, 0.05, 0.55), 0.04)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_box(Vector3(2.4, 1.4, 0.04), Vector3(0, 1.7, -4.28), glass)
	# EUV Laser Core (13.5nm pulsing violet/ultraviolet aperture)
	var euv_core := _glow(Color(0.80, 0.15, 1.0), 6.5, true)
	_blinkers.append([euv_core, 6.5, 3.2, 0.0])
	_box(Vector3(1.2, 0.8, 0.02), Vector3(0, 1.7, -4.4), euv_core)
	# Wafer load port & 300mm silicon wafer disc
	var wafer_mat := _mat(Color(0.12, 0.35, 0.40), 0.05, 0.95)
	_box(Vector3(1.4, 0.8, 0.9), Vector3(0, 0.4, -4.3), _mat(Color(0.12, 0.13, 0.16), 0.3, 0.6))
	_cylinder(0.42, 0.02, Vector3(0, 0.82, -4.3), wafer_mat)
	# Wafer load port flashing amber warning beacons
	var beacon_amber := _glow(Color(1.0, 0.55, 0.0), 4.5, true)
	_blinkers.append([beacon_amber, 4.5, 4.0, 0.5])
	_cylinder(0.06, 0.14, Vector3(-0.65, 0.88, -4.3), beacon_amber)
	_cylinder(0.06, 0.14, Vector3(0.65, 0.88, -4.3), beacon_amber)
	# Robotic wafer transfer arms flanking load port
	_prop("res://assets/stage_props/foundry/robot-arm-a.glb", Vector3(-1.6, 0.9, -4.3), Vector3(0, 50, 0), Vector3(0.65, 0.65, 0.65))
	_prop("res://assets/stage_props/foundry/robot-arm-b.glb", Vector3(1.6, 0.9, -4.3), Vector3(0, -50, 0), Vector3(0.65, 0.65, 0.65))
	# Automated wafer transport conveyors
	_prop("res://assets/stage_props/foundry/conveyor.glb", Vector3(-3.2, 0.35, -4.3), Vector3(0, 90, 0), Vector3(0.9, 0.7, 0.9))
	_prop("res://assets/stage_props/foundry/conveyor.glb", Vector3(3.2, 0.35, -4.3), Vector3(0, 90, 0), Vector3(0.9, 0.7, 0.9))
	# Glossy wafers riding on conveyors
	_cylinder(0.28, 0.015, Vector3(-3.2, 0.72, -4.3), wafer_mat)
	_cylinder(0.28, 0.015, Vector3(3.2, 0.72, -4.3), wafer_mat)
	# Lithography track machines on flanks
	_prop("res://assets/stage_props/foundry/machine.glb", Vector3(-6.2, 0.95, -5.1), Vector3(0, 0, 0), Vector3(0.9, 0.9, 0.9))
	_prop("res://assets/stage_props/foundry/machine.glb", Vector3(6.2, 0.95, -5.1), Vector3(0, 180, 0), Vector3(0.9, 0.9, 0.9))
	# High-precision wafer inspection scanners flanking track
	_prop("res://assets/stage_props/foundry/scanner-high.glb", Vector3(-4.8, 0.0, -4.6), Vector3.ZERO, Vector3(1.2, 1.2, 1.2))
	_prop("res://assets/stage_props/foundry/scanner-low.glb", Vector3(4.8, 0.0, -4.6), Vector3(0, 180, 0), Vector3(1.2, 1.2, 1.2))
	# Laser radiation caution hazard markers
	_prop("res://assets/stage_props/foundry/warning-orange.glb", Vector3(-2.6, 0.0, -3.8), Vector3.ZERO, Vector3(1.0, 1.0, 1.0))
	_prop("res://assets/stage_props/foundry/warning-orange.glb", Vector3(2.6, 0.0, -3.8), Vector3.ZERO, Vector3(1.0, 1.0, 1.0))

	# 4. AMHS (Automated Material Handling System) Overhead Monorail Track & FOUP pods
	var rail_mat := _mat(Color(0.22, 0.24, 0.28), 0.35, 0.8)
	_box(Vector3(17.8, 0.12, 0.35), Vector3(0, 3.5, -4.2), rail_mat)
	# Cleanroom overhead maintenance catwalk and stairs
	_prop("res://assets/stage_props/foundry/catwalk-straight.glb", Vector3(-5.5, 3.2, -5.5), Vector3.ZERO, Vector3(1.2, 1.2, 1.2))
	_prop("res://assets/stage_props/foundry/catwalk-straight.glb", Vector3(5.5, 3.2, -5.5), Vector3.ZERO, Vector3(1.2, 1.2, 1.2))
	_prop("res://assets/stage_props/foundry/catwalk-stairs.glb", Vector3(-8.2, 0.0, -5.5), Vector3(0, 90, 0), Vector3(1.2, 1.2, 1.2))
	_prop("res://assets/stage_props/foundry/catwalk-stairs.glb", Vector3(8.2, 0.0, -5.5), Vector3(0, -90, 0), Vector3(1.2, 1.2, 1.2))
	# Overhead telemetry display screens
	_prop("res://assets/stage_props/foundry/screen-hanging-wide.glb", Vector3(0.0, 3.2, -4.0), Vector3.ZERO, Vector3(1.5, 1.5, 1.5))
	_prop("res://assets/stage_props/foundry/screen-panel-wide.glb", Vector3(-7.2, 1.8, -5.8), Vector3.ZERO, Vector3(1.3, 1.3, 1.3))
	_prop("res://assets/stage_props/foundry/screen-panel-wide.glb", Vector3(7.2, 1.8, -5.8), Vector3.ZERO, Vector3(1.3, 1.3, 1.3))
	# Sub-fab equipment and filtration enclosures
	_prop("res://assets/stage_props/foundry/box-large.glb", Vector3(-8.5, 0.0, -4.0), Vector3.ZERO, Vector3(1.5, 1.5, 1.5))
	_prop("res://assets/stage_props/foundry/box-large.glb", Vector3(8.5, 0.0, -4.0), Vector3.ZERO, Vector3(1.5, 1.5, 1.5))
	# Glowing monorail power track
	_box(Vector3(17.8, 0.03, 0.02), Vector3(0, 3.44, -4.01), _glow(Color(0.1, 0.8, 1.0), 3.0))
	var foup_mat := _mat(Color(0.08, 0.09, 0.11), 0.2, 0.5)
	var foup_led := _glow(Color(0.1, 1.0, 0.4), 3.2)
	for fx in [-6.0, -2.5, 2.5, 6.0]:
		_box(Vector3(0.08, 0.4, 0.1), Vector3(fx, 3.25, -4.2), rail_mat)
		_box(Vector3(0.55, 0.45, 0.5), Vector3(fx, 2.9, -4.2), foup_mat)
		_box(Vector3(0.45, 0.04, 0.02), Vector3(fx, 2.9, -3.94), foup_led)
	# Overhead cryogenic fluid and gas delivery pipelines
	_prop("res://assets/stage_props/foundry/pipe-large.glb", Vector3(-4.5, 3.8, -4.2), Vector3(0, 90, 0), Vector3(1.2, 1.2, 1.2))
	_prop("res://assets/stage_props/foundry/pipe-glass-large.glb", Vector3(4.5, 3.8, -4.2), Vector3(0, 90, 0), Vector3(1.2, 1.2, 1.2))

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

	# 9. Cleanroom Lighting (high-contrast focus, rim lighting, and vibrant accents)
	_light(Vector3(0, 3.6, -2.8), Color(0.95, 0.98, 1.0), 3.2, 12.0)
	_light(Vector3(-5.5, 3.0, -2.2), Color(0.15, 0.80, 1.0), 2.0, 8.0)
	_light(Vector3(5.5, 3.0, -2.2), Color(0.15, 0.80, 1.0), 2.0, 8.0)
	_light(Vector3(0, 1.8, -4.5), Color(0.75, 0.15, 1.0), 3.0, 6.0)
	_light(Vector3(0, 0.8, -1.0), Color(0.2, 0.5, 0.9), 1.2, 5.0)

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


func _resolve_tex_path(path: String) -> String:
	if ResourceLoader.exists(path):
		return path
	if "/textures/" in path:
		var alt := path.replace("/textures/", "/Textures/")
		if ResourceLoader.exists(alt):
			return alt
	elif "/Textures/" in path:
		var alt := path.replace("/Textures/", "/textures/")
		if ResourceLoader.exists(alt):
			return alt
	return ""


func _pbr_texture_mat(diff_path: String, nor_path: String, rough_path: String, uv_scale: Vector3, roughness_mult := 1.0, metallic := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	var d := _resolve_tex_path(diff_path)
	if not d.is_empty():
		m.albedo_texture = load(d)
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		m.uv1_scale = uv_scale
	var n := _resolve_tex_path(nor_path)
	if not n.is_empty():
		m.normal_enabled = true
		m.normal_texture = load(n)
	var r := _resolve_tex_path(rough_path)
	if not r.is_empty():
		m.roughness_texture = load(r)
		m.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	m.roughness = roughness_mult
	m.metallic = metallic
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


func _prop(path: String, position_: Vector3, rotation_deg := Vector3.ZERO, scale_ := Vector3.ONE, parent: Node3D = self) -> Node3D:
	if not ResourceLoader.exists(path):
		return null
	var scene := load(path) as PackedScene
	if not scene:
		return null
	var node := scene.instantiate() as Node3D
	node.position = position_
	node.rotation_degrees = rotation_deg
	node.scale = scale_
	parent.add_child(node)
	return node


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
