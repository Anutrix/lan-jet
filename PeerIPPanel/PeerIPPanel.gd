extends Control

@onready var peer_ip_holder_node: Node = %PeerIPHolder

const LABEL_REFRESH_TIME_SECONDS: float = 2.0 # Needs to be less than PEER_REFRESH_TIME_SECONDS

func _ready() -> void:
	update_peer_ip_panel()
	create_peer_refresh_timer()

func update_peer_ip_panel() -> void:
	var current_ip_list: Array[String] = []
	var latest_peer_ip_states: Dictionary = NetworkGlobalState.peer_ip_states
	
	# Remove lost connections
	for child: Label in peer_ip_holder_node.get_children():
		var ip: String = child.text
		current_ip_list.append(ip)
		if latest_peer_ip_states[ip] == false:
			peer_ip_holder_node.remove_child(child)
			child.queue_free()
	
	# Add new connections
	for ip: String in latest_peer_ip_states:
		if latest_peer_ip_states[ip] == true and ip not in current_ip_list:
			var label: Label = Label.new()
			label.text = ip
			peer_ip_holder_node.add_child(label)

func create_peer_refresh_timer() -> void:
	var timer: Timer = Timer.new()
	timer.autostart = true
	timer.one_shot = false
	timer.wait_time = LABEL_REFRESH_TIME_SECONDS
	var err: int = timer.timeout.connect(self._on_timer_timeout)
	if err != OK:
		print("Timer signal timeout connection failed.")
	add_child(timer)

func _on_timer_timeout() -> void:
	update_peer_ip_panel()
