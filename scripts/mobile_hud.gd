extends CanvasLayer

# Cihanşah - Otantik Osmanlı Zaptiye Mobil Arayüzü & Yönetim Sistemi
# Tam Ekran Ana Menü, Bölümler Menüsü (6 Sefer), Seçenekler, Çarşı (Satın Alma),
# 8 Yönlü Otantik Osmanlı D-Pad, Omuz Üstü Nişangâh, Kırmızı Hedef Kilidi ve Eylem Düğmeleri

signal joystick_moved(vector: Vector2)
signal shoot_pressed()
signal reload_pressed()
signal aim_pressed()
signal gallop_pressed()
signal melee_pressed()
signal horse_pressed()
signal abdest_pressed()
signal interact_pressed()
signal jump_pressed()
signal sprint_pressed()
signal crouch_pressed()
signal map_toggled()

var player_ref: Node3D = null

# Menü Durumları
var is_in_main_menu: bool = true
var is_in_chapters: bool = false
var is_in_settings: bool = false
var is_in_shop: bool = false
var is_paused: bool = false

# D-Pad Değişkenleri (8-Yönlü Otantik Disk)
var dpad_active: bool = false
var dpad_touch_id: int = -1
var dpad_center: Vector2 = Vector2.ZERO
var dpad_radius: float = 90.0
var active_dpad_sector: int = -1 # 0..7

# Kamera Dokunmatik Kaydırma
var camera_touch_id: int = -1
var last_camera_touch_pos: Vector2 = Vector2.ZERO

# Kilitli Düşman ve Nişan Alma
var is_aiming_mode: bool = false
var locked_enemy_node: Node3D = null

# UI Düğümleri (Dinamik Oluşturulacak)
var root_hud: Control
var main_menu_overlay: Control
var chapters_overlay: Control
var settings_overlay: Control
var shop_overlay: Control
var pause_overlay: Control

var ingame_hud: Control
var dpad_container: Control
var dpad_rect: TextureRect
var dpad_glow_indicator: TextureRect

var health_bar_fill: ProgressBar
var health_val_label: Label
var stamina_bar_fill: ProgressBar
var stamina_val_label: Label
var gold_label: Label
var gem_label: Label
var ammo_label: Label
var ammo_sub_label: Label
var target_diamond: TextureRect
var target_info_label: Label
var quest_banner_text: Label
var message_banner: Panel
var message_text: Label
var prompt_btn: Button
var map_panel: Control
var crosshair_ctrl: Control

# Düğmeler ve Kapsayıcılar
var sprint_btn: TextureButton
var revolver_btn: TextureButton
var knife_btn: TextureButton
var melee_btn: TextureButton
var watch_btn: TextureButton
var jump_btn: TextureButton
var eye_btn: TextureButton
var aim_btn: TextureButton
var pause_btn: TextureButton
var map_btn: TextureButton
var smoke_btn: Button
var eagle_btn: Button

var top_right_box: Control
var action_box: Control
var quest_banner: Panel
var main_menu_column: VBoxContainer
var shop_container: Control
var menu_top_bar: HBoxContainer

func _ready() -> void:
	layer = 10
	# Mevcut tscn çocuklarını gizle veya temizle
	for child in get_children():
		child.visible = false
		
	_build_ui_tree()
	
	get_tree().root.size_changed.connect(_on_viewport_resized)
	_on_viewport_resized()
	
	# Başlangıçta Ana Menüyü Aç
	show_main_menu()

func _on_viewport_resized() -> void:
	var vp_size = get_viewport().get_visible_rect().size
	if top_right_box:
		top_right_box.position = Vector2(vp_size.x - 290, 18)
	if action_box:
		action_box.position = Vector2(vp_size.x - 470, vp_size.y - 250)
	if dpad_container:
		dpad_container.position = Vector2(70, vp_size.y - 240)
	if map_btn:
		map_btn.position = Vector2(15, vp_size.y - 170)
	if eye_btn:
		eye_btn.position = Vector2(15, vp_size.y - 240)
	if quest_banner:
		quest_banner.position = Vector2((vp_size.x - quest_banner.size.x) / 2.0, 58)
	if message_banner:
		message_banner.position = Vector2((vp_size.x - message_banner.size.x) / 2.0, 160)
	if prompt_btn:
		prompt_btn.position = Vector2((vp_size.x - prompt_btn.size.x) / 2.0, vp_size.y - 190)
	if main_menu_column:
		main_menu_column.position = Vector2((vp_size.x - main_menu_column.size.x) / 2.0, (vp_size.y - main_menu_column.size.y) / 2.0 - 20)
	if menu_top_bar:
		menu_top_bar.position = Vector2(vp_size.x - 240, 20)
	if shop_container:
		shop_container.position = Vector2(vp_size.x - 280, (vp_size.y / 2.0) - 20)

func _build_ui_tree() -> void:

	root_hud = Control.new()
	root_hud.name = "RootHUD"
	root_hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_hud)
	
	_build_in_game_hud()
	_build_main_menu()
	_build_chapters_menu()
	_build_settings_menu()
	_build_shop_menu()
	_build_pause_menu()
	_build_notifications_and_banners()

