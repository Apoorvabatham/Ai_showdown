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
	# Dark graphite tiles: the light texture under the pink neon washed out to pale peach.
	floor_mat.albedo_color = Color(0.3, 0.32, 0.38)
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
		we.environment.tonemap_exposure = 0.86 # 1.05 blew the windows and the marble out
		we.environment.glow_enabled = true
		we.environment.glow_bloom = 0.1
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
		"res://assets/stage_props/mensa/floor/floor_tiles_06_diff_1k.jpg",
		"res://assets/stage_props/mensa/floor/floor_tiles_06_nor_1k.jpg",
		"res://assets/stage_props/mensa/floor/floor_tiles_06_rough_1k.jpg",
		Vector3(14, 12, 1), 0.35)
	tiles.albedo_color = Color(0.78, 0.76, 0.74) # a touch darker: the white tiles glared
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
	_senate_strip_ring(stage)

	var dark_wood := _pbr_texture_mat(
		"res://assets/stage_props/senate/textures/lacquered_cherry_wood_diff_1k.jpg",
		"res://assets/stage_props/senate/textures/lacquered_cherry_wood_nor_1k.jpg",
		"res://assets/stage_props/senate/textures/lacquered_cherry_wood_rough_1k.jpg",
		Vector3(3.0, 2.0, 1.0), 0.46)
	dark_wood.albedo_color = Color(0.42, 0.22, 0.13)

	var panel_wood := _pbr_texture_mat(
		"res://assets/stage_props/senate/textures/lacquered_cherry_wood_diff_1k.jpg",
		"res://assets/stage_props/senate/textures/lacquered_cherry_wood_nor_1k.jpg",
		"res://assets/stage_props/senate/textures/lacquered_cherry_wood_rough_1k.jpg",
		Vector3(2.0, 2.0, 1.0), 0.48)
	panel_wood.albedo_color = Color(0.54, 0.28, 0.16)

	var trim_wood := _mat(Color(0.18, 0.09, 0.05), 0.44)
	var brass := _mat(Color(0.84, 0.66, 0.27), 0.26, 0.85)
	var oxblood := _mat(Color(0.24, 0.06, 0.06), 0.46)

	var probe := ReflectionProbe.new()
	probe.name = "SenateReflectionProbe"
	probe.size = Vector3(26.0, 8.0, 22.0)
	probe.origin_offset = Vector3(0.0, 2.5, -3.5)
	probe.update_mode = ReflectionProbe.UPDATE_ONCE
	probe.intensity = 0.65
	probe.max_distance = 30.0
	probe.ambient_mode = ReflectionProbe.AMBIENT_COLOR
	probe.ambient_color = Color(0.24, 0.16, 0.11)
	add_child(probe)

	_senate_build_floor_and_railing(stage, dark_wood, trim_wood, brass)
	_senate_build_chamber(dark_wood, panel_wood, trim_wood, brass)
	_senate_build_banner(trim_wood, brass)
	_senate_build_dais(dark_wood, panel_wood, trim_wood, brass, oxblood)
	_senate_build_flags(brass)
	_senate_build_gallery(dark_wood, trim_wood, brass)

	# Warm atmospheric wash on the banner, witness area, and flanking gallery (non-shadowing for 60 fps)
	_light(Vector3(0.0, 4.0, -7.0), Color(1.0, 0.88, 0.68), 1.9, 9.5)
	_light(Vector3(0.0, 2.2, -5.6), Color(1.0, 0.84, 0.60), 1.6, 8.5)
	_light(Vector3(-7.0, 3.4, -6.4), Color(1.0, 0.84, 0.60), 1.8, 9.5)
	_light(Vector3(7.0, 3.4, -6.4), Color(1.0, 0.84, 0.60), 1.8, 9.5)
	_ambience("res://assets/audio/ambience/arena_crowd.ogg", -26.0)


func _senate_strip_ring(stage: Node) -> void:
	for node_name in ["Truss", "Crowd", "Dust", "CameraFlashes", "CanvasShadows", "ArenaShadows"]:
		_remove(stage, node_name)
	var arena := stage.get_node_or_null("Arena")
	if arena:
		for child in arena.get_children():
			if child.name == "Floor":
				var floor_mesh := child as MeshInstance3D
				if floor_mesh:
					floor_mesh.material_override = _mat(Color(0.14, 0.055, 0.055), 0.92)
			else:
				child.queue_free()
	var ring := stage.get_node_or_null("BoxingRing")
	if ring:
		for child in ring.get_children():
			if child.name.begins_with("Rope_") or child.name.begins_with("Corner_") or child.name.begins_with("Step_") \
					or child.name in ["LogoDisc", "LogoText"]:
				child.queue_free()


