extends SceneTree
## Builds the stage and super-scene NPCs: res://data/npcs/<id>.tres as CharacterData with
## look fields only (no moves, no kit), on the same body/outfit/face pipeline as the
## fighters (docs/TASKS.md §3.2). Generated people only: every NPC is made up.
##
## Run: godot --headless --path . -s res://tools/build_npcs.gd
## (append `-- <id> ...` to rebuild only those NPCs)
##
## Order (HANDOFF §5, without the moves/stats steps):
##   1. python3 tools/build_prints.py (T-shirt prints, if a change touches them)
##   2. godot --headless --path . --import
##   3. this tool
##   4. godot --headless --path . -s res://tools/build_outfits.gd -- <id> ...
##   5. render (tools/render_npcs.gd) into docs/review/opencode/

const OUT_DIR := "res://data/npcs/"
const PORTRAIT_DIR := "res://assets/ui/portraits/"
const MALE_BODY := "res://assets/characters/base/Superhero_Male_FullBody.gltf"
const FEMALE_BODY := "res://assets/characters/base/Superhero_Female_FullBody.gltf"
const HAIR_DIR := "res://assets/characters/hair/"
const PRINT_DIR := "res://assets/characters/prints/"
const SKINS := {
	&"light": "res://assets/characters/base/T_Superhero_Male_Light.png",
	&"light_alt": "res://assets/characters/base/T_Superhero_Male_Dark.png",
	&"medium": "res://assets/characters/base/T_Showdown_Male_Medium.png",
	&"brown": "res://assets/characters/jin/T_Jin_Body.png",
	&"tan": "res://assets/characters/base/T_Showdown_Male_Tan.png",
	&"pale": "res://assets/characters/base/T_Showdown_Male_Pale.png",
	&"warm": "res://assets/characters/base/T_Showdown_Male_Warm.png",
	&"female_light": "res://assets/characters/base/T_Superhero_Female_Light_BaseColor.png",
	&"female_dark": "res://assets/characters/base/T_Superhero_Female_Dark_BaseColor.png",
}

const HAIR_BLACK := Color(0.055, 0.05, 0.05)
const HAIR_DARK := Color(0.1, 0.08, 0.07)
const HAIR_BROWN := Color(0.24, 0.16, 0.1)
const HAIR_AUBURN := Color(0.38, 0.16, 0.09)
const HAIR_RED := Color(0.52, 0.2, 0.1)
const HAIR_BLOND := Color(0.62, 0.48, 0.24)
const HAIR_GREY := Color(0.56, 0.56, 0.58)
const HAIR_SILVER := Color(0.76, 0.77, 0.79)

const UPRIGHT := {spine_02 = Vector3(-1, 0, 0), spine_03 = Vector3(-1, 0, 0),
	neck_01 = Vector3(1, 0, 0), Head = Vector3(-1, 0, 0)}
const SLOUCH := {spine_02 = Vector3(6, 0, 0), spine_03 = Vector3(4, 0, 0),
	neck_01 = Vector3(-7, 0, 0), Head = Vector3(-3, 0, 0)}
const LEAN_FORWARD := {spine_02 = Vector3(4, 0, 0), spine_03 = Vector3(2, 0, 0),
	neck_01 = Vector3(-4, 0, 0), Head = Vector3(-2, 0, 0)}
const STOCKY := {spine_01 = Vector3(1.12, 1, 1.14), spine_02 = Vector3(1.08, 1, 1.1),
	spine_03 = Vector3(1.02, 1, 1.04), pelvis = Vector3(1.06, 1, 1.08),
	upperarm = Vector3(1.08, 1, 1.08), thigh = Vector3(1.06, 1, 1.06)}
const TALL_SLIM := {spine_01 = Vector3(0.94, 1, 0.94), spine_02 = Vector3(0.92, 1, 0.92),
	upperarm = Vector3(0.9, 1, 0.9), thigh = Vector3(0.92, 1, 0.92), calf = Vector3(0.92, 1, 0.92)}
