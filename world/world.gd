extends Node2D

const GOLEM_SCENE: PackedScene = preload("res://golem/golem_scenes/golem.tscn")

@onready var golem_spawn_points: Node2D = $GolemSpawnPoints
@onready var golem_spawn_timer: Timer = $GolemSpawnTimer

@export var max_golems_alive: int = 4
@export var golem_spawn_time: float = 5.0

var boss_is_alive: bool = true
var alive_golems: Array[Node] = []

#camera zoom
var zoom_perto_boss = Vector2(1.0, 1.0)
var zoom_alvo_boss = Vector2(1.0, 1.0)

var zoom_perto = Vector2(7.0, 7.0)
var zoom_normal = Vector2(2.5, 2.5)
var zoom_alvo = Vector2(7.0, 7.0)
var suavidade = 3.0  # valores maiores = transição mais rápida
var player_camera : Camera2D = null

# --- SHADER VARIABLES ---
@export var tilemap_material : ShaderMaterial
var current_corruption : float = 0.0

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


var path_a_rooms = [11, 5, 4, [8, 9], [7, 11], 5, [7, 10], 4, 10]


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


var path_b_rooms = [[1, 2], [1, 2], 4, [8, 9], 11, 10, 4, 5, [8, 9], [7, 10], [1, 2]]


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


var path_c_rooms = [[1, 2], 4, [7, 10], 4, [7, 11], [1, 2], 5, [8, 9], 10, 11, 5]


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

var ground_bomb_room = [
	Vector2i(6, -7)
]

@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var boss_batle: AudioStreamPlayer2D = $boss_batle


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
	to_ignore = ground_bomb_room
	to_ignore.append_array(bomb_room)
	fill_second_ring(to_ignore)
	fill_last_ring()
	tilemap.set_cells_terrain_connect(tilemap.get_used_cells(), 0, 0, false)
	print("generation done")

func setup_player_globals():
	Global.player_start_position = player_start_position
	Global.player = player
	
	Global.player_life = player.max_life
	
	Global.respawn_player()
	
	Global.player.player_has_died.connect(game_over)
	
	SceneManager.play_transition_out()
	
	Global.tilemap = $TileMapLayer

func _ready() -> void:
	potion_6.visible = false
	potion_6.monitorable = false
	potion_6.monitoring = false
	potion_7.visible = false
	potion_7.monitorable = false
	potion_7.monitoring = false
	potion_8.visible = false
	potion_8.monitorable = false
	potion_8.monitoring = false
	door.enabled = false
	$MusicPlayer.play() 
	setup_player_globals()
	generate_tilemap()
	tilemap_material = tilemap.material as ShaderMaterial
	update_map_corruption(0.0)
	golem_spawn_timer.wait_time = golem_spawn_time
	golem_spawn_timer.timeout.connect(_on_golem_spawn_timer_timeout)
	golem_spawn_timer.start()

func fill_first_ring(ignore_positions: Array) -> void:
	for x in range(0, 5):
		for y in range(-5, 1):
			var pattern_pos = Vector2i(x, y)
			if pattern_pos not in ignore_positions:
				place_pattern(pattern_pos)

func fill_second_ring(ignore_positions:Array) -> void:
	for x in range(-3, 7):
		for y in range(-7, -5):
			var pattern_pos = Vector2i(x, y)
			if pattern_pos not in ignore_positions:
				place_pattern(pattern_pos)
				sprinkle_on_pattern(pattern_pos)
	for x in range(5, 7):
		for y in range(-5, 1):
			var pattern_pos = Vector2i(x, y)
			if pattern_pos not in ignore_positions:
				place_pattern(pattern_pos)
				sprinkle_on_pattern(pattern_pos)
	for x in range(0, 7):
		var y = 1
		var pattern_pos = Vector2i(x, y)
		if pattern_pos not in ignore_positions:
			place_pattern(pattern_pos)
			sprinkle_on_pattern(pattern_pos)

const SINGLE_TILE = Vector2i(15, 3)

func sprinkle_on_pattern(room_position: Vector2i) -> void:
	var tilemap_pos = room_position * Vector2i(32, 16)
	var cells = []

	for x in range(tilemap_pos.x, tilemap_pos.x + 32):
		for y in range(tilemap_pos.y, tilemap_pos.y + 16):
			var rng = randi_range(0, 4)
			if rng == 0:
				tilemap.set_cell(Vector2i(x, y), 0, SINGLE_TILE)
			elif rng == 1:
				tilemap.set_cell(Vector2i(x, y))
	tilemap.set_cells_terrain_connect(cells, 0, 0, true)

func fill_last_ring() -> void:
	for x in range(0, 319):
		for y in range(113, 176):
			y = -y
			if randi_range(0, 10) == 0:
				tilemap.set_cell(Vector2i(x, y), 0, SINGLE_TILE)
	
	for x in range(224, 351):
		for y in range(-112, 31):
			if randi_range(0, 10) == 0:
				tilemap.set_cell(Vector2i(x, y), 0, SINGLE_TILE)

