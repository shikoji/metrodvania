extends Label


func _process(delta: float) -> void:
	self.text = "X" + str(Global.potion_amount)
