extends CharacterBody3D

# Cihanşah - 3D Rigged Humanoid Oyuncu Kontrolcüsü
# Teşkilât-ı Mahsûsa & Hilâl-i Ahmer Gizli Operatifi
# Gelişmiş At Binme, Omuz Üstü Hassas Nişan Alma (Altıpatlar) ve Cami-i Kebîr Minber Etkileşimi

signal health_changed(current: float, max_hp: float)
signal stamina_changed(current: float, max_stamina: float)
signal ammo_changed(current: int, max_bullets: int)
signal gold_changed(amount: int)
signal message_displayed(text: String, duration: float)
signal interact_target_available(target_name: String, action_text: String)
signal interact_target_lost()
signal aim_changed(is_aiming: bool)

@export var walk_speed: float = 5.2
@export var sprint_speed: float = 9.0
@export var jump_velocity: float = 6.5
@export var mouse_sensitivity: float = 0.003

# Nitelikler
var max_health: float = 100.0
var health: float = 100.0
var max_stamina: float = 100.0
var stamina: float = 100.0
var gold: int = 27350
var justice_points: int = 100

# Silah ve Nişan Alma Sistemi (Altıpatlar & Nişangâh)
var max_ammo: int = 6
var current_ammo: int = 6
var can_shoot: bool = true
var is_aiming: bool = false
var camera_recoil: float = 0.0

# Durumlar
var is_in_menu: bool = true
var is_on_horse: bool = false
var current_horse: Node3D = null
var is_galloping: bool = false
var is_in_dialogue: bool = false
var is_praying: bool = false
var is_crouching: bool = false
var mobile_sprint: bool = false
var crouch_speed: float = 2.4
var nearby_interactable: Node3D = null
var current_anim: String = ""
var is_inside_mosque: bool = false
var right_foot_step_timer: float = 0.0
var locked_enemy: Node3D = null
var knife_count: int = 5
var smoke_bomb_count: int = 3
var is_bullet_time: bool = false
var bullet_time_timer: float = 0.0

# Assassin's Creed Mekanikleri (Kartal Görüşü, Gizlilik, Fırlatma Kaması & Sis)
var is_eagle_vision_active: bool = false
var is_stealth_hidden: bool = false
var is_v_cooldown: bool = false
var is_f_cooldown: bool = false
var is_q_cooldown: bool = false
var is_g_cooldown: bool = false
var is_x_cooldown: bool = false


# Düğümler
@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var visual: Node3D = $Visual
@onready var soldier_model: Node3D = get_node_or_null("Visual/SoldierModel")
@onready var prayer_avatar: Node3D = get_node_or_null("Visual/PrayerAvatar")
@onready var anim_player: AnimationPlayer = get_node_or_null("Visual/SoldierModel/AnimationPlayer")
@onready var muzzle_flash: OmniLight3D = get_node_or_null("Visual/SoldierModel/Character/Skeleton3D/HandAttachment/GunMesh/MuzzleFlash")
@onready var gun_mesh: Node3D = get_node_or_null("Visual/SoldierModel/Character/Skeleton3D/HandAttachment/GunMesh")
@onready var skeleton: Skeleton3D = get_node_or_null("Visual/SoldierModel/Character/Skeleton3D")

var bone_r_arm: int = -1
var bone_r_forearm: int = -1
var bone_r_hand: int = -1
var bone_l_arm: int = -1
var bone_l_up_leg: int = -1
var bone_r_up_leg: int = -1
var bone_l_leg: int = -1
var bone_r_leg: int = -1

var aim_blend: float = 0.0
var recent_shoot_timer: float = 0.0

const CharacterStyler = preload("res://scripts/character_styler.gd")

var interact_check_timer: float = 0.0

func _ready() -> void:
	# Dağlara ve yamaçlara rahat tırmanma fiziği
	floor_max_angle = deg_to_rad(62.0)
	floor_snap_length = 0.5
	floor_constant_speed = true
	
	CharacterStyler.style_character(self, "player")
	emit_signal("health_changed", health, max_health)
	emit_signal("stamina_changed", stamina, max_stamina)
	emit_signal("ammo_changed", current_ammo, max_ammo)
	emit_signal("gold_changed", gold)
	if muzzle_flash:
		muzzle_flash.visible = false
	if anim_player:
		for a in anim_player.get_animation_list():
			var anim = anim_player.get_animation(a)
			if anim:
				anim.loop_mode = Animation.LOOP_LINEAR
				
	if skeleton:
		bone_r_arm = skeleton.find_bone("mixamorig_RightArm")
		bone_r_forearm = skeleton.find_bone("mixamorig_RightForeArm")
		bone_r_hand = skeleton.find_bone("mixamorig_RightHand")
		bone_l_arm = skeleton.find_bone("mixamorig_LeftArm")
		bone_l_up_leg = skeleton.find_bone("mixamorig_LeftUpLeg")
		bone_r_up_leg = skeleton.find_bone("mixamorig_RightUpLeg")
		bone_l_leg = skeleton.find_bone("mixamorig_LeftLeg")
		bone_r_leg = skeleton.find_bone("mixamorig_RightLeg")
		
	play_anim("Idle")

func _process(delta: float) -> void:
	if is_bullet_time:
		bullet_time_timer -= delta / maxf(0.01, Engine.time_scale)
		if bullet_time_timer <= 0.0:
			is_bullet_time = false
			Engine.time_scale = 1.0
			emit_signal("message_displayed", "Zaman Akışı Normale Döndü", 1.0)

	if is_in_menu:
		return

	if recent_shoot_timer > 0.0:
		recent_shoot_timer -= delta
		
	# Nişan alma geçiş katsayısı
	var target_aim = 1.0 if (is_aiming or recent_shoot_timer > 0.0) else 0.0
	aim_blend = move_toward(aim_blend, target_aim, delta * 6.5)
	
	if gun_mesh:
		gun_mesh.visible = (aim_blend > 0.05 or is_on_horse)
		
