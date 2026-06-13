extends Node2D

@export var rotation_offset_degrees: float = 0.0

var target: Node2D = null
var active: bool = false


func _ready() -> void:
	visible = false


func enable_compass() -> void:
	active = true
	visible = true


func disable_compass() -> void:
	active = false
	visible = false
	target = null


func set_target(new_target: Node2D) -> void:
	target = new_target


func _physics_process(_delta: float) -> void:
	if not active:
		return
	
	if not is_instance_valid(target):
		return
	
	var direction: Vector2 = target.global_position - global_position
	
	if direction.length() <= 1.0:
		return
	
	global_rotation = direction.angle() + deg_to_rad(rotation_offset_degrees)
