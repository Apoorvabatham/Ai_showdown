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
