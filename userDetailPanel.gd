extends Panel

var default_icon:CompressedTexture2D = load("res://icon.png")
var os_name: String = ""

@export var user_icon: Texture2D:
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
	os_name = OS.get_name()
	
	if OS.has_environment("USERNAME"):
		user_name = OS.get_environment("USERNAME")
		
		var img_path_list = []
		
		# TODO: Add support for other OSes. First targets are Windows, Linux and Android.
		if os_name == "Windows" or os_name == "UWP":
			# Windows hack to trigger temporary generation of <username>.bmp
			add_child(WinTempAvatarTrigger.new())
			
			img_path_list.append(OS.get_environment("LOCALAPPDATA") + "\\Temp\\" + user_name + ".bmp")
			
			img_path_list.append(OS.get_environment("PROGRAMDATA") + "\\Microsoft\\User Account Pictures\\guest.png")
			img_path_list.append(OS.get_environment("PROGRAMDATA") + "\\Microsoft\\User Account Pictures\\Guest.png")
		# print(img_path_list) # Debug-line
		
		for img_path in img_path_list:
			if FileAccess.file_exists(img_path):
				var img = Image.new()
				img.load(img_path)
#				print(img.get_size()) # Debug-line
				var tex = ImageTexture.create_from_image(img)
				if tex:
					user_icon = tex
					break
		
	else:
		user_name = "Anonymous(Unknown OS)"
