@tool
extends Control
class_name DropZoneUi

signal item_dropped(drag_data: Dictionary)

@export var accept_type: DragTarget.Type  
# ^DragTarget.Type.CONDITION_ITEM or DragTarget.Type.ACTION_ITEM

func _can_drop_data(at_position: Vector2, data) -> bool:
	if data is not FKDragData:
		printerr("DropZoneUi _can_drop_data not given an FKDragData. It got: " \
		+ str(data))
		return false
		
	var drag_data := data as FKDragData
	var drag_type = drag_data.type
	return drag_type == accept_type

func _drop_data(at_position: Vector2, data) -> void:
	if _can_drop_data(at_position, data):
		item_dropped.emit(data)
