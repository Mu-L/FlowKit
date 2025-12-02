@tool
extends RefCounted
class_name ExpressionAutocomplete

## Expression Autocomplete System - GDevelop Style
## Provides categorized expression suggestions for the expression editor

## Expression categories
enum Category {
	VARIABLES,
	MATH,
	NODE_PROPERTIES,
	SYSTEM,
	COMPARISON,
	STRING,
	CONVERSION,
	INPUT,
	AUDIO,
	ANIMATION,
	PHYSICS,
	TIME
}

## Expression definition structure
class ExpressionDef:
	var name: String
	var syntax: String
	var description: String
	var category: Category
	var return_type: String
	var parameters: Array[Dictionary]
	
	func _init(p_name: String, p_syntax: String, p_desc: String, p_cat: Category, p_return: String = "Variant", p_params: Array[Dictionary] = []):
		name = p_name
		syntax = p_syntax
		description = p_desc
		category = p_cat
		return_type = p_return
		parameters = p_params

## All available expressions organized by category
var expressions: Dictionary = {}

## Editor interface for accessing scene tree
var editor_interface: EditorInterface

## Current context node path
var context_node_path: String = ""

func _init(editor_if: EditorInterface = null):
	editor_interface = editor_if
	_register_all_expressions()

func _register_all_expressions() -> void:
	expressions.clear()
	
	# Initialize categories
	for cat in Category.values():
		expressions[cat] = []
	
	_register_variable_expressions()
	_register_math_expressions()
	_register_node_expressions()
	_register_system_expressions()
	_register_comparison_expressions()
	_register_string_expressions()
	_register_conversion_expressions()
	_register_input_expressions()
	_register_audio_expressions()
	_register_animation_expressions()
	_register_physics_expressions()
	_register_time_expressions()

func _register_variable_expressions() -> void:
	var cat = Category.VARIABLES
	
	expressions[cat].append(ExpressionDef.new(
		"Get Variable",
		'system.get_var("name")',
		"Gets a global variable value by name",
		cat, "Variant",
		[{"name": "name", "type": "String", "description": "Variable name"}]
	))
	
	expressions[cat].append(ExpressionDef.new(
		"Get Node Variable",
		'system.get_node_var(node, "name")',
		"Gets a variable stored on a specific node",
		cat, "Variant",
		[{"name": "node", "type": "Node", "description": "Target node"},
		 {"name": "name", "type": "String", "description": "Variable name"}]
	))
	
	expressions[cat].append(ExpressionDef.new(
		"Node Variable (Self)",
		'n_variablename',
		"Quick access to a variable on the current node (n_ prefix)",
		cat, "Variant",
		[{"name": "variablename", "type": "String", "description": "Variable name without n_ prefix"}]
	))

