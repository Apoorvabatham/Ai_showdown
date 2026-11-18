extends SceneTree
## Builds the "style" AnimationLibrary (res://assets/animations/style_anims.res): per-fighter
## fighting-style clips, contract TASKS.md §3.6. Clips are named <fighter_id>_<move>; the
## consumer adds the library under the name "style", so a move points at style/<clip>.
##
## The pose/IK toolkit is copied from tools/build_fight_animations.gd (that file is Claude's
## and is never edited here). Poses are Dictionaries {bone_index: [position, rotation]} in
## bone local space; model space has +Z forward (toward the opponent), +Y up.
##
## Run (build):  godot --headless --path . -s res://tools/build_style_animations.gd
## Run (strips): godot --rendering-driver opengl3 --path . -s res://tools/build_style_animations.gd -- render [tesla ...]
## The strips are a row per clip and four poses per row, saved to
## docs/review/opencode/style_<fighter>.jpg.

const MODEL := "res://assets/characters/base/Superhero_Male_FullBody.gltf"
const UAL1 := "res://assets/animations/UAL1_Standard.glb"
const UAL2 := "res://assets/animations/UAL2_Standard.glb"
const OUTPUT := "res://assets/animations/style_anims.res"
const CHARACTER := "res://data/characters/%s.tres"
const OUT_DIR := "res://docs/review/opencode/"
const TRACK_PREFIX := "Armature/Skeleton3D:"
const SAMPLE_FPS := 30.0

const LOWER_BODY := ["root", "pelvis", "thigh_l", "calf_l", "foot_l", "ball_l", "ball_leaf_l",
	"thigh_r", "calf_r", "foot_r", "ball_r", "ball_leaf_r"]
const SPINE := ["spine_01", "spine_02", "spine_03"]

## Clip order in the library and on the review strip, with the time the strike lands
## (animation_impact for Claude) and whether the clip loops (idle / walk / dash).
const CLIPS := {
	"tesla": [
		{name = "tesla_idle", impact = 0.0, loop = true,
			about = "bouncing guard, up on the balls of the feet"},
		{name = "tesla_jab", impact = 0.08, loop = false,
			about = "quick lead-hand snap"},
		{name = "tesla_cross", impact = 0.14, loop = false,
			about = "rear straight, hips driving through"},
		{name = "tesla_flying_knee", impact = 0.18, loop = false,
			about = "leaping rear knee, head pulled into it"},
		{name = "tesla_spin_back_kick", impact = 0.22, loop = false,
			about = "turn the back, rear heel spears out, complete the spin"},
		{name = "tesla_dash", impact = 0.0, loop = false,
			about = "low forward burst, one knee up"},
	],
}

var skeleton: Skeleton3D
var ual1: AnimationLibrary
var ual2: AnimationLibrary
var guard: Dictionary
var crouch: Dictionary
var rear := "r"
var lead := "l"


func _initialize() -> void:
	var model := (load(MODEL) as PackedScene).instantiate()
	skeleton = model.find_child("Skeleton3D") as Skeleton3D
	ual1 = load(UAL1)
	ual2 = load(UAL2)

	guard = sample(ual1.get_animation("Punch_Jab"), 0.0)
	crouch = merge(sample(ual1.get_animation("Crouch_Idle"), 0.0), guard, upper_body_bones())
	rotate_bone(crouch, "spine_01", Vector3.RIGHT, -25.0)
	var foot_l := global_origin(guard, "foot_l")
	var foot_r := global_origin(guard, "foot_r")
	rear = "l" if foot_l.z < foot_r.z else "r"
	lead = "r" if rear == "l" else "l"
	print("rear side: ", rear)

	var style := build_library()
	var err := ResourceSaver.save(style, OUTPUT)
	print("saved ", OUTPUT, " (", style.get_animation_list().size(), " clips) err=", err)
	_print_clips(style)

	var args := OS.get_cmdline_user_args()
	var render := not args.is_empty() and args[0] == "render"
	model.free()
	if render:
		var only: Array[String] = []
		for i in range(1, args.size()):
			only.append(args[i])
		await _render_strips(style, only)
	quit()


