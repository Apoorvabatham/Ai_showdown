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
##   trials: Array of combo trials replacing the kit's (as in data/kits/*.tres; `steps` a
##           plain Array of inputs).
##           Without it, the kit's trials are kept minus any that use a removed input.
##
## A fighter with an entry here should also get its own CPU personality
## (AIController.PERSONALITIES) and showcase routine (FighterShowcase.ROUTINES), keyed by
## its id: CharacterData.lookup() prefers the fighter's entry over the kit's.

const MOVESETS := {
	# Sundar Pickai: zoner / trapper (was a copy of Jensen's kit).
	&"sundar": {
		stats = {max_health = 1020, archetype = "Zoner"},
		remove = ["dragon_barrage", "dragon_finish"],
		tweak = {
			# A fan of three small links: the low one catches crouchers.
			ki_blast = {projectile_count = 3, projectile_spread = 0.35, damage = 17, chip_damage = 2,
				projectile_speed = 6.0, hitbox_radius = 0.18, recovery = 34},
		},
		add = {
			# A slow ad that hangs in the air and controls space.
			sponsored_result = {from = "kenji/ki_blast", set = {name = "Sponsored Result", input = "214P",
				projectile_speed = 1.6, projectile_lifetime = 150, damage = 55, chip_damage = 6, hitbox_radius = 0.34,
				startup = 16, recovery = 26, hitstun = 24, projectile_color = Color(0.98, 0.78, 0.15)}},
			# Vanishes and reappears behind the opponent; punishable if they guess it.
			algorithm_update = {from = "kenji/ki_blast", set = {name = "Algorithm Update", input = "214K",
				animation = &"fight/focus_stance", animation_impact = 0.2, animation_end = 0.0,
				projectile_speed = 0.0, hitbox_radius = 0.0, damage = 0, chip_damage = 0, teleport = 1.0,
				startup = 14, active = 1, recovery = 22, invuln_frames = 15, camera_intensity = 0.0}},
			# Super: a giant search bar slams down on the opponent (overhead: block standing).
			search_result = {from = "kenji/ki_blast", set = {name = "Search Result", input = "236236P", super_move = true,
				animation = &"fight/ground_pound", animation_impact = 0.33, animation_end = 0.85,
				projectile_origin = &"sky", projectile_speed = 20.0, projectile_lifetime = 60, hitbox_radius = 0.65,
				damage = 290, chip_damage = 45, hit_level = 3, hitstun = 0, blockstun = 24, hitstop = 14,
				knockback = Vector2(1.5, 0.0), knockdown = true, startup = 5, active = 1, recovery = 40,
				invuln_frames = 8, camera_intensity = 0.6, super_fx = &"search_result"}},
		},
		trials = [
			{name = "Jab String", steps = ["LP", "LP", "HP"], corner = false,
				tip = "Jabs chain into each other and into the straight."},
			{name = "Quarterly Push", steps = ["6LK", "6HP"], corner = false,
				tip = "Hold forward: the Quarterly Kick chains into the Pixel Push."},
			{name = "Ten Blue Links", steps = ["LP", "HP", "236P"], corner = false,
				tip = "Cancel the straight into Ten Blue Links as it hits."},
			{name = "I'm Feeling Lucky", steps = ["2LP", "2LP", "623P"], corner = false,
				tip = "Low jabs, then cancel into the rising uppercut."},
			{name = "Corner Splat", steps = ["HK", "WALL", "6LK", "6HP"], corner = true,
				tip = "A roundhouse near the edge splats them: walk in and follow up."},
			{name = "Search Result", steps = ["LP", "HP", "236236P"], corner = false,
				tip = "With a full meter, cancel the straight into the super: block it standing!"},
		],
	},
	# Donald Tarrif: armoured powerhouse (was a copy of Valka's grappler kit).
	&"donald": {
		stats = {archetype = "Armoured Powerhouse"},
		tweak = {
			# Executive Order: the lariat soaks up a hit while it spins up.
			spinning_lariat = {armor_hits = 1, damage = 42},
			# Trade War Tackle: an armoured charge.
			shoulder_tackle = {armor_hits = 1, damage = 88},
			# You're Fired: slower, much bigger command grab.
			valkyrie_slam = {startup = 14, damage = 170, recovery = 40},
			# Shower of Tariffs: the kit's super; its cinematic comes later.
			thunder_valkyrie = {super_fx = &"tariff_stamp"},
		},
		add = {
			# Two shipping containers, one after the other, tumbling at the opponent.
			trade_war = {from = "kenji/ki_blast", set = {name = "Trade War", input = "236P",
				projectile_count = 2, projectile_interval = 10, projectile_speed = 5.0, projectile_lifetime = 110,
				projectile_look = &"container", projectile_color = Color(0.8, 0.3, 0.12),
				damage = 52, chip_damage = 7, hitbox_radius = 0.34, startup = 14, recovery = 30,
				hitstun = 20, blockstun = 15}},
			# A wall that stands for three seconds, eats shots and blocks the way.
			build_the_wall = {from = "kenji/ki_blast", set = {name = "Build the Wall", input = "214P",
				barrier = true, projectile_speed = 0.0, projectile_lifetime = 180, hitbox_radius = 0.15,
				projectile_color = Color(0.85, 0.7, 0.4), damage = 0, chip_damage = 0,
				startup = 16, recovery = 28}},
		},
		trials = [
			{name = "Jab String", steps = ["LP", "LP", "HP"], corner = false,
				tip = "Jabs chain into each other and into the straight."},
			{name = "Low Order", steps = ["2LP", "2LP", "623P"], corner = false,
				tip = "Low jabs, then cancel into the Executive Order."},
			{name = "Knee and Order", steps = ["6LK", "623P"], corner = false,
				tip = "Cancel the knee lift into the Executive Order while they're in the air."},
			{name = "Trade War", steps = ["LP", "HP", "236P"], corner = false,
				tip = "Cancel the straight into two shipping containers."},
			{name = "Corner Splat", steps = ["HK", "WALL", "LK", "HP"], corner = true,
				tip = "A roundhouse near the edge splats them: walk in and follow up."},
			{name = "Tackle to the Wall", steps = ["6HP", "WALL", "LP", "623P"], corner = true,
				tip = "The armoured tackle splats them on the edge: jab, then cancel into the Executive Order."},
		],
	},
}