func _register_math_expressions() -> void:
	var cat = Category.MATH
	
	# Basic operations
	expressions[cat].append(ExpressionDef.new(
		"Add", "a + b", "Addition of two values", cat, "Number"
	))
	expressions[cat].append(ExpressionDef.new(
		"Subtract", "a - b", "Subtraction of two values", cat, "Number"
	))
	expressions[cat].append(ExpressionDef.new(
		"Multiply", "a * b", "Multiplication of two values", cat, "Number"
	))
	expressions[cat].append(ExpressionDef.new(
		"Divide", "a / b", "Division of two values", cat, "Number"
	))
	expressions[cat].append(ExpressionDef.new(
		"Modulo", "a % b", "Remainder of division", cat, "Number"
	))
	
	# Math functions
	expressions[cat].append(ExpressionDef.new(
		"Absolute", "abs(x)", "Returns the absolute value", cat, "Number",
		[{"name": "x", "type": "Number", "description": "Input value"}]
	))
	expressions[cat].append(ExpressionDef.new(
		"Round", "round(x)", "Rounds to nearest integer", cat, "int",
		[{"name": "x", "type": "Number", "description": "Value to round"}]
	))
	expressions[cat].append(ExpressionDef.new(
		"Floor", "floor(x)", "Rounds down to integer", cat, "int",
		[{"name": "x", "type": "Number", "description": "Value to floor"}]
	))
	expressions[cat].append(ExpressionDef.new(
		"Ceil", "ceil(x)", "Rounds up to integer", cat, "int",
		[{"name": "x", "type": "Number", "description": "Value to ceil"}]
	))
	expressions[cat].append(ExpressionDef.new(
		"Square Root", "sqrt(x)", "Returns the square root", cat, "float",
		[{"name": "x", "type": "Number", "description": "Input value"}]
	))
	expressions[cat].append(ExpressionDef.new(
		"Power", "pow(base, exp)", "Returns base raised to exp power", cat, "float",
		[{"name": "base", "type": "Number", "description": "Base value"},
		 {"name": "exp", "type": "Number", "description": "Exponent"}]
	))
	expressions[cat].append(ExpressionDef.new(
		"Minimum", "min(a, b)", "Returns the smaller value", cat, "Number",
		[{"name": "a", "type": "Number", "description": "First value"},
		 {"name": "b", "type": "Number", "description": "Second value"}]
	))
	expressions[cat].append(ExpressionDef.new(
		"Maximum", "max(a, b)", "Returns the larger value", cat, "Number",
		[{"name": "a", "type": "Number", "description": "First value"},
		 {"name": "b", "type": "Number", "description": "Second value"}]
	))
	expressions[cat].append(ExpressionDef.new(
		"Clamp", "clamp(value, min, max)", "Constrains value between min and max", cat, "Number",
		[{"name": "value", "type": "Number", "description": "Value to clamp"},
		 {"name": "min", "type": "Number", "description": "Minimum bound"},
		 {"name": "max", "type": "Number", "description": "Maximum bound"}]
	))
	expressions[cat].append(ExpressionDef.new(
		"Lerp", "lerp(from, to, weight)", "Linear interpolation between two values", cat, "Number",
		[{"name": "from", "type": "Number", "description": "Start value"},
		 {"name": "to", "type": "Number", "description": "End value"},
		 {"name": "weight", "type": "float", "description": "Interpolation weight (0-1)"}]
	))
	expressions[cat].append(ExpressionDef.new(
		"Sign", "sign(x)", "Returns -1, 0, or 1 based on sign", cat, "int",
		[{"name": "x", "type": "Number", "description": "Input value"}]
	))
	expressions[cat].append(ExpressionDef.new(
		"Random Float", "randf()", "Returns random float between 0 and 1", cat, "float"
	))
	expressions[cat].append(ExpressionDef.new(
		"Random Integer", "randi()", "Returns random integer", cat, "int"
	))
	expressions[cat].append(ExpressionDef.new(
		"Random Range", "randf_range(from, to)", "Returns random float in range", cat, "float",
		[{"name": "from", "type": "float", "description": "Minimum value"},
		 {"name": "to", "type": "float", "description": "Maximum value"}]
	))
	
	# Trigonometry
	expressions[cat].append(ExpressionDef.new(
		"Sine", "sin(angle)", "Returns sine of angle (radians)", cat, "float",
		[{"name": "angle", "type": "float", "description": "Angle in radians"}]
	))
	expressions[cat].append(ExpressionDef.new(
		"Cosine", "cos(angle)", "Returns cosine of angle (radians)", cat, "float",
		[{"name": "angle", "type": "float", "description": "Angle in radians"}]
	))
	expressions[cat].append(ExpressionDef.new(
		"Tangent", "tan(angle)", "Returns tangent of angle (radians)", cat, "float",
		[{"name": "angle", "type": "float", "description": "Angle in radians"}]
	))
	expressions[cat].append(ExpressionDef.new(
		"Degrees to Radians", "deg_to_rad(degrees)", "Converts degrees to radians", cat, "float",
		[{"name": "degrees", "type": "float", "description": "Angle in degrees"}]
	))
	expressions[cat].append(ExpressionDef.new(
		"Radians to Degrees", "rad_to_deg(radians)", "Converts radians to degrees", cat, "float",
		[{"name": "radians", "type": "float", "description": "Angle in radians"}]
	))

