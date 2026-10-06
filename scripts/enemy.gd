extends CharacterBody3D

# Cihanşah - Suikastçı & Eşkıya Düşman Kontrolcüsü
# Saray arabasına pusu kuran ve sokaklarda gizlenen suikastçılar

@export var max_health: float = 80.0
@export var move_speed: float = 4.2
@export var attack_damage: float = 18.0
@export var attack_range: float = 2.0
@export var detection_range: float = 22.0
@export var is_boss: bool = false
@export var enemy_title: String = "Eşkıya"

var health: float = 80.0
var target: Node3D = null
var attack_cooldown: float = 0.0
var is_dead: bool = false

@onready var visual: Node3D = $Visual
@onready var health_bar3d: Label3D = $HealthLabel
var anim_player: AnimationPlayer = null

var anim_timer: float = 0.0
var roar_cooldown: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	if is_boss:
		add_to_group("bosses")
		max_health = 450.0
		health = max_health
		attack_damage = 35.0
		move_speed = 4.8
		enemy_title = "Ayı Kikor (Çete Reisi)"
		scale = Vector3(1.35, 1.35, 1.35)
	else:
		health = max_health
		
	update_health_display()
	
	if has_node("Visual/SoldierModel/AnimationPlayer"):
		anim_player = get_node("Visual/SoldierModel/AnimationPlayer")
		if anim_player.has_animation("Idle"):
			anim_player.play("Idle")

func get_target_position() -> Vector3:
	return global_position + Vector3(0, 1.4 if not is_boss else 1.9, 0)


func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	if not is_on_floor():
		velocity.y -= 19.0 * delta
		
	if attack_cooldown > 0.0:
		attack_cooldown -= delta
		
	# Oyuncuyu ara
	if not target:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			var p = players[0]
			if global_position.distance_to(p.global_position) < detection_range:
				target = p
				
	if target and is_instance_valid(target):
		var dist = global_position.distance_to(target.global_position)
		if dist <= detection_range:
			# Oyuncuya doğru dön
			var look_pos = target.global_position
			look_pos.y = global_position.y
			if global_position.distance_to(look_pos) > 0.1:
				visual.look_at(look_pos, Vector3.UP)
				visual.rotation.y += PI
				
			if dist > attack_range:
				# Takip et
				var dir = (target.global_position - global_position).normalized()
				velocity.x = dir.x * move_speed
				velocity.z = dir.z * move_speed
				
				if anim_player and anim_player.current_animation != "Run":
					anim_player.play("Run")
			else:
				# Yakın mesafede saldır
				velocity.x = 0.0
				velocity.z = 0.0
				if anim_player and anim_player.current_animation != "Idle":
					anim_player.play("Idle")
				if attack_cooldown <= 0.0:
					perform_attack()
		else:
			velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)
			if anim_player and anim_player.current_animation != "Idle":
				anim_player.play("Idle")
	else:
		velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)
		if anim_player and anim_player.current_animation != "Idle":
			anim_player.play("Idle")
		
	move_and_slide()

func perform_attack() -> void:
	attack_cooldown = 1.6
	if has_node("/root/SoundManager"):
		get_node("/root/SoundManager").play_sword_slash()
	if target and target.has_method("take_damage"):
		target.take_damage(attack_damage)

func take_damage(amount: float, attacker: Node3D = null) -> void:
	if is_dead:
		return
	health -= amount
	target = attacker
	update_health_display()
	
	# Darbe tepkisi
	visual.scale = Vector3(1.15, 0.85, 1.15)
	var tween = create_tween()
	tween.tween_property(visual, "scale", Vector3.ONE, 0.15)
	
	if health <= 0.0:
		die()

func update_health_display() -> void:
	if health_bar3d:
		var prefix = "👑 " if is_boss else "⚔️ "
		health_bar3d.text = prefix + enemy_title + ": " + str(int(maxf(0.0, health))) + " HP"
		if is_boss:
			health_bar3d.modulate = Color(1.0, 0.2, 0.2)
		elif health < max_health * 0.4:
			health_bar3d.modulate = Color(0.9, 0.2, 0.2)
		else:
			health_bar3d.modulate = Color(1.0, 0.8, 0.3)

func die() -> void:
	is_dead = true
	velocity = Vector3.ZERO
	if health_bar3d:
		health_bar3d.visible = false
	remove_from_group("enemies")
	if is_boss:
		remove_from_group("bosses")
	
	# Yere devrilme efekti
	var tween = create_tween()
	tween.tween_property(visual, "rotation:z", PI / 2.0, 0.45)
	tween.parallel().tween_property(visual, "position:y", 0.2, 0.45)
	
	# Oyuncuya ödül altın kazandır
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0 and players[0].has_method("add_gold"):
		var reward = 2500 if is_boss else 150
		players[0].add_gold(reward)
		if is_boss:
			players[0].emit_signal("message_displayed", "🏆 DESTANSI ZAFER! Ayı Kikor Devrildi! (+2500 Akçe)", 4.5)
			if has_node("/root/SoundManager"):
				get_node("/root/SoundManager").play_quest_complete()
		else:
			players[0].emit_signal("message_displayed", enemy_title + " Etkisiz Hale Getirildi! (+" + str(reward) + " Akçe)", 2.0)
		
	await get_tree().create_timer(3.5).timeout
	queue_free()

