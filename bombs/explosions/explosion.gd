extends Area2D

const GROUND_EXPLOSION = preload("res://bombs/explosions/ground_particles.tscn")

func _ready() -> void:
	$GPUParticles2D.emitting = true
	$GPUParticles2D2.emitting = true

var tick = 0

func _physics_process(delta: float) -> void:
	tick += 1
	if tick == 2:
		for body in get_overlapping_bodies():
			if body is TileMapLayer:
				break_cells(body)

			if body is Player:
				body.take_damage(20)
			if body.is_in_group("enemies"):
				body.take_damage(3)
			if body.has_method("break_sprite"):
				body.hitpoints -= 2
				if body.hitpoints <= 0:
					body.break_sprite()
				else:
					body.animation_player.play("hit")
			if body is RigidBody2D:
				var direction = global_position.direction_to(body.global_position)
				body.apply_central_impulse(direction * 1000.0)

func break_cells(body: TileMapLayer):
	var used_cells = body.get_used_cells()
	var cells = []
	var to_erase = []
	var cell = body.local_to_map(position)
	cells.append_array(get_surrounding_cells(cell))
	for c in cells:
		to_erase.append_array(get_surrounding_cells(c))
	for c in to_erase:
		if c in used_cells:
			var local_pos = body.map_to_local(c)
			var instance = GROUND_EXPLOSION.instantiate()
			instance.position = local_pos
			instance.emitting = true
			instance.connect("finished", instance.queue_free)
			add_sibling(instance)
			body.set_cell(c)

func get_surrounding_cells(cell: Vector2i):
	var res = []
	res.append(cell)
	res.append(cell + Vector2i.UP)
	res.append(cell + Vector2i.DOWN)
	res.append(cell + Vector2i.LEFT)
	res.append(cell + Vector2i.RIGHT)
	return res
