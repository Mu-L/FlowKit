@tool
extends EditorPlugin

var action_registry: FKRegistry = FKRegistry.new()
var generator: FKGenerator = null
var inspector_plugin
var export_plugin
var editor_main_screen
var editor: FKMainEditor = null
var editor_globals: FKEditorGlobals = FKEditorGlobals.new()
var editor_interface: EditorInterface

func _enable_plugin() -> void:
	# Add autoloads here if needed later.
	pass

func _disable_plugin() -> void:
	# Remove autoloads here if needed later.
	pass

func _enter_tree() -> void:
	_prep_editor_globals()
	_prep_main_editor()
	_add_runtime_autoloads()
	_register_as_main_screen_plugin()
	
	# Hide by default until user clicks the FlowKit button
	_make_visible(false)
	
	_create_and_add_custom_inspector()
	_prep_export_plugin()

	print("[FlowKit]: Plugin loaded")

func _prep_editor_globals():
	action_registry = FKRegistry.new()
	action_registry.load_providers()
	
	editor_interface = get_editor_interface()
	generator = FKGenerator.new(editor_interface)

	editor_globals = FKEditorGlobals.new()
	editor_globals.registry = action_registry
	editor_globals.editor_interface = editor_interface
	editor_globals.generator = generator

func _prep_main_editor():
	const path := FKEditorGlobals.MAIN_EDITOR_SCENE_PATH
	var editor_scene: PackedScene = preload(path)
	editor = editor_scene.instantiate()
	editor.editor_globals = editor_globals
	# ^Very important that we assign this _before_ legitimization. Why? At least
	# 1 of FKMainEditor's submodules will need an FKEditorGlobals object
	# immediately ready to go
	editor.legitimize()
	
func _add_runtime_autoloads():
	add_autoload_singleton(
		"FlowKitSystem",
		"res://addons/flowkit/runtime/flowkit_system.gd"
	)
	
	add_autoload_singleton(
		"FlowKit",
		"res://addons/flowkit/runtime/flowkit_engine.gd"
	)

func _register_as_main_screen_plugin():
	editor_main_screen = editor_interface.get_editor_main_screen()
	editor_main_screen.add_child(editor)
	
func _create_and_add_custom_inspector():
	# Create and add custom inspector
	inspector_plugin = FKEditorInspectorPlugin.new()
	inspector_plugin.set_registry(action_registry)
	inspector_plugin.set_editor_interface(editor_interface)
	add_inspector_plugin(inspector_plugin)

func _prep_export_plugin():
	# We want to make sure it excludes unused providers from builds
	export_plugin = FKExportPlugin.new()
	export_plugin.set_generator(generator)
	add_export_plugin(export_plugin)
	
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
