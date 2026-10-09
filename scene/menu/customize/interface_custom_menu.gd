extends OveepCustomizeInterface


@onready var btn_array_background: ButtonArray = %BtnArrayBackground
@onready var btn_array_overlay = %BtnArrayBorder
@onready var btn_array_letterbox = %BtnArrayLetterbox
@onready var clr_letterbox_1 = %ClrLetterbox1
@onready var clr_letterbox_2 = %ClrLetterbox2
@onready var btn_array_top_gradient = %BtnArrayTopGradient
@onready var clr_top_gradient = %ClrTopGradient
@onready var btn_array_bottom_gradient = %BtnArrayBottomGradient
@onready var clr_bottom_gradient = %ClrBottomGradient
@onready var btn_array_circles = %BtnArrayCircles
@onready var clr_circles = %ClrCircles
@onready var btn_array_waves = %BtnArrayWaves
@onready var clr_waves = %ClrWaves
@onready var btn_array_buttons = %BtnArrayButtons
@onready var clr_buttons_1 = %ClrButtons1
@onready var clr_buttons_2 = %ClrButtons2
@onready var btn_array_disc = %BtnArrayDisc
@onready var clr_spin_disc = %ClrSpinDisc

@onready var spin_horizontal = %SpinHorizontal
@onready var spin_vertical = %SpinVertical

@onready var menu_config_panel = %MenuConfigPanel
@onready var overview = %Overview
@onready var options = %Options
@onready var img_unseen_image = %ImgUnseenImage
@onready var img_no_image = %ImgNoImage

@onready var btn_save_changes = %BtnSaveChanges
@onready var btn_revert_changes = %BtnRevertChanges

var image_theseus: Texture2D
var button_selected_page: int = 0
var background_view_toggle_state: int = 0
var editing: bool = true


func _ready() -> void :
	add_child(uc)

func LoadPack(pack_name: String = M.data.custom.menu):
	Profile.menu = pack_name

	theseus_config = (uc.get_json(M.OVEEP.MENU, "config_menu")).duplicate(true)
	TheseusToNodes()
	TheseusToBackground()
	img_unseen_image.texture = uc.get_image(M.OVEEP.MENU, "unseen_image", true, Vector2i(96, 96))
	img_no_image.texture = uc.get_image(M.OVEEP.MENU, "no_image", true, Vector2i(96, 96))
	get_tree().call_group("MenuMusic", "UpdateMusic")
	visible = pack_name != "Default"


func TheseusToNodes() -> void :
	btn_array_background.set_selected = (theseus_config.background.image.use_type)
	btn_array_overlay.set_selected = int( not theseus_config.background.overlay.on)
	btn_array_letterbox.set_selected = int( not theseus_config.background.letterbox.on)
	clr_letterbox_1.color = Color.html(theseus_config.background.letterbox.color)
	clr_letterbox_2.color = Color.html(theseus_config.background.letterbox.accent)
	btn_array_top_gradient.set_selected = int( not theseus_config.background.top_gradient.on)
	clr_top_gradient.color = Color.html(theseus_config.background.top_gradient.color)
	btn_array_bottom_gradient.set_selected = int( not theseus_config.background.bottom_gradient.on)
	clr_bottom_gradient.color = Color.html(theseus_config.background.bottom_gradient.color)
	btn_array_circles.set_selected = int( not theseus_config.background.circles.on)
	clr_circles.color = Color.html(theseus_config.background.circles.color)
	btn_array_buttons.set_selected = int(theseus_config.ui.button.invert)
	clr_buttons_1.color = Color.html(theseus_config.ui.button.color1)
	clr_buttons_2.color = Color.html(theseus_config.ui.button.color2)
	btn_array_waves.set_selected = int( not theseus_config.background.waves.on)
	clr_waves.color = Color.html(theseus_config.background.waves.color)
	btn_array_disc.set_selected = theseus_config.background.clip_disc.state
	clr_spin_disc.color = Color.html(theseus_config.background.clip_disc.color)

	spin_horizontal.value = theseus_config.background.image.scroll.x
	spin_vertical.value = theseus_config.background.image.scroll.y
	_toggle_scroll_spinboxes(theseus_config.background.image.use_type == 0)


