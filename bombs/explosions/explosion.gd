extends Area2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$GPUParticles2D.emitting = true
	$GPUParticles2D2.emitting = true

var tick = 0

func _physics_process(delta: float) -> void:
	tick += 1
	if tick == 2:
		for body in get_overlapping_bodies():
			if body is TileMapLayer:
				var cells = []
				var to_erase = []
				var cell = body.local_to_map(position)
				cells.append_array(get_surrounding_cells(cell))
				for c in cells:
					to_erase.append_array(get_surrounding_cells(c))
				for c in to_erase:
					body.set_cell(c)
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

func get_surrounding_cells(cell: Vector2i):
	var res = []
	res.append(cell)
	res.append(cell + Vector2i.UP)
	res.append(cell + Vector2i.DOWN)
	res.append(cell + Vector2i.LEFT)
	res.append(cell + Vector2i.RIGHT)
	return res
