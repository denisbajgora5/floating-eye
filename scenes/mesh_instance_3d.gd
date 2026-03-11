extends MeshInstance3D

@export var color_of_path := Color.AQUA
@export var res := 50
var path_points : PackedVector3Array

func _ready() -> void:
	var path = get_parent() as Path3D
	if path and path.curve != null:
		var path_curve: Curve3D = path.curve
		path_points = []
		
		self.transform = path.transform
		var len = path_curve.get_baked_length()
		
		for r in range(res):
			var res_length := float(res-1);
			var path_res := float(r)/res_length
			var local_path_point := path_curve.sample_baked(path_res * len)
			path_points.append(local_path_point)
		var mesh_arrays := []
		mesh_arrays.resize(Mesh.ARRAY_MAX)
		mesh_arrays[Mesh.ARRAY_VERTEX] = path_points
		
		var the_mesh := ArrayMesh.new()
		the_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINE_STRIP,mesh_arrays
		)
		
		the_mesh.custom_aabb = AABB(Vector3(-1000, -1000, -1000), Vector3(2000, 2000, 2000))

		
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = color_of_path
		self.material_override = mat
		
		self.mesh = the_mesh
		
