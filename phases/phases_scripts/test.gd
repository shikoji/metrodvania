extends Node2D

@onready var player: CharacterBody2D = $player
@onready var player_scene = preload("res://player/player.tscn")
@onready var player_start_position: Marker2D = $player_start_position

@onready var transition = get_tree().get_first_node_in_group("screen_transition")

@onready var level_scene: PackedScene = preload("res://phases/phases_scenes/test.tscn")

var game_over_started := false



func _ready() -> void:
	Global.player_start_position = player_start_position
	Global.player = player
	
	Global.player_life = player.max_life
	
	Global.respawn_player()
	
	Global.player.player_has_died.connect(game_over)
	
	SceneManager.play_transition_out()

func reload_game():
	if game_over_started:
		return
	
	await get_tree().create_timer(1.0).timeout
	
	if game_over_started:
		return
	
	player = player_scene.instantiate()
	add_child(player)
	
	Global.player = player
	Global.player.player_has_died.connect(reload_game)
	Global.player_life = player.max_life
	Global.respawn_player()

func game_over():
	if player != null:
		player.set_physics_process(false)
		player.set_process(false)
	
	SceneManager.play_transition_in(level_scene)
