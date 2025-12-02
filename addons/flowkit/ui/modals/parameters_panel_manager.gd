@tool
extends RefCounted
class_name ParametersPanelManager

## Manages the parameters panel display and value storage for the GDevelop-style selector.
## Creates appropriate input controls based on parameter types and stores modified values.
## Integrated with Expression Editor for advanced expression input.

## Reference to the description label at the top of the panel
var description_label: Label

## Reference to the container for parameter controls
var parameters_container: VBoxContainer

## Dictionary mapping parameter names to their input controls
var parameter_controls: Dictionary = {}

## Dictionary storing current parameter values
var _parameter_values: Dictionary = {}

## Dictionary storing expression mode state for each parameter
var _expression_modes: Dictionary = {}

## Editor interface for accessing theme icons
var editor_interface: EditorInterface

## Context node for expressions
var context_node: Node = null

## Scene root for expressions
var scene_root: Node = null

## Signal emitted when expression editor button is clicked
signal expression_requested(param_name: String, param_type: String, current_value: String)


func _init(desc_label: Label = null, params_container: VBoxContainer = null, editor_if: EditorInterface = null) -> void:
	description_label = desc_label
	parameters_container = params_container
	editor_interface = editor_if


## Set context for expression evaluation
func set_context(node: Node, root: Node) -> void:
	context_node = node
	scene_root = root


## Display parameters for the selected action/condition.
## @param item: The action or condition instance (FKAction or FKCondition)
func display_parameters(item: Variant) -> void:
	clear_parameters()
	
	if item == null:
		return
	
	# Display description at top
	if description_label and item.has_method("get_description"):
		description_label.text = item.get_description()
	
	# Get inputs from the item
	var inputs: Array = []
	if item.has_method("get_inputs"):
		inputs = item.get_inputs()
	
	if inputs.is_empty():
		_show_no_parameters_message()
		return
	
	# Create controls for each parameter
	for input_def in inputs:
		_create_parameter_row(input_def)


## Display parameters from metadata dictionary (used when item is already selected).
## @param item_metadata: Dictionary containing "description" and "inputs" keys
func display_parameters_from_metadata(item_metadata: Dictionary) -> void:
	clear_parameters()
	
	if item_metadata.is_empty():
		return
	
	# Display description at top
	if description_label:
		description_label.text = item_metadata.get("description", "")
	
	var inputs: Array = item_metadata.get("inputs", [])
	
	if inputs.is_empty():
		_show_no_parameters_message()
		return
	
	# Create controls for each parameter
	for input_def in inputs:
		_create_parameter_row(input_def)


## Get the current parameter values.
## @return Dictionary mapping parameter names to their values
func get_parameter_values() -> Dictionary:
	return _parameter_values.duplicate()


## Clear all parameters from the panel.
func clear_parameters() -> void:
	if description_label:
		description_label.text = ""
	
	if parameters_container:
		for child in parameters_container.get_children():
			child.queue_free()
	
	parameter_controls.clear()
	_parameter_values.clear()
	_expression_modes.clear()


## Create an appropriate control for the given parameter type.
## @param param_type: The type string (String, int, float, bool, etc.)
## @return The created Control
func create_control_for_type(param_type: String) -> Control:
	var type_lower: String = param_type.to_lower()
	
	match type_lower:
		"int":
			return _create_int_spinbox()
		"float":
			return _create_float_spinbox()
		"bool":
			return _create_checkbox()
		_:  # Default to String (includes "string", "variant", etc.)
			return _create_line_edit()


# ============================================================================
# PRIVATE METHODS
# ============================================================================

func _show_no_parameters_message() -> void:
	"""Show a message when there are no parameters to configure."""
	if not parameters_container:
		return
	
	var label: Label = Label.new()
	label.text = "No parameters required"
	label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parameters_container.add_child(label)


