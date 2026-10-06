extends StaticBody3D
class_name AssassinContracts

# Cihanşah - Teşkilât-ı Mahsûsa Ferman & Suikast Sözleşmeleri Panosu
# Assassin's Creed kontrat/suikast sistemi (Tarihi hedefler, ödüller, istihbarat)

signal contract_accepted(target_name: String, target_pos: Vector3, reward_gold: int)
signal contract_completed(target_name: String)

var active_target: Node3D = null
var active_target_name: String = ""
var active_reward_gold: int = 0

var contracts_ui: CanvasLayer = null

func _ready() -> void:
	add_to_group("interactables")
	add_to_group("contract_boards")
	_build_board_mesh_and_collision()
	_build_contracts_ui()

func _build_board_mesh_and_collision() -> void:
	# 1. Çarpışma kutusu
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(2.6, 2.8, 0.6)
	col.shape = box
	col.position.y = 1.4
	add_child(col)

	var wood_mat = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.26, 0.17, 0.11)
	wood_mat.roughness = 0.8

	var roof_mat = StandardMaterial3D.new()
	roof_mat.albedo_color = Color(0.55, 0.22, 0.16)
	roof_mat.roughness = 0.75

	var parchment_mat = StandardMaterial3D.new()
	parchment_mat.albedo_color = Color(0.92, 0.86, 0.72)
	parchment_mat.roughness = 0.9

	var seal_mat = StandardMaterial3D.new()
	seal_mat.albedo_color = Color(0.75, 0.12, 0.1)

	# 2. İki Dikey Ahşap Dikme
	for x_pos in [-1.1, 1.1]:
		var post = MeshInstance3D.new()
		var p_box = BoxMesh.new()
		p_box.size = Vector3(0.18, 2.7, 0.18)
		post.mesh = p_box
		post.position = Vector3(x_pos, 1.35, 0)
		post.set_surface_override_material(0, wood_mat)
		add_child(post)

	# 3. Ana İlan Panosu (Geniş Ahşap Levha)
	var board = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(2.35, 1.45, 0.1)
	board.mesh = b_box
	board.position = Vector3(0, 1.6, 0)
	board.set_surface_override_material(0, wood_mat)
	add_child(board)

	# 4. Üst Yağmurluk Saçağı (Osmanlı Kiremit Çatı)
	var canopy = MeshInstance3D.new()
	var c_box = BoxMesh.new()
	c_box.size = Vector3(2.6, 0.15, 0.5)
	canopy.mesh = c_box
	canopy.position = Vector3(0, 2.45, 0.1)
	canopy.rotation.x = deg_to_rad(12.0)
	canopy.set_surface_override_material(0, roof_mat)
	add_child(canopy)

	# 5. Üzerine Çivilenmiş 3 Ferman Parşömeni
	for idx in range(3):
		var x_pos = -0.7 + (idx * 0.7)
		var scroll = MeshInstance3D.new()
		var s_box = BoxMesh.new()
		s_box.size = Vector3(0.55, 0.85, 0.02)
		scroll.mesh = s_box
		scroll.position = Vector3(x_pos, 1.55, 0.06)
		scroll.set_surface_override_material(0, parchment_mat)
		add_child(scroll)

		# Kırmızı Balmumu Mühür (Mühr-ü Hümâyûn)
		var seal = MeshInstance3D.new()
		var s_cyl = CylinderMesh.new()
		s_cyl.top_radius = 0.05
		s_cyl.bottom_radius = 0.05
		s_cyl.height = 0.02
		seal.mesh = s_cyl
		seal.position = Vector3(x_pos, 1.85, 0.08)
		seal.rotation.x = PI * 0.5
		seal.set_surface_override_material(0, seal_mat)
		add_child(seal)

	# 6. Sıcak Işık Veren Asılı Fener
	var lantern = OmniLight3D.new()
	lantern.light_color = Color(1.0, 0.85, 0.5)
	lantern.light_energy = 1.4
	lantern.omni_range = 6.5
	lantern.position = Vector3(0, 2.2, 0.3)
	add_child(lantern)

	# 7. 3D Yüzen Başlık
	var title_lbl = Label3D.new()
	title_lbl.text = "📜 Teşkilât-ı Mahsûsa Ferman Panosu\n[ Dokun veya 'E' ]"
	title_lbl.font_size = 24
	title_lbl.pixel_size = 0.007
	title_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title_lbl.modulate = Color(1.0, 0.88, 0.35)
	title_lbl.outline_size = 4
	title_lbl.position = Vector3(0, 2.8, 0)
	add_child(title_lbl)


