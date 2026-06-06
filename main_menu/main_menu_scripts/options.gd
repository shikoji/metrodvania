extends Control


@onready var menu_buttons: VBoxContainer = $MenuButtons
@onready var main_selector: Control = $Selector
@onready var keyboard_remap_menu: Control = $KeyboardremapMenu

@onready var controller_remap_menu: Control = $ControllerRemapMenu

@onready var master_volume: Label = $MenuButtons/MasterRow/Master_volume
@onready var music_volume: Label = $MenuButtons/MusicRow/Music_Volume
@onready var sfx_volume: Label = $MenuButtons/SFxRow/Sfx_volume

@onready var fullscreen: Button = $MenuButtons/FullscreenRow/Fullscreen_volume
@onready var v_sync: Button = $MenuButtons/VSyncRow/VSync_volume
@onready var keyboard: Button = $MenuButtons/KeyboardRow/KeyboardButton
@onready var controller: Button = $MenuButtons/ControllerRow/ControllerButton
@onready var back: Button = $MenuButtons/BackRow/Back

@onready var master_slider: HSlider = $MenuButtons/MasterRow/MasterSlider
@onready var music_slider: HSlider = $MenuButtons/MusicRow/MusicSlider
@onready var sfx_slider: HSlider = $MenuButtons/SFxRow/SfxSlider


@onready var master_value: Label = $MenuButtons/MasterRow/MasterValue
@onready var music_value: Label = $MenuButtons/MusicRow/MusicValue
@onready var sfx_value: Label = $MenuButtons/SFxRow/SfxValue

@onready var fullscreen_value: Label = $MenuButtons/FullscreenRow/FullscreenValue
@onready var vsync_value: Label = $MenuButtons/VSyncRow/VSyncValue
@onready var keyboard_value: Label = $MenuButtons/KeyboardRow/KeyboardValue
@onready var controller_value: Label = $MenuButtons/ControllerRow/ControllerValue

@onready var left_selector: TextureRect = $Selector/LeftDecoration
@onready var right_selector: TextureRect = $Selector/RightDecoration

@export var selector_gap: float = 10.0

@export var left_selector_gap: float = 25.0

@export var right_selector_gap: float = 25.0

@export var selected_item_scale: Vector2 = Vector2(1.08, 1.08)

@export var selector_press_distance: float = 10.0

@export var selector_move_time: float = 0.08

@export var selector_press_time: float = 0.08

@export var item_zoom_time: float = 0.12


var focus_items: Array[Control] = []
var current_item: Control

var left_selector_targets: Dictionary = {}
var right_selector_targets: Dictionary = {}
var scale_targets: Dictionary = {}

var left_normal_position: Vector2
var right_normal_position: Vector2

var selector_move_tween: Tween
var selector_press_tween: Tween

var item_scale_tweens: Dictionary = {}


signal back_to_home


