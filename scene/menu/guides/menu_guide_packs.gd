extends MenuBase


@onready var pages: MarginContainer = %Pages
@onready var btn_folder: ButtonCV = %BtnFolder

var current_page_index: int = 0

func _ready() -> void :
	_on_array_page_selection_selection(0)


func _on_array_page_selection_selection(index: int) -> void :
	current_page_index = index
	for child_index: int in pages.get_child_count():
		pages.get_child(child_index).visible = child_index == index



func _on_btn_folder_button_clicked() -> void :
	match current_page_index:
		0, 1, 2: OS.shell_open(ProjectSettings.globalize_path("user://game/packs_voice"))

		3: OS.shell_open(ProjectSettings.globalize_path("user://game/packs_menu"))
		4: OS.shell_open(ProjectSettings.globalize_path("user://game/packs_player"))
		5: OS.shell_open(ProjectSettings.globalize_path("user://game/packs_studio"))
		6: OS.shell_open(ProjectSettings.globalize_path("user://game/packs_judges"))
		7: OS.shell_open(ProjectSettings.globalize_path("user://game/packs_host"))
		8: OS.shell_open(ProjectSettings.globalize_path(FileManager.MODPACKS_CHATTER))
