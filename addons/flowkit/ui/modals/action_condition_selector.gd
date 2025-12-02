@tool
extends PopupPanel
class_name ActionConditionSelector

## Selector popup for actions and conditions.
## Provides a three-column layout: Nodes, Actions/Conditions, and Parameters.
## Integrated with Expression Editor for advanced parameter input.

signal item_selected(node_path: String, item_id: String, item_inputs: Array, parameter_values: Dictionary)

enum SelectorMode { ACTION, CONDITION, EVENT }

## Current selector mode (ACTION or CONDITION)
var selector_mode: SelectorMode = SelectorMode.ACTION

## Editor interface reference for accessing scene tree
var editor_interface: EditorInterface

## Currently selected object path in the scene
var selected_object_path: String = ""

## Currently selected object's class name
var selected_object_class: String = ""

## Currently selected action/condition ID
var selected_item_id: String = ""

## Current parameter values entered by user
var parameter_values: Dictionary = {}

## All available actions loaded from the actions folder
var available_actions: Array = []

## All available conditions loaded from the conditions folder
var available_conditions: Array = []

## Cache for all items in the current view
var _all_items_cache: Array = []

## Scene root node for populating objects tree
var _scene_root: Node = null

## Objects tree manager instance
var _objects_tree_manager: ObjectsTreeManager

## Other actions tree manager instance
var _other_actions_tree_manager: ObjectsTreeManager

## Actions tree manager instance
var _actions_tree_manager: ActionsTreeManager

## Parameters panel manager instance
var _parameters_panel_manager: ParametersPanelManager

## Integrated Expression Editor instance
var _expression_editor: Node = null

## Expression Editor scene path
const EXPRESSION_EDITOR_SCENE = "res://addons/flowkit/ui/modals/integrated_expression_editor.tscn"

# UI References
@onready var search_box: LineEdit = $VBoxContainer/SearchBox
@onready var objects_tab_container: TabContainer = $VBoxContainer/HSplitContainer/ObjectsPanel/TabContainer
@onready var objects_tree: Tree = $VBoxContainer/HSplitContainer/ObjectsPanel/TabContainer/Objects
@onready var other_actions_tree: Tree = $"VBoxContainer/HSplitContainer/ObjectsPanel/TabContainer/Other actions"
@onready var actions_tree: Tree = $"VBoxContainer/HSplitContainer/HSplitContainer2/ActionsPanel/VBoxContainer/ActionsTree"
@onready var description_label: Label = $"VBoxContainer/HSplitContainer/HSplitContainer2/ParametersPanel/VBoxContainer/DescriptionLabel"
@onready var parameters_container: VBoxContainer = $"VBoxContainer/HSplitContainer/HSplitContainer2/ParametersPanel/VBoxContainer/ParametersScrollContainer/ParametersContainer"
@onready var ok_button: Button = $VBoxContainer/ButtonsContainer/OKButton
@onready var cancel_button: Button = $VBoxContainer/ButtonsContainer/CancelButton


func _ready() -> void:
	# Initialize tree managers
	if objects_tree:
		_objects_tree_manager = ObjectsTreeManager.new(objects_tree, editor_interface)
	
	if other_actions_tree:
		_other_actions_tree_manager = ObjectsTreeManager.new(other_actions_tree, editor_interface)
	
	if actions_tree:
		_actions_tree_manager = ActionsTreeManager.new(actions_tree, editor_interface)
	
	# Initialize parameters panel manager
	if description_label and parameters_container:
		_parameters_panel_manager = ParametersPanelManager.new(description_label, parameters_container, editor_interface)
		_parameters_panel_manager.expression_requested.connect(_on_expression_requested)
	
	# Initialize expression editor
	_init_expression_editor()
	
	# Connect signals
	if search_box:
		search_box.text_changed.connect(_on_search_text_changed)
	
	if objects_tab_container:
		objects_tab_container.tab_changed.connect(_on_tab_changed)
	
	if objects_tree:
		objects_tree.item_selected.connect(_on_object_selected)
	
	if other_actions_tree:
		other_actions_tree.item_selected.connect(_on_other_action_category_selected)
	
	if actions_tree:
		actions_tree.item_selected.connect(_on_action_selected)
		actions_tree.item_activated.connect(_on_action_activated)
	
	if ok_button:
		ok_button.pressed.connect(_on_ok_pressed)
		ok_button.disabled = true
	
	if cancel_button:
		cancel_button.pressed.connect(_on_cancel_pressed)
	
	# Load available items
	_load_available_actions()
	_load_available_conditions()


