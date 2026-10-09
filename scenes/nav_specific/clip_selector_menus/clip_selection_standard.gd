class_name ClipSelectionMenuBase extends MenuBase


const PRINTSTR: String = "ClipSelectionMenuBase | "
const TREE_ITEM_TEXT_COLUMN: int = 0
const CLIP_SELECTION_BOOK = preload("res://scenes/nav_specific/clip_selector_menus/modules/clip_selection_book.tscn")
const ALL_PACKS_PACKET: PackInfo = preload("res://assets_gd/resources/_unsorted/all_packs_filler.tres")


@onready var info_chunk: VBoxContainer = %InfoChunk
@onready var text_search: LineEdit = %TextSearch
@onready var tree: VoicePackTree = %Tree
@onready var icon_viewer: TextureRect = %Icon
@onready var lbl_pack_title: Label = %LblPackTitle
@onready var lbl_subtitle: Label = %LblSubtitle
@onready var pack_icon_area: MarginContainer = %PackIconArea
@onready var authors_area: MarginContainer = %AuthorsArea
@onready var lbl_authors: Label = %LblAuthors
@onready var page_clips: Control = %PageClips
@onready var page_errors: Control = %PageErrors
@onready var page_readme: Control = %PageReadme
@onready var page_filtering: MarginContainer = %PageFiltering
@onready var error_list: VBoxContainer = %ErrorList
@onready var lbl_readme: Label = %LblReadme
@onready var clip_random_selection_block: VBoxContainer
@onready var btn_filtering: ButtonCV = %BtnFiltering
@onready var btn_clips: ButtonCV = %BtnClips
@onready var btn_errors: ButtonCV = %BtnErrors
@onready var btn_readme: ButtonCV = %BtnReadme
@onready var clip_book_container: Control = %ClipBookContainer
@onready var options: ColorRect = %Options
@onready var title_bubble: ColorRect = %TitleBubble
@onready var author_bubble: ColorRect = %AuthorBubble


var active_collection: OmniClipCollection
var alacarte_collection: = OmniClipCollection.new()



func _setup_bubble_color() -> void :
	var grabbed_color: Color = M.button_profile_standard.gradient_standard.gradient.colors[3]
	title_bubble.material.set_shader_parameter("color", grabbed_color)
	author_bubble.material.set_shader_parameter("color", grabbed_color)



func _ready() -> void :
	info_chunk.hide();options.hide();page_filtering.hide()
	clip_random_selection_block = %ClipRandomSelectionBlock
	if Profile.menu_slash != "Default/": _setup_bubble_color()
	menu_data.back_path = Metro.clip_selection_page_back_path




func _update_pack_presentation(pack: PackInfo) -> void :
	if pack is PackInfo:
		if pack.icon: icon_viewer.texture = pack.icon
		pack_icon_area.visible = (pack.icon != null)
		lbl_pack_title.text = pack.display_name
		if pack.subtitle: lbl_subtitle.text = pack.subtitle
		lbl_subtitle.get_parent().visible = ( !pack.subtitle.is_empty())
		if pack.authors: lbl_authors.text = "by %s" % [", ".join(pack.authors)]
		authors_area.visible = ( !pack.authors.is_empty())
	else:
		pack_icon_area.hide()
		lbl_pack_title.text = "";lbl_subtitle.text = ""
		authors_area.hide()
func _update_pack_information(pack: PackInfo) -> void :
	if !(pack is PackInfo): return
	btn_readme.enable( !pack.readme.is_empty())
	if pack.readme: lbl_readme.text = pack.readme
func _update_errors_report(report: PackedStringArray) -> void :
	for node: Node in error_list.get_children(): node.queue_free()
	if !report.is_empty(): btn_errors.enable(true);btn_errors.get_child(0).text = "⚠ Errors"
	else: btn_errors.enable(false)
	for line: String in report: var label: = Label.new();label.add_theme_color_override("font_color", Color.BLACK);label.text = line;error_list.add_child(label)
func _update_pack_book(pack: PackInfo) -> void :
	for child: Node in clip_book_container.get_children(): child.queue_free()
	if !(pack is PackInfo): return
	var clip_book: ClipSelectionBook = CLIP_SELECTION_BOOK.instantiate()
	if pack.unique_all_voice_packs: clip_book.voice_pack_tree_node = tree
	clip_book.finished_errors.connect(_update_errors_report)
	clip_book.start.connect(attempt_game_from_clipbookpackage)
	clip_book_container.add_child(clip_book)
	clip_book.load_pack(pack)
	clip_random_selection_block.changes_to_filtering.connect(clip_book.update_working_collection_from_tags)
func _pack_selected(pack: PackInfo) -> void :
	info_chunk.show()
	btn_clips.button_array_item_clicked.emit(1);btn_clips.button_clicked.emit();btn_readme.enable(false);btn_errors.enable(false);btn_errors.get_child(0).text = "Errors"
	M.sfx_select.play()
	_update_pack_presentation(pack)
	_update_pack_information(pack)
	_update_pack_book(pack)
func _all_voice_packs_selected() -> void : _pack_selected(ALL_PACKS_PACKET)










func show_page_clips() -> void : page_clips.show();page_errors.hide();page_readme.hide();page_filtering.hide()
func show_page_errors() -> void : page_clips.hide();page_errors.show();page_readme.hide();page_filtering.hide()
func show_page_readme() -> void : page_clips.hide();page_errors.hide();page_readme.show();page_filtering.hide()
func show_page_filtering() -> void : page_clips.hide();page_errors.hide();page_readme.hide();page_filtering.show()
func options_up() -> void : options.show()
func options_down() -> void : options.hide()



func attempt_game_from_clipbookpackage(package: ClipBookPackage) -> void :
	var thread: = Thread.new()
	var vamba_generator: = VambaGeneratorReduxOmniClip.new()
	var vamba: Array[OmniClip]
	M.world.ActiveHint(true, "Checking")
	if Profile.uniform == 0: thread.start(vamba_generator.generate_uniform_shuffle.bind(package.collection, package.rounds))
	else: thread.start(vamba_generator.generate_packweighted_shuffle.bind(package.collection, package.rounds))
	while thread.is_alive(): await get_tree().process_frame
	vamba = thread.wait_to_finish()
	M.world.ActiveHint(false)
	if vamba.is_empty(): pass
	Metro.gameplay_omniclip_set = vamba
	initiate_session()


func initiate_session() -> void :
	match M.session_type:
		M.SESSION_TYPE.STANDARD: M.world.CreateMatch()
		M.SESSION_TYPE.STANDARD_JABRONI: M.world.CreateMatch()
		M.SESSION_TYPE.TWITCH: M.world.generate_session_twitch()
		M.SESSION_TYPE.TWITCH_PANEL: M.world.generate_session_twitch_panel()
		_: printerr(PRINTSTR + "Current session type is one not expected.")



func filter_text(text: String) -> void :
	if text.is_empty(): tree.see_reset();return
	elif text.contains(":"):
		var split_text: PackedStringArray = text.split(":", true)
		var keyword: String = split_text[0].strip_edges()
		var phrase: String = split_text[1].strip_edges()
		match keyword:
			"author", "authors", "by", "from": tree.see_author(phrase)

			"readme", "info": tree.see_readme(phrase)
			"subtitle": tree.see_subtitle(phrase)
	else: tree.see_title(text)
