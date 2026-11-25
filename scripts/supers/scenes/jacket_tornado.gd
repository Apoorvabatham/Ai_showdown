extends SuperScene
## Jensen Wong's super "Leather Jacket Tornado" (docs/ROADMAP.md §2, owner-approved): on a
## dark keynote stage he whips off his black leather jacket; it spins into a tornado that
## sucks the opponent up, flings them around and spits them out.
##
## Timeline: about 5.0 s; MoveData.cinematic_ticks must cover it (tools/showdown_movesets.gd).

const WHIP_TIME := 0.9
const GROW_TIME := 0.8
const SUCK_TIME := 1.7
const FLING_TIME := 0.9
const END_TIME := 0.7
const LENGTH := WHIP_TIME + GROW_TIME + SUCK_TIME + FLING_TIME + END_TIME

const RING_COUNT := 10
const BIT_COUNT := 56
const TORNADO_HEIGHT := 6.2

const VORTEX_SHADER := """shader_type spatial;
render_mode cull_disabled, unshaded, blend_mix;
uniform vec4 dark_col : source_color = vec4(0.05, 0.045, 0.05, 1.0);
uniform vec4 brown_col : source_color = vec4(0.22, 0.14, 0.09, 1.0);
uniform vec4 accent_col : source_color = vec4(0.45, 0.85, 0.08, 1.0);
uniform float spin_speed = 3.2;
uniform float twists = 5.0;
uniform float density = 0.78;
void fragment() {
	float v = UV.y;
	float swirl = UV.x * 6.28318 * twists - v * 12.0 - TIME * spin_speed;
	float band = sin(swirl) * 0.5 + 0.5;
	float streak = pow(sin(swirl * 2.0 + 1.1) * 0.5 + 0.5, 4.0);
	float edge_fade = smoothstep(0.0, 0.15, v) * smoothstep(1.0, 0.72, v);
	vec3 col = mix(dark_col.rgb, brown_col.rgb, band * 0.85);
	col = mix(col, accent_col.rgb, streak * 0.45);
	ALBEDO = col;
	ALPHA = clamp((0.35 + band * 0.55) * edge_fade * density, 0.0, 0.92);
}
"""

var jensen: ScenePuppet
var victim: ScenePuppet
var jacket: Node3D
var tornado: Node3D
var _shells: Array[MeshInstance3D] = []
var _rings: Array[MeshInstance3D] = []
var _bits: Array[MeshInstance3D] = []
var _vortex_particles: GPUParticles3D
var _strength := 0.0 # 0..1: how grown the tornado is
var _spin := 0.0
var _jacket_spinning := false
## While the victim is caught: its orbit (angle, radius, height) around the tornado's axis.
var _caught := false
var _orbit := Vector3.ZERO
var _center := Vector3.ZERO
var _origin := Vector3.ZERO # the stage set's origin (global)


func build() -> void:
	var stage := load_set("keynote_stage")
	jensen = puppet(attacker, stage)
	jensen.global_transform = marker("keynote_stage", "Jensen")
	jensen.face = &"grin"
	victim = puppet(defender, stage)
	victim.global_transform = marker("keynote_stage", "Victim")
	victim.hold(&"fight/guard", 0.2)
	victim.face = &"pain"
	_center = marker("keynote_stage", "Center").origin
	_origin = stage.global_position
	jacket = prop("jensen/leather_jacket", leather_jacket, stage)
	jacket.global_position = jensen.global_position + Vector3(0, 1.3, 0)
	jacket.scale = Vector3.ONE * 0.9
	tornado = Node3D.new()
	tornado.name = "Tornado"
	stage.add_child(tornado)
	tornado.global_position = _center
	build_tornado()
	tornado.scale = Vector3(1, 0.01, 1)


