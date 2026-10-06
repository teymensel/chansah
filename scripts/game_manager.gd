extends Node

# Cihanşah - Ana Oyun ve Görev Yöneticisi
# Teşkilât-ı Mahsûsa & Hilâl-i Ahmer Senaryo Akışı

@export var player_node: Node3D
@export var hud_node: CanvasLayer
@export var dialogue_node: CanvasLayer
@export var chess_node: CanvasLayer
@export var prayer_node: CanvasLayer
@export var horse_node: Node3D

var current_quest_stage: int = 0
# 0: Şadırvanda abdest al & Camide namaz kıl & Eşref Bey ile görüş
# 1: Çayhaneye git ve Dimitri ile satranç oyna / sorgula
# 2: Atına bin ve Padişahın kızının faytonuna kurulan pusuyu engelle
# 3: Zafer & Serbest Devriye

var enemies_spawned: bool = false

func _ready() -> void:
	add_to_group("game_manager")
	
	if hud_node and player_node:
		hud_node.connect_player(player_node)
		
	if chess_node:
		chess_node.interrogation_completed.connect(_on_chess_interrogation_completed)
		
	if dialogue_node:
		dialogue_node.quest_accepted.connect(_on_quest_accepted)
		
	if prayer_node:
		prayer_node.prayer_completed.connect(_on_prayer_completed)

func start_chapter(chapter_id: int) -> void:
	current_quest_stage = chapter_id
	# Mevcut düşmanları temizle
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e):
			e.queue_free()
	enemies_spawned = false
	
	match chapter_id:
		0: # Rami - Çocukluk Dönemi
			if player_node:
				player_node.global_position = Vector3(0, 0.1, 3)
			if hud_node:
				hud_node.set_quest_objective("Rami: Cami önündeki şadırvanda abdest al, namaz kıl veya Eşref Bey ile görüş!")
				hud_node.show_notification("1. Bölüm: Rami (Çocukluk Dönemi & Manevi Hazırlık)", 4.0)
		1: # Han Baskını - Vazifeler
			if player_node:
				player_node.global_position = Vector3(14, 0.1, -3)
			if hud_node:
				hud_node.set_quest_objective("Han Baskını: Kıraathanedeki Dimitri ile satranç masasına otur ve sorgula!")
				hud_node.show_notification("2. Bölüm: Han Baskını (Teşkilat Vazifesi)", 4.0)
		2: # Samatya - Karakol ve Eşkıya
			if player_node:
				player_node.global_position = Vector3(-16, 0.1, 14)
			_spawn_samatya_gang()
			if hud_node:
				hud_node.set_quest_objective("Samatya: Mahalle karakolu çevresini haraca bağlayan eşkıyaları temizle!")
				hud_node.show_notification("3. Bölüm: Samatya (Sokak Çeteleriyle Çatışma)", 4.0)
		3: # Kapalıçarşı - Ayı Kikor Boss Düellosu
			if player_node:
				player_node.global_position = Vector3(10, 0.1, -16)
			_spawn_ayi_kikor_boss()
			if hud_node:
				hud_node.set_quest_objective("Kapalıçarşı: BÖLÜM SONU DÜELLOSU - Çete Reisi Ayı Kikor'u Alt Et!")
				hud_node.show_notification("🔥 4. Bölüm: Kapalıçarşı (Ayı Kikor Düellosu)", 5.0)
		4: # Kavala - Hain Avni Paşa'nın İzi
			if player_node:
				player_node.global_position = Vector3(20, 0.1, 18)
			_spawn_kavala_guards()
			if hud_node:
				hud_node.set_quest_objective("Kavala Kalesi: Hain Avni Paşa'nın muhafızlarını yarıp karargaha sız!")
				hud_node.show_notification("5. Bölüm: Kavala (Avni Paşa'nın Peşinde)", 4.0)
		5: # Çanakkale - 1915 Büyük Taarruz
			if player_node:
				player_node.global_position = Vector3(-20, 0.1, -22)
			_spawn_canakkale_trenches()
			if hud_node:
				hud_node.set_quest_objective("Çanakkale 1915: Siper hattını düşman hücumuna karşı son mermine kadar savun!")
				hud_node.show_notification("⚔️ 6. Bölüm: Çanakkale (1915 Büyük Cephe Savunması)", 5.0)