func _senate_build_floor_and_railing(stage: Node, dark_wood: Material, trim_wood: Material, brass: Material) -> void:
	var ring := stage.get_node_or_null("BoxingRing")
	if ring:
		var canvas := ring.get_node_or_null("Canvas") as MeshInstance3D
		if canvas:
			var carpet := _pbr_texture_mat(
				"res://assets/stages/ring/textures/terlenka_diff_1k.jpg",
				"res://assets/stages/ring/textures/terlenka_nor_gl_1k.jpg",
				"res://assets/stages/ring/textures/terlenka_rough_1k.jpg",
				Vector3(8.0, 8.0, 1.0), 0.90)
			carpet.albedo_color = Color(0.10, 0.14, 0.30)
			canvas.material_override = carpet
		var apron := ring.get_node_or_null("Apron") as MeshInstance3D
		if apron:
			apron.material_override = dark_wood
		var banners := ["HEARING ON AI OVERSIGHT", "PLEASE REMAIN SEATED", "NO PHOTOGRAPHY (PLEASE)", "TESTIMONY IN PROGRESS"]
		for i in 4:
			var banner := ring.get_node_or_null("ApronBanner%d" % i) as Label3D
			if banner:
				banner.text = banners[i]
				banner.modulate = Color(0.90, 0.75, 0.36)

	# Woven gold and crimson carpet border trim around the fight floor
	var border_gold := _mat(Color(0.58, 0.45, 0.18), 0.85)
	var border_crimson := _mat(Color(0.32, 0.07, 0.08), 0.88)
	for sz in [-4.12, 4.12]:
		_box(Vector3(8.32, 0.008, 0.08), Vector3(0, 0.004, sz), border_gold)
	for sx in [-4.12, 4.12]:
		_box(Vector3(0.08, 0.008, 8.32), Vector3(sx, 0.004, 0), border_gold)
	for sz in [-3.98, 3.98]:
		_box(Vector3(8.00, 0.008, 0.04), Vector3(0, 0.004, sz), border_crimson)
	for sx in [-3.98, 3.98]:
		_box(Vector3(0.04, 0.008, 8.00), Vector3(sx, 0.004, 0), border_crimson)

	# Woven antique-gold committee medallion inlaid in the carpet
	_cylinder(1.24, 0.008, Vector3(0, 0.004, 0), border_gold)
	_cylinder(1.14, 0.010, Vector3(0, 0.005, 0), _mat(Color(0.08, 0.11, 0.25), 0.90))
	var emblem := _label("COMMITTEE\nON AI", Vector3(0, 0.015, 0), 0.24, Color(0.88, 0.75, 0.40))
	emblem.rotation = Vector3(-PI / 2, 0, 0)

	# Mahogany railing round the floor (camera-side rail hides automatically)
	var rail_wood := _pbr_texture_mat(
		"res://assets/stage_props/senate/textures/lacquered_cherry_wood_diff_1k.jpg",
		"res://assets/stage_props/senate/textures/lacquered_cherry_wood_nor_1k.jpg",
		"res://assets/stage_props/senate/textures/lacquered_cherry_wood_rough_1k.jpg",
		Vector3(4.0, 2.0, 1.0), 0.56)
	rail_wood.albedo_color = Color(0.32, 0.16, 0.09)
	var sides := [
		[Vector3(0, 0, -4.45), Vector3(9.0, 0.08, 0.11), 0],
		[Vector3(0, 0, 4.45), Vector3(9.0, 0.08, 0.11), 1],
		[Vector3(-4.45, 0, 0), Vector3(0.11, 0.08, 9.0), 2],
		[Vector3(4.45, 0, 0), Vector3(0.11, 0.08, 9.0), 3]
	]
	for side: Array in sides:
		var group := Node3D.new()
		group.add_to_group(&"ring_side_%d" % side[2])
		add_child(group)
		var is_x: bool = side[1].x > 1.0
		var along := Vector3(1, 0, 0) if is_x else Vector3(0, 0, 1)
		_box(side[1], side[0] + Vector3(0, 0.94, 0), rail_wood, group)
		_box(side[1] * Vector3(1.0, 0.75, 0.75), side[0] + Vector3(0, 0.12, 0), trim_wood, group)
		for k in 13:
			_box(Vector3(0.055, 0.80, 0.055), side[0] + along * (-4.2 + k * 0.7) + Vector3(0, 0.52, 0), rail_wood, group)
		for end_sign in [-1.0, 1.0]:
			var post_pos: Vector3 = side[0] + along * (4.45 * end_sign)
			_box(Vector3(0.14, 1.02, 0.14), post_pos + Vector3(0, 0.51, 0), trim_wood, group)
			_box(Vector3(0.16, 0.04, 0.16), post_pos + Vector3(0, 1.04, 0), brass, group)