# =========================================================================
# 1. OYUN İÇİ HUD (ZAPTİYE D-PAD, EYLEM DÜĞMELERİ, SAĞLIK, NİŞAN)
# =========================================================================
func _build_in_game_hud() -> void:
	ingame_hud = Control.new()
	ingame_hud.name = "InGameHUD"
	ingame_hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	ingame_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ingame_hud.visible = false
	root_hud.add_child(ingame_hud)
	
	# --- SOL ÜST: CAN ÇUBUĞU & HARİTA PARŞÖMENİ ---
	var top_left = Control.new()
	top_left.position = Vector2(25, 20)
	top_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ingame_hud.add_child(top_left)
	
	# Can Çerçevesi (assets/ui/zaptiye_health_frame.png)
	var health_frame_tex = load("res://assets/ui/zaptiye_health_frame.png")
	var health_frame = TextureRect.new()
	health_frame.texture = health_frame_tex
	health_frame.custom_minimum_size = Vector2(220, 52)
	health_frame.size = Vector2(220, 52)
	health_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	top_left.add_child(health_frame)
	
	# 1. Can / Sağlık Barı (Üst Kısım)
	health_bar_fill = ProgressBar.new()
	health_bar_fill.position = Vector2(24, 11)
	health_bar_fill.size = Vector2(172, 18)
	health_bar_fill.max_value = 100.0
	health_bar_fill.value = 100.0
	health_bar_fill.show_percentage = false
	var bar_fill_style = StyleBoxFlat.new()
	bar_fill_style.bg_color = Color(0.18, 0.78, 0.22, 1.0) # Yeşil dolgu
	bar_fill_style.corner_radius_top_left = 4
	bar_fill_style.corner_radius_bottom_left = 2
	health_bar_fill.add_theme_stylebox_override("fill", bar_fill_style)
	var bar_bg_style = StyleBoxFlat.new()
	bar_bg_style.bg_color = Color(0.12, 0.08, 0.06, 0.85)
	health_bar_fill.add_theme_stylebox_override("background", bar_bg_style)
	top_left.add_child(health_bar_fill)
	
	health_val_label = Label.new()
	health_val_label.text = "100 / 100"
	health_val_label.position = Vector2(24, 11)
	health_val_label.size = Vector2(172, 18)
	health_val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	health_val_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	health_val_label.add_theme_font_size_override("font_size", 11)
	health_val_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	health_val_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	health_val_label.add_theme_constant_override("outline_size", 3)
	top_left.add_child(health_val_label)
	
	# 2. Koşma / Dayanıklılık Barı (Stamina - Alt Kısım)
	stamina_bar_fill = ProgressBar.new()
	stamina_bar_fill.position = Vector2(24, 32)
	stamina_bar_fill.size = Vector2(172, 11)
	stamina_bar_fill.max_value = 100.0
	stamina_bar_fill.value = 100.0
	stamina_bar_fill.show_percentage = false
	var st_fill = StyleBoxFlat.new()
	st_fill.bg_color = Color(0.96, 0.74, 0.16, 1.0) # Canlı Kehribar/Altın Sarısı Koşma Barı
	st_fill.corner_radius_top_left = 2
	st_fill.corner_radius_bottom_left = 4
	st_fill.corner_radius_top_right = 2
	st_fill.corner_radius_bottom_right = 2
	stamina_bar_fill.add_theme_stylebox_override("fill", st_fill)
	var st_bg = StyleBoxFlat.new()
	st_bg.bg_color = Color(0.08, 0.06, 0.04, 0.85)
	stamina_bar_fill.add_theme_stylebox_override("background", st_bg)
	top_left.add_child(stamina_bar_fill)
	
	stamina_val_label = Label.new()
	stamina_val_label.text = "⚡ KOŞMA %100"
	stamina_val_label.position = Vector2(24, 30)
	stamina_val_label.size = Vector2(172, 13)
	stamina_val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stamina_val_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stamina_val_label.add_theme_font_size_override("font_size", 9)
	stamina_val_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8))
	stamina_val_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	stamina_val_label.add_theme_constant_override("outline_size", 2)
	top_left.add_child(stamina_val_label)
	
	# Harita Parşömen Butonu (Can çubuğunun altında)
	map_btn = TextureButton.new()
	map_btn.texture_normal = load("res://assets/ui/zaptiye_map_scroll.png")
	map_btn.position = Vector2(0, 560) # Sol altta harita parşömeni (ekran görüntüsündeki gibi)
	map_btn.custom_minimum_size = Vector2(76, 52)
	map_btn.size = Vector2(76, 52)
	map_btn.ignore_texture_size = true
	map_btn.stretch_mode = TextureButton.STRETCH_SCALE
	map_btn.pressed.connect(toggle_map)
	ingame_hud.add_child(map_btn)
	
	# --- SAĞ ÜST: DURAKLATMA (ROMA II), AKÇE, MÜCEVHER SAYACI ---
	top_right_box = Control.new()
	top_right_box.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	top_right_box.position = Vector2(1280 - 280, 18)
	top_right_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ingame_hud.add_child(top_right_box)
	
	# Mücevher Göstergesi
	var gem_icon = TextureRect.new()
	gem_icon.texture = load("res://assets/ui/zaptiye_icon_gem.png")
	gem_icon.position = Vector2(0, 6)
	gem_icon.size = Vector2(26, 26)
	gem_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	top_right_box.add_child(gem_icon)
	
	gem_label = Label.new()
	gem_label.text = "4\n+4"
	gem_label.position = Vector2(30, 0)
	gem_label.add_theme_font_size_override("font_size", 13)
	gem_label.add_theme_color_override("font_color", Color(0.65, 0.9, 1.0))
	gem_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	gem_label.add_theme_constant_override("outline_size", 2)
	top_right_box.add_child(gem_label)
	
	# Akçe Göstergesi
	var akce_icon = TextureRect.new()
	akce_icon.texture = load("res://assets/ui/zaptiye_icon_akce.png")
	akce_icon.position = Vector2(90, 6)
	akce_icon.size = Vector2(26, 26)
	akce_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	top_right_box.add_child(akce_icon)
	
	gold_label = Label.new()
	gold_label.text = "27350\n+100"
	gold_label.position = Vector2(122, 0)
	gold_label.add_theme_font_size_override("font_size", 13)
	gold_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	gold_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	gold_label.add_theme_constant_override("outline_size", 2)
	top_right_box.add_child(gold_label)
	
	# Roma Rakamı II Duraklatma Düğmesi
	pause_btn = TextureButton.new()
	pause_btn.texture_normal = load("res://assets/ui/zaptiye_btn_pause.png")
	pause_btn.position = Vector2(215, 0)
	pause_btn.size = Vector2(46, 46)
	pause_btn.ignore_texture_size = true
	pause_btn.stretch_mode = TextureButton.STRETCH_SCALE
	pause_btn.pressed.connect(toggle_pause)
	top_right_box.add_child(pause_btn)

	
	# --- SOL ALT: 8-YÖNLÜ OSMANLI D-PAD TABLETİ (JOYİSTİK DEĞİL) ---
	dpad_container = Control.new()
	dpad_container.name = "OttomanDPad"
	dpad_container.position = Vector2(110, 480)
	dpad_container.size = Vector2(190, 190)
	dpad_container.mouse_filter = Control.MOUSE_FILTER_PASS
	ingame_hud.add_child(dpad_container)
	
	dpad_rect = TextureRect.new()
	dpad_rect.texture = load("res://assets/ui/zaptiye_dpad.png")
	dpad_rect.size = Vector2(190, 190)
	dpad_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dpad_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dpad_container.add_child(dpad_rect)
	
	# Aktif yön parlaması
	dpad_glow_indicator = TextureRect.new()
	dpad_glow_indicator.texture = load("res://assets/ui/zaptiye_icon_akce.png")
	dpad_glow_indicator.size = Vector2(28, 28)
	dpad_glow_indicator.modulate = Color(1.8, 1.4, 0.3, 0.85)
	dpad_glow_indicator.visible = false
	dpad_glow_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dpad_container.add_child(dpad_glow_indicator)
	
	# --- SAĞ ALT: EYLEM DÜĞMELERİ KÜMESİ (GÖRSELDEKİ BİREBİR YERLEŞİM) ---
	action_box = Control.new()
	action_box.name = "ActionBox"
	action_box.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	action_box.position = Vector2(1280 - 460, 720 - 240)
	action_box.size = Vector2(460, 240)
	action_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ingame_hud.add_child(action_box)

	
	# 1. Altıpatlar Silindiri Ateş / Doldur (Revolver)
	revolver_btn = TextureButton.new()
	revolver_btn.texture_normal = load("res://assets/ui/zaptiye_revolver_btn.png")
	revolver_btn.position = Vector2(245, 125)
	revolver_btn.size = Vector2(86, 86)
	revolver_btn.ignore_texture_size = true
	revolver_btn.stretch_mode = TextureButton.STRETCH_SCALE
	revolver_btn.pressed.connect(_on_revolver_tapped)
	action_box.add_child(revolver_btn)
	
	ammo_label = Label.new()
	ammo_label.text = "6"
	ammo_label.position = Vector2(245, 150)
	ammo_label.size = Vector2(86, 26)
	ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ammo_label.add_theme_font_size_override("font_size", 18)
	ammo_label.add_theme_color_override("font_color", Color(1, 0.95, 0.8))
	ammo_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	ammo_label.add_theme_constant_override("outline_size", 3)
	action_box.add_child(ammo_label)
	
	ammo_sub_label = Label.new()
	ammo_sub_label.text = "18"
	ammo_sub_label.position = Vector2(245, 208)
	ammo_sub_label.size = Vector2(86, 18)
	ammo_sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ammo_sub_label.add_theme_font_size_override("font_size", 11)
	ammo_sub_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
	action_box.add_child(ammo_sub_label)
	
	# 2. Altın Koşma / Sprint Düğmesi (Görseldeki büyük yanan adam)
	sprint_btn = TextureButton.new()
	sprint_btn.texture_normal = load("res://assets/ui/zaptiye_sprint_btn.png")
	sprint_btn.position = Vector2(345, 10)
	sprint_btn.size = Vector2(95, 95)
	sprint_btn.ignore_texture_size = true
	sprint_btn.stretch_mode = TextureButton.STRETCH_SCALE
	sprint_btn.pressed.connect(func(): emit_signal("sprint_pressed"))
	action_box.add_child(sprint_btn)
	
	# 3. Zıplama / Dörtnala Butonu (Sprintin hemen sağında)
	jump_btn = TextureButton.new()
	jump_btn.texture_normal = load("res://assets/ui/zaptiye_jump_btn.png")
	jump_btn.position = Vector2(375, 115)
	jump_btn.size = Vector2(68, 68)
	jump_btn.ignore_texture_size = true
	jump_btn.stretch_mode = TextureButton.STRETCH_SCALE
	jump_btn.pressed.connect(func(): emit_signal("jump_pressed"))
	action_box.add_child(jump_btn)
	
	# 4. Fırlatma Hançerleri (Daggers)
	knife_btn = TextureButton.new()
	knife_btn.texture_normal = load("res://assets/ui/zaptiye_knife_btn.png")
	knife_btn.position = Vector2(145, 130)
	knife_btn.size = Vector2(78, 78)
	knife_btn.ignore_texture_size = true
	knife_btn.stretch_mode = TextureButton.STRETCH_SCALE
	knife_btn.pressed.connect(_on_knife_tapped)
	action_box.add_child(knife_btn)
	
	# 5. Yakın Dövüş Yumruğu (Melee)
	melee_btn = TextureButton.new()
	melee_btn.texture_normal = load("res://assets/ui/zaptiye_melee_btn.png")
	melee_btn.position = Vector2(345, 175)
	melee_btn.size = Vector2(74, 74)
	melee_btn.ignore_texture_size = true
	melee_btn.stretch_mode = TextureButton.STRETCH_SCALE
	melee_btn.pressed.connect(func(): emit_signal("melee_pressed"))
	action_box.add_child(melee_btn)
	
	# 6. Köstekli Saat (Zaman Yavaşlatma / Focus)
	watch_btn = TextureButton.new()
	watch_btn.texture_normal = load("res://assets/ui/zaptiye_watch_btn.png")
	watch_btn.position = Vector2(55, 140)
	watch_btn.size = Vector2(68, 68)
	watch_btn.ignore_texture_size = true
	watch_btn.stretch_mode = TextureButton.STRETCH_SCALE
	watch_btn.pressed.connect(_on_watch_tapped)
	action_box.add_child(watch_btn)

	# Sis Bombası Butonu (Smoke Bomb)
	smoke_btn = Button.new()
	smoke_btn.name = "SmokeBtn"
	smoke_btn.text = "💨"
	smoke_btn.position = Vector2(70, 68)
	smoke_btn.size = Vector2(58, 58)
	var s_style = StyleBoxFlat.new()
	s_style.bg_color = Color(0.22, 0.22, 0.25, 0.88)
	s_style.border_color = Color(0.85, 0.85, 0.9, 0.85)
	s_style.border_width_bottom = 2
	s_style.border_width_top = 2
	s_style.border_width_left = 2
	s_style.border_width_right = 2
	s_style.corner_radius_bottom_left = 29
	s_style.corner_radius_bottom_right = 29
	s_style.corner_radius_top_left = 29
	s_style.corner_radius_top_right = 29
	smoke_btn.add_theme_stylebox_override("normal", s_style)
	smoke_btn.add_theme_font_size_override("font_size", 24)
	smoke_btn.pressed.connect(func():
		if player_ref and player_ref.has_method("throw_smoke_bomb"):
			player_ref.throw_smoke_bomb()
	)
	action_box.add_child(smoke_btn)

	# 7. Göz / Gizlenme (Crouch / Sneak) - Sol altta
	eye_btn = TextureButton.new()
	eye_btn.texture_normal = load("res://assets/ui/zaptiye_eye_btn.png")
	eye_btn.position = Vector2(25, 490)
	eye_btn.size = Vector2(62, 62)
	eye_btn.ignore_texture_size = true
	eye_btn.stretch_mode = TextureButton.STRETCH_SCALE
	eye_btn.pressed.connect(func(): emit_signal("crouch_pressed"))
	ingame_hud.add_child(eye_btn)

	# Kartal Görüşü (Eagle Vision) Butonu
	eagle_btn = Button.new()
	eagle_btn.name = "EagleVisionBtn"
	eagle_btn.text = "🦅"
	eagle_btn.position = Vector2(25, 415)
	eagle_btn.size = Vector2(58, 58)
	var e_style = StyleBoxFlat.new()
	e_style.bg_color = Color(0.1, 0.2, 0.35, 0.88)
	e_style.border_color = Color(0.35, 0.78, 1.0, 0.9)
	e_style.border_width_bottom = 2
	e_style.border_width_top = 2
	e_style.border_width_left = 2
	e_style.border_width_right = 2
	e_style.corner_radius_bottom_left = 29
	e_style.corner_radius_bottom_right = 29
	e_style.corner_radius_top_left = 29
	e_style.corner_radius_top_right = 29
	eagle_btn.add_theme_stylebox_override("normal", e_style)
	eagle_btn.add_theme_font_size_override("font_size", 24)
	eagle_btn.pressed.connect(func():
		if player_ref and player_ref.has_method("toggle_eagle_vision"):
			player_ref.toggle_eagle_vision()
	)
	ingame_hud.add_child(eagle_btn)
	
	# 8. Nişan Alma Geçiş Düğmesi (Ekran ortasında veya sağda tetiklenebilir)
	aim_btn = TextureButton.new()
	aim_btn.texture_normal = load("res://assets/ui/zaptiye_target_diamond.png")
	aim_btn.position = Vector2(1280 - 180, 720 - 240)
	aim_btn.size = Vector2(58, 58)
	aim_btn.modulate = Color(1.2, 1.2, 0.4, 0.8)
	aim_btn.ignore_texture_size = true
	aim_btn.stretch_mode = TextureButton.STRETCH_SCALE
	aim_btn.pressed.connect(func(): emit_signal("aim_pressed"))
	ingame_hud.add_child(aim_btn)
	
	# --- NİŞANGÂH & KIRMIZI HEDEF KİLİT ELMASI ---
	crosshair_ctrl = Control.new()
	crosshair_ctrl.set_anchors_preset(Control.PRESET_CENTER)
	crosshair_ctrl.position = Vector2(640, 360)
	crosshair_ctrl.visible = false
	ingame_hud.add_child(crosshair_ctrl)
	_draw_crosshair(crosshair_ctrl)
	
	# Kırmızı Hedef Kilit Elması (Ekran görüntüsü 5'teki düşman üzerindeki elmas)
	target_diamond = TextureRect.new()
	target_diamond.texture = load("res://assets/ui/zaptiye_target_diamond.png")
	target_diamond.size = Vector2(46, 46)
	target_diamond.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	target_diamond.visible = false
	target_diamond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ingame_hud.add_child(target_diamond)
	
	target_info_label = Label.new()
	target_info_label.text = ""
	target_info_label.position = Vector2(-60, 48)
	target_info_label.size = Vector2(166, 20)
	target_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target_info_label.add_theme_font_size_override("font_size", 11)
	target_info_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	target_info_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	target_info_label.add_theme_constant_override("outline_size", 2)
	target_diamond.add_child(target_info_label)