## The whole library. One builder per clip; adding a fighter means adding its CLIPS entry,
## its builders and its row here.
func build_library() -> AnimationLibrary:
	var lib := AnimationLibrary.new()
	add_tesla(lib)
	return lib


func add_tesla(lib: AnimationLibrary) -> void:
	lib.add_animation("tesla_idle", build_tesla_idle())
	lib.add_animation("tesla_jab", build_tesla_jab())
	lib.add_animation("tesla_cross", build_tesla_cross())
	lib.add_animation("tesla_flying_knee", build_tesla_flying_knee())
	lib.add_animation("tesla_spin_back_kick", build_tesla_spin_back_kick())
	lib.add_animation("tesla_dash", build_tesla_dash())


# --- tesla man: fast and jumpy ------------------------------------------------------

## Bouncing guard: two light bounces per cycle, up on the balls of both feet, the hands
## tucked tight to the chin, a small side-to-side sway. 0.80 s loop.
func build_tesla_idle() -> Animation:
	var lf := global_origin(guard, "foot_" + lead)
	var rf := global_origin(guard, "foot_" + rear)
	var down := duplicate_pose(guard)
	_tuck_hands(down)
	var up := duplicate_pose(guard)
	move_bone(up, "pelvis", Vector3(0.008, 0.055, 0.012))
	plant_foot(up, lead, lf + Vector3(0, 0.05, 0))
	plant_foot(up, rear, rf + Vector3(0, 0.06, 0))
	point_foot(up, lead, foot_direction(guard, lead) + Vector3(0, -0.55, 0))
	point_foot(up, rear, foot_direction(guard, rear) + Vector3(0, -0.75, 0))
	lean(up, -2.0, 0.0)
	_tuck_hands(up)
	var down_b := duplicate_pose(down)
	move_bone(down_b, "pelvis", Vector3(-0.01, -0.012, 0))
	lean(down_b, 1.5, 0.0)
	var up_b := duplicate_pose(up)
	move_bone(up_b, "pelvis", Vector3(-0.016, -0.004, 0))
	lean(up_b, -3.5, 0.0)
	return make_animation([[0.0, down], [0.20, up], [0.40, down_b], [0.60, up_b], [0.80, down]], true)


## Fast lead jab: a tiny dip and counter-coil, the lead shoulder rolls in and the fist
## snaps straight out, then retracts along the same line. Length 0.28 s.
func build_tesla_jab() -> Animation:
	var lf := global_origin(guard, "foot_" + lead)
	var rf := global_origin(guard, "foot_" + rear)
	var load := duplicate_pose(guard)
	move_bone(load, "pelvis", Vector3(0, -0.025, 0.0))
	hip_turn(load, 6.0)
	plant_both(load, lf, rf)

	var strike := duplicate_pose(guard)
	move_bone(strike, "pelvis", Vector3(0, -0.005, 0.06))
	hip_turn(strike, -14.0)
	lean(strike, -3.0, 0.0)
	plant_foot(strike, lead, lf)
	pivot_support_foot(strike, 6.0, false)
	var shoulder := global_origin(strike, "upperarm_" + lead)
	punch_arm(strike, lead, Vector3(shoulder.x * 0.2, shoulder.y + 0.015, shoulder.z + 0.62))
	shoulder_roll(strike, lead, 10.0)
	rotate_bone(strike, "neck_01", Vector3.RIGHT, 6.0) # chin tucked behind the shoulder
	tuck_hand(strike, rear)

	var recoil := duplicate_pose(strike)
	punch_arm(recoil, lead, Vector3(shoulder.x * 0.3, shoulder.y, shoulder.z + 0.25))
	return make_animation([[0.0, guard], [0.04, load], [0.08, strike], [0.11, strike],
		[0.17, recoil], [0.28, guard]], false)


