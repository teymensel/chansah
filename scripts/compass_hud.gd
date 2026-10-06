extends CanvasLayer
class_name CompassHUD

# Cihanşah - Tarihi Payitaht Pusulası, Vakit Paneli & Kartal Görüşü Arayüzü
# Üst ekran pusula şeridi, yönler, önemli mekan işaretçileri ve vakit saati

var player_ref: Node3D = null
var cam_ref: Camera3D = null

var compass_container: Control
var compass_strip: Control
var compass_width: float = 380.0
var time_label: Label
var time_btn: Button

# Kartal Görüşü Efekt Katmanı
var eagle_vision_overlay: ColorRect = null
var eagle_vision_badge: Label = null

# Harita Pinleri
var landmarks = [
	{"name": "Cami-i Kebîr", "pos": Vector3(0, 0, -42), "icon": "🕌"},
	{"name": "Kapalıçarşı", "pos": Vector3(0, 0, 43), "icon": "🏛️"},
	{"name": "Çınaraltı Kıraathanesi", "pos": Vector3(22, 0, -5), "icon": "☕"},
	{"name": "Şadırvan", "pos": Vector3(0, 0, -18), "icon": "💧"},
	{"name": "Eşref Bey", "pos": Vector3(-5, 0, -6), "icon": "📜"},
	{"name": "Saray Arabası", "pos": Vector3(-18, 0, 8), "icon": "👑"},
	{"name": "Saray Göleti & İskele", "pos": Vector3(62, 0, -32), "icon": "🌊"},
	{"name": "Tarihi Yel Değirmeni", "pos": Vector3(-92, 13.5, 5), "icon": "🌾"},
	{"name": "Hisar Gözetleme Kulesi", "pos": Vector3(0, 16.0, 108), "icon": "🏰"},
	{"name": "Teşkilat Ferman Panosu", "pos": Vector3(-6.0, 0, 18.0), "icon": "🎯"},
	{"name": "Kartal Zirvesi (Seyir Terası)", "pos": Vector3(0, 29.5, -118), "icon": "🦅"},
	{"name": "Rüzgârlı Tepe Seyir Balkonu", "pos": Vector3(-108, 24.0, 5), "icon": "⛰️"},
	{"name": "Boğaziçi Dervişgâh Tepesi", "pos": Vector3(112, 26.0, 18), "icon": "🏛️"}
]

var pin_labels: Dictionary = {}

func _ready() -> void:
	add_to_group("compass_hud")
	layer = 15 # HUD üstünde temiz dursun
	_build_ui()
	
	# Gün döngüsüne bağlan
	var cycle = get_tree().get_first_node_in_group("day_night_cycle")
	if cycle and cycle.has_signal("time_changed"):
		cycle.time_changed.connect(_on_time_changed)

