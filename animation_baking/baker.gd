@tool
extends RefCounted


const SurfaceData := preload("surface_data.gd")

const TRANSFORM_ZERO := Transform3D(
	Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO
)


var _surfaces: Array[SurfaceData] = []
var _bake_interval: float
var _skeleton: Skeleton3D
var _skin: Skin
var _anim_player: AnimationPlayer


func _init(
		mesh_instance: MeshInstance3D,
		bake_interval: float,
		skeleton: Skeleton3D,
		animation_player: AnimationPlayer
) -> void:
	_bake_interval = bake_interval
	_skeleton = skeleton
	_skin = mesh_instance.skin
	_anim_player = animation_player
	for surface_idx in mesh_instance.mesh.get_surface_count():
		_surfaces.append(SurfaceData.new(mesh_instance.mesh, surface_idx))


func bake_animations(surface_idx: int, animation_names := PackedStringArray()) -> Array[Texture]:
	# Use all animations if none were given
	if animation_names.is_empty():
		animation_names = _anim_player.get_animation_list()
	
	# Bake all desirec animations to images
	# and keep track of important metadata
	var animations: Array[Image] = []
	var frame_counts := PackedInt32Array()
	var frame_max := 0
	for name in animation_names:
		var anim := bake_single_animation(surface_idx, name)
		var frames := anim.get_height()
		animations.append(anim)
		frame_counts.append(frames)
		frame_max = max(frames, frame_max)
	
	# Adjust all images to be the same height as the biggest one
	# (this is required for using Texture2DArray)
	var adjusted_images: Array[Image] = []
	for anim in animations:
		var adjusted := Image.create(anim.get_width(), frame_max, false, Image.FORMAT_RGBF)
		adjusted.fill(Color.BLACK)
		adjusted.blit_rect(anim, Rect2i(Vector2i.ZERO, anim.get_size()), Vector2i.ZERO)
		adjusted_images.append(adjusted)
	
	# Create Texture2DArray containing all animations
	var animations_texture := Texture2DArray.new()
	animations_texture.create_from_images(adjusted_images)
	
	# Create ImageTexture containing the metadata (amount of frames for each animation)
	# We need to use FORMAT_RF even though we store integers. This is a workaround for
	# https://github.com/godotengine/godot/issues/57841
	# So we store the bytes of our 32 bit integers in a channel for 32 bit floats, which
	# we then convert back to int in the shader using floatBitsToInt()
	var meta_texture := ImageTexture.create_from_image(Image.create_from_data(
		frame_counts.size(),
		1,
		false,
		Image.FORMAT_RF,
		frame_counts.to_byte_array()
	))
	return [meta_texture, animations_texture]


func bake_single_animation(surface_idx: int, animation: StringName) -> Image:
	# Create an image with a width equal to the number of vertices,
	# and a height equal to the amount of frames.
	var anim := _anim_player.get_animation(animation)
	var frames = ceil(anim.length / _bake_interval) + 1
	var step: float = anim.length / (frames - 1)
	
	var data := PackedFloat32Array()
	for i in frames:
		data.append_array(_get_pose_vertices(animation, i * step, surface_idx))
	
	return Image.create_from_data(
		_surfaces[surface_idx].vertices.size(),
		frames,
		false,
		Image.FORMAT_RGBF,
		data.to_byte_array()
	)


func _get_pose_vertices(animation: StringName, timestamp: float, surface_idx: int) -> PackedFloat32Array:
	# Set animation player to the desired frame
	_anim_player.current_animation = animation
	_anim_player.seek(timestamp, true)
	
	# Force the update of all bones
	for bone_idx in _skeleton.get_parentless_bones():
		_skeleton.force_update_bone_child_transform(bone_idx)
	
	# Iterate all vertices and apply the skeletal transform
	var data := _surfaces[surface_idx]
	var result := PackedFloat32Array()
	for vertex_idx in data.size():
		var combined_xform := TRANSFORM_ZERO
		for idx in data.bones[vertex_idx].size():
			var bone_idx: int = data.bones[vertex_idx][idx]
			var skin_xform := _get_skin_bone_pose(bone_idx)
			var bone_xform := _skeleton.get_bone_global_pose(bone_idx)
			var bone_weight := float(data.weights[vertex_idx][idx])
			var xform := bone_xform * skin_xform * bone_weight
			combined_xform = _add_transforms(combined_xform, xform)
		var vertex := combined_xform * data.vertices[vertex_idx]
		result.append(vertex.x)
		result.append(vertex.y)
		result.append(vertex.z)
	
	return result


func _get_skin_bone_pose(bone_idx: int) -> Transform3D:
	var bone_name := StringName(_skeleton.get_bone_name(bone_idx))
	for binding in _skin.get_bind_count():
		if _skin.get_bind_name(binding) == bone_name:
			return _skin.get_bind_pose(binding)
	return Transform3D()


func _add_transforms(a: Transform3D, b: Transform3D) -> Transform3D:
	a.origin += b.origin
	a.basis.x += b.basis.x
	a.basis.y += b.basis.y
	a.basis.z += b.basis.z
	return a
