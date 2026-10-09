class_name VoiceClipTogglePreviewer extends Control



const VOICE_CLIP_TOGGLE_PREVIEWER_INSTANCE = preload("res://scenes/ui_modules/voice_clip_view_and_toggle/voice_clip_toggle_previewer_instance.tscn")



var list: VBoxContainer


var pack: PackInfo: set = _set_pack
var list_load_cap: int = 0
var coroutine_password: int = 0
var non_loaded_files: PackedStringArray = []




func _generate_until_cap() -> void :
	if non_loaded_files.is_empty(): return
	var next_set_of_files: PackedStringArray = non_loaded_files.slice(0, 100)
	non_loaded_files = non_loaded_files.slice(100)
	var coroutine_key: int = coroutine_password
	for file: String in next_set_of_files:
		if coroutine_key != coroutine_password: return
		var clip: = OmniClip.new()
		clip.generate_from_audio_file_exact(file)
		var instance: VoiceClipTogglePreviewerInstance = VOICE_CLIP_TOGGLE_PREVIEWER_INSTANCE.instantiate()
		list.add_child(instance)
		instance.clip = clip
		await get_tree().process_frame
	if !non_loaded_files.is_empty():
		var btn: = Button.new()
		btn.text = "Load more audio clips"
		btn.pressed.connect( func() -> void : _generate_until_cap();btn.queue_free())
		list.add_child(btn)


func _set_pack(value: PackInfo) -> void :
	pack = value
	list_load_cap = 0
	non_loaded_files = pack.audio_files.duplicate()
	non_loaded_files.append_array(pack.audio_files_ignored)
	non_loaded_files.sort()
	coroutine_password = Time.get_ticks_msec()
	for child: Node in list.get_children(): child.queue_free()
	_generate_until_cap()


func _init() -> void :
	var scroll_con: = ScrollContainer.new();add_child(scroll_con);scroll_con.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	list = VBoxContainer.new()
	scroll_con.add_child(list)
