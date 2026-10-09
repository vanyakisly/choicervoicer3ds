extends MenuBase


@onready var btn_play: ButtonCV = %BtnPlay
@onready var lbl_demo_only_advisory: RichTextLabel = %LblDemoOnlyAdvisory

@onready var btn_updates: ButtonCV = $BtnUpdates
@onready var version_update_info: ColorRect = %VersionUpdateInfo
@onready var version_update_list: VBoxContainer = %VersionUpdateList
@onready var lbl_ref: Label = %LblRef


func _ready() -> void :
	lbl_demo_only_advisory.visible = M.THISISDEMO
	btn_updates.visible = !M.newer_versions.is_empty()
	version_update_info.hide()
	_create_version_update_list()


func _toggle_version_update_visibility() -> void : version_update_info.visible = !version_update_info.visible
func _create_version_update_list() -> void :
	if M.newer_versions.is_empty(): return
	for i: int in range(M.newer_versions.size() - 1, -1, -1):
		var version: Dictionary = M.newer_versions[i]
		var lbl_version = lbl_ref.duplicate()
		lbl_version.text = "Version " + version.get("version", "");version_update_list.add_child(lbl_version)
		for line: String in version.get("changes", []):
			var new_lbl: Label = lbl_ref.duplicate()
			new_lbl.text = "  • " + line
			new_lbl.add_theme_font_size_override("font_size", 16)
			version_update_list.add_child(new_lbl)
		var b: = Control.new()
		b.custom_minimum_size.y = 48
		version_update_list.add_child(b)


func _on_btn_play_button_clicked():
	call_slide("play/play_options/menu_play_options")


func _on_btn_customize_button_clicked():
	call_slide("customize/menu_customize")


func _on_btn_open_game_button_clicked():
	OS.shell_open(ProjectSettings.globalize_path("user://game"))


func _on_btn_settings_button_clicked():

	call_slide("settings/menu_settings_cleaner")


func _on_btn_data_management_button_clicked():
	call_slide("data_management/menu_data_management")


func _on_btn_extras_button_clicked():
	call_slide("extras/menu_extras")


func _on_btn_help_button_clicked():
	call_slide("help/menu_help")


func _on_btn_pack_guides_button_clicked() -> void :
	call_slide("guides/menu_guide_packs")


func _on_btn_credits_button_clicked() -> void :
	call_slide("extras/menu_credits_new")


func _on_btn_play_new_button_clicked() -> void :
	call_slide("res://scenes/nav_specific/play_flow/select_member_count.tscn", false)
