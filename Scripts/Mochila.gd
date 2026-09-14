extends CanvasLayer

signal opened
signal closed

var is_open: bool = false

@onready var inventory: Node = $Inventario
@onready var overlay: ColorRect = $Overlay
@onready var main_panel: Panel = $Overlay/MainPanel
@onready var category_list: VBoxContainer = $Overlay/MainPanel/Layout/CategoryColumn/CategoryList
@onready var category_title: Label = $Overlay/MainPanel/Layout/ContentColumn/Header/CategoryTitle
@onready var item_list: VBoxContainer = $Overlay/MainPanel/Layout/ContentColumn/ItemArea/Scroll/ItemList
@onready var description_label: Label = $Overlay/MainPanel/Layout/ContentColumn/DescriptionPanel/Margin/Description
@onready var footer_label: Label = $Overlay/MainPanel/Layout/ContentColumn/Footer
@onready var action_panel: Panel = $Overlay/ActionPanel
@onready var action_list: VBoxContainer = $Overlay/ActionPanel/Margin/ActionList

var categories: Array[String] = []
var category_index: int = 0
var item_index: int = 0
var action_index: int = 0
var current_items: Array[Dictionary] = []
var action_mode: bool = false

var category_buttons: Array[Button] = []
var item_buttons: Array[Button] = []
var action_buttons: Array[Button] = []

const NORMAL_BG := Color("202838")
const SELECTED_BG := Color("f4d35e")
const TEXT_LIGHT := Color("f6f7fb")
const TEXT_DARK := Color("151820")
const ACCENT := Color("42c6ff")
const PANEL := Color("111827")
const BORDER := Color("6b7893")

func _ready() -> void:
	layer = 100
	overlay.visible = false
	action_panel.visible = false
	categories = inventory.get_categories()
	inventory.inventory_changed.connect(_on_inventory_changed)
	_apply_gen5_style()
	_rebuild_categories()
	_refresh_items()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if action_mode:
				_close_action_menu()
			else:
				toggle()
			get_viewport().set_input_as_handled()
			return

	if not is_open:
		return

	if event.is_action_pressed("ui_cancel"):
		if action_mode:
			_close_action_menu()
		else:
			close()
		get_viewport().set_input_as_handled()
		return

	if action_mode:
		_handle_action_input(event)
	else:
		_handle_bag_input(event)

func toggle() -> void:
	if is_open:
		close()
	else:
		open()

func open() -> void:
	if is_open:
		return

	is_open = true
	overlay.visible = true
	action_mode = false
	action_panel.visible = false
	_refresh_selection()
	opened.emit()

func close() -> void:
	if not is_open:
		return

	is_open = false
	action_mode = false
	action_panel.visible = false
	overlay.visible = false
	closed.emit()