const BROAD := {spine_01 = Vector3(1.16, 1, 1.18), spine_02 = Vector3(1.1, 1, 1.12),
	spine_03 = Vector3(1.06, 1, 1.06), upperarm = Vector3(1.12, 1, 1.12),
	thigh = Vector3(1.08, 1, 1.08)}

## NPCs: Xi's super squad (O5) plus the stage people (O3), all made up. Each entry has
## id, name, body (male/female), skin, hair, hair_color and eyes; the rest is optional:
## accessories, scale, face, shape, posture, prints. Faces and builds vary by id unless
## overridden, so new people can be added with a single line.
const NPCS := [
	{
		id = &"helper_qwen", name = "Qwen Helper", role = "engineer",
		skin = &"tan", hair = ["Hair_SimpleParted"], hair_color = Color(0.10, 0.09, 0.09),
		alt_hair_color = Color(0.32, 0.26, 0.2),
		hair_volume = [Vector3(1.03, 1.07, 1.04), Vector3(0.0, 0.005, -0.003)],
		face = {jaw = 0.94, chin = -0.002, chin_round = 0.006, cheekbones = 0.002, fullness = -0.003,
			nose_width = 0.96, nose_length = 0.003, nose_bridge = 0.001, eye_open = 0.0008,
			eye_tilt = 0.0004, face_length = 1.02, mouth_width = 0.95},
		face_rest = {smile = 0.38, brow_up = 0.16}, brows = Vector3(0.96, 0.82, 1.0), eyes = "DarkBrown",
		scale = 1.02, accessories = [&"glasses"], accessory_color = Color(0.08, 0.08, 0.09),
		prints = {0: "tee"},
		shape = {spine_01 = Vector3(0.9, 1, 0.9), spine_02 = Vector3(0.88, 1, 0.88), spine_03 = Vector3(0.9, 1, 0.9),
			upperarm = Vector3(0.84, 1, 0.84), lowerarm = Vector3(0.87, 1, 0.87),
			thigh = Vector3(0.9, 1, 0.9), calf = Vector3(0.92, 1, 0.92), neck_01 = Vector3(0.94, 1, 0.94)},
		posture = {spine_02 = Vector3(-2, 0, 0), spine_03 = Vector3(-2, 0, 0), neck_01 = Vector3(1, 0, 0), Head = Vector3(-1, 0, 0)},
	},
	{
		id = &"helper_alibaba", name = "Alibaba Helper", role = "engineer",
		skin = &"medium", hair = ["Hair_Buzzed"], hair_color = Color(0.07, 0.06, 0.06),
		alt_hair_color = Color(0.3, 0.28, 0.26),
		hair_volume = [Vector3(1.02, 1.02, 1.02), Vector3(0.0, 0.002, 0.0)],
		face = {jaw = 1.06, chin = 0.002, chin_round = 0.012, fullness = 0.008, cheekbones = -0.001,
			nose_width = 1.04, nose_length = 0.002, eye_open = 0.0004, eye_tilt = 0.0002,
			face_length = 0.97, mouth_width = 1.02, lips = 0.001},
		face_rest = {smile = 0.5, brow_up = 0.12}, brows = Vector3(1.02, 0.9, 1.0), eyes = "Brown",
		scale = 0.93, accessories = [],
		prints = {0: "tee"},
		shape = {spine_01 = [Vector3(1.16, 1, 1.2), Vector3(0, 0, 0.01)], spine_02 = Vector3(1.12, 1, 1.14),
			spine_03 = Vector3(1.02, 1, 1.04), pelvis = Vector3(1.08, 1, 1.1),
			upperarm = Vector3(1.1, 1, 1.1), lowerarm = Vector3(1.04, 1, 1.04),
			thigh = Vector3(1.08, 1, 1.08), calf = Vector3(1.04, 1, 1.04), neck_01 = Vector3(1.04, 1, 1.04)},
		posture = {spine_01 = Vector3(1, 0, 0), spine_02 = Vector3(1, 0, 0), neck_01 = Vector3(2, 0, 0), Head = Vector3(-2, 0, 0)},
	},
	{
		id = &"helper_kimi", name = "Kimi Helper", role = "engineer",
		skin = &"pale", hair = ["Hair_ShortCurls"], hair_color = Color(0.09, 0.08, 0.08),
		alt_hair_color = Color(0.28, 0.22, 0.17),
		hair_volume = [Vector3(1.06, 1.08, 1.06), Vector3(0.0, 0.004, -0.002)],
		face = {jaw = 0.98, chin = -0.001, chin_forward = 0.002, chin_round = 0.004, fullness = -0.001,
			nose_width = 0.98, nose_length = 0.004, nose_bridge = 0.002, brow = 0.001,
			eye_open = 0.0006, eye_tilt = 0.0003, face_length = 1.01, mouth_width = 0.98},
		face_rest = {smile = 0.24, brow_up = 0.22, squint = 0.1}, brows = Vector3(1.0, 0.86, 1.0), eyes = "Grey",
		scale = 1.05, accessories = [],
		prints = {0: "tee"},
		shape = {spine_01 = Vector3(0.98, 1, 0.98), spine_02 = Vector3(0.96, 1, 0.96), spine_03 = Vector3(0.94, 1, 0.94),
			upperarm = Vector3(0.9, 1, 0.9), lowerarm = Vector3(0.92, 1, 0.92),
			thigh = Vector3(0.94, 1, 0.94), calf = Vector3(0.95, 1, 0.95), neck_01 = Vector3(0.96, 1, 0.96)},
		posture = {spine_02 = Vector3(-1, 0, 0), spine_03 = Vector3(-1, 0, 0), neck_01 = Vector3(1, 0, 0), Head = Vector3(-1, 0, 0)},
	},

	# --- O3 stage people: the Senate ---
	{id = &"chair", name = "Committee Chair", role = "chair", skin = &"light",
		hair = "Hair_ElderThinning", hair_color = HAIR_GREY, eyes = "Grey",
		accessories = [&"thick_glasses"], scale = 0.98, posture = UPRIGHT},
	{id = &"senator_1", name = "Senator 1", role = "committee", skin = &"warm",
		hair = "Hair_SilverSweep", hair_color = HAIR_SILVER, eyes = "Grey",
		accessories = [&"glasses"], scale = 1.04},
	{id = &"senator_2", name = "Senator 2", role = "committee", body = &"female", skin = &"female_light",
		hair = "Hair_AcademicWave", hair_color = HAIR_BROWN, eyes = "Blue", scale = 0.98},
	{id = &"senator_3", name = "Senator 3", role = "committee", skin = &"brown",
		hair = "Hair_PolitburoPart", hair_color = HAIR_BLACK, eyes = "Brown", shape = STOCKY, scale = 1.06},
	{id = &"senator_4", name = "Senator 4", role = "committee", body = &"female", skin = &"female_light",
		hair = "Hair_Bob", hair_color = HAIR_AUBURN, eyes = "Green", scale = 0.96},
	{id = &"stenographer", name = "Stenographer", role = "staff", body = &"female", skin = &"female_light",
		hair = "Hair_Bun", hair_color = HAIR_BROWN, eyes = "DarkBrown",
		accessories = [&"glasses"], scale = 0.93,
		hair_volume = [Vector3(1.02, 1.03, 1.02), Vector3(0, 0.003, 0)]},
	{id = &"press_1", name = "Press 1", role = "press", skin = &"tan",
		hair = "Hair_Caesar", hair_color = HAIR_BLACK, eyes = "Brown", scale = 1.02},
	{id = &"press_2", name = "Press 2", role = "press", body = &"female", skin = &"female_dark",
		hair = "Hair_ShortCurls", hair_color = HAIR_BLACK, eyes = "Brown", scale = 0.95},
	{id = &"press_3", name = "Press 3", role = "press", skin = &"medium",
		hair = "Hair_UndercutPomp", hair_color = HAIR_DARK, eyes = "Green", scale = 1.0},
	{id = &"aide_1", name = "Aide 1", role = "crowd", body = &"female", skin = &"female_light",
		hair = "Hair_Bun", hair_color = HAIR_BLOND, eyes = "Blue", scale = 0.94,
		hair_volume = [Vector3(1.02, 1.03, 1.02), Vector3(0, 0.003, 0)]},
	{id = &"aide_2", name = "Aide 2", role = "crowd", body = &"female", skin = &"female_dark",
		hair = "Hair_AcademicWave", hair_color = HAIR_BLACK, eyes = "DarkBrown", scale = 0.97},
	{id = &"aide_3", name = "Aide 3", role = "crowd", skin = &"tan",
		hair = "Hair_SimpleParted", hair_color = HAIR_BROWN, eyes = "Brown", scale = 1.0},
	{id = &"citizen_1", name = "Citizen 1", role = "crowd", skin = &"warm",
		hair = "Hair_CurlyMop", hair_color = HAIR_BROWN, eyes = "Brown", shape = STOCKY, scale = 1.05},
	{id = &"citizen_2", name = "Citizen 2", role = "crowd", body = &"female", skin = &"female_dark",
		hair = "Hair_Long", hair_color = HAIR_DARK, eyes = "Brown", scale = 0.96,
		hair_volume = [Vector3(1.04, 1.04, 1.04), Vector3(0, 0.002, 0)]},
	{id = &"citizen_3", name = "Citizen 3", role = "crowd", skin = &"medium",
		hair = "Hair_Buzzed", hair_color = HAIR_BLACK, eyes = "Brown", scale = 0.98},

	# --- O3 stage people: the mensa ---
	{id = &"cook", name = "Cook", role = "staff", skin = &"medium",
		hair = "Hair_Buzzed", hair_color = HAIR_BLACK, eyes = "Brown", shape = STOCKY, scale = 1.03},
	{id = &"cashier", name = "Cashier", role = "staff", body = &"female", skin = &"female_light",
		hair = "Hair_Bun", hair_color = HAIR_AUBURN, eyes = "Green", scale = 0.95,
		hair_volume = [Vector3(1.02, 1.03, 1.02), Vector3(0, 0.003, 0)]},
	{id = &"student_1", name = "Student 1", role = "crowd", skin = &"pale",
		hair = "Hair_CurlyMop", hair_color = HAIR_DARK, eyes = "Blue", scale = 1.0},
	{id = &"student_2", name = "Student 2", role = "crowd", body = &"female", skin = &"female_light",
		hair = "Hair_Long", hair_color = HAIR_BLACK, eyes = "Brown", scale = 0.94,
		hair_volume = [Vector3(1.04, 1.04, 1.04), Vector3(0, 0.002, 0)]},
	{id = &"student_3", name = "Student 3", role = "crowd", skin = &"brown",
		hair = "Hair_Caesar", hair_color = HAIR_BROWN, eyes = "Brown", shape = BROAD, scale = 1.07},
	{id = &"student_4", name = "Student 4", role = "crowd", skin = &"tan",
		hair = "Hair_UndercutPomp", hair_color = HAIR_BLACK, eyes = "DarkBrown", scale = 1.01},
	{id = &"student_5", name = "Student 5", role = "crowd", body = &"female", skin = &"female_dark",
		hair = "Hair_AcademicWave", hair_color = HAIR_BLACK, eyes = "Brown", scale = 0.99},
	{id = &"student_6", name = "Student 6", role = "crowd", skin = &"light",
		hair = "Hair_ShortCurls", hair_color = HAIR_RED, eyes = "Green", scale = 1.02, posture = LEAN_FORWARD},
	{id = &"student_7", name = "Student 7", role = "crowd", skin = &"medium",
		hair = "Hair_SimpleParted", hair_color = HAIR_BROWN, eyes = "Blue", shape = TALL_SLIM, scale = 1.09},
	{id = &"student_8", name = "Student 8", role = "crowd", body = &"female", skin = &"female_light",
		hair = "Hair_Bob", hair_color = HAIR_BLOND, eyes = "Green", scale = 0.92},
	{id = &"student_9", name = "Student 9", role = "crowd", skin = &"warm",
		hair = "Hair_Buzzed", hair_color = HAIR_BLACK, eyes = "DarkBrown", scale = 0.96},
	{id = &"student_10", name = "Student 10", role = "crowd", body = &"female", skin = &"female_dark",
		hair = "Hair_Bun", hair_color = HAIR_DARK, eyes = "Brown", scale = 0.97,
		hair_volume = [Vector3(1.02, 1.03, 1.02), Vector3(0, 0.003, 0)]},
	{id = &"grad_student", name = "Grad Student", role = "crowd", body = &"female", skin = &"female_light",
		hair = "Hair_AcademicWave", hair_color = HAIR_DARK, eyes = "Grey",
		accessories = [&"glasses"], scale = 0.96},

	# --- O3 stage people: the foundry ---
	{id = &"technician_1", name = "Technician 1", role = "operator", skin = &"pale",
		hair = "Hair_Buzzed", hair_color = HAIR_BLACK, eyes = "Blue", scale = 1.0},
	{id = &"technician_2", name = "Technician 2", role = "operator", skin = &"tan",
		hair = "Hair_Caesar", hair_color = HAIR_DARK, eyes = "Brown",
		accessories = [&"thick_glasses"], scale = 1.04},
	{id = &"technician_3", name = "Technician 3", role = "engineer", body = &"female", skin = &"female_light",
		hair = "Hair_Bun", hair_color = HAIR_BROWN, eyes = "DarkBrown", scale = 0.95,
		hair_volume = [Vector3(1.02, 1.03, 1.02), Vector3(0, 0.003, 0)]},
	{id = &"technician_4", name = "Technician 4", role = "engineer", skin = &"brown",
		hair = "Hair_ShortCurls", hair_color = HAIR_BLACK, eyes = "Brown", scale = 0.99},
	{id = &"lead_architect", name = "Lead Architect", role = "crowd", skin = &"light",
		hair = "Hair_SilverSweep", hair_color = HAIR_GREY, eyes = "Grey",
		accessories = [&"glasses"], scale = 1.02, posture = UPRIGHT},
	{id = &"quality_inspector", name = "Quality Inspector", role = "crowd", body = &"female", skin = &"female_dark",
		hair = "Hair_Bob", hair_color = HAIR_BLACK, eyes = "DarkBrown",
		accessories = [&"glasses"], scale = 0.94},
	{id = &"cleanroom_guard", name = "Cleanroom Guard", role = "crowd", skin = &"brown",
		hair = "Hair_Buzzed", hair_color = HAIR_BLACK, eyes = "Brown", shape = BROAD, scale = 1.05},
	{id = &"cleanroom_aide", name = "Cleanroom Aide", role = "crowd", body = &"female", skin = &"female_light",
		hair = "Hair_Long", hair_color = HAIR_BROWN, eyes = "Brown", scale = 0.93,
		hair_volume = [Vector3(1.04, 1.04, 1.04), Vector3(0, 0.002, 0)]},

	# --- O3 stage people: the server farm ---
	{id = &"sysadmin_1", name = "Sysadmin 1", role = "sysadmin", skin = &"pale",
		hair = "Hair_CurlyMop", hair_color = HAIR_BROWN, eyes = "Blue",
		accessories = [&"glasses"], scale = 1.0, posture = SLOUCH},
	{id = &"sysadmin_2", name = "Sysadmin 2", role = "sysadmin", body = &"female", skin = &"female_dark",
		hair = "Hair_Bun", hair_color = HAIR_DARK, eyes = "Brown", scale = 0.96,
		hair_volume = [Vector3(1.02, 1.03, 1.02), Vector3(0, 0.003, 0)]},
	{id = &"noc_lead", name = "NOC Lead", role = "engineer", body = &"female", skin = &"female_light",
		hair = "Hair_AcademicWave", hair_color = HAIR_AUBURN, eyes = "Green", scale = 1.0},
	{id = &"cloud_architect", name = "Cloud Architect", role = "engineer", skin = &"tan",
		hair = "Hair_SimpleParted", hair_color = HAIR_BROWN, eyes = "Brown",
		accessories = [&"glasses"], scale = 1.03},
	{id = &"devops_tech", name = "DevOps Tech", role = "crowd", skin = &"brown",
		hair = "Hair_ShortCurls", hair_color = HAIR_BLACK, eyes = "DarkBrown", scale = 0.98},
	{id = &"site_reliability", name = "Site Reliability", role = "crowd", skin = &"warm",
		hair = "Hair_Caesar", hair_color = HAIR_DARK, eyes = "Brown", scale = 1.01},
	{id = &"intern", name = "Intern", role = "crowd", skin = &"light",
		hair = "Hair_UndercutPomp", hair_color = HAIR_BROWN, eyes = "Blue", scale = 0.95, posture = UPRIGHT},
	{id = &"field_engineer", name = "Field Engineer", role = "crowd", skin = &"medium",
		hair = "Hair_Buzzed", hair_color = HAIR_DARK, eyes = "Green", shape = BROAD, scale = 1.04,
		posture = LEAN_FORWARD},
]


