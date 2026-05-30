extends CharacterBody2D
class_name Player
@onready var animation_sprite: AnimatedSprite2D = $animation_sprite


@export_group("Horizontal Movement X")
@export var horizontal_max_speed: float = 240.0
@export var horizontal_acceleration: float = 12.0
@export var horizontal_deceleration: float = 16.0

@export_group("Gravity Y")
@export var gravity: float = 1200.0
@export var jump_height: float = 90.0

@export_group("Jump Buffer")
@export var jump_buffer_time: float = 0.12
var jump_buffer_timer: float = 0.0

@export_group("Wall")
@export var wall_gravity: float = 120.0
@export var wall_jump: float = 350.0
@export var wall_slide_exit_time: float = 0.03

@export_group("Attack")
@export var attack_buffer_time: float = 0.18
@export var attack_move_multiplier: float = 0.35
var is_attacking: bool = false
var attack_queued: bool = false
var attack_buffer_timer: float = 0.0

@export_group("Roll")
@export var roll_speed: float = 420.0
@export var roll_time: float = 0.28
@export var roll_cooldown: float = 0.35
@export var enemy_collision_layer: int = 3
var is_rolling: bool = false
var roll_timer: float = 0.0
var roll_cooldown_timer: float = 0.0
var roll_direction: float = 1.0

@export_category("Life")
@export var max_life: int = 3
var life: int

signal player_has_died()

var wall_slide_active: bool = false
var last_wall_normal_x: float = 0.0
var wall_slide_exit_timer: float = 0.0

var is_respawning_from_fall: bool = false

#==box valuies
var PushForce:int = 200
var push_buffer_timer: float = 0.0
@onready var box_ray = $BoxRay

# --- Hitboxes / Hurtboxes (NÃO mexe no resto do player) ---
@onready var player_hurtbox: Area2D = $HurtBoxArea2d
@onready var player_attack_area: Area2D = $AttackArea2d

@export var attack_damage: int = 1
@export var attack_hitbox_active_time: float = 0.10  # tempo que a hitbox fica ativa dentro do ataque
@export var invincibility_time: float = 0.25         # i-frames após tomar dano

var _inv_timer: float = 0.0
var _swing_id: int = 0

@onready var player_attack_shape: CollisionShape2D = $AttackArea2d/CollisionShape2D

var _attack_shape_base_pos: Vector2


@export var hurt_lock_time: float = 0.25
var is_hurt: bool = false
var hurt_timer: float = 0.0

var is_dead: bool = false

@onready var attack_sound: AudioStreamPlayer2D = $AttackSound
@onready var hurt_sound: AudioStreamPlayer2D = $HurtSound

func update_attack_facing() -> void:
	# Se flip_h = true, player está olhando pra ESQUERDA.
	var xsign := -1.0 if animation_sprite.flip_h else 1.0
	player_attack_shape.position.x = _attack_shape_base_pos.x * xsign

func _ready() -> void:
	_attack_shape_base_pos = player_attack_shape.position
	
	life = max_life
	Global.player_life = life

	# mantém seu connect atual
	if not animation_sprite.animation_finished.is_connected(_on_animation_finished):
		animation_sprite.animation_finished.connect(_on_animation_finished)

	# >>> ADICIONE ISTO:
	player_attack_area.monitoring = false
	player_attack_area.monitorable = true
	player_attack_area.set_meta("is_attacking", false)
	player_attack_area.monitoring = false

func RigidBodyCollision() -> void:
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var body := collision.get_collider()
		
		if body is RigidBody2D:
			var normal := collision.get_normal()
			if abs(normal.y) > 0.7: 
				continue
			if box_ray.is_colliding():
				push_buffer_timer = 0.15
				var push_direction := Vector2(-normal.x, 0.0).normalized()
				body.apply_central_impulse(push_direction * PushForce)
				
				velocity.x = lerp(velocity.x, 0.0, 0.25)
			
func _physics_process(delta: float) -> void:
	
	update_timers(delta)
	read_action_inputs()
	jump_buffer(delta)
	
	
	if is_rolling:
		roll_movement(delta)
	else:
		horizontal_movement(delta)
		vertical_movement(delta)
		wall_movement(delta)
	
	move_and_slide()
	update_wall_slide_state(delta)
	animations()
	sprite_flip()
	RigidBodyCollision()
	
	
	for platforms in get_slide_collision_count():
		var collision := get_slide_collision(platforms)
		if collision.get_collider().has_method("has_collided_with"):
			collision.get_collider().has_collided_with(collision, self)
			
	

func update_timers(delta: float) -> void:
	if roll_cooldown_timer > 0.0:
		roll_cooldown_timer -= delta
	
	if attack_buffer_timer > 0.0:
		attack_buffer_timer -= delta
	else:
		attack_queued = false
		
	if _inv_timer > 0.0:
		_inv_timer -= delta
		
	if hurt_timer > 0.0:
		hurt_timer -= delta
	else:
		is_hurt = false
	
	if push_buffer_timer > 0.0:
		push_buffer_timer -= delta

