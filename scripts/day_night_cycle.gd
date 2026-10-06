extends Node
class_name DayNightCycle

# Cihanşah - Dinamik Payitaht Gün Döngüsü & Atmosfer Simülatörü
# Şafak, Öğle, İkindi (Altın Saat), Akşam Gurûbu ve Kandilli Gece Döngüsü

signal time_changed(hour: float, minute: float, time_name: String)
signal prayer_time_arrived(time_name: String)

@export var day_length_seconds: float = 360.0 # 6 dakikada tam 24 saat (1 gün) döner
@export var start_hour: float = 16.5 # İkindi / Altın saat ile başlar
@export var is_paused: bool = false

var current_hour: float = 16.5
var sun_node: DirectionalLight3D = null
var env_node: WorldEnvironment = null

# Vakit isimleri
var last_announced_vakit: String = ""

# Sokak lambaları önbelleği
var street_lights: Array[Light3D] = []

func _ready() -> void:
	add_to_group("day_night_cycle")
	current_hour = start_hour
	
	# Güneş ve Dünya Ortamını bul
	sun_node = get_parent().get_node_or_null("SunLight") as DirectionalLight3D
	env_node = get_parent().get_node_or_null("WorldEnvironment") as WorldEnvironment
	
	# Şehirdeki tüm fenerleri tara
	_cache_street_lights()
	
	_update_lighting(0.0)

func _cache_street_lights() -> void:
	street_lights.clear()
	for l in get_tree().get_nodes_in_group("street_lights"):
		if l is Light3D:
			street_lights.append(l)
			
	# CityBuilder içindeki omni lightları da dahil et
	var cb = get_parent().get_node_or_null("CityBuilder")
	if cb:
		for child in cb.find_children("*", "OmniLight3D", true, false):
			if child is OmniLight3D and not street_lights.has(child):
				street_lights.append(child)

func _process(delta: float) -> void:
	if not is_paused and day_length_seconds > 0.0:
		var hours_per_sec = 24.0 / day_length_seconds
		current_hour += hours_per_sec * delta
		if current_hour >= 24.0:
			current_hour -= 24.0
			
		_update_lighting(delta)
		
	# Hızlı vakit atlama kısayolu ('T' tuşu)
	if Input.is_action_just_pressed("ui_focus_next") or Input.is_key_pressed(KEY_T):
		if not is_key_cooldown:
			skip_to_next_time()

var is_key_cooldown: bool = false
func skip_to_next_time() -> void:
	is_key_cooldown = true
	if current_hour < 7.0 or current_hour >= 21.0:
		current_hour = 7.0 # Sabah
	elif current_hour < 12.5:
		current_hour = 12.5 # Öğle
	elif current_hour < 17.0:
		current_hour = 17.0 # İkindi
	elif current_hour < 19.5:
		current_hour = 19.5 # Akşam
	else:
		current_hour = 21.5 # Gece
		
	var timer = get_tree().create_timer(0.4)
	timer.timeout.connect(func(): is_key_cooldown = false)
	
	var vakit = get_current_time_name()
	var gm = get_tree().get_first_node_in_group("game_manager")
	if gm and "hud_node" in gm and gm.hud_node:
		gm.hud_node.show_notification("⏳ Payitaht Zamanı İlerletildi: " + vakit, 3.0)

func get_current_time_name() -> String:
	if current_hour >= 5.0 and current_hour < 7.5:
		return "Sabah (Fecir)"
	elif current_hour >= 7.5 and current_hour < 12.5:
		return "Kuşluk / Öğle Vakti"
	elif current_hour >= 12.5 and current_hour < 16.5:
		return "Öğle Sonrası"
	elif current_hour >= 16.5 and current_hour < 19.0:
		return "İkindi (Altın Saat)"
	elif current_hour >= 19.0 and current_hour < 20.5:
		return "Akşam Gurûbu"
	else:
		return "Yatsı & Payitaht Gecesi"

