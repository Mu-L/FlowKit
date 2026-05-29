## The type of Node being dragged. We can't pass actual Node types directly like
## we can in C#, so this enum will have to do.
class_name DragTarget

enum Type
{
	NONE, 
	ACTION, ACTION_ITEM,
	COMMENT,
	CONDITION, CONDITION_ITEM,
	EVENT, EVENT_ROW,
	GROUP
}

static func get_name_for(val: int) -> String:
	var result := ""
	
	match val:
		Type.NONE:
			result = "none"
		Type.ACTION_ITEM:
			result = "action_item"
		Type.ACTION:
			result = "action"
		Type.COMMENT:
			result = "comment"
		Type.CONDITION:
			result = "condition"
		Type.CONDITION_ITEM:
			result = "condition_item"
		Type.EVENT_ROW:
			result = "event_row"
		Type.EVENT:
			result = "event"
		Type.GROUP:
			result = "group"
		_:
			printerr("Something went wrong in DragTargetType get_name_for. Passed valid val: " \
			+ str(val))
			
	return result
