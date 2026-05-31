extends Node2D

const WAIT_DURATION = 0.5

@onready var damage_area: Area2D = $AnimatableBody2D/DamageArea
@export var damage := 1
@export var knockback_force := 400.0
@onready var platform: AnimatableBody2D = $AnimatableBody2D
@export var move_speed = 8.0
@export var distance = 192
@export var move_horizontal = true

var follow = Vector2.ZERO
var platform_center = 16

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	move_platform()
	damage_area.body_entered.connect(_on_damage_area_body_entered)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	platform.position = platform.position.lerp(follow, 0.5)
	
	
func move_platform():
	var move_direction = Vector2.RIGHT * distance if move_horizontal else Vector2.UP * distance
	var direction = move_direction.length() / float(move_speed * platform_center)
	
	var platform_tween = create_tween().set_loops().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	platform_tween.tween_property(self, "follow", move_direction, direction).set_delay(WAIT_DURATION)
	platform_tween.tween_property(self, "follow", Vector2.ZERO, direction).set_delay(WAIT_DURATION)

func _on_damage_area_body_entered(body):
	if not body is Player:
		return

	body.take_damage(damage)

	var diff: Vector2 = body.global_position - platform.global_position
	var knockback: Vector2
	print("Diff X = ", diff.x)
	# Veio por cima
	if diff.y < -20 and abs(diff.y) > abs(diff.x):
		knockback = Vector2(0, -500)
	
		
	# Está do lado esquerdo da serra
	elif diff.x < 0:
		knockback = Vector2(-900, -300)

	# Está do lado direito da serra
	else:
		knockback = Vector2(900, -300)

	body.velocity = knockback
	
