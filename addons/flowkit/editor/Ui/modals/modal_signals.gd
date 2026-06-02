extends RefCounted
class_name FKModalSignals

signal node_selected(node_path: String, node_class: String)
signal event_selected(node_path: String, event_id: String, event_inputs: Array)
signal action_selected(node_path: String, action_id: String, action_inputs: Array)
signal condition_selected(node_path: String, condition_id: String, condition_inputs: Array)
signal expressions_confirmed(node_path: String, action_id: String, expressions: Dictionary)
signal before_contents_changed(node: FKUnitUi)