func _senate_build_chamber(dark_wood: Material, panel_wood: Material, trim_wood: Material, brass: Material) -> void:
	var plaster := _mat(Color(0.46, 0.40, 0.32), 0.88)
	var drape := _mat(Color(0.32, 0.06, 0.07), 0.86)
	var ceiling_plaster := _mat(Color(0.30, 0.25, 0.20), 0.90)

	# Full-width rear wall, side walls, and coffered ceiling (encloses the room cleanly)
	_box(Vector3(28.0, 8.6, 0.3), Vector3(0, 3.3, -9.45), dark_wood)
	_box(Vector3(28.0, 2.6, 0.36), Vector3(0, 0.3, -9.40), trim_wood)
	_box(Vector3(28.0, 0.18, 0.42), Vector3(0, 1.65, -9.38), trim_wood)
	_box(Vector3(28.0, 0.36, 0.46), Vector3(0, 6.25, -9.35), trim_wood)

	for sx in [-12.6, 12.6]:
		_box(Vector3(0.3, 8.6, 20.0), Vector3(sx, 3.3, 0.2), dark_wood)
		_box(Vector3(0.36, 2.6, 20.0), Vector3(sx, 0.3, 0.2), trim_wood)
		_box(Vector3(0.44, 0.32, 20.0), Vector3(sx, 6.25, 0.2), trim_wood)
		for sz in [-6.5, -2.5, 1.5]:
			_box(Vector3(0.42, 6.4, 0.45), Vector3(sx, 3.0, sz), trim_wood)
			_senate_sconce(Vector3(sx + (0.28 if sx < 0 else -0.28), 3.4, sz), brass, 90.0 if sx < 0 else -90.0)

	# Coffered ceiling above the chamber
	_box(Vector3(28.0, 0.25, 20.0), Vector3(0, 6.85, 0.2), ceiling_plaster)
	for bx in [-9.0, -4.5, 0.0, 4.5, 9.0]:
		_box(Vector3(0.35, 0.35, 18.0), Vector3(bx, 6.62, -0.5), trim_wood)
	for bz in [-7.5, -3.5, 0.5]:
		_box(Vector3(26.0, 0.35, 0.35), Vector3(0, 6.62, bz), trim_wood)

	# Classical fluted mahogany pilasters along the rear wall
	for px in [-10.6, -7.3, -4.15, 4.15, 7.3, 10.6]:
		_box(Vector3(0.52, 6.4, 0.28), Vector3(px, 3.0, -9.24), dark_wood)
		_box(Vector3(0.64, 0.35, 0.34), Vector3(px, 0.95, -9.22), trim_wood)
		_box(Vector3(0.66, 0.32, 0.36), Vector3(px, 5.95, -9.20), trim_wood)
		_box(Vector3(0.68, 0.06, 0.38), Vector3(px, 5.78, -9.19), brass)
		for fx in [-0.14, 0.0, 0.14]:
			_box(Vector3(0.05, 4.5, 0.04), Vector3(px + fx, 3.4, -9.09), trim_wood)

	# Recessed flank architectural bays with limestone panels, crimson velvet drapes & sconces
	for bx in [-8.95, -5.72, 5.72, 8.95]:
		_box(Vector3(2.4, 3.8, 0.08), Vector3(bx, 3.9, -9.27), plaster)
		_box(Vector3(2.52, 0.14, 0.14), Vector3(bx, 5.82, -9.24), trim_wood)
		_box(Vector3(2.2, 1.3, 0.10), Vector3(bx, 1.0, -9.24), panel_wood)
		for dx in [-0.95, -0.72, 0.72, 0.95]:
			_cylinder(0.11, 3.7, Vector3(bx + dx, 3.9, -9.16), drape)
		_box(Vector3(2.3, 0.18, 0.18), Vector3(bx, 5.68, -9.14), drape)
		_senate_sconce(Vector3(bx, 3.55, -9.12), brass, 0.0)