func update_procedural_bones(_delta: float) -> void:
	# 1. At Binme (Equestrian Seated Riding Posture)
	if is_on_horse:
		var q_l_thigh = Quaternion.from_euler(Vector3(deg_to_rad(68), deg_to_rad(18), deg_to_rad(5)))
		var q_r_thigh = Quaternion.from_euler(Vector3(deg_to_rad(68), deg_to_rad(-18), deg_to_rad(-5)))
		var q_knee = Quaternion.from_euler(Vector3(deg_to_rad(-78), 0, 0))
		
		if bone_l_up_leg >= 0: skeleton.set_bone_pose_rotation(bone_l_up_leg, q_l_thigh)
		if bone_r_up_leg >= 0: skeleton.set_bone_pose_rotation(bone_r_up_leg, q_r_thigh)
		if bone_l_leg >= 0: skeleton.set_bone_pose_rotation(bone_l_leg, q_knee)
		if bone_r_leg >= 0: skeleton.set_bone_pose_rotation(bone_r_leg, q_knee)
		
		if not is_aiming and bone_l_arm >= 0:
			var q_rein = Quaternion.from_euler(Vector3(deg_to_rad(-25), deg_to_rad(-35), deg_to_rad(-45)))
			skeleton.set_bone_pose_rotation(bone_l_arm, q_rein)

	# 2. Altıpatlar Nişan Alma (Over-the-Shoulder Marksman Arm Aiming)
	if aim_blend > 0.01:
		if bone_r_arm >= 0:
			var pitch = -camera_pivot.rotation.x
			var q_arm = Quaternion.from_euler(Vector3(pitch * 0.75, deg_to_rad(28), deg_to_rad(-78)))
			var current_pose = skeleton.get_bone_pose_rotation(bone_r_arm)
			skeleton.set_bone_pose_rotation(bone_r_arm, current_pose.slerp(q_arm, aim_blend))
		if bone_r_forearm >= 0:
			var q_fore = Quaternion.from_euler(Vector3(0, deg_to_rad(15), deg_to_rad(-10)))
			var current_f = skeleton.get_bone_pose_rotation(bone_r_forearm)
			skeleton.set_bone_pose_rotation(bone_r_forearm, current_f.slerp(q_fore, aim_blend))

func set_menu_active(active: bool) -> void:

	is_in_menu = active
	if is_in_menu:
		velocity = Vector3.ZERO
		play_anim("Idle")
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if is_in_menu:
		return

	if is_praying:

		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			var ps = get_tree().get_first_node_in_group("prayer_system")
			if ps and ps.has_method("close_prayer"):
				ps.close_prayer()
			else:
				exit_prayer_mode()
		return

	if is_in_dialogue:
		return
		
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_camera(event.relative * mouse_sensitivity)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			else:
				shoot_revolver()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			toggle_aim()
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_TAB or event.keycode == KEY_ESCAPE:
			if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		elif event.keycode == KEY_C:
			toggle_crouch()
		elif event.keycode == KEY_SPACE:
			jump()


func rotate_camera(relative: Vector2) -> void:
	camera_pivot.rotation.y -= relative.x
	camera_pivot.rotation.x = clampf(camera_pivot.rotation.x - relative.y, -1.15, 0.75)

func toggle_aim() -> void:
	is_aiming = not is_aiming
	emit_signal("aim_changed", is_aiming)
	if is_aiming:
		emit_signal("message_displayed", "🎯 Nişan Alındı (Altıpatlar Elinde)", 1.2)
		if has_node("/root/SoundManager"):
			get_node("/root/SoundManager").play_ui_click()
	else:
		emit_signal("message_displayed", "Nişan Bırakıldı.", 1.0)

func set_aiming(aim_state: bool) -> void:
	if is_aiming != aim_state:
		is_aiming = aim_state
		emit_signal("aim_changed", is_aiming)

func toggle_gallop() -> void:
	if is_on_horse and current_horse:
		is_galloping = not is_galloping
		if current_horse.has_method("set_gallop_boost"):
			current_horse.set_gallop_boost(is_galloping)
		if is_galloping:
			emit_signal("message_displayed", "⚡ Gülbatur Dörtnala Kalktı!", 1.5)
		else:
			emit_signal("message_displayed", "Tırıs Adım.", 1.2)

func play_anim(anim_name: String, speed: float = 1.0) -> void:
	if anim_player and anim_player.has_animation(anim_name):
		var anim = anim_player.get_animation(anim_name)
		if anim and anim.loop_mode != Animation.LOOP_LINEAR:
			anim.loop_mode = Animation.LOOP_LINEAR
		if current_anim != anim_name or not anim_player.is_playing():
			current_anim = anim_name
			anim_player.play(anim_name, 0.2)
		anim_player.speed_scale = speed

