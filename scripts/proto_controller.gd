# ProtoController v1.0 by Brackeys
# CC0 License
# Intended for rapid prototyping of first-person games.
# Happy prototyping!

extends CharacterBody3D

## Can we move around?
@export var can_move : bool = true
## Are we affected by gravity?
@export var has_gravity : bool = true
## Can we press to jump?
@export var can_jump : bool = true
## Can we hold to run?
@export var can_sprint : bool = false
## Can we press to enter freefly mode (noclip)?
@export var can_freefly : bool = false

@export_group("Speeds")
## Look around rotation speed.
@export var look_speed : float = 0.002
## Normal speed.
@export var base_speed : float = 7.0
## Speed of jump.
@export var jump_velocity : float = 4.5
## How fast do we run?
@export var sprint_speed : float = 10.0
## How fast do we freefly?
@export var freefly_speed : float = 25.0

@export_group("Fall Reset")
## Teleport back after falling this far below the respawn height.
@export var fall_reset_enabled : bool = true
@export var fall_reset_distance : float = 25.0
## Optional GridMap used to derive the center of the map for respawning.
@export var respawn_map_path : NodePath

@export_group("Input Actions")
## Name of Input Action to move Left.
@export var input_left : String = "ui_left"
## Name of Input Action to move Right.
@export var input_right : String = "ui_right"
## Name of Input Action to move Forward.
@export var input_forward : String = "ui_up"
## Name of Input Action to move Backward.
@export var input_back : String = "ui_down"
## Name of Input Action to Jump.
@export var input_jump : String = "ui_accept"
## Name of Input Action to Sprint.
@export var input_sprint : String = "sprint"
## Name of Input Action to toggle freefly mode.
@export var input_freefly : String = "freefly"
## Name of Input Action to pick up or throw the ball.
@export var input_throw_ball : String = "throw_ball"

@export_group("Ball")
## Can the player carry and throw the ball?
@export var can_throw_ball : bool = true
## How far in front of the camera the ball is held.
@export var ball_hold_distance : float = 1.35
## Small vertical offset so the held ball stays below the crosshair.
@export var ball_hold_height : float = -0.3
## Maximum distance for picking the ball back up.
@export var ball_pickup_distance : float = 2.2
## Initial throw speed for the ball.
@export var ball_throw_speed : float = 18.0
## Spin applied when the ball is thrown.
@export var ball_spin_speed : float = 10.0

var mouse_captured : bool = false
var look_rotation : Vector2
var move_speed : float = 0.0
var freeflying : bool = false
var respawn_position : Vector3 = Vector3.ZERO
var holding_ball : bool = false
var ball_collision_layer : int = 0
var ball_collision_mask : int = 0

## IMPORTANT REFERENCES
@onready var head: Node3D = $Head
@onready var collider: CollisionShape3D = $Collider
@onready var hold_point := get_node_or_null("Head/BallHoldPoint") as Node3D
@onready var ball := get_node_or_null("Ball") as RigidBody3D

func _ready() -> void:
	check_input_mappings()
	look_rotation.y = rotation.y
	look_rotation.x = head.rotation.x
	_configure_respawn_position()
	_configure_ball()

func _unhandled_input(event: InputEvent) -> void:
	# Mouse capturing
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		capture_mouse()
	if Input.is_key_pressed(KEY_ESCAPE):
		release_mouse()
	
	# Look around
	if mouse_captured and event is InputEventMouseMotion:
		rotate_look(event.relative)
	
	# Toggle freefly mode
	if can_freefly and Input.is_action_just_pressed(input_freefly):
		if not freeflying:
			enable_freefly()
		else:
			disable_freefly()