func _draw_crosshair(parent: Control) -> void:
	for offset in [Vector2(-18, -2), Vector2(10, -2), Vector2(-2, -18), Vector2(-2, 10)]:
		var tick = ColorRect.new()
		tick.color = Color(1.0, 0.9, 0.4, 0.9)
		if offset.x == -2:
			tick.size = Vector2(4, 10)
		else:
			tick.size = Vector2(10, 4)
		tick.position = offset
		parent.add_child(tick)

# =========================================================================
# 2. ANA SAYFA (ANA MENÜ) - GÖRSEL 3'TEKİ BİREBİR TASARIM
# =========================================================================
func _build_main_menu() -> void:
	main_menu_overlay = Control.new()
	main_menu_overlay.name = "MainMenuOverlay"
	main_menu_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_hud.add_child(main_menu_overlay)
	
	# Arka Plan Sepya Zaptiye Duvar Kağıdı
	var bg = TextureRect.new()
	bg.texture = load("res://assets/ui/zaptiye_menu_bg.jpg")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	main_menu_overlay.add_child(bg)
	
	# Üst Bar: Mücevher ve Akçe
	menu_top_bar = HBoxContainer.new()
	menu_top_bar.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	menu_top_bar.position = Vector2(1280 - 240, 20)
	menu_top_bar.add_theme_constant_override("separation", 24)
	main_menu_overlay.add_child(menu_top_bar)
	
	var gem_box = HBoxContainer.new()
	var gi = TextureRect.new()
	gi.texture = load("res://assets/ui/zaptiye_icon_gem.png")
	gi.custom_minimum_size = Vector2(28, 28)
	gi.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var gl = Label.new()
	gl.text = "4"
	gl.add_theme_font_size_override("font_size", 18)
	gl.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	gem_box.add_child(gi)
	gem_box.add_child(gl)
	menu_top_bar.add_child(gem_box)
	
	var gold_box = HBoxContainer.new()
	var ai = TextureRect.new()
	ai.texture = load("res://assets/ui/zaptiye_icon_akce.png")
	ai.custom_minimum_size = Vector2(28, 28)
	ai.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var al = Label.new()
	al.text = "27350"
	al.add_theme_font_size_override("font_size", 18)
	al.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	gold_box.add_child(ai)
	gold_box.add_child(al)
	menu_top_bar.add_child(gold_box)
	
	# Ortadaki Dikey Menü Düğmeleri (Görsel 3)
	main_menu_column = VBoxContainer.new()
	main_menu_column.position = Vector2(560, 130)
	main_menu_column.custom_minimum_size = Vector2(160, 480)
	main_menu_column.add_theme_constant_override("separation", 18)
	main_menu_column.alignment = BoxContainer.ALIGNMENT_CENTER
	main_menu_overlay.add_child(main_menu_column)
	
	# 1. Başla
	var btn_start = _create_circular_menu_btn(load("res://assets/ui/zaptiye_btn_start.png"), "Başla")
	btn_start.get_node("Btn").pressed.connect(_on_start_game_pressed)
	main_menu_column.add_child(btn_start)
	
	# 2. Bölümler
	var btn_chapters = _create_circular_menu_btn(load("res://assets/ui/zaptiye_btn_settings.png"), "Bölümler")
	btn_chapters.get_node("Btn").pressed.connect(show_chapters_menu)
	main_menu_column.add_child(btn_chapters)
	
	# 3. Seçenekler
	var btn_settings = _create_circular_menu_btn(load("res://assets/ui/zaptiye_btn_settings.png"), "Seçenekler")
	btn_settings.get_node("Btn").pressed.connect(show_settings_menu)
	main_menu_column.add_child(btn_settings)
	
	# 4. Satın Alma (Sağ ortada dikey hiza)
	shop_container = Control.new()
	shop_container.position = Vector2(1000, 360)
	var btn_shop = _create_circular_menu_btn(load("res://assets/ui/zaptiye_btn_shop.png"), "Satın alma")
	btn_shop.get_node("Btn").pressed.connect(show_shop_menu)
	shop_container.add_child(btn_shop)
	main_menu_overlay.add_child(shop_container)

	
	# 5. Çıkış (En altta)
	var btn_exit = _create_circular_menu_btn(load("res://assets/ui/zaptiye_btn_exit.png"), "Çıkış")
	btn_exit.get_node("Btn").pressed.connect(func(): get_tree().quit())
	main_menu_column.add_child(btn_exit)

	
	# Dil Butonu (Sol altta [A/文])
	var lang_box = Panel.new()
	lang_box.position = Vector2(240, 620)
	lang_box.size = Vector2(64, 48)
	var style_lang = StyleBoxFlat.new()
	style_lang.bg_color = Color(0.9, 0.85, 0.75, 0.6)
	style_lang.corner_radius_top_left = 12
	style_lang.corner_radius_top_right = 12
	style_lang.corner_radius_bottom_right = 12
	style_lang.corner_radius_bottom_left = 12
	lang_box.add_theme_stylebox_override("panel", style_lang)
	var lang_lbl = Label.new()
	lang_lbl.text = "A 文"
	lang_lbl.position = Vector2(0, 10)
	lang_lbl.size = Vector2(64, 28)
	lang_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lang_lbl.add_theme_font_size_override("font_size", 16)
	lang_lbl.add_theme_color_override("font_color", Color(0.15, 0.12, 0.08))
	lang_box.add_child(lang_lbl)
	main_menu_overlay.add_child(lang_box)

