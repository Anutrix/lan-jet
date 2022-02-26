extends Panel

@export var username: String:
	get:
		return $UserDetailPanel/Username.text
	set(username):
		$UserDetailPanel/Username.text = username

@export var user_icon: Texture2D:
	get:
		return $UserDetailPanel/UserIcon.texture
	set(tex):
		$UserDetailPanel/UserIcon.texture = tex

#
#func _init(username = "A"):
#	$UserDetailPanel/Username.text = username

func _ready():
	pass

func _process(_delta):
	pass
