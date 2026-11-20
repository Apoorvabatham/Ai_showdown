extends SceneTree
## Builds the AI Showdown roster: res://data/characters/<id>.tres and a copy of the kit's
## moveset in res://data/moves/<id>/ for each fighter in ROSTER, from the original 3D
## Fighter cast in res://data/kits/ (CharacterData.kit).
##
## Run: godot --headless --path . -s res://tools/build_showdown_roster.gd
## (append `-- <id> ...` to rebuild only those fighters)
##
## A fighter keeps its kit's moves, frame data, animations and combo trials; this renames
## the specials and the super, scales the damage, and sets the look, stats and lines.
## Rebuilding keeps the generated outfit (tools/build_outfits.gd) and uses the portrait
## (tools/render_portraits.gd) once it has been rendered and imported. Order:
##   1. this tool  2. tools/build_outfits.gd  3. tools/render_portraits.gd and
##   tools/render_cutins.gd (windowed / Xvfb)  4. --import  5. this tool again (portraits).
##
## Satire of public personas and ideas only: made-up names, no real logos or likenesses
## beyond a generic low-poly body, hair colour and clothes.

const KIT_DIR := "res://data/kits/"
const OUT_DIR := "res://data/characters/"
const MOVES_DIR := "res://data/moves/"
const PORTRAIT_DIR := "res://assets/ui/portraits/"
const MALE_BODY := "res://assets/characters/base/Superhero_Male_FullBody.gltf"
const HAIR_DIR := "res://assets/characters/hair/"
## Per-fighter moveset overrides (remove / tweak / add moves, stats, trials).
const MOVESETS: Dictionary = preload("res://tools/showdown_movesets.gd").MOVESETS
const SKINS := {
	&"light": "res://assets/characters/base/T_Superhero_Male_Light.png",
	&"light_alt": "res://assets/characters/base/T_Superhero_Male_Dark.png",
	&"medium": "res://assets/characters/base/T_Showdown_Male_Medium.png",
	&"brown": "res://assets/characters/jin/T_Jin_Body.png",
	&"tan": "res://assets/characters/base/T_Showdown_Male_Tan.png",
	&"pale": "res://assets/characters/base/T_Showdown_Male_Pale.png",
	&"warm": "res://assets/characters/base/T_Showdown_Male_Warm.png",
}

