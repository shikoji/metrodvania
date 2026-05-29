extends TextureProgressBar

func _ready():
	value = Global.player_life

func _process(delta):
	value = lerpf(value, float(Global.player_life), 5.0 * delta)