func NodesToTheseus() -> void :
	theseus_config.background.image.use_type = (btn_array_background.selected)
	theseus_config.background.overlay.on = not bool(btn_array_overlay.selected)
	theseus_config.background.letterbox.on = not bool(btn_array_letterbox.selected)
	theseus_config.background.letterbox.color = (clr_letterbox_1.color).to_html(false)
	theseus_config.background.letterbox.accent = (clr_letterbox_2.color).to_html(false)
	theseus_config.background.top_gradient.on = not bool(btn_array_top_gradient.selected)
	theseus_config.background.top_gradient.color = (clr_top_gradient.color).to_html()
	theseus_config.background.bottom_gradient.on = not bool(btn_array_bottom_gradient.selected)
	theseus_config.background.bottom_gradient.color = (clr_bottom_gradient.color).to_html()
	theseus_config.background.circles.on = not bool(btn_array_circles.selected)
	theseus_config.background.circles.color = (clr_circles.color).to_html()
	theseus_config.ui.button.invert = bool(btn_array_buttons.selected)
	theseus_config.ui.button.color1 = (clr_buttons_1.color).to_html()
	theseus_config.ui.button.color2 = (clr_buttons_2.color).to_html()
	theseus_config.background.waves.on = not bool(btn_array_waves.selected)
	theseus_config.background.waves.color = (clr_waves.color).to_html()
	theseus_config.background.clip_disc.state = btn_array_disc.selected
	theseus_config.background.clip_disc.color = (clr_spin_disc.color).to_html()

	theseus_config.background.image.scroll.x = spin_horizontal.value
	theseus_config.background.image.scroll.y = spin_vertical.value
	_toggle_scroll_spinboxes(theseus_config.background.image.use_type == 0)
	TheseusToBackground()


func TheseusToBackground() -> void :

	get_tree().call_group("ModularBackground", "AssignBackground", theseus_config.background.image)
	get_tree().call_group("ModularBackground", "AssignBorder", theseus_config.background.overlay)
	get_tree().call_group("ModularBackground", "AssignLetterbox", theseus_config.background.letterbox)
	get_tree().call_group("ModularBackground", "AssignTopGradient", theseus_config.background.top_gradient)
	get_tree().call_group("ModularBackground", "AssignBottomGradient", theseus_config.background.bottom_gradient)
	get_tree().call_group("ModularBackground", "AssignCircles", theseus_config.background.circles)
	get_tree().call_group("ModularBackground", "AssignWaves", theseus_config.background.waves)
	get_tree().call_group("ModularBackground", "AssignSpinDisc", theseus_config.background.clip_disc)
	get_tree().call_group("ModularBackground", "AssignVideo", theseus_config.audio)
	M.ChangeButtonProfiles(theseus_config.ui)
	get_tree().call_group("ButtonBase", "UpdatePalette")


func SaveConfig():

	uc.save_json_config(M.OVEEP.MENU, "config_menu", theseus_config)



func _on_btn_view_background_button_clicked():
	background_view_toggle_state = (background_view_toggle_state + 1) % 3
	match background_view_toggle_state:
		0:
			get_parent().get_parent().get_parent().get_parent().ShowBackground()
			menu_config_panel.visible = true
		1:
			get_parent().get_parent().get_parent().get_parent().ShowBackground()
		2:
			menu_config_panel.visible = false

func _on_btn_revert_changes_button_clicked():
	LoadPack()

func _on_btn_save_changes_button_clicked():
	SaveConfig()


func _on_btn_array_selection(_index):
	call_deferred("NodesToTheseus")


func _on_clr_color_changed(_color):
	call_deferred("NodesToTheseus")


func _on_judges_tabs_selection(index):
	overview.visible = (index == 0)
	options.visible = (index == 1)


func _on_btn_play_select_button_clicked():
	M.sfx_select.play()

func _on_btn_play_back_button_clicked():
	M.sfx_back.play()

func _on_btn_play_decrease_button_clicked():
	M.sfx_decrease.play()

func _on_btn_play_hover_button_clicked():
	M.sfx_hover.play()


func _on_spin_value_changed(_value):
	call_deferred("NodesToTheseus")


func _toggle_scroll_spinboxes(toggle_on: bool) -> void :
	spin_horizontal.editable = toggle_on
	spin_vertical.editable = toggle_on
