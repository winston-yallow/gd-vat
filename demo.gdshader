shader_type spatial;


uniform int current_animation = 0;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D meta_data;
uniform sampler2DArray animation_data;


vec3 interpolateVertexPosition(
		sampler2D meta,
		sampler2DArray anim,
		int anim_idx,
		float frame_progress,
		int vert_index
) {
	int frame_count = floatBitsToInt(texelFetch(meta, ivec2(anim_idx, 0), 0).x) - 1;
	float floating_frame = frame_progress * float(frame_count);
	int frame_before = int(floor(floating_frame));
	int frame_after = int(ceil(floating_frame));
	ivec3 p_before = ivec3(vert_index, clamp(frame_before, 0, frame_count), anim_idx);
	ivec3 p_after = ivec3(vert_index, clamp(frame_after, 0, frame_count), anim_idx);
	vec3 before = texelFetch(anim, p_before, 0).xyz;
	vec3 after = texelFetch(anim, p_after, 0).xyz;
	return mix(before, after, fract(floating_frame));
}


void vertex() {
	VERTEX = interpolateVertexPosition(
		meta_data, animation_data, current_animation, progress, VERTEX_ID
	);
}