func _senate_sconce(pos: Vector3, brass: Material, yaw_deg: float) -> void:
	var sconce := Node3D.new()
	sconce.position = pos
	sconce.rotation_degrees = Vector3(0, yaw_deg, 0)
	add_child(sconce)
	_box(Vector3(0.14, 0.30, 0.04), Vector3(0, 0, 0), brass, sconce)
	_box(Vector3(0.04, 0.04, 0.16), Vector3(0, -0.02, 0.08), brass, sconce)
	var shade_glow := _glow(Color(1.0, 0.82, 0.48), 2.8)
	var bulb := CylinderMesh.new()
	bulb.top_radius = 0.08
	bulb.bottom_radius = 0.05
	bulb.height = 0.18
	bulb.radial_segments = 16
	_instance(bulb, Vector3(0, 0.08, 0.14), shade_glow, sconce)


func _senate_build_banner(trim_wood: Material, brass: Material) -> void:
	# Deep midnight-navy plaque framed in walnut and brass so gold lettering reads crisply
	var plaque_bg := _mat(Color(0.055, 0.075, 0.14), 0.65)
	_box(Vector3(7.6, 3.25, 0.12), Vector3(0, 3.72, -9.26), trim_wood)
	_box(Vector3(7.2, 2.88, 0.14), Vector3(0, 3.72, -9.22), plaque_bg)
	# Brass frame rails around the committee plaque
	for fy in [5.18, 2.26]:
		_box(Vector3(7.32, 0.08, 0.16), Vector3(0, fy, -9.20), brass)
	for fx in [-3.62, 3.62]:
		_box(Vector3(0.08, 3.00, 0.16), Vector3(fx, 3.72, -9.20), brass)

	# Stylized original Senate Subcommittee Seal above the header
	var seal := Node3D.new()
	seal.position = Vector3(0, 4.58, -9.12)
	add_child(seal)
	var outer_ring := CylinderMesh.new()
	outer_ring.top_radius = 0.38
	outer_ring.bottom_radius = 0.38
	outer_ring.height = 0.04
	outer_ring.radial_segments = 28
	var ring_mi := _instance(outer_ring, Vector3.ZERO, brass, seal)
	ring_mi.rotation_degrees = Vector3(90, 0, 0)
	var inner_disc := CylinderMesh.new()
	inner_disc.top_radius = 0.32
	inner_disc.bottom_radius = 0.32
	inner_disc.height = 0.05
	inner_disc.radial_segments = 28
	var disc_mi := _instance(inner_disc, Vector3(0, 0, 0.01), _mat(Color(0.09, 0.13, 0.28), 0.7), seal)
	disc_mi.rotation_degrees = Vector3(90, 0, 0)
	for cx in [-0.12, 0.0, 0.12]:
		_box(Vector3(0.045, 0.30, 0.03), Vector3(cx, -0.02, 0.03), brass, seal)
	_box(Vector3(0.38, 0.055, 0.03), Vector3(0, 0.16, 0.03), brass, seal)
	_box(Vector3(0.40, 0.055, 0.03), Vector3(0, -0.18, 0.03), brass, seal)

	_label("SUBCOMMITTEE ON ARTIFICIAL INTELLIGENCE", Vector3(0, 3.78, -9.10), 0.34, Color(1.0, 0.85, 0.42), true)

	# Framed "IN SESSION" indicator plaque
	_box(Vector3(2.25, 0.48, 0.08), Vector3(0, 2.98, -9.15), brass)
	_box(Vector3(2.13, 0.38, 0.10), Vector3(0, 2.98, -9.13), _mat(Color(0.14, 0.035, 0.035), 0.5))
	_label("IN SESSION", Vector3(0, 2.98, -9.06), 0.22, Color(1.0, 0.42, 0.26), true)


