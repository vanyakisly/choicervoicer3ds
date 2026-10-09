class_name PackTreeMultiItem extends TreeItem



const COLUMN_CHECK: int = 0
const COLUMN_PACK: int = 1
const ICON_SIZE: int = 16


var pack: Pack: set = _set_pack



func visibility_reset() -> void :
	visible = true
	for child: PackTreeMultiItem in get_children(): child.visibility_reset()
func visibility_display_name(text: String) -> bool:
	var show: bool = pack.display_name.containsn(text)
	for child: PackTreeMultiItem in get_children(): var child_visiblility: bool = child.visibility_title(text);show = (show or child_visiblility)
	visible = show;return show
func visibility_readme(text: String) -> bool:
	var show: bool = pack.readme.containsn(text)
	for child: PackTreeMultiItem in get_children(): var child_visiblility: bool = child.visibility_readme(text);show = (show or child_visiblility)
	visible = show;return show
func visibility_author(text: String) -> bool:
	var show: bool = false
	for author: String in pack.authors: show = (show or author.containsn(text)); if show: break
	for child: PackTreeMultiItem in get_children(): var child_visiblility: bool = child.visibility_author(text);show = (show or child_visiblility)
	visible = show;return show
















func _set_pack(value: Pack) -> void :
	pack = value
	set_cell_mode(COLUMN_CHECK, TreeItem.CELL_MODE_CHECK)
	set_expand_right(COLUMN_CHECK, false)
	set_editable(COLUMN_CHECK, true)
	set_checked(COLUMN_CHECK, !pack.is_ignored())
	set_icon_max_width(COLUMN_PACK, ICON_SIZE)
	set_icon(COLUMN_PACK, pack.icon)
	set_text(COLUMN_PACK, pack.display_name)