func _init_expression_editor() -> void:
	"""Initialize the integrated expression editor."""
	if ResourceLoader.exists(EXPRESSION_EDITOR_SCENE):
		var expr_scene = load(EXPRESSION_EDITOR_SCENE)
		if expr_scene:
			_expression_editor = expr_scene.instantiate()
			add_child(_expression_editor)
			
			# Set editor interface
			if _expression_editor.has_method("set_editor_interface"):
				_expression_editor.set_editor_interface(editor_interface)
			
			# Connect expression confirmed signal
			if _expression_editor.has_signal("expression_confirmed"):
				_expression_editor.expression_confirmed.connect(_on_expression_confirmed)


func set_selector_mode(new_mode: SelectorMode) -> void:
	"""Set the selector mode (ACTION or CONDITION)."""
	selector_mode = new_mode
	
	# Update dialog title based on mode
	if selector_mode == SelectorMode.ACTION:
		title = "Select an Action"
		if objects_tab_container:
			objects_tab_container.set_tab_title(1, "Other actions")
	else:
		title = "Select a Condition"
		if objects_tab_container:
			objects_tab_container.set_tab_title(1, "Other conditions")


func populate_from_scene(scene_root: Node) -> void:
	"""Populate the objects tree from the given scene root."""
	_scene_root = scene_root
	_populate_objects_tree()
	_clear_actions_panel()
	_clear_parameters_panel()
	
	# Update parameters panel context
	if _parameters_panel_manager:
		_parameters_panel_manager.set_context(null, scene_root)
	
	# Update expression editor context
	if _expression_editor and _expression_editor.has_method("set_context"):
		_expression_editor.set_context(null, scene_root)
	
	if ok_button:
		ok_button.disabled = true


func get_selected_parameters() -> Dictionary:
	"""Get the current parameter values."""
	if _parameters_panel_manager:
		return _parameters_panel_manager.get_parameter_values()
	return parameter_values.duplicate()


# ============================================================================
# PRIVATE METHODS - Loading
# ============================================================================

func _load_available_actions() -> void:
	"""Load all action scripts from the actions folder."""
	available_actions.clear()
	var actions_path: String = "res://addons/flowkit/actions"
	_scan_directory_for_scripts(actions_path, available_actions)


func _load_available_conditions() -> void:
	"""Load all condition scripts from the conditions folder."""
	available_conditions.clear()
	var conditions_path: String = "res://addons/flowkit/conditions"
	_scan_directory_for_scripts(conditions_path, available_conditions)


func _scan_directory_for_scripts(path: String, target_array: Array) -> void:
	"""Recursively scan directories for GDScript files."""
	var dir: DirAccess = DirAccess.open(path)
	if not dir:
		return
	
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	
	while file_name != "":
		var full_path: String = path + "/" + file_name
		
		if dir.current_is_dir() and not file_name.begins_with("."):
			_scan_directory_for_scripts(full_path, target_array)
		elif file_name.ends_with(".gd") and not file_name.ends_with(".gd.uid"):
			var script: GDScript = load(full_path)
			if script:
				var instance: Variant = script.new()
				target_array.append(instance)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()


# ============================================================================
# PRIVATE METHODS - Objects Panel
# ============================================================================

func _populate_objects_tree() -> void:
	"""Populate the objects tree with scene nodes."""
	if not objects_tree or not _scene_root:
		return
	
	objects_tree.clear()
	
	var root_item: TreeItem = objects_tree.create_item()
	root_item.set_text(0, "Scene objects")
	root_item.set_selectable(0, false)
	
	_add_node_to_tree(_scene_root, root_item)


func _add_node_to_tree(node: Node, parent_item: TreeItem) -> void:
	"""Recursively add a node and its children to the tree."""
	var item: TreeItem = objects_tree.create_item(parent_item)
	item.set_text(0, node.name)
	item.set_metadata(0, {
		"path": str(node.get_path()),
		"class": node.get_class()
	})
	
	# Add children
	for child in node.get_children():
		_add_node_to_tree(child, item)


func _filter_objects_tree(search_text: String) -> void:
	"""Filter the objects tree based on search text."""
	if not objects_tree:
		return
	
	var root: TreeItem = objects_tree.get_root()
	if not root:
		return
	
	_filter_tree_item(root, search_text.to_lower())