func _initialize() -> void:
	var only := OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	for i in NPCS.size():
		var spec := _expand(NPCS[i], i)
		if only.is_empty() or String(spec.id) in only:
			_build(spec, i)
	quit()


## Fills the optional fields from the id, with something plausible and repeatable.
## Explicit fields in the table always win.
func _expand(raw: Dictionary, order: int) -> Dictionary:
	var spec := raw.duplicate(true)
	var female: bool = spec.get("body", &"male") == &"female"
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(spec.id)) + order * 7919
	if spec.get("hair") is String:
		spec.hair = [spec.hair]
	if not spec.has("skin"):
		spec.skin = &"female_light" if female else &"medium"
	if not spec.has("hair_color"):
		spec.hair_color = HAIR_DARK
	if not spec.has("alt_hair_color"):
		var hc: Color = spec.hair_color
		spec.alt_hair_color = hc.darkened(0.25) if hc.v < 0.35 else hc.lightened(0.12)
	if not spec.has("hair_volume"):
		spec.hair_volume = [Vector3.ONE, Vector3.ZERO]
	if not spec.has("face"):
		spec.face = _random_face(rng, female)
	if not spec.has("face_rest"):
		spec.face_rest = {smile = rng.randf_range(0.1, 0.35), brow_up = rng.randf_range(0.05, 0.2)}
	if not spec.has("brows"):
		spec.brows = Vector3(rng.randf_range(0.96, 1.04), rng.randf_range(0.8, 0.9), 1.0)
	if not spec.has("eyes"):
		spec.eyes = "Brown"
	if not spec.has("scale"):
		spec.scale = 0.97 if female else 1.0
	if not spec.has("accessories"):
		spec.accessories = []
	if not spec.has("accessory_color"):
		spec.accessory_color = Color(0.07, 0.07, 0.08)
	if not spec.has("shape"):
		spec.shape = _random_shape(rng, female)
	if not spec.has("posture"):
		spec.posture = _random_posture(rng)
	if not spec.has("role"):
		spec.role = "crowd"
	if not spec.has("name"):
		spec.name = String(spec.id).capitalize()
	if not spec.has("prints"):
		spec.prints = {}
	return spec


