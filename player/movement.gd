extends CharacterBody2D
class_name Player
@onready var animation_sprite: AnimatedSprite2D = $animation_sprite

@export_group("help")
@export var compass_target: Node2D

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

var is_throwing = false

#==box valuies
var PushForce:int = 200
var push_buffer_timer: float = 0.0
@onready var box_ray = $BoxRay
@onready var box_ray_head = $BoxRayHead

# --- Hitboxes / Hurtboxes (NÃO mexe no resto do player) ---
@onready var player_hurtbox: Area2D = $HurtBoxArea2d
@onready var player_attack_area: Area2D = $AttackArea2d

@export var attack_damage: int = 1
@export var attack_hitbox_active_time: float = 0.10  # tempo que a hitbox fica ativa dentro do ataque
@export var invincibility_time: float = 0.25         # i-frames após tomar dano

var _inv_timer: float = 0.0
var _swing_id: int = 0

@onready var player_attack_shape: CollisionShape2D = $AttackArea2d/SlamCollisionShape
@onready var player_stab_shape: CollisionShape2D = $AttackArea2d/StabCollisionShape

var _attack_shape_base_pos: Vector2


@export var hurt_lock_time: float = 0.25
var is_hurt: bool = false
var hurt_timer: float = 0.0

var is_dead: bool = false

@onready var attack_sound: AudioStreamPlayer2D = $AttackSound
@onready var hurt_sound: AudioStreamPlayer2D = $HurtSound

#climb
var on_ladder: bool = false
var climbing: bool = false
var ladders_touching: int = 0

@export var climb_speed: float = 120.0
@export var ladder_horizontal_speed: float = 60.0

const POWER_MODE_SHADER = preload("res://player/power_mode.tres")



@onready var compass: Node2D = $Compass

func enable_compass() -> void:
	compass.enable_compass()

func set_compass_target(target: Node2D) -> void:
	compass.set_target(target)

func disable_compass() -> void:
	compass.disable_compass()



func update_attack_facing() -> void:
	# Se flip_h = true, player está olhando pra ESQUERDA.
	var xsign := -1.0 if animation_sprite.flip_h else 1.0
	player_attack_shape.position.x = _attack_shape_base_pos.x * xsign
	player_stab_shape.position.x = _attack_shape_base_pos.x * xsign
	

func _ready() -> void:
	_attack_shape_base_pos = player_attack_shape.position

	life = max_life
	Global.player_life = life

	# mantém seu connect atual
	if not animation_sprite.animation_finished.is_connected(_on_animation_finished):
		animation_sprite.animation_finished.connect(_on_animation_finished)

	box_ray_head.add_exception(self)

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
			
			if normal.y > 0.5: 
				body.apply_central_impulse(Vector2.UP * PushForce * 1.5)
				if velocity.y < 0:
					velocity.y = 0
				continue 
			
			if normal.y < -0.7:
				continue
				
			if box_ray.is_colliding():
				push_buffer_timer = 0.15
				var push_direction := Vector2(-normal.x, 0.0).normalized()
				body.apply_central_impulse(push_direction * PushForce)
				velocity.x = lerp(velocity.x, 0.0, 0.25)
			
func _physics_process(delta: float) -> void:
	if is_dead:
		return
	update_timers(delta)
	if is_dead:
		return
	read_action_inputs()
	jump_buffer(delta)
	
	if is_rolling:
		roll_movement(delta)
	else:

		ladder_movement()

		if not climbing:
			horizontal_movement(delta)
			vertical_movement(delta)

	wall_movement(delta)
	
	var input_dir := Input.get_axis("move_left", "move_right")

	if box_ray_head.is_colliding():
		var top_body = box_ray_head.get_collider()
		if top_body is RigidBody2D:
			if input_dir != 0:

				top_body.global_position.x += input_dir * 1.5
				top_body.global_position.y -= 1.0 
			
				top_body.linear_velocity = Vector2(input_dir * PushForce * 0.5, -50.0)

	was_on_floor = is_on_floor()


		
	move_and_slide()
	
	if is_dead:
		return
	
	activate_power_mode()
	
	if is_dead:
		return
	
	update_wall_slide_state(delta)
	var previous_direction = animation_sprite.flip_h
	animations()
	
	if is_dead:
		return
	
	sprite_flip()
	RigidBodyCollision()
	if is_on_floor():
		if previous_direction != animation_sprite.flip_h:
			last_footstep_played = 0
		process_walking_footsteps()
		process_walking_particles()

	
	
	for platforms in get_slide_collision_count():
		var collision := get_slide_collision(platforms)
		if collision.get_collider().has_method("has_collided_with"):
			collision.get_collider().has_collided_with(collision, self)
			
	

