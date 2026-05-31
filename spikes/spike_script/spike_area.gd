@tool
extends Area2D

@export var knockback_x := 300.0
@export var knockback_y := 600.0
@export var damage: int = 0
@export var rect_length: Rect2 = Rect2(0, 9, 47, 7):
	set(value):
		rect_length = value
		if is_inside_tree():
			call_deferred("aplicar_region")

@export var collision_multiplier := 2.0:
	set(value):
		collision_multiplier = value
		if is_inside_tree():
			call_deferred("aplicar_region")

var ultimo_rect: Rect2
var ultimo_multiplier := -1.0

func _ready() -> void:
	aplicar_region()
	
	if Engine.is_editor_hint():
		set_process(true)
	else:
		set_process(false)

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		return
	
	if rect_length != ultimo_rect or collision_multiplier != ultimo_multiplier:
		aplicar_region()

func pegar_sprite() -> Sprite2D:
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	
	if sprite == null:
		sprite = get_node_or_null("Area2D") as Sprite2D
	
	return sprite

func aplicar_region() -> void:
	if not is_inside_tree():
		return
	
	var sprite := pegar_sprite()
	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	
	ultimo_rect = rect_length
	ultimo_multiplier = collision_multiplier
	
	if sprite != null:
		sprite.region_enabled = true
		sprite.region_rect = rect_length
		sprite.queue_redraw()
	
	if collision != null:
		if collision.shape == null:
			collision.shape = RectangleShape2D.new()
		
		if collision.shape is RectangleShape2D:
			var rect_shape := collision.shape as RectangleShape2D
			rect_shape.size = rect_length.size * collision_multiplier

func _on_body_entered(body: Node2D) -> void:
	if Engine.is_editor_hint():
		return

	if not body.has_method("take_damage"):
		return

	var direction: float = 1.0

	if body is CharacterBody2D:
		direction = -sign(body.velocity.x)

	if direction == 0:
		direction = sign(body.global_position.x - global_position.x)

	if direction == 0:
		direction = 1.0

	var knockback := Vector2(knockback_x * direction, -knockback_y)

	# aplica dano
	body.take_damage(damage)
	
	if body.has_method("apply_knockback"):
		body.apply_knockback(knockback)

	# aplica empurrão
	if body is CharacterBody2D:
		body.velocity = knockback
