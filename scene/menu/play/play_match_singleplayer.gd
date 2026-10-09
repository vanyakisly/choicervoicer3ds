extends MenuBase

var uc: = UC.new()

@onready var click_blocker: Control = %ClickBlocker


@onready var tree = %Tree
@onready var btn_start = %BtnStart
@onready var voice_sidebar = %VoiceSidebar
@onready var players_sidebar = %PlayersSidebar
@onready var players = %Players
@onready var settings_sidebar = %SettingsSidebar
@onready var player_selection_list: VBoxContainer = %PlayerSelectionList
@onready var button_array = %ButtonArray
@onready var round_buttons = %RoundButtons


@onready var right_options = %RightOptions
@onready var subtitle = $MarginContainer / HBoxContainer / RightOptions / InfoBox / MarginContainer / VBoxContainer / Subtitle
@onready var lbl_rounds = %LblRounds
@onready var lbl_voice_count = %LblVoiceCount
@onready var lbl_author = %LblAuthor

@onready var lbl_title = $MarginContainer / HBoxContainer / RightOptions / TitleBox / Label
@onready var vclip_img_preview = %VclipImgPreview
@onready var vclip_images_scroll = %VclipImagesScroll
@onready var advisory_popup = %AdvisoryPopup
@onready var lbl_popup = %LblPopup
@onready var btn_continue = %BtnContinue


var abort_hash: int
var tree_collapse: bool = not M.data.settings.play_screen_visual_preferences.start_expanded
var font: Font = load("res://graphic/font/DuruSans-Regular.ttf")


var preview_data: int = clampi(M.data.settings.play_screen_visual_preferences.clip_preview_size, 0, 3)

var img_size: int = 32 * (1 + preview_data) if preview_data != 3 else 32 * (3 + preview_data)

var unseen_image: Texture2D = ProxyMiddlemanMenu.unseen_image

var no_image: Texture2D = ProxyMiddlemanMenu.no_image


const USERDIR: String = "user://game/packs_voice/"
const NONUSERDIR: String = "packs_voice/"
const USERDIRLEN: int = 24
const UNSORT: String = "/?"
var UNSORT_adj: String = UNSORT.split("/", false)[-1]


var current_pack_pacys: PackedStringArray = []
var current_select_pack_name_chain: String

var default_rounds: int = M.data.settings.play_screen_visual_preferences.default_rounds
var selected_rounds: int = default_rounds



func _ready():
	add_child(uc)
	Begin()
	var interim_unseen: Image = unseen_image.get_image();interim_unseen.resize(img_size, img_size);unseen_image = ImageTexture.create_from_image(interim_unseen)
	var interim_noimag: Image = no_image.get_image();interim_noimag.resize(img_size, img_size);no_image = ImageTexture.create_from_image(interim_noimag)



func Begin():
	VisualsSetup()
	var all_packs_and_clips: Dictionary = ChildFoldersAsDict(USERDIR)
	PacksToSideBar(all_packs_and_clips)
	voice_sidebar.visible = true
	players_sidebar.visible = false
	settings_sidebar.visible = false


func SameLobby(lobby: Array):
	player_selection_list.SameLobby(lobby.duplicate(true))



func ChildFoldersAsDict(directory_string: String) -> Dictionary:
	var unsort: PackedStringArray = []
	var own_dict: Dictionary = {
		UNSORT: unsort.duplicate()
	}
	var dir = DirAccess.open(directory_string)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":

			if Profile.has(directory_string + file_name):
				breakpoint
				file_name = dir.get_next()
				continue
			if not dir.current_is_dir() and (file_name.ends_with(".wav") or file_name.ends_with(".mp3")):
				if not file_name.get_file().left(8) == "_ignore_":
					own_dict[UNSORT].append(file_name.left(file_name.length() - 4))
			elif dir.current_is_dir():
				var clipped_directory = directory_string.right(directory_string.length() - USERDIRLEN)
				own_dict[clipped_directory + file_name + "/"] = {UNSORT: unsort.duplicate()}
				own_dict[clipped_directory + file_name + "/"].merge(ChildFoldersAsDict(directory_string + file_name + "/"), true)
			file_name = dir.get_next()
	return own_dict


func PacksToSideBar(all_packs_and_clips: Dictionary):
	for child in tree.get_children():
		child.free()
	var root = tree.create_item()
	tree.hide_root = true

	var all_button = tree.create_item(root)
	all_button.set_tooltip_text(0, " ")
	all_button.set_collapsed(false)
	all_button.set_text(0, "All Voice Packs")
	all_button.set_metadata(0, UNSORT)

	SetVclipButtonsRecursion(root, all_packs_and_clips)


