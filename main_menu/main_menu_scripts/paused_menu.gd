extends CanvasLayer

@onready var main_menu_game = $main_menu_game
@onready var options = $options


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	visible = false

	main_menu_game.visible = true
	options.visible = false

	# Sinais dos botões do menu de pausa
	main_menu_game.continue_pressed.connect(_on_continue_pressed)
	main_menu_game.settings_pressed.connect(_on_settings_pressed)
	main_menu_game.menu_pressed.connect(_on_menu_pressed)

	# Sinal do botão Back das configurações
	options.back_to_home.connect(_on_options_back_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if visible:
			if options.visible:
				_on_options_back_pressed()
			else:
				close_pause_menu()
		else:
			open_pause_menu()

		get_viewport().set_input_as_handled()


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
