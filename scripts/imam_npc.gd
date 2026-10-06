extends CharacterBody3D

# Cihanşah - Cami-i Kebîr Baş İmamı
# imam_npc.tscn içindeki AnimationPlayer → "namaz_rekat" tüm rükünleri yönetir
# Script sadece label metnini günceller & oyuncu etkileşimini yönetir

signal carpet_change_requested(carpet_type: String)
signal prayer_started_for_player()

# Namaz rüknü isimleri ve süreleri (animasyondaki 24 sn ile senkron)
const PRAYER_STAGES = [
	{"name": "🕌 İmam Efendi\n[Kıyam - Fâtiha-i Şerîfe]",          "duration": 5.0},
	{"name": "🕌 İmam Efendi\n[Rükû - Sübhâne Rabbiye'l-Azîm]",    "duration": 4.0},
	{"name": "🕌 İmam Efendi\n[Kavme - Semi'allahu limen hamideh]",  "duration": 2.5},
	{"name": "🕌 İmam Efendi\n[Secde - Sübhâne Rabbiye'l-A'lâ]",   "duration": 4.5},
	{"name": "🕌 İmam Efendi\n[Celse - Ara Oturuş]",                "duration": 2.5},
	{"name": "🕌 İmam Efendi\n[İkinci Secde]",                      "duration": 4.5},
	{"name": "🕌 İmam Efendi\n[Teşehhüd & Salavât]",                "duration": 5.0},
	{"name": "🕌 İmam Efendi\n[Esselâmü aleyküm ve rahmetullâh]",   "duration": 1.5},
]

var current_stage: int = 0
var stage_timer: float = 0.0
var is_dialogue_open: bool = false
var anim_player: AnimationPlayer = null

@onready var label: Label3D = $Label3D

func _ready() -> void:
	add_to_group("interactables")
	add_to_group("imam")
	
	# AnimationPlayer doğrudan sahneden al — TSCN'deki animasyonu kullan
	anim_player = get_node_or_null("AnimationPlayer")
	if anim_player:
		if anim_player.has_animation("namaz_rekat"):
			anim_player.play("namaz_rekat")
	
	if label:
		label.text = PRAYER_STAGES[0]["name"]
	stage_timer = PRAYER_STAGES[0]["duration"]
	
	rotation.y = 0.0

