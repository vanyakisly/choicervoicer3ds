extends MenuBase

const PACKS_BUTTONS_PAGES: int = 2
const PERSONALIZERS_WITH_ADD_NEW: Array[M.PERSONALIZER] = [M.PERSONALIZER.MENU, M.PERSONALIZER.CONTESTANT, M.PERSONALIZER.STUDIO, M.PERSONALIZER.JUDGES, M.PERSONALIZER.HOST]

@onready var tree: Tree = %Tree
@onready var tree_checkmarks: Tree = %TreeCheckmarks

@onready var unbounded_host_capsule: Control = %UnboundedHostCapsule
@onready var pack_listings = %PackListings
@onready var interface_capsule: Control = %InterfaceCapsule
@onready var add_new: HBoxContainer = %AddNew
@onready var pack_button_array = %PackButtonArray
@onready var btn_open_pack_browser: ButtonCV = %BtnOpenPackBrowser
@onready var btn_add_new_pack = %BtnAddNewPack
@onready var new_pack_name_text_edit: LineEdit = %NewPackNameTextEdit


@onready var voice_pack_tree: VoicePackTree = %VoicePackTree
@onready var tree_pack_toggle: TreePackToggle = %TreePackToggle


@onready var btn_menu: ButtonCV = %BtnMenu
@onready var btn_player: ButtonCV = %BtnPlayer
@onready var btn_studio: ButtonCV = %BtnStudio
@onready var btn_judges: ButtonCV = %BtnJudges
@onready var btn_host: ButtonCV = %BtnHost
@onready var btn_voices: ButtonCV = %BtnVoices
@onready var btn_chatter: ButtonCV = %BtnChatter
@onready var btn_packs_page: ButtonCV = %BtnPacksPage
var btns_page_1: Array[ButtonCV]
var btns_page_2: Array[ButtonCV]


var interface_host: PackedScene:
	get:
		if !interface_host: interface_host = load("res://scene/menu/customize/interface_custom_host.tscn")
		return interface_host
var interface_judges: PackedScene:
	get:
		if !interface_judges: interface_judges = load("res://scene/menu/customize/interface_custom_judges.tscn")
		return interface_judges
var interface_contestant: PackedScene:
	get:
		if !interface_contestant: interface_contestant = load("res://scene/menu/customize/interface_custom_player.tscn")
		return interface_contestant
var interface_menu: PackedScene:
	get:
		if !interface_menu: interface_menu = load("res://scene/menu/customize/interface_custom_menu.tscn")
		return interface_menu
var interface_studio: PackedScene:
	get:
		if !interface_studio: interface_studio = load("res://scene/menu/customize/interface_custom_studio.tscn")
		return interface_studio
var interface_voice: PackedScene:
	get:
		if !interface_voice: interface_voice = load("res://scenes/ui_modules/voice_clip_view_and_toggle/voice_clip_previewer_block_scene.tscn")
		return interface_voice
var interface_chatter: PackedScene:
	get:
		if !interface_chatter: interface_chatter = load("res://scenes/ui_modules/chatter_view/chatter_previewer_scene.tscn")
		return interface_chatter



var page: int = 0
var active_personalizer: M.PERSONALIZER: set = _set_active_personalizer
func _set_active_personalizer(value: M.PERSONALIZER) -> void :
	if active_personalizer == value: return
	active_personalizer = value
	clear_interface()
	add_new.hide();new_pack_name_text_edit.clear();btn_add_new_pack.enable(PERSONALIZERS_WITH_ADD_NEW.has(active_personalizer))
	for child: Node in interface_capsule.get_children(): child.queue_free()
	match active_personalizer:
		M.PERSONALIZER.VOICE: tree.hide();voice_pack_tree.show();tree_pack_toggle.hide()
		M.PERSONALIZER.CHATTER: tree.hide();voice_pack_tree.hide();tree_pack_toggle.show()
		_:
			voice_pack_tree.hide();tree.show();tree_pack_toggle.hide()
			setup_tree_from(active_personalizer)
	match active_personalizer:
		M.PERSONALIZER.MENU: interface_capsule.add_child(interface_menu.instantiate())
		M.PERSONALIZER.CONTESTANT: interface_capsule.add_child(interface_contestant.instantiate())
		M.PERSONALIZER.JUDGES: interface_capsule.add_child(interface_judges.instantiate())
		M.PERSONALIZER.STUDIO: interface_capsule.add_child(interface_studio.instantiate())
		M.PERSONALIZER.HOST: interface_capsule.add_child(interface_host.instantiate())
		M.PERSONALIZER.VOICE:
			var interface: VoiceClipPreviewerBlockScene = interface_voice.instantiate()
			interface_capsule.add_child(interface)
			voice_pack_tree.pack_selected.connect(interface.set_pack)
			var browser_button_enabled: bool = false
			btn_open_pack_browser.enable(voice_pack_tree.active_pack != null)
		M.PERSONALIZER.CHATTER:
			var interface: ChatterPreviewerScene = interface_chatter.instantiate()
			interface_capsule.add_child(interface)
			tree_pack_toggle.pack_selected.connect(interface.set_pack)
			_on_tree_pack_toggle_pack_selected(tree_pack_toggle.selected_cell_pack)


