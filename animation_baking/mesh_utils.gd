@tool
extends RefCounted


static func to_deindexed_surfaces(mesh: Mesh) -> ArrayMesh:
	var deindexed_mesh := ArrayMesh.new()
	for surface_idx in mesh.get_surface_count():
		var st := SurfaceTool.new()
		st.create_from(mesh, surface_idx)
		st.deindex()
		st.commit(deindexed_mesh)
	return deindexed_mesh


static func to_single_deindexed_surface(mesh: Mesh) -> ArrayMesh:
	var single_surface := SurfaceTool.new()
	single_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for surface_idx in mesh.get_surface_count():
		var mdt := MeshDataTool.new()
		mdt.create_from_surface(mesh, surface_idx)
		for face_idx in mdt.get_face_count():
			for triangle_pos in 3:
				var vertex_idx := mdt.get_face_vertex(face_idx, triangle_pos)
				single_surface.set_bones(mdt.get_vertex_bones(vertex_idx))
				single_surface.set_weights(mdt.get_vertex_weights(vertex_idx))
				single_surface.set_normal(mdt.get_vertex_normal(vertex_idx))
				single_surface.add_vertex(mdt.get_vertex(vertex_idx))
	return single_surface.commit()
