extends CharacterBody2D
@export var max_hp: int = 5
@export var contact_damage: int = 10
@export var speed: float = 60.0
@export var gravity: float = 900.0

@export var turn_cooldown: float = 0.15
@export var attack_interval: float = 0.6
@export var hurt_stun_time: float = 0.18

@export var anim_walk: StringName = &"walk"
@export var anim_attack: StringName = &"attack"
@export var anim_hurt: StringName = &"hurt"
@export var anim_death: StringName = &"death" # você já ajustou o nome


@onready var anim: AnimatedSprite2D = $anim
@onready var wall_ray: RayCast2D = $RayCast2D
@onready var wall_ray2: RayCast2D = $RayCast2D3
@onready var floor_ray: RayCast2D = $RayCast2D2

@onready var hurtbox: Area2D = $HurtBoxArea2d
@onready var attack_area: Area2D = $AttackArea2d
@onready var hurt_shape: CollisionShape2D = $HurtBoxArea2d/CollisionShape2D
@onready var attack_shape: CollisionShape2D = $AttackArea2d/CollisionShape2D

var hp: int
var facing: int = 1 # começa pra direita

var _dead := false
var _attacking := false

var _turn_cd := 0.0
var _attack_cd := 0.0
var _hurt_timer := 0.0

var _player_in_range: Node = null
var _last_player_swing_id: int = -999999

# Flip base direita
var _wall_ray_base_pos: Vector2
var _wall_ray2_base_pos: Vector2
var _floor_ray_base_pos: Vector2
var _wall_ray_base_target: Vector2
var _wall_ray2_base_target: Vector2
var _floor_ray_base_target: Vector2
var _hurt_shape_base_pos: Vector2
var _attack_shape_base_pos: Vector2

@onready var texture_progress_bar: TextureProgressBar = $TextureProgressBar

func _ready() -> void:
	texture_progress_bar.value = max_hp
	hp = max_hp

	_wall_ray_base_pos = wall_ray.position
	_wall_ray2_base_pos = wall_ray2.position
	_floor_ray_base_pos = floor_ray.position
	_wall_ray_base_target = wall_ray.target_position
	_wall_ray2_base_target = wall_ray2.target_position
	_floor_ray_base_target = floor_ray.target_position
	_hurt_shape_base_pos = hurt_shape.position
	_attack_shape_base_pos = attack_shape.position

	# Sinais
	if not attack_area.area_entered.is_connected(_on_attack_area_area_entered):
		attack_area.area_entered.connect(_on_attack_area_area_entered)
	if not attack_area.area_exited.is_connected(_on_attack_area_area_exited):
		attack_area.area_exited.connect(_on_attack_area_area_exited)

	if not hurtbox.area_entered.is_connected(_on_hurtbox_area_entered):
		hurtbox.area_entered.connect(_on_hurtbox_area_entered)

	if not anim.animation_finished.is_connected(_on_anim_finished):
		anim.animation_finished.connect(_on_anim_finished)

	update_facing()
	_play_walk()

func _physics_process(delta: float) -> void:
	if is_instance_valid(texture_progress_bar):
		texture_progress_bar.value = lerpf(
			texture_progress_bar.value,
			hp,
			5.0 * delta
		)

	if hp <= 0:
		if is_instance_valid(texture_progress_bar):
			texture_progress_bar.queue_free()

		_dead = true
	
	if _dead:
		return

	_turn_cd = maxf(0.0, _turn_cd - delta)
	_attack_cd = maxf(0.0, _attack_cd - delta)
	_hurt_timer = maxf(0.0, _hurt_timer - delta)

	# gravidade
	if not is_on_floor():
		velocity.y += gravity * delta

	# trava movimento se hurt ou atacando
	var can_move := (_hurt_timer <= 0.0) and (not _attacking)
	velocity.x = (float(facing) * speed) if can_move else 0.0
	move_and_slide()

	# virar
	if can_move and is_on_floor() and _turn_cd <= 0.0:
		wall_ray.force_raycast_update()
		wall_ray2.force_raycast_update()
		floor_ray.force_raycast_update()
		if wall_ray.is_colliding() or wall_ray2.is_colliding() or not floor_ray.is_colliding():
			flip_direction()
			_turn_cd = turn_cooldown

	# atacar
	if _player_in_range != null and (not _attacking) and _attack_cd <= 0.0 and _hurt_timer <= 0.0:
		attack_player()

	# manter walk quando não está atacando nem hurt
	if not _attacking and _hurt_timer <= 0.0:
		_play_walk()
		
		
	# Fallback: se "hurt" acabou e ficou no último frame, volta pro walk
	if not _dead and anim.animation == "hurt" and not anim.is_playing():
		_hurt_timer = 0.0
		_play_walk()

	# (Opcional) mesmo para attack, se quiser:
	if not _dead and anim.animation == "attack" and not anim.is_playing():
		_attacking = false
		_play_walk()