func _register_node_expressions() -> void:
	var cat = Category.NODE_PROPERTIES
	
	# Position
	expressions[cat].append(ExpressionDef.new(
		"Position", "node.position", "Current position of the node", cat, "Vector2"
	))
	expressions[cat].append(ExpressionDef.new(
		"Position X", "node.position.x", "X coordinate of position", cat, "float"
	))
	expressions[cat].append(ExpressionDef.new(
		"Position Y", "node.position.y", "Y coordinate of position", cat, "float"
	))
	expressions[cat].append(ExpressionDef.new(
		"Global Position", "node.global_position", "Global position of the node", cat, "Vector2"
	))
	expressions[cat].append(ExpressionDef.new(
		"Global Position X", "node.global_position.x", "Global X coordinate", cat, "float"
	))
	expressions[cat].append(ExpressionDef.new(
		"Global Position Y", "node.global_position.y", "Global Y coordinate", cat, "float"
	))
	
	# Rotation & Scale
	expressions[cat].append(ExpressionDef.new(
		"Rotation", "node.rotation", "Rotation in radians", cat, "float"
	))
	expressions[cat].append(ExpressionDef.new(
		"Rotation Degrees", "node.rotation_degrees", "Rotation in degrees", cat, "float"
	))
	expressions[cat].append(ExpressionDef.new(
		"Scale", "node.scale", "Scale of the node", cat, "Vector2"
	))
	expressions[cat].append(ExpressionDef.new(
		"Scale X", "node.scale.x", "X scale factor", cat, "float"
	))
	expressions[cat].append(ExpressionDef.new(
		"Scale Y", "node.scale.y", "Y scale factor", cat, "float"
	))
	
	# Visibility
	expressions[cat].append(ExpressionDef.new(
		"Visible", "node.visible", "Whether node is visible", cat, "bool"
	))
	expressions[cat].append(ExpressionDef.new(
		"Modulate", "node.modulate", "Color modulation", cat, "Color"
	))
	expressions[cat].append(ExpressionDef.new(
		"Modulate Alpha", "node.modulate.a", "Alpha/opacity value", cat, "float"
	))
	
	# CharacterBody2D specific
	expressions[cat].append(ExpressionDef.new(
		"Velocity", "node.velocity", "Current velocity (CharacterBody2D)", cat, "Vector2"
	))
	expressions[cat].append(ExpressionDef.new(
		"Velocity X", "node.velocity.x", "X component of velocity", cat, "float"
	))
	expressions[cat].append(ExpressionDef.new(
		"Velocity Y", "node.velocity.y", "Y component of velocity", cat, "float"
	))
	expressions[cat].append(ExpressionDef.new(
		"Is On Floor", "node.is_on_floor()", "Whether character is on floor", cat, "bool"
	))
	expressions[cat].append(ExpressionDef.new(
		"Is On Wall", "node.is_on_wall()", "Whether character is touching wall", cat, "bool"
	))
	expressions[cat].append(ExpressionDef.new(
		"Is On Ceiling", "node.is_on_ceiling()", "Whether character is touching ceiling", cat, "bool"
	))
	
	# Node info
	expressions[cat].append(ExpressionDef.new(
		"Node Name", "node.name", "Name of the node", cat, "String"
	))
	expressions[cat].append(ExpressionDef.new(
		"Get Node", 'node.get_node("path")', "Get a child node by path", cat, "Node",
		[{"name": "path", "type": "String", "description": "Relative path to node"}]
	))

