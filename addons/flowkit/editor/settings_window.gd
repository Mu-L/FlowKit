@tool
extends Window
class_name FKSettingsWindow

@export var auto_save_toggle: CheckButton
## Saves the settings to a json file
@export var save_button: Button

func _legitimize():
	if not _is_editor_preview:
		return
	_is_editor_preview = false
	_enter_tree()
	
var _is_editor_preview := true

func _enter_tree() -> void:
	if _is_editor_preview:
		var log_message := "[FlowKit]: Viewing FKSettingsWindow in the Scene View."
		print(log_message)
		return
	
	_ensure_settings_registered()
	_update_toggle()
	_update_sheet_auto_saver.call_deferred()
	_toggle_subs(true)

func _ensure_settings_registered():
	if not editor_settings.has_setting(_auto_save_toggle_key):
		print("[FKSettingsWindow]: Initializing auto save setting.")
		editor_settings.set_setting(_auto_save_toggle_key, auto_save_toggle.button_pressed)
	
var _auto_save_toggle_key: String:
	get:
		return FKEditorGlobals.AUTO_SAVE_TOGGLE_KEY
		
func _update_toggle():
	var current: bool = _auto_save_toggle_setting
	auto_save_toggle.button_pressed = current

var _auto_save_toggle_setting: bool:
	get:
		return editor_settings.get_setting(_auto_save_toggle_key)
		
var editor_settings: EditorSettings:
	get:
		return editor_interface.get_editor_settings()
		
var editor_interface: EditorInterface:
	get:
		return globals.editor_interface
		
var globals: FKEditorGlobals

func _update_sheet_auto_saver():
	var current: bool = _auto_save_toggle_setting
	if globals and globals.sheet_auto_saver:
		print("[FKSettingsWindow]: Updated auto sheet saver enabled to: " + str(current))
		globals.sheet_auto_saver.enabled = current

func _toggle_subs(on: bool):
	if on && !_is_subbed:
		save_button.pressed.connect(_on_save_button_pressed)
		close_requested.connect(_on_close_requested)
		
	elif _is_subbed && !on:
		save_button.pressed.disconnect(_on_save_button_pressed)
		close_requested.disconnect(_on_close_requested)
		
	else:
		return
		
	_is_subbed = on

var _is_subbed := false

func _on_save_button_pressed() -> void:
	var should_auto_save := auto_save_toggle.button_pressed
	var name := FKEditorGlobals.AUTO_SAVE_TOGGLE_KEY
	editor_settings.set_setting(name, should_auto_save)
	_update_sheet_auto_saver()
	print("[FKSettingsWindow]: Settings saved!")

func _on_close_requested():
	hide()
	
func _exit_tree() -> void:
	if _is_editor_preview:
		var log_message := "[FlowKit]: FKSettingsWindow exiting the Scene View."
		print(log_message)
		return
	_toggle_subs(false)