var uc: = UC.new()
var selected_oveep: M.OVEEP = M.OVEEP.NONE

func _ready():
	_setup_buttons_pages_arrays()
	tree_checkmarks.set_column_expand(0, false)
	add_child(uc)

	active_personalizer = M.PERSONALIZER.MENU
	page = -1;_change_packs_buttons_page()


func CheckForNewInterface(button_oveep: M.OVEEP):
	if selected_oveep == M.OVEEP.MENU:

		interface_capsule.get_child(0).LoadPack()
	if selected_oveep != button_oveep:
		print("MenuCustomize | Is new selection")
		ClearInterface()
		NewInterface(button_oveep)
		selected_oveep = button_oveep
	if selected_oveep == M.OVEEP.VOICE: PacksToTreeCheckmarks(selected_oveep)

	else: PacksToTree(selected_oveep)


func NewInterface(oveep: M.OVEEP):


	match oveep:
		M.OVEEP.HOST: interface_capsule.add_child(interface_host.instantiate())
		M.OVEEP.JUDGES: interface_capsule.add_child(interface_judges.instantiate())
		M.OVEEP.PLAYER: interface_capsule.add_child(interface_contestant.instantiate())
		M.OVEEP.MENU: interface_capsule.add_child(interface_menu.instantiate())
		M.OVEEP.STUDIO: interface_capsule.add_child(interface_studio.instantiate())
		M.OVEEP.VOICE:
			var interface: OveepCustomizeInterface = load("res://scene/menu/customize/interface_custom_voice.tscn").instantiate()
			interface_capsule.add_child(interface)
			interface.visible = false


func ClearInterface():
	for child: Node in interface_capsule.get_children(): child.free()
	for child: Node in unbounded_host_capsule.get_children(): child.queue_free()
func clear_interface() -> void : ClearInterface()


func _on_btn_player_button_clicked(): active_personalizer = M.PERSONALIZER.CONTESTANT
func _on_btn_menu_button_clicked(): active_personalizer = M.PERSONALIZER.MENU
func _on_btn_studio_button_clicked(): active_personalizer = M.PERSONALIZER.STUDIO
func _on_btn_judges_button_clicked(): active_personalizer = M.PERSONALIZER.JUDGES
func _on_btn_host_button_clicked(): active_personalizer = M.PERSONALIZER.HOST
func _on_btn_voices_button_clicked(): active_personalizer = M.PERSONALIZER.VOICE
func _on_btn_chatter_button_clicked(): active_personalizer = M.PERSONALIZER.CHATTER



func setup_tree_from(personalizer_input: M.PERSONALIZER) -> void :
	tree.clear()
	var tree_root: TreeItem = tree.create_item();tree.hide_root = true
	if PERSONALIZERS_WITH_ADD_NEW.has(personalizer_input): var cell_default: TreeItem = tree_root.create_child();cell_default.set_text(0, "Default")
	var folders_array: PackedStringArray
	var profile_active: String
	match personalizer_input:
		M.PERSONALIZER.MENU: folders_array = DirAccess.get_directories_at(FileManager.MODPACKS_MENU);profile_active = Profile.menu_slash;selected_oveep = M.OVEEP.MENU
		M.PERSONALIZER.STUDIO: folders_array = DirAccess.get_directories_at(FileManager.MODPACKS_STUDIO);profile_active = Profile.studio_slash;selected_oveep = M.OVEEP.STUDIO
		M.PERSONALIZER.CONTESTANT: folders_array = DirAccess.get_directories_at(FileManager.MODPACKS_CONTESTANT);profile_active = Profile.contestant_slash;selected_oveep = M.OVEEP.PLAYER
		M.PERSONALIZER.JUDGES: folders_array = DirAccess.get_directories_at(FileManager.MODPACKS_JUDGES);profile_active = Profile.judges_slash;selected_oveep = M.OVEEP.JUDGES
		M.PERSONALIZER.HOST: folders_array = DirAccess.get_directories_at(FileManager.MODPACKS_HOST);profile_active = Profile.host_slash;selected_oveep = M.OVEEP.HOST
		_: return
	if profile_active == "Default/": tree.set_selected(tree_root.get_child(0), 0)
	for folder: String in folders_array:
		if folder.to_lower() == "default": return
		var tree_cell: TreeItem = tree_root.create_child()
		tree_cell.set_text(0, folder)
		tree_cell.set_metadata(0, folder)
		if folder + "/" == profile_active: tree.set_selected(tree_cell, 0)


