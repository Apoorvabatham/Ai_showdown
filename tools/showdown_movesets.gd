extends RefCounted
## Per-fighter moveset overrides for the AI Showdown roster (docs/ROADMAP.md §1).
##
## tools/build_showdown_roster.gd copies each fighter's kit (data/kits/), renames the
## specials (ROSTER `moves`) and scales the damage (ROSTER `damage`). Then it applies the
## entry here, so a fighter can play differently from its kit. Owner: Claude (TASKS.md §2).
##
## Entry keys (all optional), applied in this order:
##   remove: Array of kit move files (e.g. "dragon_barrage") to drop. Drop a super's
##           follow-ups along with it.
##   tweak:  {move_file: {MoveData field: value}}: set fields on a kept move. Values are
##           final (no damage scaling).
##   add:    {new_file: {from = "<moves folder>/<file>", set = {field: value}}}: a new move
##           cloned from any move in data/moves/ (a kit's or a fighter's), then `set`
##           applied. `damage` / `chip_damage` are scaled by the ROSTER `damage` unless `set`
##           gives them. Give it a `name` and an `input`.
##   stats:  {CharacterData field: value}: applied after the ROSTER `stats`.
##
## A fighter with an entry here should also get its own CPU personality
## (AIController.PERSONALITIES) and showcase routine (FighterShowcase.ROUTINES), keyed by
## its id: CharacterData.lookup() prefers the fighter's entry over the kit's.