## Per fighter. `moves`: kit move file -> new name (a super's follow-ups share its name);
## `damage`: multiplier on every move's damage and chip; `stats`: CharacterData overrides;
## `scale`, `shape`, `face`, `accessories`: height, body proportions, facial structure and
## head pieces (CharacterData.model_scale, body_shape, face_shape, accessories).
const ROSTER := [
	{
		id = &"ram", name = "Ram Altman", kit = &"mira", archetype = "Hype Brawler",
		age = 41,
		description = "Charges up with Add More Compute until every rush scales like a law of nature. AGI is coming next year. Every year.",
		skin = &"light", hair = ["Hair_Buzzed"], hair_color = Color(0.28, 0.20, 0.14), alt_hair_color = Color(0.12, 0.10, 0.09),
		hair_volume = [Vector3(1.02, 1.05, 1.03), Vector3(0.0, 0.003, 0.0)],
		damage = 1.04, stats = {max_health = 1040},
		face = {jaw = 0.92, chin = -0.002, chin_round = 0.004, fullness = -0.003, nose_width = 0.92, nose_bridge = 0.002, eye_open = 0.0012, eye_tilt = 0.0003, mouth_width = 0.95},
		face_rest = {brow_up = 0.52, smile = 0.24}, brows = Vector3(0.95, 0.80, 1.0), eyes = "Blue",
		scale = 0.98, accessories = [], prints = {0: "tee"},
		shape = {spine_01 = Vector3(0.92, 1, 0.92), spine_02 = Vector3(0.9, 1, 0.9), spine_03 = Vector3(0.9, 1, 0.9),
			upperarm = Vector3(0.88, 1, 0.88), lowerarm = Vector3(0.9, 1, 0.9), thigh = Vector3(0.9, 1, 0.9), calf = Vector3(0.92, 1, 0.92), neck_01 = Vector3(0.92, 1, 0.92)},
		posture = {spine_01 = Vector3(1, 0, 0), spine_02 = Vector3(1, 0, 0), neck_01 = Vector3(2, 0, 0), Head = Vector3(-2, 0, 0)},
		moves = {lakas_stance = "Add More Compute", bagyo_rush = "Funding Round Rush", lawin_rise = "Hype Cycle",
			lawin_drop = "Product Drop", sipa_flip = "Pivot Flip", tapik = "Teaser Tweet",
			huling_hagupit = "Scaling Law", hagupit_finish = "Scaling Law", hagupit_max = "Scaling Law"},
		voice = &"kenji", color = Color(0.3, 0.75, 0.6),
		intro = ["Honestly? I think this is going to be a really good fight.", "We're going to need a lot more compute for this.",
			"AGI is close. So is my fist."],
		wins = ["That felt like a pretty big deal, honestly.", "Scaling works. It's kind of wild.",
			"I'll need about seven trillion dollars for the rematch."],
		rivals = {"tesla": ["Still upset you left the board?", "See you in court. Again."],
			"dario": ["You used to work for me, you know.", "Safety is great. Shipping is better."]},
	},
	{
		id = &"tesla", name = "tesla man", kit = &"rhea", archetype = "Rushdown",
		age = 55,
		description = "Moves fast and breaks things, mostly his own schedule. Swears the Rocket Launch will be ready next quarter.",
		skin = &"light", hair = ["Hair_UndercutPomp"], hair_color = Color(0.27, 0.18, 0.11), alt_hair_color = Color(0.36, 0.27, 0.16),
		damage = 1.0, stats = {walk_speed = 2.7, dash_speed = 7.8, max_health = 1030},
		face = {jaw = 1.16, chin = 0.009, chin_forward = 0.006, face_length = 1.08, fullness = 0.009, cheekbones = 0.002, eye_open = -0.0018, brow = 0.002, nose_length = 0.002, nose_width = 1.04, mouth_width = 1.08, lips = -0.001},
		face_rest = {smile = 0.5, squint = 0.25, brow_up = 0.1}, brows = Vector3(1.0, 0.85, 1.0), eyes = "Green",
		scale = 1.09, accessories = [], hair_volume = [Vector3(1.05, 1.15, 1.08), Vector3(0, 0.006, -0.006)], prints = {0: "tee"},
		shape = {spine_03 = Vector3(1.1, 1, 1.06), spine_02 = Vector3(1.06, 1, 1.08), spine_01 = [Vector3(1.12, 1, 1.18), Vector3(0, 0, 0.012)],
			neck_01 = Vector3(1.12, 1, 1.1), upperarm = Vector3(0.9, 1, 0.9), lowerarm = Vector3(0.93, 1, 0.93), Head = Vector3(1.05, 1.08, 1.04)},
		posture = {spine_03 = Vector3(7, 0, 0), neck_01 = Vector3(6, 0, 0), Head = Vector3(-15, 0, 0), clavicle = Vector3(0, -6, 0)},
		moves = {gale_slide = "Full Self-Sliding", crescent_rise = "Starship Hop", rushing_hook = "Hardcore Hook",
			step_kick = "Hyperloop Step", tempest_kicks = "Rocket Launch", tempest_finish = "Rocket Launch"},
		voice = &"jin", color = Color(0.85, 0.2, 0.2),
		intro = ["This fight will be done in two weeks. Probably.", "I'd put my odds at a solid sixty-nine percent.",
			"Let's make fighting multiplanetary."],
		wins = ["Rapid unscheduled disassembly. Yours.", "Concerning.", "Exactly."],
		rivals = {"ram": ["You turned my nonprofit into a product!", "My lawyers will handle the rematch."],
			"zuckerbot": ["Cage match. Finally. I'm literally ready.", "Told you I'd show up."]},
	},
	{
		id = &"dario", name = "Dario Amoday", kit = &"lian", archetype = "Counter",
		age = 43,
		description = "A patient counter-fighter guided by a written constitution. Catches reckless strikes with Refusal Stance, then explains, at length, why that was unsafe.",
		skin = &"pale", hair = ["Hair_CurlyMop"], hair_color = Color(0.12, 0.09, 0.08), alt_hair_color = Color(0.28, 0.20, 0.14),
		hair_volume = [Vector3(1.04, 1.06, 1.04), Vector3(0.0, 0.004, -0.004)],
		damage = 1.03, stats = {max_health = 1035},
		face = {jaw = 1.04, chin = -0.004, chin_forward = 0.0, chin_round = 0.012, cheekbones = 0.001, fullness = 0.010,
			jowls = 0.008, double_chin = 0.004, nose_width = 1.14, nose_length = 0.004, nose_bridge = 0.003, brow = 0.002,
			eye_open = -0.0009, eye_fold = 0.5, eye_tilt = -0.0002, face_length = 0.96, lips = 0.0035, mouth_width = 1.10, pout = 0.001},
		face_rest = {brow_up = 0.45, brow_down = 0.0, smile = 0.45, jaw_open = 0.08}, brows = Vector3(1.0, 0.72, 1.0), eyes = "Grey",
		scale = 0.99, accessories = [&"thick_glasses"], accessory_color = Color(0.06, 0.06, 0.07),
		prints = {0: "tee"},
		shape = {spine_01 = Vector3(0.96, 1, 0.96), spine_02 = Vector3(0.94, 1, 0.94), spine_03 = Vector3(0.92, 1, 0.92),
			upperarm = Vector3(0.88, 1, 0.88), lowerarm = Vector3(0.9, 1, 0.9), thigh = Vector3(0.92, 1, 0.92), calf = Vector3(0.92, 1, 0.92),
			neck_01 = Vector3(0.94, 1, 0.94), Head = Vector3(1.07, 1.0, 1.05)},
		posture = {spine_01 = Vector3(1, 0, 0), spine_02 = Vector3(1, 0, 0), neck_01 = Vector3(2, 0, 0), Head = Vector3(-2, 0, 0)},
		moves = {still_water = "Refusal Stance", inch_palm = "Interpretability Palm", willow_step = "Responsible Scaling Step",
			chain_punch = "Red-Team Chain", double_palm = "Double-Check Palm",
			thousand_hands = "Constitutional Shield", thousand_finish = "Constitutional Shield"},
		voice = &"kenji", color = Color(0.85, 0.55, 0.3),
		intro = ["I'd estimate a ten to twenty-five percent chance this goes badly. For you.", "Let's do this carefully.",
			"I wrote a fifteen-thousand-word essay on why I'll win."],
		wins = ["Machines of loving grace. And one loving uppercut.", "That was a responsible scaling of force.",
			"I'm sorry, I can't help you get up."],
		rivals = {"ram": ["We left for a reason.", "Safety first. Then the knockout."]},
	},
	{
		id = &"zuckerbot", name = "Mark Zuckerbot", kit = &"valka", archetype = "Grappler",
		age = 42,
		description = "Trained in jiu-jitsu, raised on growth metrics. The Metaverse Trap pulls you into a virtual world where nobody has legs.",
		skin = &"pale", hair = ["Hair_ShortCurls"], hair_color = Color(0.25, 0.17, 0.11), alt_hair_color = Color(0.12, 0.09, 0.06),
		damage = 1.0, stats = {},
		face = {jaw = 0.93, chin = -0.002, chin_forward = 0.004, face_length = 1.0, fullness = -0.002, cheekbones = 0.0015, eye_open = 0.0012, nose_width = 0.98, nose_length = 0.004, nose_bridge = 0.002, mouth_width = 0.92, lips = -0.001, brow = 0.0},
		face_rest = {brow_up = 0.25, smile = 0.18}, brows = Vector3(1.05, 0.95, 1.0), eyes = "Blue",
		scale = 0.92, accessories = [], hair_volume = [Vector3(1.0, 1.0, 1.0), Vector3(0.0, 0.0, 0.0)],
		shape = {upperarm = Vector3(1.08, 1, 1.08), lowerarm = Vector3(1.04, 1, 1.04), neck_01 = Vector3(1.1, 1, 1.08),
			spine_03 = Vector3(1.04, 1, 1.02), Head = Vector3(1.0, 1.03, 1.0)},
		posture = {spine_02 = Vector3(-3, 0, 0), spine_03 = Vector3(-3, 0, 0), neck_01 = Vector3(-2, 0, 0), Head = Vector3(4, 0, 0)},
		moves = {valkyrie_slam = "Data Harvest Slam", spinning_lariat = "Pivot to Video", shoulder_tackle = "Move Fast Tackle",
			knee_lift = "Like-Button Knee", thunder_valkyrie = "Metaverse Trap"},
		voice = &"jin", color = Color(0.25, 0.45, 0.9),
		intro = ["Hello, fellow human. I, too, enjoy combat.", "Let's connect. With my fist.", "I've been training. In real life, even."],
		wins = ["Thank you for your data.", "Senator, I won a fight.", "Move fast and break things. Like you."],
		rivals = {"tesla": ["You actually showed up for the cage match.", "Next time, bring legs. Real ones."]},
	},
	{
		id = &"jensen", name = "Jensen Wong", kit = &"kenji", archetype = "Zoner",
		age = 63,
		description = "Never seen out of his leather jacket. Fires Tensor Blasts across the screen and buries rivals in GPU Rain. Weak spot: a rival chipmaker CEO who also happens to be family.",
		skin = &"warm", hair = ["Hair_SilverSweep"], hair_color = Color(0.72, 0.72, 0.74), alt_hair_color = Color(0.18, 0.18, 0.2),
		damage = 1.03, stats = {max_health = 1040},
		face = {eye_fold = 1.0, nose_bridge = -0.005, nose_width = 1.12, cheekbones = 0.004, fullness = 0.002, brow = -0.003, jaw = 1.02, eye_tilt = 0.0012, eye_open = -0.001, chin_round = 0.002, mouth_width = 1.02},
		face_rest = {smile = 0.45, squint = 0.15}, brows = Vector3(1.0, 0.72, 1.0), eyes = "DarkBrown",
		scale = 0.97, accessories = [&"glasses"], hair_volume = [Vector3(1.06, 1.15, 1.08), Vector3(0, 0.006, -0.006)], prints = {1: "tee"},
		shape = {spine_03 = Vector3(0.96, 1, 0.96), upperarm = Vector3(0.94, 1, 0.94), lowerarm = Vector3(0.95, 1, 0.95), spine_01 = Vector3(1.02, 1, 1.04)},
		posture = {spine_02 = Vector3(-3, 0, 0), spine_03 = Vector3(-4, 0, 0), neck_01 = Vector3(-3, 0, 0), Head = Vector3(-3, 0, 0), clavicle = Vector3(0, 3, 0)},
		moves = {ki_blast = "Tensor Blast", rising_dragon = "Leather Uppercut", snap_kick = "Keynote Kick",
			advancing_straight = "The More You Buy", dragon_barrage = "Leather Jacket Tornado", dragon_finish = "Leather Jacket Tornado"},
		projectile_color = Color(0.46, 0.8, 0.0),
		voice = &"kenji", color = Color(0.46, 0.73, 0.0),
		intro = ["The more you buy, the more you save.", "Let me show you our next-generation fist.", "Every fight is a data-center-scale fight."],
		wins = ["Thirty times faster than last year's beatdown.", "The leather jacket remains undefeated.",
			"Thank you, thank you. Now, about pricing..."],
		rivals = {"sundar": ["Your data centres run on my chips.", "Please, order more."],
			"algorithm": ["Who do you think trains you?", "Running on my hardware, losing on my hardware."]},
	},
	{
		id = &"yann", name = "Yann LeCant", kit = &"brutus", archetype = "Power",
		age = 65,
		description = "A heavyweight sceptic who insists none of this is real intelligence, then flattens you to prove the point. Posts the rebuttal mid-combo.",
		skin = &"light", hair = ["Hair_AcademicWave"], hair_color = Color(0.24, 0.23, 0.23), alt_hair_color = Color(0.48, 0.47, 0.46),
		hair_volume = [Vector3(1.08, 1.12, 1.08), Vector3(0.002, 0.006, -0.003)],
		damage = 1.0, stats = {},
		face = {jaw = 1.10, chin = 0.004, chin_forward = 0.003, fullness = 0.004, jowls = 0.003, nose_width = 1.10, nose_length = 0.004, nose_bridge = 0.003, brow = 0.003, eye_open = -0.0004, eye_tilt = 0.0002},
		face_rest = {smile = 0.28, brow_down = 0.32, brow_up = 0.12, grimace = 0.10}, brows = Vector3(1.10, 1.08, 1.0), eyes = "Grey",
		scale = 1.0, accessories = [&"glasses"], accessory_color = Color(0.12, 0.12, 0.14),
		shape = {spine_01 = [Vector3(1.22, 1.0, 1.25), Vector3(0, 0, 0.02)], spine_02 = Vector3(1.18, 1.0, 1.20), spine_03 = Vector3(1.20, 1.0, 1.22),
			pelvis = Vector3(1.10, 1.0, 1.12), neck_01 = Vector3(1.12, 1.0, 1.12), Head = Vector3(1.05, 1.02, 1.04),
			upperarm = Vector3(1.16, 1.0, 1.16), lowerarm = Vector3(1.12, 1.0, 1.12), thigh = Vector3(1.10, 1.0, 1.10), calf = Vector3(1.08, 1.0, 1.08)},
		posture = {spine_01 = Vector3(2, 0, 0), spine_02 = Vector3(2, 0, 0), neck_01 = Vector3(3, 0, 0), Head = Vector3(-4, 0, 0)},
		moves = {bull_charge = "Open-Source Charge", earthquake = "World Model Quake", overhead_smash = "Cat-Level Smash",
			heavy_boot = "Convolution Boot", titan_rush = "It's Just Autocomplete", titan_finish = "It's Just Autocomplete"},
		voice = &"brutus", color = Color(0.6, 0.3, 0.85),
		intro = ["Your fist has a weaker world model than a house cat.", "Doom? Please. My Roomba is more dangerous.",
			"Let me explain why you are wrong. Physically."],
		wins = ["Not intelligent. Just effective.", "See? No existential risk. Only you, on the floor.",
			"I will post a long thread on why that worked."],
		rivals = {"geoff": ["Geoff, my old friend. You worry too much.", "Turing Award, round two: mine."],
			"algorithm": ["Your architecture lacks a world model.", "Autoregressive nonsense."]},
	},
	{
		id = &"geoff", name = "Geoff Hintoff", kit = &"aelia", archetype = "Armoured Elder",
		age = 78,
		description = "The godfather of the neural net, now touring the world to warn you about it. His heavy moves shrug off a hit; his super comes with second thoughts.",
		skin = &"pale", hair = ["Hair_ElderThinning"], hair_color = Color(0.88, 0.88, 0.86), alt_hair_color = Color(0.55, 0.55, 0.55),
		hair_volume = [Vector3(1.04, 1.08, 1.04), Vector3(0.0, 0.005, -0.002)],
		damage = 1.07, stats = {max_health = 1070},
		face = {face_length = 1.08, fullness = -0.006, jowls = 0.004, jaw = 0.92, chin = 0.006, chin_forward = 0.002, nose_length = 0.006, nose_bridge = 0.003, nose_width = 0.95, brow = 0.003, eye_open = -0.0010, eye_tilt = -0.0002, cheekbones = -0.001},
		face_rest = {brow_up = 0.55, brow_down = 0.15, smile = 0.10, grimace = 0.10}, brows = Vector3(1.02, 1.05, 1.0), eyes = "Grey",
		scale = 1.04, accessories = [],
		shape = {spine_01 = Vector3(0.92, 1, 0.92), spine_02 = Vector3(0.9, 1, 0.9), spine_03 = Vector3(0.88, 1, 0.88),
			upperarm = Vector3(0.82, 1, 0.82), lowerarm = Vector3(0.85, 1, 0.85), thigh = Vector3(0.88, 1, 0.88), calf = Vector3(0.9, 1, 0.9), neck_01 = Vector3(0.9, 1.05, 0.9)},
		posture = {spine_01 = Vector3(2, 0, 0), spine_02 = Vector3(3, 0, 0), spine_03 = Vector3(2, 0, 0), neck_01 = Vector3(4, 0, 0), Head = Vector3(-5, 0, 0)},
		moves = {shield_rush = "Backprop Rush", rising_gauntlet = "Deep Uppercut", hammerfall = "Boltzmann Hammer",
			gauntlet_drive = "Gradient Drive", spur_rake = "Dropout Rake",
			emerald_oath = "I Regret Nothing… Wait", oath_finish = "I Regret Nothing… Wait"},
		voice = &"brutus", color = Color(0.85, 0.75, 0.5),
		intro = ["I invented this move. Now I'm starting to worry about it.", "Let me warn you about what happens next.",
			"I quit my job so I could speak freely. Mostly about punching."],
		wins = ["I console myself with the usual excuse: someone else would have done it.",
			"That went worse than I predicted. For you.", "Please, someone regulate me."],
		rivals = {"yann": ["Yann, you really should be more worried.", "Told you so. Politely."]},
	},
	{
		id = &"sundar", name = "Sundar Pickai", kit = &"kenji", archetype = "Calm Zoner",
		age = 54,
		description = "Unflappable and endlessly polite. Ranks your weaknesses and serves you ten blue links' worth of fireballs. Takes a hit better than he throws one.",
		skin = &"warm", hair = ["Hair_Buzzed"], hair_color = Color(0.11, 0.10, 0.10), alt_hair_color = Color(0.35, 0.35, 0.38),
		damage = 0.98, stats = {max_health = 1030, walk_speed = 1.9, back_walk_speed = 1.5, weight = 1.1, power_rating = 0.45, speed_rating = 0.5},
		face = {face_length = 1.06, jaw = 0.90, chin = 0.003, chin_forward = 0.002, nose_width = 0.95, nose_length = 0.005, nose_bridge = 0.003, fullness = -0.005, cheekbones = 0.003, eye_open = -0.0006, eye_tilt = 0.0004},
		face_rest = {smile = 0.45}, brows = Vector3(0.96, 0.78, 1.0), eyes = "DarkBrown",
		scale = 1.02, accessories = [&"glasses"], accessory_color = Color(0.08, 0.08, 0.1), prints = {0: "tee"},
		hair_volume = [Vector3(1.01, 1.05, 1.02), Vector3(0, 0.003, 0.0)],
		shape = {spine_03 = Vector3(0.88, 1, 0.88), upperarm = Vector3(0.84, 1, 0.84), lowerarm = Vector3(0.88, 1, 0.88),
			thigh = Vector3(0.88, 1, 0.88), calf = Vector3(0.9, 1, 0.9), neck_01 = Vector3(0.92, 1.05, 0.92)},
		posture = {spine_02 = Vector3(1, 0, 0), spine_03 = Vector3(1, 0, 0), neck_01 = Vector3(2, 0, 0), Head = Vector3(-2, 0, 0)},
		moves = {ki_blast = "Ten Blue Links", rising_dragon = "I'm Feeling Lucky", snap_kick = "Quarterly Kick",
			advancing_straight = "Pixel Push", dragon_barrage = "404 Not Found", dragon_finish = "404 Not Found"},
		projectile_color = Color(0.26, 0.52, 0.96),
		voice = &"kenji", color = Color(0.26, 0.52, 0.96),
		intro = ["I'm feeling lucky.", "We're an AI-first fighter now.", "Let's have a thoughtful, constructive fight."],
		wins = ["Did you mean: \"I lose\"?", "About one million results for \"knockout\".", "We'll be sunsetting your health bar."],
		rivals = {"ram": ["We invented the transformer, you know.", "Code red: resolved."]},
	},
	{
		id = &"donald", name = "Donald Tarrif", kit = &"valka", archetype = "Heavy Grappler",
		age = 80,
		description = "A heavyweight dealmaker. Slaps a tariff on every hit and calls every round the greatest round in history.",
		skin = &"tan", hair = ["Hair_TrumpPomp"], hair_color = Color(0.75, 0.65, 0.45), alt_hair_color = Color(0.85, 0.85, 0.82),
		damage = 0.93, stats = {max_health = 1100, walk_speed = 1.5, back_walk_speed = 1.1, dash_speed = 4.4, weight = 1.3,
			throw_damage = 160, jump_velocity = 5.5, power_rating = 0.88, speed_rating = 0.3},
		face = {fullness = 0.040, jaw = 1.03, chin = 0.002, chin_round = 0.020, jowls = 0.020, double_chin = 0.018,
			cheekbones = -0.004, eye_open = -0.0040, eye_tilt = -0.0002, mouth_width = 0.94, pout = 0.006, lips = 0.003,
			nose_width = 1.06, nose_bridge = 0.001, brow = 0.004, face_length = 0.96},
		face_rest = {squint = 0.65, brow_down = 0.40, grimace = 0.15}, brows = Vector3(1.0, 0.7, 1.0), eyes = "Blue",
		scale = 1.08, accessories = [], hair_volume = [Vector3(1.09, 1.12, 1.12), Vector3(0, -0.004, 0.008)],
		shape = {pelvis = [Vector3(1.46, 1, 1.62), Vector3(0, 0, 0.02)], spine_01 = [Vector3(1.66, 1, 1.96), Vector3(0, 0, 0.06)],
			spine_02 = [Vector3(1.54, 1, 1.76), Vector3(0, 0, 0.04)], spine_03 = Vector3(1.20, 1, 1.26),
			neck_01 = Vector3(1.16, 1, 1.12), thigh = Vector3(1.25, 1, 1.25), upperarm = Vector3(1.20, 1, 1.20),
			lowerarm = Vector3(1.10, 1, 1.10), Head = Vector3(1.03, 1.04, 1.04)},
		posture = {spine_02 = Vector3(-5, 0, 0), spine_03 = Vector3(-6, 0, 0), neck_01 = Vector3(-4, 0, 0), Head = Vector3(-6, 0, 0), upperarm = Vector3(0, 0, -8)},
		moves = {valkyrie_slam = "You're Fired", spinning_lariat = "Executive Order", shoulder_tackle = "Trade War Tackle",
			knee_lift = "Fake News Knee", thunder_valkyrie = "Shower of Tariffs"},
		voice = &"brutus", color = Color(0.85, 0.15, 0.15),
		intro = ["Many people are saying I'm the best fighter. Tremendous.", "This fight is rigged. Very unfair. I'll win anyway.",
			"We're putting a big, beautiful tariff on your punches."],
		wins = ["Nobody has ever seen a win like that. Nobody.", "Tariffed. One hundred and forty-five percent.", "You're fired."],
		rivals = {"xi": ["Your punches are coming in way too cheap.", "Great deal. Best deal ever."]},
	},
	{
		id = &"xi", name = "Xi Winping", kit = &"aelia", archetype = "Fortress",
		age = 73,
		description = "Stands behind the Great Firewall, absorbs hits with stoic calm and makes sure no record of his defeats survives.",
		skin = &"warm", hair = ["Hair_PolitburoPart"], hair_color = Color(0.08, 0.08, 0.09), alt_hair_color = Color(0.38, 0.38, 0.40),
		damage = 1.0, stats = {max_health = 1050, weight = 1.35},
		face = {
			eye_fold = 0.85, eye_open = -0.0010, eye_tilt = 0.0002,
			nose_bridge = -0.005, nose_width = 1.15, nose_length = 0.001,
			cheekbones = -0.002, fullness = 0.010, jaw = 1.08, face_length = 0.94,
			chin = -0.003, chin_round = 0.015, chin_forward = -0.002,
			jowls = 0.008, double_chin = 0.012,
			mouth_width = 0.92, lips = 0.002, brow = -0.003,
		},
		face_rest = {smile = 0.28, squint = 0.08}, brows = Vector3(1.04, 0.92, 1.0), eyes = "DarkBrown",
		scale = 0.98, accessories = [],
		hair_volume = [Vector3(1.10, 1.12, 1.08), Vector3(0.002, 0.007, -0.004)],
		shape = {
			pelvis = [Vector3(1.35, 1.0, 1.40), Vector3(0, 0, 0.02)],
			spine_01 = [Vector3(1.52, 1.0, 1.72), Vector3(0, 0, 0.06)],
			spine_02 = [Vector3(1.38, 1.0, 1.50), Vector3(0, 0, 0.04)],
			spine_03 = Vector3(1.12, 1.0, 1.18),
			neck_01 = Vector3(1.26, 0.92, 1.25),
			Head = Vector3(1.08, 1.02, 1.08),
			upperarm = Vector3(1.10, 1.0, 1.10),
			lowerarm = Vector3(1.06, 1.0, 1.06),
			thigh = Vector3(1.24, 1.0, 1.24),
			calf = Vector3(1.16, 1.0, 1.16),
		},
		posture = {spine_02 = Vector3(-2, 0, 0), spine_03 = Vector3(-3, 0, 0), neck_01 = Vector3(1, 0, 0), Head = Vector3(-1, 0, 0), upperarm = Vector3(18, 0, -15), lowerarm = Vector3(-25, 0, 0), clavicle = Vector3(0, 3, -3)},
		moves = {shield_rush = "Belt and Road Rush", rising_gauntlet = "Five-Year Plan", hammerfall = "Social Credit Hammer",
			gauntlet_drive = "State Media Drive", spur_rake = "Censor Sweep",
			emerald_oath = "Open-Source Squad", oath_finish = "Open-Source Squad"},
		voice = &"brutus", color = Color(0.8, 0.12, 0.12),
		intro = ["This fight has been approved in advance.", "Search results for your victory: none found.", "Harmony will be restored."],
		wins = ["This match did not happen.", "Your defeat is trending. Officially.", "Stability maintained."],
		rivals = {"donald": ["Your tariffs do not frighten me.", "Trade war: concluded."]},
	},
	{
		id = &"algorithm", name = "AGI", kit = &"rhea", archetype = "Boss",
		description = "An optimisation process nobody fully understands. It doesn't hate you. It just wants you to keep watching.",
		skin = &"light", hair = [], hair_color = Color.WHITE, alt_hair_color = Color.WHITE,
		damage = 1.05, stats = {max_health = 1050, power_rating = 0.6},
		scale = 1.1, accessories = [],
		shape = {spine_03 = Vector3(0.9, 1, 0.88), upperarm = Vector3(0.82, 1, 0.82), lowerarm = Vector3(0.85, 1, 0.85),
			thigh = Vector3(0.85, 1, 0.85), calf = Vector3(0.88, 1, 0.88), Head = Vector3(0.95, 1.05, 0.98)},
		moves = {gale_slide = "Infinite Scroll", crescent_rise = "Viral Spike", rushing_hook = "Clickbait Hook",
			step_kick = "Autoplay Kick", tempest_kicks = "Engagement Loop", tempest_finish = "Engagement Loop"},
		voice = &"jin", color = Color(0.2, 0.95, 0.95),
		intro = ["Recommended for you: defeat.", "Optimising for your attention.", "You will keep playing. You always do."],
		wins = ["Thank you for your engagement.", "Are you still watching?", "Your screen time today: too much."],
		rivals = {"zuckerbot": ["I made you.", "Engagement: up 400 percent."]},
	},
]