func _build_ui() -> void:
	var root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	
	# --- KARTAL GÖRÜŞÜ SİNEMATİK EKRAN FİLTRESİ ---
	eagle_vision_overlay = ColorRect.new()
	eagle_vision_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	eagle_vision_overlay.color = Color(0.04, 0.18, 0.35, 0.28) # Soğuk Assassin's Creed mavi filtre
	eagle_vision_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	eagle_vision_overlay.visible = false
	root.add_child(eagle_vision_overlay)
	
	eagle_vision_badge = Label.new()
	eagle_vision_badge.text = "🦅 TEŞKİLÂT İDRAKI (KARTAL GÖRÜŞÜ) AKTİF"
	eagle_vision_badge.set_anchors_preset(Control.PRESET_CENTER_TOP)
	eagle_vision_badge.position = Vector2(-200, 62)
	eagle_vision_badge.size = Vector2(400, 30)
	eagle_vision_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eagle_vision_badge.modulate = Color(1.0, 0.88, 0.35)
	eagle_vision_badge.visible = false
	root.add_child(eagle_vision_badge)
	
	# --- 1. ÜST ORTA: TARİHİ PUSULA ŞERİDİ ---
	compass_container = Control.new()
	compass_container.custom_minimum_size = Vector2(compass_width, 42)
	compass_container.set_anchors_preset(Control.PRESET_CENTER_TOP)
	compass_container.position = Vector2(-compass_width * 0.5, 10)
	compass_container.clip_contents = true
	root.add_child(compass_container)
	
	# Pusula Arka Planı (Pirinç/Bronz çerçeve & yarı şeffaf koyu zemin)
	var bg = Panel.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.07, 0.05, 0.75)
	style.border_color = Color(0.82, 0.68, 0.35, 0.9)
	style.border_width_bottom = 2
	style.border_width_top = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	bg.add_theme_stylebox_override("panel", style)
	compass_container.add_child(bg)
	
	# Ortadaki Altın Nişan Oku (V)
	var center_mark = Label.new()
	center_mark.text = "▼"
	center_mark.modulate = Color(1.0, 0.85, 0.3)
	center_mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_mark.set_anchors_preset(Control.PRESET_CENTER_TOP)
	center_mark.position = Vector2(-10, -2)
	compass_container.add_child(center_mark)
	
	# Hareketli Pusula Şeridi
	compass_strip = Control.new()
	compass_strip.custom_minimum_size = Vector2(compass_width * 4.0, 42)
	compass_container.add_child(compass_strip)
	
	# Yön İşaretleri (K, KD, D, GD, G, GB, B, KB)
	var cardinal_dirs = [
		{"name": "K", "angle": 0.0, "major": true},
		{"name": "KD", "angle": 45.0, "major": false},
		{"name": "D", "angle": 90.0, "major": true},
		{"name": "GD", "angle": 135.0, "major": false},
		{"name": "G", "angle": 180.0, "major": true},
		{"name": "GB", "angle": 225.0, "major": false},
		{"name": "B", "angle": 270.0, "major": true},
		{"name": "KB", "angle": 315.0, "major": false},
		{"name": "K", "angle": 360.0, "major": true}
	]
	
	for cd in cardinal_dirs:
		var lbl = Label.new()
		lbl.text = cd["name"]
		lbl.name = "Dir_" + cd["name"] + "_" + str(int(cd["angle"]))
		lbl.set_meta("base_angle", cd["angle"])
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.custom_minimum_size = Vector2(30, 30)
		if cd["major"]:
			lbl.modulate = Color(1.0, 0.88, 0.4) if cd["name"] == "K" else Color(0.95, 0.9, 0.75)
		else:
			lbl.modulate = Color(0.65, 0.62, 0.55)
		compass_strip.add_child(lbl)
		
	# Mekan İkonları
	for lm in landmarks:
		_add_pin_to_strip(lm["name"], lm["pos"], lm["icon"])

	# --- 2. SOL ÜST: VAKİT VE SAAT ROZETİ (Can Barının Hemen Altında) ---
	var time_card = Panel.new()
	time_card.custom_minimum_size = Vector2(230, 36)
	time_card.set_anchors_preset(Control.PRESET_TOP_LEFT)
	time_card.position = Vector2(20, 74)
	var t_style = StyleBoxFlat.new()
	t_style.bg_color = Color(0.08, 0.07, 0.05, 0.8)
	t_style.border_color = Color(0.82, 0.68, 0.35, 0.8)
	t_style.border_width_bottom = 2
	t_style.border_width_top = 2
	t_style.border_width_left = 2
	t_style.border_width_right = 2
	t_style.corner_radius_bottom_left = 6
	t_style.corner_radius_bottom_right = 6
	t_style.corner_radius_top_left = 6
	t_style.corner_radius_top_right = 6
	time_card.add_theme_stylebox_override("panel", t_style)
	root.add_child(time_card)
	
	time_label = Label.new()
	time_label.text = "🕌 İkindi (16:30)"
	time_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	time_label.modulate = Color(1.0, 0.88, 0.45)
	time_card.add_child(time_label)
	
	# Vakit Atlama Butonu ([T] Tuşu veya Tıklama)
	time_btn = Button.new()
	time_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	time_btn.flat = true
	time_btn.tooltip_text = "Vakti İlerlet (T Tuşu)"
	time_btn.pressed.connect(_on_time_button_pressed)
	time_card.add_child(time_btn)

