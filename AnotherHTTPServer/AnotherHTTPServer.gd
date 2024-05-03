# A full HTTP server for Godot
# Copyright (c) Anutrix(Numan Zaheer Ahmed)
# MIT License
# Heavily based on Godot Editor's unexposed HTTP Server
# Note: Treat this file as Alpha level. Unsure about threads and lock logic too.

extends Node
class_name AnotherHTTPServer

var server: TCPServer = null
var mimes: Dictionary = {}
var tcp: StreamPeerTCP = null
var tls: StreamPeerTLS = null
var peer: StreamPeer = null
var key: CryptoKey = null
var cert: X509Certificate = null
var use_tls: bool = false
var time: int = 0
var req_buf: PackedByteArray = []
var req_pos: int = 0
var server_quit_flag_set: bool = false
var server_lock: Mutex = Mutex.new()
var server_thread: Thread = Thread.new()

func _init() -> void:
	mimes["html"] = "text/html"
	mimes["js"] = "application/javascript"
	mimes["json"] = "application/json"
	mimes["pck"] = "application/octet-stream"
	mimes["png"] = "image/png"
	mimes["svg"] = "image/svg"
	mimes["wasm"] = "application/wasm"
	mimes["zip"] = "application/octet-stream"
	mimes["txt"] = "text/html"
	server = TCPServer.new()
	stop()

func start() -> void:
	set_process(true)

func stop() -> void:
	server_quit_flag_set = true
	if server_thread.is_started():
		server_thread.wait_to_finish()
	if is_instance_valid(server):
		server.stop()
	_clear_client()
	
	set_process(false)

func _clear_client() -> void:
	peer = null # Is this correct?
	if tls:
		tls.disconnect_from_stream()
		tls = null
	if tcp:
		tcp.disconnect_from_host()
		tcp = null
	req_buf.clear()
	time = 0
	req_pos = 0

func listen(p_port: int, p_address: String, p_use_tls: bool, p_tls_key: String, p_tls_cert: String) -> Error:
	server_lock.lock()
	
	if server.is_listening():
		return ERR_ALREADY_IN_USE
	
	use_tls = p_use_tls
	if use_tls:
		var crypto: Crypto = Crypto.new()
		if crypto == null:
			return ERR_UNAVAILABLE
		
		if !p_tls_key.is_empty() and !p_tls_cert.is_empty():
			key = CryptoKey.new()
			var err: Error = key.load(p_tls_key)
			if err != OK:
				print("err", err)
				stop()
				return FAILED
			cert = X509Certificate.new()
			err = cert.load(p_tls_cert)
			if err != OK:
				print("err", err)
				stop()
				return FAILED
		else:
			_set_internal_certs(crypto)

	var err_listen: Error = server.listen(p_port, p_address)
	if err_listen == OK:
		server_quit_flag_set = false
		var err_thread_start: Error = server_thread.start(_server_thread_poll)
		if err_thread_start != OK:
			print("Error: ", err_thread_start)
			stop()
	
	server_lock.unlock()
	return err_listen

func _set_internal_certs(p_crypto: Crypto) -> void:
	const cache_path: String = "res://"
	var key_path: String = cache_path.path_join("html5_server.key")
	var crt_path: String = cache_path.path_join("html5_server.crt")
	var regen: bool = !FileAccess.file_exists(key_path) || !FileAccess.file_exists(crt_path)
	if !regen:
		key = CryptoKey.new()
		cert = X509Certificate.new()
		if key.load(key_path) != OK || cert.load(crt_path) != OK:
			regen = true
	
	if regen:
		print("Regenerating key and cert.")
		key = p_crypto.generate_rsa(2048)
		var key_err: Error = key.save(key_path)
		if key_err != OK:
			print("Error saving key.")
		cert = p_crypto.generate_self_signed_certificate(key, "CN=godot-debug.local,O=A Game Dev,C=XXA", "20140101000000", "20340101000000")
		var crt_err: Error = cert.save(crt_path)
		if crt_err != OK:
			print("Error saving cert.")
	else:
		print("Reusing existing key and cert.")
	
	#var key_file: FileAccess = FileAccess.open(key_path, FileAccess.READ)
	#print(key_file.get_as_text())
	#var crt_file: FileAccess = FileAccess.open(crt_path, FileAccess.READ)
	#print(crt_file.get_as_text())