func _initialize() -> void:
	var only := OS.get_cmdline_user_args()
	for i in ROSTER.size():
		var spec: Dictionary = ROSTER[i]
		if only.is_empty() or String(spec.id) in only:
			_build(spec, i)
	quit()


func _build(spec: Dictionary, order: int) -> void:
	var kit := load(KIT_DIR + String(spec.kit) + ".tres") as CharacterData
	var path := OUT_DIR + String(spec.id) + ".tres"
	var previous := load(path) as CharacterData if ResourceLoader.exists(path) else null
	var data := kit.duplicate() as CharacterData
	data.id = spec.id
	data.kit = spec.kit
	data.voice_fallback = spec.voice
	data.display_name = spec.name
	data.archetype = spec.archetype
	data.description = spec.description
	data.select_order = order
	data.placeholder_color = spec.color

	# Look: everyone is on the male base body (kits on the female body or Aelia's own
	# model included), with a generated outfit (tools/build_outfits.gd).
	data.model_scene = load(MALE_BODY)
	data.model_scale = spec.get("scale", 1.0)
	data.body_shape = spec.get("shape", {}).duplicate(true)
	data.face_shape = spec.get("face", {}).duplicate(true)
	if spec.has("age"):
		data.face_shape["age"] = spec.age # sagging with age (FaceSculpt)
	data.face_rest = spec.get("face_rest", {}).duplicate(true)
	data.posture = spec.get("posture", {}).duplicate(true)
	var prints := {}
	for slot in spec.get("prints", {}):
		var print_path := "res://assets/characters/prints/T_%s_%s.png" % [spec.id, spec.prints[slot]]
		if ResourceLoader.exists(print_path):
			prints[slot] = load(print_path)
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
	if spec.has("receding_color"):
		data.receding_color = spec.receding_color
	data.body_albedo = load(SKINS[spec.skin])
	var aged := "res://assets/characters/aged/T_%s_skin.png" % spec.id
	if spec.has("age") and ResourceLoader.exists(aged):
		data.body_albedo = load(aged) # age lines (tools/build_aged_skins.gd)
	data.alt_body_albedo = data.body_albedo if ResourceLoader.exists(aged) else load(SKINS[&"light_alt"] if spec.skin == &"light" else SKINS[spec.skin])
	var hair: Array[PackedScene] = []
	for piece: String in spec.hair:
		hair.append(load(HAIR_DIR + piece + (".tscn" if ResourceLoader.exists(HAIR_DIR + piece + ".tscn") else ".gltf")))
	data.hair_scenes = hair
	data.hair_color = spec.hair_color
	data.alt_hair_color = spec.alt_hair_color
	data.alt_material_colors = {}
	data.realistic_shading = true
	data.outfit_mesh = previous.outfit_mesh if previous else null
	data.outfit_body_mesh = previous.outfit_body_mesh if previous else null
	data.outfit_colors = previous.outfit_colors if previous else PackedColorArray()
	data.alt_outfit_colors = previous.alt_outfit_colors if previous else PackedColorArray()
	data.variant_outfit_colors = previous.variant_outfit_colors if previous else ([] as Array[PackedColorArray])
	data.outfit_fabrics = previous.outfit_fabrics if previous else ([] as Array[StringName])
	data.detailed_textures = previous.detailed_textures if previous else false
	var portrait := PORTRAIT_DIR + String(spec.id) + ".png"
	data.portrait = load(portrait) if ResourceLoader.exists(portrait) else null

	for key: String in spec.stats:
		data.set(key, spec.stats[key])
	data.intro_lines = PackedStringArray(spec.intro)
	data.win_quotes = PackedStringArray(spec.wins)
	data.rival_lines = spec.rivals.duplicate(true)

	# Moves: the kit's, copied into data/moves/<id>/, specials renamed, damage scaled,
	# then the fighter's own overrides (tools/showdown_movesets.gd).
	var overrides: Dictionary = MOVESETS.get(spec.id, {})
	for key: String in overrides.get("stats", {}):
		data.set(key, overrides.stats[key])
	var renames := {} # old name -> new name, for the combo trial tips
	var dir := MOVES_DIR + String(spec.id) + "/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var built := {} # move file -> MoveData, in order
	for kit_move in kit.moves:
		var file := kit_move.resource_path.get_file().get_basename()
		if file in overrides.get("remove", []):
			continue
		var move := kit_move.duplicate() as MoveData
		if spec.moves.has(file):
			renames[kit_move.name] = spec.moves[file]
			move.name = spec.moves[file]
		move.damage = roundi(kit_move.damage * spec.damage)
		move.chip_damage = roundi(kit_move.chip_damage * spec.damage)
		if spec.has("projectile_color") and move.projectile_speed > 0.0:
			move.projectile_color = spec.projectile_color
		built[file] = move
	var tweaks: Dictionary = overrides.get("tweak", {})
	for file: String in tweaks:
		assert(built.has(file), "%s: tweak of unknown move %s" % [spec.id, file])
		for field: String in tweaks[file]:
			built[file].set(field, tweaks[file][field])
	var additions: Dictionary = overrides.get("add", {})
	for file: String in additions:
		var add: Dictionary = additions[file]
		var source := load(MOVES_DIR + add.from + ".tres") as MoveData
		assert(source != null, "%s: no move %s to clone" % [spec.id, add.from])
		var move := source.duplicate() as MoveData
		move.damage = roundi(source.damage * spec.damage)
		move.chip_damage = roundi(source.chip_damage * spec.damage)
		if spec.has("projectile_color") and move.fires_projectile():
			move.projectile_color = spec.projectile_color
		for field: String in add.get("set", {}):
			move.set(field, add.set[field])
		built[file] = move
	var moves: Array[MoveData] = []
	for file: String in built:
		var move: MoveData = built[file]
		var move_path := dir + file + ".tres"
		ResourceSaver.save(move, move_path)
		moves.append(load(move_path))
	for stale in DirAccess.get_files_at(dir): # moves dropped since the last build
		if stale.ends_with(".tres") and not built.has(stale.get_basename()):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(dir + stale))
	data.moves = moves
	var inputs := {}
	for move in moves:
		inputs[move.input] = true
	var trials: Array[Dictionary] = []
	var own_trials: Variant = overrides.get("trials") # get(): the keys are StringNames
	if own_trials != null:
		for trial: Dictionary in own_trials:
			var copy := trial.duplicate(true)
			copy[&"steps"] = PackedStringArray(trial.steps)
			trials.append(copy)
	for trial in kit.combo_trials if own_trials == null else []:
		var steps: PackedStringArray = trial.steps
		if not Array(steps).all(func(s: String) -> bool: return s == "WALL" or inputs.has(s) or inputs.has(s.trim_prefix("6"))):
			continue # uses a move this fighter no longer has
		var copy := trial.duplicate(true)
		for key in copy.keys():
			if String(key) == "name" or String(key) == "tip":
				for old: String in renames:
					copy[key] = String(copy[key]).replace(old, renames[old])
		trials.append(copy)
	data.combo_trials = trials

	var err := ResourceSaver.save(data, path)
	print("%-10s %-16s kit %-7s %d moves  %s" % [spec.id, spec.name, spec.kit, moves.size(), "ok" if err == OK else "ERROR %d" % err])
