@tool
extends PopupPanel
class_name IntegratedExpressionEditor

## Integrated Expression Editor - GDevelop Style
## Provides autocomplete and categorized expression browsing for parameter inputs

signal expression_confirmed(param_name: String, expression: String)

## Editor interface reference
var editor_interface: EditorInterface

## Autocomplete system
var autocomplete: ExpressionAutocomplete

## Current parameter being edited
var current_param_name: String = ""
var current_param_type: String = ""

## Context node for expression evaluation
var context_node: Node = null
var scene_root: Node = null

# UI References
@onready var title_label: Label = $MainMargin/MainVBox/TitleBar/TitleLabel
@onready var param_type_label: Label = $MainMargin/MainVBox/TitleBar/ParamTypeLabel
@onready var expression_input: LineEdit = $MainMargin/MainVBox/InputSection/ExpressionInput
@onready var search_input: LineEdit = $MainMargin/MainVBox/ContentSection/LeftPanel/SearchBox
@onready var category_tree: Tree = $MainMargin/MainVBox/ContentSection/LeftPanel/CategoryTree
@onready var expressions_list: ItemList = $MainMargin/MainVBox/ContentSection/RightPanel/ExpressionsList
@onready var description_label: RichTextLabel = $MainMargin/MainVBox/ContentSection/RightPanel/DescriptionPanel/DescriptionMargin/DescriptionLabel
@onready var syntax_label: Label = $MainMargin/MainVBox/ContentSection/RightPanel/SyntaxPanel/SyntaxMargin/SyntaxHBox/SyntaxLabel
@onready var cancel_button: Button = $MainMargin/MainVBox/ButtonBar/CancelButton
@onready var ok_button: Button = $MainMargin/MainVBox/ButtonBar/OKButton

## Currently selected category
var selected_category: int = -1

## Filtered expressions cache
var filtered_expressions: Array = []

func _ready() -> void:
	# Initialize autocomplete system
	autocomplete = ExpressionAutocomplete.new(editor_interface)
	
	# Connect signals
	if search_input:
		search_input.text_changed.connect(_on_search_changed)
	
	if category_tree:
		category_tree.item_selected.connect(_on_category_selected)
	
	if expressions_list:
		expressions_list.item_selected.connect(_on_expression_selected)
		expressions_list.item_activated.connect(_on_expression_activated)
	
	if expression_input:
		expression_input.text_changed.connect(_on_expression_text_changed)
	
	if cancel_button:
		cancel_button.pressed.connect(_on_cancel_pressed)
	
	if ok_button:
		ok_button.pressed.connect(_on_ok_pressed)
	
	# Populate categories
	_populate_categories()

func set_editor_interface(interface: EditorInterface) -> void:
	editor_interface = interface
	if autocomplete:
		autocomplete.editor_interface = interface
	_populate_categories()

func set_context(node: Node, root: Node) -> void:
	context_node = node
	scene_root = root
	if autocomplete:
		autocomplete.context_node_path = str(node.get_path()) if node else ""

## Open the editor for a specific parameter
func open_for_parameter(param_name: String, param_type: String, current_value: String = "") -> void:
	current_param_name = param_name
	current_param_type = param_type
	
	if title_label:
		title_label.text = param_name
	
	if param_type_label:
		param_type_label.text = "(" + param_type + ")"
	
	if expression_input:
		expression_input.text = current_value
		expression_input.grab_focus()
		expression_input.caret_column = expression_input.text.length()
	
	# Reset selection
	selected_category = -1
	if category_tree:
		category_tree.deselect_all()
	
	_clear_expressions_list()
	_clear_description()
	
	popup_centered()