func read_action_inputs() -> void:
	if Input.is_action_just_pressed("attack"):
		request_attack()
	
	if Input.is_action_just_pressed("dash"):
		request_roll()


func request_attack() -> void:
	if is_rolling:
		cancel_roll_into_attack()
		return
	
	if is_attacking:
		attack_queued = true
		attack_buffer_timer = attack_buffer_time
		return
	
	start_attack()

func cancel_roll_into_attack() -> void:
	is_rolling = false
	set_collision_mask_value(enemy_collision_layer, false)
	velocity.x = roll_direction * horizontal_max_speed * attack_move_multiplier
	start_attack()

func start_attack() -> void:
	is_attacking = true
	attack_queued = false
	attack_buffer_timer = 0.0
	
	animation_sprite.play("attack")
	animation_sprite.frame = 0
	
	_swing_id += 1
	
	player_attack_area.set_meta("swing_id", _swing_id)
	player_attack_area.set_meta("damage", attack_damage)
	player_attack_area.set_meta("is_attacking", true)
	
	await get_tree().create_timer(0.08).timeout
	
	player_attack_area.monitoring = true
	attack_sound.play()
	
	await get_tree().create_timer(attack_hitbox_active_time).timeout
	
	# só desliga se ainda for o mesmo swing
	if player_attack_area.get_meta("swing_id", -1) == _swing_id:
		player_attack_area.monitoring = false
		player_attack_area.set_meta("is_attacking", false)


func request_roll() -> void:
	if roll_cooldown_timer > 0.0:
		return
	
	if not is_on_floor():
		return
	
	start_roll()


func start_roll() -> void:
	
	is_rolling = true
	is_attacking = false
	attack_queued = false
	wall_slide_active = false
	
	roll_cooldown_timer = roll_cooldown
	
	var input_dir := Input.get_axis("move_left", "move_right")
	
	if input_dir != 0.0:
		roll_direction = sign(input_dir)
	else:
		roll_direction = -1.0 if animation_sprite.flip_h else 1.0
	
	velocity = Vector2(roll_direction * roll_speed, 0.0)
	
	set_collision_mask_value(enemy_collision_layer, false)
	
	animation_sprite.play("roll")
	animation_sprite.frame = 0


func roll_movement(delta: float) -> void:
	# O roll agora termina pela animação, não pelo timer.
	velocity.x = roll_direction * roll_speed
	
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0


func end_roll() -> void:
	if not is_rolling:
		return

	is_rolling = false

	# IMPORTANTE:
	# Player não deve colidir fisicamente com Enemies nunca.
	# Então não reative a layer 3 na mask.
	set_collision_mask_value(enemy_collision_layer, false)


func horizontal_movement(delta: float) -> void:
	var horizontal_direction := Input.get_axis("move_left", "move_right")
	var target_velocity := horizontal_direction * horizontal_max_speed
	
	if is_attacking and is_on_floor():
		target_velocity *= attack_move_multiplier
	
	var target_weight := delta * (horizontal_acceleration if horizontal_direction else horizontal_deceleration)
	target_weight = clampf(target_weight, 0.0, 1.0)
	
	velocity.x = lerp(velocity.x, target_velocity, target_weight)


func jump_buffer(delta: float) -> void:
	if Input.is_action_just_pressed("move_jump"):
		jump_buffer_timer = jump_buffer_time
	
	if jump_buffer_timer > 0.0:
		jump_buffer_timer -= delta


func vertical_movement(delta: float) -> void:
	if is_on_floor() and jump_buffer_timer > 0.0:
		velocity.y = -sqrt(2.0 * gravity * jump_height)
		jump_buffer_timer = 0.0
	
	if not is_on_floor():
		velocity.y += gravity * delta


func can_wall_slide() -> bool:
	var horizontal_direction := Input.get_axis("move_left", "move_right")
	var wall_normal := get_wall_normal()
	
	if wall_normal.x != 0.0:
		last_wall_normal_x = wall_normal.x
	
	var pressing_wall := false
	
	if wall_normal.x != 0.0:
		pressing_wall = sign(horizontal_direction) == -sign(wall_normal.x)
	
	return is_on_wall() and not is_on_floor() and velocity.y > 0.0 and pressing_wall


func update_wall_slide_state(delta: float) -> void:
	var horizontal_direction := Input.get_axis("move_left", "move_right")
	
	if is_rolling or is_attacking:
		wall_slide_active = false
		return
	
	if can_wall_slide():
		wall_slide_active = true
		wall_slide_exit_timer = wall_slide_exit_time
	else:
		if wall_slide_active:
			wall_slide_exit_timer -= delta
			
			if is_on_floor() or velocity.y <= 0.0 or horizontal_direction == 0.0 or wall_slide_exit_timer <= 0.0:
				wall_slide_active = false


