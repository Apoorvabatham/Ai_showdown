class_name StageEvents
extends Node3D
## Scripted stage events for StageCrowd (the "events" of the stage-life JSON). Cosmetic only.
## Each event is a name; run() returns false for an unknown one. Missing sound files are
## skipped silently.

const NAMES: Array[StringName] = [&"camera_flashes", &"gavel", &"food_fight", &"sparks", &"spark_shower",
	&"steam_burst", &"alarm"]
const DEFAULT_SPOT := Vector3(0.0, 3.2, -5.0)

var crowd: StageCrowd
var runs := 0 # events started (tests)
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.randomize()


func run(event: StringName, at := Vector3.INF) -> bool:
	match event:
		&"camera_flashes": _camera_flashes()
		&"gavel": _gavel()
		&"food_fight": _food_fight()
		&"sparks", &"spark_shower": _sparks(at)
		&"steam_burst": _steam(at)
		&"alarm": _alarm(at)
		_:
			return false
	runs += 1
	return true


func _spots(role := "") -> Array[Vector3]:
	var spots: Array[Vector3] = []
	if crowd:
		for actor in crowd.actors:
			if role == "" or actor.role == role:
				spots.append(actor.position + Vector3(0, actor.head_height, 0))
		if spots.is_empty() and role != "":
			return _spots()
	if spots.is_empty():
		spots.append(DEFAULT_SPOT)
	return spots


func _camera_flashes() -> void:
	var spots := _spots("press")
	for i in 5:
		var spot := spots[_rng.randi() % spots.size()] + Vector3(_rng.randf_range(-0.3, 0.3), 0.1, 0.4)
		var timer := get_tree().create_timer(i * _rng.randf_range(0.06, 0.16))
		timer.timeout.connect(func() -> void: _flash(spot))


func _flash(spot: Vector3) -> void:
	if not is_inside_tree():
		return
	var light := OmniLight3D.new()
	light.light_color = Color(0.95, 0.97, 1.0)
	light.light_energy = 6.0
	light.omni_range = 5.0
	light.shadow_enabled = false
	light.position = spot
	add_child(light)
	var tween := create_tween()
	tween.tween_property(light, "light_energy", 0.0, 0.12)
	tween.tween_callback(light.queue_free)


func _gavel() -> void:
	var path := "res://assets/audio/stage/%s/gavel.ogg" % (crowd.stage_name if crowd else "")
	if ResourceLoader.exists(path):
		var stream := load(path) as AudioStream
		if stream:
			var player := AudioStreamPlayer.new()
			player.stream = stream
			player.volume_db = -4.0
			add_child(player)
			player.finished.connect(player.queue_free)
			player.play()
	if crowd:
		var chair := crowd.actor_with_role("chair")
		if chair:
			chair.react(&"gavel")
		crowd.shout_line("Order!", "gavel", chair)


func _food_fight() -> void:
	var from := _spots()
	for i in 6:
		var mesh := MeshInstance3D.new()
		if i % 2 == 0:
			var box := BoxMesh.new()
			box.size = Vector3.ONE * 0.14
			mesh.mesh = box
		else:
			var ball := SphereMesh.new()
			ball.radius = 0.07
			ball.height = 0.14
			mesh.mesh = ball
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color.from_hsv(_rng.randf(), 0.5, 0.85)
		mesh.material_override = mat
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var start := from[_rng.randi() % from.size()] - Vector3(0, 0.3, 0)
		var end := Vector3(_rng.randf_range(-7.0, 7.0), 0.1, _rng.randf_range(-6.0, -3.0))
		var apex := _rng.randf_range(1.5, 2.8)
		mesh.position = start
		add_child(mesh)
		var tween := create_tween()
		tween.tween_interval(i * 0.1)
		var fly := func(t: float) -> void:
			var p := start.lerp(end, t)
			p.y += sin(t * PI) * apex
			mesh.position = p
			mesh.rotation += Vector3(0.3, 0.2, 0.1) * 0.05
		tween.tween_method(fly, 0.0, 1.0, _rng.randf_range(0.9, 1.3))
		tween.tween_callback(mesh.queue_free)


func _particles(at: Vector3, amount: int, lifetime: float, mesh: Mesh, color: Color, velocity: Vector2, gravity: Vector3, spread: float, up := Vector3.UP) -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	var mat := ParticleProcessMaterial.new()
	mat.direction = up
	mat.spread = spread
	mat.initial_velocity_min = velocity.x
	mat.initial_velocity_max = velocity.y
	mat.gravity = gravity
	mat.color = color
	mat.scale_min = 0.6
	mat.scale_max = 1.2
	particles.process_material = mat
	particles.draw_pass_1 = mesh
	particles.amount = amount
	particles.lifetime = lifetime
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.emitting = true
	particles.position = at
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(particles)
	get_tree().create_timer(lifetime + 0.5).timeout.connect(particles.queue_free)
	return particles


func _unshaded(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.vertex_color_use_as_albedo = true
	return mat


func _sparks(at: Vector3) -> void:
	var spot := at if at != Vector3.INF else _spots()[_rng.randi() % _spots().size()] + Vector3(0, 0.6, 0)
	var mesh := SphereMesh.new()
	mesh.radius = 0.025
	mesh.height = 0.05
	mesh.material = _unshaded(Color(1.0, 0.75, 0.3))
	_particles(spot, 40, 1.2, mesh, Color(1.0, 0.8, 0.35), Vector2(2.0, 5.0), Vector3(0, -9.0, 0), 70.0)


func _steam(at: Vector3) -> void:
	var spot := at if at != Vector3.INF else Vector3(_rng.randf_range(-6.0, 6.0), 0.2, -4.5)
	var mesh := SphereMesh.new()
	mesh.radius = 0.25
	mesh.height = 0.5
	var mat := _unshaded(Color(0.9, 0.92, 0.95, 0.35))
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material = mat
	_particles(spot, 18, 1.8, mesh, Color(1, 1, 1, 0.5), Vector2(1.0, 2.2), Vector3(0, 0.6, 0), 18.0)


func _alarm(at: Vector3) -> void:
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.1, 0.08)
	light.omni_range = 9.0
	light.light_energy = 0.0
	light.shadow_enabled = false
	light.position = at if at != Vector3.INF else DEFAULT_SPOT
	add_child(light)
	var tween := create_tween()
	for i in 3:
		tween.tween_property(light, "light_energy", 5.0, 0.3)
		tween.tween_property(light, "light_energy", 0.4, 0.3)
	tween.tween_callback(light.queue_free)
