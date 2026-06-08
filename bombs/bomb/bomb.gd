extends RigidBody2D
class_name Bomb

func _ready() -> void:
	pass

func explode():
	# place bomb explosion code here
	queue_free()
