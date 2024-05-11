extends VBoxContainer

@onready var mainButton: MenuButton = %MainButton
@onready var popupMenu: PopupMenu = mainButton.get_popup()

# TODO: Make popupMenu update items over time

func _ready() -> void:
	mainButton.text = UserGlobalState.user_name + " (" + UserGlobalState.os_name + ")"
	mainButton.icon = UserGlobalState.user_icon
	
	for ip: String in NetworkGlobalState.self_ips:
		popupMenu.add_item(ip)

func _process(_delta: float) -> void:
	if !Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		popupMenu.hide()
		
