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
	if only.is_empty() or "zuckerbot" in only:
		_build_zuckerbot_props()
	if only.is_empty() or "sundar" in only:
		_build_sundar_props()
	if only.is_empty() or "xi" in only:
		_build_xi_props()
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
	sphere.height = radius * 2.0
	sphere.radial_segments = 16
	return _mesh(sphere, position, material, name)

func _torus(inner: float, outer: float, position: Vector3, material: Material, name := "",
		rotation := Vector3.ZERO) -> MeshInstance3D:
	var torus: TorusMesh = TorusMesh.new()
	torus.inner_radius = inner
	torus.outer_radius = outer
	torus.rings = 20
	torus.ring_segments = 8
	return _mesh(torus, position, material, name, rotation)

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

# =============================================================================
# O2d - zuckerbot props
# =============================================================================

func _build_zuckerbot_props() -> void:
	_dir_for("zuckerbot")
	_vr_goggles()
	_metaverse_kit()

## Chunky VR goggles: dark shell with a glowing lens strip, rubber face pads, side arms,
## a top strap and a head band. Origin is the point between the eyes, +Z is the front
## (the convention in scripts/supers/zuckerbot_fx.gd, which wears it on the head bone).
func _vr_goggles() -> void:
	var root: Node3D = Node3D.new()
	root.name = "VRGoggles"
	var shell := _metal(Color(0.1, 0.105, 0.12), 0.35, 0.36)
	var shell_top := _metal(Color(0.17, 0.175, 0.2), 0.3, 0.3)
	var rubber := _rubber(Color(0.035, 0.035, 0.04))
	var frame := _metal(Color(0.03, 0.03, 0.035), 0.5, 0.2)
	var lens := _glow(Color(0.12, 0.7, 0.95), 1.2)
	var led := _glow(Color(0.3, 0.95, 0.4), 1.5)
	var strap_mat := _cloth(Color(0.5, 0.51, 0.56))
	var metal := _metal(Color(0.6, 0.62, 0.66), 0.85, 0.3)

	# Face pads leave a notch for the nose.
	root.add_child(_box(Vector3(0.095, 0.1, 0.035), Vector3(-0.052, -0.005, 0.03), rubber, "Pad_L"))
	root.add_child(_box(Vector3(0.095, 0.1, 0.035), Vector3(0.052, -0.005, 0.03), rubber, "Pad_R"))
	root.add_child(_box(Vector3(0.2, 0.03, 0.035), Vector3(0, 0.045, 0.03), rubber, "Pad_Top"))
	# Chunky shell, top vent and the glowing lens behind a dark frame.
	root.add_child(_box(Vector3(0.21, 0.11, 0.07), Vector3(0, 0.005, 0.075), shell, "Visor"))
	root.add_child(_box(Vector3(0.18, 0.035, 0.02), Vector3(0, 0.075, 0.07), shell_top, "Vent"))
	root.add_child(_box(Vector3(0.205, 0.06, 0.018), Vector3(0, 0.0, 0.112), frame, "LensFrame"))
	root.add_child(_box(Vector3(0.17, 0.045, 0.014), Vector3(0, 0.0, 0.12), lens, "Lens"))
	root.add_child(_box(Vector3(0.06, 0.02, 0.01), Vector3(0.075, -0.045, 0.115), led, "LED"))
	root.add_child(_box(Vector3(0.035, 0.035, 0.012), Vector3(0, -0.048, 0.112), frame, "Sensor"))
	for side in [-1.0, 1.0]:
		root.add_child(_box(Vector3(0.03, 0.055, 0.13), Vector3(0.115 * side, 0.0, 0.03), shell, "Arm"))
		root.add_child(_box(Vector3(0.02, 0.04, 0.03), Vector3(0.125 * side, 0.0, -0.03), metal, "StrapMount"))
	# Over-the-head strap and the band around the back.
	var top_strap := _box(Vector3(0.07, 0.018, 0.2), Vector3(0, 0.085, -0.02), shell, "TopStrap")
	top_strap.rotation.x = -0.12
	root.add_child(top_strap)
	var ring := TorusMesh.new()
	ring.inner_radius = 0.1
	ring.outer_radius = 0.118
	ring.rings = 24
	ring.ring_segments = 8
	var band := _mesh(ring, Vector3(0, 0, -0.02), strap_mat, "Strap")
	band.scale = Vector3(1.0, 1.02, 1.2)
	root.add_child(band)
	root.add_child(_box(Vector3(0.045, 0.05, 0.03), Vector3(0, 0, -0.135), metal, "StrapBuckle"))
	root.add_child(_box(Vector3(0.03, 0.022, 0.012), Vector3(-0.075, -0.045, 0.115), frame, "Button"))

	_save(root, PROP_DIR + "zuckerbot/vr_goggles.tscn")

