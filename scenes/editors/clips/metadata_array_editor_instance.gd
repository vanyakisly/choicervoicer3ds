@tool
class_name MetadataArrayEditorInstance extends VBoxContainer


const CELL = preload("res://scenes/editors/clips/metadata_array_editor_cell.tscn")


enum TYPE{TEXT, NUMBER}


@onready var lbl_title: Label = %LblTitle
@onready var list_of_items: VBoxContainer = %ListOfItems
@onready var lbl_add: Label = %LblAdd


@export var type: TYPE
@export var title: String: set = _set_title




func new_cell() -> MetadataArrayEditorCell:
	var cell: MetadataArrayEditorCell = CELL.instantiate()
	var placeholder: String
	match type:
		TYPE.TEXT: placeholder = "%s name"
		TYPE.NUMBER: placeholder = "%s number"
	cell.set_line_edit(placeholder % title)
	list_of_items.add_child(cell)
	cell.line_edit.grab_focus()
	return cell
func new_blank_cell() -> void : new_cell()
func get_array() -> Array:
	var data: Array = []
	for cell: MetadataArrayEditorCell in list_of_items.get_children():
		var cell_contents: String = cell.get_text()
		match type:
			TYPE.TEXT: if !cell_contents.is_empty(): data.append(cell_contents)
			TYPE.NUMBER: data.append(type_convert(cell_contents, TYPE_FLOAT))
	return data
func load_clip_data(data: Array) -> void :
	for element: MetadataArrayEditorCell in list_of_items.get_children(): element.queue_free()
	for element: Variant in data:
		var cell: MetadataArrayEditorCell = new_cell()
		if typeof(element) == TYPE_FLOAT: element = snappedf(element, 0.001)
		cell.set_text(type_convert(element, TYPE_STRING))


func _ready() -> void :
	_set_title(title)




func _set_title(value: String) -> void :
	title = value
	if lbl_title: lbl_title.text = "%ss" % title
	if lbl_add: lbl_add.text = "+ Add %s" % title
