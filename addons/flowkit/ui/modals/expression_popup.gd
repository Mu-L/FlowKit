@tool
extends PopupPanel
class_name ExpressionPopup

## Autocomplete popup for expression input fields.
## Shows suggestions as user types in expression fields.

signal item_selected(syntax: String)

## Autocomplete system reference
var autocomplete: ExpressionAutocomplete

## Editor interface
var editor_interface: EditorInterface

## Current search query
var current_query: String = ""

## Maximum items to show
const MAX_ITEMS: int = 10

## Reference to the input field this popup is attached to
var attached_input: Control = null

# UI Components
var items_list: ItemList
var info_label: Label

func _ready() -> void:
	_setup_ui()

func _setup_ui() -> void:
	# Main container
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(vbox)
	
	# Items list
	items_list = ItemList.new()
	items_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	items_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	items_list.custom_minimum_size = Vector2(300, 200)
	items_list.item_activated.connect(_on_item_activated)
	items_list.item_selected.connect(_on_item_selected)
	vbox.add_child(items_list)
	
	# Info label at bottom
	info_label = Label.new()
	info_label.add_theme_font_size_override("font_size", 11)
	info_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(info_label)
	
	# Initialize autocomplete
	autocomplete = ExpressionAutocomplete.new(editor_interface)

func set_editor_interface(interface: EditorInterface) -> void:
	editor_interface = interface
	if autocomplete:
		autocomplete.editor_interface = interface

## Update suggestions based on query
func update_suggestions(query: String) -> void:
	current_query = query
	
	if not items_list or not autocomplete:
		return
	
	items_list.clear()
	
	if query.is_empty():
		hide()
		return
	
	# Search for matching expressions
	var results = autocomplete.search_expressions(query)
	
	if results.is_empty():
		hide()
		return
	
	# Add items (limited to MAX_ITEMS)
	var count = 0
	for result in results:
		if count >= MAX_ITEMS:
			break
		
		var expr = result.expression
		var cat = result.category
		
		var display_text = expr.name + " - " + ExpressionAutocomplete.get_category_name(cat)
		var idx = items_list.add_item(display_text)
		items_list.set_item_metadata(idx, expr)
		
		# Set icon
		if editor_interface:
			var icon_name = ExpressionAutocomplete.get_category_icon(cat)
			var icon = editor_interface.get_base_control().get_theme_icon(icon_name, "EditorIcons")
			if icon:
				items_list.set_item_icon(idx, icon)
		
		count += 1
	
	# Show popup
	if items_list.item_count > 0:
		_position_below_input()
		popup()
		# Select first item
		items_list.select(0)
		_update_info_label(0)

## Show suggestions for a specific category
func show_category_suggestions(category: int) -> void:
	if not items_list or not autocomplete:
		return
	
	items_list.clear()
	
	var expressions = autocomplete.get_expressions_for_category(category)
	
	for expr in expressions:
		var idx = items_list.add_item(expr.name)
		items_list.set_item_metadata(idx, expr)
		
		if editor_interface:
			var icon_name = _get_type_icon(expr.return_type)
			var icon = editor_interface.get_base_control().get_theme_icon(icon_name, "EditorIcons")
			if icon:
				items_list.set_item_icon(idx, icon)
	
	if items_list.item_count > 0:
		popup()
		items_list.select(0)
		_update_info_label(0)

func _on_item_activated(index: int) -> void:
	if index < 0 or index >= items_list.item_count:
		return
	
	var expr = items_list.get_item_metadata(index)
	if expr:
		item_selected.emit(expr.syntax)
	
	hide()

func _on_item_selected(index: int) -> void:
	_update_info_label(index)

func _update_info_label(index: int) -> void:
	if not info_label or index < 0 or index >= items_list.item_count:
		return
	
	var expr = items_list.get_item_metadata(index)
	if expr:
		info_label.text = expr.syntax + "\n" + expr.description

func _get_type_icon(type_name: String) -> String:
	match type_name.to_lower():
		"int", "integer": return "int"
		"float", "number": return "float"
		"bool", "boolean": return "bool"
		"string": return "String"
		"vector2": return "Vector2"
		"vector3": return "Vector3"
		"color": return "Color"
		"node": return "Node"
		_: return "Variant"

## Navigate selection up
func select_previous() -> void:
	if not items_list or items_list.item_count == 0:
		return
	
	var current = items_list.get_selected_items()
	if current.is_empty():
		items_list.select(items_list.item_count - 1)
	else:
		var new_idx = max(0, current[0] - 1)
		items_list.select(new_idx)
		_update_info_label(new_idx)

## Navigate selection down
func select_next() -> void:
	if not items_list or items_list.item_count == 0:
		return
	
	var current = items_list.get_selected_items()
	if current.is_empty():
		items_list.select(0)
	else:
		var new_idx = min(items_list.item_count - 1, current[0] + 1)
		items_list.select(new_idx)
		_update_info_label(new_idx)

## Confirm current selection
func confirm_selection() -> void:
	var selected = items_list.get_selected_items()
	if not selected.is_empty():
		_on_item_activated(selected[0])

## Get currently selected syntax
func get_selected_syntax() -> String:
	var selected = items_list.get_selected_items()
	if selected.is_empty():
		return ""
	
	var expr = items_list.get_item_metadata(selected[0])
	return expr.syntax if expr else ""


## Attach this popup to an input field
func attach_to_input(input: Control) -> void:
	attached_input = input


## Position the popup below the attached input field
func _position_below_input() -> void:
	if not attached_input:
		return
	
	# Get the global position of the input field
	var input_global_rect = attached_input.get_global_rect()
	
	# Calculate popup dimensions
	var item_height = 24
	var popup_height = min(items_list.item_count * item_height + 60, 280)  # +60 for info label
	var popup_width = max(input_global_rect.size.x, 350)
	
	# Position popup directly below the input field
	var popup_pos = Vector2(
		input_global_rect.position.x,
		input_global_rect.position.y + input_global_rect.size.y + 2  # 2px gap
	)
	
	# Check if popup would go off screen bottom, if so show above
	var viewport = attached_input.get_viewport()
	if viewport:
		var viewport_size = viewport.get_visible_rect().size
		if popup_pos.y + popup_height > viewport_size.y:
			# Show above the input field instead
			popup_pos.y = input_global_rect.position.y - popup_height - 2
		
		# Ensure popup doesn't go off screen right
		if popup_pos.x + popup_width > viewport_size.x:
			popup_pos.x = viewport_size.x - popup_width - 10
		
		# Ensure popup doesn't go off screen left
		if popup_pos.x < 0:
			popup_pos.x = 10
	
	position = popup_pos
	size = Vector2(popup_width, popup_height)