func _populate_other_actions_categories() -> void:
	"""Populate the Other Actions tree with system-level categories."""
	if not other_actions_tree:
		return
	
	other_actions_tree.clear()
	
	# Define system-level categories based on available actions/conditions
	var categories: Array[Dictionary] = _get_system_categories()
	
	if _other_actions_tree_manager:
		_other_actions_tree_manager.populate_other_actions_tree(categories)
	else:
		# Fallback if manager not initialized
		for category in categories:
			var item: TreeItem = other_actions_tree.create_item()
			item.set_text(0, category.get("name", "Unknown"))
			item.set_metadata(0, {
				"path": "",
				"class": category.get("class", ""),
				"is_category": true
			})


func _get_system_categories() -> Array[Dictionary]:
	"""Get the list of system-level categories for Other Actions tab."""
	var categories: Array[Dictionary] = []
	var found_classes: Array[String] = []
	
	# Scan available items to find unique system-level types
	var items: Array = available_actions if selector_mode == SelectorMode.ACTION else available_conditions
	
	for item in items:
		var supported_types: Array = item.get_supported_types()
		for type_name in supported_types:
			# System-level types are those that don't correspond to scene node classes
			# or are explicitly system categories
			if type_name in ["System", "Timer", "Window"] and type_name not in found_classes:
				found_classes.append(type_name)
				categories.append({
					"name": type_name,
					"class": type_name,
					"icon": _get_category_icon(type_name)
				})
	
	# Sort categories alphabetically
	categories.sort_custom(func(a, b): return a.get("name", "") < b.get("name", ""))
	
	return categories


func _get_category_icon(category_name: String) -> Texture2D:
	"""Get an icon for a category based on its name."""
	if editor_interface:
		var base_control: Control = editor_interface.get_base_control()
		if base_control:
			# Try to get an appropriate icon from the editor theme
			var icon_name: String = category_name
			var icon: Texture2D = base_control.get_theme_icon(icon_name, "EditorIcons")
			if icon:
				return icon
	return null


func _filter_other_actions_tree(search_text: String) -> void:
	"""Filter the Other Actions tree based on search text."""
	if not other_actions_tree:
		return
	
	if _other_actions_tree_manager:
		_other_actions_tree_manager.filter_items(search_text)
	else:
		# Fallback filtering
		var item: TreeItem = other_actions_tree.get_root()
		if item:
			_filter_tree_item(item, search_text.to_lower())
		else:
			# For trees with hide_root, iterate top-level items
			item = other_actions_tree.get_root()
			while item:
				var matches: bool = search_text.is_empty() or search_text.to_lower() in item.get_text(0).to_lower()
				item.visible = matches
				item = item.get_next()


func _filter_tree_item(item: TreeItem, search_lower: String) -> bool:
	"""Recursively filter tree items. Returns true if item or any child matches."""
	var any_child_visible: bool = false
	
	# Process children first
	var child: TreeItem = item.get_first_child()
	while child:
		if _filter_tree_item(child, search_lower):
			any_child_visible = true
		child = child.get_next()
	
	# Check if this item matches
	var item_matches: bool = search_lower.is_empty() or search_lower in item.get_text(0).to_lower()
	
	# Item is visible if it matches or any child is visible
	var should_be_visible: bool = item_matches or any_child_visible
	item.visible = should_be_visible
	
	return should_be_visible


# ============================================================================
# PRIVATE METHODS - Actions Panel
# ============================================================================

func _populate_actions_for_object(object_class: String) -> void:
	"""Populate the actions tree with items compatible with the selected object."""
	if not actions_tree:
		return
	
	_all_items_cache.clear()
	
	var items: Array = available_actions if selector_mode == SelectorMode.ACTION else available_conditions
	
	# Use ActionsTreeManager if available
	if _actions_tree_manager:
		_actions_tree_manager.set_available_items(items)
		_actions_tree_manager.populate_for_object(object_class)
	else:
		# Fallback to manual population
		actions_tree.clear()
		
		# Filter items by compatibility
		var compatible_items: Array = []
		for item in items:
			var supported_types: Array = item.get_supported_types()
			if _is_class_compatible(object_class, supported_types):
				compatible_items.append(item)
		
		if compatible_items.is_empty():
			var root: TreeItem = actions_tree.create_item()
			root.set_text(0, "No items available for this object type")
			root.set_selectable(0, false)
			return
		
		# Group items by category
		var categories: Dictionary = _group_items_by_category(compatible_items)
		
		# Sort category names alphabetically
		var sorted_categories: Array = categories.keys()
		sorted_categories.sort()
		
		# Create tree structure with collapsible category headers
		for category_name in sorted_categories:
			var category_item: TreeItem = actions_tree.create_item()
			category_item.set_text(0, category_name.to_upper())
			category_item.set_selectable(0, false)
			
			for item in categories[category_name]:
				var action_item: TreeItem = actions_tree.create_item(category_item)
				action_item.set_text(0, item.get_name())
				action_item.set_metadata(0, {
					"id": item.get_id(),
					"inputs": item.get_inputs(),
					"description": item.get_description()
				})
				_all_items_cache.append({
					"name": item.get_name(),
					"tree_item": action_item,
					"metadata": action_item.get_metadata(0)
				})


