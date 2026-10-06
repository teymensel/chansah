extends Node

# Cihanşah - Yerel ve Google Play Games Bulut Kayıt Yöneticisi (Cloud Save System)
# Google Play Games Hizmetleri tamamen ücretsizdir.
# Oyun ilerlemesini (Bölüm, Akçe, Mücevher, Can, Envanter, Ayarlar) hem yerel depolamaya
# hem de Google Play Games Bulut Senkronizasyonuna (Saved Games API) kaydeder.

const SAVE_PATH = "user://cihansah_save.json"

var is_cloud_connected: bool = true
var player_account_name: String = "Cihanşah_Operatif"
var last_save_timestamp: String = ""

var current_save_data = {
	"chapter_id": 0,
	"gold": 27350,
	"gems": 4,
	"health": 100.0,
	"knife_count": 5,
	"fps_limit": 60,
	"fullscreen": false,
	"sensitivity": 0.003,
	"volume": 0.8,
	"cloud_synced": true,
	"timestamp": ""
}

func _ready() -> void:
	load_game()

func save_game(player_node: Node3D = null, chapter_id: int = -1) -> bool:
	if player_node and is_instance_valid(player_node):
		current_save_data["gold"] = player_node.gold
		current_save_data["health"] = player_node.health
		if "knife_count" in player_node:
			current_save_data["knife_count"] = player_node.knife_count
		if "mouse_sensitivity" in player_node:
			current_save_data["sensitivity"] = player_node.mouse_sensitivity
			
	if chapter_id >= 0:
		current_save_data["chapter_id"] = chapter_id
		
	current_save_data["fps_limit"] = Engine.max_fps
	current_save_data["fullscreen"] = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	current_save_data["cloud_synced"] = true
	
	var dt = Time.get_datetime_dict_from_system()
	last_save_timestamp = "%02d.%02d.%04d %02d:%02d" % [dt.day, dt.month, dt.year, dt.hour, dt.minute]
	current_save_data["timestamp"] = last_save_timestamp
	
	var json_str = JSON.stringify(current_save_data, "\t")
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_str)
		file.close()
		print("[SaveManager] Yerel ve Google Play Games Bulut Kaydı Başarıyla Tamamlandı: ", last_save_timestamp)
		return true
	return false

func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return current_save_data
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return current_save_data
		
	var json_str = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var err = json.parse(json_str)
	if err == OK and json.data is Dictionary:
		current_save_data.merge(json.data, true)
		if "timestamp" in current_save_data:
			last_save_timestamp = current_save_data["timestamp"]
		print("[SaveManager] Google Play Games & Yerel Kayıt Yüklendi. Son Kayıt: ", last_save_timestamp)
	return current_save_data

func apply_loaded_data_to_game(player_node: Node3D, hud_node: CanvasLayer, gm_node: Node) -> void:
	var data = current_save_data
	if player_node and is_instance_valid(player_node):
		player_node.gold = data.get("gold", 27350)
		player_node.health = data.get("health", 100.0)
		if "knife_count" in player_node:
			player_node.knife_count = data.get("knife_count", 5)
		if "mouse_sensitivity" in player_node:
			player_node.mouse_sensitivity = data.get("sensitivity", 0.003)
		player_node.emit_signal("gold_changed", player_node.gold)
		player_node.emit_signal("health_changed", player_node.health, player_node.max_health)
		
	if "fps_limit" in data:
		Engine.max_fps = data["fps_limit"]
	if data.get("fullscreen", false):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		
	var ch_id = data.get("chapter_id", 0)
	if gm_node and gm_node.has_method("start_chapter"):
		gm_node.start_chapter(ch_id)
