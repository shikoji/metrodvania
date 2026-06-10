extends Area2D
class_name Teleporter

@export var target: Teleporter
@export var teleport_protection = []

func _on_body_entered(body: Node2D) -> void:
	if body in teleport_protection:
		return
	if body is Player:
		target.teleport_protection.append(body)
		body.global_position = target.global_position
		

func _on_body_exited(body: Node2D) -> void:
	if body in teleport_protection:
		teleport_protection.erase(body)
