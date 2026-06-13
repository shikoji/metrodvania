@tool
extends Sprite2D

@export var particle_colors: Color:
	set(new_color):
		$GPUParticles2D.process_material.color = new_color
		particle_colors = new_color

enum Ability {
	PowerMode,
	DoubleJump,
	Bomb,
	GroundBomb,
	Roll,
	Compass
}

@export var ability = Ability.PowerMode

func _ready():
	offset.y = 0.0
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
	audio_player.bus = "Sounds"
	add_sibling(audio_player)
	audio_player.play()
	audio_player.connect("finished", audio_player.queue_free)


func _on_area_body_entered(body: Node2D) -> void:
	if body == Global.player:
		match ability:
			Ability.PowerMode:
				$CanvasLayer/AbilityName.text = "You've unlocked the Power Mode!"
				Abilities.power_mode = true
			Ability.DoubleJump:
				$CanvasLayer/AbilityName.text = "You've unlocked the Double Jump!"
				Abilities.double_jump = true
			Ability.Bomb:
				$CanvasLayer/AbilityName.text = "You've unlocked the Bomb! (E)"
				Abilities.bomb = true
			Ability.GroundBomb:
				$CanvasLayer/AbilityName.text = "You've unlocked the Ground Bomb! (Q)"
				Abilities.ground_bomb = true
			Ability.Roll:
				$CanvasLayer/AbilityName.text = "You've unlocked the Roll! (SHIFT)"
				Abilities.roll = true
			Ability.Compass:
				$CanvasLayer/AbilityName.text = "You've unlocked the Compass! (ARROW)"
				body.get_node("Compass").show()
		play_ability_unlock_sound()
		start_text_fade_sequence()


func start_text_fade_sequence() -> void:
	var label = $CanvasLayer/AbilityName
	var tween = create_tween()
	
	tween.tween_property(label, "modulate:a", 1.0, 0.5).from(0.0)
	
	tween.tween_interval(0.4)
	
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	
	await tween.finished
	queue_free()