func _handle_bag_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left"):
		_change_category(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right"):
		_change_category(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up"):
		_change_item(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down"):
		_change_item(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		if not current_items.is_empty():
			_open_action_menu()
		get_viewport().set_input_as_handled()

func _handle_action_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_up"):
		action_index = wrapi(action_index - 1, 0, action_buttons.size())
		_refresh_action_selection()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down"):
		action_index = wrapi(action_index + 1, 0, action_buttons.size())
		_refresh_action_selection()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		_execute_selected_action()
		get_viewport().set_input_as_handled()

func _change_category(delta: int) -> void:
	if categories.is_empty():
		return

	category_index = wrapi(category_index + delta, 0, categories.size())
	item_index = 0
	_refresh_items()
	_refresh_selection()

func _change_item(delta: int) -> void:
	if current_items.is_empty():
		return

	item_index = wrapi(item_index + delta, 0, current_items.size())
	_refresh_selection()

func _rebuild_categories() -> void:
	for child in category_list.get_children():
		child.queue_free()

	category_buttons.clear()

	for i in range(categories.size()):
		var button := Button.new()
		button.text = categories[i]
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(150, 42)
		button.pressed.connect(_on_category_clicked.bind(i))
		category_list.add_child(button)
		category_buttons.append(button)

func _refresh_items() -> void:
	if categories.is_empty():
		return

	current_items = inventory.get_items_for_category(categories[category_index])

	if item_index >= current_items.size():
		item_index = max(0, current_items.size() - 1)

	for child in item_list.get_children():
		child.queue_free()

	item_buttons.clear()

	for i in range(current_items.size()):
		var item: Dictionary = current_items[i]
		var button := Button.new()
		button.text = "%s    ×%d" % [
			str(item.get("name", "Objeto")),
			int(item.get("quantity", 0))
		]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(0, 46)
		button.pressed.connect(_on_item_clicked.bind(i))
		item_list.add_child(button)
		item_buttons.append(button)

	category_title.text = categories[category_index]

	if current_items.is_empty():
		var empty := Label.new()
		empty.text = "No hay objetos en este bolsillo."
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.custom_minimum_size = Vector2(0, 100)
		item_list.add_child(empty)

	_refresh_selection()

func _refresh_selection() -> void:
	_style_category_buttons()
	_style_item_buttons()

	if current_items.is_empty():
		description_label.text = "Este bolsillo está vacío."
		return

	var item: Dictionary = current_items[item_index]
	description_label.text = str(item.get("description", ""))

func _style_category_buttons() -> void:
	for i in range(category_buttons.size()):
		var selected := i == category_index
		_apply_button_style(category_buttons[i], selected, true)

func _style_item_buttons() -> void:
	for i in range(item_buttons.size()):
		var selected := i == item_index
		_apply_button_style(item_buttons[i], selected, false)

func _apply_button_style(button: Button, selected: bool, category: bool) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = SELECTED_BG if selected else NORMAL_BG
	box.border_width_left = 3 if selected else 1
	box.border_width_top = 1
	box.border_width_right = 1
	box.border_width_bottom = 1
	box.border_color = ACCENT if selected else Color("39455a")
	box.corner_radius_top_left = 7
	box.corner_radius_top_right = 7
	box.corner_radius_bottom_left = 7
	box.corner_radius_bottom_right = 7
	box.content_margin_left = 12
	box.content_margin_right = 12

	button.add_theme_stylebox_override("normal", box)
	button.add_theme_stylebox_override("hover", box)
	button.add_theme_stylebox_override("pressed", box)
	button.add_theme_color_override("font_color", TEXT_DARK if selected else TEXT_LIGHT)
	button.add_theme_color_override("font_hover_color", TEXT_DARK if selected else TEXT_LIGHT)
	button.add_theme_font_size_override("font_size", 17 if category else 18)

func _open_action_menu() -> void:
	if current_items.is_empty():
		return

	action_mode = true
	action_panel.visible = true
	action_index = 0
	_rebuild_actions()

func _close_action_menu() -> void:
	action_mode = false
	action_panel.visible = false

func _rebuild_actions() -> void:
	for child in action_list.get_children():
		child.queue_free()

	action_buttons.clear()

	var item: Dictionary = current_items[item_index]
	var actions: Array[String] = []

	if bool(item.get("usable", false)):
		actions.append("USAR")

	actions.append("DAR")

	if item.get("category", "") == "CLAVE":
		actions.append("REGISTRAR")

	if bool(item.get("can_toss", true)):
		actions.append("TIRAR")

	actions.append("CANCELAR")

	for i in range(actions.size()):
		var button := Button.new()
		button.text = actions[i]
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(165, 38)
		button.pressed.connect(_on_action_clicked.bind(i))
		action_list.add_child(button)
		action_buttons.append(button)

	_refresh_action_selection()

func _refresh_action_selection() -> void:
	for i in range(action_buttons.size()):
		_apply_button_style(action_buttons[i], i == action_index, false)

func _execute_selected_action() -> void:
	if action_buttons.is_empty() or current_items.is_empty():
		return

	var action := action_buttons[action_index].text
	var item: Dictionary = current_items[item_index]
	var item_id := str(item.get("id", ""))

	match action:
		"USAR":
			if inventory.use_item(item_id):
				_show_status("Usaste %s." % str(item.get("name", "el objeto")))
			else:
				_show_status("No se puede usar ahora.")
		"DAR":
			_show_status("La opción DAR queda preparada para conectarla con tu equipo Pokémon.")
		"REGISTRAR":
			_show_status("%s quedó marcado como objeto clave." % str(item.get("name", "El objeto")))
		"TIRAR":
			if inventory.toss_item(item_id):
				_show_status("Tiraste una unidad.")
			else:
				_show_status("Este objeto no se puede tirar.")
		"CANCELAR":
			_close_action_menu()

	if action != "CANCELAR":
		_close_action_menu()

func _show_status(message: String) -> void:
	footer_label.text = message

func _on_inventory_changed() -> void:
	_refresh_items()

func _on_category_clicked(index: int) -> void:
	category_index = index
	item_index = 0
	_refresh_items()

func _on_item_clicked(index: int) -> void:
	item_index = index
	_refresh_selection()
	_open_action_menu()

func _on_action_clicked(index: int) -> void:
	action_index = index
	_execute_selected_action()

func _apply_gen5_style() -> void:
	# Fondo translúcido que oscurece el mundo.
	overlay.color = Color(0.02, 0.035, 0.07, 0.90)

	var main_style := StyleBoxFlat.new()
	main_style.bg_color = PANEL
	main_style.border_width_left = 4
	main_style.border_width_top = 4
	main_style.border_width_right = 4
	main_style.border_width_bottom = 4
	main_style.border_color = Color("9aa7be")
	main_style.corner_radius_top_left = 14
	main_style.corner_radius_top_right = 14
	main_style.corner_radius_bottom_left = 14
	main_style.corner_radius_bottom_right = 14
	main_panel.add_theme_stylebox_override("panel", main_style)

	var action_style := StyleBoxFlat.new()
	action_style.bg_color = Color("0b1220")
	action_style.border_width_left = 3
	action_style.border_width_top = 3
	action_style.border_width_right = 3
	action_style.border_width_bottom = 3
	action_style.border_color = Color("d9e2f1")
	action_style.corner_radius_top_left = 10
	action_style.corner_radius_top_right = 10
	action_style.corner_radius_bottom_left = 10
	action_style.corner_radius_bottom_right = 10
	action_panel.add_theme_stylebox_override("panel", action_style)

	category_title.add_theme_color_override("font_color", TEXT_LIGHT)
	category_title.add_theme_font_size_override("font_size", 25)
	description_label.add_theme_color_override("font_color", TEXT_LIGHT)
	description_label.add_theme_font_size_override("font_size", 18)
	footer_label.add_theme_color_override("font_color", Color("b9c8dc"))
	footer_label.add_theme_font_size_override("font_size", 15)