## Cartoon metaverse kit: a small floating island (pastel grass over stacked rock), a tree
## with pastel canopies, three glowing crystals and a little cloud. Low-poly, bright colours.
## Origin at the bottom of the island's rock tip, front = -Z (nothing directional here).
func _metaverse_kit() -> void:
	var kit: Node3D = Node3D.new()
	kit.name = "MetaverseKit"
	var island: Node3D = Node3D.new()
	island.name = "Island"
	var tree: Node3D = Node3D.new()
	tree.name = "Tree"
	var crystals: Node3D = Node3D.new()
	crystals.name = "Crystals"
	var cloud: Node3D = Node3D.new()
	cloud.name = "Cloud"
	kit.add_child(island)
	kit.add_child(tree)
	kit.add_child(crystals)
	kit.add_child(cloud)

	var grass := _metal(Color(0.3, 0.76, 0.48), 0.0, 0.85)
	var grass_dark := _metal(Color(0.2, 0.6, 0.38), 0.0, 0.9)
	var rock_a := _metal(Color(0.63, 0.52, 0.95), 0.0, 0.8)
	var rock_b := _metal(Color(0.47, 0.37, 0.82), 0.0, 0.85)
	var rock_tip := _metal(Color(0.9, 0.48, 0.75), 0.0, 0.8)
	var pond := _glow(Color(0.25, 0.75, 1.0), 0.25)
	var trunk_mat := _metal(Color(0.42, 0.27, 0.17), 0.0, 0.8)
	var leaf_mint := _metal(Color(0.4, 0.9, 0.58), 0.0, 0.8)
	var leaf_pink := _metal(Color(0.95, 0.52, 0.8), 0.0, 0.8)
	var leaf_lemon := _metal(Color(0.95, 0.85, 0.4), 0.0, 0.8)

	# Island: faceted grass slab, a rim, two rock layers and a pointed tip.
	island.add_child(_disk(1.5, 0.08, Vector3(0, 1.36, 0), grass, "Grass", 12))
	island.add_child(_disk(1.56, 0.1, Vector3(0, 1.28, 0), grass_dark, "Rim", 12))
	island.add_child(_disk(1.35, 0.45, Vector3(0, 1.075, 0), rock_a, "RockA", 10, 0.95))
	island.add_child(_disk(1.0, 0.55, Vector3(0, 0.625, 0), rock_b, "RockB", 9, 0.55))
	island.add_child(_disk(0.58, 0.4, Vector3(0, 0.2, 0), rock_tip, "RockTip", 7, 0.05))
	island.add_child(_disk(0.42, 0.02, Vector3(-0.35, 1.405, 0.35), pond, "Pond", 12))
	for i in 4:
		var angle := TAU * i / 4.0 + 0.4
		island.add_child(_cone(0.075, 0.26, Vector3(cos(angle) * 1.1, 1.52, sin(angle) * 1.1),
			grass_dark, "Tuft"))

	# Tree: a warm trunk under four pastel canopy blobs.
	tree.add_child(_cylinder(0.12, 0.22, 1.3, Vector3(0, 2.05, 0), trunk_mat, "Trunk"))
	tree.add_child(_blob(0.62, Vector3(0, 3.0, 0), leaf_mint, "Canopy"))
	tree.add_child(_blob(0.5, Vector3(-0.45, 2.7, 0.25), leaf_pink, "Canopy_L"))
	tree.add_child(_blob(0.46, Vector3(0.44, 2.65, 0.2), leaf_lemon, "Canopy_R"))
	tree.add_child(_blob(0.42, Vector3(0.05, 2.6, -0.35), leaf_pink, "Canopy_Front"))
	tree.add_child(_blob(0.34, Vector3(0.02, 3.45, 0.02), leaf_mint, "Canopy_Top"))

	# Three glowing crystals, each on a little rock.
	var crystal_pink := _glow(Color(1.0, 0.4, 0.75), 0.9)
	var crystal_cyan := _glow(Color(0.3, 0.9, 1.0), 0.9)
	var crystal_lemon := _glow(Color(1.0, 0.9, 0.35), 0.8)
	crystals.add_child(_cluster(Vector3(-0.95, 1.42, 0.25), 0.7, crystal_pink, rock_a))
	crystals.add_child(_cluster(Vector3(-0.7, 1.42, 0.5), 0.5, crystal_cyan, rock_a))
	crystals.add_child(_cluster(Vector3(1.0, 1.42, -0.3), 0.6, crystal_lemon, rock_b))

	# A small cloud off to the side.
	var cloud_mat := _cloth(Color(0.98, 0.98, 1.0))
	cloud.add_child(_blob(0.42, Vector3(2.25, 2.5, 0.1), cloud_mat, "Puff"))
	cloud.add_child(_blob(0.34, Vector3(1.95, 2.42, -0.2), cloud_mat, "Puff_L"))
	cloud.add_child(_blob(0.3, Vector3(2.5, 2.4, -0.15), cloud_mat, "Puff_R"))

	_save(kit, PROP_DIR + "zuckerbot/metaverse_kit.tscn")

