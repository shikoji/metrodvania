extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$GPUParticles2D.emitting = true
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_method(set_shader_value.bind("progress_fall"), 0.0, 1.0, 2.0)
	tween.tween_method(set_shader_value.bind("progress_scatter"), 0.0, 1.0, 2.0)
	tween.tween_method(set_shader_value.bind("progress_fade"), 0.0, 1.0, 1.0)


func set_shader_value(value, key):
	$Sprite2D.material.set_shader_parameter(key, value)


func _on_gpu_particles_2d_finished() -> void:
	queue_free()
