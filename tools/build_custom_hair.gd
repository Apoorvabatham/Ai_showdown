extends SceneTree
## Builds distinct authentic hairstyles for the AI Showdown roster.
## Run: godot_console --headless --path . -s res://tools/build_custom_hair.gd

const HAIR_DIR := "res://assets/characters/hair/"
const MALE_BODY := "res://assets/characters/base/Superhero_Male_FullBody.gltf"

var _male_scalp := PackedVector3Array()
var _male_scalp_normals := PackedVector3Array()

func _initialize() -> void:
	_load_male_scalp()
	_build_curly_mop("Hair_CurlyMop")
	_build_trump_pomp("Hair_TrumpPomp")
	_build_silver_sweep("Hair_SilverSweep")
	_build_caesar("Hair_Caesar")
	_build_politburo("Hair_PolitburoPart")
	_build_academic_wave("Hair_AcademicWave")
	_build_elder_thinning("Hair_ElderThinning")
	_build_undercut_pomp("Hair_UndercutPomp")
	quit()

func _load_male_scalp() -> void:
	var body := (load(MALE_BODY) as PackedScene).instantiate()
	for mi: MeshInstance3D in body.find_children("*", "MeshInstance3D", true, false):
		if mi.name.to_lower() != "superhero_male":
			continue
		var arrays := mi.mesh.surface_get_arrays(0)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		for i in verts.size():
			if verts[i].y > 1.55:
				_male_scalp.append(verts[i])
				_male_scalp_normals.append(normals[i])
	body.free()
	print("Loaded male scalp: ", _male_scalp.size(), " vertices")

