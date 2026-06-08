extends Control

signal back_requested

const CONFIG_PATH := "user://controller_binds.cfg"

const BIND_NONE := 0
const BIND_BUTTON := 1
const BIND_AXIS := 2

const AXIS_POSITIVE := 1
const AXIS_NEGATIVE := -1

const ACTIONS := [
	{
		"action": "move_jump",
		"default": {"type": BIND_BUTTON, "index": JOY_BUTTON_A},
		"button_name": "JumpBind"
	},
	{
		"action": "attack",
		"default": {"type": BIND_BUTTON, "index": JOY_BUTTON_X},
		"button_name": "AttackBind"
	},
	{
		"action": "dash",
		"default": {"type": BIND_AXIS, "index": JOY_AXIS_TRIGGER_RIGHT, "direction": AXIS_POSITIVE},
		"button_name": "DashBind"
	},
	{
		"action": "potion",
		"default": {"type": BIND_BUTTON, "index": JOY_BUTTON_DPAD_UP},
		"button_name": "PotionBind"
	},
	{
		"action": "parasite",
		"default": {"type": BIND_BUTTON, "index": JOY_BUTTON_Y},
		"button_name": "ParasiteBind"
	},
	{
		"action": "interact",
		"default": {"type": BIND_BUTTON, "index": JOY_BUTTON_B},
		"button_name": "InteractBind"
	},
	{
		"action": "advance_dialog",
		"default": {"type": BIND_BUTTON, "index": JOY_BUTTON_DPAD_RIGHT},
		"button_name": "AdvanceDialogBind"
	},
	{
		"action": "pause",
		"default": {"type": BIND_BUTTON, "index": JOY_BUTTON_START},
		"button_name": "PauseBind"
	},
	{
		"action": "throw_bomb",
		"default": {"type": BIND_BUTTON, "index": JOY_BUTTON_RIGHT_SHOULDER},
		"button_name": "ThrowBombBind"
	},
	{
		"action": "throw_ground",
		"default": {"type": BIND_BUTTON, "index": JOY_BUTTON_LEFT_SHOULDER},
		"button_name": "GrassBind"
	}
]

@export var icon_cross: Texture2D
@export var icon_circle: Texture2D
@export var icon_square: Texture2D
@export var icon_triangle: Texture2D

@export var icon_dpad_up: Texture2D
@export var icon_dpad_down: Texture2D
@export var icon_dpad_left: Texture2D
@export var icon_dpad_right: Texture2D

@export var icon_l1: Texture2D
@export var icon_r1: Texture2D
@export var icon_l2: Texture2D
@export var icon_r2: Texture2D

@export var icon_options: Texture2D
@export var icon_share: Texture2D
@export var icon_none: Texture2D


@onready var title: Label = $Title

@onready var jump_bind: Button = $Rows/LeftColumn/JumpRow/JumpBind
@onready var attack_bind: Button = $Rows/LeftColumn/AttackRow/AttackBind
@onready var dash_bind: Button = $Rows/LeftColumn/DashRow/DashBind
@onready var potion_bind: Button = $Rows/LeftColumn/PotionRow/PotionBind
@onready var bomb_bind: Button = $Rows/LeftColumn/BombRow/ThrowBombBind

@onready var parasite_bind: Button = $Rows/RightColumn/ParasiteRow/ParasiteBind
@onready var interact_bind: Button = $Rows/RightColumn/InteractRow/InteractBind
@onready var advance_dialog_bind: Button = $Rows/RightColumn/AdvanceDialogRow/AdvanceDialogBind
@onready var pause_bind: Button = $Rows/RightColumn/PauseRow/PauseBind

@onready var throw_bomb_bind: Button = $Rows/LeftColumn/BombRow/ThrowBombBind

@onready var grass_bind: Button = $Rows/RightColumn/GrassRow/GrassBind

@onready var restore_button: Button = $BottomButtons/RestoreButton
@onready var back_button: Button = $BottomButtons/BackButton

var bind_buttons: Dictionary = {}
var current_binds: Dictionary = {}

var waiting_for_input: bool = false
var waiting_action: String = ""
var waiting_button: Button = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	visible = false

	bind_buttons = {
		"move_jump": jump_bind,
		"attack": attack_bind,
		"dash": dash_bind,
		"potion": potion_bind,
		"parasite": parasite_bind,
		"interact": interact_bind,
		"advance_dialog": advance_dialog_bind,
		"pause": pause_bind,
		"throw_bomb": bomb_bind,
		"throw_ground": grass_bind
	}

	_prepare_buttons()
	_prepare_input_actions()
	_load_or_create_binds()

	var removed_duplicates: bool = _remove_duplicate_binds_after_load()

	if removed_duplicates:
		_save_binds()

	_apply_all_binds_to_input_map()
	_refresh_all_buttons()
	_setup_manual_navigation()

