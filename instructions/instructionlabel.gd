extends RichTextLabel

@export var characters_per_second: float = 30.0
@export var pause_between_messages: float = 1.5 # Seconds to wait before next text
@onready var audioplayer: AudioStreamPlayer = $AudioStreamPlayer



var dialog_messages: Array[String] = [
	"The world is now a dark and broken place..",
	"People are suffering as the world becomes more and more corupt.",
	"A legend is summoned every one thousand years to save the world...",
	"Is this your tale..",
	"Save the world",
	"....",
	""
]

var current_message_index: int = 0

func _ready() -> void:
	audioplayer.play()
	autowrap_mode = TextServer.AUTOWRAP_WORD
	visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	
	show_message(current_message_index)

func show_message(index: int) -> void:
	if index >= dialog_messages.size():
		print("All messages finished!")
		return
		
	text = dialog_messages[index]
	visible_characters = 0
	
	var total_chars: int = text.length()
	var duration: float = total_chars / characters_per_second
	
	var tween: Tween = create_tween()
	
	tween.tween_property(self, "visible_characters", total_chars, duration).from(0)
	
	tween.tween_interval(pause_between_messages)
	
	tween.finished.connect(_on_message_cycle_complete)

func _on_message_cycle_complete() -> void:
	if text == "":
		get_tree().change_scene_to_file("res://world/world.tscn")
	
	current_message_index += 1
	show_message(current_message_index)
