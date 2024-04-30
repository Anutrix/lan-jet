extends Node

func _ready() -> void:
	var ips: Array[String] = NetworkUtils.getInterfaceIPv4Addresses()
	print(ips)
	
	var server: HttpServer = HttpServer.new()
	server.register_router("/", MainRouter.new())
	add_child(server)
	server.start()

func _process(_delta: float) -> void:
	pass
