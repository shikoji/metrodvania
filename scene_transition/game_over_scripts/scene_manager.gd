extends CanvasLayer

@onready var rect: ColorRect = $ColorRect

@export var transition_time := 1.5
@export var max_progress := 1.5

var is_transitioning := false

func _ready() -> void:
	visible = false
	layer = 100


func play_transition_in(next_scene: PackedScene = null) -> void:
	if is_transitioning:
		return
	
	is_transitioning = true
	
	var mat := rect.material as ShaderMaterial
	
	visible = true
	mat.set_shader_parameter("progress", 0.0)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_method(
		func(value: float): mat.set_shader_parameter("progress", value),
		0.0,
		max_progress,
		transition_time
	)

	await tween.finished
	
	mat.set_shader_parameter("progress", max_progress)
	is_transitioning = false
	
	if next_scene != null:
		get_tree().change_scene_to_packed(next_scene)


func play_transition_out() -> void:
	if is_transitioning:
		return
	
	is_transitioning = true
	
	var mat := rect.material as ShaderMaterial
	
	visible = true
	mat.set_shader_parameter("progress", max_progress)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_method(
		func(value: float): mat.set_shader_parameter("progress", value),
		max_progress,
		0.0,
		transition_time
	)

	await tween.finished
	
	mat.set_shader_parameter("progress", 0.0)
	visible = false
	is_transitioning = false
