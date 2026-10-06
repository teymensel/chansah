extends CanvasLayer

# Cihanşah - Mount & Blade: Warband Tarzı Tarihsel Diyalog Sistemi
# Karakter portresi, unvan, Osmanlı tarzı konuşma, klavye kısayolları ve dokunmatik butonlar

signal dialogue_closed(last_node_id: String)
signal quest_accepted(quest_id: String)

@onready var portrait_rect: TextureRect = $Panel/Portrait
@onready var title_label: Label = $Panel/TitleLabel
@onready var speaker_label: Label = $Panel/SpeakerLabel
@onready var speech_text: RichTextLabel = $Panel/SpeechText
@onready var choices_container: VBoxContainer = $Panel/ChoicesContainer

var current_dialogue: Dictionary = {}
var active_buttons: Array[Button] = []

func _ready() -> void:
	visible = false

func start_dialogue(npc_data: Dictionary) -> void:
	current_dialogue = npc_data
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if npc_data.has("portrait"):
		var tex = load(npc_data["portrait"])
		if tex:
			portrait_rect.texture = tex
			
	speaker_label.text = npc_data.get("name", "Bilinmeyen Şahıs")
	title_label.text = npc_data.get("title", "İstanbul Sakini")
	
	show_dialogue_node(npc_data.get("start_node", "start"))

func show_dialogue_node(node_id: String) -> void:
	var nodes = current_dialogue.get("nodes", {})
	if not nodes.has(node_id):
		close_dialogue()
		return
		
	var node = nodes[node_id]
	speech_text.text = node.get("text", "")
	
	active_buttons.clear()
	for child in choices_container.get_children():
		child.queue_free()
		
	var options = node.get("options", [])
	var idx = 1
	for opt in options:
		var btn = Button.new()
		var opt_text = opt.get("text", "Devam et...")
		btn.text = opt_text
		btn.custom_minimum_size = Vector2(0, 48)
		btn.add_theme_font_size_override("font_size", 15)
		
		# Warband & Osmanlı ahşap-altın çerçeveli buton stili
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.18, 0.13, 0.09, 0.95)
		sb.border_color = Color(0.85, 0.72, 0.25, 1.0)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(8)
		btn.add_theme_stylebox_override("normal", sb)
		
		var hover_sb = sb.duplicate()
		hover_sb.bg_color = Color(0.38, 0.25, 0.14, 1.0)
		hover_sb.border_color = Color(1.0, 0.88, 0.4, 1.0)
		btn.add_theme_stylebox_override("hover", hover_sb)
		
		var target_node = opt.get("target", "")
		var quest_to_give = opt.get("give_quest", "")
		
		btn.pressed.connect(func():
			if has_node("/root/SoundManager"):
				get_node("/root/SoundManager").play_ui_click()
				
			if quest_to_give != "":
				emit_signal("quest_accepted", quest_to_give)
				
			if target_node == "exit":
				close_dialogue()
			else:
				show_dialogue_node(target_node)
		)
		choices_container.add_child(btn)
		active_buttons.append(btn)
		idx += 1

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1 and active_buttons.size() >= 1:
			active_buttons[0].emit_signal("pressed")
		elif event.keycode == KEY_2 and active_buttons.size() >= 2:
			active_buttons[1].emit_signal("pressed")
		elif event.keycode == KEY_3 and active_buttons.size() >= 3:
			active_buttons[2].emit_signal("pressed")
		elif event.keycode == KEY_4 and active_buttons.size() >= 4:
			active_buttons[3].emit_signal("pressed")
		elif (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER) and active_buttons.size() > 0:
			active_buttons[0].emit_signal("pressed")
		elif event.keycode == KEY_ESCAPE:
			close_dialogue()

func close_dialogue() -> void:
	visible = false
	emit_signal("dialogue_closed", "exit")