func _random_face(rng: RandomNumberGenerator, female: bool) -> Dictionary:
	return {
		jaw = rng.randf_range(0.95, 1.0) if female else rng.randf_range(0.95, 1.06),
		chin = rng.randf_range(-0.002, 0.0025),
		chin_forward = rng.randf_range(-0.0015, 0.002),
		chin_round = rng.randf_range(0.002, 0.01),
		cheekbones = rng.randf_range(-0.002, 0.0035),
		fullness = rng.randf_range(-0.002, 0.006),
		nose_width = rng.randf_range(0.94, 1.06),
		nose_length = rng.randf_range(0.0005, 0.0038),
		nose_bridge = rng.randf_range(0.0003, 0.002),
		brow = rng.randf_range(0.0, 0.0018),
		eye_open = rng.randf_range(0.0003, 0.001),
		eye_tilt = rng.randf_range(0.0002, 0.0005),
		face_length = rng.randf_range(0.97, 1.03),
		mouth_width = rng.randf_range(0.95, 1.03),
		lips = rng.randf_range(0.0006, 0.0016) if female else rng.randf_range(0.0002, 0.001),
	}


func _random_shape(rng: RandomNumberGenerator, female: bool) -> Dictionary:
	if female:
		return {
			spine_01 = Vector3(rng.randf_range(0.93, 1.0), 1, rng.randf_range(0.96, 1.05)),
			spine_02 = Vector3(rng.randf_range(0.93, 1.0), 1, rng.randf_range(0.96, 1.04)),
			spine_03 = Vector3(rng.randf_range(0.95, 1.02), 1, rng.randf_range(0.96, 1.04)),
			pelvis = Vector3(rng.randf_range(0.98, 1.06), 1, rng.randf_range(0.98, 1.06)),
			upperarm = Vector3(rng.randf_range(0.9, 1.0), 1, rng.randf_range(0.9, 1.0)),
			lowerarm = Vector3(rng.randf_range(0.9, 1.0), 1, rng.randf_range(0.9, 1.0)),
			thigh = Vector3(rng.randf_range(0.96, 1.06), 1, rng.randf_range(0.96, 1.06)),
			calf = Vector3(rng.randf_range(0.96, 1.04), 1, rng.randf_range(0.96, 1.04)),
			neck_01 = Vector3(rng.randf_range(0.94, 0.98), 1, rng.randf_range(0.94, 0.98)),
		}
	return {
		spine_01 = Vector3(rng.randf_range(0.94, 1.14), 1, rng.randf_range(0.94, 1.14)),
		spine_02 = Vector3(rng.randf_range(0.94, 1.1), 1, rng.randf_range(0.94, 1.1)),
		spine_03 = Vector3(rng.randf_range(0.94, 1.08), 1, rng.randf_range(0.94, 1.08)),
		pelvis = Vector3(rng.randf_range(0.96, 1.08), 1, rng.randf_range(0.96, 1.08)),
		upperarm = Vector3(rng.randf_range(0.9, 1.12), 1, rng.randf_range(0.9, 1.12)),
		lowerarm = Vector3(rng.randf_range(0.9, 1.1), 1, rng.randf_range(0.9, 1.1)),
		thigh = Vector3(rng.randf_range(0.94, 1.08), 1, rng.randf_range(0.94, 1.08)),
		calf = Vector3(rng.randf_range(0.94, 1.06), 1, rng.randf_range(0.94, 1.06)),
		neck_01 = Vector3(rng.randf_range(0.94, 1.04), 1, rng.randf_range(0.94, 1.04)),
	}