func _process(_delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var dist = global_position.distance_to(player.global_position)
		if dist > 65.0:
			visible = false
			return
		visible = true
	
	if not anim_player:
		anim_player = get_node_or_null("AnimationPlayer")
		
	if anim_player and label:
		var pos = anim_player.current_animation_position
		if pos < 1.6:
			label.text = "🕌 İmam Efendi\n[İftitah Tekbiri - Allâhu Ekber]"
		elif pos < 5.0:
			label.text = "🕌 İmam Efendi\n[Kıyam - Fâtiha-i Şerîfe]"
		elif pos < 8.5:
			label.text = "🕌 İmam Efendi\n[Rükû - Sübhâne Rabbiye'l-Azîm]"
		elif pos < 10.5:
			label.text = "🕌 İmam Efendi\n[Kavme - Semi'allahu limen hamideh]"
		elif pos < 14.5:
			label.text = "🕌 İmam Efendi\n[1. Secde - Sübhâne Rabbiye'l-A'lâ]"
		elif pos < 17.0:
			label.text = "🕌 İmam Efendi\n[Celse - Ara Oturuş]"
		elif pos < 20.0:
			label.text = "🕌 İmam Efendi\n[2. Secde - Sübhâne Rabbiye'l-A'lâ]"
		elif pos < 22.5:
			label.text = "🕌 İmam Efendi\n[Ka'de-i Ahîre - Teşehhüd]"
		else:
			label.text = "🕌 İmam Efendi\n[Selâm & Âmin]"

# ----------------- ETKİLEŞİM & HALI DEĞİŞİM MENÜSÜ -----------------

func interact(_player_node: Node3D) -> void:
	is_dialogue_open = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	open_carpet_choice_dialogue()

func open_carpet_choice_dialogue() -> void:
	var diag = get_node_or_null("ImamDialogueCanvas")
	if diag:
		diag.visible = true
		return
	
	var canvas = CanvasLayer.new()
	canvas.name = "ImamDialogueCanvas"
	canvas.layer = 15
	
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(580, 370)
	panel.anchors_preset = Control.PRESET_CENTER
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -290
	panel.offset_top = -185
	panel.offset_right = 290
	panel.offset_bottom = 185
	
	var pbox = StyleBoxFlat.new()
	pbox.bg_color = Color(0.08, 0.07, 0.05, 0.96)
	pbox.border_color = Color(0.92, 0.8, 0.3)
	pbox.border_width_left = 3
	pbox.border_width_top = 3
	pbox.border_width_right = 3
	pbox.border_width_bottom = 3
	pbox.corner_radius_top_left = 12
	pbox.corner_radius_top_right = 12
	pbox.corner_radius_bottom_right = 12
	pbox.corner_radius_bottom_left = 12
	panel.add_theme_stylebox_override("panel", pbox)
	canvas.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.anchors_preset = Control.PRESET_FULL_RECT
	vbox.offset_left = 25
	vbox.offset_top = 20
	vbox.offset_right = -25
	vbox.offset_bottom = -20
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "🕌 Cami-i Kebîr Baş İmamı Hafız Mahmud Efendi"
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)
	
	var msg = Label.new()
	msg.text = "Esselâmü aleyküm ve rahmetullâh Cihan Bey evladım. Hayrınız ne? Halı seçimi mi, yoksa cemaatle namaza mı duruyoruz?"
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg.add_theme_color_override("font_color", Color(0.92, 0.9, 0.85))
	msg.add_theme_font_size_override("font_size", 13)
	vbox.add_child(msg)
	
	var btn_yesil = Button.new()
	btn_yesil.text = "🌿 1. Zümrüt Yeşili Saf Halısı (Tavus CS-2050) Serilsin"
	btn_yesil.pressed.connect(func(): _select_carpet("yesil", canvas))
	vbox.add_child(btn_yesil)
	
	var btn_turkuaz = Button.new()
	btn_turkuaz.text = "💠 2. Turkuaz Saf Halısı (Tavus CS-2020) Serilsin"
	btn_turkuaz.pressed.connect(func(): _select_carpet("turkuaz", canvas))
	vbox.add_child(btn_turkuaz)
	
	var btn_gokmavi = Button.new()
	btn_gokmavi.text = "🌊 3. Gök Mavi Saf Halısı (Tavus CS-2049) Serilsin"
	btn_gokmavi.pressed.connect(func(): _select_carpet("gokmavi", canvas))
	vbox.add_child(btn_gokmavi)
	
	var btn_pray = Button.new()
	btn_pray.text = "🕌 4. 'Huşû ile cemaatle namaza duralım İmam Efendi!'"
	btn_pray.add_theme_color_override("font_color", Color(1.0, 0.95, 0.5))
	btn_pray.pressed.connect(func(): _start_player_prayer(canvas))
	vbox.add_child(btn_pray)
	
	var btn_close = Button.new()
	btn_close.text = "Âmin, Allah kabul etsin. (Kapat)"
	btn_close.pressed.connect(func(): _close_dialogue(canvas))
	vbox.add_child(btn_close)
	
	add_child(canvas)

func _select_carpet(type_name: String, canvas: CanvasLayer) -> void:
	var cb = get_tree().get_first_node_in_group("city_builder")
	if cb and cb.has_method("set_mosque_carpet"):
		cb.set_mosque_carpet(type_name)
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var name_tr = "Zümrüt Yeşili (Tavus CS-2050)"
		if type_name == "turkuaz":
			name_tr = "Turkuaz (Tavus CS-2020)"
		elif type_name == "gokmavi":
			name_tr = "Gök Mavi (Tavus CS-2049)"
		player.emit_signal("message_displayed", "Cami zeminine " + name_tr + " halı serildi.", 3.0)
	_close_dialogue(canvas)

func _start_player_prayer(canvas: CanvasLayer) -> void:
	_close_dialogue(canvas)
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("start_prayer"):
		player.start_prayer()

func _close_dialogue(canvas: CanvasLayer) -> void:
	is_dialogue_open = false
	if canvas:
		canvas.queue_free()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
