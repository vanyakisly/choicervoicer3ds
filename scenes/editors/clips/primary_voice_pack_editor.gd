extends Control



const TREE_ITEM_TEXT_COLUMN: int = 0
const CLIP_METADATA_EDITOR = preload("res://scenes/editors/clips/clip_metadata_editor.tscn")


@onready var tree: VoicePackTree = %Tree
@onready var clips_tree: Tree = %ClipsTree
@onready var pack_metadata_editor: MetadataEditorPack = %PackMetadataEditor
@onready var clip_metadata_holder: MarginContainer = %ClipMetadataHolder
@onready var btn_swap_editor: ButtonCV = %BtnSwapEditor
@onready var section_pack_data: MarginContainer = %SECTION_PackData
@onready var section_clip_data: MarginContainer = %SECTION_ClipData
@onready var lbl_change_editor: Label = %LblChangeEditor


var tree_clips_root: TreeItem


var main_active: bool = false
var clip_selection_active: bool:
	set(value):
		clip_selection_active = value
		lbl_change_editor.text = "Swap to pack editor" if clip_selection_active else "Swap to clips editor"




func _update_selected_pack(input: PackInfo) -> void :
	printerr("TODO: UPDATE VOICEPACKTREE WHEN NAME/ICON IS ALTERED")





func _pack_selected_to_pack_editor(pack: PackInfo) -> void :
	for child: Node in clip_metadata_holder.get_children(): child.queue_free()
	if !main_active:
		main_active = true
		btn_swap_editor.show()
		section_clip_data.show()
	pack_metadata_editor.pack = pack
	pack_metadata_editor.show()

	for child: TreeItem in tree_clips_root.get_children(): child.free()
	var all_files: PackedStringArray = pack.audio_files.duplicate()
	all_files.append_array(pack.audio_files_ignored)
	all_files.sort()
	for clip_name: String in all_files:
		clip_name.trim_prefix(pack.path_to_files)
		var new_cell: TreeItem = tree_clips_root.create_child()
		new_cell.set_text(TREE_ITEM_TEXT_COLUMN, clip_name.trim_prefix(pack.path_to_files))
		new_cell.set_metadata(TREE_ITEM_TEXT_COLUMN, clip_name)
func _previous_clip_in_tree() -> void :
	var cell: TreeItem = clips_tree.get_selected()
	if !cell: return
	var cell_prev: TreeItem = cell.get_prev_visible(true)
	if cell_prev:
		clips_tree.set_selected(cell_prev, 0)
		_clicked_cell_to_clip_editor()
func _next_clip_in_tree() -> void :
	var cell: TreeItem = clips_tree.get_selected()
	if !cell: return
	var cell_next: TreeItem = cell.get_next_visible(true)
	if cell_next:
		clips_tree.set_selected(cell_next, 0)
		_clicked_cell_to_clip_editor()
func _open_in_browser() -> void : tree.active_pack.open_in_browser()
func _clicked_cell_to_clip_editor() -> void :
	clips_tree.queue_redraw()
	var active_cell: TreeItem = clips_tree.get_selected()
	for child: Node in clip_metadata_holder.get_children(): child.queue_free()
	var new: MetadataEditorClip = CLIP_METADATA_EDITOR.instantiate()
	new.custom_minimum_size.x = 390
	var active_pack: PackInfo = tree.active_pack
	clip_metadata_holder.add_child(new)

	var cell_contents: Variant = active_cell.get_metadata(TREE_ITEM_TEXT_COLUMN)
	if cell_contents == null: return
	new.load_stn_from_global_path.call_deferred(cell_contents)


func _swap_visible_editor() -> void :
	if section_pack_data.visible or section_clip_data.visible:
		section_pack_data.visible = section_clip_data.visible
		section_clip_data.visible = !section_clip_data.visible
		clip_selection_active = section_clip_data.visible
func _leave() -> void : M.world.CreateMenu()


func _ready() -> void :
	tree_clips_root = clips_tree.create_item()
	clips_tree.scroll_horizontal_enabled = true
	pack_metadata_editor.hide();btn_swap_editor.hide();section_pack_data.hide();section_clip_data.hide()
	clip_selection_active = true