func get_interaction_label() -> String:
	if active_target and is_instance_valid(active_target) and not active_target.get("is_dead"):
		return "📜 Teşkilât Ferman Panosu (Aktif Vazife: " + active_target_name + ")"
	else:
		return "📜 Teşkilât-ı Mahsûsa Ferman Panosu (Gizli Suikast Vazifeleri Al)"

func interact(player: Node3D) -> void:
	if contracts_ui:
		contracts_ui.visible = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		if player.has_signal("message_displayed"):
			player.emit_signal("message_displayed", "📜 Teşkilât Ferman Panosunu inceliyorsun...", 2.0)

func _build_contracts_ui() -> void:
	contracts_ui = CanvasLayer.new()
	contracts_ui.layer = 25
	contracts_ui.visible = false
	add_child(contracts_ui)
	
	var root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	contracts_ui.add_child(root)
	
	# Karartma arka plan
	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.65)
	root.add_child(dim)
	
	# Ana Ferman Paneli (Tarihi Parşömen / Bronz Tasarım)
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(740, 520)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-370, -260)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.1, 0.08, 0.95)
	style.border_color = Color(0.85, 0.72, 0.35, 1.0) # Varaklı altın çerçeve
	style.border_width_bottom = 3
	style.border_width_top = 3
	style.border_width_left = 3
	style.border_width_right = 3
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	panel.add_theme_stylebox_override("panel", style)
	root.add_child(panel)
	
	# Başlık
	var title = Label.new()
	title.text = "⚔️ TEŞKİLÂT-I MAHSÛSA GİZLİ SUİKAST FERMANLARI"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(20, 20)
	title.size = Vector2(700, 35)
	title.modulate = Color(1.0, 0.88, 0.4)
	panel.add_child(title)
	
	var subtitle = Label.new()
	subtitle.text = "Payitahtın selametine kasteden hainleri ve casusları sessizce bertaraf et!"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.position = Vector2(20, 55)
	subtitle.size = Vector2(700, 25)
	subtitle.modulate = Color(0.75, 0.72, 0.65)
	panel.add_child(subtitle)
	
	# 3 Kontrat Kartı
	var contract_list = [
		{
			"id": 1,
			"name": "Casus Kara Vasil",
			"loc_name": "Batı Çıkmaz Sokağı (x: -46, z: 18)",
			"pos": Vector3(-46, 0, 18),
			"desc": "Yabancı elçiliklere gizli tabyaların krokisini ulaştırmaya çalışan tehlikeli casus.",
			"reward": 600,
			"badge": "🎯 SESSİZ İNFAZ"
		},
		{
			"id": 2,
			"name": "Çopur İdris ve Çetesi",
			"loc_name": "Doğu Çatı Köprüleri Üstü (x: 34, z: 18)",
			"pos": Vector3(34, 4.2, 18),
			"desc": "Kapalıçarşı tüccarlarını haraca kesen, çatıları mesken tutmuş eli kanlı eşkıya reisi.",
			"reward": 900,
			"badge": "🏹 ÇATI PARKURU"
		},
		{
			"id": 3,
			"name": "Hain Yüzbaşı Dimitri",
			"loc_name": "Saray Göleti İskelesi (x: 58, z: -32)",
			"pos": Vector3(58, 0, -32),
			"desc": "Avni Paşa'nın kaçak sandalla Karadeniz'e kaçışını organize eden darbeci hain.",
			"reward": 1500,
			"badge": "👑 BAŞ HEDEF"
		}
	]
	
	for idx in range(contract_list.size()):
		var c = contract_list[idx]
		var card = Panel.new()
		card.position = Vector2(30, 95 + (idx * 125))
		card.size = Vector2(680, 110)
		var c_style = StyleBoxFlat.new()
		c_style.bg_color = Color(0.18, 0.15, 0.12, 0.9)
		c_style.border_color = Color(0.65, 0.55, 0.3, 0.8)
		c_style.border_width_bottom = 1
		c_style.border_width_top = 1
		c_style.border_width_left = 1
		c_style.border_width_right = 1
		c_style.corner_radius_bottom_left = 8
		c_style.corner_radius_bottom_right = 8
		c_style.corner_radius_top_left = 8
		c_style.corner_radius_top_right = 8
		card.add_theme_stylebox_override("panel", c_style)
		panel.add_child(card)
		
		# İsim ve Rozet
		var name_lbl = Label.new()
		name_lbl.text = c["badge"] + " - " + c["name"]
		name_lbl.position = Vector2(16, 12)
		name_lbl.modulate = Color(1.0, 0.85, 0.35)
		card.add_child(name_lbl)
		
		# Açıklama ve Konum
		var desc_lbl = Label.new()
		desc_lbl.text = c["desc"] + "\n📍 Konum: " + c["loc_name"] + " | 💰 Ödül: " + str(c["reward"]) + " Kuruş"
		desc_lbl.position = Vector2(16, 42)
		desc_lbl.size = Vector2(480, 50)
		desc_lbl.modulate = Color(0.85, 0.82, 0.78)
		card.add_child(desc_lbl)
		
		# Fermanı Kabul Et Butonu
		var btn = Button.new()
		btn.text = "📜 VAZİFEYİ AL"
		btn.position = Vector2(520, 32)
		btn.size = Vector2(140, 46)
		var b_style = StyleBoxFlat.new()
		b_style.bg_color = Color(0.55, 0.18, 0.15, 1.0)
		b_style.border_color = Color(0.9, 0.75, 0.3)
		b_style.border_width_bottom = 2
		b_style.border_width_top = 2
		b_style.border_width_left = 2
		b_style.border_width_right = 2
		b_style.corner_radius_bottom_left = 6
		b_style.corner_radius_bottom_right = 6
		b_style.corner_radius_top_left = 6
		b_style.corner_radius_top_right = 6
		btn.add_theme_stylebox_override("normal", b_style)
		btn.pressed.connect(func(): _accept_contract(c))
		card.add_child(btn)
		
	# Kapat Butonu
	var close_btn = Button.new()
	close_btn.text = "✖ Kapat"
	close_btn.position = Vector2(620, 16)
	close_btn.size = Vector2(90, 34)
	close_btn.pressed.connect(_close_ui)
	panel.add_child(close_btn)

