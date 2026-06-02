extends RefCounted
class_name FKUnitUiSignals

signal before_contents_changed(unit_ui: FKUnitUi)
signal contents_changed(unit_ui: FKUnitUi)
signal entered_sheet_ui(unit_ui: FKUnitUi)
signal exiting_sheet_ui(unit_ui: FKUnitUi)
signal moved_in_sheet_ui(unit_ui: FKUnitUi)

signal selected(unit_ui: FKUnitUi)
signal edit_requested(unit_ui: FKUnitUi)
signal delete_requested(unit_ui: FKUnitUi)
signal reorder_requested(source_item: Control, target_item: Control, drop_above: bool)
