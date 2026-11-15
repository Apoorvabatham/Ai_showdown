class_name FaceSculpt
extends RefCounted
## Per-fighter facial structure for the shared base head: smooth displacement fields over
## the rest-pose face, placed from the landmarks FaceShapes measures (eyeballs, lip seam,
## jaw hinge). build_outfits.gd runs it on each fighter's body before the expression blend
## shapes are made (FaceShapes re-measures the sculpted face, so blinking and the mouth
## still fit). Parameters come from CharacterData.face_shape; all optional, 0 / 1 = as
## modelled:
##
##   jaw          width of the lower face and jaw (factor, e.g. 0.95 narrow, 1.08 broad)
##   chin         chin length (m; + longer face, - shorter, rounder)
##   chin_forward chin projection (m)
##   cheekbones   cheekbone prominence (m outward)
##   fullness     fuller (+) or hollower (-) cheeks and jowls (m)
##   nose_width   nose width (factor)
##   nose_length  nose length (m; + longer, tip lower)
##   nose_bridge  height of the bridge between the eyes (m; - lower / flatter)
##   brow         brow ridge projection (m; + heavier)
##   eye_fold     0..1: a fuller upper eyelid with a lower, softer fold (a monolid-like
##                eye, as common in East Asian faces), the opening a little narrower
##   eye_tilt     m: raises (+) the outer corners of the eyes
##   eye_open     m: raises (+, rounder, wider-open eyes) or lowers (-, hooded, narrower)
##                the upper lid's rim
##   face_length  length of the face below the eyes (factor)
##   lips         fuller, more forward lips (m; - thinner)
##   mouth_width  width of the mouth (factor)
##
## Changes stay small (millimetres) and away from the eyeballs and the skull, so the shared
## eyebrows, eyes and hair still sit right.


