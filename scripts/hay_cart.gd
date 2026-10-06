extends StaticBody3D

# Cihanşah - Assassin's Creed Saman Yığını & İnanç Atlayışı (Leap of Faith)
# Yüksek çatılardan atlamayı sağlayan ve düşmanlardan gizleyen tarihi saman arabası

signal player_hid_in_hay(player: Node3D)
signal player_left_hay(player: Node3D)

var is_player_inside: bool = false
var hidden_player: Node3D = null

func _ready() -> void:
	add_to_group("hay_carts")
	add_to_group("interactables")
	
	# Saman içine iniş algılama alanı
	var area = Area3D.new()
	var acol = CollisionShape3D.new()
	var abox = BoxShape3D.new()
	abox.size = Vector3(2.6, 2.2, 3.8)
	acol.shape = abox
	acol.position.y = 1.3
	area.add_child(acol)
	area.body_entered.connect(_on_body_entered)
	add_child(area)

func get_interaction_label() -> String:
	if is_player_inside:
		return "🌾 Samandan Çık (Zıpla veya Yürü)"
	else:
		return "🌾 Saman Arabasına Gizlen (İnanç Atlayışı)"

func interact(player: Node3D) -> void:
	if is_player_inside:
		exit_hay()
	else:
		enter_hay(player)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and not is_player_inside:
		# Çatıdan düşerek veya atlayarak girdi
		enter_hay(body)

func enter_hay(player: Node3D) -> void:
	is_player_inside = true
	hidden_player = player
	
	# Düşme hasarını ve dikey hızı sıfırla
	if "velocity" in player:
		player.velocity = Vector3.ZERO
		
	# Oyuncuyu samanın içine oturt
	player.global_position = global_position + Vector3(0, 0.9, 0)
	
	if has_node("/root/SoundManager"):
		get_node("/root/SoundManager").play_sword_slash() # Hışırtı sesi
		
	if player.has_signal("message_displayed"):
		player.emit_signal("message_displayed", "🌾 Saman Arabasına Gizlendin! Düşmanlar seni göremez. (Çıkmak için [E] veya Zıpla)", 3.5)
		
	# Düşmanların hedef almasını engelle
	if "is_stealth_hidden" in player:
		player.is_stealth_hidden = true

func exit_hay() -> void:
	if hidden_player:
		if "is_stealth_hidden" in hidden_player:
			hidden_player.is_stealth_hidden = false
		hidden_player.global_position = global_position + (global_transform.basis.x * 2.2)
		if hidden_player.has_signal("message_displayed"):
			hidden_player.emit_signal("message_displayed", "Samandan çıktın.", 1.5)
	is_player_inside = false
	hidden_player = null

func _process(_delta: float) -> void:
	if is_player_inside and hidden_player:
		# Oyuncu hareket tuşuna basarsa samandan çıkar
		if Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("move_forward"):
			exit_hay()