func _create_parameter_row(input_def: Dictionary) -> void:
	"""Create a row with label and control for a parameter."""
	if not parameters_container:
		return
	
	var param_name: String = input_def.get("name", "")
	var param_type: String = input_def.get("type", "String")
	var param_default: Variant = input_def.get("default", null)
	var param_description: String = input_def.get("description", "")
	var param_options: Array = input_def.get("options", [])
	
	# Main container for the parameter
	var main_vbox: VBoxContainer = VBoxContainer.new()
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Create horizontal container for the row
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Create label
	var label: Label = Label.new()
	label.text = param_name
	label.custom_minimum_size.x = 100
	label.tooltip_text = param_description
	hbox.add_child(label)
	
	# Create control based on type (pass options for dropdown support)
	var control: Control = _create_control_with_value(param_type, param_name, param_default, param_options)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(control)
	
	# Add expression button for all types (GDevelop style)
	var expr_button: Button = _create_expression_button(param_name, param_type)
	hbox.add_child(expr_button)
	
	main_vbox.add_child(hbox)
	
	# Add description label if available
	if not param_description.is_empty():
		var desc_label: Label = Label.new()
		desc_label.text = param_description
		desc_label.add_theme_font_size_override("font_size", 11)
		desc_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		main_vbox.add_child(desc_label)
	
	# Add separator
	var separator: HSeparator = HSeparator.new()
	separator.add_theme_constant_override("separation", 8)
	main_vbox.add_child(separator)
	
	parameters_container.add_child(main_vbox)
	
	# Store control reference
	parameter_controls[param_name] = control
	
	# Store default value
	if param_default != null:
		_parameter_values[param_name] = param_default
	
	# Initialize expression mode as false
	_expression_modes[param_name] = false


func _create_control_with_value(param_type: String, param_name: String, default_value: Variant, options: Array = []) -> Control:
	"""Create a control and set its initial value."""
	var type_lower: String = param_type.to_lower()
	
	# If options are provided, create a dropdown regardless of type
	if not options.is_empty():
		var option_button: OptionButton = _create_option_button(options)
		if default_value != null:
			var idx = options.find(str(default_value))
			if idx >= 0:
				option_button.select(idx)
		option_button.item_selected.connect(func(idx): _on_parameter_changed(param_name, options[idx]))
		# Set initial value
		if option_button.selected >= 0 and option_button.selected < options.size():
			_parameter_values[param_name] = options[option_button.selected]
		return option_button
	
	match type_lower:
		"int":
			var spinbox: SpinBox = _create_int_spinbox()
			if default_value != null:
				spinbox.value = int(default_value)
			spinbox.value_changed.connect(func(value): _on_parameter_changed(param_name, int(value)))
			return spinbox
		"float":
			var spinbox: SpinBox = _create_float_spinbox()
			if default_value != null:
				spinbox.value = float(default_value)
			spinbox.value_changed.connect(func(value): _on_parameter_changed(param_name, value))
			return spinbox
		"bool":
			var checkbox: CheckBox = _create_checkbox()
			if default_value != null:
				checkbox.button_pressed = bool(default_value)
			checkbox.toggled.connect(func(pressed): _on_parameter_changed(param_name, pressed))
			return checkbox
		_:  # Default to String - use SmartExpressionInput for autocomplete
			var smart_input: SmartExpressionInput = _create_smart_expression_input(param_name)
			if default_value != null:
				smart_input.text = str(default_value)
			smart_input.expression_changed.connect(func(text): _on_parameter_changed(param_name, text))
			return smart_input


func _create_int_spinbox() -> SpinBox:
	"""Create a SpinBox configured for integer values."""
	var spinbox: SpinBox = SpinBox.new()
	spinbox.allow_greater = true
	spinbox.allow_lesser = true
	spinbox.step = 1
	spinbox.rounded = true
	return spinbox


func _create_float_spinbox() -> SpinBox:
	"""Create a SpinBox configured for float values."""
	var spinbox: SpinBox = SpinBox.new()
	spinbox.allow_greater = true
	spinbox.allow_lesser = true
	spinbox.step = 0.1
	return spinbox


func _create_checkbox() -> CheckBox:
	"""Create a CheckBox for boolean values."""
	return CheckBox.new()


func _create_option_button(options: Array) -> OptionButton:
	"""Create an OptionButton (dropdown) for predefined options."""
	var option_button: OptionButton = OptionButton.new()
	for option in options:
		option_button.add_item(str(option))
	if option_button.item_count > 0:
		option_button.select(0)
	return option_button


