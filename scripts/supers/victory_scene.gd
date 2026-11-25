class_name VictoryScene
extends SuperScene
## Base class of a victory scene (docs/ROADMAP.md §2), played by VictoryScenePlayer when
## the match is won: `attacker` is the winner, `defender` the loser, `move` is null.
## Two kinds:
## - own_set = true: the fight is hidden and the scene plays in its own set far away (like
##   a super scene), e.g. tesla man planting a flag on Mars;
## - own_set = false: the scene adds things to the stage around the real fighters (e.g.
##   golden statues and flags) and may use the stage's own camera (keep_fight_camera).
## The scene keeps running behind the result menu; end it with a held last shot.

## Play in a set of its own (the fight is hidden) instead of on the stage.
var own_set := true
## Leave the fight's victory camera in charge instead of the scene camera.
var keep_fight_camera := false


func start() -> void:
	if keep_fight_camera:
		build()
		run()
		return
	super()


## Builds a crisp two-line bordered plaque so victory callouts read clearly over bright stages.
func make_plaque(title_text: String, sub_text: String, width: float, bg_color: Color,
		border_mat: Material, title_color := Color(1.0, 0.94, 0.72),
		sub_color := Color(0.95, 0.96, 0.98)) -> Node3D:
	var root := Node3D.new()
	var height := 1.05
	var back := StandardMaterial3D.new()
	back.albedo_color = bg_color
	back.roughness = 0.7
	back.emission_enabled = true
	back.emission = bg_color
	back.emission_energy_multiplier = 0.35
	root.add_child(SuperStandins.box(Vector3(width, height, 0.05), Vector3.ZERO, back, "PlaqueBack"))
	root.add_child(SuperStandins.box(Vector3(width + 0.16, 0.07, 0.08), Vector3(0.0, height * 0.5 + 0.02, 0.0), border_mat))
	root.add_child(SuperStandins.box(Vector3(width + 0.16, 0.07, 0.08), Vector3(0.0, -height * 0.5 - 0.02, 0.0), border_mat))
	for side_x in [-width * 0.5 - 0.04, width * 0.5 + 0.04]:
		root.add_child(SuperStandins.box(Vector3(0.08, height + 0.14, 0.08), Vector3(side_x, 0.0, 0.0), border_mat))

	var title := Label3D.new()
	title.font = FONT_PUNCH
	title.text = title_text
	title.font_size = 84
	title.pixel_size = 0.0044
	title.modulate = title_color
	title.outline_size = 16
	title.outline_modulate = Color(0.04, 0.04, 0.08, 0.98)
	title.shaded = false
	title.position = Vector3(0.0, 0.18, 0.05)
	root.add_child(title)

	var sub := Label3D.new()
	sub.font = FONT_PUNCH
	sub.text = sub_text
	sub.font_size = 46
	sub.pixel_size = 0.0038
	sub.modulate = sub_color
	sub.outline_size = 12
	sub.outline_modulate = Color(0.04, 0.04, 0.08, 0.98)
	sub.shaded = false
	sub.position = Vector3(0.0, -0.22, 0.05)
	root.add_child(sub)
	return root
