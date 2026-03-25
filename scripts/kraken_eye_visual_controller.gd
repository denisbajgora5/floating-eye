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

@export_group("Proximity Flash")
@export var player_path: NodePath
@export_range(1.0, 40.0, 0.1) var proximity_flash_distance: float = 11.0
@export_range(0.1, 8.0, 0.1) var proximity_flash_pulse_speed: float = 2.1
@export var proximity_flash_color: Color = Color(1.0, 0.45, 0.12, 1.0)
@export_range(0.0, 3.0, 0.05) var proximity_flash_emission_boost: float = 0.8
@export_range(0.0, 1.5, 0.05) var proximity_flash_particle_boost: float = 0.2
@export_range(0.0, 1.0, 0.05) var proximity_flash_particle_tint_strength: float = 0.9

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
var player: Node3D = null
var proximity_flash_phase: float = 0.0
var eye_flash_materials: Array[BaseMaterial3D] = []
var eye_flash_base_emission_enabled: Array[bool] = []
var eye_flash_base_emission_colors: Array[Color] = []
var eye_flash_base_emission_energies: Array[float] = []
var flash_particles: GPUParticles3D = null
var flash_particle_process_material: ParticleProcessMaterial = null
var flash_particle_draw_material: BaseMaterial3D = null
var flash_particle_base_color: Color = Color.WHITE
var flash_particle_base_albedo: Color = Color.WHITE
var flash_particle_base_emission: Color = Color.BLACK
var flash_particle_base_emission_energy: float = 0.0

func _find_node(paths: Array) -> Node:
	for path in paths:
		var node = boid.get_node_or_null(path)
		if node:
			return node
	return null

func _ready() -> void:
	_cache_proximity_flash_visuals()
	_resolve_player()

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

func _cache_proximity_flash_visuals() -> void:
	_cache_eye_flash_materials()
	_cache_flash_particles()

func _cache_eye_flash_materials() -> void:
	if eye_root == null:
		return

	if eye_root is MeshInstance3D:
		_cache_mesh_flash_materials(eye_root as MeshInstance3D)

	for mesh_node in eye_root.find_children("*", "MeshInstance3D", true, false):
		_cache_mesh_flash_materials(mesh_node as MeshInstance3D)

func _cache_mesh_flash_materials(mesh_instance: MeshInstance3D) -> void:
	if mesh_instance == null or mesh_instance.mesh == null:
		return

	for surface_idx in mesh_instance.mesh.get_surface_count():
		var source_material := mesh_instance.get_active_material(surface_idx)
		if source_material is BaseMaterial3D:
			var flash_material := (source_material as BaseMaterial3D).duplicate() as BaseMaterial3D
			mesh_instance.set_surface_override_material(surface_idx, flash_material)
			eye_flash_materials.append(flash_material)
			eye_flash_base_emission_enabled.append(flash_material.emission_enabled)
			eye_flash_base_emission_colors.append(flash_material.emission)
			eye_flash_base_emission_energies.append(flash_material.emission_energy_multiplier)

func _cache_flash_particles() -> void:
	for child in boid.get_children():
		if child is GPUParticles3D:
			flash_particles = child as GPUParticles3D
			break

	if flash_particles == null:
		return

	if flash_particles.process_material is ParticleProcessMaterial:
		flash_particle_process_material = (flash_particles.process_material as ParticleProcessMaterial).duplicate() as ParticleProcessMaterial
		flash_particles.process_material = flash_particle_process_material
		flash_particle_base_color = flash_particle_process_material.color

	if flash_particles.draw_pass_1 is PrimitiveMesh:
		var particle_mesh := (flash_particles.draw_pass_1 as PrimitiveMesh).duplicate() as PrimitiveMesh
		flash_particles.draw_pass_1 = particle_mesh
		if particle_mesh.material is BaseMaterial3D:
			flash_particle_draw_material = (particle_mesh.material as BaseMaterial3D).duplicate() as BaseMaterial3D
			particle_mesh.material = flash_particle_draw_material
			flash_particle_base_albedo = flash_particle_draw_material.albedo_color
			flash_particle_base_emission = flash_particle_draw_material.emission
			flash_particle_base_emission_energy = flash_particle_draw_material.emission_energy_multiplier

func _resolve_player() -> void:
	if player != null and is_instance_valid(player):
		return

	player = null

	if not player_path.is_empty():
		player = get_node_or_null(player_path) as Node3D
		if player:
			return

	var current_scene := get_tree().current_scene
	if current_scene:
		player = current_scene.find_child("Player", true, false) as Node3D

func _flash_origin() -> Vector3:
	if eye_root:
		return eye_root.global_position
	return boid.global_position

func _update_proximity_flash(delta: float) -> void:
	if proximity_flash_distance <= 0.0:
		_apply_proximity_flash(0.0)
		return

	if player == null or not is_instance_valid(player):
		_resolve_player()

	proximity_flash_phase = wrapf(proximity_flash_phase + delta * proximity_flash_pulse_speed * TAU, 0.0, TAU)

	var flash_strength := 0.0
	if player:
		var distance_to_player := _flash_origin().distance_to(player.global_position)
		var proximity := clamp(1.0 - (distance_to_player / proximity_flash_distance), 0.0, 1.0)
		proximity = proximity * proximity * (3.0 - 2.0 * proximity)
		var pulse := 0.45 + 0.55 * (0.5 + 0.5 * sin(proximity_flash_phase))
		flash_strength = proximity * pulse

	_apply_proximity_flash(flash_strength)

func _apply_proximity_flash(strength: float) -> void:
	for idx in eye_flash_materials.size():
		var material := eye_flash_materials[idx]
		var base_color := eye_flash_base_emission_colors[idx]
		material.emission_enabled = eye_flash_base_emission_enabled[idx] or strength > 0.001
		material.emission = base_color.lerp(proximity_flash_color, strength)
		material.emission_energy_multiplier = eye_flash_base_emission_energies[idx] + strength * proximity_flash_emission_boost

	if flash_particle_process_material:
		flash_particle_process_material.color = flash_particle_base_color.lerp(
			proximity_flash_color,
			strength * proximity_flash_particle_tint_strength
		)

	if flash_particle_draw_material:
		flash_particle_draw_material.emission_enabled = true
		flash_particle_draw_material.albedo_color = flash_particle_base_albedo.lerp(
			proximity_flash_color.lightened(0.08),
			strength * 0.55
		)
		flash_particle_draw_material.emission = flash_particle_base_emission.lerp(
			proximity_flash_color,
			strength * proximity_flash_particle_tint_strength
		)
		flash_particle_draw_material.emission_energy_multiplier = (
			flash_particle_base_emission_energy
			+ strength * proximity_flash_particle_boost
		)

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

	_update_proximity_flash(_delta)

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
