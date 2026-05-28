extends Area2D

var is_active = false

@onready var anim: AnimatedSprite2D = $anim
@onready var marker_2d: Marker2D = $Marker2D


func _on_body_entered(body: Node2D) -> void:
	if body.name != "player" or is_active:
		return
	activate_checkpoint()
	
	
func activate_checkpoint():
	Global.current_checkpoint_position = marker_2d.global_position
	Global.has_checkpoint = true
	anim.play("raising")
	is_active = true
	

func _on_anim_animation_finished() -> void:
	if anim.animation == "raising":
		anim.play("checked")
