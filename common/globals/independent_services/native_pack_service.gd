extends Node



enum NATIVE_PACK_NAMES{
	TEST, 
	HUHH, 
	CHATTER_CLAP, 
}


const NATIVE_NAME_CHATTER_CLAPPING: String = "/native:Clap"


const NATIVE_CHATTER_PACKS: PackedStringArray = [
	NATIVE_NAME_CHATTER_CLAPPING
]




func get_native_chatter_pack(pack_name: String) -> PackChatter:
	match pack_name:
		NATIVE_NAME_CHATTER_CLAPPING:
			var pack: PackChatter = load("res://assets_gd/resources/packs/chatter/pack_core_chatter.tres")
			pack.native_name = NATIVE_NAME_CHATTER_CLAPPING;return pack
		_: return null