func PacksToTree(oveep: M.OVEEP) -> void :
	if tree_checkmarks.visible: tree_checkmarks.visible = false
	if !tree.visible: tree.visible = true
	tree.clear()
	var tree_root: TreeItem = tree.create_item()
	tree.hide_root = true

	var usr_pack: String = uc.user_oveep_pack_path(oveep)
	var usr_oveep: String = usr_pack.get_base_dir().get_base_dir() + "/"


	var default_tree_child = tree.create_item(tree_root)
	default_tree_child.set_tooltip_text(0, " ")
	var defaults_text: String = "Default"
	default_tree_child.set_text(0, defaults_text)
	if defaults_text == usr_pack.get_base_dir().get_file(): tree.set_selected(default_tree_child, 0)

	var dir = DirAccess.open(usr_oveep)
	if !dir: return
	dir.list_dir_begin()
	var iffyee_or_folder: String = dir.get_next()
	while iffyee_or_folder != "":
		if dir.current_is_dir():
			var tree_child: TreeItem = tree.create_item(tree_root)
			tree_child.set_tooltip_text(0, " ")
			tree_child.set_text(0, iffyee_or_folder)
			tree_child.set_metadata(0, iffyee_or_folder)
			if iffyee_or_folder == usr_pack.get_base_dir().get_file():
				tree.set_selected(tree_child, 0)
		iffyee_or_folder = dir.get_next()


func PacksToTreeCheckmarks(_oveep: M.OVEEP) -> void :
	if not tree_checkmarks.visible: tree_checkmarks.visible = true
	if tree.visible: tree.visible = false
	tree_checkmarks.clear()
	var tree_root = tree_checkmarks.create_item()
	tree_checkmarks.hide_root = true




	for pack_name in DirAccess.get_directories_at("user://game/packs_voice/"):
		var included: bool = true






		included = !Profile.ignored_packs_voice.has(pack_name + "/")
		var pack_line: TreeItem = tree_checkmarks.create_item(tree_root)

		pack_line.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
		pack_line.set_expand_right(0, false)
		pack_line.set_checked(0, included)
		pack_line.set_tooltip_text(0, " ")


		pack_line.set_text(1, pack_name)
		pack_line.set_expand_right(1, false)

	btn_open_pack_browser.enable(false)


func ShowBackground():
	pack_button_array.visible = not pack_button_array.visible
	pack_listings.visible = not pack_listings.visible
	btn_packs_page.visible = !btn_packs_page.visible


func _on_tree_cell_selected():
	await get_tree().process_frame
	var selected_cell_text: String = tree.get_selected().get_text(0)
	interface_capsule.get_child(0).LoadPack(selected_cell_text)
	if selected_oveep == M.OVEEP.MENU: M.AssignSfx()
	btn_open_pack_browser.enable(selected_cell_text != "Default")
	M.sfx_select.play()


