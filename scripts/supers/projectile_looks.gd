class_name ProjectileLooks
extends RefCounted
## Modelled shots for supers and specials (MoveData.projectile_look), built from simple
## meshes in code: a search bar, a graphics card. Cosmetic only: the simulation never reads
## them. Projectile builds one in _ready() and calls animate() every frame.
##
## To add a look: a case in build(), orient() and animate(). Bigger props (3D models from
## assets/props/supers/, docs/TASKS.md O2) can replace these later.

const PROP_DIR := "res://assets/props/supers/"

const SEARCH_QUERIES := ["how to win a fight", "am I losing?", "best combo 2026", "ten blue links",
	"is it over?", "near me: pain"]


static func _load_prop(subpath: String) -> Node3D:
	var path := PROP_DIR + subpath + ".tscn"
	if ResourceLoader.exists(path):
		var scene := load(path) as PackedScene
		if scene:
			return scene.instantiate() as Node3D
	return null


static func build(look: StringName, color: Color) -> Node3D:
	match look:
		&"search_bar":
			return _search_bar(color)
		&"gpu":
			return _gpu(color)
		&"container":
			return _container(color)
		&"mini_rocket":
			return _mini_rocket(color)
		&"paper_dragon":
			return _paper_dragon(color)
		&"rulebook":
			return _rulebook(color)
	push_warning("ProjectileLooks: unknown look %s" % look)
	return Node3D.new()


## Starting rotation: a search bar faces the camera (animate keeps it so); a GPU starts
## tumbled at an angle picked from `seed_value` (cosmetic).
static func orient(look: StringName, direction: Vector3, seed_value: int) -> Basis:
	if look == &"paper_dragon":
		var flat := Vector3(direction.x, 0.0, direction.z)
		return Basis.looking_at(flat.normalized()) if flat.length_squared() > 0.001 else Basis.IDENTITY
	if look == &"mini_rocket" or look == &"rulebook":
		# Nose (-Z) along the flight direction.
		return Basis.looking_at(direction.normalized() if direction.length_squared() > 0.001 else Vector3.FORWARD)
	if look == &"gpu" or look == &"container":
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		if look == &"container":
			return Basis.from_euler(Vector3(0.0, 0.0, rng.randf() * TAU))
		return Basis.from_euler(Vector3(rng.randf_range(-0.6, 0.6), rng.randf() * TAU, rng.randf_range(-0.6, 0.6)))
	return Basis.IDENTITY


static func animate(node: Node3D, look: StringName, direction: Vector3, age: float, delta: float) -> void:
	match look:
		&"search_bar":
			# Pops in, then faces the camera with a slight wobble as it flies.
			var pop := clampf(age / 0.12, 0.0, 1.0)
			var camera := node.get_viewport().get_camera_3d() if node.is_inside_tree() else null
			if camera:
				var away := node.global_position - camera.global_position
				if away.length_squared() > 0.001:
					node.global_basis = Basis.looking_at(away.normalized()) * Basis(Vector3.FORWARD, 0.08 * sin(age * 9.0))
			node.scale = Vector3.ONE * lerpf(0.3, 1.0, pop)
		&"mini_rocket":
			# The exhaust flame flickers.
			var flame := node.get_node_or_null("Flame") as Node3D
			if flame:
				flame.scale = Vector3(1.0 + 0.25 * sin(age * 70.0), 1.0 + 0.25 * sin(age * 70.0), 1.0 + 0.4 * sin(age * 53.0 + 1.0))
		&"container":
			# Tumbles end over end along its flight.
			node.rotate(Vector3(0, 0, 1), -5.0 * delta)
		&"paper_dragon":
			# The body weaves up and down behind the head like dancers carrying it.
			for part: Node in node.get_children():
				if part is Node3D and part.has_meta(&"segment"):
					var k: int = part.get_meta(&"segment")
					part.position.y = float(part.get_meta(&"rest_y")) + 0.16 * sin(age * 11.0 - k * 0.9)
					part.position.x = 0.08 * sin(age * 6.0 - k * 0.7)
		&"gpu":
			# Tumbles as it falls; the fans spin.
			var axis: Vector3 = node.get_meta(&"tumble_axis", Vector3.RIGHT)
			node.rotate(axis, 4.0 * delta)
			for fan_name in [&"Fan1", &"Fan2"]:
				var fan := node.get_node_or_null(NodePath(fan_name)) as Node3D
				if fan:
					fan.rotate_object_local(Vector3.FORWARD, 30.0 * delta)
		&"rulebook":
			node.rotation.z = 0.08 * sin(age * 7.0)