var was_on_floor = true
var last_footstep_played = 0
var last_footstep_emitted = 0



func process_walking_footsteps():
	if animation_sprite.animation == "run":
		if animation_sprite.frame == 2 and last_footstep_played != 2:
			last_footstep_played = 2
			play_footstep(1.0)
		if animation_sprite.frame == 6 and last_footstep_played != 6:
			last_footstep_played = 6
			play_footstep(1.2)
	if not was_on_floor:
		play_footstep(0.7)

func process_walking_particles():
	if animation_sprite.animation != "run":
		return
	if (animation_sprite.frame == 1 or animation_sprite.frame == 5) and last_footstep_emitted != animation_sprite.frame:
		last_footstep_emitted = animation_sprite.frame
		var instance
		if animation_sprite.flip_h:
			instance = $FootStepParticleFlip.duplicate()
		else:
			instance = $FootStepParticle.duplicate()
		add_child(instance)
		instance.emitting = true
		instance.connect("finished", instance.queue_free)

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
	
	if power_mode:
		power_mode_hit_rate -= delta
		if power_mode_hit_rate <= 0:
			life -= 50
			Global.player_life = life
			power_mode_hit_rate = 0.5
			if Global.player_life <= 0:
				death()
				return

@export_category("Abilits")
@export var power_mode_hit_rate = 0.5

func read_action_inputs() -> void:
	if Input.is_action_just_pressed("attack"):
		request_attack()
	
	if Input.is_action_just_pressed("dash") and Abilities.roll:
		request_roll()
	
	if Input.is_action_just_pressed("throw_bomb") and Abilities.bomb:
		if current_bomb == null:
			throw_bomb()
		else:
			current_bomb.explode()
	
	if Input.is_action_just_pressed("throw_ground") and Abilities.ground_bomb:
		if current_ground_bomb == null:
			throw_ground_bomb()
		else:
			current_ground_bomb.explode()

const BOMB = preload("res://bombs/bomb/bomb.tscn")
const GROUND_BOMB = preload("res://bombs/ground_bomb/ground_bomb.tscn")

var current_bomb: Bomb
var current_ground_bomb: GroundBomb

func throw_bomb() -> void:
	is_throwing = true
	animation_sprite.play("throw")
	animation_sprite.frame = 0

	await get_tree().create_timer(0.08).timeout
	
	current_bomb = spawn_bomb(BOMB)

	await animation_sprite.animation_finished
	
	is_throwing = false


func throw_ground_bomb() -> void:
	is_throwing = true
	animation_sprite.play("throw")
	animation_sprite.frame = 0

	await get_tree().create_timer(0.08).timeout
	
	current_ground_bomb = spawn_bomb(GROUND_BOMB)

	await animation_sprite.animation_finished
	
	is_throwing = false

func spawn_bomb(bomb_resource: Resource) -> RigidBody2D:
	const THROW_FORCE = Vector2(250.0, 300.0)
	var facing_left = animation_sprite.flip_h
	var instance: RigidBody2D = bomb_resource.instantiate()
	instance.position = position
	add_sibling(instance)
	var forward_force = -THROW_FORCE.x if facing_left else THROW_FORCE.x
	instance.apply_impulse(Vector2(forward_force, -THROW_FORCE.y))
	instance.angular_velocity = -20.0 if facing_left else 20.0
	return instance

