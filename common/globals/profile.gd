extends Node



signal changed_menu
signal changed_clip_filtering
signal changed_dub_mode_options
signal changed_twitch_chatter_on



const EMPTY_STRING_VERSION: String = "0.0.0.0"























@export var first_time: bool
@export var seen_clips_voice: PackedStringArray

@export var played_packs: PackedStringArray


@export var host: String
@export var judges: String
@export var menu: String:
	set(value): menu = value;changed_menu.emit()
@export var studio: String
@export var contestant: String
@export var zengarden: String
var host_slash: String:
	get: return host if host.ends_with("/") else (host + "/")
var judges_slash: String:
	get: return judges if judges.ends_with("/") else (judges + "/")
var menu_slash: String:
	get: return menu if menu.ends_with("/") else (menu + "/")
var studio_slash: String:
	get: return studio if studio.ends_with("/") else (studio + "/")
var contestant_slash: String:
	get: return contestant if contestant.ends_with("/") else (contestant + "/")
var zengarden_slash: String:
	get: return zengarden if zengarden.ends_with("/") else (zengarden + "/")


@export var window_resolution: int: set = _set_window_resolution
@export var window_mode: int: set = _set_window_mode

@export var snap_window_to_center: bool: set = _set_snap_window_to_center
func _set_snap_window_to_center(value: bool) -> void : snap_window_to_center = value


@export var show_captions: bool: set = _set_show_captions
@export var caption_wait_time: float
@export var fully_mute_music: bool: set = _set_fully_mute_music
@export var easier_scoring: bool
@export var dual_player_playback: float
@export var faster_judge_scoring: bool: set = _set_faster_judge_scoring
@export var skip_host_post_record: bool: set = _set_skip_host_post_record
@export var skip_host_post_playback: bool: set = _set_skip_host_post_playback
@export var skip_host_post_scoring: bool: set = _set_skip_host_post_scoring
@export var show_clip_file_name: bool: set = _set_show_clip_file_name

@export var automatically_save_clips: bool: set = _set_automatically_save_clips
func _set_automatically_save_clips(value: bool) -> void : automatically_save_clips = value
@export var countdown_time: float: set = _set_countdown_time
func _set_countdown_time(value: float) -> void : countdown_time = value


@export var uniform: int
@export var shuffle: int: set = _set_shuffle
@export var start_from: int

@export var clip_range_on: bool: set = _set_clip_range_on
@export var clip_range_minimum: float: set = _set_clip_range_minimum
@export var clip_range_maximum: float: set = _set_clip_range_maximum
@export var unseen_percent: int: set = _set_unseen_percent

@export var auto_tag_with_nested_folders: bool: set = _set_auto_tag_with_nested_folders
func _set_auto_tag_with_nested_folders(value: bool) -> void : auto_tag_with_nested_folders = value


@export var ignored_packs_host: PackedStringArray
@export var ignored_packs_judges: PackedStringArray
@export var ignored_packs_menu: PackedStringArray
@export var ignored_packs_studio: PackedStringArray
@export var ignored_packs_contestant: PackedStringArray
@export var ignored_packs_voice: PackedStringArray

@export var ignored_packs_chatter: PackedStringArray
@export var ignored_clips: PackedStringArray
@export var hide_ignored: bool


@export var default_rounds: int: set = _set_default_rounds
@export var clip_preview_size: int
@export var preview_images_per_row: int
@export var start_expanded: bool
@export var image_preview_cutoff: int

@export var volume_master: float: set = _set_volume_master
@export var volume_music: float: set = _set_volume_music
@export var volume_sfx: float: set = _set_volume_sfx
@export var volume_buttons: float: set = _set_volume_buttons
@export var volume_voice_clips: float: set = _set_volume_voice_clips
@export var volume_player_recordings: float: set = _set_volume_player_recordings
@export var volume_clip_playback: float: set = _set_volume_clip_playback
@export var volume_chatter: float: set = _set_volume_chatter

@export var audio_device_in: String: set = _set_audio_device_in
@export var audio_device_out: String: set = _set_audio_device_out

@export var mic_delay: float: set = _set_mic_delay
@export var mic_crust_compressor_on: bool: set = _set_mic_crust_compressor_on
@export var mic_crust_cutoff_on: bool: set = _set_mic_crust_cutoff_on
@export var mic_crust_limiter_on: bool: set = _set_mic_crust_limiter_on
@export var mic_crust_distortion_on: bool: set = _set_mic_crust_distortion_on
@export var mic_crust_sample_rate_on: bool: set = _set_mic_crust_sample_rate_on
@export var mic_crust_sample_rate_index: int: set = _set_mic_crust_sample_rate_index
@export var mic_crust_cutoff_low_pass: int: set = _set_mic_crust_cutoff_low_pass
@export var mic_crust_cutoff_high_pass: int: set = _set_mic_crust_cutoff_high_pass
@export var mic_crust_compressor_threshold: float: set = _set_mic_crust_compressor_threshold
@export var mic_crust_compressor_gain: float: set = _set_mic_crust_compressor_gain
@export var mic_crust_limiter_ceilingdb: float: set = _set_mic_crust_limiter_ceilingdb
@export var mic_crust_limiter_thresholddb: float: set = _set_mic_crust_limiter_thresholddb
@export var mic_crust_distortion_pre_gain: float: set = _set_mic_crust_distortion_pre_gain
@export var mic_crust_distortion_drive: float: set = _set_mic_crust_distortion_drive
@export var mic_crust_distortion_post_gain: float: set = _set_mic_crust_distortion_post_gain
@export var mic_crust_mic_input: float: set = _set_mic_crust_mic_input
@export var mic_crust_mic_multiplier: float: set = _set_mic_crust_mic_multiplier