func _ready() -> void:
	focus_items = [
		master_slider,
		music_slider,
		sfx_slider,
		fullscreen,
		v_sync,
		keyboard,
		controller,
		back
	]

	left_selector_targets = {
		master_slider: master_volume,
		music_slider: music_volume,
		sfx_slider: sfx_volume,
		fullscreen: fullscreen,
		v_sync: v_sync,
		keyboard: keyboard,
		controller: controller,
		back: back
	}

	right_selector_targets = {
		master_slider: master_value,
		music_slider: music_value,
		sfx_slider: sfx_value,
		fullscreen: fullscreen_value,
		v_sync: vsync_value,
		keyboard: keyboard_value,
		controller: controller_value,
		back: back
	}

	scale_targets = {
		master_slider: master_volume,
		music_slider: music_volume,
		sfx_slider: sfx_volume,
		fullscreen: fullscreen,
		v_sync: v_sync,
		keyboard: keyboard,
		controller: controller,
		back: back
	}

	master_slider.focus_mode = Control.FOCUS_ALL
	music_slider.focus_mode = Control.FOCUS_ALL
	sfx_slider.focus_mode = Control.FOCUS_ALL
	
	keyboard.focus_mode = Control.FOCUS_ALL
	controller.focus_mode = Control.FOCUS_ALL

	for item in focus_items:
		item.focus_entered.connect(_on_item_focus_entered.bind(item))
		item.mouse_entered.connect(_on_item_mouse_entered.bind(item))

	fullscreen.button_down.connect(_on_item_down.bind(fullscreen))
	fullscreen.button_up.connect(_on_item_up)

	v_sync.button_down.connect(_on_item_down.bind(v_sync))
	v_sync.button_up.connect(_on_item_up)
	
	keyboard.button_down.connect(_on_item_down.bind(keyboard))
	keyboard.button_up.connect(_on_item_up)
	
	controller.button_down.connect(_on_item_down.bind(controller))
	controller.button_up.connect(_on_item_up)
	
	back.button_down.connect(_on_item_down.bind(back))
	back.button_up.connect(_on_item_up)

	master_slider.drag_started.connect(_on_item_down.bind(master_slider))
	master_slider.drag_ended.connect(_on_slider_drag_ended)

	music_slider.drag_started.connect(_on_item_down.bind(music_slider))
	music_slider.drag_ended.connect(_on_slider_drag_ended)

	sfx_slider.drag_started.connect(_on_item_down.bind(sfx_slider))
	sfx_slider.drag_ended.connect(_on_slider_drag_ended)

	await get_tree().process_frame

	for item in focus_items:
		var target: Control = scale_targets[item]
		target.pivot_offset = target.size / 2.0

	setup_slider(master_slider)
	setup_slider(music_slider)
	setup_slider(sfx_slider)

	master_slider.value = 100
	music_slider.value = 100
	sfx_slider.value = 100

	update_volume_labels()

	master_slider.value_changed.connect(_on_master_slider_changed)
	music_slider.value_changed.connect(_on_music_slider_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)

	fullscreen.pressed.connect(_on_fullscreen_pressed)
	v_sync.pressed.connect(_on_vsync_pressed)
	
	keyboard.pressed.connect(_on_keyboard_pressed)
	controller.pressed.connect(_on_controller_pressed)
	
	keyboard_remap_menu.back_requested.connect(_on_keyboard_remap_back_requested)
	keyboard_remap_menu.visible = false
	
	controller_remap_menu.back_requested.connect(_on_controller_remap_back_requested)
	controller_remap_menu.visible = false

	load_saved_preferences()
	update_fullscreen_label()
	update_vsync_label()
	process_audio_sliders()

func load_saved_preferences() -> void:
	var file = FileAccess.open("user://preferences.txt", FileAccess.READ)
	if file == null:
		return
	var line = file.get_line()
	while line:
		var key = line.split(" ")[0]
		var value = line.split(" ")[1]
		match key:
			"master_volume":
				master_slider.value = float(value)
			"music_volume":
				music_slider.value = float(value)
			"sfx_volume":
				sfx_slider.value = float(value)
			"fullscreen":
				DisplayServer.window_set_mode(int(value))
			"vsync":
				DisplayServer.window_set_vsync_mode(int(value))
		line = file.get_line()

func save_current_preferences() -> void:
	var file = FileAccess.open("user://preferences.txt", FileAccess.WRITE)
	file.store_line("master_volume " + str(master_slider.value))
	file.store_line("music_volume " + str(music_slider.value))
	file.store_line("sfx_volume " + str(sfx_slider.value))
	file.store_line("fullscreen " + str(DisplayServer.window_get_mode()))
	file.store_line("vsync " + str(DisplayServer.window_get_vsync_mode()))
	file.close()


func setup_slider(slider: HSlider) -> void:
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1


func update_volume_labels() -> void:
	master_value.text = str(int(master_slider.value)) + "%"
	music_value.text = str(int(music_slider.value)) + "%"
	sfx_value.text = str(int(sfx_slider.value)) + "%"


func _on_master_slider_changed(value: float) -> void:
	master_value.text = str(int(value)) + "%"


func _on_music_slider_changed(value: float) -> void:
	music_value.text = str(int(value)) + "%"


func _on_sfx_slider_changed(value: float) -> void:
	sfx_value.text = str(int(value)) + "%"

func _unhandled_input(event: InputEvent) -> void:
	if keyboard_remap_menu.visible or controller_remap_menu.visible:
		return

	if event.is_action_pressed("ui_cancel") or _is_controller_back_event(event):
		_on_back_pressed()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
		if current_item == fullscreen:
			_on_fullscreen_pressed()

		elif current_item == v_sync:
			_on_vsync_pressed()


func _is_controller_back_event(event: InputEvent) -> bool:
	if event is InputEventJoypadButton:
		var joy_button: InputEventJoypadButton = event as InputEventJoypadButton

		if joy_button.pressed and joy_button.button_index == JOY_BUTTON_B:
			return true

	return false

func _on_fullscreen_pressed() -> void:
	var current_mode := DisplayServer.window_get_mode()

	var is_fullscreen := (
		current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN
		or current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	)

	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

	await get_tree().process_frame
	update_fullscreen_label()


func update_fullscreen_label() -> void:
	var current_mode := DisplayServer.window_get_mode()

	var is_fullscreen := (
		current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN
		or current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	)

	fullscreen_value.text = "YES" if is_fullscreen else "NO"

