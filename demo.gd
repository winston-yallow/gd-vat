extends Node3D


var Baker := preload("res://animation_baking/baker.gd")
var MeshUtils := preload("res://animation_baking/mesh_utils.gd")

@onready var _target := $Target


func _ready() -> void:
	var start := Time.get_ticks_msec()
	print("\nstart generating")
	
	# Load the gltf and get the individual nodes
	var gltf := preload("res://assets/alpaca.gltf")
	var alpaca := gltf.instantiate()
	var anim_player: AnimationPlayer = alpaca.get_node("AnimationPlayer")
	var skeleton: Skeleton3D = alpaca.get_node("AnimalArmature/Skeleton3D")
	var mesh_instance: MeshInstance3D = alpaca.get_node("AnimalArmature/Skeleton3D/Alpaca")
	
	# Convert the mesh to a single surface that is deindexed
	var mesh := MeshUtils.to_single_deindexed_surface(mesh_instance.mesh)
	mesh_instance.mesh = mesh
	
	# Bake a few animations to a texture
	var baker := Baker.new(mesh_instance, 0.2, skeleton, anim_player)
	var result := baker.bake_animations(0, ["Gallop", "Gallop_Jump"])
	
	# Free the loaded GLTF scene to not cause any memory leak
	alpaca.free()
	
	# Construct a mesh that uses these animations
	var material := ShaderMaterial.new()
	material.shader = preload("res://demo.gdshader")
	material.set_shader_parameter("meta_data", result[0])
	material.set_shader_parameter("animation_data", result[1])
	_target.mesh = mesh
	_target.material_override = material
	
	var end := Time.get_ticks_msec()
	prints("end [%ss]" % ((end - start) / 1000.0))
	
	var set_progress := func (progress: float) -> void:
		material.set_shader_parameter("progress", fposmod(progress, 1.0))
	
	var set_animation := func (animation: int) -> void:
		material.set_shader_parameter("current_animation", animation)
	
	while true:
		var tween := create_tween()
		tween.tween_callback(set_animation.bind(0))
		tween.tween_method(set_progress, 0.0, 1.0, 1.0)
		tween.tween_method(set_progress, 0.0, 1.0, 1.0)
		tween.tween_callback(set_animation.bind(1))
		tween.tween_method(set_progress, 0.0, 1.0, 1.0)
		await tween.finished