## Flat low-poly disc (a cylinder with few sides).
func _disk(top: float, height: float, position: Vector3, material: Material, name := "",
		segments := 10, bottom := -1.0) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom if bottom >= 0.0 else top
	mesh.height = height
	mesh.radial_segments = segments
	return _mesh(mesh, position, material, name)

## Low-poly cone (top radius 0).
func _cone(radius: float, height: float, position: Vector3, material: Material, name := "") -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 6
	return _mesh(mesh, position, material, name)

## Low-poly faceted sphere.
func _blob(radius: float, position: Vector3, material: Material, name := "") -> MeshInstance3D:
	var blob := _sphere(radius, position, material, name)
	var sphere := blob.mesh as SphereMesh
	sphere.radial_segments = 10
	sphere.rings = 6
	return blob

## A crystal spike (with a smaller side spike) on a flattened rock.
func _cluster(at: Vector3, height: float, crystal: Material, rock: Material) -> Node3D:
	var group: Node3D = Node3D.new()
	group.add_child(_disk(0.22, 0.12, at + Vector3(0, 0.02, 0), rock, "Base", 7, 0.26))
	var main := _cone(0.12, height, at + Vector3(0, height * 0.5 + 0.06, 0), crystal, "Crystal")
	main.rotation.z = 0.22
	main.rotation.x = -0.15
	group.add_child(main)
	var side := _cone(0.07, height * 0.6, at + Vector3(0.15, height * 0.3 + 0.06, 0.04), crystal, "CrystalSide")
	side.rotation.z = -0.5
	group.add_child(side)
	return group

# =============================================================================
# O2e - sundar props
# =============================================================================

func _build_sundar_props() -> void:
	_dir_for("sundar")
	_browser_window()

const BROWSER_URL := "https://www.skill-issue.com/you/are/here"
const PAGE_COLOR := Color(0.62, 0.72, 0.9)