func _register_system_expressions() -> void:
	var cat = Category.SYSTEM
	
	expressions[cat].append(ExpressionDef.new(
		"Delta Time", "system.delta", "Time since last frame (seconds)", cat, "float"
	))
	expressions[cat].append(ExpressionDef.new(
		"Time Scale", "Engine.time_scale", "Current time scale", cat, "float"
	))
	expressions[cat].append(ExpressionDef.new(
		"FPS", "Engine.get_frames_per_second()", "Current frames per second", cat, "float"
	))
	expressions[cat].append(ExpressionDef.new(
		"Frame Count", "Engine.get_process_frames()", "Total frames processed", cat, "int"
	))
	expressions[cat].append(ExpressionDef.new(
		"Physics Frame Count", "Engine.get_physics_frames()", "Total physics frames", cat, "int"
	))
	expressions[cat].append(ExpressionDef.new(
		"Screen Width", "ProjectSettings.get_setting(\"display/window/size/viewport_width\")", "Viewport width in pixels", cat, "int"
	))
	expressions[cat].append(ExpressionDef.new(
		"Screen Height", "ProjectSettings.get_setting(\"display/window/size/viewport_height\")", "Viewport height in pixels", cat, "int"
	))

func _register_comparison_expressions() -> void:
	var cat = Category.COMPARISON
	
	expressions[cat].append(ExpressionDef.new(
		"Equal", "a == b", "True if a equals b", cat, "bool"
	))
	expressions[cat].append(ExpressionDef.new(
		"Not Equal", "a != b", "True if a does not equal b", cat, "bool"
	))
	expressions[cat].append(ExpressionDef.new(
		"Greater Than", "a > b", "True if a is greater than b", cat, "bool"
	))
	expressions[cat].append(ExpressionDef.new(
		"Less Than", "a < b", "True if a is less than b", cat, "bool"
	))
	expressions[cat].append(ExpressionDef.new(
		"Greater or Equal", "a >= b", "True if a is greater than or equal to b", cat, "bool"
	))
	expressions[cat].append(ExpressionDef.new(
		"Less or Equal", "a <= b", "True if a is less than or equal to b", cat, "bool"
	))
	expressions[cat].append(ExpressionDef.new(
		"And", "a and b", "True if both a and b are true", cat, "bool"
	))
	expressions[cat].append(ExpressionDef.new(
		"Or", "a or b", "True if either a or b is true", cat, "bool"
	))
	expressions[cat].append(ExpressionDef.new(
		"Not", "not a", "Inverts boolean value", cat, "bool"
	))
	expressions[cat].append(ExpressionDef.new(
		"Ternary", "a if condition else b", "Returns a if condition is true, else b", cat, "Variant"
	))

func _register_string_expressions() -> void:
	var cat = Category.STRING
	
	expressions[cat].append(ExpressionDef.new(
		"Concatenate", 'str1 + str2', "Joins two strings together", cat, "String"
	))
	expressions[cat].append(ExpressionDef.new(
		"String Length", 'text.length()', "Returns length of string", cat, "int",
		[{"name": "text", "type": "String", "description": "Input string"}]
	))
	expressions[cat].append(ExpressionDef.new(
		"Substring", 'text.substr(start, length)', "Extracts part of a string", cat, "String",
		[{"name": "text", "type": "String", "description": "Input string"},
		 {"name": "start", "type": "int", "description": "Start index"},
		 {"name": "length", "type": "int", "description": "Number of characters"}]
	))
	expressions[cat].append(ExpressionDef.new(
		"To Upper", 'text.to_upper()', "Converts to uppercase", cat, "String",
		[{"name": "text", "type": "String", "description": "Input string"}]
	))
	expressions[cat].append(ExpressionDef.new(
		"To Lower", 'text.to_lower()', "Converts to lowercase", cat, "String",
		[{"name": "text", "type": "String", "description": "Input string"}]
	))
	expressions[cat].append(ExpressionDef.new(
		"Find", 'text.find(what)', "Finds position of substring (-1 if not found)", cat, "int",
		[{"name": "text", "type": "String", "description": "String to search in"},
		 {"name": "what", "type": "String", "description": "String to find"}]
	))
	expressions[cat].append(ExpressionDef.new(
		"Replace", 'text.replace(what, with)', "Replaces occurrences in string", cat, "String",
		[{"name": "text", "type": "String", "description": "Input string"},
		 {"name": "what", "type": "String", "description": "String to replace"},
		 {"name": "with", "type": "String", "description": "Replacement string"}]
	))

