extends Node

var os_name: String = "Unknown OS"
var user_name: String = "Anonymous"
var user_icon: Texture2D = load("res://icon.png")

func _ready() -> void:
	os_name = OS.get_name()
	
	if OS.has_environment("USERNAME"):
		user_name = OS.get_environment("USERNAME")
		
		var img_path_list: Array[String] = []
		
		# TODO: Add support for other OSes.
		if os_name == "Windows" or os_name == "UWP":
			# Windows hack to trigger temporary generation of <username>.bmp
			add_child(WinTempAvatarTrigger.new())
			
			img_path_list.append(OS.get_environment("LOCALAPPDATA") + "\\Temp\\" + user_name + ".bmp")
			
			img_path_list.append(OS.get_environment("PROGRAMDATA") + "\\Microsoft\\User Account Pictures\\guest.png")
			img_path_list.append(OS.get_environment("PROGRAMDATA") + "\\Microsoft\\User Account Pictures\\Guest.png")
		# print(img_path_list) # Debug-line
		
		for img_path: String in img_path_list:
			if FileAccess.file_exists(img_path):
				var img: Image = Image.new()
				var err: Error = img.load(img_path)
				if err == Error.OK:
					#print(img.get_size()) # Debug-line
					var tex: ImageTexture = ImageTexture.create_from_image(img)
					if tex:
						user_icon = tex
						break
	elif os_name == "Android" or os_name == "iOS":
		user_name = OS.get_model_name()
	else:
		user_name = "Anonymous(Unknown OS)"
	pass
