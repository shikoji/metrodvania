extends Control

@export_file("*.tscn") var main_menu_scene: String = "res://main_menu/main_menu_scenes/main_menu.tscn"

@export var scroll_speed: float = 65.0
@export var start_delay: float = 0.8
@export var end_delay: float = 0.0

@export var main_title_size: int = 56
@export var section_title_size: int = 42
@export var name_size: int = 26
@export var line_separation: int = 8

@onready var credits_area: Control = $CreditsArea
@onready var credits_content: VBoxContainer = $CreditsArea/CreditsContent

var _returning_to_menu: bool = false
var _scrolling: bool = false
var _finished_credits: bool = false
var _last_credit_label: Label = null

const CREDIT_SECTIONS: Array[Dictionary] = [
	{
		"title": "ARTISTS",
		"color": Color(1.0, 0.25, 0.20),
		"names": [
			"Alex",
			"Kyryl",
			"Visclo"
		]
	},
	{
		"title": "PROGRAMMING",
		"color": Color(0.25, 0.70, 1.0),
		"names": [
			"Robson",
			"Kyryl",
			"Visclo"
		]
	},
	{
		"title": "MUSIC AND SOUND",
		"color": Color(0.85, 0.45, 1.0),
		"names": [
			"Danny",
			"Kyryl",
			"Visclo",
			"Robson"
		]
	},
	{
		"title": "LEVEL DESIGN",
		"color": Color(1.0, 0.80, 0.25),
		"names": [
			"Visclo"
		]
	}
]


func _ready() -> void:
	set_process(false)
	
	credits_area.clip_contents = true
	
	_build_credits()
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	credits_content.custom_minimum_size.x = credits_area.size.x
	credits_content.size.x = credits_area.size.x
	
	# Começa embaixo da tela.
	credits_content.position = Vector2(0.0, credits_area.size.y)
	
	await get_tree().create_timer(start_delay).timeout
	
	_scrolling = true
	set_process(true)


func _process(delta: float) -> void:
	if not _scrolling:
		return
	
	if _returning_to_menu:
		return
	
	# Move os créditos para cima.
	credits_content.position.y -= scroll_speed * delta
	
	# Quando o último texto sair pelo topo da tela, termina.
	if is_instance_valid(_last_credit_label):
		var last_rect: Rect2 = _last_credit_label.get_global_rect()
		var last_bottom_y: float = last_rect.position.y + last_rect.size.y
		
		if last_bottom_y <= 0.0:
			_finish_credits()


func _build_credits() -> void:
	for child in credits_content.get_children():
		child.queue_free()
	
	credits_content.add_theme_constant_override("separation", line_separation)
	
	_add_spacer(120)
	_add_label("CREDITS", Color.WHITE, main_title_size, true)
	_add_spacer(80)
	
	for section: Dictionary in CREDIT_SECTIONS:
		_add_label(str(section["title"]), section["color"] as Color, section_title_size, true)
		_add_spacer(10)
		
		var names: Array = section["names"]
		for person_name in names:
			_add_label(str(person_name), Color(0.88, 0.88, 0.88), name_size, false)
		
		_add_spacer(50)
	
	_add_spacer(200)
	
	_last_credit_label = _add_label("THANK YOU FOR PLAYING", Color.WHITE, 32, true)


func _add_label(text: String, color: Color, font_size: int, with_outline: bool) -> Label:
	var label := Label.new()
	
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.custom_minimum_size.y = font_size + 14
	
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	
	if with_outline:
		label.add_theme_constant_override("outline_size", 3)
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	
	credits_content.add_child(label)
	return label


func _add_spacer(height: float) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, height)
	credits_content.add_child(spacer)


func _finish_credits() -> void:
	if _finished_credits:
		return
	
	_finished_credits = true
	_scrolling = false
	set_process(false)
	
	if end_delay > 0.0:
		await get_tree().create_timer(end_delay).timeout
	
	_go_to_main_menu()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		_go_to_main_menu()


func _go_to_main_menu() -> void:
	if _returning_to_menu:
		return
	
	if main_menu_scene.is_empty():
		push_error("Main menu scene path is empty.")
		return
	
	if not ResourceLoader.exists(main_menu_scene):
		push_error("Main menu scene does not exist: " + main_menu_scene)
		return
	
	_returning_to_menu = true
	
	var error := get_tree().change_scene_to_file(main_menu_scene)
	
	if error != OK:
		_returning_to_menu = false
		push_error("Could not change to main menu scene: " + main_menu_scene + " | Error code: " + str(error))