func _remove_duplicate_binds_after_load() -> bool:
	var changed: bool = false
	var used_binds: Array = []

	for info in ACTIONS:
		var action_name: String = info["action"]

		if not current_binds.has(action_name):
			continue

		var current_bind: Dictionary = current_binds[action_name]

		if int(current_bind.get("type", BIND_NONE)) == BIND_NONE:
			continue

		var found_duplicate: bool = false

		for used_bind in used_binds:
			var used_bind_dictionary: Dictionary = used_bind

			if _binds_are_equal(current_bind, used_bind_dictionary):
				found_duplicate = true
				break

		if found_duplicate:
			current_binds[action_name] = _empty_bind()
			changed = true
		else:
			used_binds.append(current_bind.duplicate(true))

	return changed

func open_menu() -> void:
	visible = true

	waiting_for_input = false
	waiting_action = ""
	waiting_button = null

	_refresh_all_buttons()

	await get_tree().process_frame
	jump_bind.grab_focus()


func close_menu() -> void:
	visible = false

	waiting_for_input = false
	waiting_action = ""
	waiting_button = null

	_set_remap_lock(false)

	_refresh_all_buttons()


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return

	if waiting_for_input:
		_handle_waiting_input(event)
		return

	if event.is_action_pressed("ui_cancel") or _is_controller_back_event(event):
		_on_back_button_pressed()
		get_viewport().set_input_as_handled()
		return

func _is_controller_back_event(event: InputEvent) -> bool:
	if event is InputEventJoypadButton:
		var joy_button: InputEventJoypadButton = event as InputEventJoypadButton

		if joy_button.pressed and joy_button.button_index == JOY_BUTTON_B:
			return true

	return false

func _prepare_buttons() -> void:
	for action_name in bind_buttons.keys():
		var button: Button = bind_buttons[action_name] as Button

		button.text = ""
		button.focus_mode = Control.FOCUS_ALL

		var icon: TextureRect = button.get_node("Icon") as TextureRect
		var waiting_text: Label = button.get_node("WaitingText") as Label

		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		waiting_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		waiting_text.text = "..."
		waiting_text.visible = false

		button.pressed.connect(_on_bind_button_pressed.bind(action_name, button))

	restore_button.focus_mode = Control.FOCUS_ALL
	back_button.focus_mode = Control.FOCUS_ALL

	restore_button.pressed.connect(_on_restore_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)


func _prepare_input_actions() -> void:
	for info in ACTIONS:
		var action_name: String = info["action"]

		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)


func _on_bind_button_pressed(action_name: String, button: Button) -> void:
	if waiting_for_input:
		return

	waiting_for_input = true
	waiting_action = action_name
	waiting_button = button

	_set_remap_lock(true)

	_show_button_waiting(button)


func _handle_waiting_input(event: InputEvent) -> void:
	if event is InputEventJoypadButton:
		var joy_button: InputEventJoypadButton = event as InputEventJoypadButton

		if not joy_button.pressed:
			return

		get_viewport().set_input_as_handled()

		_set_bind(waiting_action, {
			"type": BIND_BUTTON,
			"index": joy_button.button_index
		})

		return

	if event is InputEventJoypadMotion:
		var joy_motion: InputEventJoypadMotion = event as InputEventJoypadMotion

		if abs(joy_motion.axis_value) < 0.75:
			return

		if joy_motion.axis != JOY_AXIS_TRIGGER_LEFT and joy_motion.axis != JOY_AXIS_TRIGGER_RIGHT:
			return

		get_viewport().set_input_as_handled()

		var direction: int = AXIS_POSITIVE

		if joy_motion.axis_value < 0.0:
			direction = AXIS_NEGATIVE

		_set_bind(waiting_action, {
			"type": BIND_AXIS,
			"index": joy_motion.axis,
			"direction": direction
		})

		return


func _set_bind(action_name: String, bind_data: Dictionary) -> void:
	_remove_same_bind_from_other_actions(action_name, bind_data)

	current_binds[action_name] = bind_data.duplicate(true)

	waiting_for_input = false
	waiting_action = ""
	waiting_button = null

	_unlock_remap_lock_next_frame()

	_apply_all_binds_to_input_map()
	_save_binds()
	_refresh_all_buttons()

func _empty_bind() -> Dictionary:
	return {
		"type": BIND_NONE,
		"index": -1,
		"direction": AXIS_POSITIVE
	}