func _populate_categories() -> void:
	if not category_tree or not autocomplete:
		return
	
	category_tree.clear()
	var root: TreeItem = category_tree.create_item()
	category_tree.hide_root = true
	
	# Add "All" category
	var all_item: TreeItem = category_tree.create_item(root)
	all_item.set_text(0, "All Expressions")
	all_item.set_metadata(0, -1)
	if editor_interface:
		var icon = editor_interface.get_base_control().get_theme_icon("Search", "EditorIcons")
		if icon:
			all_item.set_icon(0, icon)
	
	# Add separator
	var sep_item: TreeItem = category_tree.create_item(root)
	sep_item.set_text(0, "─────────────")
	sep_item.set_selectable(0, false)
	sep_item.set_custom_color(0, Color(0.5, 0.5, 0.5))
	
	# Add Operators section first (before Variables)
	_add_operators_category(root)
	
	# Add separator after operators
	var sep_item2: TreeItem = category_tree.create_item(root)
	sep_item2.set_text(0, "─────────────")
	sep_item2.set_selectable(0, false)
	sep_item2.set_custom_color(0, Color(0.5, 0.5, 0.5))
	
	# Add each category
	for cat in autocomplete.get_all_categories():
		var item: TreeItem = category_tree.create_item(root)
		item.set_text(0, ExpressionAutocomplete.get_category_name(cat))
		item.set_metadata(0, cat)
		
		if editor_interface:
			var icon_name = ExpressionAutocomplete.get_category_icon(cat)
			var icon = editor_interface.get_base_control().get_theme_icon(icon_name, "EditorIcons")
			if icon:
				item.set_icon(0, icon)
	
	# Add Node Variables section if context exists
	if context_node:
		_add_node_variables_category(root)
	
	# Add Scene Variables section
	if scene_root:
		_add_scene_variables_category(root)


func _add_operators_category(root: TreeItem) -> void:
	# Operators header
	var ops_header: TreeItem = category_tree.create_item(root)
	ops_header.set_text(0, "Operators & Values")
	ops_header.set_metadata(0, "operators")
	if editor_interface:
		var icon = editor_interface.get_base_control().get_theme_icon("Add", "EditorIcons")
		if icon:
			ops_header.set_icon(0, icon)
	
	# Vectors
	var vectors_item: TreeItem = category_tree.create_item(root)
	vectors_item.set_text(0, "Vectors")
	vectors_item.set_metadata(0, "vectors")
	if editor_interface:
		var icon = editor_interface.get_base_control().get_theme_icon("Vector2", "EditorIcons")
		if icon:
			vectors_item.set_icon(0, icon)
	
	# Colors
	var colors_item: TreeItem = category_tree.create_item(root)
	colors_item.set_text(0, "Colors")
	colors_item.set_metadata(0, "colors")
	if editor_interface:
		var icon = editor_interface.get_base_control().get_theme_icon("Color", "EditorIcons")
		if icon:
			colors_item.set_icon(0, icon)

func _add_node_variables_category(root: TreeItem) -> void:
	if not context_node or not autocomplete:
		return
	
	var node_vars = autocomplete.get_node_variables(context_node)
	if node_vars.is_empty():
		return
	
	# Add separator
	var sep_item: TreeItem = category_tree.create_item(root)
	sep_item.set_text(0, "─────────────")
	sep_item.set_selectable(0, false)
	sep_item.set_custom_color(0, Color(0.5, 0.5, 0.5))
	
	var item: TreeItem = category_tree.create_item(root)
	item.set_text(0, "Node Variables (" + context_node.name + ")")
	item.set_metadata(0, "node_vars")
	
	if editor_interface:
		var icon = editor_interface.get_base_control().get_theme_icon("MemberProperty", "EditorIcons")
		if icon:
			item.set_icon(0, icon)

func _add_scene_variables_category(root: TreeItem) -> void:
	if not scene_root or not autocomplete:
		return
	
	var scene_vars = autocomplete.get_scene_variables(scene_root)
	if scene_vars.is_empty():
		return
	
	var item: TreeItem = category_tree.create_item(root)
	item.set_text(0, "Scene Variables")
	item.set_metadata(0, "scene_vars")
	
	if editor_interface:
		var icon = editor_interface.get_base_control().get_theme_icon("Environment", "EditorIcons")
		if icon:
			item.set_icon(0, icon)

func _on_category_selected() -> void:
	var selected: TreeItem = category_tree.get_selected()
	if not selected:
		return
	
	var metadata = selected.get_metadata(0)
	
	if metadata is int:
		selected_category = metadata
		_populate_expressions_for_category(metadata)
	elif metadata == "node_vars":
		_populate_node_variables()
	elif metadata == "scene_vars":
		_populate_scene_variables()
	elif metadata == "operators":
		_populate_operators()
	elif metadata == "vectors":
		_populate_vectors()
	elif metadata == "colors":
		_populate_colors()

