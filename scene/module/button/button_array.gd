extends GridContainer
class_name ButtonArray


signal selection(index: int)


const OUTLINE = preload("res://scene/module/button/outline.tscn")
const OUTLINE_SMALL = preload("res://scene/module/button/outline_small.tscn")


@export var large_buttons: bool = true
@export var initial_outline_index: int = 0


var selected: int = 0
var set_selected: int = 0:
	set(value):
		select_item(value)
var enabled: bool = true:
	set(value):
		enabled = value
		for child: Node in get_children(): if child is ButtonCV: child.enable(value)


var outline: Control


func _ready():
	if large_buttons: outline = OUTLINE.instantiate()
	else: outline = OUTLINE_SMALL.instantiate()
	for child_idx: int in get_child_count():
		var child: Node = get_child(child_idx)
		if child is ButtonCV:
			if child_idx == initial_outline_index: child.add_child(outline)
			child.button_array_item_clicked.connect(SendOutput)
			child.set_meta("button_array_item", true)
			child.set_meta("selection_index", child_idx)
			child.set_meta("button_array_selected", false)
	call_deferred("select_item", selected)


func select_item(selection_index: int):
	selection_index = clampi(selection_index, 0, get_child_count())
	selected = selection_index
	for child_idx: int in get_child_count():
		get_child(child_idx).set_meta("button_array_selected", child_idx == selection_index)
		if child_idx == selection_index: reparent_outline(child_idx)


func reparent_outline(index: int) -> void :
	outline.reparent(get_child(index), false)
	outline.anchors_preset = PRESET_FULL_RECT


func SendOutput(index: int):
	select_item(index)
	selection.emit(index)
