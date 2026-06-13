extends RigidBody2D
class_name Bomb

const EXPLOSION = preload("res://bombs/explosions/explosion.tscn")

func explode():
	var instance = EXPLOSION.instantiate()
	instance.position = position
	add_sibling(instance)
	
	# place bomb explosion code here
	queue_free()


func _on_body_entered(body: Node) -> void:
	set_deferred("freeze", true)
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
