extends Node3D

# Cihanşah - Profesyonel Tarihsel Osmanlı Şehir & Kapalıçarşı Mimarisi
# PBR Kaplamalı Taş Yollar, Cami, Büyük Kapalıçarşı, İç Dükkanlar ve EZ-Tree Ağaçları

const CharacterStyler = preload("res://scripts/character_styler.gd")

var tex_cobble: Texture2D
var tex_wood: Texture2D
var tex_roof: Texture2D
var tex_stone: Texture2D
var tex_velvet: Texture2D
var tex_carpet: Texture2D
var tex_carpet_turkuaz: Texture2D
var tex_carpet_gokmavi: Texture2D
var tex_carpet_yesil: Texture2D
var tex_minber_wood: Texture2D
var tex_minber_lattice: Texture2D
var tex_mahfil_wood: Texture2D
var tex_mahfil_lattice: Texture2D
var tex_mahfil_base_frieze: Texture2D
var tex_grass: Texture2D
var tex_grass_tuft: Texture2D
var mosque_carpet_mat: StandardMaterial3D
var current_carpet_type: String = "yesil"

var EZTreeScript = null
var InteractivePropScript = preload("res://scripts/interactive_prop.gd")
var HayCartScript = preload("res://scripts/hay_cart.gd")

func _ready() -> void:
	add_to_group("city_builder")
	load_resources()
	build_ground()
	build_grand_bazaar(Vector3(0, 0, 43)) # Kapalıçarşı güneyde (z = 24'te 2 kapılı anıtsal taç giriş)
	build_sadirvan(Vector3(0, 0, -18))     # Abdesthane / Şadırvan CAMİNİN ÖNÜNDE (Kuzey Cami Avlusu)
	build_mosque_complex(Vector3(0, 0, -42)) # İki büyük kapılı, ferah, yüksek kubbeli Cami-i Kebîr
	spawn_imam_npc(Vector3(0, 0.4, -53.2))  # Mihrap önünde huşû ile namaz kılan İmam Efendi
	build_sultan_carriage(Vector3(-18, 0, 8))
	build_tea_house_area(Vector3(22, 0, -5))
	build_residential_streets()
	build_city_props()
	spawn_realistic_trees()
	build_city_greenery_and_gardens()
	build_perimeter_hills_and_nature()
	build_climbable_mountain_trails_and_summits()
	build_historical_lake_and_pier(Vector3(62, 0, -32))
	spawn_assassin_hay_carts()
	spawn_assassin_contracts_board(Vector3(-6.0, 0, 18.0))
	build_rooftop_parkour_network()
	spawn_secret_assassin_chests()

func load_resources() -> void:
	tex_cobble = load("res://assets/textures/cobblestone.png")
	tex_wood = load("res://assets/textures/wood_facade.png")
	tex_roof = load("res://assets/textures/roof_tiles.png")
	tex_stone = load("res://assets/textures/stone_wall.png")
	tex_velvet = load("res://assets/textures/carriage_velvet.png")
	tex_carpet = load("res://assets/textures/oriental_carpet.png")
	tex_carpet_turkuaz = _load_texture_file("res://assets/textures/carpet_turkuaz.jpg")
	tex_carpet_gokmavi = _load_texture_file("res://assets/textures/carpet_gokmavi.jpg")
	tex_carpet_yesil = _load_texture_file("res://assets/textures/carpet_yesil.jpg")
	tex_minber_wood = _load_texture_file("res://assets/models/materials/[Wood Floor]/Wood_Floor.jpg")
	tex_minber_lattice = _load_texture_file("res://assets/models/materials/[Wood Bamboo]/Wood_Bamboo_Medium.jpg")
	tex_mahfil_wood = _load_texture_file("res://assets/textures/mahfil_wood.png")
	tex_mahfil_lattice = _load_texture_file("res://assets/textures/mahfil_lattice.png")
	tex_mahfil_base_frieze = _load_texture_file("res://assets/textures/mahfil_base_frieze.png")
	tex_grass = _load_texture_file("res://assets/textures/grass.png")
	tex_grass_tuft = _load_texture_file("res://assets/textures/grass_tuft.png")
	
	if ResourceLoader.exists("res://addons/ez-tree-godot-port/ez_tree.gd"):
		EZTreeScript = load("res://addons/ez-tree-godot-port/ez_tree.gd")

func _load_texture_file(res_path: String) -> Texture2D:
	var global_p = ProjectSettings.globalize_path(res_path)
	var img = Image.load_from_file(global_p)
	if img and not img.is_empty():
		return ImageTexture.create_from_image(img)
	if ResourceLoader.exists(res_path):
		var res = load(res_path)
		if res is Texture2D:
			return res
	return null

func set_mosque_carpet(carpet_type: String) -> void:
	current_carpet_type = carpet_type
	if mosque_carpet_mat:
		if carpet_type == "yesil" and tex_carpet_yesil:
			mosque_carpet_mat.albedo_texture = tex_carpet_yesil
		elif carpet_type == "gokmavi" and tex_carpet_gokmavi:
			mosque_carpet_mat.albedo_texture = tex_carpet_gokmavi
		elif tex_carpet_turkuaz:
			mosque_carpet_mat.albedo_texture = tex_carpet_turkuaz


func build_ground() -> void:
	var ground = StaticBody3D.new()
	ground.name = "Ground"
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(450, 1, 450)
	col.shape = box
	col.position.y = -0.5
	ground.add_child(col)
	
	# 1. Ana Zemin Katmanı: Yemyeşil Doğal Payitaht Çayırı (Lush Ottoman Meadow Grass)
	var mesh_inst = MeshInstance3D.new()
	var plane_mesh = BoxMesh.new()
	plane_mesh.size = Vector3(450, 1, 450)
	mesh_inst.mesh = plane_mesh
	mesh_inst.position.y = -0.5
	
	var grass_base_mat = StandardMaterial3D.new()
	if tex_grass:
		grass_base_mat.albedo_texture = tex_grass
		grass_base_mat.uv1_scale = Vector3(80, 80, 80)
	else:
		grass_base_mat.albedo_color = Color(0.28, 0.58, 0.22)
	grass_base_mat.roughness = 0.88
	mesh_inst.set_surface_override_material(0, grass_base_mat)
	ground.add_child(mesh_inst)
	
	# 2. Tarihi Arnavut Kaldırımı Kent Sokak Ağı (Urban Cobblestone Paving Network)
	var cobble_mat = StandardMaterial3D.new()
	if tex_cobble:
		cobble_mat.albedo_texture = tex_cobble
	else:
		cobble_mat.albedo_color = Color(0.45, 0.42, 0.38)
	cobble_mat.roughness = 0.75
	
	var street_segments = [
		# [Pozisyon, Ebat, UV Scale]
		# Ana Divanyolu Caddesi (Meydan boydan boya)
		[Vector3(0, 0.03, 10), Vector3(16.0, 0.06, 120.0), Vector3(3.5, 26.0, 3.5)],
		# Doğu-Batı Meydan Geçiş Aksı (Saray arabasından çay bahçesine)
		[Vector3(0, 0.032, 5), Vector3(110.0, 0.06, 14.0), Vector3(24.0, 3.2, 3.2)],
		# Batı Konaklar Ana Caddesi
		[Vector3(-32, 0.033, 4), Vector3(13.0, 0.06, 80.0), Vector3(3.0, 18.0, 3.0)],
		# Batı Çıkmaz Sokağı
		[Vector3(-46, 0.034, 4), Vector3(9.0, 0.06, 70.0), Vector3(2.0, 16.0, 2.0)],
		# Doğu Konaklar Ana Caddesi (Çınaraltı doğusu)
		[Vector3(34, 0.033, 4), Vector3(13.0, 0.06, 80.0), Vector3(3.0, 18.0, 3.0)],
		# Doğu Çıkmaz Sokağı
		[Vector3(48, 0.034, 4), Vector3(9.0, 0.06, 70.0), Vector3(2.0, 16.0, 2.0)],
		# Güney Kapalıçarşı Arkası Esnaf Yolu
		[Vector3(0, 0.033, 72), Vector3(95.0, 0.06, 13.0), Vector3(22.0, 3.0, 3.0)],
		# Cami Şadırvan Avlusu Taş Meydanı
		[Vector3(0, 0.035, -20), Vector3(35.0, 0.06, 26.0), Vector3(8.0, 6.0, 8.0)]
	]
	
	for seg in street_segments:
		var road = MeshInstance3D.new()
		var r_box = BoxMesh.new()
		r_box.size = seg[1]
		road.mesh = r_box
		road.position = seg[0]
		var seg_mat = cobble_mat.duplicate()
		seg_mat.uv1_scale = seg[2]
		road.set_surface_override_material(0, seg_mat)
		ground.add_child(road)
	
	add_child(ground)

# 3D Gerçekçi Çim Tutamı (Volumetric Cross-Quad Billboard Grass)
func spawn_grass_tuft(pos: Vector3, scale_mult: float = 1.0) -> Node3D:
	var tuft = Node3D.new()
	tuft.position = pos
	
	var mat = StandardMaterial3D.new()
	if tex_grass_tuft:
		mat.albedo_texture = tex_grass_tuft
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		mat.alpha_scissor_threshold = 0.45
	else:
		mat.albedo_color = Color(0.28, 0.6, 0.22)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 0.88
	
	for angle in [0.0, PI * 0.5]:
		var quad = MeshInstance3D.new()
		var qm = QuadMesh.new()
		qm.size = Vector2(0.9 * scale_mult, 0.75 * scale_mult)
		quad.mesh = qm
		quad.position.y = 0.38 * scale_mult
		quad.rotation.y = angle + randf_range(-0.15, 0.15)
		quad.set_surface_override_material(0, mat)
		tuft.add_child(quad)
		
	return tuft


# ----------------- BÜYÜK KAPALIÇARŞI (WALK-IN COVERED BAZAAR) -----------------

# ----------------- BÜYÜK KAPALIÇARŞI (WALK-IN COVERED BAZAAR) -----------------

func build_grand_bazaar(pos: Vector3) -> void:
	var bazaar = Node3D.new()
	bazaar.name = "GrandBazaar"
	bazaar.position = pos
	
	var stone_mat = StandardMaterial3D.new()
	if tex_stone:
		stone_mat.albedo_texture = tex_stone
		stone_mat.uv1_scale = Vector3(5, 3, 5)
	else:
		stone_mat.albedo_color = Color(0.82, 0.78, 0.72)
	stone_mat.roughness = 0.85
	
	var wood_mat = StandardMaterial3D.new()
	if tex_wood:
		wood_mat.albedo_texture = tex_wood
		wood_mat.uv1_scale = Vector3(2, 2, 2)
	else:
		wood_mat.albedo_color = Color(0.38, 0.24, 0.14)
	wood_mat.roughness = 0.75
	
	var roof_mat = StandardMaterial3D.new()
	if tex_roof:
		roof_mat.albedo_texture = tex_roof
		roof_mat.uv1_scale = Vector3(6, 4, 6)
	else:
		roof_mat.albedo_color = Color(0.68, 0.26, 0.16)
		
	# Kapalıçarşı Dış Duvarları (38 metre boyunda devasa kapalı çarşı holü)
	# Sol Duvar (Batı)
	var left_wall = StaticBody3D.new()
	var lcol = CollisionShape3D.new()
	var lbox = BoxShape3D.new()
	lbox.size = Vector3(1.5, 7.2, 38.0)
	lcol.shape = lbox
	lcol.position = Vector3(-9.0, 3.6, 0)
	left_wall.add_child(lcol)
	var lmesh = MeshInstance3D.new()
	var lb = BoxMesh.new()
	lb.size = Vector3(1.5, 7.2, 38.0)
	lmesh.mesh = lb
	lmesh.position = Vector3(-9.0, 3.6, 0)
	lmesh.set_surface_override_material(0, stone_mat)
	left_wall.add_child(lmesh)
	bazaar.add_child(left_wall)
	
	# Sağ Duvar (Doğu)
	var right_wall = StaticBody3D.new()
	var rcol = CollisionShape3D.new()
	var rbox = BoxShape3D.new()
	rbox.size = Vector3(1.5, 7.2, 38.0)
	rcol.shape = rbox
	rcol.position = Vector3(9.0, 3.6, 0)
	right_wall.add_child(rcol)
	var rmesh = MeshInstance3D.new()
	var rb = BoxMesh.new()
	rb.size = Vector3(1.5, 7.2, 38.0)
	rmesh.mesh = rb
	rmesh.position = Vector3(9.0, 3.6, 0)
	rmesh.set_surface_override_material(0, stone_mat)
	right_wall.add_child(rmesh)
	bazaar.add_child(right_wall)
	
	# Arka Duvar (Güney, z = +19)
	var back_wall = StaticBody3D.new()
	var bcol = CollisionShape3D.new()
	var bbox = BoxShape3D.new()
	bbox.size = Vector3(19.5, 7.2, 1.5)
	bcol.shape = bbox
	bcol.position = Vector3(0, 3.6, 19.0)
	back_wall.add_child(bcol)
	var bmesh = MeshInstance3D.new()
	var bb = BoxMesh.new()
	bb.size = Vector3(19.5, 7.2, 1.5)
	bmesh.mesh = bb
	bmesh.position = Vector3(0, 3.6, 19.0)
	bmesh.set_surface_override_material(0, stone_mat)
	back_wall.add_child(bmesh)
	bazaar.add_child(back_wall)
	
	# ----------------- 2 KAPILI ANITSAL TAÇ KAPI (Kuzey, z = -19, Meydana Açılan) -----------------
	# Eski şadırvanın olduğu yerde tam 2 kapılı girişten çarşının içine girilir!
	# 1. Sol Köşe Duvarı
	var fl_wall = StaticBody3D.new()
	var flcol = CollisionShape3D.new()
	var flbox = BoxShape3D.new()
	flbox.size = Vector3(2.5, 7.2, 1.8)
	flcol.shape = flbox
	flcol.position = Vector3(-7.75, 3.6, -19.0)
	fl_wall.add_child(flcol)
	var flm = MeshInstance3D.new()
	var flmb = BoxMesh.new()
	flmb.size = Vector3(2.5, 7.2, 1.8)
	flm.mesh = flmb
	flm.position = Vector3(-7.75, 3.6, -19.0)
	flm.set_surface_override_material(0, stone_mat)
	fl_wall.add_child(flm)
	bazaar.add_child(fl_wall)
	
	# 2. Sağ Köşe Duvarı
	var fr_wall = StaticBody3D.new()
	var frcol = CollisionShape3D.new()
	var frbox = BoxShape3D.new()
	frbox.size = Vector3(2.5, 7.2, 1.8)
	frcol.shape = frbox
	frcol.position = Vector3(7.75, 3.6, -19.0)
	fr_wall.add_child(frcol)
	var frm = MeshInstance3D.new()
	var frmb = BoxMesh.new()
	frmb.size = Vector3(2.5, 7.2, 1.8)
	frm.mesh = frmb
	frm.position = Vector3(7.75, 3.6, -19.0)
	frm.set_surface_override_material(0, stone_mat)
	fr_wall.add_child(frm)
	bazaar.add_child(fr_wall)
	
	# 3. İki Kapı Arasındaki Orta Mermer Taç Paye / Sütun
	var mid_pier = StaticBody3D.new()
	var mpcol = CollisionShape3D.new()
	var mpbox = BoxShape3D.new()
	mpbox.size = Vector3(2.4, 7.2, 2.0)
	mpcol.shape = mpbox
	mpcol.position = Vector3(0, 3.6, -19.0)
	mid_pier.add_child(mpcol)
	var mpm = MeshInstance3D.new()
	var mpmb = BoxMesh.new()
	mpmb.size = Vector3(2.4, 7.2, 2.0)
	mpm.mesh = mpmb
	mpm.position = Vector3(0, 3.6, -19.0)
	var marble_gate_mat = StandardMaterial3D.new()
	marble_gate_mat.albedo_color = Color(0.92, 0.90, 0.86)
	marble_gate_mat.roughness = 0.5
	mpm.set_surface_override_material(0, marble_gate_mat)
	mid_pier.add_child(mpm)
	
	# Orta Sütunda Altın Osmanlı Arması / Tuğrası
	var tughra = MeshInstance3D.new()
	var t_cyl = CylinderMesh.new()
	t_cyl.top_radius = 0.45
	t_cyl.bottom_radius = 0.45
	t_cyl.height = 0.08
	tughra.mesh = t_cyl
	tughra.position = Vector3(0, 3.8, -20.05)
	tughra.rotation.x = PI / 2.0
	var gold_mat = StandardMaterial3D.new()
	gold_mat.albedo_color = Color(0.96, 0.82, 0.22)
	gold_mat.metallic = 0.95
	gold_mat.roughness = 0.2
	tughra.set_surface_override_material(0, gold_mat)
	mid_pier.add_child(tughra)
	bazaar.add_child(mid_pier)
	
	# 4. Sol Kapı Kemer Üstü (5 metre genişliğinde açık kapı geçidi)
	var l_arch_top = StaticBody3D.new()
	var lat_col = CollisionShape3D.new()
	var lat_box = BoxShape3D.new()
	lat_box.size = Vector3(5.3, 2.2, 1.8)
	lat_col.shape = lat_box
	lat_col.position = Vector3(-3.85, 6.1, -19.0)
	l_arch_top.add_child(lat_col)
	var lat_mesh = MeshInstance3D.new()
	var lat_b = BoxMesh.new()
	lat_b.size = Vector3(5.3, 2.2, 1.8)
	lat_mesh.mesh = lat_b
	lat_mesh.position = Vector3(-3.85, 6.1, -19.0)
	lat_mesh.set_surface_override_material(0, stone_mat)
	l_arch_top.add_child(lat_mesh)
	bazaar.add_child(l_arch_top)
	
	# 5. Sağ Kapı Kemer Üstü (5 metre genişliğinde açık kapı geçidi)
	var r_arch_top = StaticBody3D.new()
	var rat_col = CollisionShape3D.new()
	var rat_box = BoxShape3D.new()
	rat_box.size = Vector3(5.3, 2.2, 1.8)
	rat_col.shape = rat_box
	rat_col.position = Vector3(3.85, 6.1, -19.0)
	r_arch_top.add_child(rat_col)
	var rat_mesh = MeshInstance3D.new()
	var rat_b = BoxMesh.new()
	rat_b.size = Vector3(5.3, 2.2, 1.8)
	rat_mesh.mesh = rat_b
	rat_mesh.position = Vector3(3.85, 6.1, -19.0)
	rat_mesh.set_surface_override_material(0, stone_mat)
	r_arch_top.add_child(rat_mesh)
	bazaar.add_child(r_arch_top)
	
	# 6. Açık Tarihi Ahşap Çift Kapı Kanatları
	# Sol kapının kanatları
	spawn_wooden_door_leaf(bazaar, Vector3(-6.1, 2.5, -18.2), -0.7)
	spawn_wooden_door_leaf(bazaar, Vector3(-1.6, 2.5, -18.2), 0.7)
	# Sağ kapının kanatları
	spawn_wooden_door_leaf(bazaar, Vector3(1.6, 2.5, -18.2), -0.7)
	spawn_wooden_door_leaf(bazaar, Vector3(6.1, 2.5, -18.2), 0.7)
	
	# 7. Kapı Giriş Kitabesi
	var plaque = Label3D.new()
	plaque.text = "🏛️ DERSAADET BÜYÜK KAPALIÇARŞISI 🏛️\n[ BÂB-I BEYAZIT - 2 KAPILI ÇİFT KANATLI GİRİŞ ]"
	plaque.billboard = 1
	plaque.font_size = 24
	plaque.modulate = Color(1.0, 0.88, 0.25)
	plaque.outline_size = 6
	plaque.position = Vector3(0, 6.2, -20.2)
	bazaar.add_child(plaque)
	
	# Kapı Giriş Fenerleri
	for lx in [-3.85, 0.0, 3.85]:
		var gate_light = OmniLight3D.new()
		gate_light.light_color = Color(1.0, 0.85, 0.45)
		gate_light.light_energy = 3.2
		gate_light.omni_range = 9.0
		gate_light.position = Vector3(lx, 4.2, -19.8)
		bazaar.add_child(gate_light)
	
	# Kapalıçarşı Tonoz Çatısı & Kubbeleri
	var roof_body = StaticBody3D.new()
	var rcol_roof = CollisionShape3D.new()
	var rbox_roof = BoxShape3D.new()
	rbox_roof.size = Vector3(19.5, 0.8, 38.0)
	rcol_roof.shape = rbox_roof
	rcol_roof.position = Vector3(0, 7.4, 0)
	roof_body.add_child(rcol_roof)
	var rmesh_roof = MeshInstance3D.new()
	var rmb = BoxMesh.new()
	rmb.size = Vector3(19.5, 0.8, 38.0)
	rmesh_roof.mesh = rmb
	rmesh_roof.position = Vector3(0, 7.4, 0)
	rmesh_roof.set_surface_override_material(0, roof_mat)
	roof_body.add_child(rmesh_roof)
	bazaar.add_child(roof_body)
	
	# Çarşı İçi Sıra Kubbeler
	for z_dome in [-10.0, 0.0, 10.0]:
		var dome = MeshInstance3D.new()
		var s = SphereMesh.new()
		s.radius = 4.2
		s.height = 3.5
		dome.mesh = s
		dome.position = Vector3(0, 7.8, z_dome)
		var lead_mat = StandardMaterial3D.new()
		lead_mat.albedo_color = Color(0.35, 0.44, 0.48)
		lead_mat.metallic = 0.5
		dome.set_surface_override_material(0, lead_mat)
		bazaar.add_child(dome)
		
	# Çarşı İçi Halı Yolluk (Girişten sona uzanan Osmanlı halısı)
	var runner = MeshInstance3D.new()
	var r_box = BoxMesh.new()
	r_box.size = Vector3(6.5, 0.04, 34.0)
	runner.mesh = r_box
	runner.position = Vector3(0, 0.02, 0)
	var c_mat = StandardMaterial3D.new()
	if tex_carpet:
		c_mat.albedo_texture = tex_carpet
		c_mat.uv1_scale = Vector3(2, 12, 1)
	else:
		c_mat.albedo_color = Color(0.68, 0.15, 0.15)
	runner.set_surface_override_material(0, c_mat)
	bazaar.add_child(runner)
	
	# Çarşı İçi Aydınlatma (Sıcak Gaz Lambaları ve Pirinç Avizeler)
	for z_light in [-12.0, -4.0, 4.0, 12.0]:
		var lantern = OmniLight3D.new()
		lantern.light_color = Color(1.0, 0.82, 0.45)
		lantern.light_energy = 2.8
		lantern.omni_range = 9.0
		lantern.position = Vector3(0, 4.8, z_light)
		bazaar.add_child(lantern)
		
		var chain = MeshInstance3D.new()
		var ccyl = CylinderMesh.new()
		ccyl.top_radius = 0.03
		ccyl.bottom_radius = 0.03
		ccyl.height = 2.4
		chain.mesh = ccyl
		chain.position = Vector3(0, 6.0, z_light)
		var chain_mat = StandardMaterial3D.new()
		chain_mat.albedo_color = Color(0.85, 0.72, 0.2)
		chain_mat.metallic = 0.9
		chain.set_surface_override_material(0, chain_mat)
		bazaar.add_child(chain)

	# ----------------- İÇ DÜKKANLAR VE ESNAFLAR -----------------
	# Dükkan 1: Tarihi Halıcı / Kilimci (Sol Giriş)
	build_carpet_shop(bazaar, Vector3(-5.5, 0, -8.0))
	
	# Dükkan 2: Mısır Çarşısı Baharatçısı (Sağ Giriş)
	build_spice_shop(bazaar, Vector3(5.5, 0, -8.0))
	
	# Dükkan 3: Bakırcı & Çayhane Tezgahı (Sol Derin)
	build_copper_shop(bazaar, Vector3(-5.5, 0, 6.0))
	
	# Dükkan 4: Kuyumcu & Antika Silahçı (Sağ Derin)
	build_antique_shop(bazaar, Vector3(5.5, 0, 6.0))
	
	# ----------------- KAPALIÇARŞI HANIMLARI (Osmanlı Kadın Sakinleri & Gown 3D Modeli) -----------------
	spawn_bazaar_woman_npc(bazaar, Vector3(-2.2, 0, -6.8), 0.75, "Ayşe Hatun", "Hayırlı günler evladım! Teşkilâtın gözü pek neferlerini görmek kalbimizi ferahlatır. Bu Hereke halıları pek zarifmiş.")
	spawn_bazaar_woman_npc(bazaar, Vector3(2.4, 0, -4.5), -1.15, "Fatma Hanım", "Selamünaleyküm Cihanşah Bey! Şakir Ağa'nın amber ve safran kokusu ta çarşı kapısına kadar vuruyor.")
	spawn_bazaar_woman_npc(bazaar, Vector3(-1.8, 0, 4.2), 1.55, "Emine Kadın", "İşittik ki Padişahımızın kerimesi Mihrimah Sultan'ın alayı bu havaliden geçecekmiş. Dualarımız sizinle.")
	spawn_bazaar_woman_npc(bazaar, Vector3(1.8, 0, 7.8), -0.65, "Gülfem Hatun", "Hoş geldiniz beyim! Hilâl-i Ahmer için yetimlere erzak toplandığını duyduk, Cenâb-ı Hak hayrınızı kabul buyursun.")
	
	add_child(bazaar)

func spawn_wooden_door_leaf(parent: Node3D, pos: Vector3, rot_y: float) -> void:
	var door = MeshInstance3D.new()
	var dbox = BoxMesh.new()
	dbox.size = Vector3(1.8, 4.8, 0.14)
	door.mesh = dbox
	door.position = pos
	door.rotation.y = rot_y
	var dmat = StandardMaterial3D.new()
	if tex_wood:
		dmat.albedo_texture = tex_wood
	else:
		dmat.albedo_color = Color(0.3, 0.18, 0.1)
	dmat.roughness = 0.7
	door.set_surface_override_material(0, dmat)
	parent.add_child(door)

func build_carpet_shop(parent: Node3D, pos: Vector3) -> void:
	var shop = Node3D.new()
	shop.position = pos
	
	# Halı Tezgahı
	var table = StaticBody3D.new()
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(3.2, 0.9, 1.4)
	col.shape = box
	col.position.y = 0.45
	table.add_child(col)
	var tm = MeshInstance3D.new()
	var tbox = BoxMesh.new()
	tbox.size = Vector3(3.2, 0.9, 1.4)
	tm.mesh = tbox
	tm.position.y = 0.45
	var wmat = StandardMaterial3D.new()
	wmat.albedo_color = Color(0.38, 0.24, 0.14)
	tm.set_surface_override_material(0, wmat)
	table.add_child(tm)
	shop.add_child(table)
	
	# Duvarda Asılı Hereke İpek Halısı
	var wall_carpet = MeshInstance3D.new()
	var cp_box = BoxMesh.new()
	cp_box.size = Vector3(0.08, 2.6, 3.6)
	wall_carpet.mesh = cp_box
	wall_carpet.position = Vector3(-2.1, 3.2, 0)
	var cmat = StandardMaterial3D.new()
	if tex_carpet:
		cmat.albedo_texture = tex_carpet
	else:
		cmat.albedo_color = Color(0.75, 0.15, 0.15)
	wall_carpet.set_surface_override_material(0, cmat)
	shop.add_child(wall_carpet)
	
	# Halıcı Esnafı
	spawn_vendor_npc(shop, Vector3(0, 0, -1.2), "Halıcı Haydar Usta\n[Konuş / İncele (E)]")
	parent.add_child(shop)

func build_spice_shop(parent: Node3D, pos: Vector3) -> void:
	var shop = Node3D.new()
	shop.position = pos
	
	# Baharat Tezgahı
	var table = StaticBody3D.new()
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(3.2, 0.9, 1.4)
	col.shape = box
	col.position.y = 0.45
	table.add_child(col)
	var tm = MeshInstance3D.new()
	var tbox = BoxMesh.new()
	tbox.size = Vector3(3.2, 0.9, 1.4)
	tm.mesh = tbox
	tm.position.y = 0.45
	var wmat = StandardMaterial3D.new()
	wmat.albedo_color = Color(0.38, 0.24, 0.14)
	tm.set_surface_override_material(0, wmat)
	table.add_child(tm)
	shop.add_child(table)
	
	# Renkli Baharat Kümeleri (Safran, Kırmızı Biber, Kimyon)
	var colors = [Color(0.95, 0.78, 0.1), Color(0.85, 0.18, 0.12), Color(0.48, 0.32, 0.15), Color(0.88, 0.55, 0.18)]
	for i in range(4):
		var cone = MeshInstance3D.new()
		var cm = CylinderMesh.new()
		cm.top_radius = 0.0
		cm.bottom_radius = 0.25
		cm.height = 0.4
		cone.mesh = cm
		cone.position = Vector3(-1.0 + (i * 0.65), 1.1, 0)
		var sp_mat = StandardMaterial3D.new()
		sp_mat.albedo_color = colors[i]
		cone.set_surface_override_material(0, sp_mat)
		shop.add_child(cone)
		
	# Baharatçı Esnafı
	spawn_vendor_npc(shop, Vector3(0, 0, -1.2), "Baharatçı Şakir Ağa\n[Şifalı Merhem / Bilgi]")
	parent.add_child(shop)

func build_copper_shop(parent: Node3D, pos: Vector3) -> void:
	var shop = Node3D.new()
	shop.position = pos
	
	var table = StaticBody3D.new()
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(3.2, 0.9, 1.4)
	col.shape = box
	col.position.y = 0.45
	table.add_child(col)
	var tm = MeshInstance3D.new()
	var tbox = BoxMesh.new()
	tbox.size = Vector3(3.2, 0.9, 1.4)
	tm.mesh = tbox
	tm.position.y = 0.45
	var wmat = StandardMaterial3D.new()
	wmat.albedo_color = Color(0.38, 0.24, 0.14)
	tm.set_surface_override_material(0, wmat)
	table.add_child(tm)
	shop.add_child(table)
	
	# Bakır Semaver & İbrikler
	var samovar = MeshInstance3D.new()
	var sm = CylinderMesh.new()
	sm.top_radius = 0.2
	sm.bottom_radius = 0.15
	sm.height = 0.55
	samovar.mesh = sm
	samovar.position = Vector3(0, 1.18, 0)
	var copper_mat = StandardMaterial3D.new()
	copper_mat.albedo_color = Color(0.85, 0.45, 0.25)
	copper_mat.metallic = 0.95
	copper_mat.roughness = 0.2
	samovar.set_surface_override_material(0, copper_mat)
	shop.add_child(samovar)
	
	spawn_vendor_npc(shop, Vector3(0, 0, -1.2), "Bakırcı Rüstem\n[Demir & Bakır Sanatı]")
	parent.add_child(shop)

func build_antique_shop(parent: Node3D, pos: Vector3) -> void:
	var shop = Node3D.new()
	shop.position = pos
	
	var table = StaticBody3D.new()
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(3.2, 0.9, 1.4)
	col.shape = box
	col.position.y = 0.45
	table.add_child(col)
	var tm = MeshInstance3D.new()
	var tbox = BoxMesh.new()
	tbox.size = Vector3(3.2, 0.9, 1.4)
	tm.mesh = tbox
	tm.position.y = 0.45
	var wmat = StandardMaterial3D.new()
	wmat.albedo_color = Color(0.38, 0.24, 0.14)
	tm.set_surface_override_material(0, wmat)
	table.add_child(tm)
	shop.add_child(table)
	
	# Kavisli Osmanlı Yatağan Kılıcı ve Altın Tabak
	var sword = MeshInstance3D.new()
	var sb = BoxMesh.new()
	sb.size = Vector3(0.08, 0.05, 0.9)
	sword.mesh = sb
	sword.position = Vector3(0, 0.95, 0)
	var steel_mat = StandardMaterial3D.new()
	steel_mat.albedo_color = Color(0.9, 0.9, 0.95)
	steel_mat.metallic = 0.95
	steel_mat.roughness = 0.15
	sword.set_surface_override_material(0, steel_mat)
	shop.add_child(sword)
	
	spawn_vendor_npc(shop, Vector3(0, 0, -1.2), "Sarraf & Antikacı Ziya\n[Nadir Eşyalar & Mühürler]")
	parent.add_child(shop)

func spawn_vendor_npc(parent: Node3D, local_pos: Vector3, label_text: String) -> void:
	var vendor = CharacterBody3D.new()
	vendor.name = "VendorNPC"
	vendor.add_to_group("interactables")
	vendor.position = local_pos
	
	var col = CollisionShape3D.new()
	var cap = CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.85
	col.shape = cap
	col.position.y = 0.925
	vendor.add_child(col)
	
	var soldier_res = load("res://assets/models/Soldier.glb")
	if soldier_res:
		var model = soldier_res.instantiate()
		vendor.add_child(model)
		var anim = model.get_node_or_null("AnimationPlayer")
		if anim and anim.has_animation("Idle"):
			anim.play("Idle")
		CharacterStyler.style_character(model, "vendor")
	else:
		var body = MeshInstance3D.new()
		var b_cap = CapsuleMesh.new()
		b_cap.radius = 0.35
		b_cap.height = 1.75
		body.mesh = b_cap
		body.position.y = 0.875
		vendor.add_child(body)
	
	var label = Label3D.new()
	label.text = label_text
	label.billboard = 1
	label.font_size = 18
	label.modulate = Color(1.0, 0.9, 0.4)
	label.outline_size = 4
	label.position = Vector3(0, 2.2, 0)
	vendor.add_child(label)
	
	parent.add_child(vendor)

func spawn_bazaar_woman_npc(parent: Node3D, local_pos: Vector3, rot_y: float, woman_name: String, dialogue_text: String) -> void:
	var woman = CharacterBody3D.new()
	woman.name = "BazaarWomanNPC_" + woman_name.replace(" ", "_")
	woman.add_to_group("interactables")
	woman.position = local_pos
	woman.rotation.y = rot_y
	woman.set_meta("woman_name", woman_name)
	woman.set_meta("dialogue_text", dialogue_text)
	
	var col = CollisionShape3D.new()
	var cap = CapsuleShape3D.new()
	cap.radius = 0.38
	cap.height = 1.72
	col.shape = cap
	col.position.y = 0.86
	woman.add_child(col)
	
	var gown_res = load("res://assets/models/gown/scene.gltf")
	if gown_res:
		var model = gown_res.instantiate()
		model.name = "GownModel"
		model.scale = Vector3(1.0, 1.0, 1.0)
		model.position = Vector3(0, 0.02, 0)
		woman.add_child(model)
	else:
		var body = MeshInstance3D.new()
		var b_cap = CapsuleMesh.new()
		b_cap.radius = 0.35
		b_cap.height = 1.65
		body.mesh = b_cap
		body.position.y = 0.825
		woman.add_child(body)
		
	# Hakiki İnsan Yüzü, Gözler, Kaşlar, Burun, Dudaklar, Saç ve İpek Yaşmak
	build_woman_face_and_head(woman)
		
	var label = Label3D.new()
	label.name = "NameLabel"
	label.text = woman_name + "\n[Kapalıçarşı Sakini]"
	label.billboard = 1
	label.font_size = 20
	label.outline_size = 5
	label.modulate = Color(1.0, 0.90, 0.96)
	label.position = Vector3(0, 2.15, 0)
	woman.add_child(label)
	
	woman.set_script(preload("res://scripts/bazaar_woman.gd"))
	parent.add_child(woman)

