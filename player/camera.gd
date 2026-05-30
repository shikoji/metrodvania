extends Camera2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func shake(strength: float, time: float) -> void:
	var tween = create_tween()
	var direction = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
	tween.tween_property(self, "position", direction.normalized() * strength, time * 0.5)
	tween.tween_property(self, "position", Vector2.ZERO, time * 0.5)
