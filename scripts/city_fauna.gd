extends Node3D
class_name CityFauna

# Cihanşah - Payitaht Şehir Faünası (Meydan Güvercinleri & Tarihi Sokak Kedileri)
# Selatin cami meydanlarında sürü halinde uçuşan güvercinler ve avlu kedileri

var pigeons: Array[Node3D] = []
var player_ref: Node3D = null

func _ready() -> void:
	add_to_group("city_fauna")
	spawn_pigeon_flock(Vector3(0, 0, -20), 12) # Cami Şadırvan Avlusu Güvercinleri
	spawn_pigeon_flock(Vector3(0, 0, 14), 10)  # Ana Divanyolu Meydanı Güvercinleri
	spawn_ottoman_cats()

func _physics_process(delta: float) -> void:
	if not player_ref:
		player_ref = get_tree().get_first_node_in_group("player")
		
	# Güvercin sürü mantığı ve oyuncu/at yaklaşma kontrolü
	var player_pos = player_ref.global_position if player_ref else Vector3.ZERO
	for p in pigeons:
		if is_instance_valid(p):
			_update_pigeon(p, delta, player_pos)

# ----------------- PAYİTAHT GÜVERCİNLERİ -----------------

func spawn_pigeon_flock(center: Vector3, count: int) -> void:
	for i in range(count):
		var p = Node3D.new()
		var rand_offset = Vector3(randf_range(-6.0, 6.0), 0, randf_range(-6.0, 6.0))
		p.position = center + rand_offset
		p.set_meta("home_pos", p.position)
		p.set_meta("state", "peck") # "peck", "walk", "fly", "glide", "land"
		p.set_meta("timer", randf_range(1.0, 4.0))
		p.set_meta("fly_vel", Vector3.ZERO)
		p.set_meta("target_y", 0.0)
		
		# Güvercin Görsel Modeli
		var p_mesh = MeshInstance3D.new()
		var b_sph = SphereMesh.new()
		b_sph.radius = 0.14
		b_sph.height = 0.28
		p_mesh.mesh = b_sph
		p_mesh.position.y = 0.14
		p_mesh.rotation.x = 0.2
		var p_mat = StandardMaterial3D.new()
		# Güvercin rengi (Kül grisi / mavi tüyler)
		var c_rand = randf()
		if c_rand < 0.6:
			p_mat.albedo_color = Color(0.48, 0.52, 0.58) # Kül grisi
		elif c_rand < 0.85:
			p_mat.albedo_color = Color(0.85, 0.86, 0.88) # Beyaz paçalı güvercin
		else:
			p_mat.albedo_color = Color(0.32, 0.3, 0.35) # Yanardöner koyu güvercin
		p_mat.roughness = 0.8
		p_mesh.set_surface_override_material(0, p_mat)
		p.add_child(p_mesh)
		
		# Kafa ve Gaga
		var head = MeshInstance3D.new()
		var h_sph = SphereMesh.new()
		h_sph.radius = 0.08
		h_sph.height = 0.14
		head.mesh = h_sph
		head.position = Vector3(0, 0.24, 0.12)
		head.set_surface_override_material(0, p_mat)
		p.add_child(head)
		
		var beak = MeshInstance3D.new()
		var bk_prism = PrismMesh.new()
		bk_prism.size = Vector3(0.04, 0.08, 0.04)
		beak.mesh = bk_prism
		beak.position = Vector3(0, 0.23, 0.18)
		beak.rotation.x = PI * 0.5
		var bk_mat = StandardMaterial3D.new()
		bk_mat.albedo_color = Color(0.9, 0.7, 0.3)
		beak.set_surface_override_material(0, bk_mat)
		p.add_child(beak)
		
		# Kanatlar (Uçarken çırpınır)
		for side in [-1, 1]:
			var wing = MeshInstance3D.new()
			var w_box = BoxMesh.new()
			w_box.size = Vector3(0.24, 0.03, 0.16)
			wing.mesh = w_box
			wing.name = "Wing_" + ("L" if side == -1 else "R")
			wing.position = Vector3(side * 0.12, 0.16, -0.02)
			wing.set_surface_override_material(0, p_mat)
			p.add_child(wing)
			
		add_child(p)
		pigeons.append(p)

