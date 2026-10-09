class_name PackInfo extends Resource


const PRINTSTR: String = "PackData | "

const SECTION_DATA: String = "data"

const KEY_TITLE: String = "title"
const KEY_SUBTITLE: String = "subtitle"
const KEY_INFO: String = "info"
const KEY_AUTHORS: String = "authors"
const KEY_TAGS: String = "tags"
const KEY_ICON: String = "icon"
const KEY_README: String = "readme"
const KEY_PRESELECTED_VOICE_PACKS: String = "preselected_voice_packs"
const KEY_PRESELECTED_DUB_CHARACTERS: String = "preselected_dub_characters"

const RESERVED_AUDIO_STARTERS: PackedStringArray = [
	"_backing_track", "_ignore_", "_dubrecord_freestyle"
]




@export var pack_use: M.CLIP_USES



@export var ingame_asset: bool = false
@export var flag_config_loaded: bool = false



@export var global_folder_path: String
@export var folder_name: String
@export var path_from_pack: String
@export var path_to_files: String:
	get: return FileManager.MODPACKS_VOICE + path_from_pack
@export var audio_files_unnested: PackedStringArray
@export var audio_files_nested: PackedStringArray
@export var audio_files_ignored: PackedStringArray
@export var audio_files: PackedStringArray:
	get: var output: PackedStringArray = [];output.append_array(audio_files_unnested);output.append_array(audio_files_nested);return output
@export var is_ignored: bool:
	get: return Profile.ignored_packs_voice.has(path_from_pack)



@export var display_name: String
@export var subtitle: String
@export var tags: PackedStringArray
@export var authors: PackedStringArray
@export var icon: Texture2D
@export var found_audio_count: int
@export_multiline var readme: String
@export var icon_file_name: String
@export var has_dub_video_file: bool
@export var preselected_voice_tags: PackedStringArray
@export var preselected_dub_characters: PackedStringArray


@export var unique_all_voice_packs: bool

func _init(use: = M.CLIP_USES.VOICE) -> void : pack_use = use


func generate_from_target_pack_folder(global_target_pack_folder: String) -> void :
	if !global_target_pack_folder.ends_with("/"): global_target_pack_folder += "/"
	global_folder_path = global_target_pack_folder
	folder_name = global_folder_path.get_base_dir().get_file() + "/"
	path_from_pack = global_folder_path.trim_prefix(FileManager.MODPACKS_VOICE)
	if !path_from_pack.ends_with("/"): path_from_pack += "/"

	_top_level_iteration(global_target_pack_folder)
	found_audio_count = audio_files.size()


func attempt_config_load(global_file_path: String) -> bool:
	var config: CondomFile = VD.get_config(global_file_path)
	if config:
		flag_config_loaded = true
		if !display_name: display_name = config.get_section_key_as_string(SECTION_DATA, KEY_TITLE)
		if !subtitle: subtitle = config.get_section_key_as_string(SECTION_DATA, KEY_SUBTITLE)
		if !tags:
			if pack_use == M.CLIP_USES.VOICE: tags = config.get_section_key_as_packed_string_array(SECTION_DATA, KEY_TAGS)

		if !authors: authors = config.get_section_key_as_packed_string_array(SECTION_DATA, KEY_AUTHORS)

		var potential_icon: Texture2D
		var potential_icon_file_name = config.get_section_key_as_string(SECTION_DATA, KEY_ICON)
		if potential_icon_file_name.get_extension(): potential_icon = VD.get_texture(global_folder_path + potential_icon_file_name)
		else: potential_icon = VD.get_texture_agnostic(global_folder_path + potential_icon_file_name)
		if potential_icon: icon = potential_icon;icon_file_name = potential_icon_file_name

		if !readme: readme = config.get_section_key_as_string(SECTION_DATA, KEY_README)
		preselected_voice_tags = config.get_section_key_as_packed_string_array(SECTION_DATA, KEY_PRESELECTED_VOICE_PACKS)
		preselected_dub_characters = config.get_section_key_as_packed_string_array(SECTION_DATA, KEY_PRESELECTED_DUB_CHARACTERS)
		return true
	else: return false