func _on_vsync_pressed() -> void:
	var is_enabled := DisplayServer.window_get_vsync_mode() != DisplayServer.VSYNC_DISABLED

	if is_enabled:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)

	update_vsync_label()


func update_vsync_label() -> void:
	var is_enabled := DisplayServer.window_get_vsync_mode() != DisplayServer.VSYNC_DISABLED
	vsync_value.text = "YES" if is_enabled else "NO"


func _on_keyboard_pressed() -> void:
	keyboard_remap_menu.open_menu()
	menu_buttons.visible = false
	main_selector.visible = false


func _on_keyboard_remap_back_requested() -> void:
	keyboard_remap_menu.visible = false

	menu_buttons.visible = true
	main_selector.visible = true

	await get_tree().process_frame

	keyboard.grab_focus()
	select_item(keyboard, false)
	
func _on_controller_pressed() -> void:
	controller_remap_menu.open_menu()
	menu_buttons.visible = false
	main_selector.visible = false


func _on_controller_remap_back_requested() -> void:
	controller_remap_menu.visible = false

	menu_buttons.visible = true
	main_selector.visible = true

	await get_tree().process_frame

	controller.grab_focus()
	select_item(controller, false)

func _on_item_focus_entered(item: Control) -> void:
	select_item(item, true)


func _on_item_mouse_entered(item: Control) -> void:
	item.grab_focus()


func select_item(item: Control, animate_selector: bool = true) -> void:
	current_item = item

	for focus_item in focus_items:
		var target: Control = scale_targets[focus_item]

		if focus_item == item:
			animate_control_scale(target, selected_item_scale)
		else:
			animate_control_scale(target, Vector2.ONE)

	update_selector_positions(item)

	move_selectors_to_normal_position(animate_selector)


func update_selector_positions(item: Control) -> void:
	var left_target: Control = left_selector_targets[item]
	var right_target: Control = right_selector_targets[item]

	var center_y := left_target.global_position.y + left_target.size.y / 2.0

	var left_visual_width := left_target.size.x * left_target.scale.x
	var left_visual_x := left_target.global_position.x - ((left_visual_width - left_target.size.x) / 2.0)

	left_normal_position = Vector2(
		left_visual_x - left_selector.size.x - left_selector_gap,
		center_y - left_selector.size.y / 2.0
	)

	var right_visual_width := right_target.size.x * right_target.scale.x
	var right_visual_x := right_target.global_position.x + right_target.size.x + ((right_visual_width - right_target.size.x) / 2.0)

	right_normal_position = Vector2(
		right_visual_x + right_selector_gap,
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


func animate_control_scale(control: Control, target_scale: Vector2) -> void:
	if item_scale_tweens.has(control) and item_scale_tweens[control]:
		item_scale_tweens[control].kill()

	var tween := create_tween()
	item_scale_tweens[control] = tween

	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(
		control,
		"scale",
		target_scale,
		item_zoom_time
	)


func _on_item_down(item: Control) -> void:
	if current_item != item:
		select_item(item, true)

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


func _on_item_up() -> void:
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


func _on_slider_drag_ended(_value_changed: bool) -> void:
	_on_item_up()

func focus_first_option() -> void:
	await get_tree().process_frame
	master_slider.grab_focus()

	await get_tree().process_frame
	select_item(master_slider, false)

func _on_back_pressed() -> void:
	if keyboard_remap_menu.visible:
		keyboard_remap_menu.close_menu()

	if controller_remap_menu.visible:
		controller_remap_menu.close_menu()
	save_current_preferences()
	back_to_home.emit()


func process_audio_sliders() -> void:
	var sfx_index = AudioServer.get_bus_index("Sounds")
	var music_index = AudioServer.get_bus_index("Music")
	var master_index = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_linear(sfx_index, sfx_slider.value / 100.0)
	AudioServer.set_bus_volume_linear(music_index, music_slider.value / 100.0)
	AudioServer.set_bus_volume_linear(master_index, master_slider.value / 100.0)


func _process(_delta: float) -> void:
	if visible:
		process_audio_sliders()

func is_waiting_for_remap_input() -> bool:
	if keyboard_remap_menu != null:
		if keyboard_remap_menu.has_method("is_waiting_for_remap_input"):
			if keyboard_remap_menu.is_waiting_for_remap_input():
				return true

	if controller_remap_menu != null:
		if controller_remap_menu.has_method("is_waiting_for_remap_input"):
			if controller_remap_menu.is_waiting_for_remap_input():
				return true

	return false

func is_controller_remap_menu_open() -> bool:
	if controller_remap_menu == null:
		return false

	return controller_remap_menu.is_visible_in_tree()
