class_name PackData extends Resource

const PRINTSTR: String = "PackData | "

const SECTION_DATA: String = "data"

const KEY_TITLE: String = "title"
const KEY_SUBTITLE: String = "subtitle"
const KEY_INFO: String = "info"
const KEY_AUTHORS: String = "authors"
const KEY_TAGS: String = "tags"
const KEY_ICON: String = "icon"



@export var self_global_path: String: set = _set_self_global_path
var global_containing_folder: String
var folder_name: String


@export var title: String
@export var subtitle: String
@export var authors: PackedStringArray
@export var tags: PackedStringArray
@export var icon: Texture2D
@export_multiline var info: String


func _init(in_global_folder_path: String = "") -> void :
	printerr(PRINTSTR + "Using deprecated class.")
	if !in_global_folder_path: print(PRINTSTR + "No path input, assuming premade.");return
	_import_from_global_path(in_global_folder_path)


func _import_from_global_path(in_global_folder_path: String) -> void :
	if !DirAccess.dir_exists_absolute(in_global_folder_path): printerr(PRINTSTR + "Target folder path `%s` does not exist" % in_global_folder_path);return
	self_global_path = in_global_folder_path
	var icon_path: String
	title = folder_name.left(-1)
	if FileAccess.file_exists(self_global_path + "_pack_info.ini"):
		var metadata: = CondomFile.new()
		metadata.load(self_global_path + "_pack_info.ini")
		var metadata_title: String = metadata.get_section_key_as_string(SECTION_DATA, KEY_TITLE); if metadata_title: title = metadata_title
		subtitle = metadata.get_section_key_as_string(SECTION_DATA, KEY_SUBTITLE)
		authors = metadata.get_section_key_as_packed_string_array(SECTION_DATA, KEY_AUTHORS)
		tags = metadata.get_section_key_as_packed_string_array(SECTION_DATA, KEY_TAGS)
		icon_path = metadata.get_section_key_as_string(SECTION_DATA, KEY_ICON)
		info = metadata.get_section_key_as_string(SECTION_DATA, KEY_INFO)

	if icon_path:

		if icon_path.get_extension(): icon = VD.get_texture(icon_path)
		else: icon = VD.get_any_texture_from(DirAccess.get_files_at(self_global_path), icon_path)
	if !icon:
		var files_list: PackedStringArray = DirAccess.get_files_at(self_global_path)
		icon = VD.get_any_texture_from(files_list, "_icon")
		if !icon: icon = VD.get_any_texture_from(files_list, "_pack_filler_image")

	var potential_subtitle: String = VD.get_text(self_global_path + "_subtitle.txt"); if potential_subtitle: subtitle = potential_subtitle
	var potential_authors: String = VD.get_text(self_global_path + "_authors.txt"); if potential_authors: authors = [potential_authors]



func _set_self_global_path(value: String) -> void :
	if !value.ends_with("/"): value += "/"
	self_global_path = value
	global_containing_folder = self_global_path.left(-1).get_base_dir()
	folder_name = self_global_path.left(-1).get_basename() + "/"