func build_woman_face_and_head(parent: Node3D) -> void:
	var head_root = Node3D.new()
	head_root.name = "HeadAndFace"
	head_root.position = Vector3(0, 1.62, 0.08)
	
	# 1. Ten Rengi Kafa & Yüz Kaidesi (Doğal Sıcak İnsan Teni)
	var skin_mat = StandardMaterial3D.new()
	skin_mat.albedo_color = Color(0.90, 0.77, 0.65)
	skin_mat.roughness = 0.75
	
	var head = MeshInstance3D.new()
	var hm = SphereMesh.new()
	hm.radius = 0.125
	hm.height = 0.245
	head.mesh = hm
	head.position = Vector3(0, 0, 0)
	head.set_surface_override_material(0, skin_mat)
	head_root.add_child(head)
	
	# 2. Doğal Koyu Dalgalı Saç (Alın ve Şakakları Çevreleyen Perçem)
	var hair_mat = StandardMaterial3D.new()
	hair_mat.albedo_color = Color(0.12, 0.08, 0.05)
	hair_mat.roughness = 0.85
	
	var hair_top = MeshInstance3D.new()
	var htm = SphereMesh.new()
	htm.radius = 0.130
	htm.height = 0.15
	hair_top.mesh = htm
	hair_top.position = Vector3(0, 0.065, -0.02)
	hair_top.set_surface_override_material(0, hair_mat)
	head_root.add_child(hair_top)
	
	var bangs = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(0.12, 0.03, 0.04)
	bangs.mesh = bm
	bangs.position = Vector3(0, 0.075, 0.085)
	bangs.set_surface_override_material(0, hair_mat)
	head_root.add_child(bangs)
	
	# 3. İfade Dolu Canlı Gözler (Göz Akı + Koyu Ela Gözbebeği + Üst Kirpik + Hilâl Kaş)
	var eye_white_mat = StandardMaterial3D.new()
	eye_white_mat.albedo_color = Color(0.96, 0.96, 0.96)
	
	var pupil_mat = StandardMaterial3D.new()
	pupil_mat.albedo_color = Color(0.14, 0.09, 0.06)
	pupil_mat.roughness = 0.2
	
	var lash_mat = StandardMaterial3D.new()
	lash_mat.albedo_color = Color(0.08, 0.05, 0.04)
	
	var brow_mat = StandardMaterial3D.new()
	brow_mat.albedo_color = Color(0.16, 0.10, 0.07)
	
	for eye_x in [-0.036, 0.036]:
		var eye = MeshInstance3D.new()
		var em = SphereMesh.new()
		em.radius = 0.014
		em.height = 0.016
		eye.mesh = em
		eye.position = Vector3(eye_x, 0.02, 0.098)
		eye.set_surface_override_material(0, eye_white_mat)
		head_root.add_child(eye)
		
		var pupil = MeshInstance3D.new()
		var pm = SphereMesh.new()
		pm.radius = 0.008
		pm.height = 0.008
		pupil.mesh = pm
		pupil.position = Vector3(eye_x, 0.02, 0.108)
		pupil.set_surface_override_material(0, pupil_mat)
		head_root.add_child(pupil)
		
		var lash = MeshInstance3D.new()
		var lm = BoxMesh.new()
		lm.size = Vector3(0.028, 0.003, 0.005)
		lash.mesh = lm
		lash.position = Vector3(eye_x, 0.032, 0.102)
		lash.set_surface_override_material(0, lash_mat)
		head_root.add_child(lash)
		
		var brow = MeshInstance3D.new()
		var brm = BoxMesh.new()
		brm.size = Vector3(0.034, 0.004, 0.005)
		brow.mesh = brm
		brow.position = Vector3(eye_x, 0.046, 0.096)
		brow.rotation.z = -0.12 if eye_x > 0 else 0.12
		brow.set_surface_override_material(0, brow_mat)
		head_root.add_child(brow)
		
	# 4. Zarif Burun
	var nose = MeshInstance3D.new()
	var nm = PrismMesh.new()
	nm.size = Vector3(0.022, 0.038, 0.028)
	nose.mesh = nm
	nose.position = Vector3(0, -0.01, 0.112)
	nose.rotation.x = PI * 0.5
	nose.set_surface_override_material(0, skin_mat)
	head_root.add_child(nose)
	
	# 5. Elmacık Kemikleri & Doğal Allık
	var blush_mat = StandardMaterial3D.new()
	blush_mat.albedo_color = Color(0.88, 0.62, 0.56)
	blush_mat.roughness = 0.85
	
	for bx in [-0.054, 0.054]:
		var blush = MeshInstance3D.new()
		var blm = SphereMesh.new()
		blm.radius = 0.020
		blm.height = 0.015
		blush.mesh = blm
		blush.position = Vector3(bx, -0.015, 0.092)
		blush.set_surface_override_material(0, blush_mat)
		head_root.add_child(blush)
		
	# 6. Gül Kurusu Zarif Dudaklar
	var lip_mat = StandardMaterial3D.new()
	lip_mat.albedo_color = Color(0.78, 0.36, 0.36)
	lip_mat.roughness = 0.5
	
	var upper_lip = MeshInstance3D.new()
	var ulm = BoxMesh.new()
	ulm.size = Vector3(0.034, 0.007, 0.010)
	upper_lip.mesh = ulm
	upper_lip.position = Vector3(0, -0.042, 0.106)
	upper_lip.set_surface_override_material(0, lip_mat)
	head_root.add_child(upper_lip)
	
	var lower_lip = MeshInstance3D.new()
	var llm = BoxMesh.new()
	llm.size = Vector3(0.028, 0.007, 0.009)
	lower_lip.mesh = llm
	lower_lip.position = Vector3(0, -0.052, 0.103)
	lower_lip.set_surface_override_material(0, lip_mat)
	head_root.add_child(lower_lip)
	
	# 7. Tarihi Osmanlı İpek Yaşmağı (Draped Silk Headscarf)
	var scarf_mat = StandardMaterial3D.new()
	scarf_mat.albedo_color = Color(0.94, 0.91, 0.85)
	scarf_mat.roughness = 0.65
	
	var scarf_hood = MeshInstance3D.new()
	var shm = SphereMesh.new()
	shm.radius = 0.142
	shm.height = 0.27
	scarf_hood.mesh = shm
	scarf_hood.position = Vector3(0, 0.025, -0.055)
	scarf_hood.set_surface_override_material(0, scarf_mat)
	head_root.add_child(scarf_hood)
	
	var scarf_drape = MeshInstance3D.new()
	var sdm = CylinderMesh.new()
	sdm.top_radius = 0.12
	sdm.bottom_radius = 0.19
	sdm.height = 0.18
	scarf_drape.mesh = sdm
	scarf_drape.position = Vector3(0, -0.10, 0)
	scarf_drape.set_surface_override_material(0, scarf_mat)
	head_root.add_child(scarf_drape)
	
	parent.add_child(head_root)

# ----------------- GERÇEKÇİ AĞAÇLAR (EZ-TREE ADDON) -----------------

func spawn_realistic_trees() -> void:
	var tree_coords = [
		# Cami Ön Avlusu & Şadırvan gölgelikleri
		Vector3(-9, 0, -18), Vector3(9, 0, -18),
		Vector3(-12, 0, -25), Vector3(12, 0, -25),
		# Kapalıçarşı 2 Kapılı Taç Girişi önü (z = 24 hizası)
		Vector3(-12, 0, 22), Vector3(12, 0, 22),
		# Meydan ortası
		Vector3(-8, 0, 6), Vector3(8, 0, 6),
		# Çınaraltı Çay Bahçesi açık avlusu (Ağaçlar binanın dışında, açık gölgelikte durur)
		Vector3(14.0, 0, -3.5), Vector3(14.0, 0, -11.0),
		# Yan sokaklar ve konak bahçeleri
		Vector3(-26, 0, -4), Vector3(-26, 0, 14),
		Vector3(28, 0, 14)
	]
	
	for i in range(tree_coords.size()):
		var pos = tree_coords[i]
		var tree_body = StaticBody3D.new()
		tree_body.position = pos
		
		# Gövde çarpışması
		var col = CollisionShape3D.new()
		var cyl_col = CylinderShape3D.new()
		cyl_col.radius = 0.45
		cyl_col.height = 3.5
		col.shape = cyl_col
		col.position.y = 1.75
		tree_body.add_child(col)
		
		if EZTreeScript:
			var tree_inst = Node3D.new()
			tree_inst.set_script(EZTreeScript)
			tree_inst.scale = Vector3(0.7, 0.7, 0.7)
			tree_inst.set("rng_seed", 1000 + i * 7919)
			tree_inst.set("branch_levels", 2)
			tree_inst.set("leaf_count", 14)
			tree_inst.set("branch_length", PackedFloat32Array([8.0, 2.8, 2.5, 1.4]))
			tree_inst.set("branch_radius", PackedFloat32Array([0.42, 0.8, 0.65, 0.9]))
			if tree_inst.has_method("generate"):
				tree_inst.generate()
			tree_body.add_child(tree_inst)
		else:
			spawn_fallback_tree_to(tree_body)
			
		add_child(tree_body)

func spawn_fallback_tree_to(parent_node: Node3D) -> void:
	var trunk = MeshInstance3D.new()
	var t_cyl = CylinderMesh.new()
	t_cyl.top_radius = 0.25
	t_cyl.bottom_radius = 0.38
	t_cyl.height = 3.0
	trunk.mesh = t_cyl
	trunk.position.y = 1.5
	var bark = StandardMaterial3D.new()
	bark.albedo_color = Color(0.32, 0.22, 0.15)
	trunk.set_surface_override_material(0, bark)
	parent_node.add_child(trunk)
	
	var foliage = MeshInstance3D.new()
	var fs = SphereMesh.new()
	fs.radius = 2.4
	fs.height = 3.6
	foliage.mesh = fs
	foliage.position.y = 4.2
	var lf = StandardMaterial3D.new()
	lf.albedo_color = Color(0.14, 0.38, 0.18)
	foliage.set_surface_override_material(0, lf)
	parent_node.add_child(foliage)

# ----------------- CAMİ, FAYTON VE SOKAKLAR -----------------