## Rear cross: coil away, then the rear hip drives the straight through while the rear
## heel pivots and the lead hand comes back to the chin. Length 0.34 s.
func build_tesla_cross() -> Animation:
	var lf := global_origin(guard, "foot_" + lead)
	var rf := global_origin(guard, "foot_" + rear)
	var load := duplicate_pose(guard)
	move_bone(load, "pelvis", Vector3(0, -0.03, -0.01))
	hip_turn(load, -12.0)
	plant_both(load, lf, rf)

	var strike := duplicate_pose(guard)
	move_bone(strike, "pelvis", Vector3(0, 0.0, 0.07))
	hip_turn(strike, 42.0)
	lean(strike, -4.0, 0.0)
	plant_foot(strike, lead, lf)
	plant_foot(strike, rear, rf + Vector3(0, 0.03, 0.02))
	point_foot(strike, rear, foot_direction(guard, rear).rotated(Vector3.UP, deg_to_rad(-rear_sign() * 45.0)) + Vector3(0, -0.45, 0))
	var shoulder := global_origin(strike, "upperarm_" + rear)
	punch_arm(strike, rear, Vector3(shoulder.x * 0.25, shoulder.y + 0.01, shoulder.z + 0.64))
	shoulder_roll(strike, rear, 8.0)
	var lead_shoulder := global_origin(strike, "upperarm_" + lead)
	reach_arm(strike, lead, Vector3(lead_shoulder.x * 0.7, lead_shoulder.y - 0.1, lead_shoulder.z + 0.18))

	var follow := duplicate_pose(strike)
	hip_turn(follow, 8.0)
	lean(follow, -8.0, 0.0)
	return make_animation([[0.0, guard], [0.05, load], [0.14, strike], [0.18, strike],
		[0.26, follow], [0.34, guard]], false)


## Leaping knee: dip, both feet leave the floor, the rear knee drives up to chest height
## while both hands pull forward and down (the head), then land in a low guard. Length
## 0.56 s; the knee arrives at 0.18 s.
func build_tesla_flying_knee() -> Animation:
	var s := rear_sign()
	var lf := global_origin(guard, "foot_" + lead)
	var rf := global_origin(guard, "foot_" + rear)
	var dip := duplicate_pose(guard)
	move_bone(dip, "pelvis", Vector3(0, -0.09, 0.0))
	lean(dip, -6.0, 0.0)
	plant_both(dip, lf, rf)

	var air := duplicate_pose(guard)
	move_bone(air, "pelvis", Vector3(0, 0.17, 0.07))
	hip_turn(air, 25.0)
	lean(air, 6.0, 3.0)
	var hip := global_origin(air, "thigh_" + rear)
	solve_ik(air, "thigh_" + rear, "calf_" + rear, "foot_" + rear,
		hip + Vector3(s * 0.02, 0.2, 0.12), Vector3(0, 1, 0.6))
	point_foot(air, rear, Vector3(0, -1, -0.25))
	var lead_hip := global_origin(air, "thigh_" + lead)
	solve_ik(air, "thigh_" + lead, "calf_" + lead, "foot_" + lead,
		lead_hip + Vector3(-s * 0.05, -0.5, -0.18), Vector3(0, 0.2, 1))
	point_foot(air, lead, Vector3(0, -0.9, 0.2))
	var chest := global_origin(air, "spine_03")
	reach_arm(air, lead, Vector3(0.1, chest.y + 0.05, chest.z + 0.48))
	reach_arm(air, rear, Vector3(-0.1, chest.y + 0.08, chest.z + 0.42))

	var peak := duplicate_pose(air)
	move_bone(peak, "pelvis", Vector3(0, 0.04, 0.02))
	hip_turn(peak, 8.0)

	var land := duplicate_pose(guard)
	move_bone(land, "pelvis", Vector3(0, -0.07, 0.06))
	lean(land, -10.0, 0.0)
	plant_both(land, lf + Vector3(0, 0, 0.08), rf + Vector3(0, 0, 0.04))
	return make_animation([[0.0, guard], [0.06, dip], [0.18, air], [0.28, peak],
		[0.40, land], [0.56, guard]], false)


