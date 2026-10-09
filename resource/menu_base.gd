extends Control
class_name MenuBase

@export var menu_data: MenuData


func call_slide(path: String, assume_path: bool = true):
	get_parent().get_parent().NewSlide(path, assume_path)
