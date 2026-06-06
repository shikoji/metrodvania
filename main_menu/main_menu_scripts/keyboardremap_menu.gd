extends Control

signal back_requested

const CONFIG_PATH := "user://keyboard_binds.cfg"

const BIND_NONE := 0
const BIND_KEY := 1
const BIND_MOUSE := 2

const SLOT_COUNT := 2

const ACTIONS := [
	{
		"action": "pause",
		"label": "Pause",
		"row_name": "PauseRow",
		"defaults": [
			{"type": BIND_KEY, "code": KEY_ESCAPE},
			{"type": BIND_KEY, "code": KEY_P}
		]
	},
	{
		"action": "move_jump",
		"label": "Jump",
		"row_name": "MoveJumpRow",
		"defaults": [
			{"type": BIND_KEY, "code": KEY_SPACE},
			{"type": BIND_NONE, "code": 0}
		]
	},
	{
		"action": "move_left",
		"label": "move Left",
		"row_name": "MoveLeftRow",
		"defaults": [
			{"type": BIND_KEY, "code": KEY_A},
			{"type": BIND_KEY, "code": KEY_LEFT}
		]
	},
	{
		"action": "move_right",
		"label": "Move Right",
		"row_name": "MoveRightRow",
		"defaults": [
			{"type": BIND_KEY, "code": KEY_D},
			{"type": BIND_KEY, "code": KEY_RIGHT}
		]
	},
	{
		"action": "dash",
		"label": "Dash",
		"row_name": "DashRow",
		"defaults": [
			{"type": BIND_KEY, "code": KEY_A},
			{"type": BIND_NONE, "code": 0}
		]
	},
	{
		"action": "attack",
		"label": "Attack",
		"row_name": "AttackRow",
		"defaults": [
			{"type": BIND_KEY, "code": KEY_L},
			{"type": BIND_MOUSE, "code": MOUSE_BUTTON_LEFT}
		]
	},
	{
		"action": "potion",
		"label": "Potion",
		"row_name": "PotionRow",
		"defaults": [
			{"type": BIND_KEY, "code": KEY_R},
			{"type": BIND_NONE, "code": 0}
		]
	},
	{
		"action": "move_up",
		"label": "Move Up",
		"row_name": "MoveUpRow",
		"defaults": [
			{"type": BIND_KEY, "code": KEY_W},
			{"type": BIND_KEY, "code": KEY_UP}
		]
	},
	{
		"action": "move_down",
		"label": "Move Down",
		"row_name": "MoveDownRow",
		"defaults": [
			{"type": BIND_KEY, "code": KEY_S},
			{"type": BIND_KEY, "code": KEY_DOWN}
		]
	},
	{
		"action": "parasite",
		"label": "Parasite",
		"row_name": "ParasiteRow",
		"defaults": [
			{"type": BIND_KEY, "code": KEY_Z},
			{"type": BIND_NONE, "code": 0}
		]
	},
	{
		"action": "interact",
		"label": "Interact",
		"row_name": "InteractRow",
		"defaults": [
			{"type": BIND_KEY, "code": KEY_F},
			{"type": BIND_NONE, "code": 0}
		]
	},
	{
		"action": "advance_dialog",
		"label": "advance Dialog",
		"row_name": "AdvanceDialogRow",
		"defaults": [
			{"type": BIND_KEY, "code": KEY_ENTER},
			{"type": BIND_NONE, "code": 0}
		]
	}
]

@onready var title: Label = $Title

@onready var rows: HBoxContainer = $Rows
@onready var left_column: VBoxContainer = $Rows/LeftColumn
@onready var right_column: VBoxContainer = $Rows/RightColumn

@onready var restore_button: Button = $BottomButtons/RestoreButton
@onready var back_keyboard_button: Button = $BottomButtons/BackKeyboardButton

@export var selected_item_scale: Vector2 = Vector2(1.08, 1.08)
@export var item_zoom_time: float = 0.12

var current_binds: Dictionary = {}

var focus_items: Array[Control] = []
var left_column_buttons: Array = []
var right_column_buttons: Array = []
var left_targets: Dictionary = {}
var right_targets: Dictionary = {}
var scale_targets: Dictionary = {}

var current_item: Control = null
var current_scale_target: Control = null

var waiting_for_input := false
var waiting_action := ""
var waiting_slot := -1
var waiting_button: Button = null

var scale_tweens: Dictionary = {}