func _group_items_by_category(items: Array) -> Dictionary:
	"""Group items by their category."""
	var categories: Dictionary = {}
	
	for item in items:
		var category: String = "General"
		if item.has_method("get_category"):
			category = item.get_category()
		
		if not categories.has(category):
			categories[category] = []
		categories[category].append(item)
	
	return categories


func _is_class_compatible(node_class: String, supported_types: Array) -> bool:
	"""Check if a node class is compatible with the supported types."""
	if supported_types.is_empty():
		return false
	
	if node_class in supported_types:
		return true
	
	if "Node" in supported_types:
		return true
	
	for supported_type in supported_types:
		if ClassDB.is_parent_class(node_class, supported_type):
			return true
	
	return false


func _filter_actions_tree(search_text: String) -> void:
	"""Filter the actions tree based on search text."""
	if not actions_tree:
		return
	
	# Use ActionsTreeManager if available
	if _actions_tree_manager:
		_actions_tree_manager.filter_items(search_text)
	else:
		# Fallback to manual filtering
		var root: TreeItem = actions_tree.get_root()
		if not root:
			return
		
		_filter_tree_item(root, search_text.to_lower())


func _update_no_results_message() -> void:
	"""Update 'No results found' messages in trees based on visible items."""
	# Check objects tree (only when Objects tab is active)
	if objects_tab_container and objects_tab_container.current_tab == 0:
		_update_tree_no_results(objects_tree, "No objects found")
	else:
		# Check other actions tree
		_update_tree_no_results(other_actions_tree, "No actions found")
	
	# Check actions tree
	_update_tree_no_results(actions_tree, "No results found")


func _update_tree_no_results(target_tree: Tree, message: String) -> void:
	"""Update a specific tree to show 'No results found' if no visible items."""
	if not target_tree:
		return
	
	var has_visible_items: bool = _tree_has_visible_selectable_items(target_tree)
	var search_text: String = search_box.text if search_box else ""
	
	# Find or create the "no results" item
	var no_results_item: TreeItem = _find_no_results_item(target_tree)
	
	if search_text.is_empty():
		# Search cleared - remove "no results" message if it exists
		if no_results_item:
			no_results_item.free()
		return
	
	if has_visible_items:
		# Has visible items - remove "no results" message if it exists
		if no_results_item:
			no_results_item.free()
	else:
		# No visible items - show "no results" message
		if not no_results_item:
			no_results_item = target_tree.create_item()
			no_results_item.set_text(0, message)
			no_results_item.set_selectable(0, false)
			no_results_item.set_metadata(0, {"is_no_results": true})


func _tree_has_visible_selectable_items(target_tree: Tree) -> bool:
	"""Check if a tree has any visible and selectable items."""
	var root: TreeItem = target_tree.get_root()
	if not root:
		return false
	
	return _has_visible_selectable_item(root)


func _has_visible_selectable_item(item: TreeItem) -> bool:
	"""Recursively check if an item or its children are visible and selectable."""
	# Check if this item is visible and selectable
	if item.visible and item.is_selectable(0):
		# Skip "no results" items
		var metadata: Variant = item.get_metadata(0)
		if metadata is Dictionary and metadata.get("is_no_results", false):
			pass  # Skip this item
		else:
			return true
	
	# Check children
	var child: TreeItem = item.get_first_child()
	while child:
		if _has_visible_selectable_item(child):
			return true
		child = child.get_next()
	
	return false


func _find_no_results_item(target_tree: Tree) -> TreeItem:
	"""Find the 'no results' item in a tree if it exists."""
	var root: TreeItem = target_tree.get_root()
	if not root:
		return null
	
	# Check root first
	var metadata: Variant = root.get_metadata(0)
	if metadata is Dictionary and metadata.get("is_no_results", false):
		return root
	
	# Check children of root
	var child: TreeItem = root.get_first_child()
	while child:
		metadata = child.get_metadata(0)
		if metadata is Dictionary and metadata.get("is_no_results", false):
			return child
		child = child.get_next()
	
	# For trees with hide_root, check top-level items
	if target_tree.hide_root:
		var item: TreeItem = root
		while item:
			metadata = item.get_metadata(0)
			if metadata is Dictionary and metadata.get("is_no_results", false):
				return item
			item = item.get_next()
	
	return null


