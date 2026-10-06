extends StaticBody3D

# Cihanşah - Etkileşimli Şehir Unsurları (Tarihi Su Kuyusu, Çatı Zulası, Gözcü Noktası)
@export var prop_type: String = "kuyu" # "kuyu", "zula", "gozcu"
@export var interact_label: String = ""

var is_cooldown: bool = false

func _ready() -> void:
	add_to_group("interactables")
	if interact_label == "":
		match prop_type:
			"kuyu":
				interact_label = "💧 Tarihi Taş Kuyu (Buz Gibi Su İç - Can Yenile)"
			"zula":
				interact_label = "📦 Teşkilât Çatı Zulası (Cephane & İstihbarat Al)"
			"gozcu":
				interact_label = "🦅 Çatı Gözcü Noktası (Şehri Teftiş Et)"

func get_interaction_label() -> String:
	return interact_label

func interact(player: Node3D) -> void:
	if is_cooldown:
		if player.has_signal("message_displayed"):
			player.emit_signal("message_displayed", "Biraz beklemen icap eder...", 2.0)
		return
		
	match prop_type:
		"kuyu":
			# Can ve Takat tazele
			if "health" in player and "max_health" in player:
				player.health = player.max_health
				if player.has_signal("health_changed"):
					player.emit_signal("health_changed", player.health, player.max_health)
			if "stamina" in player and "max_stamina" in player:
				player.stamina = player.max_stamina
			if player.has_signal("message_displayed"):
				player.emit_signal("message_displayed", "💧 Tarihi kuyudan buz gibi kaynak suyu içtin. Sıhhat ve zindelik buldun! (Can ve Takat Fullendi)", 3.5)
			_start_cooldown(6.0)
			
		"zula":
			# Altıpatlar mühimmatı doldur
			if "current_ammo" in player and "max_ammo" in player:
				player.current_ammo = player.max_ammo
				if player.has_signal("ammo_changed"):
					player.emit_signal("ammo_changed", player.current_ammo, player.max_ammo)
			if player.has_signal("message_displayed"):
				player.emit_signal("message_displayed", "📦 Teşkilât Çatı Zulası: Altıpatlar fişekleri ve gizli payitaht krokisi temin edildi!", 3.5)
			_start_cooldown(8.0)
			
		"gozcu":
			if player.has_signal("message_displayed"):
				player.emit_signal("message_displayed", "🦅 Çatı Gözcü Noktasındasın: Tüm sokaklar, çarşı kubbesi ve Cami-i Kebîr avlusu ayaklarının altında!", 4.0)
			_start_cooldown(4.0)

func _start_cooldown(sec: float) -> void:
	is_cooldown = true
	var timer = get_tree().create_timer(sec)
	timer.timeout.connect(func(): is_cooldown = false)
