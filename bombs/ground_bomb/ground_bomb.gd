extends RigidBody2D
class_name GroundBomb

const EXPLOSION = preload("res://bombs/explosions/explosion.tscn")
const GROUND_EXPLOSION = preload("res://bombs/explosions/ground_particles.tscn")

func explode():
	# get the tilemap
	var tilemap: TileMapLayer
	for node in get_tree().current_scene.get_children():
		if node is TileMapLayer:
			tilemap = node
			break

	# place ground terrain
	var cell = tilemap.local_to_map(position)
	var cells = [cell]
	cells.append(cell + Vector2i.LEFT)
	cells.append(cell + Vector2i.RIGHT)
	tilemap.set_cells_terrain_connect(cells, 0, 0)
	
	# play some sfx
	var sound = AudioStreamPlayer2D.new()
	sound.position = position
	sound.stream = load("res://bombs/ground_bomb/creating_ground.wav")
	sound.bus = "Sounds"
	add_sibling(sound)
	sound.play()
	sound.connect("finished", sound.queue_free)
	
	for c in cells:
		var local_pos = tilemap.map_to_local(c)
		var instance = GROUND_EXPLOSION.instantiate()
		instance.position = local_pos
		instance.emitting = true
		instance.connect("finished", instance.queue_free)
		add_sibling(instance)
	#var instance = EXPLOSION.instantiate()
	#instance.position = position
	#add_sibling(instance)
	
	queue_free()
