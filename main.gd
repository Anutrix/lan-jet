extends Panel

var os_name: String = ""
var username: String = ""

var user_profile_picture = load("res://icon.png")

func _ready():
	os_name = OS.get_name()

	if OS.has_environment("USERNAME"):
		username = OS.get_environment("USERNAME")
		$UserDetailPanel.username = username
		
		var img_path
		var file = File.new()
		if os_name == "Windows" or os_name == "UWP":
			var img_path_list = []
			# img_path_list.append(OS.get_environment("LOCALAPPDATA") + "\\Temp\\" + username + ".bmp")
			# Access issue probably
			img_path_list.append(OS.get_environment("PROGRAMDATA") + "\\Microsoft\\User Account Pictures\\Guest.bmp")
			print(img_path_list)
			
			for img_path in img_path_list:
				if file.file_exists(img_path):
					user_profile_picture = make_image(img_path)
					break
		
		$UserDetailPanel.user_icon = user_profile_picture
	else:
		$UserDetailPanel.username = "Anonymous"
	
func make_image(img_path):
	var img = Image.new()
	var tex = ImageTexture.new()
	img.load(img_path)
	tex.create_from_image(img)
	return tex
