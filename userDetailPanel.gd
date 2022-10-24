extends Panel

var default_icon:CompressedTexture2D = load("res://icon.png")

@export var icon: Texture2D:
	get:
		return %UserIcon.texture
	set(tex):
		%UserIcon.texture = tex

@export var user_name: String:
	get:
		return %Username.text
	set(username):
		%Username.text = username

func _ready():
	user_name = "Godot"
	icon = default_icon