## Spinning back kick: a fast turn on the lead foot, eyes over the shoulder, the rear heel
## spears straight back through the opponent, then the spin completes back to the guard.
## Length 0.56 s; heel arrives at 0.22 s.
func build_tesla_spin_back_kick() -> Animation:
	var s := rear_sign()
	var lf := global_origin(guard, "foot_" + lead)
	var turn := duplicate_pose(guard)
	move_bone(turn, "pelvis", Vector3(0, -0.03, 0.04))
	rotate_bone(turn, "pelvis", Vector3.UP, s * 120.0)
	rotate_bone(turn, "neck_01", Vector3.UP, -s * 70.0)
	plant_foot(turn, lead, lf)

	var kick := duplicate_pose(guard)
	move_bone(kick, "pelvis", Vector3(0, -0.02, 0.05))
	rotate_bone(kick, "pelvis", Vector3.UP, s * 175.0)
	rotate_bone(kick, "neck_01", Vector3.UP, -s * 90.0)
	lean(kick, -18.0, 0.0)
	plant_foot(kick, lead, lf)
	var hip := global_origin(kick, "thigh_" + rear)
	solve_ik(kick, "thigh_" + rear, "calf_" + rear, "foot_" + rear,
		Vector3(hip.x * 0.3, 1.15, hip.z + 1.0), Vector3(0, 1, 0))
	point_foot(kick, rear, Vector3(0, -1.0, 0.1)) # heel leads

	var through := duplicate_pose(guard)
	rotate_bone(through, "pelvis", Vector3.UP, s * 300.0)
	plant_foot(through, lead, lf)
	return make_animation([[0.0, guard], [0.10, turn], [0.20, kick], [0.26, kick],
		[0.40, through], [0.56, guard]], false)


## Dash: a quick low coil, then a forward burst with the lead knee up and the rear leg
## driving behind, arms pumping, landing in the guard. Movement clip (no strike). 0.42 s.
func build_tesla_dash() -> Animation:
	var lf := global_origin(guard, "foot_" + lead)
	var rf := global_origin(guard, "foot_" + rear)
	var coil := duplicate_pose(guard)
	move_bone(coil, "pelvis", Vector3(0, -0.07, -0.02))
	lean(coil, 8.0, 0.0)
	plant_both(coil, lf, rf)

	var burst := duplicate_pose(guard)
	move_bone(burst, "pelvis", Vector3(0, 0.05, 0.14))
	lean(burst, -22.0, 0.0)
	hip_turn(burst, 16.0)
	var hip := global_origin(burst, "thigh_" + lead)
	solve_ik(burst, "thigh_" + lead, "calf_" + lead, "foot_" + lead,
		hip + Vector3(0, -0.08, 0.26), Vector3(0, 0.8, 1))
	point_foot(burst, lead, Vector3(0, -0.5, 1))
	var rear_hip := global_origin(burst, "thigh_" + rear)
	solve_ik(burst, "thigh_" + rear, "calf_" + rear, "foot_" + rear,
		rear_hip + Vector3(0, -0.6, -0.58), Vector3(0, 0.2, 1))
	point_foot(burst, rear, Vector3(0, -0.35, 1))
	var shoulder := global_origin(burst, "upperarm_" + rear)
	reach_arm(burst, rear, shoulder + Vector3(rear_sign() * 0.22, -0.12, -0.28))
	var lead_shoulder := global_origin(burst, "upperarm_" + lead)
	reach_arm(burst, lead, lead_shoulder + Vector3(-rear_sign() * 0.08, -0.04, 0.2))

	var land := duplicate_pose(guard)
	move_bone(land, "pelvis", Vector3(0, -0.05, 0.06))
	lean(land, -10.0, 0.0)
	plant_both(land, lf + Vector3(0, 0, 0.06), rf + Vector3(0, 0, 0.03))
	return make_animation([[0.0, guard], [0.05, coil], [0.14, burst], [0.24, burst],
		[0.32, land], [0.42, guard]], false)


# --- Pose helpers -------------------------------------------------------------------

