@tool
extends LineEdit
class_name SmartExpressionInput

## Smart Expression Input with real-time autocomplete
## Provides inline suggestions as user types

signal expression_changed(new_expression: String)
signal autocomplete_requested()

## Autocomplete system
var autocomplete: ExpressionAutocomplete

## Editor interface
var editor_interface: EditorInterface

## Autocomplete popup
var popup: PopupPanel
var popup_list: ItemList

## Whether autocomplete is enabled
var autocomplete_enabled: bool = true

## Minimum characters before showing autocomplete
var min_chars_for_autocomplete: int = 2

## Current suggestions
var current_suggestions: Array = []

## Whether we're in expression mode (vs simple value)
var is_expression_mode: bool = false

func _ready() -> void:
	# Initialize autocomplete
	autocomplete = ExpressionAutocomplete.new(editor_interface)
	
	# Create popup
	_create_popup()
	
	# Connect signals
	text_changed.connect(_on_text_changed)
	text_submitted.connect(_on_text_submitted)
	focus_exited.connect(_on_focus_exited)

func _create_popup() -> void:
	popup = PopupPanel.new()
	popup.size = Vector2(300, 200)
	
	var margin = MarginContainer.new()
	margin.anchors_preset = Control.PRESET_FULL_RECT
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	popup.add_child(margin)
	
	popup_list = ItemList.new()
	popup_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	popup_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	popup_list.item_activated.connect(_on_popup_item_activated)
	margin.add_child(popup_list)
	
	add_child(popup)

func set_editor_interface(interface: EditorInterface) -> void:
	editor_interface = interface
	if autocomplete:
		autocomplete.editor_interface = interface

func _on_text_changed(new_text: String) -> void:
	expression_changed.emit(new_text)
	
	if not autocomplete_enabled:
		return
	
	# Check if we should show autocomplete
	var word = _get_current_word()
	
	if word.length() >= min_chars_for_autocomplete:
		_show_suggestions(word)
	else:
		_hide_popup()

func _get_current_word() -> String:
	var cursor_pos = caret_column
	var full_text = text
	
	if cursor_pos == 0:
		return ""
	
	# Find word start
	var start = cursor_pos - 1
	while start > 0:
		var c = full_text[start - 1]
		if not _is_word_char(c):
			break
		start -= 1
	
	return full_text.substr(start, cursor_pos - start)

func _is_word_char(c: String) -> bool:
	return c.is_valid_identifier() or c == "_" or c == "."

func _show_suggestions(query: String) -> void:
	if not autocomplete or not popup_list:
		return
	
	popup_list.clear()
	current_suggestions.clear()
	
	# Search for matching expressions
	var results = autocomplete.search_expressions(query)
	
	if results.is_empty():
		_hide_popup()
		return
	
	# Add suggestions (max 8)
	var count = 0
	for result in results:
		if count >= 8:
			break
		
		var expr = result.expression
		var idx = popup_list.add_item(expr.name)
		popup_list.set_item_metadata(idx, expr)
		popup_list.set_item_tooltip(idx, expr.syntax)
		current_suggestions.append(expr)
		
		if editor_interface:
			var icon_name = _get_type_icon(expr.return_type)
			var icon = editor_interface.get_base_control().get_theme_icon(icon_name, "EditorIcons")
			if icon:
				popup_list.set_item_icon(idx, icon)
		
		count += 1
	
	# Position and show popup
	if popup_list.item_count > 0:
		_position_popup()
		popup.popup()
		popup_list.select(0)

func _position_popup() -> void:
	if not popup:
		return
	
	# Get the global position of the input field
	var input_global_rect = get_global_rect()
	
	# Calculate popup height based on items
	var item_height = 24
	var popup_height = min(popup_list.item_count * item_height + 16, 200)
	var popup_width = max(input_global_rect.size.x, 350)
	
	# Position popup directly below the input field
	var popup_pos = Vector2(
		input_global_rect.position.x,
		input_global_rect.position.y + input_global_rect.size.y + 2  # 2px gap
	)
	
	# Check if popup would go off screen bottom, if so show above
	var viewport_size = get_viewport().get_visible_rect().size
	if popup_pos.y + popup_height > viewport_size.y:
		# Show above the input field instead
		popup_pos.y = input_global_rect.position.y - popup_height - 2
	
	# Ensure popup doesn't go off screen right
	if popup_pos.x + popup_width > viewport_size.x:
		popup_pos.x = viewport_size.x - popup_width - 10
	
	# Ensure popup doesn't go off screen left
	if popup_pos.x < 0:
		popup_pos.x = 10
	
	popup.position = popup_pos
	popup.size = Vector2(popup_width, popup_height)

func _hide_popup() -> void:
	if popup:
		popup.hide()

func _on_popup_item_activated(index: int) -> void:
	if index < 0 or index >= current_suggestions.size():
		return
	
	var expr = current_suggestions[index]
	_insert_suggestion(expr.syntax)
	_hide_popup()

func _insert_suggestion(syntax: String) -> void:
	var cursor_pos = caret_column
	var full_text = text
	
	# Find word start to replace
	var start = cursor_pos - 1
	while start > 0:
		var c = full_text[start - 1]
		if not _is_word_char(c):
			break
		start -= 1
	
	# Replace word with suggestion
	var before = full_text.substr(0, start)
	var after = full_text.substr(cursor_pos)
	
	text = before + syntax + after
	caret_column = start + syntax.length()
	grab_focus()

func _on_text_submitted(_new_text: String) -> void:
	_hide_popup()

func _on_focus_exited() -> void:
	# Delay hiding to allow popup click
	await get_tree().create_timer(0.1).timeout
	_hide_popup()

func _input(event: InputEvent) -> void:
	if not has_focus() or not popup.visible:
		return
	
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_UP:
				_select_previous()
				get_viewport().set_input_as_handled()
			KEY_DOWN:
				_select_next()
				get_viewport().set_input_as_handled()
			KEY_ENTER, KEY_KP_ENTER:
				_confirm_selection()
				get_viewport().set_input_as_handled()
			KEY_ESCAPE:
				_hide_popup()
				get_viewport().set_input_as_handled()
			KEY_TAB:
				_confirm_selection()
				get_viewport().set_input_as_handled()

func _select_previous() -> void:
	if not popup_list or popup_list.item_count == 0:
		return
	
	var selected = popup_list.get_selected_items()
	if selected.is_empty():
		popup_list.select(popup_list.item_count - 1)
	else:
		var new_idx = max(0, selected[0] - 1)
		popup_list.select(new_idx)

func _select_next() -> void:
	if not popup_list or popup_list.item_count == 0:
		return
	
	var selected = popup_list.get_selected_items()
	if selected.is_empty():
		popup_list.select(0)
	else:
		var new_idx = min(popup_list.item_count - 1, selected[0] + 1)
		popup_list.select(new_idx)

func _confirm_selection() -> void:
	var selected = popup_list.get_selected_items()
	if not selected.is_empty():
		_on_popup_item_activated(selected[0])

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

## Set expression mode (changes visual style)
func set_expression_mode(enabled: bool) -> void:
	is_expression_mode = enabled
	
	if enabled:
		add_theme_color_override("font_color", Color(0.9, 0.9, 0.5))
		placeholder_text = "Enter expression..."
	else:
		remove_theme_color_override("font_color")
		placeholder_text = "Enter value..."

## Enable/disable autocomplete
func set_autocomplete_enabled(enabled: bool) -> void:
	autocomplete_enabled = enabled
	if not enabled:
		_hide_popup()
