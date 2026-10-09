extends MenuBase
func set_metro_members_as_solo() -> void : var solo_member: = BasicPlayerPackage.new(Profile.contestant, Profile.audio_device_in);Metro.current_players = [solo_member]
func metro_backpath_solo() -> void : Metro.clip_selection_page_back_path = "res://scenes/nav_specific/play_flow/select_game_mode_solo.tscn"
func metro_backpath_group() -> void : Metro.clip_selection_page_back_path = "res://scenes/nav_specific/play_flow/select_game_mode_group.tscn"
func choose_solo() -> void : metro_backpath_solo();set_metro_members_as_solo();call_slide("res://scenes/nav_specific/play_flow/select_game_mode_solo.tscn", false)
func choose_group() -> void : metro_backpath_group();call_slide("res://scenes/nav_specific/play_flow/select_members.tscn", false)
