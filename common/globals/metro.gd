extends Node
@export var gameplay_resource_dub_mode: GameplayResourceDubMode
@export var current_players: Array[BasicPlayerPackage]
@export var clip_selection_page_back_path: String
@export var gameplay_omniclip_set: Array[OmniClip]
@export var judge_master_uses_panelists: bool = false

var coroutine_password_omniclip_collection: int
var coroutine_password_pack_weighted_selector: int

var cinema_from_dub_mode: String
var cinema_came_from_dub_mode: bool = false
var cinema_name: PackedStringArray = []