func _senate_build_dais(dark_wood: Material, panel_wood: Material, trim_wood: Material, brass: Material, oxblood: Material) -> void:
	# Raised committee dais with paneled front and dark walnut desktop
	_box(Vector3(14.0, 1.8, 1.2), Vector3(0, -0.1, -7.2), dark_wood)
	_box(Vector3(14.4, 0.08, 1.4), Vector3(0, 0.84, -7.25), trim_wood)
	for px in range(-6, 7, 2):
		_box(Vector3(1.5, 1.15, 0.05), Vector3(px, 0.25, -6.58), panel_wood)
		_box(Vector3(0.08, 1.35, 0.07), Vector3(px + 0.9, 0.25, -6.58), trim_wood)

	# Flanking dark mahogany bookcases filled with bound legal volumes
	_senate_bookcase(Vector3(-8.2, 0.0, -8.55), dark_wood, trim_wood)
	_senate_bookcase(Vector3(8.2, 0.0, -8.55), dark_wood, trim_wood)

	var names := ["SEN. GRAY", "SEN. OKAFOR", "SEN. LINDQVIST", "CHAIR", "SEN. MORALES", "SEN. PATEL", "SEN. BROOKS"]
	var mic_mat := _mat(Color(0.08, 0.08, 0.09), 0.3, 0.8)
	var mic_head := _mat(Color(0.65, 0.67, 0.70), 0.25, 0.9)
	var plate_wood := _mat(Color(0.10, 0.05, 0.03), 0.4)
	for i in names.size():
		var x := -5.4 + i * 1.8
		# Walnut & brass nameplate
		_box(Vector3(0.84, 0.20, 0.06), Vector3(x, 0.98, -6.60), brass)
		_box(Vector3(0.78, 0.15, 0.08), Vector3(x, 0.98, -6.59), plate_wood)
		_label(names[i], Vector3(x, 0.98, -6.54), 0.085, Color(0.96, 0.88, 0.68), true)
		# Gooseneck microphone
		_box(Vector3(0.08, 0.025, 0.08), Vector3(x + 0.32, 0.89, -6.82), mic_mat)
		_cylinder(0.011, 0.34, Vector3(x + 0.32, 1.06, -6.82), mic_mat)
		_cylinder(0.018, 0.05, Vector3(x + 0.32, 1.24, -6.80), mic_head)
		# Oxblood leather & mahogany committee chair behind seat (clear of StageCrowd senators)
		_senate_chair(Vector3(x, 0.0, -8.02), 0.0, trim_wood, oxblood)
		_prop("res://assets/stage_props/senate/books.glb", Vector3(x - 0.35, 0.88, -6.88), Vector3(0, 90, 0), Vector3(0.85, 0.85, 0.85))

	# Warm green-glass & brass banker's lamps along the dais
	for lx in [-4.5, -1.5, 1.5, 4.5]:
		_senate_banker_lamp(Vector3(lx, 0.88, -6.92), brass, Color(0.04, 0.24, 0.10))
	_light(Vector3(-2.6, 1.4, -6.6), Color(1.0, 0.78, 0.42), 1.8, 5.5)
	_light(Vector3(2.6, 1.4, -6.6), Color(1.0, 0.78, 0.42), 1.8, 5.5)

	# Chairman's brass gavel and walnut sound block
	_box(Vector3(0.24, 0.04, 0.24), Vector3(0.42, 0.90, -6.8), trim_wood)
	_cylinder(0.02, 0.26, Vector3(0.42, 0.95, -6.8), dark_wood)
	_cylinder(0.035, 0.12, Vector3(0.42, 0.97, -6.7), brass)

	# Stately planters flanking the dais
	_prop("res://assets/stage_props/senate/plantSmall1.glb", Vector3(-6.4, 0.85, -6.85), Vector3.ZERO, Vector3(1.4, 1.4, 1.4))
	_prop("res://assets/stage_props/senate/plantSmall1.glb", Vector3(6.4, 0.85, -6.85), Vector3.ZERO, Vector3(1.4, 1.4, 1.4))

	# Witness table just behind the center railing
	_box(Vector3(2.5, 0.85, 0.92), Vector3(0, 0.425, -4.95), dark_wood)
	_box(Vector3(2.6, 0.06, 1.0), Vector3(0, 0.85, -4.95), trim_wood)
	_box(Vector3(2.1, 0.62, 0.04), Vector3(0, 0.44, -4.48), panel_wood)
	_box(Vector3(0.70, 0.16, 0.05), Vector3(0, 0.94, -4.55), brass)
	_box(Vector3(0.64, 0.12, 0.07), Vector3(0, 0.94, -4.54), plate_wood)
	_label("WITNESS", Vector3(0, 0.94, -4.50), 0.075, Color(0.96, 0.88, 0.68), true)
	for mx in [-0.22, 0.22]:
		_cylinder(0.008, 0.30, Vector3(mx, 1.00, -4.78), mic_mat)
		_cylinder(0.015, 0.04, Vector3(mx, 1.16, -4.76), mic_head)
	# Water pitcher & glass, banker's lamp, briefing binder, witness chair
	var crystal := _mat(Color(0.82, 0.90, 0.98, 0.32), 0.06)
	crystal.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_cylinder(0.065, 0.20, Vector3(0.55, 0.98, -4.85), crystal)
	_cylinder(0.032, 0.10, Vector3(0.42, 0.93, -4.82), crystal)
	_senate_banker_lamp(Vector3(-0.92, 0.88, -4.85), brass, Color(0.04, 0.24, 0.10))
	_senate_chair(Vector3(0, 0.0, -5.72), 180.0, trim_wood, oxblood)
	_prop("res://assets/stage_props/senate/books.glb", Vector3(-0.48, 0.88, -4.88), Vector3(0, 45, 0), Vector3(0.85, 0.85, 0.85))
	_box(Vector3(0.32, 0.08, 0.26), Vector3(0.82, 0.92, -4.85), _mat(Color(0.10, 0.16, 0.36), 0.6))

	# Compact dark-walnut stenographer station matching data/stage_life/senate.json [-1.8, 0.0, -5.2]
	_box(Vector3(0.72, 0.68, 0.50), Vector3(-1.8, 0.34, -5.35), dark_wood)
	_box(Vector3(0.78, 0.05, 0.56), Vector3(-1.8, 0.70, -5.35), trim_wood)
	_box(Vector3(0.28, 0.06, 0.22), Vector3(-1.8, 0.75, -5.30), mic_mat)
	_senate_chair(Vector3(-1.55, 0.0, -5.75), 45.0, trim_wood, oxblood)


