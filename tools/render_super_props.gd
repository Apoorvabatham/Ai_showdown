extends SceneTree
## Review sheet of the super props: one image per fighter folder under
## assets/props/supers/, each prop in a lit cell shot from its front-left (front = -Z).
## Cells are fitted to the prop's bounds, so a 0.6 m rocket and an 8 m rocket both fill
## their cell. Saves docs/review/opencode/props_<fighter>.jpg.
##
## Run windowed (needs a renderer):
##   godot --rendering-driver opengl3 --path . -s res://tools/render_super_props.gd [-- <fighter> ...]

const PROP_DIR := "res://assets/props/supers/"
const OUT_DIR := "res://docs/review/opencode/"
const CELL := Vector2i(420, 360)
const COLUMNS := 3


func _initialize() -> void:
	await process_frame
	var settings: Node = root.get_node("Settings")
	settings.graphics = settings.Graphics.HIGH
	settings.resolution = settings.RESOLUTIONS.size() - 1
	settings.apply_graphics(root)
	var only := OS.get_cmdline_user_args()
	var fighters := only if not only.is_empty() else DirAccess.get_directories_at(PROP_DIR)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	for fighter: String in fighters:
		var paths := DirAccess.get_files_at(PROP_DIR + fighter)
		var props: Array[String] = []
		for file in paths:
			if file.ends_with(".tscn"):
				props.append(PROP_DIR + fighter + "/" + file)
		if props.is_empty():
			continue
		var rows := int(ceil(float(props.size()) / COLUMNS))
		var sheet := Image.create(CELL.x * mini(props.size(), COLUMNS), CELL.y * rows, false, Image.FORMAT_RGB8)
		sheet.fill(Color(0.13, 0.13, 0.16))
		for i in props.size():
			var cell := await _render(props[i])
			sheet.blit_rect(cell, Rect2i(Vector2i.ZERO, CELL), Vector2i((i % COLUMNS) * CELL.x, (i / COLUMNS) * CELL.y))
			print("rendered ", props[i].get_file().get_basename())
		var out := OUT_DIR + "props_%s.jpg" % fighter
		sheet.save_jpg(out, 0.9)
		print("saved ", out)
	quit()


func _render(path: String) -> Image:
	var scene := load(path) as PackedScene
	var prop := scene.instantiate() as Node3D
	var vp := SubViewport.new()
	vp.size = CELL
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_4X
	root.add_child(vp)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.13, 0.13, 0.16)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.65, 0.67, 0.75)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	vp.add_child(world_env)
	var key := DirectionalLight3D.new()
	key.light_energy = 1.6
	key.shadow_enabled = true
	vp.add_child(key)
	key.look_at_from_position(Vector3(3.0, 5.0, -4.0), Vector3.ZERO)
	var fill := DirectionalLight3D.new()
	fill.light_energy = 0.5
	vp.add_child(fill)
	fill.look_at_from_position(Vector3(-4.0, 2.0, 3.0), Vector3.ZERO)
	vp.add_child(prop)
	await process_frame
	var bounds := _bounds(prop)
	var centre := bounds.get_center()
	var radius := maxf(bounds.size.length() * 0.5, 0.05)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(radius * 20.0, radius * 20.0)
	ground.mesh = plane
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.18, 0.18, 0.21)
	floor_material.roughness = 0.9
	ground.material_override = floor_material
	ground.position = Vector3(centre.x, 0.0, centre.z)
	vp.add_child(ground)
	var camera := Camera3D.new()
	vp.add_child(camera)
	camera.fov = 38.0
	var direction := Vector3(1.15, 0.72, -1.5).normalized()
	var distance := radius / tan(deg_to_rad(camera.fov) * 0.5) * 1.25
	camera.look_at_from_position(centre + direction * distance, centre + Vector3(0, -radius * 0.04, 0))
	camera.current = true
	for i in 4:
		await process_frame
	var image := vp.get_texture().get_image()
	image.convert(Image.FORMAT_RGB8)
	vp.queue_free()
	return image


func _bounds(node: Node3D) -> AABB:
	var result := AABB()
	var first := true
	var stack: Array[Node] = [node]
	while not stack.is_empty():
		var current: Node = stack.pop_back()
		if current is MeshInstance3D and (current as MeshInstance3D).mesh != null:
			var mesh := current as MeshInstance3D
			var box := mesh.global_transform * mesh.get_aabb()
			result = box if first else result.merge(box)
			first = false
		for child in current.get_children():
			stack.append(child)
	if first:
		result = AABB(Vector3(-0.5, 0, -0.5), Vector3.ONE)
	return result
