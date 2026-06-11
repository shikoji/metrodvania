extends Node2D

@export var target: Node2D

func _physics_process(delta: float) -> void:
	look_at(target.global_position)
