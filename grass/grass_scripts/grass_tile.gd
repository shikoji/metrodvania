extends Node2D

@onready var anim: AnimationPlayer = $anim


func _on_grass_area_body_entered(body: Node2D) -> void:
	if body is Player or body.is_in_group("enemies"):
		anim.play("sway")