func _register_conversion_expressions() -> void:
	var cat = Category.CONVERSION
	
	expressions[cat].append(ExpressionDef.new(
		"To String", 'str(value)', "Converts value to string", cat, "String",
		[{"name": "value", "type": "Variant", "description": "Value to convert"}]
	))
	expressions[cat].append(ExpressionDef.new(
		"To Integer", 'int(value)', "Converts value to integer", cat, "int",
		[{"name": "value", "type": "Variant", "description": "Value to convert"}]
	))
	expressions[cat].append(ExpressionDef.new(
		"To Float", 'float(value)', "Converts value to float", cat, "float",
		[{"name": "value", "type": "Variant", "description": "Value to convert"}]
	))
	expressions[cat].append(ExpressionDef.new(
		"To Boolean", 'bool(value)', "Converts value to boolean", cat, "bool",
		[{"name": "value", "type": "Variant", "description": "Value to convert"}]
	))
	expressions[cat].append(ExpressionDef.new(
		"Vector2", 'Vector2(x, y)', "Creates a 2D vector", cat, "Vector2",
		[{"name": "x", "type": "float", "description": "X component"},
		 {"name": "y", "type": "float", "description": "Y component"}]
	))
	expressions[cat].append(ExpressionDef.new(
		"Color", 'Color(r, g, b, a)', "Creates a color", cat, "Color",
		[{"name": "r", "type": "float", "description": "Red (0-1)"},
		 {"name": "g", "type": "float", "description": "Green (0-1)"},
		 {"name": "b", "type": "float", "description": "Blue (0-1)"},
		 {"name": "a", "type": "float", "description": "Alpha (0-1)"}]
	))

## Get category name as string
static func get_category_name(cat: Category) -> String:
	match cat:
		Category.VARIABLES: return "Variables"
		Category.MATH: return "Math"
		Category.NODE_PROPERTIES: return "Node Properties"
		Category.SYSTEM: return "System"
		Category.COMPARISON: return "Comparison"
		Category.STRING: return "String"
		Category.CONVERSION: return "Conversion"
		Category.INPUT: return "Input"
		Category.AUDIO: return "Audio"
		Category.ANIMATION: return "Animation"
		Category.PHYSICS: return "Physics"
		Category.TIME: return "Time"
		_: return "Other"

## Get category icon name for editor
static func get_category_icon(cat: Category) -> String:
	match cat:
		Category.VARIABLES: return "MemberProperty"
		Category.MATH: return "float"
		Category.NODE_PROPERTIES: return "Node"
		Category.SYSTEM: return "Environment"
		Category.COMPARISON: return "Compare"
		Category.STRING: return "String"
		Category.CONVERSION: return "Reload"
		Category.INPUT: return "InputEventKey"
		Category.AUDIO: return "AudioStreamPlayer"
		Category.ANIMATION: return "AnimationPlayer"
		Category.PHYSICS: return "RigidBody2D"
		Category.TIME: return "Timer"
		_: return "Object"

## Get all expressions for a category
func get_expressions_for_category(cat: Category) -> Array:
	return expressions.get(cat, [])

## Get all categories
func get_all_categories() -> Array:
	return Category.values()

## Search expressions by name or description
func search_expressions(query: String) -> Array:
	var results: Array = []
	var query_lower = query.to_lower()
	
	for cat in expressions.keys():
		for expr in expressions[cat]:
			if query_lower in expr.name.to_lower() or query_lower in expr.description.to_lower() or query_lower in expr.syntax.to_lower():
				results.append({"expression": expr, "category": cat})
	
	return results