func _senate_banker_lamp(pos: Vector3, brass: Material, shade_color: Color) -> void:
	var lamp := Node3D.new()
	lamp.position = pos
	add_child(lamp)
	var base := CylinderMesh.new()
	base.top_radius = 0.09
	base.bottom_radius = 0.09
	base.height = 0.03
	base.radial_segments = 16
	_instance(base, Vector3(0, 0.015, 0), brass, lamp)
	var stem := CylinderMesh.new()
	stem.top_radius = 0.016
	stem.bottom_radius = 0.016
	stem.height = 0.32
	stem.radial_segments = 12
	_instance(stem, Vector3(0, 0.17, -0.02), brass, lamp)
	_box(Vector3(0.02, 0.02, 0.09), Vector3(0, 0.33, 0.02), brass, lamp)
	var shade_mat := _mat(shade_color, 0.16)
	shade_mat.emission_enabled = true
	shade_mat.emission = Color(0.12, 0.45, 0.18)
	shade_mat.emission_energy_multiplier = 0.35
	var shade := CylinderMesh.new()
	shade.top_radius = 0.075
	shade.bottom_radius = 0.075
	shade.height = 0.24
	shade.radial_segments = 16
	var shade_mi := _instance(shade, Vector3(0, 0.32, 0.05), shade_mat, lamp)
	shade_mi.rotation_degrees = Vector3(0, 0, 90)
	_box(Vector3(0.20, 0.03, 0.09), Vector3(0, 0.285, 0.05), _glow(Color(1.0, 0.80, 0.42), 3.8), lamp)


func _senate_chair(pos: Vector3, yaw_deg: float, wood_mat: Material, leather_mat: Material) -> void:
	var chair := Node3D.new()
	chair.position = pos
	chair.rotation_degrees = Vector3(0, yaw_deg, 0)
	add_child(chair)
	_box(Vector3(0.54, 0.08, 0.50), Vector3(0, 0.44, 0), leather_mat, chair)
	_box(Vector3(0.56, 0.78, 0.12), Vector3(0, 0.88, -0.20), leather_mat, chair)
	_box(Vector3(0.60, 0.82, 0.05), Vector3(0, 0.88, -0.25), wood_mat, chair)
	for ax in [-0.27, 0.27]:
		_box(Vector3(0.06, 0.06, 0.42), Vector3(ax, 0.64, -0.02), wood_mat, chair)
	var ped := CylinderMesh.new()
	ped.top_radius = 0.04
	ped.bottom_radius = 0.04
	ped.height = 0.40
	ped.radial_segments = 12
	_instance(ped, Vector3(0, 0.22, 0), wood_mat, chair)


