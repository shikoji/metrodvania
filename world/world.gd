extends Node2D

@onready var player_start_position = $PlayerStartPosition
@onready var player = $player
const SCENE: PackedScene = preload("res://world/world.tscn")


@onready var tilemap: TileMapLayer = $TileMapLayer
@onready var tileset: TileSet = tilemap.tile_set

func generate_tilemap():
	var cells = []
	var tileset : TileSet = tilemap.tile_set
	#for x in range(-10, 10):
	#	for y in range(-10, 10):
	#		var pattern = tileset.get_pattern(randi_range(0, 4))
	#		var pattern_position = Vector2i(x * 32, y * 16)
	#		tilemap.set_pattern(pattern_position, pattern)
	#tilemap.set_cells_terrain_connect(cells, 0, 0, false)
	place_pattern(Vector2i(2, 0))
	place_pattern(Vector2i(2, -1))
	place_pattern(Vector2i(2, -2))
	place_pattern(Vector2i(2, -3))
	tilemap.set_cells_terrain_connect(tilemap.get_used_cells(), 0, 0, false)

func setup_player_globals():
	
	Global.player_start_position = player_start_position
	Global.player = player
	
	Global.player_life = player.max_life
	
	Global.respawn_player()
	
	Global.player.player_has_died.connect(game_over)
	
	SceneManager.play_transition_out()

func _ready() -> void:
	setup_player_globals()
	generate_tilemap()

func place_pattern(room_position: Vector2i) -> void:
	var pattern = tileset.get_pattern(randi_range(0, 3))
	var tileset_position = Vector2i(room_position.x * 32, room_position.y * 16)
	tilemap.set_pattern(tileset_position, pattern)

func _process(_delta: float) -> void:
	pass

func game_over():
	if player != null:
		player.set_physics_process(false)
		player.set_process(false)
	
	SceneManager.play_transition_in(SCENE)

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE:
			get_tree().quit()
