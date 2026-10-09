class_name ClipBookPackage extends Resource
var collection: OmniClipCollection
var full_collection: OmniClipCollection
var rounds: int
var selected_tags_names: PackedStringArray
var all_tags_names: PackedStringArray
func _init(set_collection: OmniClipCollection, set_rounds: int, set_full_collection: OmniClipCollection = null, tags_list: VBoxContainer = null) -> void :
	collection = set_collection
	rounds = set_rounds
	full_collection = set_full_collection
	if (tags_list): for el: Control in tags_list.get_children():
		all_tags_names.append(el.get_meta("tag", ""))
		if el is CheckBox: if el.button_pressed: selected_tags_names.append(el.get_meta("tag", ""))