## Both hands tucked tight in front of the chin, elbows down (a tight, mobile boxer guard).
func _tuck_hands(pose: Dictionary) -> void:
	var chin := global_origin(pose, "neck_01") + Vector3(0, -0.24, 0.18)
	var side := 1.0 if lead == "l" else -1.0
	reach_arm(pose, lead, chin + Vector3(side * 0.055, 0.02, 0.02))
	reach_arm(pose, rear, chin + Vector3(-side * 0.055, -0.01, -0.01))


func tuck_hand(pose: Dictionary, side: String) -> void:
	var chin := global_origin(pose, "neck_01") + Vector3(0, -0.24, 0.16)
	var x := 0.06 if side == "l" else -0.06
	reach_arm(pose, side, chin + Vector3(x, 0.0, -0.02))


# --- Toolkit copied from tools/build_fight_animations.gd ----------------------------

func sample(anim: Animation, time: float) -> Dictionary:
	var pose := {}
	for i in skeleton.get_bone_count():
		var rest := skeleton.get_bone_rest(i)
		var path := NodePath(TRACK_PREFIX + skeleton.get_bone_name(i))
		var pos := rest.origin
		var rot := rest.basis.get_rotation_quaternion()
		var pt := anim.find_track(path, Animation.TYPE_POSITION_3D)
		if pt >= 0:
			pos = anim.position_track_interpolate(pt, time)
		var rt := anim.find_track(path, Animation.TYPE_ROTATION_3D)
		if rt >= 0:
			rot = anim.rotation_track_interpolate(rt, time)
		pose[i] = [pos, rot]
	return pose


func merge(base: Dictionary, overlay: Dictionary, overlay_bones: Array) -> Dictionary:
	var out := duplicate_pose(base)
	for i: int in overlay_bones:
		out[i] = overlay[i].duplicate()
	return out


func duplicate_pose(pose: Dictionary) -> Dictionary:
	var out := {}
	for i in pose:
		out[i] = pose[i].duplicate()
	return out


func global_transform(pose: Dictionary, bone: int) -> Transform3D:
	var local := Transform3D(Basis(pose[bone][1] as Quaternion), pose[bone][0] as Vector3)
	var parent := skeleton.get_bone_parent(bone)
	return local if parent < 0 else global_transform(pose, parent) * local


func global_origin(pose: Dictionary, bone_name: String) -> Vector3:
	return global_transform(pose, skeleton.find_bone(bone_name)).origin


## Rotates `bone` (and its subtree) by `degrees` around a model-space axis.
func rotate_bone(pose: Dictionary, bone_name: String, axis: Vector3, degrees: float) -> void:
	_apply_global_rotation(pose, skeleton.find_bone(bone_name), Quaternion(axis.normalized(), deg_to_rad(degrees)))


## Rotates `bone` so the direction toward `child` points along a model-space direction.
func aim(pose: Dictionary, bone_name: String, child_name: String, direction: Vector3) -> void:
	var bone := skeleton.find_bone(bone_name)
	var from := global_origin(pose, bone_name)
	var to := global_origin(pose, child_name)
	_apply_global_rotation(pose, bone, Quaternion((to - from).normalized(), direction.normalized()))


## Moves `bone` by a model-space offset.
func move_bone(pose: Dictionary, bone_name: String, offset: Vector3) -> void:
	var bone := skeleton.find_bone(bone_name)
	var parent := skeleton.get_bone_parent(bone)
	var parent_basis := Basis() if parent < 0 else global_transform(pose, parent).basis
	pose[bone][0] = (pose[bone][0] as Vector3) + parent_basis.inverse() * offset


func _apply_global_rotation(pose: Dictionary, bone: int, rotation: Quaternion) -> void:
	var parent := skeleton.get_bone_parent(bone)
	var parent_basis := Basis() if parent < 0 else global_transform(pose, parent).basis
	var global_basis := global_transform(pose, bone).basis
	var new_local := parent_basis.inverse() * Basis(rotation) * global_basis
	pose[bone][1] = new_local.get_rotation_quaternion()


func bone_indices(names: Array) -> Array:
	var out := []
	for n: String in names:
		out.append(skeleton.find_bone(n))
	return out


func upper_body_bones() -> Array:
	var lower := bone_indices(LOWER_BODY + SPINE)
	var out := []
	for i in skeleton.get_bone_count():
		if i not in lower:
			out.append(i)
	return out


