@tool
extends Sprite2D

@export var particle_colors: Color:
	set(new_color):
		$GPUParticles2D.process_material.color = new_color
		particle_colors = new_color

enum Ability {
	PowerMode,
	DoubleJump
}

@export var ability = Ability.PowerMode

func _ready():
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "offset:y", -2.0, 0.5).as_relative().set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "offset:y", 2.0, 0.5).as_relative().set_ease(Tween.EASE_IN)
	tween.tween_property(self, "offset:y", 2.0, 0.5).as_relative().set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "offset:y", -2.0, 0.5).as_relative().set_ease(Tween.EASE_IN)

const STREAM = preload("res://ability_unlocker/ability_unlock.wav")

func play_ability_unlock_sound():
	var audio_player = AudioStreamPlayer2D.new()
	audio_player.position = position
	audio_player.stream = STREAM
	add_sibling(audio_player)
	audio_player.play()
	audio_player.connect("finished", audio_player.queue_free)


func _on_area_body_entered(body: Node2D) -> void:
	if body == Global.player:
		match ability:
			Ability.PowerMode:
				Abilities.power_mode = true
		play_ability_unlock_sound()
		queue_free()