func _close_ui() -> void:
	if contracts_ui:
		contracts_ui.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _accept_contract(contract_data: Dictionary) -> void:
	_close_ui()
	
	active_target_name = contract_data["name"]
	active_reward_gold = contract_data["reward"]
	var target_pos: Vector3 = contract_data["pos"]
	
	# Eski hedef varsa temizle
	if active_target and is_instance_valid(active_target):
		active_target.queue_free()
		
	# Düşmanı sahneye yarat
	var enemy_scene = load("res://scenes/enemy.tscn")
	if enemy_scene:
		var target = enemy_scene.instantiate()
		target.position = target_pos
		target.set("enemy_title", active_target_name)
		target.set("max_health", 140.0)
		target.set("health", 140.0)
		target.set("attack_damage", 25.0)
		target.add_to_group("contract_targets")
		
		get_parent().add_child(target)
		active_target = target
		
		# Pusula HUD'ına 💀 hedef pini ekle
		var compass = get_tree().get_first_node_in_group("compass_hud")
		if compass and compass.has_method("add_custom_landmark"):
			compass.add_custom_landmark("Hedef: " + active_target_name, target_pos, "💀")
			
		var gm = get_tree().get_first_node_in_group("game_manager")
		if gm and "hud_node" in gm and gm.hud_node:
			gm.hud_node.set_quest_objective("🎯 Suikast Vazifesi: " + active_target_name + "'i bul ve ortadan kaldır! (" + contract_data["loc_name"] + ")")
			gm.hud_node.show_notification("📜 Vazife Alındı: " + active_target_name + " (Ödül: " + str(active_reward_gold) + " Kuruş)", 4.0)

func _process(_delta: float) -> void:
	# Hedefin ölümünü kontrol et
	if active_target and is_instance_valid(active_target):
		if active_target.get("is_dead") or active_target.get("health") <= 0.0:
			_complete_active_contract()

func _complete_active_contract() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if "gold" in player:
			player.gold += active_reward_gold
		if "justice_points" in player:
			player.justice_points += 50
		if player.has_signal("gold_changed"):
			player.emit_signal("gold_changed", player.gold)
			
	var gm = get_tree().get_first_node_in_group("game_manager")
	if gm and "hud_node" in gm and gm.hud_node:
		gm.hud_node.show_notification("🏆 VAZİFE TAMAMLANDI: " + active_target_name + " bertaraf edildi! (+ " + str(active_reward_gold) + " Kuruş)", 5.0)
		gm.hud_node.set_quest_objective("Vazife Başarıyla Tamamlandı! Teşkilat panosundan yeni ferman alabilirsin.")
		
	if has_node("/root/SoundManager"):
		get_node("/root/SoundManager").play_quest_complete()
		
	active_target = null
	active_target_name = ""
