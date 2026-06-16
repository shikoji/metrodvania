extends RichTextLabel

@export var characters_per_second: float = 15.0
@export var pause_between_messages: float = 1.5
@onready var audioplayer: AudioStreamPlayer = $Music
@onready var dialogue_sound: AudioStreamPlayer = $DialogueSound
@onready var progress_bar: ProgressBar = $"../ProgressBar"

var dialog_messages: Array[String] = [
	"The world is now a dark and broken place..",
	"People are suffering as the world becomes more and more corupt.",
	"A legend is summoned every one thousand years to save the world...",
	"Is this your tale..",
	"Save the world",
	"...."
]

var current_message_index: int = 0
var current_tween: Tween
var target_scene_path: String = "res://world/world.tscn"
var progress: Array = []
var is_loading: bool = false

func _ready() -> void:
	SceneManager.play_transition_out()
	audioplayer.play()
	autowrap_mode = TextServer.AUTOWRAP_WORD
	visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	
	if progress_bar:
		progress_bar.hide()
		progress_bar.anchors_preset = Control.PRESET_CENTER
		progress_bar.pivot_offset = progress_bar.size / 2
	
	show_message(current_message_index)

func show_message(index: int) -> void: 
	if index >= dialog_messages.size(): 
		_on_message_cycle_complete()
		return 
		
	current_message_index = index
	text = dialog_messages[index] 
	visible_characters = 0 
	
	var total_chars: int = text.length() 
	var duration: float = total_chars / characters_per_second 
	
	if current_tween:
		current_tween.kill()
		
	current_tween = create_tween() 
	
	current_tween.tween_method(
		func(chars: int):
			if chars > visible_characters:
				visible_characters = chars
				if text[visible_characters - 1] != " " and dialogue_sound:
					dialogue_sound.pitch_scale = randf_range(0.9, 1.1)
					dialogue_sound.play()
	, 0, total_chars, duration
	)
	
	current_tween.tween_interval(pause_between_messages)
	current_tween.finished.connect(func(): show_message(index + 1))

func _process(delta: float) -> void:
	if is_loading:
		var status = ResourceLoader.load_threaded_get_status(target_scene_path, progress)
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			if progress_bar and progress.size() > 0:
				progress_bar.value = progress[0] * 100
		elif status == ResourceLoader.THREAD_LOAD_LOADED:
			var new_scene = ResourceLoader.load_threaded_get(target_scene_path)
			get_tree().change_scene_to_packed(new_scene)
		return

	if Input.is_action_just_pressed("skip_instructions"):
		if current_tween and current_tween.is_running():
			var total_chars: int = text.length()
			if visible_characters < total_chars:
				current_tween.kill()
				visible_characters = total_chars
				current_tween = create_tween()
				current_tween.tween_interval(pause_between_messages)
				current_tween.finished.connect(func(): show_message(current_message_index + 1))
			else:
				show_message(current_message_index + 1)
		else:
			show_message(current_message_index + 1)
		
"""
func _on_message_cycle_complete() -> void:
	if is_loading:
		return
	is_loading = true
	hide()
	
	if progress_bar:
		progress_bar.show()
		progress_bar.value = 0
		
	if audioplayer:
		var fade_tween = create_tween()
		fade_tween.tween_property(audioplayer, "volume_db", -80.0, 1.0)
		fade_tween.finished.connect(func(): audioplayer.stop())
		
	ResourceLoader.load_threaded_request(target_scene_path)
"""

func _on_message_cycle_complete() -> void:
	hide()

	if progress_bar:
		progress_bar.show()
		progress_bar.value = 100

	await get_tree().process_frame
	await get_tree().process_frame

	get_tree().change_scene_to_file(target_scene_path)
