extends FKEvent

func get_description() -> String:
	return "This event will run at the start of the scene."

func get_id() -> String:
	return "on_ready"

func get_name() -> String:
	return "On Ready"

func get_supported_types() -> Array[String]:
	return ["Node", "System"]

func get_inputs() -> Array:
	return []

# Track which block IDs have already fired for on_ready
var _fired_blocks: Dictionary = {}  # block_id -> true
var _last_scene_path: String = ""


func poll(node: Node, inputs: Dictionary = {}, block_id: String = "") -> bool:
	if not node:
		return false
	
	# Detect scene changes and reset tracking
	var current_scene = node.get_tree().current_scene
	if current_scene:
		var scene_path = current_scene.scene_file_path
		if scene_path != _last_scene_path:
			_last_scene_path = scene_path
			_fired_blocks.clear()
	
	# If this specific block has already fired, don't fire again
	if block_id and _fired_blocks.has(block_id):
		return false
	
	# Fire this block (first time we see it in this scene)
	if block_id:
		_fired_blocks[block_id] = true
	
	return true
