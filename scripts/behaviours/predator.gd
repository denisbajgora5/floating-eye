class_name Predator
extends Follower


func find_prey():
	var closest = null
	var closest_dist = INF
	
	for boid in get_parent().get_children():
		# target followers but ignore self
		if boid is Follower and boid != self:
			
			var dist = global_transform.origin.distance_to(boid.global_transform.origin)
			
			if dist < closest_dist:
				closest_dist = dist
				closest = boid
	
	return closest


func _process(delta):
	# keep normal boid behaviour
	super._process(delta)

	var prey = find_prey()

	# if no prey exists stop
	if prey == null:
		return

	# chase the prey
	var chase_force = seek_force(prey.global_transform.origin)

	# apply strong pursuit force
	new_force += chase_force * 8
