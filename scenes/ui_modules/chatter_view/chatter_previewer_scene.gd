class_name ChatterPreviewerScene extends Control


@onready var pack_icon: TextureRect = %PackIcon
@onready var lbl_pack_name: Label = %LblPackName
@onready var lbl_pack_authors: Label = %LblPackAuthors
@onready var chatter_previewer: ChatterPreviewer = %ChatterPreviewer





func set_pack(pack: PackChatter) -> void :
	pack_icon.texture = pack.icon
	pack_icon.custom_minimum_size.x = 96 if pack.icon else 0
	lbl_pack_name.text = pack.display_name
	if pack.authors: lbl_pack_authors.text = "by %s" % ", ".join(pack.authors)
	else: lbl_pack_authors.text = ""
	chatter_previewer.pack = pack
