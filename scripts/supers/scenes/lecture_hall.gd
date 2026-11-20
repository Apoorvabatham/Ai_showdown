extends SuperScene
## Geoff Hintoff's super "I Regret Nothing… Wait" (docs/ROADMAP.md §2, owner-approved):
## Rewinds back to 1986 in a university lecture hall; the chalkboard neural network diagram
## comes alive and zaps the opponent with synaptic electric arcs; Geoff at the lectern looks
## stricken with second thoughts and pleads for regulation.
##
## Timeline: ~4.5 s (270 ticks); MoveData.cinematic_ticks covers it.

const REWIND_TIME := 1.40
const ZAP_TIME := 1.10
const REGRET_TIME := 1.10
const BLAST_TIME := 0.90

var geoff: ScenePuppet
var victim: ScenePuppet
var _shake := 0.0
var _zap_beams: Array[MeshInstance3D] = []
var _zap_active := false


func build() -> void:
	var hall := load_set("lecture_hall")
	geoff = puppet(attacker, hall)
	geoff.global_transform = marker("lecture_hall", "Attacker")
	geoff.play(&"ual1/Idle")
	geoff.face = &"smile"

	victim = puppet(defender, hall)
	victim.global_transform = marker("lecture_hall", "Opponent")
	victim.play(&"ual1/Idle")
	victim.face = &"surprise"

	# Build dynamic synaptic electric beams from blackboard to opponent
	var beam_mat := StandardMaterial3D.new()
	beam_mat.albedo_color = Color(1.0, 0.9, 0.3)
	beam_mat.emission_enabled = true
	beam_mat.emission = Color(1.0, 0.85, 0.2)
	beam_mat.emission_energy_multiplier = 3.8
	beam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	for i in 4:
		var beam := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.045
		cyl.bottom_radius = 0.045
		cyl.height = 1.0
		beam.mesh = cyl
		beam.material_override = beam_mat
		beam.visible = false
		add_child(beam)
		_zap_beams.append(beam)


func run() -> void:
	show_set("lecture_hall")
	var board := marker("lecture_hall", "Board").origin
	var podium := marker("lecture_hall", "Podium").origin
	var opp := marker("lecture_hall", "Opponent").origin

	# 1. VHS Rewind to 1986 Lecture Hall
	shot("lecture_hall", "Cam_Wide", board + Vector3(-1.85, -1.2, 2.4))
	sound("victory")
	geoff.play(&"fight/focus_stance")
	geoff.face = &"smile"
	victim.play(&"ual1/Idle")
	victim.face = &"surprise"
	big_text("<< 1986: BACKPROPAGATION", board + Vector3(-1.85, 1.6, 1.6), Color(0.25, 1.0, 0.65), 0.85, 2.0)
	await wait(REWIND_TIME)

	# 2. Synaptic Network Ignites & Zaps Opponent
	shot("lecture_hall", "Cam_Board", opp + Vector3(0, 1.0, 0))
	sound("shockwave")
	_shake = 0.32
	_zap_active = true
	_update_beams(board, opp)
	victim.play(&"fight/crouch_guard")
	victim.face = &"pain"
	big_text("SYNAPTIC ACTIVATION!", opp + Vector3(0, 1.85, 0.4), Color(1.0, 0.85, 0.3), 0.75, 1.8)
	await wait(ZAP_TIME)

	# 3. Geoff's Regret & Second Thoughts
	_zap_active = false
	_hide_beams()
	shot("lecture_hall", "Cam_Geoff", podium + Vector3(0, 0.2, 0.4))
	geoff.play(&"fight/crouch_guard")
	geoff.face = &"sad"
	big_text("WHAT HAVE I DONE?!", podium + Vector3(0, 1.8, 0.2), Color(1.0, 0.45, 0.45), 0.85, 2.0)
	await wait(REGRET_TIME)

	# 4. Final Catastrophic Overfit Blast
	shot("lecture_hall", "Cam_Zap", opp + Vector3(0, 0.5, 0))
	sound("shockwave", 2.0)
	_shake = 0.55
	_zap_active = true
	_update_beams(board, opp, true)
	victim.play(&"ual2/Hit_Knockback")
	victim.face = &"pain"

	var blast_fall := create_tween()
	blast_fall.tween_property(victim, "global_position", opp + Vector3(0, 0, 1.4), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	big_text("PLEASE REGULATE US.", opp + Vector3(0, 2.1, 0.8), Color(1.0, 0.92, 0.7), 0.95, 2.0)
	await wait(0.4)
	_zap_active = false
	_hide_beams()
	await wait(BLAST_TIME - 0.4)


func _update_beams(board: Vector3, opp: Vector3, overload := false) -> void:
	var target := opp + Vector3(0, 1.1, 0)
	var output_offsets: Array[Vector3] = [
		Vector3(2.2, 0.6, 0.08),
		Vector3(2.2, -0.4, 0.08),
		Vector3(0.7, 1.2, 0.08),
		Vector3(0.7, -1.0, 0.08)
	]
	for i in _zap_beams.size():
		var beam := _zap_beams[i]
		var origin: Vector3 = board + output_offsets[i]
		var jitter := Vector3(randf_range(-0.1, 0.1), randf_range(-0.1, 0.1), randf_range(-0.1, 0.1))
		var diff: Vector3 = (target + jitter) - origin
		var length: float = diff.length()
		beam.visible = true
		var thick: float = 2.5 if overload else 1.2
		beam.scale = Vector3(thick, length, thick)
		beam.global_position = origin + diff * 0.5
		if length > 0.001:
			var up := Vector3.UP
			if absf(diff.normalized().dot(up)) > 0.95:
				up = Vector3.RIGHT
			beam.basis = Basis.looking_at(diff.normalized(), up) * Basis(Vector3.RIGHT, deg_to_rad(90))


func _hide_beams() -> void:
	for beam in _zap_beams:
		beam.visible = false


func _process(delta: float) -> void:
	super._process(delta)
	if camera and _shake > 0.0:
		_shake = maxf(0.0, _shake - delta * 1.6)
		camera.h_offset = randf_range(-_shake, _shake) * 0.08
		camera.v_offset = randf_range(-_shake, _shake) * 0.08

	if _zap_active and _sets.has("lecture_hall"):
		var board := marker("lecture_hall", "Board").origin
		var opp := victim.global_position if is_instance_valid(victim) else marker("lecture_hall", "Opponent").origin
		_update_beams(board, opp)
