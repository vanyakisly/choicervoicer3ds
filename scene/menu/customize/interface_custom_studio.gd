extends OveepCustomizeInterface

const NO_MODEL_TEXT: String = "⚠️Note: This pack has no custom studio model."
const ONLY_TEMPLATE_TEXT: String = "⚠️Note: This pack has an unused template model."

@onready var recording_body_simulator: ColorRect = %RecordingBodySimulator
@onready var clr_recording_overlay: ColorPickerButton = %ClrRecordingOverlay
@onready var clr_clip_waveform: ColorPickerButton = %ClrClipWaveform
@onready var clr_player_waveform: ColorPickerButton = %ClrPlayerWaveform
@onready var clr_waveform_border: ColorPickerButton = %ClrWaveformBorder
@onready var clr_playbar: ColorPickerButton = %ClrPlaybar
@onready var clr_recording_light: ColorPickerButton = %ClrRecordingLight

@onready var waveform_mantle = %WaveformMantle

@onready var btn_save_changes: ButtonCV = %BtnSaveChanges

@onready var lbl_no_studio_model_warning: Label = %LblNoStudioModelWarning

var mantle_filler_data: PackedByteArray = [
	255, 255, 255, 255, 255, 239, 223, 207, 191, 175, 
	128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 
	128, 128, 112, 96, 80, 64, 64, 64, 64, 64, 
	64, 64, 64, 64, 64, 56, 48, 40, 32, 24, 
	16, 16, 16, 8, 8, 8, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0]


func _ready() -> void :
	add_child(uc)


func LoadPack(pack_name: String = Profile.studio_slash):
	if !pack_name.ends_with("/"): pack_name += "/"
	if (pack_name == "Default/" or FileAccess.file_exists(FileManager.MODPACKS_STUDIO + pack_name + "model.glb") or FileAccess.file_exists(FileManager.MODPACKS_STUDIO + pack_name + "model.gltf")):
		lbl_no_studio_model_warning.text = ""
	else:
		if FileAccess.file_exists(FileManager.MODPACKS_STUDIO + pack_name + "model_template.glb") or FileAccess.file_exists(FileManager.MODPACKS_STUDIO + pack_name + "model_template.gltf"):
			lbl_no_studio_model_warning.text = ONLY_TEMPLATE_TEXT
		else: lbl_no_studio_model_warning.text = NO_MODEL_TEXT


	Profile.studio = pack_name
	theseus_config = (uc.get_json(M.OVEEP.STUDIO, "config_studio")).duplicate(true)
	TheseusToNodes()

	visible = (pack_name != "Default/")
	waveform_mantle.AssignVclipLength(1.0)
	waveform_mantle.waveform_core.vclip_drawer.vclip_history_avg = mantle_filler_data
	var rev: PackedByteArray = mantle_filler_data.duplicate()
	rev.reverse()
	waveform_mantle.waveform_core.plmic_drawer.plmic_history_avg = rev
	waveform_mantle.waveform_core.queue_redraw()


func TheseusToNodes() -> void :
	clr_recording_overlay.color = Color.html(theseus_config.recording_overlay_colors.body)
	recording_body_simulator.color = Color.html(theseus_config.recording_overlay_colors.body)
	clr_clip_waveform.color = Color.html(theseus_config.recording_overlay_colors.voice_color)
	clr_player_waveform.color = Color.html(theseus_config.recording_overlay_colors.user_color)
	clr_waveform_border.color = Color.html(theseus_config.recording_overlay_colors.block_border)
	clr_playbar.color = Color.html(theseus_config.recording_overlay_colors.playbar)
	clr_recording_light.color = Color.html(theseus_config.recording_overlay_colors.record_light)
	waveform_mantle.Colorize(theseus_config.recording_overlay_colors)
	waveform_mantle.waveform_core.queue_redraw()



func NodesToTheseus() -> void :
	theseus_config.recording_overlay_colors.body = (clr_recording_overlay.color).to_html(false)
	theseus_config.recording_overlay_colors.voice_color = (clr_clip_waveform.color).to_html(false)
	theseus_config.recording_overlay_colors.user_color = (clr_player_waveform.color).to_html(false)
	theseus_config.recording_overlay_colors.block_border = (clr_waveform_border.color).to_html(false)
	theseus_config.recording_overlay_colors.playbar = (clr_playbar.color).to_html(false)

	theseus_config.recording_overlay_colors.record_light = (clr_recording_light.color).to_html(false)
	var crm: Color = clr_recording_light.color
	theseus_config.recording_overlay_colors.record_backlight = (Color.from_hsv(crm.h, crm.s / 2.0, crm.v)).to_html(false)

	waveform_mantle.Colorize(theseus_config.recording_overlay_colors)
	waveform_mantle.waveform_core.queue_redraw()
	recording_body_simulator.color = Color.html(theseus_config.recording_overlay_colors.body)


func SaveConfig():
	uc.save_json_config(M.OVEEP.STUDIO, "config_studio", theseus_config)




func _on_btn_save_changes_button_clicked():
	SaveConfig()

func _on_btn_revert_changes_button_clicked():
	LoadPack()


func _on_clr_color_changed(_color):
	call_deferred("NodesToTheseus")
