extends Node

var http_requests_holder: Node = null

const LANJET_VERIFICATION_STRING: String = "Lan-Jet is alive!"
const LANJET_VERIFICATION_FILEPATH: String = "lanjet.txt"
# Bug on Android export where TextFiles are skipped.
# lanjet.gd works as workaround for now. Untested.
# https://github.com/godotengine/godot/issues/91491
const PEER_REFRESH_TIME_SECONDS: float = 4.0
const PORT: String = "8888"

var self_ips: PackedStringArray = []
var peer_ip_states: Dictionary = {}

func _process(_delta: float) -> void:
	pass

func _ready() -> void:
	repopulate_self_IPs()
	
	http_requests_holder = Node.new()
	http_requests_holder.name = "HTTPRequestHolder"
	add_child(http_requests_holder)
	
	update_peer_address_states()
	create_peer_refresh_timer()

func repopulate_self_IPs() -> void:
	self_ips = IP.get_local_addresses()

func create_peer_refresh_timer() -> void:
	var timer: Timer = Timer.new()
	timer.autostart = true
	timer.one_shot = false
	timer.wait_time = PEER_REFRESH_TIME_SECONDS
	var err: int = timer.timeout.connect(self._on_timer_timeout)
	if err != OK:
		print("Timer signal timeout connection failed.")
	add_child(timer)

func _on_timer_timeout() -> void:
	update_peer_address_states()

func update_peer_address_states() -> void:
	for http_req: HTTPRequest in http_requests_holder.get_children():
		http_req.queue_free()
	
	for i: int in range(255):
		var ip: String = "192.168.1." + str(i)
		# Exclude own ips
		if ip not in self_ips:
			make_get_request(ip)
		else:
			peer_ip_states[ip] = false

func make_get_request(ip: String) -> void:
	var http_request: HTTPRequest = HTTPRequest.new()
	#http_request.use_threads = true
	http_request.timeout = 2.0
	var connect_err: int = http_request.request_completed.connect(self._http_request_completed.bind(ip, http_request))
	if connect_err != OK:
		print("An error occurred in the request_completed signal connection.")
		peer_ip_states[ip] = false
	
	http_requests_holder.add_child(http_request)
	
	# Perform a GET request.
	var url: String = "http://" + ip + ":" + PORT + "/" + LANJET_VERIFICATION_FILEPATH
	#print(url)
	var error: Error = http_request.request(url)
	if error != OK:
		print("An error occurred in the HTTP request for IP: ", ip)
		peer_ip_states[ip] = false

func _http_request_completed(_result: int, _response_code: int, _headers: PackedStringArray, body: PackedByteArray, request_ip: String, http_request: HTTPRequest) -> void:
	http_request.queue_free()
	var resp: String = body.get_string_from_utf8()
	
	# Exclude unknown servers
	if resp.contains(LANJET_VERIFICATION_STRING):
		peer_ip_states[request_ip] = true
	else:
		peer_ip_states[request_ip] = false