func _physics_process(delta: float) -> void:
	interact_check_timer += delta
	if interact_check_timer >= 0.1:
		interact_check_timer = 0.0
		check_nearby_interactions()
	
	# Geri Tepme (Recoil) Sönümlenmesi
	if camera_recoil > 0.001:
		camera_pivot.rotation.x -= camera_recoil * delta * 6.0
		camera_recoil = move_toward(camera_recoil, 0.0, delta * 3.5)

	if is_praying:
		velocity = Vector3.ZERO
		spring_arm.spring_length = lerp(spring_arm.spring_length, 4.2, 8.0 * delta)
		camera_pivot.rotation.x = lerp_angle(camera_pivot.rotation.x, deg_to_rad(-10.0), 8.0 * delta)
		camera_pivot.rotation.y = lerp_angle(camera_pivot.rotation.y, 0.0, 8.0 * delta)
		move_and_slide()
		return

	if is_in_dialogue:
		velocity = Vector3.ZERO
		play_anim("Idle")
		move_and_slide()
		return

	# Dinamik Kamera Rig Geçişi (Omuz Üstü Nişan & At Kamerası)
	var target_length = 1.7 if is_aiming else (4.6 if is_on_horse else 3.6)
	spring_arm.spring_length = lerp(spring_arm.spring_length, target_length, 12.0 * delta)
	
	var target_offset = Vector3(0.55, 0.12, 0.0) if is_aiming else (Vector3(0, 0.22, 0) if is_on_horse else Vector3.ZERO)
	camera.position = camera.position.lerp(target_offset, 12.0 * delta)
	
	var horse_spd = abs(current_horse.current_speed) if (is_on_horse and current_horse) else 0.0
	var target_fov = 58.0 if is_aiming else (84.0 if horse_spd > 12.0 else 75.0)
	camera.fov = lerp(camera.fov, target_fov, 10.0 * delta)


	# ================= AT ÜZERİNDE KONTROLLER & NİŞAN ALMA =================
	if is_on_horse and current_horse:
		velocity = Vector3.ZERO
		
		# At üzerinde nişan alırken gövde kameranın baktığı yöne döner
		if is_aiming:
			var target_yaw = (camera_pivot.global_rotation.y - current_horse.global_rotation.y) + PI
			visual.rotation.y = lerp_angle(visual.rotation.y, target_yaw, 14.0 * delta)
		else:
			visual.rotation.y = lerp_angle(visual.rotation.y, PI, 8.0 * delta)
			
		play_anim("Idle", 1.0)
		
		# At üzerindeyken de ateş edilebilir, mermi doldurulabilir, inilebilir!
		if Input.is_action_just_pressed("shoot"):
			shoot_revolver()
		elif Input.is_action_just_pressed("reload"):
			reload_revolver()
		elif Input.is_action_just_pressed("horse_mount"):
			toggle_horse()
		elif Input.is_action_just_pressed("interact"):
			trigger_interaction()
		return

	# ================= YAYA HAREKET & ÇATIŞMA =================
	if not is_on_floor():
		velocity.y -= 19.0 * delta
		
	if (Input.is_action_just_pressed("jump") or Input.is_key_pressed(KEY_SPACE)) and is_on_floor():
		jump()
		
	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("move_forward"):
		input_dir.y += 1.0
	if Input.is_action_pressed("move_backward"):
		input_dir.y -= 1.0
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1.0
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1.0
		
	input_dir = input_dir.normalized()
	
	var cam_yaw = camera_pivot.rotation.y
	var cam_forward = Vector3(-sin(cam_yaw), 0, -cos(cam_yaw))
	var cam_right = Vector3(cos(cam_yaw), 0, -sin(cam_yaw))
	var move_dir = (cam_right * input_dir.x + cam_forward * input_dir.y).normalized()
	
	var is_sprinting = (Input.is_key_pressed(KEY_SHIFT) or mobile_sprint) and stamina > 5.0 and input_dir.length() > 0.1 and not is_aiming and not is_crouching
	var target_speed = sprint_speed if is_sprinting else (crouch_speed if is_crouching else (walk_speed * 0.65 if is_aiming else walk_speed))
	
	if move_dir.length() > 0.1:
		velocity.x = move_dir.x * target_speed
		velocity.z = move_dir.z * target_speed
		
		if is_aiming:
			# Nişan alırken her zaman kameranın baktığı yöne odaklan
			visual.rotation.y = lerp_angle(visual.rotation.y, cam_yaw + PI, 16.0 * delta)
			play_anim("Walk", 0.9)
		else:
			var target_angle = atan2(move_dir.x, move_dir.z)
			visual.rotation.y = lerp_angle(visual.rotation.y, target_angle, 12.0 * delta)
			if is_sprinting:
				play_anim("Run", 1.25)
				stamina = maxf(0.0, stamina - 12.0 * delta)
			elif is_crouching:
				play_anim("Walk", 0.7)
				stamina = minf(max_stamina, stamina + 16.0 * delta)
			else:
				play_anim("Walk", 1.1)
				stamina = minf(max_stamina, stamina + 18.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 18.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 18.0 * delta)
		if is_aiming:
			visual.rotation.y = lerp_angle(visual.rotation.y, cam_yaw + PI, 16.0 * delta)
		play_anim("Idle")
		stamina = minf(max_stamina, stamina + 32.0 * delta)
		
	emit_signal("stamina_changed", stamina, max_stamina)
	move_and_slide()
	check_mosque_shoes_transition(delta)
	
	# Aksiyonlar
	if Input.is_key_pressed(KEY_V):
		if not is_v_cooldown:
			is_v_cooldown = true
			toggle_eagle_vision()
			var vtimer = get_tree().create_timer(0.4)
			vtimer.timeout.connect(func(): is_v_cooldown = false)
	elif Input.is_key_pressed(KEY_F):
		if not is_f_cooldown:
			is_f_cooldown = true
			perform_stealth_assassination()
			var ftimer = get_tree().create_timer(0.4)
			ftimer.timeout.connect(func(): is_f_cooldown = false)
	elif Input.is_key_pressed(KEY_Q):
		if not is_q_cooldown:
			is_q_cooldown = true
			throw_knife()
			var qtimer = get_tree().create_timer(0.4)
			qtimer.timeout.connect(func(): is_q_cooldown = false)
	elif Input.is_key_pressed(KEY_G):
		if not is_g_cooldown:
			is_g_cooldown = true
			throw_smoke_bomb()
			var gtimer = get_tree().create_timer(0.5)
			gtimer.timeout.connect(func(): is_g_cooldown = false)
	elif Input.is_key_pressed(KEY_X):
		if not is_x_cooldown:
			is_x_cooldown = true
			activate_focus()
			var xtimer = get_tree().create_timer(0.5)
			xtimer.timeout.connect(func(): is_x_cooldown = false)
	elif Input.is_key_pressed(KEY_R) or Input.is_action_just_pressed("reload"):
		reload_revolver()
	elif Input.is_key_pressed(KEY_E) or Input.is_action_just_pressed("interact"):
		trigger_interaction()
	elif Input.is_action_just_pressed("shoot"):
		shoot_revolver()
	elif Input.is_action_just_pressed("melee"):
		perform_melee()
	elif Input.is_action_just_pressed("abdest"):
		perform_abdest()
	elif Input.is_action_just_pressed("horse_mount"):
		toggle_horse()