func arm_bones() -> Array:
	var out := []
	for i in skeleton.get_bone_count():
		var n := skeleton.get_bone_name(i)
		if n.ends_with("_l") or n.ends_with("_r"):
			if not (n.begins_with("thigh") or n.begins_with("calf") or n.begins_with("foot") or n.begins_with("ball")):
				out.append(i)
	return out


## keys: Array of [time, pose]. Position track for the pelvis, rotation tracks for all bones.
func make_animation(keys: Array, loop: bool) -> Animation:
	var anim := Animation.new()
	anim.length = keys[-1][0]
	anim.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	var pelvis := skeleton.find_bone("pelvis")
	var pos_track := anim.add_track(Animation.TYPE_POSITION_3D)
	anim.track_set_path(pos_track, NodePath(TRACK_PREFIX + "pelvis"))
	for key in keys:
		anim.position_track_insert_key(pos_track, key[0], key[1][pelvis][0])
	for i in skeleton.get_bone_count():
		var track := anim.add_track(Animation.TYPE_ROTATION_3D)
		anim.track_set_path(track, NodePath(TRACK_PREFIX + skeleton.get_bone_name(i)))
		anim.track_set_interpolation_type(track, Animation.INTERPOLATION_CUBIC)
		for key in keys:
			anim.rotation_track_insert_key(track, key[0], key[1][i][1])
	return anim


func resample_merged(source: Animation, keep_bones: Array, loop: bool) -> Animation:
	var keys := []
	var t := 0.0
	while t <= source.length + 0.001:
		keys.append([t, merge(guard, sample(source, t), bone_indices(keep_bones))])
		t += 1.0 / SAMPLE_FPS
	return make_animation(keys, loop)


## +1 if the rear (kicking) side is the model's left (+X), -1 if it's the right.
func rear_sign() -> float:
	return 1.0 if rear == "l" else -1.0


## Two-bone IK in model space: places `end_bone` at `target`, bending `mid_bone` toward
## `pole`. Out-of-reach targets straighten the limb toward them.
func solve_ik(pose: Dictionary, upper: String, mid: String, end_bone: String, target: Vector3, pole: Vector3) -> void:
	var a := global_origin(pose, upper)
	var l1 := a.distance_to(global_origin(pose, mid))
	var l2 := global_origin(pose, mid).distance_to(global_origin(pose, end_bone))
	var to_target := target - a
	var d := clampf(to_target.length(), absf(l1 - l2) + 0.001, l1 + l2 - 0.001)
	var dir := to_target.normalized()
	var cos_a := clampf((l1 * l1 + d * d - l2 * l2) / (2.0 * l1 * d), -1.0, 1.0)
	var bend := pole - dir * pole.dot(dir)
	if bend.length_squared() < 0.0001:
		bend = Vector3.UP.cross(dir)
	bend = bend.normalized()
	var knee := a + dir * (cos_a * l1) + bend * (sqrt(1.0 - cos_a * cos_a) * l1)
	aim(pose, upper, mid, knee - a)
	aim(pose, mid, end_bone, (a + dir * d) - global_origin(pose, mid))


## Keeps a support foot at `planted` (model space), knee bending forward and slightly out.
func plant_foot(pose: Dictionary, side: String, planted: Vector3) -> void:
	var out := 0.25 if side == "l" else -0.25
	solve_ik(pose, "thigh_" + side, "calf_" + side, "foot_" + side, planted, Vector3(out, 0, 1))
	point_foot(pose, side, foot_direction(guard, side))


## Points the foot (ankle -> ball) along a model-space direction.
func point_foot(pose: Dictionary, side: String, direction: Vector3) -> void:
	aim(pose, "foot_" + side, "ball_" + side, direction)


func foot_direction(pose: Dictionary, side: String) -> Vector3:
	return global_origin(pose, "ball_" + side) - global_origin(pose, "foot_" + side)