## Get node variables from scene
func get_node_variables(node: Node) -> Array[Dictionary]:
	var variables: Array[Dictionary] = []
	
	if node and node.has_meta("flowkit_variables"):
		var vars: Dictionary = node.get_meta("flowkit_variables", {})
		for var_name in vars.keys():
			variables.append({
				"name": var_name,
				"value": vars[var_name],
				"syntax": "n_" + var_name
			})
	
	return variables

## Get scene variables from FlowKitSystem
func get_scene_variables(scene_root: Node) -> Array[Dictionary]:
	var variables: Array[Dictionary] = []
	
	if not scene_root:
		return variables
	
	var system = scene_root.get_tree().root.get_node_or_null("/root/FlowKitSystem")
	if system and "variables" in system:
		for var_name in system.variables.keys():
			variables.append({
				"name": var_name,
				"value": system.variables[var_name],
				"syntax": 'system.get_var("' + var_name + '")'
			})
	
	return variables


func _register_input_expressions() -> void:
	var cat = Category.INPUT
	
	# Action checks
	expressions[cat].append(ExpressionDef.new(
		"Is Action Pressed",
		'Input.is_action_pressed("action_name")',
		"Returns true while the action is being held",
		cat, "bool",
		[{"name": "action_name", "type": "String", "description": "Name of the input action"}]
	))
	expressions[cat].append(ExpressionDef.new(
		"Is Action Just Pressed",
		'Input.is_action_just_pressed("action_name")',
		"Returns true on the frame the action was pressed",
		cat, "bool",
		[{"name": "action_name", "type": "String", "description": "Name of the input action"}]
	))
	expressions[cat].append(ExpressionDef.new(
		"Is Action Just Released",
		'Input.is_action_just_released("action_name")',
		"Returns true on the frame the action was released",
		cat, "bool",
		[{"name": "action_name", "type": "String", "description": "Name of the input action"}]
	))
	expressions[cat].append(ExpressionDef.new(
		"Get Action Strength",
		'Input.get_action_strength("action_name")',
		"Returns the strength of the action (0.0 to 1.0)",
		cat, "float",
		[{"name": "action_name", "type": "String", "description": "Name of the input action"}]
	))
	expressions[cat].append(ExpressionDef.new(
		"Get Axis",
		'Input.get_axis("negative_action", "positive_action")',
		"Returns axis value from -1.0 to 1.0 based on two actions",
		cat, "float",
		[{"name": "negative_action", "type": "String", "description": "Action for negative direction"},
		 {"name": "positive_action", "type": "String", "description": "Action for positive direction"}]
	))
	expressions[cat].append(ExpressionDef.new(
		"Get Vector",
		'Input.get_vector("left", "right", "up", "down")',
		"Returns a Vector2 from four directional actions",
		cat, "Vector2",
		[{"name": "left", "type": "String", "description": "Left action"},
		 {"name": "right", "type": "String", "description": "Right action"},
		 {"name": "up", "type": "String", "description": "Up action"},
		 {"name": "down", "type": "String", "description": "Down action"}]
	))
	
	# Key checks
	expressions[cat].append(ExpressionDef.new(
		"Is Key Pressed",
		'Input.is_key_pressed(KEY_SPACE)',
		"Returns true while a specific key is held",
		cat, "bool",
		[{"name": "key", "type": "Key", "description": "Key constant (e.g., KEY_SPACE, KEY_A)"}]
	))
	
	# Mouse
	expressions[cat].append(ExpressionDef.new(
		"Mouse Position",
		'node.get_global_mouse_position()',
		"Returns the global mouse position",
		cat, "Vector2"
	))
	expressions[cat].append(ExpressionDef.new(
		"Local Mouse Position",
		'node.get_local_mouse_position()',
		"Returns the mouse position relative to the node",
		cat, "Vector2"
	))
	expressions[cat].append(ExpressionDef.new(
		"Is Mouse Button Pressed",
		'Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)',
		"Returns true while a mouse button is held",
		cat, "bool",
		[{"name": "button", "type": "MouseButton", "description": "Mouse button constant"}]
	))