# ----------------- ETKİLEŞİM & KONUŞMA -----------------

func check_nearby_interactions() -> void:
	if is_in_dialogue:
		emit_signal("interact_target_lost")
		return
		
	var closest_dist = 5.0
	var closest_target: Node3D = null
	var label = ""
	
	# Sessiz Suikast (Eğilmiş ve düşmana yakınsa)
	if is_crouching:
		var enemies = get_tree().get_nodes_in_group("enemies")
		for e in enemies:
			if is_instance_valid(e) and not e.get("is_dead"):
				var ed = global_position.distance_to(e.global_position)
				if ed < 2.8:
					closest_dist = ed
					closest_target = e
					label = "🗡️ [F] Sessiz Suikast (Gizli Hançer)"
					break
	
	var interactables = get_tree().get_nodes_in_group("interactables")
	for obj in interactables:
		if is_instance_valid(obj):
			var d = global_position.distance_to(obj.global_position)
			if d < closest_dist:
				closest_dist = d
				closest_target = obj
				if obj.has_method("get_interaction_label"):
					label = obj.get_interaction_label()
				elif "interact_label" in obj and str(obj.interact_label) != "":
					label = str(obj.interact_label)
				elif "Esref" in obj.name:
					label = "Eşref Bey (Teşkilât Reisi)"
				elif "Vendor" in obj.name:
					label = "Kapalıçarşı Esnafı"
				elif "Imam" in obj.name:
					label = "İmam Efendi (Halı Rengini Değiştir / Namaza Dur)"
				elif "Kuyu" in obj.name:
					label = "💧 Tarihi Taş Kuyu (Buz Gibi Su İç - Can Yenile)"
				elif "Zula" in obj.name:
					label = "📦 Teşkilât Çatı Zulası (Cephane Al)"
				elif "Gozcu" in obj.name:
					label = "🦅 Çatı Gözcü Noktası (Şehri Teftiş Et)"
				
	var chess_pos = Vector3(18, 0, -5)
	if global_position.distance_to(chess_pos) < 5.0 and global_position.distance_to(chess_pos) < closest_dist:
		closest_dist = global_position.distance_to(chess_pos)
		closest_target = null
		label = "Dimitri (Kıraathane Satranç Masası)"
		
	var sadirvans = get_tree().get_nodes_in_group("sadirvan")
	for s in sadirvans:
		if is_instance_valid(s):
			var sd = global_position.distance_to(s.global_position)
			if sd < 7.5 and sd < closest_dist:
				closest_dist = sd
				closest_target = s
				label = "💧 Cami Şadırvanı (Abdest Al)"
		
	var horses = get_tree().get_nodes_in_group("horses")
	for h in horses:
		if is_instance_valid(h) and not is_on_horse:
			var hd = global_position.distance_to(h.global_position)
			if hd < 4.2 and hd < closest_dist:
				closest_dist = hd
				closest_target = h
				label = "Gülbatur (Binek Atı)"

	# Cami Harimi, Mihrap ve Minber-i Şerîf
	var is_in_mosque = absf(global_position.x) < 11.0 and global_position.z < -28.0 and global_position.z > -56.0
	if is_in_mosque:
		# Minber-i Şerîf Girişi (x = 5.2, z = -49.0 civarı)
		var minber_gate_pos = Vector3(5.2, 0.4, -48.6)
		if global_position.distance_to(minber_gate_pos) < 3.5:
			closest_dist = global_position.distance_to(minber_gate_pos)
			closest_target = null
			label = "🕌 Minber-i Şerîf (Hutbe Basamaklarına Çık)"
		else:
			var imams = get_tree().get_nodes_in_group("imam")
			var near_imam = false
			for im in imams:
				if is_instance_valid(im) and global_position.distance_to(im.global_position) < 3.8:
					closest_dist = global_position.distance_to(im.global_position)
					closest_target = im
					label = "🕌 İmam Efendi (Halı Rengi Değiştir / Namaza Dur)"
					near_imam = true
					break
			if not near_imam and label == "":
				closest_dist = 0.5
				closest_target = null
				label = "🕌 Cami-i Kebîr (Namazlık Alanı - Namaz Kıl)"

	nearby_interactable = closest_target
	if label != "":
		emit_signal("interact_target_available", label, "Etkileşim (E / Dokun)")
	else:
		emit_signal("interact_target_lost")

