extends SceneTree
## Builds every super prop in docs/TASKS.md tasks O2a-O2f and O7.
## Run: godot --headless --path . -s res://tools/build_super_props.gd
## Writes res://assets/props/supers/<fighter_id>/<prop>.tscn
## Contract §3.1: root Node3D, no scripts, metres, origin at bottom centre,
## front faces -Z. Child names match the task contract exactly.

const PROP_DIR := "res://assets/props/supers/"

func _initialize() -> void:
	var only := OS.get_cmdline_user_args() # e.g. `-- donald`: rebuild just these folders
	if only.is_empty() or "tesla" in only:
		_build_tesla_props()
	if only.is_empty() or "donald" in only:
		_build_donald_props()
	if only.is_empty() or "jensen" in only:
		_build_jensen_props()
	quit()

# --- Materials ---------------------------------------------------------------

func _metal(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = roughness
	return m

func _rubber(color: Color) -> StandardMaterial3D:
	return _metal(color, 0.05, 0.9)

func _cloth(color: Color) -> StandardMaterial3D:
	return _metal(color, 0.0, 0.95)

func _glow(color: Color, energy: float) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	return m

func _pastel(color: Color) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = color
	return m

# --- Mesh helpers ------------------------------------------------------------

func _mesh(mesh: Mesh, position: Vector3, material: Material, name: String = "",
		rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = position
	mi.material_override = material
	mi.rotation = rotation
	if name != "":
		mi.name = name
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi

func _box(size: Vector3, position: Vector3, material: Material, name: String = "") -> MeshInstance3D:
	var box: BoxMesh = BoxMesh.new()
	box.size = size
	return _mesh(box, position, material, name)

func _cylinder(top: float, bottom: float, height: float, position: Vector3,
		material: Material, name: String = "", rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var cyl: CylinderMesh = CylinderMesh.new()
	cyl.top_radius = top
	cyl.bottom_radius = bottom
	cyl.height = height
	cyl.radial_segments = 16
	return _mesh(cyl, position, material, name, rotation)

func _sphere(radius: float, position: Vector3, material: Material, name: String = "") -> MeshInstance3D:
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = radius
	sphere.radial_segments = 16
	return _mesh(sphere, position, material, name)

# =============================================================================
# O2a - tesla man props
# =============================================================================

func _build_tesla_props() -> void:
	_dir_for("tesla")
	_steel_pickup()
	_rocket()
	_mini_rocket()
	_mars_flag()

## Angular stainless-steel pickup truck (our own design, no badge).
## ~5.6 m long, front = -Z. Wheels: Wheel_FL, Wheel_FR, Wheel_RL, Wheel_RR.
## Child Headlights: emissive strip at the front.
func _steel_pickup() -> void:
	var root: Node3D = Node3D.new()
	root.name = "SteelPickup"
	var steel := _metal(Color(0.74, 0.76, 0.79), 0.85, 0.25)
	var steel_dark := _metal(Color(0.50, 0.52, 0.55), 0.90, 0.20)
	var glass := _metal(Color(0.06, 0.08, 0.10), 0.15, 0.15)
	var headlight := _glow(Color(1.0, 1.0, 1.0), 9.0)
	var taillight := _glow(Color(1.0, 0.08, 0.08), 6.0)
	var tyre := _rubber(Color(0.03, 0.03, 0.04))
	var spoke_metal := _metal(Color(0.55, 0.56, 0.58), 0.85, 0.3)

	root.add_child(_box(Vector3(2.05, 0.5, 5.2), Vector3(0, 0.75, 0), steel))            # chassis
	root.add_child(_box(Vector3(1.9, 1.55, 2.0), Vector3(0, 1.9, -1.15), steel))          # cab
	root.add_child(_box(Vector3(2.0, 0.65, 1.5), Vector3(0, 1.3, -2.5), steel))           # hood
	root.add_child(_box(Vector3(1.8, 0.45, 1.4), Vector3(0, 2.65, -1.15), steel))         # roof
	root.add_child(_box(Vector3(1.75, 0.55, 0.05), Vector3(0, 2.25, -3.08), glass))        # windscreen
	root.add_child(_box(Vector3(1.7, 0.08, 0.05), Vector3(0, 1.1, -3.09), headlight, "Headlights"))
	root.add_child(_box(Vector3(1.7, 0.08, 0.05), Vector3(0, 1.1, 3.09), taillight))
	root.add_child(_box(Vector3(2.15, 0.35, 0.12), Vector3(0, 0.9, -3.18), steel_dark))   # front bumper
	root.add_child(_box(Vector3(2.15, 0.35, 0.12), Vector3(0, 0.9, 3.18), steel_dark))    # rear bumper
	root.add_child(_box(Vector3(1.85, 0.12, 2.4), Vector3(0, 0.8, 1.5), steel))            # bed floor
	root.add_child(_box(Vector3(2.05, 0.8, 0.1), Vector3(0, 1.2, 2.72), steel))            # tailgate
	root.add_child(_box(Vector3(0.1, 0.8, 2.6), Vector3(-0.975, 1.2, 1.5), steel))        # bed rail left
	root.add_child(_box(Vector3(0.1, 0.8, 2.6), Vector3(0.975, 1.2, 1.5), steel))         # bed rail right
	# Fenders + wheels: front corners at -Z, rear at +Z.
	for corner in [[-1, -1], [1, -1], [-1, 1], [1, 1]]:
		var side: float = corner[0]
		var rear: float = corner[1]
		var wx: float = 0.92 * side
		var wz: float = 1.75 * rear
		var wheel_name: String = "Wheel_FL" if side < 0 and rear < 0 else "Wheel_FR" if side > 0 and rear < 0 else "Wheel_RL" if side < 0 else "Wheel_RR"
		root.add_child(_box(Vector3(0.75, 0.4, 0.6), Vector3(wx, 0.85, wz), steel_dark))  # fender
		var wheel := _cylinder(0.45, 0.45, 0.38, Vector3(wx, 0.45, wz), tyre, "", Vector3(0.0, 0.0, PI * 0.5))
		wheel.name = wheel_name
		root.add_child(wheel)
		var spoke := _box(Vector3(0.55, 0.42, 0.1), Vector3.ZERO, spoke_metal)
		spoke.rotation.z = PI * 0.2
		wheel.add_child(spoke)

	_save(root, PROP_DIR + "tesla/steel_pickup.tscn")

## ~8 m rocket, nose up. `Flame` at the nozzle (hidden until lit); `ChainPoint`
## Marker3D on its +Z side where a fighter is chained.
func _rocket() -> void:
	var root: Node3D = Node3D.new()
	root.name = "Rocket"
	var hull := _metal(Color(0.9, 0.9, 0.92), 0.45, 0.3)
	var hull_dark := _metal(Color(0.6, 0.62, 0.65), 0.6, 0.35)
	var band := _glow(Color(0.2, 0.5, 1.0), 3.0)
	var flame_outer := _glow(Color(1.0, 0.45, 0.08), 2.0)
	var flame_inner := _glow(Color(1.0, 0.85, 0.45), 3.0)

	var body := _cylinder(0.52, 0.57, 6.0, Vector3(0, 3.0, 0), hull, "", Vector3.ZERO)   # stands on Y, bottom at y=0
	root.add_child(body)
	var nose := _cylinder(0.0, 0.52, 1.9, Vector3(0, 6.95, 0), hull, "", Vector3.ZERO)   # wide end at y=6.0, tip near 7.9
	root.add_child(nose)
	root.add_child(_box(Vector3(1.7, 0.04, 0.04), Vector3(0, 6.0, 0), band))  # blue band at the joint
	for i in 3:
		var angle := TAU * i / 3.0
		var fin := _box(Vector3(0.08, 1.05, 0.85), Vector3.ZERO, hull_dark)
		fin.position = Vector3(0, 1.1, 0.72) + Vector3(0, 0, 0.72).rotated(Vector3.UP, angle)
		fin.rotation.y = angle
		root.add_child(fin)
	var flame := Node3D.new()
	flame.name = "Flame"
	flame.position = Vector3(0, 0.2, 0)
	flame.visible = false
	flame.add_child(_cylinder(0.0, 0.055, 0.4, Vector3(0, 0.2, 0), flame_outer))   # nozzle flame, hangs down
	flame.add_child(_cylinder(0.0, 0.03, 0.25, Vector3(0, 0.125, 0), flame_inner))
	root.add_child(flame)
	var chain_point := Marker3D.new()
	chain_point.name = "ChainPoint"
	chain_point.position = Vector3(0, 1.6, 0.85)
	root.add_child(chain_point)

	_save(root, PROP_DIR + "tesla/rocket.tscn")

## ~0.6 m power-move rocket shot. Nose toward -Z, `Flame` at the back (+Z).
func _mini_rocket() -> void:
	var root: Node3D = Node3D.new()
	root.name = "MiniRocket"
	var shift := 0.065   # so the bottom sits at y=0
	var white := _metal(Color(0.9, 0.9, 0.92), 0.1, 0.4)
	var red := _metal(Color(0.85, 0.15, 0.12), 0.2, 0.4)
	var dark := _metal(Color(0.12, 0.12, 0.14), 0.3, 0.4)
	var flame_outer := _glow(Color(1.0, 0.45, 0.08), 2.5)
	var flame_inner := _glow(Color(1.0, 0.85, 0.45), 3.0)

	root.add_child(_cylinder(0.065, 0.065, 0.38, Vector3(0, shift, 0), white, "", Vector3(PI * 0.5, 0.0, 0.0)))      # body
	root.add_child(_cylinder(0.0, 0.065, 0.18, Vector3(0, shift, -0.28), red, "", Vector3(-PI * 0.5, 0.0, 0.0)))  # nose cone
	root.add_child(_cylinder(0.068, 0.068, 0.04, Vector3(0, shift, -0.06), dark, "", Vector3(PI * 0.5, 0.0, 0.0)))   # tip ring
	for i in 3:
		var angle := TAU * i / 3.0
		var fin := _box(Vector3(0.015, 0.11, 0.13), Vector3.ZERO, red)
		fin.position = Vector3(0, 0.09 + shift, 0.15).rotated(Vector3.FORWARD, angle)
		fin.rotation.z = -angle
		root.add_child(fin)
	var flame := Node3D.new()
	flame.name = "Flame"
	flame.position = Vector3(0, shift, 0.19)
	flame.add_child(_cylinder(0.0, 0.055, 0.26, Vector3(0, shift, 0.32), flame_outer, "", Vector3(PI * 0.5, 0.0, 0.0)))
	flame.add_child(_cylinder(0.0, 0.03, 0.16, Vector3(0, shift, 0.24), flame_inner, "", Vector3(PI * 0.5, 0.0, 0.0)))
	root.add_child(flame)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.6, 0.2)
	light.light_energy = 0.35
	light.omni_range = 1.0
	light.position = Vector3(0, shift, 0.5)
	root.add_child(light)

	_save(root, PROP_DIR + "tesla/mini_rocket.tscn")

## ~2.5 m pole with a white `Cloth` child (blank space for "CAPTURED").
func _mars_flag() -> void:
	var root: Node3D = Node3D.new()
	root.name = "MarsFlag"
	var pole := _metal(Color(0.55, 0.57, 0.6), 0.6, 0.35)
	var gold := _glow(Color(1.0, 0.8, 0.25), 2.0)
	var cloth := _cloth(Color(0.96, 0.97, 1.0))

	root.add_child(_cylinder(0.025, 0.025, 2.5, Vector3(0, 1.25, 0), pole, "", Vector3.ZERO))   # pole stands on y=0
	root.add_child(_sphere(0.045, Vector3(0, 2.57, 0), gold))                  # finial
	var flag := Node3D.new()
	flag.name = "Cloth"
	flag.position = Vector3(0.72, 2.05, 0)
	flag.rotation.y = 0.15
	flag.add_child(_box(Vector3(1.4, 0.85, 0.02), Vector3.ZERO, cloth))
	root.add_child(flag)

	_save(root, PROP_DIR + "tesla/mars_flag.tscn")

# =============================================================================
# O2b - donald props
# =============================================================================

func _build_donald_props() -> void:
	_dir_for("donald")
	_shipping_container()
	_tariff_stamp()
	_office_desk()
	_us_flag()
	_tariff_mark()

## Cartoon shipping container, ~1.2 x 0.5 x 0.5 m: corrugated long sides, doors at the
## +X end, a raised blank panel on both long sides for the word IMPORTS.
## Front = -Z.
func _shipping_container() -> void:
	var root: Node3D = Node3D.new()
	root.name = "ShippingContainer"
	var body_color := Color(0.62, 0.18, 0.10)
	var corrugation := _metal(body_color.darkened(0.18), 0.25, 0.6)
	var frame := _metal(body_color.darkened(0.38), 0.3, 0.55)
	var doors := _metal(body_color.darkened(0.52), 0.35, 0.5)
	var lock := _metal(Color(0.55, 0.56, 0.58), 0.85, 0.35)
	var panel := _metal(body_color.darkened(0.12), 0.2, 0.65)

	root.add_child(_box(Vector3(1.14, 0.46, 0.46), Vector3(0, 0.25, 0), frame, "Body"))
	root.add_child(_box(Vector3(1.2, 0.04, 0.5), Vector3(0, 0.48, 0), frame, "Roof"))
	root.add_child(_box(Vector3(1.2, 0.04, 0.5), Vector3(0, 0.02, 0), frame, "Floor"))
	# Vertical corrugation along both long sides (front/back are Z, so the ridges face Z).
	for side in [-1.0, 1.0]:
		for i in 13:
			var x := -0.51 + 0.085 * i
			root.add_child(_box(Vector3(0.032, 0.4, 0.018), Vector3(x, 0.25, 0.235 * side), corrugation))
		# Raised blank panel (the IMPORTS sign area).
		root.add_child(_box(Vector3(0.78, 0.28, 0.012), Vector3(0, 0.25, 0.246 * side), panel, "Panel" if side < 0 else "PanelBack"))
		var sign := Label3D.new()
		sign.name = "Imports" if side < 0 else "ImportsBack"
		sign.text = "IMPORTS"
		sign.font_size = 72
		sign.pixel_size = 0.0024
		sign.modulate = Color(0.97, 0.93, 0.84)
		sign.outline_size = 0
		sign.shaded = false
		sign.double_sided = false
		sign.position = Vector3(0, 0.25, 0.253 * side)
		sign.rotation.y = 0.0 if side > 0.0 else PI
		root.add_child(sign)
	# Doors at the +X end: two leaves, hinges on the outer edges and locking bars.
	for z in [-0.1155, 0.1155]:
		root.add_child(_box(Vector3(0.022, 0.44, 0.222), Vector3(0.581, 0.25, z), doors, "Door"))
	root.add_child(_box(Vector3(0.03, 0.44, 0.012), Vector3(0.584, 0.25, 0), frame))
	for z in [-0.21, 0.21]:
		for y in [0.08, 0.42]:
			root.add_child(_box(Vector3(0.04, 0.055, 0.03), Vector3(0.596, y, z), lock))
	for z in [-0.07, 0.07]:
		root.add_child(_box(Vector3(0.035, 0.36, 0.018), Vector3(0.596, 0.25, z), lock))
		root.add_child(_box(Vector3(0.04, 0.03, 0.05), Vector3(0.596, 0.1, z), lock))
		root.add_child(_box(Vector3(0.04, 0.03, 0.05), Vector3(0.596, 0.4, z), lock))
	# Small corner castings, like a real container.
	for x in [-0.57, 0.57]:
		for z in [-0.22, 0.22]:
			for y in [0.045, 0.455]:
				root.add_child(_box(Vector3(0.06, 0.07, 0.06), Vector3(x, y, z), frame))

	_save(root, PROP_DIR + "donald/shipping_container.tscn")

## Giant rubber stamp: red rubber base on a wooden block, wooden handle and knob. Origin
## at the middle of the rubber base's underside; the underside reads TARIFF mirrored.
func _tariff_stamp() -> void:
	var root: Node3D = Node3D.new()
	root.name = "TariffStamp"
	var rubber := _rubber(Color(0.72, 0.07, 0.07))
	var rubber_dark := _rubber(Color(0.48, 0.04, 0.04))
	var wood := _metal(Color(0.42, 0.24, 0.11), 0.0, 0.45)
	var wood_dark := _metal(Color(0.30, 0.16, 0.07), 0.0, 0.5)
	var brass := _metal(Color(0.82, 0.62, 0.25), 0.9, 0.3)

	# Rubber base: a flat slab with a slightly inset sole, so the print edge reads.
	root.add_child(_box(Vector3(1.7, 0.5, 1.2), Vector3(0, 0.27, 0), rubber, "Base"))
	root.add_child(_box(Vector3(1.62, 0.04, 1.12), Vector3(0, 0.02, 0), rubber_dark, "Sole"))
	# Wooden mounting block and top plate.
	root.add_child(_box(Vector3(1.78, 0.1, 1.28), Vector3(0, 0.57, 0), wood_dark))
	root.add_child(_box(Vector3(1.62, 0.08, 1.12), Vector3(0, 0.5, 0), wood))
	root.add_child(_box(Vector3(1.9, 0.12, 1.4), Vector3(0, 0.66, 0), wood, "Plate"))
	root.add_child(_box(Vector3(0.24, 0.04, 0.24), Vector3(0, 0.735, 0), brass, "Collar"))
	# Handle rod and knob.
	root.add_child(_cylinder(0.16, 0.2, 1.4, Vector3(0, 1.42, 0), wood, "Handle"))
	root.add_child(_cylinder(0.12, 0.12, 0.08, Vector3(0, 2.14, 0), wood_dark))
	var knob: MeshInstance3D = _mesh(SphereMesh.new(), Vector3(0, 2.32, 0), wood, "Knob")
	(knob.mesh as SphereMesh).radius = 0.36
	(knob.mesh as SphereMesh).height = 0.72
	knob.scale = Vector3(1.0, 0.85, 1.0)
	root.add_child(knob)
	# TARIFF on the underside, mirrored like a real rubber stamp.
	var label := Label3D.new()
	label.name = "Underside"
	label.text = "TARIFF"
	label.font_size = 112
	label.pixel_size = 0.0034
	label.modulate = Color(0.95, 0.9, 0.86)
	label.outline_size = 0
	label.shaded = false
	label.double_sided = false
	label.scale = Vector3(-1.0, 1.0, 1.0) # mirror image, like a rubber stamp
	label.rotation_degrees = Vector3(90, 0, 0) # faces down
	label.position = Vector3(0, -0.002, 0)
	root.add_child(label)

	_save(root, PROP_DIR + "donald/tariff_stamp.tscn")

## Big dark-wood executive desk, 2.4 x 1.2 m and 0.78 m high: overhanging top, two
## drawer pedestals, a modesty panel and brass pulls. Front = -Z.
func _office_desk() -> void:
	var root: Node3D = Node3D.new()
	root.name = "OfficeDesk"
	var wood := _metal(Color(0.13, 0.07, 0.035), 0.0, 0.32)
	var wood_light := _metal(Color(0.19, 0.11, 0.06), 0.0, 0.4)
	var wood_dark := _metal(Color(0.08, 0.04, 0.02), 0.0, 0.45)
	var brass := _metal(Color(0.78, 0.6, 0.28), 0.9, 0.3)

	# Top with a rounded-looking lip and a darker edge band.
	root.add_child(_box(Vector3(2.4, 0.07, 1.2), Vector3(0, 0.75, 0), wood, "Top"))
	root.add_child(_box(Vector3(2.44, 0.025, 1.24), Vector3(0, 0.71, 0), wood_dark))
	root.add_child(_box(Vector3(2.36, 0.02, 1.16), Vector3(0, 0.79, 0), wood_light))
	# Pedestals, each with three drawer fronts and brass pulls.
	for side in [-1.0, 1.0]:
		var x: float = 0.85 * side
		root.add_child(_box(Vector3(0.56, 0.68, 1.02), Vector3(x, 0.34, 0), wood_dark, "Pedestal"))
		for i in 3:
			var y: float = 0.17 + 0.22 * i
			root.add_child(_box(Vector3(0.5, 0.18, 0.03), Vector3(x, y, -0.52), wood))
			root.add_child(_box(Vector3(0.24, 0.022, 0.03), Vector3(x, y, -0.54), brass))
	# Modesty panel between the pedestals (at the back, +Z), and a plinth.
	root.add_child(_box(Vector3(1.16, 0.5, 0.06), Vector3(0, 0.4, 0.45), wood, "Modesty"))
	root.add_child(_box(Vector3(2.2, 0.06, 0.9), Vector3(0, 0.03, 0.02), wood_dark))

	_save(root, PROP_DIR + "donald/office_desk.tscn")

## Flag on a pole (like the victory stand-in): silver pole, gold finial and a `Cloth`
## child hinged at the pole so the victory scene can swing it. Stars and stripes, no logo.
func _us_flag() -> void:
	var root: Node3D = Node3D.new()
	root.name = "UsaFlag"
	var pole := _metal(Color(0.82, 0.83, 0.86), 0.9, 0.28)
	var gold := _metal(Color(1.0, 0.8, 0.25), 0.9, 0.3)
	var red := _cloth(Color(0.78, 0.1, 0.16))
	var white := _cloth(Color(0.96, 0.96, 0.94))
	var blue := _cloth(Color(0.1, 0.16, 0.48))

	root.add_child(_cylinder(0.04, 0.05, 4.2, Vector3(0, 2.1, 0), pole, "Pole"))
	root.add_child(_cylinder(0.09, 0.12, 0.08, Vector3(0, 0.04, 0), gold, "Foot"))
	root.add_child(_sphere(0.09, Vector3(0, 4.25, 0), gold, "Finial"))
	var cloth := Node3D.new()
	cloth.name = "Cloth"
	cloth.position = Vector3(0.0, 3.75, 0.0)
	cloth.rotation.y = 0.0
	root.add_child(cloth)
	var stripe: float = 1.4 / 13.0
	for i in 13:
		cloth.add_child(_box(Vector3(2.1, stripe, 0.025), Vector3(1.05, 0.7 - stripe * (i + 0.5), 0.0),
			red if i % 2 == 0 else white))
	cloth.add_child(_box(Vector3(0.84, stripe * 7.0, 0.032), Vector3(0.42, 0.7 - stripe * 3.5, 0.0), blue, "Canton"))
	for row in 4:
		for col in 5:
			cloth.add_child(_box(Vector3(0.06, 0.06, 0.04), Vector3(0.1 + col * 0.15, 0.62 - row * 0.14, 0.0), white))

	_save(root, PROP_DIR + "donald/us_flag.tscn")

## Flat red TARIFF mark for the desk after the slam (the scene's `donald/tariff_mark`).
func _tariff_mark() -> void:
	var root: Node3D = Node3D.new()
	root.name = "TariffMark"
	root.add_child(_box(Vector3(1.9, 0.01, 1.4), Vector3(0, 0.005, 0), _rubber(Color(0.82, 0.08, 0.08))))
	root.add_child(_box(Vector3(1.62, 0.012, 1.12), Vector3(0, 0.011, 0), _cloth(Color(0.96, 0.92, 0.84))))
	var label := Label3D.new()
	label.name = "Text"
	label.text = "TARIFF"
	label.font_size = 96
	label.pixel_size = 0.0068
	label.modulate = Color(0.82, 0.07, 0.07)
	label.outline_size = 0
	label.shaded = false
	label.rotation_degrees = Vector3(-90, 0, 0) # faces up
	label.position = Vector3(0, 0.02, 0)
	root.add_child(label)
	_save(root, PROP_DIR + "donald/tariff_mark.tscn")

# =============================================================================
# O2c - jensen props
# =============================================================================

func _build_jensen_props() -> void:
	_dir_for("jensen")
	_leather_jacket()

## Open black leather jacket, spread out with the sleeves out (for the tornado super):
## back and side panels, two flared front panels with open zip edges, collar and lapels,
## bent sleeves with cuffs and a dark lining. About 1.9 m across and 1.0 m tall.
## Origin at the middle of the chest, like the scene's stand-in (the scene puts it on
## Jensen's chest); front = -Z.
func _leather_jacket() -> void:
	var root: Node3D = Node3D.new()
	root.name = "LeatherJacket"
	var leather := _metal(Color(0.145, 0.125, 0.13), 0.16, 0.34)
	var leather_light := _metal(Color(0.2, 0.175, 0.18), 0.12, 0.27)
	var lining := _cloth(Color(0.07, 0.058, 0.058))
	var zip := _metal(Color(0.72, 0.74, 0.78), 1.0, 0.22)
	var buckle := _metal(Color(0.55, 0.56, 0.6), 0.9, 0.3)
	var tag := _metal(Color(0.55, 0.09, 0.07), 0.05, 0.55)

	root.add_child(_box(Vector3(0.72, 0.78, 0.09), Vector3(0, 0.0, 0.1), leather, "Back"))
	root.add_child(_box(Vector3(0.62, 0.12, 0.02), Vector3(0, 0.3, 0.045), leather_light, "Yoke"))
	root.add_child(_box(Vector3(0.5, 0.64, 0.02), Vector3(0, -0.02, 0.045), lining, "Lining"))
	for side in [-1.0, 1.0]:
		# Side panel from the back around the ribs, under the arm.
		root.add_child(_box(Vector3(0.15, 0.6, 0.34), Vector3(0.42 * side, -0.02, 0.08), leather, "Side"))
		# Front panel, flared open: the zip edge runs down its inner side.
		var flap := _box(Vector3(0.31, 0.76, 0.06), Vector3(0.27 * side, -0.01, -0.1), leather_light, "Front")
		flap.rotation.y = -0.34 * side
		root.add_child(flap)
		var zip_line := _box(Vector3(0.022, 0.74, 0.02), Vector3(0.115 * side, -0.01, -0.145), zip, "Zip")
		zip_line.rotation.y = -0.34 * side
		root.add_child(zip_line)
		# Piping along the outer edge of the front panel.
		var piping := _box(Vector3(0.016, 0.74, 0.02), Vector3(0.41 * side, -0.01, -0.155), leather, "Piping")
		piping.rotation.y = -0.34 * side
		root.add_child(piping)
		# A small welt pocket on the chest.
		root.add_child(_box(Vector3(0.14, 0.025, 0.03), Vector3(0.31 * side, -0.16, -0.165), leather, "Welt"))
		# Rounded shoulder, collar wing and lapel.
		var shoulder := _sphere(0.15, Vector3(0.35 * side, 0.33, 0.02), leather, "Shoulder")
		shoulder.scale = Vector3(1.1, 0.6, 1.0)
		root.add_child(shoulder)
		var collar := _box(Vector3(0.24, 0.13, 0.08), Vector3(0.12 * side, 0.44, -0.02), leather_light, "Collar")
		collar.rotation.z = 0.38 * side
		collar.rotation.y = -0.3 * side
		root.add_child(collar)
		var lapel := _box(Vector3(0.2, 0.33, 0.035), Vector3(0.2 * side, 0.27, -0.14), leather_light, "Lapel")
		lapel.rotation.z = 0.14 * side
		lapel.rotation.y = -0.42 * side
		root.add_child(lapel)
		# Sleeve: upper arm out and slightly down, forearm further out and down, cuff.
		var upper := _cylinder(0.12, 0.1, 0.62, Vector3(0.55 * side, 0.17, 0.03),
			leather, "Sleeve", Vector3(0, 0, -1.83 * side))
		root.add_child(upper)
		var lower := _cylinder(0.1, 0.085, 0.5, Vector3(0.93 * side, -0.06, 0.02),
			leather_light, "SleeveLower", Vector3(0, 0, -2.27 * side))
		root.add_child(lower)
		var cuff := _cylinder(0.095, 0.1, 0.1, Vector3(1.11 * side, -0.22, 0.02),
			leather, "Cuff", Vector3(0, 0, -2.27 * side))
		root.add_child(cuff)
		var cuff_seam := _cylinder(0.101, 0.101, 0.018, Vector3(1.08 * side, -0.2, 0.02),
			leather_light, "CuffSeam", Vector3(0, 0, -2.27 * side))
		root.add_child(cuff_seam)
		# Waistband and a buckle at each side.
		var band := _box(Vector3(0.34, 0.09, 0.07), Vector3(0.19 * side, -0.4, -0.08), leather_light, "Waistband")
		band.rotation.y = -0.2 * side
		root.add_child(band)
		root.add_child(_box(Vector3(0.07, 0.06, 0.025), Vector3(0.34 * side, -0.4, -0.1), buckle, "Buckle"))
	# Zipper pull at the top of the left zip, and a small red maker's tag.
	root.add_child(_box(Vector3(0.026, 0.07, 0.014), Vector3(-0.085, 0.34, -0.16), zip, "ZipPull"))
	root.add_child(_box(Vector3(0.07, 0.05, 0.012), Vector3(0.3, -0.3, -0.16), tag, "Tag"))

	_save(root, PROP_DIR + "jensen/leather_jacket.tscn")

## Makes sure every node below `root` is owned by `root` so PackedScene.pack()
## keeps the whole subtree (see tools/build_custom_hair.gd).
func _claim_ownership(root: Node) -> void:
	var stack: Array[Node] = [root]
	while stack.size() > 0:
		var node: Node = stack.pop_front()
		for child: Node in node.get_children():
			child.owner = root
			stack.append(child)

func _save(root: Node3D, path: String) -> void:
	_claim_ownership(root)
	var scene: PackedScene = PackedScene.new()
	scene.pack(root)
	var err: Error = ResourceSaver.save(scene, path)
	if err != OK:
		push_error("build_super_props: failed to save %s: %d" % [path, err])
	else:
		print("saved %s" % path)

func _dir_for(fighter: String) -> String:
	var dir: String = PROP_DIR + fighter + "/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	return dir