extends SceneTree
## Beginner bench: scripted "newbie" bots (button masher, simple pressure player) as P1
## against the CPU at each difficulty. Prints match win rate, round win rate and how often
## the CPU blocked / used its super.
## Run: godot-q.cmd --headless --path . -s res://tools/mash_bench.gd -- [matches per fighter] [bot: mash|simple]

class Newbie extends FighterController:
	var kind := "mash"
	var rng := RandomNumberGenerator.new()
	var _tick := 0
	var _dir := 5
	func read(f: Fighter) -> int:
		_tick += 1
		if kind == "mash":
			# Random direction held for a few frames, a random button every 6 ticks.
			if _tick % 8 == 1:
				_dir = [6, 6, 6, 5, 4, 2, 8][rng.randi() % 7]
			var b := 0
			if _tick % 6 == 0:
				b = [InputBuffer.LP, InputBuffer.HP, InputBuffer.LK, InputBuffer.HK][rng.randi() % 4]
			return InputBuffer.pack(_dir, b)
		# simple: walk up, poke with a jab / kick, repeat; never blocks.
		var d := Vector2(f.opponent.position.x - f.position.x, f.opponent.position.z - f.position.z).length()
		if d > 1.15:
			return InputBuffer.pack(6, 0)
		var b := 0
		if _tick % 12 == 0:
			b = InputBuffer.LP if (_tick / 12) % 2 == 0 else InputBuffer.LK
		return InputBuffer.pack(5, b)

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var matches := int(args[0]) if args.size() > 0 else 3
	var kind: String = args[1] if args.size() > 1 else "mash"
	await process_frame
	ReplayRecorder.enabled = false
	var gs = root.get_node("GameState")
	gs.mode = gs.Mode.VS_CPU
	gs.stage_path = gs.DEFAULT_STAGE
	var roster: Array = gs.roster
	for level in AIController.Difficulty.values():
		var mw := 0
		var total := 0
		var rw := 0
		var rt := 0
		for i in roster.size():
			gs.player_character = roster[i]
			gs.p2_character = roster[(i + 3) % roster.size()]
			change_scene_to_file("res://scenes/fight.tscn")
			await process_frame
			await process_frame
			var m = current_scene
			m.set_physics_process(false)
			var p1: Fighter = m.fighters[0]
			var p2: Fighter = m.fighters[1]
			for k in matches:
				var seed_base := hash("%d|%d|%d" % [level, i, k])
				var bot := Newbie.new()
				bot.kind = kind
				bot.rng.seed = seed_base
				var cpu := AIController.new(level, seed_base + 7919)
				cpu.attach(p2)
				p1.controller = bot
				p2.controller = cpu
				m.start_match()
				var ticks := 0
				while m.phase != m.Phase.MATCH_OVER and ticks < 5 * 120 * 60:
					m._physics_process(1.0 / 60.0)
					ticks += 1
				total += 1
				mw += 1 if m.round_wins[0] > m.round_wins[1] else 0
				rw += m.round_wins[0]
				rt += m.round_wins[0] + m.round_wins[1]
		print("%s: newbie(%s) wins %d/%d matches (%.0f%%), rounds %d/%d (%.0f%%)" % [
			AIController.DIFFICULTY_NAMES[level], kind, mw, total, 100.0 * mw / total, rw, rt, 100.0 * rw / maxi(rt, 1)])
	quit()
