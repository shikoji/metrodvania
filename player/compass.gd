extends Node2D

@onready var target: Node2D = get_parent().compass_target

func _physics_process(delta: float) -> void:
	if target:
		look_at(target.global_position)
