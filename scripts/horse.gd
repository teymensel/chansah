extends CharacterBody3D

# Cihanşah - Gülbatur (Gelişmiş Osmanlı Harp Atı Sistemi)
# Gerçekçi 3D at hareket fiziği, tırıs & dörtnal vitesleri, dönüş yatışı ve nal sesleri

@export var walk_speed: float = 5.0
@export var trot_speed: float = 9.5
@export var gallop_speed: float = 19.5
@export var turn_speed: float = 3.4

var is_mounted: bool = false
var rider: Node3D = null
var current_speed: float = 0.0
var gallop_timer: float = 0.0
var is_galloping_boost: bool = false
var current_turn_velocity: float = 0.0

@onready var mount_point: Marker3D = $MountPoint
@onready var interact_area: Area3D = $InteractArea
@onready var anim_player: AnimationPlayer = get_node_or_null("HorseModel/AnimationPlayer")

func _ready() -> void:
	floor_max_angle = deg_to_rad(60.0)
	floor_snap_length = 0.5
	floor_constant_speed = true
	add_to_group("horses")
	apply_horse_material()
	if anim_player and anim_player.has_animation("horse_A_"):
		var anim = anim_player.get_animation("horse_A_")
		if anim:
			anim.loop_mode = Animation.LOOP_LINEAR
		anim_player.play("horse_A_")
		anim_player.pause()

func apply_horse_material() -> void:
	var mesh_node: MeshInstance3D = find_mesh_recursive(get_node_or_null("HorseModel"))
	if mesh_node:
		var horse_mat = StandardMaterial3D.new()
		# Asil Kestane Yağız Doru Osmanlı Atı
		horse_mat.albedo_color = Color(0.25, 0.13, 0.06)
		horse_mat.roughness = 0.48
		horse_mat.metallic = 0.06
		mesh_node.set_surface_override_material(0, horse_mat)

func find_mesh_recursive(parent: Node) -> MeshInstance3D:
	if not parent:
		return null
	for c in parent.get_children():
		if c is MeshInstance3D:
			return c
		var found = find_mesh_recursive(c)
		if found:
			return found
	return null

func set_gallop_boost(boost_active: bool) -> void:
	is_galloping_boost = boost_active

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 22.0 * delta
		
	if is_mounted and rider:
		handle_mounted_movement(delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 16.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 16.0 * delta)
		rotation.z = lerp_angle(rotation.z, 0.0, 8.0 * delta)
		rotation.x = lerp_angle(rotation.x, 0.0, 8.0 * delta)
		if anim_player and anim_player.is_playing():
			anim_player.pause()
		
	move_and_slide()

func handle_mounted_movement(delta: float) -> void:
	var input_vec = Vector2.ZERO
	if Input.is_action_pressed("move_forward"):
		input_vec.y += 1.0
	if Input.is_action_pressed("move_backward"):
		input_vec.y -= 0.6
	if Input.is_action_pressed("move_left"):
		input_vec.x -= 1.0
	if Input.is_action_pressed("move_right"):
		input_vec.x += 1.0
		
	var boost = is_galloping_boost or Input.is_key_pressed(KEY_SHIFT)
	
	# Yumuşak Dönüş Fiziği & Atın Virajda Yana Yatması (Banking)
	var target_turn = -input_vec.x * turn_speed
	current_turn_velocity = lerp(current_turn_velocity, target_turn, 10.0 * delta)
	rotation.y += current_turn_velocity * delta
	
	# Virajda asil yana yatış (Roll)
	var target_bank = clampf(-input_vec.x * (0.12 if boost else 0.06), -0.15, 0.15)
	rotation.z = lerp_angle(rotation.z, target_bank, 8.0 * delta)
	
	# Hız Kademeleri (Geri Adım, Normal Tırıs, Fırtına Dörtnal)
	var target_speed = 0.0
	if input_vec.y > 0.1:
		target_speed = gallop_speed if boost else trot_speed
	elif input_vec.y < -0.1:
		target_speed = -walk_speed * 0.7
		
	var accel = 18.0 if boost else 14.0
	current_speed = move_toward(current_speed, target_speed, accel * delta)
	
	var forward = -transform.basis.z
	velocity.x = forward.x * current_speed
	velocity.z = forward.z * current_speed
	
	# Dörtnal Ritim & Şahlanma / Baş Sallama Salınımı (Pitch)
	if abs(current_speed) > 1.0:
		var speed_factor = abs(current_speed) / 8.0
		gallop_timer += delta * speed_factor * 8.0
		
		# Hızlı koşarken atın sırt ve baş ritmi
		var pitch_osc = sin(gallop_timer) * (0.04 if boost else 0.02)
		rotation.x = lerp_angle(rotation.x, pitch_osc, 10.0 * delta)
		
		if anim_player:
			if not anim_player.is_playing():
				anim_player.play("horse_A_")
			anim_player.speed_scale = clampf(speed_factor * 1.2, 0.85, 2.6)
			
		var gallop_step_interval = 0.30 if boost else 0.44
		if fmod(gallop_timer, PI) < delta * 14.0:
			if has_node("/root/SoundManager"):
				get_node("/root/SoundManager").play_horse_gallop()
	else:
		rotation.x = lerp_angle(rotation.x, 0.0, 10.0 * delta)
		if anim_player and anim_player.is_playing():
			anim_player.pause()

func mount(player_node: Node3D) -> void:
	if is_mounted:
		return
	is_mounted = true
	rider = player_node
	player_node.reparent(mount_point)
	player_node.position = Vector3.ZERO
	player_node.rotation = Vector3.ZERO
	if player_node.has_method("set_on_horse"):
		player_node.set_on_horse(true, self)
	if has_node("/root/SoundManager"):
		get_node("/root/SoundManager").play_horse_gallop()

func dismount() -> void:
	if not is_mounted or not rider:
		return
	var player_node = rider
	is_mounted = false
	rider = null
	
	var spawn_pos = global_position + (transform.basis.x * 1.7)
	spawn_pos.y = global_position.y
	player_node.reparent(get_parent())
	player_node.global_position = spawn_pos
	if player_node.has_method("set_on_horse"):
		player_node.set_on_horse(false, null)
