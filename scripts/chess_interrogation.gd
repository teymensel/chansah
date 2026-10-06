extends CanvasLayer

# Cihanşah - Satranç & Rus Ajanı Dimitri Sorgulama Sahnesi
# Kurtlar Vadisi & Teşkilât-ı Mahsûsa gerilimi: Satranç hamleleri, laf cambazlığı,
# altıpatlar mermilerinin masaya boşaltılması ve suikast planının deşifre edilmesi!

signal interrogation_completed(cipher_obtained: bool)

@onready var bg_texture: TextureRect = $Background
@onready var portrait_dimitri: TextureRect = $DimitriPortrait
@onready var portrait_cihansah: TextureRect = $CihanPortrait
@onready var speaker_label: Label = $DialoguePanel/SpeakerLabel
@onready var dialogue_text: RichTextLabel = $DialoguePanel/DialogueText
@onready var chess_status_label: Label = $ChessPanel/ChessStatus
@onready var tension_bar: ProgressBar = $ChessPanel/TensionBar
@onready var bullet_cylinder_label: Label = $GunShowdownPanel/BulletStatus
@onready var action_vbox: VBoxContainer = $DialoguePanel/ActionButtons
@onready var showdown_panel: Panel = $GunShowdownPanel

var step: int = 0
var tension: float = 20.0
var bullets_in_gun: int = 6

func _ready() -> void:
	visible = false
	if showdown_panel:
		showdown_panel.visible = false

func start_interrogation() -> void:
	visible = true
	step = 0
	tension = 25.0
	bullets_in_gun = 6
	update_tension_ui()
	if showdown_panel:
		showdown_panel.visible = false
	show_step_0()

func update_tension_ui() -> void:
	if tension_bar:
		tension_bar.value = tension

func show_step_0() -> void:
	speaker_label.text = "Dimitri Voronin (Sözde Odesa Tüccarı)"
	dialogue_text.text = "Hoş geldiniz aziz dostum... İstanbul'un kahvehaneleri pek meşhurdur derlerdi de inanmazdım. Beyazlarla e4 sürdüm. Bir parti satranç oynarken hem sohbet ederiz, hem ticaret konuşuruz, ne dersiniz?"
	chess_status_label.text = "Hamle: Beyaz (e4) - Açılış Hamlesi"
	
	setup_buttons([
		{"text": "1. Şah Gambiti Karşılığı (e5) - 'Ticaretiniz buğday mı, yoksa saray sırları mı Dimitri?'", "callback": "_on_choice_1_a"},
		{"text": "2. Vezir Hint Savunması (c5) - 'Gözleriniz bir tüccardan çok askeri bir zabitin gözlerine benziyor.'", "callback": "_on_choice_1_b"},
		{"text": "3. Sakin Başlangıç (Af6) - 'Hamlenizi yaptınız, şimdi niyetinizi görelim.'", "callback": "_on_choice_1_c"}
	])

func _on_choice_1_a() -> void:
	tension += 15.0
	show_step_1("Buğday da gelir kervanla, altın da Cihan Bey... Lakin saraydaki mühim şahsiyetlerin seyahat güzergahları daha karlı bir haberdir.")

func _on_choice_1_b() -> void:
	tension += 20.0
	show_step_1("Asker mi? Güldürmeyin beni dostum... Ben sadece ekmeğinin peşinde biçare bir kürk taciriyim. Lakin atımı f3 karesine sürerim.")

func _on_choice_1_c() -> void:
	tension += 10.0
	show_step_1("Niyetimiz ticaret ve sulh... Ancak duyduğuma göre Sultanın kerimesi Mihrimah Sultan bugün saray arabasıyla Fatih yolundan geçecekmiş.")

func show_step_1(dimitri_response: String) -> void:
	step = 1
	update_tension_ui()
	speaker_label.text = "Dimitri Voronin"
	dialogue_text.text = dimitri_response + "\n\n(Dimitri parmağındaki Çarlık subay mührünü saklamaya çalışır, ceketinin iç cebinde şifreli bir defter kabarmaktadır.)"
	chess_status_label.text = "Hamle: Siyah - Karşı Hücum & Sıkıştırma"
	
	setup_buttons([
		{"text": "1. 'Parmağındaki Çarlık ordusu yüzüğünü görmediğimi mi sandın Yüzbaşı Dimitri?'", "callback": "_on_choice_2_a"},
		{"text": "2. Filimi c5'e sürdüm - 'Sarayın arabasından sana ne tüccar kılıklı casus?'", "callback": "_on_choice_2_b"},
		{"text": "3. Veziri d4'e çektim - 'Şahını korumasız bıraktın. Tıpkı Galata'daki hücren gibi!'", "callback": "_on_choice_2_c"}
	])