func _create_circular_menu_btn(tex: Texture2D, label_text: String) -> Control:
	var root = Control.new()
	root.custom_minimum_size = Vector2(140, 100)
	
	var btn = TextureButton.new()
	btn.name = "Btn"
	btn.texture_normal = tex
	btn.position = Vector2(25, 0)
	btn.size = Vector2(88, 88)
	btn.ignore_texture_size = true
	btn.stretch_mode = TextureButton.STRETCH_SCALE
	root.add_child(btn)
	
	var lbl = Label.new()
	lbl.text = label_text
	lbl.position = Vector2(0, 88)
	lbl.size = Vector2(140, 24)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.add_theme_color_override("font_color", Color(0.18, 0.15, 0.12))
	lbl.add_theme_color_override("font_outline_color", Color(1, 0.95, 0.8, 0.8))
	lbl.add_theme_constant_override("outline_size", 2)
	root.add_child(lbl)
	
	return root

# =========================================================================
# 3. BÖLÜMLER MENÜSÜ - GÖRSEL 4'TEKİ BİREBİR TASARIM VE 6 SEFER
# =========================================================================
func _build_chapters_menu() -> void:
	chapters_overlay = Control.new()
	chapters_overlay.name = "ChaptersOverlay"
	chapters_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	chapters_overlay.visible = false
	root_hud.add_child(chapters_overlay)
	
	# Arka Plan
	var bg = TextureRect.new()
	bg.texture = load("res://assets/ui/zaptiye_menu_bg.jpg")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	chapters_overlay.add_child(bg)
	
	# Yarı saydam tül
	var tint = ColorRect.new()
	tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	tint.color = Color(0.08, 0.06, 0.04, 0.45)
	chapters_overlay.add_child(tint)
	
	# Başlık
	var title = Label.new()
	title.text = "Bölümler"
	title.position = Vector2(540, 35)
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.15, 0.12, 0.08))
	title.add_theme_color_override("font_outline_color", Color(1.0, 0.95, 0.8))
	title.add_theme_constant_override("outline_size", 3)
	chapters_overlay.add_child(title)
	
	# Bölüm Listesi
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(260, 95)
	scroll.size = Vector2(760, 530)
	chapters_overlay.add_child(scroll)
	
	var list_box = VBoxContainer.new()
	list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_box.add_theme_constant_override("separation", 24)
	scroll.add_child(list_box)
	
	var chapters_data = [
		{"id": 0, "title": "Rami", "sub": "Çocukluk dönemi - Manevi Huzur & Talim"},
		{"id": 1, "title": "Han Baskını", "sub": "Vazifeler - Dimitri Casus Sorgusu & Pusu"},
		{"id": 2, "title": "Samatya", "sub": "Karakol ve Eşkıya - Gece Sokak Çatışmaları"},
		{"id": 3, "title": "Kapalıçarşı", "sub": "AYI KİKOR Düellosu (Bölüm Sonu Boss)"},
		{"id": 4, "title": "Kavala", "sub": "Hain Avni Paşa'nın İzinde - Kale Sığınağı"},
		{"id": 5, "title": "Çanakkale", "sub": "1915 Büyük Taarruz & Siper Savunması"}
	]
	
	for ch in chapters_data:
		var row = _create_chapter_row(ch["id"], ch["title"], ch["sub"])
		list_box.add_child(row)
		
	# Geri Düğmesi (Görsel 4'teki yuvarlak Geri butonu)
	var back_container = Control.new()
	back_container.position = Vector2(240, 600)
	var back_btn = TextureButton.new()
	back_btn.texture_normal = load("res://assets/ui/zaptiye_btn_back.png")
	back_btn.size = Vector2(68, 68)
	back_btn.ignore_texture_size = true
	back_btn.stretch_mode = TextureButton.STRETCH_SCALE
	back_btn.pressed.connect(show_main_menu)
	back_container.add_child(back_btn)
	
	var back_lbl = Label.new()
	back_lbl.text = "Geri"
	back_lbl.position = Vector2(0, 70)
	back_lbl.size = Vector2(68, 20)
	back_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	back_lbl.add_theme_font_size_override("font_size", 14)
	back_lbl.add_theme_color_override("font_color", Color(0.18, 0.15, 0.1))
	back_container.add_child(back_lbl)
	chapters_overlay.add_child(back_container)

func _create_chapter_row(id: int, title_text: String, sub_text: String) -> Control:
	var row = Control.new()
	row.custom_minimum_size = Vector2(740, 70)
	
	# Sol yuvarlak süs madalyonu
	var medallion = TextureRect.new()
	medallion.texture = load("res://assets/ui/zaptiye_btn_back.png")
	medallion.position = Vector2(10, 6)
	medallion.size = Vector2(58, 58)
	medallion.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	row.add_child(medallion)
	
	# Başlık ve Açıklama
	var title = Label.new()
	title.text = title_text
	title.position = Vector2(90, 8)
	title.size = Vector2(460, 26)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.15, 0.35, 0.18) if id == 0 else Color(0.15, 0.12, 0.08))
	title.add_theme_color_override("font_outline_color", Color(1, 0.95, 0.8))
	title.add_theme_constant_override("outline_size", 2)
	row.add_child(title)
	
	var sub = Label.new()
	sub.text = sub_text
	sub.position = Vector2(90, 36)
	sub.size = Vector2(460, 20)
	sub.add_theme_font_size_override("font_size", 13)
	sub.add_theme_color_override("font_color", Color(0.28, 0.22, 0.18))
	row.add_child(sub)
	
	# Yeşil Oval "Git" Düğmesi (Görsel 4)
	var git_btn = TextureButton.new()
	git_btn.texture_normal = load("res://assets/ui/zaptiye_btn_git.png")
	git_btn.position = Vector2(580, 10)
	git_btn.size = Vector2(145, 48)
	git_btn.ignore_texture_size = true
	git_btn.stretch_mode = TextureButton.STRETCH_SCALE
	git_btn.pressed.connect(func(): _on_select_chapter(id))
	row.add_child(git_btn)
	
	return row

