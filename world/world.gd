extends Node2D

@onready var player_start_position = $PlayerStartPosition
@onready var player = $player
const SCENE: PackedScene = preload("res://world/world.tscn")


@onready var tilemap: TileMapLayer = $TileMapLayer
@onready var tileset: TileSet = tilemap.tile_set

var path_a = [
	Vector2i(2, -1),
	Vector2i(2, 0),
	Vector2i(3, 0),
	Vector2i(3, -1),
	Vector2i(3, -2),
	Vector2i(2, -2),
	Vector2i(2, -3),
	Vector2i(3, -3),
	Vector2i(3, -4)
]

var path_a_rooms = [7, 5, 4, [8, 9], 7, 5, 7, 4, 7]

var path_b = [
	Vector2i(2, -1),
	Vector2i(3, -1),
	Vector2i(4, -1),
	Vector2i(4, -2),
	Vector2i(4, -3),
	Vector2i(3, -3),
	Vector2i(3, -2),
	Vector2i(2, -2),
	Vector2i(2, -3),
	Vector2i(2, -4),
	Vector2i(3, -4)
]

var path_b_rooms = [[1, 2], [1, 2], 4, [8, 9], 7, 7, 4, 5, [8, 9], 7, [1, 2]]

var path_c = [
	Vector2i(2, -1),
	Vector2i(3, -1),
	Vector2i(3, -2),
	Vector2i(4, -2),
	Vector2i(4, -3),
	Vector2i(3, -3),
	Vector2i(2, -3),
	Vector2i(2, -4),
	Vector2i(2, -5),
	Vector2i(3, -5),
	Vector2i(3, -4)
]

var path_c_rooms = [[1, 2], 4, 7, 4, 7, [1, 2], 5, [8, 9], 7, 7, 5]

var starting_room = [
	Vector2i(0, -1),
	Vector2i(1, -1),
	Vector2i(0, -2),
	Vector2i(1, -2),
	Vector2i(0, -3),
	Vector2i(1, -3),
]

var bomb_room = [
	Vector2i(4, -4),
	Vector2i(5, -4)
]

# Throughout this function and the ones descending, we use a coordinate system
# that relates to the room sizes. A room is x32 and y16 in term of cell size
func generate_tilemap():
	var to_ignore = []
	to_ignore.append_array(starting_room)
	to_ignore.append_array(bomb_room)
	match randi_range(0, 2):
		0:
			to_ignore.append_array(path_a)
			draw_path(path_a, path_a_rooms)
		1:
			to_ignore.append_array(path_b)
			draw_path(path_b, path_b_rooms)
		2:
			to_ignore.append_array(path_c)
			draw_path(path_c, path_c_rooms)
	fill_first_ring(to_ignore)
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

func fill_first_ring(ignore_positions: Array) -> void:
	for x in range(0, 5):
		for y in range(-5, 1):
			var pattern_pos = Vector2i(x, y)
			if pattern_pos not in ignore_positions:
				place_pattern(pattern_pos)

func place_pattern(room_position: Vector2i, pattern: TileMapPattern = null) -> void:
	if pattern == null:
		pattern = tileset.get_pattern(randi_range(0, tileset.get_patterns_count() - 1))
	var tileset_position = Vector2i(room_position.x * 32, room_position.y * 16)
	tilemap.set_pattern(tileset_position, pattern)

func draw_path(room_positions, room_indexs) -> void:
	for i in range(room_positions.size()):
		var room_id = room_indexs[i]
		if room_indexs[i] is Array:
			room_id = room_indexs[i].pick_random()
		place_pattern(room_positions[i], tileset.get_pattern(room_id))

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
