extends Node


const IGNORE_KEYWORD: String = "_ignore_"


var IGNORE_KEYWORD_LENGTH: int = IGNORE_KEYWORD.length()


func convert_ignored_keyword_to_profile_variables(path: String = "") -> void :
	for file: String in DirAccess.get_files_at(FileManager.MODPACKS_VOICE + path):
		if !VD.SCANNED_AUDIO_EXTENSIONS.has(file.get_extension()): continue
		if !file.begins_with(IGNORE_KEYWORD): continue
		var renamed_file: String = file.right( - IGNORE_KEYWORD_LENGTH)
		DirAccess.rename_absolute(FileManager.MODPACKS_VOICE + path + file, FileManager.MODPACKS_VOICE + path + renamed_file)
		Profile.ignored_clips.append(path + renamed_file.get_basename())
	for folder: String in DirAccess.get_directories_at(FileManager.MODPACKS_VOICE + path):
		folder += "/"
		var renamed_folder: String = folder
		if folder.begins_with(IGNORE_KEYWORD):
			renamed_folder = folder.right( - IGNORE_KEYWORD_LENGTH)
			DirAccess.rename_absolute(FileManager.MODPACKS_VOICE + path + folder, FileManager.MODPACKS_VOICE + path + renamed_folder)
			if !Profile.ignored_packs_voice.has(path + renamed_folder): Profile.ignored_packs_voice.append(path + renamed_folder)
		convert_ignored_keyword_to_profile_variables(path + renamed_folder)