func _on_select_chapter(chapter_id: int) -> void:
	if has_node("/root/SoundManager"):
		get_node("/root/SoundManager").play_ui_click()
	chapters_overlay.visible = false
	main_menu_overlay.visible = false
	ingame_hud.visible = true
	is_in_main_menu = false
	
	if player_ref:
		player_ref.set_menu_active(false)
		
	var gm = get_tree().get_first_node_in_group("game_manager")
	if gm and gm.has_method("start_chapter"):
		gm.start_chapter(chapter_id)

# =========================================================================
# 4. SEÇENEKLER & AYARLAR MENÜSÜ
# =========================================================================
func _build_settings_menu() -> void:
	settings_overlay = Control.new()
	settings_overlay.name = "SettingsOverlay"
	settings_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	settings_overlay.visible = false
	root_hud.add_child(settings_overlay)
	
	var bg = TextureRect.new()
	bg.texture = load("res://assets/ui/zaptiye_menu_bg.jpg")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	settings_overlay.add_child(bg)
	
	var tint = ColorRect.new()
	tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	tint.color = Color(0.06, 0.05, 0.04, 0.65)
	settings_overlay.add_child(tint)
	
	var box = Panel.new()
	box.position = Vector2(340, 80)
	box.size = Vector2(600, 560)
	var pstyle = StyleBoxFlat.new()
	pstyle.bg_color = Color(0.12, 0.09, 0.07, 0.95)
	pstyle.border_width_left = 3
	pstyle.border_width_top = 3
	pstyle.border_width_right = 3
	pstyle.border_width_bottom = 3
	pstyle.border_color = Color(0.85, 0.72, 0.3)
	pstyle.corner_radius_top_left = 14
	pstyle.corner_radius_top_right = 14
	pstyle.corner_radius_bottom_right = 14
	pstyle.corner_radius_bottom_left = 14
	box.add_theme_stylebox_override("panel", pstyle)
	settings_overlay.add_child(box)
	
	var title = Label.new()
	title.text = "⚔️ SEÇENEKLER & TEKNİK AYARLAR"
	title.position = Vector2(0, 20)
	title.size = Vector2(600, 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	box.add_child(title)
	
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(50, 70)
	vbox.size = Vector2(500, 420)
	vbox.add_theme_constant_override("separation", 18)
	box.add_child(vbox)
	
	# FPS Kilidi
	var fps_box = HBoxContainer.new()
	var fps_lbl = Label.new()
	fps_lbl.text = "Kare Hızı (FPS Kilidi): "
	fps_lbl.custom_minimum_size = Vector2(220, 30)
	var fps30 = Button.new()
	fps30.text = "30 FPS"
	fps30.pressed.connect(func(): Engine.max_fps = 30; show_notification("FPS 30'a sabitlendi."))
	var fps60 = Button.new()
	fps60.text = "60 FPS"
	fps60.pressed.connect(func(): Engine.max_fps = 60; show_notification("FPS 60'a sabitlendi."))
	var fps_unl = Button.new()
	fps_unl.text = "Sınırsız"
	fps_unl.pressed.connect(func(): Engine.max_fps = 0; show_notification("Kare hızı sınırı kaldırıldı."))
	fps_box.add_child(fps_lbl)
	fps_box.add_child(fps30)
	fps_box.add_child(fps60)
	fps_box.add_child(fps_unl)
	vbox.add_child(fps_box)
	
	# Tam Ekran
	var fs_box = HBoxContainer.new()
	var fs_lbl = Label.new()
	fs_lbl.text = "Ekran Modu: "
	fs_lbl.custom_minimum_size = Vector2(220, 30)
	var fs_btn = Button.new()
	fs_btn.text = "Tam Ekran Aç / Kapat"
	fs_btn.pressed.connect(func():
		var mode = DisplayServer.window_get_mode()
		if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	)
	fs_box.add_child(fs_lbl)
	fs_box.add_child(fs_btn)
	vbox.add_child(fs_box)
	
	# Kamera Hassasiyeti
	var sens_box = VBoxContainer.new()
	var sens_lbl = Label.new()
	sens_lbl.text = "Nişan & Kamera Hassasiyeti:"
	var sens_slider = HSlider.new()
	sens_slider.min_value = 0.001
	sens_slider.max_value = 0.008
	sens_slider.step = 0.0005
	sens_slider.value = 0.003
	sens_slider.value_changed.connect(func(val):
		if player_ref:
			player_ref.mouse_sensitivity = val
	)
	sens_box.add_child(sens_lbl)
	sens_box.add_child(sens_slider)
	vbox.add_child(sens_box)
	
	# Ses Seviyesi
	var vol_box = VBoxContainer.new()
	var vol_lbl = Label.new()
	vol_lbl.text = "Oyun Sesleri & Efektler:"
	var vol_slider = HSlider.new()
	vol_slider.min_value = 0.0
	vol_slider.max_value = 1.0
	vol_slider.step = 0.05
	vol_slider.value = 0.8
	vol_slider.value_changed.connect(func(val):
		AudioServer.set_bus_volume_db(0, linear_to_db(val))
	)
	vol_box.add_child(vol_lbl)
	vol_box.add_child(vol_slider)
	vbox.add_child(vol_box)
	
	# Google Play Games Bulut Kayıt (Cloud Save) Durum Paneli
	var gpg_panel = Panel.new()
	gpg_panel.custom_minimum_size = Vector2(500, 52)
	var gpg_style = StyleBoxFlat.new()
	gpg_style.bg_color = Color(0.06, 0.16, 0.08, 0.9)
	gpg_style.border_width_left = 2
	gpg_style.border_width_top = 2
	gpg_style.border_width_right = 2
	gpg_style.border_width_bottom = 2
	gpg_style.border_color = Color(0.2, 0.85, 0.35, 0.9)
	gpg_style.corner_radius_top_left = 8
	gpg_style.corner_radius_top_right = 8
	gpg_style.corner_radius_bottom_right = 8
	gpg_style.corner_radius_bottom_left = 8
	gpg_panel.add_theme_stylebox_override("panel", gpg_style)
	
	var gpg_title = Label.new()
	gpg_title.text = "🎮 Google Play Games: Oturum Açıldı (Bulut Senkronizasyonu Aktif)"
	gpg_title.position = Vector2(10, 6)
	gpg_title.size = Vector2(480, 20)
	gpg_title.add_theme_font_size_override("font_size", 12)
	gpg_title.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
	gpg_panel.add_child(gpg_title)
	
	var gpg_sub = Label.new()
	gpg_sub.text = "Ücretsiz Google Bulut Hizmeti: Seviye, Akçe, Mücevher ve Bölümler otomatik senkronizedir."
	gpg_sub.position = Vector2(10, 28)
	gpg_sub.size = Vector2(480, 18)
	gpg_sub.add_theme_font_size_override("font_size", 10)
	gpg_sub.add_theme_color_override("font_color", Color(0.85, 0.95, 0.85))
	gpg_panel.add_child(gpg_sub)
	vbox.add_child(gpg_panel)
	
	# Şimdi Buluta / Yerel Depolamaya Kaydet Butonu
	var save_cloud_btn = Button.new()
	save_cloud_btn.text = "💾 İLERLEMEYİ ŞİMDİ KAYDET (BULUT & YEREL)"
	save_cloud_btn.custom_minimum_size = Vector2(500, 42)
	save_cloud_btn.pressed.connect(func():
		var sm = get_node_or_null("/root/SaveManager")
		if sm:
			var ch = 0
			var gm = get_tree().get_first_node_in_group("game_manager")
			if gm and "current_quest_stage" in gm:
				ch = gm.current_quest_stage
			sm.save_game(player_ref, ch)
		show_notification("💾 Google Play Games Bulutuna & Yerel Hafızaya Başarıyla Kaydedildi!", 3.0)
	)
	vbox.add_child(save_cloud_btn)
	
	# Butonlar: Kaydet ve Geri Dön / Kaydetmeden Geri Dön
	var btn_row = HBoxContainer.new()
	btn_row.custom_minimum_size = Vector2(500, 44)
	btn_row.add_theme_constant_override("separation", 16)
	
	var save_and_close = Button.new()
	save_and_close.text = "KAYDET VE GERİ DÖN"
	save_and_close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_and_close.pressed.connect(func():
		var sm = get_node_or_null("/root/SaveManager")
		if sm:
			var ch = 0
			var gm = get_tree().get_first_node_in_group("game_manager")
			if gm and "current_quest_stage" in gm:
				ch = gm.current_quest_stage
			sm.save_game(player_ref, ch)
		settings_overlay.visible = false
		if is_paused:
			pause_overlay.visible = true
		else:
			show_main_menu()
		show_notification("Ayarlar ve İlerleme Kaydedildi.", 2.0)
	)
	btn_row.add_child(save_and_close)
	
	var cancel_and_close = Button.new()
	cancel_and_close.text = "KAYDETMEDEN GERİ DÖN"
	cancel_and_close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_and_close.pressed.connect(func():
		settings_overlay.visible = false
		if is_paused:
			pause_overlay.visible = true
		else:
			show_main_menu()
		show_notification("Değişiklikler kaydedilmedi.", 1.5)
	)
	btn_row.add_child(cancel_and_close)
	
	vbox.add_child(btn_row)


# =========================================================================
# 5. SATIN ALMA (KAPALIÇARŞI CEPHANELİĞİ)
# =========================================================================
func _build_shop_menu() -> void:
	shop_overlay = Control.new()
	shop_overlay.name = "ShopOverlay"
	shop_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	shop_overlay.visible = false
	root_hud.add_child(shop_overlay)
	
	var tint = ColorRect.new()
	tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	tint.color = Color(0.08, 0.06, 0.04, 0.75)
	shop_overlay.add_child(tint)
	
	var box = Panel.new()
	box.position = Vector2(280, 60)
	box.size = Vector2(720, 600)
	var pstyle = StyleBoxFlat.new()
	pstyle.bg_color = Color(0.12, 0.09, 0.07, 0.95)
	pstyle.border_width_left = 3
	pstyle.border_width_top = 3
	pstyle.border_width_right = 3
	pstyle.border_width_bottom = 3
	pstyle.border_color = Color(0.85, 0.72, 0.3)
	pstyle.corner_radius_top_left = 14
	pstyle.corner_radius_top_right = 14
	pstyle.corner_radius_bottom_right = 14
	pstyle.corner_radius_bottom_left = 14
	box.add_theme_stylebox_override("panel", pstyle)
	shop_overlay.add_child(box)
	
	var title = Label.new()
	title.text = "🕌 KAPALIÇARŞI CEPHANELİĞİ (SATIN ALMA)"
	title.position = Vector2(0, 18)
	title.size = Vector2(720, 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	box.add_child(title)
	
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(40, 65)
	scroll.size = Vector2(640, 460)
	box.add_child(scroll)
	
	var list_box = VBoxContainer.new()
	list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_box.add_theme_constant_override("separation", 14)
	scroll.add_child(list_box)
	
	var items = [
		{"name": "Mauser Uzun Namlulu Osmanlı Tüfeği", "cost": 1200, "desc": "Menzilli yüksek hasar veren keskin nişancı tüfeği"},
		{"name": "Fırlatma Hançeri (5x Demet)", "cost": 300, "desc": "Sessiz ve ölümcül suikast hançerleri"},
		{"name": "Osmanlı Çelik Göğüslük & Zırh", "cost": 2500, "desc": "Gelen hasarı %40 oranında soğuran zaptiye zırhı"},
		{"name": "Gülbatur Yarış Nalları & Eyeri", "cost": 800, "desc": "Atın dörtnala koşma hızını %35 artırır"},
		{"name": "Şifalı Lokman Hekim İksiri", "cost": 150, "desc": "Canı anında 100 HP'ye yeniler"}
	]
	
	for it in items:
		var item_row = HBoxContainer.new()
		item_row.custom_minimum_size = Vector2(620, 50)
		
		var info = VBoxContainer.new()
		info.custom_minimum_size = Vector2(450, 40)
		var iname = Label.new()
		iname.text = it["name"] + "  (" + str(it["cost"]) + " Akçe)"
		iname.add_theme_font_size_override("font_size", 16)
		iname.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
		var idesc = Label.new()
		idesc.text = it["desc"]
		idesc.add_theme_font_size_override("font_size", 12)
		idesc.add_theme_color_override("font_color", Color(0.8, 0.75, 0.7))
		info.add_child(iname)
		info.add_child(idesc)
		item_row.add_child(info)
		
		var buy_btn = Button.new()
		buy_btn.text = "SATIN AL"
		buy_btn.custom_minimum_size = Vector2(130, 36)
		buy_btn.pressed.connect(func(): _buy_item(it["cost"], it["name"]))
		item_row.add_child(buy_btn)
		
		list_box.add_child(item_row)
		
	var close_shop = Button.new()
	close_shop.text = "KAPAT"
	close_shop.position = Vector2(280, 540)
	close_shop.size = Vector2(160, 40)
	close_shop.pressed.connect(func():
		shop_overlay.visible = false
		show_main_menu()
	)
	box.add_child(close_shop)

func _buy_item(cost: int, item_name: String) -> void:
	if player_ref and player_ref.gold >= cost:
		player_ref.gold -= cost
		player_ref.emit_signal("gold_changed", player_ref.gold)
		if "Hançer" in item_name:
			player_ref.knife_count += 5
		elif "İksir" in item_name:
			player_ref.health = player_ref.max_health
			player_ref.emit_signal("health_changed", player_ref.health, player_ref.max_health)
		show_notification("Satın Alındı: " + item_name + " (-" + str(cost) + " Akçe)", 2.5)
	else:
		show_notification("Yetersiz Akçe! Görevlerden akçe kazanmalısın.", 2.0)

# =========================================================================
# 6. DURAKLATMA MENÜSÜ (PAUSE)
# =========================================================================
func _build_pause_menu() -> void:
	pause_overlay = Control.new()
	pause_overlay.name = "PauseOverlay"
	pause_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_overlay.visible = false
	root_hud.add_child(pause_overlay)
	
	var tint = ColorRect.new()
	tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	tint.color = Color(0.06, 0.05, 0.04, 0.75)
	pause_overlay.add_child(tint)
	
	var pbox = Panel.new()
	pbox.position = Vector2(460, 160)
	pbox.size = Vector2(360, 400)
	var pstyle = StyleBoxFlat.new()
	pstyle.bg_color = Color(0.12, 0.09, 0.07, 0.95)
	pstyle.border_width_left = 2
	pstyle.border_width_top = 2
	pstyle.border_width_right = 2
	pstyle.border_width_bottom = 2
	pstyle.border_color = Color(0.85, 0.72, 0.3)
	pstyle.corner_radius_top_left = 12
	pstyle.corner_radius_top_right = 12
	pstyle.corner_radius_bottom_right = 12
	pstyle.corner_radius_bottom_left = 12
	pbox.add_theme_stylebox_override("panel", pstyle)
	pause_overlay.add_child(pbox)
	
	var title = Label.new()
	title.text = "OYUN DURAKLATILDI"
	title.position = Vector2(0, 25)
	title.size = Vector2(360, 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	pbox.add_child(title)
	
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(50, 85)
	vbox.size = Vector2(260, 270)
	vbox.add_theme_constant_override("separation", 16)
	pbox.add_child(vbox)
	
	var btn_resume = Button.new()
	btn_resume.text = "DEVAM ET"
	btn_resume.custom_minimum_size = Vector2(260, 44)
	btn_resume.pressed.connect(toggle_pause)
	vbox.add_child(btn_resume)
	
	var btn_ch = Button.new()
	btn_ch.text = "BÖLÜMLER"
	btn_ch.custom_minimum_size = Vector2(260, 44)
	btn_ch.pressed.connect(func():
		pause_overlay.visible = false
		show_chapters_menu()
	)
	vbox.add_child(btn_ch)
	
	var btn_st = Button.new()
	btn_st.text = "SEÇENEKLER"
	btn_st.custom_minimum_size = Vector2(260, 44)
	btn_st.pressed.connect(func():
		pause_overlay.visible = false
		show_settings_menu()
	)
	vbox.add_child(btn_st)
	
	var btn_mm = Button.new()
	btn_mm.text = "ANA MENÜYE DÖN"
	btn_mm.custom_minimum_size = Vector2(260, 44)
	btn_mm.pressed.connect(func():
		pause_overlay.visible = false
		show_main_menu()
	)
	vbox.add_child(btn_mm)

func toggle_pause() -> void:
	if is_in_main_menu or is_in_chapters or is_in_settings or is_in_shop:
		return
	is_paused = not is_paused
	pause_overlay.visible = is_paused
	if player_ref:
		player_ref.set_menu_active(is_paused)

# =========================================================================
# 7. BİLDİRİMLER, VAZİFE BANNERI, HARİTA VE ETKİLEŞİM
# =========================================================================
func _build_notifications_and_banners() -> void:
	# Vazife Bannerı (Üst Orta - Pusulanın Hemen Altında)
	quest_banner = Panel.new()
	quest_banner.position = Vector2(360, 58)
	quest_banner.size = Vector2(560, 34)

	var qb_style = StyleBoxFlat.new()
	qb_style.bg_color = Color(0.1, 0.08, 0.06, 0.88)
	qb_style.border_width_left = 1
	qb_style.border_width_top = 1
	qb_style.border_width_right = 1
	qb_style.border_width_bottom = 1
	qb_style.border_color = Color(0.85, 0.72, 0.25, 0.85)
	qb_style.corner_radius_top_left = 6
	qb_style.corner_radius_top_right = 6
	qb_style.corner_radius_bottom_right = 6
	qb_style.corner_radius_bottom_left = 6
	quest_banner.add_theme_stylebox_override("panel", qb_style)
	ingame_hud.add_child(quest_banner)
	
	quest_banner_text = Label.new()
	quest_banner_text.position = Vector2(10, 5)
	quest_banner_text.size = Vector2(540, 24)
	quest_banner_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quest_banner_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	quest_banner_text.text = "Vazife: Şadırvanda abdest al, camide namaz kıl veya Eşref Bey ile görüş!"
	quest_banner_text.add_theme_font_size_override("font_size", 12)
	quest_banner_text.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))
	quest_banner.add_child(quest_banner_text)
	
	# Bildirim Bannerı (Alt Orta)
	message_banner = Panel.new()
	message_banner.position = Vector2(340, 160)
	message_banner.size = Vector2(600, 48)
	var mb_style = StyleBoxFlat.new()
	mb_style.bg_color = Color(0.1, 0.08, 0.06, 0.95)
	mb_style.border_width_left = 2
	mb_style.border_width_top = 2
	mb_style.border_width_right = 2
	mb_style.border_width_bottom = 2
	mb_style.border_color = Color(0.9, 0.75, 0.25, 1)
	mb_style.corner_radius_top_left = 8
	mb_style.corner_radius_top_right = 8
	mb_style.corner_radius_bottom_right = 8
	mb_style.corner_radius_bottom_left = 8
	message_banner.add_theme_stylebox_override("panel", mb_style)
	message_banner.visible = false
	ingame_hud.add_child(message_banner)
	
	message_text = Label.new()
	message_text.position = Vector2(10, 10)
	message_text.size = Vector2(580, 28)
	message_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_text.add_theme_font_size_override("font_size", 14)
	message_text.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85))
	message_banner.add_child(message_text)
	
	# Etkileşim Butonu
	prompt_btn = Button.new()
	prompt_btn.position = Vector2(440, 530)
	prompt_btn.size = Vector2(400, 44)
	prompt_btn.visible = false
	prompt_btn.pressed.connect(func(): emit_signal("interact_pressed"))
	ingame_hud.add_child(prompt_btn)
	
	# Harita Paneli
	map_panel = Control.new()
	map_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	map_panel.visible = false
	var map_bg = TextureRect.new()
	map_bg.texture = load("res://assets/ui/ottoman_map.png")
	map_bg.position = Vector2(190, 60)
	map_bg.size = Vector2(900, 600)
	map_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map_panel.add_child(map_bg)
	
	var close_map = Button.new()
	close_map.text = "HARİTAYI KAPAT"
	close_map.position = Vector2(540, 610)
	close_map.size = Vector2(200, 40)
	close_map.pressed.connect(toggle_map)
	map_panel.add_child(close_map)
	ingame_hud.add_child(map_panel)

