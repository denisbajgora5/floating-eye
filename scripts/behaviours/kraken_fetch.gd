class_name KrakenFetch
extends SteeringBehavior

enum FetchState { IDLE, FETCHING, RETURNING }

@export var player_path: NodePath
@export var ball_path: NodePath
@export var wander_behavior_path: NodePath = NodePath("../Wander")
@export var grab_distance: float = 2.0
@export var ball_arrive_radius: float = 7.5
@export var player_arrive_radius: float = 9.0
@export var player_follow_height: float = 3.0
@export var player_follow_side_offset: float = 1.8
@export var player_follow_back_offset: float = 1.1
@export var carried_ball_forward_offset: float = 0.7
@export var carried_ball_down_offset: float = 1.25
@export var ball_chase_height_offset: float = 0.35

var current_state: int = FetchState.IDLE
var player: Node3D = null
var ball: ThrowableBall = null
var wander_behavior: SteeringBehavior = null


func _ready() -> void:
	boid = get_parent()
	wander_behavior = _resolve_wander_behavior()
	call_deferred("_resolve_dependencies")


func calculate() -> Vector3:
	if boid == null:
		boid = get_parent()

	if player == null or ball == null:
		_resolve_dependencies()
		return Vector3.ZERO

	match current_state:
		FetchState.FETCHING:
			if not ball.is_free():
				_set_state(FetchState.RETURNING if ball.is_held_by(boid) else FetchState.IDLE)
				return Vector3.ZERO

			if boid.global_position.distance_to(ball.global_position) <= grab_distance:
				_grab_ball()
				return Vector3.ZERO

			return boid.arrive_force(_ball_target_position(), ball_arrive_radius)
		FetchState.RETURNING:
			if not ball.is_held_by(boid):
				_set_state(FetchState.IDLE)
				return Vector3.ZERO

			_carry_ball()
			return boid.arrive_force(_player_follow_position(), player_arrive_radius)
		_:
			return Vector3.ZERO


func _resolve_dependencies() -> void:
	if player == null:
		player = _find_player()

	if ball == null:
		ball = _find_ball()
		if ball:
			_connect_ball_signals()

	if wander_behavior == null:
		wander_behavior = _resolve_wander_behavior()

	if ball and ball.is_held_by(boid):
		_set_state(FetchState.RETURNING)
	elif ball and player and ball.is_held_by(player):
		_set_state(FetchState.IDLE)


func _find_player() -> Node3D:
	if not player_path.is_empty():
		return get_node_or_null(player_path) as Node3D

	var current_scene := get_tree().current_scene
	if current_scene:
		return current_scene.find_child("Player", true, false) as Node3D

	return null


func _find_ball() -> ThrowableBall:
	if not ball_path.is_empty():
		return get_node_or_null(ball_path) as ThrowableBall

	var current_scene := get_tree().current_scene
	if current_scene:
		return current_scene.find_child("Ball", true, false) as ThrowableBall

	return null


func _resolve_wander_behavior() -> SteeringBehavior:
	if not wander_behavior_path.is_empty():
		return get_node_or_null(wander_behavior_path) as SteeringBehavior

	return boid.get_node_or_null("Wander") as SteeringBehavior


func _connect_ball_signals() -> void:
	var thrown_callable := Callable(self, "_on_ball_thrown")
	if not ball.thrown.is_connected(thrown_callable):
		ball.thrown.connect(thrown_callable)

	var picked_up_callable := Callable(self, "_on_ball_picked_up")
	if not ball.picked_up.is_connected(picked_up_callable):
		ball.picked_up.connect(picked_up_callable)

	var carried_callable := Callable(self, "_on_ball_carried")
	if not ball.carried.is_connected(carried_callable):
		ball.carried.connect(carried_callable)


func _set_state(new_state: int) -> void:
	if current_state == new_state:
		return

	current_state = new_state
	if wander_behavior:
		wander_behavior.enabled = current_state == FetchState.IDLE


func _on_ball_thrown(thrower: Node3D) -> void:
	if thrower == player:
		_set_state(FetchState.FETCHING)


func _on_ball_picked_up(holder: Node3D) -> void:
	if holder == player:
		_set_state(FetchState.IDLE)
	elif holder == boid:
		_set_state(FetchState.RETURNING)
	else:
		_set_state(FetchState.IDLE)


func _on_ball_carried(carrier: Node3D) -> void:
	_set_state(FetchState.RETURNING if carrier == boid else FetchState.IDLE)


func _grab_ball() -> void:
	if ball == null:
		return

	ball.freeze = true
	ball.sleeping = false
	ball.collision_layer = 0
	ball.collision_mask = 0
	ball.notify_carried(boid)
	_carry_ball()
	_set_state(FetchState.RETURNING)


func _carry_ball() -> void:
	if ball == null or boid == null:
		return

	var forward: Vector3 = -boid.global_basis.z.normalized()
	ball.global_position = boid.global_position + forward * carried_ball_forward_offset + Vector3.DOWN * carried_ball_down_offset
	ball.global_basis = Basis.IDENTITY
	ball.linear_velocity = Vector3.ZERO
	ball.angular_velocity = Vector3.ZERO


func _ball_target_position() -> Vector3:
	return ball.global_position + Vector3.UP * ball_chase_height_offset


func _player_follow_position() -> Vector3:
	var player_basis: Basis = player.global_basis
	return player.global_position + player_basis.x * player_follow_side_offset - player_basis.z * player_follow_back_offset + Vector3.UP * player_follow_height
