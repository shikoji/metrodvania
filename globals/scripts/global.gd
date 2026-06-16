extends Node
 

var player_damage = 1
var boss_life = 400
var boss_death = false
var fx_boss_finished = false

var coins = 0
var score = 0
var player_life := 100

# checkpoint
var player = null
var player_start_position = null

#potions
var potion_amount: int
var potion_increase:int = 80

var current_checkpoint_position: Vector2
var has_checkpoint := false

# tilemap
var tilemap: TileMapLayer

func respawn_player():
	if player == null:
		return
	
	if has_checkpoint:
		player.global_position = current_checkpoint_position
	else:
		player.global_position = player_start_position.global_position