@export var twitch_channel_name: String: set = _set_twitch_channel_name
@export var twitch_advanced_options: bool: set = _set_twitch_advanced_options
@export var twitch_is_case_sensitive: bool: set = _set_twitch_is_case_sensitive
@export var twitch_is_exact_phrase: bool: set = _set_twitch_is_exact_phrase
@export var twitch_allow_duplicate_voting: bool: set = _set_twitch_allow_duplicate_voting
@export var twitch_vote_type_is_binary: bool: set = _set_twitch_vote_type_is_binary
@export var twitch_close_poll_votes_bool: bool: set = _set_twitch_close_poll_votes_bool
@export var twitch_close_poll_inactivity_bool: bool: set = _set_twitch_close_poll_inactivity_bool

@export var twitch_close_poll_votes_int: int: set = _set_twitch_close_poll_votes_int
@export var twitch_close_poll_inactivity_int: int: set = _set_twitch_close_poll_inactivity_int
@export var twitch_commands_binary_pass: String: set = _set_twitch_commands_binary_pass
@export var twitch_commands_binary_fail: String: set = _set_twitch_commands_binary_fail
@export var twitch_commands_score_0: String: set = _set_twitch_commands_score_0
@export var twitch_commands_score_1: String: set = _set_twitch_commands_score_1
@export var twitch_commands_score_2: String: set = _set_twitch_commands_score_2
@export var twitch_commands_score_3: String: set = _set_twitch_commands_score_3
@export var twitch_commands_score_4: String: set = _set_twitch_commands_score_4
@export var twitch_commands_score_5: String: set = _set_twitch_commands_score_5
@export var twitch_commands_direct: String

@export var twitch_chatter_on: bool: set = _set_twitch_chatter_on
@export var twitch_chatter_user_cooldown: int: set = _set_twitch_chatter_user_cooldown
@export var twitch_chatter_global_cooldown: int: set = _set_twitch_chatter_global_cooldown
func _set_twitch_chatter_on(value: bool) -> void : twitch_chatter_on = value;changed_twitch_chatter_on.emit()
func _set_twitch_chatter_user_cooldown(value: int) -> void : twitch_chatter_user_cooldown = value
func _set_twitch_chatter_global_cooldown(value: int) -> void : twitch_chatter_global_cooldown = value


@export var content_pack_preference_absolute_image: int = 0


@export var twitch_panel_username_1: String: set = _set_twitch_panel_username_1
@export var twitch_panel_username_2: String: set = _set_twitch_panel_username_2
@export var twitch_panel_username_3: String: set = _set_twitch_panel_username_3
@export var twitch_panel_username_4: String: set = _set_twitch_panel_username_4
@export var twitch_panel_username_5: String: set = _set_twitch_panel_username_5
@export var twitch_panel_override_judge_names: bool = true: set = _set_twitch_panel_override_judge_names
func _set_twitch_panel_username_1(value: String) -> void : twitch_panel_username_1 = value
func _set_twitch_panel_username_2(value: String) -> void : twitch_panel_username_2 = value
func _set_twitch_panel_username_3(value: String) -> void : twitch_panel_username_3 = value
func _set_twitch_panel_username_4(value: String) -> void : twitch_panel_username_4 = value
func _set_twitch_panel_username_5(value: String) -> void : twitch_panel_username_5 = value
func _set_twitch_panel_override_judge_names(value: bool) -> void : twitch_panel_override_judge_names = value


@export var dub_mode_mute_backing_track: bool: set = _set_dub_mode_mute_backing_track
@export var dub_mode_clip_order_index: int: set = _set_dub_mode_clip_order_index
@export var dub_mode_hard_mute_clips: bool: set = _set_dub_mode_hard_mute_clips
@export var dub_mode_hard_no_captions: bool: set = _set_dub_mode_hard_no_captions
@export var dub_mode_hard_one_take: bool: set = _set_dub_mode_hard_one_take
func _set_dub_mode_mute_backing_track(value: bool) -> void : dub_mode_mute_backing_track = value;changed_dub_mode_options.emit()
func _set_dub_mode_clip_order_index(value: int) -> void : dub_mode_clip_order_index = value;changed_dub_mode_options.emit()
func _set_dub_mode_hard_mute_clips(value: bool) -> void : dub_mode_hard_mute_clips = value;changed_dub_mode_options.emit()
func _set_dub_mode_hard_no_captions(value: bool) -> void : dub_mode_hard_no_captions = value;changed_dub_mode_options.emit()
func _set_dub_mode_hard_one_take(value: bool) -> void : dub_mode_hard_one_take = value;changed_dub_mode_options.emit()


@export var dub_cinema_mute_audience: bool: set = _set_dub_cinema_mute_audience
@export var dub_cinema_start_fullscreened: bool: set = _set_dub_cinema_start_fullscreened
@export var dub_cinema_autoload_audience: bool: set = _set_dub_cinema_autoload_audience
func _set_dub_cinema_mute_audience(value: bool) -> void : dub_cinema_mute_audience = value
func _set_dub_cinema_start_fullscreened(value: bool) -> void : dub_cinema_start_fullscreened = value
func _set_dub_cinema_autoload_audience(value: bool) -> void : dub_cinema_autoload_audience = value