func _register_audio_expressions() -> void:
	var cat = Category.AUDIO
	
	expressions[cat].append(ExpressionDef.new(
		"Is Playing",
		'audio_player.playing',
		"Returns true if the audio player is currently playing",
		cat, "bool"
	))
	expressions[cat].append(ExpressionDef.new(
		"Get Playback Position",
		'audio_player.get_playback_position()',
		"Returns the current playback position in seconds",
		cat, "float"
	))
	expressions[cat].append(ExpressionDef.new(
		"Volume dB",
		'audio_player.volume_db',
		"Returns the volume in decibels",
		cat, "float"
	))
	expressions[cat].append(ExpressionDef.new(
		"Pitch Scale",
		'audio_player.pitch_scale',
		"Returns the pitch scale (1.0 = normal)",
		cat, "float"
	))
	expressions[cat].append(ExpressionDef.new(
		"Stream Length",
		'audio_player.stream.get_length()',
		"Returns the length of the audio stream in seconds",
		cat, "float"
	))


func _register_animation_expressions() -> void:
	var cat = Category.ANIMATION
	
	# AnimationPlayer
	expressions[cat].append(ExpressionDef.new(
		"Current Animation",
		'animation_player.current_animation',
		"Returns the name of the currently playing animation",
		cat, "String"
	))
	expressions[cat].append(ExpressionDef.new(
		"Is Playing",
		'animation_player.is_playing()',
		"Returns true if an animation is currently playing",
		cat, "bool"
	))
	expressions[cat].append(ExpressionDef.new(
		"Current Position",
		'animation_player.current_animation_position',
		"Returns the current position in the animation",
		cat, "float"
	))
	expressions[cat].append(ExpressionDef.new(
		"Animation Length",
		'animation_player.current_animation_length',
		"Returns the length of the current animation",
		cat, "float"
	))
	expressions[cat].append(ExpressionDef.new(
		"Speed Scale",
		'animation_player.speed_scale',
		"Returns the animation speed scale",
		cat, "float"
	))
	
	# AnimatedSprite2D
	expressions[cat].append(ExpressionDef.new(
		"Sprite Animation",
		'animated_sprite.animation',
		"Returns the current animation name (AnimatedSprite2D)",
		cat, "String"
	))
	expressions[cat].append(ExpressionDef.new(
		"Sprite Frame",
		'animated_sprite.frame',
		"Returns the current frame index (AnimatedSprite2D)",
		cat, "int"
	))
	expressions[cat].append(ExpressionDef.new(
		"Sprite Is Playing",
		'animated_sprite.is_playing()',
		"Returns true if sprite animation is playing",
		cat, "bool"
	))
	expressions[cat].append(ExpressionDef.new(
		"Frame Count",
		'animated_sprite.sprite_frames.get_frame_count(animated_sprite.animation)',
		"Returns the number of frames in current animation",
		cat, "int"
	))


