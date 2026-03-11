class_name Predator
extends Follower

enum PredatorState {
	WANDER,
	CHASE,
}

@export var chase_start_distance: float = 28.0
@export var chase_stop_distance: float = 42.0

var current_state: int = -1
var pursue_behavior: SteeringBehavior
var wander_behavior: SteeringBehavior
var prey: Node3D


func _ready():
	super._ready()
	pursue_behavior = get_node_or_null("Pursue")
	wander_behavior = get_node_or_null("Wander")
	prey = _resolve_prey()
	_set_state(PredatorState.WANDER)


func _process(delta):
	super._process(delta)

	if prey == null:
		prey = _resolve_prey()
		if prey == null:
			_set_state(PredatorState.WANDER)
			return

	var dist = global_transform.origin.distance_to(prey.global_transform.origin)
	if current_state == PredatorState.WANDER and dist <= chase_start_distance:
		_set_state(PredatorState.CHASE)
	elif current_state == PredatorState.CHASE and dist >= chase_stop_distance:
		_set_state(PredatorState.WANDER)


func _resolve_prey() -> Node3D:
	if pursue_behavior is Pursue:
		var pursue := pursue_behavior as Pursue
		if pursue.enemy_boid is Node3D:
			return pursue.enemy_boid

	var target := get_parent().get_node_or_null("Prey")
	if target is Node3D:
		return target

	return null


func _set_state(new_state: int):
	if current_state == new_state:
		return

	current_state = new_state

	if pursue_behavior:
		pursue_behavior.enabled = current_state == PredatorState.CHASE

	if wander_behavior:
		wander_behavior.enabled = current_state == PredatorState.WANDER
