extends Node

func _ready() -> void:
	var server: HttpServer = HttpServer.new()
	server.register_router("/", MainRouter.new())
	add_child(server)
	server.start()