@export var debug_sample_timing: int: set = _set_debug_sample_timing; func _set_debug_sample_timing(value: int) -> void : debug_sample_timing = value
@export var debug_countdown_type: int: set = _set_debug_countdown_type; func _set_debug_countdown_type(value: int) -> void : debug_countdown_type = value
@export var debug_disable_fog: bool: set = _set_debug_disable_fog; func _set_debug_disable_fog(value: bool) -> void : debug_disable_fog = value




func import_data(data: Dictionary) -> void :
	var _version = type_convert(data.get("version", EMPTY_STRING_VERSION), TYPE_STRING)

	var player: Dictionary = type_convert(data.get("player", {}), TYPE_DICTIONARY)
	first_time = type_convert(player.get("first_time", true), TYPE_BOOL)
	var clips: Dictionary = type_convert(player.get("clips", {}), TYPE_DICTIONARY)
	seen_clips_voice = type_convert(clips.get("seen", []), TYPE_PACKED_STRING_ARRAY)

	played_packs = type_convert(player.get("played_packs", []), TYPE_PACKED_STRING_ARRAY)
	var player_ignored: Dictionary = type_convert(player.get("ignored", {}), TYPE_DICTIONARY)
	var imported_ignored_packs_host = (type_convert(player_ignored.get("ignored_packs_host", []), TYPE_PACKED_STRING_ARRAY));for s: String in imported_ignored_packs_host: if !ignored_packs_host.has(s): ignored_packs_host.append(s)
	var imported_ignored_packs_judges = (type_convert(player_ignored.get("ignored_packs_judges", []), TYPE_PACKED_STRING_ARRAY));for s: String in imported_ignored_packs_judges: if !ignored_packs_judges.has(s): ignored_packs_judges.append(s)
	var imported_ignored_packs_menu = (type_convert(player_ignored.get("ignored_packs_menu", []), TYPE_PACKED_STRING_ARRAY));for s: String in imported_ignored_packs_menu: if !ignored_packs_menu.has(s): ignored_packs_menu.append(s)
	var imported_ignored_packs_studio = (type_convert(player_ignored.get("ignored_packs_studio", []), TYPE_PACKED_STRING_ARRAY));for s: String in imported_ignored_packs_studio: if !ignored_packs_studio.has(s): ignored_packs_studio.append(s)
	var imported_ignored_packs_contestant = (type_convert(player_ignored.get("ignored_packs_contestant", []), TYPE_PACKED_STRING_ARRAY));for s: String in imported_ignored_packs_contestant: if !ignored_packs_contestant.has(s): ignored_packs_contestant.append(s)
	var imported_ignored_packs_voice = (type_convert(player_ignored.get("ignored_packs_voice", []), TYPE_PACKED_STRING_ARRAY));for s: String in imported_ignored_packs_voice: if !ignored_packs_voice.has(s): ignored_packs_voice.append(s)
	var imported_ignored_packs_chatter = (type_convert(player_ignored.get("ignored_packs_chatter", []), TYPE_PACKED_STRING_ARRAY));for s: String in imported_ignored_packs_chatter: if !ignored_packs_chatter.has(s): ignored_packs_chatter.append(s)
	var imported_ignored_clips = (type_convert(player_ignored.get("ignored_clips", []), TYPE_PACKED_STRING_ARRAY));for s: String in imported_ignored_clips: if !ignored_clips.has(s): ignored_clips.append(s)
	hide_ignored = type_convert(player_ignored.get("hide_ignored", true), TYPE_BOOL)

	var custom: = _get_or_make_dict(data, "custom")
	host = type_convert(custom.get("host", "Default"), TYPE_STRING)
	judges = type_convert(custom.get("judges", "Default"), TYPE_STRING)
	menu = type_convert(custom.get("menu", "Default"), TYPE_STRING)
	studio = type_convert(custom.get("studio", "Default"), TYPE_STRING)
	contestant = type_convert(custom.get("player", "Default"), TYPE_STRING)

	var settings: = _get_or_make_dict(data, "settings")

	var display: = _get_or_make_dict(settings, "display")
	window_resolution = type_convert(display.get("window_resolution", 0), TYPE_INT)
	window_mode = type_convert(display.get("window_mode", 0), TYPE_INT)
	snap_window_to_center = type_convert(display.get("snap_window_to_center", true), TYPE_BOOL)

	var gameshow: = _get_or_make_dict(settings, "match_settings")
	show_captions = type_convert(gameshow.get("show_text_hints", true), TYPE_BOOL)
	caption_wait_time = type_convert(gameshow.get("hint_wait_time", 0.0), TYPE_FLOAT)
	fully_mute_music = type_convert(gameshow.get("fully_mute_music", true), TYPE_BOOL)
	easier_scoring = type_convert(gameshow.get("easier_scoring", true), TYPE_BOOL)
	dual_player_playback = type_convert(gameshow.get("dual_player_playback", -0.13), TYPE_FLOAT)
	faster_judge_scoring = type_convert(gameshow.get("faster_scoring_from_judges", true), TYPE_BOOL)
	skip_host_post_record = type_convert(gameshow.get("skip_host_post_record", false), TYPE_BOOL)
	skip_host_post_playback = type_convert(gameshow.get("skip_host_post_playback", false), TYPE_BOOL)
	skip_host_post_scoring = type_convert(gameshow.get("skip_host_post_scoring", false), TYPE_BOOL)
	show_clip_file_name = type_convert(gameshow.get("show_clip_name", false), TYPE_BOOL)
	automatically_save_clips = type_convert(gameshow.get("automatically_save_clips", false), TYPE_BOOL)
	countdown_time = type_convert(gameshow.get("countdown_time", 2.0), TYPE_FLOAT)


	var clipsel: = _get_or_make_dict(settings, "clip_selection")
	uniform = type_convert(clipsel.get("uniform", 0), TYPE_INT)
	shuffle = type_convert(clipsel.get("shuffle", 0), TYPE_INT)
	start_from = type_convert(clipsel.get("start_from", 1), TYPE_INT)
	unseen_percent = type_convert(clipsel.get("unseen_percent", 100), TYPE_INT)
	auto_tag_with_nested_folders = type_convert(clipsel.get("auto_tag_with_nested_folders", true), TYPE_BOOL)

	var voice_range: = _get_or_make_dict(clipsel, "voice_range")
	clip_range_on = type_convert(voice_range.get("clip_range_on", false), TYPE_BOOL)
	clip_range_minimum = type_convert(voice_range.get("min", 0.0), TYPE_FLOAT)
	clip_range_maximum = type_convert(voice_range.get("max", 60.0), TYPE_FLOAT)

	var psvp: = _get_or_make_dict(settings, "play_screen_visual_preferences")
	clip_preview_size = type_convert(psvp.get("clip_preview_size", 1), TYPE_INT)
	preview_images_per_row = type_convert(psvp.get("preview_images_per_row", 9), TYPE_INT)
	default_rounds = type_convert(psvp.get("default_rounds", 3), TYPE_INT)
	image_preview_cutoff = type_convert(psvp.get("image_preview_cutoff", 448), TYPE_INT)
	start_expanded = type_convert(psvp.get("start_expanded", true), TYPE_BOOL)

	var volume: = _get_or_make_dict(settings, "volume")
	volume_master = type_convert(volume.get("master", 0.8), TYPE_FLOAT)
	volume_music = type_convert(volume.get("music", 0.5), TYPE_FLOAT)
	volume_sfx = type_convert(volume.get("sound_effects", 1.0), TYPE_FLOAT)
	volume_buttons = type_convert(volume.get("button_sounds", 1.0), TYPE_FLOAT)
	volume_voice_clips = type_convert(volume.get("voice_clips", 1.0), TYPE_FLOAT)
	volume_player_recordings = type_convert(volume.get("player_recordings", 1.0), TYPE_FLOAT)
	volume_clip_playback = type_convert(volume.get("clip_playback", 0.33), TYPE_FLOAT)
	volume_chatter = type_convert(volume.get("chatter", 0.5), TYPE_FLOAT)

	var mic: = _get_or_make_dict(settings, "mic")
	var devices: = _get_or_make_dict(mic, "devices")
	audio_device_in = type_convert(devices.get("audio_in", "Default"), TYPE_STRING)
	audio_device_out = type_convert(devices.get("audio_out", "Default"), TYPE_STRING)
	var crust: = _get_or_make_dict(mic, "crust")
	mic_crust_compressor_on = type_convert(crust.get("mic_crust_compressor_on", false), TYPE_BOOL)
	mic_crust_cutoff_on = type_convert(crust.get("mic_crust_cutoff_on", false), TYPE_BOOL)
	mic_crust_limiter_on = type_convert(crust.get("mic_crust_limiter_on", false), TYPE_BOOL)
	mic_crust_distortion_on = type_convert(crust.get("mic_crust_distortion_on", false), TYPE_BOOL)
	mic_crust_sample_rate_on = type_convert(crust.get("mic_crust_sample_rate_on", false), TYPE_BOOL)
	mic_crust_sample_rate_index = type_convert(crust.get("sample_rate", 0), TYPE_INT)
	mic_crust_cutoff_low_pass = type_convert(crust.get("cutoff_low_pass", 16000), TYPE_INT)
	mic_crust_cutoff_high_pass = type_convert(crust.get("cutoff_high_pass", 0), TYPE_INT)
	mic_crust_compressor_threshold = type_convert(crust.get("compressor_threshold", 0.0), TYPE_FLOAT)
	mic_crust_compressor_gain = type_convert(crust.get("compressor_gain", 9.0), TYPE_FLOAT)
	mic_crust_limiter_ceilingdb = type_convert(crust.get("limiter_ceilingdb", -10.0), TYPE_FLOAT)
	mic_crust_limiter_thresholddb = type_convert(crust.get("limiter_thresholddb", -5.0), TYPE_FLOAT)
	mic_crust_distortion_pre_gain = type_convert(crust.get("distortion_pre_gain", 0.0), TYPE_FLOAT)
	mic_crust_distortion_drive = type_convert(crust.get("distortion_drive", 0.0), TYPE_FLOAT)
	mic_crust_distortion_post_gain = type_convert(crust.get("distortion_post_gain", 6.0), TYPE_FLOAT)
	mic_crust_mic_input = type_convert(crust.get("mic_input", 1.0), TYPE_FLOAT)
	mic_crust_mic_multiplier = type_convert(crust.get("mic_multiplier", 1), TYPE_INT)

	var twitch: = _get_or_make_dict(settings, "twitch")
	twitch_channel_name = type_convert(twitch.get("channel_name", ""), TYPE_STRING)
	twitch_advanced_options = type_convert(twitch.get("advanced_options", false), TYPE_BOOL)
	twitch_is_case_sensitive = type_convert(twitch.get("is_case_sensitive", false), TYPE_BOOL)
	twitch_is_exact_phrase = type_convert(twitch.get("is_exact_phrase", false), TYPE_BOOL)
	twitch_allow_duplicate_voting = type_convert(twitch.get("allow_duplicate_voting", false), TYPE_BOOL)
	twitch_vote_type_is_binary = type_convert(twitch.get("vote_type_is_binary", true), TYPE_BOOL)
	twitch_close_poll_votes_bool = type_convert(twitch.get("close_poll_votes_bool", false), TYPE_BOOL)
	twitch_close_poll_inactivity_bool = type_convert(twitch.get("close_poll_inactivity_bool", false), TYPE_BOOL)

	twitch_close_poll_votes_int = type_convert(twitch.get("close_poll_votes_int", 0), TYPE_INT)
	twitch_close_poll_inactivity_int = type_convert(twitch.get("close_poll_inactivity_int", 5), TYPE_INT)
	var twitch_commands: = _get_or_make_dict(twitch, "commands")
	twitch_commands_binary_pass = type_convert(twitch_commands.get("binary_pass", "!pass"), TYPE_STRING)
	twitch_commands_binary_fail = type_convert(twitch_commands.get("binary_fail", "!fail"), TYPE_STRING)
	twitch_commands_score_0 = type_convert(twitch_commands.get("score_0", "!vote0"), TYPE_STRING)
	twitch_commands_score_1 = type_convert(twitch_commands.get("score_1", "!vote1"), TYPE_STRING)
	twitch_commands_score_2 = type_convert(twitch_commands.get("score_2", "!vote2"), TYPE_STRING)
	twitch_commands_score_3 = type_convert(twitch_commands.get("score_3", "!vote3"), TYPE_STRING)
	twitch_commands_score_4 = type_convert(twitch_commands.get("score_4", "!vote4"), TYPE_STRING)
	twitch_commands_score_5 = type_convert(twitch_commands.get("score_5", "!vote5"), TYPE_STRING)
	twitch_commands_direct = type_convert(twitch_commands.get("direct", "!direct"), TYPE_STRING)
	var twitch_panelists: = _get_or_make_dict(twitch, "panelists")
	twitch_panel_username_1 = type_convert(twitch_panelists.get("panel_username_1", ""), TYPE_STRING)
	twitch_panel_username_2 = type_convert(twitch_panelists.get("panel_username_2", ""), TYPE_STRING)
	twitch_panel_username_3 = type_convert(twitch_panelists.get("panel_username_3", ""), TYPE_STRING)
	twitch_panel_username_4 = type_convert(twitch_panelists.get("panel_username_4", ""), TYPE_STRING)
	twitch_panel_username_5 = type_convert(twitch_panelists.get("panel_username_5", ""), TYPE_STRING)
	twitch_panel_override_judge_names = type_convert(twitch_panelists.get("panel_override_judge_names", true), TYPE_BOOL)
	var twitch_chatter: = _get_or_make_dict(twitch, "chatter")
	twitch_chatter_on = type_convert(twitch_chatter.get("twitch_chatter_on", true), TYPE_BOOL)
	twitch_chatter_user_cooldown = type_convert(twitch_chatter.get("twitch_chatter_user_cooldown", 0), TYPE_INT)
	twitch_chatter_global_cooldown = type_convert(twitch_chatter.get("twitch_chatter_global_cooldown", 0), TYPE_INT)

	var dubmode: = _get_or_make_dict(settings, "dub_mode")
	dub_mode_clip_order_index = type_convert(dubmode.get("clip_order_index", 1), TYPE_INT)
	dub_mode_mute_backing_track = type_convert(dubmode.get("mute_backing_track", false), TYPE_BOOL)
	dub_mode_hard_mute_clips = type_convert(dubmode.get("hard_mute_clips", false), TYPE_BOOL)
	dub_mode_hard_no_captions = type_convert(dubmode.get("hard_no_captions", false), TYPE_BOOL)
	dub_mode_hard_one_take = type_convert(dubmode.get("hard_one_take", false), TYPE_BOOL)

	var dubcinema: = _get_or_make_dict(settings, "dub_cinema")
	dub_cinema_mute_audience = type_convert(dubcinema.get("mute_audience", false), TYPE_BOOL)
	dub_cinema_start_fullscreened = type_convert(dubcinema.get("start_fullscreened", false), TYPE_BOOL)
	dub_cinema_autoload_audience = type_convert(dubcinema.get("autoload_audience", true), TYPE_BOOL)

	var debug: = _get_or_make_dict(settings, "debug")
	debug_sample_timing = type_convert(debug.get("debug_sample_timing", 3), TYPE_INT)
	debug_countdown_type = type_convert(debug.get("debug_countdown_type", 0), TYPE_INT)
	debug_disable_fog = type_convert(debug.get("debug_disable_fog", false), TYPE_BOOL)