# --- Mini rocket -----------------------------------------------------------------

## ~0.6 m white rocket: nose toward -Z, flame at the back (+Z).
static func _mini_rocket(_color: Color) -> Node3D:
	var prop := _load_prop("tesla/mini_rocket")
	if prop:
		return prop
	var root := Node3D.new()
	root.name = "MiniRocket"
	var white := _metal(Color(0.9, 0.9, 0.92), 0.1)
	var red := _metal(Color(0.85, 0.15, 0.12), 0.2)
	root.add_child(_cylinder(0.065, 0.065, 0.38, Vector3.ZERO, white))
	root.add_child(_cylinder(0.0, 0.065, 0.18, Vector3(0, 0, -0.28), red, -PI * 0.5))
	root.add_child(_cylinder(0.068, 0.068, 0.04, Vector3(0, 0, -0.06), _metal(Color(0.12, 0.12, 0.14), 0.3)))
	for i in 3:
		var fin := _box(Vector3(0.015, 0.11, 0.13), Vector3.ZERO, red)
		var angle := TAU * i / 3.0
		fin.position = Vector3(0, 0.09, 0.15).rotated(Vector3.FORWARD, angle)
		fin.rotation.z = -angle
		root.add_child(fin)
	var flame := Node3D.new()
	flame.name = "Flame"
	flame.position = Vector3(0, 0, 0.19)
	flame.add_child(_cylinder(0.0, 0.055, 0.26, Vector3(0, 0, 0.13), _glow(Color(1.0, 0.45, 0.08), 2.5)))
	flame.add_child(_cylinder(0.0, 0.03, 0.16, Vector3(0, 0, 0.08), _glow(Color(1.0, 0.85, 0.45), 3.0)))
	root.add_child(flame)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.6, 0.2)
	light.light_energy = 0.35
	light.omni_range = 1.0
	light.position = Vector3(0, 0, 0.5)
	root.add_child(light)
	return root


# --- Shipping container ----------------------------------------------------------

static func _container(color: Color) -> Node3D:
	var prop := _load_prop("donald/shipping_container")
	if prop:
		return prop
	var root := Node3D.new()
	root.name = "Container"
	var body_color := color
	root.add_child(_box(Vector3(1.0, 0.45, 0.45), Vector3.ZERO, _metal(body_color, 0.3)))
	# Thin raised ridges along the long sides.
	for i in 7:
		var x := -0.42 + 0.14 * i
		for z in [-0.228, 0.228]:
			root.add_child(_box(Vector3(0.03, 0.43, 0.012), Vector3(x, 0, z), _metal(body_color.darkened(0.15), 0.3)))
	# Darker door end with a locking bar pair.
	var door_color := body_color.darkened(0.45)
	root.add_child(_box(Vector3(0.02, 0.44, 0.44), Vector3(0.5, 0, 0), _metal(door_color, 0.4)))
	for y in [-0.08, 0.08]:
		root.add_child(_box(Vector3(0.03, 0.02, 0.36), Vector3(0.51, y, 0), _metal(Color(0.6, 0.6, 0.62), 0.8)))
	# "IMPORTS" on both long sides.
	for side in [1.0, -1.0]:
		var text := Label3D.new()
		text.text = "IMPORTS"
		text.font_size = 64
		text.pixel_size = 0.0022
		text.modulate = Color(0.97, 0.95, 0.9)
		text.outline_size = 4
		text.outline_modulate = body_color.darkened(0.6)
		text.shaded = false
		text.double_sided = false
		text.position = Vector3(-0.05, 0.0, 0.236 * side)
		text.rotation.y = 0.0 if side > 0.0 else PI
		root.add_child(text)
	return root


# --- Search bar ------------------------------------------------------------------