func _ready() -> void:
	visible = false

	title.text = "Keyboard"

	restore_button.text = "Restore Defaults"
	back_keyboard_button.text = "Back"

	restore_button.flat = true
	back_keyboard_button.flat = true

	restore_button.focus_mode = Control.FOCUS_ALL
	back_keyboard_button.focus_mode = Control.FOCUS_ALL

	_prepare_input_actions()
	_load_or_create_binds()
	_create_rows()
	_connect_bottom_buttons()
	_apply_all_binds_to_input_map()
	_refresh_all_buttons()


func open_menu() -> void:
	visible = true
	waiting_for_input = false

	await get_tree().process_frame

	var first_button := _get_first_focus_item()
	if first_button != null:
		first_button.grab_focus()
		_select_item(first_button, false)


func close_menu() -> void:
	visible = false
	waiting_for_input = false
	waiting_action = ""
	waiting_slot = -1
	waiting_button = null

	for item in focus_items:
		var target: Control = scale_targets[item]
		_animate_scale(target, Vector2.ONE)


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return

	if waiting_for_input:
		_handle_waiting_input(event)
		return

	if event.is_action_pressed("ui_cancel"):
		_on_back_keyboard_pressed()
		get_viewport().set_input_as_handled()


func _handle_waiting_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event := event as InputEventKey

		if not key_event.pressed:
			return

		if key_event.echo:
			return

		get_viewport().set_input_as_handled()

		var code := key_event.physical_keycode

		if code == KEY_NONE:
			code = key_event.keycode

		if code == KEY_BACKSPACE or code == KEY_DELETE:
			_clear_waiting_slot()
			return

		_set_bind(waiting_action, waiting_slot, {
			"type": BIND_KEY,
			"code": code
		})

		return

	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton

		if not mouse_event.pressed:
			return

		get_viewport().set_input_as_handled()

		if mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			_cancel_waiting()
			return

		_set_bind(waiting_action, waiting_slot, {
			"type": BIND_MOUSE,
			"code": mouse_event.button_index
		})


func _prepare_input_actions() -> void:
	for info in ACTIONS:
		var action_name: String = info["action"]

		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)


func _load_or_create_binds() -> void:
	current_binds.clear()

	for info in ACTIONS:
		var action_name: String = info["action"]
		var defaults: Array = info["defaults"]

		current_binds[action_name] = [
			_copy_bind(defaults[0]),
			_copy_bind(defaults[1])
		]

	var config := ConfigFile.new()
	var err := config.load(CONFIG_PATH)

	if err != OK:
		return

	for info in ACTIONS:
		var action_name: String = info["action"]

		if not config.has_section_key("keyboard", action_name):
			continue

		var saved = config.get_value("keyboard", action_name)

		if typeof(saved) != TYPE_ARRAY:
			continue

		var slot_1 := {"type": BIND_NONE, "code": 0}
		var slot_2 := {"type": BIND_NONE, "code": 0}

		if saved.size() > 0:
			slot_1 = _string_to_bind(str(saved[0]))

		if saved.size() > 1:
			slot_2 = _string_to_bind(str(saved[1]))

		current_binds[action_name] = [slot_1, slot_2]


func _save_binds() -> void:
	var config := ConfigFile.new()

	for info in ACTIONS:
		var action_name: String = info["action"]

		var binds_as_text := [
			_bind_to_string(current_binds[action_name][0]),
			_bind_to_string(current_binds[action_name][1])
		]

		config.set_value("keyboard", action_name, binds_as_text)

	config.save(CONFIG_PATH)


func _create_rows() -> void:
	for child in left_column.get_children():
		child.queue_free()

	for child in right_column.get_children():
		child.queue_free()

	focus_items.clear()
	left_targets.clear()
	right_targets.clear()
	scale_targets.clear()
	
	left_column_buttons.clear()
	right_column_buttons.clear()

	left_column.add_theme_constant_override("separation", 12)
	right_column.add_theme_constant_override("separation", 12)

	var half := int(ceil(float(ACTIONS.size()) / 2.0))

	for i in ACTIONS.size():
		var info: Dictionary = ACTIONS[i]
		var row := _create_action_row(info)

		var slot_1 := row.get_node("Slot1Button") as Button
		var slot_2 := row.get_node("Slot2Button") as Button
		var row_buttons := [slot_1, slot_2]

		if i < half:
			left_column.add_child(row)
			left_column_buttons.append(row_buttons)
		else:
			right_column.add_child(row)
			right_column_buttons.append(row_buttons)

	_setup_manual_navigation()

	_register_focus_item(
		restore_button,
		restore_button,
		restore_button,
		restore_button
	)

	_register_focus_item(
		back_keyboard_button,
		back_keyboard_button,
		back_keyboard_button,
		back_keyboard_button
	)

