extends Resource
class_name FKCondition

func get_description() -> String:
    return ""

func get_id() -> String:
    return ""

func get_name() -> String:
    return ""

func get_inputs() -> Array[Dictionary]:
    return []

func get_supported_types() -> Array[String]:
    return []

func get_category() -> String:
    return "General"

func check(node: Node, inputs: Dictionary) -> bool:
    return false