func _populate_expressions_for_category(category: int) -> void:
	if not expressions_list or not autocomplete:
		return
	
	expressions_list.clear()
	filtered_expressions.clear()
	
	var exprs: Array = []
	
	if category == -1:
		# All expressions
		for cat in autocomplete.get_all_categories():
			exprs.append_array(autocomplete.get_expressions_for_category(cat))
	else:
		exprs = autocomplete.get_expressions_for_category(category)
	
	# Apply search filter
	var search_text = search_input.text.to_lower() if search_input else ""
	
	for expr in exprs:
		if search_text.is_empty() or search_text in expr.name.to_lower() or search_text in expr.syntax.to_lower():
			var idx = expressions_list.add_item(expr.name)
			expressions_list.set_item_metadata(idx, expr)
			filtered_expressions.append(expr)
			
			# Set icon based on return type
			if editor_interface:
				var icon_name = _get_type_icon(expr.return_type)
				var icon = editor_interface.get_base_control().get_theme_icon(icon_name, "EditorIcons")
				if icon:
					expressions_list.set_item_icon(idx, icon)

func _populate_node_variables() -> void:
	if not expressions_list or not autocomplete or not context_node:
		return
	
	expressions_list.clear()
	filtered_expressions.clear()
	
	var node_vars = autocomplete.get_node_variables(context_node)
	var search_text = search_input.text.to_lower() if search_input else ""
	
	for var_data in node_vars:
		if search_text.is_empty() or search_text in var_data.name.to_lower():
			var idx = expressions_list.add_item(var_data.name)
			
			# Create a pseudo expression def for consistency
			var expr_def = ExpressionAutocomplete.ExpressionDef.new(
				var_data.name,
				var_data.syntax,
				"Node variable: " + var_data.name,
				ExpressionAutocomplete.Category.VARIABLES,
				"Variant"
			)
			expressions_list.set_item_metadata(idx, expr_def)
			filtered_expressions.append(expr_def)
			
			if editor_interface:
				var icon = editor_interface.get_base_control().get_theme_icon("MemberProperty", "EditorIcons")
				if icon:
					expressions_list.set_item_icon(idx, icon)

func _populate_scene_variables() -> void:
	if not expressions_list or not autocomplete or not scene_root:
		return
	
	expressions_list.clear()
	filtered_expressions.clear()
	
	var scene_vars = autocomplete.get_scene_variables(scene_root)
	var search_text = search_input.text.to_lower() if search_input else ""
	
	for var_data in scene_vars:
		if search_text.is_empty() or search_text in var_data.name.to_lower():
			var idx = expressions_list.add_item(var_data.name)
			
			var expr_def = ExpressionAutocomplete.ExpressionDef.new(
				var_data.name,
				var_data.syntax,
				"Scene variable: " + var_data.name,
				ExpressionAutocomplete.Category.VARIABLES,
				"Variant"
			)
			expressions_list.set_item_metadata(idx, expr_def)
			filtered_expressions.append(expr_def)
			
			if editor_interface:
				var icon = editor_interface.get_base_control().get_theme_icon("Environment", "EditorIcons")
				if icon:
					expressions_list.set_item_icon(idx, icon)

func _on_expression_selected(index: int) -> void:
	if index < 0 or index >= expressions_list.item_count:
		return
	
	var expr = expressions_list.get_item_metadata(index)
	if not expr:
		return
	
	_show_expression_details(expr)

func _show_expression_details(expr: ExpressionAutocomplete.ExpressionDef) -> void:
	if syntax_label:
		syntax_label.text = expr.syntax
	
	if description_label:
		var desc_text = "[b]" + expr.name + "[/b]\n\n"
		desc_text += expr.description + "\n\n"
		
		if not expr.parameters.is_empty():
			desc_text += "[b]Parameters:[/b]\n"
			for param in expr.parameters:
				desc_text += "• [color=#8888ff]" + param.name + "[/color] (" + param.type + "): " + param.get("description", "") + "\n"
		
		desc_text += "\n[b]Returns:[/b] " + expr.return_type
		
		description_label.text = desc_text

func _on_expression_activated(index: int) -> void:
	if index < 0 or index >= expressions_list.item_count:
		return
	
	var expr = expressions_list.get_item_metadata(index)
	if not expr:
		return
	
	_insert_expression(expr.syntax)

func _insert_expression(syntax: String) -> void:
	if not expression_input:
		return
	
	var cursor_pos = expression_input.caret_column
	var current_text = expression_input.text
	
	var before = current_text.substr(0, cursor_pos)
	var after = current_text.substr(cursor_pos)
	
	expression_input.text = before + syntax + after
	expression_input.caret_column = cursor_pos + syntax.length()
	expression_input.grab_focus()