func _get_or_make_dict(input: Dictionary, key: String) -> Dictionary: return type_convert(input.get(key, {}), TYPE_DICTIONARY)


func export_data() -> Dictionary:
	var output: Dictionary = {
		"player": {"clips": {}, "ignored": {}}, 
		"custom": {}, 
		"settings": {
			"display": {}, 
			"match_settings": {}, 
			"clip_selection": {"voice_range": {}}, 
			"play_screen_visual_preferences": {}, 
			"volume": {}, 
			"mic": {"crust": {}, "devices": {}}, 
			"twitch": {"commands": {}, "panelists": {}, "chatter": {}}, 
			"dub_mode": {}, 
			"dub_cinema": {}, 
			"debug": {}
		}
	}
	output.version = M.GAME_VERSION

	output.player.first_time = first_time
	output.player.clips.seen = seen_clips_voice

	output.player.played_packs = played_packs

	output.player.ignored.ignored_packs_host = ignored_packs_host
	output.player.ignored.ignored_packs_judges = ignored_packs_judges
	output.player.ignored.ignored_packs_menu = ignored_packs_menu
	output.player.ignored.ignored_packs_studio = ignored_packs_studio
	output.player.ignored.ignored_packs_contestant = ignored_packs_contestant
	output.player.ignored.ignored_packs_voice = ignored_packs_voice

	output.player.ignored.ignored_packs_chatter = ignored_packs_chatter
	output.player.ignored.ignored_clips = ignored_clips
	output.player.ignored.hide_ignored = hide_ignored

	output.custom.host = host
	output.custom.judges = judges
	output.custom.menu = menu
	output.custom.studio = studio
	output.custom.player = contestant

	output.settings.display.window_resolution = window_resolution
	output.settings.display.window_mode = window_mode
	output.settings.display.snap_window_to_center = snap_window_to_center

	output.settings.match_settings.show_text_hints = show_captions
	output.settings.match_settings.hint_wait_time = caption_wait_time
	output.settings.match_settings.fully_mute_music = fully_mute_music
	output.settings.match_settings.easier_scoring = easier_scoring
	output.settings.match_settings.dual_player_playback = dual_player_playback
	output.settings.match_settings.faster_scoring_from_judges = faster_judge_scoring
	output.settings.match_settings.skip_host_post_record = skip_host_post_record
	output.settings.match_settings.skip_host_post_playback = skip_host_post_playback
	output.settings.match_settings.skip_host_post_scoring = skip_host_post_scoring
	output.settings.match_settings.show_clip_name = show_clip_file_name
	output.settings.match_settings.automatically_save_clips = automatically_save_clips
	output.settings.match_settings.countdown_time = countdown_time

	output.settings.clip_selection.uniform = uniform
	output.settings.clip_selection.shuffle = shuffle
	output.settings.clip_selection.start_from = start_from
	output.settings.clip_selection.voice_range.clip_range_on = clip_range_on
	output.settings.clip_selection.voice_range.min = clip_range_minimum
	output.settings.clip_selection.voice_range.max = clip_range_maximum
	output.settings.clip_selection.unseen_percent = unseen_percent
	output.settings.clip_selection.auto_tag_with_nested_folders = auto_tag_with_nested_folders

	output.settings.play_screen_visual_preferences.clip_preview_size = clip_preview_size
	output.settings.play_screen_visual_preferences.preview_images_per_row = preview_images_per_row
	output.settings.play_screen_visual_preferences.default_rounds = default_rounds
	output.settings.play_screen_visual_preferences.start_expanded = start_expanded
	output.settings.play_screen_visual_preferences.image_preview_cutoff = image_preview_cutoff

	output.settings.volume.master = volume_master
	output.settings.volume.music = volume_music
	output.settings.volume.sound_effects = volume_sfx
	output.settings.volume.button_sounds = volume_buttons
	output.settings.volume.clip_playback = volume_clip_playback
	output.settings.volume.voice_clips = volume_voice_clips
	output.settings.volume.player_recordings = volume_player_recordings
	output.settings.volume.chatter = volume_chatter

	output.settings.mic.devices.audio_in = audio_device_in
	output.settings.mic.devices.audio_out = audio_device_out

	output.settings.mic.crust.mic_crust_compressor_on = mic_crust_compressor_on
	output.settings.mic.crust.mic_crust_cutoff_on = mic_crust_cutoff_on
	output.settings.mic.crust.mic_crust_limiter_on = mic_crust_limiter_on
	output.settings.mic.crust.mic_crust_distortion_on = mic_crust_distortion_on
	output.settings.mic.crust.mic_crust_sample_rate_on = mic_crust_sample_rate_on
	output.settings.mic.crust.sample_rate = mic_crust_sample_rate_index
	output.settings.mic.crust.cutoff_low_pass = mic_crust_cutoff_low_pass
	output.settings.mic.crust.cutoff_high_pass = mic_crust_cutoff_high_pass
	output.settings.mic.crust.compressor_threshold = mic_crust_compressor_threshold
	output.settings.mic.crust.compressor_gain = mic_crust_compressor_gain
	output.settings.mic.crust.limiter_ceilingdb = mic_crust_limiter_ceilingdb
	output.settings.mic.crust.limiter_thresholddb = mic_crust_limiter_thresholddb
	output.settings.mic.crust.distortion_pre_gain = mic_crust_distortion_pre_gain
	output.settings.mic.crust.distortion_drive = mic_crust_distortion_drive
	output.settings.mic.crust.distortion_post_gain = mic_crust_distortion_post_gain
	output.settings.mic.crust.mic_input = mic_crust_mic_input
	output.settings.mic.crust.mic_multiplier = mic_crust_mic_multiplier

	output.settings.twitch.channel_name = twitch_channel_name
	output.settings.twitch.advanced_options = twitch_advanced_options
	output.settings.twitch.is_case_sensitive = twitch_is_case_sensitive
	output.settings.twitch.is_exact_phrase = twitch_is_exact_phrase
	output.settings.twitch.allow_duplicate_voting = twitch_allow_duplicate_voting
	output.settings.twitch.vote_type_is_binary = twitch_vote_type_is_binary
	output.settings.twitch.close_poll_votes_bool = twitch_close_poll_votes_bool
	output.settings.twitch.close_poll_inactivity_bool = twitch_close_poll_inactivity_bool

	output.settings.twitch.close_poll_votes_int = twitch_close_poll_votes_int
	output.settings.twitch.close_poll_inactivity_int = twitch_close_poll_inactivity_int
	output.settings.twitch.commands.binary_pass = twitch_commands_binary_pass
	output.settings.twitch.commands.binary_fail = twitch_commands_binary_fail
	output.settings.twitch.commands.score_0 = twitch_commands_score_0
	output.settings.twitch.commands.score_1 = twitch_commands_score_1
	output.settings.twitch.commands.score_2 = twitch_commands_score_2
	output.settings.twitch.commands.score_3 = twitch_commands_score_3
	output.settings.twitch.commands.score_4 = twitch_commands_score_4
	output.settings.twitch.commands.score_5 = twitch_commands_score_5
	output.settings.twitch.commands.direct = twitch_commands_direct

	output.settings.twitch.panelists.panel_username_1 = twitch_panel_username_1
	output.settings.twitch.panelists.panel_username_2 = twitch_panel_username_2
	output.settings.twitch.panelists.panel_username_3 = twitch_panel_username_3
	output.settings.twitch.panelists.panel_username_4 = twitch_panel_username_4
	output.settings.twitch.panelists.panel_username_5 = twitch_panel_username_5
	output.settings.twitch.panelists.panel_override_judge_names = twitch_panel_override_judge_names

	output.settings.twitch.chatter.twitch_chatter_on = twitch_chatter_on
	output.settings.twitch.chatter.twitch_chatter_user_cooldown = twitch_chatter_user_cooldown
	output.settings.twitch.chatter.twitch_chatter_global_cooldown = twitch_chatter_global_cooldown

	output.settings.dub_mode.clip_order_index = dub_mode_clip_order_index
	output.settings.dub_mode.mute_backing_track = dub_mode_mute_backing_track
	output.settings.dub_mode.hard_mute_clips = dub_mode_hard_mute_clips
	output.settings.dub_mode.hard_no_captions = dub_mode_hard_no_captions
	output.settings.dub_mode.hard_one_take = dub_mode_hard_one_take

	output.settings.dub_cinema.mute_audience = dub_cinema_mute_audience
	output.settings.dub_cinema.start_fullscreened = dub_cinema_start_fullscreened
	output.settings.dub_cinema.autoload_audience = dub_cinema_autoload_audience

	output.settings.debug.debug_sample_timing = debug_sample_timing
	output.settings.debug.debug_countdown_type = debug_countdown_type
	output.settings.debug.debug_disable_fog = debug_disable_fog

	return output



