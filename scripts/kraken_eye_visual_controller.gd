extends Node

const LEG_ANIMATION := &"leg_animations"
const WING_ANIMATION := &"flutter"
const EYE_ROOT_PATH := "Sketchfab_model/root/GLTF_SceneRootNode/eye-kraken_1"
const MODEL_ROOT_PATHS := [
	"Sketchfab_model",
	EYE_ROOT_PATH,
]

const LEGS_PATHS := [
	"legs",
	EYE_ROOT_PATH + "/legs",
]
const WINGS_PATHS := [
	"wings",
	EYE_ROOT_PATH + "/wings",
]
const LEG_PLAYER_PATHS := [
	"AnimationPlayer",
	EYE_ROOT_PATH + "/AnimationPlayer",
]
const WING_PLAYER_PATHS := [
	"wings/AnimationPlayer",
	EYE_ROOT_PATH + "/wings/AnimationPlayer",
]

@export var backflip_duration: float = 0.42
@export var backflip_turns: float = 1.0
@export var backflip_hop_height: float = 0.42
@export var backflip_wing_speed_scale: float = 3.0
@export var backflip_leg_speed_scale: float = 1.9

@onready var boid := get_parent() as CharacterBody3D
@onready var model_root := _find_node(MODEL_ROOT_PATHS) as Node3D
@onready var eye_root := boid.get_node_or_null(EYE_ROOT_PATH) as Node3D
@onready var legs_root := _find_node(LEGS_PATHS) as Node3D
@onready var wings_root := _find_node(WINGS_PATHS) as Node3D
@onready var leg_player := _find_node(LEG_PLAYER_PATHS) as AnimationPlayer
@onready var wing_player := _find_node(WING_PLAYER_PATHS) as AnimationPlayer

var last_on_floor: bool = false
var state_applied: bool = false
var backflip_time_left: float = 0.0
var flip_root_base_position: Vector3 = Vector3.ZERO
var flip_root_base_rotation: Vector3 = Vector3.ZERO
var legs_root_base_rotation: Vector3 = Vector3.ZERO
var wings_root_base_rotation: Vector3 = Vector3.ZERO

func _find_node(paths: Array) -> Node:
	for path in paths:
		var node = boid.get_node_or_null(path)
		if node:
			return node
	return null

func _ready() -> void:
	if eye_root:
		if legs_root and legs_root.get_parent() != eye_root:
			legs_root.reparent(eye_root, false)
		if wings_root and wings_root.get_parent() != eye_root:
			wings_root.reparent(eye_root, false)
		if leg_player and leg_player.get_parent() != eye_root:
			leg_player.reparent(eye_root, false)

	if legs_root:
		for shape in legs_root.find_children("*", "CollisionShape3D", true, false):
			shape.disabled = true

	_cache_backflip_pose()
	_reset_backflip_pose()

	if leg_player:
		leg_player.play(LEG_ANIMATION)

func _get_flip_root() -> Node3D:
	if model_root:
		return model_root
	if eye_root:
		return eye_root
	return null

func _cache_backflip_pose() -> void:
	var flip_root := _get_flip_root()
	if flip_root:
		flip_root_base_position = flip_root.position
		flip_root_base_rotation = flip_root.rotation
	if legs_root:
		legs_root_base_rotation = legs_root.rotation
	if wings_root:
		wings_root_base_rotation = wings_root.rotation

func play_return_celebration() -> void:
	_cache_backflip_pose()
	backflip_time_left = backflip_duration

func _reset_backflip_pose() -> void:
	var flip_root := _get_flip_root()
	if flip_root:
		flip_root.position = flip_root_base_position
		flip_root.rotation = flip_root_base_rotation
	if legs_root:
		legs_root.rotation = legs_root_base_rotation
	if wings_root:
		wings_root.rotation = wings_root_base_rotation

func _apply_backflip_pose() -> void:
	var flip_root := _get_flip_root()
	if flip_root == null:
		return

	var duration: float = max(backflip_duration, 0.001)
	var progress: float = clamp(1.0 - (backflip_time_left / duration), 0.0, 1.0)
	var hop_arc: float = sin(progress * PI)
	var flip_angle: float = -TAU * backflip_turns * progress
	var tuck_amount: float = sin(progress * PI)

	flip_root.position = flip_root_base_position + Vector3(0.0, hop_arc * backflip_hop_height, 0.0)
	flip_root.rotation = flip_root_base_rotation + Vector3(flip_angle, 0.0, 0.0)

	if legs_root:
		legs_root.rotation = legs_root_base_rotation + Vector3(deg_to_rad(22.0) * tuck_amount, 0.0, 0.0)

	if wings_root:
		wings_root.rotation = wings_root_base_rotation + Vector3(0.0, 0.0, deg_to_rad(18.0) * tuck_amount)

func _physics_process(_delta: float) -> void:
	if boid == null:
		return

	var backflipping: bool = backflip_time_left > 0.0
	if backflipping:
		backflip_time_left = max(backflip_time_left - _delta, 0.0)
		_apply_backflip_pose()
	else:
		_reset_backflip_pose()

	if leg_player:
		if leg_player.current_animation != StringName(LEG_ANIMATION):
			leg_player.play(LEG_ANIMATION)
		leg_player.speed_scale = backflip_leg_speed_scale if backflipping else 1.0

	if backflipping and wing_player:
		wing_player.speed_scale = backflip_wing_speed_scale
		if wing_player.current_animation != StringName(WING_ANIMATION) or not wing_player.is_playing():
			wing_player.play(WING_ANIMATION)
		state_applied = false
		last_on_floor = boid.is_on_floor()
		return

	var on_floor: bool = boid.is_on_floor()
	if state_applied and on_floor == last_on_floor:
		return

	if wing_player:
		if on_floor:
			wing_player.speed_scale = 1.0
			wing_player.stop()
		else:
			wing_player.speed_scale = 1.0
			wing_player.play(WING_ANIMATION)

	last_on_floor = on_floor
	state_applied = true
