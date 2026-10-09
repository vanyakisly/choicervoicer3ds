extends Node


const MAIN: String = "user://game/"
const GAME: String = MAIN

const MODPACKS_HOST: String = MAIN + "packs_host/"
const MODPACKS_JUDGES: String = MAIN + "packs_judges/"
const MODPACKS_MENU: String = MAIN + "packs_menu/"
const MODPACKS_PLAYER: String = MAIN + "packs_player/"
const MODPACKS_CONTESTANT: String = MODPACKS_PLAYER
const MODPACKS_STUDIO: String = MAIN + "packs_studio/"
const MODPACKS_VOICE: String = MAIN + "packs_voice/"

const MODPACKS_CHATTER: String = MAIN + "packs_chatter/"
const MODPACKS_SANCTUARY: String = MAIN + "packs_sanctuary/"

const MODFILES_CRUST: String = MAIN + "files_crust/"

const RECORDINGS: String = MAIN + "recordings/"
const RECORDINGS_DUBS: String = RECORDINGS + "dub_recordings/"
const SAVES: String = MAIN + "saves/"


const TEMP: String = MAIN + ".temp/"
const TEMP_EDITOR: String = TEMP + "editor/"
const TEMP_DUBMODE: String = TEMP + "dub_mode/"


const ILLEGAL_WINDOWS_FOLDER_NAMES: PackedStringArray = [
	"con", "prn", "aux", "nul", "com1", "com2", "com3", "com4", "com5", "com6", "com7", "com8", "com9", 
	"lpt1", "lpt2", "lpt3", "lpt4", "lpt5", "lpt6", "lpt7", "lpt8", "lpt9"
]


func _generate_game_folders() -> void :
	for directory: String in [
			MAIN, 
			MODPACKS_HOST, MODPACKS_JUDGES, MODPACKS_MENU, 
				MODPACKS_PLAYER, MODPACKS_STUDIO, MODPACKS_VOICE, 
				MODPACKS_CHATTER, 

			RECORDINGS, SAVES, 
			TEMP, 
			]:
		if !DirAccess.dir_exists_absolute(directory): DirAccess.make_dir_recursive_absolute(directory)


func get_directory_files_with_extension(directory: String, extension: String) -> PackedStringArray:
	var dir: = DirAccess.open(directory)
	var output: PackedStringArray = []
	if dir:
		dir.list_dir_begin(); var file_name: String = dir.get_next()
		while file_name:
			if dir.current_is_dir(): file_name = dir.get_next();continue
			if extension == file_name.get_extension().to_lower(): output.append(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	return output


func get_directory_files_with_extensions(directory: String, extensions: PackedStringArray) -> PackedStringArray:
	var dir: = DirAccess.open(directory)
	var output: PackedStringArray = []
	if dir:
		dir.list_dir_begin(); var file_name: String = dir.get_next()
		while file_name:
			if dir.current_is_dir(): file_name = dir.get_next();continue
			if extensions.has(file_name.get_extension().to_lower()): output.append(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	return output


func x_get_directory_files_with_extensions(directory: String, extensions: PackedStringArray) -> PackedStringArray:
	var list: PackedStringArray = DirAccess.get_files_at(directory)
	var output: PackedStringArray = []
	for file: String in list: if extensions.has(file.get_extension().to_lower()): output.append(file)
	return output


func _ready() -> void : _generate_game_folders()
