extends RigidBody2D
class_name Bomb

const EXPLOSION = preload("res://bombs/explosions/explosion.tscn")

func _ready() -> void:
	pass

func explode():
	var instance = EXPLOSION.instantiate()
	instance.position = position
	add_sibling(instance)
	
	# place bomb explosion code here
	queue_free()
