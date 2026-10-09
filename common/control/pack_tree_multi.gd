class_name TreePackToggle extends Tree



signal pack_selected(pack: Pack)
signal loading_finished


@export var personalizer_type: M.PERSONALIZER
@export var load_when_visible: bool = false


var root: TreeItem
var section_native: TreeItem
var section_custom: TreeItem


var selected_cell_pack: Pack:
	get:
		var selected_cell: TreeItem = get_selected()
		if selected_cell is PackTreeMultiItem: return selected_cell.pack
		else: return null


var has_been_visible: bool = false




func _setup_defaults_override() -> void :
	hide_root = true
	auto_tooltip = false
	add_theme_constant_override("v_separation", -2)
	columns = 2
	set_column_expand(0, false)
func _setup_roots() -> void :
	root = create_item()
	section_native = root.create_child();section_native.set_text(1, "Base Game Packs")
	section_custom = root.create_child();section_custom.set_text(1, "Custom Packs")
	for section: TreeItem in [section_native, section_custom]: section.set_expand_right(0, false);section.set_selectable(0, false);section.set_selectable(1, false)
func _setup_signals() -> void :
	cell_selected.connect(_emit_selected_pack)
	item_edited.connect(_toggle_pack_by_checkmark)
	if load_when_visible: visibility_changed.connect(_check_for_visibility_generation)
func _setup() -> void :
	_setup_defaults_override()
	_setup_roots()
	_setup_signals()


func clear_current_contents() -> void :
	for section: TreeItem in [section_native, section_custom]:
		for child: TreeItem in section.get_children(): child.free()
func generate_new_list() -> void :
	clear_current_contents()

	match personalizer_type:
		M.PERSONALIZER.CHATTER:

			for native_name: String in NativePackService.NATIVE_CHATTER_PACKS:
				var new_pack: PackChatter = NativePackService.get_native_chatter_pack(native_name)

				var cell: TreeItem = section_native.create_child()
				cell.set_script(PackTreeMultiItem)
				if cell is PackTreeMultiItem: cell.pack = new_pack
				else: cell.free()

			for chatter_pack_name: String in DirAccess.get_directories_at(FileManager.MODPACKS_CHATTER):
				var new_pack: = PackChatter.new()

				var error: Error = new_pack.generate_from_global_directory(FileManager.MODPACKS_CHATTER + chatter_pack_name)
				if error: continue
				var cell: TreeItem = section_custom.create_child()
				cell.set_script(PackTreeMultiItem)
				if cell is PackTreeMultiItem: cell.pack = new_pack
				else: cell.free()



func _emit_selected_pack() -> void :
	if get_selected_column() != 1: return
	pack_selected.emit(selected_cell_pack)
func _toggle_pack_by_checkmark() -> void :
	await get_tree().process_frame
	var selected_cell: TreeItem = get_selected()
	if selected_cell is PackTreeMultiItem: selected_cell.pack.toggle_pack_ignored(selected_cell.is_checked(0))
func _check_for_visibility_generation() -> void :
	if has_been_visible: return
	if !is_visible_in_tree(): return
	has_been_visible = true
	generate_new_list()


func _ready() -> void :
	_setup()
	if load_when_visible and !visible: return
	generate_new_list()
