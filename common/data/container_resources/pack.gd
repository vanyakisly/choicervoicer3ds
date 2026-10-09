class_name Pack extends Resource




@export var native_pack: bool = false
var native_name: String
var folder_name: String: get = _get_folder_name
var display_name: String: get = _get_display_name
var authors: PackedStringArray: get = _get_authors
var readme: String: get = _get_readme
var unix_last_modified: int: get = _get_unix_last_modified
var icon: Texture2D: get = _get_icon


var failed_to_complete: bool



func generate_from_global_directory(directory: String) -> Error: return FAILED
func toggle_pack_ignored(show_pack: bool) -> void : return
func is_ignored() -> bool: return false

func _get_condat() -> Condat: return null
func _get_conres() -> Conres: return null

func _get_folder_name() -> String:
	if native_pack: return native_name
	var condat: Condat = _get_condat();return condat.folder_name if condat else ""
func _get_display_name() -> String: var condat: Condat = _get_condat();return condat.display_name if condat else ""
func _get_authors() -> PackedStringArray: var condat: Condat = _get_condat();return condat.authors if condat else []
func _get_readme() -> String: var condat: Condat = _get_condat();return condat.readme if condat else ""
func _get_unix_last_modified() -> int: var condat: Condat = _get_condat();return condat.unix_last_modified if condat else 0
func _get_global_path_agnostic() -> String: var condat: Condat = _get_condat();return condat.global_path_agnostic if condat else ""

func _get_icon() -> Texture2D: var conres: Conres = _get_conres();return conres.icon if conres else null
