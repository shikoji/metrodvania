extends Node

const SMALL_PARTICLES = preload("res://particles_helper/small_particles.tscn")

func spawn_particles(g_position) -> GPUParticles2D:
	var instance = SMALL_PARTICLES.instantiate()
	get_tree().current_scene.add_child(instance)
	instance.global_position = g_position
	instance.emitting = true
	instance.connect("finished", instance.queue_free)
	return instance