## A giant ~4 x 3 m browser window. The scene (`not_found.gd`) looks for these children by
## name: `Url` (Label3D in the address bar), `Progress` (loading bar, scaled in x),
## `PageLoading` and `PageError` (page contents), `PageTint` (page backing, its
## material_override's albedo is changed) and `Inside` (Marker3D where the trapped
## fighter's feet stand). The page faces +Z, like the scene's stand-in (the set's camera
## and the trapped fighter are on that side); the root origin is the floor under the
## window's centre.
func _browser_window() -> void:
	var root: Node3D = Node3D.new()
	root.name = "BrowserWindow"
	var y0 := 0.15
	var frame := _metal(Color(0.16, 0.18, 0.24), 0.35, 0.3)
	var frame_dark := _metal(Color(0.1, 0.12, 0.18), 0.4, 0.28)
	var frame_light := _metal(Color(0.26, 0.29, 0.36), 0.3, 0.35)
	var chrome := _metal(Color(0.08, 0.09, 0.13), 0.5, 0.25)
	var white := _metal(Color(0.94, 0.96, 1.0), 0.0, 0.35)
	var tint_mat := _metal(PAGE_COLOR, 0.0, 0.85)
	var page_beam := _metal(PAGE_COLOR.darkened(0.18), 0.0, 0.85)
	var skeleton := _metal(PAGE_COLOR.darkened(0.28), 0.0, 0.8)
	var ink := _metal(Color(0.12, 0.16, 0.35), 0.0, 0.5)
	var red_glow := _glow(Color(0.95, 0.3, 0.28), 0.8)
	var green_glow := _glow(Color(0.3, 0.8, 0.35), 0.8)
	var yellow_glow := _glow(Color(0.98, 0.78, 0.2), 0.8)
	var blue_glow := _glow(Color(0.26, 0.52, 0.96), 1.0)

	# Page backing, in two layers (the frame sits in front of its rim).
	var tint := _box(Vector3(3.8, 2.2, 0.04), Vector3(0, y0 + 1.1, -0.5), tint_mat, "PageTint")
	root.add_child(tint)
	root.add_child(_box(Vector3(3.8, 0.05, 0.03), Vector3(0, y0 + 2.175, -0.47), page_beam))
	root.add_child(_box(Vector3(3.8, 0.05, 0.03), Vector3(0, y0 + 0.025, -0.47), page_beam))
	root.add_child(_box(Vector3(0.05, 2.2, 0.03), Vector3(-1.875, y0 + 1.1, -0.47), page_beam))
	root.add_child(_box(Vector3(0.05, 2.2, 0.03), Vector3(1.875, y0 + 1.1, -0.47), page_beam))
	# A page scrollbar on the right of the page.
	root.add_child(_box(Vector3(0.06, 1.8, 0.02), Vector3(1.82, y0 + 1.1, -0.46), skeleton, "ScrollTrack"))
	root.add_child(_box(Vector3(0.06, 0.5, 0.03), Vector3(1.82, y0 + 1.55, -0.45), frame_light, "ScrollThumb"))

	# Window chrome: title bar, toolbar, side and bottom borders, inner bevels.
	root.add_child(_box(Vector3(4.0, 0.4, 0.14), Vector3(0, y0 + 2.8, 0), frame_dark, "TitleBar"))
	root.add_child(_box(Vector3(3.92, 0.05, 0.02), Vector3(0, y0 + 2.985, 0.075), frame_light)) # gloss
	root.add_child(_box(Vector3(4.0, 0.36, 0.14), Vector3(0, y0 + 2.42, 0), frame, "Toolbar"))
	root.add_child(_box(Vector3(4.0, 0.025, 0.02), Vector3(0, y0 + 2.6, 0.075), chrome)) # toolbar seam
	for side in [-1.0, 1.0]:
		root.add_child(_box(Vector3(0.1, 2.2, 0.14), Vector3(1.95 * side, y0 + 1.1, 0), frame))
		root.add_child(_box(Vector3(0.03, 2.14, 0.02), Vector3(1.89 * side, y0 + 1.1, 0.075), frame_light))
	root.add_child(_box(Vector3(4.0, 0.1, 0.14), Vector3(0, y0 + 0.0, 0), frame))
	root.add_child(_box(Vector3(3.8, 0.03, 0.02), Vector3(0, y0 + 0.045, 0.075), frame_light))

	# App icon and window title.
	root.add_child(_box(Vector3(0.16, 0.16, 0.035), Vector3(-1.72, y0 + 2.8, 0.085), white, "AppIcon"))
	root.add_child(_box(Vector3(0.1, 0.05, 0.01), Vector3(-1.72, y0 + 2.8, 0.105), frame_dark))
	root.add_child(_label("404 Not Found", 0.16, Color(0.85, 0.88, 0.95), Vector3(-1.15, y0 + 2.8, 0.09)))
	# Close, maximise, minimise: a dark rim and a glowing dot each.
	for i in 3:
		var colors := [red_glow, green_glow, yellow_glow]
		var x := 0.91 + 0.32 * i
		var rim := _cylinder(0.13, 0.13, 0.03, Vector3(x, y0 + 2.8, 0.085), chrome, "LightRim")
		rim.rotation.x = PI * 0.5
		root.add_child(rim)
		var dot := _cylinder(0.095, 0.095, 0.03, Vector3(x, y0 + 2.8, 0.095), colors[i], "Light")
		dot.rotation.x = PI * 0.5
		root.add_child(dot)

	# Toolbar: back / forward / reload buttons, address bar and its URL.
	for i in 3:
		var glyphs := ["<", ">", "C"]
		var x := -1.8 + 0.18 * i
		var disc := _cylinder(0.075, 0.075, 0.025, Vector3(x, y0 + 2.42, 0.085), chrome, "NavButton")
		disc.rotation.x = PI * 0.5
		root.add_child(disc)
		root.add_child(_label(glyphs[i], 0.11, Color(0.9, 0.93, 1.0), Vector3(x, y0 + 2.42, 0.1)))
	root.add_child(_box(Vector3(3.0, 0.24, 0.03), Vector3(0.35, y0 + 2.42, 0.09), white, "AddressBar"))
	root.add_child(_box(Vector3(3.0, 0.02, 0.01), Vector3(0.35, y0 + 2.3, 0.105), chrome)) # bar shadow
	var url := _label(BROWSER_URL, 0.115, Color(0.15, 0.2, 0.55), Vector3(-1.02, y0 + 2.42, 0.115), "Url")
	url.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	root.add_child(url)
	# A tiny padlock at the left of the address bar.
	root.add_child(_box(Vector3(0.05, 0.05, 0.015), Vector3(-1.12, y0 + 2.42, 0.11), frame_dark))
	root.add_child(_box(Vector3(0.03, 0.035, 0.015), Vector3(-1.12, y0 + 2.455, 0.11), white))

	# Loading progress: the scene scales `Progress.x`; the track stays put.
	root.add_child(_box(Vector3(3.0, 0.07, 0.02), Vector3(0.35, y0 + 2.27, 0.08), chrome, "ProgressTrack"))
	var progress: Node3D = Node3D.new()
	progress.name = "Progress"
	progress.position = Vector3(-1.15, y0 + 2.27, 0.1)
	var bar := _box(Vector3(3.0, 0.045, 0.03), Vector3(1.5, 0, 0), blue_glow)
	bar.name = "ProgressBar"
	progress.add_child(bar)
	root.add_child(progress)

	# Page contents while loading: a soft skeleton and a spinner.
	var loading: Node3D = Node3D.new()
	loading.name = "PageLoading"
	loading.add_child(_box(Vector3(2.6, 0.55, 0.02), Vector3(0, y0 + 1.75, -0.47), white))
	loading.add_child(_box(Vector3(1.4, 0.12, 0.02), Vector3(0, y0 + 1.92, -0.455), skeleton))
	for i in 3:
		loading.add_child(_box(Vector3(2.4 - i * 0.5, 0.08, 0.02),
			Vector3(0, y0 + 1.25 - i * 0.2, -0.455), skeleton))
	var spinner := TorusMesh.new()
	spinner.inner_radius = 0.16
	spinner.outer_radius = 0.2
	spinner.rings = 24
	spinner.ring_segments = 8
	var ring := _mesh(spinner, Vector3(0, y0 + 1.75, -0.45), blue_glow, "Spinner")
	ring.rotation.x = PI * 0.5
	loading.add_child(ring)
	var loading_label := _label("Loading...", 0.2, Color(0.35, 0.38, 0.45),
		Vector3(0, y0 + 0.72, -0.44), "LoadingLabel")
	loading.add_child(loading_label)
	root.add_child(loading)

	# The 404 page, hidden until the scene pops it in.
	var error: Node3D = Node3D.new()
	error.name = "PageError"
	error.position = Vector3(0, y0 + 1.4, 0.06)
	error.visible = false
	error.add_child(_label("404", 1.0, Color(0.85, 0.15, 0.15), Vector3(0, 0.45, 0)))
	error.add_child(_label("NOT FOUND", 0.42, Color(0.6, 0.1, 0.1), Vector3(0, -0.35, 0)))
	error.add_child(_label(":(  this page is gone", 0.14, Color(0.4, 0.4, 0.45), Vector3(0, -0.75, 0)))
	root.add_child(error)
	var inside := Marker3D.new()
	inside.name = "Inside"
	inside.position = Vector3(0, y0 + 0.12, -0.25)
	root.add_child(inside)

	_save(root, PROP_DIR + "sundar/browser_window.tscn")

