extends RefCounted
class_name FKEditorGlobals

const EVENT_ROW_SCENE_PATH := "res://addons/flowkit/editor/scenes/unitUis/event_row_ui.tscn"
const COMMENT_SCENE_PATH := "res://addons/flowkit/editor/scenes/unitUis/comment_ui.tscn"
const CONDITION_SCENE_PATH := "res://addons/flowkit/editor/scenes/unitUis/condition_unit_ui.tscn"
const ACTION_ITEM_SCENE_PATH := "res://addons/flowkit/editor/scenes/unitUis/action_unit_ui.tscn"
const BRANCH_ITEM_SCENE_PATH := "res://addons/flowkit/editor/scenes/unitUis/branch_unit_ui.tscn"
const GROUP_SCENE_PATH := "res://addons/flowkit/editor/scenes/unitUis/group_ui.tscn"
const PATH_TO_EVENTS_FOLDER := "res://addons/flowkit/events"

const MAIN_EDITOR_SCENE_PATH := "res://addons/flowkit/editor/scenes/main_editor.tscn"

const EVENT_ROW_SCENE := preload(EVENT_ROW_SCENE_PATH)
const COMMENT_SCENE := preload(COMMENT_SCENE_PATH)
const CONDITION_ITEM_SCENE := preload(CONDITION_SCENE_PATH)
const ACTION_ITEM_SCENE := preload(ACTION_ITEM_SCENE_PATH)
const BRANCH_ITEM_SCENE := preload(BRANCH_ITEM_SCENE_PATH)

var editor_interface: EditorInterface
var generator: FKGenerator
var registry: FKRegistry 
var modal_signals: FKModalSignals = FKModalSignals.new()
