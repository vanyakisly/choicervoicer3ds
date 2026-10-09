class_name ClipPreviewThumbnail extends BaseButton


signal listen(stream: AudioStream)
signal add(clip: OmniClip)


const PRINTMSG: String = "ClipPreviewThumbnail | "

@export var clip: OmniClip
@export var showing: bool


func _init(in_clip: OmniClip, guarantee_show = false) -> void :
	action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	button_mask = 3
	clip = in_clip
	showing = guarantee_show or clip.has_been_seen()
	write_from_clip()
	pressed.connect(parse_button_click)


func write_from_clip() -> void :
	if !clip: return
	var texture_view: = TextureRect.new()
	if showing:
		if clip.clip_texture: texture_view.texture = clip.clip_texture
		else: texture_view.texture = ProxyMiddlemanMenu.no_image
	else: texture_view.texture = ProxyMiddlemanMenu.unseen_image
	add_child(texture_view)

	texture_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func parse_button_click() -> void :
	if Input.is_action_pressed("ui_mouse1"): if showing: listen.emit(clip.clip_audio)
	else: add.emit(clip)