func _update_lighting(delta: float) -> void:
	var hour_int = int(current_hour)
	var minute_int = int((current_hour - hour_int) * 60.0)
	var v_name = get_current_time_name()
	
	emit_signal("time_changed", current_hour, minute_int, v_name)
	
	if v_name != last_announced_vakit:
		last_announced_vakit = v_name
		emit_signal("prayer_time_arrived", v_name)
		
	# Güneş Açısı Hesabı (0 saat = Gece yarısı, 12 saat = Tepe)
	var sun_progress = (current_hour - 6.0) / 12.0 # 0.0 gün doğumu, 1.0 gün batımı
	var sun_elevation = sin(clampf(sun_progress, 0.0, 1.0) * PI)
	var sun_azimuth = (sun_progress * PI) - (PI * 0.5)
	
	var is_night = current_hour < 5.5 or current_hour > 20.0
	var is_golden_hour = (current_hour >= 16.5 and current_hour <= 19.2) or (current_hour >= 5.5 and current_hour <= 7.2)
	
	# Güneş Işığı Güncelleme
	if sun_node:
		if is_night:
			# Gece: Gümüşi Dolunay Işığı
			sun_node.rotation_degrees = Vector3(-45, -70, 0)
			sun_node.light_color = Color(0.65, 0.75, 0.95)
			sun_node.light_energy = 0.35
			sun_node.shadow_enabled = true
		else:
			# Gündüz / Akşam / Sabah Güneşi
			var pitch = -lerpf(12.0, 68.0, sun_elevation)
			var yaw = rad_to_deg(sun_azimuth) - 45.0
			sun_node.rotation_degrees = Vector3(pitch, yaw, 0)
			
			if is_golden_hour:
				# Büyüleyici Altın Saat & Akşamüstü Turuncusu
				sun_node.light_color = Color(1.0, 0.78, 0.52)
				sun_node.light_energy = 1.65
			else:
				# Parlak Öğle Güneşi
				sun_node.light_color = Color(1.0, 0.95, 0.88)
				sun_node.light_energy = 1.7
				
	# Dünya Ortamı & Gökyüzü Renkleri
	if env_node and env_node.environment:
		var env = env_node.environment
		if env.sky and env.sky.sky_material is ProceduralSkyMaterial:
			var sky_mat = env.sky.sky_material as ProceduralSkyMaterial
			if is_night:
				sky_mat.sky_top_color = Color(0.04, 0.07, 0.16)
				sky_mat.sky_horizon_color = Color(0.12, 0.16, 0.26)
				sky_mat.ground_bottom_color = Color(0.02, 0.03, 0.06)
				sky_mat.ground_horizon_color = Color(0.08, 0.1, 0.18)
				env.ambient_light_color = Color(0.15, 0.18, 0.3)
				env.ambient_light_energy = 0.45
				env.fog_light_color = Color(0.08, 0.11, 0.2)
				env.fog_density = 0.004
			elif is_golden_hour:
				sky_mat.sky_top_color = Color(0.28, 0.42, 0.75)
				sky_mat.sky_horizon_color = Color(0.96, 0.62, 0.38)
				sky_mat.ground_bottom_color = Color(0.15, 0.12, 0.1)
				sky_mat.ground_horizon_color = Color(0.72, 0.48, 0.32)
				env.ambient_light_color = Color(0.92, 0.75, 0.58)
				env.ambient_light_energy = 0.85
				env.fog_light_color = Color(0.92, 0.68, 0.45)
				env.fog_density = 0.003
			else:
				sky_mat.sky_top_color = Color(0.24, 0.5, 0.85)
				sky_mat.sky_horizon_color = Color(0.85, 0.78, 0.68)
				sky_mat.ground_bottom_color = Color(0.18, 0.15, 0.12)
				sky_mat.ground_horizon_color = Color(0.65, 0.58, 0.48)
				env.ambient_light_color = Color(0.88, 0.84, 0.78)
				env.ambient_light_energy = 0.8
				env.fog_light_color = Color(0.84, 0.76, 0.65)
				env.fog_density = 0.002
				
	# Gece Kandil & Sokak Lambası Otomasyonu
	var lanterns_should_be_on = is_night or current_hour >= 18.5
	if street_lights.is_empty():
		_cache_street_lights()
	for light in street_lights:
		if is_instance_valid(light):
			light.visible = lanterns_should_be_on