const MOVESETS := {
	# Xi Winping: fortress / control (was a copy of Geoff's armoured kit): no armour, long
	# wall-carrying rush, a low shockwave, a reflect stance and the paper dragon.
	&"xi": {
		stats = {archetype = "Fortress"},
		tweak = {
			shield_rush = {armor_hits = 0, travel = 6.5, knockback = Vector2(4.0, 0.0), damage = 80, startup = 14, recovery = 20, blockstun = 18},
			hammerfall = {armor_hits = 0, hit_level = 2, animation = &"fight/ground_pound", animation_impact = 0.33,
				animation_end = 0.85, impact_fx = &"shockwave", hitbox_offset = Vector3(0, 0.2, -1.1), hitbox_radius = 0.6,
				knockdown = true, damage = 90, recovery = 28},
			rising_gauntlet = {armor_hits = 0, invuln_frames = 3, damage = 80},
			gauntlet_drive = {armor_hits = 0},
			# Super finisher: the squad scene (scripts/supers/scenes/open_source_squad.gd, 5 s).
			oath_finish = {cinematic = &"open_source_squad", cinematic_ticks = 310, super_fx = &"open_source_squad"},
		},
		add = {
			# Censorship: a short stance that sends the opponent's shots back.
			censorship = {from = "lian/still_water", set = {name = "Censorship", input = "214K", reversal = false,
				reflect_projectiles = true, damage = 0, startup = 3, active = 18, recovery = 16, camera_intensity = 0.0}},
			# Power move: a paper festival dragon weaving along the floor (jump it or block low).
			paper_dragon = {from = "kenji/ki_blast", set = {name = "Paper Dragon Dance", input = "63214P",
				projectile_look = &"paper_dragon", projectile_height = 0.55, projectile_speed = 4.6, projectile_lifetime = 120,
				hitbox_radius = 0.5, damage = 70, chip_damage = 7, hit_level = 2, knockdown = true, hitstun = 0,
				startup = 16, recovery = 30, projectile_color = Color(0.92, 0.15, 0.1)}},
		},
	},
	# tesla man: the super's finisher plays the "Rocket Launch" scene when it hits.
	&"tesla": {
		tweak = {
			tempest_finish = {cinematic = &"rocket_launch", cinematic_ticks = 405, super_fx = &"rocket_launch"},
			jab = {animation = &"style/tesla_jab", animation_impact = 0.08, startup = 4, active = 2, recovery = 8},
			straight = {animation = &"style/tesla_cross", animation_impact = 0.14, startup = 8, active = 3, recovery = 12},
			step_kick = {animation = &"style/tesla_flying_knee", animation_impact = 0.18, startup = 10, active = 3, recovery = 15},
			roundhouse = {animation = &"style/tesla_spin_back_kick", animation_impact = 0.22, startup = 12, active = 4, recovery = 18},
		},
		add = {
			# Power move: three small rockets, one after another, from the hand.
			rocket_barrage = {from = "kenji/ki_blast", set = {name = "Rocket Barrage", input = "214K",
				projectile_count = 3, projectile_interval = 8, projectile_speed = 7.0, projectile_lifetime = 90,
				projectile_look = &"mini_rocket", projectile_color = Color(0.35, 0.09, 0.02),
				damage = 34, chip_damage = 4, hitbox_radius = 0.2, startup = 14, recovery = 30,
				hitstun = 18, blockstun = 13}},
		},
	},
	# Dario Amoday: patient counter-fighter, high reward on counters and palms.
	&"dario": {
		stats = {max_health = 1000},
		tweak = {
			inch_palm = {damage = 80, recovery = 20},
			double_palm = {damage = 88, recovery = 20},
			# Super finisher: Constitutional Scroll wraps opponent in legal text, sealed with SAFE stamp.
			thousand_finish = {cinematic = &"constitution_scroll", cinematic_ticks = 230, super_fx = &"constitution_scroll"},
		},
		add = {
			# Power move: a glowing rulebook shield that reflects projectile attacks and flies forward.
			rulebook_shield = {from = "kenji/ki_blast", set = {name = "Rulebook Shield", input = "236K",
				reflect_projectiles = true, projectile_look = &"rulebook", projectile_speed = 4.2, projectile_lifetime = 75,
				hitbox_radius = 0.38, damage = 65, chip_damage = 8,
				animation = &"fight/focus_stance", animation_impact = 0.2, animation_end = 0.65,
				startup = 14, active = 18, recovery = 22, projectile_color = Color(0.95, 0.85, 0.55),
				camera_intensity = 0.2}},
		},
	},
	# Yann LeCant: heavyweight sceptic, word token bursts and autocomplete finisher.
	&"yann": {
		tweak = {
			# Super finisher: Opponent trapped in giant text box, autocomplete types "you lose", heavy letters fall.
			titan_finish = {cinematic = &"autocomplete", cinematic_ticks = 270, super_fx = &"autocomplete"},
		},
		add = {
			# Power move: word tokens "the" / "next" / "token" fly toward the opponent.
			word_tokens = {from = "kenji/ki_blast", set = {name = "Word Tokens", input = "214K",
				projectile_look = &"word_token", projectile_count = 3, projectile_interval = 8,
				projectile_speed = 5.2, projectile_lifetime = 80,
				hitbox_radius = 0.32, damage = 25, chip_damage = 3,
				animation = &"fight/overhead_smash", animation_impact = 0.25, animation_end = 0.7,
				startup = 14, active = 18, recovery = 22, projectile_color = Color(0.35, 0.65, 0.95),
				camera_intensity = 0.2}},
		},
	},
	# Mark Zuckerbot: Like Bomb power move + Metaverse Trap (command grab) super scene.
	&"zuckerbot": {
		tweak = {thunder_valkyrie = {cinematic = &"metaverse_trap", cinematic_ticks = 390}},
		add = {
			# Power move: throws chunky blue thumbs-up "Like" bombs at the opponent.
			like_bomb = {from = "kenji/ki_blast", set = {name = "Like Bomb", input = "236P",
				projectile_look = &"like_bomb", projectile_count = 2, projectile_interval = 10,
				projectile_speed = 5.4, projectile_lifetime = 95,
				projectile_color = Color(0.2, 0.52, 1.0),
				hitbox_radius = 0.34, damage = 32, chip_damage = 4,
				startup = 14, recovery = 30, hitstun = 18, blockstun = 14,
				camera_intensity = 0.15}},
		},
	},
	# Jensen Wong: Tensor Blast (kit fireball) plus the GPU Rain power move.
	&"jensen": {
		# The super's finisher plays the "Leather Jacket Tornado" scene when it hits.
		tweak = {dragon_finish = {cinematic = &"jacket_tornado", cinematic_ticks = 320}},
		add = {
			# Power move: four graphics cards fall on and around the opponent.
			gpu_rain = {from = "kenji/ki_blast", set = {name = "GPU Rain", input = "214P",
				projectile_origin = &"sky", projectile_count = 4, projectile_interval = 6, projectile_spread = 0.68,
				projectile_speed = 13.5, projectile_lifetime = 60, projectile_look = &"gpu",
				hitbox_radius = 0.38, damage = 34, chip_damage = 4,
				animation = &"fight/ground_pound", animation_impact = 0.33, animation_end = 0.85,
				startup = 15, recovery = 36, hitstun = 20, blockstun = 15}},
		},
	},
	# Geoff Hintoff: Armoured Elder, hard-hitting, resilient specials.
	&"geoff": {
		tweak = {
			# Super finisher: 1986 Lecture Hall, chalkboard neural net zaps opponent, Geoff looks regretful.
			oath_finish = {cinematic = &"lecture_hall", cinematic_ticks = 270, super_fx = &"lecture_hall"},
		},
		add = {
			# Power move: two neural-net nodes zap forward with synaptic arcs.
			neural_zap = {from = "kenji/ki_blast", set = {name = "Neural Zap", input = "214K",
				projectile_count = 2, projectile_interval = 8, projectile_speed = 6.2, projectile_lifetime = 75,
				projectile_look = &"net_node", projectile_color = Color(0.95, 0.82, 0.35),
				hitbox_radius = 0.34, damage = 32, chip_damage = 4,
				animation = &"fight/focus_stance", animation_impact = 0.2, animation_end = 0.65,
				startup = 14, active = 18, recovery = 24,
				camera_intensity = 0.2}},
		},
	},
	# Sundar Pickai: zoner / trapper (was a copy of Jensen's kit).
	&"sundar": {
		stats = {max_health = 1030, archetype = "Zoner"},
		remove = ["dragon_barrage", "dragon_finish"],
		tweak = {
			jab = {animation = &"style/sundar_jab", animation_impact = 0.10, startup = 5, active = 2, recovery = 8},
			straight = {animation = &"style/sundar_cross", animation_impact = 0.14, startup = 8, active = 3, recovery = 14},
			# A fan of three small links: the low one catches crouchers.
			ki_blast = {animation = &"style/sundar_cast", animation_impact = 0.26, startup = 13, active = 1,
				projectile_count = 3, projectile_spread = 0.35, damage = 16, chip_damage = 3,
				projectile_speed = 6.6, hitbox_radius = 0.20, recovery = 27},
			sweep = {animation = &"style/sundar_sweep", animation_impact = 0.26, startup = 14, active = 4, recovery = 24},
		},
		add = {
			# A slow ad that hangs in the air and controls space.
			sponsored_result = {from = "kenji/ki_blast", set = {name = "Sponsored Result", input = "214P",
				projectile_speed = 1.8, projectile_lifetime = 150, damage = 45, chip_damage = 5, hitbox_radius = 0.35,
				startup = 15, recovery = 26, hitstun = 24, projectile_color = Color(0.98, 0.78, 0.15)}},
			# Vanishes and reappears behind the opponent; punishable if they guess it.
			algorithm_update = {from = "kenji/ki_blast", set = {name = "Algorithm Update", input = "214K",
				animation = &"fight/focus_stance", animation_impact = 0.2, animation_end = 0.0,
				projectile_speed = 0.0, hitbox_radius = 0.0, damage = 0, chip_damage = 0, teleport = 1.0,
				startup = 14, active = 1, recovery = 22, invuln_frames = 15, camera_intensity = 0.0}},
			# Power move: five search bars fly in at the opponent from every side.
			search_result = {from = "kenji/ki_blast", set = {name = "Search Result", input = "63214P",
				projectile_origin = &"around", projectile_count = 5, projectile_interval = 4, projectile_speed = 8.8,
				projectile_lifetime = 70, projectile_look = &"search_bar", hit_level = 1, hitbox_radius = 0.38,
				damage = 22, chip_damage = 3, startup = 17, recovery = 38, hitstun = 18, blockstun = 14,
				animation = &"fight/ground_pound", animation_impact = 0.33, animation_end = 0.85}},
			# Super: a giant search bar slams down on the opponent (overhead: block standing).
			not_found = {from = "kenji/ki_blast", set = {name = "404 Not Found", input = "236236P", super_move = true,
				animation = &"fight/ground_pound", animation_impact = 0.33, animation_end = 0.85,
				projectile_origin = &"sky", projectile_speed = 20.0, projectile_lifetime = 60, hitbox_radius = 0.65,
				damage = 265, chip_damage = 40, hit_level = 3, hitstun = 0, blockstun = 24, hitstop = 14,
				knockback = Vector2(1.5, 0.0), knockdown = true, startup = 5, active = 1, recovery = 40,
				invuln_frames = 8, camera_intensity = 0.6, super_fx = &"search_result",
				cinematic = &"not_found", cinematic_ticks = 320}},
		},
	},
	# Donald Tarrif: armoured powerhouse (was a copy of Valka's grappler kit).
	&"donald": {
		stats = {archetype = "Armoured Powerhouse"},
		tweak = {
			# Executive Order: the lariat soaks up a hit while it spins up.
			spinning_lariat = {armor_hits = 1, damage = 40},
			# Trade War Tackle: an armoured charge.
			shoulder_tackle = {armor_hits = 1, damage = 84, animation = &"style/donald_shove", animation_impact = 0.32, startup = 18, active = 4, recovery = 20},
			# Big wind-up haymaker.
			roundhouse = {animation = &"style/donald_haymaker", animation_impact = 0.58, startup = 16, active = 4, recovery = 20},
			# You're Fired: slower, much bigger command grab.
			valkyrie_slam = {startup = 14, damage = 160, recovery = 40},
			# Shower of Tariffs: the kit's super, a command grab; when it connects the
			# "Shower of Tariffs" scene plays (scripts/supers/scenes/tariff_stamp.gd, ~5.7 s).
			thunder_valkyrie = {super_fx = &"tariff_stamp", cinematic = &"tariff_stamp", cinematic_ticks = 360},
		},
		add = {
			# Two shipping containers, one after the other, tumbling at the opponent.
			trade_war = {from = "kenji/ki_blast", set = {name = "Trade War", input = "236P",
				projectile_count = 2, projectile_interval = 10, projectile_speed = 5.0, projectile_lifetime = 110,
				projectile_look = &"container", projectile_color = Color(0.8, 0.3, 0.12),
				damage = 48, chip_damage = 6, hitbox_radius = 0.34, startup = 14, recovery = 30,
				hitstun = 20, blockstun = 15}},
			# A wall that stands for three seconds, eats shots and blocks the way.
			build_the_wall = {from = "kenji/ki_blast", set = {name = "Build the Wall", input = "214P",
				barrier = true, projectile_speed = 0.0, projectile_lifetime = 180, hitbox_radius = 0.15,
				projectile_color = Color(0.85, 0.7, 0.4), damage = 0, chip_damage = 0,
				startup = 16, recovery = 28}},
		},
	},
	# Ram Altman: Hype Brawler, funding round money rain and exponential scaling law.
	&"ram": {
		tweak = {
			# Super finisher: exponential Scaling Law curve off the chart.
			hagupit_finish = {cinematic = &"scaling_law", cinematic_ticks = 270, super_fx = &"scaling_law"},
			hagupit_max = {cinematic = &"scaling_law", cinematic_ticks = 270, super_fx = &"scaling_law"},
		},
		add = {
			# Power move: money bags rain from the sky ("Funding Round").
			funding_round = {from = "kenji/ki_blast", set = {name = "Funding Round", input = "214K",
				projectile_origin = &"sky", projectile_count = 4, projectile_interval = 6, projectile_spread = 0.72,
				projectile_speed = 12.5, projectile_lifetime = 60, projectile_look = &"money_bag",
				hitbox_radius = 0.38, damage = 32, chip_damage = 4,
				animation = &"fight/focus_stance", animation_impact = 0.2, animation_end = 0.65,
				startup = 15, recovery = 35, hitstun = 20, blockstun = 15,
				projectile_color = Color(0.2, 0.85, 0.4), camera_intensity = 0.2}},
		},
	},
	# AGI (algorithm): the final boss, trained on everyone (ROADMAP §4).
	# Projectile (Kenji), command grab (Valka), reversal (Lian), armour (Aelia),
	# teleport (Sundar), super Engagement Loop (Rhea).
	&"algorithm": {
		stats = {max_health = 1050, archetype = "Boss"},
		remove = ["gale_slide", "crescent_rise"],
		tweak = {
			# Super finisher: sucked into giant phone, endless scroll, spat out.
			tempest_finish = {cinematic = &"infinite_scroll", cinematic_ticks = 270, super_fx = &"infinite_scroll"},
		},
		add = {
			# Power move: five feed cards spin around the opponent.
			feed_cards = {from = "kenji/ki_blast", set = {name = "For You Feed", input = "63214K",
				projectile_origin = &"around", projectile_count = 5, projectile_interval = 4, projectile_speed = 8.5,
				projectile_lifetime = 70, projectile_look = &"feed_card", hit_level = 1, hitbox_radius = 0.38,
				damage = 22, chip_damage = 3, startup = 16, recovery = 36, hitstun = 18, blockstun = 14,
				animation = &"fight/focus_stance", animation_impact = 0.2, animation_end = 0.65,
				projectile_color = Color(0.2, 0.95, 0.95), camera_intensity = 0.2}},
			# Projectile (from Kenji's Ki Blast): a high-speed electric stream of tokens.
			data_stream = {from = "kenji/ki_blast", set = {name = "Data Stream", input = "236P",
				damage = 65, chip_damage = 7, projectile_speed = 7.0, hitbox_radius = 0.28,
				projectile_color = Color(0.2, 0.95, 0.95), startup = 10, recovery = 25}},
			# Command Grab (from Valka's Valkyrie Slam): compresses the opponent's latent space.
			model_collapse = {from = "valka/valkyrie_slam", set = {name = "Model Collapse", input = "63214P",
				damage = 122, startup = 8, grab_range = 0.92, recovery = 36, camera_intensity = 0.4}},
			# Reversal (from Lian's Still Water): catches attacks and counters with safety alignment.
			safety_filter = {from = "lian/still_water", set = {name = "Safety Filter", input = "214P",
				reversal = true, damage = 110, startup = 3, active = 15, recovery = 22, camera_intensity = 0.4}},
			# Armour (from Aelia's Shield Rush): absorbs a hit and charges forward with brute-force compute.
			compute_rush = {from = "aelia/shield_rush", set = {name = "Compute Rush", input = "236K",
				armor_hits = 1, travel = 5.5, damage = 80, chip_damage = 9, startup = 10, recovery = 22,
				camera_intensity = 0.3}},
			# Teleport (from Sundar's Algorithm Update): dematerializes and shifts positions instantly.
			weights_update = {from = "kenji/ki_blast", set = {name = "Weights Update", input = "214K",
				animation = &"fight/focus_stance", animation_impact = 0.2, animation_end = 0.0,
				projectile_speed = 0.0, hitbox_radius = 0.0, damage = 0, chip_damage = 0, teleport = 1.0,
				startup = 14, active = 1, recovery = 22, invuln_frames = 15, camera_intensity = 0.0}},
		},
	},
}
