@tool
extends RefCounted
class_name ObjectsTreeManager

## Manages the objects tree display in the GDevelop-style selector.
## Handles populating, filtering, and selection of scene objects.

## The Tree control being managed
var tree: Tree

## Editor interface for accessing icons and scene information
var editor_interface: EditorInterface

## Cache of all tree items for filtering
var _all_items: Array[Dictionary] = []

## Root item of the tree
var _root_item: TreeItem


func _init(p_tree: Tree, p_editor_interface: EditorInterface = null) -> void:
	tree = p_tree
	editor_interface = p_editor_interface


## Populate the objects tree from the given scene root node.
## Creates a hierarchical tree structure mirroring the scene tree.
func populate_objects_tree(root: Node) -> void:
	if not tree or not root:
		return
	
	tree.clear()
	_all_items.clear()
	
	# Create the root category item
	_root_item = tree.create_item()
	_root_item.set_text(0, "Scene objects")
	_root_item.set_selectable(0, false)
	
	# Recursively add all nodes from the scene
	_add_node_to_tree(root, _root_item)


## Populate the tree with "Other actions" categories.
## Used for the second tab showing system-level actions.
func populate_other_actions_tree(categories: Array) -> void:
	if not tree:
		return
	
	tree.clear()
	_all_items.clear()
	
	for category in categories:
		var category_name: String = category.get("name", "Unknown")
		var category_icon: Texture2D = category.get("icon", null)
		var category_class: String = category.get("class", "")
		
		var item: TreeItem = tree.create_item()
		item.set_text(0, category_name)
		
		if category_icon:
			item.set_icon(0, category_icon)
		
		item.set_metadata(0, {
			"path": "",
			"class": category_class,
			"is_category": true
		})
		
		_all_items.append({
			"name": category_name,
			"tree_item": item,
			"metadata": item.get_metadata(0)
		})


## Filter tree items based on search text.
## Items matching the search (case-insensitive) remain visible.
## Parent items remain visible if any child matches.
func filter_items(search_text: String) -> void:
	if not tree:
		return
	
	var root: TreeItem = tree.get_root()
	if not root:
		# For trees without a root (hide_root = true), iterate top-level items
		var item: TreeItem = tree.get_root()
		if item:
			_filter_tree_item(item, search_text.to_lower())
		return
	
	_filter_tree_item(root, search_text.to_lower())


## Get the currently selected object's information.
## Returns a dictionary with 'path' and 'class' keys.
func get_selected_object() -> Dictionary:
	if not tree:
		return {}
	
	var selected: TreeItem = tree.get_selected()
	if not selected:
		return {}
	
	var metadata: Variant = selected.get_metadata(0)
	if metadata is Dictionary:
		return metadata
	
	return {}


## Collapse all expandable items in the tree.
func collapse_all() -> void:
	if not tree:
		return
	
	var root: TreeItem = tree.get_root()
	if root:
		_set_collapsed_recursive(root, true)


## Expand all expandable items in the tree.
func expand_all() -> void:
	if not tree:
		return
	
	var root: TreeItem = tree.get_root()
	if root:
		_set_collapsed_recursive(root, false)


## Toggle the collapsed state of a specific item.
func toggle_item_collapsed(item: TreeItem) -> void:
	if item:
		item.collapsed = not item.collapsed


# ============================================================================
# PRIVATE METHODS
# ============================================================================

## Recursively add a node and its children to the tree.
func _add_node_to_tree(node: Node, parent_item: TreeItem) -> void:
	var item: TreeItem = tree.create_item(parent_item)
	item.set_text(0, node.name)
	
	# Set icon based on node class
	var icon: Texture2D = _get_node_icon(node)
	if icon:
		item.set_icon(0, icon)
	
	# Store metadata for selection handling
	var metadata: Dictionary = {
		"path": str(node.get_path()),
		"class": node.get_class()
	}
	item.set_metadata(0, metadata)
	
	# Cache for filtering
	_all_items.append({
		"name": node.name,
		"tree_item": item,
		"metadata": metadata
	})
	
	# Recursively add children
	for child in node.get_children():
		_add_node_to_tree(child, item)


## Get the appropriate icon for a node based on its class.
func _get_node_icon(node: Node) -> Texture2D:
	if editor_interface:
		var base_control: Control = editor_interface.get_base_control()
		if base_control:
			var icon: Texture2D = base_control.get_theme_icon(node.get_class(), "EditorIcons")
			if icon:
				return icon
	
	# Fallback: try to get icon from theme
	return null


## Recursively filter tree items based on search text.
## Returns true if this item or any descendant matches.
func _filter_tree_item(item: TreeItem, search_lower: String) -> bool:
	var any_child_visible: bool = false
	
	# Process children first (depth-first)
	var child: TreeItem = item.get_first_child()
	while child:
		if _filter_tree_item(child, search_lower):
			any_child_visible = true
		child = child.get_next()
	
	# Check if this item matches the search
	var item_text: String = item.get_text(0).to_lower()
	var item_matches: bool = search_lower.is_empty() or search_lower in item_text
	
	# Item is visible if it matches OR any child is visible
	var should_be_visible: bool = item_matches or any_child_visible
	item.visible = should_be_visible
	
	# Auto-expand items that have matching children
	if any_child_visible and not search_lower.is_empty():
		item.collapsed = false
	
	return should_be_visible


## Recursively set collapsed state for all items.
func _set_collapsed_recursive(item: TreeItem, collapsed: bool) -> void:
	item.collapsed = collapsed
	
	var child: TreeItem = item.get_first_child()
	while child:
		_set_collapsed_recursive(child, collapsed)
		child = child.get_next()
