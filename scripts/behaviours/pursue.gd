class_name Pursue extends SteeringBehavior

@export var enemy_node_path:NodePath
var enemy_boid:Node

var target:Vector3
var world_target:Vector3
var projected:Vector3

func _ready():
	boid = get_parent()
		
	if enemy_node_path:
		enemy_boid = get_node(enemy_node_path)
		
func _process(delta):
	if draw_gizmos:
		DebugDraw3D.draw_arrow(boid.global_transform.origin, projected, Color.BISQUE, 0.1)

func calculate():		
	if enemy_boid == null or boid == null:
		return Vector3.ZERO

	var to_enemy = enemy_boid.global_transform.origin - boid.global_transform.origin	
	var dist = to_enemy.length()	
	var speed = max(boid.max_speed, 0.001)
	var time = dist / speed
	projected = enemy_boid.global_transform.origin + enemy_boid.velocity * time	
	return boid.seek_force(projected)