func request_attack() -> void:
	if is_rolling:
		cancel_roll_into_attack()
		return
	
	if is_attacking:
		attack_queued = true
		attack_buffer_timer = attack_buffer_time
		return
	
	start_attack(AttackTypes.SLAM)

func cancel_roll_into_attack() -> void:
	is_rolling = false
	set_collision_mask_value(enemy_collision_layer, false)
	velocity.x = roll_direction * horizontal_max_speed * attack_move_multiplier
	start_attack(AttackTypes.STAB)

enum AttackTypes { SLAM, STAB }

func start_attack(type: AttackTypes) -> void:
	climbing = false
	is_attacking = true
	attack_queued = false
	attack_buffer_timer = 0.0
	match type:
		AttackTypes.SLAM:
			animation_sprite.play("attack")
			animation_sprite.frame = 0
	
			_swing_id += 1
	
			player_attack_area.set_meta("swing_id", _swing_id)
			player_attack_area.set_meta("damage", attack_damage)
			player_attack_area.set_meta("is_attacking", true)
	
			await get_tree().create_timer(0.08).timeout
	
			$AttackArea2d/SlamCollisionShape.disabled = false
			player_attack_area.monitoring = true
			attack_sound.play()
			attack_sound.pitch_scale = 1.0
	
			await get_tree().create_timer(attack_hitbox_active_time).timeout
	
			# só desliga se ainda for o mesmo swing
			if player_attack_area.get_meta("swing_id", -1) == _swing_id:
				player_attack_area.monitoring = false
				$AttackArea2d/SlamCollisionShape.disabled = true
				player_attack_area.set_meta("is_attacking", false)
		AttackTypes.STAB:
			animation_sprite.play("stab")
			animation_sprite.frame = 0
			_swing_id += 1
			
			player_attack_area.set_meta("swing_id", _swing_id)
			player_attack_area.set_meta("damage", attack_damage)
			player_attack_area.set_meta("is_attacking", true)
			await get_tree().create_timer(0.02).timeout
			$AttackArea2d/StabCollisionShape.disabled = false
			player_attack_area.monitoring = true
			attack_sound.play()
			attack_sound.pitch_scale = 1.5
	
			await get_tree().create_timer(attack_hitbox_active_time).timeout
	
			# só desliga se ainda for o mesmo swing
			if player_attack_area.get_meta("swing_id", -1) == _swing_id:
				player_attack_area.monitoring = false
				$AttackArea2d/StabCollisionShape.disabled = true
				player_attack_area.set_meta("is_attacking", false)

func request_roll() -> void:
	if roll_cooldown_timer > 0.0:
		return
	
	if not is_on_floor():
		return
	
	start_roll()

var power_mode = false

func activate_power_mode():
	if Input.is_action_just_pressed("parasite") and not power_mode and Abilities.power_mode:
		print("hello?")
		power_mode = true
		animation_sprite.material = POWER_MODE_SHADER
		attack_damage *= 2
		$PowerMode.emitting = true

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
	$colider.position.y = 9.0
	$colider.shape.size.y = 10.0


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
	$colider.position.y = 2.0
	$colider.shape.size.y = 26.0

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

var double_jump = false

func jump_buffer(delta: float) -> void:
	if Input.is_action_just_pressed("move_jump"):
		jump_buffer_timer = jump_buffer_time
	
	if jump_buffer_timer > 0.0:
		jump_buffer_timer -= delta

