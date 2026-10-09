class_name MetadataEditorPack extends Control


signal selected_pack_updated(output: PackInfo)


@onready var file_dialog: FileDialog = %FileDialog
@onready var lbl_pack_folder_name: Label = %LblPackFolderName
@onready var btn_save: ButtonCV = %BtnSave
@onready var pack_icon: TextureRect = %PackIcon
@onready var lbl_pack_icon_name: Label = %LblPackIconName
@onready var line_title_text: LineEdit = %LineTitleText
@onready var line_subtitle_text: LineEdit = %LineSubtitleText
@onready var section_authors: MetadataArrayEditorInstance = %SECTION_Authors
@onready var text_readme_text: TextEdit = %TextReadmeText
@onready var section_preselected_voice_tags: MetadataArrayEditorInstance = %SECTION_PreselectedVoiceTags
@onready var section_default_characters: MetadataArrayEditorInstance = %SECTION_DefaultCharacters


var pack: PackInfo: set = _set_pack




func _inject_path_to_pack(input: PackInfo, global_path: String) -> void :
	input.generate_from_target_pack_folder(global_path);pack = input


func save_current() -> void :
	btn_save.enable(false);btn_save.set_first_label_text("Saving...")
	if lbl_pack_icon_name.text: pack.icon_file_name = "Icon: %s" % lbl_pack_icon_name.text

	pack.icon_file_name = lbl_pack_icon_name.text
	pack.display_name = line_title_text.text
	pack.subtitle = line_subtitle_text.text
	pack.readme = text_readme_text.text
	pack.authors = PackedStringArray(section_authors.get_array())
	pack.preselected_voice_tags = PackedStringArray(section_preselected_voice_tags.get_array())
	pack.preselected_dub_characters = PackedStringArray(section_default_characters.get_array())
	pack.save_config()
	pack.reload_icon()
	selected_pack_updated.emit(pack)
	btn_save.set_first_label_text("Saved!"); await get_tree().create_timer(2.0).timeout
	btn_save.enable(true);btn_save.set_first_label_text("Save")


func _open_file_dialog() -> void : file_dialog.popup()
func _file_image_chosen(path: String) -> void :
	pack.icon_file_name = path.get_file()
	var chosen: Texture2D = VD.get_texture(pack.global_folder_path + path.get_file())
	pack_icon.texture = chosen
	lbl_pack_icon_name.text = path.get_file()




func _set_pack(value: PackInfo) -> void :
	pack = value
	if lbl_pack_folder_name: lbl_pack_folder_name.text = pack.folder_name.left(-1)
	if pack_icon: pack_icon.texture = pack.icon
	if lbl_pack_icon_name: lbl_pack_icon_name.text = pack.icon_file_name
	if line_title_text: line_title_text.text = pack.display_name
	if line_subtitle_text: line_subtitle_text.text = pack.subtitle
	if section_authors: section_authors.load_clip_data(pack.authors)
	if text_readme_text: text_readme_text.text = pack.readme
	if section_preselected_voice_tags: section_preselected_voice_tags.load_clip_data(pack.preselected_voice_tags)
	if section_default_characters: section_default_characters.load_clip_data(pack.preselected_dub_characters)
	file_dialog.root_subfolder = ProjectSettings.globalize_path(pack.global_folder_path)