# =========================================================================
# MENÜLER ARASI GEÇİŞ YÖNETİMİ
# =========================================================================
func show_main_menu() -> void:
	is_in_main_menu = true
	is_in_chapters = false
	is_in_settings = false
	is_in_shop = false
	is_paused = false
	
	main_menu_overlay.visible = true
	chapters_overlay.visible = false
	settings_overlay.visible = false
	shop_overlay.visible = false
	pause_overlay.visible = false
	ingame_hud.visible = false
	
	if player_ref:
		player_ref.set_menu_active(true)

func show_chapters_menu() -> void:
	is_in_chapters = true
	main_menu_overlay.visible = false
	chapters_overlay.visible = true
	settings_overlay.visible = false
	shop_overlay.visible = false
	pause_overlay.visible = false

func show_settings_menu() -> void:
	is_in_settings = true
	main_menu_overlay.visible = false
	chapters_overlay.visible = false
	settings_overlay.visible = true
	shop_overlay.visible = false

func show_shop_menu() -> void:
	is_in_shop = true
	main_menu_overlay.visible = false
	shop_overlay.visible = true

func _on_start_game_pressed() -> void:
	if has_node("/root/SoundManager"):
		get_node("/root/SoundManager").play_ui_click()
	main_menu_overlay.visible = false
	chapters_overlay.visible = false
	settings_overlay.visible = false
	shop_overlay.visible = false
	pause_overlay.visible = false
	ingame_hud.visible = true
	is_in_main_menu = false
	
	if player_ref:
		player_ref.set_menu_active(false)
		
	show_notification("Zaptiye Cihanşah göreve hazır! Payitaht seni bekler.", 3.0)

