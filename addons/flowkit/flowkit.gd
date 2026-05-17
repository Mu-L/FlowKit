@tool
extends EditorPlugin

var action_registry
var editor: FKMainEditor
var generator
var inspector_plugin
var export_plugin
var editor_main_screen

func _enable_plugin() -> void:
	# Add autoloads here if needed later.
	pass

func _disable_plugin() -> void:
	# Remove autoloads here if needed later.
	pass

func _enter_tree() -> void:
	# Load UI
	var editor_scene: PackedScene = preload("res://addons/flowkit/ui/main_editor.tscn")
	editor = editor_scene.instantiate()
	editor.legitimize()
	
	# Load registry
	action_registry = FKRegistry.new() # preload("res://addons/flowkit/registry.gd").new()
	action_registry.load_providers()
	
	# Initialize generator
	var ed_interface := get_editor_interface()
	generator = FKGenerator.new(ed_interface)

	# Pass editor interface and registry to the editor UI
	editor.set_editor_interface(ed_interface)
	editor.set_registry(action_registry)
	editor.set_generator(generator)

	# Add runtime autoloads
	add_autoload_singleton(
		"FlowKitSystem",
		"res://addons/flowkit/runtime/flowkit_system.gd"
	)
	
	add_autoload_singleton(
		"FlowKit",
		"res://addons/flowkit/runtime/flowkit_engine.gd"
	)

	# Add editor as main screen plugin
	editor_main_screen = ed_interface.get_editor_main_screen()
	editor_main_screen.add_child(editor)
	
	# Hide by default until user clicks the FlowKit button
	_make_visible(false)
	
	# Create and add custom inspector
	inspector_plugin = FKEditorInspectorPlugin.new()
	inspector_plugin.set_registry(action_registry)
	inspector_plugin.set_editor_interface(ed_interface)
	add_inspector_plugin(inspector_plugin)

	# Register export plugin to exclude unused providers from builds
	export_plugin = FKExportPlugin.new()
	export_plugin.set_generator(generator)
	add_export_plugin(export_plugin)

	print("[FlowKit]: Plugin loaded")

func _exit_tree() -> void:
	action_registry.free()

	remove_autoload_singleton("FlowKitSystem")
	remove_autoload_singleton("FlowKit")
	
	if editor:
		editor.queue_free()
	
	# Remove inspector plugin
	if inspector_plugin:
		remove_inspector_plugin(inspector_plugin)
		inspector_plugin = null

	# Remove export plugin
	if export_plugin:
		remove_export_plugin(export_plugin)
		export_plugin = null

func _has_main_screen() -> bool:
	return true

func _make_visible(visible: bool) -> void:
	if editor:
		editor.visible = visible

func _get_plugin_name() -> String:
	return "FlowKit"

func _get_plugin_icon() -> Texture2D:
	return preload("res://addons/flowkit/assets/icon.svg")