func _senate_bookcase(pos: Vector3, dark_wood: Material, trim_wood: Material) -> void:
	var bc := Node3D.new()
	bc.position = pos
	add_child(bc)
	_box(Vector3(1.9, 3.2, 0.42), Vector3(0, 1.6, 0), trim_wood, bc)
	_box(Vector3(1.72, 2.9, 0.36), Vector3(0, 1.6, 0.04), dark_wood, bc)
	var book_colors := [
		Color(0.38, 0.08, 0.08),
		Color(0.09, 0.15, 0.32),
		Color(0.10, 0.24, 0.14),
		Color(0.32, 0.22, 0.09)
	]
	for sy in [0.75, 1.40, 2.05, 2.65]:
		_box(Vector3(1.74, 0.05, 0.42), Vector3(0, sy, 0.06), trim_wood, bc)
		for bi in 9:
			var bx := -0.72 + bi * 0.18
			var bh := 0.34 + (bi % 3) * 0.04
			_box(Vector3(0.13, bh, 0.24), Vector3(bx, sy + 0.03 + bh * 0.5, 0.12), _mat(book_colors[(bi + int(sy * 3)) % book_colors.size()], 0.65), bc)


func _senate_build_flags(brass: Material) -> void:
	# Ceremonial standing flags flanking the dais banner (US-inspired stripes + Senate navy standard)
	_senate_flag(Vector3(-5.55, 0.0, -8.35), brass, true, 5.0)
	_senate_flag(Vector3(-4.60, 0.0, -8.40), brass, false, 3.5)
	_senate_flag(Vector3(4.60, 0.0, -8.40), brass, false, -3.5)
	_senate_flag(Vector3(5.55, 0.0, -8.35), brass, true, -5.0)


func _senate_flag(pos: Vector3, brass: Material, striped: bool, tilt_z_deg: float) -> void:
	var flag := Node3D.new()
	flag.position = pos
	flag.rotation_degrees = Vector3(3.0, 0.0, tilt_z_deg)
	add_child(flag)
	# Brass pedestal base, mahogany pole, spearhead finial
	var base_plate := CylinderMesh.new()
	base_plate.top_radius = 0.22
	base_plate.bottom_radius = 0.22
	base_plate.height = 0.08
	base_plate.radial_segments = 16
	_instance(base_plate, Vector3(0, 0.04, 0), brass, flag)
	var base_dome := CylinderMesh.new()
	base_dome.top_radius = 0.06
	base_dome.bottom_radius = 0.18
	base_dome.height = 0.12
	base_dome.radial_segments = 16
	_instance(base_dome, Vector3(0, 0.12, 0), brass, flag)
	var pole := CylinderMesh.new()
	pole.top_radius = 0.024
	pole.bottom_radius = 0.024
	pole.height = 4.3
	pole.radial_segments = 12
	_instance(pole, Vector3(0, 2.2, 0), _mat(Color(0.24, 0.12, 0.06), 0.42), flag)
	var finial := CylinderMesh.new()
	finial.top_radius = 0.004
	finial.bottom_radius = 0.055
	finial.height = 0.22
	finial.radial_segments = 12
	_instance(finial, Vector3(0, 4.46, 0), brass, flag)

	# Pleated vertical draped fabric folds hanging from the upper pole
	var navy := _mat(Color(0.08, 0.13, 0.34), 0.85)
	var red := _mat(Color(0.55, 0.08, 0.09), 0.85)
	var cream := _mat(Color(0.84, 0.81, 0.74), 0.85)
	var gold := _mat(Color(0.76, 0.60, 0.22), 0.65)
	for fold in 6:
		var fx := (fold - 2.5) * 0.065
		var fz := 0.08 + sin(fold * 1.4) * 0.05
		var h := 2.45 - (fold % 2) * 0.08
		if striped:
			var strip_mat := red if (fold % 2 == 0) else cream
			_box(Vector3(0.075, h, 0.05), Vector3(fx, 2.95, fz), strip_mat, flag)
			if fold < 3:
				_box(Vector3(0.082, 0.92, 0.062), Vector3(fx, 3.68, fz + 0.01), navy, flag)
		else:
			var fold_mat := gold if (fold == 2 or fold == 3) else navy
			_box(Vector3(0.078, h, 0.05), Vector3(fx, 2.95, fz), fold_mat, flag)