func _clear_actions_panel() -> void:
	"""Clear the actions panel."""
	if actions_tree:
		actions_tree.clear()
	_all_items_cache.clear()


# ============================================================================
# PRIVATE METHODS - Parameters Panel
# ============================================================================

func _display_parameters(item_metadata: Dictionary) -> void:
	"""Display parameters for the selected action/condition."""
	if _parameters_panel_manager:
		_parameters_panel_manager.display_parameters_from_metadata(item_metadata)
		parameter_values = _parameters_panel_manager.get_parameter_values()
	else:
		# Fallback to inline implementation
		_clear_parameters_panel()
		
		if description_label:
			description_label.text = item_metadata.get("description", "")
		
		var inputs: Array = item_metadata.get("inputs", [])
		parameter_values.clear()
		
		for input_def in inputs:
			var param_name: String = input_def.get("name", "")
			var param_type: String = input_def.get("type", "String")
			var param_default: Variant = input_def.get("default", null)
			
			var hbox: HBoxContainer = HBoxContainer.new()
			
			var label: Label = Label.new()
			label.text = param_name + ":"
			label.custom_minimum_size.x = 120
			hbox.add_child(label)
			
			var control: Control = _create_control_for_type(param_type, param_name, param_default)
			control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hbox.add_child(control)
			
			if parameters_container:
				parameters_container.add_child(hbox)
			
			# Store default value
			if param_default != null:
				parameter_values[param_name] = param_default


func _create_control_for_type(param_type: String, param_name: String, default_value: Variant) -> Control:
	"""Create an appropriate control for the parameter type."""
	match param_type:
		"int", "float":
			var spinbox: SpinBox = SpinBox.new()
			spinbox.allow_greater = true
			spinbox.allow_lesser = true
			if param_type == "float":
				spinbox.step = 0.1
			if default_value != null:
				spinbox.value = default_value
			spinbox.value_changed.connect(func(value): _on_parameter_changed(param_name, value))
			return spinbox
		"bool":
			var checkbox: CheckBox = CheckBox.new()
			if default_value != null:
				checkbox.button_pressed = default_value
			checkbox.toggled.connect(func(pressed): _on_parameter_changed(param_name, pressed))
			return checkbox
		_:  # Default to String
			var line_edit: LineEdit = LineEdit.new()
			if default_value != null:
				line_edit.text = str(default_value)
			line_edit.text_changed.connect(func(text): _on_parameter_changed(param_name, text))
			return line_edit


func _clear_parameters_panel() -> void:
	"""Clear the parameters panel."""
	if _parameters_panel_manager:
		_parameters_panel_manager.clear_parameters()
		parameter_values.clear()
	else:
		# Fallback to inline implementation
		if description_label:
			description_label.text = ""
		
		if parameters_container:
			for child in parameters_container.get_children():
				child.queue_free()
		
		parameter_values.clear()


# ============================================================================
# SIGNAL HANDLERS
# ============================================================================

func _on_search_text_changed(new_text: String) -> void:
	"""Handle search text changes."""
	# Filter based on current tab
	if objects_tab_container and objects_tab_container.current_tab == 0:
		_filter_objects_tree(new_text)
	else:
		_filter_other_actions_tree(new_text)
	
	# Always filter the actions tree
	_filter_actions_tree(new_text)
	
	# Update "No results found" messages
	_update_no_results_message()


func _on_tab_changed(tab: int) -> void:
	"""Handle tab switching - search text is preserved automatically."""
	# Tab 0 = Objects (scene objects)
	# Tab 1 = Other actions (system-level categories)
	
	if tab == 0:
		# Objects tab selected - show actions for selected object
		if not selected_object_class.is_empty():
			_populate_actions_for_object(selected_object_class)
		else:
			_clear_actions_panel()
	else:
		# Other actions tab selected - show system-level categories
		_populate_other_actions_categories()
	
	# Clear parameters panel when switching tabs
	_clear_parameters_panel()
	selected_item_id = ""
	if ok_button:
		ok_button.disabled = true
	
	# Apply current search filter to the newly visible tree
	if search_box:
		var search_text: String = search_box.text
		if tab == 0:
			_filter_objects_tree(search_text)
		else:
			_filter_other_actions_tree(search_text)


