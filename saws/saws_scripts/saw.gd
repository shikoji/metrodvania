extends Node2D

const WAIT_DURATION = 0.5
const DAMAGE_INTERVAL = 0.1

@onready var damage_area: Area2D = $AnimatableBody2D/DamageArea
@export var damage := 1
@onready var platform: AnimatableBody2D = $AnimatableBody2D
@export var move_speed = 8.0
@export var distance = 192
@export var move_horizontal = true

var follow = Vector2.ZERO
var platform_center = 16

var player_in_area: Player = null
var damage_timer: Timer

func _ready():
	move_platform()
	damage_area.body_entered.connect(_on_body_entered)
	damage_area.body_exited.connect(_on_body_exited)
	
	damage_timer = Timer.new()
	damage_timer.wait_time = DAMAGE_INTERVAL
	damage_timer.one_shot = false
	damage_timer.timeout.connect(_apply_damage)
	add_child(damage_timer)

func _physics_process(_delta):
	platform.position = platform.position.lerp(follow, 0.5)

func move_platform():
	var move_direction = Vector2.RIGHT * distance if move_horizontal else Vector2.UP * distance
	var direction = move_direction.length() / float(move_speed * platform_center)
	var platform_tween = create_tween().set_loops().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	platform_tween.tween_property(self, "follow", move_direction, direction).set_delay(WAIT_DURATION)
	platform_tween.tween_property(self, "follow", Vector2.ZERO, direction).set_delay(WAIT_DURATION)

func _on_body_entered(body):
	if body is Player:
		player_in_area = body
		if damage_timer.is_stopped():
			damage_timer.start()
		_apply_damage()

func _on_body_exited(body):
	if body == player_in_area:
		player_in_area = null
		if not damage_area.has_overlapping_bodies():
			damage_timer.stop()

func _apply_damage():
	if player_in_area != null and is_instance_valid(player_in_area):
		player_in_area.take_damage(damage)