func build_mosque_complex(pos: Vector3) -> void:
	var mosque = Node3D.new()
	mosque.name = "MosqueComplex"
	mosque.position = pos
	
	var stone_mat = StandardMaterial3D.new()
	if tex_stone:
		stone_mat.albedo_texture = tex_stone
		stone_mat.uv1_scale = Vector3(5, 3, 5)
	else:
		stone_mat.albedo_color = Color(0.88, 0.85, 0.78)
	stone_mat.roughness = 0.85
	
	var marble_mat = StandardMaterial3D.new()
	marble_mat.albedo_color = Color(0.95, 0.94, 0.90)
	marble_mat.roughness = 0.35
	
	var wood_mat = StandardMaterial3D.new()
	if tex_wood:
		wood_mat.albedo_texture = tex_wood
		wood_mat.uv1_scale = Vector3(2, 2, 2)
	else:
		wood_mat.albedo_color = Color(0.36, 0.22, 0.12)
	wood_mat.roughness = 0.75
	
	var lead_mat = StandardMaterial3D.new()
	lead_mat.albedo_color = Color(0.38, 0.46, 0.52)
	lead_mat.metallic = 0.65
	lead_mat.roughness = 0.35
	
	var gold_mat = StandardMaterial3D.new()
	gold_mat.albedo_color = Color(0.98, 0.82, 0.18)
	gold_mat.metallic = 0.95
	gold_mat.roughness = 0.2
	
	var carpet_mat = StandardMaterial3D.new()
	if tex_carpet:
		carpet_mat.albedo_texture = tex_carpet
		carpet_mat.uv1_scale = Vector3(10, 12, 1)
	else:
		carpet_mat.albedo_color = Color(0.62, 0.14, 0.12)
	carpet_mat.roughness = 0.9
	
	# ================= 1. CAMİ HARİM ZEMİNİ & TAVUS SAF HALISI =================
	# Namazlık Tabanı (Yerden 0.40m Yüksekte Mermer Kaide Üzerinde Tavus Saf Halısı)
	var floor_body = StaticBody3D.new()
	var fcol = CollisionShape3D.new()
	var fbox = BoxShape3D.new()
	fbox.size = Vector3(23.6, 0.8, 27.6)
	fcol.shape = fbox
	fcol.position.y = 0.2
	floor_body.add_child(fcol)
	
	var floor_mesh = MeshInstance3D.new()
	var fm = BoxMesh.new()
	fm.size = Vector3(23.6, 0.8, 27.6)
	floor_mesh.mesh = fm
	floor_mesh.position.y = 0.2
	
	# Otantik Tavus Cami Halısı Materyali (Yeşil, Turkuaz veya Gök Mavi)
	mosque_carpet_mat = StandardMaterial3D.new()
	if current_carpet_type == "yesil" and tex_carpet_yesil:
		mosque_carpet_mat.albedo_texture = tex_carpet_yesil
	elif current_carpet_type == "gokmavi" and tex_carpet_gokmavi:
		mosque_carpet_mat.albedo_texture = tex_carpet_gokmavi
	elif tex_carpet_turkuaz:
		mosque_carpet_mat.albedo_texture = tex_carpet_turkuaz
	else:
		mosque_carpet_mat.albedo_color = Color(0.08, 0.52, 0.28)
		
	mosque_carpet_mat.roughness = 0.85
	# 26m derinlikte saf sıraları, 22m genişlikte orantılı Selçuklu örgü ve lale deseni
	mosque_carpet_mat.uv1_scale = Vector3(8.0, 16.0, 1.0)
	mosque_carpet_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	floor_mesh.set_surface_override_material(0, mosque_carpet_mat)
	floor_body.add_child(floor_mesh)
	mosque.add_child(floor_body)
	
	# Giriş Kapıları Önü Mermer Basamaklar (Harime zarif geçiş)
	for step_door_x in [-4.5, 4.5]:
		var step_inst = MeshInstance3D.new()
		var st_box = BoxMesh.new()
		st_box.size = Vector3(3.6, 0.35, 1.4)
		step_inst.mesh = st_box
		step_inst.position = Vector3(step_door_x, 0.175, 13.8)
		step_inst.set_surface_override_material(0, marble_mat)
		mosque.add_child(step_inst)

	# ================= 2. İÇİNE GİRİLEBİLİR DIŞ DUVARLAR (HOLLOW) =================
	# Kuzey Kıble Duvarı (Arkada, z = -13)
	var north_wall = StaticBody3D.new()
	var ncol = CollisionShape3D.new()
	var nbox = BoxShape3D.new()
	nbox.size = Vector3(22.0, 12.0, 1.4)
	ncol.shape = nbox
	ncol.position = Vector3(0, 6.0, -13.0)
	north_wall.add_child(ncol)
	var nm = MeshInstance3D.new()
	var nmesh = BoxMesh.new()
	nmesh.size = Vector3(22.0, 12.0, 1.4)
	nm.mesh = nmesh
	nm.position = Vector3(0, 6.0, -13.0)
	nm.set_surface_override_material(0, stone_mat)
	north_wall.add_child(nm)
	mosque.add_child(north_wall)
	
	# Doğu Sağ Duvar (x = +11)
	var east_wall = StaticBody3D.new()
	var ecol = CollisionShape3D.new()
	var ebox = BoxShape3D.new()
	ebox.size = Vector3(1.4, 12.0, 26.0)
	ecol.shape = ebox
	ecol.position = Vector3(11.0, 6.0, 0.0)
	east_wall.add_child(ecol)
	var em = MeshInstance3D.new()
	var emesh = BoxMesh.new()
	emesh.size = Vector3(1.4, 12.0, 26.0)
	em.mesh = emesh
	em.position = Vector3(11.0, 6.0, 0.0)
	em.set_surface_override_material(0, stone_mat)
	east_wall.add_child(em)
	mosque.add_child(east_wall)
	
	# Batı Sol Duvar (x = -11)
	var west_wall = StaticBody3D.new()
	var wcol = CollisionShape3D.new()
	var wbox = BoxShape3D.new()
	wbox.size = Vector3(1.4, 12.0, 26.0)
	wcol.shape = wbox
	wcol.position = Vector3(-11.0, 6.0, 0.0)
	west_wall.add_child(wcol)
	var wm = MeshInstance3D.new()
	var wmesh = BoxMesh.new()
	wmesh.size = Vector3(1.4, 12.0, 26.0)
	wm.mesh = wmesh
	wm.position = Vector3(-11.0, 6.0, 0.0)
	wm.set_surface_override_material(0, stone_mat)
	west_wall.add_child(wm)
	mosque.add_child(west_wall)

	# ================= 3. GÜNEY GİRİŞ CEPHESİ VE İKİ BÜYÜK GERÇEK KAPI =================
	# Sol Duvar Kanadı (x = -11 ile x = -5.8 arası, genişlik 5.2m)
	var s_left = StaticBody3D.new()
	var slcol = CollisionShape3D.new()
	var slbox = BoxShape3D.new()
	slbox.size = Vector3(5.2, 12.0, 1.4)
	slcol.shape = slbox
	slcol.position = Vector3(-8.4, 6.0, 13.0)
	s_left.add_child(slcol)
	var slm = MeshInstance3D.new()
	var slmesh = BoxMesh.new()
	slmesh.size = Vector3(5.2, 12.0, 1.4)
	slm.mesh = slmesh
	slm.position = Vector3(-8.4, 6.0, 13.0)
	slm.set_surface_override_material(0, stone_mat)
	s_left.add_child(slm)
	mosque.add_child(s_left)
	
	# Orta Bölme Sütun Duvarı (x = -3.2 ile x = +3.2 arası, genişlik 6.4m)
	var s_mid = StaticBody3D.new()
	var smcol = CollisionShape3D.new()
	var smbox = BoxShape3D.new()
	smbox.size = Vector3(6.4, 12.0, 1.4)
	smcol.shape = smbox
	smcol.position = Vector3(0.0, 6.0, 13.0)
	s_mid.add_child(smcol)
	var smm = MeshInstance3D.new()
	var smmesh = BoxMesh.new()
	smmesh.size = Vector3(6.4, 12.0, 1.4)
	smm.mesh = smmesh
	smm.position = Vector3(0.0, 6.0, 13.0)
	smm.set_surface_override_material(0, stone_mat)
	s_mid.add_child(smm)
	mosque.add_child(s_mid)
	
	# Sağ Duvar Kanadı (x = +5.8 ile x = +11 arası, genişlik 5.2m)
	var s_right = StaticBody3D.new()
	var srcol = CollisionShape3D.new()
	var srbox = BoxShape3D.new()
	srbox.size = Vector3(5.2, 12.0, 1.4)
	srcol.shape = srbox
	srcol.position = Vector3(8.4, 6.0, 13.0)
	s_right.add_child(srcol)
	var srm = MeshInstance3D.new()
	var srmesh = BoxMesh.new()
	srmesh.size = Vector3(5.2, 12.0, 1.4)
	srm.mesh = srmesh
	srm.position = Vector3(8.4, 6.0, 13.0)
	srm.set_surface_override_material(0, stone_mat)
	s_right.add_child(srm)
	mosque.add_child(s_right)
	
	# İki Kapının Üst Kirişleri (y = 4.2 ile 12.0 arası kapalı, altları serbest açık geçit)
	for door_x in [-4.5, 4.5]:
		var header = StaticBody3D.new()
		var hcol = CollisionShape3D.new()
		var hbox = BoxShape3D.new()
		hbox.size = Vector3(2.6, 7.8, 1.4)
		hcol.shape = hbox
		hcol.position = Vector3(door_x, 8.1, 13.0)
		header.add_child(hcol)
		var hm = MeshInstance3D.new()
		var hmesh = BoxMesh.new()
		hmesh.size = Vector3(2.6, 7.8, 1.4)
		hm.mesh = hmesh
		hm.position = Vector3(door_x, 8.1, 13.0)
		hm.set_surface_override_material(0, stone_mat)
		header.add_child(hm)
		mosque.add_child(header)
		
		# Anıtsal Mermer Kapı Kemeri & Taç Söveleri
		var portal_arch = MeshInstance3D.new()
		var pabox = BoxMesh.new()
		pabox.size = Vector3(3.2, 0.6, 1.8)
		portal_arch.mesh = pabox
		portal_arch.position = Vector3(door_x, 4.3, 13.1)
		portal_arch.set_surface_override_material(0, marble_mat)
		mosque.add_child(portal_arch)
		
		# İki Yan Söve Mermerleri
		for side_sign in [-1.0, 1.0]:
			var jamb = MeshInstance3D.new()
			var jbox = BoxMesh.new()
			jbox.size = Vector3(0.4, 4.2, 1.8)
			jamb.mesh = jbox
			jamb.position = Vector3(door_x + side_sign * 1.4, 2.1, 13.1)
			jamb.set_surface_override_material(0, marble_mat)
			mosque.add_child(jamb)
			
		# İçe Doğru Açık Duran Heybetli Oymalı Ahşap Cami Kapı Kanatları
		# Sol Kanat
		var door_l = MeshInstance3D.new()
		var dbox = BoxMesh.new()
		dbox.size = Vector3(0.12, 3.8, 1.25)
		door_l.mesh = dbox
		door_l.position = Vector3(door_x - 1.2, 2.0, 12.3)
		door_l.rotation.y = -0.5
		door_l.set_surface_override_material(0, wood_mat)
		mosque.add_child(door_l)
		# Sağ Kanat
		var door_r = MeshInstance3D.new()
		door_r.mesh = dbox
		door_r.position = Vector3(door_x + 1.2, 2.0, 12.3)
		door_r.rotation.y = 0.5
		door_r.set_surface_override_material(0, wood_mat)
		mosque.add_child(door_r)
		
		# Cami Giriş Ahşap Pabuçluğu (Ayakkabılık)
		var shoe_rack = MeshInstance3D.new()
		var srb = BoxMesh.new()
		srb.size = Vector3(0.36, 1.15, 0.90)
		shoe_rack.mesh = srb
		shoe_rack.position = Vector3(door_x + 1.65, 0.58, 12.6)
		shoe_rack.set_surface_override_material(0, wood_mat)
		mosque.add_child(shoe_rack)
		
		var pabuc_label = Label3D.new()
		pabuc_label.text = "👞 Pabuçluk\n[Ayakkabılar Çıkarılır]"
		pabuc_label.font_size = 14
		pabuc_label.modulate = Color(1.0, 0.9, 0.5)
		pabuc_label.outline_size = 3
		pabuc_label.position = Vector3(door_x + 1.65, 1.35, 12.6)
		mosque.add_child(pabuc_label)
		
		# Raflarda Duran Deri Pabuçlar / Mestler
		for row_y in [0.25, 0.55, 0.85]:
			for p_z in [-0.22, 0.22]:
				var spair = MeshInstance3D.new()
				var spb = BoxMesh.new()
				spb.size = Vector3(0.24, 0.08, 0.14)
				spair.mesh = spb
				spair.position = Vector3(door_x + 1.65, row_y, 12.6 + p_z)
				var lp_mat = StandardMaterial3D.new()
				lp_mat.albedo_color = Color(0.18, 0.11, 0.07)
				spair.set_surface_override_material(0, lp_mat)
				mosque.add_child(spair)
		
		# Kapı Üstü Altın Hat Kitabesi
		var sign_mesh = MeshInstance3D.new()
		var sbox = BoxMesh.new()
		sbox.size = Vector3(2.4, 0.45, 0.1)
		sign_mesh.mesh = sbox
		sign_mesh.position = Vector3(door_x, 4.75, 13.8)
		var sign_mat = StandardMaterial3D.new()
		sign_mat.albedo_color = Color(0.1, 0.12, 0.1)
		sign_mat.roughness = 0.5
		sign_mesh.set_surface_override_material(0, sign_mat)
		mosque.add_child(sign_mesh)
		
		var label = Label3D.new()
		if door_x < 0:
			label.text = "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ"
		else:
			label.text = "سَلَامٌ عَلَيْكُمْ طِبْتُمْ فَادْخُلُوهَا"
		label.font_size = 32
		label.pixel_size = 0.005
		label.modulate = Color(1.0, 0.88, 0.3)
		label.outline_size = 6
		label.position = Vector3(door_x, 4.75, 13.9)
		mosque.add_child(label)

	# İki Kapı Arasındaki Anıtsal Mermer Niş ve Tuğra (x = 0)
	var center_niche = MeshInstance3D.new()
	var cn_box = BoxMesh.new()
	cn_box.size = Vector3(3.2, 6.0, 0.3)
	center_niche.mesh = cn_box
	center_niche.position = Vector3(0, 3.5, 13.8)
	center_niche.set_surface_override_material(0, marble_mat)
	mosque.add_child(center_niche)
	
	var tugra_label = Label3D.new()
	tugra_label.text = "🕌 CAMİ-İ KEBÎR 🕌"
	tugra_label.font_size = 36
	tugra_label.pixel_size = 0.005
	tugra_label.modulate = Color(0.98, 0.82, 0.2)
	tugra_label.outline_size = 7
	tugra_label.position = Vector3(0, 5.0, 14.0)
	mosque.add_child(tugra_label)

	# ================= 4. SON CEMAAT YERİ (REVAKLI ÖN SUFFA) =================
	# Revak Mermer Sütunları
	for px in [-8.0, -2.6, 2.6, 8.0]:
		var col_body = StaticBody3D.new()
		var ccol = CollisionShape3D.new()
		var ccyl = CylinderShape3D.new()
		ccyl.radius = 0.38
		ccyl.height = 5.5
		ccol.shape = ccyl
		ccol.position = Vector3(px, 2.75, 16.5)
		col_body.add_child(ccol)
		var c_mesh = MeshInstance3D.new()
		var cyl_m = CylinderMesh.new()
		cyl_m.top_radius = 0.35
		cyl_m.bottom_radius = 0.42
		cyl_m.height = 5.5
		c_mesh.mesh = cyl_m
		c_mesh.position = Vector3(px, 2.75, 16.5)
		c_mesh.set_surface_override_material(0, marble_mat)
		col_body.add_child(c_mesh)
		mosque.add_child(col_body)
		
	# Revak Kemer Saçağı ve 3 Küçük Giriş Kubbesi
	var porch_roof = MeshInstance3D.new()
	var prbox = BoxMesh.new()
	prbox.size = Vector3(20.0, 0.6, 4.0)
	porch_roof.mesh = prbox
	porch_roof.position = Vector3(0, 5.8, 15.0)
	porch_roof.set_surface_override_material(0, stone_mat)
	mosque.add_child(porch_roof)
	
	for dome_x in [-5.5, 0.0, 5.5]:
		var s_dome = MeshInstance3D.new()
		var sd_mesh = SphereMesh.new()
		sd_mesh.radius = 2.4
		sd_mesh.height = 2.4
		s_dome.mesh = sd_mesh
		s_dome.position = Vector3(dome_x, 6.8, 15.0)
		s_dome.set_surface_override_material(0, lead_mat)
		mosque.add_child(s_dome)

	# ================= 5. HEYBETLİ MİNARE =================
	var minaret = StaticBody3D.new()
	var mcol = CollisionShape3D.new()
	var mcyl = CylinderShape3D.new()
	mcyl.radius = 1.4
	mcyl.height = 28.0
	mcol.shape = mcyl
	mcol.position = Vector3(13.2, 14.0, 10.0)
	minaret.add_child(mcol)
	var m_mesh = MeshInstance3D.new()
	var cyl_mesh = CylinderMesh.new()
	cyl_mesh.top_radius = 1.15
	cyl_mesh.bottom_radius = 1.5
	cyl_mesh.height = 25.0
	m_mesh.mesh = cyl_mesh
	m_mesh.position = Vector3(13.2, 12.5, 10.0)
	m_mesh.set_surface_override_material(0, stone_mat)
	minaret.add_child(m_mesh)
	
	# Şerefe ve Külah
	var balcony = MeshInstance3D.new()
	var b_cyl = CylinderMesh.new()
	b_cyl.top_radius = 1.95
	b_cyl.bottom_radius = 1.35
	b_cyl.height = 1.5
	balcony.mesh = b_cyl
	balcony.position = Vector3(13.2, 21.0, 10.0)
	balcony.set_surface_override_material(0, stone_mat)
	minaret.add_child(balcony)
	
	var spire = MeshInstance3D.new()
	var cone = CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 1.25
	cone.height = 7.0
	spire.mesh = cone
	spire.position = Vector3(13.2, 28.0, 10.0)
	spire.set_surface_override_material(0, lead_mat)
	minaret.add_child(spire)
	mosque.add_child(minaret)

	# ================= 6. FERAH & YÜKSEK İMPARATORLUK KUBBESİ (KASNAKLI MİMARİ) =================
	# Tavan Saçağı & Dört Büyük Taşıyıcı Kemer (y = 12.5)
	var ceiling_frame = MeshInstance3D.new()
	var cf_box = BoxMesh.new()
	cf_box.size = Vector3(22.6, 0.8, 26.6)
	ceiling_frame.mesh = cf_box
	ceiling_frame.position = Vector3(0, 12.4, 0)
	ceiling_frame.set_surface_override_material(0, stone_mat)
	mosque.add_child(ceiling_frame)
	
	# Kubbe Kasnağı (8 Adet Kemerli Renkli Vitray Pencereli Sekizgen Kasnak, y = 12.8 ile 16.5 arası)
	var drum = MeshInstance3D.new()
	var drum_cyl = CylinderMesh.new()
	drum_cyl.top_radius = 8.6
	drum_cyl.bottom_radius = 8.6
	drum_cyl.height = 3.6
	drum.mesh = drum_cyl
	drum.position = Vector3(0, 14.6, 0)
	drum.set_surface_override_material(0, marble_mat)
	mosque.add_child(drum)
	
	# Kasnak Vitray Pencereleri (Revzen-i Menkuş ışığı)
	var window_mat = StandardMaterial3D.new()
	window_mat.albedo_color = Color(0.95, 0.85, 0.5, 0.85)
	window_mat.emission_enabled = true
	window_mat.emission = Color(1.0, 0.88, 0.5)
	window_mat.emission_energy_multiplier = 0.8
	for w_idx in range(8):
		var w_angle = float(w_idx) * (TAU / 8.0)
		var win = MeshInstance3D.new()
		var wb = BoxMesh.new()
		wb.size = Vector3(1.8, 2.2, 0.2)
		win.mesh = wb
		win.position = Vector3(cos(w_angle) * 8.65, 14.6, sin(w_angle) * 8.65)
		win.rotation.y = -w_angle + PI * 0.5
		win.set_surface_override_material(0, window_mat)
		mosque.add_child(win)
		
	# Heybetli Ana Kubbe (y = 16.4'ten yükselerek 23m zirveye ulaşır - İçeriyi ASLA daraltmaz)
	var dome = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 8.8
	sphere.height = 8.5
	sphere.is_hemisphere = true
	dome.mesh = sphere
	dome.position = Vector3(0, 16.4, 0)
	dome.set_surface_override_material(0, lead_mat)
	mosque.add_child(dome)
	
	# Altın Alem (Zirvede)
	var crescent = MeshInstance3D.new()
	var c_cyl = CylinderMesh.new()
	c_cyl.top_radius = 0.05
	c_cyl.bottom_radius = 0.22
	c_cyl.height = 3.2
	crescent.mesh = c_cyl
	crescent.position = Vector3(0, 25.0, 0)
	crescent.set_surface_override_material(0, gold_mat)
	mosque.add_child(crescent)

	# ================= 7. İÇ MEKAN: İMAM YERİ (HAKİKİ 3D MİHRÂB-I ŞERÎF) =================
	# Kıble Duvarı Merkezinde 3D PBR Mukarnaslı Gerçek Osmanlı Mihrabı (x = 0, z = -12.1)
	var mihrap = Node3D.new()
	mihrap.name = "Mihrap"
	mihrap.position = Vector3(0, 0.4, -12.1)
	
	var mihrap_scene = load("res://assets/models/mihrab/scene.gltf")
	if mihrap_scene:
		var mihrap_model = mihrap_scene.instantiate()
		mihrap_model.name = "Mihrap3DModel"
		mihrap_model.scale = Vector3(0.088, 0.088, 0.088)
		mihrap_model.rotation.y = 0.0
		mihrap_model.position = Vector3(0, 0, 0.15)
		
		# Siyah kutuyu (Object_4) kaldır ve asıl dokulu nişi (Object_2, Object_3) görünür kıl
		for child in mihrap_model.find_children("*", "MeshInstance3D"):
			if child.name == "Object_4":
				child.visible = false
				child.queue_free()
			elif child.name in ["Object_2", "Object_3"]:
				var mat = child.get_surface_override_material(0)
				if not mat:
					mat = child.mesh.surface_get_material(0)
				if mat is StandardMaterial3D:
					mat.cull_mode = BaseMaterial3D.CULL_DISABLED
					mat.roughness = 0.35
					mat.metallic = 0.02
					
		mihrap.add_child(mihrap_model)
		
		# Mihrap Nişi İçine Sıcak Altın Varak Işıltısı
		var niche_glow = OmniLight3D.new()
		niche_glow.light_color = Color(1.0, 0.90, 0.65)
		niche_glow.light_energy = 2.8
		niche_glow.omni_range = 8.0
		niche_glow.position = Vector3(0, 2.8, 0.8)
		mihrap.add_child(niche_glow)
		
		# Sağlam Mermer Çarpışma Duvarı
		var m_body = StaticBody3D.new()
		var m_col = CollisionShape3D.new()
		var m_box = BoxShape3D.new()
		m_box.size = Vector3(3.8, 5.8, 1.2)
		m_col.shape = m_box
		m_col.position = Vector3(0, 2.9, -0.4)
		m_body.add_child(m_col)
		mihrap.add_child(m_body)
	else:
		# Yedek Mermer Nişi
		var m_niche = MeshInstance3D.new()
		var mn_box = BoxMesh.new()
		mn_box.size = Vector3(3.2, 5.6, 0.8)
		m_niche.mesh = mn_box
		m_niche.position.y = 2.8
		m_niche.set_surface_override_material(0, marble_mat)
		mihrap.add_child(m_niche)
		
		# Mukarnaslı Altın Kavis
		var muqarnas = MeshInstance3D.new()
		var mq_mesh = PrismMesh.new()
		mq_mesh.size = Vector3(2.2, 2.0, 0.6)
		muqarnas.mesh = mq_mesh
		muqarnas.position = Vector3(0, 4.4, 0.2)
		muqarnas.rotation.x = PI
		muqarnas.set_surface_override_material(0, gold_mat)
		mihrap.add_child(muqarnas)
	
	# İmam Seccadesi (Zümrüt Yeşil İpek Çuha)
	var imam_carpet = MeshInstance3D.new()
	var ic_mesh = BoxMesh.new()
	ic_mesh.size = Vector3(1.6, 0.04, 2.4)
	imam_carpet.mesh = ic_mesh
	imam_carpet.position = Vector3(0, 0.03, 1.2)
	var green_carpet_mat = StandardMaterial3D.new()
	green_carpet_mat.albedo_color = Color(0.12, 0.38, 0.2)
	green_carpet_mat.roughness = 0.85
	imam_carpet.set_surface_override_material(0, green_carpet_mat)
	mihrap.add_child(imam_carpet)
	
	# Mihrap Yanı Dev Pirinç Şamdanlar & Kandil Işıkları
	for cand_x in [-2.1, 2.1]:
		var cand_body = MeshInstance3D.new()
		var cb_cyl = CylinderMesh.new()
		cb_cyl.top_radius = 0.12
		cb_cyl.bottom_radius = 0.28
		cb_cyl.height = 1.8
		cand_body.mesh = cb_cyl
		cand_body.position = Vector3(cand_x, 0.9, 0.4)
		cand_body.set_surface_override_material(0, gold_mat)
		mihrap.add_child(cand_body)
		
		# Mum & Alev
		var candle = MeshInstance3D.new()
		var cm = CylinderMesh.new()
		cm.top_radius = 0.06
		cm.bottom_radius = 0.06
		cm.height = 0.5
		candle.mesh = cm
		candle.position = Vector3(cand_x, 1.95, 0.4)
		var candle_wax = StandardMaterial3D.new()
		candle_wax.albedo_color = Color(0.96, 0.94, 0.88)
		candle.set_surface_override_material(0, candle_wax)
		mihrap.add_child(candle)
		
		var flame_light = OmniLight3D.new()
		flame_light.light_color = Color(1.0, 0.82, 0.45)
		flame_light.light_energy = 2.2
		flame_light.omni_range = 7.0
		flame_light.position = Vector3(cand_x, 2.3, 0.4)
		mihrap.add_child(flame_light)
		
	var mihrap_label = Label3D.new()
	mihrap_label.text = "فَوَلِّ وَجْهَكَ شَطْرَ الْمَسْجِدِ الْحَرَامِ"
	mihrap_label.font_size = 80
	mihrap_label.pixel_size = 0.004
	mihrap_label.modulate = Color(1.0, 0.92, 0.35)
	mihrap_label.outline_size = 10
	mihrap_label.position = Vector3(0, 5.75, 0.55)
	mihrap.add_child(mihrap_label)
	mosque.add_child(mihrap)

	# ================= 8. İÇ MEKAN: GERÇEK OSMANLI MİNBER-İ ŞERÎFİ (WALK-IN MİNBER) =================
	# minber.skp ve klasik Osmanlı mimarisine birebir uygun: Açık taç kapı, 12 basamaklı çıkılabilir merdiven,
	# kündekâri kapalı yan aynalıklar, köşk altı anıtsal mermer kaide ve gövde duvarları (asla havada uçmaz),
	# 4 mermer sütunlu, kemerli, oymalı rahleli ve kurşun külahlı heybetli üst hutbe köşkü
	var minber = Node3D.new()
	minber.name = "Minber"
	minber.position = Vector3(5.2, 0.4, -9.0) # Caminin zemin seviyesinde (+0.4)
	
	# Minber Malzemeleri
	var mb_marble = StandardMaterial3D.new()
	mb_marble.albedo_color = Color(0.95, 0.94, 0.92) # Has Marmara Beyaz Mermeri
	mb_marble.roughness = 0.35
	
	var mb_wood = StandardMaterial3D.new()
	if tex_mahfil_wood:
		mb_wood.albedo_texture = tex_mahfil_wood
		mb_wood.uv1_scale = Vector3(2.0, 2.0, 1.0)
	elif tex_minber_wood:
		mb_wood.albedo_texture = tex_minber_wood
		mb_wood.uv1_scale = Vector3(2.0, 2.0, 1.0)
	else:
		mb_wood.albedo_color = Color(0.24, 0.14, 0.08) # Oymalı Abanoz / Ceviz Ahşap
	mb_wood.roughness = 0.55
	
	var mb_lattice = StandardMaterial3D.new()
	if tex_mahfil_lattice:
		mb_lattice.albedo_texture = tex_mahfil_lattice
		mb_lattice.uv1_scale = Vector3(3.0, 3.0, 1.0)
	elif tex_minber_lattice:
		mb_lattice.albedo_texture = tex_minber_lattice
		mb_lattice.uv1_scale = Vector3(3.0, 3.0, 1.0)
	else:
		mb_lattice.albedo_color = Color(0.32, 0.20, 0.11)
	mb_lattice.roughness = 0.65
	
	var mb_gold = StandardMaterial3D.new()
	mb_gold.albedo_color = Color(0.96, 0.82, 0.32) # Varak Altın
	mb_gold.metallic = 0.95
	mb_gold.roughness = 0.2
	
	var mb_lead = StandardMaterial3D.new()
	mb_lead.albedo_color = Color(0.32, 0.35, 0.38) # Has Kurşun Külah
	mb_lead.metallic = 0.35
	mb_lead.roughness = 0.45

	var mb_velvet = StandardMaterial3D.new()
	mb_velvet.albedo_color = Color(0.12, 0.38, 0.20) # Zümrüt Yeşili İpek Çuha
	mb_velvet.roughness = 0.85

	# ================= A. GİRİŞ TAÇ KAPISI (Ön Cephe Z = 2.35) =================
	var mb_gate_body = StaticBody3D.new()
	mb_gate_body.name = "MinberTacKapi"
	
	for col_x in [-0.55, 0.55]:
		# Taban Mermer Pabuçları
		var base_mesh = MeshInstance3D.new()
		var mb_gate_base_m = BoxMesh.new()
		mb_gate_base_m.size = Vector3(0.28, 0.24, 0.30)
		base_mesh.mesh = mb_gate_base_m
		base_mesh.position = Vector3(col_x, 0.12, 2.35)
		base_mesh.set_surface_override_material(0, mb_marble)
		mb_gate_body.add_child(base_mesh)
		
		# Yan Mermer Taşıyıcı Dikmeler
		var post_mesh = MeshInstance3D.new()
		var mb_gate_post_m = BoxMesh.new()
		mb_gate_post_m.size = Vector3(0.22, 2.40, 0.24)
		post_mesh.mesh = mb_gate_post_m
		post_mesh.position = Vector3(col_x, 1.32, 2.35)
		post_mesh.set_surface_override_material(0, mb_marble)
		mb_gate_body.add_child(post_mesh)
		
		var post_col = CollisionShape3D.new()
		var mb_gate_post_shape = BoxShape3D.new()
		mb_gate_post_shape.size = Vector3(0.24, 2.45, 0.26)
		post_col.shape = mb_gate_post_shape
		post_col.position = Vector3(col_x, 1.32, 2.35)
		mb_gate_body.add_child(post_col)
		
		# Sütun Başlığı ve Altın Bilezik
		var cap_mesh = MeshInstance3D.new()
		var mb_gate_cap_m = BoxMesh.new()
		mb_gate_cap_m.size = Vector3(0.28, 0.16, 0.30)
		cap_mesh.mesh = mb_gate_cap_m
		cap_mesh.position = Vector3(col_x, 2.55, 2.35)
		cap_mesh.set_surface_override_material(0, mb_marble)
		mb_gate_body.add_child(cap_mesh)
		
		var ring_mesh = MeshInstance3D.new()
		var mb_gate_ring_m = BoxMesh.new()
		mb_gate_ring_m.size = Vector3(0.30, 0.05, 0.32)
		ring_mesh.mesh = mb_gate_ring_m
		ring_mesh.position = Vector3(col_x, 2.48, 2.35)
		ring_mesh.set_surface_override_material(0, mb_gold)
		mb_gate_body.add_child(ring_mesh)

	# Taç Kapı Üst Kemeri ve Kitabelik
	var arch_lintel = MeshInstance3D.new()
	var mb_arch_lintel_m = BoxMesh.new()
	mb_arch_lintel_m.size = Vector3(1.36, 0.35, 0.26)
	arch_lintel.mesh = mb_arch_lintel_m
	arch_lintel.position = Vector3(0, 2.68, 2.35)
	arch_lintel.set_surface_override_material(0, mb_marble)
	mb_gate_body.add_child(arch_lintel)
	
	var arch_col = CollisionShape3D.new()
	var mb_arch_shape = BoxShape3D.new()
	mb_arch_shape.size = Vector3(1.36, 0.35, 0.26)
	arch_col.shape = mb_arch_shape
	arch_col.position = Vector3(0, 2.68, 2.35)
	mb_gate_body.add_child(arch_col)
	
	# Taç Kapı Tepeliği & Altın Alem
	var crest_mesh = MeshInstance3D.new()
	var mb_crest_m = PrismMesh.new()
	mb_crest_m.size = Vector3(1.34, 0.55, 0.22)
	crest_mesh.mesh = mb_crest_m
	crest_mesh.position = Vector3(0, 3.12, 2.35)
	crest_mesh.set_surface_override_material(0, mb_marble)
	mb_gate_body.add_child(crest_mesh)
	
	var crest_finial = MeshInstance3D.new()
	var mb_crest_finial_m = CylinderMesh.new()
	mb_crest_finial_m.top_radius = 0.02
	mb_crest_finial_m.bottom_radius = 0.06
	mb_crest_finial_m.height = 0.40
	crest_finial.mesh = mb_crest_finial_m
	crest_finial.position = Vector3(0, 3.55, 2.35)
	crest_finial.set_surface_override_material(0, mb_gold)
	mb_gate_body.add_child(crest_finial)
	
	var mb_gate_label = Label3D.new()
	mb_gate_label.text = "لَا إِلٰهَ إِلَّا الله\nمُحَمَّدٌ رَسُولُ الله"
	mb_gate_label.font_size = 28
	mb_gate_label.pixel_size = 0.0048
	mb_gate_label.modulate = Color(1.0, 0.88, 0.38)
	mb_gate_label.outline_size = 5
	mb_gate_label.position = Vector3(0, 2.70, 2.50)
	mb_gate_body.add_child(mb_gate_label)
	minber.add_child(mb_gate_body)

	# ================= B. 12 BASAMAKLI ÇIKILABİLİR MERDİVEN =================
	var mb_stairs_body = StaticBody3D.new()
	mb_stairs_body.name = "MinberBasamaklari"
	
	var num_steps = 12
	var step_start_z = 2.05
	var step_end_z = -0.95
	var step_depth = (step_start_z - step_end_z) / float(num_steps) # 0.25m
	var step_rise = 0.20 # 12 adımda 2.40m net çıkış
	var step_width = 0.84
	
	for s in range(num_steps):
		var step_top_y = (s + 1) * step_rise
		var step_center_z = step_start_z - (s * step_depth) - (step_depth * 0.5)
		
		# Ahşap Basamak Rıht ve Basma Yüzeyi
		var step_mesh = MeshInstance3D.new()
		var mb_step_m = BoxMesh.new()
		mb_step_m.size = Vector3(step_width, step_rise, step_depth * 1.02)
		step_mesh.mesh = mb_step_m
		step_mesh.position = Vector3(0, step_top_y - (step_rise * 0.5), step_center_z)
		step_mesh.set_surface_override_material(0, mb_wood)
		mb_stairs_body.add_child(step_mesh)
		
		# Basamak Burun Pirinç Çıtası (Nosing Gold Trim)
		var nosing = MeshInstance3D.new()
		var mb_nosing_m = BoxMesh.new()
		mb_nosing_m.size = Vector3(step_width, 0.025, 0.03)
		nosing.mesh = mb_nosing_m
		nosing.position = Vector3(0, step_top_y - 0.012, step_center_z + (step_depth * 0.5))
		nosing.set_surface_override_material(0, mb_gold)
		mb_stairs_body.add_child(nosing)
		
		# Fiziksel Basamak Çarpışma Kutusu
		var step_col = CollisionShape3D.new()
		var mb_step_shape = BoxShape3D.new()
		mb_step_shape.size = Vector3(step_width, step_rise, step_depth * 1.02)
		step_col.shape = mb_step_shape
		step_col.position = Vector3(0, step_top_y - (step_rise * 0.5), step_center_z)
		mb_stairs_body.add_child(step_col)

	# Merdiven Üzerinde Takılmadan Pürüzsüz Yürüme Rampası (Smooth Stair Walk Collider)
	var ramp_col = CollisionShape3D.new()
	var mb_ramp_shape = BoxShape3D.new()
	mb_ramp_shape.size = Vector3(step_width, 0.08, 3.90)
	ramp_col.shape = mb_ramp_shape
	ramp_col.position = Vector3(0, 1.20, 0.615)
	ramp_col.rotation.x = 0.5934 # Merdiven çıkış yönünde pozitif eğim
	mb_stairs_body.add_child(ramp_col)
	minber.add_child(mb_stairs_body)

	# ================= C. YAN KÜNDEKÂRİ AYNALIKLAR VE KAPALI MERDİVEN GÖVDESİ =================
	var mb_flanks_body = StaticBody3D.new()
	mb_flanks_body.name = "MinberYanAynalar"
	
	# Handrail / balustrade koordinatları
	# Başlangıç: z = 2.25, y = 1.07 (Ön Taç Kapı Sövesi)
	# Bitiş: z = -1.02, y = 3.28 (Köşk Ön Sütun Başlığı)
	var rail_len = 3.95
	var rail_rot_x = 0.5934 # Pozitif eğim: +Z'de aşağıda, -Z'de yukarıda (merdivenle birebir uyumlu)
	var rail_mid_y = 2.175
	var rail_mid_z = 0.615
	
	for side_x in [-0.48, 0.48]:
		# 1. Zemin Mermer Süpürgelik (Flank Base Plinth along floor)
		var base_plinth = MeshInstance3D.new()
		var mb_flank_base_m = BoxMesh.new()
		mb_flank_base_m.size = Vector3(0.08, 0.20, 3.05)
		base_plinth.mesh = mb_flank_base_m
		base_plinth.position = Vector3(side_x, 0.10, 0.55)
		base_plinth.set_surface_override_material(0, mb_marble)
		mb_flanks_body.add_child(base_plinth)
		
		# 2. Merdiven Altı Masif Ahşap Aynalık Panelleri (Zeminden basamağa kadar kesintisiz kapalı)
		for s in range(num_steps):
			var step_top_y = (s + 1) * step_rise
			var step_center_z = step_start_z - (s * step_depth) - (step_depth * 0.5)
			var wall_h = step_top_y
			
			var flank_wall = MeshInstance3D.new()
			var mb_flank_wall_m = BoxMesh.new()
			mb_flank_wall_m.size = Vector3(0.06, wall_h, step_depth * 1.02)
			flank_wall.mesh = mb_flank_wall_m
			flank_wall.position = Vector3(side_x, wall_h * 0.5, step_center_z)
			flank_wall.set_surface_override_material(0, mb_wood)
			mb_flanks_body.add_child(flank_wall)
			
		# 3. Merdiven Üstü Eğimli Ahşap Küpeşte & Şebeke Korkuluk Grubu (Rotated Group)
		var rail_group = Node3D.new()
		rail_group.position = Vector3(side_x, rail_mid_y, rail_mid_z)
		rail_group.rotation.x = rail_rot_x
		
		# Ahşap Küpeşte
		var rail_mesh = MeshInstance3D.new()
		var mb_rail_m = BoxMesh.new()
		mb_rail_m.size = Vector3(0.10, 0.08, rail_len)
		rail_mesh.mesh = mb_rail_m
		rail_mesh.set_surface_override_material(0, mb_wood)
		rail_group.add_child(rail_mesh)
		
		# Küpeşte Altın Şerit Çıtası
		var rail_gold = MeshInstance3D.new()
		var mb_rail_gold_m = BoxMesh.new()
		mb_rail_gold_m.size = Vector3(0.06, 0.02, rail_len)
		rail_gold.mesh = mb_rail_gold_m
		rail_gold.position = Vector3(0, -0.04, 0)
		rail_gold.set_surface_override_material(0, mb_gold)
		rail_group.add_child(rail_gold)
		
		# 4. Küpeşte Altı Ajurlu Geometrik Şebeke Korkuluk Paneli
		var balustrade_mesh = MeshInstance3D.new()
		var mb_balustrade_m = BoxMesh.new()
		mb_balustrade_m.size = Vector3(0.04, 0.56, rail_len - 0.10)
		balustrade_mesh.mesh = mb_balustrade_m
		balustrade_mesh.position = Vector3(0, -0.32, 0)
		balustrade_mesh.set_surface_override_material(0, mb_lattice)
		rail_group.add_child(balustrade_mesh)
		
		# Oyuncunun Yan Korkuluktan Düşmesini Önleyen Masif Çarpışma Bloğu
		var flank_col = CollisionShape3D.new()
		var mb_flank_shape = BoxShape3D.new()
		mb_flank_shape.size = Vector3(0.12, 1.40, rail_len)
		flank_col.shape = mb_flank_shape
		flank_col.position = Vector3(0, -0.20, 0)
		rail_group.add_child(flank_col)
		
		mb_flanks_body.add_child(rail_group)
		
		# 5. Korkuluk Bağlantı Pirinç Bilezikleri (Taç kapı ve köşk sütununa tam kenetlenir)
		for anchor_pt in [Vector3(side_x, 1.07, 2.25), Vector3(side_x, 3.28, -1.02)]:
			var anchor_boss = MeshInstance3D.new()
			var mb_anchor_boss_m = BoxMesh.new()
			mb_anchor_boss_m.size = Vector3(0.12, 0.12, 0.12)
			anchor_boss.mesh = mb_anchor_boss_m
			anchor_boss.position = anchor_pt
			anchor_boss.set_surface_override_material(0, mb_gold)
			mb_flanks_body.add_child(anchor_boss)
	minber.add_child(mb_flanks_body)

	# ================= D. KÖŞK ALTI ANITSAL KAİDE VE GÖVDE (ASLA HAVADA UÇMAZ!) =================
	# İmamın çıktığı yerin altındaki devasa mermer/ahşap taşıyıcı kaide.
	# Zemin seviyesinden (y = 0.0) sahanlık zeminine (y = 2.45) kadar tamamen dolgulu,
	# sağ ve sol kör kemerli nişler, köşe mermer pilastırları ve mukarnaslı konsollar içerir.
	var mb_pedestal_body = StaticBody3D.new()
	mb_pedestal_body.name = "MinberKaidesi"
	
	var ped_z_center = -1.625
	var ped_depth = 1.35
	var ped_width = 1.22
	
	# 1. Zemin Mermer Pabucu (Base Plinth on carpet)
	var ped_base = MeshInstance3D.new()
	var mb_ped_base_m = BoxMesh.new()
	mb_ped_base_m.size = Vector3(ped_width + 0.04, 0.22, ped_depth + 0.04)
	ped_base.mesh = mb_ped_base_m
	ped_base.position = Vector3(0, 0.11, ped_z_center)
	ped_base.set_surface_override_material(0, mb_marble)
	mb_pedestal_body.add_child(ped_base)
	
	var ped_torus = MeshInstance3D.new()
	var mb_ped_torus_m = BoxMesh.new()
	mb_ped_torus_m.size = Vector3(ped_width + 0.02, 0.06, ped_depth + 0.02)
	ped_torus.mesh = mb_ped_torus_m
	ped_torus.position = Vector3(0, 0.24, ped_z_center)
	ped_torus.set_surface_override_material(0, mb_gold)
	mb_pedestal_body.add_child(ped_torus)
	
	# 2. Masif İç Taşıyıcı Gövde (Solid Core - İçi Asla Boş Görünmez)
	var ped_core = MeshInstance3D.new()
	var mb_ped_core_m = BoxMesh.new()
	mb_ped_core_m.size = Vector3(ped_width - 0.04, 2.18, ped_depth - 0.04)
	ped_core.mesh = mb_ped_core_m
	ped_core.position = Vector3(0, 1.36, ped_z_center)
	ped_core.set_surface_override_material(0, mb_wood)
	mb_pedestal_body.add_child(ped_core)
	
	# 3. Arka Mermer Duvar (Back Wall at z = -2.26)
	var back_wall = MeshInstance3D.new()
	var mb_back_wall_m = BoxMesh.new()
	mb_back_wall_m.size = Vector3(ped_width, 2.22, 0.10)
	back_wall.mesh = mb_back_wall_m
	back_wall.position = Vector3(0, 1.36, -2.26)
	back_wall.set_surface_override_material(0, mb_marble)
	mb_pedestal_body.add_child(back_wall)
	
	# 4. Sol ve Sağ Dış Cephelerde Klasik Osmanlı Kör Kemerli Nişler (Side Niche Arches)
	for side_px in [-0.56, 0.56]:
		# Yan Dış Mermer Duvar
		var side_wall = MeshInstance3D.new()
		var mb_side_wall_m = BoxMesh.new()
		mb_side_wall_m.size = Vector3(0.08, 2.22, ped_depth)
		side_wall.mesh = mb_side_wall_m
		side_wall.position = Vector3(side_px, 1.36, ped_z_center)
		side_wall.set_surface_override_material(0, mb_marble)
		mb_pedestal_body.add_child(side_wall)
		
		# Oymalı Kündekâri Kemer Nişi Dolgusu
		var niche_panel = MeshInstance3D.new()
		var mb_niche_panel_m = BoxMesh.new()
		mb_niche_panel_m.size = Vector3(0.04, 1.65, 0.92)
		niche_panel.mesh = mb_niche_panel_m
		niche_panel.position = Vector3(side_px * 1.03, 1.25, ped_z_center)
		niche_panel.set_surface_override_material(0, mb_lattice)
		mb_pedestal_body.add_child(niche_panel)
		
		# Kemer Varak Altın Çerçevesi
		var arch_frame = MeshInstance3D.new()
		var mb_arch_frame_m = BoxMesh.new()
		mb_arch_frame_m.size = Vector3(0.05, 0.08, 0.96)
		arch_frame.mesh = mb_arch_frame_m
		arch_frame.position = Vector3(side_px * 1.04, 2.10, ped_z_center)
		arch_frame.set_surface_override_material(0, mb_gold)
		mb_pedestal_body.add_child(arch_frame)

	# 5. Kaidenin 4 Köşesindeki Taşıyıcı Mermer Pilastırlar & Mukarnaslı Konsollar
	for cx in [-0.56, 0.56]:
		for cz in [-0.98, -2.26]:
			var pilaster = MeshInstance3D.new()
			var mb_pilaster_m = BoxMesh.new()
			mb_pilaster_m.size = Vector3(0.14, 2.25, 0.14)
			pilaster.mesh = mb_pilaster_m
			pilaster.position = Vector3(cx, 1.36, cz)
			pilaster.set_surface_override_material(0, mb_marble)
			mb_pedestal_body.add_child(pilaster)
			
			# Üst Konsol (Mukarnas Çıkması - Köşk döşemesini heybetle taşır)
			var corbel = MeshInstance3D.new()
			var mb_corbel_m = PrismMesh.new()
			mb_corbel_m.size = Vector3(0.18, 0.22, 0.18)
			corbel.mesh = mb_corbel_m
			corbel.position = Vector3(cx, 2.40, cz)
			corbel.rotation.x = PI
			corbel.set_surface_override_material(0, mb_gold)
			mb_pedestal_body.add_child(corbel)
			
	# Kaide Tam Çarpışma Bloğu (Physical Solid Barrier)
	var ped_col = CollisionShape3D.new()
	var mb_ped_shape = BoxShape3D.new()
	mb_ped_shape.size = Vector3(ped_width, 2.45, ped_depth)
	ped_col.shape = mb_ped_shape
	ped_col.position = Vector3(0, 1.225, ped_z_center)
	mb_pedestal_body.add_child(ped_col)
	minber.add_child(mb_pedestal_body)

	# ================= E. ÜST HUTBE KÖŞKÜ (İMAMIN ÇIKTIĞI MAKÂM-I ÂLÎ) =================
	# Platform, 4 Mermer Sütun, 4 Sivri Kemer, Oymalı Rahle, Mushaf, Saçak ve Kurşun Külah
	var mb_pulpit_body = StaticBody3D.new()
	mb_pulpit_body.name = "MinberKosku"
	
	# 1. Sahanlık Döşemesi (Walk-in Platform Floor - Merdivenin bittiği y = 2.40 ile tam hizalı)
	var pulpit_floor_mesh = MeshInstance3D.new()
	var mb_pulpit_floor_m = BoxMesh.new()
	mb_pulpit_floor_m.size = Vector3(1.22, 0.16, 1.38)
	pulpit_floor_mesh.mesh = mb_pulpit_floor_m
	pulpit_floor_mesh.position = Vector3(0, 2.48, ped_z_center)
	pulpit_floor_mesh.set_surface_override_material(0, mb_marble)
	mb_pulpit_body.add_child(pulpit_floor_mesh)
	
	# İmamın Bastığı Zümrüt Yeşili İpek Namazlık Çuhası
	var imam_pad = MeshInstance3D.new()
	var mb_imam_pad_m = BoxMesh.new()
	mb_imam_pad_m.size = Vector3(0.85, 0.02, 1.05)
	imam_pad.mesh = mb_imam_pad_m
	imam_pad.position = Vector3(0, 2.57, ped_z_center)
	imam_pad.set_surface_override_material(0, mb_velvet)
	mb_pulpit_body.add_child(imam_pad)
	
	var pulpit_floor_col = CollisionShape3D.new()
	var mb_pulpit_floor_shape = BoxShape3D.new()
	mb_pulpit_floor_shape.size = Vector3(1.22, 0.16, 1.38)
	pulpit_floor_col.shape = mb_pulpit_floor_shape
	pulpit_floor_col.position = Vector3(0, 2.48, ped_z_center)
	mb_pulpit_body.add_child(pulpit_floor_col)

	# 2. 4 Adet Kusursuz Mermer Sütun & Baklavalı Başlıklar
	for cx in [-0.48, 0.48]:
		for cz in [-1.02, -2.22]:
			# Sütun Mermer Kaidesi
			var col_base = MeshInstance3D.new()
			var mb_col_base_m = BoxMesh.new()
			mb_col_base_m.size = Vector3(0.16, 0.08, 0.16)
			col_base.mesh = mb_col_base_m
			col_base.position = Vector3(cx, 2.60, cz)
			col_base.set_surface_override_material(0, mb_marble)
			mb_pulpit_body.add_child(col_base)
			
			# Sütun Gövdesi
			var col_mesh = MeshInstance3D.new()
			var mb_col_shaft_m = CylinderMesh.new()
			mb_col_shaft_m.top_radius = 0.060
			mb_col_shaft_m.bottom_radius = 0.065
			mb_col_shaft_m.height = 1.82
			col_mesh.mesh = mb_col_shaft_m
			col_mesh.position = Vector3(cx, 3.55, cz)
			col_mesh.set_surface_override_material(0, mb_marble)
			mb_pulpit_body.add_child(col_mesh)
			
			# Altın Bilezik & Baklavalı Mermer Başlık
			var col_ring = MeshInstance3D.new()
			var mb_col_ring_m = BoxMesh.new()
			mb_col_ring_m.size = Vector3(0.16, 0.04, 0.16)
			col_ring.mesh = mb_col_ring_m
			col_ring.position = Vector3(cx, 4.42, cz)
			col_ring.set_surface_override_material(0, mb_gold)
			mb_pulpit_body.add_child(col_ring)
			
			var col_cap = MeshInstance3D.new()
			var mb_col_cap_m = BoxMesh.new()
			mb_col_cap_m.size = Vector3(0.18, 0.12, 0.18)
			col_cap.mesh = mb_col_cap_m
			col_cap.position = Vector3(cx, 4.50, cz)
			col_cap.set_surface_override_material(0, mb_marble)
			mb_pulpit_body.add_child(col_cap)
			
			var col_c = CollisionShape3D.new()
			var mb_col_shape = CylinderShape3D.new()
			mb_col_shape.radius = 0.075
			mb_col_shape.height = 1.95
			col_c.shape = mb_col_shape
			col_c.position = Vector3(cx, 3.55, cz)
			mb_pulpit_body.add_child(col_c)

	# 3. Sütunları Üstten Bağlayan Mermer Kemerler (Pointed Arch Lintels)
	# Ön Kemer (Merdivenden girişte baş üstü açıklığı)
	var front_arch = MeshInstance3D.new()
	var mb_front_arch_m = BoxMesh.new()
	mb_front_arch_m.size = Vector3(0.96, 0.14, 0.10)
	front_arch.mesh = mb_front_arch_m
	front_arch.position = Vector3(0, 4.56, -1.02)
	front_arch.set_surface_override_material(0, mb_marble)
	mb_pulpit_body.add_child(front_arch)
	
	# Arka Kemer
	var back_arch = MeshInstance3D.new()
	back_arch.mesh = mb_front_arch_m
	back_arch.position = Vector3(0, 4.56, -2.22)
	back_arch.set_surface_override_material(0, mb_marble)
	mb_pulpit_body.add_child(back_arch)
	
	# Yan Kemerler (Sol & Sağ)
	for arch_x in [-0.48, 0.48]:
		var side_arch = MeshInstance3D.new()
		var mb_side_arch_m = BoxMesh.new()
		mb_side_arch_m.size = Vector3(0.10, 0.14, 1.20)
		side_arch.mesh = mb_side_arch_m
		side_arch.position = Vector3(arch_x, 4.56, ped_z_center)
		side_arch.set_surface_override_material(0, mb_marble)
		mb_pulpit_body.add_child(side_arch)

	# 4. Köşk Yan ve Arka Korkulukları (Sol, Sağ, Arka - Önü İmamın girişi için AÇIKTIR)
	for side_w in [-0.49, 0.49]:
		# Kündekâri Şebeke Panel
		var side_bar = MeshInstance3D.new()
		var mb_side_bar_m = BoxMesh.new()
		mb_side_bar_m.size = Vector3(0.04, 0.76, 1.15)
		side_bar.mesh = mb_side_bar_m
		side_bar.position = Vector3(side_w, 2.98, ped_z_center)
		side_bar.set_surface_override_material(0, mb_lattice)
		mb_pulpit_body.add_child(side_bar)
		
		# Üst Oymalı Küpeşte ve Altın Fitil
		var side_rail = MeshInstance3D.new()
		var mb_side_rail_m = BoxMesh.new()
		mb_side_rail_m.size = Vector3(0.08, 0.06, 1.18)
		side_rail.mesh = mb_side_rail_m
		side_rail.position = Vector3(side_w, 3.36, ped_z_center)
		side_rail.set_surface_override_material(0, mb_wood)
		mb_pulpit_body.add_child(side_rail)
		
		var side_rail_gold = MeshInstance3D.new()
		var mb_side_rail_gold_m = BoxMesh.new()
		mb_side_rail_gold_m.size = Vector3(0.06, 0.02, 1.18)
		side_rail_gold.mesh = mb_side_rail_gold_m
		side_rail_gold.position = Vector3(side_w, 3.33, ped_z_center)
		side_rail_gold.set_surface_override_material(0, mb_gold)
		mb_pulpit_body.add_child(side_rail_gold)
		
		var side_col = CollisionShape3D.new()
		var mb_side_col_shape = BoxShape3D.new()
		mb_side_col_shape.size = Vector3(0.08, 0.85, 1.18)
		side_col.shape = mb_side_col_shape
		side_col.position = Vector3(side_w, 2.98, ped_z_center)
		mb_pulpit_body.add_child(side_col)

	# Arka Korkuluk
	var back_bar = MeshInstance3D.new()
	var mb_back_bar_m = BoxMesh.new()
	mb_back_bar_m.size = Vector3(0.92, 0.76, 0.04)
	back_bar.mesh = mb_back_bar_m
	back_bar.position = Vector3(0, 2.98, -2.23)
	back_bar.set_surface_override_material(0, mb_lattice)
	mb_pulpit_body.add_child(back_bar)
	
	var back_rail = MeshInstance3D.new()
	var mb_back_rail_m = BoxMesh.new()
	mb_back_rail_m.size = Vector3(0.96, 0.06, 0.08)
	back_rail.mesh = mb_back_rail_m
	back_rail.position = Vector3(0, 3.36, -2.23)
	back_rail.set_surface_override_material(0, mb_wood)
	mb_pulpit_body.add_child(back_rail)
	
	var back_col = CollisionShape3D.new()
	var mb_back_col_shape = BoxShape3D.new()
	mb_back_col_shape.size = Vector3(0.96, 0.85, 0.08)
	back_col.shape = mb_back_col_shape
	back_col.position = Vector3(0, 2.98, -2.23)
	mb_pulpit_body.add_child(back_col)

	# 5. Köşk İçi Oymalı Ahşap Rahle ve Açık Mushaf-ı Şerif
	var mb_rahle = Node3D.new()
	mb_rahle.name = "MinberRahlesi"
	mb_rahle.position = Vector3(0, 2.58, -1.95)
	
	# Rahle Ahşap Çapraz Ayakları
	for leg_rot in [-0.45, 0.45]:
		var leg = MeshInstance3D.new()
		var mb_rahle_leg_m = BoxMesh.new()
		mb_rahle_leg_m.size = Vector3(0.34, 0.46, 0.03)
		leg.mesh = mb_rahle_leg_m
		leg.position = Vector3(0, 0.22, 0)
		leg.rotation.x = leg_rot
		leg.set_surface_override_material(0, mb_wood)
		mb_rahle.add_child(leg)
		
	# Açık Mushaf-ı Şerif Sayfaları (Cemaate dönük açık Kur'an-ı Kerim)
	var book = MeshInstance3D.new()
	var mb_book_m = BoxMesh.new()
	mb_book_m.size = Vector3(0.30, 0.04, 0.24)
	book.mesh = mb_book_m
	book.position = Vector3(0, 0.42, 0)
	var book_mat = StandardMaterial3D.new()
	book_mat.albedo_color = Color(0.96, 0.94, 0.88)
	book.set_surface_override_material(0, book_mat)
	mb_rahle.add_child(book)
	
	var book_cover = MeshInstance3D.new()
	var mb_book_cover_m = BoxMesh.new()
	mb_book_cover_m.size = Vector3(0.32, 0.015, 0.26)
	book_cover.mesh = mb_book_cover_m
	book_cover.position = Vector3(0, 0.395, 0)
	var cover_mat = StandardMaterial3D.new()
	cover_mat.albedo_color = Color(0.10, 0.35, 0.18)
	book_cover.set_surface_override_material(0, cover_mat)
	mb_rahle.add_child(book_cover)
	mb_pulpit_body.add_child(mb_rahle)

	# 6. Köşk Üst Mukarnaslı Saçak ve Korniş (Stepped Eaves)
	var eave_lower = MeshInstance3D.new()
	var mb_eave_lower_m = BoxMesh.new()
	mb_eave_lower_m.size = Vector3(1.28, 0.10, 1.48)
	eave_lower.mesh = mb_eave_lower_m
	eave_lower.position = Vector3(0, 4.67, ped_z_center)
	eave_lower.set_surface_override_material(0, mb_marble)
	mb_pulpit_body.add_child(eave_lower)
	
	var eave_upper = MeshInstance3D.new()
	var mb_eave_upper_m = BoxMesh.new()
	mb_eave_upper_m.size = Vector3(1.42, 0.12, 1.62)
	eave_upper.mesh = mb_eave_upper_m
	eave_upper.position = Vector3(0, 4.77, ped_z_center)
	eave_upper.set_surface_override_material(0, mb_marble)
	mb_pulpit_body.add_child(eave_upper)
	
	var eave_dentil = MeshInstance3D.new()
	var mb_eave_dentil_m = BoxMesh.new()
	mb_eave_dentil_m.size = Vector3(1.44, 0.04, 1.64)
	eave_dentil.mesh = mb_eave_dentil_m
	eave_dentil.position = Vector3(0, 4.83, ped_z_center)
	eave_dentil.set_surface_override_material(0, mb_gold)
	mb_pulpit_body.add_child(eave_dentil)

	# 7. İhtişamlı Sivri Minber Külahı (Conical Lead Spire)
	var spire_mesh = MeshInstance3D.new()
	var mb_spire_m = CylinderMesh.new()
	mb_spire_m.top_radius = 0.02
	mb_spire_m.bottom_radius = 0.68
	mb_spire_m.height = 2.60
	spire_mesh.mesh = mb_spire_m
	spire_mesh.position = Vector3(0, 6.15, ped_z_center)
	spire_mesh.set_surface_override_material(0, mb_lead)
	mb_pulpit_body.add_child(spire_mesh)

	# 8. Varak Altın Hilâl ve Alem (Imperial Crescent Finial)
	var finial_pole = MeshInstance3D.new()
	var mb_finial_pole_m = CylinderMesh.new()
	mb_finial_pole_m.top_radius = 0.02
	mb_finial_pole_m.bottom_radius = 0.02
	mb_finial_pole_m.height = 0.75
	finial_pole.mesh = mb_finial_pole_m
	finial_pole.position = Vector3(0, 7.70, ped_z_center)
	finial_pole.set_surface_override_material(0, mb_gold)
	mb_pulpit_body.add_child(finial_pole)

	# Alem Küreleri
	for sphere_y in [7.55, 7.75, 7.95]:
		var sphere_inst = MeshInstance3D.new()
		var mb_sphere_m = SphereMesh.new()
		mb_sphere_m.radius = 0.045
		mb_sphere_m.height = 0.09
		sphere_inst.mesh = mb_sphere_m
		sphere_inst.position = Vector3(0, sphere_y, ped_z_center)
		sphere_inst.set_surface_override_material(0, mb_gold)
		mb_pulpit_body.add_child(sphere_inst)

	# Altın Hilâl
	var alem_mesh = MeshInstance3D.new()
	var mb_alem_m = TorusMesh.new()
	mb_alem_m.inner_radius = 0.08
	mb_alem_m.outer_radius = 0.18
	alem_mesh.mesh = mb_alem_m
	alem_mesh.position = Vector3(0, 8.20, ped_z_center)
	alem_mesh.rotation.x = PI / 2.0
	alem_mesh.set_surface_override_material(0, mb_gold)
	mb_pulpit_body.add_child(alem_mesh)

	# Köşk İçi Sıcak İlahi Kandil Işığı
	var mb_light = OmniLight3D.new()
	mb_light.light_color = Color(1.0, 0.88, 0.65)
	mb_light.light_energy = 1.2
	mb_light.omni_range = 4.5
	mb_light.position = Vector3(0, 3.80, ped_z_center)
	mb_pulpit_body.add_child(mb_light)

	minber.add_child(mb_pulpit_body)
	mosque.add_child(minber)

	# ================= 9. İÇ MEKAN: HAKİKİ OSMANLI MÜEZZİN MAHFİLİ =================
	# Referans fotoğraflardaki gibi: Merdivensiz, zemin seviyesinde oymalı ahşap platform,
	# kündekâri şebeke kafesli korkuluklar, pirinç mikrofon, rahle ve topuzlu köşe babaları
	_build_muezzin_mahfili(mosque)

	# ================= 10. İÇ MEKAN: DEV KANDİL AVİZESİ & IŞIKLANDIRMA =================
	# Kubbeden Sarkan Devasa Pirinç Kandil Halkaları (x = 0, z = 0, y = 4.2)
	var chandelier = Node3D.new()
	chandelier.name = "Chandelier"
	chandelier.position = Vector3(0, 4.2, 0)
	
	var ring_outer = MeshInstance3D.new()
	var ro_mesh = TorusMesh.new()
	ro_mesh.inner_radius = 4.2
	ro_mesh.outer_radius = 4.5
	ring_outer.mesh = ro_mesh
	ring_outer.set_surface_override_material(0, gold_mat)
	chandelier.add_child(ring_outer)
	
	var ring_inner = MeshInstance3D.new()
	var ri_mesh = TorusMesh.new()
	ri_mesh.inner_radius = 2.2
	ri_mesh.outer_radius = 2.45
	ring_inner.mesh = ri_mesh
	ring_inner.set_surface_override_material(0, gold_mat)
	chandelier.add_child(ring_inner)
	
	# Taşıyıcı Zincirler
	for a in range(4):
		var chain = MeshInstance3D.new()
		var ch_cyl = CylinderMesh.new()
		ch_cyl.top_radius = 0.03
		ch_cyl.bottom_radius = 0.03
		ch_cyl.height = 7.5
		chain.mesh = ch_cyl
		var rad = float(a) * (PI * 0.5)
		chain.position = Vector3(cos(rad) * 3.0, 3.8, sin(rad) * 3.0)
		chain.set_surface_override_material(0, gold_mat)
		chandelier.add_child(chain)
		
	# Sıcak Altın Kandil Işığı
	var mosque_light = OmniLight3D.new()
	mosque_light.light_color = Color(1.0, 0.88, 0.65)
	mosque_light.light_energy = 2.4
	mosque_light.omni_range = 18.0
	mosque_light.shadow_enabled = true
	mosque_light.position.y = 0.2
	chandelier.add_child(mosque_light)
	mosque.add_child(chandelier)

	# ================= 11. DUVAR HAT LEVHALARI (HULEFA-İ RAŞİDİN) =================
	# Ayasofya & Sultanahmet tarzı anıtsal Hulefâ-i Râşidîn ve Lafzullâh/Muhammedî hat levhaları
	var calligraphy_names = [
		{"text": "اللَّه", "pos": Vector3(-4.8, 7.6, -12.1)},
		{"text": "مُحَمَّد", "pos": Vector3(4.8, 7.6, -12.1)},
		{"text": "أَبُو بَكْر", "pos": Vector3(-10.1, 7.6, -4.5), "rot": PI * 0.5},
		{"text": "عُمَر", "pos": Vector3(-10.1, 7.6, 4.5), "rot": PI * 0.5},
		{"text": "عُثْمَان", "pos": Vector3(10.1, 7.6, -4.5), "rot": -PI * 0.5},
		{"text": "عَلِيّ", "pos": Vector3(10.1, 7.6, 4.5), "rot": -PI * 0.5}
	]
	
	for c in calligraphy_names:
		# 1. Ana Ahşap / Nefti Lake Levha Kaidesi (4.1 Metre Genişliğinde İhtişamlı Madalyon)
		var plate = MeshInstance3D.new()
		var p_cyl = CylinderMesh.new()
		p_cyl.top_radius = 2.05
		p_cyl.bottom_radius = 2.05
		p_cyl.height = 0.14
		plate.mesh = p_cyl
		plate.position = c["pos"]
		plate.rotation.x = PI * 0.5
		if c.has("rot"):
			plate.rotation.y = c["rot"]
		var plate_mat = StandardMaterial3D.new()
		plate_mat.albedo_color = Color(0.06, 0.10, 0.07) # Nefti yeşil Osmanlı cila lake
		plate_mat.roughness = 0.35
		plate.set_surface_override_material(0, plate_mat)
		mosque.add_child(plate)
		
		# 2. Altın Varak İşlemeli Dış Pervaz Çerçevesi (Gold Rim)
		var rim = MeshInstance3D.new()
		var rm = TorusMesh.new()
		rm.inner_radius = 1.95
		rm.outer_radius = 2.12
		rim.mesh = rm
		rim.position = c["pos"]
		rim.rotation.x = PI * 0.5
		if c.has("rot"):
			rim.rotation.y = c["rot"]
		rim.set_surface_override_material(0, gold_mat)
		mosque.add_child(rim)
		
		# 3. İri, Okunaklı ve Altın Yaldızlı Hat Yazısı (Görkemli ve Net)
		var clabel = Label3D.new()
		clabel.text = c["text"]
		clabel.font_size = 120
		clabel.pixel_size = 0.006
		clabel.modulate = Color(1.0, 0.92, 0.35)
		clabel.outline_size = 18
		clabel.outline_modulate = Color(0.02, 0.02, 0.02)
		clabel.position = c["pos"] + Vector3(0, 0, 0.16).rotated(Vector3.UP, c.get("rot", 0.0))
		if c.has("rot"):
			clabel.rotation.y = c["rot"]
		mosque.add_child(clabel)

	# ================= 12. NAMAZ ALANI TETİKLEYİCİSİ (PRAYER AREA3D) =================
	var prayer_area = Area3D.new()
	prayer_area.name = "MosquePrayerArea"
	prayer_area.add_to_group("prayer_area")
	prayer_area.add_to_group("interactables")
	var pacol = CollisionShape3D.new()
	var pabox = BoxShape3D.new()
	pabox.size = Vector3(19.0, 4.5, 22.0)
	pacol.shape = pabox
	pacol.position = Vector3(0, 2.25, 0.5)
	prayer_area.add_child(pacol)
	mosque.add_child(prayer_area)

	add_child(mosque)

