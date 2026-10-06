extends Node3D
class_name SmokeBomb

# Cihanşah - Osmanlı Kükürt & Sis Bombası (Assassin's Creed Smoke Bomb)
# Düşmanları sersemleten, görüşü kapatan ve gizli kaçış/suikast sağlayan sis perdesi

var duration: float = 6.0
var radius: float = 7.5
var timer: float = 0.0

func _ready() -> void:
	# Sis bulutu görseli (İç içe geçen yumuşak duman küreleri)
	var smoke_mat = StandardMaterial3D.new()
	smoke_mat.albedo_color = Color(0.85, 0.85, 0.88, 0.45)
	smoke_mat.roughness = 0.95
	smoke_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smoke_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	for i in range(8):
		var puff = MeshInstance3D.new()
		var p_sph = SphereMesh.new()
		p_sph.radius = randf_range(2.4, 3.8)
		p_sph.height = p_sph.radius * 2.0
		puff.mesh = p_sph
		puff.position = Vector3(randf_range(-2.0, 2.0), randf_range(0.8, 2.5), randf_range(-2.0, 2.0))
		puff.set_surface_override_material(0, smoke_mat)
		add_child(puff)
		
	# Sis patlama sesi
	if has_node("/root/SoundManager"):
		get_node("/root/SoundManager").play_sword_slash()

func _physics_process(delta: float) -> void:
	timer += delta
	
	# Çevredeki düşmanları sersemlet ve hedef şaşırt
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and not e.get("is_dead"):
			if global_position.distance_to(e.global_position) <= radius:
				e.set("is_stunned", true)
				if "target" in e:
					e.target = null # Hedefi kaybet
					
	# Duman yavaşça dağılır
	scale = lerp(scale, Vector3(1.4, 1.2, 1.4), 0.8 * delta)
	
	if timer >= duration:
		# Sersemletmeyi kaldır
		for e in enemies:
			if is_instance_valid(e):
				e.set("is_stunned", false)
		queue_free()