func _update_pigeon(p: Node3D, delta: float, player_pos: Vector3) -> void:
	var state: String = p.get_meta("state")
	var timer: float = p.get_meta("timer") - delta
	var home_pos: Vector3 = p.get_meta("home_pos")
	var dist_to_player = p.global_position.distance_to(player_pos)
	
	# Oyuncu veya at 4.2 metreye yaklaşınca sürü aniden havalanır!
	if dist_to_player < 4.2 and state != "fly" and state != "glide":
		p.set_meta("state", "fly")
		p.set_meta("timer", randf_range(4.5, 7.5))
		var escape_dir = (p.global_position - player_pos).normalized()
		escape_dir.y = 0.65
		p.set_meta("fly_vel", escape_dir.normalized() * randf_range(7.0, 10.0))
		p.set_meta("target_y", randf_range(9.0, 16.0))
		return
		
	var wing_l = p.get_node_or_null("Wing_L")
	var wing_r = p.get_node_or_null("Wing_R")
	
	match state:
		"peck":
			# Yem yeme animasyonu (hafif kafa sallama)
			p.rotation.x = sin(Time.get_ticks_msec() * 0.015) * 0.15
			if wing_l and wing_r:
				wing_l.rotation.z = 0.0
				wing_r.rotation.z = 0.0
			if timer <= 0.0:
				p.set_meta("state", "walk" if randf() < 0.6 else "peck")
				p.set_meta("timer", randf_range(1.5, 3.5))
				p.rotation.y = randf_range(-PI, PI)
				
		"walk":
			p.position += -p.transform.basis.z * 0.8 * delta
			p.rotation.x = 0.0
			# Yürürken hafif ileri geri baş hareketi
			if timer <= 0.0:
				p.set_meta("state", "peck")
				p.set_meta("timer", randf_range(1.5, 4.0))
				
		"fly":
			# Kanat çırpma
			var flap = sin(Time.get_ticks_msec() * 0.04) * 0.75
			if wing_l and wing_r:
				wing_l.rotation.z = flap
				wing_r.rotation.z = -flap
				
			var vel: Vector3 = p.get_meta("fly_vel")
			p.position += vel * delta
			p.rotation.y = lerp_angle(p.rotation.y, atan2(-vel.x, -vel.z), 4.0 * delta)
			
			var target_y: float = p.get_meta("target_y")
			if p.position.y < target_y:
				p.position.y += 4.5 * delta
			else:
				# Tepe noktaya ulaştı, süzülme ve daire çizme
				vel = vel.rotated(Vector3.UP, 0.8 * delta)
				p.set_meta("fly_vel", vel)
				
			if timer <= 0.0:
				p.set_meta("state", "land")
				p.set_meta("timer", 3.0)
				
		"land":
			# Süzülerek yere inme
			if wing_l and wing_r:
				wing_l.rotation.z = 0.15
				wing_r.rotation.z = -0.15
			var dir_to_home = (home_pos - p.position).normalized()
			p.position += dir_to_home * 4.0 * delta
			p.position.y = move_toward(p.position.y, 0.0, 3.8 * delta)
			p.rotation.y = lerp_angle(p.rotation.y, atan2(-dir_to_home.x, -dir_to_home.z), 4.0 * delta)
			
			if p.position.y <= 0.05:
				p.position.y = 0.0
				p.set_meta("state", "peck")
				p.set_meta("timer", randf_range(2.0, 5.0))
				
	p.set_meta("timer", timer)

# ----------------- TARİHİ PAYİTAHT KEDİLERİ -----------------

