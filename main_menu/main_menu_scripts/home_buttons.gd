extends Control

@onready var play: Button = $Play
@onready var settings: Button = $Settings
@onready var credits: Button = $Credits
@onready var quit: Button = $Quit

@onready var left_selector: TextureRect = $Selector/LeftDecoration
@onready var right_selector: TextureRect = $Selector/RightDecoration


# Distância dos selectors para o texto do botão
@export var selector_gap: float = 10.0

# Quanto o botão selecionado aumenta
@export var selected_button_scale: Vector2 = Vector2(1.08, 1.08)

# Quanto os selectors andam para dentro ao clicar
@export var selector_press_distance: float = 10.0

# Velocidades das animações
@export var selector_move_time: float = 0.08
@export var selector_press_time: float = 0.08
@export var button_zoom_time: float = 0.12



var buttons: Array[Button] = []
var current_button: Button

var left_normal_position: Vector2
var right_normal_position: Vector2

var selector_move_tween: Tween
var selector_press_tween: Tween

var button_scale_tweens: Dictionary = {}

signal open_options

func _ready() -> void:
	buttons = [play, settings, credits, quit]

	# Conecta os sinais dos botões
	for button in buttons:
		button.focus_entered.connect(_on_button_focus_entered.bind(button))
		button.mouse_entered.connect(_on_button_mouse_entered.bind(button))
		button.button_down.connect(_on_button_down.bind(button))
		button.button_up.connect(_on_button_up)

	# Espera o VBoxContainer organizar os botões corretamente
	await get_tree().process_frame

	# Faz o zoom acontecer a partir do centro de cada botão
	for button in buttons:
		button.pivot_offset = button.size / 2.0




func _on_button_focus_entered(button: Button) -> void:
	select_button(button, true)

func _on_button_mouse_entered(button: Button) -> void:
	button.grab_focus()

func select_button(button: Button, animate_selector: bool = true) -> void:
	current_button = button

	# Volta todos ao tamanho normal
	for b in buttons:
		if b == button:
			animate_button_scale(b, selected_button_scale)
		else:
			animate_button_scale(b, Vector2.ONE)

	# Calcula onde os selectors devem ficar
	update_selector_positions(button)

	# Move os selectors para o botão selecionado
	move_selectors_to_normal_position(animate_selector)


func update_selector_positions(button: Button) -> void:
	var center_y := button.global_position.y + button.size.y / 2.0

	# Como o botão selecionado dá zoom,
	# calculamos a largura visual final dele
	var expanded_width := button.size.x * selected_button_scale.x
	var expanded_left_x := button.global_position.x - ((expanded_width - button.size.x) / 2.0)

	left_normal_position = Vector2(
		expanded_left_x - left_selector.size.x - selector_gap,
		center_y - left_selector.size.y / 2.0
	)

	right_normal_position = Vector2(
		expanded_left_x + expanded_width + selector_gap,
		center_y - right_selector.size.y / 2.0
	)


func move_selectors_to_normal_position(animate: bool = true) -> void:
	if selector_move_tween:
		selector_move_tween.kill()

	if selector_press_tween:
		selector_press_tween.kill()

	if not animate:
		left_selector.global_position = left_normal_position
		right_selector.global_position = right_normal_position
		return

	selector_move_tween = create_tween()
	selector_move_tween.set_trans(Tween.TRANS_SINE)
	selector_move_tween.set_ease(Tween.EASE_OUT)

	selector_move_tween.tween_property(
		left_selector,
		"global_position",
		left_normal_position,
		selector_move_time
	)

	selector_move_tween.parallel().tween_property(
		right_selector,
		"global_position",
		right_normal_position,
		selector_move_time
	)


func animate_button_scale(button: Button, target_scale: Vector2) -> void:
	# Cancela animação antiga desse botão, se houver
	if button_scale_tweens.has(button) and button_scale_tweens[button]:
		button_scale_tweens[button].kill()

	var tween := create_tween()
	button_scale_tweens[button] = tween

	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(
		button,
		"scale",
		target_scale,
		button_zoom_time
	)


func _on_button_down(button: Button) -> void:
	# Garante que, ao clicar com o mouse em outro botão,
	# ele seja tratado como o botão atual
	if current_button != button:
		select_button(button, true)

	var left_pressed_position := left_normal_position + Vector2(selector_press_distance, 0)
	var right_pressed_position := right_normal_position - Vector2(selector_press_distance, 0)

	if selector_press_tween:
		selector_press_tween.kill()

	selector_press_tween = create_tween()
	selector_press_tween.set_trans(Tween.TRANS_SINE)
	selector_press_tween.set_ease(Tween.EASE_OUT)

	selector_press_tween.tween_property(
		left_selector,
		"global_position",
		left_pressed_position,
		selector_press_time
	)

	selector_press_tween.parallel().tween_property(
		right_selector,
		"global_position",
		right_pressed_position,
		selector_press_time
	)


func _on_button_up() -> void:
	if selector_press_tween:
		selector_press_tween.kill()

	selector_press_tween = create_tween()
	selector_press_tween.set_trans(Tween.TRANS_SINE)
	selector_press_tween.set_ease(Tween.EASE_OUT)

	selector_press_tween.tween_property(
		left_selector,
		"global_position",
		left_normal_position,
		selector_press_time
	)

	selector_press_tween.parallel().tween_property(
		right_selector,
		"global_position",
		right_normal_position,
		selector_press_time
	)

func focus_first_button() -> void:
	await get_tree().process_frame
	play.grab_focus()

	await get_tree().process_frame
	select_button(play, false)

func _on_settings_pressed() -> void:
	open_options.emit()


func _on_credits_pressed() -> void:
	pass # Replace with function body.


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://phases/phases_scenes/test.tscn")
