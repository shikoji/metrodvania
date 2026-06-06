extends Node2D

@onready var sprite_2d: Sprite2D = $texture
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var dialog_offset: Vector2 = Vector2(-35, -35)
@export var dialog_box_size: Vector2 = Vector2(60, 40)
@export var dialog_box_scale: Vector2 = Vector2(0.3, 0.3)

@export var dialog_lines: Array[String] = [
	"Oi! Seja bem-vindo ao arraial",
	"Dá uma olhada ao redor antes 
	de seguir adiante.",
	"Para seguir adiante, você vai 
	precisar de um item especial.",
	"Esse item está guardado em 
	um baú aqui na área.",
	"O baú só abre se você responder 
	uma pergunta de matemática.",
	"Depois de pegar o item, entregue
	 a quem bloqueia a passagem.",
	"Ela só deixa você passar com o 
	item certo. Boa sorte!"
]


var pode_interagir = false

var dialog_ativo := false


func _ready() -> void:
	sprite_2d.hide()
	DialogManager.dialog_finished.connect(_on_dialog_finished)
	
func _on_dialog_finished():
	dialog_ativo = false
	if pode_interagir:
		sprite_2d.show()

	
func _process(_delta: float) -> void:
	if get_tree().paused:
		return

	if not pode_interagir or dialog_ativo:
		return
	
	if Input.is_action_just_pressed("interact"):
		sprite_2d.hide()
		dialog_ativo = true

		DialogManager.start_dialog(
			global_position + dialog_offset,
			dialog_lines,
			dialog_box_size,
			dialog_box_scale
		)
	
func _on_area_sing_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		pode_interagir = true
		sprite_2d.show()
		animation_player.play("idle")


func _on_area_sing_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		pode_interagir = false
		sprite_2d.hide()
		
		if dialog_ativo:
			dialog_ativo = false
			DialogManager.end_dialog()
