extends Resource
class_name MenuData

enum SLIDETYPE{NORMAL, HOME, SETTINGS, HAS_OPTIONS}

@export var back_path: StringName
@export var slide_hint: PackedStringArray
@export var type: SLIDETYPE
@export var assume_path: bool = true