func _create_line_edit() -> LineEdit:
	"""Create a LineEdit for string values."""
	var line_edit: LineEdit = LineEdit.new()
	line_edit.placeholder_text = "Enter value..."
	return line_edit


func _create_smart_expression_input(param_name: String) -> SmartExpressionInput:
	"""Create a SmartExpressionInput with autocomplete support."""
	var smart_input: SmartExpressionInput = SmartExpressionInput.new()
	smart_input.placeholder_text = "Enter value or expression..."
	smart_input.set_editor_interface(editor_interface)
	return smart_input


func _create_expression_button(param_name: String, param_type: String) -> Button:
	"""Create an expression editor button for parameters."""
	var button: Button = Button.new()
	button.text = "Σ 123"
	button.tooltip_text = "Open expression editor"
	button.custom_minimum_size = Vector2(50, 0)
	button.toggle_mode = true
	button.pressed.connect(func(): _on_expression_button_pressed(param_name, param_type))
	
	# Style the button
	if editor_interface:
		var base_control = editor_interface.get_base_control()
		if base_control:
			var font_color = Color(0.4, 0.6, 0.9)
			button.add_theme_color_override("font_color", font_color)
	
	return button


func _on_parameter_changed(param_name: String, value: Variant) -> void:
	"""Handle parameter value changes."""
	_parameter_values[param_name] = value


func _on_expression_button_pressed(param_name: String, param_type: String) -> void:
	"""Handle expression button press."""
	var current_value: String = ""
	if parameter_controls.has(param_name):
		var control: Control = parameter_controls[param_name]
		if control is SpinBox:
			current_value = str(control.value)
		elif control is LineEdit:
			current_value = control.text
		elif control is CheckBox:
			current_value = str(control.button_pressed)
	
	expression_requested.emit(param_name, param_type, current_value)


## Set a parameter value programmatically (e.g., from expression editor).
## @param param_name: The parameter name
## @param value: The value to set
## @param is_expression: Whether the value is an expression string
func set_parameter_value(param_name: String, value: Variant, is_expression: bool = false) -> void:
	_parameter_values[param_name] = value
	_expression_modes[param_name] = is_expression
	
	# Update the control if it exists
	if parameter_controls.has(param_name):
		var control: Control = parameter_controls[param_name]
		
		# Don't convert OptionButton to expression input - it has predefined options
		if control is OptionButton:
			# Find and select the matching option
			for i in control.item_count:
				if control.get_item_text(i) == str(value):
					control.select(i)
					break
		elif is_expression:
			# Convert control to LineEdit for expression display
			_convert_to_expression_input(param_name, str(value))
		else:
			if control is SpinBox and (value is int or value is float):
				control.value = float(value)
			elif control is CheckBox and value is bool:
				control.button_pressed = value
			elif control is LineEdit:
				control.text = str(value)


func _convert_to_expression_input(param_name: String, expression: String) -> void:
	"""Convert a parameter control to expression input mode."""
	if not parameter_controls.has(param_name):
		return
	
	var old_control: Control = parameter_controls[param_name]
	var parent: Node = old_control.get_parent()
	
	if not parent:
		return
	
	# Create new LineEdit for expression
	var line_edit: LineEdit = LineEdit.new()
	line_edit.text = expression
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_edit.placeholder_text = "Expression..."
	line_edit.add_theme_color_override("font_color", Color(0.9, 0.9, 0.5))  # Yellow tint for expressions
	line_edit.text_changed.connect(func(text): _on_parameter_changed(param_name, text))
	
	# Replace old control
	var idx = old_control.get_index()
	parent.remove_child(old_control)
	old_control.queue_free()
	parent.add_child(line_edit)
	parent.move_child(line_edit, idx)
	
	parameter_controls[param_name] = line_edit
	_parameter_values[param_name] = expression


## Check if a parameter is in expression mode
func is_expression_mode(param_name: String) -> bool:
	return _expression_modes.get(param_name, false)


## Get all parameters that are in expression mode
func get_expression_parameters() -> Array[String]:
	var result: Array[String] = []
	for param_name in _expression_modes.keys():
		if _expression_modes[param_name]:
			result.append(param_name)
	return result