func trigger_interaction() -> void:
	if is_in_dialogue:
		return
		
	# Minber taç kapısına yakınsa minber hutbe sahanlığına çık
	var minber_gate_pos = Vector3(5.2, 0.4, -48.6)
	if global_position.distance_to(minber_gate_pos) < 3.5:
		global_position = Vector3(5.2, 3.1, -50.65)
		visual.rotation.y = 0.0 # Harîm-i Şerîf cemaatine doğru bak
		emit_signal("message_displayed", "🕌 Minber-i Şerîf Hutbe Makamındasın. Harîm-i Şerîf'e hitâb et!", 3.5)
		return

	# Eğer İmamın yanındaysak önce İmam ile etkileşime gir
	var imams = get_tree().get_nodes_in_group("imam")
	for im in imams:
		if is_instance_valid(im) and global_position.distance_to(im.global_position) < 3.8:
			im.interact(self)
			return
		
	var is_in_mosque = absf(global_position.x) < 11.0 and global_position.z < -28.0 and global_position.z > -56.0
	if is_in_mosque:
		start_prayer()
		return
		
	var interactables = get_tree().get_nodes_in_group("interactables")
	for obj in interactables:
		if is_instance_valid(obj) and global_position.distance_to(obj.global_position) < 5.2:
			if obj.is_in_group("sadirvan"):
				perform_abdest()
				return
			if obj.is_in_group("prayer_area"):
				start_prayer()
				return
			if obj.has_method("interact"):
				if not ("prop_type" in obj):
					Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				obj.interact(self)
				return
				
	if global_position.distance_to(Vector3(18, 0, -5)) < 5.2:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		var gm = get_tree().get_first_node_in_group("game_manager")
		if gm and gm.has_method("start_chess_interrogation"):
			gm.start_chess_interrogation()
		return
		
	var sadirvans = get_tree().get_nodes_in_group("sadirvan")
	for s in sadirvans:
		if is_instance_valid(s) and global_position.distance_to(s.global_position) < 7.5:
			perform_abdest()
			return
		
	var horses = get_tree().get_nodes_in_group("horses")
	for h in horses:
		if is_instance_valid(h) and global_position.distance_to(h.global_position) < 4.5:
			toggle_horse()
			return

func jump() -> void:
	if is_on_horse:
		if current_horse and current_horse.has_method("jump"):
			current_horse.jump()
		return
	if is_on_floor() and not is_in_dialogue and not is_praying:
		if is_crouching:
			set_mobile_crouch(false)
		velocity.y = jump_velocity
		emit_signal("message_displayed", "⬆️ Zıplama!", 0.7)
		if has_node("/root/SoundManager"):
			get_node("/root/SoundManager").play_ui_click()

func toggle_sprint() -> void:
	set_mobile_sprint(not mobile_sprint)

func set_mobile_sprint(s: bool) -> void:
	if is_crouching and s:
		set_mobile_crouch(false)
	mobile_sprint = s
	if mobile_sprint:
		emit_signal("message_displayed", "🏃 Koşma Modu Açık", 1.0)
	else:
		emit_signal("message_displayed", "Yürüyüş Modu", 0.8)

func toggle_crouch() -> void:
	set_mobile_crouch(not is_crouching)

func set_mobile_crouch(c: bool) -> void:
	if is_on_horse or is_praying:
		return
	is_crouching = c
	if is_crouching and mobile_sprint:
		mobile_sprint = false
		
	var col = get_node_or_null("CollisionShape3D")
	if col and col.shape is CapsuleShape3D:
		if is_crouching:
			col.shape.height = 1.15
			col.position.y = 0.58
			camera_pivot.position.y = 1.1
			visual.position.y = -0.35
			emit_signal("message_displayed", "🧎 Eğilme Modu (Gizlenme)", 1.0)
		else:
			col.shape.height = 1.85
			col.position.y = 0.925
			camera_pivot.position.y = 1.6
			visual.position.y = 0.0
			emit_signal("message_displayed", "Ayağa Kalkıldı", 0.8)

func start_prayer() -> void:
	if is_praying:
		return
	enter_prayer_mode()
	var ps = get_tree().get_first_node_in_group("prayer_system")
	if ps and ps.has_method("start_prayer"):
		ps.start_prayer(self)
	else:
		var gm = get_tree().get_first_node_in_group("game_manager")
		if gm and gm.has_method("start_prayer_simulation"):
			gm.start_prayer_simulation()

func enter_prayer_mode() -> void:
	if not visual:
		visual = get_node_or_null("Visual")
	if not camera_pivot:
		camera_pivot = get_node_or_null("CameraPivot")
	if not spring_arm:
		spring_arm = get_node_or_null("CameraPivot/SpringArm3D")
	if not prayer_avatar:
		prayer_avatar = get_node_or_null("Visual/PrayerAvatar")
	if not soldier_model:
		soldier_model = get_node_or_null("Visual/SoldierModel")
		
	is_praying = true
	is_in_dialogue = true
	velocity = Vector3.ZERO
	is_aiming = false
	if is_crouching:
		set_mobile_crouch(false)
	if gun_mesh:
		gun_mesh.visible = false
	
	# Kıbleye yönelt (Mihrap Kuzey yönünde / z-)
	rotation.y = 0.0
	if visual:
		visual.rotation.y = 0.0
		visual.position = Vector3.ZERO
	
	# Cemaat safına hizala (İmam mihrapta ise hemen arkasındaki safa geç)
	var imams = get_tree().get_nodes_in_group("imam")
	if imams.size() > 0 and is_instance_valid(imams[0]):
		var imam = imams[0]
		var target_x = clampf(global_position.x, -4.5, 4.5)
		global_position = Vector3(target_x, 0.4, imam.global_position.z + 3.2)
	elif absf(global_position.x) < 11.0 and global_position.z < -28.0:
		global_position = Vector3(clampf(global_position.x, -4.5, 4.5), 0.4, -49.5)
		
	# Kamera açısını huşû dolu 3. şahıs açısına ayarla (arkadan hem oyuncuyu hem imamı görür)
	if camera_pivot:
		camera_pivot.rotation = Vector3(deg_to_rad(-10.0), 0.0, 0.0)
		camera_pivot.position = Vector3(0.0, 1.6, 0.0)
	if spring_arm:
		spring_arm.spring_length = 4.2
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# SoldierModel'i gizle, PrayerAvatar'ı göster ve başlat
	if soldier_model:
		soldier_model.visible = false
		
	if prayer_avatar:
		prayer_avatar.visible = true
		var anim = prayer_avatar.get_node_or_null("AnimationPlayer")
		if anim:
			anim.play("namaz_rekat")
			if imams.size() > 0 and is_instance_valid(imams[0]):
				var imam_anim = imams[0].get_node_or_null("AnimationPlayer")
				if imam_anim and imam_anim.is_playing():
					anim.seek(imam_anim.current_animation_position, true)