func _on_tree_checkmarks_cell_selected():
	await get_tree().process_frame

	var selection_item: TreeItem = tree_checkmarks.get_selected()
	var column: int = tree_checkmarks.get_selected_column()
	var pack_visible: bool = selection_item.is_checked(0)
	var pack_name: String = selection_item.get_text(1)
	var oveep_name: String = ""

	oveep_name = "packs_voice/"
	var name_visible: String = "user://game/" + oveep_name + pack_name
	var name_ignored: String = "user://game/" + oveep_name + "_ignore_" + pack_name

	if column == 0:
		pack_visible = not pack_visible
		selection_item.set_checked(0, pack_visible)



		if pack_visible:
			DirAccess.rename_absolute(name_ignored, name_visible)
		else:
			DirAccess.rename_absolute(name_visible, name_ignored)
		M.sfx_decrease.play()
	elif column == 1:
		if pack_visible: interface_capsule.get_child(0).LoadPack(name_visible)
		else: interface_capsule.get_child(0).LoadPack(name_ignored)
		interface_capsule.get_child(0).visible = true
		M.sfx_select.play()
	if !btn_open_pack_browser.enabled: btn_open_pack_browser.enable(true)


func _on_btn_open_pack_browser_button_clicked() -> void :
	var directory: String
	match active_personalizer:
		M.PERSONALIZER.VOICE:
			var active_pack: PackInfo = voice_pack_tree.active_pack
			if !active_pack: return
			directory = active_pack.global_folder_path
		M.PERSONALIZER.CHATTER:
			var pack: Pack = tree_pack_toggle.selected_cell_pack
			directory = pack._get_condat().global_directory
		_:
			directory = uc.user_oveep_pack_path(selected_oveep)





	OS.shell_open(ProjectSettings.globalize_path(directory))


func _on_btn_add_new_pack_button_clicked():
	add_new.visible = true
	new_pack_name_text_edit.edit()


func _on_btn_new_cancel_button_clicked():
	add_new.visible = false
	new_pack_name_text_edit.clear()


func _on_btn_new_add_button_clicked(_filler: String = ""):
	get_tree().get_root().get_node("World").ActiveHint(true, "Please Wait")
	await get_tree().create_timer(0.06).timeout
	var np_integer: int = 0
	var np_name: String = new_pack_name_text_edit.text
	if !np_name: np_name = "New Pack"
	var target_oveep_path = uc.user_oveep_pack_path(selected_oveep).get_base_dir().get_base_dir()
	var existing_pack_names = DirAccess.get_directories_at(target_oveep_path)
	existing_pack_names.append_array(["Default"])
	var np_adjusted_name = np_name
	while existing_pack_names.has(np_adjusted_name):
		np_integer += 1
		np_adjusted_name = np_name + (" %0*d" % [2, np_integer])
	var new_packstr: String = target_oveep_path + "/" + np_adjusted_name + "/"
	var error: Error = DirAccess.make_dir_absolute(new_packstr)
	if not error:
		await uc.populate_from_defaults(uc.res_oveep_pack_path(selected_oveep), new_packstr)
		new_pack_name_text_edit.clear()
		add_new.visible = false
		CheckForNewInterface(selected_oveep)
		get_tree().get_root().get_node("World").ActiveHint(false)
		for item: TreeItem in tree.get_root().get_children(): if item.get_metadata(0) == np_adjusted_name: item.select(0)
	else:
		get_tree().get_root().get_node("World").ActiveHint(true, "Name Failure", true, false)
		get_tree().get_root().get_node("World").ActiveHint(false, "Name Failure", true, false)


func BackButtonPressed():




	if active_personalizer == M.PERSONALIZER.MENU: await interface_capsule.get_child(0).LoadPack()
	M.SaveData()





func _setup_buttons_pages_arrays() -> void :
	btns_page_1 = [btn_menu, btn_player, btn_studio, btn_judges, btn_host]
	btns_page_2 = [btn_voices, btn_chatter]
func _change_packs_buttons_page() -> void :
	page = wrapi(page + 1, 0, PACKS_BUTTONS_PAGES)
	match page:
		0:
			btn_packs_page.set_first_label_text("Page 1: Solo Packs")
			for btn: ButtonCV in btns_page_1: btn.show()
			for btn: ButtonCV in btns_page_2: btn.hide()
		1:
			btn_packs_page.set_first_label_text("Page 2: Multi Packs")
			for btn: ButtonCV in btns_page_1: btn.hide()
			for btn: ButtonCV in btns_page_2: btn.show()



func _on_tree_pack_toggle_pack_selected(pack: Pack) -> void :
	if !pack: btn_open_pack_browser.enable(false);return
	btn_open_pack_browser.enable( !pack.native_pack)


func _on_voice_pack_tree_pack_selected(pack: PackInfo) -> void :
	if !pack: btn_open_pack_browser.enable(false)
	else: btn_open_pack_browser.enable(true)
