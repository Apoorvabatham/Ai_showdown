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
		skin = &"light", hair = ["Hair_Buzzed"], hair_color = Color(0.3, 0.21, 0.13), alt_hair_color = Color(0.1, 0.08, 0.07),
		damage = 1.0, stats = {},
		face = {jaw = 0.93, chin = -0.003, fullness = -0.003, nose_width = 0.93, eye_open = 0.0012, mouth_width = 0.95},
		face_rest = {brow_up = 0.55, smile = 0.2}, brows = Vector3(0.95, 0.75, 1.0), eyes = "Blue",
		scale = 0.95, accessories = [&"tousled"],
		shape = {spine_03 = Vector3(0.9, 1, 0.92), upperarm = Vector3(0.84, 1, 0.84), lowerarm = Vector3(0.88, 1, 0.88),
			thigh = Vector3(0.9, 1, 0.9), calf = Vector3(0.92, 1, 0.92)},
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
		skin = &"light", hair = ["Hair_SimpleParted"], hair_color = Color(0.27, 0.18, 0.11), alt_hair_color = Color(0.36, 0.27, 0.16),
		damage = 0.95, stats = {walk_speed = 2.7, dash_speed = 7.8},
		face = {jaw = 1.16, chin = 0.009, chin_forward = 0.006, face_length = 1.08, fullness = 0.009, cheekbones = 0.002, eye_open = -0.0018, brow = 0.002, nose_length = 0.002, nose_width = 1.04, mouth_width = 1.08, lips = -0.001},
		face_rest = {smile = 0.5, squint = 0.25, brow_up = 0.1}, brows = Vector3(1.0, 0.85, 1.0), eyes = "Green",
		scale = 1.09, accessories = [], hair_volume = [Vector3(1.1, 1.28, 1.12), Vector3(0, 0.012, -0.014)], prints = {0: "tee"},
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
		skin = &"light", hair = ["Hair_Buzzed"], hair_color = Color(0.14, 0.1, 0.08), alt_hair_color = Color(0.32, 0.22, 0.13),
		damage = 1.0, stats = {},
		face = {fullness = 0.002, nose_width = 1.06, chin = -0.002, eye_open = 0.0005, lips = 0.001},
		face_rest = {brow_up = 0.55}, eyes = "DarkBrown",
		scale = 0.98, accessories = [&"curls"],
		shape = {spine_03 = Vector3(0.9, 1, 0.9), upperarm = Vector3(0.85, 1, 0.85), lowerarm = Vector3(0.88, 1, 0.88),
			thigh = Vector3(0.9, 1, 0.9)},
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
		skin = &"pale", hair = ["Hair_Buzzed"], hair_color = Color(0.28, 0.19, 0.12), alt_hair_color = Color(0.12, 0.09, 0.07),
		damage = 1.0, stats = {},
		face = {jaw = 0.9, chin = -0.002, chin_forward = 0.003, face_length = 0.97, fullness = -0.002, cheekbones = 0.0015, eye_open = 0.0024, nose_width = 0.94, mouth_width = 0.88, lips = -0.001, brow = -0.0015},
		face_rest = {brow_up = 0.35, smile = 0.12}, brows = Vector3(1.0, 0.8, 1.0), eyes = "Blue",
		scale = 0.92, accessories = [&"curls"],
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
		skin = &"warm", hair = ["Hair_SimpleParted"], hair_color = Color(0.72, 0.72, 0.74), alt_hair_color = Color(0.18, 0.18, 0.2),
		damage = 1.05, stats = {},
		face = {eye_fold = 1.0, nose_bridge = -0.005, nose_width = 1.12, cheekbones = 0.004, fullness = 0.002, brow = -0.003, jaw = 1.02, eye_tilt = 0.0012, eye_open = -0.001, chin_round = 0.002, mouth_width = 1.02},
		face_rest = {smile = 0.45, squint = 0.15}, brows = Vector3(1.0, 0.72, 1.0), eyes = "DarkBrown",
		scale = 0.97, accessories = [&"glasses"], hair_volume = [Vector3(1.1, 1.22, 1.12), Vector3(0, 0.008, -0.008)], prints = {1: "tee"},
		shape = {spine_03 = Vector3(0.96, 1, 0.96), upperarm = Vector3(0.94, 1, 0.94), lowerarm = Vector3(0.95, 1, 0.95), spine_01 = Vector3(1.02, 1, 1.04)},
		posture = {spine_02 = Vector3(-3, 0, 0), spine_03 = Vector3(-4, 0, 0), neck_01 = Vector3(-3, 0, 0), Head = Vector3(-3, 0, 0), clavicle = Vector3(0, 3, 0)},
		moves = {ki_blast = "Tensor Blast", rising_dragon = "Leather Uppercut", snap_kick = "Keynote Kick",
			advancing_straight = "The More You Buy", dragon_barrage = "GPU Rain", dragon_finish = "GPU Rain"},
		projectile_color = Color(0.46, 0.8, 0.0),
		voice = &"kenji", color = Color(0.46, 0.73, 0.0),
		intro = ["The more you buy, the more you save.", "Let me show you our next-generation fist.", "Every fight is a data-center-scale fight."],
		wins = ["Thirty times faster than last year's beatdown.", "The leather jacket remains undefeated.",
			"Thank you, thank you. Now, about pricing..."],
		rivals = {"sundar": ["Your data centres run on my chips.", "Please, order more."],
			"algorithm": ["Who do you think trains you?", "Running on my hardware, losing on my hardware."]},
	},
	{
		id = &"demis", name = "Demis Hasabist", kit = &"jin", archetype = "Kicker",
		age = 50,
		description = "Former chess prodigy and game designer. Reads every fight forty moves ahead, then folds you like a protein.",
		skin = &"light", hair = ["Hair_Buzzed"], hair_color = Color(0.1, 0.08, 0.07), alt_hair_color = Color(0.3, 0.22, 0.14),
		damage = 1.0, stats = {},
		face = {jaw = 0.92, chin = -0.002, fullness = -0.003, nose_length = 0.002, eye_open = 0.0008},
		face_rest = {brow_down = 0.2, smile = 0.1}, brows = Vector3(1.0, 0.85, 1.0), eyes = "DarkBrown",
		scale = 0.92, accessories = [],
		shape = {spine_03 = Vector3(0.9, 1, 0.9), upperarm = Vector3(0.86, 1, 0.86), lowerarm = Vector3(0.9, 1, 0.9),
			Head = Vector3(1.03, 1.02, 1.02)},
		moves = {spinning_back_kick = "Move 37", tornado_kick = "Self-Play Tornado", axe_kick = "Checkmate Axe",
			push_kick = "Gambit Push", hurricane_kicks = "Protein Fold", hurricane_finish = "Protein Fold"},
		voice = &"jin", color = Color(0.3, 0.55, 0.95),
		intro = ["I've already simulated this fight. You lose.", "First, solve fighting. Then use it to solve everything else.",
			"A nice game. Shall we?"],
		wins = ["Folded in under a second.", "Fascinating. You played like a random policy.", "Good game. I've seen it a million times."],
		rivals = {"yann": ["Tell me again it's just autocomplete.", "Go was harder."]},
	},
	{
		id = &"yann", name = "Yann LeCant", kit = &"brutus", archetype = "Power",
		age = 65,
		description = "A heavyweight sceptic who insists none of this is real intelligence, then flattens you to prove the point. Posts the rebuttal mid-combo.",
		skin = &"light", hair = ["Hair_SimpleParted"], hair_color = Color(0.32, 0.31, 0.3), alt_hair_color = Color(0.12, 0.1, 0.09),
		damage = 1.0, stats = {},
		face = {fullness = 0.005, jaw = 1.08, nose_width = 1.12, brow = 0.002, eye_open = -0.0005, chin = 0.001},
		face_rest = {brow_down = 0.45, grimace = 0.15}, eyes = "Grey",
		scale = 1.0, accessories = [&"glasses"],
		shape = {spine_01 = [Vector3(1.18, 1, 1.25), Vector3(0, 0, 0.015)], spine_02 = Vector3(1.1, 1, 1.15), pelvis = Vector3(1.08, 1, 1.1),
			neck_01 = Vector3(1.1, 1, 1.1), Head = Vector3(1.04, 1.02, 1.03)},
		moves = {bull_charge = "Open-Source Charge", earthquake = "World Model Quake", overhead_smash = "Cat-Level Smash",
			heavy_boot = "Convolution Boot", titan_rush = "It's Just Autocomplete", titan_finish = "It's Just Autocomplete"},
		voice = &"brutus", color = Color(0.6, 0.3, 0.85),
		intro = ["Your fist has a weaker world model than a house cat.", "Doom? Please. My Roomba is more dangerous.",
			"Let me explain why you are wrong. Physically."],
		wins = ["Not intelligent. Just effective.", "See? No existential risk. Only you, on the floor.",
			"I will post a long thread on why that worked."],
		rivals = {"geoff": ["Geoff, my old friend. You worry too much.", "Turing Award, round two: mine."],
			"demis": ["Your agent still can't load a dishwasher.", "Self-supervised that."]},
	},
	{
		id = &"geoff", name = "Geoff Hintoff", kit = &"aelia", archetype = "Armoured Elder",
		age = 78,
		description = "The godfather of the neural net, now touring the world to warn you about it. His heavy moves shrug off a hit; his super comes with second thoughts.",
		skin = &"pale", hair = ["Hair_SimpleParted"], hair_color = Color(0.86, 0.86, 0.84), alt_hair_color = Color(0.6, 0.6, 0.6),
		damage = 0.95, stats = {},
		face = {face_length = 1.08, fullness = -0.005, jaw = 0.92, chin = 0.006, nose_length = 0.004, nose_bridge = 0.002, brow = 0.003, eye_open = -0.0012, cheekbones = -0.001},
		face_rest = {brow_up = 0.75, grimace = 0.2}, brows = Vector3(1.05, 1.1, 1.0), eyes = "Grey",
		scale = 1.05, accessories = [],
		shape = {spine_03 = Vector3(0.88, 1, 0.9), upperarm = Vector3(0.8, 1, 0.8), lowerarm = Vector3(0.85, 1, 0.85),
			thigh = Vector3(0.88, 1, 0.88), calf = Vector3(0.9, 1, 0.9), neck_01 = Vector3(0.9, 1, 0.9)},
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
		damage = 0.9, stats = {max_health = 1100, walk_speed = 1.8, back_walk_speed = 1.5, weight = 1.1, power_rating = 0.4, speed_rating = 0.45},
		face = {face_length = 1.06, jaw = 0.90, chin = 0.003, chin_forward = 0.002, nose_width = 0.95, nose_length = 0.005, nose_bridge = 0.003, fullness = -0.005, cheekbones = 0.003, eye_open = -0.0006, eye_tilt = 0.0004},
		face_rest = {smile = 0.45}, brows = Vector3(0.96, 0.78, 1.0), eyes = "DarkBrown",
		scale = 1.02, accessories = [&"glasses"], accessory_color = Color(0.08, 0.08, 0.1), prints = {0: "tee"},
		hair_volume = [Vector3(1.01, 1.05, 1.02), Vector3(0, 0.003, 0.0)],
		shape = {spine_03 = Vector3(0.88, 1, 0.88), upperarm = Vector3(0.84, 1, 0.84), lowerarm = Vector3(0.88, 1, 0.88),
			thigh = Vector3(0.88, 1, 0.88), calf = Vector3(0.9, 1, 0.9), neck_01 = Vector3(0.92, 1.05, 0.92)},
		posture = {spine_02 = Vector3(1, 0, 0), spine_03 = Vector3(1, 0, 0), neck_01 = Vector3(2, 0, 0), Head = Vector3(-2, 0, 0)},
		moves = {ki_blast = "Ten Blue Links", rising_dragon = "Featured Snippet", snap_kick = "Quarterly Kick",
			advancing_straight = "Sponsored Result", dragon_barrage = "Search Result", dragon_finish = "Search Result"},
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
		skin = &"tan", hair = ["Hair_SimpleParted"], hair_color = Color(0.88, 0.7, 0.38), alt_hair_color = Color(0.85, 0.85, 0.82),
		damage = 1.1, stats = {max_health = 1150, walk_speed = 1.6, back_walk_speed = 1.2, dash_speed = 4.6, weight = 1.3,
			throw_damage = 170, jump_velocity = 5.5, power_rating = 0.9, speed_rating = 0.3},
		face = {fullness = 0.022, jaw = 0.95, chin_round = 0.013, jowls = 0.01, double_chin = 0.008, cheekbones = -0.002, eye_open = -0.0025, mouth_width = 0.84, pout = 0.004, lips = 0.002, nose_width = 1.08, brow = 0.001},
		face_rest = {squint = 0.55, brow_down = 0.35, grimace = 0.25}, brows = Vector3(1.0, 0.7, 1.0), eyes = "Blue",
		scale = 1.07, accessories = [], hair_volume = [Vector3(1.18, 1.45, 1.22), Vector3(0, 0.012, 0.008)],
		shape = {pelvis = [Vector3(1.32, 1, 1.45), Vector3(0, 0, 0.02)], spine_01 = [Vector3(1.55, 1, 1.85), Vector3(0, 0, 0.06)],
			spine_02 = [Vector3(1.4, 1, 1.6), Vector3(0, 0, 0.04)], spine_03 = Vector3(1.15, 1, 1.2),
			neck_01 = Vector3(1.28, 1, 1.25), thigh = Vector3(1.16, 1, 1.16), upperarm = Vector3(1.12, 1, 1.12),
			lowerarm = Vector3(1.05, 1, 1.05), Head = Vector3(1.05, 1.08, 1.08)},
		posture = {spine_02 = Vector3(-5, 0, 0), spine_03 = Vector3(-6, 0, 0), neck_01 = Vector3(-4, 0, 0), Head = Vector3(-6, 0, 0), upperarm = Vector3(0, 0, -8)},
		moves = {valkyrie_slam = "The Art of the Deal", spinning_lariat = "Executive Order", shoulder_tackle = "Trade War Tackle",
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
		skin = &"warm", hair = ["Hair_SimpleParted"], hair_color = Color(0.08, 0.08, 0.09), alt_hair_color = Color(0.38, 0.38, 0.40),
		damage = 1.0, stats = {max_health = 1100, weight = 1.35},
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
		hair_volume = [Vector3(1.14, 1.15, 1.12), Vector3(0.002, 0.009, -0.005)],
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
			emerald_oath = "Great Firewall", oath_finish = "Great Firewall"},
		voice = &"brutus", color = Color(0.8, 0.12, 0.12),
		intro = ["This fight has been approved in advance.", "Search results for your victory: none found.", "Harmony will be restored."],
		wins = ["This match did not happen.", "Your defeat is trending. Officially.", "Stability maintained."],
		rivals = {"donald": ["Your tariffs do not frighten me.", "Trade war: concluded."]},
	},
	{
		id = &"algorithm", name = "The Algorithm", kit = &"rhea", archetype = "Boss",
		description = "An optimisation process nobody fully understands. It doesn't hate you. It just wants you to keep watching.",
		skin = &"light", hair = [], hair_color = Color.WHITE, alt_hair_color = Color.WHITE,
		damage = 1.1, stats = {max_health = 1050, power_rating = 0.6},
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
	data.outfit_fabrics = previous.outfit_fabrics if previous else ([] as Array[StringName])
	data.detailed_textures = previous.detailed_textures if previous else false
	var portrait := PORTRAIT_DIR + String(spec.id) + ".png"
	data.portrait = load(portrait) if ResourceLoader.exists(portrait) else null

	for key: String in spec.stats:
		data.set(key, spec.stats[key])
	data.intro_lines = PackedStringArray(spec.intro)
	data.win_quotes = PackedStringArray(spec.wins)
	data.rival_lines = spec.rivals.duplicate(true)

	# Moves: the kit's, copied into data/moves/<id>/, specials renamed, damage scaled.
	var renames := {} # old name -> new name, for the combo trial tips
	var dir := MOVES_DIR + String(spec.id) + "/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var moves: Array[MoveData] = []
	for kit_move in kit.moves:
		var file := kit_move.resource_path.get_file().get_basename()
		var move := kit_move.duplicate() as MoveData
		if spec.moves.has(file):
			renames[kit_move.name] = spec.moves[file]
			move.name = spec.moves[file]
		move.damage = roundi(kit_move.damage * spec.damage)
		move.chip_damage = roundi(kit_move.chip_damage * spec.damage)
		if spec.has("projectile_color") and move.projectile_speed > 0.0:
			move.projectile_color = spec.projectile_color
		var move_path := dir + file + ".tres"
		ResourceSaver.save(move, move_path)
		moves.append(load(move_path))
	data.moves = moves
	var trials: Array[Dictionary] = []
	for trial in kit.combo_trials:
		var copy := trial.duplicate(true)
		for key in copy.keys():
			if String(key) == "name" or String(key) == "tip":
				for old: String in renames:
					copy[key] = String(copy[key]).replace(old, renames[old])
		trials.append(copy)
	data.combo_trials = trials

	var err := ResourceSaver.save(data, path)
	print("%-10s %-16s kit %-7s %d moves  %s" % [spec.id, spec.name, spec.kit, moves.size(), "ok" if err == OK else "ERROR %d" % err])
