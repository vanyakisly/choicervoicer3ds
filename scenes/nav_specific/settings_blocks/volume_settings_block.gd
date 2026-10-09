class_name SettingsBlockVolumes extends GridContainer


@onready var lbl_volume_master: Label = %LblVolumeMaster
@onready var lbl_volume_music: Label = %LblVolumeMusic
@onready var lbl_volume_voice: Label = %LblVolumeVoice
@onready var lbl_volume_sound_effects: Label = %LblAllSoundEffects
@onready var lbl_volume_button_sounds: Label = %LblButtonSfx
@onready var lbl_volume_sfx_judges: Label = %LblJudgesSfx
@onready var lbl_volume_clip_playback: Label = %LblClipPlayback
@onready var lbl_volume_chatter: Label = %LblChatter


@onready var slider_volume_master: HSlider = %SliderMaster
@onready var slider_volume_music: HSlider = %SliderMusic
@onready var slider_volume_voice: HSlider = %SliderVoice
@onready var slider_volume_sound_effects: HSlider = %SliderAllSoundEffects
@onready var slider_volume_button_sounds: HSlider = %SliderButtonSfx
@onready var slider_volume_sfx_judges: HSlider = %SliderJudgesSfx
@onready var slider_volume_clip_playback: HSlider = %SliderClipPlayback
@onready var slider_volume_chatter: HSlider = %SliderChatter






func _ready() -> void :
	_connect_signals()
	_onready_slider_match()
	_update_labels()


func _connect_signals() -> void :


	slider_volume_master.value_changed.connect(Profile._set_volume_master)
	slider_volume_music.value_changed.connect(Profile._set_volume_music)
	slider_volume_voice.value_changed.connect(Profile._set_volume_voice_clips)
	slider_volume_sound_effects.value_changed.connect(Profile._set_volume_sfx)
	slider_volume_button_sounds.value_changed.connect(Profile._set_volume_buttons)

	slider_volume_clip_playback.value_changed.connect(Profile._set_volume_clip_playback)
	slider_volume_chatter.value_changed.connect(Profile._set_volume_chatter)

	slider_volume_master.value_changed.connect(_update_labels)
	slider_volume_music.value_changed.connect(_update_labels)
	slider_volume_voice.value_changed.connect(_update_labels)
	slider_volume_sound_effects.value_changed.connect(_update_labels)
	slider_volume_button_sounds.value_changed.connect(_update_labels)
	slider_volume_sfx_judges.value_changed.connect(_update_labels)
	slider_volume_clip_playback.value_changed.connect(_update_labels)
	slider_volume_chatter.value_changed.connect(_update_labels)


func _onready_slider_match() -> void :
	slider_volume_master.set_value_no_signal(Profile.volume_master)
	slider_volume_music.set_value_no_signal(Profile.volume_music)
	slider_volume_voice.set_value_no_signal(Profile.volume_voice_clips)
	slider_volume_sound_effects.set_value_no_signal(Profile.volume_sfx)
	slider_volume_button_sounds.set_value_no_signal(Profile.volume_buttons)

	slider_volume_clip_playback.set_value_no_signal(Profile.volume_clip_playback)
	slider_volume_chatter.set_value_no_signal(Profile.volume_chatter)

func _update_labels(_dummy: float = 0.0) -> void :
	lbl_volume_master.text = "%1.0f%%" % [Profile.volume_master * 100.0];lbl_volume_master.add_theme_color_override("font_color", Color.ORANGE) if (Profile.volume_master > 1.01) else lbl_volume_master.add_theme_color_override("font_color", Color.WHITE)
	lbl_volume_music.text = "%1.0f%%" % [Profile.volume_music * 100.0];lbl_volume_music.add_theme_color_override("font_color", Color.ORANGE) if (Profile.volume_music > 1.01) else lbl_volume_music.add_theme_color_override("font_color", Color.WHITE)
	lbl_volume_voice.text = "%1.0f%%" % [Profile.volume_voice_clips * 100.0];lbl_volume_voice.add_theme_color_override("font_color", Color.ORANGE) if (Profile.volume_voice_clips > 1.01) else lbl_volume_voice.add_theme_color_override("font_color", Color.WHITE)
	lbl_volume_sound_effects.text = "%1.0f%%" % [Profile.volume_sfx * 100.0];lbl_volume_sound_effects.add_theme_color_override("font_color", Color.ORANGE) if (Profile.volume_sfx > 1.01) else lbl_volume_sound_effects.add_theme_color_override("font_color", Color.WHITE)
	lbl_volume_button_sounds.text = "%1.0f%%" % [Profile.volume_buttons * 100.0];lbl_volume_button_sounds.add_theme_color_override("font_color", Color.ORANGE) if (Profile.volume_buttons > 1.01) else lbl_volume_button_sounds.add_theme_color_override("font_color", Color.WHITE)

	lbl_volume_clip_playback.text = "%1.0f%%" % [Profile.volume_clip_playback * 100.0];lbl_volume_clip_playback.add_theme_color_override("font_color", Color.ORANGE) if (Profile.volume_clip_playback > 1.01) else lbl_volume_clip_playback.add_theme_color_override("font_color", Color.WHITE)
	lbl_volume_chatter.text = "%1.0f%%" % [Profile.volume_chatter * 100.0];lbl_volume_chatter.add_theme_color_override("font_color", Color.ORANGE) if (Profile.volume_chatter > 1.01) else lbl_volume_chatter.add_theme_color_override("font_color", Color.WHITE)