func spawn_ottoman_cats() -> void:
	var cat_data = [
		{
			"pos": Vector3(-25.8, 1.4, -21.5),
			"rot_y": 0.3,
			"name": "Sarı Sarman (Avlu Duvarı Kedisi)",
			"color": Color(0.92, 0.58, 0.22), # Tekir Sarı
			"msg": "🐾 Sarı Sarman mırıldayarak patilerini uzattı. Huzur buldun! (Takat Yenilendi)"
		},
		{
			"pos": Vector3(19.2, 0.45, -7.2),
			"rot_y": -1.2,
			"name": "Kıraathane Müdavimi (Üçrenkli Calico)",
			"color": Color(0.85, 0.72, 0.6), # Calico
			"msg": "🐾 Kıraathane kedisi çay semaverinin sıcağında esneyip sana sırnaştı!"
		},
		{
			"pos": Vector3(-21.5, 0.25, -42.0),
			"rot_y": 1.5,
			"name": "Hazire Bekçisi (Kömür Kedi)",
			"color": Color(0.15, 0.15, 0.18), # Asil Siyah Kedi
			"msg": "🐾 Hazirenin asil siyah kedisi başını okşatıp sakinleşti. (Maneviyat Tazelendi)"
		},
		{
			"pos": Vector3(34.2, 0.2, -6.5),
			"rot_y": 3.14,
			"name": "Kuyu Başı Tekiri (Smokin)",
			"color": Color(0.22, 0.25, 0.3), # Smokin / Çizgili
			"msg": "🐾 Kuyu başındaki sevimli kedi bacaklarına sürtündü!"
		}
	]
	
	for cd in cat_data:
		var cat = StaticBody3D.new()
		cat.position = cd["pos"]
		cat.rotation.y = cd["rot_y"]
		cat.add_to_group("interactables")
		cat.add_to_group("cats")
		
		# Çarpışma kutusu
		var col = CollisionShape3D.new()
		var c_box = BoxShape3D.new()
		c_box.size = Vector3(0.65, 0.5, 0.8)
		col.shape = c_box
		col.position.y = 0.25
		cat.add_child(col)
		
		# Kedi Gövde Modeli
		var mat = StandardMaterial3D.new()
		mat.albedo_color = cd["color"]
		mat.roughness = 0.85
		
		var body = MeshInstance3D.new()
		var b_box = BoxMesh.new()
		b_box.size = Vector3(0.28, 0.22, 0.48)
		body.mesh = b_box
		body.position.y = 0.18
		body.set_surface_override_material(0, mat)
		cat.add_child(body)
		
		# Baş ve Kulaklar
		var head = MeshInstance3D.new()
		var h_sph = SphereMesh.new()
		h_sph.radius = 0.12
		h_sph.height = 0.22
		head.mesh = h_sph
		head.position = Vector3(0, 0.26, 0.25)
		head.set_surface_override_material(0, mat)
		cat.add_child(head)
		
		for side in [-0.07, 0.07]:
			var ear = MeshInstance3D.new()
			var e_prism = PrismMesh.new()
			e_prism.size = Vector3(0.06, 0.08, 0.04)
			ear.mesh = e_prism
			ear.position = Vector3(side, 0.36, 0.24)
			ear.set_surface_override_material(0, mat)
			cat.add_child(ear)
			
		# Kıvrık Kuyruk
		var tail = MeshInstance3D.new()
		var t_cyl = CylinderMesh.new()
		t_cyl.top_radius = 0.03
		t_cyl.bottom_radius = 0.04
		t_cyl.height = 0.32
		tail.mesh = t_cyl
		tail.position = Vector3(0, 0.25, -0.32)
		tail.rotation.x = -0.7
		tail.set_surface_override_material(0, mat)
		cat.add_child(tail)
		
		# Etiket
		var clabel = Label3D.new()
		clabel.text = "🐱 " + cd["name"]
		clabel.font_size = 24
		clabel.pixel_size = 0.007
		clabel.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		clabel.modulate = Color(1.0, 0.9, 0.6)
		clabel.outline_size = 4
		clabel.position = Vector3(0, 0.65, 0)
		cat.add_child(clabel)
		
		# Etkileşim Script Mantığı
		cat.set_meta("interact_msg", cd["msg"])
		cat.set_meta("cat_name", cd["name"])
		cat.set_script(CatInteractionScript)
		
		add_child(cat)

# Kedi Sevme Etkileşim Sınıfı
var CatInteractionScript = preload("res://scripts/cat_interact.gd")