func place_pattern(room_position: Vector2i, pattern: TileMapPattern = null) -> void:
	if pattern == null:
		pattern = tileset.get_pattern(randi_range(0, tileset.get_patterns_count() - 1))
	var tileset_position = Vector2i(room_position.x * 32, room_position.y * 16)
	tilemap.set_pattern(tileset_position, pattern)
	
	# try spawn enemy
	var x = randi_range(tileset_position.x, tileset_position.x + 32)
	var y = randi_range(tileset_position.y, tileset_position.y + 16)
	for i in range(0, 5):
		for j in range(0, 3):
			if tilemap.get_cell_source_id(Vector2i(x + i, y + j)) != -1:
				return # check failed, don't spawn enemy
	x += 2
	y += 1
	var instance = ALICE.instantiate()
	instance.position = tilemap.map_to_local(Vector2i(x, y))
	add_child(instance)

const ALICE = preload("res://enemies/enemies_scenes/alice.tscn")

func draw_path(room_positions, room_indexs) -> void:
	for i in range(room_positions.size()):
		var room_id = room_indexs[i]
		if room_indexs[i] is Array:
			room_id = room_indexs[i].pick_random()
		place_pattern(room_positions[i], tileset.get_pattern(room_id))

@onready var potion_6: Area2D = $potions/Potion6
@onready var potion_7: Area2D = $potions/Potion7
@onready var potion_8: Area2D = $potions/Potion8


var potion_6_spawned: bool = false
var potion_7_spawned: bool = false
var potion_8_spawned: bool = false
func update_map_corruption(factor: float) -> void:
	if tilemap_material:
		var safe_factor = clampf(factor, 0.0, 0.75)
		tilemap_material.set_shader_parameter("darkness", safe_factor * 0.40)
		tilemap_material.set_shader_parameter("glitch_intensity", safe_factor)

var credits_started: bool = false


func _process(delta: float) -> void:
	if Global.fx_boss_finished and not credits_started:
		credits_started = true
		SceneManager.play_transition_in(preload("res://ending/ending.tscn"))
	
	if Global.boss_death:
		stop_golem_spawn()
	
	if not potion_6_spawned and Global.boss_life <= 300:
		potion_6_spawned = true
		show_potion(potion_6)

	if not potion_7_spawned and Global.boss_life <= 200:
		potion_7_spawned = true
		show_potion(potion_7)

	if not potion_8_spawned and Global.boss_life <= 100:
		potion_8_spawned = true
		show_potion(potion_8)

	if player_camera:
		player_camera.zoom = player_camera.zoom.lerp(zoom_alvo, delta * suavidade)
		
	current_corruption = move_toward(current_corruption, 1.0, delta * 0.01)
	update_map_corruption(current_corruption)

func show_potion(potion: Area2D) -> void:
	potion.visible = true
	potion.monitorable = true
	potion.monitoring = true

func game_over():
	if player != null:
		player.set_physics_process(false)
		player.set_process(false)
	
	SceneManager.play_transition_in(SCENE)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.has_node("Camera2D"):
		player_camera = body.get_node("Camera2D")
		zoom_alvo = zoom_perto

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.has_node("Camera2D"):
		player_camera = body.get_node("Camera2D")
		zoom_alvo = zoom_normal



@onready var door: TileMapLayer = $door

func _on_damage_area_body_entered(_body: Node2D) -> void:
	music_player.playing = false
	boss_batle.playing = true
	door.enabled = true
	Global.player_damage = 20


func _on_damage_area_body_exited(_body: Node2D) -> void:
	boss_batle.playing = false
	door.enabled = false
	Global.player_damage = 20


func _on_golem_spawn_timer_timeout() -> void:
	if not boss_is_alive:
		return

	_clear_dead_golems()

	if alive_golems.size() >= max_golems_alive:
		return

	spawn_golem()


func spawn_golem() -> void:
	var points: Array[Node] = golem_spawn_points.get_children()

	if points.is_empty():
		return

	var point: Marker2D = points.pick_random() as Marker2D

	if point == null:
		return

	var golem: Node2D = GOLEM_SCENE.instantiate()
	golem.global_position = point.global_position

	add_child(golem)
	alive_golems.append(golem)


func _clear_dead_golems() -> void:
	alive_golems = alive_golems.filter(func(golem: Node) -> bool:
		return is_instance_valid(golem)
	)


func stop_golem_spawn() -> void:
	boss_is_alive = false
	golem_spawn_timer.stop()


func _on_lost_bombs_body_entered(_body: Node2D) -> void:
	Abilities.bomb = false
	Abilities.ground_bomb = false


func _on_lost_bombs_body_exited(_body: Node2D) -> void:
	Abilities.bomb = true
	Abilities.ground_bomb = true


func _on_zoom_boss_body_entered(body: Node2D) -> void:
	if body.has_node("Camera2D"):
		player_camera = body.get_node("Camera2D")
		zoom_alvo = Vector2(1.7, 1.7) # mostra mais área


func _on_zoom_boss_body_exited(body: Node2D) -> void:
	if body.has_node("Camera2D"):
		player_camera = body.get_node("Camera2D")
		zoom_alvo = zoom_normal
