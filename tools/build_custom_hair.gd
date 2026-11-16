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
	_build_receding("Hair_RecedingGrandmaster")
	_build_politburo("Hair_PolitburoPart")
	_build_academic_wave("Hair_AcademicWave")
	_build_elder_thinning("Hair_ElderThinning")
	_build_undercut_pomp("Hair_UndercutPomp")
	quit()

func _load_male_scalp() -> void:
	var body := (load(MALE_BODY) as PackedScene).instantiate()
	for mi: MeshInstance3D in body.find_children("*", "MeshInstance3D", true, false):
		if mi.name != "Superhero_Male":
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

## 1. Dario Amoday: Thick, unruly curly mop (from Hair_Long cut at ears/nape + 3D curl harmonics)
func _build_curly_mop(style: String) -> void:
	var source := (load(HAIR_DIR + "Hair_Long.gltf") as PackedScene).instantiate()
	var mi := source.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var arrays := mi.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]

	var cut_fn := func(p: Vector3) -> float:
		var back := clampf((-p.z - 0.01) / 0.12, 0.0, 1.0)
		# Cut around chin in front (1.62m) and slightly lower around back (1.58m)
		return p.y - (1.61 - 0.03 * back)

	var st := SurfaceTool.new()
	st.set_skin_weight_count(SurfaceTool.SKIN_4_WEIGHTS)
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var kept := 0

	for t in indices.size() / 3:
		var polygon: Array = []
		for k in 3:
			var c := indices[t * 3 + k]
			polygon.append({p = verts[c], n = normals[c], uv = uvs[c],
				bones = bones.slice(c * 4, c * 4 + 4), weights = weights.slice(c * 4, c * 4 + 4)})
		polygon = _clip_poly(polygon, cut_fn)
		for v: Dictionary in polygon:
			# Apply 3D curly displacement harmonics
			var p: Vector3 = v.p
			var outward := Vector3(p.x, 0, p.z).normalized() * 0.010
			var f1 := 52.0
			var f2 := 34.0
			var curl := Vector3(
				sin(p.y * f1 + p.z * f2) * 0.007 + cos(p.z * f1) * 0.004,
				cos(p.x * f2 + p.z * f1) * 0.004,
				sin(p.x * f1 + p.y * f2) * 0.007 + cos(p.y * f1) * 0.004
			)
			v.p = p + outward + curl
		for i in range(1, polygon.size() - 1):
			for v: Dictionary in [polygon[0], polygon[i], polygon[i + 1]]:
				st.set_normal(v.n)
				st.set_uv(v.uv)
				st.set_bones(v.bones)
				st.set_weights(v.weights)
				st.add_vertex(v.p)
			kept += 1

	_save_hair(st, mi, style, kept)
	source.free()

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
		# Loft top and front up and sweep to the right
		if p.y > 1.70:
			var lift := (p.y - 1.70) / 0.14
			p.y += lift * 0.038 * clampf(1.0 - absf(p.x) * 3.0, 0.2, 1.0)
			# Sweep across to the right (+X) and forward (+Z)
			p.x += lift * 0.022
			if p.z > -0.02:
				p.z += lift * 0.018
		# Sides flared over temples
		if absf(p.x) > 0.065 and p.y > 1.68:
			p.x *= 1.08
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

## 5. Demis Hassabis: Deeply receding M-shape temples, high forehead, close-cropped sides
func _build_receding(style: String) -> void:
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
		# Recede at the temples: pull hairline back and up
		if p.z > 0.03 and absf(p.x) > 0.035 and absf(p.x) < 0.075 and p.y < 1.79:
			p.z -= 0.015
			p.y += 0.012
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