func _random_posture(rng: RandomNumberGenerator) -> Dictionary:
	return {
		spine_02 = Vector3(rng.randf_range(-2, 2), 0, rng.randf_range(-1.5, 1.5)),
		spine_03 = Vector3(rng.randf_range(-1.5, 1.5), 0, rng.randf_range(-1, 1)),
		neck_01 = Vector3(rng.randf_range(-1.5, 2), 0, rng.randf_range(-1, 1)),
		Head = Vector3(rng.randf_range(-1.5, 1), 0, rng.randf_range(-1, 1)),
	}


func _build(spec: Dictionary, order: int) -> void:
	var path := OUT_DIR + String(spec.id) + ".tres"
	var previous := load(path) as CharacterData if ResourceLoader.exists(path) else null
	var data := CharacterData.new()
	data.id = spec.id
	data.display_name = spec.name
	data.archetype = spec.get("role", "engineer")
	data.select_order = order
	data.placeholder_color = spec.get("color", Color(0.55, 0.55, 0.58))
	data.kit = &""
	data.voice_fallback = &""
	data.moves = [] as Array[MoveData]
	data.combo_trials = []

	# Look: the shared base body (male or female) and the generated outfit
	# (tools/build_outfits.gd, specs keyed by the NPC id).
	data.model_scene = load(FEMALE_BODY if spec.get("body", &"male") == &"female" else MALE_BODY)
	data.model_scale = spec.get("scale", 1.0)
	data.body_shape = spec.get("shape", {}).duplicate(true)
	data.face_shape = spec.get("face", {}).duplicate(true)
	data.face_rest = spec.get("face_rest", {}).duplicate(true)
	data.posture = spec.get("posture", {}).duplicate(true)
	var prints := {}
	for slot in spec.get("prints", {}):
		var print_path := PRINT_DIR + "T_%s_%s.png" % [spec.id, spec.prints[slot]]
		if ResourceLoader.exists(print_path):
			prints[slot] = load(print_path)
		else:
			push_warning("%s: no print %s (run tools/build_prints.py and --import first)" % [spec.id, print_path])
	data.outfit_textures = prints
	data.hair_scale = spec.hair_volume[0] if spec.has("hair_volume") else Vector3.ONE
	data.hair_offset = spec.hair_volume[1] if spec.has("hair_volume") else Vector3.ZERO
	data.brow_scale = spec.get("brows", Vector3.ONE)
	data.eye_texture = load("res://assets/characters/base/T_Eye_%s.png" % spec.eyes) if spec.has("eyes") else null
	var accessories: Array[StringName] = []
	accessories.assign(spec.get("accessories", []))
	data.accessories = accessories
	if spec.has("accessory_color"):
		data.accessory_color = spec.accessory_color
	data.body_albedo = load(SKINS[spec.skin])
	data.alt_body_albedo = data.body_albedo
	var hair: Array[PackedScene] = []
	for piece: String in spec.hair:
		hair.append(load(HAIR_DIR + piece + (".tscn" if ResourceLoader.exists(HAIR_DIR + piece + ".tscn") else ".gltf")))
	data.hair_scenes = hair
	data.hair_color = spec.hair_color
	data.alt_hair_color = spec.alt_hair_color
	data.alt_material_colors = {}
	data.realistic_shading = true

	# Keep the generated outfit (tools/build_outfits.gd) on a rebuild.
	data.outfit_mesh = previous.outfit_mesh if previous else null
	data.outfit_body_mesh = previous.outfit_body_mesh if previous else null
	data.outfit_colors = previous.outfit_colors if previous else PackedColorArray()
	data.alt_outfit_colors = previous.alt_outfit_colors if previous else PackedColorArray()
	data.outfit_fabrics = previous.outfit_fabrics if previous else ([] as Array[StringName])
	data.detailed_textures = previous.detailed_textures if previous else false
	var portrait := PORTRAIT_DIR + String(spec.id) + ".png"
	data.portrait = load(portrait) if ResourceLoader.exists(portrait) else null

	var err := ResourceSaver.save(data, path)
	print("%-16s %-18s %s" % [spec.id, spec.name, "ok" if err == OK else "ERROR %d" % err])