func _on_search_changed(_new_text: String) -> void:
	# Re-filter current category based on selection
	if category_tree:
		var selected = category_tree.get_selected()
		if selected:
			var metadata = selected.get_metadata(0)
			# Check string types first
			if metadata is String:
				match metadata:
					"node_vars":
						_populate_node_variables()
					"scene_vars":
						_populate_scene_variables()
					"operators":
						_populate_operators()
					"vectors":
						_populate_vectors()
					"colors":
						_populate_colors()
			elif metadata is int:
				selected_category = metadata
				_populate_expressions_for_category(metadata)
		elif selected_category != -1:
			_populate_expressions_for_category(selected_category)


func _populate_operators() -> void:
	if not expressions_list:
		return
	
	expressions_list.clear()
	filtered_expressions.clear()
	
	var search_text = search_input.text.to_lower() if search_input else ""
	
	# Get all operators
	var all_ops = ExpressionOperators.get_all_operators()
	
	for category_name in all_ops.keys():
		var ops = all_ops[category_name]
		for op in ops:
			if search_text.is_empty() or search_text in op.name.to_lower() or search_text in op.symbol.to_lower():
				var display = op.symbol + " - " + op.name
				var idx = expressions_list.add_item(display)
				
				var expr_def = ExpressionAutocomplete.ExpressionDef.new(
					op.name,
					op.insert_text,
					op.description,
					ExpressionAutocomplete.Category.COMPARISON,
					"Operator"
				)
				expressions_list.set_item_metadata(idx, expr_def)
				filtered_expressions.append(expr_def)
	
	# Add common literals
	var literals = ExpressionOperators.get_common_literals()
	for lit in literals:
		if search_text.is_empty() or search_text in lit.name.to_lower() or search_text in lit.symbol.to_lower():
			var idx = expressions_list.add_item(lit.symbol + " - " + lit.name)
			
			var expr_def = ExpressionAutocomplete.ExpressionDef.new(
				lit.name,
				lit.insert_text,
				lit.description,
				ExpressionAutocomplete.Category.CONVERSION,
				"Literal"
			)
			expressions_list.set_item_metadata(idx, expr_def)
			filtered_expressions.append(expr_def)


func _populate_vectors() -> void:
	if not expressions_list:
		return
	
	expressions_list.clear()
	filtered_expressions.clear()
	
	var search_text = search_input.text.to_lower() if search_input else ""
	var vectors = ExpressionOperators.get_vector_constructors()
	
	for vec in vectors:
		if search_text.is_empty() or search_text in vec.name.to_lower() or search_text in vec.symbol.to_lower():
			var idx = expressions_list.add_item(vec.name)
			
			var expr_def = ExpressionAutocomplete.ExpressionDef.new(
				vec.name,
				vec.insert_text,
				vec.description,
				ExpressionAutocomplete.Category.CONVERSION,
				"Vector2"
			)
			expressions_list.set_item_metadata(idx, expr_def)
			filtered_expressions.append(expr_def)
			
			if editor_interface:
				var icon = editor_interface.get_base_control().get_theme_icon("Vector2", "EditorIcons")
				if icon:
					expressions_list.set_item_icon(idx, icon)


func _populate_colors() -> void:
	if not expressions_list:
		return
	
	expressions_list.clear()
	filtered_expressions.clear()
	
	var search_text = search_input.text.to_lower() if search_input else ""
	var colors = ExpressionOperators.get_color_constructors()
	
	for col in colors:
		if search_text.is_empty() or search_text in col.name.to_lower() or search_text in col.symbol.to_lower():
			var idx = expressions_list.add_item(col.name)
			
			var expr_def = ExpressionAutocomplete.ExpressionDef.new(
				col.name,
				col.insert_text,
				col.description,
				ExpressionAutocomplete.Category.CONVERSION,
				"Color"
			)
			expressions_list.set_item_metadata(idx, expr_def)
			filtered_expressions.append(expr_def)
			
			if editor_interface:
				var icon = editor_interface.get_base_control().get_theme_icon("Color", "EditorIcons")
				if icon:
					expressions_list.set_item_icon(idx, icon)

func _on_expression_text_changed(_new_text: String) -> void:
	# Could add real-time validation here
	pass

func _clear_expressions_list() -> void:
	if expressions_list:
		expressions_list.clear()
	filtered_expressions.clear()

func _clear_description() -> void:
	if description_label:
		description_label.text = "Select an expression to see details"
	if syntax_label:
		syntax_label.text = ""

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

func _on_cancel_pressed() -> void:
	hide()

func _on_ok_pressed() -> void:
	if expression_input:
		expression_confirmed.emit(current_param_name, expression_input.text)
	hide()
