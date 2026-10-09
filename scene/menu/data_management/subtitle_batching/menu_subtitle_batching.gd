extends MenuBase


@onready var tree: Tree = %Tree
@onready var title_box: ColorRect = %TitleBox
@onready var list: VBoxContainer = %List
@onready var editor: SubtitleBatchingEditor = %Editor
@onready var scroll_container: ScrollContainer = %ScrollContainer

var world: Node

var no_image_texture: CompressedTexture2D = preload("res://game_default/packs_menu/The Choicer Voicer's Default Menu/no_image.png")
var line_packed_scene: PackedScene = preload("res://scene/menu/data_management/subtitle_batching/subtitle_batching_clip_line_instance.tscn")
var fresh_editor_scene: PackedScene = preload("res://scene/menu/data_management/subtitle_batching/subtitle_batching_editor.tscn")

func _ready() -> void :
	title_box.get_child(0).text = ""
	var root = tree.create_item()

	_recursive_folder_addings(root)
	root.set_collapsed_recursive(true)
	root.collapsed = false

	world = get_tree().root.get_node("World")


func _recursive_folder_addings(cell: TreeItem, from: String = "user://game/packs_voice/") -> void :
	for folder_name: String in DirAccess.get_directories_at(from):
		var new_cell: = cell.create_child()
		new_cell.set_tooltip_text(0, " ")
		new_cell.set_text(0, folder_name)
		folder_name += "/"
		new_cell.set_metadata(0, from + folder_name)
		_recursive_folder_addings(new_cell, from + folder_name)


func _on_tree_item_selected() -> void :
	var this_upath: String = tree.get_selected().get_metadata(0)
	editor.detach()
	if list.get_meta("upath", "") != this_upath:
		M.sfx_select.play()
		world.ActiveHint(true, "Loading")
		scroll_container.scroll_vertical = 0
		list.set_meta("upath", this_upath)
		title_box.get_child(0).text = this_upath.get_base_dir().get_file()
		for child: Control in list.get_children():
			if list.get_meta("upath") != this_upath: return
			child.queue_free()
		for file: String in DirAccess.get_files_at(this_upath):
			if list.get_meta("upath") != this_upath: return
			var extension: String = file.get_extension().to_lower()
			if ["wav", "mp3", "ogg"].has(extension):
				var list_item: SubtitleBatchingClipLine = line_packed_scene.instantiate()
				list_item.assign(this_upath + file.get_basename())

				if list_item.clip_image == null: list_item.clip_image = no_image_texture.get_image()
				list_item.selected.connect( func(active_instance: SubtitleBatchingClipLine) -> void : editor.active_instance = active_instance)
				list.add_child(list_item)
				await get_tree().process_frame
		world.ActiveHint(false, "Loading")