# =========================================================================
# GİRİŞ & DOKUNMATİK / FARE ETKİLEŞİMİ (8-YÖNLÜ OSMANLI D-PAD)
# =========================================================================
func _input(event: InputEvent) -> void:
	if is_in_main_menu or is_in_chapters or is_in_settings or is_in_shop:
		return
		
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		toggle_pause()
		return
		
	# Dokunmatik Ekran Olayları
	if event is InputEventScreenTouch:
		handle_touch(event)
	elif event is InputEventScreenDrag:
		handle_drag(event)
	# PC Fare Olayları: SADECE D-Pad üzerindeyse D-Pad'i kontrol et!
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var dpad_rect_global = Rect2(dpad_container.global_position, dpad_container.size)
			if event.pressed:
				if dpad_rect_global.has_point(event.position):
					dpad_active = true
					dpad_center = dpad_container.global_position + (dpad_container.size / 2.0)
					update_dpad(event.position)
				else:
					# PC'de oyun alanına tıklandığında fareyi yakala (böylece fare serbestçe kamerayı döndürür)
					if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and not is_in_main_menu and not is_paused:
						Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			else:
				if dpad_active:
					reset_dpad()
	elif event is InputEventMouseMotion and dpad_active:
		update_dpad(event.position)

func handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		var dpad_rect_global = Rect2(dpad_container.global_position, dpad_container.size)
		if dpad_rect_global.has_point(event.position):
			dpad_active = true
			dpad_touch_id = event.index
			dpad_center = dpad_container.global_position + (dpad_container.size / 2.0)
			update_dpad(event.position)
		elif event.position.x > get_viewport().get_visible_rect().size.x * 0.45:
			# Sadece mobil dokunmatik ekranda parmakla kamera döndürme
			if camera_touch_id == -1 and event.position.y < get_viewport().get_visible_rect().size.y * 0.8:
				camera_touch_id = event.index
				last_camera_touch_pos = event.position
	else:
		if event.index == dpad_touch_id:
			reset_dpad()

		elif event.index == camera_touch_id:
			camera_touch_id = -1

func handle_drag(event: InputEventScreenDrag) -> void:
	if event.index == dpad_touch_id:
		update_dpad(event.position)
	elif event.index == camera_touch_id:
		var delta_pos = event.position - last_camera_touch_pos
		last_camera_touch_pos = event.position
		if player_ref and is_instance_valid(player_ref) and player_ref.has_method("rotate_camera"):
			player_ref.rotate_camera(delta_pos * 0.005)

