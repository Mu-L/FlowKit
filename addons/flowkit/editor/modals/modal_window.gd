extends PopupPanel
class_name FKModalWindow

func _enter_tree() -> void:
	# For designer-friendliness, we want some things to proc
	# even in editor preview
	_ensure_export_fields_filled()
	_apply_styling()
	
	if is_editor_preview or is_fully_legit:
		return
	_toggle_subs(true)

var is_fully_legit: bool:
	get:
		return _is_fully_legit
var _is_fully_legit := false

func _ensure_export_fields_filled():
	pass 
	
func _apply_styling():
	pass
	
var is_editor_preview: bool:
	get:
		return _is_editor_preview
		
var _is_editor_preview := true

func _toggle_subs(on: bool):
	pass # We expect subclasses to override this
	
var _is_subbed := false

func set_editor_interface(interface: EditorInterface):
	_editor_interface = interface
	
var _editor_interface: EditorInterface

func legitimize():
	if not is_editor_preview:
		return
	_is_editor_preview = false # So the initialization process can begin
	_enter_tree()
	_ready()
	_is_fully_legit = true # And now we're done!
	
func _exit_tree() -> void:
	if !is_fully_legit:
		return
	_toggle_subs(false)

func set_registry(reg: FKRegistry):
	_registry = reg
	
var _registry: FKRegistry

func _ready() -> void:
	pass
