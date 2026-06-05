extends MarginContainer

@onready var label: Label = $MarginContainer/Label



signal finished_displaying

var text := ""
var letter_index := 0

var time_acc := 0.0

var letter_time := 0.07
var space_time := 0.05
var punctuation_time := 0.12

var current_delay := 0.03
var is_typing := false

var fast_forward := false

#const MAX_WIDTH := 220

@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var continue_label: AnimatedSprite2D = $MarginContainer/MarginContainer/ContinueLabel

func _ready():
	audio_stream_player_2d.volume_db = -25

func display_text(text_to_display: String):
	continue_label.hide()
	text = text_to_display.replace("\\n", "\n")
	letter_index = 0
	label.text = ""
	time_acc = 0
	is_typing = true
	#custom_minimum_size.x = MAX_WIDTH
	
	

func _process(delta):
	if not is_typing:
		return
		
	var speed := 1.0
	if fast_forward:
		speed = 6.0
	
	time_acc += delta * speed
	
	if time_acc < current_delay:
		return
	
	time_acc = 0
	
	#label.text += text[letter_index]
	
	var letra := text[letter_index]

	if letra == "\n":
		label.text += "\n"
	else:
		label.text += letra
		
		if letra != "" \
		and letra != "." \
		and letra != "," \
		and letra != "!" \
		and letra != "?" \
		and letra != "\n":
			audio_stream_player_2d.pitch_scale = randf_range(0.95, 1.05)
			play_letter_sound()
	
	letter_index += 1
	if letter_index >= text.length():
		is_typing = false
		continue_label.show()
		continue_label.play("idle")
		finished_displaying.emit()
		return
	
	match text[letter_index]:
		"!", ".", ",", "?":
			current_delay = punctuation_time
		" ":
			current_delay = space_time
		_:
			current_delay = letter_time
	
	
	
func _unhandled_input(event):

	if not is_typing:
		return

	if event.is_action_pressed("advance_dialog"):

		label.text = text

		letter_index = text.length()

		is_typing = false

		continue_label.show()
		continue_label.play("idle")

		finished_displaying.emit()

		get_viewport().set_input_as_handled()

	
func play_letter_sound():

	var player := AudioStreamPlayer.new()

	add_child(player)

	player.stream = audio_stream_player_2d.stream
	
	player.volume_db = audio_stream_player_2d.volume_db

	player.pitch_scale = randf_range(0.85, 1.15)

	player.finished.connect(player.queue_free)

	player.play()
