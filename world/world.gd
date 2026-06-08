extends Node2D

@onready var tilemap = $TileMapLayer

func generate_tilemap():
	var cells = []
	var tileset : TileSet = tilemap.tile_set
	for x in range(-10, 10):
		for y in range(-10, 10):
			var pattern = tileset.get_pattern(randi_range(0, 4))
			var pattern_position = Vector2i(x * 32, y * 16)
			tilemap.set_pattern(pattern_position, pattern)
	#tilemap.set_cells_terrain_connect(cells, 0, 0, false)

func _ready() -> void:
	pass
	generate_tilemap()

func _process(_delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE:
			get_tree().quit()
