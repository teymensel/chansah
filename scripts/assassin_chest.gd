extends StaticBody3D
class_name AssassinChest

# Cihanşah - Teşkilât-ı Mahsûsa Gizli Hazine ve Mühimmat Sandığı
# Çatılarda, bahçelerde ve kulelerde gizlenmiş, açılabilir sandık mekaniği

@export var chest_title: String = "Teşkilât Gizli Zulâsı"
@export var gold_reward: int = 450
@export var knife_reward: int = 3
@export var smoke_reward: int = 2

var is_opened: bool = false
var lid_node: Node3D = null
var label_node: Label3D = null

func _ready() -> void:
	add_to_group("interactables")
	add_to_group("chests")
	_build_chest_mesh_and_collision()

func _build_chest_mesh_and_collision() -> void:
	# Çarpışma kutusu
	var col = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(1.1, 0.75, 0.75)
	col.shape = box_shape
	col.position.y = 0.375
	add_child(col)

	# Sandık Malzemeleri (Koyu Ceviz Ağacı & Varaklı Pirinç Şeritler)
	var wood_mat = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.24, 0.16, 0.10)
	wood_mat.roughness = 0.7

	var brass_mat = StandardMaterial3D.new()
	brass_mat.albedo_color = Color(0.88, 0.74, 0.28)
	brass_mat.metallic = 0.85
	brass_mat.roughness = 0.3

	# 1. Sandık Gövdesi (Alt Kasa)
	var base_mesh = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(1.0, 0.45, 0.65)
	base_mesh.mesh = b_box
	base_mesh.position.y = 0.225
	base_mesh.set_surface_override_material(0, wood_mat)
	add_child(base_mesh)

	# Pirinç Köşe ve Kilit Şeritleri
	for x_offset in [-0.46, 0.46]:
		var strip = MeshInstance3D.new()
		var s_box = BoxMesh.new()
		s_box.size = Vector3(0.08, 0.46, 0.66)
		strip.mesh = s_box
		strip.position = Vector3(x_offset, 0.225, 0)
		strip.set_surface_override_material(0, brass_mat)
		add_child(strip)

	# Pirinç Kilit Aynası
	var lock_mesh = MeshInstance3D.new()
	var l_box = BoxMesh.new()
	l_box.size = Vector3(0.14, 0.14, 0.05)
	lock_mesh.mesh = l_box
	lock_mesh.position = Vector3(0, 0.28, 0.33)
	lock_mesh.set_surface_override_material(0, brass_mat)
	add_child(lock_mesh)

	# 2. Menteşeli Sandık Kapağı (Dönme noktası arka kenarda)
	lid_node = Node3D.new()
	lid_node.position = Vector3(0, 0.45, -0.325) # Arka menteşe
	add_child(lid_node)

	var lid_mesh = MeshInstance3D.new()
	var l_box_mesh = BoxMesh.new()
	l_box_mesh.size = Vector3(1.04, 0.18, 0.67)
	lid_mesh.mesh = l_box_mesh
	lid_mesh.position = Vector3(0, 0.09, 0.325)
	lid_mesh.set_surface_override_material(0, wood_mat)
	lid_node.add_child(lid_mesh)

	# Kapak Pirinç Şeritleri
	for x_offset in [-0.46, 0.46]:
		var lid_strip = MeshInstance3D.new()
		var ls_box = BoxMesh.new()
		ls_box.size = Vector3(0.08, 0.19, 0.68)
		lid_strip.mesh = ls_box
		lid_strip.position = Vector3(x_offset, 0.09, 0.325)
		lid_strip.set_surface_override_material(0, brass_mat)
		lid_node.add_child(lid_strip)

	# 3. Yüzen Etiket
	label_node = Label3D.new()
	label_node.text = "💎 " + chest_title + "\n[ Dokun veya 'E' ]"
	label_node.font_size = 20
	label_node.pixel_size = 0.007
	label_node.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label_node.modulate = Color(1.0, 0.88, 0.35)
	label_node.outline_size = 4
	label_node.position = Vector3(0, 1.15, 0)
	add_child(label_node)

	# Hafif gizemli altın parıltısı (Hafif lamba)
	var glow = OmniLight3D.new()
	glow.light_color = Color(1.0, 0.85, 0.35)
	glow.light_energy = 0.65
	glow.omni_range = 3.2
	glow.position = Vector3(0, 0.5, 0)
	add_child(glow)

func get_interaction_label() -> String:
	if is_opened:
		return "💎 " + chest_title + " (Yağmalandı)"
	return "💎 " + chest_title + " [ Aç ]"

func interact(player: Node3D) -> void:
	if is_opened:
		if player.has_signal("message_displayed"):
			player.emit_signal("message_displayed", "Bu teşkilât zulası daha önce açılmış.", 1.5)
		return

	is_opened = true
	if label_node:
		label_node.text = "💎 " + chest_title + "\n(Açıldı)"
		label_node.modulate = Color(0.6, 0.6, 0.6)

	# Kapak açılma animasyonu (Menteşeden geriye doğru açıl)
	if lid_node:
		var tw = create_tween()
		tw.tween_property(lid_node, "rotation:x", deg_to_rad(-75.0), 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Ödülleri ver
	if player:
		if "gold" in player:
			player.gold += gold_reward
			if player.has_signal("gold_changed"):
				player.emit_signal("gold_changed", player.gold)
		if "knife_count" in player:
			player.knife_count += knife_reward
		if "smoke_bomb_count" in player:
			player.smoke_bomb_count += smoke_reward
		if "justice_points" in player:
			player.justice_points += 30

		if player.has_signal("message_displayed"):
			var msg = "🏆 ZULA AÇILDI! (+" + str(gold_reward) + " Akçe, +" + str(knife_reward) + " Kama, +" + str(smoke_reward) + " Sis, +30 Şeref)"
			player.emit_signal("message_displayed", msg, 3.8)

	if has_node("/root/SoundManager"):
		get_node("/root/SoundManager").play_quest_complete()