func _build_muezzin_mahfili(mosque: Node3D) -> void:
	# ================= HAKİKİ OSMANLI MÜEZZİN MAHFİLİ =================
	# Referans fotoğraftaki gibi: Yerden 45cm yükseltilmiş masif ahşap suffa podyumu,
	# alt kısmı boydan boya oymalı masif ahşap panellerle kaplı, kündekâri şebeke kafesli korkuluklar,
	# heybetli topuzlu köşe babaları, basamaklı rahat giriş, rahle & Mushaf, mikrofon ve tesbih.
	var mahfil = StaticBody3D.new()
	mahfil.name = "MuezzinMahfili"
	# Caminin halı seviyesi y = 0.60
	mahfil.position = Vector3(-6.5, 0.60, 3.0)
	
	# 1. Malzemeler (Ceviz Ahşap, Kündekâri Oymalı Şebeke Kafes & Kabartma Baza)
	var wood_mat = StandardMaterial3D.new()
	if tex_mahfil_wood:
		wood_mat.albedo_texture = tex_mahfil_wood
		wood_mat.uv1_scale = Vector3(1.5, 1.5, 1.5)
	else:
		wood_mat.albedo_color = Color(0.44, 0.24, 0.13)
	wood_mat.roughness = 0.45
	
	var lattice_mat = StandardMaterial3D.new()
	if tex_mahfil_lattice:
		lattice_mat.albedo_texture = tex_mahfil_lattice
		lattice_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		lattice_mat.alpha_scissor_threshold = 0.45
		lattice_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		lattice_mat.uv1_scale = Vector3(1.0, 1.0, 1.0)
	else:
		lattice_mat.albedo_color = Color(0.48, 0.28, 0.16)
	lattice_mat.roughness = 0.55
	
	var frieze_mat = StandardMaterial3D.new()
	if tex_mahfil_base_frieze:
		frieze_mat.albedo_texture = tex_mahfil_base_frieze
		frieze_mat.uv1_scale = Vector3(6.0, 1.0, 1.0)
	else:
		frieze_mat.albedo_color = Color(0.42, 0.22, 0.12)
	frieze_mat.roughness = 0.50
	
	var carpet_mat = StandardMaterial3D.new()
	if tex_carpet_yesil:
		carpet_mat.albedo_texture = tex_carpet_yesil
		carpet_mat.uv1_scale = Vector3(2.0, 2.0, 1.0)
	elif mosque_carpet_mat and mosque_carpet_mat.albedo_texture:
		carpet_mat.albedo_texture = mosque_carpet_mat.albedo_texture
		carpet_mat.uv1_scale = Vector3(2.0, 2.0, 1.0)
	else:
		carpet_mat.albedo_color = Color(0.08, 0.50, 0.26)
	carpet_mat.roughness = 0.85
	
	var brass_mat = StandardMaterial3D.new()
	brass_mat.albedo_color = Color(0.85, 0.72, 0.32)
	brass_mat.metallic = 0.90
	brass_mat.roughness = 0.25

	# 2. Yükseltilmiş Podyum Boyutları (3.2m x 3.2m, Yerden 45cm Yüksekte Masif Kaide)
	var half_w = 1.6
	var half_d = 1.6
	var plat_h = 0.45          # Platform zemin yüksekliği (45cm)
	var solid_under_h = 0.72   # Yerden kafesin başladığı hizaya kadar olan masif ahşap kaplama
	var lattice_h = 0.58       # Kündekâri kafes yüksekliği
	var rail_top_h = 1.38      # Üst küpeşte zirve yüksekliği
	var post_h = 1.50          # Baba sütun gövde yüksekliği
	
	# Podyum Ana Çarpışma Kutusu (Karakterin üzerinde duracağı 45cm yüksekliğindeki iç zemin)
	var plat_col = CollisionShape3D.new()
	var pc_box = BoxShape3D.new()
	pc_box.size = Vector3(3.10, plat_h, 3.10)
	plat_col.shape = pc_box
	plat_col.position.y = plat_h * 0.5
	mahfil.add_child(plat_col)
	
	# Podyum İçi Masif Ahşap Zemin
	var inner_floor = MeshInstance3D.new()
	var if_box = BoxMesh.new()
	if_box.size = Vector3(3.08, 0.04, 3.08)
	inner_floor.mesh = if_box
	inner_floor.position.y = plat_h - 0.02
	inner_floor.set_surface_override_material(0, wood_mat)
	mahfil.add_child(inner_floor)
	
	# Mahfil İçi Halı Kaplaması
	var inner_carpet = MeshInstance3D.new()
	var ic_box = BoxMesh.new()
	ic_box.size = Vector3(2.96, 0.02, 2.96)
	inner_carpet.mesh = ic_box
	inner_carpet.position.y = plat_h + 0.005
	inner_carpet.set_surface_override_material(0, carpet_mat)
	mahfil.add_child(inner_carpet)
	
	# Giriş Basamağı (Doğu Cephesinde X = 1.60 hizasında Z = -0.48 ile +0.48 arası)
	# Karakterin 45cm yüksekliğe pürüzsüzce adım atması için basamak
	var step_mesh = MeshInstance3D.new()
	var sm_box = BoxMesh.new()
	sm_box.size = Vector3(0.35, plat_h * 0.5, 0.96)
	step_mesh.mesh = sm_box
	step_mesh.position = Vector3(half_w + 0.12, plat_h * 0.25, 0)
	step_mesh.set_surface_override_material(0, wood_mat)
	mahfil.add_child(step_mesh)
	
	var step_col = CollisionShape3D.new()
	var sc_box = BoxShape3D.new()
	sc_box.size = Vector3(0.35, plat_h * 0.5, 0.96)
	step_col.shape = sc_box
	step_col.position = Vector3(half_w + 0.12, plat_h * 0.25, 0)
	mahfil.add_child(step_col)

	# Pürüzsüz yürüyüş için görünmez rampa çarpışması (Player controller takılmadan yukarı çıkar)
	var ramp_col = CollisionShape3D.new()
	var rc_box = BoxShape3D.new()
	rc_box.size = Vector3(0.55, 0.10, 0.96)
	ramp_col.shape = rc_box
	ramp_col.position = Vector3(half_w, plat_h * 0.5, 0)
	ramp_col.rotation.z = -0.55
	mahfil.add_child(ramp_col)

	# 3. Topuzlu Babalar (Köşe ve Kapı Dikmeleri)
	# 4 Köşe Babası + Doğu Giriş Kapısını Sınırlayan 2 Kapı Babası (Toplam 6 Adet)
	var post_positions = [
		Vector3(-half_w, 0, -half_d),
		Vector3(-half_w, 0, half_d),
		Vector3(half_w, 0, -half_d),
		Vector3(half_w, 0, half_d),
		Vector3(half_w, 0, -0.52), # Giriş sol babası
		Vector3(half_w, 0, 0.52)   # Giriş sağ babası
	]
	
	for ppos in post_positions:
		var p_root = Node3D.new()
		p_root.position = ppos
		
		# Dikme Sütun Gövdesi (0.20m x 0.20m, Yerden 1.50m Yükseğe)
		var post_col = CollisionShape3D.new()
		var pcs = BoxShape3D.new()
		pcs.size = Vector3(0.22, post_h, 0.22)
		post_col.shape = pcs
		post_col.position = Vector3(ppos.x, post_h * 0.5, ppos.z)
		mahfil.add_child(post_col)
		
		var post_mesh = MeshInstance3D.new()
		var pm_box = BoxMesh.new()
		pm_box.size = Vector3(0.20, post_h, 0.20)
		post_mesh.mesh = pm_box
		post_mesh.position.y = post_h * 0.5
		post_mesh.set_surface_override_material(0, wood_mat)
		p_root.add_child(post_mesh)
		
		# Baza Etek Çerçevesi (Baba eteğinde pahlı bilezik)
		var pbase_mesh = MeshInstance3D.new()
		var pbm_box = BoxMesh.new()
		pbm_box.size = Vector3(0.24, 0.12, 0.24)
		pbase_mesh.mesh = pbm_box
		pbase_mesh.position.y = 0.06
		pbase_mesh.set_surface_override_material(0, wood_mat)
		p_root.add_child(pbase_mesh)
		
		# Sütun Başlık Tablası
		var cap_mesh = MeshInstance3D.new()
		var cm_box = BoxMesh.new()
		cm_box.size = Vector3(0.25, 0.05, 0.25)
		cap_mesh.mesh = cm_box
		cap_mesh.position.y = post_h + 0.025
		cap_mesh.set_surface_override_material(0, wood_mat)
		p_root.add_child(cap_mesh)
		
		# Boyun Bileziği
		var neck_mesh = MeshInstance3D.new()
		var nm_cyl = CylinderMesh.new()
		nm_cyl.top_radius = 0.05
		nm_cyl.bottom_radius = 0.065
		nm_cyl.height = 0.04
		neck_mesh.mesh = nm_cyl
		neck_mesh.position.y = post_h + 0.07
		neck_mesh.set_surface_override_material(0, wood_mat)
		p_root.add_child(neck_mesh)
		
		# Ahşap Küre Topuz (Finial Sphere)
		var finial_ball = MeshInstance3D.new()
		var f_sph = SphereMesh.new()
		f_sph.radius = 0.09
		f_sph.height = 0.18
		finial_ball.mesh = f_sph
		finial_ball.position.y = post_h + 0.18
		finial_ball.set_surface_override_material(0, wood_mat)
		p_root.add_child(finial_ball)
		
		# Topuz Sivri Alem Ucu
		var tip_mesh = MeshInstance3D.new()
		var tm_cyl = CylinderMesh.new()
		tm_cyl.top_radius = 0.015
		tm_cyl.bottom_radius = 0.04
		tm_cyl.height = 0.05
		tip_mesh.mesh = tm_cyl
		tip_mesh.position.y = post_h + 0.29
		tip_mesh.set_surface_override_material(0, wood_mat)
		p_root.add_child(tip_mesh)
		
		mahfil.add_child(p_root)

	# 4. Korkuluk Panelleri & Alt Masif Ahşap Kaplama ("Altında Resimdeki Gibi Kaplayacak")
	# Her bir kenar:
	# 1. En altta baklava dilimi oymalı baza bordürü (0 - 12cm)
	# 2. Orta-alt masif ceviz ayna paneli kaplaması (10cm - 72cm)
	# 3. Kordon/kuşak pervazı (70cm - 74cm)
	# 4. Kündekâri oymalı şebeke kafes (74cm - 132cm)
	# 5. Üst pahlı küpeşte (132cm - 140cm)
	var railing_specs = [
		# Batı Kenarı (Boydan boya 3.2m)
		{"center": Vector3(-half_w, 0, 0), "size_l": 3.00, "is_z_axis": true},
		# Kuzey Kenarı (Kıble yönü 3.2m)
		{"center": Vector3(0, 0, -half_d), "size_l": 3.00, "is_z_axis": false},
		# Güney Kenarı (Giriş yönü 3.2m)
		{"center": Vector3(0, 0, half_d), "size_l": 3.00, "is_z_axis": false},
		# Doğu Kenarı Sol Kanat (Kuzey köşesinden giriş kapısına, ~1.0m)
		{"center": Vector3(half_w, 0, -1.06), "size_l": 0.88, "is_z_axis": true},
		# Doğu Kenarı Sağ Kanat (Giriş kapısından Güney köşesine, ~1.0m)
		{"center": Vector3(half_w, 0, 1.06), "size_l": 0.88, "is_z_axis": true}
	]
	
	for spec in railing_specs:
		var r_node = Node3D.new()
		r_node.position = spec["center"]
		if spec["is_z_axis"]:
			r_node.rotation.y = PI * 0.5
			
		var r_len = spec["size_l"]
		
		# Korkuluk Tam Boy Çarpışma Kutusu (Yerden küpeşteye kadar)
		var r_col = CollisionShape3D.new()
		var r_box = BoxShape3D.new()
		r_box.size = Vector3(r_len, rail_top_h, 0.18)
		r_col.shape = r_box
		r_col.position.y = rail_top_h * 0.5
		r_node.add_child(r_col)
		
		# A. En Alt Oymalı Kabartma Baza Bordürü (Yerden 0 - 12cm)
		var frieze = MeshInstance3D.new()
		var fb = BoxMesh.new()
		fb.size = Vector3(r_len, 0.12, 0.14)
		frieze.mesh = fb
		frieze.position.y = 0.06
		frieze.set_surface_override_material(0, frieze_mat)
		r_node.add_child(frieze)
		
		# B. Alt Masif Ahşap Ayna Paneli Kaplaması (Yerden 10cm ile 72cm arası - TAM KAPLAMA)
		# Resim 3'teki gibi geniş masif ahşap etek paneli
		var apron = MeshInstance3D.new()
		var ap_box = BoxMesh.new()
		ap_box.size = Vector3(r_len, 0.62, 0.11)
		apron.mesh = ap_box
		apron.position.y = 0.41 # (0.10 + 0.72) / 2
		apron.set_surface_override_material(0, wood_mat)
		r_node.add_child(apron)
		
		# C. Orta Kuşak / Kordon Pervazı (Kafesi taşıyan ara pervaz)
		var belt = MeshInstance3D.new()
		var belt_box = BoxMesh.new()
		belt_box.size = Vector3(r_len, 0.05, 0.14)
		belt.mesh = belt_box
		belt.position.y = solid_under_h + 0.015
		belt.set_surface_override_material(0, wood_mat)
		r_node.add_child(belt)
		
		# D. Orta Kündekâri Şebeke Kafes (74cm ile 132cm arası - 58cm net yükseklik)
		var lattice = MeshInstance3D.new()
		var lat_box = BoxMesh.new()
		lat_box.size = Vector3(r_len, lattice_h, 0.03)
		lattice.mesh = lat_box
		lattice.position.y = solid_under_h + (lattice_h * 0.5) + 0.03
		lattice.set_surface_override_material(0, lattice_mat)
		r_node.add_child(lattice)
		
		# E. Üst Küpeşte / Korkuluk Pervazı (Profil Pahlı Masif El Tutamağı)
		var handrail = MeshInstance3D.new()
		var hr_box = BoxMesh.new()
		hr_box.size = Vector3(r_len, 0.08, 0.16)
		handrail.mesh = hr_box
		handrail.position.y = solid_under_h + lattice_h + 0.06
		handrail.set_surface_override_material(0, wood_mat)
		r_node.add_child(handrail)
		
		mahfil.add_child(r_node)

	# 5. Müezzin Oturma Minderi & Seccadesi (Yüzünü Kıbleye / Mihraba Döner)
	var minder = MeshInstance3D.new()
	var mb_box = BoxMesh.new()
	mb_box.size = Vector3(0.75, 0.05, 0.75)
	minder.mesh = mb_box
	minder.position = Vector3(-0.35, plat_h + 0.03, 0.22)
	var minder_mat = StandardMaterial3D.new()
	minder_mat.albedo_color = Color(0.10, 0.40, 0.20) # Zümrüt yeşili Osmanlı kadife minderi
	minder_mat.roughness = 0.85
	minder.set_surface_override_material(0, minder_mat)
	mahfil.add_child(minder)

	# 6. Mahfil İçi Eşyalar: Oymalı Ahşap Rahle ve Mushaf-ı Şerif (Platform üzerinde, KIBLEYE DÖNÜK)
	var rahle_root = Node3D.new()
	rahle_root.position = Vector3(-0.35, plat_h, -0.40)
	rahle_root.rotation.y = PI # 180 derece: Caminin ön tarafına / Kıbleye (-Z) bakar!
	rahle_root.rotation.x = -0.15 # Sayfalar kıbleye doğru yükselen okuma açısı
	
	# Çapraz Ahşap Kanatlar (X-Rahle Standı)
	for wing_sign in [-1.0, 1.0]:
		var wing = MeshInstance3D.new()
		var wb = BoxMesh.new()
		wb.size = Vector3(0.55, 0.028, 0.38)
		wing.mesh = wb
		wing.position = Vector3(wing_sign * 0.11, 0.28, 0)
		wing.rotation.z = wing_sign * 0.38
		wing.set_surface_override_material(0, wood_mat)
		rahle_root.add_child(wing)
		
	# Açık Mushaf-ı Şerif (Kur'an-ı Kerîm - Kıbleye Bakan Fildişi Sayfalar)
	var quran_page_mat = StandardMaterial3D.new()
	quran_page_mat.albedo_color = Color(0.97, 0.95, 0.89)
	quran_page_mat.roughness = 0.85
	
	for page_sign in [-1.0, 1.0]:
		var page_mesh = MeshInstance3D.new()
		var pb = BoxMesh.new()
		pb.size = Vector3(0.22, 0.022, 0.34)
		page_mesh.mesh = pb
		page_mesh.position = Vector3(page_sign * 0.10, 0.30, 0)
		page_mesh.rotation.z = page_sign * 0.38
		page_mesh.set_surface_override_material(0, quran_page_mat)
		rahle_root.add_child(page_mesh)
		
	# Kırmızı İpek Ayraç Kurdelesi
	var ribbon = MeshInstance3D.new()
	var rb = BoxMesh.new()
	rb.size = Vector3(0.025, 0.005, 0.30)
	ribbon.mesh = rb
	ribbon.position = Vector3(0, 0.32, 0.04)
	var rib_mat = StandardMaterial3D.new()
	rib_mat.albedo_color = Color(0.85, 0.12, 0.15)
	ribbon.set_surface_override_material(0, rib_mat)
	rahle_root.add_child(ribbon)
	
	mahfil.add_child(rahle_root)
	
	# 7. Müezzin Kürsü Mikrofonu & Sehpası (KIBLEYE / CAMİNİN ÖNÜNE YÖNLENDİRİLMİŞ)
	var mic_root = Node3D.new()
	mic_root.position = Vector3(-0.75, plat_h, -0.32)
	
	var mic_base = MeshInstance3D.new()
	var mb_cyl = CylinderMesh.new()
	mb_cyl.top_radius = 0.12
	mb_cyl.bottom_radius = 0.14
	mb_cyl.height = 0.03
	mic_base.mesh = mb_cyl
	mic_base.position.y = 0.015
	mic_base.set_surface_override_material(0, brass_mat)
	mic_root.add_child(mic_base)
	
	var mic_stem = MeshInstance3D.new()
	var ms_cyl = CylinderMesh.new()
	ms_cyl.top_radius = 0.012
	ms_cyl.bottom_radius = 0.014
	ms_cyl.height = 0.95
	mic_stem.mesh = ms_cyl
	mic_stem.position.y = 0.49
	mic_stem.set_surface_override_material(0, brass_mat)
	mic_root.add_child(mic_stem)
	
	# Mikrofon boynu ve başlığı doğrudan Kıbleye (Caminin ön tarafı / Mihrap, -Z) bakar
	var mic_arm = MeshInstance3D.new()
	var ma_cyl = CylinderMesh.new()
	ma_cyl.top_radius = 0.008
	ma_cyl.bottom_radius = 0.01
	ma_cyl.height = 0.24
	mic_arm.mesh = ma_cyl
	mic_arm.position = Vector3(0.09, 0.99, -0.09)
	mic_arm.rotation = Vector3(-0.65, 0.75, 0.0)
	mic_arm.set_surface_override_material(0, brass_mat)
	mic_root.add_child(mic_arm)
	
	var mic_head = MeshInstance3D.new()
	var mh_cyl = CylinderMesh.new()
	mh_cyl.top_radius = 0.02
	mh_cyl.bottom_radius = 0.02
	mh_cyl.height = 0.07
	mic_head.mesh = mh_cyl
	mic_head.position = Vector3(0.18, 1.05, -0.18)
	mic_head.rotation = Vector3(-0.75, 0.75, 0.0) # Tamamen kıble / mihrap yönüne dönük
	var mic_mat = StandardMaterial3D.new()
	mic_mat.albedo_color = Color(0.12, 0.12, 0.14)
	mic_mat.metallic = 0.8
	mic_head.set_surface_override_material(0, mic_mat)
	mic_root.add_child(mic_head)
	
	mahfil.add_child(mic_root)
	
	# 7. Asılı Müezzin Tesbihi (Referans Fotoğraf 3'te kapı dikmesinde asılı)
	var beads_root = Node3D.new()
	beads_root.position = Vector3(half_w, post_h * 0.85, 0.54)
	var bead_mat = StandardMaterial3D.new()
	bead_mat.albedo_color = Color(0.85, 0.45, 0.55) # Pembe gül tanesi tesbih
	bead_mat.roughness = 0.3
	for b_idx in range(11):
		var bead = MeshInstance3D.new()
		var bs = SphereMesh.new()
		bs.radius = 0.014
		bs.height = 0.028
		bead.mesh = bs
		var b_angle = float(b_idx) / 10.0 * PI
		bead.position = Vector3(0.01, -0.03 - sin(b_angle) * 0.16, (cos(b_angle) - 0.5) * 0.07)
		bead.set_surface_override_material(0, bead_mat)
		beads_root.add_child(bead)
	mahfil.add_child(beads_root)

	# 8. Müezzin Mahfili 3D Levhası
	var mahfil_label = Label3D.new()
	mahfil_label.text = "🕌 Müezzin Mahfili 🕌\n[Ezan & Kamet Makamı]"
	mahfil_label.font_size = 20
	mahfil_label.modulate = Color(1.0, 0.92, 0.42)
	mahfil_label.outline_size = 4
	mahfil_label.outline_modulate = Color(0.05, 0.05, 0.05)
	mahfil_label.position = Vector3(0, 2.35, 0)
	mahfil.add_child(mahfil_label)
	
	mosque.add_child(mahfil)



# ----------------- TARİHİ ŞADIRVAN (MEYDANIN MERKEZİNDE) -----------------

func build_sadirvan(pos: Vector3) -> void:
	var sadirvan = Node3D.new()
	sadirvan.name = "SadirvanFountain"
	sadirvan.add_to_group("sadirvan")
	sadirvan.add_to_group("interactables")
	sadirvan.position = pos
	
	var basin = StaticBody3D.new()
	var bcol = CollisionShape3D.new()
	var bshape = CylinderShape3D.new()
	bshape.radius = 2.8
	bshape.height = 1.0
	bcol.shape = bshape
	bcol.position.y = 0.5
	basin.add_child(bcol)
	var bmesh_inst = MeshInstance3D.new()
	var b_mesh = CylinderMesh.new()
	b_mesh.top_radius = 2.8
	b_mesh.bottom_radius = 2.8
	b_mesh.height = 1.0
	bmesh_inst.mesh = b_mesh
	bmesh_inst.position.y = 0.5
	var marble_mat = StandardMaterial3D.new()
	marble_mat.albedo_color = Color(0.92, 0.92, 0.90)
	marble_mat.roughness = 0.4
	bmesh_inst.set_surface_override_material(0, marble_mat)
	basin.add_child(bmesh_inst)
	sadirvan.add_child(basin)
	
	var water = MeshInstance3D.new()
	var wmesh = CylinderMesh.new()
	wmesh.top_radius = 2.6
	wmesh.bottom_radius = 2.6
	wmesh.height = 0.2
	water.mesh = wmesh
	water.position.y = 0.9
	var water_mat = StandardMaterial3D.new()
	water_mat.albedo_color = Color(0.12, 0.6, 0.8, 0.85)
	water_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water_mat.roughness = 0.05
	water.set_surface_override_material(0, water_mat)
	sadirvan.add_child(water)
	
	var wood_mat = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.35, 0.22, 0.12)
	wood_mat.roughness = 0.7
	
	var brass_mat = StandardMaterial3D.new()
	brass_mat.albedo_color = Color(0.95, 0.82, 0.22)
	brass_mat.metallic = 0.95
	
	var lead_mat = StandardMaterial3D.new()
	lead_mat.albedo_color = Color(0.38, 0.46, 0.5)
	lead_mat.metallic = 0.6
	lead_mat.roughness = 0.35
	
	for i in range(8):
		var angle = i * (TAU / 8.0)
		var px = cos(angle) * 2.6
		var pz = sin(angle) * 2.6
		var pillar = MeshInstance3D.new()
		var pmesh = CylinderMesh.new()
		pmesh.top_radius = 0.1
		pmesh.bottom_radius = 0.12
		pmesh.height = 3.0
		pillar.mesh = pmesh
		pillar.position = Vector3(px, 1.5, pz)
		pillar.set_surface_override_material(0, wood_mat)
		sadirvan.add_child(pillar)
		
		# Abdest Kurnası ve Pirinç Musluk
		var tap = MeshInstance3D.new()
		var tb = BoxMesh.new()
		tb.size = Vector3(0.08, 0.12, 0.18)
		tap.mesh = tb
		tap.position = Vector3(px * 1.05, 0.65, pz * 1.05)
		tap.rotation.y = -angle
		tap.set_surface_override_material(0, brass_mat)
		sadirvan.add_child(tap)
		
		# Ahşap Abdest Taburesi
		var stool = MeshInstance3D.new()
		var scyl = CylinderMesh.new()
		scyl.top_radius = 0.22
		scyl.bottom_radius = 0.25
		scyl.height = 0.35
		stool.mesh = scyl
		stool.position = Vector3(px * 1.35, 0.175, pz * 1.35)
		stool.set_surface_override_material(0, wood_mat)
		sadirvan.add_child(stool)
		
	var roof = MeshInstance3D.new()
	var rcone = CylinderMesh.new()
	rcone.top_radius = 0.15
	rcone.bottom_radius = 3.3
	rcone.height = 1.6
	roof.mesh = rcone
	roof.position.y = 3.7
	roof.set_surface_override_material(0, lead_mat)
	sadirvan.add_child(roof)
	
	# Şadırvan Hilâl Alemi
	var crescent = MeshInstance3D.new()
	var ccyl = CylinderMesh.new()
	ccyl.top_radius = 0.03
	ccyl.bottom_radius = 0.08
	ccyl.height = 0.8
	crescent.mesh = ccyl
	crescent.position.y = 4.8
	var gold_mat = StandardMaterial3D.new()
	gold_mat.albedo_color = Color(0.96, 0.82, 0.22)
	gold_mat.metallic = 0.95
	crescent.set_surface_override_material(0, gold_mat)
	sadirvan.add_child(crescent)
	
	var alabel = Label3D.new()
	alabel.text = "💧 Tarihi Şadırvan\n[ 'Q' veya 'Abdest' Butonuna Dokun ]"
	alabel.billboard = 1
	alabel.font_size = 20
	alabel.modulate = Color(0.4, 0.9, 1.0)
	alabel.outline_size = 4
	alabel.position = Vector3(0, 2.2, 0)
	sadirvan.add_child(alabel)
	
	add_child(sadirvan)