func clip_include(clip: OmniClip) -> void :
	while ignored_clips.has(clip.seen_path): ignored_clips.remove_at(ignored_clips.find(clip.seen_path))
func clip_exclude(clip: OmniClip) -> void :
	if !ignored_clips.has(clip.seen_path): ignored_clips.append(clip.seen_path)



func _set_clip_range_on(value: bool) -> void : clip_range_on = value;changed_clip_filtering.emit()
func _set_clip_range_minimum(value: float) -> void : clip_range_minimum = value;changed_clip_filtering.emit()
func _set_clip_range_maximum(value: float) -> void : clip_range_maximum = value;changed_clip_filtering.emit()
func _set_unseen_percent(value: int) -> void : unseen_percent = value;changed_clip_filtering.emit()
func _set_shuffle(value: int) -> void : shuffle = value
func _set_default_rounds(value: int) -> void : default_rounds = value


func _set_window_resolution(value: int) -> void :
	var attempt_recentering: bool = window_resolution != value
	window_resolution = value;DisplayManager.change_window_resolution(window_resolution, attempt_recentering)
func _set_window_mode(value: int) -> void : window_mode = value;DisplayManager.change_window_mode(window_mode)

func _set_show_captions(value: bool) -> void : show_captions = value
func _set_fully_mute_music(value: bool) -> void : fully_mute_music = value
func _set_faster_judge_scoring(value: bool) -> void : faster_judge_scoring = value
func _set_skip_host_post_record(value: bool) -> void : skip_host_post_record = value
func _set_skip_host_post_playback(value: bool) -> void : skip_host_post_playback = value
func _set_skip_host_post_scoring(value: bool) -> void : skip_host_post_scoring = value
func _set_show_clip_file_name(value: bool) -> void : show_clip_file_name = value

