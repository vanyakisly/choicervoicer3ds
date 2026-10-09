extends VBoxContainer



@onready var thumbnails_list: GridContainer = %ThumbnailsList
@onready var timer_new_thumbnail: Timer = %TimerNewThumbnail
@onready var label: Label = %Label


var thumbnail_index: int = 0
var seen_clips: Array




func _reshuffle_seen_clips() -> void :
	if seen_clips.size() > 9:
		var split_point: int = floori(seen_clips.size() / 2.0)
		var seen_a: Array = seen_clips.slice(0, split_point)
		var seen_b: Array = seen_clips.slice(split_point)
		seen_a.shuffle();seen_b.shuffle()
		seen_a.append_array(seen_b)
		seen_clips = seen_a
	else: seen_clips.shuffle()
func clear_label(selector: PackWeightedSelector) -> void : label.text = "%s clips found within search parameters." % ["Max required" if selector.validated_clips.size() >= 50 else selector.validated_clips.size()]


func _setup_visual_thumbnails(guarantee_show = false) -> void :
	for i: int in range(21):
		var thumbnail: = TextureRect.new()
		thumbnail.texture = ProxyMiddlemanMenu.unseen_image
		thumbnail.custom_minimum_size = Vector2i(64, 64)
		thumbnails_list.add_child(thumbnail)
		thumbnail.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		thumbnail.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
func _setup_misc() -> void :
	seen_clips = Array(Profile.seen_clips_voice)
	seen_clips.shuffle()


func _change_next_thumbnail() -> void :
	var active_thumbnail: TextureRect = thumbnails_list.get_child(wrapi(thumbnail_index, 0, 21))
	thumbnail_index += 1
	var new_image: Texture2D
	if active_thumbnail.texture != ProxyMiddlemanMenu.unseen_image and randf() < 0.5: new_image = ProxyMiddlemanMenu.unseen_image
	elif active_thumbnail.texture == ProxyMiddlemanMenu.unseen_image and randf() < 0.5: new_image = ProxyMiddlemanMenu.unseen_image
	elif seen_clips:
		new_image = VD.get_texture_agnostic(FileManager.MODPACKS_VOICE + seen_clips[wrapi(thumbnail_index, 0, seen_clips.size())])
		if !new_image: new_image = ProxyMiddlemanMenu.unseen_image
	else:
		new_image = ProxyMiddlemanMenu.unseen_image
	if seen_clips and thumbnail_index % seen_clips.size() == 0: _reshuffle_seen_clips()
	var tween: Tween = create_tween()
	await tween.tween_property(active_thumbnail, "modulate:a", 0.0, 0.3).finished
	active_thumbnail.texture = new_image
	tween = create_tween()
	await tween.tween_property(active_thumbnail, "modulate:a", 1.0, 0.3).finished


func _ready() -> void :
	_setup_visual_thumbnails(false)
	_setup_misc()
	timer_new_thumbnail.start()