static func apply(verts: PackedVector3Array, L: Dictionary, params: Dictionary) -> PackedVector3Array:
	var out := verts.duplicate()
	if params.is_empty():
		return out
	var P := {}
	for key in params:
		P[String(key)] = params[key]
	var eye: Vector3 = L.eye # right eyeball centre (x > 0)
	var r: float = L.eye_radius
	var seam: float = L.seam
	var hinge: Vector3 = L.hinge
	var axis_z := eye.z - 0.07 # the head's vertical axis, for "outward"
	for i in verts.size():
		var p := verts[i]
		if p.y < eye.y - 0.2 or p.y > eye.y + 0.09:
			continue
		var d := Vector3.ZERO
		var side := 1.0 if p.x >= 0.0 else -1.0
		var ax := absf(p.x)
		var out_dir := Vector3(p.x, 0.0, p.z - axis_z).normalized()
		var front := _ramp(p.z, hinge.z - 0.03, hinge.z + 0.03) # 0 behind the jaw hinge, 1 in front
		var neck_fade := _ramp(p.y, eye.y - 0.19, eye.y - 0.13)
		# Lower face below the cheekbones.
		var lower := _ramp(p.y, eye.y - 0.012, eye.y - 0.06) * neck_fade * front
		if P.has("jaw"):
			d.x += p.x * (float(P.jaw) - 1.0) * lower
		if P.has("face_length"):
			d.y += (p.y - (eye.y - 0.02)) * (float(P.face_length) - 1.0) * lower
		var mouth := (1.0 - _ramp(ax, 0.02, 0.045)) * _blob1(p.y, seam, 0.018) * _ramp(p.z, eye.z - 0.01, eye.z + 0.005)
		if P.has("lips"):
			d.z += float(P.lips) * mouth
		if P.has("mouth_width"):
			d.x += p.x * (float(P.mouth_width) - 1.0) * mouth
		if P.has("fullness"):
			var cheek := _blob(Vector3(ax, p.y, p.z), Vector3(0.048, eye.y - 0.055, eye.z - 0.02), 0.05)
			d += out_dir * float(P.fullness) * cheek * neck_fade
		if P.has("cheekbones"):
			var bone := _blob(Vector3(ax, p.y, p.z), Vector3(0.052, eye.y - 0.024, eye.z - 0.015), 0.026)
			d += out_dir * float(P.cheekbones) * bone
		# Chin: everything under the lip seam, in front, fading toward the throat.
		var chin_w := _ramp(p.y, seam - 0.004, seam - 0.045) * neck_fade * _ramp(p.z, hinge.z, hinge.z + 0.06) \
			* (1.0 - _ramp(ax, 0.035, 0.07) * 0.6)
		if P.has("chin"):
			d.y -= float(P.chin) * chin_w
		if P.has("chin_forward"):
			d.z += float(P.chin_forward) * chin_w
		# Nose: between the eyes down to above the lip, near the middle, in front.
		var nose_w := (1.0 - _ramp(ax, 0.012, 0.032)) * _ramp(p.y, seam + 0.004, seam + 0.016) \
			* (1.0 - _ramp(p.y, eye.y - 0.005, eye.y + 0.012)) * _ramp(p.z, eye.z - 0.005, eye.z + 0.01)
		if P.has("nose_width"):
			d.x += p.x * (float(P.nose_width) - 1.0) * nose_w
		if P.has("nose_length"):
			d.y -= float(P.nose_length) * nose_w * _ramp(p.y, eye.y - 0.01, eye.y - 0.045)
		if P.has("nose_bridge"):
			var bridge := (1.0 - _ramp(ax, 0.006, 0.019)) * _blob1(p.y, eye.y - 0.006, 0.022) * _ramp(p.z, eye.z - 0.01, eye.z + 0.004)
			d.z += float(P.nose_bridge) * bridge
		# Around each eye, in that eye's frame.
		var q := Vector3(ax - eye.x, p.y - eye.y, p.z - eye.z)
		if q.z > -r * 0.4:
			if P.has("brow"):
				var ridge := _blob1(q.y, r * 2.6, r * 1.4) * (1.0 - _ramp(absf(q.x), r * 1.6, r * 2.6))
				d.z += float(P.brow) * ridge
			if P.has("eye_fold"):
				# The skin over the upper lid swells forward and down a little.
				var lid := _blob1(q.y, r * 1.0, r * 0.85) * (1.0 - _ramp(absf(q.x), r * 1.15, r * 1.9))
				var k: float = P.eye_fold
				d.z += 0.0042 * k * lid
				d.y -= 0.0022 * k * lid * (1.0 - _ramp(q.y, r * 1.2, r * 2.2))
			if P.has("eye_open"):
				var rim := _blob1(q.y, r * 0.85, r * 0.75) * (1.0 - _ramp(absf(q.x), r * 1.0, r * 1.7)) * _ramp(q.z, 0.0, r * 0.5)
				var e: float = P.eye_open
				d.y += e * rim
				if e < 0.0:
					d.z += -e * 0.7 * rim # keep the lowered lid outside the eyeball
			if P.has("eye_tilt"):
				var corner := _ramp(q.x, 0.0, r * 1.2) * (1.0 - _ramp(absf(q.y), r * 0.9, r * 1.8)) * (1.0 - _ramp(q.x, r * 1.6, r * 2.4))
				d.y += float(P.eye_tilt) * corner
		out[i] = p + d
	return out


## 0 at a, 1 at b (either order), smooth.
static func _ramp(x: float, a: float, b: float) -> float:
	if a == b:
		return 1.0 if x >= a else 0.0
	return smoothstep(0.0, 1.0, (x - a) / (b - a))


static func _blob(p: Vector3, c: Vector3, radius: float) -> float:
	var t := clampf(p.distance_to(c) / radius, 0.0, 1.0)
	return 1.0 - t * t * (3.0 - 2.0 * t)


static func _blob1(x: float, c: float, radius: float) -> float:
	var t := clampf(absf(x - c) / radius, 0.0, 1.0)
	return 1.0 - t * t * (3.0 - 2.0 * t)
