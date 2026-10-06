extends CharacterBody3D

# Cihanşah - Tarihi Kapalıçarşı Hanımları (Osmanlı Kadın Sakinleri)
# Alışveriş yapan, esnafla hasbihal eden ve Cihanşah'a samimi tarihi bilgiler veren hanımefendiler

@onready var label: Label3D = $NameLabel
var is_player_near: bool = false
var default_rot_y: float = 0.0
var woman_name: String = "Ayşe Hatun"
var dialogue_quote: String = "Hayırlı günler efendi!"
var idle_phase: float = 0.0

func _ready() -> void:
	add_to_group("interactables")
	default_rot_y = rotation.y
	idle_phase = randf() * PI * 2.0
	
	if has_meta("woman_name"):
		woman_name = get_meta("woman_name")
	if has_meta("dialogue_text"):
		dialogue_quote = get_meta("dialogue_text")
		
	update_label(false)

func _process(delta: float) -> void:
	# Zarif duruş salınımı (Nefes alma & kumaş salınımı)
	var time = (Time.get_ticks_msec() * 0.0015) + idle_phase
	rotation.z = sin(time) * 0.015
	
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var p = players[0]
		var dist = global_position.distance_to(p.global_position)
		if dist < 4.5:
			if not is_player_near:
				is_player_near = true
				update_label(true)
			# Oyuncuya doğru zarifçe dön
			var to_player = p.global_position - global_position
			var target_rot = atan2(to_player.x, to_player.z)
			rotation.y = lerp_angle(rotation.y, target_rot, 3.5 * delta)
		else:
			if is_player_near:
				is_player_near = false
				update_label(false)
			rotation.y = lerp_angle(rotation.y, default_rot_y, 2.5 * delta)

func update_label(active: bool) -> void:
	if not label:
		return
	if active:
		label.text = "★ " + woman_name + " ★\n[ 'E' veya 'Konuş' Butonuna Dokun ]"
		label.modulate = Color(1.2, 0.95, 1.1)
		label.outline_modulate = Color(0.4, 0.1, 0.25)
	else:
		label.text = woman_name + "\n[Kapalıçarşı Alışverişi]"
		label.modulate = Color(0.95, 0.85, 0.9)
		label.outline_modulate = Color(0.15, 0.1, 0.15)

func interact(player: Node3D) -> void:
	if has_node("/root/SoundManager"):
		get_node("/root/SoundManager").play_ui_click()
	
	if player and player.has_signal("message_displayed"):
		player.emit_signal("message_displayed", "🧕 " + woman_name + ": \"" + dialogue_quote + "\"", 4.5)