func run() -> void:
	show_set("keynote_stage")
	shot("keynote_stage", "Cam_Wide", _center + Vector3(-0.7, 1.45, 0))

	# Whip it off: the jacket flies up over his head.
	jensen.play(&"fight/victory_point")
	sound("whoosh")
	big_text("JACKET OFF!", _center + Vector3(-0.5, 2.7, 0.8), Color(0.92, 0.98, 1.0), 0.65, 0.7)
	await wait(0.25)
	_jacket_spinning = true
	var toss := create_tween().set_parallel(true)
	toss.tween_property(jacket, "global_position", _center + Vector3(0, 2.5, 0), WHIP_TIME - 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	toss.tween_property(jacket, "scale", Vector3.ONE * 1.9, WHIP_TIME - 0.25)
	await wait(WHIP_TIME - 0.25)

	# It spins into a tornado, growing from the floor.
	sound("tornado")
	camera_move(Vector3(0.4, 2.5, 7.6), Vector3(0.5, 2.8, 0.2), GROW_TIME + SUCK_TIME)
	if _vortex_particles:
		_vortex_particles.emitting = true
	var grow := create_tween().set_parallel(true)
	grow.tween_property(tornado, "scale", Vector3.ONE, GROW_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	grow.tween_property(self, "_strength", 1.0, GROW_TIME)
	grow.tween_property(jacket, "global_position", _center + Vector3(0, TORNADO_HEIGHT * 0.78, 0), GROW_TIME)
	await wait(GROW_TIME)

	# The opponent is sucked in and carried up, round and round.
	victim.play(&"fight/thrown", 1.0)
	victim.face = &"shout"
	_orbit = Vector3(0.0, 2.0, 0.0)
	_caught = true
	var suck := create_tween().set_parallel(true)
	suck.tween_property(self, "_orbit:y", 0.75, SUCK_TIME) # radius pulls in
	suck.tween_property(self, "_orbit:z", 4.0, SUCK_TIME).set_trans(Tween.TRANS_QUAD) # and climbs
	await wait(SUCK_TIME)

	# Spat out: flung off across the stage, the tornado winds down.
	_caught = false
	sound("whoosh")
	var out := create_tween()
	out.tween_property(victim, "global_position", _center + Vector3(4.5, 4.5, 2.2), FLING_TIME * 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	out.tween_property(victim, "global_position", marker("keynote_stage", "Victim").origin + Vector3(1.1, 0, 0.8), FLING_TIME * 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	var spin_out := create_tween()
	spin_out.tween_property(victim, "rotation:z", TAU * 2.0, FLING_TIME)
	var wind_down := create_tween().set_parallel(true)
	wind_down.tween_property(self, "_strength", 0.0, FLING_TIME)
	wind_down.tween_property(tornado, "scale", Vector3(0.1, 0.01, 0.1), FLING_TIME).set_delay(0.2)
	if _vortex_particles:
		_vortex_particles.emitting = false
	jacket_return(FLING_TIME)
	camera_move(Vector3(1.1, 2.0, 6.2), Vector3(1.6, 1.3, 0.4), FLING_TIME + END_TIME)
	await wait(FLING_TIME)
	victim.rotation = marker("keynote_stage", "Victim").basis.get_euler()
	victim.hold(&"fight/wall_splat", 0.4)
	victim.face = &"pain"
	big_text("1000x TURBO FLUNG!", victim.global_position + Vector3(0, 2.1, 0.5), Color(1.0, 0.94, 0.72), 0.65, 0.65)
	var dust := _impact_dust()
	add_child(dust)
	dust.global_position = victim.global_position + Vector3(0, 0.15, 0)
	await wait(END_TIME)


func _process(delta: float) -> void:
	super(delta)
	_spin += delta
	if _jacket_spinning and jacket:
		jacket.rotate_y(delta * (14.0 if _strength > 0.0 else 9.0))
	if _strength > 0.0 and tornado:
		animate_tornado()
	if _caught and victim:
		_orbit.x += delta * 7.5
		var around := Vector3(cos(_orbit.x), 0.0, sin(_orbit.x)) * _orbit.y
		victim.global_position = tornado.global_position + around + Vector3(0, _orbit.z, 0)
		victim.rotation = Vector3(0.7 * sin(_orbit.x * 0.5), -_orbit.x + PI * 0.5, 0.6)


## The jacket flies back to Jensen's shoulders and he puts it back on.
func jacket_return(seconds: float) -> void:
	_jacket_spinning = false
	var back := create_tween().set_parallel(true)
	back.tween_property(jacket, "global_position", jensen.global_position + Vector3(0, 1.3, 0), seconds).set_trans(Tween.TRANS_QUAD)
	back.tween_property(jacket, "scale", Vector3.ONE * 0.9, seconds)
	back.chain().tween_callback(func() -> void: jacket.visible = false)


func camera_move(to: Vector3, look: Vector3, seconds: float) -> void:
	track = null
	to += _origin # local to the stage set
	look += _origin
	var start := camera.global_position
	var start_look := start - camera.global_basis.z * 9.0
	var tween := create_tween()
	tween.tween_method(func(t: float) -> void:
		camera.global_position = start.lerp(to, t)
		camera.look_at(start_look.lerp(look, t)), 0.0, 1.0, seconds).set_trans(Tween.TRANS_SINE)


## Back in the fight: the opponent is a bit dizzy.
func aftermath() -> void:
	if is_instance_valid(defender) and defender.model:
		defender.model.flash(Color(0.1, 0.1, 0.12), 0.8)


# --- Tornado ----------------------------------------------------------------------------

func build_tornado() -> void:
	var shader := Shader.new()
	shader.code = VORTEX_SHADER
	var shell_specs := [
		[0.24, 1.55, 6.0, Color(0.05, 0.045, 0.055), Color(0.18, 0.11, 0.08), Color(0.48, 0.9, 0.1), 5.5, 4.0, 0.85],
		[0.42, 2.25, 6.2, Color(0.07, 0.06, 0.07), Color(0.28, 0.18, 0.11), Color(0.35, 0.78, 0.08), -4.2, 6.0, 0.65],
		[0.65, 2.85, 5.8, Color(0.09, 0.08, 0.09), Color(0.22, 0.15, 0.10), Color(0.55, 0.92, 0.15), 3.0, 3.0, 0.42],
	]
	for i in shell_specs.size():
		var spec: Array = shell_specs[i]
		var shell := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.bottom_radius = spec[0]
		cone.top_radius = spec[1]
		cone.height = spec[2]
		cone.radial_segments = 28
		cone.rings = 10
		cone.cap_top = false
		cone.cap_bottom = false
		shell.mesh = cone
		shell.position.y = spec[2] * 0.5 + 0.05
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("dark_col", spec[3])
		mat.set_shader_parameter("brown_col", spec[4])
		mat.set_shader_parameter("accent_col", spec[5])
		mat.set_shader_parameter("spin_speed", spec[6])
		mat.set_shader_parameter("twists", spec[7])
		mat.set_shader_parameter("density", spec[8])
		shell.material_override = mat
		shell.set_meta(&"index", i)
		tornado.add_child(shell)
		_shells.append(shell)

	var dark_leather := SuperStandins.metal(Color(0.09, 0.085, 0.095), 0.25, 0.35)
	var warm_leather := SuperStandins.metal(Color(0.24, 0.15, 0.10), 0.15, 0.45)
	var chrome := SuperStandins.metal(Color(0.78, 0.80, 0.84), 0.95, 0.22)
	var green_glow := SuperStandins.glow(Color(0.46, 0.82, 0.06), 1.6)
	for i in RING_COUNT:
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.90
		torus.outer_radius = 0.99
		torus.rings = 24
		torus.ring_segments = 6
		ring.mesh = torus
		ring.material_override = green_glow if i % 3 == 0 else dark_leather
		ring.set_meta(&"index", i)
		tornado.add_child(ring)
		_rings.append(ring)
	for i in BIT_COUNT:
		var bit := MeshInstance3D.new()
		var shape := BoxMesh.new()
		var is_zip := i % 7 == 0
		var is_spark := i % 5 == 0
		shape.size = Vector3(0.08, 0.04, 0.22) if is_zip else (Vector3(0.26, 0.03, 0.18) * (1.0 + (i % 3) * 0.35))
		bit.mesh = shape
		bit.material_override = chrome if is_zip else (green_glow if is_spark else (warm_leather if i % 2 == 0 else dark_leather))
		bit.set_meta(&"index", i)
		tornado.add_child(bit)
		_bits.append(bit)

	_vortex_particles = SuperStandins._particles(
		Color(0.45, 0.85, 0.1, 0.75), Color(0.14, 0.12, 0.14, 0.0),
		70, 0.9, 0.28, Vector3.UP * 5.5, 1.4, false
	)
	_vortex_particles.emitting = false
	_vortex_particles.position.y = 0.4
	tornado.add_child(_vortex_particles)


## Radius of the funnel at `t` (0 = floor, 1 = top).
func funnel_radius(t: float) -> float:
	return lerpf(0.28, 2.35, pow(t, 1.15))


func animate_tornado() -> void:
	for shell in _shells:
		var i: int = shell.get_meta(&"index")
		var dir := 1.0 if i % 2 == 0 else -0.8
		shell.rotation.y = _spin * (5.5 + i * 1.8) * dir
		shell.position.x = 0.18 * sin(_spin * 3.0 + i * 1.2)
		shell.position.z = 0.14 * cos(_spin * 3.0 + i * 1.2)
	for ring in _rings:
		var i: int = ring.get_meta(&"index")
		var t := float(i) / (RING_COUNT - 1)
		var radius := funnel_radius(t)
		var sway := 0.22 * sin(_spin * 3.0 + t * 5.0) * t
		ring.position = Vector3(sway, t * TORNADO_HEIGHT, 0.18 * cos(_spin * 3.0 + t * 5.0) * t)
		ring.scale = Vector3(radius, radius * 0.4, radius)
		ring.rotation = Vector3(0.16 * sin(_spin * 4.0 + i), _spin * (3.5 + t * 4.5) + i, 0.16 * cos(_spin * 3.0 + i))
	for bit in _bits:
		var i: int = bit.get_meta(&"index")
		var t := fposmod(float(i) / BIT_COUNT * 1.0 + _spin * 0.42 * (1.0 + (i % 3) * 0.3), 1.0)
		var angle := _spin * (7.0 - t * 2.2) + float(i) * 2.4
		var radius := funnel_radius(t) * 1.18
		bit.position = Vector3(cos(angle) * radius, t * TORNADO_HEIGHT, sin(angle) * radius)
		bit.rotation = Vector3(angle * 2.0, angle, 0.5)


func _impact_dust() -> GPUParticles3D:
	var dust := SuperStandins._particles(
		Color(0.32, 0.28, 0.25, 0.32), Color(0.18, 0.16, 0.15, 0.0),
		24, 0.7, 0.42, Vector3(0, 1.4, 0), 1.4, false
	)
	dust.one_shot = true
	return dust


# --- Stand-ins -------------------------------------------------------------------------

## An open black leather jacket: back, two front flaps, two sleeves, collar, a zip line.
## ~1.2 m across with the sleeves out. Front = +Z.
static func leather_jacket() -> Node3D:
	var root := Node3D.new()
	root.name = "LeatherJacket"
	var leather := SuperStandins.metal(Color(0.1, 0.1, 0.12), 0.35, 0.3)
	root.add_child(SuperStandins.box(Vector3(0.7, 0.85, 0.08), Vector3(0, 0, -0.1), leather, "Back"))
	for side in [-1.0, 1.0]:
		var flap := SuperStandins.box(Vector3(0.32, 0.85, 0.07), Vector3(0.3 * side, 0, 0.1), leather, "Front")
		flap.rotation.y = -0.45 * side
		root.add_child(flap)
		var sleeve := SuperStandins.box(Vector3(0.22, 0.75, 0.2), Vector3(0.62 * side, -0.1, -0.02), leather, "Sleeve")
		sleeve.rotation.z = 0.9 * side
		sleeve.position = Vector3(0.78 * side, 0.15, -0.02)
		root.add_child(sleeve)
		var collar := SuperStandins.box(Vector3(0.22, 0.18, 0.1), Vector3(0.14 * side, 0.45, 0.02), leather, "Collar")
		collar.rotation.z = 0.35 * side
		root.add_child(collar)
		root.add_child(SuperStandins.box(Vector3(0.03, 0.8, 0.02), Vector3(0.16 * side, 0, 0.17), SuperStandins.metal(Color(0.75, 0.77, 0.8), 1.0, 0.25), "Zip"))
	return root