func _on_object_selected() -> void:
	"""Handle object selection in the objects tree."""
	var selected: TreeItem = objects_tree.get_selected()
	if not selected:
		return
	
	var metadata: Dictionary = selected.get_metadata(0)
	if metadata.is_empty():
		return
	
	selected_object_path = metadata.get("path", "")
	selected_object_class = metadata.get("class", "")
	
	# Update context for expressions
	var context_node: Node = null
	if _scene_root and not selected_object_path.is_empty():
		context_node = _scene_root.get_node_or_null(selected_object_path)
	
	if _parameters_panel_manager:
		_parameters_panel_manager.set_context(context_node, _scene_root)
	
	if _expression_editor and _expression_editor.has_method("set_context"):
		_expression_editor.set_context(context_node, _scene_root)
	
	_populate_actions_for_object(selected_object_class)
	_clear_parameters_panel()
	
	selected_item_id = ""
	if ok_button:
		ok_button.disabled = true


func _on_other_action_category_selected() -> void:
	"""Handle selection in the Other Actions tab."""
	var selected: TreeItem = other_actions_tree.get_selected()
	if not selected:
		return
	
	var metadata: Dictionary = selected.get_metadata(0)
	if metadata.is_empty():
		return
	
	# Get the category class (e.g., "System", "Timer", "Window")
	var category_class: String = metadata.get("class", "")
	if category_class.is_empty():
		return
	
	# Update selection state
	selected_object_path = ""  # No specific object path for system actions
	selected_object_class = category_class
	
	# Populate actions for this category
	_populate_actions_for_object(category_class)
	_clear_parameters_panel()
	
	selected_item_id = ""
	if ok_button:
		ok_button.disabled = true


func _on_action_selected() -> void:
	"""Handle action/condition selection."""
	var selected: TreeItem = actions_tree.get_selected()
	if not selected:
		return
	
	var metadata: Dictionary = selected.get_metadata(0)
	if metadata.is_empty():
		return
	
	selected_item_id = metadata.get("id", "")
	_display_parameters(metadata)
	
	# Sync parameter values from manager
	if _parameters_panel_manager:
		parameter_values = _parameters_panel_manager.get_parameter_values()
	
	if ok_button:
		ok_button.disabled = selected_item_id.is_empty()


func _on_action_activated() -> void:
	"""Handle double-click on action/condition - immediately confirm."""
	_on_action_selected()
	if not selected_item_id.is_empty():
		_confirm_selection()


func _on_parameter_changed(param_name: String, value: Variant) -> void:
	"""Handle parameter value changes."""
	parameter_values[param_name] = value


func _on_expression_requested(param_name: String, param_type: String, current_value: String) -> void:
	"""Handle expression editor button press from parameters panel."""
	if not _expression_editor:
		_init_expression_editor()
	
	if _expression_editor:
		# Set context for expression evaluation
		if _expression_editor.has_method("set_context"):
			var context_node: Node = null
			if _scene_root and not selected_object_path.is_empty():
				context_node = _scene_root.get_node_or_null(selected_object_path)
			_expression_editor.set_context(context_node, _scene_root)
		
		# Open the expression editor
		if _expression_editor.has_method("open_for_parameter"):
			_expression_editor.open_for_parameter(param_name, param_type, current_value)


func _on_expression_confirmed(param_name: String, expression: String) -> void:
	"""Handle confirmed expression from the expression editor."""
	if _parameters_panel_manager:
		# Set the value as an expression
		_parameters_panel_manager.set_parameter_value(param_name, expression, true)
		parameter_values = _parameters_panel_manager.get_parameter_values()


func _on_ok_pressed() -> void:
	"""Handle OK button press."""
	_confirm_selection()


func _on_cancel_pressed() -> void:
	"""Handle Cancel button press."""
	hide()