## 1. Dario Amoday: Thick, voluminous unruly curly mop with prominent 3D curl spirals
func _build_curly_mop(style: String) -> void:
	var source := (load(HAIR_DIR + "Hair_Buzzed.gltf") as PackedScene).instantiate()
	var mi := source.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var arrays := mi.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]

	var st := SurfaceTool.new()
	st.set_skin_weight_count(SurfaceTool.SKIN_4_WEIGHTS)
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var head_center := Vector3(0.0, 1.71, -0.01)

	# 1. Base scalp / dome underlayer (expanded outward to give dark, rounded mop volume)
	var base_tri_count := indices.size() / 3
	for t in base_tri_count:
		for k in 3:
			var c := indices[t * 3 + k]
			var p := verts[c]
			var rad := p - head_center
			rad.y *= 0.80
			var p_out := p + rad.normalized() * 0.020
			st.set_normal(normals[c])
			st.set_uv(uvs[c])
			st.set_bones(bones.slice(c * 4, c * 4 + 4))
			st.set_weights(weights.slice(c * 4, c * 4 + 4))
			st.add_vertex(p_out)

	# 2. Rich 3D helical curly ribbons covering the head
	var curl_tri_count := 0
	var rng := RandomNumberGenerator.new()
	rng.seed = 314159

	var locks: Array[Dictionary] = []

	# A. Forehead bangs / fringe curls (tumbling forward and down right above the glasses)
	for i in 30:
		var frac := float(i) / 29.0
		var x := lerpf(-0.065, 0.065, frac) + rng.randf_range(-0.006, 0.006)
		var y := rng.randf_range(1.74, 1.78)
		var z := rng.randf_range(0.055, 0.078)
		var dir := Vector3(x * 0.45 + rng.randf_range(-0.1, 0.1), -0.42 + rng.randf_range(-0.08, 0.08), 0.78 + rng.randf_range(-0.08, 0.08)).normalized()
		locks.append({
			root = Vector3(x, y, z),
			dir = dir,
			length = rng.randf_range(0.042, 0.058),
			turns = rng.randf_range(2.0, 2.8),
			radius = rng.randf_range(0.011, 0.016),
			width = rng.randf_range(0.015, 0.021),
			phase = rng.randf_range(0.0, TAU),
			sag = Vector3(0, -0.008, 0.004)
		})

	# B. Mid-front and frontal dome transition curls (filling the forehead-to-crown zone seamlessly)
	for i in 25:
		var x := rng.randf_range(-0.065, 0.065)
		var z := rng.randf_range(0.015, 0.055)
		var y := rng.randf_range(1.77, 1.81)
		var dir := Vector3(x * 0.8 + rng.randf_range(-0.15, 0.15), 0.55 + rng.randf_range(-0.1, 0.15), 0.55 + rng.randf_range(-0.1, 0.15)).normalized()
		locks.append({
			root = Vector3(x, y, z),
			dir = dir,
			length = rng.randf_range(0.045, 0.062),
			turns = rng.randf_range(1.8, 2.6),
			radius = rng.randf_range(0.012, 0.017),
			width = rng.randf_range(0.015, 0.022),
			phase = rng.randf_range(0.0, TAU),
			sag = Vector3(0, -0.008, 0.006)
		})

	# C. Crown and top mop volume (springy loops building high curly volume)
	for i in 45:
		var angle := rng.randf_range(0.0, TAU)
		var r := sqrt(rng.randf_range(0.01, 1.0)) * 0.068
		var x := cos(angle) * r
		var z := sin(angle) * r - 0.01
		var y := 1.77 + (1.0 - (r / 0.068)) * 0.038 + rng.randf_range(-0.008, 0.012)
		var dir := Vector3(x * 1.3 + rng.randf_range(-0.15, 0.15), 0.85 + rng.randf_range(-0.15, 0.15), (z + 0.01) * 1.3 + rng.randf_range(-0.15, 0.15)).normalized()
		locks.append({
			root = Vector3(x, y, z),
			dir = dir,
			length = rng.randf_range(0.048, 0.068),
			turns = rng.randf_range(1.8, 2.6),
			radius = rng.randf_range(0.012, 0.018),
			width = rng.randf_range(0.016, 0.022),
			phase = rng.randf_range(0.0, TAU),
			sag = Vector3(dir.x * 0.006, -0.006, dir.z * 0.006)
		})

	# D. Temples, sideburns and sides (framing ears with rounded curly mop silhouette)
	for side_val in [-1.0, 1.0]:
		var side: float = side_val
		for i in 22:
			var y := rng.randf_range(1.68, 1.78)
			var z := rng.randf_range(-0.045, 0.045)
			var x := side * (0.062 + rng.randf_range(0.0, 0.015))
			var dir := Vector3(side * (0.85 + rng.randf_range(0.0, 0.2)), -0.28 + rng.randf_range(-0.1, 0.1), z * 0.45 + rng.randf_range(-0.1, 0.1)).normalized()
			locks.append({
				root = Vector3(x, y, z),
				dir = dir,
				length = rng.randf_range(0.046, 0.068),
				turns = rng.randf_range(1.8, 2.6),
				radius = rng.randf_range(0.012, 0.018),
				width = rng.randf_range(0.015, 0.021),
				phase = rng.randf_range(0.0, TAU),
				sag = Vector3(0, -0.010, 0)
			})

	# E. Back and nape (curly cascade covering back of skull)
	for i in 28:
		var x := rng.randf_range(-0.06, 0.06)
		var y := rng.randf_range(1.66, 1.77)
		var z := -0.068 - rng.randf_range(0.0, 0.032)
		var dir := Vector3(x * 0.45 + rng.randf_range(-0.1, 0.1), -0.48 + rng.randf_range(-0.1, 0.1), -0.75 + rng.randf_range(-0.1, 0.1)).normalized()
		locks.append({
			root = Vector3(x, y, z),
			dir = dir,
			length = rng.randf_range(0.050, 0.072),
			turns = rng.randf_range(1.8, 2.6),
			radius = rng.randf_range(0.012, 0.018),
			width = rng.randf_range(0.015, 0.021),
			phase = rng.randf_range(0.0, TAU),
			sag = Vector3(0, -0.012, -0.006)
		})

	var head_bone := PackedInt32Array([6, 0, 0, 0])
	var head_weight := PackedFloat32Array([1.0, 0.0, 0.0, 0.0])

	for lock in locks:
		var root: Vector3 = lock.root
		var dir: Vector3 = lock.dir
		var length: float = lock.length
		var turns: float = lock.turns
		var max_radius: float = lock.radius
		var max_width: float = lock.width
		var phase: float = lock.phase
		var sag: Vector3 = lock.sag

		var up := Vector3.UP if absf(dir.y) < 0.9 else Vector3.FORWARD
		var norm1 := dir.cross(up).normalized()
		var norm2 := dir.cross(norm1).normalized()

		var num_steps := 16
		var spine_pts: Array[Vector3] = []
		var tangents: Array[Vector3] = []
		var radial_vecs: Array[Vector3] = []

		for s in (num_steps + 1):
			var u := float(s) / float(num_steps)
			var spine := root + dir * (length * u) + sag * (u * u)
			var r_spiral := max_radius * sin(clampf(u * PI, 0.15, 1.0))
			var angle := turns * TAU * u + phase
			var r_vec := (norm1 * cos(angle) + norm2 * sin(angle))
			var pt := spine + r_vec * r_spiral
			spine_pts.append(pt)
			radial_vecs.append(r_vec)

		for s in (num_steps + 1):
			var s_prev := maxi(s - 1, 0)
			var s_next := mini(s + 1, num_steps)
			var tan := (spine_pts[s_next] - spine_pts[s_prev]).normalized()
			tangents.append(tan)

		var prev_left := Vector3.ZERO
		var prev_right := Vector3.ZERO
		var prev_norm := Vector3.ZERO

		for s in (num_steps + 1):
			var u := float(s) / float(num_steps)
			var pt := spine_pts[s]
			var tan := tangents[s]
			var r_vec := radial_vecs[s]

			# Binormal along ribbon width
			var binorm := tan.cross(r_vec).normalized()
			if binorm.length_squared() < 0.1:
				binorm = norm1
			var norm := binorm.cross(tan).normalized()

			var w := max_width * sin(clampf(u * PI, 0.2, 1.0))
			var cur_left := pt - binorm * (w * 0.5)
			var cur_right := pt + binorm * (w * 0.5)

			if s > 0:
				var uv_v0 := float(s - 1) / float(num_steps)
				var uv_v1 := float(s) / float(num_steps)

				# Front face
				st.set_normal(prev_norm)
				st.set_uv(Vector2(0.0, uv_v0))
				st.set_bones(head_bone)
				st.set_weights(head_weight)
				st.add_vertex(prev_left)

				st.set_normal(norm)
				st.set_uv(Vector2(0.0, uv_v1))
				st.set_bones(head_bone)
				st.set_weights(head_weight)
				st.add_vertex(cur_left)

				st.set_normal(norm)
				st.set_uv(Vector2(1.0, uv_v1))
				st.set_bones(head_bone)
				st.set_weights(head_weight)
				st.add_vertex(cur_right)

				st.set_normal(prev_norm)
				st.set_uv(Vector2(0.0, uv_v0))
				st.set_bones(head_bone)
				st.set_weights(head_weight)
				st.add_vertex(prev_left)

				st.set_normal(norm)
				st.set_uv(Vector2(1.0, uv_v1))
				st.set_bones(head_bone)
				st.set_weights(head_weight)
				st.add_vertex(cur_right)

				st.set_normal(prev_norm)
				st.set_uv(Vector2(1.0, uv_v0))
				st.set_bones(head_bone)
				st.set_weights(head_weight)
				st.add_vertex(prev_right)

				# Back face (for full visibility from all viewing angles)
				st.set_normal(-prev_norm)
				st.set_uv(Vector2(0.0, uv_v0))
				st.set_bones(head_bone)
				st.set_weights(head_weight)
				st.add_vertex(prev_left)

				st.set_normal(-norm)
				st.set_uv(Vector2(1.0, uv_v1))
				st.set_bones(head_bone)
				st.set_weights(head_weight)
				st.add_vertex(cur_right)

				st.set_normal(-norm)
				st.set_uv(Vector2(0.0, uv_v1))
				st.set_bones(head_bone)
				st.set_weights(head_weight)
				st.add_vertex(cur_left)

				st.set_normal(-prev_norm)
				st.set_uv(Vector2(0.0, uv_v0))
				st.set_bones(head_bone)
				st.set_weights(head_weight)
				st.add_vertex(prev_left)

				st.set_normal(-prev_norm)
				st.set_uv(Vector2(1.0, uv_v0))
				st.set_bones(head_bone)
				st.set_weights(head_weight)
				st.add_vertex(prev_right)

				st.set_normal(-norm)
				st.set_uv(Vector2(1.0, uv_v1))
				st.set_bones(head_bone)
				st.set_weights(head_weight)
				st.add_vertex(cur_right)

				curl_tri_count += 4

			prev_left = cur_left
			prev_right = cur_right
			prev_norm = norm

	var total_tri_count := base_tri_count + curl_tri_count
	_save_curly_hair(st, mi, style, total_tri_count)
	source.free()

