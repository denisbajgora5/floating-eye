extends Follower

@export var panic_distance := 30.0
@export var flee_weight := 1.0


func find_predator():
	for node in get_parent().get_children():
		if node is Predator:
			return node
	return null


func _process(delta):
	super._process(delta)

	var predator = find_predator()

	if predator == null:
		return

	var dist = global_transform.origin.distance_to(predator.global_transform.origin)

	if dist < panic_distance:
		var flee_dir = global_transform.origin - predator.global_transform.origin
		flee_dir = flee_dir.normalized()

		var flee_force = flee_dir * max_speed

		new_force += flee_force * flee_weight