func _on_choice_2_a() -> void:
	tension = 80.0
	trigger_showdown()

func _on_choice_2_b() -> void:
	tension = 85.0
	trigger_showdown()

func _on_choice_2_c() -> void:
	tension = 90.0
	trigger_showdown()

func trigger_showdown() -> void:
	step = 2
	update_tension_ui()
	if showdown_panel:
		showdown_panel.visible = true
		
	speaker_label.text = "Cihanşah (Teşkilât-ı Mahsûsa)"
	dialogue_text.text = "Dimitri aniden elini kuşağındaki gizli tabancaya doğru atar! Fakat Cihanşah daha çeviktir; gümüş kakmalı Altıpatlar'ını masaya vurur. Satranç taşları titrer!\n\nCihanşah soğukkanlılıkla silindiri açar..."
	chess_status_label.text = "DURUM: ŞAH VE MAT! SİLAHLAR ÇEKİLDİ!"
	
	setup_buttons([
		{"text": "💥 Silindiri Çevir ve 5 Mermiyi Masaya Boşalt! (Tek Mermi Bırak)", "callback": "_on_empty_bullets_action"}
	])

func _on_empty_bullets_action() -> void:
	bullets_in_gun = 1
	if bullet_cylinder_label:
		bullet_cylinder_label.text = "Silindirde Kalan: 1 Mermi (5 Kovan Masada Tıkırdadı)"
		
	if has_node("/root/SoundManager"):
		get_node("/root/SoundManager").play_bullet_drop()
		await get_tree().create_timer(0.4).timeout
		get_node("/root/SoundManager").play_reload()
		
	tension = 100.0
	update_tension_ui()
	
	speaker_label.text = "Cihanşah"
	dialogue_text.text = "*Tak-tak-tak-tak-tak!* Pirinç kovanlar ahşap masaya dökülür ve satranç tahtasının üzerine dağılır.\n\nCihanşah tek bir mermi bırakıp silindiri çevirir ve şak diye kapatır. Namluyu Dimitri'nin alnına doğrultur:\n\n'Kimin için çalışıyorsun Dimitri?! Teşkilât-ı Mahsûsa'nın gözünden kaçacağını mı sandın?! Suikast planını anlat yoksa bu masadan sağ çıkamazsın!'"
	
	setup_buttons([
		{"text": "🔍 'Padişahın kızına kurulacak pusuyu kim planladı? İsim ver!'", "callback": "_on_final_confession"}
	])

func _on_final_confession() -> void:
	step = 3
	speaker_label.text = "Dimitri Voronin (Korkudan Titreyerek)"
	dialogue_text.text = "'Dur... Ateş etme Cihan! Her şeyi anlatacağım! Saraydaki işbirlikçimiz bize altın verdi. Padişahın kızı Mihrimah Sultan'ın faytonu Fatih çıkışındaki sur kapısına varınca eşkıyalar pusu kuracak! İşte şifreli harita burada... Alın benden uzak durun!'"
	
	if has_node("/root/SoundManager"):
		get_node("/root/SoundManager").play_quest_complete()
		
	setup_buttons([
		{"text": "📜 Şifreli Suikast Haritasını Al ve Casusu Tutuklat!", "callback": "_on_finish_interrogation"}
	])

func _on_finish_interrogation() -> void:
	visible = false
	emit_signal("interrogation_completed", true)

func setup_buttons(button_data: Array) -> void:
	for child in action_vbox.get_children():
		child.queue_free()
		
	for data in button_data:
		var btn = Button.new()
		btn.text = data["text"]
		btn.custom_minimum_size = Vector2(0, 48)
		btn.add_theme_font_size_override("font_size", 15)
		
		# Osmanlı altın & ahşap buton stili
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.18, 0.12, 0.08, 0.95)
		sb.border_color = Color(0.85, 0.72, 0.25, 1.0)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(6)
		btn.add_theme_stylebox_override("normal", sb)
		
		var hover_sb = sb.duplicate()
		hover_sb.bg_color = Color(0.35, 0.22, 0.12, 1.0)
		btn.add_theme_stylebox_override("hover", hover_sb)
		
		var cb_name = data["callback"]
		btn.pressed.connect(Callable(self, cb_name))
		btn.pressed.connect(func():
			if has_node("/root/SoundManager"):
				get_node("/root/SoundManager").play_ui_click()
		)
		action_vbox.add_child(btn)
