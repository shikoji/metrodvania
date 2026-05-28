extends TextureProgressBar

@onready var timer: Timer = $"../Timer"

func _ready():
	value = Global.player_life

func _process(delta):
	value = lerpf(value, float(Global.player_life), 5.0 * delta)

func _on_timer_timeout():
	Global.player_life -= 100
	
	print(Global.player_life)
	
	if Global.player_life <= 0:
		Global.player_life = 0
		timer.queue_free()
