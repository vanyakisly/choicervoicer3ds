class_name MetadataArrayEditorCell extends HBoxContainer

@export var line_edit: LineEdit


func set_text(value: String) -> void : line_edit.text = value
func set_line_edit(value: String) -> void : line_edit.placeholder_text = value
func kill() -> void : self.queue_free()
func get_text() -> String: return line_edit.text.strip_edges()
