extends CanvasLayer

@onready var main_menu_game = $main_menu_game
@onready var options = $options


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	get_tree().root.set_meta("remap_is_waiting", false)
	
	visible = false

	main_menu_game.visible = true
	options.visible = false

	main_menu_game.continue_pressed.connect(_on_continue_pressed)
	main_menu_game.settings_pressed.connect(_on_settings_pressed)
	main_menu_game.menu_pressed.connect(_on_menu_pressed)

	options.back_to_home.connect(_on_options_back_pressed)


func _input(event: InputEvent) -> void:
	# Se a tela de remap do controle está aberta,
	# o botão Options/Start NÃO pode pausar o jogo.
	if options.visible:
		if options.has_method("is_controller_remap_menu_open"):
			if options.is_controller_remap_menu_open():
				if options.has_method("is_waiting_for_remap_input"):
					if options.is_waiting_for_remap_input():
						# Não marca como handled.
						# Assim o ControllerRemapMenu ainda consegue cadastrar o botão.
						return

				if event.is_action_pressed("pause"):
					get_viewport().set_input_as_handled()
					return

	var pressed_pause: bool = event.is_action_pressed("pause")
	var pressed_controller_back: bool = _is_controller_back_event(event)

	if not pressed_pause and not pressed_controller_back:
		return

	if pressed_pause:
		if visible:
			if options.visible:
				_on_options_back_pressed()
			else:
				close_pause_menu()
		else:
			open_pause_menu()

		get_viewport().set_input_as_handled()
		return

	if pressed_controller_back:
		if visible:
			if options.visible:
				_on_options_back_pressed()
			else:
				close_pause_menu()

			get_viewport().set_input_as_handled()
			return

func _is_controller_back_event(event: InputEvent) -> bool:
	if event is InputEventJoypadButton:
		var joy_button: InputEventJoypadButton = event as InputEventJoypadButton

		if joy_button.pressed and joy_button.button_index == JOY_BUTTON_B:
			return true

	return false

func open_pause_menu() -> void:
	visible = true
	get_tree().paused = true

	main_menu_game.visible = true
	options.visible = false

	main_menu_game.focus_first_button()


func close_pause_menu() -> void:
	get_tree().paused = false
	visible = false


func _on_continue_pressed() -> void:
	close_pause_menu()


func _on_settings_pressed() -> void:
	main_menu_game.visible = false
	options.visible = true

	options.focus_first_option()


func _on_options_back_pressed() -> void:
	options.visible = false
	main_menu_game.visible = true

	main_menu_game.focus_first_button()


func _on_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://main_menu/main_menu_scenes/main_menu.tscn")