## Open the selector in edit mode with pre-selected item and values.
## @param mode: The selector mode (ACTION or CONDITION)
## @param node_path: The path to the target node
## @param item_id: The ID of the action/condition to edit
## @param existing_values: Dictionary of existing parameter values
## @param scene_root_node: The scene root node
func open_for_edit(mode: SelectorMode, node_path: String, item_id: String, existing_values: Dictionary, scene_root_node: Node) -> void:
	"""Open selector pre-configured for editing an existing item."""
	selector_mode = mode
	_scene_root = scene_root_node
	
	# Update dialog title
	if selector_mode == SelectorMode.ACTION:
		title = "Edit Action"
		if objects_tab_container:
			objects_tab_container.set_tab_title(1, "Other actions")
	else:
		title = "Edit Condition"
		if objects_tab_container:
			objects_tab_container.set_tab_title(1, "Other conditions")
	
	# Populate objects tree
	_populate_objects_tree()
	
	# Find and select the node in the tree
	selected_object_path = node_path
	var target_node: Node = null
	if _scene_root and not node_path.is_empty():
		target_node = _scene_root.get_node_or_null(node_path)
		if target_node:
			selected_object_class = target_node.get_class()
			_select_node_in_tree(node_path)
	
	# If no node found (system action/condition), check the class from item
	if not target_node:
		selected_object_class = _get_class_from_item_id(item_id)
		if not selected_object_class.is_empty():
			# Switch to "Other actions" tab for system items
			if objects_tab_container:
				objects_tab_container.current_tab = 1
			_populate_other_actions_categories()
			_select_category_in_other_tree(selected_object_class)
	
	# Update context for expressions
	if _parameters_panel_manager:
		_parameters_panel_manager.set_context(target_node, _scene_root)
	
	if _expression_editor and _expression_editor.has_method("set_context"):
		_expression_editor.set_context(target_node, _scene_root)
	
	# Populate actions for the object class
	_populate_actions_for_object(selected_object_class)
	
	# Select the item in the actions tree
	selected_item_id = item_id
	_select_item_in_actions_tree(item_id)
	
	# Display parameters with existing values
	var selected_tree_item: TreeItem = actions_tree.get_selected() if actions_tree else null
	if selected_tree_item:
		var metadata: Dictionary = selected_tree_item.get_metadata(0)
		_display_parameters_with_values(metadata, existing_values)
	
	# Enable OK button
	if ok_button:
		ok_button.disabled = selected_item_id.is_empty()


func _select_node_in_tree(node_path: String) -> void:
	"""Select a node in the objects tree by its path."""
	if not objects_tree:
		return
	
	var root: TreeItem = objects_tree.get_root()
	if not root:
		return
	
	var found_item: TreeItem = _find_tree_item_by_path(root, node_path)
	if found_item:
		found_item.select(0)
		objects_tree.scroll_to_item(found_item)


func _find_tree_item_by_path(item: TreeItem, target_path: String) -> TreeItem:
	"""Recursively find a tree item by node path."""
	var metadata: Variant = item.get_metadata(0)
	if metadata is Dictionary and metadata.get("path", "") == target_path:
		return item
	
	var child: TreeItem = item.get_first_child()
	while child:
		var found: TreeItem = _find_tree_item_by_path(child, target_path)
		if found:
			return found
		child = child.get_next()
	
	return null


func _select_category_in_other_tree(category_class: String) -> void:
	"""Select a category in the Other Actions tree."""
	if not other_actions_tree:
		return
	
	var root: TreeItem = other_actions_tree.get_root()
	if not root:
		# For trees with hide_root, iterate top-level items differently
		var item: TreeItem = other_actions_tree.get_root()
		while item:
			var metadata: Variant = item.get_metadata(0)
			if metadata is Dictionary and metadata.get("class", "") == category_class:
				item.select(0)
				return
			item = item.get_next()
		return
	
	var child: TreeItem = root.get_first_child()
	while child:
		var metadata: Variant = child.get_metadata(0)
		if metadata is Dictionary and metadata.get("class", "") == category_class:
			child.select(0)
			other_actions_tree.scroll_to_item(child)
			return
		child = child.get_next()


func _get_class_from_item_id(item_id: String) -> String:
	"""Get the supported class for an item by its ID."""
	var items: Array = available_actions if selector_mode == SelectorMode.ACTION else available_conditions
	
	for item in items:
		if item.has_method("get_id") and item.get_id() == item_id:
			if item.has_method("get_supported_types"):
				var types: Array = item.get_supported_types()
				if not types.is_empty():
					return types[0]
	
	return ""


func _select_item_in_actions_tree(item_id: String) -> void:
	"""Select an item in the actions tree by its ID."""
	if not actions_tree:
		return
	
	var root: TreeItem = actions_tree.get_root()
	if not root:
		return
	
	var found_item: TreeItem = _find_action_tree_item_by_id(root, item_id)
	if found_item:
		found_item.select(0)
		actions_tree.scroll_to_item(found_item)


func _find_action_tree_item_by_id(item: TreeItem, target_id: String) -> TreeItem:
	"""Recursively find an action tree item by ID."""
	var metadata: Variant = item.get_metadata(0)
	if metadata is Dictionary and metadata.get("id", "") == target_id:
		return item
	
	var child: TreeItem = item.get_first_child()
	while child:
		var found: TreeItem = _find_action_tree_item_by_id(child, target_id)
		if found:
			return found
		child = child.get_next()
	
	return null