func vertical_movement(delta: float) -> void:
	if climbing:
		return
	
	if is_on_floor() and not double_jump and Abilities.double_jump:
		double_jump = true

	if is_on_floor() and jump_buffer_timer > 0.0:
		play_footstep(0.5)
		velocity.y = -sqrt(2.0 * gravity * jump_height)
		jump_buffer_timer = 0.0
	
	if double_jump and jump_buffer_timer > 0.0:
		velocity.y = -sqrt(2.0 * gravity * jump_height)
		jump_buffer_timer = 0.0
		double_jump = false
	
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
	if climbing:
		wall_slide_active = false
		return
	
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
	if climbing:
		return
	
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
	if climbing:
		return
	
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
	
	if is_dead:
		return
	
	if not climbing:
		animation_sprite.speed_scale = 1.0
	
	if is_hurt:
		play_animation("hurt")
		return
	
	if is_rolling:
		play_animation("roll")
		return
	
	if is_attacking:
		if animation_sprite.animation == "stab":
			play_animation("stab")
		else:
			play_animation("attack")
		return

	if is_throwing:
		play_animation("throw")
		return
	
	if climbing:
		animation_sprite.play("climb")

		if abs(velocity.y) > 0 or abs(velocity.x) > 0:
			animation_sprite.speed_scale = 1.0
		else:
			animation_sprite.speed_scale = 0.0

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
			
			# SAFETY
			player_attack_area.monitoring = false
			player_attack_area.set_deferred("monitoring", false)
			
			if attack_queued and attack_buffer_timer > 0.0:
				start_attack(AttackTypes.STAB)
			else:
				attack_queued = false
		"stab":
			is_attacking = false
			
			# SAFETY
			player_attack_area.monitoring = false
			player_attack_area.set_deferred("monitoring", false)
			if attack_queued and attack_buffer_timer > 0.0:
				start_attack(AttackTypes.SLAM)
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

func apply_knockback(force: Vector2) -> void:
	velocity = force

func take_damage(amount: int) -> void:
	if is_dead:
		return

	if is_rolling:
		return

	if _inv_timer > 0.0:
		return

	_inv_timer = invincibility_time

	life -= amount
	Global.player_life = life
	
	hurt_sound.play()
	var particles = ParticleHelper.spawn_particles(position)
	var particles_material: ParticleProcessMaterial = particles.process_material
	particles_material.color = Color.RED
	
	if life <= 0:
		life = 0
		death()
		return

	# Só atualiza o Global se NÃO morreu
	

	is_hurt = true
	hurt_timer = hurt_lock_time

	if animation_sprite.sprite_frames.has_animation("hurt"):
		animation_sprite.play("hurt")
		#animation_sprite.frame = 0

func death() -> void:
	if is_dead:
		return

	is_dead = true
	power_mode = false

	velocity = Vector2.ZERO
	is_hurt = false
	is_attacking = false
	is_rolling = false
	climbing = false
	wall_slide_active = false

	player_attack_area.set_deferred("monitoring", false)
	player_hurtbox.set_deferred("monitoring", false)

	set_physics_process(false)

	# Opcional: remove shader do power mode na morte
	animation_sprite.material = null
	$PowerMode.emitting = false

	animation_sprite.speed_scale = 1.0
	animation_sprite.play("death")
	animation_sprite.frame = 0

	await animation_sprite.animation_finished

	player_has_died.emit()

func play_footstep(pitch_scale: float = 1.0, volume_db :float = 0.0):
	var instance: AudioStreamPlayer2D = $Footstep.duplicate()
	add_child(instance)
	instance.pitch_scale = pitch_scale
	instance.volume_db = volume_db
	instance.bus = "Sounds"
	instance.play()
	instance.connect("finished", instance.queue_free)

@onready var camera: Camera2D = $Camera2D

func _on_attack_area_2d_body_entered(body: Node2D) -> void:
	if body is TileMapLayer:
		return
	var _particle = ParticleHelper.spawn_particles($AttackArea2d/SlamCollisionShape.global_position)
	
	if body.has_method("break_sprite"):
		camera.shake(2.5, 0.05);
		body.hitpoints -= attack_damage
		if body.hitpoints <= 0:
			body.break_sprite()
		else:
			body.animation_player.play("hit")

func ladder_movement() -> void:

	var vertical := Input.get_axis("move_up", "move_down")
	var horizontal := Input.get_axis("move_left", "move_right")
	
	if not on_ladder:
		climbing = false
	
	if on_ladder and (abs(vertical) > 0 or abs(horizontal) > 0):
		climbing = true

	if not climbing:
		return
		
	if climbing:
		velocity.x = horizontal * ladder_horizontal_speed
		velocity.y = vertical * climb_speed

	if Input.is_action_just_pressed("move_jump"):
		climbing = false
		velocity.y = -sqrt(2.0 * gravity * jump_height)