func _spawn_samatya_gang() -> void:
	var enemy_scene = load("res://scenes/enemy.tscn")
	if not enemy_scene: return
	var pts = [Vector3(-22, 0, 18), Vector3(-14, 0, 22), Vector3(-20, 0, 26)]
	for p in pts:
		var enemy = enemy_scene.instantiate()
		enemy.position = p
		enemy.enemy_title = "Samatya Eşkıyası"
		get_parent().add_child(enemy)

func _spawn_ayi_kikor_boss() -> void:
	var enemy_scene = load("res://scenes/enemy.tscn")
	if not enemy_scene: return
	# Boss Ayı Kikor
	var boss = enemy_scene.instantiate()
	boss.position = Vector3(-4, 0, -18)
	boss.is_boss = true
	boss.enemy_title = "Ayı Kikor (Çete Reisi)"
	get_parent().add_child(boss)
	# 2 Koruma
	for offset in [Vector3(-6, 0, -15), Vector3(-2, 0, -21)]:
		var guard = enemy_scene.instantiate()
		guard.position = offset
		guard.enemy_title = "Kikor'un Fedaisi"
		get_parent().add_child(guard)

func _spawn_kavala_guards() -> void:
	var enemy_scene = load("res://scenes/enemy.tscn")
	if not enemy_scene: return
	for p in [Vector3(25, 0, 22), Vector3(18, 0, 26), Vector3(22, 0, 30)]:
		var enemy = enemy_scene.instantiate()
		enemy.position = p
		enemy.enemy_title = "Kavala Muhafızı"
		get_parent().add_child(enemy)

func _spawn_canakkale_trenches() -> void:
	var enemy_scene = load("res://scenes/enemy.tscn")
	if not enemy_scene: return
	for p in [Vector3(-28, 0, -24), Vector3(-24, 0, -28), Vector3(-30, 0, -20), Vector3(-22, 0, -22)]:
		var enemy = enemy_scene.instantiate()
		enemy.position = p
		enemy.enemy_title = "İstilacı Tabur Askeri"
		get_parent().add_child(enemy)


func start_prayer_simulation() -> void:
	if prayer_node and player_node:
		prayer_node.start_prayer(player_node)

func _on_prayer_completed(blessed: bool) -> void:
	if blessed and hud_node and current_quest_stage == 0:
		hud_node.set_quest_objective("Namaz kılındı, ruha huzur indi. Çınar altındaki Eşref Bey ile görüş!")
		hud_node.show_notification("Manevi ferahlık hasıl oldu. Teşkilat Reisi Eşref Bey seni bekliyor.", 4.0)

func start_chess_interrogation() -> void:
	if current_quest_stage < 1:
		hud_node.show_notification("Önce Eşref Bey'den vazife talimatını almalısın!", 2.5)
		return
		
	if chess_node:
		player_node.is_in_dialogue = true
		chess_node.start_interrogation()

func _on_chess_interrogation_completed(cipher_obtained: bool) -> void:
	player_node.is_in_dialogue = false
	if cipher_obtained:
		current_quest_stage = 2
		player_node.add_gold(500)
		hud_node.set_quest_objective("ATINA BİN! Saray arabasına pusu kuran suikastçıları etkisiz hale getir!")
		hud_node.show_notification("Şifreli Harita Ele Geçirildi! Pusu yerine süratle intikal et!", 4.0)
		spawn_ambush_assassins()

func spawn_ambush_assassins() -> void:
	if enemies_spawned:
		return
	enemies_spawned = true
	
	var enemy_scene = load("res://scenes/enemy.tscn")
	if not enemy_scene:
		return
		
	var spawn_points = [
		Vector3(-18, 0, 18),
		Vector3(-12, 0, 24),
		Vector3(-20, 0, 22)
	]
	
	for i in range(spawn_points.size()):
		var enemy = enemy_scene.instantiate()
		enemy.position = spawn_points[i]
		get_parent().add_child(enemy)