## Pivots the lead (support) foot so the heel turns toward the target; optionally up on
## the ball of the foot.
func pivot_support_foot(pose: Dictionary, degrees: float, on_ball: bool) -> void:
	var base := foot_direction(guard, lead)
	var dir := base.rotated(Vector3.UP, deg_to_rad(degrees * -rear_sign()))
	if on_ball:
		dir.y -= 0.22 * Vector2(dir.x, dir.z).length()
	point_foot(pose, lead, dir)


## Turns the hips by `degrees` (positive brings the rear hip forward). Shoulders follow
## about half way and the head stays on the target.
func hip_turn(pose: Dictionary, degrees: float) -> void:
	var signed := degrees * -rear_sign()
	rotate_bone(pose, "pelvis", Vector3.UP, signed)
	rotate_bone(pose, "spine_02", Vector3.UP, -signed * 0.5)
	rotate_bone(pose, "neck_01", Vector3.UP, -signed * 0.4)


## Leans the torso back (positive) or forward (negative) and sideways toward the
## support side, then rights the head a little.
func lean(pose: Dictionary, back_degrees: float, side_degrees: float) -> void:
	rotate_bone(pose, "spine_01", Vector3.RIGHT, -back_degrees * 0.6)
	rotate_bone(pose, "spine_02", Vector3.RIGHT, -back_degrees * 0.4)
	rotate_bone(pose, "spine_01", Vector3(0, 0, 1), -rear_sign() * side_degrees)
	rotate_bone(pose, "neck_01", Vector3.RIGHT, back_degrees * 0.4)


## Rear arm swings down and back to counterbalance a kick (amount 0..1); lead arm keeps
## the guard.
func swing_rear_arm(pose: Dictionary, amount: float) -> void:
	var s := rear_sign()
	var upper := Vector3(s * 0.35, -0.2, 0.25).lerp(Vector3(s * 0.35, -0.85, -0.45), amount)
	var lower := Vector3(0, 0.4, 0.6).lerp(Vector3(s * 0.1, -0.95, -0.15), amount)
	aim(pose, "upperarm_" + rear, "lowerarm_" + rear, upper)
	aim(pose, "lowerarm_" + rear, "hand_" + rear, lower)


## Places a hand at `target` (model space), elbow bending back and out.
func reach_arm(pose: Dictionary, side: String, target: Vector3) -> void:
	var out := 1.0 if side == "l" else -1.0
	solve_ik(pose, "upperarm_" + side, "lowerarm_" + side, "hand_" + side, target, Vector3(out * 0.6, 0.3, -0.6))


## Straight punch: hand to `target` with the elbow tucked down and slightly out.
func punch_arm(pose: Dictionary, side: String, target: Vector3) -> void:
	var out := 1.0 if side == "l" else -1.0
	solve_ik(pose, "upperarm_" + side, "lowerarm_" + side, "hand_" + side, target, Vector3(out * 0.4, -1.0, -0.2))


## Raises a shoulder (clavicle) by `degrees`: the jab's chin-covering shoulder roll.
func shoulder_roll(pose: Dictionary, side: String, degrees: float) -> void:
	rotate_bone(pose, "clavicle_" + side, Vector3(0, 0, 1), degrees * (1.0 if side == "l" else -1.0))


func plant_both(pose: Dictionary, lead_foot: Vector3, rear_foot: Vector3) -> void:
	plant_foot(pose, lead, lead_foot)
	plant_foot(pose, rear, rear_foot)


# --- Review strips ------------------------------------------------------------------

func _print_clips(lib: AnimationLibrary) -> void:
	for fighter: String in CLIPS:
		for clip: Dictionary in CLIPS[fighter]:
			var anim := lib.get_animation(clip.name)
			print("%s length %.2f impact %.2f loop %s  (%s)" % [clip.name, anim.length,
				clip.impact, clip.loop, clip.about])