func _save_curly_hair(st: SurfaceTool, source_mi: MeshInstance3D, style: String, tri_count: int) -> void:
	st.index()
	st.generate_tangents()
	var mesh := st.commit()
	var mat := source_mi.mesh.surface_get_material(0).duplicate() as StandardMaterial3D
	mat.resource_name = "MI_Hair_2"
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 0.92
	mat.metallic = 0.0
	mat.metallic_specular = 0.15
	mesh.surface_set_material(0, mat)
	var out_mesh := HAIR_DIR + style + "_mesh.res"
	var out_scene := HAIR_DIR + style + ".tscn"
	ResourceSaver.save(mesh, out_mesh)

	var root := Node3D.new()
	root.name = style
	var piece := MeshInstance3D.new()
	piece.name = style
	piece.mesh = load(out_mesh)
	piece.skin = source_mi.skin
	root.add_child(piece)
	piece.owner = root
	var scene := PackedScene.new()
	scene.pack(root)
	var err := ResourceSaver.save(scene, out_scene)
	print("%s: %d triangles, err=%d" % [style, tri_count, err])
	root.free()

## 2. Donald Tarrif: Sweeping golden pompadour comb-over swoop
func _build_trump_pomp(style: String) -> void:
	var source := (load(HAIR_DIR + "Hair_SimpleParted.gltf") as PackedScene).instantiate()
	var mi := source.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var arrays := mi.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]

	var st := SurfaceTool.new()
	st.set_skin_weight_count(SurfaceTool.SKIN_4_WEIGHTS)
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for i in verts.size():
		var p := verts[i]
		# Loft the top into a lower, combed-over sweep: a controlled side part, not a
		# tall quiff. The height and forward sweep both come down from the old values.
		if p.y > 1.70:
			var lift := (p.y - 1.70) / 0.14
			p.y += lift * 0.024 * clampf(1.0 - absf(p.x) * 3.0, 0.2, 1.0)
			# Sweep across to the right (+X) and slightly forward (+Z)
			p.x += lift * 0.016
			if p.z > -0.02:
				p.z += lift * 0.010
		# Sides tucked over the temples rather than flared wide.
		if absf(p.x) > 0.065 and p.y > 1.68:
			p.x *= 1.04
		# Bring the front hairline down over the forehead: the comb-over should cover
		# more of the brow line instead of leaving a tall, bare forehead.
		if p.z > 0.040 and p.y > 1.68 and p.y < 1.81:
			var front := clampf((p.z - 0.040) / 0.055, 0.0, 1.0)
			p.y -= 0.014 * front
			p.z += 0.005 * front
		verts[i] = p

	for t in indices.size() / 3:
		for k in 3:
			var c := indices[t * 3 + k]
			st.set_normal(normals[c])
			st.set_uv(uvs[c])
			st.set_bones(bones.slice(c * 4, c * 4 + 4))
			st.set_weights(weights.slice(c * 4, c * 4 + 4))
			st.add_vertex(verts[c])

	_save_hair(st, mi, style, indices.size() / 3)
	source.free()

