@tool
extends VBoxContainer
class_name FKVBoxContainer

func _can_drop_data(at_position: Vector2, data) -> bool:
	# Check if data is a dictionary with our expected structure
	var drag_data := data as FKDragData
	if not drag_data:
		return false
	
	if not data.node or not data.type:
		return false
	
	var node = drag_data.node
	
	# Verify the node is a child of this container
	if not is_instance_valid(node) or node.get_parent() != self:
		return false
	
	# Only allow dragging event, condition, and action nodes
	return drag_data.type in [DragTarget.Type.EVENT, DragTarget.Type.CONDITION, \
	DragTarget.Type.ACTION]

func _drop_data(at_position: Vector2, data):
	var drag_data := data as FKDragData
	if not drag_data or not drag_data.node:
		return
	
	var dragged_node = drag_data.node
	
	if not is_instance_valid(dragged_node) or dragged_node.get_parent() != self:
		return
	
	var old_index = dragged_node.get_index()
	var new_index: int = _get_drop_index(at_position)
	
	# Adjust index if moving down
	if new_index > old_index:
		new_index -= 1
	
	# Only move if the position actually changed
	if old_index != new_index:
		move_child(dragged_node, new_index)

func _get_drop_index(at_position: Vector2) -> int:
	var child_count = get_child_count()
	if child_count == 0:
		return 0
	
	for i in range(child_count):
		var child = get_child(i)
		if not child is Control:
			continue
			
		# Skip the "No Action Available" label
		if child.name == "No Action Available":
			continue
		
		var child_rect = child.get_rect()
		var child_middle = child_rect.position.y + child_rect.size.y / 2
		
		if at_position.y < child_middle:
			return i
	
	return child_count
