class_name ThrowableBall
extends RigidBody3D

signal thrown(thrower: Node3D)
signal picked_up(holder: Node3D)
signal carried(carrier: Node3D)

var holder: Node3D = null
var last_thrower: Node3D = null
var visuals_default_scale: Vector3 = Vector3.ONE

@onready var visuals := get_node_or_null("Visuals") as Node3D


func _ready() -> void:
	if visuals:
		visuals_default_scale = visuals.scale


func notify_thrown(thrower: Node3D) -> void:
	last_thrower = thrower
	holder = null
	thrown.emit(thrower)


func notify_picked_up(new_holder: Node3D) -> void:
	holder = new_holder
	picked_up.emit(new_holder)


func notify_carried(carrier: Node3D) -> void:
	holder = carrier
	carried.emit(carrier)


func set_visual_scale_multiplier(scale_multiplier: float) -> void:
	if visuals == null:
		return

	visuals.scale = visuals_default_scale * scale_multiplier


func reset_visual_scale() -> void:
	if visuals == null:
		return

	visuals.scale = visuals_default_scale


func is_held_by(node: Node) -> bool:
	return holder == node


func is_free() -> bool:
	return holder == null