func _remove_same_bind_from_other_actions(selected_action: String, new_bind: Dictionary) -> void:
	if int(new_bind.get("type", BIND_NONE)) == BIND_NONE:
		return

	for info in ACTIONS:
		var action_name: String = info["action"]

		if action_name == selected_action:
			continue

		if not current_binds.has(action_name):
			continue

		var old_bind: Dictionary = current_binds[action_name]

		if _binds_are_equal(old_bind, new_bind):
			current_binds[action_name] = _empty_bind()


func _binds_are_equal(bind_a: Dictionary, bind_b: Dictionary) -> bool:
	var type_a: int = int(bind_a.get("type", BIND_NONE))
	var type_b: int = int(bind_b.get("type", BIND_NONE))

	if type_a == BIND_NONE or type_b == BIND_NONE:
		return false

	if type_a != type_b:
		return false

	if type_a == BIND_BUTTON:
		return int(bind_a.get("index", -1)) == int(bind_b.get("index", -1))

	if type_a == BIND_AXIS:
		return (
			int(bind_a.get("index", -1)) == int(bind_b.get("index", -1))
			and int(bind_a.get("direction", AXIS_POSITIVE)) == int(bind_b.get("direction", AXIS_POSITIVE))
		)

	return false


func _load_or_create_binds() -> void:
	current_binds.clear()

	for info in ACTIONS:
		var action_name: String = info["action"]
		var default_bind: Dictionary = info["default"]

		current_binds[action_name] = default_bind.duplicate(true)

	var config := ConfigFile.new()
	var err := config.load(CONFIG_PATH)

	if err != OK:
		return

	for info in ACTIONS:
		var action_name: String = info["action"]

		if config.has_section_key("controller", action_name):
			var saved = config.get_value("controller", action_name)

			if typeof(saved) == TYPE_DICTIONARY:
				current_binds[action_name] = saved


func _save_binds() -> void:
	var config := ConfigFile.new()

	for info in ACTIONS:
		var action_name: String = info["action"]
		config.set_value("controller", action_name, current_binds[action_name])

	config.save(CONFIG_PATH)


func _on_restore_button_pressed() -> void:
	for info in ACTIONS:
		var action_name: String = info["action"]
		var default_bind: Dictionary = info["default"]

		current_binds[action_name] = default_bind.duplicate(true)

	waiting_for_input = false
	waiting_action = ""
	waiting_button = null

	_apply_all_binds_to_input_map()
	_save_binds()
	_refresh_all_buttons()


func _apply_all_binds_to_input_map() -> void:
	for info in ACTIONS:
		var action_name: String = info["action"]

		var old_events: Array = InputMap.action_get_events(action_name)
		var non_controller_events: Array[InputEvent] = []

		for event in old_events:
			if not (event is InputEventJoypadButton or event is InputEventJoypadMotion):
				non_controller_events.append(event)

		InputMap.action_erase_events(action_name)

		for event in non_controller_events:
			InputMap.action_add_event(action_name, event)

		var bind_data: Dictionary = current_binds[action_name]
		var bind_type: int = int(bind_data.get("type", BIND_NONE))

		if bind_type == BIND_NONE:
			continue

		if bind_type == BIND_BUTTON:
			var joy_button := InputEventJoypadButton.new()
			joy_button.button_index = int(bind_data.get("index", -1)) as JoyButton
			InputMap.action_add_event(action_name, joy_button)

		elif bind_type == BIND_AXIS:
			var joy_axis := InputEventJoypadMotion.new()
			joy_axis.axis = int(bind_data.get("index", -1)) as JoyAxis
			joy_axis.axis_value = float(bind_data.get("direction", AXIS_POSITIVE))
			InputMap.action_add_event(action_name, joy_axis)


func _refresh_all_buttons() -> void:
	for action_name in bind_buttons.keys():
		var button: Button = bind_buttons[action_name] as Button

		if waiting_for_input and waiting_action == action_name:
			_show_button_waiting(button)
		else:
			_show_button_bind(button, current_binds[action_name])


func _show_button_waiting(button: Button) -> void:
	var icon: TextureRect = button.get_node("Icon") as TextureRect
	var waiting_text: Label = button.get_node("WaitingText") as Label

	icon.visible = false
	waiting_text.visible = true


func _show_button_bind(button: Button, bind_data: Dictionary) -> void:
	var icon: TextureRect = button.get_node("Icon") as TextureRect
	var waiting_text: Label = button.get_node("WaitingText") as Label

	waiting_text.visible = false
	icon.visible = true
	icon.texture = _get_icon_for_bind(bind_data)


