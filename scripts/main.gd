extends Node3D

const BOID_GIZMO_GROUP := "boid_gizmo_roots"
const FLOATING_EYE_PATH_MESH_PATH := "floating_eye/Path3D/MeshInstance3D"

var gizmos_enabled := false
var floating_eye_path_visible := false

func _ready() -> void:
	gizmos_enabled = _has_visible_boid_gizmos()
	_set_floating_eye_path_visible(false)
	_update_gizmo_label_visibility(gizmos_enabled)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_G or event.physical_keycode == KEY_G:
			_set_boid_gizmos_enabled(not gizmos_enabled)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_H or event.physical_keycode == KEY_H:
			_set_floating_eye_path_visible(not floating_eye_path_visible)
			get_viewport().set_input_as_handled()


func _set_boid_gizmos_enabled(enabled: bool) -> void:
	gizmos_enabled = enabled

	for boid in get_tree().get_nodes_in_group(BOID_GIZMO_GROUP):
		if boid.has_method("draw_gizmos_recursive"):
			boid.draw_gizmos_recursive(enabled)

	_update_gizmo_label_visibility(enabled)


func _has_visible_boid_gizmos() -> bool:
	for boid in get_tree().get_nodes_in_group(BOID_GIZMO_GROUP):
		if boid.get("draw_gizmos"):
			return true

	return false


func _set_floating_eye_path_visible(visible: bool) -> void:
	floating_eye_path_visible = visible

	var path_mesh := get_node_or_null(FLOATING_EYE_PATH_MESH_PATH) as MeshInstance3D
	if path_mesh:
		path_mesh.visible = visible


func _update_gizmo_label_visibility(enabled: bool) -> void:
	var label := get_node_or_null("CanvasLayer/Label3D")
	if label:
		label.visible = enabled