## Label3D sized like the scene's stand-ins: `size` is roughly the world height.
func _label(text: String, size: float, color: Color, position: Vector3, name := "") -> Label3D:
	var label: Label3D = Label3D.new()
	label.text = text
	label.font_size = 64
	label.pixel_size = size * 0.0155
	label.modulate = color
	label.shaded = false
	label.outline_size = 0
	label.position = position
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if name != "":
		label.name = name
	return label

# =============================================================================
# O2f - xi props
# =============================================================================

func _build_xi_props() -> void:
	_dir_for("xi")
	_paper_dragon()

const DRAGON_SEGMENTS := 7

## Festival paper dragon for Xi's power move: a big red-and-gold head with horns, glowing
## eyes and whiskers, and seven hooped body segments trailing along +Z. Front = -Z.
## `ProjectileLooks.animate` weaves the head and each segment, so the head and
## `Segment1`..`Segment7` carry the same `segment`/`rest_y` metadata as the code look it
## replaces; the root origin is the head's centre (a projectile origin, not the floor).
func _paper_dragon() -> void:
	var root: Node3D = Node3D.new()
	root.name = "PaperDragon"
	var red := _metal(Color(0.72, 0.1, 0.08), 0.0, 0.55)
	var red_dark := _metal(Color(0.48, 0.05, 0.04), 0.0, 0.6)
	var red_light := _metal(Color(0.85, 0.16, 0.12), 0.0, 0.5)
	var gold := _metal(Color(0.95, 0.72, 0.2), 0.65, 0.3)
	var gold_dark := _metal(Color(0.7, 0.48, 0.1), 0.6, 0.35)
	var gold_flat := _metal(Color(0.88, 0.65, 0.16), 0.0, 0.65)
	var cream := _metal(Color(0.97, 0.93, 0.8), 0.0, 0.5)
	var dark := _rubber(Color(0.07, 0.04, 0.04))
	var eye_glow := _glow(Color(1.0, 0.85, 0.3), 1.5)

	# Head (metadata 0 like the code look so the weave animation picks it up).
	var head: Node3D = Node3D.new()
	head.name = "Head"
	head.set_meta(&"segment", 0)
	head.set_meta(&"rest_y", 0.0)
	head.add_child(_box(Vector3(0.4, 0.3, 0.42), Vector3(0, 0.05, 0.03), red, "Skull"))
	head.add_child(_box(Vector3(0.3, 0.3, 0.14), Vector3(0, 0.05, 0.21), red, "Neck"))
	for side in [-1.0, 1.0]:
		head.add_child(_box(Vector3(0.06, 0.16, 0.26), Vector3(0.21 * side, 0.0, -0.04), red_dark, "Cheek"))
		# Eye: glowing ball, dark pupil, gold rim.
		head.add_child(_sphere(0.062, Vector3(0.13 * side, 0.17, -0.18), eye_glow, "Eye"))
		head.add_child(_sphere(0.028, Vector3(0.135 * side, 0.17, -0.235), dark, "Pupil"))
		head.add_child(_torus(0.062, 0.08, Vector3(0.13 * side, 0.17, -0.222), gold, "EyeRim",
			Vector3(PI * 0.5, 0, 0)))
		var brow := _box(Vector3(0.16, 0.04, 0.07), Vector3(0.13 * side, 0.25, -0.17), gold_dark, "Brow")
		brow.rotation.z = 0.25 * side
		head.add_child(brow)
		# Antler-like horn: two tapering pieces and a forward branch.
		head.add_child(_cylinder(0.028, 0.055, 0.26, Vector3(0.11 * side, 0.31, 0.08), gold,
			"Horn", Vector3(0.35, 0, -0.15 * side)))
		head.add_child(_cylinder(0.012, 0.028, 0.22, Vector3(0.145 * side, 0.49, 0.17), gold,
			"HornTip", Vector3(0.7, 0, -0.35 * side)))
		head.add_child(_cylinder(0.008, 0.02, 0.14, Vector3(0.06 * side, 0.43, 0.12), gold_dark,
			"HornBranch", Vector3(0.3, 0, 0.85 * side)))
		# Whiskers: thin gold rods, bent at the tip, with a bead.
		var whisker := _box(Vector3(0.22, 0.012, 0.012), Vector3(0.23 * side, -0.02, -0.34), gold_flat, "Whisker")
		whisker.rotation.z = 0.1 * side
		whisker.rotation.y = 0.3 * side
		head.add_child(whisker)
		var w_tip := _box(Vector3(0.1, 0.01, 0.01), Vector3(0.32 * side, -0.04, -0.38), gold_flat, "WhiskerTip")
		w_tip.rotation.z = 0.25 * side
		w_tip.rotation.y = 0.5 * side
		head.add_child(w_tip)
		head.add_child(_sphere(0.016, Vector3(0.37 * side, -0.06, -0.4), gold_flat, "WhiskerBead"))
		# Fangs on the upper jaw.
		head.add_child(_box(Vector3(0.025, 0.05, 0.025), Vector3(0.09 * side, -0.05, -0.39), cream, "Fang"))
	# A gold stripe over the snout.
	head.add_child(_box(Vector3(0.06, 0.02, 0.28), Vector3(0, 0.09, -0.28), gold, "NoseBridge"))
	# Snout, nose, mouth and jaw.
	head.add_child(_box(Vector3(0.3, 0.16, 0.3), Vector3(0, 0.0, -0.28), red, "Snout"))
	head.add_child(_box(Vector3(0.32, 0.1, 0.08), Vector3(0, 0.03, -0.43), red_dark, "Nose"))
	head.add_child(_box(Vector3(0.28, 0.02, 0.26), Vector3(0, -0.075, -0.29), dark, "Mouth"))
	head.add_child(_box(Vector3(0.26, 0.08, 0.26), Vector3(0, -0.12, -0.28), red_dark, "Jaw"))
	head.add_child(_box(Vector3(0.26, 0.03, 0.24), Vector3(0, -0.165, -0.28), gold_dark, "JawTrim"))
	for side in [-1.0, 1.0]:
		head.add_child(_box(Vector3(0.04, 0.03, 0.02), Vector3(0.07 * side, 0.07, -0.475), dark, "Nostril"))
	# Forehead crest and the gold mane behind the head.
	var crest := _box(Vector3(0.16, 0.03, 0.13), Vector3(0, 0.235, -0.12), gold, "Crest")
	crest.rotation.x = 0.25
	head.add_child(crest)
	for i in 5:
		var x := -0.12 + 0.06 * i
		var mane := _box(Vector3(0.035, 0.19, 0.05), Vector3(x, 0.28, 0.15), gold, "Mane")
		mane.rotation.z = x * 3.5
		mane.rotation.x = 0.3
		head.add_child(mane)
	head.add_child(_box(Vector3(0.16, 0.03, 0.18), Vector3(0, 0.22, -0.02), gold_dark, "Spine"))
	root.add_child(head)

	# Seven hooped body segments trailing behind the head (+Z).
	for i in DRAGON_SEGMENTS:
		var segment: Node3D = Node3D.new()
		segment.name = "Segment%d" % (i + 1)
		var rest_y := -0.02 * i
		segment.set_meta(&"segment", i + 1)
		segment.set_meta(&"rest_y", rest_y)
		segment.position = Vector3(0, rest_y, 0.45 + 0.3 * i)
		var radius := 0.19 - 0.012 * i
		segment.add_child(_cylinder(radius - 0.02, radius, 0.26, Vector3.ZERO, red, "Body",
			Vector3(PI * 0.5, 0, 0)))
		for z in [-0.13, 0.13]:
			segment.add_child(_torus(radius - 0.03, radius + 0.01, Vector3(0, 0, z), gold, "Hoop",
				Vector3(PI * 0.5, 0, 0)))
		var fin := _box(Vector3(0.025, 0.13, 0.18), Vector3(0, radius + 0.05, 0.0), gold, "Fin")
		fin.rotation.x = 0.3
		segment.add_child(fin)
		var fringe := _box(Vector3(0.02, 0.09, 0.18), Vector3(0, -radius - 0.04, 0.0), red_light, "Fringe")
		fringe.rotation.x = -0.2
		segment.add_child(fringe)
		if i == DRAGON_SEGMENTS - 1:
			# Tail fan at the very back.
			for k in 3:
				var fan := _box(Vector3(0.02, 0.16 + 0.03 * (1 - absi(k - 1)), 0.24),
					Vector3(0.0, 0.03, 0.2), gold if k != 1 else red_light, "Tail")
				fan.rotation.y = (k - 1) * 0.45
				segment.add_child(fan)
		root.add_child(segment)

	var light := OmniLight3D.new()
	light.name = "Light"
	light.light_color = Color(1.0, 0.55, 0.25)
	light.light_energy = 1.2
	light.omni_range = 2.0
	light.position = Vector3(0, 0.25, -0.15)
	root.add_child(light)

	_save(root, PROP_DIR + "xi/paper_dragon.tscn")

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