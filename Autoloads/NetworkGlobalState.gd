extends Node

const VERBOSE_LOGGING: bool = false

const PORT: int = 8888
const ENABLE_TLS: bool = true

const LANJET_VERIFICATION_STRING: String = "Lan-Jet is alive!"
const LANJET_VERIFICATION_FILEPATH: String = "lanjet.txt"
const REFRESH_WAIT_TIME_SECONDS: float = 4.0

var http_requests_holder: Node = null

var self_ips: PackedStringArray = []
var peer_ip_states: Dictionary = {}

func _process(_delta: float) -> void:
	pass

func _ready() -> void:
	repopulate_self_IPs()
	create_refresh_timer(self.repopulate_self_IPs)
	
	http_requests_holder = Node.new()
	http_requests_holder.name = "HTTPRequestHolder"
	add_child(http_requests_holder)
	
	update_peer_address_states()
	create_refresh_timer(self.update_peer_address_states)

func repopulate_self_IPs() -> void:
	self_ips = IP.get_local_addresses()

func create_refresh_timer(target_callable: Callable) -> void:
	var timer: Timer = Timer.new()
	timer.autostart = true
	timer.one_shot = false
	timer.wait_time = REFRESH_WAIT_TIME_SECONDS
	var err: int = timer.timeout.connect(target_callable)
	if err != OK:
		print("Timer's signal 'timeout' failed to connect to function.")
	add_child(timer)

func update_peer_address_states() -> void:
	for http_req: HTTPRequest in http_requests_holder.get_children():
		http_req.queue_free()
	
	for i: int in range(255):
		var ip: String = "192.168.1." + str(i)
		# Exclude own ips
		if ip not in self_ips:
			_make_get_request(ip)
		else:
			peer_ip_states[ip] = false

func _make_get_request(ip: String) -> void:
	var http_request: HTTPRequest = HTTPRequest.new()
	#http_request.use_threads = true
	http_request.timeout = 2.0
	if ENABLE_TLS:
		http_request.set_tls_options(TLSOptions.client_unsafe())
	var connect_err: int = http_request.request_completed.connect(self._http_request_completed.bind(ip, http_request))
	if connect_err != OK:
		print("An error occurred in the request_completed signal connection.")
		peer_ip_states[ip] = false
	
	http_requests_holder.add_child(http_request)
	
	# Perform a GET request.
	var url: String = "http://"
	if ENABLE_TLS:
		url = "https://"
	url += ip + ":" + str(PORT) + "/" + LANJET_VERIFICATION_FILEPATH
	var error: Error = http_request.request(url)
	if error != OK:
		print("An error occurred in the HTTP request for IP: ", ip)
		peer_ip_states[ip] = false

func _http_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, target_ip: String, http_request: HTTPRequest) -> void:
	http_request.queue_free()
	var resp: String = body.get_string_from_utf8()
	
	if result == 0:
		if response_code == 200:
			# Exclude other kind of servers
			if resp.contains(LANJET_VERIFICATION_STRING):
				peer_ip_states[target_ip] = true
				return
		else:
			print("Server exists but doesn't return 200. Probably not a lan-jet app.")
	elif VERBOSE_LOGGING:
		if target_ip.ends_with(".6") or target_ip.ends_with(".10"):
			print("Non-zero Godot result code '", result,"' for IP '", target_ip, "'.")
			print("-----------")
			print("'" + target_ip + "'")
			print(result)
			print(response_code)
			print(_headers)
			print(body)
			print(resp)
			print("-----------")
	
	peer_ip_states[target_ip] = false