func _set_volume_master(value: float) -> void : volume_master = value;VolumeService.base_volume_master = volume_master
func _set_volume_music(value: float) -> void : volume_music = value;VolumeService.base_volume_music = volume_music
func _set_volume_sfx(value: float) -> void : volume_sfx = value;VolumeService.base_volume_sfx = volume_sfx
func _set_volume_buttons(value: float) -> void : volume_buttons = value;VolumeService.base_volume_buttons = volume_buttons
func _set_volume_voice_clips(value: float) -> void : volume_voice_clips = value;VolumeService.base_volume_voice = volume_voice_clips
func _set_volume_player_recordings(value: float) -> void : volume_player_recordings = value;VolumeService.base_volume_recordings = volume_player_recordings
func _set_volume_clip_playback(value: float) -> void : volume_clip_playback = value;VolumeService.base_volume_playback = volume_clip_playback
func _set_volume_chatter(value: float) -> void : volume_chatter = value;VolumeService.base_volume_chatter = volume_chatter

func _set_audio_device_in(value: String) -> void : audio_device_in = value;AudioServer.input_device = audio_device_in if AudioServer.get_input_device_list().has(audio_device_in) else "Default"
func _set_audio_device_out(value: String) -> void : audio_device_out = value;AudioServer.output_device = audio_device_out if AudioServer.get_output_device_list().has(audio_device_out) else "Default"

