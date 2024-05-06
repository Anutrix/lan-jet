extends Node

var bind_port: int = NetworkGlobalState.PORT
var bind_ip: String = "0.0.0.0"
var use_tls: bool = NetworkGlobalState.ENABLE_TLS
var tls_key: String = ""
var tls_cert: String = ""

func _ready() -> void:
	#var old_server: HttpServer = HttpServer.new()
	#old_server.port = bind_port
	#old_server.register_router("/lanjet.txt", MainRouter.new())
	#add_child(old_server)
	#old_server.start()
	
	print("Server Manager started.")
	
	var server: AnotherHTTPServer = AnotherHTTPServer.new()
	var err: Error = server.listen(bind_port, bind_ip, use_tls, tls_key, tls_cert);
	match err:
		OK:
			var protocol_str: String = "http"
			if use_tls:
				protocol_str = "https"
			print("Web Server listening on %s://%s:%s" % [protocol_str, bind_ip, bind_port])
		ERR_ALREADY_IN_USE:
			print("Could not bind to port %d, already in use." % bind_port);
			server.stop()
		_:
			print("Error starting server. ErrorCode: %d" % err);
			server.stop()
	
	add_child(server)
	server.start()
	
	#print(DirAccess.get_directories_at("res://"))
