extends MeshInstance3D

@export var color_of_path := Color.AQUA
@export var res := 50
var path_points : PackedVector3Array

func _ready() -> void:
	var path = get_parent() as Path3D
	if path and path.curve != null:
		var path_curve: Curve3D = path.curve
		path_points = []
		
		for r in range(res):
			var res_length := float(res-1);
			var path_res := float(r)/res_length
			path_points.append(path_curve.sample(path_res,true))
			
		var mesh_arrays := []
		mesh_arrays.resize(Mesh.ARRAY_MAX)
		mesh_arrays[Mesh.ARRAY_VERTEX] = path_points
		
		var the_mesh := ArrayMesh.new()
		the_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINE_STRIP,mesh_arrays
		)
		
		self.mesh = the_mesh
		
