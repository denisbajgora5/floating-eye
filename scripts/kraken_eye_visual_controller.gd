extends Node

const LEG_ANIMATION := &"leg_animations"
const WING_ANIMATION := &"flutter"
const EYE_ROOT_PATH := "Sketchfab_model/root/GLTF_SceneRootNode/eye-kraken_1"

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

@onready var boid := get_parent() as CharacterBody3D
@onready var eye_root := boid.get_node_or_null(EYE_ROOT_PATH) as Node3D
@onready var legs_root := _find_node(LEGS_PATHS) as Node3D
@onready var wings_root := _find_node(WINGS_PATHS) as Node3D
@onready var leg_player := _find_node(LEG_PLAYER_PATHS) as AnimationPlayer
@onready var wing_player := _find_node(WING_PLAYER_PATHS) as AnimationPlayer

var last_on_floor := false
var state_applied := false

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

	if leg_player:
		leg_player.play(LEG_ANIMATION)

func _physics_process(_delta: float) -> void:
	if boid == null:
		return

	if leg_player and leg_player.current_animation != StringName(LEG_ANIMATION):
		leg_player.play(LEG_ANIMATION)

	var on_floor := boid.is_on_floor()
	if state_applied and on_floor == last_on_floor:
		return

	if wing_player:
		if on_floor:
			wing_player.stop()
		else:
			wing_player.play(WING_ANIMATION)

	last_on_floor = on_floor
	state_applied = true