func exit_prayer_mode() -> void:
	is_praying = false
	is_in_dialogue = false
	
	if prayer_avatar:
		var anim = prayer_avatar.get_node_or_null("AnimationPlayer")
		if anim:
			anim.stop()
		prayer_avatar.visible = false
		
	if soldier_model:
		soldier_model.visible = true
		
	play_anim("Idle")
	if spring_arm:
		spring_arm.spring_length = 3.6
	if camera_pivot:
		camera_pivot.rotation = Vector3.ZERO
		camera_pivot.position = Vector3(0.0, 1.6, 0.0)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# ----------------- SİLAH & ÇATIŞMA (ALTIPATLAR & NİŞAN ALMA) -----------------

func shoot_revolver() -> void:
	if not can_shoot or is_in_dialogue:
		return
		
	if current_ammo <= 0:
		emit_signal("message_displayed", "Altıpatlar Boş! Mermileri doldur (R)", 2.0)
		if has_node("/root/SoundManager"):
			get_node("/root/SoundManager").play_ui_click()
		return
		
	current_ammo -= 1
	emit_signal("ammo_changed", current_ammo, max_ammo)
	can_shoot = false
	recent_shoot_timer = 0.9
	
	# Ateş geri tepmesi (Recoil Kick)
	camera_pivot.rotation.x += 0.045
	camera_recoil = 0.045
	
	if has_node("/root/SoundManager"):
		get_node("/root/SoundManager").play_gunshot()
		
	if muzzle_flash:
		muzzle_flash.visible = true
		
	cast_bullet()
	
	await get_tree().create_timer(0.08).timeout
	if muzzle_flash:
		muzzle_flash.visible = false
		
	await get_tree().create_timer(0.32).timeout
	can_shoot = true

func cast_bullet() -> void:
	var from = camera.global_position
	var muzzle_pos = gun_mesh.global_position if (gun_mesh and gun_mesh.visible) else (global_position + Vector3(0.3, 1.4, 0.4))
	var target_pos = from - camera.global_transform.basis.z * 65.0
	
	if locked_enemy and is_instance_valid(locked_enemy) and not locked_enemy.is_dead:
		target_pos = locked_enemy.get_target_position() if locked_enemy.has_method("get_target_position") else (locked_enemy.global_position + Vector3(0, 1.3, 0))
		locked_enemy.take_damage(50.0, self)
		emit_signal("message_displayed", "🎯 Kilitli Hedefe Tam İsabet! (50 Hasar)", 1.2)
	else:
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(from, target_pos)
		query.exclude = [self]
		if is_on_horse and current_horse:
			query.exclude.append(current_horse)
		var result = space_state.intersect_ray(query)
		if result:
			target_pos = result.position
			var col = result.collider
			if col and col.has_method("take_damage"):
				col.take_damage(50.0, self)
				emit_signal("message_displayed", "🎯 Tam İsabet Vuruldu! (50 Hasar)", 1.2)
				
	_spawn_bullet_tracer(muzzle_pos, target_pos)

func _spawn_bullet_tracer(from: Vector3, to: Vector3) -> void:
	var tracer = MeshInstance3D.new()
	var imm = ImmediateMesh.new()
	imm.surface_begin(Mesh.PRIMITIVE_LINES)
	imm.surface_add_vertex(from)
	imm.surface_add_vertex(to)
	imm.surface_end()
	tracer.mesh = imm
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.8, 1.4, 0.5, 0.9)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	get_parent().add_child(tracer)
	var tw = create_tween()
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.10)
	tw.tween_callback(tracer.queue_free)


func throw_knife() -> void:
	if knife_count <= 0:
		emit_signal("message_displayed", "Hançer Kalmadı! Çarşıdan satın alabilirsin.", 1.5)
		return
	knife_count -= 1
	if has_node("/root/SoundManager"):
		get_node("/root/SoundManager").play_sword_slash()
	
	var start_pos = global_position + Vector3(0, 1.4, 0) + (-global_transform.basis.z * 0.8)
	var target_pos = global_position + (-global_transform.basis.z * 22.0) + Vector3(0, 1.0, 0)
	
	if locked_enemy and is_instance_valid(locked_enemy) and not locked_enemy.is_dead:
		target_pos = locked_enemy.global_position + Vector3(0, 1.0, 0)
		_spawn_visual_knife_projectile(start_pos, target_pos)
		locked_enemy.take_damage(65.0, self)
		emit_signal("message_displayed", "🗡️ Fırlatma Kaması İsabet Etti! (65 Hasar - Kalan: " + str(knife_count) + ")", 1.5)
	else:
		var enemies = get_tree().get_nodes_in_group("enemies")
		var hit_one = false
		for e in enemies:
			if is_instance_valid(e) and not e.is_dead and global_position.distance_to(e.global_position) < 20.0:
				target_pos = e.global_position + Vector3(0, 1.0, 0)
				_spawn_visual_knife_projectile(start_pos, target_pos)
				e.take_damage(65.0, self)
				emit_signal("message_displayed", "🗡️ Fırlatma Kaması İsabet Etti! (65 Hasar - Kalan: " + str(knife_count) + ")", 1.5)
				hit_one = true
				break
		if not hit_one:
			_spawn_visual_knife_projectile(start_pos, target_pos)
			emit_signal("message_displayed", "🗡️ Fırlatma Kaması Atıldı! (Kalan: " + str(knife_count) + ")", 1.2)