static func _search_bar(color: Color) -> Node3D:
	var prop := _load_prop("sundar/search_bar")
	if prop:
		var query := prop.get_node_or_null("Query") as Label3D
		if query:
			query.text = SEARCH_QUERIES[randi() % SEARCH_QUERIES.size()]
		return prop
	var root := Node3D.new()
	root.name = "SearchBar"
	# Coloured outline behind a white pill.
	root.add_child(_box(Vector3(1.78, 0.44, 0.04), Vector3(0, 0, -0.02), _glow(color, 2.0)))
	root.add_child(_box(Vector3(1.7, 0.36, 0.06), Vector3.ZERO, _flat(Color(0.98, 0.98, 1.0))))
	# Magnifying glass on the left.
	var lens := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.055
	torus.outer_radius = 0.085
	lens.mesh = torus
	lens.material_override = _flat(Color(0.35, 0.36, 0.4))
	lens.position = Vector3(-0.7, 0.02, 0.035)
	lens.rotation = Vector3(PI * 0.5, 0, 0)
	root.add_child(lens)
	var handle := _box(Vector3(0.025, 0.09, 0.02), Vector3(-0.64, -0.06, 0.035), _flat(Color(0.35, 0.36, 0.4)))
	handle.rotation.z = PI * 0.25
	root.add_child(handle)
	var text := Label3D.new()
	text.name = "Query"
	text.text = SEARCH_QUERIES[randi() % SEARCH_QUERIES.size()] # cosmetic: any query will do
	text.font_size = 56
	text.pixel_size = 0.0032
	text.modulate = Color(0.22, 0.23, 0.26)
	text.outline_size = 0
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	text.position = Vector3(-0.58, 0.0, 0.035)
	text.shaded = false
	root.add_child(text)
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 2.0
	light.omni_range = 2.5
	root.add_child(light)
	return root


# --- Paper dragon (Xi's power move) ----------------------------------------------

## A festival paper dragon facing -Z: a big red-and-gold head and a weaving body.
static func _paper_dragon(color: Color) -> Node3D:
	var prop := _load_prop("xi/paper_dragon")
	if prop:
		return prop
	var root := Node3D.new()
	root.name = "PaperDragon"
	var red := _metal(color, 0.0)
	var gold := _glow(Color(1.0, 0.78, 0.2), 1.5)
	var head := Node3D.new()
	head.set_meta(&"segment", 0)
	head.set_meta(&"rest_y", 0.0)
	head.add_child(_box(Vector3(0.5, 0.42, 0.6), Vector3(0, 0.05, 0), red))
	head.add_child(_box(Vector3(0.44, 0.12, 0.4), Vector3(0, -0.2, -0.18), red))
	head.add_child(_box(Vector3(0.52, 0.04, 0.62), Vector3(0, -0.13, 0), gold))
	for side: float in [-1.0, 1.0]:
		head.add_child(_box(Vector3(0.1, 0.1, 0.06), Vector3(0.15 * side, 0.17, -0.31), gold))
		var horn := _box(Vector3(0.05, 0.3, 0.05), Vector3(0.14 * side, 0.38, 0.12), gold)
		horn.rotation.x = -0.5
		head.add_child(horn)
		var whisker := _box(Vector3(0.3, 0.02, 0.02), Vector3(0.35 * side, -0.05, -0.28), gold)
		whisker.rotation.z = 0.4 * side
		head.add_child(whisker)
	root.add_child(head)
	for i in 7:
		var segment := Node3D.new()
		var rest_y := -0.02 * i
		segment.set_meta(&"segment", i + 1)
		segment.set_meta(&"rest_y", rest_y)
		segment.position = Vector3(0, rest_y, 0.45 + 0.3 * i)
		var size := 0.4 - 0.025 * i
		segment.add_child(_box(Vector3(size, size, 0.26), Vector3.ZERO, red))
		segment.add_child(_box(Vector3(size + 0.02, 0.05, 0.27), Vector3(0, size * 0.5, 0), gold))
		root.add_child(segment)
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 1.2
	light.omni_range = 2.0
	root.add_child(light)
	return root


# --- Graphics card ---------------------------------------------------------------