func SetVclipButtonsRecursion(parent: TreeItem, dict_frag: Dictionary):
	for key in dict_frag.keys():
		var plaintext_name: String = key.split("/", false)[-1]
		if plaintext_name != UNSORT_adj:
			var child = tree.create_item(parent)
			child.set_tooltip_text(0, " ")
			child.set_collapsed(true)
			child.set_text(0, plaintext_name)
			child.set_metadata(0, key)
			SetVclipButtonsRecursion(child, dict_frag[key])




func TreeCollapse(do: bool):
	for child in tree.get_root().get_children():
		child.set_collapsed_recursive(do)


func _on_tree_cell_selected():
	selected_rounds = default_rounds
	right_options.visible = true
	M.sfx_select.play()
	var folder_path: String = tree.get_selected().get_metadata(0)
	var text: String = tree.get_selected().get_text(0)
	var time_start: float = Time.get_ticks_msec()
	LoadContainedVclips(folder_path, text)
	var time_end: float = Time.get_ticks_msec()
	print("Milliseconds taken: %s" % [time_end - time_start])
	AdjustRounds(0)


func _on_btn_expand_packs_button_clicked():
	tree_collapse = not tree_collapse
	TreeCollapse(tree_collapse)




func LoadContainedVclips(folder_path: String, text: String):
	if folder_path == "/?":
		folder_path = ""
	current_pack_pacys = recursive_vclip_from_folder(folder_path)
	buffered_load_image_previews(current_pack_pacys)
	update_selection_subtitle_and_size(folder_path, current_pack_pacys.size())
	lbl_title.text = text
	current_select_pack_name_chain = folder_path



func recursive_vclip_from_folder(folder_name: String) -> PackedStringArray:
	var output: PackedStringArray = []
	var dir = DirAccess.open(FileManager.MODPACKS_VOICE + folder_name)
	if dir:
		dir.list_dir_begin(); var file_name = dir.get_next()
		while file_name:
			if file_name.begins_with("_ignore_"): file_name = dir.get_next();continue
			if dir.current_is_dir(): output.append_array(recursive_vclip_from_folder(folder_name + file_name + "/"));file_name = dir.get_next();continue
			if VD.SCANNED_AUDIO_EXTENSIONS.has(file_name.right(3)): output.append(folder_name + file_name.left(-4))

			file_name = dir.get_next()
	return output


func update_selection_subtitle_and_size(folder_path: String, pack_size: int):

	var font_size_try: int = 24
	var subtitle_text: String = uc.get_text(M.OVEEP.VOICE, folder_path + "_subtitle")
	var subtitle_pixel_width: Vector2 = font.get_string_size(subtitle_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size_try)
	while (subtitle_pixel_width.x > 636) and (font_size_try > 12):
		font_size_try -= 4
		subtitle_pixel_width = font.get_string_size(subtitle_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size_try)
	subtitle.add_theme_font_size_override("font_size", font_size_try)
	subtitle.text = subtitle_text
	var author_text: String = uc.get_text(M.OVEEP.VOICE, folder_path + "_author")
	lbl_author.text = "by " + author_text if not author_text.is_empty() else ""

	var rounds_min: int = min(default_rounds, pack_size)
	lbl_rounds.text = str(rounds_min)
	btn_start.enable(rounds_min > 0)
	match pack_size:
		0:
			lbl_voice_count.text = "No voices in this pack"
		1:
			lbl_voice_count.text = "%s voice found!" % [pack_size]
		_:
			lbl_voice_count.text = "%s voices found!" % [pack_size]


func buffered_load_image_previews(vclip_set: PackedStringArray):
	var seen_images: PackedStringArray = M.data.player.clips.seen


	var my_hash: int = Array(vclip_set).hash()
	abort_hash = my_hash
	for child in vclip_img_preview.get_children():
		child.free()
	var wait_rows: int = clampi(M.data.settings.play_screen_visual_preferences.preview_images_per_row, 5, 9)
	for path_idx in vclip_set.size():
		if vclip_img_preview.get_child_count() > M.data.settings.play_screen_visual_preferences.image_preview_cutoff:
			var image_load: Image = load("res://graphic/image/dots.png").get_image()
			image_load.resize(img_size, img_size)
			var img: = TextureRect.new()
			img.texture = ImageTexture.create_from_image(image_load)
			vclip_img_preview.add_child(img)
			break
		var path: String = vclip_set[path_idx]
		if path_idx % wait_rows == 0:
			await get_tree().process_frame
			if my_hash != abort_hash:
				return
		var img = TextureRect.new()
		if M.THISISDEMO or seen_images.has(path):
			var texture: ImageTexture
			texture = uc.get_image(M.OVEEP.VOICE, path, false, Vector2i(img_size, img_size))
			if texture == null:
				texture = uc.get_image(M.OVEEP.VOICE, path.get_base_dir() + "/_pack_filler_image", false, Vector2i(img_size, img_size))
				if texture == null:
					img.texture = no_image
				else:
					img.texture = texture
			else:
				img.texture = texture
		else:
			img.texture = unseen_image
		vclip_img_preview.add_child(img)