## 3. Jensen Wong: Swept-back silver mane with winged temples
func _build_silver_sweep(style: String) -> void:
	var source := (load(HAIR_DIR + "Hair_SimpleParted.gltf") as PackedScene).instantiate()
	var mi := source.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var arrays := mi.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]

	var st := SurfaceTool.new()
	st.set_skin_weight_count(SurfaceTool.SKIN_4_WEIGHTS)
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for i in verts.size():
		var p := verts[i]
		# Brushed back along Z
		if p.y > 1.71:
			var h := (p.y - 1.71) / 0.13
			p.z -= h * 0.016
			p.y += h * 0.018
		# Winged fullness over ears/temples
		if absf(p.x) > 0.06:
			p.x *= 1.12
		verts[i] = p

	for t in indices.size() / 3:
		for k in 3:
			var c := indices[t * 3 + k]
			st.set_normal(normals[c])
			st.set_uv(uvs[c])
			st.set_bones(bones.slice(c * 4, c * 4 + 4))
			st.set_weights(weights.slice(c * 4, c * 4 + 4))
			st.add_vertex(verts[c])

	_save_hair(st, mi, style, indices.size() / 3)
	source.free()

## 4. Mark Zuckerbot: Roman Caesar cut with blunt forward micro-fringe
func _build_caesar(style: String) -> void:
	var source := (load(HAIR_DIR + "Hair_Buzzed.gltf") as PackedScene).instantiate()
	var mi := source.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var arrays := mi.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]

	var st := SurfaceTool.new()
	st.set_skin_weight_count(SurfaceTool.SKIN_4_WEIGHTS)
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for i in verts.size():
		var p := verts[i]
		# Forward micro-fringe: pull forehead hairline forward into a blunt straight edge
		if p.z > 0.05 and p.y > 1.71 and p.y < 1.78 and absf(p.x) < 0.055:
			p.z += 0.009
			p.y -= 0.003
		# Textured top
		if p.y > 1.75:
			p.y += sin(p.x * 60.0) * 0.003
		verts[i] = p

	for t in indices.size() / 3:
		for k in 3:
			var c := indices[t * 3 + k]
			st.set_normal(normals[c])
			st.set_uv(uvs[c])
			st.set_bones(bones.slice(c * 4, c * 4 + 4))
			st.set_weights(weights.slice(c * 4, c * 4 + 4))
			st.add_vertex(verts[c])

	_save_hair(st, mi, style, indices.size() / 3)
	source.free()

