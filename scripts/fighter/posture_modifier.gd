class_name PostureModifier
extends SkeletonModifier3D
## A fighter's own way of standing (CharacterData.posture): extra bone rotations applied on
## top of whatever animation plays, every frame (chest out and leaning back, a stoop, chin
## up...). A skeleton modifier, so it never accumulates and the animation stays the base.
## Cosmetic only: the simulation never reads bones.

## Bone index -> rotation (in the bone's own space) added after the animation.
var offsets := {}


func setup(skeleton: Skeleton3D, posture: Dictionary) -> void:
	for key in posture:
		var bone_name := String(key)
		var degrees: Vector3 = posture[key]
		var turn := Quaternion.from_euler(degrees * (PI / 180.0))
		for side_name in ([bone_name] if skeleton.find_bone(bone_name) >= 0 else [bone_name + "_l", bone_name + "_r"]):
			var bone := skeleton.find_bone(side_name)
			if bone < 0:
				continue
			# Mirror the turn for the right side (rotations about Y and Z flip).
			var q := turn
			if side_name.ends_with("_r"):
				q = Quaternion.from_euler(Vector3(degrees.x, -degrees.y, -degrees.z) * (PI / 180.0))
			offsets[bone] = q


func _process_modification_with_delta(_delta: float) -> void:
	var skeleton := get_skeleton()
	if skeleton == null:
		return
	for bone: int in offsets:
		skeleton.set_bone_pose_rotation(bone, skeleton.get_bone_pose_rotation(bone) * (offsets[bone] as Quaternion))