func wall_movement(_delta: float) -> void:
	if wall_slide_active and Input.is_action_just_pressed("move_jump"):
		var wall_normal_x := get_wall_normal().x
		
		if wall_normal_x == 0.0:
			wall_normal_x = last_wall_normal_x
		
		if wall_normal_x != 0.0:
			velocity.x = wall_normal_x * wall_jump
			velocity.y = -sqrt(2.0 * gravity * jump_height)
		
		wall_slide_active = false
		jump_buffer_timer = 0.0
		return
	
	if wall_slide_active:
		velocity.y = min(velocity.y, wall_gravity)


func sprite_flip() -> void:
	if is_rolling:
		animation_sprite.flip_h = roll_direction < 0.0
		return
	
	var horizontal_direction := Input.get_axis("move_left", "move_right")
	
	if wall_slide_active:
		var wall_normal_x := get_wall_normal().x
		
		if wall_normal_x == 0.0:
			wall_normal_x = last_wall_normal_x
		
		if wall_normal_x < 0.0:
			animation_sprite.flip_h = true
		elif wall_normal_x > 0.0:
			animation_sprite.flip_h = false
		
		return
	
	if horizontal_direction > 0.0:
		box_ray.target_position = Vector2(15,0)
		animation_sprite.flip_h = false
	elif horizontal_direction < 0.0:
		box_ray.target_position = Vector2(-15,0)
		animation_sprite.flip_h = true
		
	update_attack_facing()


func play_animation(anim_name: String) -> void:
	if animation_sprite.sprite_frames.has_animation(anim_name):
		if animation_sprite.animation != anim_name:
			animation_sprite.play(anim_name)


func animations() -> void:
	# Prioridade:
	# roll > attack > wall_slide > jump/fall > run > idle
	
	if is_hurt:
		play_animation("hurt")
		return
	
	if is_rolling:
		play_animation("roll")
		return
	
	if is_attacking:
		play_animation("attack")
		return
	
	if wall_slide_active:
		play_animation("wall_slide")
		return
	
	if not is_on_floor():
		if velocity.y < 0.0:
			play_animation("jump")
		else:
			play_animation("fall")
		return
	
	if push_buffer_timer > 0.0 and $BoxRay:
		play_animation("push")
	elif abs(velocity.x) > 10.0:
		play_animation("run")
	else:
		play_animation("idle")


func _on_animation_finished() -> void:
	match animation_sprite.animation:
		"attack":
			is_attacking = false
			
			# >>> ADICIONE ISTO (segurança):
			player_attack_area.monitoring = false
			player_attack_area.set_deferred("monitoring", false)
			
			if attack_queued and attack_buffer_timer > 0.0:
				start_attack()
			else:
				attack_queued = false
		
		"roll":
			end_roll()
			
		


func handle_death_zone() -> void:
	if is_respawning_from_fall:
		return
	
	is_respawning_from_fall = true
	
	Global.player_life -= 1
	life = Global.player_life
	
	velocity = Vector2.ZERO
	set_physics_process(false)
	set_process(false)
	
	if Global.player_life <= 0:
		death()
		is_respawning_from_fall = false
		return
	
	await SceneManager.play_transition_in()
	
	Global.respawn_player()
	velocity = Vector2.ZERO
	
	set_physics_process(true)
	set_process(true)
	visible = true
	
	await get_tree().process_frame
	await SceneManager.play_transition_out()
	
	is_respawning_from_fall = false


func take_damage(amount: int) -> void:
	hurt_sound.play()
	if is_dead:
		return

	if is_rolling:
		return

	if _inv_timer > 0.0:
		return

	_inv_timer = invincibility_time

	life -= amount
	
	Global.player_life = life
	
	if life <= 0:
		life = 0
		death()
		return

	# Só atualiza o Global se NÃO morreu
	

	is_hurt = true
	hurt_timer = hurt_lock_time

	if animation_sprite.sprite_frames.has_animation("hurt"):
		animation_sprite.play("hurt")
		animation_sprite.frame = 0

func death() -> void:
	if is_dead:
		return

	is_dead = true

	velocity = Vector2.ZERO
	is_hurt = false
	is_attacking = false
	is_rolling = false

	player_attack_area.set_deferred("monitoring", false)
	player_hurtbox.set_deferred("monitoring", false)
	
	player_attack_area.queue_free()
	player_hurtbox.queue_free()
	
	set_physics_process(false)

	animation_sprite.play("death")
	animation_sprite.frame = 0

	while animation_sprite.frame < animation_sprite.sprite_frames.get_frame_count("death") - 2:
		await get_tree().process_frame
	
	player_has_died.emit()


@onready var camera: Camera2D = $Camera2D

func _on_attack_area_2d_body_entered(body: Node2D) -> void:
	if body.has_method("break_sprite"):
		camera.shake(2.5, 0.05);
		body.hitpoints -= 1
		if body.hitpoints <= 0:
			body.break_sprite()
		else:
			body.animation_player.play("hit")