func _spawn_visual_knife_projectile(start_pos: Vector3, end_pos: Vector3) -> void:
	var knife_mesh = MeshInstance3D.new()
	var prism = BoxMesh.new()
	prism.size = Vector3(0.08, 0.04, 0.45)
	knife_mesh.mesh = prism
	var m = StandardMaterial3D.new()
	m.albedo_color = Color(0.95, 0.9, 0.8)
	m.metallic = 0.95
	m.roughness = 0.15
	knife_mesh.set_surface_override_material(0, m)
	
	get_parent().add_child(knife_mesh)
	knife_mesh.global_position = start_pos
	if start_pos.distance_to(end_pos) > 0.1:
		knife_mesh.look_at(end_pos, Vector3.UP)
	
	var travel_time = clampf(start_pos.distance_to(end_pos) / 38.0, 0.06, 0.4)
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(knife_mesh, "global_position", end_pos, travel_time)
	tw.tween_property(knife_mesh, "rotation:z", PI * 4.0, travel_time)
	tw.chain().tween_callback(knife_mesh.queue_free)

func throw_smoke_bomb() -> void:
	if smoke_bomb_count <= 0:
		emit_signal("message_displayed", "Sis Bombası Kalmadı! (Teşkilat sandıklarından tedarik et)", 2.0)
		return
	smoke_bomb_count -= 1
	var smoke_scene = load("res://scripts/smoke_bomb.gd")
	if smoke_scene:
		var bomb = Node3D.new()
		bomb.set_script(smoke_scene)
		var spawn_pos = global_position + (-global_transform.basis.z * 1.6) + Vector3(0, 0.3, 0)
		get_parent().add_child(bomb)
		bomb.global_position = spawn_pos
		emit_signal("message_displayed", "💨 SİS BOMBASI PATLATILDI! (Düşmanlar Sersemledi - Kalan: " + str(smoke_bomb_count) + ")", 2.5)


func activate_focus() -> void:
	if is_bullet_time:
		return
	is_bullet_time = true
	bullet_time_timer = 4.0
	Engine.time_scale = 0.4
	emit_signal("message_displayed", "⏳ Köstekli Saat: Zaman Yavaşlatıldı (Odaklanma)!", 2.2)
	if has_node("/root/SoundManager"):
		get_node("/root/SoundManager").play_ui_click()


func reload_revolver() -> void:
	if current_ammo >= max_ammo or not can_shoot:
		return
	can_shoot = false
	emit_signal("message_displayed", "Altıpatlar Dolduruluyor...", 1.2)
	if has_node("/root/SoundManager"):
		get_node("/root/SoundManager").play_reload()
		
	await get_tree().create_timer(1.2).timeout
	current_ammo = max_ammo
	emit_signal("ammo_changed", current_ammo, max_ammo)
	emit_signal("message_displayed", "Altıpatlar Hazır! (6/6 Mermi)", 1.5)
	can_shoot = true

func perform_melee() -> void:
	if has_node("/root/SoundManager"):
		get_node("/root/SoundManager").play_sword_slash()
	emit_signal("message_displayed", "Osmanlı Darbesi!", 1.2)
	
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and global_position.distance_to(e.global_position) < 3.2:
			e.take_damage(35.0, self)

# =============================================================================
# ASSASSIN'S CREED: KARTAL GÖRÜŞÜ (TEŞKİLÂT İDRAKI) & SESSİZ SUİKAST
# =============================================================================
func toggle_eagle_vision() -> void:
	is_eagle_vision_active = !is_eagle_vision_active
	
	if has_node("/root/SoundManager"):
		get_node("/root/SoundManager").play_ui_click()
		
	if is_eagle_vision_active:
		emit_signal("message_displayed", "🦅 Teşkilât İdrakı (Kartal Görüşü) Açıldı! (Düşmanlar Kırmızı, Zula ve Kuyular Altın Parıldar)", 3.5)
	else:
		emit_signal("message_displayed", "Kartal Görüşü kapandı.", 1.5)
		
	_apply_eagle_vision_effects()

func _apply_eagle_vision_effects() -> void:
	# 1. Düşmanlar & Suikast Hedefleri (Kırmızı Parıltı - Duvar Arkasından Görünür)
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e):
			var hl = e.get_node_or_null("HealthLabel") as Label3D
			if hl:
				hl.no_depth_test = is_eagle_vision_active
				if is_eagle_vision_active:
					hl.modulate = Color(1.0, 0.1, 0.1, 1.0)
					hl.outline_size = 6
					hl.font_size = 28
				else:
					hl.modulate = Color(1.0, 0.3, 0.3, 1.0)
					hl.outline_size = 4
					hl.font_size = 22
					
	# 2. Müttefikler (Eşref Bey, İmam vb. - Mavi/Turkuaz Parıltı)
	var esrefs = get_tree().get_nodes_in_group("esref")
	for es in esrefs:
		if is_instance_valid(es):
			for child in es.find_children("*", "Label3D", true, false):
				if child is Label3D:
					child.no_depth_test = is_eagle_vision_active
					child.modulate = Color(0.2, 0.85, 1.0) if is_eagle_vision_active else Color.WHITE
					
	# 3. Teşkilât Çatı Zulaları, Kuyular & Gözcüler (Altın Parıltı)
	var interactables = get_tree().get_nodes_in_group("interactables")
	for obj in interactables:
		if is_instance_valid(obj):
			for child in obj.find_children("*", "Label3D", true, false):
				if child is Label3D:
					child.no_depth_test = is_eagle_vision_active
					if is_eagle_vision_active:
						child.modulate = Color(1.0, 0.85, 0.2)
						child.outline_size = 5

