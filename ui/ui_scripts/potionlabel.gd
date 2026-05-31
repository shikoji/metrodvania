extends Label


func _process(delta: float) -> void:
	self.text = "X" + str(Global.potion_amount)

	if Input.is_action_just_pressed("drink_potion") and Global.potion_amount > 0:
		if Global.player_life < 100:
			Global.player_life = min(Global.player_life + Global.potion_increase, 100)
			Global.potion_amount -= 1
