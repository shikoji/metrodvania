extends Node2D

@onready var hit_impact: RayCast2D = $hit_impact
@onready var laser_line: Line2D = $laser_line
@onready var impact_fx: GPUParticles2D = $impact_fx
@onready var laser_cooldown_timer: Timer = $laser_cooldown_timer

@export var laser_color: Color = Color.WHITE : set = set_laser_color
@export var damage: int = 1

var active: bool = false
var tween_duration: float = 0.15

func _ready() -> void:
	laser_line.visible = false
	set_laser_color(laser_color)

func _physics_process(delta: float) -> void:
	if !active:
		return

	var end_point = hit_impact.target_position

	if hit_impact.is_colliding():
		var collider = hit_impact.get_collider()

		# Dano no player
		if collider is Player:
			collider.take_damage(damage)

		var collision_point = hit_impact.get_collision_point()
		var collision_normal = hit_impact.get_collision_normal()
		end_point = to_local(collision_point + collision_normal * 2.0)
		impact_fx.global_position = hit_impact.get_collision_point()
		impact_fx.emitting = true

	laser_line.points[0] = Vector2.ZERO
	laser_line.points[1] = end_point

func set_laser_color(new_color: Color) -> void:
	laser_color = new_color

	if !laser_line:
		return

	laser_line.modulate = new_color

	if impact_fx.process_material:
		impact_fx.process_material.set("color", new_color)

func _on_laser_cooldown_timer_timeout() -> void:
	if active:
		stop()
	else:
		fire()

	laser_cooldown_timer.start()

func fire() -> void:
	active = true
	laser_line.visible = true

	hit_impact.force_raycast_update()

	var target = hit_impact.target_position

	if hit_impact.is_colliding():
		target = to_local(hit_impact.get_collision_point())
		impact_fx.global_position = hit_impact.get_collision_point()
		impact_fx.emitting = true

	laser_line.points = PackedVector2Array([
		Vector2.ZERO,
		Vector2.ZERO
	])

	var tween = create_tween()

	var final_points = PackedVector2Array([
		Vector2.ZERO,
		target
	])

	tween.tween_property(
		laser_line,
		"points",
		final_points,
		tween_duration
	)

func stop() -> void:
	active = false
	impact_fx.emitting = false

	var tween = create_tween()

	tween.tween_property(
		laser_line,
		"points",
		PackedVector2Array([
			Vector2.ZERO,
			Vector2.ZERO
		]),
		tween_duration
	)

	await tween.finished

	laser_line.visible = false
