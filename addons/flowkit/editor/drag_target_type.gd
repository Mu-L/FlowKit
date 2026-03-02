## The type of Node being dragged. We can't pass actual Node types directly like
## we can in C#, so this enum will have to do.
class_name DragTarget

enum Type
{
	none, 
	action, action_item,
	comment,
	condition, condition_item,
	event, event_row,
	group
}

static func get_name_for(val: int) -> String:
	var result := ""
	match val:
		Type.none:
			result = "none"
		Type.action_item:
			result = "action_item"
		Type.action:
			result = "action"
		Type.comment:
			result = "comment"
		Type.condition:
			result = "condition"
		Type.condition_item:
			result = "condition_item"
		Type.event_row:
			result = "event_row"
		Type.event:
			result = "event"
		Type.group:
			result = "group"
		_:
			printerr("Something went wrong in DragTargetType get_name_for. Passed valid val: " \
			+ str(val))
	return result
