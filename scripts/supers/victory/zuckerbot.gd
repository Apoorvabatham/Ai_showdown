extends VictoryScene
## Mark Zuckerbot's victory (docs/ROADMAP.md §2, owner-approved): the map changes to the
## metaverse. A glitch wipes the stage away, and he celebrates on the pastel grid while the
## loser hovers behind him in goggles, with no legs.

const Fx := preload("res://scripts/supers/zuckerbot_fx.gd")

var winner: ScenePuppet
var loser: ScenePuppet
var glitch: Fx.Glitch
var _legs := 0.0


func _init() -> void:
	own_set = true
	process_priority = 50


func build() -> void:
	var world := load_set("metaverse")
	glitch = Fx.Glitch.new()
	add_child(glitch)
	winner = puppet(attacker, world)
	winner.global_transform = marker("metaverse", "Attacker")
	winner.position += Vector3(0.9, 0, 0.3)
	winner.look_at(winner.global_position + Vector3(0, 0, 1))
	winner.visible = false
	loser = puppet(defender, world)
	loser.global_transform = marker("metaverse", "Victim")
	loser.position += Vector3(1.2, 0, -1.8)
	loser.look_at(loser.global_position + Vector3(0, 0, 1))
	loser.play(&"ual1/Idle")
	loser.face = &"pain"
	Fx.wear(loser.model, prop("zuckerbot/vr_goggles", Fx.goggles))


func _process(delta: float) -> void:
	super(delta)
	if loser and loser.model:
		Fx.legs(loser.model, _legs)


func run() -> void:
	# The old map glitches out: a loading screen, then the metaverse appears.
	glitch.cover(true)
	sound("digital_glitch")
	await wait(0.35)
	show_set("metaverse")
	var spot := winner.global_position
	shot("metaverse", "Cam_Far", spot + Vector3(0, 1.0, 0))
	sound("victory")
	glitch.cover(false)
	glitch.burst(0.5)
	big_text("WELCOME TO\nTHE METAVERSE!", spot + Vector3(0.0, 2.7, -1.0), Color(1.0, 0.94, 0.72), 0.48, 1.6)
	await wait(0.4)

	# He logs in, big head and all, and dances.
	winner.visible = true
	winner.face = &"grin"
	winner.play(&"ual1/Dance")
	sound("teleport", -4.0)
	Fx.pixels(self, spot + Vector3(0, 1.2, 0), 18, 2.0)
	await wait(1.4)

	# Hero shot: a low close-up of the flex; the legless loser floats behind.
	shot("metaverse", "Cam_Hero", spot + Vector3(-0.1, 1.1, 0))
	winner.play(&"fight/victory_flex")
	big_text("LEGS SOLD SEPARATELY!", spot + Vector3(0.0, 2.15, -0.6), Color(0.35, 0.95, 1.0), 0.42)
	Fx.pixels(self, spot + Vector3(0, 1.3, 0), 12, 1.8)
