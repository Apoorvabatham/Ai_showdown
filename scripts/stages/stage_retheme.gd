class_name StageRetheme
extends Node3D
## Turns an original 3D Fighter stage into an AI Showdown stage: removes the props that
## don't fit and builds new ones from simple shapes (cosmetic only: no collision, nothing
## the simulation reads). Added as a child of the stage root in the AI Showdown stage
## scenes, which inherit the original stages:
##   server_farm.tscn (rooftop): rows of GPU racks with blinking lights, cooling units.
##   mensa.tscn (dojo): a university cafeteria: tiled floor, tables, trays, the counter.
##   senate.tscn (ring): a hearing room: carpet, the committee's dais, a railing.

enum Look { SERVER_FARM, MENSA, SENATE }

@export var look: Look = Look.SERVER_FARM

var _materials := {}
## Blinking rack lights: [material, base energy, rate, phase].
var _blinkers: Array = []
var _time := 0.0


func _ready() -> void:
	match look:
		Look.SERVER_FARM:
			_build_server_farm()
		Look.MENSA:
			_build_mensa()
		Look.SENATE:
			_build_senate()
	set_process(not _blinkers.is_empty())


func _process(delta: float) -> void:
	_time += delta
	for blinker: Array in _blinkers:
		var on := sin(_time * blinker[2] + blinker[3]) > -0.3
		(blinker[0] as StandardMaterial3D).emission_energy_multiplier = blinker[1] if on else blinker[1] * 0.15


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
	for x in [-9.6, 9.6]:
		_cylinder(0.75, 1.8, Vector3(x, 0.9, -3.5), _mat(Color(0.55, 0.57, 0.6), 0.4, 0.6))
		_cylinder(0.6, 0.08, Vector3(x, 1.84, -3.5), _mat(Color(0.1, 0.1, 0.12)))
	_label("WARNING: LIQUID COOLING\nDO NOT FIGHT NEAR THE RACKS", Vector3(5.5, 2.6, -4.65), 0.13, Color(1.0, 0.85, 0.2), true)
	_light(Vector3(0, 3.2, -3.8), Color(0.55, 0.8, 1.0), 2.5, 9.0)


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
	# Long tables with trays at the back and the sides, people having lunch.
	var table_mat := _mat(Color(0.85, 0.83, 0.78), 0.5)
	var chair_colors := [Color(0.9, 0.45, 0.1), Color(0.1, 0.55, 0.6), Color(0.85, 0.75, 0.15)]
	var shirt_colors := [Color(0.2, 0.3, 0.6), Color(0.6, 0.2, 0.2), Color(0.25, 0.5, 0.3), Color(0.5, 0.5, 0.52), Color(0.7, 0.6, 0.3)]
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for spot: Vector3 in [Vector3(-4.5, 0, -6.0), Vector3(0.0, 0, -6.0), Vector3(4.5, 0, -6.0), Vector3(-7.0, 0, -2.0), Vector3(7.0, 0, -2.0)]:
		_box(Vector3(3.2, 0.05, 1.0), spot + Vector3(0, 0.75, 0), table_mat)
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
	_box(Vector3(16.0, 5.0, 0.2), Vector3(0, 1.5, -9.0), _mat(Color(0.7, 0.64, 0.54), 0.8))
	for x in [-7.0, -5.6, 5.6, 7.0]:
		_box(Vector3(0.9, 3.0, 0.04), Vector3(x, 2.2, -8.85), _mat(Color(0.12, 0.18, 0.45) if absf(x) > 6.0 else Color(0.6, 0.1, 0.12), 0.8))
	_label("SUBCOMMITTEE ON ARTIFICIAL INTELLIGENCE", Vector3(0, 3.4, -8.85), 0.36, Color(0.95, 0.78, 0.35), true)
	_light(Vector3(0, 3.0, -5.0), Color(1.0, 0.9, 0.75), 3.0, 10.0)
	_label("IN SESSION", Vector3(0, 2.75, -8.85), 0.22, Color(0.95, 0.25, 0.2), true)


# --- Helpers ---------------------------------------------------------------------------

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