func _server_thread_poll() -> void:
	while (!server_quit_flag_set == true):
		OS.delay_usec(6900)
		
		server_lock.lock()
		_poll()
		server_lock.unlock()

func _poll() -> void:
	if !server.is_listening():
		return
	
	if tcp == null:
		if !server.is_connection_available():
			return
		
		tcp = server.take_connection()
		peer = tcp
		time = Time.get_ticks_usec()
	
	if Time.get_ticks_usec() - time > 1000000:
		_clear_client()
		return
	
	if tcp.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		return

	if use_tls:
		if tls == null:
			tls = StreamPeerTLS.new()
			peer = tls
			if tls.accept_stream(tcp, TLSOptions.server(key, cert)) != OK:
				_clear_client()
				return
		tls.poll()
		var status: int = tls.get_status()
		if status == StreamPeerTLS.STATUS_HANDSHAKING:
			# Still handshaking, keep waiting.
			return
		if status != StreamPeerTLS.STATUS_CONNECTED:
			_clear_client()
			return

	while (true):
		var r: PackedByteArray = req_buf.duplicate()
		var l: int = req_pos - 1
		if (l > 3 and char(r[l]) == '\n' and char(r[l - 1]) == '\r' and char(r[l - 2]) == '\n' and char(r[l - 3]) == '\r'):
			_send_response()
			_clear_client()
			return
		
		if (req_pos >= 4096):
			print("req_pos >= 4096")
			return
		
		var dat: Array = peer.get_data(1)
		var err: Error = dat[0]
		req_buf.append_array(dat[1])
		
		if err != OK:
			# Got an error
			_clear_client()
			#break
			return
		
		req_pos += 1

func _send_response() -> void:
	var data: String = req_buf.get_string_from_utf8()
	print("\n---Start of Request----")
	print(data)
	print("----End of Request-----\n")
	
	var psa: PackedStringArray = data.split("\r\n")
	var sze: int = psa.size()
	if sze < 4:
		print("Not enough response headers, got: " + str(sze) + ", expected >= 4.")

	var req: PackedStringArray = psa[0].split(" ", false)
	if req.size() < 2:
		print("Invalid protocol or status code.")

	# Wrong protocol
	if(req[0] != "GET" || req[2] != "HTTP/1.1"):
		print("Invalid method or HTTP version.")

	var query_index: int = req[1].find('?')
	var path: String = ""
	if query_index == -1:
		path = req[1]
	else:
		path = req[1].substr(0, query_index)

	var req_file: String = path.get_file()
	var req_ext: String = path.get_extension()
	var cache_path: String = "res://Data"
	var filepath: String = cache_path.path_join(req_file)

	if !mimes.has(req_ext) || !FileAccess.file_exists(filepath):
		var s2: String = "HTTP/1.1 404 Not Found\r\n"
		s2 += "Connection: Close\r\n"
		s2 += "\r\n"
		var cs2: PackedByteArray = s2.to_utf8_buffer()
		var err2: Error = peer.put_data(cs2)
		if err2 != OK:
			print("Error: ", err2)
		return
	
	var ctype: String = mimes[req_ext]
	
	var res_file: FileAccess = FileAccess.open(filepath, FileAccess.READ)
	if res_file == null:
		print("Couldn't access file.")
		return
	
	var s: String = "HTTP/1.1 200 OK\r\n"
	s += "Connection: Close\r\n"
	s += "Content-Type: " + ctype + "\r\n"
	s += "Access-Control-Allow-Origin: *\r\n"
	s += "Cross-Origin-Opener-Policy: same-origin\r\n"
	s += "Cross-Origin-Embedder-Policy: require-corp\r\n"
	s += "Cache-Control: no-store, max-age=0\r\n"
	s += "\r\n"
	var cs: PackedByteArray = s.to_utf8_buffer()
	var err: Error = peer.put_data(cs)
	if err != OK:
		print("Error: ", err)
		return

	while (true):
		var data_chunk: PackedByteArray = res_file.get_buffer(4096)
		if data_chunk.is_empty():
			return
		err = peer.put_data(data_chunk)
		if err != OK:
			print("Error: ", err)
			return

func is_listening() -> bool:
	server_lock.lock()
	var res: bool = server.is_listening()
	server_lock.unlock()
	return res

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	pass