# -------------------------
# Direção / flip
# -------------------------
func flip_direction() -> void:
	facing *= -1
	update_facing()

func update_facing() -> void:
	anim.flip_h = (facing == -1)
	var xsign := 1.0 if facing == 1 else -1.0

	# flip shapes
	hurt_shape.position.x = _hurt_shape_base_pos.x * xsign
	attack_shape.position.x = _attack_shape_base_pos.x * xsign

	# flip raycasts
	wall_ray.position = Vector2(_wall_ray_base_pos.x * xsign, _wall_ray_base_pos.y)
	wall_ray2.position = Vector2(_wall_ray2_base_pos.x * xsign, _wall_ray2_base_pos.y)
	wall_ray.target_position = Vector2(_wall_ray_base_target.x * xsign, _wall_ray_base_target.y)
	wall_ray2.target_position = Vector2(_wall_ray2_base_target.x * xsign, _wall_ray2_base_target.y)

	floor_ray.position = Vector2(_floor_ray_base_pos.x * xsign, _floor_ray_base_pos.y)
	floor_ray.target_position = Vector2(_floor_ray_base_target.x * xsign, _floor_ray_base_target.y)

# -------------------------
# Combate
# -------------------------
func attack_player() -> void:
	if _dead or _attacking or _player_in_range == null:
		return
	
	if _attack_cd > 0.0:
		return

	_attacking = true
	_attack_cd = attack_interval
	velocity.x = 0.0

	# toca animação
	if anim.sprite_frames and anim.sprite_frames.has_animation(anim_attack):
		anim.play(anim_attack)

	# espera o frame do golpe
	await get_tree().create_timer(0.25).timeout

	# segurança
	if _dead:
		return
	
	if not _attacking:
		return
	
	if _player_in_range == null:
		return

	# aplica dano no timing do ataque
	_apply_damage_to_player(_player_in_range)

func take_damage(amount: int) -> void:
	if _dead:
		return

	hp -= amount

	# cancela ataque ao tomar dano (evita travas)
	_attacking = false
	_attack_cd = 0.0

	_hurt_timer = hurt_stun_time
	if anim.sprite_frames and anim.sprite_frames.has_animation(anim_hurt):
		anim.play(anim_hurt)

	if hp <= 0:
		death()

func death() -> void:
	if _dead:
		return

	_dead = true
	_attacking = false
	velocity = Vector2.ZERO

	# Turn off areas safely after the signal finishes
	attack_area.set_deferred("monitoring", false)
	hurtbox.set_deferred("monitoring", false)

	# Optional: disable collision shapes too
	attack_shape.set_deferred("disabled", true)
	hurt_shape.set_deferred("disabled", true)

	if anim.sprite_frames and anim.sprite_frames.has_animation(anim_death):
		anim.play(anim_death)
	else:
		queue_free()

func _apply_damage_to_player(player: Node) -> void:
	if player and player.has_method("take_damage"):
		player.call("take_damage", contact_damage)

# -------------------------
# Sinais
# -------------------------
func _on_attack_area_area_entered(area: Area2D) -> void:
	if _dead:
		return
	var player := area.get_parent()
	if player and player.has_method("take_damage"):
		_player_in_range = player

func _on_attack_area_area_exited(area: Area2D) -> void:
	var player := area.get_parent()
	if player == _player_in_range:
		_player_in_range = null




func _on_hurtbox_area_entered(area: Area2D) -> void:
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

func _on_anim_finished() -> void:
	if _dead:
		if anim.animation == String(anim_death):
			queue_free()
		return

	if anim.animation == String(anim_attack):
		_attacking = false
		_play_walk()
		return

	if anim.animation == String(anim_hurt):
		_hurt_timer = 0.0
		_play_walk()

func _play_walk() -> void:
	if _dead:
		return
	# só bloqueia se realmente está atacando OU ainda está dentro do stun
	if _attacking or _hurt_timer > 0.0:
		return

	# tenta tocar walk; se não existir, tenta "idle"; se não existir, para o sprite
	if anim.sprite_frames:
		if anim.sprite_frames.has_animation(anim_walk):
			if anim.animation != String(anim_walk):
				anim.play(anim_walk)
			return
		elif anim.sprite_frames.has_animation(&"idle"):
			if anim.animation != "idle":
				anim.play("idle")
			return

	anim.stop()
