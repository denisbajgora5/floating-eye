class_name Avoidance extends SteeringBehavior

enum ForceDirection {Normal, Incident, Up, Braking}
@export var direction = ForceDirection.Normal
@export var feeler_angle = 45.0
@export var feeler_length = 10.0
@export var feeler_origin_offset = 0.6
@export var speed_probe_scale = 1.5
@export var lateral_force = 1.6
@export var braking_force = 0.5
@export var updates_per_second = 12.0

var force = Vector3.ZERO
var feelers = []
var space_state
var needs_updating = true
var current_feeler_length = 0.0

func on_draw_gizmos():
	for feeler in feelers:
		if feeler["hit"]:
			DebugDraw3D.draw_line(feeler["start"], feeler["hit_target"], Color.CHARTREUSE)
			DebugDraw3D.draw_arrow(feeler["hit_target"], feeler["hit_target"] + feeler["normal"], Color.BLUE, 0.1)
			DebugDraw3D.draw_arrow(feeler["hit_target"], feeler["hit_target"] + feeler["force"] * weight, Color.RED, 0.1)
		else:
			DebugDraw3D.draw_line(feeler["start"], feeler["end"], Color.CHARTREUSE)

func start_updating():
	var timer = get_child(0) as Timer
	var start_callable = Callable(self, "start_updating")
	var update_callable = Callable(self, "on_needs_updating")

	if timer.is_connected("timeout", start_callable):
		timer.disconnect("timeout", start_callable)

	timer.wait_time = 1.0 / max(updates_per_second, 1.0)
	if not timer.is_connected("timeout", update_callable):
		timer.connect("timeout", update_callable)

	timer.one_shot = false
	timer.start()

func on_needs_updating():
	needs_updating = true

func _physics_process(delta):
	if needs_updating:
		update_feelers()
		needs_updating = false

func _forward_vector() -> Vector3:
	var forward = boid.global_transform.basis * Vector3.BACK
	if forward.length_squared() < 0.0001:
		return Vector3.BACK
	return forward.normalized()

func _probe_length() -> float:
	var current_speed = max(boid.velocity.length(), boid.vel.length())
	return max(feeler_length, current_speed * speed_probe_scale)

func _make_probe(local_origin: Vector3, local_direction: Vector3, length_scale: float, steer_hint: Vector3) -> Dictionary:
	return {
		"origin": local_origin,
		"direction": local_direction.normalized(),
		"length": current_feeler_length * length_scale,
		"steer_hint": steer_hint.normalized() if steer_hint.length_squared() > 0.0 else Vector3.ZERO,
	}

func _recovery_force(to_boid: Vector3, normal: Vector3, strength: float) -> Vector3:
	match direction:
		ForceDirection.Normal:
			return normal * strength
		ForceDirection.Incident:
			return to_boid.reflect(normal).normalized() * strength
		ForceDirection.Up:
			return Vector3.UP * strength
		ForceDirection.Braking:
			return to_boid.normalized() * strength
	return Vector3.ZERO

func _lateral_force(normal: Vector3, forward: Vector3, steer_hint: Vector3, hit_target: Vector3) -> Vector3:
	var lateral = normal.slide(forward)
	if lateral.length_squared() > 0.0001:
		return lateral.normalized()

	if steer_hint.length_squared() > 0.0:
		return (boid.global_transform.basis * steer_hint).normalized()

	var local_hit = boid.to_local(hit_target)
	if abs(local_hit.y) > abs(local_hit.x):
		var vertical_sign = -sign(local_hit.y)
		if not is_zero_approx(vertical_sign):
			return (boid.global_transform.basis.y * vertical_sign).normalized()

	var horizontal_sign = -sign(local_hit.x)
	if is_zero_approx(horizontal_sign):
		horizontal_sign = 1.0
	return (boid.global_transform.basis.x * horizontal_sign).normalized()

func feel(probe: Dictionary) -> Dictionary:
	var local_origin: Vector3 = probe["origin"]
	var local_direction: Vector3 = probe["direction"]
	var probe_length: float = probe["length"]
	var steer_hint: Vector3 = probe["steer_hint"]
	var start = boid.global_transform * local_origin
	var world_direction = (boid.global_transform.basis * local_direction).normalized()
	var ray_end = start + world_direction * probe_length
	var query = PhysicsRayQueryParameters3D.create(start, ray_end, boid.collision_mask, [boid.get_rid()])
	query.hit_from_inside = false
	var result = space_state.intersect_ray(query)

	var feeler = {
		"start": start,
		"end": ray_end,
		"hit": false,
		"hit_target": ray_end,
		"normal": Vector3.ZERO,
		"force": Vector3.ZERO,
	}

	if not result.is_empty():
		var hit_target: Vector3 = result["position"]
		var normal: Vector3 = result["normal"]
		var hit_distance = start.distance_to(hit_target)
		var strength = clamp((probe_length - hit_distance) / max(probe_length, 0.001), 0.0, 1.0)
		var forward = _forward_vector()
		var to_boid = boid.global_transform.origin - hit_target
		var sidestep = _lateral_force(normal, forward, steer_hint, hit_target) * lateral_force * strength
		var braking = -forward * braking_force * strength
		var recovery = _recovery_force(to_boid, normal, strength)

		feeler["hit"] = true
		feeler["hit_target"] = hit_target
		feeler["normal"] = normal
		feeler["force"] = sidestep + braking + recovery
		force += feeler["force"]

	return feeler

func update_feelers():
	current_feeler_length = _probe_length()
	force = Vector3.ZERO
	feelers.clear()
	var forward = Vector3.BACK
	var left_dir = forward.rotated(Vector3.UP, deg_to_rad(-feeler_angle))
	var right_dir = forward.rotated(Vector3.UP, deg_to_rad(feeler_angle))
	var up_dir = forward.rotated(Vector3.RIGHT, deg_to_rad(feeler_angle))
	var down_dir = forward.rotated(Vector3.RIGHT, deg_to_rad(-feeler_angle))
	var probes = [
		_make_probe(Vector3.ZERO, forward, 1.35, Vector3.ZERO),
		_make_probe(Vector3.ZERO, left_dir, 1.0, Vector3.RIGHT),
		_make_probe(Vector3.ZERO, right_dir, 1.0, Vector3.LEFT),
		_make_probe(Vector3.ZERO, up_dir, 1.0, -Vector3.UP),
		_make_probe(Vector3.ZERO, down_dir, 1.0, Vector3.UP),
		_make_probe(Vector3.LEFT * feeler_origin_offset, forward, 0.85, Vector3.RIGHT),
		_make_probe(Vector3.RIGHT * feeler_origin_offset, forward, 0.85, Vector3.LEFT),
		_make_probe(Vector3.UP * feeler_origin_offset, forward, 0.75, -Vector3.UP),
		_make_probe(-Vector3.UP * feeler_origin_offset, forward, 0.75, Vector3.UP),
	]

	for probe in probes:
		feelers.push_back(feel(probe))

func calculate():
	return force

func _ready():
	boid = get_parent()
	space_state = boid.get_world_3d().direct_space_state

	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = randf_range(0.0, 1.0 / max(updates_per_second, 1.0))
	timer.one_shot = true
	timer.connect("timeout", Callable(self, "start_updating"))
	timer.start()