## One image per fighter: a row per clip, four poses across (start, wind-up/impact, the
## strike or follow-through, the end). Needs a renderer, not --headless.
func _render_strips(lib: AnimationLibrary, only: Array[String]) -> void:
	var settings: Node = root.get_node("Settings")
	settings.graphics = settings.Graphics.HIGH
	settings.resolution = settings.RESOLUTIONS.size() - 1
	settings.apply_graphics(root)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var fighters: Array = only if not only.is_empty() else CLIPS.keys()
	for fighter: String in fighters:
		if not CLIPS.has(fighter):
			print("no clips for ", fighter)
			continue
		var character := load(CHARACTER % fighter) as CharacterData
		if character == null:
			print("missing character ", fighter)
			continue
		var clips: Array = CLIPS[fighter]
		var cell := Vector2i(300, 320)
		var sheet := Image.create(cell.x * 4, cell.y * clips.size(), false, Image.FORMAT_RGB8)
		sheet.fill(Color(0.10, 0.10, 0.13))
		var viewport := await _make_viewport(cell)
		var model := FighterModel.new()
		(viewport.get_node("Stage") as Node3D).add_child(model)
		model.build(character, false)
		model.player.add_animation_library(&"style", lib)
		for row in clips.size():
			var clip: Dictionary = clips[row]
			var anim := lib.get_animation(clip.name)
			var times := _preview_times(anim.length, clip.impact, clip.loop)
			for column in 4:
				var t: float = times[column]
				model.show_clip(&"style/" + String(clip.name), t, 1.0, 1.0 / 60.0)
				_settings_label(viewport, "%s  %.2fs" % [clip.name, t])
				for i in 8:
					model.show_clip(&"style/" + String(clip.name), t, 1.0, 1.0 / 60.0)
					await process_frame
				var image := viewport.get_texture().get_image()
				image.convert(Image.FORMAT_RGB8)
				sheet.blit_rect(image, Rect2i(Vector2i.ZERO, cell), Vector2i(column * cell.x, row * cell.y))
			print("rendered ", clip.name)
		var out := OUT_DIR + "style_%s.jpg" % fighter
		sheet.save_jpg(out, 0.9)
		print("saved ", out)
		viewport.queue_free()


## Four times to sample for a strip: the start, the wind-up or a third in, the impact (or
## the middle for movement), and the end.
func _preview_times(length: float, impact: float, loop: bool) -> Array:
	if impact > 0.0:
		return [0.0, minf(length, impact * 0.5), minf(length, impact), length * 0.98]
	if loop:
		return [0.0, length / 3.0, length * 2.0 / 3.0, length * 0.98]
	return [0.0, length * 0.35, length * 0.65, length * 0.98]


func _make_viewport(cell: Vector2i) -> SubViewport:
	var vp := SubViewport.new()
	vp.size = cell
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_4X
	root.add_child(vp)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.10, 0.10, 0.13)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.64, 0.72)
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	vp.add_child(world_env)
	var stage := Node3D.new()
	stage.name = "Stage"
	vp.add_child(stage)
	var key := DirectionalLight3D.new()
	key.light_energy = 1.5
	key.shadow_enabled = true
	stage.add_child(key)
	key.look_at_from_position(Vector3(3.0, 5.0, -3.0), Vector3(0, 1.0, 0))
	var fill := DirectionalLight3D.new()
	fill.light_energy = 0.45
	stage.add_child(fill)
	fill.look_at_from_position(Vector3(-4.0, 2.0, 3.0), Vector3(0, 1.0, 0))
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(8.0, 8.0)
	ground.mesh = plane
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.16, 0.16, 0.19)
	floor_material.roughness = 0.9
	ground.material_override = floor_material
	stage.add_child(ground)
	var label := Label3D.new()
	label.name = "Caption"
	label.font_size = 40
	label.pixel_size = 0.0042
	label.modulate = Color(0.90, 0.92, 0.96)
	label.shaded = false
	label.no_depth_test = true
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0.0, -0.18, 0.35)
	stage.add_child(label)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.75
	camera.look_at_from_position(Vector3(4.0, 1.7, -1.3), Vector3(0, 1.02, 0))
	camera.current = true
	vp.add_child(camera)
	await process_frame
	return vp


func _settings_label(viewport: SubViewport, text: String) -> void:
	var stage := viewport.get_node("Stage") as Node3D
	(stage.get_node("Caption") as Label3D).text = text
