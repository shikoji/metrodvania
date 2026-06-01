extends Node2D

@onready var anim: AnimationPlayer = $anim


func _on_grass_area_body_entered(body: Node2D) -> void:
	if body is Player or body.is_in_group("enemies"):
		anim.play("sway")
		var particles = ParticleHelper.spawn_particles(global_position)
		particles.amount = 2
		var particle_material: ParticleProcessMaterial = particles.process_material
		particle_material.color = Color.GREEN
		particle_material.gravity = Vector3(0.0, 10.0, 0.0)
		particle_material.initial_velocity_max = 50.0
		particle_material.initial_velocity_min = 30.0
