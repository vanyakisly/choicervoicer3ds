extends OveepCustomizeInterface

@onready var pack_info_page = %PackInfoPage
@onready var simple_window = %SimpleWindow
@onready var lbl_pack_name = %LblPackName
@onready var text_edit_pack_subtitle = %TextEditPackSubtitle
@onready var lines_holder = %LinesHolder


var editing: bool = false
var voice_pack_pacy: String = ""

func _ready():
	add_child(uc)
	VisibilitySetup()


func VisibilitySetup():
	simple_window.visible = true
	pack_info_page.visible = false


func LoadPack(pack_name: String = voice_pack_pacy):
	if not voice_pack_pacy == pack_name: voice_pack_pacy = pack_name
	if editing:
		lbl_pack_name.text = voice_pack_pacy.get_file()
		text_edit_pack_subtitle.text = uc.get_text(M.OVEEP.VOICE, pack_name.get_file() + "/_subtitle", false, false)
		load_clips()


func SetAsEditing():
	editing = true
	simple_window.visible = false
	pack_info_page.visible = true
	LoadPack()

func SaveConfig():

	uc.save_json_config(M.OVEEP.JUDGES, "config_judges", theseus_config)


func _on_btn_enable_editing_button_clicked():
	SetAsEditing()


func load_clips():
	M.ShowActivityHint(true, "Loading")
	for line in lines_holder.get_children():
		line.queue_free()
	var top_level_clip_list: PackedStringArray = recursive_clip_search(voice_pack_pacy.replace("user://game/packs_voice/", "") + "/")
	var frame_buffer: int = 0
	for clip in top_level_clip_list:
		frame_buffer += 1
		if frame_buffer % 6 == 0: await get_tree().process_frame
		var voice_instance_line: VoiceLinePreviewer = load("res://scene/menu/customize/voice_previewer_line.tscn").instantiate()
		lines_holder.add_child(voice_instance_line)
		voice_instance_line.play_pressed.connect(stop_all_playing)
		voice_instance_line.get_from_path(clip.get_basename())
	M.ShowActivityHint(false, "Loading")


func stop_all_playing():
	for line: VoiceLinePreviewer in lines_holder.get_children():
		if line.audio_stream_player.playing: line.audio_stream_player.stop()


const UPATHVOICE: String = "user://game/packs_voice/"
func recursive_clip_search(upath_poveep: String) -> PackedStringArray:
	var array: PackedStringArray = []
	for folder in DirAccess.get_directories_at(UPATHVOICE + upath_poveep):
		array.append_array(recursive_clip_search(upath_poveep + folder + "/"))
	for file_ext: String in DirAccess.get_files_at(UPATHVOICE + upath_poveep):
		if file_ext.get_extension() in ["wav", "mp3", "ogg"]:
			array.append(upath_poveep + file_ext)
	return array