func _physics_process(delta: float) -> void:
	if _should_reset_after_fall():
		_reset_after_fall()
		return

	# If freeflying, handle freefly and nothing else
	if can_freefly and freeflying:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		var motion := (head.global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		motion *= freefly_speed * delta
		move_and_collide(motion)
		_update_ball_state()
		return
	
	# Apply gravity to velocity
	if has_gravity:
		if not is_on_floor():
			velocity += get_gravity() * delta

	# Apply jumping
	if can_jump:
		if Input.is_action_just_pressed(input_jump) and is_on_floor():
			velocity.y = jump_velocity

	# Modify speed based on sprinting
	if can_sprint and Input.is_action_pressed(input_sprint):
			move_speed = sprint_speed
	else:
		move_speed = base_speed

	# Apply desired movement to velocity
	if can_move:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		var move_dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if move_dir:
			velocity.x = move_dir.x * move_speed
			velocity.z = move_dir.z * move_speed
		else:
			velocity.x = move_toward(velocity.x, 0, move_speed)
			velocity.z = move_toward(velocity.z, 0, move_speed)
	else:
		velocity.x = 0
		velocity.y = 0
	
	# Use velocity to actually move
	move_and_slide()

	_update_ball_state()

	if _should_reset_after_fall():
		_reset_after_fall()


## Rotate us to look around.
## Base of controller rotates around y (left/right). Head rotates around x (up/down).
## Modifies look_rotation based on rot_input, then resets basis and rotates by look_rotation.
func rotate_look(rot_input : Vector2):
	look_rotation.x -= rot_input.y * look_speed
	look_rotation.x = clamp(look_rotation.x, deg_to_rad(-85), deg_to_rad(85))
	look_rotation.y -= rot_input.x * look_speed
	transform.basis = Basis()
	rotate_y(look_rotation.y)
	head.transform.basis = Basis()
	head.rotate_x(look_rotation.x)


func enable_freefly():
	collider.disabled = true
	freeflying = true
	velocity = Vector3.ZERO

func disable_freefly():
	collider.disabled = false
	freeflying = false


func capture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true


func release_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false


func _configure_ball() -> void:
	if not can_throw_ball:
		return

	if hold_point == null or ball == null:
		push_error("Ball disabled. Missing Ball or Head/BallHoldPoint on the player scene.")
		can_throw_ball = false
		return

	hold_point.position = Vector3(0.0, ball_hold_height, -ball_hold_distance)
	ball.top_level = true
	ball_collision_layer = ball.collision_layer
	ball_collision_mask = ball.collision_mask
	_pick_up_ball()


func _configure_respawn_position() -> void:
	respawn_position = global_position

	var grid_map := _find_respawn_grid_map()
	if grid_map == null:
		return

	var map_center := _get_grid_map_center(grid_map)
	respawn_position.x = map_center.x
	respawn_position.z = map_center.z


func _find_respawn_grid_map() -> GridMap:
	if not respawn_map_path.is_empty():
		var configured_grid_map := get_node_or_null(respawn_map_path) as GridMap
		if configured_grid_map:
			return configured_grid_map

	var current_scene := get_tree().current_scene
	if current_scene:
		return current_scene.find_child("GridMap", true, false) as GridMap

	return null


func _get_grid_map_center(grid_map: GridMap) -> Vector3:
	var used_cells := grid_map.get_used_cells()
	if used_cells.is_empty():
		return respawn_position

	var min_cell: Vector3i = used_cells[0]
	var max_cell: Vector3i = used_cells[0]

	for cell in used_cells:
		min_cell.x = mini(min_cell.x, cell.x)
		min_cell.y = mini(min_cell.y, cell.y)
		min_cell.z = mini(min_cell.z, cell.z)
		max_cell.x = maxi(max_cell.x, cell.x)
		max_cell.y = maxi(max_cell.y, cell.y)
		max_cell.z = maxi(max_cell.z, cell.z)

	# Average the outermost used cell centers so respawn stays centered even if the map grows.
	var min_world := grid_map.to_global(grid_map.map_to_local(min_cell))
	var max_world := grid_map.to_global(grid_map.map_to_local(max_cell))
	return (min_world + max_world) * 0.5


func _should_reset_after_fall() -> bool:
	if not fall_reset_enabled or freeflying:
		return false

	return global_position.y <= respawn_position.y - fall_reset_distance


func _reset_after_fall() -> void:
	global_position = respawn_position
	velocity = Vector3.ZERO
	if holding_ball:
		_sync_held_ball()


func _update_ball_state() -> void:
	if not can_throw_ball or ball == null or hold_point == null:
		return

	if Input.is_action_just_pressed(input_throw_ball):
		if holding_ball:
			_throw_ball()
		elif _can_pick_up_ball():
			_pick_up_ball()

	if holding_ball:
		_sync_held_ball()
	elif _ball_is_lost():
		_pick_up_ball()


func _sync_held_ball() -> void:
	if ball == null or hold_point == null:
		return

	ball.global_position = hold_point.global_position
	ball.global_basis = Basis.IDENTITY
	ball.linear_velocity = Vector3.ZERO
	ball.angular_velocity = Vector3.ZERO


func _pick_up_ball() -> void:
	if ball == null:
		return

	holding_ball = true
	ball.freeze = true
	ball.sleeping = false
	ball.collision_layer = 0
	ball.collision_mask = 0
	_sync_held_ball()


func _throw_ball() -> void:
	if ball == null or hold_point == null:
		return

	holding_ball = false

	var throw_direction := -head.global_basis.z.normalized()
	ball.global_position = hold_point.global_position + throw_direction * 0.35
	ball.freeze = false
	ball.sleeping = false
	ball.collision_layer = ball_collision_layer
	ball.collision_mask = ball_collision_mask
	ball.linear_velocity = throw_direction * ball_throw_speed + velocity
	ball.angular_velocity = head.global_basis.x * ball_spin_speed + Vector3.UP * (ball_spin_speed * 0.35)


func _can_pick_up_ball() -> bool:
	if ball == null or hold_point == null:
		return false

	return ball.global_position.distance_to(hold_point.global_position) <= ball_pickup_distance


func _ball_is_lost() -> bool:
	if ball == null:
		return false

	return ball.global_position.y <= respawn_position.y - fall_reset_distance - 10.0


## Checks if some Input Actions haven't been created.
## Disables functionality accordingly.
func check_input_mappings():
	if can_move and not InputMap.has_action(input_left):
		push_error("Movement disabled. No InputAction found for input_left: " + input_left)
		can_move = false
	if can_move and not InputMap.has_action(input_right):
		push_error("Movement disabled. No InputAction found for input_right: " + input_right)
		can_move = false
	if can_move and not InputMap.has_action(input_forward):
		push_error("Movement disabled. No InputAction found for input_forward: " + input_forward)
		can_move = false
	if can_move and not InputMap.has_action(input_back):
		push_error("Movement disabled. No InputAction found for input_back: " + input_back)
		can_move = false
	if can_jump and not InputMap.has_action(input_jump):
		push_error("Jumping disabled. No InputAction found for input_jump: " + input_jump)
		can_jump = false
	if can_sprint and not InputMap.has_action(input_sprint):
		push_error("Sprinting disabled. No InputAction found for input_sprint: " + input_sprint)
		can_sprint = false
	if can_freefly and not InputMap.has_action(input_freefly):
		push_error("Freefly disabled. No InputAction found for input_freefly: " + input_freefly)
		can_freefly = false
	if can_throw_ball and not InputMap.has_action(input_throw_ball):
		push_error("Ball throwing disabled. No InputAction found for input_throw_ball: " + input_throw_ball)
		can_throw_ball = false
