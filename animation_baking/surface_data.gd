@tool
extends RefCounted


var vertices: Array[Vector3] = []
var bones: Array = []
var weights: Array = []


func _init(mesh: Mesh, surface_idx: int) -> void:
	var arrays := mesh.surface_get_arrays(surface_idx)
	var vertices_size: int = arrays[Mesh.ARRAY_VERTEX].size()
	var bones_size: int = arrays[Mesh.ARRAY_BONES].size()
	@warning_ignore("integer_division")
	var bones_per_vertex: int = bones_size / vertices_size
	var indices = vertices_size
	if arrays.size() > Mesh.ARRAY_INDEX and arrays[Mesh.ARRAY_INDEX]:
		indices = arrays[Mesh.ARRAY_INDEX]
	for idx in indices:
		var bone_start = idx * bones_per_vertex
		var bone_end = idx * bones_per_vertex + bones_per_vertex
		vertices.append(arrays[Mesh.ARRAY_VERTEX][idx])
		bones.append(arrays[Mesh.ARRAY_BONES].slice(bone_start, bone_end))
		weights.append(arrays[Mesh.ARRAY_WEIGHTS].slice(bone_start, bone_end))


func size() -> int:
	return vertices.size()
