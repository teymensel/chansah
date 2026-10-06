extends StaticBody3D

# Cihanşah - Kedi Sevme Etkileşimi
var is_cooldown: bool = false

func _ready() -> void:
	add_to_group("interactables")

func get_interaction_label() -> String:
	var cname = get_meta("cat_name") if has_meta("cat_name") else "Sokak Kedisi"
	return "🐾 " + str(cname) + " (Sev / Okşa)"

func interact(player: Node3D) -> void:
	if is_cooldown:
		if player.has_signal("message_displayed"):
			player.emit_signal("message_displayed", "Kedicik memnuniyetle mırıldıyor...", 2.0)
		return
		
	var msg = get_meta("interact_msg") if has_meta("interact_msg") else "🐾 Kediyi sevdin, mırıldandı!"
	if player.has_signal("message_displayed"):
		player.emit_signal("message_displayed", msg, 3.5)
		
	if "stamina" in player and "max_stamina" in player:
		player.stamina = minf(player.stamina + 35.0, player.max_stamina)
		
	# Sevimli hafif mırıldanma zıplaması
	var tween = create_tween()
	tween.tween_property(self, "position:y", position.y + 0.12, 0.15)
	tween.tween_property(self, "position:y", position.y, 0.15)
	
	is_cooldown = true
	var timer = get_tree().create_timer(5.0)
	timer.timeout.connect(func(): is_cooldown = false)