func _top_level_iteration(global_folder: String) -> void :
	var found_config_files: PackedStringArray = []
	var dir: = DirAccess.open(global_folder)
	if dir:
		if !global_folder.ends_with("/"): global_folder += "/"
		dir.list_dir_begin()
		var element: String = dir.get_next()
		while element:
			if dir.current_is_dir() and (pack_use == M.CLIP_USES.VOICE):
				var audio_collections: Dictionary[String, PackedStringArray] = _nested_iteration_dx(global_folder + element)
				if Profile.ignored_packs_voice.has((global_folder + element + "/").trim_prefix(FileManager.MODPACKS_VOICE)):
					audio_files_ignored.append_array(audio_collections["enabled"])
				else: audio_files_nested.append_array(audio_collections["enabled"])
				audio_files_ignored.append_array(audio_collections["ignored"])

				element = dir.get_next();continue
			var file: String = element
			var file_agnostic: String = file.get_basename()
			var file_extension: String = file.get_extension()
			if (file_extension in VD.SCANNED_VIDEO_EXTENSIONS) and (file_agnostic == "dub_video"): has_dub_video_file = true
			if (file_extension in VD.SCANNED_AUDIO_EXTENSIONS) and ( !RESERVED_AUDIO_STARTERS.has(file_agnostic)):
				if Profile.ignored_clips.has(path_from_pack + element.get_basename()): audio_files_ignored.append(global_folder_path + element)
				else: audio_files_unnested.append(global_folder + element)
			else:
				match file_agnostic:
					"_subtitle": if !subtitle and file_extension in VD.SCANNED_TEXT_EXTENSIONS: subtitle = VD.get_text(global_folder + file)
					"_author": if !authors and file_extension in VD.SCANNED_TEXT_EXTENSIONS: authors = [VD.get_text(global_folder + file)]
					"_icon": if !icon and file_extension in VD.SCANNED_IMAGE_EXTENSIONS: icon = VD.get_texture(global_folder + file);icon_file_name = "_icon"
					"_readme": if !readme and file_extension in VD.SCANNED_TEXT_EXTENSIONS: readme = VD.get_text(global_folder + file)
					"_pack_info": if file_extension in VD.SCANNED_CONFIG_EXTENSIONS: found_config_files.append(file)
			element = dir.get_next()
		for possible_config_file: String in found_config_files: if attempt_config_load(global_folder + possible_config_file): break
	if !display_name: display_name = folder_name.left(-1)
	if !icon:
		icon = VD.get_texture_agnostic(global_folder_path + "_pack_filler_image")
		if icon: icon_file_name = "_pack_filler_image"
	_check_icon_height()



func _check_icon_height() -> void :
	if icon and icon.get_height() > icon.get_width():
		var img: Image = icon.get_image()
		img.resize_to_po2(true, Image.INTERPOLATE_BILINEAR)
		icon = ImageTexture.create_from_image(img)






















func _nested_iteration_dx(global_folder: String) -> Dictionary[String, PackedStringArray]:
	var output: Dictionary[String, PackedStringArray] = {
		"enabled": [], 
		"ignored": []}
	var dir: = DirAccess.open(global_folder)
	if dir:
		if !global_folder.ends_with("/"): global_folder += "/"
		var path_from_this_pack: String = global_folder.trim_prefix(FileManager.MODPACKS_VOICE)
		dir.list_dir_begin()
		var element: String = dir.get_next()
		while element:
			for starter: String in OmniClip.RESERVED_AUDIO_STARTERS: if element.begins_with(starter): element = dir.get_next();continue
			if Profile.ignored_clips.has(path_from_this_pack + element.get_basename()):
				output.ignored.append(global_folder + element)
				element = dir.get_next();continue
			if dir.current_is_dir():
				var audio_collections: Dictionary[String, PackedStringArray] = _nested_iteration_dx(global_folder + element)
				output.ignored.append_array(audio_collections["ignored"])
				if Profile.ignored_packs_voice.has(path_from_this_pack + element + "/"):
					output.ignored.append_array(audio_collections["enabled"])
				else: output.enabled.append_array(audio_collections["enabled"])
				element = dir.get_next();continue
			var file_extension: String = element.get_extension()
			if file_extension in VD.SCANNED_AUDIO_EXTENSIONS: output.enabled.append(global_folder + element)
			element = dir.get_next()
	return output


func save_config() -> void :
	var config: = ConfigFile.new()
	if display_name: config.set_value(SECTION_DATA, KEY_TITLE, display_name)
	if subtitle: config.set_value(SECTION_DATA, KEY_SUBTITLE, subtitle)
	if tags: config.set_value(SECTION_DATA, KEY_TAGS, Array(tags))
	if icon_file_name: config.set_value(SECTION_DATA, KEY_ICON, icon_file_name)
	if authors: config.set_value(SECTION_DATA, KEY_AUTHORS, Array(authors))
	if readme: config.set_value(SECTION_DATA, KEY_README, readme)
	if preselected_voice_tags: config.set_value(SECTION_DATA, KEY_PRESELECTED_VOICE_PACKS, Array(preselected_voice_tags))
	if preselected_dub_characters: config.set_value(SECTION_DATA, KEY_PRESELECTED_DUB_CHARACTERS, Array(preselected_dub_characters))
	VD.save_config(global_folder_path + "_pack_info.ini", config)


func reload_icon() -> void :
	if icon_file_name:
		if VD.SCANNED_AUDIO_EXTENSIONS_LOWER.has(icon_file_name.get_extension().to_lower()): icon = VD.get_texture(global_folder_path + icon_file_name)
		else: icon = VD.get_texture_agnostic(global_folder_path + icon_file_name)
	else:
		icon = VD.get_texture_agnostic(global_folder_path + "_icon")
		if !icon: icon = VD.get_texture_agnostic(global_folder_path + "_pack_filler_image")


func open_in_browser() -> void : OS.shell_open(ProjectSettings.globalize_path(global_folder_path))


func has_recordings_folder() -> bool: return DirAccess.dir_exists_absolute(FileManager.RECORDINGS_DUBS + path_from_pack)
func get_recordings_list() -> PackedStringArray: return DirAccess.get_directories_at(FileManager.RECORDINGS_DUBS + path_from_pack)
