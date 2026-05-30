extends CharacterBody2D

@onready var bounce_area: Area2D = $bounce_area

@export var move_distance: float = 10.0
@export var move_duration: float = 0.6
@export var bounce_factor: float = 1.2

var start_position: Vector2
var tween: Tween
var is_moving: bool = false

func _ready() -> void:
	start_position = position
	bounce_area.body_entered.connect(_on_bounce_entered)

func _on_bounce_entered(body: Node2D):
	if body is Player and not is_moving:
		if body.velocity.y  == 0:
			activate()
		
func activate():
	is_moving = true
	
	if tween and tween.is_valid():
		tween.kill()
	
	tween = get_tree().create_tween()
	
	var down_position = start_position + Vector2(0, move_distance)
	var bounce_position = start_position - Vector2(0, move_distance * (bounce_factor - 1))
	
	tween.tween_property(self, "position", down_position, move_duration * 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.chain().tween_property(self, "position", bounce_position, move_duration * 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(self, "position", start_position, move_duration * 0.4).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
	tween.tween_callback(reset_movement)
	
func reset_movement():
	is_moving = false