func _display_parameters_with_values(item_metadata: Dictionary, existing_values: Dictionary) -> void:
	"""Display parameters and populate with existing values."""
	if _parameters_panel_manager:
		_parameters_panel_manager.display_parameters_from_metadata(item_metadata)
		
		# Set existing values
		for param_name in existing_values.keys():
			var value = existing_values[param_name]
			# Check if value looks like an expression (contains operators or function calls)
			var is_expression: bool = _looks_like_expression(str(value))
			_parameters_panel_manager.set_parameter_value(param_name, value, is_expression)
		
		parameter_values = _parameters_panel_manager.get_parameter_values()
	else:
		# Fallback
		_display_parameters(item_metadata)
		for param_name in existing_values.keys():
			parameter_values[param_name] = existing_values[param_name]


func _looks_like_expression(value: String) -> bool:
	"""Check if a value looks like an expression rather than a simple value."""
	# Simple heuristic: contains operators, parentheses, or known expression patterns
	if value.contains("(") or value.contains(")"):
		return true
	if value.contains("+") or value.contains("-") or value.contains("*") or value.contains("/"):
		return true
	if value.contains(".") and not value.is_valid_float():
		return true
	return false


func _on_popup_hide() -> void:
	"""Handle popup hide - clear search and restore panels."""
	if search_box:
		search_box.clear()
	
	# Restore visibility of panels (in case they were hidden for EVENT mode)
	if objects_tab_container:
		objects_tab_container.visible = true
	if actions_tree and actions_tree.get_parent() and actions_tree.get_parent().get_parent():
		actions_tree.get_parent().get_parent().visible = true


## Open the selector for event parameter input only (no item selection needed).
## @param node_path: The path to the target node
## @param event_id: The ID of the event
## @param inputs: Array of input definitions
## @param existing_values: Dictionary of existing parameter values (optional)
## @param scene_root_node: The scene root node
func open_for_event_parameters(node_path: String, event_id: String, inputs: Array, existing_values: Dictionary, scene_root_node: Node) -> void:
	"""Open selector for event parameter input only."""
	selector_mode = SelectorMode.EVENT
	_scene_root = scene_root_node
	
	# Update dialog title
	title = "Event Parameters: " + event_id
	
	# Store selection info
	selected_object_path = node_path
	selected_item_id = event_id
	
	# Find context node
	var target_node: Node = null
	if _scene_root and not node_path.is_empty():
		target_node = _scene_root.get_node_or_null(node_path)
		if target_node:
			selected_object_class = target_node.get_class()
	
	# Update context for expressions
	if _parameters_panel_manager:
		_parameters_panel_manager.set_context(target_node, _scene_root)
	
	if _expression_editor and _expression_editor.has_method("set_context"):
		_expression_editor.set_context(target_node, _scene_root)
	
	# Hide the left panels (objects and actions) since we only need parameters
	if objects_tab_container:
		objects_tab_container.visible = false
	if actions_tree:
		actions_tree.get_parent().get_parent().visible = false
	
	# Create metadata from inputs
	var item_metadata: Dictionary = {
		"id": event_id,
		"inputs": inputs,
		"description": "Configure event parameters"
	}
	
	# Display parameters with existing values
	_display_parameters_with_values(item_metadata, existing_values)
	
	# Enable OK button
	if ok_button:
		ok_button.disabled = false


func _confirm_selection() -> void:
	"""Confirm the current selection and emit signal."""
	# For EVENT mode, we don't need a selected item in the tree
	if selector_mode == SelectorMode.EVENT:
		var final_parameter_values: Dictionary = {}
		if _parameters_panel_manager:
			final_parameter_values = _parameters_panel_manager.get_parameter_values()
		else:
			final_parameter_values = parameter_values.duplicate()
		
		item_selected.emit(selected_object_path, selected_item_id, [], final_parameter_values)
		
		# Restore visibility of panels
		if objects_tab_container:
			objects_tab_container.visible = true
		if actions_tree:
			actions_tree.get_parent().get_parent().visible = true
		
		hide()
		return
	
	if selected_item_id.is_empty():
		return
	
	var selected: TreeItem = actions_tree.get_selected()
	if not selected:
		return
	
	var metadata: Dictionary = selected.get_metadata(0)
	var inputs: Array = metadata.get("inputs", [])
	
	# Get the latest parameter values from the manager
	var final_parameter_values: Dictionary = {}
	if _parameters_panel_manager:
		final_parameter_values = _parameters_panel_manager.get_parameter_values()
	else:
		final_parameter_values = parameter_values.duplicate()
	
	item_selected.emit(selected_object_path, selected_item_id, inputs, final_parameter_values)
	hide()
