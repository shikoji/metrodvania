extends Label
@onready var drinking_sound = $DrinkingSound
@onready var error_sound = $Error

func _process(delta: float) -> void:
	self.text = "X" + str(Global.potion_amount)

	if Input.is_action_just_pressed("drink_potion"):
		if Global.potion_amount > 0:
		
			if Global.player_life < 100:
				Global.player_life = min(Global.player_life + Global.potion_increase, 100)
				drinking_sound.play()
				Global.potion_amount -= 1
			else:
				error_sound.play()
		else:
			error_sound.play()
	
	
