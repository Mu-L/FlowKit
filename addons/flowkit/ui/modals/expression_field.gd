@tool
extends HBoxContainer
class_name ExpressionField

## A reusable expression input field with integrated expression editor button.
## Can be used anywhere an expression input is needed.

signal value_changed(new_value: String)
signal expression_editor_requested(current_value: String)

## The parameter name for this field
@export var param_name: String = ""

## The parameter type hint
@export var param_type: String = "Variant"

## Placeholder text for the input
@export var placeholder_text: String = "Enter value or expression..."

## Whether the field is in expression mode (shows expression syntax)
var is_expression_mode: bool = false

## Editor interface reference
var editor_interface: EditorInterface

## Reference to the integrated expression editor
var expression_editor: Control = null

# UI Components
var input_field: LineEdit
var expression_button: Button

func _ready() -> void:
	_setup_ui()

func _setup_ui() -> void:
	# Create input field
	input_field = LineEdit.new()
	input_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input_field.placeholder_text = placeholder_text
	input_field.caret_blink = true
	input_field.text_changed.connect(_on_text_changed)
	add_child(input_field)
	
	# Create expression button
	expression_button = Button.new()
	expression_button.text = "Σ 123"
	expression_button.tooltip_text = "Open expression editor"
	expression_button.custom_minimum_size = Vector2(50, 0)
	expression_button.toggle_mode = true
	expression_button.pressed.connect(_on_expression_button_pressed)
	add_child(expression_button)
	
	# Style the button
	_apply_button_style()

func _apply_button_style() -> void:
	if expression_button:
		expression_button.add_theme_color_override("font_color", Color(0.4, 0.6, 0.9))

func set_editor_interface(interface: EditorInterface) -> void:
	editor_interface = interface
	_apply_button_style()

func set_expression_editor(editor: Control) -> void:
	expression_editor = editor

## Set the current value
func set_value(value: String, as_expression: bool = false) -> void:
	is_expression_mode = as_expression
	
	if input_field:
		input_field.text = value
		
		# Update visual style based on mode
		if as_expression:
			input_field.add_theme_color_override("font_color", Color(0.9, 0.9, 0.5))
		else:
			input_field.remove_theme_color_override("font_color")
	
	if expression_button:
		expression_button.button_pressed = as_expression

## Get the current value
func get_value() -> String:
	return input_field.text if input_field else ""

## Check if in expression mode
func is_expression() -> bool:
	return is_expression_mode

func _on_text_changed(new_text: String) -> void:
	value_changed.emit(new_text)

func _on_expression_button_pressed() -> void:
	if expression_editor and expression_editor.has_method("open_for_parameter"):
		expression_editor.open_for_parameter(param_name, param_type, get_value())
	else:
		expression_editor_requested.emit(get_value())

## Toggle expression mode
func set_expression_mode(enabled: bool) -> void:
	is_expression_mode = enabled
	
	if input_field:
		if enabled:
			input_field.add_theme_color_override("font_color", Color(0.9, 0.9, 0.5))
		else:
			input_field.remove_theme_color_override("font_color")
	
	if expression_button:
		expression_button.button_pressed = enabled

## Focus the input field
func grab_input_focus() -> void:
	if input_field:
		input_field.grab_focus()

## Set placeholder text
func set_placeholder(text: String) -> void:
	placeholder_text = text
	if input_field:
		input_field.placeholder_text = text

## Clear the field
func clear() -> void:
	if input_field:
		input_field.clear()
	is_expression_mode = false
	if expression_button:
		expression_button.button_pressed = false
