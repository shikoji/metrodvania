extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("handle_death_zone"):
		body.call_deferred("handle_death_zone")
