extends Control

@onready var home_buttons: Control = $home_buttons
@onready var options: Control = $options


func _ready() -> void:
	home_buttons.visible = true
	options.visible = false

	home_buttons.open_options.connect(show_options)
	options.back_to_home.connect(show_home)

	home_buttons.focus_first_button()


func show_options() -> void:
	home_buttons.visible = false
	options.visible = true
	options.focus_first_option()


func show_home() -> void:
	options.visible = false
	home_buttons.visible = true
	home_buttons.focus_first_button()
