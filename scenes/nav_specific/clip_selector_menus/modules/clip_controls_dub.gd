extends Control

signal attempt_session(package: ClipBookPackage)

@onready var main: VBoxContainer = %Main
@onready var loading_screen: Control = %LoadingScreen
@onready var bottom_section: HBoxContainer = %BottomSection
@onready var info_grid_container: GridContainer = %InfoGridContainer

@onready var checklist: VBoxContainer = %Checklist
@onready var lbl_clip_count_selected: RichTextLabel = %LblClipCountSelected
@onready var lbl_clip_length_selected: Label = %LblClipLengthSelected
@onready var lbl_estimated_playtime: Label = %LblEstimatedPlaytime
@onready var lbl_longest_clip: Label = %LblLongestClip
@onready var chk_ref: CheckBox = %ChkREF
@onready var lbl_plurals: Label = %LblPlurals

@onready var btn_start: ButtonCV = %BtnStart

@onready var spin_wheel_animator: AnimationPlayer = %SpinWheelAnimator

var pack: PackInfo
var omni_clip_array: OmniClipCollection
var selected_clips: Array[OmniClip]
var selected_characters: PackedStringArray = []
var unselected_characters: PackedStringArray = []


func _ready() -> void :
	_reset_visuals()
	if M.THISISDEMO: btn_start.set_first_label_text("Demo Only");btn_start.enable(false)


func _reset_visuals() -> void :
	main.hide();loading_screen.show()
	spin_wheel_animator.play("SpinWheel")


func new_pack(input: PackInfo) -> void :
	_reset_visuals()
	pack = input
	var thread: = Thread.new()
	thread.start(_process_pack_into_collection.bind(pack))
	while thread.is_alive(): await get_tree().process_frame
	omni_clip_array = thread.wait_to_finish()
	_new_checkboxes()
	_update()
	loading_screen.hide();main.show();spin_wheel_animator.stop()
	if !omni_clip_array.get_clips_with_dub_timestamps():
		btn_start.set_first_label_text("no dub\n audio found")
		btn_start.call_deferred("enable", false)
		info_grid_container.hide()
	elif pack.has_dub_video_file:
		btn_start.set_first_label_text("Start")
		btn_start.call_deferred("enable", true)
		if !info_grid_container.visible: info_grid_container.show()
	else:
		btn_start.set_first_label_text("missing\n`dub_video.ogv`")
		btn_start.call_deferred("enable", false)
		info_grid_container.hide()


func _process_pack_into_collection(input: PackInfo) -> OmniClipCollection:
	var output: = OmniClipCollection.new()
	output.generate_from_pack_info(pack, false)
	return output


func _new_checkboxes() -> void :
	for child: Control in checklist.get_children(): child.queue_free()
	var no_preselected_characters: bool = pack.preselected_dub_characters.is_empty()
	for character: String in omni_clip_array.get_dub_characters():
		var chkbox: CheckBox = chk_ref.duplicate()
		checklist.add_child(chkbox)
		chkbox.button_pressed = true if no_preselected_characters else pack.preselected_dub_characters.has(character)
		chkbox.toggled.connect(_update)
		var character_length: float = 0.0
		for clip: OmniClip in omni_clip_array.get_clips_from_characters([character]): character_length += clip.get_length()
		chkbox.text = "  %s - %2.0f:%02.0f" % [character, floori(character_length / 60.0), fmod(character_length, 60.0)]
		chkbox.set_meta("tag", character)
		chkbox.show()


func _update(_filler: bool = false) -> void :
	selected_characters.clear();unselected_characters.clear();selected_clips.clear()
	if !omni_clip_array.get_dub_characters():
		selected_clips = omni_clip_array.data
	else:
		for chkbox: CheckBox in checklist.get_children():
			if chkbox.button_pressed: selected_characters.append(chkbox.get_meta("tag", ""))
			else: unselected_characters.append(chkbox.get_meta("tag", ""))
		if selected_characters.is_empty(): selected_characters = unselected_characters.duplicate()
		selected_clips = omni_clip_array.get_clips_from_characters(selected_characters)
	lbl_clip_count_selected.text = "%s[font_size=16]/%s[/font_size]" % [selected_clips.size(), omni_clip_array.data.size()]
	var selected_length: float = 0.0
	var longest_length: float = 0.0
	var estimated_playtime: float = 0.0
	for clip: OmniClip in selected_clips:
		var length: float = clip.get_length()
		selected_length += length
		if length > longest_length: longest_length = length
		estimated_playtime += 4.0 + length * (1.0 + minf(5.0, 2.5 / pow(length, 2.0)))
	lbl_clip_length_selected.text = "%2.0f:%02.0f" % [floori(selected_length / 60.0), fmod(selected_length, 60.0)]
	lbl_longest_clip.text = "%2.0f:%02.0f" % [floori(longest_length / 60.0), fmod(longest_length, 60.0)]
	lbl_estimated_playtime.text = "%2.0f:%02.0f" % [floori(estimated_playtime / 60.0), fmod(estimated_playtime, 60.0)]


func _send_package() -> void :
	var selected_collection: = OmniClipCollection.new()
	selected_collection.data = selected_clips
	attempt_session.emit(ClipBookPackage.new(selected_collection, 0, omni_clip_array, checklist))
