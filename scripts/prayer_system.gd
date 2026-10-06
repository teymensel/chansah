extends CanvasLayer

# Cihanşah - Cami-i Kebîr Namaz Kılma Simülasyonu (Tamamen Görsel & 3D Animasyon)
# Kullanıcı talebi: Hiçbir açılır UI penceresi veya Arapça/Türkçe kart çıkmayacak!
# Sadece 3D karakterin ve cemaatin huşû içinde namaz kılış animasyonu çalışacak.

signal prayer_completed(blessed: bool)

var player_ref: Node3D = null
var is_active: bool = false
var prayer_timer: float = 0.0
var prayer_duration: float = 18.0

func _ready() -> void:
	visible = false
	for child in get_children():
		child.visible = false

func start_prayer(p: Node3D) -> void:
	player_ref = p
	visible = false
	is_active = true
	prayer_timer = 0.0
	
	if player_ref:
		if player_ref.has_method("enter_prayer_mode") and not player_ref.is_praying:
			player_ref.enter_prayer_mode()
		else:
			player_ref.is_in_dialogue = true
			player_ref.rotation.y = 0.0
			
	var hud = get_tree().get_first_node_in_group("mobile_hud")
	if hud and hud.has_method("show_notification"):
		hud.show_notification("🕌 Namaza duruldu... (Huşû içinde eda ediliyor)", 3.5)

func _process(delta: float) -> void:
	if not is_active:
		return
		
	prayer_timer += delta
	
	# İmam veya oyuncu animasyon kontrolü
	var anim_pos = -1.0
	if player_ref and "prayer_avatar" in player_ref and is_instance_valid(player_ref.prayer_avatar):
		var anim = player_ref.prayer_avatar.get_node_or_null("AnimationPlayer")
		if anim and anim.is_playing():
			anim_pos = anim.current_animation_position
			
	if anim_pos >= 23.5 or prayer_timer >= prayer_duration:
		finish_prayer()

func finish_prayer() -> void:
	if not is_active:
		return
	is_active = false
	
	# Manevi mükâfat ve şifa
	if player_ref:
		player_ref.health = player_ref.max_health
		player_ref.stamina = player_ref.max_stamina
		player_ref.emit_signal("health_changed", player_ref.health, player_ref.max_health)
		if player_ref.has_method("add_gold"):
			player_ref.add_gold(150)
		if "justice_points" in player_ref:
			player_ref.justice_points += 50
			
	close_prayer()
	
	emit_signal("prayer_completed", true)
	
	var hud = get_tree().get_first_node_in_group("mobile_hud")
	if hud and hud.has_method("show_notification"):
		hud.show_notification("🕌 1 Rekat Namaz Huşû İle Eda Edildi! (+100 Can, +150 Akçe)", 4.0)

func close_prayer() -> void:
	visible = false
	is_active = false
	if player_ref:
		if player_ref.has_method("exit_prayer_mode"):
			player_ref.exit_prayer_mode()
		else:
			player_ref.is_in_dialogue = false
			player_ref.is_praying = false