func build_tea_house_area(pos: Vector3) -> void:
	var teahouse = Node3D.new()
	teahouse.name = "TeaHouse"
	teahouse.position = pos
	
	# Malzemeler
	var th_timber_mat = StandardMaterial3D.new()
	if tex_wood:
		th_timber_mat.albedo_texture = tex_wood
		th_timber_mat.uv1_scale = Vector3(2, 2, 2)
	else:
		th_timber_mat.albedo_color = Color(0.36, 0.22, 0.12)
	th_timber_mat.roughness = 0.7
	
	var th_stone_mat = StandardMaterial3D.new()
	if tex_stone:
		th_stone_mat.albedo_texture = tex_stone
		th_stone_mat.uv1_scale = Vector3(4, 2, 4)
	else:
		th_stone_mat.albedo_color = Color(0.82, 0.78, 0.72)
	th_stone_mat.roughness = 0.85
	
	var th_roof_mat = StandardMaterial3D.new()
	if tex_roof:
		th_roof_mat.albedo_texture = tex_roof
		th_roof_mat.uv1_scale = Vector3(4, 3, 4)
	else:
		th_roof_mat.albedo_color = Color(0.65, 0.25, 0.18)
	th_roof_mat.roughness = 0.65
	
	var th_carpet_mat = StandardMaterial3D.new()
	if tex_carpet:
		th_carpet_mat.albedo_texture = tex_carpet
		th_carpet_mat.uv1_scale = Vector3(2, 2, 1)
	else:
		th_carpet_mat.albedo_color = Color(0.68, 0.15, 0.12)
	th_carpet_mat.roughness = 0.85
	
	var th_copper_mat = StandardMaterial3D.new()
	th_copper_mat.albedo_color = Color(0.85, 0.52, 0.32)
	th_copper_mat.metallic = 0.90
	th_copper_mat.roughness = 0.25
	
	var th_gold_mat = StandardMaterial3D.new()
	th_gold_mat.albedo_color = Color(0.96, 0.82, 0.25)
	th_gold_mat.metallic = 0.95
	th_gold_mat.roughness = 0.2
	
	var th_dark_wood = StandardMaterial3D.new()
	th_dark_wood.albedo_color = Color(0.22, 0.14, 0.08)
	th_dark_wood.roughness = 0.6

	# ================= 1. ZEMİN KAİDESİ VE AHŞAP VERANDA DÖŞEMESİ =================
	var deck_body = StaticBody3D.new()
	deck_body.name = "TeaHouseDeck"
	
	# Taş Temel Pabucu
	var stone_base = MeshInstance3D.new()
	var sbm = BoxMesh.new()
	sbm.size = Vector3(14.0, 0.30, 10.4)
	stone_base.mesh = sbm
	stone_base.position = Vector3(0, 0.15, 0)
	stone_base.set_surface_override_material(0, th_stone_mat)
	deck_body.add_child(stone_base)
	
	# Masif Ahşap Veranda Döşemesi
	var wood_floor = MeshInstance3D.new()
	var wfm = BoxMesh.new()
	wfm.size = Vector3(13.6, 0.08, 10.0)
	wood_floor.mesh = wfm
	wood_floor.position = Vector3(0, 0.34, 0)
	wood_floor.set_surface_override_material(0, th_timber_mat)
	deck_body.add_child(wood_floor)
	
	# Giriş Mermer/Taş Basamakları (Ön avludan rahat çıkış)
	for st_idx in range(2):
		var step_inst = MeshInstance3D.new()
		var sm_box = BoxMesh.new()
		sm_box.size = Vector3(3.2 - st_idx * 0.4, 0.15, 0.6)
		step_inst.mesh = sm_box
		step_inst.position = Vector3(0, 0.075 + st_idx * 0.15, 5.3 + (1 - st_idx) * 0.45)
		step_inst.set_surface_override_material(0, th_stone_mat)
		deck_body.add_child(step_inst)
		
	var deck_col = CollisionShape3D.new()
	var dcs = BoxShape3D.new()
	dcs.size = Vector3(14.0, 0.38, 10.4)
	deck_col.shape = dcs
	deck_col.position = Vector3(0, 0.19, 0)
	deck_body.add_child(deck_col)
	teahouse.add_child(deck_body)

	# ================= 2. TAŞIYICI AHŞAP DİKMELER, HATILLAR VE ELİBÖĞRÜNDELER =================
	# 8 Adet masif ahşap kolon
	var post_x_coords = [-5.8, -1.9, 1.9, 5.8]
	var post_z_coords = [-4.6, 4.6]
	
	for px in post_x_coords:
		for pz in post_z_coords:
			var post_body = StaticBody3D.new()
			
			var post_mesh = MeshInstance3D.new()
			var pm = BoxMesh.new()
			pm.size = Vector3(0.24, 3.10, 0.24)
			post_mesh.mesh = pm
			post_mesh.position = Vector3(px, 1.93, pz)
			post_mesh.set_surface_override_material(0, th_dark_wood)
			post_body.add_child(post_mesh)
			
			# Sütun Başlığı
			var cap_mesh = MeshInstance3D.new()
			var cm = BoxMesh.new()
			cm.size = Vector3(0.36, 0.14, 0.36)
			cap_mesh.mesh = cm
			cap_mesh.position = Vector3(px, 3.45, pz)
			cap_mesh.set_surface_override_material(0, th_dark_wood)
			post_body.add_child(cap_mesh)
			
			# Çapraz Eli Böğründe Konsol Destekleri (Geleneksel mimari çıkma)
			for dir_x in [-1, 1]:
				var bracket = MeshInstance3D.new()
				var brm = BoxMesh.new()
				brm.size = Vector3(0.10, 0.55, 0.10)
				bracket.mesh = brm
				bracket.position = Vector3(px + dir_x * 0.22, 3.25, pz)
				bracket.rotation.z = dir_x * 0.65
				bracket.set_surface_override_material(0, th_dark_wood)
				post_body.add_child(bracket)
				
			var p_col = CollisionShape3D.new()
			var pcs = BoxShape3D.new()
			pcs.size = Vector3(0.26, 3.10, 0.26)
			p_col.shape = pcs
			p_col.position = Vector3(px, 1.93, pz)
			post_body.add_child(p_col)
			
			teahouse.add_child(post_body)

	# Üst Taşıyıcı Ahşap Hatıllar (Architraves)
	for pz in post_z_coords:
		var beam_long = MeshInstance3D.new()
		var blm = BoxMesh.new()
		blm.size = Vector3(12.2, 0.22, 0.26)
		beam_long.mesh = blm
		beam_long.position = Vector3(0, 3.52, pz)
		beam_long.set_surface_override_material(0, th_dark_wood)
		teahouse.add_child(beam_long)
		
	for px in [-5.8, 5.8]:
		var beam_cross = MeshInstance3D.new()
		var bcm = BoxMesh.new()
		bcm.size = Vector3(0.26, 0.22, 9.4)
		beam_cross.mesh = bcm
		beam_cross.position = Vector3(px, 3.52, 0)
		beam_cross.set_surface_override_material(0, th_dark_wood)
		teahouse.add_child(beam_cross)

	# ================= 3. ARKA DUVAR VE YAN AHŞAP KORKULUKLAR =================
	# Arka Duvar (Kuzey cephe - ahşap yalı baskı ve ocak nişi)
	var back_wall = StaticBody3D.new()
	var bwm = MeshInstance3D.new()
	var bw_box = BoxMesh.new()
	bw_box.size = Vector3(12.0, 3.10, 0.16)
	bwm.mesh = bw_box
	bwm.position = Vector3(0, 1.93, -4.6)
	bwm.set_surface_override_material(0, th_timber_mat)
	back_wall.add_child(bwm)
	
	var bw_col = CollisionShape3D.new()
	var bw_shape = BoxShape3D.new()
	bw_shape.size = Vector3(12.0, 3.10, 0.16)
	bw_col.shape = bw_shape
	bw_col.position = Vector3(0, 1.93, -4.6)
	back_wall.add_child(bw_col)
	
	# Arka Duvar Kafesli Pencereler
	for win_x in [-3.5, 3.5]:
		var window_frame = MeshInstance3D.new()
		var wfm_box = BoxMesh.new()
		wfm_box.size = Vector3(1.6, 1.8, 0.20)
		window_frame.mesh = wfm_box
		window_frame.position = Vector3(win_x, 2.1, -4.6)
		window_frame.set_surface_override_material(0, th_dark_wood)
		back_wall.add_child(window_frame)
	teahouse.add_child(back_wall)

	# Yan ve Ön Ahşap Korkuluklar (Otantik Parmaklıklar)
	# Sağ Yan Korkuluk
	var rail_right = MeshInstance3D.new()
	var rrm = BoxMesh.new()
	rrm.size = Vector3(0.12, 0.85, 9.2)
	rail_right.mesh = rrm
	rail_right.position = Vector3(5.8, 0.80, 0)
	rail_right.set_surface_override_material(0, th_dark_wood)
	teahouse.add_child(rail_right)
	
	# Sol Yan Korkuluk
	var rail_left = MeshInstance3D.new()
	rail_left.mesh = rrm
	rail_left.position = Vector3(-5.8, 0.80, 0)
	rail_left.set_surface_override_material(0, th_dark_wood)
	teahouse.add_child(rail_left)
	
	# Ön Kanat Korkulukları (Orta giriş serbest açık)
	for front_rx in [-3.85, 3.85]:
		var rail_front = MeshInstance3D.new()
		var rfm = BoxMesh.new()
		rfm.size = Vector3(3.7, 0.85, 0.12)
		rail_front.mesh = rfm
		rail_front.position = Vector3(front_rx, 0.80, 4.6)
		rail_front.set_surface_override_material(0, th_dark_wood)
		teahouse.add_child(rail_front)

	# ================= 4. HEYBETLİ ALATURKA KİREMİTLİ KIRMA ÇATI (PITCHED ROOF) =================
	# Geniş Saçaklar (Cantilevered Eaves)
	var roof_eaves = MeshInstance3D.new()
	var rem = BoxMesh.new()
	rem.size = Vector3(14.6, 0.18, 11.2)
	roof_eaves.mesh = rem
	roof_eaves.position = Vector3(0, 3.63, 0)
	roof_eaves.set_surface_override_material(0, th_dark_wood)
	teahouse.add_child(roof_eaves)
	
	# Saçak Oymalı Alın Tahtası
	var eaves_fascia = MeshInstance3D.new()
	var efm = BoxMesh.new()
	efm.size = Vector3(14.8, 0.12, 11.4)
	eaves_fascia.mesh = efm
	eaves_fascia.position = Vector3(0, 3.56, 0)
	eaves_fascia.set_surface_override_material(0, th_dark_wood)
	teahouse.add_child(eaves_fascia)
	
	# Kırma Kiremit Çatı Gövdesi (Pitched Terracotta Roof)
	var roof_mesh = MeshInstance3D.new()
	var rm_prism = PrismMesh.new()
	rm_prism.size = Vector3(14.2, 1.85, 10.8)
	roof_mesh.mesh = rm_prism
	roof_mesh.position = Vector3(0, 4.56, 0)
	roof_mesh.set_surface_override_material(0, th_roof_mat)
	teahouse.add_child(roof_mesh)
	
	# Çatı Mahyası ve Kiremit Sırtı
	var roof_ridge = MeshInstance3D.new()
	var rrm_box = BoxMesh.new()
	rrm_box.size = Vector3(9.2, 0.18, 0.35)
	roof_ridge.mesh = rrm_box
	roof_ridge.position = Vector3(0, 5.48, 0)
	roof_ridge.set_surface_override_material(0, th_roof_mat)
	teahouse.add_child(roof_ridge)
	
	# Çatı Uç Pirinç Alemleri
	for fin_x in [-4.6, 4.6]:
		var finial = MeshInstance3D.new()
		var fm_cyl = CylinderMesh.new()
		fm_cyl.top_radius = 0.02
		fm_cyl.bottom_radius = 0.08
		fm_cyl.height = 0.45
		finial.mesh = fm_cyl
		finial.position = Vector3(fin_x, 5.75, 0)
		finial.set_surface_override_material(0, th_gold_mat)
		teahouse.add_child(finial)

	# ================= 5. ÇAY OCAĞI TEZGAHI VE BÜYÜK BAKIR SEMAVER =================
	var tea_counter = StaticBody3D.new()
	tea_counter.name = "TeaCounter"
	
	# Oymalı Ahşap Servis Tezgahı
	var counter_mesh = MeshInstance3D.new()
	var cbm = BoxMesh.new()
	cbm.size = Vector3(2.8, 0.90, 0.90)
	counter_mesh.mesh = cbm
	counter_mesh.position = Vector3(3.2, 0.83, -3.8)
	counter_mesh.set_surface_override_material(0, th_dark_wood)
	tea_counter.add_child(counter_mesh)
	
	var counter_col = CollisionShape3D.new()
	var ccs = BoxShape3D.new()
	ccs.size = Vector3(2.8, 0.90, 0.90)
	counter_col.shape = ccs
	counter_col.position = Vector3(3.2, 0.83, -3.8)
	tea_counter.add_child(counter_col)
	
	# Tezgah Üstü Mermer Plaka
	var counter_top = MeshInstance3D.new()
	var ctm = BoxMesh.new()
	ctm.size = Vector3(2.9, 0.06, 0.96)
	counter_top.mesh = ctm
	counter_top.position = Vector3(3.2, 1.30, -3.8)
	counter_top.set_surface_override_material(0, th_stone_mat)
	tea_counter.add_child(counter_top)
	
	# Büyük Osmanlı Bakır Semaveri (Authentic Copper Samovar)
	var samovar_base = MeshInstance3D.new()
	var sbm_cyl = CylinderMesh.new()
	sbm_cyl.top_radius = 0.17
	sbm_cyl.bottom_radius = 0.14
	sbm_cyl.height = 0.52
	samovar_base.mesh = sbm_cyl
	samovar_base.position = Vector3(3.2, 1.58, -3.8)
	samovar_base.set_surface_override_material(0, th_copper_mat)
	tea_counter.add_child(samovar_base)
	
	# Semaver Demliği (Porselen / Bakır Üst Demlik)
	var teapot = MeshInstance3D.new()
	var tpm = CylinderMesh.new()
	tpm.top_radius = 0.08
	tpm.bottom_radius = 0.12
	tpm.height = 0.22
	teapot.mesh = tpm
	teapot.position = Vector3(3.2, 1.94, -3.8)
	teapot.set_surface_override_material(0, th_copper_mat)
	tea_counter.add_child(teapot)
	
	# Semaver Bacası
	var chimney = MeshInstance3D.new()
	var chm = CylinderMesh.new()
	chm.top_radius = 0.03
	chm.bottom_radius = 0.03
	chm.height = 0.35
	chimney.mesh = chm
	chimney.position = Vector3(3.2, 2.20, -3.8)
	chimney.set_surface_override_material(0, th_copper_mat)
	tea_counter.add_child(chimney)
	
	# Semaver Altı Sıcak Köz Işığı
	var ember_light = OmniLight3D.new()
	ember_light.light_color = Color(1.0, 0.55, 0.2)
	ember_light.light_energy = 1.2
	ember_light.omni_range = 2.5
	ember_light.position = Vector3(3.2, 1.45, -3.8)
	tea_counter.add_child(ember_light)
	
	# Bakır Çay Tepsisi & İnce Belli Çay Bardakları
	var tea_tray = MeshInstance3D.new()
	var trm = CylinderMesh.new()
	trm.top_radius = 0.32
	trm.bottom_radius = 0.32
	trm.height = 0.03
	tea_tray.mesh = trm
	tea_tray.position = Vector3(2.3, 1.34, -3.8)
	tea_tray.set_surface_override_material(0, th_copper_mat)
	tea_counter.add_child(tea_tray)
	
	for g_idx in range(3):
		var glass = MeshInstance3D.new()
		var gm = CylinderMesh.new()
		gm.top_radius = 0.04
		gm.bottom_radius = 0.03
		gm.height = 0.09
		glass.mesh = gm
		var g_ang = float(g_idx) * (TAU / 3.0)
		glass.position = Vector3(2.3 + cos(g_ang) * 0.16, 1.40, -3.8 + sin(g_ang) * 0.16)
		var tea_mat = StandardMaterial3D.new()
		tea_mat.albedo_color = Color(0.68, 0.12, 0.08)
		glass.set_surface_override_material(0, tea_mat)
		tea_counter.add_child(glass)
	teahouse.add_child(tea_counter)

	# ================= 6. GELENEKSEL KİLİM KAPLI SEDİRLER VE HASIR TABURELER =================
	# Sol Duvar Sediri (L-sedir bölümü)
	var sedir_body = StaticBody3D.new()
	var sedir_mesh = MeshInstance3D.new()
	var sdm = BoxMesh.new()
	sdm.size = Vector3(4.8, 0.45, 1.0)
	sedir_mesh.mesh = sdm
	sedir_mesh.position = Vector3(-3.2, 0.58, -3.8)
	sedir_mesh.set_surface_override_material(0, th_dark_wood)
	sedir_body.add_child(sedir_mesh)
	
	# Sedir Kilim Minderi
	var cushion = MeshInstance3D.new()
	var csm = BoxMesh.new()
	csm.size = Vector3(4.7, 0.12, 0.95)
	cushion.mesh = csm
	cushion.position = Vector3(-3.2, 0.84, -3.8)
	cushion.set_surface_override_material(0, th_carpet_mat)
	sedir_body.add_child(cushion)
	
	# Sırt Kırlentleri
	for k_idx in range(4):
		var pillow = MeshInstance3D.new()
		var plm = BoxMesh.new()
		plm.size = Vector3(0.9, 0.4, 0.18)
		pillow.mesh = plm
		pillow.position = Vector3(-4.6 + k_idx * 1.0, 1.05, -4.3)
		pillow.set_surface_override_material(0, th_carpet_mat)
		sedir_body.add_child(pillow)
		
	var s_col = CollisionShape3D.new()
	var sc_box = BoxShape3D.new()
	sc_box.size = Vector3(4.8, 0.85, 1.0)
	s_col.shape = sc_box
	s_col.position = Vector3(-3.2, 0.78, -3.8)
	sedir_body.add_child(s_col)
	teahouse.add_child(sedir_body)

	# Alçak Masalar ve Hasır Tabureler
	for tb_x in [-3.2, 0.0]:
		var low_table = StaticBody3D.new()
		var ltm = MeshInstance3D.new()
		var ltc = CylinderMesh.new()
		ltc.top_radius = 0.45
		ltc.bottom_radius = 0.45
		ltc.height = 0.55
		ltm.mesh = ltc
		ltm.position = Vector3(tb_x, 0.62, -2.4)
		ltm.set_surface_override_material(0, th_dark_wood)
		low_table.add_child(ltm)
		
		# Tabureler
		for stool_sign in [-1, 1]:
			var stool = MeshInstance3D.new()
			var st_m = CylinderMesh.new()
			st_m.top_radius = 0.22
			st_m.bottom_radius = 0.22
			st_m.height = 0.38
			stool.mesh = st_m
			stool.position = Vector3(tb_x + stool_sign * 0.7, 0.53, -2.4)
			stool.set_surface_override_material(0, th_timber_mat)
			low_table.add_child(stool)
		teahouse.add_child(low_table)

	# ================= 7. SATRANÇ VE CASUS DİMİTRİ MASASI =================
	# Düzenli, görkemli satranç masası - Oyuncu tam önünde durup 'E' ile etkileşime girer
	var chess_table = StaticBody3D.new()
	chess_table.name = "ChessInterrogationTable"
	chess_table.position = Vector3(-3.5, 0.34, 0.5) # Global: (18.5, 0.34, -4.5) -> Etkileşim alanıyla tam uyumlu!
	
	var t_col = CollisionShape3D.new()
	var t_shape = CylinderShape3D.new()
	t_shape.radius = 0.75
	t_shape.height = 0.85
	t_col.shape = t_shape
	t_col.position.y = 0.425
	chess_table.add_child(t_col)
	
	# Oymalı Yuvarlak Ahşap Masa
	var t_mesh = MeshInstance3D.new()
	var tm = CylinderMesh.new()
	tm.top_radius = 0.72
	tm.bottom_radius = 0.68
	tm.height = 0.85
	t_mesh.mesh = tm
	t_mesh.position.y = 0.425
	t_mesh.set_surface_override_material(0, th_dark_wood)
	chess_table.add_child(t_mesh)
	
	# Masa Üstü Sedef Kakmalı Satranç Tahtası
	var board = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(0.72, 0.05, 0.72)
	board.mesh = b_box
	board.position = Vector3(0, 0.875, 0)
	var board_mat = StandardMaterial3D.new()
	board_mat.albedo_color = Color(0.18, 0.12, 0.08)
	board.set_surface_override_material(0, board_mat)
	chess_table.add_child(board)
	
	# Satranç Taşları (Beyaz & Siyah Temsili Figürler)
	for piece_idx in range(6):
		var piece = MeshInstance3D.new()
		var pcm = CylinderMesh.new()
		pcm.top_radius = 0.02
		pcm.bottom_radius = 0.035
		pcm.height = 0.08
		piece.mesh = pcm
		var px_off = (piece_idx % 3 - 1) * 0.16
		var pz_off = (piece_idx / 3 - 0.5) * 0.28
		piece.position = Vector3(px_off, 0.94, pz_off)
		var p_mat = StandardMaterial3D.new()
		p_mat.albedo_color = Color(0.92, 0.88, 0.8) if (piece_idx % 2 == 0) else Color(0.15, 0.12, 0.1)
		piece.set_surface_override_material(0, p_mat)
		chess_table.add_child(piece)
		
	# Ahşap Sandalyeler (İki yanda)
	for chair_z in [-0.85, 0.85]:
		var chair = MeshInstance3D.new()
		var ch_box = BoxMesh.new()
		ch_box.size = Vector3(0.55, 0.48, 0.50)
		chair.mesh = ch_box
		chair.position = Vector3(0, 0.24, chair_z)
		chair.set_surface_override_material(0, th_dark_wood)
		chess_table.add_child(chair)
		
		var backrest = MeshInstance3D.new()
		var br_box = BoxMesh.new()
		br_box.size = Vector3(0.55, 0.50, 0.08)
		backrest.mesh = br_box
		backrest.position = Vector3(0, 0.70, chair_z + (0.22 if chair_z > 0 else -0.22))
		backrest.set_surface_override_material(0, th_dark_wood)
		chess_table.add_child(backrest)
	
	# Satranç Masası Üstü Odak Işığı
	var chess_light = OmniLight3D.new()
	chess_light.light_color = Color(1.0, 0.88, 0.55)
	chess_light.light_energy = 2.2
	chess_light.omni_range = 5.0
	chess_light.position = Vector3(0, 2.2, 0)
	chess_table.add_child(chess_light)
	
	# Rus Ajanı Dimitri NPC
	var dimitri_npc = Node3D.new()
	dimitri_npc.name = "DimitriNPC"
	dimitri_npc.position = Vector3(0, 0, 0.85)
	var soldier_res = load("res://assets/models/Soldier.glb")
	if soldier_res:
		var d_model = soldier_res.instantiate()
		dimitri_npc.add_child(d_model)
		var anim = d_model.get_node_or_null("AnimationPlayer")
		if anim and anim.has_animation("Idle"):
			anim.play("Idle")
		CharacterStyler.style_character(d_model, "spy")
	else:
		var d_body = MeshInstance3D.new()
		var cap = CapsuleMesh.new()
		cap.radius = 0.35
		cap.height = 1.6
		d_body.mesh = cap
		d_body.position.y = 0.8
		var spy_mat = StandardMaterial3D.new()
		spy_mat.albedo_color = Color(0.18, 0.2, 0.24)
		d_body.set_surface_override_material(0, spy_mat)
		dimitri_npc.add_child(d_body)
	chess_table.add_child(dimitri_npc)
	
	var dlabel = Label3D.new()
	dlabel.text = "♟️ Dimitri (Sözde Kürk Tüccarı)\n[ 'E' veya 'Konuş' ile Satranç Oyna ]"
	dlabel.billboard = 1
	dlabel.font_size = 20
	dlabel.modulate = Color(1.0, 0.85, 0.35)
	dlabel.outline_size = 4
	dlabel.position = Vector3(0, 2.3, 0.85)
	chess_table.add_child(dlabel)
	
	teahouse.add_child(chess_table)

	# ================= 8. ASMA PİRİNÇ FENERLER VE OTANTİK AYDINLATMA =================
	var lantern_coords = [
		Vector3(-3.5, 3.1, 1.5),
		Vector3(3.2, 3.1, 1.5),
		Vector3(0.0, 3.1, -1.8)
	]
	for lp in lantern_coords:
		var lantern_pole = MeshInstance3D.new()
		var ch_cyl = CylinderMesh.new()
		ch_cyl.top_radius = 0.015
		ch_cyl.bottom_radius = 0.015
		ch_cyl.height = 0.50
		lantern_pole.mesh = ch_cyl
		lantern_pole.position = Vector3(lp.x, lp.y + 0.25, lp.z)
		lantern_pole.set_surface_override_material(0, th_copper_mat)
		teahouse.add_child(lantern_pole)
		
		var lantern_box = MeshInstance3D.new()
		var lb_mesh = BoxMesh.new()
		lb_mesh.size = Vector3(0.32, 0.42, 0.32)
		lantern_box.mesh = lb_mesh
		lantern_box.position = lp
		lantern_box.set_surface_override_material(0, th_gold_mat)
		teahouse.add_child(lantern_box)
		
		var l_omni = OmniLight3D.new()
		l_omni.light_color = Color(1.0, 0.82, 0.45)
		l_omni.light_energy = 1.8
		l_omni.omni_range = 6.5
		l_omni.position = lp
		teahouse.add_child(l_omni)

	# ================= 9. GİRİŞ KIRAATHANE TABELASI =================
	var sign_board = MeshInstance3D.new()
	var sgn_m = BoxMesh.new()
	sgn_m.size = Vector3(3.6, 0.65, 0.08)
	sign_board.mesh = sgn_m
	sign_board.position = Vector3(0, 3.10, 4.75)
	sign_board.set_surface_override_material(0, th_dark_wood)
	teahouse.add_child(sign_board)
	
	var sign_label = Label3D.new()
	sign_label.text = "☕ ÇINARALTI KIRAATHANESİ ☕\n— Tiryaki Ocağı • 1876 —"
	sign_label.font_size = 24
	sign_label.pixel_size = 0.0055
	sign_label.modulate = Color(1.0, 0.88, 0.35)
	sign_label.outline_size = 5
	sign_label.position = Vector3(0, 3.10, 4.81)
	teahouse.add_child(sign_label)

	# ================= 10. AÇIK AVLUDA KOCA ÇINAR ALTI DAİRESEL SEDİR =================
	# Avludaki çınar ağacının (x = 14.0, z = -3.5) etrafındaki dairesel ahşap seki/sedir
	var tree_bench_pos = Vector3(-8.0, 0, 1.5) # Avlu çınarının gövde etrafı
	var round_bench = StaticBody3D.new()
	round_bench.position = tree_bench_pos
	
	var rb_mesh = MeshInstance3D.new()
	var rbm = CylinderMesh.new()
	rbm.top_radius = 1.6
	rbm.bottom_radius = 1.6
	rbm.height = 0.45
	rb_mesh.mesh = rbm
	rb_mesh.position.y = 0.225
	rb_mesh.set_surface_override_material(0, th_timber_mat)
	round_bench.add_child(rb_mesh)
	
	var rb_col = CollisionShape3D.new()
	var rbcs = CylinderShape3D.new()
	rbcs.radius = 1.6
	rbcs.height = 0.45
	rb_col.shape = rbcs
	rb_col.position.y = 0.225
	round_bench.add_child(rb_col)
	teahouse.add_child(round_bench)

	add_child(teahouse)

func build_sultan_carriage(pos: Vector3) -> void:
	var carriage = Node3D.new()
	carriage.name = "SultanCarriage"
	carriage.position = pos
	
	var body = StaticBody3D.new()
	var bcol = CollisionShape3D.new()
	var bshape = BoxShape3D.new()
	bshape.size = Vector3(3.4, 2.3, 2.1)
	bcol.shape = bshape
	bcol.position.y = 1.45
	body.add_child(bcol)
	
	var cmesh = MeshInstance3D.new()
	var cbox = BoxMesh.new()
	cbox.size = Vector3(3.4, 2.1, 2.1)
	cmesh.mesh = cbox
	cmesh.position.y = 1.45
	var royal_mat = StandardMaterial3D.new()
	if tex_velvet:
		royal_mat.albedo_texture = tex_velvet
		royal_mat.uv1_scale = Vector3(1.5, 1, 1)
	else:
		royal_mat.albedo_color = Color(0.12, 0.16, 0.28)
	royal_mat.metallic = 0.4
	royal_mat.roughness = 0.3
	cmesh.set_surface_override_material(0, royal_mat)
	body.add_child(cmesh)
	
	var trim = MeshInstance3D.new()
	var tr_box = BoxMesh.new()
	tr_box.size = Vector3(3.45, 0.14, 2.15)
	trim.mesh = tr_box
	trim.position.y = 2.45
	var gold_mat = StandardMaterial3D.new()
	gold_mat.albedo_color = Color(0.98, 0.82, 0.22)
	gold_mat.metallic = 0.95
	trim.set_surface_override_material(0, gold_mat)
	body.add_child(trim)
	
	var wheel_mat = StandardMaterial3D.new()
	wheel_mat.albedo_color = Color(0.28, 0.18, 0.1)
	for wx in [-1.3, 1.3]:
		for wz in [-1.2, 1.2]:
			var wheel = MeshInstance3D.new()
			var wcyl = CylinderMesh.new()
			wcyl.top_radius = 0.58
			wcyl.bottom_radius = 0.58
			wcyl.height = 0.14
			wheel.mesh = wcyl
			wheel.position = Vector3(wx, 0.58, wz)
			wheel.rotation.x = PI / 2.0
			wheel.set_surface_override_material(0, wheel_mat)
			carriage.add_child(wheel)
			
	var clabel = Label3D.new()
	clabel.text = "👑 Mihrimah Sultan'ın Faytonu\n(Pusu Hedefi - Koru!)"
	clabel.billboard = 1
	clabel.font_size = 22
	clabel.modulate = Color(1.0, 0.85, 0.3)
	clabel.outline_size = 4
	clabel.position = Vector3(0, 3.1, 0)
	carriage.add_child(clabel)
	
	carriage.add_child(body)
	add_child(carriage)

func build_residential_streets() -> void:
	# Cami Külliye İhata Duvarı
	build_mosque_courtyard_perimeter()

	# =========================================================================
	# 1. BATI TARİHİ MAHALLE (x = -32 Ana Konaklar Caddesi & x = -46 Çıkmazı)
	# =========================================================================
	# Ana Batı Caddesi (x = -32) - Meydana ve Camiye cepheli
	spawn_courtyard_garden_house(Vector3(-32, 0, -22), 0.0, true) # Avlulu & Tarihi Taş Kuyulu Konak
	var w_bridge1 = Vector3(-32, 5.2, 5.0)
	spawn_parkour_rooftop_house(Vector3(-32, 0, -8), 0.0, w_bridge1, true) # Çatı Zulası & Köprü Başlangıcı
	spawn_ottoman_mansion(Vector3(-32, 0, 5), 0.0, 0) # Aşı Boyası Kırmızı Konak (Köprü iniş noktası)
	var w_bridge2 = Vector3(-46, 5.2, 18.0) # Arka sokağa geçen çatı köprüsü
	spawn_parkour_rooftop_house(Vector3(-32, 0, 18), 0.0, w_bridge2, false) # Gözcülü Parkur Konağı
	spawn_courtyard_garden_house(Vector3(-32, 0, 31), 0.0, true) # Bahçeli Çardaklı Konak

	# Batı Çıkmaz Sokağı (x = -46) - Arka sokak dokusu
	spawn_ottoman_mansion(Vector3(-46, 0, -20), PI, 1) # Safranbolu Sarısı Konak
	spawn_parkour_rooftop_house(Vector3(-46, 0, -6), PI, Vector3.ZERO, true) # Arka Sokak Parkur & Zula Konağı
	spawn_ottoman_mansion(Vector3(-46, 0, 7), PI, 2) # Koyu Meşe / Çam Konak
	spawn_ottoman_mansion(Vector3(-46, 0, 18), PI, 3) # Beyaz Badanalı Ahşap Konak (Köprü Karşılama)
	spawn_courtyard_garden_house(Vector3(-46, 0, 31), PI, true) # Arka Bahçeli Kuyu Evi

	# =========================================================================
	# 2. DOĞU TARİHİ MAHALLE (x = +34 Çınaraltı Yanı & x = +48 Doğu Çıkmazı)
	# =========================================================================
	# Ana Doğu Caddesi (x = +34)
	spawn_parkour_rooftop_house(Vector3(34, 0, -22), PI, Vector3.ZERO, true) # Camiye ve Avluya bakan Gözcülü Parkur
	spawn_courtyard_garden_house(Vector3(34, 0, -8), PI, true) # Çınaraltı Kıraathanesi Arkası Avlulu Kuyu
	spawn_ottoman_mansion(Vector3(34, 0, 5), PI, 0) # Klasik Aşı Boyalı Konak
	var e_bridge1 = Vector3(48, 5.2, 18.0) # Doğu sokağını aşan çatı geçiş köprüsü
	spawn_parkour_rooftop_house(Vector3(34, 0, 18), PI, e_bridge1, true) # Teşkilat Zula & Çatı Köprüsü
	spawn_courtyard_garden_house(Vector3(34, 0, 31), PI, true) # Bahçeli Çardaklı Konak

	# Doğu Çıkmaz Sokağı (x = +48)
	spawn_ottoman_mansion(Vector3(48, 0, -20), 0.0, 1) # Safranbolu Sarısı
	spawn_courtyard_garden_house(Vector3(48, 0, -6), 0.0, true) # Avlulu Taş Kuyu Evi
	spawn_ottoman_mansion(Vector3(48, 0, 7), 0.0, 2) # Koyu Ahşap Konak
	spawn_parkour_rooftop_house(Vector3(48, 0, 18), 0.0, Vector3.ZERO, false) # Köprü Karşılama Parkur Konağı
	spawn_courtyard_garden_house(Vector3(48, 0, 31), 0.0, true) # Çardaklı Doğu Konağı

	# =========================================================================
	# 3. GÜNEY ESNAF & ÇARŞI MAHALLESİ (Kapalıçarşı Arkası, z = 70..74)
	# =========================================================================
	spawn_ottoman_mansion(Vector3(-36, 0, 72), PI, 2)
	spawn_parkour_rooftop_house(Vector3(-18, 0, 72), PI, Vector3(0, 5.2, 74), true) # Çarşı Parkur Çatısı
	spawn_courtyard_garden_house(Vector3(0, 0, 74), PI, true) # Çarşı Kuyu Konağı
	spawn_parkour_rooftop_house(Vector3(18, 0, 72), PI, Vector3.ZERO, true) # Teşkilat Zula Konağı
	spawn_ottoman_mansion(Vector3(36, 0, 72), PI, 0)

	# =========================================================================
	# 4. KUZEY KÜLLİYE & CAMİ YANI MAHALLESİ (z = -44..-56)
	# =========================================================================
	spawn_courtyard_garden_house(Vector3(-32, 0, -44), 0.0, true) # Cami Batı Girişi Külliye Konağı
	spawn_ottoman_mansion(Vector3(-32, 0, -56), 0.0, 3) # Medrese Karşısı Beyaz Konak
	spawn_courtyard_garden_house(Vector3(34, 0, -44), PI, true) # Doğu Şadırvan Yanı Külliye Evi
	spawn_parkour_rooftop_house(Vector3(34, 0, -56), PI, Vector3.ZERO, true) # Minareye ve Mihraba Bakan Gözcü Çatısı

	# =========================================================================
	# 5. KUZEY MEDRESE & MOLLA MAHALLESİ (Cami Arkası Sokakları, z = -68..-84)
	# =========================================================================
	spawn_ottoman_mansion(Vector3(-46, 0, -68), PI, 0)
	spawn_courtyard_garden_house(Vector3(-32, 0, -68), 0.0, true)
	spawn_parkour_rooftop_house(Vector3(-18, 0, -70), 0.0, Vector3.ZERO, true)
	spawn_ottoman_mansion(Vector3(-18, 0, -82), PI, 2)
	spawn_courtyard_garden_house(Vector3(0, 0, -84), PI, true)
	spawn_ottoman_mansion(Vector3(18, 0, -82), PI, 1)
	spawn_parkour_rooftop_house(Vector3(18, 0, -70), PI, Vector3.ZERO, true)
	spawn_courtyard_garden_house(Vector3(34, 0, -68), PI, true)
	spawn_ottoman_mansion(Vector3(48, 0, -68), 0.0, 3)

	# =========================================================================
	# 6. BATI YAMAÇ & DEĞİRMENÖNÜ MAHALLESİ (x = -62..-76, z = -32..40)
	# =========================================================================
	spawn_ottoman_mansion(Vector3(-62, 0, -32), 0.0, 1)
	spawn_courtyard_garden_house(Vector3(-62, 0, -18), 0.0, true)
	spawn_parkour_rooftop_house(Vector3(-62, 0, -4), 0.0, Vector3.ZERO, true)
	spawn_ottoman_mansion(Vector3(-62, 0, 10), 0.0, 2)
	spawn_courtyard_garden_house(Vector3(-62, 0, 24), 0.0, true)
	spawn_ottoman_mansion(Vector3(-62, 0, 38), 0.0, 0)
	spawn_ottoman_mansion(Vector3(-74, 0, -20), PI, 3)
	spawn_courtyard_garden_house(Vector3(-74, 0, -6), PI, true)
	spawn_parkour_rooftop_house(Vector3(-74, 0, 8), PI, Vector3.ZERO, true)
	spawn_ottoman_mansion(Vector3(-74, 0, 22), PI, 1)

	# =========================================================================
	# 7. DOĞU BOĞAZİÇİ & YALILAR MAHALLESİ (x = +62..+76, z = -20..40)
	# =========================================================================
	spawn_ottoman_mansion(Vector3(62, 0, -18), PI, 0)
	spawn_courtyard_garden_house(Vector3(62, 0, -4), PI, true)
	spawn_parkour_rooftop_house(Vector3(62, 0, 10), PI, Vector3.ZERO, true)
	spawn_ottoman_mansion(Vector3(62, 0, 24), PI, 2)
	spawn_courtyard_garden_house(Vector3(62, 0, 38), PI, true)
	spawn_ottoman_mansion(Vector3(76, 0, -10), 0.0, 1)
	spawn_courtyard_garden_house(Vector3(76, 0, 5), 0.0, true)
	spawn_parkour_rooftop_house(Vector3(76, 0, 20), 0.0, Vector3.ZERO, true)
	spawn_ottoman_mansion(Vector3(76, 0, 35), 0.0, 3)

	# =========================================================================
	# 8. GÜNEYBATI ZANAATKÂRLAR & SARAÇLAR MAHALLESİ (x = -52..-68, z = 55..90)
	# =========================================================================
	spawn_ottoman_mansion(Vector3(-52, 0, 55), 0.0, 2)
	spawn_courtyard_garden_house(Vector3(-52, 0, 70), 0.0, true)
	spawn_parkour_rooftop_house(Vector3(-52, 0, 85), 0.0, Vector3.ZERO, true)
	spawn_ottoman_mansion(Vector3(-66, 0, 60), PI, 1)
	spawn_courtyard_garden_house(Vector3(-66, 0, 75), PI, true)
	spawn_ottoman_mansion(Vector3(-66, 0, 90), PI, 0)

	# =========================================================================
	# 9. GÜNEYDOĞU AKTARLAR & KERVANCILAR MAHALLESİ (x = +52..+68, z = 55..90)
	# =========================================================================
	spawn_ottoman_mansion(Vector3(52, 0, 55), PI, 0)
	spawn_courtyard_garden_house(Vector3(52, 0, 70), PI, true)
	spawn_parkour_rooftop_house(Vector3(52, 0, 85), PI, Vector3.ZERO, true)
	spawn_ottoman_mansion(Vector3(66, 0, 60), 0.0, 2)
	spawn_courtyard_garden_house(Vector3(66, 0, 75), 0.0, true)
	spawn_ottoman_mansion(Vector3(66, 0, 90), 0.0, 3)

	# =========================================================================
	# 10. HİSARARDI SURLARÖNÜ & SİPAHİ MAHALLESİ (z = 86..98, x = -26..+26)
	# =========================================================================
	spawn_ottoman_mansion(Vector3(-24, 0, 88), 0.0, 1)
	spawn_courtyard_garden_house(Vector3(-8, 0, 90), 0.0, true)
	spawn_courtyard_garden_house(Vector3(8, 0, 90), 0.0, true)
	spawn_ottoman_mansion(Vector3(24, 0, 88), 0.0, 0)
	spawn_parkour_rooftop_house(Vector3(0, 0, 98), PI, Vector3.ZERO, true)