func _on_btn_plus_button_clicked():
	AdjustRounds(1)


func _on_btn_minus_button_clicked():
	AdjustRounds(-1)


func AdjustRounds(amount: int = 0):
	if selected_rounds > 0:

		selected_rounds = wrapi(selected_rounds + amount, 1, current_pack_pacys.size() + 1)
		lbl_rounds.text = str(selected_rounds)




var search_tags: PackedStringArray = []
var match_mailto: Dictionary = {
	"players": [], 
	"total_rounds": 0, 
	"vamba": []
}


func VisualsSetup():
	button_array.visible = (M.session_type == M.SESSION_TYPE.STANDARD) or (M.session_type == M.SESSION_TYPE.STANDARD_JABRONI)
	vclip_images_scroll.custom_minimum_size.x = 432 + 68 * (-6 + clampi(M.data.settings.play_screen_visual_preferences.preview_images_per_row, 5, 9))
	right_options.visible = false
	if M.THISISDEMO:
		button_array.visible = false
		round_buttons.visible = false
	call_deferred("TreeCollapse", tree_collapse)


func AttemptMatchStart():
	var thread: = Thread.new()
	var vamba_generator: = VambaGenerator.new()

	match_mailto.total_rounds = selected_rounds
	var vamba: PackedStringArray
	get_tree().root.get_node("World").ActiveHint(true, "Checking")
	click_blocker.show()
	if M.data.settings.clip_selection.uniform == 0:

		thread.start(vamba_generator.generate_vamba.bind(current_pack_pacys, selected_rounds, M.data.settings.clip_selection.duplicate(true)))
	else:

		thread.start(vamba_generator.generate_vamba_pack_weighted.bind(selected_rounds, current_select_pack_name_chain))
	while thread.is_alive(): await get_tree().process_frame
	vamba = thread.wait_to_finish()
	print("PlayMatch | vamba:\n%s" % JSON.stringify(vamba, "\t"))
	get_tree().root.get_node("World").ActiveHint(false)
	click_blocker.hide()
	match_mailto.vamba = vamba





	if vamba.is_empty():

		btn_continue.visible = false
		advisory_popup.visible = true
		lbl_popup.text = "Attention!\n\nDue to your clip selection criteria, no clips were able to be selected.\n\nCurrent minimum allowed length: %1.1f\nCurrent maximum allowed length: %1.1f" % [M.data.settings.clip_selection.voice_range.min, M.data.settings.clip_selection.voice_range.max]
		return
	elif vamba.size() < match_mailto.total_rounds:
		btn_continue.visible = true
		advisory_popup.visible = true
		lbl_popup.text = "Attention!\n\nDue to your clip selection criteria, this pack cannot create a session with the desired rounds. It will be %s rounds instead.\n\nCurrent minimum allowed length: %1.1f\nCurrent maximum allowed length: %1.1f" % [vamba.size(), M.data.settings.clip_selection.voice_range.min, M.data.settings.clip_selection.voice_range.max]
		return
	initiate_session()

func initiate_session() -> void :
	match M.session_type:
		M.SESSION_TYPE.STANDARD:
			get_tree().get_root().get_node("World").CreateMatch(match_mailto)
		M.SESSION_TYPE.STANDARD_JABRONI:
			get_tree().get_root().get_node("World").CreateMatch(match_mailto)
		M.SESSION_TYPE.TWITCH:
			get_tree().get_root().get_node("World").generate_session_twitch(match_mailto)



func _on_btn_start_button_clicked():
	AttemptMatchStart()


func _on_btn_confirm_exit_button_clicked():
	advisory_popup.visible = false


func _on_btn_continue_button_clicked():
	advisory_popup.visible = false
	initiate_session()


func _on_btn_voice_packs_button_clicked():
	voice_sidebar.visible = true
	players_sidebar.visible = false
	settings_sidebar.visible = false


func _on_btn_players_button_clicked():
	voice_sidebar.visible = false
	players_sidebar.visible = true
	settings_sidebar.visible = false


func _on_btn_settings_button_clicked():
	voice_sidebar.visible = false
	players_sidebar.visible = false
	settings_sidebar.visible = true


@onready var pack_search_bar = %PackSearchBar
func _on_pack_search_bar_text_changed():
	var search_text: String = pack_search_bar.text.to_lower()
	if search_text.is_empty(): for treeitem: TreeItem in tree.get_root().get_children(): reset_all_visible(tree.get_root())
	else: for trit: TreeItem in tree.get_root().get_children(): self_or_child_has(trit, search_text)





func reset_all_visible(trit: TreeItem):
	trit.visible = true
	for child in trit.get_children(): reset_all_visible(child)

func self_or_child_has(trit: TreeItem, text: String) -> bool:
	var checker: bool = trit.get_text(0).to_lower().contains(text)
	for child in trit.get_children():
		checker = self_or_child_has(child, text) or checker
	trit.visible = checker
	return checker
