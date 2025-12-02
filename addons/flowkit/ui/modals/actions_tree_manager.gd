@tool
extends RefCounted
class_name ActionsTreeManager

## Manages the actions/conditions tree display in the GDevelop-style selector.
## Handles populating, filtering, and grouping of actions by category.

## The Tree control being managed
var tree: Tree

## Editor interface for accessing icons
var editor_interface: EditorInterface

## All available items (actions or conditions)
var available_items: Array = []

## Cache of all tree items for filtering
var _all_items: Array[Dictionary] = []

## Root item of the tree
var _root_item: TreeItem

## Category tree items for quick access
var _category_items: Dictionary = {}


func _init(p_tree: Tree, p_editor_interface: EditorInterface = null) -> void:
	tree = p_tree
	editor_interface = p_editor_interface


## Set the available items (actions or conditions) to display.
func set_available_items(items: Array) -> void:
	available_items = items


## Populate the actions tree with items compatible with the given object class.
## Filters items by supported_types and groups them by category.
func populate_for_object(object_class: String) -> void:
	if not tree:
		return
	
	tree.clear()
	_all_items.clear()
	_category_items.clear()
	
	# Filter items by compatibility with the object class
	var compatible_items: Array = _get_compatible_items(object_class)
	
	if compatible_items.is_empty():
		_root_item = tree.create_item()
		_root_item.set_text(0, "No items available for this object type")
		_root_item.set_selectable(0, false)
		return

	# Group items by category
	var categories: Dictionary = group_items_by_category(compatible_items)
	
	# Sort category names alphabetically
	var sorted_categories: Array = categories.keys()
	sorted_categories.sort()
	
	# Create tree structure with collapsible category headers
	for category_name in sorted_categories:
		var category_item: TreeItem = tree.create_item()
		category_item.set_text(0, category_name.to_upper())
		category_item.set_selectable(0, false)
		
		# Set category icon if available
		var category_icon: Texture2D = _get_category_icon(category_name)
		if category_icon:
			category_item.set_icon(0, category_icon)
		
		_category_items[category_name] = category_item
		
		# Add items under this category
		for item in categories[category_name]:
			_add_item_to_tree(item, category_item)


## Group items by their category.
## Returns a dictionary mapping category names to arrays of items.
func group_items_by_category(items: Array) -> Dictionary:
	var categories: Dictionary = {}
	
	for item in items:
		var category: String = "General"
		if item.has_method("get_category"):
			category = item.get_category()
		
		if not categories.has(category):
			categories[category] = []
		categories[category].append(item)
	
	return categories


## Filter tree items based on search text.
## Items matching the search (case-insensitive) remain visible.
## Category headers remain visible if any child matches.
func filter_items(search_text: String) -> void:
	if not tree:
		return
	
	var search_lower: String = search_text.to_lower()
	
	# Iterate through all cached items
	for item_data in _all_items:
		var tree_item: TreeItem = item_data.get("tree_item")
		var item_name: String = item_data.get("name", "").to_lower()
		
		if tree_item:
			var matches: bool = search_lower.is_empty() or search_lower in item_name
			tree_item.visible = matches
	
	# Update category visibility based on children
	for category_name in _category_items.keys():
		var category_item: TreeItem = _category_items[category_name]
		var has_visible_children: bool = _has_visible_children(category_item)
		category_item.visible = has_visible_children
		
		# Auto-expand categories with matching items
		if has_visible_children and not search_lower.is_empty():
			category_item.collapsed = false


## Get the currently selected item's information.
## Returns a dictionary with 'id', 'inputs', and 'description' keys.
func get_selected_item() -> Dictionary:
	if not tree:
		return {}
	
	var selected: TreeItem = tree.get_selected()
	if not selected:
		return {}
	
	var metadata: Variant = selected.get_metadata(0)
	if metadata is Dictionary:
		return metadata
	
	return {}


## Collapse all category headers.
func collapse_all() -> void:
	for category_item in _category_items.values():
		category_item.collapsed = true


## Expand all category headers.
func expand_all() -> void:
	for category_item in _category_items.values():
		category_item.collapsed = false


# ============================================================================
# PRIVATE METHODS
# ============================================================================

## Get items compatible with the given object class.
func _get_compatible_items(object_class: String) -> Array:
	var compatible: Array = []
	
	for item in available_items:
		var supported_types: Array = item.get_supported_types()
		if _is_class_compatible(object_class, supported_types):
			compatible.append(item)
	
	return compatible


## Check if a node class is compatible with the supported types.
func _is_class_compatible(node_class: String, supported_types: Array) -> bool:
	if supported_types.is_empty():
		return false
	
	# Direct match
	if node_class in supported_types:
		return true
	
	# "Node" supports all node types
	if "Node" in supported_types:
		return true
	
	# Check inheritance hierarchy
	for supported_type in supported_types:
		if ClassDB.is_parent_class(node_class, supported_type):
			return true
	
	return false


## Add an action/condition item to the tree under a category.
func _add_item_to_tree(item: Variant, parent_item: TreeItem) -> void:
	var tree_item: TreeItem = tree.create_item(parent_item)
	tree_item.set_text(0, item.get_name())
	
	# Set icon if available
	var icon: Texture2D = _get_item_icon(item)
	if icon:
		tree_item.set_icon(0, icon)
	
	# Store metadata for selection handling
	var metadata: Dictionary = {
		"id": item.get_id(),
		"inputs": item.get_inputs(),
		"description": item.get_description(),
		"category": item.get_category() if item.has_method("get_category") else "General"
	}
	tree_item.set_metadata(0, metadata)
	
	# Cache for filtering
	_all_items.append({
		"name": item.get_name(),
		"tree_item": tree_item,
		"metadata": metadata
	})


## Get the appropriate icon for an action/condition item.
func _get_item_icon(item: Variant) -> Texture2D:
	if not editor_interface:
		return null
	
	var base_control: Control = editor_interface.get_base_control()
	if not base_control:
		return null
	
	# Try to get icon based on supported types
	var supported_types: Array = item.get_supported_types()
	if not supported_types.is_empty():
		var icon: Texture2D = base_control.get_theme_icon(supported_types[0], "EditorIcons")
		if icon:
			return icon
	
	# Fallback to generic action icon
	return base_control.get_theme_icon("Play", "EditorIcons")


## Get the appropriate icon for a category.
func _get_category_icon(category_name: String) -> Texture2D:
	if not editor_interface:
		return null
	
	var base_control: Control = editor_interface.get_base_control()
	if not base_control:
		return null
	
	# Map category names to editor icons
	var icon_map: Dictionary = {
		"Movement": "CharacterBody2D",
		"Audio": "AudioStreamPlayer",
		"Variables": "MemberProperty",
		"System": "Node",
		"Timer": "Timer",
		"Window": "Window",
		"General": "Script"
	}
	
	var icon_name: String = icon_map.get(category_name, "Script")
	return base_control.get_theme_icon(icon_name, "EditorIcons")


## Check if a tree item has any visible children.
func _has_visible_children(item: TreeItem) -> bool:
	var child: TreeItem = item.get_first_child()
	while child:
		if child.visible:
			return true
		child = child.get_next()
	return false