func _process(_delta: float) -> void:
	# Görev 2 kontrolü: Suikastçılar yenildi mi?
	if current_quest_stage == 2 and enemies_spawned:
		var active_enemies = get_tree().get_nodes_in_group("enemies")
		if active_enemies.size() == 0:
			complete_story_campaign()

func complete_story_campaign() -> void:
	current_quest_stage = 3
	hud_node.set_quest_objective("Zafer! Saray arabası kurtarıldı. Payitaht sokaklarında serbest devriye gez.")
	hud_node.show_notification("Padişahın Kerimesi Kurtarıldı! Teşkilât-ı Mahsûsa adına büyük zafer! (+1000 Akçe)", 5.0)
	player_node.add_gold(1000)
	if has_node("/root/SoundManager"):
		get_node("/root/SoundManager").play_quest_complete()

func open_esref_bey_dialogue() -> void:
	if not dialogue_node:
		return
		
	player_node.is_in_dialogue = true
	
	var npc_data = {
		"name": "Eşref Bey",
		"title": "Teşkilât-ı Mahsûsa Reisi",
		"portrait": "res://assets/ui/esref_bey.png",
		"start_node": "intro",
		"nodes": {
			"intro": {
				"text": "Selamünaleyküm Cihanşah evladım. Hilâl-i Ahmer kisvesi altında yürüttüğün hizmetler takdire şayandır. Lakin şimdi memleketin kaderini alakadar eden çok daha mühim bir vazife kapımızdadır.",
				"options": [
					{"text": "1. Aleykümselam Beyim. Emriniz başım üstünedir, vazife nedir?", "target": "mission_brief"},
					{"text": "2. Şadırvanda abdestimi tazeledim, zihnim ve pusatım hazırdır.", "target": "ready_status"},
					{"text": "3. Padişah dahi olsa haksıza boyun eğmeyiz, mazlumun ahı yerde kalmaz.", "target": "justice_talk"}
				]
			},
			"mission_brief": {
				"text": "Eski çarşı kıraathanesinde Odesa'dan geldiğini iddia eden Dimitri adında bir Rus tüccar oturur. Kürk satar gibi görünür lakin saray arabalarının güzergahını soruşturmaktadır. Yanına var, şüphe çekmeden satranç masasına otur ve asıl niyetini öğren. Sana bu 6-patları veriyorum, namlusu hakka yönelsin!",
				"options": [
					{"text": "Emredersiniz Beyim! Kıraathaneye gidip casusu sorgulayacağım.", "target": "exit", "give_quest": "chess_mission"}
				]
			},
			"ready_status": {
				"text": "Maşallah evladım. Temiz beden ve arı niyet en büyük kalkandır. Kıraathanedeki Dimitri denen adamı teftiş et.",
				"options": [
					{"text": "Vazife başına geçiyorum Beyim.", "target": "exit", "give_quest": "chess_mission"}
				]
			},
			"justice_talk": {
				"text": "İşte Teşkilâtın aradığı ruh budur! Makam mevki dinlemeyiz; kim halka ve vatana kastederse cezasını çeker. Şimdi git ve vazifeni ifa et!",
				"options": [
					{"text": "Hakkın ve adaletin izindeyiz!", "target": "exit", "give_quest": "chess_mission"}
				]
			}
		}
	}
	
	dialogue_node.start_dialogue(npc_data)
	dialogue_node.dialogue_closed.connect(func(_node_id):
		player_node.is_in_dialogue = false
	, CONNECT_ONE_SHOT)

func _on_quest_accepted(quest_id: String) -> void:
	if quest_id == "chess_mission":
		current_quest_stage = 1
		hud_node.set_quest_objective("Çayhaneye git! Dimitri ile satranç masasına otur ve sorgula.")
		hud_node.show_notification("Yeni Vazife: Kıraathanedeki Rus Casusu Dimitri'yi Soruştur!", 3.5)
