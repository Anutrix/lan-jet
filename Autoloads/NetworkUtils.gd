extends Node

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	pass

func getInterfaceIPv4Addresses() -> Array[String]:
	var ipList: Array[String] = []
	var os_name: String = OS.get_name()
	
	# TODO: Add support for other OSes
	if os_name == "Windows" or os_name == "UWP":
		var output: Array[String] = []
		var exit_code: int = OS.execute("cmd.exe", ["/C", "ipconfig"], output)
		if exit_code == 0:
			if len(output) == 1:
				var lines: PackedStringArray = output[0].split("\r\n")
				for line: String in lines:
					if "IPv4 Address" in line:
						var ip: String = line.split(":")[-1].strip_edges()
						ipList.append(ip)
			else:
				print("Unexpected response to 'ipconfig' command:", output)
		else:
			print("Error: Couldn't run ipconfig")
	else:
		print("Unsupported OS")
	
	return ipList