func _senate_build_gallery(dark_wood: Material, trim_wood: Material, brass: Material) -> void:
	# Broadcast television cameras on the flank wings with flash lights
	var tally_mat := _glow(Color(1.0, 0.12, 0.12), 4.0)
	var rig_mat := _mat(Color(0.14, 0.15, 0.17), 0.4, 0.6)
	var cam_body := _mat(Color(0.07, 0.07, 0.09), 0.35, 0.5)
	var rng_senate := RandomNumberGenerator.new()
	rng_senate.seed = 42
	for cam_x in [-6.4, 6.4]:
		_cylinder(0.025, 1.3, Vector3(cam_x, 0.65, -3.8), rig_mat)
		_box(Vector3(0.32, 0.35, 0.55), Vector3(cam_x, 1.45, -3.8), cam_body)
		_cylinder(0.09, 0.32, Vector3(cam_x, 1.45, -3.45), _mat(Color(0.04, 0.04, 0.05), 0.2, 0.8))
		_cylinder(0.03, 0.05, Vector3(cam_x, 1.66, -3.7), tally_mat)
		_person(Vector3(cam_x, 0.0, -4.25), Color(0.10, 0.10, 0.12), rng_senate)
		var flash_light := OmniLight3D.new()
		flash_light.position = Vector3(cam_x, 1.8, -3.3)
		flash_light.light_color = Color(0.95, 0.96, 1.0)
		flash_light.light_energy = 0.0
		flash_light.omni_range = 6.0
		add_child(flash_light)
		_flashers.append([flash_light, 3.2])

	# Flanking dark mahogany gallery benches (matching data/stage_life/senate.json aides/citizens)
	for gx in [-7.2, 7.2]:
		var inward := 1.0 if gx < 0.0 else -1.0
		for gz in [-1.5, 0.5, 2.5]:
			_box(Vector3(0.55, 0.08, 1.45), Vector3(gx, 0.24, gz), dark_wood)
			_box(Vector3(0.10, 0.56, 1.45), Vector3(gx - inward * 0.24, 0.50, gz), trim_wood)
			_box(Vector3(0.45, 0.24, 0.08), Vector3(gx, 0.12, gz - 0.62), trim_wood)
			_box(Vector3(0.45, 0.24, 0.08), Vector3(gx, 0.12, gz + 0.62), trim_wood)
			_box(Vector3(0.04, 0.04, 1.45), Vector3(gx - inward * 0.24, 0.80, gz), brass)
			_person(Vector3(gx, 0.28, gz - 0.35), Color(0.12, 0.14, 0.20), rng_senate)
			_person(Vector3(gx, 0.28, gz + 0.35), Color(0.20, 0.20, 0.24), rng_senate)


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
	# (Lightly tinted: at 55% the pane hid the violet core and read as a flat yellow block.)
	var glass := _mat(Color(1.0, 0.6, 0.15, 0.18), 0.04)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_box(Vector3(2.4, 1.4, 0.04), Vector3(0, 1.7, -4.28), glass)
	var frame := _mat(Color(0.1, 0.11, 0.13), 0.35, 0.7)
	for fy in [0.98, 2.42]:
		_box(Vector3(2.56, 0.08, 0.08), Vector3(0, fy, -4.27), frame)
	for fx in [-1.24, 1.24]:
		_box(Vector3(0.08, 1.52, 0.08), Vector3(fx, 1.7, -4.27), frame)
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
		Vector3(-5.0, 1.75, -5.85)) # low enough to stay clear of the HUD
	_board("FAB 4090 METRICS\n• Process: 1.8nm Hype-FinFET\n• Die Yield: 88.4% (dropping)\n• EUV Uptime: 99.98%\n• Wafer Cost: $42,000 / piece\n• Today's Scrap: 12 wafers (blame P2)",
		Vector3(5.0, 1.75, -5.85))
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