static func _gpu(color: Color) -> Node3D:
	var prop := _load_prop("jensen/gpu_card")
	if prop:
		prop.set_meta(&"tumble_axis", Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized())
		return prop
	var root := Node3D.new()
	root.name = "GPU"
	root.set_meta(&"tumble_axis", Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized())
	# Shroud, backplate, glowing accent strip, gold PCIe fingers.
	root.add_child(_box(Vector3(0.95, 0.36, 0.14), Vector3.ZERO, _metal(Color(0.12, 0.12, 0.13), 0.6)))
	root.add_child(_box(Vector3(0.95, 0.36, 0.02), Vector3(0, 0, -0.08), _metal(Color(0.7, 0.72, 0.75), 0.9)))
	root.add_child(_box(Vector3(0.96, 0.03, 0.15), Vector3(0, 0.17, 0), _glow(color, 4.0)))
	root.add_child(_box(Vector3(0.42, 0.05, 0.02), Vector3(-0.12, -0.2, -0.04), _metal(Color(0.95, 0.75, 0.25), 1.0)))
	for i in 2:
		var fan := Node3D.new()
		fan.name = "Fan%d" % (i + 1)
		fan.position = Vector3(-0.22 + 0.44 * i, 0.0, 0.075)
		var ring := MeshInstance3D.new()
		var disc := CylinderMesh.new()
		disc.top_radius = 0.15
		disc.bottom_radius = 0.15
		disc.height = 0.01
		ring.mesh = disc
		ring.rotation.x = PI * 0.5
		ring.material_override = _metal(Color(0.05, 0.05, 0.06), 0.3)
		fan.add_child(ring)
		for b in 5:
			var blade := _box(Vector3(0.025, 0.12, 0.012), Vector3.ZERO, _metal(Color(0.2, 0.2, 0.22), 0.4))
			blade.rotation.z = TAU * b / 5.0
			blade.position = Vector3(0.07, 0, 0.008).rotated(Vector3.FORWARD, -TAU * b / 5.0)
			fan.add_child(blade)
		fan.add_child(_box(Vector3(0.05, 0.05, 0.02), Vector3(0, 0, 0.012), _glow(color, 2.0)))
		root.add_child(fan)
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 1.5
	light.omni_range = 2.0
	root.add_child(light)
	return root


# --- Helpers ---------------------------------------------------------------------

static func _box(size: Vector3, position: Vector3, material: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = position
	mesh.material_override = material
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mesh


## A cylinder / cone along Z (rotation_x PI/2 turns its Y axis onto +Z).
static func _cylinder(top: float, bottom: float, height: float, position: Vector3, material: Material, rotation_x := PI * 0.5) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = top
	cyl.bottom_radius = bottom
	cyl.height = height
	cyl.radial_segments = 12
	mesh.mesh = cyl
	mesh.position = position
	mesh.rotation.x = rotation_x
	mesh.material_override = material
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mesh


# --- Rulebook shield (Dario's power move) ----------------------------------------

## An open glowing hardcover rulebook shield facing forward.
static func _rulebook(color: Color) -> Node3D:
	var prop := _load_prop("dario/rulebook")
	if prop:
		return prop
	var root := Node3D.new()
	root.name = "Rulebook"
	var leather := _flat(Color(0.28, 0.14, 0.08))
	var gold := _glow(Color(1.0, 0.84, 0.35), 2.0)
	var paper := _flat(Color(0.94, 0.92, 0.82))
	# Open book: two angled covers and page blocks forming a V/shield facing forward
	var left_wing := Node3D.new()
	left_wing.position = Vector3(-0.24, 0, 0)
	left_wing.rotation.y = deg_to_rad(22.0)
	left_wing.add_child(_box(Vector3(0.48, 0.65, 0.04), Vector3.ZERO, leather))
	left_wing.add_child(_box(Vector3(0.44, 0.60, 0.06), Vector3(0.02, 0, -0.02), paper))
	root.add_child(left_wing)

	var right_wing := Node3D.new()
	right_wing.position = Vector3(0.24, 0, 0)
	right_wing.rotation.y = deg_to_rad(-22.0)
	right_wing.add_child(_box(Vector3(0.48, 0.65, 0.04), Vector3.ZERO, leather))
	right_wing.add_child(_box(Vector3(0.44, 0.60, 0.06), Vector3(-0.02, 0, -0.02), paper))
	root.add_child(right_wing)

	# Spine in the middle
	root.add_child(_box(Vector3(0.08, 0.66, 0.08), Vector3(0, 0, 0.08), gold))

	# Glowing golden "RULES" shield seal in front of book
	var label := Label3D.new()
	label.text = "RULES\n★ SAFE ★"
	label.font_size = 48
	label.pixel_size = 0.003
	label.modulate = Color(1.0, 0.88, 0.3)
	label.outline_size = 4
	label.outline_modulate = Color(0.15, 0.08, 0.02)
	label.position = Vector3(0, 0, -0.08)
	label.shaded = false
	root.add_child(label)

	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 2.0
	light.omni_range = 2.4
	root.add_child(light)
	return root


static func _flat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = color
	return m


static func _metal(color: Color, metallic: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = 0.35
	return m


static func _glow(color: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	return m