func build_mosque_courtyard_perimeter() -> void:
	var wall_mat = StandardMaterial3D.new()
	if tex_stone:
		wall_mat.albedo_texture = tex_stone
		wall_mat.uv1_scale = Vector3(4, 1.5, 4)
	else:
		wall_mat.albedo_color = Color(0.85, 0.82, 0.76)
	wall_mat.roughness = 0.85
	
	# Batı Avlu Duvarı (x = -17, z = -32'den z = -12'ye)
	var w_wall = StaticBody3D.new()
	var wcol = CollisionShape3D.new()
	var wbox = BoxShape3D.new()
	wbox.size = Vector3(0.8, 2.8, 20.0)
	wcol.shape = wbox
	wcol.position = Vector3(-17.5, 1.4, -22.0)
	w_wall.add_child(wcol)
	var wm = MeshInstance3D.new()
	var wmesh = BoxMesh.new()
	wmesh.size = Vector3(0.8, 2.8, 20.0)
	wm.mesh = wmesh
	wm.position = Vector3(-17.5, 1.4, -22.0)
	wm.set_surface_override_material(0, wall_mat)
	w_wall.add_child(wm)
	add_child(w_wall)
	
	# Doğu Avlu Duvarı (x = +17.5, z = -32'den z = -12'ye)
	var e_wall = StaticBody3D.new()
	var ecol = CollisionShape3D.new()
	var ebox = BoxShape3D.new()
	ebox.size = Vector3(0.8, 2.8, 20.0)
	ecol.shape = ebox
	ecol.position = Vector3(17.5, 1.4, -22.0)
	e_wall.add_child(ecol)
	var em = MeshInstance3D.new()
	var emesh = BoxMesh.new()
	emesh.size = Vector3(0.8, 2.8, 20.0)
	em.mesh = emesh
	em.position = Vector3(17.5, 1.4, -22.0)
	em.set_surface_override_material(0, wall_mat)
	e_wall.add_child(em)
	add_child(e_wall)

# Geriye dönük uyumluluk için alias
func spawn_ottoman_house(pos: Vector3, rot_y: float) -> void:
	spawn_ottoman_mansion(pos, rot_y, 0)

# -----------------------------------------------------------------------------
# 1. TARİHİ OSMANLI KONAĞI (Cumbası, Eli Böğründe Destekleri, Çift Kanat Kapısı)
# -----------------------------------------------------------------------------
func spawn_ottoman_mansion(pos: Vector3, rot_y: float, variant: int = 0) -> void:
	var house = StaticBody3D.new()
	house.position = pos
	house.rotation.y = rot_y
	
	# Ana Gövde Çarpışması
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(9.5, 8.5, 8.5)
	col.shape = box
	col.position.y = 4.25
	house.add_child(col)
	
	# Cumba Çarpışması (Sokağa taşan kısım)
	var c_col = CollisionShape3D.new()
	var c_box = BoxShape3D.new()
	c_box.size = Vector3(4.0, 3.2, 1.4)
	c_col.shape = c_box
	c_col.position = Vector3(0, 5.8, 4.8)
	house.add_child(c_col)
	
	# 1. Zemin Kat (Masif Kesme Taş Örgüsü)
	var ground_floor = MeshInstance3D.new()
	var g_box = BoxMesh.new()
	g_box.size = Vector3(9.0, 3.8, 8.0)
	ground_floor.mesh = g_box
	ground_floor.position.y = 1.9
	var stone_mat = StandardMaterial3D.new()
	if tex_stone:
		stone_mat.albedo_texture = tex_stone
		stone_mat.uv1_scale = Vector3(3, 1.5, 3)
	else:
		stone_mat.albedo_color = Color(0.7, 0.67, 0.62)
	stone_mat.roughness = 0.85
	ground_floor.set_surface_override_material(0, stone_mat)
	house.add_child(ground_floor)
	
	# Ahşap Çift Kanatlı Giriş Kapısı
	var door = MeshInstance3D.new()
	var d_box = BoxMesh.new()
	d_box.size = Vector3(1.8, 2.5, 0.15)
	door.mesh = d_box
	door.position = Vector3(0, 1.25, 4.05)
	var door_mat = StandardMaterial3D.new()
	if tex_wood:
		door_mat.albedo_texture = tex_wood
	door_mat.albedo_color = Color(0.28, 0.18, 0.12)
	door_mat.roughness = 0.75
	door.set_surface_override_material(0, door_mat)
	house.add_child(door)
	
	# Kapı Üstü Feneri
	var d_lamp = OmniLight3D.new()
	d_lamp.light_color = Color(1.0, 0.85, 0.5)
	d_lamp.light_energy = 1.2
	d_lamp.omni_range = 4.5
	d_lamp.position = Vector3(0, 2.8, 4.3)
	house.add_child(d_lamp)
	
	# 2. Üst Kat (Geleneksel Ahşap Cephe / Renk Varyantları)
	var upper_floor = MeshInstance3D.new()
	var u_box = BoxMesh.new()
	u_box.size = Vector3(9.6, 4.2, 8.6)
	upper_floor.mesh = u_box
	upper_floor.position = Vector3(0, 5.7, 0.3)
	var wood_mat = StandardMaterial3D.new()
	if tex_wood:
		wood_mat.albedo_texture = tex_wood
		wood_mat.uv1_scale = Vector3(2.5, 1.5, 2.5)
	
	match variant:
		0: # Klasik Aşı Boyası (Boğaziçi Kırmızısı)
			wood_mat.albedo_color = Color(0.55, 0.22, 0.18)
		1: # Safranbolu Sarısı / Hardal Sıva
			wood_mat.albedo_color = Color(0.82, 0.72, 0.52)
		2: # Koyu Meşe / Çam Ahşap
			wood_mat.albedo_color = Color(0.36, 0.26, 0.18)
		3: # Beyaz Badana
			wood_mat.albedo_color = Color(0.88, 0.86, 0.82)
	wood_mat.roughness = 0.8
	upper_floor.set_surface_override_material(0, wood_mat)
	house.add_child(upper_floor)
	
	# 3. Cumba (Sokağa Taşan Geleneksel Şahnişin)
	var cumba = MeshInstance3D.new()
	var c_mesh = BoxMesh.new()
	c_mesh.size = Vector3(3.8, 3.0, 1.2)
	cumba.mesh = c_mesh
	cumba.position = Vector3(0, 5.7, 4.8)
	cumba.set_surface_override_material(0, wood_mat)
	house.add_child(cumba)
	
	# Cumba Kafesli Pencereleri (Kafes / Maşrabiye)
	var c_window = MeshInstance3D.new()
	var cw_box = BoxMesh.new()
	cw_box.size = Vector3(3.2, 1.6, 0.08)
	c_window.mesh = cw_box
	c_window.position = Vector3(0, 5.8, 5.42)
	var win_mat = StandardMaterial3D.new()
	win_mat.albedo_color = Color(0.18, 0.22, 0.28)
	win_mat.roughness = 0.3
	win_mat.metallic = 0.2
	c_window.set_surface_override_material(0, win_mat)
	house.add_child(c_window)
	
	# Cumba Altı Eli Böğründe Destekleri (2 Adet Eğimli Ahşap Strüktür)
	var dark_timber_mat = StandardMaterial3D.new()
	dark_timber_mat.albedo_color = Color(0.24, 0.15, 0.1)
	for side in [-1.4, 1.4]:
		var bracket = MeshInstance3D.new()
		var b_box = BoxMesh.new()
		b_box.size = Vector3(0.22, 1.6, 0.22)
		bracket.mesh = b_box
		bracket.position = Vector3(side, 4.1, 4.4)
		bracket.rotation.x = -0.55
		bracket.set_surface_override_material(0, dark_timber_mat)
		house.add_child(bracket)
		
	# 4. Kırma Kiremit Çatı & Saçaklar
	var roof = MeshInstance3D.new()
	var r_prism = PrismMesh.new()
	r_prism.size = Vector3(10.8, 2.8, 10.4)
	roof.mesh = r_prism
	roof.position = Vector3(0, 9.2, 0.5)
	roof.rotation.y = PI / 2.0
	var roof_mat = StandardMaterial3D.new()
	if tex_roof:
		roof_mat.albedo_texture = tex_roof
		roof_mat.uv1_scale = Vector3(4, 3, 4)
	else:
		roof_mat.albedo_color = Color(0.68, 0.26, 0.16)
	roof_mat.roughness = 0.85
	roof.set_surface_override_material(0, roof_mat)
	house.add_child(roof)
	
	# Çatı Bacası
	var chimney = MeshInstance3D.new()
	var ch_box = BoxMesh.new()
	ch_box.size = Vector3(0.8, 2.0, 0.8)
	chimney.mesh = ch_box
	chimney.position = Vector3(2.2, 9.8, -1.0)
	chimney.set_surface_override_material(0, stone_mat)
	house.add_child(chimney)
	
	add_child(house)

# -----------------------------------------------------------------------------
# 2. AVLULU VE BAHÇELİ KONAK (Tarihi Taş Kuyu, Asma Çardağı, Sedir, Ağaç)
# -----------------------------------------------------------------------------
func spawn_courtyard_garden_house(pos: Vector3, rot_y: float, with_well: bool = true) -> void:
	var root = Node3D.new()
	root.position = pos
	root.rotation.y = rot_y
	
	# Arkada Ana Konak (Avlu gerisinde)
	var mansion_offset = Vector3(0, 0, -4.5).rotated(Vector3.UP, rot_y)
	spawn_ottoman_mansion(pos + mansion_offset, rot_y, 1)
	
	# Avlu İçi Yemyeşil Çim Zemin (Lush Garden Lawn)
	var lawn = MeshInstance3D.new()
	var l_box = BoxMesh.new()
	l_box.size = Vector3(11.8, 0.06, 9.2)
	lawn.mesh = l_box
	lawn.position = Vector3(0, 0.04, 0.5)
	var grass_mat = StandardMaterial3D.new()
	if tex_grass:
		grass_mat.albedo_texture = tex_grass
		grass_mat.uv1_scale = Vector3(3.5, 3.5, 3.5)
	else:
		grass_mat.albedo_color = Color(0.28, 0.58, 0.22)
	grass_mat.roughness = 0.88
	lawn.set_surface_override_material(0, grass_mat)
	root.add_child(lawn)
	
	# Avlu Doğal Taş Yürüme Yolu (Stepping stones)
	var stone_step_mat = StandardMaterial3D.new()
	if tex_stone:
		stone_step_mat.albedo_texture = tex_stone
		stone_step_mat.uv1_scale = Vector3(1, 1, 1)
	else:
		stone_step_mat.albedo_color = Color(0.68, 0.65, 0.6)
	stone_step_mat.roughness = 0.8
	
	for i in range(5):
		var step_stone = MeshInstance3D.new()
		var ss_box = BoxMesh.new()
		ss_box.size = Vector3(1.3, 0.06, 0.8)
		step_stone.mesh = ss_box
		step_stone.position = Vector3(0, 0.075, 4.2 - (i * 1.35))
		step_stone.set_surface_override_material(0, stone_step_mat)
		root.add_child(step_stone)
		
	if with_well:
		for i in range(3):
			var well_step = MeshInstance3D.new()
			var ws_box = BoxMesh.new()
			ws_box.size = Vector3(0.85, 0.06, 0.85)
			well_step.mesh = ws_box
			well_step.position = Vector3(0.9 + (i * 0.95), 0.075, 1.8)
			well_step.set_surface_override_material(0, stone_step_mat)
			root.add_child(well_step)
	
	# Avlu Taş Duvarları (Taş örgü & harpuşta)
	var garden_wall_mat = StandardMaterial3D.new()
	if tex_stone:
		garden_wall_mat.albedo_texture = tex_stone
		garden_wall_mat.uv1_scale = Vector3(3, 1, 3)
	else:
		garden_wall_mat.albedo_color = Color(0.75, 0.72, 0.68)
	garden_wall_mat.roughness = 0.9
	
	# Sol Avlu Duvarı
	var left_w = StaticBody3D.new()
	var l_col = CollisionShape3D.new()
	var lw_box = BoxShape3D.new()
	lw_box.size = Vector3(0.6, 2.2, 9.5)
	l_col.shape = lw_box
	l_col.position = Vector3(-6.2, 1.1, 0.5)
	left_w.add_child(l_col)
	var l_mesh = MeshInstance3D.new()
	var lm_box = BoxMesh.new()
	lm_box.size = Vector3(0.6, 2.2, 9.5)
	l_mesh.mesh = lm_box
	l_mesh.position = Vector3(-6.2, 1.1, 0.5)
	l_mesh.set_surface_override_material(0, garden_wall_mat)
	left_w.add_child(l_mesh)
	root.add_child(left_w)
	
	# Sağ Avlu Duvarı
	var right_w = StaticBody3D.new()
	var r_col = CollisionShape3D.new()
	var rw_box = BoxShape3D.new()
	rw_box.size = Vector3(0.6, 2.2, 9.5)
	r_col.shape = rw_box
	r_col.position = Vector3(6.2, 1.1, 0.5)
	right_w.add_child(r_col)
	var r_mesh = MeshInstance3D.new()
	var rm_box = BoxMesh.new()
	rm_box.size = Vector3(0.6, 2.2, 9.5)
	r_mesh.mesh = rm_box
	r_mesh.position = Vector3(6.2, 1.1, 0.5)
	r_mesh.set_surface_override_material(0, garden_wall_mat)
	right_w.add_child(r_mesh)
	root.add_child(right_w)
	
	# Ön Avlu Duvarı (Giriş kapısı açıklığı bırakılmış)
	# Sol Ön Duvar
	var f_left = StaticBody3D.new()
	var fl_col = CollisionShape3D.new()
	var fl_box = BoxShape3D.new()
	fl_box.size = Vector3(4.5, 2.2, 0.6)
	fl_col.shape = fl_box
	fl_col.position = Vector3(-3.9, 1.1, 5.0)
	f_left.add_child(fl_col)
	var fl_mesh = MeshInstance3D.new()
	var flm_box = BoxMesh.new()
	flm_box.size = Vector3(4.5, 2.2, 0.6)
	fl_mesh.mesh = flm_box
	fl_mesh.position = Vector3(-3.9, 1.1, 5.0)
	fl_mesh.set_surface_override_material(0, garden_wall_mat)
	f_left.add_child(fl_mesh)
	root.add_child(f_left)
	
	# Sağ Ön Duvar
	var f_right = StaticBody3D.new()
	var fr_col = CollisionShape3D.new()
	var fr_box = BoxShape3D.new()
	fr_box.size = Vector3(4.5, 2.2, 0.6)
	fr_col.shape = fr_box
	fr_col.position = Vector3(3.9, 1.1, 5.0)
	f_right.add_child(fr_col)
	var fr_mesh = MeshInstance3D.new()
	var frm_box = BoxMesh.new()
	frm_box.size = Vector3(4.5, 2.2, 0.6)
	fr_mesh.mesh = frm_box
	fr_mesh.position = Vector3(3.9, 1.1, 5.0)
	fr_mesh.set_surface_override_material(0, garden_wall_mat)
	f_right.add_child(fr_mesh)
	root.add_child(f_right)
	
	# Avlu Taç Cümle Kapısı (Ahşap Kemer & Kiremit Sundurma)
	var gate_roof = MeshInstance3D.new()
	var gr_prism = PrismMesh.new()
	gr_prism.size = Vector3(3.4, 0.9, 1.2)
	gate_roof.mesh = gr_prism
	gate_roof.position = Vector3(0, 3.1, 5.0)
	var roof_mat = StandardMaterial3D.new()
	if tex_roof:
		roof_mat.albedo_texture = tex_roof
	roof_mat.albedo_color = Color(0.68, 0.26, 0.16)
	gate_roof.set_surface_override_material(0, roof_mat)
	root.add_child(gate_roof)
	
	# Avlu Giriş Feneri
	var gate_lamp = OmniLight3D.new()
	gate_lamp.light_color = Color(1.0, 0.88, 0.6)
	gate_lamp.light_energy = 1.5
	gate_lamp.omni_range = 6.0
	gate_lamp.position = Vector3(0, 2.7, 5.3)
	root.add_child(gate_lamp)
	
	# --- TARİHİ TAŞ KUYU (Can ve Takat Fullleyen Etkileşimli Su Kaynağı) ---
	if with_well:
		var well = StaticBody3D.new()
		well.position = Vector3(3.2, 0, 1.8)
		if InteractivePropScript:
			well.set_script(InteractivePropScript)
			well.prop_type = "kuyu"
			well.interact_label = "💧 Tarihi Taş Kuyu (Buz Gibi Su İç - Can ve Takat Tazele)"
		
		# Kuyu Çarpışması
		var w_col = CollisionShape3D.new()
		var w_cyl = CylinderShape3D.new()
		w_cyl.radius = 1.05
		w_cyl.height = 1.1
		w_col.shape = w_cyl
		w_col.position.y = 0.55
		well.add_child(w_col)
		
		# Kuyu Taş Bileziği
		var well_stone = MeshInstance3D.new()
		var ws_cyl = CylinderMesh.new()
		ws_cyl.top_radius = 1.0
		ws_cyl.bottom_radius = 1.05
		ws_cyl.height = 0.9
		well_stone.mesh = ws_cyl
		well_stone.position.y = 0.45
		well_stone.set_surface_override_material(0, garden_wall_mat)
		well.add_child(well_stone)
		
		# Kuyu İçi Su Yüzeyi
		var water = MeshInstance3D.new()
		var wt_cyl = CylinderMesh.new()
		wt_cyl.top_radius = 0.85
		wt_cyl.bottom_radius = 0.85
		wt_cyl.height = 0.1
		water.mesh = wt_cyl
		water.position.y = 0.35
		var water_mat = StandardMaterial3D.new()
		water_mat.albedo_color = Color(0.12, 0.45, 0.65, 0.9)
		water_mat.roughness = 0.05
		water_mat.metallic = 0.3
		water.set_surface_override_material(0, water_mat)
		well.add_child(water)
		
		# Kuyu Direkleri ve Çıkrığı (Ahşap)
		var wood_dark = StandardMaterial3D.new()
		wood_dark.albedo_color = Color(0.32, 0.2, 0.12)
		for side in [-0.85, 0.85]:
			var post = MeshInstance3D.new()
			var p_cyl = CylinderMesh.new()
			p_cyl.top_radius = 0.08
			p_cyl.bottom_radius = 0.08
			p_cyl.height = 2.1
			post.mesh = p_cyl
			post.position = Vector3(side, 1.45, 0)
			post.set_surface_override_material(0, wood_dark)
			well.add_child(post)
			
		# Çıkrık Üst Kirişi
		var top_beam = MeshInstance3D.new()
		var tb_box = BoxMesh.new()
		tb_box.size = Vector3(1.9, 0.14, 0.14)
		top_beam.mesh = tb_box
		top_beam.position = Vector3(0, 2.45, 0)
		top_beam.set_surface_override_material(0, wood_dark)
		well.add_child(top_beam)
		
		# İp ve Ahşap Kova
		var bucket = MeshInstance3D.new()
		var b_cyl = CylinderMesh.new()
		b_cyl.top_radius = 0.22
		b_cyl.bottom_radius = 0.18
		b_cyl.height = 0.45
		bucket.mesh = b_cyl
		bucket.position = Vector3(0.2, 1.2, 0)
		bucket.set_surface_override_material(0, wood_dark)
		well.add_child(bucket)
		
		# Kuyu Bilgi Etiketi
		var w_label = Label3D.new()
		w_label.text = "💧 Tarihi Kuyu"
		w_label.font_size = 32
		w_label.pixel_size = 0.007
		w_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		w_label.modulate = Color(0.4, 0.85, 1.0)
		w_label.outline_size = 4
		w_label.position = Vector3(0, 2.75, 0)
		well.add_child(w_label)
		
		root.add_child(well)
		
	# --- ASMA ÇARDAĞI & GÖLGELİK PERGOLA ---
	var pergola = Node3D.new()
	pergola.position = Vector3(-3.4, 0, 1.8)
	var perg_wood = StandardMaterial3D.new()
	perg_wood.albedo_color = Color(0.38, 0.24, 0.15)
	
	# 4 Direk
	for dx in [-1.4, 1.4]:
		for dz in [-1.4, 1.4]:
			var colm = MeshInstance3D.new()
			var c_box = BoxMesh.new()
			c_box.size = Vector3(0.16, 2.6, 0.16)
			colm.mesh = c_box
			colm.position = Vector3(dx, 1.3, dz)
			colm.set_surface_override_material(0, perg_wood)
			pergola.add_child(colm)
			
	# Çardak Üst Sarmaşık Yeşilliği (Asma Yaprakları)
	var vine_roof = MeshInstance3D.new()
	var vr_box = BoxMesh.new()
	vr_box.size = Vector3(3.2, 0.25, 3.2)
	vine_roof.mesh = vr_box
	vine_roof.position = Vector3(0, 2.6, 0)
	var vine_mat = StandardMaterial3D.new()
	vine_mat.albedo_color = Color(0.22, 0.48, 0.18)
	vine_mat.roughness = 0.9
	vine_roof.set_surface_override_material(0, vine_mat)
	pergola.add_child(vine_roof)
	
	# Çardak Altı Ahşap Sedir / Peyke
	var bench = StaticBody3D.new()
	var b_col = CollisionShape3D.new()
	var bc_box = BoxShape3D.new()
	bc_box.size = Vector3(2.4, 0.6, 0.9)
	b_col.shape = bc_box
	b_col.position = Vector3(0, 0.3, -0.7)
	bench.add_child(b_col)
	var b_mesh = MeshInstance3D.new()
	var bm_box = BoxMesh.new()
	bm_box.size = Vector3(2.4, 0.6, 0.9)
	b_mesh.mesh = bm_box
	b_mesh.position = Vector3(0, 0.3, -0.7)
	b_mesh.set_surface_override_material(0, perg_wood)
	bench.add_child(b_mesh)
	pergola.add_child(bench)
	
	root.add_child(pergola)
	
	# Bahçe İçi Küçük Meyve Ağacı
	var tree = Node3D.new()
	tree.position = Vector3(3.8, 0, -1.8)
	var trunk = MeshInstance3D.new()
	var tr_cyl = CylinderMesh.new()
	tr_cyl.top_radius = 0.14
	tr_cyl.bottom_radius = 0.22
	tr_cyl.height = 2.4
	trunk.mesh = tr_cyl
	trunk.position.y = 1.2
	trunk.set_surface_override_material(0, perg_wood)
	tree.add_child(trunk)
	var foliage = MeshInstance3D.new()
	var fol_sph = SphereMesh.new()
	fol_sph.radius = 1.4
	fol_sph.height = 2.4
	foliage.mesh = fol_sph
	foliage.position.y = 2.8
	var fol_mat = StandardMaterial3D.new()
	fol_mat.albedo_color = Color(0.25, 0.52, 0.2)
	foliage.set_surface_override_material(0, fol_mat)
	tree.add_child(foliage)
	root.add_child(tree)
	
	# Avlu İçi 3D Çim Tutamları (Volumetric Grass Tufts)
	var tuft_positions = [
		Vector3(-4.8, 0.07, 4.0), Vector3(4.8, 0.07, 4.0),
		Vector3(-5.2, 0.07, -0.5), Vector3(5.2, 0.07, -0.5),
		Vector3(2.2, 0.07, 1.2), Vector3(4.2, 0.07, 2.4),
		Vector3(-2.2, 0.07, 2.8), Vector3(-4.5, 0.07, 2.8),
		Vector3(3.2, 0.07, -2.6), Vector3(4.5, 0.07, -1.2)
	]
	for tpos in tuft_positions:
		root.add_child(spawn_grass_tuft(tpos, randf_range(0.85, 1.25)))
		
	add_child(root)

# -----------------------------------------------------------------------------
# 3. TIKANMAZ PARKUR & ÇATI KONAĞI (Kasa/Fıçı, Merdiven Rampası, Zula & Köprüler)
# -----------------------------------------------------------------------------
func spawn_parkour_rooftop_house(pos: Vector3, rot_y: float, bridge_target: Vector3 = Vector3.ZERO, has_chest: bool = true) -> void:
	var house = StaticBody3D.new()
	house.position = pos
	house.rotation.y = rot_y
	
	# Ana Zemin Kat
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(9.2, 4.0, 8.2)
	col.shape = box
	col.position.y = 2.0
	house.add_child(col)
	
	var ground_mesh = MeshInstance3D.new()
	var gm_box = BoxMesh.new()
	gm_box.size = Vector3(9.2, 4.0, 8.2)
	ground_mesh.mesh = gm_box
	ground_mesh.position.y = 2.0
	var stone_mat = StandardMaterial3D.new()
	if tex_stone:
		stone_mat.albedo_texture = tex_stone
		stone_mat.uv1_scale = Vector3(3, 1.5, 3)
	else:
		stone_mat.albedo_color = Color(0.72, 0.68, 0.62)
	stone_mat.roughness = 0.85
	ground_mesh.set_surface_override_material(0, stone_mat)
	house.add_child(ground_mesh)
	
	# 2. Kat (Yarısı Kapalı Oda, Yarısı Açık Çatı Terası)
	# Kapalı Oda Bölümü (x: -4.6'dan 0'a)
	var room_col = CollisionShape3D.new()
	var rc_box = BoxShape3D.new()
	rc_box.size = Vector3(4.8, 3.4, 8.2)
	room_col.shape = rc_box
	room_col.position = Vector3(-2.2, 5.7, 0)
	house.add_child(room_col)
	
	var room_mesh = MeshInstance3D.new()
	var rm_box = BoxMesh.new()
	rm_box.size = Vector3(4.8, 3.4, 8.2)
	room_mesh.mesh = rm_box
	room_mesh.position = Vector3(-2.2, 5.7, 0)
	var wood_mat = StandardMaterial3D.new()
	if tex_wood:
		wood_mat.albedo_texture = tex_wood
	wood_mat.albedo_color = Color(0.48, 0.32, 0.2)
	wood_mat.roughness = 0.8
	room_mesh.set_surface_override_material(0, wood_mat)
	house.add_child(room_mesh)
	
	# Oda Çatısı
	var room_roof = MeshInstance3D.new()
	var rr_prism = PrismMesh.new()
	rr_prism.size = Vector3(5.2, 2.2, 8.6)
	room_roof.mesh = rr_prism
	room_roof.position = Vector3(-2.2, 8.2, 0)
	room_roof.rotation.y = PI / 2.0
	var roof_mat = StandardMaterial3D.new()
	if tex_roof:
		roof_mat.albedo_texture = tex_roof
	roof_mat.albedo_color = Color(0.68, 0.26, 0.16)
	room_roof.set_surface_override_material(0, roof_mat)
	house.add_child(room_roof)
	
	# --- AÇIK ÇATI TERASI (y = 4.0 taban, y = 4.2 yürüme seviyesi) ---
	var terrace_floor = MeshInstance3D.new()
	var tf_box = BoxMesh.new()
	tf_box.size = Vector3(4.6, 0.4, 8.2)
	terrace_floor.mesh = tf_box
	terrace_floor.position = Vector3(2.3, 4.0, 0)
	var floor_mat = StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.38, 0.25, 0.16)
	terrace_floor.set_surface_override_material(0, floor_mat)
	house.add_child(terrace_floor)
	
	# Çatı Terası Ahşap Korkulukları (Düşmeyi engelleyen estetik korkuluk)
	var dark_timber = StandardMaterial3D.new()
	dark_timber.albedo_color = Color(0.24, 0.15, 0.1)
	for side in [Vector3(4.5, 4.7, 0), Vector3(2.3, 4.7, 4.0), Vector3(2.3, 4.7, -4.0)]:
		var rail = MeshInstance3D.new()
		var r_box = BoxMesh.new()
		if side.x > 3.0:
			r_box.size = Vector3(0.15, 1.0, 8.0)
		else:
			r_box.size = Vector3(4.4, 1.0, 0.15)
		rail.mesh = r_box
		rail.position = side
		rail.set_surface_override_material(0, dark_timber)
		house.add_child(rail)
		
	# --- PARKUR 1. ETAP: YERDEN ODUNLUK ÇATISINA TIRMANIŞ ---
	# Sokakta İstifli Ahşap Sandıklar ve Fıçı
	# Kasa 1: Yükseklik 0.85m (Yerden ilk zıplama basamağı)
	var crate1 = StaticBody3D.new()
	var c1_col = CollisionShape3D.new()
	var c1_box = BoxShape3D.new()
	c1_box.size = Vector3(1.2, 0.85, 1.2)
	c1_col.shape = c1_box
	c1_col.position = Vector3(5.4, 0.425, -2.8)
	crate1.add_child(c1_col)
	var c1_mesh = MeshInstance3D.new()
	var c1m_box = BoxMesh.new()
	c1m_box.size = Vector3(1.2, 0.85, 1.2)
	c1_mesh.mesh = c1m_box
	c1_mesh.position = Vector3(5.4, 0.425, -2.8)
	c1_mesh.set_surface_override_material(0, floor_mat)
	crate1.add_child(c1_mesh)
	house.add_child(crate1)
	
	# Kasa 2: Yükseklik 1.7m (İkinci tırmanış basamağı)
	var crate2 = StaticBody3D.new()
	var c2_col = CollisionShape3D.new()
	var c2_box = BoxShape3D.new()
	c2_box.size = Vector3(1.1, 0.85, 1.1)
	c2_col.shape = c2_box
	c2_col.position = Vector3(5.4, 1.275, -1.6)
	crate2.add_child(c2_col)
	var c2_mesh = MeshInstance3D.new()
	var c2m_box = BoxMesh.new()
	c2m_box.size = Vector3(1.1, 0.85, 1.1)
	c2_mesh.mesh = c2m_box
	c2_mesh.position = Vector3(5.4, 1.275, -1.6)
	c2_mesh.set_surface_override_material(0, floor_mat)
	crate2.add_child(c2_mesh)
	house.add_child(crate2)
	
	# Bitişik Yan Odunluk Sundurması (Yükseklik 2.5m - Düz Ahşap Çatı)
	var shed = StaticBody3D.new()
	var s_col = CollisionShape3D.new()
	var s_box = BoxShape3D.new()
	s_box.size = Vector3(2.4, 2.5, 3.2)
	s_col.shape = s_box
	s_col.position = Vector3(5.4, 1.25, 1.2)
	shed.add_child(s_col)
	var s_mesh = MeshInstance3D.new()
	var sm_box = BoxMesh.new()
	sm_box.size = Vector3(2.4, 2.5, 3.2)
	s_mesh.mesh = sm_box
	s_mesh.position = Vector3(5.4, 1.25, 1.2)
	s_mesh.set_surface_override_material(0, dark_timber)
	shed.add_child(s_mesh)
	house.add_child(shed)
	
	# --- PARKUR 2. ETAP: ODUNLUKTAN ÇATI TERASINA TIRMANMA MERDİVENİ ---
	# Kesintisiz yürünebilir görünmez rampa + Ahşap basamak ve yan korkuluklar
	# Odunluk çatısı (y = 2.5, z = 1.8) -> Çatı terası (y = 4.2, z = 3.6)
	var ladder = StaticBody3D.new()
	# Akıcı Yürüme Rampası (Karakterin basamaklara takılmadan koşarak çıkmasını sağlar)
	var ramp_col = CollisionShape3D.new()
	var ramp_box = BoxShape3D.new()
	ramp_box.size = Vector3(1.2, 0.2, 2.6)
	ramp_col.shape = ramp_box
	ramp_col.position = Vector3(4.4, 3.35, 2.7)
	ramp_col.rotation.x = -0.62 # Eğim açısı (~35.5 derece)
	ladder.add_child(ramp_col)
	
	# Görsel Merdiven Kolları ve 6 Basamak
	for step in range(6):
		var t = float(step) / 5.0
		var rung = MeshInstance3D.new()
		var r_box = BoxMesh.new()
		r_box.size = Vector3(1.0, 0.08, 0.22)
		rung.mesh = r_box
		rung.position = Vector3(4.4, lerp(2.55, 4.15, t), lerp(1.7, 3.6, t))
		rung.set_surface_override_material(0, floor_mat)
		ladder.add_child(rung)
		
	# Merdiven Yan Ahşap Korkulukları
	for side_x in [3.85, 4.95]:
		var rail_side = MeshInstance3D.new()
		var rs_box = BoxMesh.new()
		rs_box.size = Vector3(0.08, 0.12, 2.7)
		rail_side.mesh = rs_box
		rail_side.position = Vector3(side_x, 3.45, 2.65)
		rail_side.rotation.x = -0.62
		rail_side.set_surface_override_material(0, dark_timber)
		ladder.add_child(rail_side)
	house.add_child(ladder)
	
	# --- PARKUR 3. ETAP: ÇATI ZULASI / GÖZCÜ NOKTASI ---
	if has_chest:
		# Teşkilât-ı Mahsusa Gizli Çatı Zulası
		var zula = StaticBody3D.new()
		zula.position = Vector3(1.2, 4.2, -2.6)
		if InteractivePropScript:
			zula.set_script(InteractivePropScript)
			zula.prop_type = "zula"
			zula.interact_label = "📦 Teşkilât Çatı Zulası (Cephane & İstihbarat Al)"
		var z_col = CollisionShape3D.new()
		var z_box = BoxShape3D.new()
		z_box.size = Vector3(1.1, 0.8, 0.8)
		z_col.shape = z_box
		z_col.position.y = 0.4
		zula.add_child(z_col)
		
		# Sandık Gövdesi
		var z_mesh = MeshInstance3D.new()
		var zm_box = BoxMesh.new()
		zm_box.size = Vector3(1.1, 0.7, 0.7)
		z_mesh.mesh = zm_box
		z_mesh.position.y = 0.35
		var chest_mat = StandardMaterial3D.new()
		chest_mat.albedo_color = Color(0.28, 0.16, 0.08)
		z_mesh.set_surface_override_material(0, chest_mat)
		zula.add_child(z_mesh)
		
		# Pirinç Kilit ve Köşebentler
		var brass = MeshInstance3D.new()
		var br_box = BoxMesh.new()
		br_box.size = Vector3(0.18, 0.22, 0.1)
		brass.mesh = br_box
		brass.position = Vector3(0, 0.45, 0.36)
		var brass_mat = StandardMaterial3D.new()
		brass_mat.albedo_color = Color(0.9, 0.75, 0.25)
		brass_mat.metallic = 0.8
		brass.set_surface_override_material(0, brass_mat)
		zula.add_child(brass)
		
		# Zula Bilgi Etiketi
		var z_label = Label3D.new()
		z_label.text = "📦 Teşkilât Zulası"
		z_label.font_size = 28
		z_label.pixel_size = 0.007
		z_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		z_label.modulate = Color(1.0, 0.8, 0.3)
		z_label.outline_size = 4
		z_label.position = Vector3(0, 1.1, 0)
		zula.add_child(z_label)
		
		house.add_child(zula)
	else:
		# Çatı Gözcü Noktası
		var scout = StaticBody3D.new()
		scout.position = Vector3(1.5, 4.2, 2.5)
		if InteractivePropScript:
			scout.set_script(InteractivePropScript)
			scout.prop_type = "gozcu"
			scout.interact_label = "🦅 Çatı Gözcü Noktası (Payitahtı Teftiş Et)"
		var sc_col = CollisionShape3D.new()
		var sc_box = BoxShape3D.new()
		sc_box.size = Vector3(1.2, 1.2, 1.2)
		sc_col.shape = sc_box
		sc_col.position.y = 0.6
		scout.add_child(sc_col)
		
		var sc_label = Label3D.new()
		sc_label.text = "🦅 Gözcü Noktası"
		sc_label.font_size = 28
		sc_label.pixel_size = 0.007
		sc_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sc_label.modulate = Color(0.9, 0.9, 0.4)
		sc_label.outline_size = 4
		sc_label.position = Vector3(0, 1.4, 0)
		scout.add_child(sc_label)
		
		house.add_child(scout)
		
	add_child(house)
	
	# --- PARKUR 4. ETAP: ÇATIDAN ÇATIYA GEÇİŞ KÖPRÜSÜ (SKYBRIDGE) ---
	if bridge_target != Vector3.ZERO:
		var bridge_start = pos + Vector3(0, 4.2, 0)
		var bridge_diff = bridge_target - bridge_start
		var bridge_dist = bridge_diff.length()
		if bridge_dist > 1.0:
			var bridge = StaticBody3D.new()
			var br_col = CollisionShape3D.new()
			var brc_box = BoxShape3D.new()
			brc_box.size = Vector3(1.4, 0.25, bridge_dist)
			br_col.shape = brc_box
			br_col.position = Vector3(0, 0, bridge_dist * 0.5)
			bridge.add_child(br_col)
			
			var br_mesh = MeshInstance3D.new()
			var brm_box = BoxMesh.new()
			brm_box.size = Vector3(1.4, 0.2, bridge_dist)
			br_mesh.mesh = brm_box
			br_mesh.position = Vector3(0, 0, bridge_dist * 0.5)
			br_mesh.set_surface_override_material(0, floor_mat)
			bridge.add_child(br_mesh)
			
			# İki Yanda Halat / Ahşap Korkuluk
			for side_x in [-0.65, 0.65]:
				var rope = MeshInstance3D.new()
				var rp_box = BoxMesh.new()
				rp_box.size = Vector3(0.08, 0.8, bridge_dist)
				rope.mesh = rp_box
				rope.position = Vector3(side_x, 0.4, bridge_dist * 0.5)
				rope.set_surface_override_material(0, dark_timber)
				bridge.add_child(rope)
				
			add_child(bridge)
			bridge.global_position = bridge_start
			bridge.look_at(bridge_target, Vector3.UP)