func _register_physics_expressions() -> void:
	var cat = Category.PHYSICS
	
	# CharacterBody2D
	expressions[cat].append(ExpressionDef.new(
		"Is On Floor",
		'node.is_on_floor()',
		"Returns true if character is on the floor",
		cat, "bool"
	))
	expressions[cat].append(ExpressionDef.new(
		"Is On Wall",
		'node.is_on_wall()',
		"Returns true if character is touching a wall",
		cat, "bool"
	))
	expressions[cat].append(ExpressionDef.new(
		"Is On Ceiling",
		'node.is_on_ceiling()',
		"Returns true if character is touching the ceiling",
		cat, "bool"
	))
	expressions[cat].append(ExpressionDef.new(
		"Get Floor Normal",
		'node.get_floor_normal()',
		"Returns the floor normal vector",
		cat, "Vector2"
	))
	expressions[cat].append(ExpressionDef.new(
		"Get Wall Normal",
		'node.get_wall_normal()',
		"Returns the wall normal vector",
		cat, "Vector2"
	))
	expressions[cat].append(ExpressionDef.new(
		"Get Last Motion",
		'node.get_last_motion()',
		"Returns the last motion applied",
		cat, "Vector2"
	))
	expressions[cat].append(ExpressionDef.new(
		"Get Real Velocity",
		'node.get_real_velocity()',
		"Returns the actual velocity after move_and_slide",
		cat, "Vector2"
	))
	
	# RigidBody2D
	expressions[cat].append(ExpressionDef.new(
		"Linear Velocity",
		'rigid_body.linear_velocity',
		"Returns the linear velocity of a RigidBody2D",
		cat, "Vector2"
	))
	expressions[cat].append(ExpressionDef.new(
		"Angular Velocity",
		'rigid_body.angular_velocity',
		"Returns the angular velocity of a RigidBody2D",
		cat, "float"
	))
	expressions[cat].append(ExpressionDef.new(
		"Mass",
		'rigid_body.mass',
		"Returns the mass of a RigidBody2D",
		cat, "float"
	))
	expressions[cat].append(ExpressionDef.new(
		"Is Sleeping",
		'rigid_body.sleeping',
		"Returns true if the RigidBody2D is sleeping",
		cat, "bool"
	))
	
	# Distance and direction
	expressions[cat].append(ExpressionDef.new(
		"Distance To",
		'node.position.distance_to(target_position)',
		"Returns distance between two positions",
		cat, "float",
		[{"name": "target_position", "type": "Vector2", "description": "Target position"}]
	))
	expressions[cat].append(ExpressionDef.new(
		"Direction To",
		'node.position.direction_to(target_position)',
		"Returns normalized direction vector to target",
		cat, "Vector2",
		[{"name": "target_position", "type": "Vector2", "description": "Target position"}]
	))
	expressions[cat].append(ExpressionDef.new(
		"Angle To",
		'node.position.angle_to_point(target_position)',
		"Returns angle to target position in radians",
		cat, "float",
		[{"name": "target_position", "type": "Vector2", "description": "Target position"}]
	))


func _register_time_expressions() -> void:
	var cat = Category.TIME
	
	expressions[cat].append(ExpressionDef.new(
		"Delta Time",
		'system.delta',
		"Time elapsed since last frame (seconds)",
		cat, "float"
	))
	expressions[cat].append(ExpressionDef.new(
		"Physics Delta",
		'get_physics_process_delta_time()',
		"Time elapsed since last physics frame",
		cat, "float"
	))
	expressions[cat].append(ExpressionDef.new(
		"Time (msec)",
		'Time.get_ticks_msec()',
		"Time since engine start in milliseconds",
		cat, "int"
	))
	expressions[cat].append(ExpressionDef.new(
		"Time (usec)",
		'Time.get_ticks_usec()',
		"Time since engine start in microseconds",
		cat, "int"
	))
	expressions[cat].append(ExpressionDef.new(
		"Unix Time",
		'Time.get_unix_time_from_system()',
		"Current Unix timestamp",
		cat, "float"
	))
	expressions[cat].append(ExpressionDef.new(
		"Time Scale",
		'Engine.time_scale',
		"Current time scale (1.0 = normal)",
		cat, "float"
	))
	
	# Timer specific
	expressions[cat].append(ExpressionDef.new(
		"Timer Time Left",
		'timer.time_left',
		"Time remaining on a Timer node",
		cat, "float"
	))
	expressions[cat].append(ExpressionDef.new(
		"Timer Wait Time",
		'timer.wait_time',
		"Total wait time of a Timer node",
		cat, "float"
	))
	expressions[cat].append(ExpressionDef.new(
		"Timer Is Stopped",
		'timer.is_stopped()',
		"Returns true if timer is stopped",
		cat, "bool"
	))
	expressions[cat].append(ExpressionDef.new(
		"Timer Progress",
		'1.0 - (timer.time_left / timer.wait_time)',
		"Returns timer progress from 0.0 to 1.0",
		cat, "float"
	))
