@tool
extends RefCounted
class_name ExpressionOperators

## Provides operator definitions for the expression editor
## Used for quick insertion of common operators

class OperatorDef:
	var symbol: String
	var name: String
	var description: String
	var category: String
	var insert_text: String  # What to actually insert (may differ from symbol)
	
	func _init(p_symbol: String, p_name: String, p_desc: String, p_cat: String, p_insert: String = ""):
		symbol = p_symbol
		name = p_name
		description = p_desc
		category = p_cat
		insert_text = p_insert if not p_insert.is_empty() else p_symbol

## Get all arithmetic operators
static func get_arithmetic_operators() -> Array[OperatorDef]:
	return [
		OperatorDef.new("+", "Add", "Addition", "Arithmetic"),
		OperatorDef.new("-", "Subtract", "Subtraction", "Arithmetic"),
		OperatorDef.new("*", "Multiply", "Multiplication", "Arithmetic"),
		OperatorDef.new("/", "Divide", "Division", "Arithmetic"),
		OperatorDef.new("%", "Modulo", "Remainder of division", "Arithmetic"),
		OperatorDef.new("**", "Power", "Exponentiation", "Arithmetic"),
	]

## Get all comparison operators
static func get_comparison_operators() -> Array[OperatorDef]:
	return [
		OperatorDef.new("==", "Equal", "Equal to", "Comparison"),
		OperatorDef.new("!=", "Not Equal", "Not equal to", "Comparison"),
		OperatorDef.new("<", "Less Than", "Less than", "Comparison"),
		OperatorDef.new(">", "Greater Than", "Greater than", "Comparison"),
		OperatorDef.new("<=", "Less or Equal", "Less than or equal to", "Comparison"),
		OperatorDef.new(">=", "Greater or Equal", "Greater than or equal to", "Comparison"),
	]

## Get all logical operators
static func get_logical_operators() -> Array[OperatorDef]:
	return [
		OperatorDef.new("and", "And", "Logical AND", "Logical"),
		OperatorDef.new("or", "Or", "Logical OR", "Logical"),
		OperatorDef.new("not", "Not", "Logical NOT", "Logical"),
	]

## Get all assignment operators (for actions)
static func get_assignment_operators() -> Array[OperatorDef]:
	return [
		OperatorDef.new("=", "Set", "Set value", "Assignment"),
		OperatorDef.new("+=", "Add", "Add to value", "Assignment"),
		OperatorDef.new("-=", "Subtract", "Subtract from value", "Assignment"),
		OperatorDef.new("*=", "Multiply", "Multiply value", "Assignment"),
		OperatorDef.new("/=", "Divide", "Divide value", "Assignment"),
	]

## Get all operators grouped by category
static func get_all_operators() -> Dictionary:
	return {
		"Arithmetic": get_arithmetic_operators(),
		"Comparison": get_comparison_operators(),
		"Logical": get_logical_operators(),
		"Assignment": get_assignment_operators(),
	}

## Get operators suitable for condition expressions
static func get_condition_operators() -> Array[OperatorDef]:
	var ops: Array[OperatorDef] = []
	ops.append_array(get_comparison_operators())
	ops.append_array(get_logical_operators())
	return ops

## Get operators suitable for value expressions
static func get_value_operators() -> Array[OperatorDef]:
	var ops: Array[OperatorDef] = []
	ops.append_array(get_arithmetic_operators())
	return ops

## Common brackets and grouping
static func get_grouping_symbols() -> Array[OperatorDef]:
	return [
		OperatorDef.new("()", "Parentheses", "Group expressions", "Grouping", "("),
		OperatorDef.new("[]", "Array Access", "Access array element", "Grouping", "["),
		OperatorDef.new(".", "Member Access", "Access object member", "Grouping"),
	]

## Get common literal values
static func get_common_literals() -> Array[OperatorDef]:
	return [
		OperatorDef.new("true", "True", "Boolean true", "Literals"),
		OperatorDef.new("false", "False", "Boolean false", "Literals"),
		OperatorDef.new("null", "Null", "Null value", "Literals"),
		OperatorDef.new("PI", "Pi", "Mathematical constant π (3.14159...)", "Literals"),
		OperatorDef.new("TAU", "Tau", "Mathematical constant τ (6.28318...)", "Literals"),
		OperatorDef.new("INF", "Infinity", "Positive infinity", "Literals"),
	]

## Get Vector constructors
static func get_vector_constructors() -> Array[OperatorDef]:
	return [
		OperatorDef.new("Vector2(x, y)", "Vector2", "Create 2D vector", "Vectors", "Vector2("),
		OperatorDef.new("Vector2.ZERO", "Vector2 Zero", "Zero vector (0, 0)", "Vectors"),
		OperatorDef.new("Vector2.ONE", "Vector2 One", "One vector (1, 1)", "Vectors"),
		OperatorDef.new("Vector2.UP", "Vector2 Up", "Up direction (0, -1)", "Vectors"),
		OperatorDef.new("Vector2.DOWN", "Vector2 Down", "Down direction (0, 1)", "Vectors"),
		OperatorDef.new("Vector2.LEFT", "Vector2 Left", "Left direction (-1, 0)", "Vectors"),
		OperatorDef.new("Vector2.RIGHT", "Vector2 Right", "Right direction (1, 0)", "Vectors"),
		OperatorDef.new("Vector3(x, y, z)", "Vector3", "Create 3D vector", "Vectors", "Vector3("),
	]

## Get Color constructors
static func get_color_constructors() -> Array[OperatorDef]:
	return [
		OperatorDef.new("Color(r, g, b, a)", "Color RGBA", "Create color from RGBA", "Colors", "Color("),
		OperatorDef.new("Color.WHITE", "White", "White color", "Colors"),
		OperatorDef.new("Color.BLACK", "Black", "Black color", "Colors"),
		OperatorDef.new("Color.RED", "Red", "Red color", "Colors"),
		OperatorDef.new("Color.GREEN", "Green", "Green color", "Colors"),
		OperatorDef.new("Color.BLUE", "Blue", "Blue color", "Colors"),
		OperatorDef.new("Color.YELLOW", "Yellow", "Yellow color", "Colors"),
		OperatorDef.new("Color.TRANSPARENT", "Transparent", "Fully transparent", "Colors"),
	]