func _set_mic_delay(value: float) -> void : mic_delay = value;GMCrust.mic_delay = mic_delay
func _set_mic_crust_compressor_on(value: bool) -> void : mic_crust_compressor_on = value;GMCrust.mic_crust_compressor_on = mic_crust_compressor_on
func _set_mic_crust_cutoff_on(value: bool) -> void : mic_crust_cutoff_on = value;GMCrust.mic_crust_cutoff_on = mic_crust_cutoff_on
func _set_mic_crust_limiter_on(value: bool) -> void : mic_crust_limiter_on = value;GMCrust.mic_crust_limiter_on = mic_crust_limiter_on
func _set_mic_crust_distortion_on(value: bool) -> void : mic_crust_distortion_on = value;GMCrust.mic_crust_distortion_on = mic_crust_distortion_on
func _set_mic_crust_sample_rate_on(value: bool) -> void : mic_crust_sample_rate_on = value;GMCrust.mic_crust_sample_rate_on = mic_crust_sample_rate_on
func _set_mic_crust_sample_rate_index(value: int) -> void : mic_crust_sample_rate_index = value;GMCrust.mic_crust_sample_rate_index = mic_crust_sample_rate_index
func _set_mic_crust_cutoff_low_pass(value: int) -> void : mic_crust_cutoff_low_pass = value;GMCrust.mic_crust_cutoff_low_pass = mic_crust_cutoff_low_pass
func _set_mic_crust_cutoff_high_pass(value: int) -> void : mic_crust_cutoff_high_pass = value;GMCrust.mic_crust_cutoff_high_pass = mic_crust_cutoff_high_pass
func _set_mic_crust_compressor_threshold(value: float) -> void : mic_crust_compressor_threshold = value;GMCrust.mic_crust_compressor_threshold = mic_crust_compressor_threshold
func _set_mic_crust_compressor_gain(value: float) -> void : mic_crust_compressor_gain = value;GMCrust.mic_crust_compressor_gain = mic_crust_compressor_gain
func _set_mic_crust_limiter_ceilingdb(value: float) -> void : mic_crust_limiter_ceilingdb = value;GMCrust.mic_crust_limiter_ceilingdb = mic_crust_limiter_ceilingdb
func _set_mic_crust_limiter_thresholddb(value: float) -> void : mic_crust_limiter_thresholddb = value;GMCrust.mic_crust_limiter_thresholddb = mic_crust_limiter_thresholddb
func _set_mic_crust_distortion_pre_gain(value: float) -> void : mic_crust_distortion_pre_gain = value;GMCrust.mic_crust_distortion_pre_gain = mic_crust_distortion_pre_gain
func _set_mic_crust_distortion_drive(value: float) -> void : mic_crust_distortion_drive = value;GMCrust.mic_crust_distortion_drive = mic_crust_distortion_drive
func _set_mic_crust_distortion_post_gain(value: float) -> void : mic_crust_distortion_post_gain = value;GMCrust.mic_crust_distortion_post_gain = mic_crust_distortion_post_gain
func _set_mic_crust_mic_input(value: float) -> void : mic_crust_mic_input = value;GMCrust.mic_crust_mic_input = mic_crust_mic_input * mic_crust_mic_multiplier
func _set_mic_crust_mic_multiplier(value: float) -> void : mic_crust_mic_multiplier = value;GMCrust.mic_crust_mic_input = mic_crust_mic_input * mic_crust_mic_multiplier