func build_city_props() -> void:
	var lamp_positions = [
		Vector3(-8, 0, 5), Vector3(8, 0, 5),
		Vector3(-8, 0, -12), Vector3(8, 0, -12),
		Vector3(12, 0, -8), Vector3(-12, 0, 18),
		Vector3(-4, 0, 20), Vector3(4, 0, 20)
	]
	for p in lamp_positions:
		spawn_street_lamp(p)

func spawn_street_lamp(pos: Vector3) -> void:
	var lamp = Node3D.new()
	lamp.position = pos
	
	var pole = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.06
	cyl.bottom_radius = 0.1
	cyl.height = 3.5
	pole.mesh = cyl
	pole.position.y = 1.75
	var iron_mat = StandardMaterial3D.new()
	iron_mat.albedo_color = Color(0.18, 0.2, 0.22)
	iron_mat.metallic = 0.8
	pole.set_surface_override_material(0, iron_mat)
	lamp.add_child(pole)
	
	var lantern = MeshInstance3D.new()
	var l_box = BoxMesh.new()
	l_box.size = Vector3(0.4, 0.5, 0.4)
	lantern.mesh = l_box
	lantern.position.y = 3.6
	lantern.set_surface_override_material(0, iron_mat)
	lamp.add_child(lantern)
	
	var light = OmniLight3D.new()
	light.light_color = Color(1.0, 0.85, 0.5)
	light.light_energy = 2.5
	light.omni_range = 8.0
	light.position.y = 3.6
	lamp.add_child(light)
	
	add_child(lamp)

func spawn_historic_street_lantern(pos: Vector3) -> void:
	spawn_street_lamp(pos)

func spawn_imam_npc(pos: Vector3) -> void:
	var imam_scene = load("res://scenes/imam_npc.tscn")
	if imam_scene:
		var imam = imam_scene.instantiate()
		imam.position = pos
		add_child(imam)

# =============================================================================
# TARİHİ PAYİTAHT YEŞİL ALANLARI, CAMİ HAZİRESİ & GÜL BAHÇELERİ
# =============================================================================
func build_city_greenery_and_gardens() -> void:
	# 1. CAMİ-İ KEBÎR HAZİRESİ VE SERVİ BAHÇESİ (Mosque Historic Hazire & Cypresses)
	var hazire_mat = StandardMaterial3D.new()
	if tex_grass:
		hazire_mat.albedo_texture = tex_grass
		hazire_mat.uv1_scale = Vector3(4, 10, 4)
	else:
		hazire_mat.albedo_color = Color(0.28, 0.58, 0.22)
	hazire_mat.roughness = 0.88
	
	var curb_mat = StandardMaterial3D.new()
	if tex_stone:
		curb_mat.albedo_texture = tex_stone
		curb_mat.uv1_scale = Vector3(1, 8, 1)
	else:
		curb_mat.albedo_color = Color(0.72, 0.7, 0.65)
	curb_mat.roughness = 0.85

	# Batı Cami Haziresi (x = -22.5, z = -43 civarı)
	var w_garden = Node3D.new()
	w_garden.position = Vector3(-22.5, 0, -43)
	
	# Çim Yatağı
	var wg_mesh = MeshInstance3D.new()
	var wgm_box = BoxMesh.new()
	wgm_box.size = Vector3(7.5, 0.12, 22.0)
	wg_mesh.mesh = wgm_box
	wg_mesh.position.y = 0.06
	wg_mesh.set_surface_override_material(0, hazire_mat)
	w_garden.add_child(wg_mesh)
	
	# Taş Bordür / Harpuşta
	var wb_mesh = MeshInstance3D.new()
	var wbm_box = BoxMesh.new()
	wbm_box.size = Vector3(8.0, 0.22, 22.5)
	wb_mesh.mesh = wbm_box
	wb_mesh.position.y = 0.04
	wb_mesh.set_surface_override_material(0, curb_mat)
	w_garden.add_child(wb_mesh)
	
	# Batı Hazire Mezar Taşları & Akdeniz Servileri
	for z_off in [-8.0, -3.0, 2.5, 7.5]:
		w_garden.add_child(spawn_cypress_tree(Vector3(-2.2, 0, z_off)))
		w_garden.add_child(spawn_hazire_tombstone(Vector3(1.2, 0, z_off - 1.2), true))
		w_garden.add_child(spawn_hazire_tombstone(Vector3(1.4, 0, z_off + 1.2), false))
		w_garden.add_child(spawn_rose_bush(Vector3(-0.4, 0, z_off), Color(0.88, 0.18, 0.25)))
		# 3D Çim Tutamları
		for dx in [-1.5, 0.0, 1.5]:
			w_garden.add_child(spawn_grass_tuft(Vector3(dx, 0.12, z_off + randf_range(-0.8, 0.8)), 1.1))
	add_child(w_garden)

	# Doğu Cami Bahçesi & Gülzâr (x = 22.5, z = -43 civarı)
	var e_garden = Node3D.new()
	e_garden.position = Vector3(22.5, 0, -43)
	
	var eg_mesh = MeshInstance3D.new()
	var egm_box = BoxMesh.new()
	egm_box.size = Vector3(7.5, 0.12, 22.0)
	eg_mesh.mesh = egm_box
	eg_mesh.position.y = 0.06
	eg_mesh.set_surface_override_material(0, hazire_mat)
	e_garden.add_child(eg_mesh)
	
	var eb_mesh = MeshInstance3D.new()
	var ebm_box = BoxMesh.new()
	ebm_box.size = Vector3(8.0, 0.22, 22.5)
	eb_mesh.mesh = ebm_box
	eb_mesh.position.y = 0.04
	eb_mesh.set_surface_override_material(0, curb_mat)
	e_garden.add_child(eb_mesh)
	
	for z_off in [-8.0, -3.0, 2.5, 7.5]:
		e_garden.add_child(spawn_cypress_tree(Vector3(2.2, 0, z_off)))
		e_garden.add_child(spawn_rose_bush(Vector3(-1.0, 0, z_off - 1.0), Color(0.95, 0.85, 0.2))) # Sarı güller
		e_garden.add_child(spawn_rose_bush(Vector3(0.8, 0, z_off + 1.0), Color(0.88, 0.18, 0.25))) # Kırmızı güller
		for dx in [-1.5, 0.5, 1.8]:
			e_garden.add_child(spawn_grass_tuft(Vector3(dx, 0.12, z_off + randf_range(-0.7, 0.7)), 1.15))
	add_child(e_garden)

	# 2. ÇINARALTI KIRAATHANESİ BAHÇE ÇİMLENDİRMESİ
	# Asırlık çınarların dibinde yeşil çim adası
	for tree_p in [Vector3(14.0, 0, -3.5), Vector3(14.0, 0, -11.0)]:
		var t_bed = Node3D.new()
		t_bed.position = tree_p
		
		# Taş Çember
		var t_curb = MeshInstance3D.new()
		var tc_cyl = CylinderMesh.new()
		tc_cyl.top_radius = 2.4
		tc_cyl.bottom_radius = 2.5
		tc_cyl.height = 0.18
		t_curb.mesh = tc_cyl
		t_curb.position.y = 0.09
		t_curb.set_surface_override_material(0, curb_mat)
		t_bed.add_child(t_curb)
		
		# İçi Çim Dolgusu
		var t_lawn = MeshInstance3D.new()
		var tl_cyl = CylinderMesh.new()
		tl_cyl.top_radius = 2.3
		tl_cyl.bottom_radius = 2.3
		tl_cyl.height = 0.2
		t_lawn.mesh = tl_cyl
		t_lawn.position.y = 0.11
		t_lawn.set_surface_override_material(0, hazire_mat)
		t_bed.add_child(t_lawn)
		
		# Ağaç etrafında 3D çim tutamları
		for angle in [0.0, 1.2, 2.4, 3.6, 4.8]:
			var rx = cos(angle) * 1.5
			var rz = sin(angle) * 1.5
			t_bed.add_child(spawn_grass_tuft(Vector3(rx, 0.21, rz), 1.2))
			
		add_child(t_bed)

	# 3. MEYDAN ŞADIRVAN & SARAY ARABASI ÇİÇEKLİKLERİ
	var planter_coords = [
		Vector3(-5.5, 0, -18), Vector3(5.5, 0, -18),
		Vector3(-5.5, 0, -12), Vector3(5.5, 0, -12),
		Vector3(-14.0, 0, 8.0), Vector3(-22.0, 0, 8.0)
	]
	for pcoord in planter_coords:
		var planter = Node3D.new()
		planter.position = pcoord
		
		var p_box = MeshInstance3D.new()
		var pb_mesh = BoxMesh.new()
		pb_mesh.size = Vector3(1.8, 0.45, 1.8)
		p_box.mesh = pb_mesh
		p_box.position.y = 0.225
		p_box.set_surface_override_material(0, curb_mat)
		planter.add_child(p_box)
		
		var p_soil = MeshInstance3D.new()
		var ps_mesh = BoxMesh.new()
		ps_mesh.size = Vector3(1.6, 0.08, 1.6)
		p_soil.mesh = ps_mesh
		p_soil.position.y = 0.45
		p_soil.set_surface_override_material(0, hazire_mat)
		planter.add_child(p_soil)
		
		# Çiçeklik içi gül ve 3D çim
		planter.add_child(spawn_rose_bush(Vector3(0, 0.45, 0), Color(0.9, 0.2, 0.3)))
		planter.add_child(spawn_grass_tuft(Vector3(-0.4, 0.47, -0.4), 0.9))
		planter.add_child(spawn_grass_tuft(Vector3(0.4, 0.47, 0.4), 0.9))
		
		add_child(planter)

# Asil Osmanlı Akdeniz Servisi (Cupressus Sempervirens)
func spawn_cypress_tree(pos: Vector3) -> Node3D:
	var cypress = StaticBody3D.new()
	cypress.position = pos
	
	# Gövde Çarpışması
	var ccol = CollisionShape3D.new()
	var cyl_shape = CylinderShape3D.new()
	cyl_shape.radius = 0.3
	cyl_shape.height = 3.0
	ccol.shape = cyl_shape
	ccol.position.y = 1.5
	cypress.add_child(ccol)
	
	# Ağaç Gövdesi
	var trunk = MeshInstance3D.new()
	var tr_cyl = CylinderMesh.new()
	tr_cyl.top_radius = 0.22
	tr_cyl.bottom_radius = 0.38
	tr_cyl.height = 3.2
	trunk.mesh = tr_cyl
	trunk.position.y = 1.6
	var trunk_mat = StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(0.28, 0.2, 0.15)
	trunk_mat.roughness = 0.9
	trunk.set_surface_override_material(0, trunk_mat)
	cypress.add_child(trunk)
	
	# Koyu Yeşil Servi Yaprak Konisi (3 Katmanlı Zarif Servi Formu)
	var leaf_mat = StandardMaterial3D.new()
	leaf_mat.albedo_color = Color(0.12, 0.32, 0.15)
	leaf_mat.roughness = 0.85
	
	var layers = [
		[Vector3(0, 4.2, 0), 1.25, 3.8],
		[Vector3(0, 6.4, 0), 1.0, 3.4],
		[Vector3(0, 8.2, 0), 0.65, 2.8]
	]
	for l in layers:
		var cone = MeshInstance3D.new()
		var c_cyl = CylinderMesh.new()
		c_cyl.top_radius = 0.05
		c_cyl.bottom_radius = l[1]
		c_cyl.height = l[2]
		cone.mesh = c_cyl
		cone.position = l[0]
		cone.set_surface_override_material(0, leaf_mat)
		cypress.add_child(cone)
		
	return cypress

# Tarihi Osmanlı Sarıklı Mezar Taşı (Hazire Şahidesi)
func spawn_hazire_tombstone(pos: Vector3, has_turban: bool = true) -> Node3D:
	var stone = StaticBody3D.new()
	stone.position = pos
	stone.rotation.y = randf_range(-0.25, 0.25)
	
	var marble_mat = StandardMaterial3D.new()
	marble_mat.albedo_color = Color(0.86, 0.85, 0.82)
	marble_mat.roughness = 0.7
	
	# Kaide
	var base = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(0.55, 0.2, 0.55)
	base.mesh = b_box
	base.position.y = 0.1
	base.set_surface_override_material(0, marble_mat)
	stone.add_child(base)
	
	# Mezar Gövde Şahidesi (Kitabeli Dikdörtgen Dikilitaş)
	var body = MeshInstance3D.new()
	var bd_box = BoxMesh.new()
	bd_box.size = Vector3(0.38, 1.45, 0.18)
	body.mesh = bd_box
	body.position.y = 0.85
	body.set_surface_override_material(0, marble_mat)
	stone.add_child(body)
	
	# Başlık: Sarıklı / Kavuklu veya Kandilli Başlık
	if has_turban:
		var turban = MeshInstance3D.new()
		var t_cyl = CylinderMesh.new()
		t_cyl.top_radius = 0.26
		t_cyl.bottom_radius = 0.22
		t_cyl.height = 0.35
		turban.mesh = t_cyl
		turban.position.y = 1.68
		turban.set_surface_override_material(0, marble_mat)
		stone.add_child(turban)
		
		# Sarık Tepeliği
		var top_cap = MeshInstance3D.new()
		var tc_sph = SphereMesh.new()
		tc_sph.radius = 0.12
		tc_sph.height = 0.2
		top_cap.mesh = tc_sph
		top_cap.position.y = 1.88
		top_cap.set_surface_override_material(0, marble_mat)
		stone.add_child(top_cap)
	else:
		# Palmet / Çiçek Rölyefli Kadın Şahidesi Tacı
		var finial = MeshInstance3D.new()
		var f_prism = PrismMesh.new()
		f_prism.size = Vector3(0.38, 0.35, 0.18)
		finial.mesh = f_prism
		finial.position.y = 1.68
		finial.set_surface_override_material(0, marble_mat)
		stone.add_child(finial)
		
	return stone

# Payitaht Gül Çalısı (Rose Bush with Flowering Blooms)
func spawn_rose_bush(pos: Vector3, flower_color: Color = Color(0.85, 0.15, 0.22)) -> Node3D:
	var bush = Node3D.new()
	bush.position = pos
	
	# Yeşil Çalı Gövdesi
	var bush_mesh = MeshInstance3D.new()
	var b_sph = SphereMesh.new()
	b_sph.radius = 0.55
	b_sph.height = 0.75
	bush_mesh.mesh = b_sph
	bush_mesh.position.y = 0.38
	var b_mat = StandardMaterial3D.new()
	b_mat.albedo_color = Color(0.2, 0.46, 0.16)
	b_mat.roughness = 0.85
	bush_mesh.set_surface_override_material(0, b_mat)
	bush.add_child(bush_mesh)
	
	# Çiçek Açan Gül Başları
	var f_mat = StandardMaterial3D.new()
	f_mat.albedo_color = flower_color
	f_mat.roughness = 0.4
	
	var flower_offsets = [
		Vector3(-0.25, 0.55, 0.18), Vector3(0.22, 0.62, -0.15),
		Vector3(-0.1, 0.68, -0.22), Vector3(0.28, 0.48, 0.2),
		Vector3(0.0, 0.72, 0.05)
	]
	for foff in flower_offsets:
		var rose = MeshInstance3D.new()
		var r_sph = SphereMesh.new()
		r_sph.radius = 0.09
		r_sph.height = 0.14
		rose.mesh = r_sph
		rose.position = foff
		rose.set_surface_override_material(0, f_mat)
		bush.add_child(rose)
		
	return bush

# =============================================================================
# TARİHİ PAYİTAHT TEPELERİ, DAĞLAR & ÇEVRE DOĞASI (Rolling Hills & Windmill)
# =============================================================================
func build_perimeter_hills_and_nature() -> void:
	var mountain_mat = StandardMaterial3D.new()
	mountain_mat.vertex_color_use_as_albedo = true
	mountain_mat.roughness = 0.92
	mountain_mat.cull_mode = BaseMaterial3D.CULL_BACK
	
	# Şehri çevreleyen yakındaki sarp Osmanlı tepeleri ve dağları
	# [Pozisyon, Vector3(genişlik_x, yükseklik, genişlik_z), seed_val, is_plateau]
	var mountain_configs = [
		# Kuzey Haliç Dağ Silsilesi (Cami-i Kebîr arkası sarp kayalık doruklar)
		[Vector3(-52, -1, -100), Vector3(56, 26, 52), 1.2, false],
		[Vector3(0, 0, -118), Vector3(68, 34, 60), 2.5, false], # Kuzey Ana Zirve
		[Vector3(56, -1, -105), Vector3(54, 28, 50), 3.8, false],
		
		# Batı Sırtları (Yel Değirmeni Dağı ve sarp kayalıklar)
		[Vector3(-102, -1, -55), Vector3(58, 28, 54), 4.1, false],
		[Vector3(-110, 0, 5), Vector3(68, 25, 62), 5.7, true],   # Yel Değirmeni Platosu (Dengeli oturma alanı)
		[Vector3(-104, -1, 62), Vector3(56, 26, 52), 6.3, false],
		
		# Güney Yamaçları (Hisar Kulesi Tepesi & Kapalıçarşı ardı dağ sırtları)
		[Vector3(-60, -1, 116), Vector3(60, 27, 56), 7.2, false],
		[Vector3(0, 0, 126), Vector3(72, 28, 66), 8.1, true],    # Hisar Gözetleme Tepesi
		[Vector3(62, -1, 118), Vector3(58, 26, 54), 9.4, false],
		
		# Doğu Gölet & Boğaz Ardı Sarp Sırtları
		[Vector3(108, -1, -45), Vector3(56, 26, 52), 10.5, false],
		[Vector3(116, 0, 18), Vector3(64, 30, 58), 11.8, false],  # Doğu Sivri Doruğu
		[Vector3(102, -1, 72), Vector3(54, 25, 50), 12.6, false],
		
		# --- UFUK SIRADAĞLARI (Distant Majestic Mountain Backdrop) ---
		# Kuzey Ufuk Zinciri (Heybetli sıradağ silueti)
		[Vector3(-80, -2, -165), Vector3(95, 48, 80), 13.1, false],
		[Vector3(0, -2, -178), Vector3(110, 58, 90), 14.5, false],
		[Vector3(85, -2, -168), Vector3(100, 52, 85), 15.9, false],
		
		# Batı Ufuk Zinciri
		[Vector3(-170, -2, -60), Vector3(90, 46, 80), 16.4, false],
		[Vector3(-175, -2, 20), Vector3(105, 54, 88), 17.8, false],
		[Vector3(-165, -2, 95), Vector3(92, 45, 78), 18.2, false],
		
		# Güney Ufuk Zinciri
		[Vector3(-85, -2, 175), Vector3(95, 48, 82), 19.3, false],
		[Vector3(15, -2, 185), Vector3(110, 55, 90), 20.7, false],
		[Vector3(95, -2, 172), Vector3(98, 46, 80), 21.1, false],
		
		# Doğu Ufuk Zinciri
		[Vector3(170, -2, -55), Vector3(95, 48, 80), 22.4, false],
		[Vector3(178, -2, 25), Vector3(108, 56, 88), 23.6, false],
		[Vector3(165, -2, 100), Vector3(90, 44, 76), 24.9, false]
	]
	
	for m_cfg in mountain_configs:
		var pos: Vector3 = m_cfg[0]
		var dims: Vector3 = m_cfg[1]
		var seed_v: float = m_cfg[2]
		var is_plat: bool = m_cfg[3]
		
		var m_body = StaticBody3D.new()
		m_body.position = pos
		
		var m_mesh_inst = MeshInstance3D.new()
		var craggy_mesh = create_craggy_mountain_mesh(dims.x * 0.5, dims.y, dims.z * 0.5, seed_v, is_plat)
		m_mesh_inst.mesh = craggy_mesh
		m_mesh_inst.set_surface_override_material(0, mountain_mat)
		m_body.add_child(m_mesh_inst)
		
		# Sarp dağ yüzeyine birebir uyan gerçekçi çarpışma
		var col = CollisionShape3D.new()
		var col_shape = craggy_mesh.create_trimesh_shape()
		if col_shape:
			col.shape = col_shape
			m_body.add_child(col)
			
		add_child(m_body)

# Prosedürel Sarp & Kayalık Dağ Üretici (Yuvarlak Küre Yerine Gerçek Dağ Dorukları & Sırtları)
func create_craggy_mountain_mesh(rad_x: float, height: float, rad_z: float, seed_val: float = 0.0, is_plateau: bool = false) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var rings: int = 7
	var sectors: int = 24
	
	var grid: Array = []
	for r in range(rings + 1):
		var row: Array = []
		var t_r = float(r) / float(rings) # 0.0 (doruk) -> 1.0 (etek)
		
		# Dağ yükseklik profili: Zirveye doğru sarp ve sivri piramidal doruk
		var y_val: float
		if is_plateau:
			y_val = height * (1.0 - pow(t_r, 1.65))
		else:
			y_val = height * pow(1.0 - t_r, 1.28)
			
		for s in range(sectors):
			var angle = (float(s) / float(sectors)) * TAU
			
			# Daireselliği/karpuzluğu tamamen kıran sarp sırtlar (ridges) ve kanyon vadileri
			var ridge1 = cos(angle * 3.0 + seed_val) * 0.28
			var ridge2 = sin(angle * 5.0 + seed_val * 1.5) * 0.16
			var ridge3 = cos(angle * 7.0 + seed_val * 0.7) * 0.09
			var rad_mult = 1.0 + ridge1 + ridge2 + ridge3
			
			var curr_rx = rad_x * t_r * rad_mult
			var curr_rz = rad_z * t_r * rad_mult
			
			# Yamaçlarda kayalık kırıklıklar ve sarp uçurumlar (crags)
			var bump = 0.0
			if r > 0 and r < rings:
				bump = sin(angle * 4.0 + float(r) * 1.4 + seed_val) * (height * 0.08)
				bump += cos(angle * 6.0 + float(r) * 2.2) * (height * 0.05)
				
			var px = cos(angle) * curr_rx
			var py = y_val + bump
			var pz = sin(angle) * curr_rz
			
			# Etekleri zeminin biraz altına gömelim ki zeminle boşluk kalmasın
			if r == rings:
				py = -1.6
				
			# Zirve sivri doruk noktası
			if r == 0:
				px = 0.0 + sin(seed_val) * (rad_x * 0.02)
				pz = 0.0 + cos(seed_val) * (rad_z * 0.02)
				py = height
				
			# Vertex Renkleri:
			# Zirve: Sarp kayalık açık taş rengi
			# Yamaç: Yosunlu kaya ve çakıl
			# Etek: Zengin koyu orman/çimen örtüsü
			var vert_color: Color
			if t_r < 0.32:
				vert_color = Color(0.48, 0.45, 0.40).lerp(Color(0.40, 0.38, 0.34), (float(s % 3) * 0.1))
			elif t_r < 0.68:
				vert_color = Color(0.32, 0.39, 0.26).lerp(Color(0.26, 0.34, 0.22), (float(s % 4) * 0.08))
			else:
				vert_color = Color(0.16, 0.34, 0.14).lerp(Color(0.22, 0.40, 0.18), (float(s % 3) * 0.1))
				
			var uv = Vector2(px * 0.06, pz * 0.06)
			row.append({"pos": Vector3(px, py, pz), "uv": uv, "color": vert_color})
		grid.append(row)
		
	# Üçgen yüzeyleri ör
	for r in range(rings):
		for s in range(sectors):
			var next_s = (s + 1) % sectors
			
			var v0 = grid[r][s]
			var v1 = grid[r + 1][s]
			var v2 = grid[r + 1][next_s]
			var v3 = grid[r][next_s]
			
			if r == 0:
				st.set_color(v0["color"])
				st.set_uv(v0["uv"])
				st.add_vertex(v0["pos"])
				st.set_color(v2["color"])
				st.set_uv(v2["uv"])
				st.add_vertex(v2["pos"])
				st.set_color(v1["color"])
				st.set_uv(v1["uv"])
				st.add_vertex(v1["pos"])
			else:
				st.set_color(v0["color"])
				st.set_uv(v0["uv"])
				st.add_vertex(v0["pos"])
				st.set_color(v2["color"])
				st.set_uv(v2["uv"])
				st.add_vertex(v2["pos"])
				st.set_color(v1["color"])
				st.set_uv(v1["uv"])
				st.add_vertex(v1["pos"])
				
				st.set_color(v0["color"])
				st.set_uv(v0["uv"])
				st.add_vertex(v0["pos"])
				st.set_color(v3["color"])
				st.set_uv(v3["uv"])
				st.add_vertex(v3["pos"])
				st.set_color(v2["color"])
				st.set_uv(v2["uv"])
				st.add_vertex(v2["pos"])
				
	st.generate_normals()
	return st.commit()
		
	# 1. Batı Tepesindeki Tarihi Taş Yel Değirmeni
	spawn_ottoman_windmill(Vector3(-92, 13.5, 5))
	
	# 2. Güney Tepesindeki Hisar Gözetleme Kulesi & Sancak
	spawn_citadel_watchtower(Vector3(0, 16.0, 108))

# Tarihi Taş Yel Değirmeni (Ottoman Stone Windmill)
func spawn_ottoman_windmill(pos: Vector3) -> void:
	var mill = StaticBody3D.new()
	mill.position = pos
	
	var col = CollisionShape3D.new()
	var cyl_shape = CylinderShape3D.new()
	cyl_shape.radius = 3.2
	cyl_shape.height = 10.0
	col.shape = cyl_shape
	col.position.y = 5.0
	mill.add_child(col)
	
	# Kule Taş Gövdesi
	var body = MeshInstance3D.new()
	var bm = CylinderMesh.new()
	bm.top_radius = 2.8
	bm.bottom_radius = 3.6
	bm.height = 9.5
	body.mesh = bm
	body.position.y = 4.75
	var smat = StandardMaterial3D.new()
	if tex_stone:
		smat.albedo_texture = tex_stone
		smat.uv1_scale = Vector3(3, 4, 3)
	else:
		smat.albedo_color = Color(0.72, 0.68, 0.62)
	smat.roughness = 0.85
	body.set_surface_override_material(0, smat)
	mill.add_child(body)
	
	# Koni Kiremit Çatı
	var roof = MeshInstance3D.new()
	var rm = CylinderMesh.new()
	rm.top_radius = 0.1
	rm.bottom_radius = 3.4
	rm.height = 3.8
	roof.mesh = rm
	roof.position.y = 11.4
	var rmat = StandardMaterial3D.new()
	if tex_roof:
		rmat.albedo_texture = tex_roof
	rmat.albedo_color = Color(0.68, 0.26, 0.16)
	roof.set_surface_override_material(0, rmat)
	mill.add_child(roof)
	
	# 4 Kollu Yel Değirmeni Kanatları
	var sails = Node3D.new()
	sails.position = Vector3(0, 9.8, 3.2)
	var sail_wood = StandardMaterial3D.new()
	sail_wood.albedo_color = Color(0.3, 0.2, 0.12)
	var sail_cloth = StandardMaterial3D.new()
	sail_cloth.albedo_color = Color(0.92, 0.9, 0.82)
	
	for i in range(4):
		var arm = Node3D.new()
		arm.rotation.z = i * (PI * 0.5)
		
		var beam = MeshInstance3D.new()
		var b_box = BoxMesh.new()
		b_box.size = Vector3(0.18, 6.2, 0.18)
		beam.mesh = b_box
		beam.position.y = 3.1
		beam.set_surface_override_material(0, sail_wood)
		arm.add_child(beam)
		
		var cloth = MeshInstance3D.new()
		var c_box = BoxMesh.new()
		c_box.size = Vector3(0.95, 4.8, 0.05)
		cloth.mesh = c_box
		cloth.position = Vector3(0.5, 3.4, 0.05)
		cloth.set_surface_override_material(0, sail_cloth)
		arm.add_child(cloth)
		
		sails.add_child(arm)
	mill.add_child(sails)
	
	add_child(mill)

# Hisar Gözetleme Kulesi (Citadel Stone Watchtower)
func spawn_citadel_watchtower(pos: Vector3) -> void:
	var tower = StaticBody3D.new()
	tower.position = pos
	
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(6.5, 14.0, 6.5)
	col.shape = box
	col.position.y = 7.0
	tower.add_child(col)
	
	var t_mesh = MeshInstance3D.new()
	var t_box = BoxMesh.new()
	t_box.size = Vector3(6.0, 13.0, 6.0)
	t_mesh.mesh = t_box
	t_mesh.position.y = 6.5
	var smat = StandardMaterial3D.new()
	if tex_stone:
		smat.albedo_texture = tex_stone
		smat.uv1_scale = Vector3(3, 6, 3)
	smat.roughness = 0.85
	t_mesh.set_surface_override_material(0, smat)
	tower.add_child(t_mesh)
	
	# Burçlar (Crenellations)
	for side in [Vector3(-2.8, 13.5, 0), Vector3(2.8, 13.5, 0), Vector3(0, 13.5, -2.8), Vector3(0, 13.5, 2.8)]:
		var wall = MeshInstance3D.new()
		var w_box = BoxMesh.new()
		w_box.size = Vector3(6.0 if side.z != 0 else 0.5, 1.2, 0.5 if side.z != 0 else 6.0)
		wall.mesh = w_box
		wall.position = side
		wall.set_surface_override_material(0, smat)
		tower.add_child(wall)
		
	# Dalgalanan Osmanlı Sancağı Direği
	var pole = MeshInstance3D.new()
	var p_cyl = CylinderMesh.new()
	p_cyl.top_radius = 0.05
	p_cyl.bottom_radius = 0.08
	p_cyl.height = 4.8
	pole.mesh = p_cyl
	pole.position = Vector3(0, 15.5, 0)
	var pole_mat = StandardMaterial3D.new()
	pole_mat.albedo_color = Color(0.2, 0.2, 0.2)
	pole.set_surface_override_material(0, pole_mat)
	tower.add_child(pole)
	
	var flag = MeshInstance3D.new()
	var f_box = BoxMesh.new()
	f_box.size = Vector3(2.2, 1.4, 0.04)
	flag.mesh = f_box
	flag.position = Vector3(1.1, 16.8, 0)
	var f_mat = StandardMaterial3D.new()
	f_mat.albedo_color = Color(0.85, 0.12, 0.12) # Kırmızı Sancak
	flag.set_surface_override_material(0, f_mat)
	tower.add_child(flag)
	
	add_child(tower)