func _setup_manual_navigation() -> void:
	var row_count: int = mini(
		int(left_column_buttons.size()),
		int(right_column_buttons.size())
	)

	for row_index in range(row_count):
		var left_slot_1: Button = left_column_buttons[row_index][0] as Button
		var left_slot_2: Button = left_column_buttons[row_index][1] as Button

		var right_slot_1: Button = right_column_buttons[row_index][0] as Button
		var right_slot_2: Button = right_column_buttons[row_index][1] as Button

		var previous_index: int = int(row_index) - 1
		var next_index: int = int(row_index) + 1

		if previous_index < 0:
			previous_index = 0

		if next_index >= row_count:
			next_index = row_count - 1

		var left_previous_slot_1: Button = left_column_buttons[previous_index][0] as Button
		var left_previous_slot_2: Button = left_column_buttons[previous_index][1] as Button
		var left_next_slot_1: Button = left_column_buttons[next_index][0] as Button
		var left_next_slot_2: Button = left_column_buttons[next_index][1] as Button

		var right_previous_slot_1: Button = right_column_buttons[previous_index][0] as Button
		var right_previous_slot_2: Button = right_column_buttons[previous_index][1] as Button
		var right_next_slot_1: Button = right_column_buttons[next_index][0] as Button
		var right_next_slot_2: Button = right_column_buttons[next_index][1] as Button

		# ESQUERDA - SLOT 1
		left_slot_1.focus_neighbor_left = left_slot_1.get_path()
		left_slot_1.focus_neighbor_right = left_slot_2.get_path()
		left_slot_1.focus_neighbor_top = left_previous_slot_1.get_path()
		left_slot_1.focus_neighbor_bottom = left_next_slot_1.get_path()

		# ESQUERDA - SLOT 2
		# Apertar direita aqui vai direto para o primeiro botão da coluna direita.
		left_slot_2.focus_neighbor_left = left_slot_1.get_path()
		left_slot_2.focus_neighbor_right = right_slot_1.get_path()
		left_slot_2.focus_neighbor_top = left_previous_slot_2.get_path()
		left_slot_2.focus_neighbor_bottom = left_next_slot_2.get_path()

		# DIREITA - SLOT 1
		right_slot_1.focus_neighbor_left = left_slot_2.get_path()
		right_slot_1.focus_neighbor_right = right_slot_2.get_path()
		right_slot_1.focus_neighbor_top = right_previous_slot_1.get_path()
		right_slot_1.focus_neighbor_bottom = right_next_slot_1.get_path()

		# DIREITA - SLOT 2
		right_slot_2.focus_neighbor_left = right_slot_1.get_path()
		right_slot_2.focus_neighbor_right = right_slot_2.get_path()
		right_slot_2.focus_neighbor_top = right_previous_slot_2.get_path()
		right_slot_2.focus_neighbor_bottom = right_next_slot_2.get_path()

	if row_count > 0:
		var last_left_slot_1: Button = left_column_buttons[row_count - 1][0] as Button
		var last_left_slot_2: Button = left_column_buttons[row_count - 1][1] as Button
		var last_right_slot_1: Button = right_column_buttons[row_count - 1][0] as Button
		var last_right_slot_2: Button = right_column_buttons[row_count - 1][1] as Button

		last_left_slot_1.focus_neighbor_bottom = restore_button.get_path()
		last_left_slot_2.focus_neighbor_bottom = restore_button.get_path()
		last_right_slot_1.focus_neighbor_bottom = restore_button.get_path()
		last_right_slot_2.focus_neighbor_bottom = restore_button.get_path()

		restore_button.focus_neighbor_top = last_right_slot_1.get_path()
		restore_button.focus_neighbor_bottom = back_keyboard_button.get_path()
		restore_button.focus_neighbor_left = restore_button.get_path()
		restore_button.focus_neighbor_right = restore_button.get_path()

		back_keyboard_button.focus_neighbor_top = restore_button.get_path()
		back_keyboard_button.focus_neighbor_bottom = back_keyboard_button.get_path()
		back_keyboard_button.focus_neighbor_left = back_keyboard_button.get_path()
		back_keyboard_button.focus_neighbor_right = back_keyboard_button.get_path()