## 6. Xi Winping: Rigid, squared-off Chinese Politburo pompadour part
func _build_politburo(style: String) -> void:
	var source := (load(HAIR_DIR + "Hair_SimpleParted.gltf") as PackedScene).instantiate()
	var mi := source.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var arrays := mi.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]

	var st := SurfaceTool.new()
	st.set_skin_weight_count(SurfaceTool.SKIN_4_WEIGHTS)
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for i in verts.size():
		var p := verts[i]
		# Boxy, stately lifted pompadour part
		if p.y > 1.72:
			p.y += 0.014
		# Tight, disciplined slicked sides
		if absf(p.x) > 0.065:
			p.x *= 0.96
		verts[i] = p

	for t in indices.size() / 3:
		for k in 3:
			var c := indices[t * 3 + k]
			st.set_normal(normals[c])
			st.set_uv(uvs[c])
			st.set_bones(bones.slice(c * 4, c * 4 + 4))
			st.set_weights(weights.slice(c * 4, c * 4 + 4))
			st.add_vertex(verts[c])

	_save_hair(st, mi, style, indices.size() / 3)
	source.free()

## 7. Yann LeCant: Wavy French academic side-part with cowlick
func _build_academic_wave(style: String) -> void:
	var source := (load(HAIR_DIR + "Hair_SimpleParted.gltf") as PackedScene).instantiate()
	var mi := source.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var arrays := mi.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]

	var st := SurfaceTool.new()
	st.set_skin_weight_count(SurfaceTool.SKIN_4_WEIGHTS)
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for i in verts.size():
		var p := verts[i]
		# Wavy cowlick on top
		if p.y > 1.72:
			p.y += sin(p.x * 35.0 + p.z * 20.0) * 0.007 + 0.010
			p.x += cos(p.z * 30.0) * 0.006
		# Thick wave over ears
		if absf(p.x) > 0.06:
			p.x *= 1.07
		verts[i] = p

	for t in indices.size() / 3:
		for k in 3:
			var c := indices[t * 3 + k]
			st.set_normal(normals[c])
			st.set_uv(uvs[c])
			st.set_bones(bones.slice(c * 4, c * 4 + 4))
			st.set_weights(weights.slice(c * 4, c * 4 + 4))
			st.add_vertex(verts[c])

	_save_hair(st, mi, style, indices.size() / 3)
	source.free()

## 8. Geoff Hintoff: Thinning wispy silver elder side-part
func _build_elder_thinning(style: String) -> void:
	var source := (load(HAIR_DIR + "Hair_SimpleParted.gltf") as PackedScene).instantiate()
	var mi := source.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var arrays := mi.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]

	var st := SurfaceTool.new()
	st.set_skin_weight_count(SurfaceTool.SKIN_4_WEIGHTS)
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for i in verts.size():
		var p := verts[i]
		# Thinning: reduce top volume slightly, pull temples back
		if p.y > 1.73:
			p.y -= 0.006
		if p.z > 0.03 and absf(p.x) > 0.04 and p.y < 1.77:
			p.z -= 0.012
			p.y += 0.008
		verts[i] = p

	for t in indices.size() / 3:
		for k in 3:
			var c := indices[t * 3 + k]
			st.set_normal(normals[c])
			st.set_uv(uvs[c])
			st.set_bones(bones.slice(c * 4, c * 4 + 4))
			st.set_weights(weights.slice(c * 4, c * 4 + 4))
			st.add_vertex(verts[c])

	_save_hair(st, mi, style, indices.size() / 3)
	source.free()