func perform_stealth_assassination() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var target_enemy: Node3D = null
	var min_d = 2.8
	for e in enemies:
		if is_instance_valid(e) and not e.get("is_dead"):
			var d = global_position.distance_to(e.global_position)
			if d < min_d:
				min_d = d
				target_enemy = e
				
	if target_enemy:
		# Arkadan sessiz hançer infazı
		if has_node("/root/SoundManager"):
			get_node("/root/SoundManager").play_sword_slash()
		
		# Düşmanı anında tek hamlede etkisiz hale getir
		if target_enemy.has_method("take_damage"):
			target_enemy.take_damage(9999.0, self)
			
		gold += 100
		justice_points += 25
		emit_signal("message_displayed", "🗡️ SESSİZ SUİKAST İCRA EDİLDİ! (+100 Kuruş & +25 Şeref)", 3.0)
		
		# Hızlı gizli atılma
		var tween = create_tween()
		tween.tween_property(self, "global_position", target_enemy.global_position - target_enemy.global_transform.basis.z * 0.8, 0.15)
	else:
		perform_melee()

func perform_abdest() -> void:
	var is_in_mosque = absf(global_position.x) < 11.0 and global_position.z < -28.0 and global_position.z > -56.0
	if is_in_mosque:
		start_prayer()
		return
		
	var sadirvans = get_tree().get_nodes_in_group("sadirvan")
	var is_near = false
	for s in sadirvans:
		if is_instance_valid(s) and global_position.distance_to(s.global_position) < 7.5:
			is_near = true
			break
			
	if is_near:
		health = max_health
		stamina = max_stamina
		emit_signal("health_changed", health, max_health)
		emit_signal("message_displayed", "Abdest Alındı: Gönül Ferahlığı & Beden Sıhhati (+100 Can). Camiye girip saf tutabilirsin!", 3.5)
		if has_node("/root/SoundManager"):
			get_node("/root/SoundManager").play_abdest_water()
	else:
		emit_signal("message_displayed", "Abdest almak için cami önündeki şadırvana yaklaş!", 2.5)

func set_on_horse(status: bool, horse_node: Node3D) -> void:
	is_on_horse = status
	current_horse = horse_node
	is_galloping = false
	if is_on_horse:
		emit_signal("message_displayed", "🐎 Gülbatur'a Binildi! (Dörtnala koştur, omuzdan nişan al ve ateş et!)", 3.0)
	else:
		emit_signal("message_displayed", "Attan İndin.", 1.5)

func toggle_horse() -> void:
	if is_on_horse and current_horse:
		current_horse.dismount()
	else:
		var horses = get_tree().get_nodes_in_group("horses")
		for h in horses:
			if is_instance_valid(h) and global_position.distance_to(h.global_position) < 4.5:
				h.mount(self)
				return
		emit_signal("message_displayed", "Yakında binek at yok! (Gülbatur'un yanına yaklaş)", 2.0)

func take_damage(amount: float) -> void:
	health = maxf(0.0, health - amount)
	emit_signal("health_changed", health, max_health)
	emit_signal("message_displayed", "Yaralandın! (-" + str(int(amount)) + " Can) Şadırvanda abdest al!", 2.0)
	if health <= 0:
		emit_signal("message_displayed", "Düştün! Teşkilat hekimi seni şadırvana ulaştırdı.", 3.5)
		health = 50.0
		global_position = Vector3(0, 1, -10)
		emit_signal("health_changed", health, max_health)

func add_gold(amount: int) -> void:
	gold += amount
	emit_signal("gold_changed", gold)

# ----------------- CAMİYE GİRİŞ: AYAKKABI ÇIKARMA & SAĞ AYAKLA ADIM ATMA -----------------

func check_mosque_shoes_transition(delta: float) -> void:
	if is_on_horse:
		return
		
	# Cami-i Kebîr Harim sınırları (Dünya koordinatlarında Z: -29.2 ile -55.0 arası, X: -10.8 ile 10.8 arası)
	var in_mosque = absf(global_position.x) < 10.8 and global_position.z < -29.2 and global_position.z > -55.0
	
	if in_mosque and not is_inside_mosque:
		is_inside_mosque = true
		on_enter_mosque()
	elif not in_mosque and is_inside_mosque and (global_position.z >= -28.9 or absf(global_position.x) >= 10.9):
		is_inside_mosque = false
		on_exit_mosque()
		
	if right_foot_step_timer > 0.0:
		right_foot_step_timer -= delta
		# Sağ bacak kemiğini sünnet üzere öne doğru adım attır
		if skeleton and bone_r_up_leg >= 0:
			var t = clampf(right_foot_step_timer / 0.65, 0.0, 1.0)
			var angle_hip = sin(t * PI) * deg_to_rad(36.0)
			var angle_knee = sin(t * PI) * deg_to_rad(-22.0)
			skeleton.set_bone_pose_rotation(bone_r_up_leg, Quaternion.from_euler(Vector3(angle_hip, 0, 0)))
			if bone_r_leg >= 0:
				skeleton.set_bone_pose_rotation(bone_r_leg, Quaternion.from_euler(Vector3(angle_knee, 0, 0)))

func on_enter_mosque() -> void:
	# 1. Ayakkabılar otomatik çıkarılır, temiz namaz çoraplarına geçilir
	CharacterStyler.set_shoes_visible(self, false)
	# 2. Sağ ayakla girilir (Sünnet-i Seniyye)
	right_foot_step_timer = 0.65
	# Hafifçe harime doğru süzülüş
	velocity.z = -1.6
	emit_signal("message_displayed", "🕌 Bismillâh: Pabuçlar Çıkarıldı, Camiye Sağ Ayakla Girildi (Sünnet-i Seniyye) ✨", 3.5)
	if has_node("/root/SoundManager"):
		get_node("/root/SoundManager").play_ui_click()

func on_exit_mosque() -> void:
	# Camiden çıkınca pabuçlar tekrar giyilir
	CharacterStyler.set_shoes_visible(self, true)
	emit_signal("message_displayed", "👞 Pabuçlar Giyildi, Cami Avlusuna Çıkıldı.", 2.5)
