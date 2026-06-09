extends RigidBody2D
class_name GroundBomb

const EXPLOSION = preload("res://bombs/explosions/explosion.tscn")

func explode():
	# get the tilemap
	
	# place ground terrain
	
	# play some sfx
	var instance = EXPLOSION.instantiate()
	instance.position = position
	add_sibling(instance)
	
	queue_free()