## 9. Tesla Man: High textured pomp with modern undercut fade
func _build_undercut_pomp(style: String) -> void:
	var source := (load(HAIR_DIR + "Hair_SimpleParted.gltf") as PackedScene).instantiate()
	var mi := source.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var arrays := mi.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]

	var st := SurfaceTool.new()
	st.set_skin_weight_count(SurfaceTool.SKIN_4_WEIGHTS)
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for i in verts.size():
		var p := verts[i]
		# High textured pompadour top
		if p.y > 1.72:
			p.y += 0.024 * clampf(1.0 - absf(p.x) * 4.0, 0.2, 1.0)
			p.z -= 0.008
		# Tight undercut sides (tuck inward)
		if absf(p.x) > 0.055 and p.y < 1.74:
			p.x *= 0.93
		verts[i] = p

	for t in indices.size() / 3:
		for k in 3:
			var c := indices[t * 3 + k]
			st.set_normal(normals[c])
			st.set_uv(uvs[c])
			st.set_bones(bones.slice(c * 4, c * 4 + 4))
			st.set_weights(weights.slice(c * 4, c * 4 + 4))
			st.add_vertex(verts[c])

	_save_hair(st, mi, style, indices.size() / 3)
	source.free()

func _save_hair(st: SurfaceTool, source_mi: MeshInstance3D, style: String, tri_count: int) -> void:
	st.index()
	st.generate_tangents()
	var mesh := st.commit()
	var mat := source_mi.mesh.surface_get_material(0).duplicate() as StandardMaterial3D
	mat.roughness = 1.0
	mat.metallic_specular = 0.25
	mesh.surface_set_material(0, mat)
	var out_mesh := HAIR_DIR + style + "_mesh.res"
	var out_scene := HAIR_DIR + style + ".tscn"
	ResourceSaver.save(mesh, out_mesh)

	var root := Node3D.new()
	root.name = style
	var piece := MeshInstance3D.new()
	piece.name = style
	piece.mesh = load(out_mesh)
	piece.skin = source_mi.skin
	root.add_child(piece)
	piece.owner = root
	var scene := PackedScene.new()
	scene.pack(root)
	var err := ResourceSaver.save(scene, out_scene)
	print("%s: %d triangles, err=%d" % [style, tri_count, err])
	root.free()

func _clip_poly(polygon: Array, cut_fn: Callable) -> Array:
	var values := polygon.map(func(v: Dictionary) -> float: return cut_fn.call(v.p))
	var out: Array = []
	for i in polygon.size():
		var a: Dictionary = polygon[i]
		var b: Dictionary = polygon[(i + 1) % polygon.size()]
		var da: float = values[i]
		var db: float = values[(i + 1) % polygon.size()]
		if da >= 0.0:
			out.append(a)
		if (da >= 0.0) != (db >= 0.0):
			out.append(_blend_vertex(a, b, da / (da - db)))
	return out

func _blend_vertex(a: Dictionary, b: Dictionary, t: float) -> Dictionary:
	var influence := {}
	for k in 4:
		influence[a.bones[k]] = influence.get(a.bones[k], 0.0) + a.weights[k] * (1.0 - t)
		influence[b.bones[k]] = influence.get(b.bones[k], 0.0) + b.weights[k] * t
	var order := influence.keys()
	order.sort_custom(func(x, y): return influence[x] > influence[y])
	var bone_ids := PackedInt32Array()
	var bone_weights := PackedFloat32Array()
	var total := 0.0
	for k in 4:
		var bone: int = order[k] if k < order.size() else 0
		var weight: float = influence[bone] if k < order.size() else 0.0
		bone_ids.append(bone)
		bone_weights.append(weight)
		total += weight
	for k in 4:
		bone_weights[k] /= maxf(total, 0.0001)
	return {p = a.p.lerp(b.p, t), n = a.n.lerp(b.n, t).normalized(), uv = a.uv.lerp(b.uv, t),
		bones = bone_ids, weights = bone_weights}
