extends Node

@onready var text_box_scene = preload("res://dialog/dialog_scene/text_box.tscn")

var dialog_lines: Array[String] = []
var current_line_index = 0

var text_box
var text_box_position: Vector2

var is_dialog_active = false
var can_advance_line = false

@export var default_dialog_box_size: Vector2 = Vector2(350, 90)
var dialog_box_size: Vector2

var dialog_box_scale: Vector2 = Vector2.ONE

signal dialog_finished


func start_dialog(
	world_position: Vector2,
	lines: Array[String],
	box_size: Vector2 = Vector2.ZERO,
	box_scale: Vector2 = Vector2.ONE
):
	if is_dialog_active:
		return
	if lines.is_empty():
		return
	
	dialog_lines = lines.duplicate()
	current_line_index = 0
	is_dialog_active = true
	
	text_box_position = world_position
	
	
	if box_size == Vector2.ZERO:
		dialog_box_size = default_dialog_box_size
	else:
		dialog_box_size = box_size
	

	dialog_box_scale = box_scale
	
	_show_text_box()

func end_dialog():
	if not is_dialog_active:
		return
	
	if is_instance_valid(text_box):
		text_box.queue_free()
	
	is_dialog_active = false
	can_advance_line = false
	current_line_index = 0
	dialog_lines.clear()
	
	dialog_finished.emit() 



	
func _show_text_box():
	text_box = text_box_scene.instantiate()
	text_box.finished_displaying.connect(_on_text_box_finished_displaying)
	get_tree().current_scene.add_child(text_box)
	
	text_box.custom_minimum_size = dialog_box_size
	text_box.size = dialog_box_size
	text_box.position = text_box_position
	
	text_box.scale = dialog_box_scale
	
	text_box.display_text(dialog_lines[current_line_index])
	can_advance_line = false
	
func _on_text_box_finished_displaying():
	can_advance_line = true
	
func _unhandled_input(event):
	if (
		event.is_action_pressed("advance_dialog") &&
		is_dialog_active &&
		can_advance_line
	):
		if is_instance_valid(text_box):
			text_box.queue_free()
		
		current_line_index += 1
		if current_line_index >= dialog_lines.size():
			is_dialog_active = false
			current_line_index = 0
			text_box.queue_free()
			dialog_finished.emit()
			return

		_show_text_box()
	
	
	
