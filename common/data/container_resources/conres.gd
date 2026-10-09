class_name Conres extends Resource




const FILE_NAME_ICON: String = "_icon"


@export var icon: Texture2D




func _load_common_from_path(global_directory: String) -> void :
	if !global_directory.ends_with("/"): global_directory += "/"
	var retrieved_texture: Texture2D = VD.get_texture_either(global_directory + FILE_NAME_ICON)
	if retrieved_texture: icon = retrieved_texture
func _load_common_from_condat(input: Condat) -> void :
	var retrieved_texture: Texture2D = VD.get_texture_either(input.global_directory + input.icon_file_name)
	if retrieved_texture: icon = retrieved_texture
