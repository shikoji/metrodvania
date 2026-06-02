extends RigidBody2D

@export var hp: int
@export var max_speed: float = 1.0
@export var acceleration = 10.0
@export var contact_damage: int = 10
var _dead: bool
var _last_player_swing_id: int
var _player_target: CharacterBody2D

const DEATH_FX = preload("res://fx/death_fx/death_fx.tscn")


func _ready() -> void:
	_player_target = get_tree().current_scene.find_child("player")


var velocity = Vector2.ZERO

func _physics_process(delta: float) -> void:
	velocity += global_position.direction_to(_player_target.global_position) * delta * acceleration
	velocity = velocity.limit_length(max_speed)
	var collisions = move_and_collide(velocity)
	if collisions:
		velocity = -velocity
	#position += velocity * delta


func _on_attack_area_entered(area: Area2D) -> void:
	if _dead:
		return
	var player := area.get_parent()
	if player and player.has_method("take_damage"):
		_apply_damage_to_player(player)


func _apply_damage_to_player(player: Node) -> void:
	if player and player.has_method("take_damage"):
		player.call("take_damage", contact_damage)

func _on_hurt_box_area_entered(area: Area2D) -> void:
	if _dead:
		return
	if not area.has_meta("swing_id"):
		return

	if not area.get_meta("is_attacking", false):
		return

	var swing_id := int(area.get_meta("swing_id"))
	if swing_id == _last_player_swing_id:
		return
	_last_player_swing_id = swing_id

	var dmg := int(area.get_meta("damage", 1))
	take_damage(dmg)


func take_damage(amount: int):
	if _dead:
		return
	hp -= amount
	$TakeDamage.play()
	if hp <= 0:
		death()

func death():
	if _dead:
		return
	$AnimatedSprite2D.stop()
	var particles = ParticleHelper.spawn_particles(global_position)
	particles.amount = 20
	var process_mat: ParticleProcessMaterial = particles.process_material
	process_mat.color = Color.DIM_GRAY
	process_mat.scale_max = 3.0
	call_deferred("set", "freeze", false)
	_dead = true
	var dir = global_position.direction_to(_player_target.global_position)
	angular_velocity = randf_range(-1.0, 1.0) * 10.0
	call_deferred("apply_central_impulse", (Vector2.UP - dir).normalized() * 500.0)
	
	await get_tree().create_timer(randf_range(1.0, 2.0)).timeout
	
	free_and_explode()

func free_and_explode():
	var instance = DEATH_FX.instantiate()
	instance.position = position + (Vector2.UP * 16.0)
	add_sibling(instance)
	queue_free()
