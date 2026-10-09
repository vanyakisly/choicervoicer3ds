class_name VoicePackTreeItem extends TreeItem

var pack_info: PackInfo: set = _set_pack_info
var use_case: VoicePackTree.USE_CASE


func visibility_reset() -> void :
	visible = true
	for child: VoicePackTreeItem in get_children(): child.visibility_reset()
func visibility_title(text: String) -> bool:
	var show: bool = pack_info.display_name.containsn(text)
	for child: VoicePackTreeItem in get_children(): var child_visiblility: bool = child.visibility_title(text);show = (show or child_visiblility)
	visible = show;return show
func visibility_subtitle(text: String) -> bool:
	var show: bool = pack_info.subtitle.containsn(text)
	for child: VoicePackTreeItem in get_children(): var child_visiblility: bool = child.visibility_subtitle(text);show = (show or child_visiblility)
	visible = show;return show
func visibility_readme(text: String) -> bool:
	var show: bool = pack_info.readme.containsn(text)
	for child: VoicePackTreeItem in get_children(): var child_visiblility: bool = child.visibility_readme(text);show = (show or child_visiblility)
	visible = show;return show
func visibility_author(text: String) -> bool:
	var show: bool = false
	for author: String in pack_info.authors: show = (show or author.containsn(text)); if show: break
	for child: VoicePackTreeItem in get_children(): var child_visiblility: bool = child.visibility_author(text);show = (show or child_visiblility)
	visible = show;return show



func generate_from_path(in_use_case: VoicePackTree.USE_CASE, path: String) -> void :
	use_case = in_use_case
	if path and !path.ends_with("/"): path += "/"
	var active_pack_info: PackInfo
	match use_case:
		VoicePackTree.USE_CASE.STANDARD, VoicePackTree.USE_CASE.TOGGLING:
			active_pack_info = PackInfo.new(M.CLIP_USES.VOICE)
		VoicePackTree.USE_CASE.DUB, VoicePackTree.USE_CASE.CINEMA:
			active_pack_info = PackInfo.new(M.CLIP_USES.DUB)
	active_pack_info.generate_from_target_pack_folder(FileManager.MODPACKS_VOICE + path)
	pack_info = active_pack_info
	populate_self(use_case, path)
	if use_case == VoicePackTree.USE_CASE.DUB or use_case == VoicePackTree.USE_CASE.CINEMA: is_preserve_branch()

func populate_self(in_use_case: VoicePackTree.USE_CASE, path: String = "") -> void :
	use_case = in_use_case
	if path and !path.ends_with("/"): path += "/"
	for folder: String in DirAccess.get_directories_at(FileManager.MODPACKS_VOICE + path):
		if use_case != VoicePackTree.USE_CASE.TOGGLING and Profile.ignored_packs_voice.has(path + folder + "/"): continue
		var active_pack_info: PackInfo
		match use_case:
			VoicePackTree.USE_CASE.STANDARD, VoicePackTree.USE_CASE.TOGGLING:
				active_pack_info = PackInfo.new(M.CLIP_USES.VOICE)
			VoicePackTree.USE_CASE.DUB, VoicePackTree.USE_CASE.CINEMA:
				active_pack_info = PackInfo.new(M.CLIP_USES.DUB)
		active_pack_info.generate_from_target_pack_folder(FileManager.MODPACKS_VOICE + path + folder)
		var child: TreeItem = create_child()
		child.set_script(VoicePackTreeItem)
		child.use_case = use_case
		child.pack_info = active_pack_info
		child.populate_self(use_case, path + folder)










func is_preserve_branch() -> bool:
	var self_or_child_is_valid: bool = pack_info.has_dub_video_file
	if use_case == VoicePackTree.USE_CASE.CINEMA and self_or_child_is_valid:
		self_or_child_is_valid = self_or_child_is_valid and pack_info.has_recordings_folder()
	for child: VoicePackTreeItem in get_children():
		var child_is_valid: bool = child.is_preserve_branch()
		if !child_is_valid: child.free()
		else: if !self_or_child_is_valid: self_or_child_is_valid = (self_or_child_is_valid or child_is_valid)
	return self_or_child_is_valid


func _set_pack_info(input_pack: PackInfo) -> void :
	pack_info = input_pack
	var cell_offset: int = 0
	if use_case == VoicePackTree.USE_CASE.TOGGLING:
		cell_offset += 1
		set_cell_mode(VoicePackTree.TREE_COLUMN, TreeItem.CELL_MODE_CHECK)
		set_expand_right(VoicePackTree.TREE_COLUMN, false)
		set_editable(VoicePackTree.TREE_COLUMN, true)
		set_checked(VoicePackTree.TREE_COLUMN, !Profile.ignored_packs_voice.has(pack_info.path_from_pack))

	set_icon_max_width(VoicePackTree.TREE_COLUMN + cell_offset, VoicePackTree.ICON_SIZE)
	set_icon(VoicePackTree.TREE_COLUMN + cell_offset, pack_info.icon)
	set_text(VoicePackTree.TREE_COLUMN + cell_offset, pack_info.display_name)
