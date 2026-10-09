class_name ChatterPreviewer extends Control



const CHATTER_PREVIEWER_INSTANCE = preload("res://scenes/ui_modules/chatter_view/chatter_previewer_instance.tscn")


var list: VBoxContainer


var pack: PackChatter: set = _set_pack
var coroutine_password: int = 0




func _generate() -> void :
	var coroutine_key: int = coroutine_password
	for collection: Dictionary[ConresChatterInstance, PackedStringArray] in [pack.conres.broad_collection, pack.conres.exact_collection]:
		for chatter: ConresChatterInstance in collection.keys():
			if coroutine_key != coroutine_password: return
			var instance: ChatterPreviewerInstance = CHATTER_PREVIEWER_INSTANCE.instantiate()
			list.add_child(instance)
			instance.set_data(chatter, chatter.audio_file_name, collection[chatter])
			await get_tree().process_frame


func _set_pack(value: PackChatter) -> void :
	pack = value
	coroutine_password = Time.get_ticks_msec()
	for child: Node in list.get_children(): child.queue_free()
	_generate()


func _init() -> void :
	var scroll_con: = ScrollContainer.new();add_child(scroll_con);scroll_con.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	list = VBoxContainer.new()
	scroll_con.add_child(list)
