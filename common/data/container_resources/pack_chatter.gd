class_name PackChatter extends Pack



const CONFIG_FILE_NAME_AGNOSTIC: String = "config_chatter"


@export var condat: CondatChatter
@export var conres: ConresChatter




func generate_from_global_directory(directory: String) -> Error:
	if native_pack: return OK
	condat = CondatChatter.new()
	if !directory.ends_with("/"): directory += "/"
	var error: Error = condat.load_from_file_agnostic(directory + CONFIG_FILE_NAME_AGNOSTIC)
	if error != OK: return FAILED
	conres = ConresChatter.new()
	conres.load_from_condat(condat)
	return OK
func native_create_sounds_directories() -> void : conres.create_sounds_directory_from_collection()


func toggle_pack_ignored(show_pack: bool) -> void :
	if show_pack:
		while Profile.ignored_packs_chatter.has(folder_name):
			var index: int = Profile.ignored_packs_chatter.find(folder_name)
			if index == -1: break
			Profile.ignored_packs_chatter.remove_at(index)
	elif !Profile.ignored_packs_chatter.has(folder_name): Profile.ignored_packs_chatter.append(folder_name)
func is_ignored() -> bool: return Profile.ignored_packs_chatter.has(folder_name)


func _get_condat() -> Condat: return condat
func _get_conres() -> Conres: return conres