func _create_action_row(info: Dictionary) -> HBoxContainer:
	var action_name: String = info["action"]
	var action_label: String = info["label"]
	var row_name: String = info["row_name"]

	var row := HBoxContainer.new()
	row.name = row_name
	row.custom_minimum_size = Vector2(620, 46)
	row.add_theme_constant_override("separation", 18)

	var label := Label.new()
	label.name = "ActionLabel"
	label.text = action_label
	label.custom_minimum_size = Vector2(260, 40)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.focus_mode = Control.FOCUS_NONE
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	row.add_child(label)

	for slot in SLOT_COUNT:
		var button := Button.new()
		button.name = "Slot%dButton" % [slot + 1]
		button.custom_minimum_size = Vector2(145, 42)
		button.focus_mode = Control.FOCUS_ALL
		button.flat = true
		button.text = _bind_to_pretty_text(current_binds[action_name][slot])

		button.pressed.connect(_on_slot_pressed.bind(action_name, slot, button))
		button.focus_entered.connect(_on_item_focus_entered.bind(button))
		button.mouse_entered.connect(_on_item_mouse_entered.bind(button))

		row.add_child(button)

		_register_focus_item(
			button,
			label,
			button,
			button
		)

	return row


func _connect_bottom_buttons() -> void:
	restore_button.pressed.connect(_on_restore_pressed)
	back_keyboard_button.pressed.connect(_on_back_keyboard_pressed)

	restore_button.focus_entered.connect(_on_item_focus_entered.bind(restore_button))
	back_keyboard_button.focus_entered.connect(_on_item_focus_entered.bind(back_keyboard_button))

	restore_button.mouse_entered.connect(_on_item_mouse_entered.bind(restore_button))
	back_keyboard_button.mouse_entered.connect(_on_item_mouse_entered.bind(back_keyboard_button))


func _register_focus_item(
	item: Control,
	left_target: Control,
	right_target: Control,
	scale_target: Control
) -> void:
	focus_items.append(item)
	left_targets[item] = left_target
	right_targets[item] = right_target
	scale_targets[item] = scale_target


func _on_slot_pressed(action_name: String, slot: int, button: Button) -> void:
	if waiting_for_input:
		return

	waiting_for_input = true
	waiting_action = action_name
	waiting_slot = slot
	waiting_button = button

	button.text = "Pressione outra tecla"
	_select_item(button, true)


func _set_bind(action_name: String, slot: int, bind: Dictionary) -> void:
	current_binds[action_name][slot] = _copy_bind(bind)

	waiting_for_input = false
	waiting_action = ""
	waiting_slot = -1
	waiting_button = null

	_apply_all_binds_to_input_map()
	_save_binds()
	_refresh_all_buttons()


func _clear_waiting_slot() -> void:
	if waiting_action == "":
		return

	current_binds[waiting_action][waiting_slot] = {
		"type": BIND_NONE,
		"code": 0
	}

	waiting_for_input = false
	waiting_action = ""
	waiting_slot = -1
	waiting_button = null

	_apply_all_binds_to_input_map()
	_save_binds()
	_refresh_all_buttons()


func _cancel_waiting() -> void:
	waiting_for_input = false
	waiting_action = ""
	waiting_slot = -1
	waiting_button = null

	_refresh_all_buttons()


func _apply_all_binds_to_input_map() -> void:
	for info in ACTIONS:
		var action_name: String = info["action"]

		var old_events := InputMap.action_get_events(action_name)
		var controller_events: Array[InputEvent] = []

		for event in old_events:
			if event is InputEventJoypadButton or event is InputEventJoypadMotion:
				controller_events.append(event)

		InputMap.action_erase_events(action_name)

		for event in controller_events:
			InputMap.action_add_event(action_name, event)

		for bind in current_binds[action_name]:
			var bind_type: int = int(bind["type"])
			var bind_code: int = int(bind["code"])

			if bind_type == BIND_NONE:
				continue

			if bind_type == BIND_KEY:
				var key_event := InputEventKey.new()
				key_event.physical_keycode = bind_code as Key
				InputMap.action_add_event(action_name, key_event)

			elif bind_type == BIND_MOUSE:
				var mouse_event := InputEventMouseButton.new()
				mouse_event.button_index = bind_code as MouseButton
				InputMap.action_add_event(action_name, mouse_event)


func _refresh_all_buttons() -> void:
	for column in [left_column, right_column]:
		for row in column.get_children():
			if not row is HBoxContainer:
				continue

			var action_name := _get_action_name_by_row_name(row.name)

			if action_name == "":
				continue

			var slot_1 := row.get_node("Slot1Button") as Button
			var slot_2 := row.get_node("Slot2Button") as Button

			slot_1.text = _bind_to_pretty_text(current_binds[action_name][0])
			slot_2.text = _bind_to_pretty_text(current_binds[action_name][1])


