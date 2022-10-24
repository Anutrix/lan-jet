extends Panel

var os_name: String = ""
var username: String = ""

func _ready():
	os_name = OS.get_name()

	if OS.has_environment("USERNAME"):
		username = OS.get_environment("USERNAME")
		$UserDetailPanel.user_name = username
		
		var img_path_list = []
		if os_name == "Windows" or os_name == "UWP":	
			img_path_list.append(OS.get_environment("LOCALAPPDATA") + "\\Temp\\" + username + ".bmp")
			# Can't load because in Godot, 16-bpp BMP images are not supported.

			img_path_list.append(OS.get_environment("PROGRAMDATA") + "\\Microsoft\\User Account Pictures\\Guest.png")
		
#		print(img_path_list)
			
		for img_path in img_path_list:
			if FileAccess.file_exists(img_path):
				var img = Image.new()
				img.load(img_path)
#				print(img.get_size())
				var tex = ImageTexture.create_from_image(img)
				if tex:
					$UserDetailPanel.icon = tex
					break
		
	else:
		$UserDetailPanel.username = "Anonymous"