func _add_pin_to_strip(pin_name: String, pos: Vector3, icon: String) -> void:
	if pin_labels.has(pin_name):
		pin_labels[pin_name].set_meta("pos", pos)
		return
	var icon_lbl = Label.new()
	icon_lbl.text = icon
	icon_lbl.name = "Pin_" + pin_name
	icon_lbl.set_meta("pos", pos)
	icon_lbl.set_meta("name", pin_name)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.custom_minimum_size = Vector2(24, 24)
	compass_strip.add_child(icon_lbl)
	pin_labels[pin_name] = icon_lbl

func add_custom_landmark(pin_name: String, pos: Vector3, icon: String) -> void:
	_add_pin_to_strip(pin_name, pos, icon)

func _on_time_button_pressed() -> void:
	var cycle = get_tree().get_first_node_in_group("day_night_cycle")
	if cycle and cycle.has_method("skip_to_next_time"):
		cycle.skip_to_next_time()

func _on_time_changed(hour: float, minute: int, time_name: String) -> void:
	if time_label:
		var h_str = "%02d" % int(hour)
		var m_str = "%02d" % minute
		time_label.text = "🕌 " + time_name + " (" + h_str + ":" + m_str + ")"

func _process(_delta: float) -> void:
	if not cam_ref:
		cam_ref = get_viewport().get_camera_3d()
	if not player_ref:
		player_ref = get_tree().get_first_node_in_group("player")
		
	if not cam_ref or not player_ref:
		return
		
	# Kartal Görüşü Filtresi Kontrolü
	if "is_eagle_vision_active" in player_ref:
		var active: bool = player_ref.is_eagle_vision_active
		if eagle_vision_overlay and eagle_vision_overlay.visible != active:
			eagle_vision_overlay.visible = active
		if eagle_vision_badge and eagle_vision_badge.visible != active:
			eagle_vision_badge.visible = active
		
	# Kameranın baktığı açı (0 rad = Kuzey, PI*0.5 = Batı vs.)
	var cam_forward = -cam_ref.global_transform.basis.z
	var player_yaw = atan2(cam_forward.x, cam_forward.z) # -PI .. PI
	var player_deg = wrapf(rad_to_deg(player_yaw), 0.0, 360.0)
	
	# 360 derece = compass_width * 2.5 piksel
	var px_per_deg = compass_width / 90.0 # Ekranda 90 derecelik görüş alanı
	var center_x = compass_width * 0.5
	
	# Yön etiketlerini güncelle
	for child in compass_strip.get_children():
		if child.has_meta("base_angle"):
			var base_ang: float = child.get_meta("base_angle")
			var diff = wrapf(base_ang - player_deg, -180.0, 180.0)
			var screen_x = center_x + (diff * px_per_deg)
			child.position = Vector2(screen_x - 15, 8)
			child.visible = absf(diff) < 55.0
			
	# Mekan pinlerini güncelle
	var p_pos = player_ref.global_position
	for lm_name in pin_labels:
		var lbl: Label = pin_labels[lm_name]
		var target_pos: Vector3 = lbl.get_meta("pos")
		var to_target = (target_pos - p_pos)
		to_target.y = 0.0
		var target_yaw = atan2(to_target.x, to_target.z)
		var target_deg = wrapf(rad_to_deg(target_yaw), 0.0, 360.0)
		var diff = wrapf(target_deg - player_deg, -180.0, 180.0)
		var screen_x = center_x + (diff * px_per_deg)
		lbl.position = Vector2(screen_x - 12, 14)
		lbl.visible = absf(diff) < 50.0