func _on_restore_pressed() -> void:
	for info in ACTIONS:
		var action_name: String = info["action"]
		var defaults: Array = info["defaults"]

		current_binds[action_name] = [
			_copy_bind(defaults[0]),
			_copy_bind(defaults[1])
		]

	waiting_for_input = false
	waiting_action = ""
	waiting_slot = -1
	waiting_button = null

	_apply_all_binds_to_input_map()
	_save_binds()
	_refresh_all_buttons()


func _on_back_keyboard_pressed() -> void:
	if waiting_for_input:
		_cancel_waiting()
		return

	close_menu()
	back_requested.emit()


func _on_item_focus_entered(item: Control) -> void:
	_select_item(item, true)


func _on_item_mouse_entered(item: Control) -> void:
	if waiting_for_input:
		return

	item.grab_focus()


func _select_item(item: Control, _animate_selector: bool = true) -> void:
	current_item = item

	for focus_item in focus_items:
		var target: Control = scale_targets[focus_item]

		if focus_item == item:
			_animate_scale(target, selected_item_scale)
			current_scale_target = target
		else:
			_animate_scale(target, Vector2.ONE)


func _animate_scale(control: Control, target_scale: Vector2) -> void:
	if scale_tweens.has(control) and scale_tweens[control]:
		scale_tweens[control].kill()

	var tween := create_tween()
	scale_tweens[control] = tween

	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(
		control,
		"scale",
		target_scale,
		item_zoom_time
	)


func _copy_bind(bind: Dictionary) -> Dictionary:
	return {
		"type": int(bind["type"]),
		"code": int(bind["code"])
	}


func _bind_to_string(bind: Dictionary) -> String:
	var bind_type: int = int(bind["type"])
	var bind_code: int = int(bind["code"])

	if bind_type == BIND_NONE:
		return "none:0"

	if bind_type == BIND_KEY:
		return "key:" + str(bind_code)

	if bind_type == BIND_MOUSE:
		return "mouse:" + str(bind_code)

	return "none:0"


func _string_to_bind(text: String) -> Dictionary:
	var parts := text.split(":")

	if parts.size() < 2:
		return {"type": BIND_NONE, "code": 0}

	var type_text := parts[0]
	var code := int(parts[1])

	if type_text == "key":
		return {"type": BIND_KEY, "code": code}

	if type_text == "mouse":
		return {"type": BIND_MOUSE, "code": code}

	return {"type": BIND_NONE, "code": 0}


func _bind_to_pretty_text(bind: Dictionary) -> String:
	var bind_type: int = int(bind["type"])
	var bind_code: int = int(bind["code"])

	if bind_type == BIND_NONE:
		return "Not Set"

	if bind_type == BIND_MOUSE:
		return _mouse_button_to_text(bind_code)

	if bind_type == BIND_KEY:
		return _key_to_text(bind_code)

	return "Not Set"


func _key_to_text(code: int) -> String:
	match code:
		KEY_ESCAPE:
			return "Esc"
		KEY_SPACE:
			return "Space"
		KEY_ENTER:
			return "Enter"
		KEY_TAB:
			return "Tab"
		KEY_LEFT:
			return "Left"
		KEY_RIGHT:
			return "Right"
		KEY_UP:
			return "Up"
		KEY_DOWN:
			return "Down"
		KEY_SHIFT:
			return "Shift"
		KEY_CTRL:
			return "Ctrl"
		KEY_ALT:
			return "Alt"
		_:
			return OS.get_keycode_string(code)


func _mouse_button_to_text(button_index: int) -> String:
	match button_index:
		MOUSE_BUTTON_LEFT:
			return "Left Mouse"
		MOUSE_BUTTON_RIGHT:
			return "Right Mouse"
		MOUSE_BUTTON_MIDDLE:
			return "Middle Mouse"
		MOUSE_BUTTON_WHEEL_UP:
			return "Mouse Wheel Up"
		MOUSE_BUTTON_WHEEL_DOWN:
			return "Mouse Wheel Down"
		_:
			return "Mouse " + str(button_index)


func _get_action_name_by_row_name(row_name: String) -> String:
	for info in ACTIONS:
		if String(info["row_name"]) == row_name:
			return String(info["action"])

	return ""


func _get_first_focus_item() -> Control:
	if focus_items.is_empty():
		return null

	return focus_items[0]

func is_waiting_for_remap_input() -> bool:
	return is_visible_in_tree() and waiting_for_input