# =============================================================================
# ÜSTÜNE ÇIKILABİLİR DAĞLAR, ZİRVE SEYİR TERASLARI & DAĞ PATİKALARI
# =============================================================================
func build_climbable_mountain_trails_and_summits() -> void:
	# 1. KUZEY ZİRVESİ: KARTAL TEPESİ (Şehitlik Sancağı, Seyir Terası & Kamp Ateşi)
	build_north_kartal_summit_and_trail()
	
	# 2. BATI ZİRVESİ: YEL DEĞİRMENİ & RÜZGÂRLI TEPE SEYİR YOLU
	build_west_windmill_summit_trail()
	
	# 3. GÜNEY ZİRVESİ: HİSAR SANCAK KALESİ & GÖZETLEME BURCU YOLU
	build_south_citadel_summit_trail()
	
	# 4. DOĞU ZİRVESİ: BOĞAZİÇİ DERVİŞGÂH TEPESİ PATİKASI
	build_east_derwish_summit_trail()

func build_north_kartal_summit_and_trail() -> void:
	var trail_node = Node3D.new()
	trail_node.name = "NorthMountainTrail"
	
	var stone_step_mat = StandardMaterial3D.new()
	if tex_stone:
		stone_step_mat.albedo_texture = tex_stone
		stone_step_mat.uv1_scale = Vector3(2, 1, 2)
	else:
		stone_step_mat.albedo_color = Color(0.68, 0.65, 0.6)
	stone_step_mat.roughness = 0.9
	
	# 28 Basamaklı Doğal Kıvrımlı Taş Patika (z = -86 -> z = -118, y = 0.5 -> y = 29.5)
	for i in range(28):
		var t = float(i) / 27.0
		var step_pos = Vector3(
			sin(t * PI * 2.2) * 5.0,
			0.5 + t * 29.0,
			lerp(-86.0, -118.0, t)
		)
		
		var step_body = StaticBody3D.new()
		step_body.position = step_pos
		
		var col = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = Vector3(4.8, 0.6, 2.2)
		col.shape = box
		step_body.add_child(col)
		
		var sm = MeshInstance3D.new()
		var bm = BoxMesh.new()
		bm.size = Vector3(4.8, 0.6, 2.2)
		sm.mesh = bm
		sm.set_surface_override_material(0, stone_step_mat)
		step_body.add_child(sm)
		
		trail_node.add_child(step_body)
		
		# Her 7 basamakta bir yol kenarı feneri
		if i % 7 == 2:
			var lantern_pos = step_pos + Vector3(2.8, 0.3, 0)
			spawn_historic_street_lantern(lantern_pos)
			
	# --- KARTAL TEPESİ ZİRVE SEYİR TERASI (Vector3(0, 29.5, -118)) ---
	var summit_pos = Vector3(0, 29.5, -118)
	
	# 1. Masif Ahşap Seyir Platformu (13x13 metre)
	var deck = StaticBody3D.new()
	deck.position = summit_pos
	
	var d_col = CollisionShape3D.new()
	var d_box = BoxShape3D.new()
	d_box.size = Vector3(13.0, 0.8, 13.0)
	d_col.shape = d_box
	deck.add_child(d_col)
	
	var d_mesh = MeshInstance3D.new()
	var dm = BoxMesh.new()
	dm.size = Vector3(13.0, 0.8, 13.0)
	d_mesh.mesh = dm
	var wood_mat = StandardMaterial3D.new()
	if tex_wood:
		wood_mat.albedo_texture = tex_wood
		wood_mat.uv1_scale = Vector3(4, 1, 4)
	else:
		wood_mat.albedo_color = Color(0.42, 0.28, 0.16)
	wood_mat.roughness = 0.82
	d_mesh.set_surface_override_material(0, wood_mat)
	deck.add_child(d_mesh)
	
	# Ahşap Korkuluklar
	var rail_mat = StandardMaterial3D.new()
	rail_mat.albedo_color = Color(0.32, 0.2, 0.12)
	rail_mat.roughness = 0.85
	
	for side in [Vector3(0, 0.8, -6.2), Vector3(0, 0.8, 6.2), Vector3(-6.2, 0.8, 0), Vector3(6.2, 0.8, 0)]:
		var rail = MeshInstance3D.new()
		var rm = BoxMesh.new()
		if side.z != 0:
			rm.size = Vector3(12.5, 1.1, 0.25)
		else:
			rm.size = Vector3(0.25, 1.1, 12.5)
		rail.mesh = rm
		rail.position = side
		rail.set_surface_override_material(0, rail_mat)
		deck.add_child(rail)
		
	trail_node.add_child(deck)
	
	# 2. Göğe Yükselen 9 Metrelik Osmanlı Sancak Direği
	var flag_pole = MeshInstance3D.new()
	var fp_cyl = CylinderMesh.new()
	fp_cyl.top_radius = 0.08
	fp_cyl.bottom_radius = 0.14
	fp_cyl.height = 9.0
	flag_pole.mesh = fp_cyl
	flag_pole.position = summit_pos + Vector3(0, 4.9, 0)
	var fp_mat = StandardMaterial3D.new()
	fp_mat.albedo_color = Color(0.25, 0.22, 0.18)
	flag_pole.set_surface_override_material(0, fp_mat)
	trail_node.add_child(flag_pole)
	
	# Dalgalanan Dev Osmanlı Sancağı (Kırmızı & Hilâl)
	var flag = MeshInstance3D.new()
	var fm = BoxMesh.new()
	fm.size = Vector3(3.6, 2.2, 0.04)
	flag.mesh = fm
	flag.position = summit_pos + Vector3(1.8, 7.6, 0)
	var flag_mat = StandardMaterial3D.new()
	flag_mat.albedo_color = Color(0.88, 0.12, 0.12)
	flag.set_surface_override_material(0, flag_mat)
	trail_node.add_child(flag)
	
	# 3. Zirve Kamp Ateşi (Campfire)
	var fire_center = summit_pos + Vector3(-3.2, 0.45, -2.5)
	
	# Taş Ocak Halkası
	var ring = MeshInstance3D.new()
	var ring_mesh = TorusMesh.new()
	ring_mesh.inner_radius = 0.55
	ring_mesh.outer_radius = 0.95
	ring.mesh = ring_mesh
	ring.position = fire_center
	var ring_mat = StandardMaterial3D.new()
	ring_mat.albedo_color = Color(0.35, 0.33, 0.3)
	ring.set_surface_override_material(0, ring_mat)
	trail_node.add_child(ring)
	
	# Yanık Odunlar
	for ang in [0.0, PI * 0.33, PI * 0.66]:
		var log_m = MeshInstance3D.new()
		var lc = CylinderMesh.new()
		lc.top_radius = 0.08
		lc.bottom_radius = 0.08
		lc.height = 0.85
		log_m.mesh = lc
		log_m.position = fire_center + Vector3(0, 0.1, 0)
		log_m.rotation = Vector3(0.3, ang, 0.2)
		var log_mat = StandardMaterial3D.new()
		log_mat.albedo_color = Color(0.18, 0.12, 0.08)
		log_m.set_surface_override_material(0, log_mat)
		trail_node.add_child(log_m)
		
	# Sıcak Kamp Ateşi Işığı
	var fire_light = OmniLight3D.new()
	fire_light.position = fire_center + Vector3(0, 0.6, 0)
	fire_light.light_color = Color(1.0, 0.62, 0.22)
	fire_light.light_energy = 3.6
	fire_light.omni_range = 14.0
	trail_node.add_child(fire_light)
	
	# 4. Oturma Kütükleri
	for k in [Vector3(-4.5, 0.8, -2.5), Vector3(-3.2, 0.8, -4.0)]:
		var bench = MeshInstance3D.new()
		var bc = CylinderMesh.new()
		bc.top_radius = 0.25
		bc.bottom_radius = 0.28
		bc.height = 0.6
		bench.mesh = bc
		bench.position = summit_pos + k
		bench.set_surface_override_material(0, rail_mat)
		trail_node.add_child(bench)
		
	# 5. Teşkilât-ı Mahsûsa Zirve Zulası (500 Akçe & Mühimmat)
	if InteractivePropScript:
		var chest = InteractivePropScript.new()
		chest.prop_type = "zula"
		chest.interact_label = "📦 Teşkilât Kartal Zirvesi Zulası (Cephane & Akçe Al)"
		chest.position = summit_pos + Vector3(3.5, 0.4, 3.2)
		trail_node.add_child(chest)
		
	add_child(trail_node)

func build_west_windmill_summit_trail() -> void:
	var trail_node = Node3D.new()
	trail_node.name = "WestMountainTrail"
	
	var stone_step_mat = StandardMaterial3D.new()
	if tex_stone:
		stone_step_mat.albedo_texture = tex_stone
		stone_step_mat.uv1_scale = Vector3(2, 1, 2)
	else:
		stone_step_mat.albedo_color = Color(0.68, 0.65, 0.6)
		
	# Yel değirmenine çıkan taş merdivenler (x = -74 -> x = -92, z = 5, y = 0.5 -> y = 13.5)
	for i in range(16):
		var t = float(i) / 15.0
		var step_pos = Vector3(
			lerp(-74.0, -92.0, t),
			0.5 + t * 13.0,
			5.0 + sin(t * PI) * 2.5
		)
		var step_body = StaticBody3D.new()
		step_body.position = step_pos
		var col = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = Vector3(2.4, 0.6, 4.2)
		col.shape = box
		step_body.add_child(col)
		var sm = MeshInstance3D.new()
		var bm = BoxMesh.new()
		bm.size = Vector3(2.4, 0.6, 4.2)
		sm.mesh = bm
		sm.set_surface_override_material(0, stone_step_mat)
		step_body.add_child(sm)
		trail_node.add_child(step_body)
		
	# Değirmenden Rüzgârlı Doruğa tırmanış taşları (x = -92 -> x = -108, y = 13.5 -> y = 24.0)
	for i in range(12):
		var t = float(i) / 11.0
		var step_pos = Vector3(
			lerp(-92.0, -108.0, t),
			13.5 + t * 10.5,
			5.0 + cos(t * PI) * 3.0
		)
		var step_body = StaticBody3D.new()
		step_body.position = step_pos
		var col = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = Vector3(2.2, 0.6, 3.8)
		col.shape = box
		step_body.add_child(col)
		var sm = MeshInstance3D.new()
		var bm = BoxMesh.new()
		bm.size = Vector3(2.2, 0.6, 3.8)
		sm.mesh = bm
		sm.set_surface_override_material(0, stone_step_mat)
		step_body.add_child(sm)
		trail_node.add_child(step_body)
		
	# Rüzgârlı Tepe Seyir Balkonu (Vector3(-108, 24.0, 5))
	var summit_deck = StaticBody3D.new()
	summit_deck.position = Vector3(-108, 24.0, 5)
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(8.0, 0.7, 8.0)
	col.shape = box
	summit_deck.add_child(col)
	var dm = MeshInstance3D.new()
	var dmesh = BoxMesh.new()
	dmesh.size = Vector3(8.0, 0.7, 8.0)
	dm.mesh = dmesh
	dm.set_surface_override_material(0, stone_step_mat)
	summit_deck.add_child(dm)
	trail_node.add_child(summit_deck)
	
	spawn_historic_street_lantern(Vector3(-106, 24.5, 3))
	
	add_child(trail_node)

func build_south_citadel_summit_trail() -> void:
	var trail_node = Node3D.new()
	trail_node.name = "SouthCitadelTrail"
	
	var stone_mat = StandardMaterial3D.new()
	if tex_stone:
		stone_mat.albedo_texture = tex_stone
	else:
		stone_mat.albedo_color = Color(0.7, 0.67, 0.62)
		
	# Kapalıçarşı güneyinden Hisar Tepesine çıkan sur merdivenleri (z = 96 -> z = 118, y = 0.5 -> y = 25.0)
	for i in range(22):
		var t = float(i) / 21.0
		var step_pos = Vector3(
			sin(t * PI * 1.5) * 4.0,
			0.5 + t * 24.5,
			lerp(96.0, 120.0, t)
		)
		var step_body = StaticBody3D.new()
		step_body.position = step_pos
		var col = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = Vector3(4.5, 0.6, 2.0)
		col.shape = box
		step_body.add_child(col)
		var sm = MeshInstance3D.new()
		var bm = BoxMesh.new()
		bm.size = Vector3(4.5, 0.6, 2.0)
		sm.mesh = bm
		sm.set_surface_override_material(0, stone_mat)
		step_body.add_child(sm)
		trail_node.add_child(step_body)
		
		if i % 6 == 1:
			spawn_historic_street_lantern(step_pos + Vector3(2.6, 0.3, 0))
			
	# Hisar Zirve Seyir Burcu (Vector3(0, 25.5, 122))
	var fort_deck = StaticBody3D.new()
	fort_deck.position = Vector3(0, 25.5, 122)
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(10.0, 0.8, 10.0)
	col.shape = box
	fort_deck.add_child(col)
	var fm = MeshInstance3D.new()
	var fmesh = BoxMesh.new()
	fmesh.size = Vector3(10.0, 0.8, 10.0)
	fm.mesh = fmesh
	fm.set_surface_override_material(0, stone_mat)
	fort_deck.add_child(fm)
	trail_node.add_child(fort_deck)
	
	add_child(trail_node)

func build_east_derwish_summit_trail() -> void:
	var trail_node = Node3D.new()
	trail_node.name = "EastDerwishTrail"
	
	var stone_mat = StandardMaterial3D.new()
	if tex_stone:
		stone_mat.albedo_texture = tex_stone
	else:
		stone_mat.albedo_color = Color(0.72, 0.7, 0.65)
		
	# Gölet iskelesinden doğu tepesine kıvrılan patika (x = 76 -> x = 112, z = 0 -> z = 18, y = 0.5 -> y = 26.0)
	for i in range(22):
		var t = float(i) / 21.0
		var step_pos = Vector3(
			lerp(76.0, 112.0, t),
			0.5 + t * 25.5,
			lerp(0.0, 18.0, t) + sin(t * PI * 2.0) * 3.5
		)
		var step_body = StaticBody3D.new()
		step_body.position = step_pos
		var col = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = Vector3(3.8, 0.6, 2.2)
		col.shape = box
		step_body.add_child(col)
		var sm = MeshInstance3D.new()
		var bm = BoxMesh.new()
		bm.size = Vector3(3.8, 0.6, 2.2)
		sm.mesh = bm
		sm.set_surface_override_material(0, stone_mat)
		step_body.add_child(sm)
		trail_node.add_child(step_body)
		
		if i % 7 == 2:
			spawn_historic_street_lantern(step_pos + Vector3(0, 0.3, 2.4))
			
	# Doğu Zirvesi Dervişgâh Harabesi Seyir Platformu (Vector3(112, 26.0, 18))
	var dervish_deck = StaticBody3D.new()
	dervish_deck.position = Vector3(112, 26.0, 18)
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(9.0, 0.8, 9.0)
	col.shape = box
	dervish_deck.add_child(col)
	var dm = MeshInstance3D.new()
	var dmesh = BoxMesh.new()
	dmesh.size = Vector3(9.0, 0.8, 9.0)
	dm.mesh = dmesh
	dm.set_surface_override_material(0, stone_mat)
	dervish_deck.add_child(dm)
	
	# Antik Mermer Sütunlar (Dervişgâh Seyir Köşeleri)
	var pillar_mat = StandardMaterial3D.new()
	pillar_mat.albedo_color = Color(0.85, 0.83, 0.78)
	pillar_mat.roughness = 0.45
	
	for p_offset in [Vector3(-3.5, 2.2, -3.5), Vector3(3.5, 2.2, -3.5), Vector3(-3.5, 2.2, 3.5), Vector3(3.5, 2.2, 3.5)]:
		var pillar = MeshInstance3D.new()
		var pcyl = CylinderMesh.new()
		pcyl.top_radius = 0.3
		pcyl.bottom_radius = 0.35
		pcyl.height = 4.0
		pillar.mesh = pcyl
		pillar.position = p_offset
		pillar.set_surface_override_material(0, pillar_mat)
		dervish_deck.add_child(pillar)
		
	trail_node.add_child(dervish_deck)
	
	# Dervişgâh Gizli Zulası
	if InteractivePropScript:
		var chest = InteractivePropScript.new()
		chest.prop_type = "zula"
		chest.interact_label = "📦 Boğaziçi Dervişgâh Zulası (Cephane & Akçe Al)"
		chest.position = Vector3(112, 26.5, 18)
		trail_node.add_child(chest)
		
	add_child(trail_node)

# =============================================================================
# DOĞAL SARAY GÖLETİ, İSKELE & KAYIK (Historical Lake, Pier & Rowing Boat)
# =============================================================================
func build_historical_lake_and_pier(pos: Vector3) -> void:
	var lake_node = Node3D.new()
	lake_node.position = pos
	
	# 1. Gölet Su Yüzeyi (Yansımalı Büyüleyici Turkuaz/Zümrüt Su)
	var water = MeshInstance3D.new()
	var w_cyl = CylinderMesh.new()
	w_cyl.top_radius = 16.0
	w_cyl.bottom_radius = 16.0
	w_cyl.height = 0.15
	water.mesh = w_cyl
	water.position.y = -0.06
	var water_mat = StandardMaterial3D.new()
	water_mat.albedo_color = Color(0.1, 0.42, 0.46, 0.88)
	water_mat.roughness = 0.04
	water_mat.metallic = 0.18
	water_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water.set_surface_override_material(0, water_mat)
	lake_node.add_child(water)
	
	# 2. Gölet Kıyı Taşları ve Çakıllar
	var shore_ring = MeshInstance3D.new()
	var sr_torus = TorusMesh.new()
	sr_torus.inner_radius = 15.6
	sr_torus.outer_radius = 17.2
	shore_ring.mesh = sr_torus
	shore_ring.position.y = 0.04
	var stone_mat = StandardMaterial3D.new()
	if tex_cobble:
		stone_mat.albedo_texture = tex_cobble
		stone_mat.uv1_scale = Vector3(18, 2, 2)
	else:
		stone_mat.albedo_color = Color(0.55, 0.52, 0.48)
	shore_ring.set_surface_override_material(0, stone_mat)
	lake_node.add_child(shore_ring)
	
	# 3. Ahşap Balıkçı İskelesi (Kıyıdan gölün içine uzanır)
	var pier = StaticBody3D.new()
	pier.position = Vector3(-14.0, 0, 0)
	
	var pcol = CollisionShape3D.new()
	var pc_box = BoxShape3D.new()
	pc_box.size = Vector3(10.0, 0.35, 2.4)
	pcol.shape = pc_box
	pcol.position = Vector3(5.0, 0.15, 0)
	pier.add_child(pcol)
	
	var pdeck = MeshInstance3D.new()
	var pd_box = BoxMesh.new()
	pd_box.size = Vector3(10.0, 0.25, 2.4)
	pdeck.mesh = pd_box
	pdeck.position = Vector3(5.0, 0.15, 0)
	var wood_mat = StandardMaterial3D.new()
	if tex_wood:
		wood_mat.albedo_texture = tex_wood
	wood_mat.albedo_color = Color(0.38, 0.26, 0.16)
	pdeck.set_surface_override_material(0, wood_mat)
	pier.add_child(pdeck)
	
	# İskele Kazıkları
	for px in [1.5, 5.0, 8.5, 9.8]:
		for pz in [-1.1, 1.1]:
			var post = MeshInstance3D.new()
			var p_cyl = CylinderMesh.new()
			p_cyl.top_radius = 0.09
			p_cyl.bottom_radius = 0.09
			p_cyl.height = 1.4
			post.mesh = p_cyl
			post.position = Vector3(px, -0.4, pz)
			post.set_surface_override_material(0, wood_mat)
			pier.add_child(post)
			
	# İskele Feneri (Gece göle sarı ışık saçar)
	var pier_lamp = OmniLight3D.new()
	pier_lamp.light_color = Color(1.0, 0.85, 0.5)
	pier_lamp.light_energy = 1.8
	pier_lamp.omni_range = 7.5
	pier_lamp.position = Vector3(9.5, 1.6, 0)
	pier.add_child(pier_lamp)
	lake_node.add_child(pier)
	
	# 4. Göle Bağlı Tarihi Ahşap Sandal / Kayık
	var boat = StaticBody3D.new()
	boat.position = Vector3(-3.5, 0, 3.2)
	boat.rotation.y = 0.25
	
	var bcol = CollisionShape3D.new()
	var bc_box = BoxShape3D.new()
	bc_box.size = Vector3(3.6, 0.8, 1.6)
	bcol.shape = bc_box
	bcol.position.y = 0.2
	boat.add_child(bcol)
	
	var b_mesh = MeshInstance3D.new()
	var bm_box = BoxMesh.new()
	bm_box.size = Vector3(3.4, 0.65, 1.4)
	b_mesh.mesh = bm_box
	b_mesh.position.y = 0.15
	b_mesh.set_surface_override_material(0, wood_mat)
	boat.add_child(b_mesh)
	
	# Sandak Kürekleri
	for side_z in [-0.85, 0.85]:
		var oar = MeshInstance3D.new()
		var om_box = BoxMesh.new()
		om_box.size = Vector3(2.2, 0.06, 0.12)
		oar.mesh = om_box
		oar.position = Vector3(0, 0.5, side_z)
		oar.rotation.z = -0.15
		oar.set_surface_override_material(0, wood_mat)
		boat.add_child(oar)
	lake_node.add_child(boat)
	
	# 5. Nilüferler (Water Lilies)
	var lily_mat = StandardMaterial3D.new()
	lily_mat.albedo_color = Color(0.2, 0.55, 0.22)
	var pink_mat = StandardMaterial3D.new()
	pink_mat.albedo_color = Color(0.95, 0.45, 0.65)
	
	var lily_spots = [
		Vector3(4.0, 0.02, 6.0), Vector3(-6.0, 0.02, -8.0),
		Vector3(8.0, 0.02, -4.0), Vector3(-2.0, 0.02, -10.0)
	]
	for lspot in lily_spots:
		var pad = MeshInstance3D.new()
		var p_cyl = CylinderMesh.new()
		p_cyl.top_radius = 0.55
		p_cyl.bottom_radius = 0.55
		p_cyl.height = 0.02
		pad.mesh = p_cyl
		pad.position = lspot
		pad.set_surface_override_material(0, lily_mat)
		lake_node.add_child(pad)
		
		var flower = MeshInstance3D.new()
		var f_sph = SphereMesh.new()
		f_sph.radius = 0.12
		f_sph.height = 0.18
		flower.mesh = f_sph
		flower.position = lspot + Vector3(0, 0.08, 0)
		flower.set_surface_override_material(0, pink_mat)
		lake_node.add_child(flower)
		
	# 6. Kıyı Salkımsöğüt Ağaçları (Weeping Willows)
	for tree_x in [-15.0, 0.0, 14.0]:
		var willow = spawn_weeping_willow(Vector3(tree_x, 0, -15.5))
		lake_node.add_child(willow)
		
	add_child(lake_node)

# Zarif Salkımsöğüt Ağacı (Weeping Willow)
func spawn_weeping_willow(pos: Vector3) -> Node3D:
	var tree = StaticBody3D.new()
	tree.position = pos
	
	var col = CollisionShape3D.new()
	var cyl = CylinderShape3D.new()
	cyl.radius = 0.4
	cyl.height = 3.5
	col.shape = cyl
	col.position.y = 1.75
	tree.add_child(col)
	
	var trunk = MeshInstance3D.new()
	var tr_cyl = CylinderMesh.new()
	tr_cyl.top_radius = 0.28
	tr_cyl.bottom_radius = 0.5
	tr_cyl.height = 3.8
	trunk.mesh = tr_cyl
	trunk.position.y = 1.9
	var t_mat = StandardMaterial3D.new()
	t_mat.albedo_color = Color(0.32, 0.24, 0.16)
	trunk.set_surface_override_material(0, t_mat)
	tree.add_child(trunk)
	
	# Sarkık Yaprak Kubbesi
	var foliage = MeshInstance3D.new()
	var fol_cyl = CylinderMesh.new()
	fol_cyl.top_radius = 1.2
	fol_cyl.bottom_radius = 3.6
	fol_cyl.height = 4.2
	foliage.mesh = fol_cyl
	foliage.position.y = 4.8
	var fol_mat = StandardMaterial3D.new()
	fol_mat.albedo_color = Color(0.3, 0.58, 0.24)
	fol_mat.roughness = 0.85
	foliage.set_surface_override_material(0, fol_mat)
	tree.add_child(foliage)
	
	return tree

# =============================================================================
# ASSASSIN'S CREED SAMAN ARABALARI & İNANÇ ATLAYIŞI NOKTALARI
# =============================================================================
func spawn_assassin_hay_carts() -> void:
	var cart_spots = [
		[Vector3(-37.5, 0, -8), 0.0],   # Batı Konaklar W2 Çatısı İnişi
		[Vector3(-37.5, 0, 18), 0.0],   # Batı Parkur W4 Çatısı İnişi
		[Vector3(39.5, 0, -22), PI],    # Doğu Çatı E1 İnişi
		[Vector3(39.5, 0, 18), PI],     # Doğu Zula E4 Çatısı İnişi
		[Vector3(14.0, 0, -32.0), 0.4]  # Cami Külliye İhata Çatısı İnişi
	]
	for cs in cart_spots:
		spawn_hay_cart(cs[0], cs[1])

func spawn_hay_cart(pos: Vector3, rot_y: float) -> void:
	var cart = StaticBody3D.new()
	cart.position = pos
	cart.rotation.y = rot_y
	if HayCartScript:
		cart.set_script(HayCartScript)
		
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(2.4, 1.8, 3.6)
	col.shape = box
	col.position.y = 0.9
	cart.add_child(col)
	
	# Ahşap Kasa
	var body = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(2.2, 0.7, 3.4)
	body.mesh = b_box
	body.position.y = 0.55
	var wood_mat = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.36, 0.24, 0.15)
	body.set_surface_override_material(0, wood_mat)
	cart.add_child(body)
	
	# 4 Büyük Parmaklı Ahşap Araba Tekerleği
	for side_x in [-1.15, 1.15]:
		for side_z in [-1.2, 1.2]:
			var wheel = MeshInstance3D.new()
			var w_cyl = CylinderMesh.new()
			w_cyl.top_radius = 0.52
			w_cyl.bottom_radius = 0.52
			w_cyl.height = 0.12
			wheel.mesh = w_cyl
			wheel.position = Vector3(side_x, 0.52, side_z)
			wheel.rotation.z = PI * 0.5
			wheel.set_surface_override_material(0, wood_mat)
			cart.add_child(wheel)
			
	# Tepeleme Yığılmış Altın Sarı Saman Yığını (Soft Fluffy Hay)
	var hay = MeshInstance3D.new()
	var h_sph = SphereMesh.new()
	h_sph.radius = 1.15
	h_sph.height = 1.6
	hay.mesh = h_sph
	hay.position = Vector3(0, 1.15, 0)
	var hay_mat = StandardMaterial3D.new()
	hay_mat.albedo_color = Color(0.92, 0.78, 0.38) # Altın sarısı saman
	hay_mat.roughness = 0.92
	hay.set_surface_override_material(0, hay_mat)
	cart.add_child(hay)
	
	# Etiket
	var hlabel = Label3D.new()
	hlabel.text = "🌾 Saman Arabası (İnanç Atlayışı)"
	hlabel.font_size = 24
	hlabel.pixel_size = 0.007
	hlabel.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	hlabel.modulate = Color(1.0, 0.9, 0.4)
	hlabel.outline_size = 4
	hlabel.position = Vector3(0, 2.3, 0)
	cart.add_child(hlabel)
	
	add_child(cart)

# =============================================================================
# TEŞKİLÂT-I MAHSÛSA: FERMAN PANOSU, ÇATI PARKURU & GİZLİ ZULALAR
# =============================================================================

func spawn_assassin_contracts_board(pos: Vector3) -> void:
	var board_scene = load("res://scripts/assassin_contracts.gd")
	if board_scene:
		var board = StaticBody3D.new()
		board.name = "AssassinContractsBoard"
		board.position = pos
		board.rotation.y = deg_to_rad(20.0)
		board.set_script(board_scene)
		add_child(board)

func build_rooftop_parkour_network() -> void:
	# 1. BATI MAHALLE ÇATI İPLERİ & ASMA KÖPRÜLERİ (Hemp Tightropes)
	spawn_tightrope_span(Vector3(-32, 5.2, -8), Vector3(-46, 5.2, -6))
	spawn_tightrope_span(Vector3(-32, 5.2, 5), Vector3(-46, 5.2, 7))
	spawn_tightrope_span(Vector3(-32, 5.2, 18), Vector3(-32, 5.2, 31))
	spawn_tightrope_span(Vector3(-46, 5.2, 7), Vector3(-46, 5.2, 18))

	# 2. DOĞU MAHALLE ÇATI İPLERİ & ASMA KÖPRÜLERİ
	spawn_tightrope_span(Vector3(34, 5.2, -22), Vector3(48, 5.2, -20))
	spawn_tightrope_span(Vector3(34, 5.2, 5), Vector3(48, 5.2, 7))
	spawn_tightrope_span(Vector3(34, 5.2, 18), Vector3(34, 5.2, 31))
	spawn_tightrope_span(Vector3(48, 5.2, 7), Vector3(48, 5.2, 18))

	# 3. KÜLLİYE CAMİİ'NDEN BATI KONAĞINA DEV ASMA ÇATI HATTI (Grand Rooftop Traverse)
	spawn_tightrope_span(Vector3(-14, 5.2, -32), Vector3(-32, 5.2, -22))

	# 4. GÜNEY KAPALIÇARŞI İLE MAHALLELERİ BİRBİRİNE BAĞLAYAN AHŞAP ASMA KÖPRÜLER
	spawn_suspended_wooden_bridge(Vector3(-18, 5.2, 72), Vector3(-32, 5.2, 31))
	spawn_suspended_wooden_bridge(Vector3(18, 5.2, 72), Vector3(34, 5.2, 31))

func spawn_tightrope_span(start_p: Vector3, end_p: Vector3) -> void:
	var span_dist = start_p.distance_to(end_p)
	if span_dist < 0.5:
		return

	var rope_body = StaticBody3D.new()
	var mid_p = (start_p + end_p) * 0.5
	add_child(rope_body)
	rope_body.position = mid_p
	rope_body.look_at(end_p, Vector3.UP)

	# Yürüme Çarpışması (Oyuncunun rahatça düşmeden yürüyebileceği düz halat yolu)
	var col = CollisionShape3D.new()
	var box_s = BoxShape3D.new()
	box_s.size = Vector3(0.42, 0.12, span_dist)
	col.shape = box_s
	rope_body.add_child(col)

	# Kenevir Halat Görseli
	var rope_mesh = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.055
	cyl.bottom_radius = 0.055
	cyl.height = span_dist
	rope_mesh.mesh = cyl
	rope_mesh.rotation.x = PI * 0.5
	var r_mat = StandardMaterial3D.new()
	r_mat.albedo_color = Color(0.52, 0.44, 0.32) # Kenevir urgan
	r_mat.roughness = 0.95
	rope_mesh.set_surface_override_material(0, r_mat)
	rope_body.add_child(rope_mesh)

	# Halatın ortasında rüzgarda sallanan küçük kırmızı Osmanlı sancağı
	var flag = MeshInstance3D.new()
	var f_box = BoxMesh.new()
	f_box.size = Vector3(0.02, 0.35, 0.28)
	flag.mesh = f_box
	flag.position = Vector3(0, -0.20, 0)
	var f_mat = StandardMaterial3D.new()
	f_mat.albedo_color = Color(0.78, 0.14, 0.12) # Kırmızı sancak
	flag.set_surface_override_material(0, f_mat)
	rope_body.add_child(flag)

func spawn_suspended_wooden_bridge(start_p: Vector3, end_p: Vector3) -> void:
	var span_dist = start_p.distance_to(end_p)
	if span_dist < 0.5:
		return

	var bridge_body = StaticBody3D.new()
	var mid_p = (start_p + end_p) * 0.5
	add_child(bridge_body)
	bridge_body.position = mid_p
	bridge_body.look_at(end_p, Vector3.UP)

	# Ahşap Köprü Tablası Çarpışması
	var col = CollisionShape3D.new()
	var box_s = BoxShape3D.new()
	box_s.size = Vector3(1.3, 0.2, span_dist)
	col.shape = box_s
	bridge_body.add_child(col)

	# Kalın Ahşap Kalaslar
	var wood_mat = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.35, 0.23, 0.14)
	wood_mat.roughness = 0.85

	var plank_mesh = MeshInstance3D.new()
	var p_box = BoxMesh.new()
	p_box.size = Vector3(1.2, 0.12, span_dist)
	plank_mesh.mesh = p_box
	plank_mesh.set_surface_override_material(0, wood_mat)
	bridge_body.add_child(plank_mesh)

	# İki Taraf Korkuluk Halatları
	for side_x in [-0.55, 0.55]:
		var rail = MeshInstance3D.new()
		var r_cyl = CylinderMesh.new()
		r_cyl.top_radius = 0.04
		r_cyl.bottom_radius = 0.04
		r_cyl.height = span_dist
		rail.mesh = r_cyl
		rail.position = Vector3(side_x, 0.65, 0)
		rail.rotation.x = PI * 0.5
		rail.set_surface_override_material(0, wood_mat)
		bridge_body.add_child(rail)


func spawn_secret_assassin_chests() -> void:
	var ChestScript = load("res://scripts/assassin_chest.gd")
	if not ChestScript:
		return

	var chest_locations = [
		{"pos": Vector3(0, 5.3, 38.0), "rot": 0.0, "title": "Kapalıçarşı Çatı Zulası", "gold": 650, "knife": 4, "smoke": 2},
		{"pos": Vector3(-15.5, 0.0, -48.0), "rot": PI * 0.5, "title": "Cami-i Kebîr Hazire Zulası", "gold": 500, "knife": 3, "smoke": 3},
		{"pos": Vector3(0, 16.1, 108.0), "rot": PI, "title": "Hisar Gözetleme Zulası", "gold": 800, "knife": 5, "smoke": 3},
		{"pos": Vector3(56.0, 0.0, -38.0), "rot": -PI * 0.25, "title": "Saray Göleti Gizli Zulası", "gold": 550, "knife": 3, "smoke": 2}
	]

	for c_data in chest_locations:
		var chest = StaticBody3D.new()
		chest.position = c_data["pos"]
		chest.rotation.y = c_data["rot"]
		chest.set_script(ChestScript)
		chest.set("chest_title", c_data["title"])
		chest.set("gold_reward", c_data["gold"])
		chest.set("knife_reward", c_data["knife"])
		chest.set("smoke_reward", c_data["smoke"])
		add_child(chest)