# 8 AYRIK YÖN KONTROLÜ (Joyistik gibi kayan top değil, 8 yönlü tablet)
func update_dpad(touch_pos: Vector2) -> void:
	var offset = touch_pos - dpad_center
	var dist = offset.length()
	
	if dist < 18.0:
		reset_dpad_actions()
		dpad_glow_indicator.visible = false
		return
		
	var angle = offset.angle() # -PI ile +PI arası
	# 8 sektöre böl (Her sektör 45 derece = PI/4)
	# 0: Sağ, 1: Sağ-Aşağı, 2: Aşağı, 3: Sol-Aşağı, 4: Sol, 5: Sol-Yukarı, 6: Yukarı, 7: Sağ-Yukarı
	var octant = int(round(angle / (PI / 4.0)))
	if octant < 0:
		octant += 8
	octant = octant % 8
	
	active_dpad_sector = octant
	
	# Eylemleri Sıfırla
	reset_dpad_actions()
	
	match octant:
		0: # Sağ
			Input.action_press("move_right", 1.0)
		1: # Sağ-Aşağı (Çapraz)
			Input.action_press("move_backward", 1.0)
			Input.action_press("move_right", 1.0)
		2: # Aşağı
			Input.action_press("move_backward", 1.0)
		3: # Sol-Aşağı (Çapraz)
			Input.action_press("move_backward", 1.0)
			Input.action_press("move_left", 1.0)
		4: # Sol
			Input.action_press("move_left", 1.0)
		5: # Sol-Yukarı (Çapraz)
			Input.action_press("move_forward", 1.0)
			Input.action_press("move_left", 1.0)
		6: # Yukarı
			Input.action_press("move_forward", 1.0)
		7: # Sağ-Yukarı (Çapraz)
			Input.action_press("move_forward", 1.0)
			Input.action_press("move_right", 1.0)
			
	# Parlama göstergesini seçilen yönün üzerine yerleştir
	var indicator_offset = Vector2.from_angle(angle) * minf(dist, 55.0)
	dpad_glow_indicator.position = (dpad_container.size / 2.0) + indicator_offset - (dpad_glow_indicator.size / 2.0)
	dpad_glow_indicator.visible = true

func reset_dpad() -> void:
	dpad_active = false
	dpad_touch_id = -1
	active_dpad_sector = -1
	dpad_glow_indicator.visible = false
	reset_dpad_actions()

func reset_dpad_actions() -> void:
	Input.action_release("move_forward")
	Input.action_release("move_backward")
	Input.action_release("move_left")
	Input.action_release("move_right")

# =========================================================================
# OYUNCU BAĞLANTILARI & SİNYALLER
# =========================================================================
func connect_player(p: Node3D) -> void:
	player_ref = p
	p.health_changed.connect(_on_health_changed)
	if p.has_signal("stamina_changed"):
		p.stamina_changed.connect(_on_stamina_changed)
	p.ammo_changed.connect(_on_ammo_changed)
	p.gold_changed.connect(_on_gold_changed)
	p.message_displayed.connect(show_notification)
	p.interact_target_available.connect(_on_interact_target_available)
	p.interact_target_lost.connect(_on_interact_target_lost)
	if p.has_signal("aim_changed"):
		p.aim_changed.connect(_on_aim_changed)
		
	shoot_pressed.connect(p.shoot_revolver)
	reload_pressed.connect(p.reload_revolver)
	aim_pressed.connect(p.toggle_aim)
	gallop_pressed.connect(p.toggle_gallop)
	melee_pressed.connect(p.perform_melee)
	horse_pressed.connect(p.toggle_horse)
	abdest_pressed.connect(p.perform_abdest)
	interact_pressed.connect(p.trigger_interaction)
	jump_pressed.connect(p.jump)
	sprint_pressed.connect(p.toggle_sprint)
	crouch_pressed.connect(p.toggle_crouch)

func _process(_delta: float) -> void:
	if not ingame_hud.visible or is_in_main_menu or is_paused:
		return
		
	if player_ref and is_instance_valid(player_ref) and "stamina" in player_ref:
		_on_stamina_changed(player_ref.stamina, player_ref.max_stamina)
		
	# Nişan modundayken en yakın düşmana kırmızı hedef elması kilitleme
	if is_aiming_mode:
		_update_lock_on_target()
	else:
		if target_diamond and target_diamond.visible:
			target_diamond.visible = false
		if player_ref and is_instance_valid(player_ref) and "locked_enemy" in player_ref:
			player_ref.locked_enemy = null

func _update_lock_on_target() -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if not camera:
		return
		
	var enemies = get_tree().get_nodes_in_group("enemies")
	var best_enemy: Node3D = null
	var best_dist: float = 999999.0
	var best_screen_pos: Vector2 = Vector2.ZERO
	var screen_center = get_viewport().get_visible_rect().size / 2.0
	
	for e in enemies:
		if is_instance_valid(e) and not e.is_dead:
			var target_3d = e.get_target_position() if e.has_method("get_target_position") else (e.global_position + Vector3(0, 1.4, 0))
			if camera.is_position_behind(target_3d):
				continue
			var scr_pos = camera.unproject_position(target_3d)
			var dist = scr_pos.distance_to(screen_center)
			if dist < 320.0 and dist < best_dist:
				best_dist = dist
				best_enemy = e
				best_screen_pos = scr_pos
				
	if best_enemy:
		locked_enemy_node = best_enemy
		target_diamond.position = best_screen_pos - (target_diamond.size / 2.0)
		target_diamond.visible = true
		var e_name = best_enemy.enemy_title if "enemy_title" in best_enemy else "Eşkıya"
		target_info_label.text = e_name + " (" + str(int(best_enemy.health)) + " HP)"
		if player_ref and is_instance_valid(player_ref) and "locked_enemy" in player_ref:
			player_ref.locked_enemy = best_enemy
	else:
		locked_enemy_node = null
		target_diamond.visible = false
		if player_ref and is_instance_valid(player_ref) and "locked_enemy" in player_ref:
			player_ref.locked_enemy = null

func _on_aim_changed(aiming: bool) -> void:
	is_aiming_mode = aiming
	if crosshair_ctrl:
		crosshair_ctrl.visible = aiming
	if aim_btn:
		aim_btn.modulate = Color(1.8, 1.5, 0.4) if aiming else Color(1.2, 1.2, 0.4, 0.8)

func _on_revolver_tapped() -> void:
	if player_ref:
		if player_ref.current_ammo > 0:
			emit_signal("shoot_pressed")
		else:
			emit_signal("reload_pressed")

func _on_knife_tapped() -> void:
	if player_ref and player_ref.has_method("throw_knife"):
		player_ref.throw_knife()

func _on_watch_tapped() -> void:
	if player_ref and player_ref.has_method("activate_focus"):
		player_ref.activate_focus()

func _on_health_changed(cur: float, max_hp: float) -> void:
	if health_bar_fill:
		health_bar_fill.max_value = max_hp
		health_bar_fill.value = cur
	if health_val_label:
		health_val_label.text = str(int(cur)) + " / " + str(int(max_hp))

func _on_stamina_changed(cur: float, max_s: float) -> void:
	if stamina_bar_fill:
		stamina_bar_fill.max_value = max_s
		stamina_bar_fill.value = cur
	if stamina_val_label:
		var pct = int((cur / maxf(1.0, max_s)) * 100.0)
		stamina_val_label.text = "⚡ %d%%" % pct

func _on_ammo_changed(cur: int, _max_b: int) -> void:
	if ammo_label:
		ammo_label.text = str(cur)

func _on_gold_changed(amount: int) -> void:
	if gold_label:
		gold_label.text = str(amount) + "\n+100"

func set_quest_objective(text: String) -> void:
	if quest_banner_text:
		quest_banner_text.text = "Vazife: " + text

func show_notification(msg: String, duration: float = 2.5) -> void:
	if message_banner and message_text:
		message_text.text = msg
		message_banner.visible = true
		var tween = create_tween()
		tween.tween_property(message_banner, "modulate:a", 1.0, 0.2)
		await get_tree().create_timer(duration).timeout
		var tween_out = create_tween()
		tween_out.tween_property(message_banner, "modulate:a", 0.0, 0.35)
		await tween_out.finished
		message_banner.visible = false

func _on_interact_target_available(target_name: String, _action_text: String) -> void:
	if prompt_btn:
		prompt_btn.text = "🕌 " + target_name + " [ DOKUN veya 'E' ]"
		prompt_btn.visible = true

func _on_interact_target_lost() -> void:
	if prompt_btn:
		prompt_btn.visible = false

func toggle_map() -> void:
	if map_panel:
		map_panel.visible = not map_panel.visible
		if has_node("/root/SoundManager"):
			get_node("/root/SoundManager").play_ui_click()