func _set_twitch_channel_name(value: String) -> void : twitch_channel_name = value
func _set_twitch_advanced_options(value: bool) -> void : twitch_advanced_options = value
func _set_twitch_is_case_sensitive(value: bool) -> void : twitch_is_case_sensitive = value
func _set_twitch_is_exact_phrase(value: bool) -> void : twitch_is_exact_phrase = value
func _set_twitch_allow_duplicate_voting(value: bool) -> void : twitch_allow_duplicate_voting = value
func _set_twitch_vote_type_is_binary(value: bool) -> void : twitch_vote_type_is_binary = value
func _set_twitch_close_poll_votes_bool(value: bool) -> void : twitch_close_poll_votes_bool = value
func _set_twitch_close_poll_inactivity_bool(value: bool) -> void : twitch_close_poll_inactivity_bool = value

func _set_twitch_close_poll_votes_int(value: int) -> void : twitch_close_poll_votes_int = value
func _set_twitch_close_poll_inactivity_int(value: int) -> void : twitch_close_poll_inactivity_int = value
func _set_twitch_commands_binary_pass(value: String) -> void : twitch_commands_binary_pass = value
func _set_twitch_commands_binary_fail(value: String) -> void : twitch_commands_binary_fail = value
func _set_twitch_commands_score_0(value: String) -> void : twitch_commands_score_0 = value
func _set_twitch_commands_score_1(value: String) -> void : twitch_commands_score_1 = value
func _set_twitch_commands_score_2(value: String) -> void : twitch_commands_score_2 = value
func _set_twitch_commands_score_3(value: String) -> void : twitch_commands_score_3 = value
func _set_twitch_commands_score_4(value: String) -> void : twitch_commands_score_4 = value
func _set_twitch_commands_score_5(value: String) -> void : twitch_commands_score_5 = value