func _get_icon_for_bind(bind_data: Dictionary) -> Texture2D:
	var bind_type: int = int(bind_data.get("type", BIND_NONE))

	if bind_type == BIND_NONE:
		return icon_none

	if bind_type == BIND_BUTTON:
		return _get_icon_for_button(int(bind_data.get("index", -1)))

	if bind_type == BIND_AXIS:
		return _get_icon_for_axis(
			int(bind_data.get("index", -1)),
			int(bind_data.get("direction", AXIS_POSITIVE))
		)

	return icon_none


func _get_icon_for_button(button_index: int) -> Texture2D:
	match button_index:
		JOY_BUTTON_A:
			return icon_cross

		JOY_BUTTON_B:
			return icon_circle

		JOY_BUTTON_X:
			return icon_square

		JOY_BUTTON_Y:
			return icon_triangle

		JOY_BUTTON_DPAD_UP:
			return icon_dpad_up

		JOY_BUTTON_DPAD_DOWN:
			return icon_dpad_down

		JOY_BUTTON_DPAD_LEFT:
			return icon_dpad_left

		JOY_BUTTON_DPAD_RIGHT:
			return icon_dpad_right

		JOY_BUTTON_LEFT_SHOULDER:
			return icon_l1

		JOY_BUTTON_RIGHT_SHOULDER:
			return icon_r1

		JOY_BUTTON_START:
			return icon_options

		JOY_BUTTON_BACK:
			return icon_share

		_:
			return icon_none


func _get_icon_for_axis(axis_index: int, direction: int) -> Texture2D:
	if axis_index == JOY_AXIS_TRIGGER_LEFT and direction == AXIS_POSITIVE:
		return icon_l2

	if axis_index == JOY_AXIS_TRIGGER_RIGHT and direction == AXIS_POSITIVE:
		return icon_r2

	return icon_none

func _setup_manual_navigation() -> void:
	var left_buttons: Array[Button] = [
		jump_bind,
		attack_bind,
		dash_bind,
		potion_bind
	]

	var right_buttons: Array[Button] = [
		parasite_bind,
		interact_bind,
		advance_dialog_bind,
		pause_bind
	]

	for i in range(left_buttons.size()):
		var left_button: Button = left_buttons[i]
		var right_button: Button = right_buttons[i]

		var previous_i: int = i - 1
		var next_i: int = i + 1

		if previous_i < 0:
			previous_i = 0

		if next_i >= left_buttons.size():
			next_i = left_buttons.size() - 1

		left_button.focus_neighbor_left = left_button.get_path_to(left_button)
		left_button.focus_neighbor_right = left_button.get_path_to(right_button)
		left_button.focus_neighbor_top = left_button.get_path_to(left_buttons[previous_i])
		left_button.focus_neighbor_bottom = left_button.get_path_to(left_buttons[next_i])

		right_button.focus_neighbor_left = right_button.get_path_to(left_button)
		right_button.focus_neighbor_right = right_button.get_path_to(right_button)
		right_button.focus_neighbor_top = right_button.get_path_to(right_buttons[previous_i])
		right_button.focus_neighbor_bottom = right_button.get_path_to(right_buttons[next_i])

	potion_bind.focus_neighbor_bottom = potion_bind.get_path_to(restore_button)
	pause_bind.focus_neighbor_bottom = pause_bind.get_path_to(restore_button)

	restore_button.focus_neighbor_top = restore_button.get_path_to(potion_bind)
	restore_button.focus_neighbor_bottom = restore_button.get_path_to(back_button)
	restore_button.focus_neighbor_left = restore_button.get_path_to(restore_button)
	restore_button.focus_neighbor_right = restore_button.get_path_to(restore_button)

	back_button.focus_neighbor_top = back_button.get_path_to(restore_button)
	back_button.focus_neighbor_bottom = back_button.get_path_to(back_button)
	back_button.focus_neighbor_left = back_button.get_path_to(back_button)
	back_button.focus_neighbor_right = back_button.get_path_to(back_button)

func _on_back_button_pressed() -> void:
	if waiting_for_input:
		waiting_for_input = false
		waiting_action = ""
		waiting_button = null

		_set_remap_lock(false)

		_refresh_all_buttons()
		return

	close_menu()
	back_requested.emit()


func is_waiting_for_remap_input() -> bool:
	return waiting_for_input

func _set_remap_lock(value: bool) -> void:
	get_tree().root.set_meta("remap_is_waiting", value)

func _unlock_remap_lock_next_frame() -> void:
	await get_tree().process_frame
	_set_remap_lock(false)
