extends RefCounted
class_name CharacterStyler

# Cihanşah - Tarihsel Dönem Karakter Şekillendirici
# Karakterleri modern/robot görünümden çıkarıp otantik 19. yüzyıl Osmanlı kılığına dönüştürür.
# NOT: Mixamo iskeleti santimetre (100x) ölçeğindedir (Kafa Z=157, Kalça Z=106).
# Tüm BoneAttachment eklentileri kemik yerel koordinatlarına tam uygun ölçekte (cm) eklenir.

static func style_character(root_node: Node, role: String = "player") -> void:
	var skel: Skeleton3D = root_node.find_child("Skeleton3D", true, false)
	if not skel:
		return
		
	# 1. Robot kaskı ve parlayan siperliği gizle
	var visor = skel.get_node_or_null("vanguard_visor")
	if visor:
		visor.visible = false
		
	# 2. Gövde kaplamasını Osmanlı çuha kumaşı ve dinamik ayakkabı/namaz çorabı shader'ı ile donat
	var body_mesh: MeshInstance3D = skel.get_node_or_null("vanguard_Mesh")
	if body_mesh:
		var sm = ShaderMaterial.new()
		var code = """shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap;
uniform vec4 uniform_color : source_color = vec4(0.12, 0.16, 0.22, 1.0);
uniform vec4 boot_color : source_color = vec4(0.08, 0.06, 0.05, 1.0);
uniform vec4 sock_color : source_color = vec4(0.96, 0.95, 0.92, 1.0);
uniform bool is_barefoot_or_socks = false;

varying float v_height;
varying vec3 v_pos;

void vertex() {
	v_height = VERTEX.z;
	v_pos = VERTEX;
	
	if (is_barefoot_or_socks && VERTEX.z < 15.0) {
		float center_x = (VERTEX.x < 0.0) ? -11.2 : 11.2;
		// 1. Kalın çizme genişliğini ayağın gerçek anatomik enine daralt
		VERTEX.x = center_x + (VERTEX.x - center_x) * 0.70;
		// 2. Kaba çizme burnunu ve uzunluğunu ayağa göre orantıla
		VERTEX.y = 4.0 + (VERTEX.y - 4.0) * 0.82;
		// 3. Çizmenin kalın alt tabanını (sole) ve topuk bloğunu tamamen yok et, yere sıfır ince ayak tabanı yap
		if (VERTEX.z < 4.2) {
			VERTEX.z = VERTEX.z * 0.22;
		} else {
			VERTEX.z = (VERTEX.z - 3.2) * 0.82;
		}
	}
}

void fragment() {
	vec4 tex = texture(albedo_texture, UV);
	vec3 base_col = uniform_color.rgb;
	
	if (v_height < 15.0) {
		if (is_barefoot_or_socks) {
			base_col = sock_color.rgb;
			if (v_pos.y > 13.0) {
				base_col *= 0.92;
			}
		} else {
			base_col = boot_color.rgb;
		}
	}
	
	ALBEDO = base_col * (tex.rgb * 0.35 + 0.65);
	ROUGHNESS = (v_height < 15.0 && !is_barefoot_or_socks) ? 0.45 : 0.85;
	METALLIC = 0.0;
}"""

		var sh = Shader.new()
		sh.code = code
		sm.shader = sh
		
		var u_color = Color(0.12, 0.16, 0.22)
		match role:
			"player": u_color = Color(0.12, 0.16, 0.22) # Koyu Lacivert Zaptiye
			"pasha": u_color = Color(0.14, 0.22, 0.18) # Koyu Nefti Paşa
			"imam": u_color = Color(0.08, 0.26, 0.14) # Zümrüt Yeşili İmam
			"vendor": u_color = Color(0.38, 0.26, 0.18) # Esnaf
			"spy": u_color = Color(0.18, 0.20, 0.24) # Rus Casus
			"boss": u_color = Color(0.28, 0.12, 0.12) # Kırmızı Çete Reisi
			
		sm.set_shader_parameter("uniform_color", u_color)
		sm.set_shader_parameter("boot_color", Color(0.08, 0.06, 0.05))
		sm.set_shader_parameter("sock_color", Color(0.96, 0.95, 0.92))
		sm.set_shader_parameter("is_barefoot_or_socks", false)
		
		var orig_mat = body_mesh.mesh.surface_get_material(0)
		if orig_mat and "albedo_texture" in orig_mat and orig_mat.albedo_texture:
			sm.set_shader_parameter("albedo_texture", orig_mat.albedo_texture)
			
		body_mesh.set_surface_override_material(0, sm)

	# Mevcut eski Fes / ekleri temizle (çift oluşmasın)
	for child in skel.get_children():
		if child is BoneAttachment3D and child.name.begins_with("Ottoman_"):
			child.queue_free()
			
	# Kemik Bağlantıları (Santimetre ölçeğinde)
	build_head_and_face(skel, role)
	build_torso_uniform(skel, role)
	build_waist_and_belt(skel, role)
	if role == "player":
		build_hilal_armband(skel)


# ----------------- KAFA, YÜZ, PALA BIYIK VE FES -----------------
static func build_head_and_face(skel: Skeleton3D, role: String) -> void:
	var head_idx = skel.find_bone("mixamorig_Head")
	if head_idx == -1:
		return
		
	var head_attach = BoneAttachment3D.new()
	head_attach.name = "Ottoman_HeadAttachment"
	head_attach.bone_name = "mixamorig_Head"
	head_attach.bone_idx = head_idx
	skel.add_child(head_attach)
	
	# İnsan Başı (Ten Rengi Kafa - cm ölçeğinde)
	var skin_mat = StandardMaterial3D.new()
	skin_mat.albedo_color = Color(0.86, 0.72, 0.58) # Doğal sıcak ten rengi
	skin_mat.roughness = 0.75
	
	var head_mesh = MeshInstance3D.new()
	var head_sphere = SphereMesh.new()
	head_sphere.radius = 13.5
	head_sphere.height = 25.0
	head_mesh.mesh = head_sphere
	head_mesh.position = Vector3(0, 13.0, 2.0)
	head_mesh.set_surface_override_material(0, skin_mat)
	head_attach.add_child(head_mesh)
	
	# Burun
	var nose = MeshInstance3D.new()
	var nose_prism = PrismMesh.new()
	nose_prism.size = Vector3(3.5, 6.0, 4.0)
	nose.mesh = nose_prism
	nose.position = Vector3(0, 11.0, 15.5)
	nose.rotation.x = PI / 2.0
	nose.set_surface_override_material(0, skin_mat)
	head_attach.add_child(nose)
	
	# Gözler
	var eye_white_mat = StandardMaterial3D.new()
	eye_white_mat.albedo_color = Color(0.95, 0.95, 0.95)
	var eye_pupil_mat = StandardMaterial3D.new()
	eye_pupil_mat.albedo_color = Color(0.08, 0.06, 0.05)
	
	for eye_x in [-4.5, 4.5]:
		var eye = MeshInstance3D.new()
		var es = SphereMesh.new()
		es.radius = 1.8
		es.height = 3.6
		eye.mesh = es
		eye.position = Vector3(eye_x, 13.0, 13.5)
		eye.set_surface_override_material(0, eye_white_mat)
		head_attach.add_child(eye)
		
		var pupil = MeshInstance3D.new()
		var ps = SphereMesh.new()
		ps.radius = 1.0
		ps.height = 2.0
		pupil.mesh = ps
		pupil.position = Vector3(eye_x, 13.0, 14.8)
		pupil.set_surface_override_material(0, eye_pupil_mat)
		head_attach.add_child(pupil)
		
		# Kaşlar
		var brow = MeshInstance3D.new()
		var bb = BoxMesh.new()
		bb.size = Vector3(4.2, 1.2, 2.0)
		brow.mesh = bb
		brow.position = Vector3(eye_x, 15.5, 14.2)
		brow.set_surface_override_material(0, eye_pupil_mat)
		head_attach.add_child(brow)
		
	# Kulaklar
	for ear_x in [-13.5, 13.5]:
		var ear = MeshInstance3D.new()
		var ear_box = BoxMesh.new()
		ear_box.size = Vector3(2.0, 5.5, 3.5)
		ear.mesh = ear_box
		ear.position = Vector3(ear_x, 11.0, 1.0)
		ear.set_surface_override_material(0, skin_mat)
		head_attach.add_child(ear)
	
	# Heybetli Osmanlı Pala Bıyığı
	var hair_mat = StandardMaterial3D.new()
	hair_mat.albedo_color = Color(0.08, 0.06, 0.05) # Kömür siyahı
	hair_mat.roughness = 0.9
	
	var mustache_center = MeshInstance3D.new()
	var mb = BoxMesh.new()
	mb.size = Vector3(7.0, 2.8, 3.5)
	mustache_center.mesh = mb
	mustache_center.position = Vector3(0, 6.5, 15.2)
	mustache_center.set_surface_override_material(0, hair_mat)
	head_attach.add_child(mustache_center)
	
	# Kıvrık pala bıyık uçları
	for side in [-1.0, 1.0]:
		var wing = MeshInstance3D.new()
		var wb = BoxMesh.new()
		wb.size = Vector3(5.5, 2.4, 3.0)
		wing.mesh = wb
		wing.position = Vector3(side * 5.8, 7.5, 14.5)
		wing.rotation.z = side * -0.35
		wing.set_surface_override_material(0, hair_mat)
		head_attach.add_child(wing)
		
	# Eğer Paşa (Eşref Bey) veya İmam ise sakal da ekle
	if role == "pasha" or role == "imam":
		var beard = MeshInstance3D.new()
		var bb_mesh = BoxMesh.new()
		bb_mesh.size = Vector3(9.0, 7.0, 5.0)
		beard.mesh = bb_mesh
		beard.position = Vector3(0, 1.0, 13.0)
		beard.set_surface_override_material(0, hair_mat)
		head_attach.add_child(beard)

	# Fes-i Şerif / Sarık (İmam için yeşil fes & tam beyaz ipek sarık)
	var fez_mat = StandardMaterial3D.new()
	if role == "imam":
		fez_mat.albedo_color = Color(0.12, 0.38, 0.2) # Nefti yeşil kubbe
	else:
		fez_mat.albedo_color = Color(0.68, 0.08, 0.08) # Vişne çürüğü fes çuhası
	fez_mat.roughness = 0.85
	
	var fez = MeshInstance3D.new()
	var fez_cyl = CylinderMesh.new()
	fez_cyl.top_radius = 11.5
	fez_cyl.bottom_radius = 13.8
	fez_cyl.height = 18.0
	fez.mesh = fez_cyl
	fez.position = Vector3(0, 26.0, 1.0)
	fez.set_surface_override_material(0, fez_mat)
	head_attach.add_child(fez)
	
	# Fes Arması (Pirinç/Altın Hilal Madalyon)
	var crest = MeshInstance3D.new()
	var cc = CylinderMesh.new()
	cc.top_radius = 2.5
	cc.bottom_radius = 2.5
	cc.height = 1.0
	crest.mesh = cc
	crest.position = Vector3(0, 25.0, 14.5)
	crest.rotation.x = PI / 2.0
	var gold_mat = StandardMaterial3D.new()
	gold_mat.albedo_color = Color(0.96, 0.82, 0.22)
	gold_mat.metallic = 0.95
	gold_mat.roughness = 0.2
	crest.set_surface_override_material(0, gold_mat)
	head_attach.add_child(crest)
	
	# İpek Püskül ve Tepe Düğmesi
	var tassel_top = MeshInstance3D.new()
	var tc = CylinderMesh.new()
	tc.top_radius = 2.0
	tc.bottom_radius = 2.0
	tc.height = 2.0
	tassel_top.mesh = tc
	tassel_top.position = Vector3(0, 35.5, 1.0)
	tassel_top.set_surface_override_material(0, gold_mat)
	head_attach.add_child(tassel_top)
	
	var tassel = MeshInstance3D.new()
	var t_cyl = CylinderMesh.new()
	t_cyl.top_radius = 1.5
	t_cyl.bottom_radius = 3.5
	t_cyl.height = 16.0
	tassel.mesh = t_cyl
	tassel.position = Vector3(8.0, 28.0, 7.0)
	tassel.rotation = Vector3(0.2, 0, -0.3)
	tassel.set_surface_override_material(0, hair_mat)
	head_attach.add_child(tassel)

	# Otantik İpek Sarık Sargısı (Fesin tabanını ve baş arkasını saran tülbent)
	var sarik_mat = StandardMaterial3D.new()
	sarik_mat.albedo_color = Color(0.96, 0.94, 0.88)
	sarik_mat.roughness = 0.8
	var sarik = MeshInstance3D.new()
	var s_torus = TorusMesh.new()
	s_torus.inner_radius = 12.0
	s_torus.outer_radius = 16.5
	sarik.mesh = s_torus
	sarik.position = Vector3(0, 19.5, 1.0)
	sarik.set_surface_override_material(0, sarik_mat)
	head_attach.add_child(sarik)

# ----------------- GÖĞÜS: ÇAPRAZ FİŞEKLİK, DÜĞMELER VE APOLETLER -----------------
static func build_torso_uniform(skel: Skeleton3D, role: String) -> void:
	var spine_idx = skel.find_bone("mixamorig_Spine2")
	if spine_idx == -1:
		return
		
	var spine_attach = BoneAttachment3D.new()
	spine_attach.name = "Ottoman_SpineAttachment"
	spine_attach.bone_name = "mixamorig_Spine2"
	spine_attach.bone_idx = spine_idx
	skel.add_child(spine_attach)
	
	var gold_mat = StandardMaterial3D.new()
	gold_mat.albedo_color = Color(0.96, 0.82, 0.22)
	gold_mat.metallic = 0.95
	gold_mat.roughness = 0.2
	
	var leather_mat = StandardMaterial3D.new()
	leather_mat.albedo_color = Color(0.32, 0.2, 0.12)
	leather_mat.roughness = 0.65
	
	# Osmanlı Subay Pelerini / Kaftan Sırtlığı (Omuz robotik kısımları örten heybetli çuha pelerin)
	var cape_mat = StandardMaterial3D.new()
	if role == "imam":
		cape_mat.albedo_color = Color(0.08, 0.26, 0.14) # Zümrüt yeşili ilmiye cübbesi
	else:
		cape_mat.albedo_color = Color(0.11, 0.15, 0.22) # Koyu lacivert zaptiye çuhası
	cape_mat.roughness = 0.88
	
	var cape = MeshInstance3D.new()
	var cb = BoxMesh.new()
	cb.size = Vector3(56.0, 36.0, 9.0)
	cape.mesh = cb
	cape.position = Vector3(0, 8.0, -8.0)
	cape.set_surface_override_material(0, cape_mat)
	spine_attach.add_child(cape)
	
	# Pelerin Altın Kenar Harcı
	var cape_trim = MeshInstance3D.new()
	var ctb = BoxMesh.new()
	ctb.size = Vector3(56.4, 2.5, 9.2)
	cape_trim.mesh = ctb
	cape_trim.position = Vector3(0, -9.5, -8.0)
	cape_trim.set_surface_override_material(0, gold_mat)
	spine_attach.add_child(cape_trim)
	
	# Üniforma Pirinç Düğmeleri (Ön göğüs hattı - cm ölçeğinde)
	for i in range(4):
		var btn = MeshInstance3D.new()
		var bc = CylinderMesh.new()
		bc.top_radius = 1.6
		bc.bottom_radius = 1.6
		bc.height = 1.2
		btn.mesh = bc
		btn.position = Vector3(0, 4.0 + (i * 6.5), 17.5)
		btn.rotation.x = PI / 2.0
		btn.set_surface_override_material(0, gold_mat)
		spine_attach.add_child(btn)
		
	# Sırma Omuz Apoletleri
	for side in [-1.0, 1.0]:
		var epaulet = MeshInstance3D.new()
		var eb = BoxMesh.new()
		eb.size = Vector3(14.0, 3.0, 16.0)
		epaulet.mesh = eb
		epaulet.position = Vector3(side * 24.0, 22.0, 2.0)
		epaulet.set_surface_override_material(0, gold_mat)
		spine_attach.add_child(epaulet)
		
	# Çapraz Deri Fişeklik / Kütüklük (Sağ omuzdan sol bele)
	if role == "player":
		var strap = MeshInstance3D.new()
		var sb = BoxMesh.new()
		sb.size = Vector3(5.0, 40.0, 1.8)
		strap.mesh = sb
		strap.position = Vector3(2.0, 11.0, 17.0)
		strap.rotation.z = -0.55
		strap.set_surface_override_material(0, leather_mat)
		spine_attach.add_child(strap)
		
		# Fişeklik üzerindeki pirinç mermiler
		for b in range(5):
			var bullet = MeshInstance3D.new()
			var b_cyl = CylinderMesh.new()
			b_cyl.top_radius = 0.9
			b_cyl.bottom_radius = 0.9
			b_cyl.height = 4.0
			bullet.mesh = b_cyl
			bullet.position = Vector3(-8.0 + (b * 4.2), 19.0 - (b * 4.2), 18.0)
			bullet.rotation.z = 0.95
			bullet.set_surface_override_material(0, gold_mat)
			spine_attach.add_child(bullet)

# ----------------- BEL: KIRMIZI KUŞAK, KEMER VE KAMA -----------------
static func build_waist_and_belt(skel: Skeleton3D, role: String) -> void:
	var hips_idx = skel.find_bone("mixamorig_Hips")
	if hips_idx == -1:
		return
		
	var hips_attach = BoneAttachment3D.new()
	hips_attach.name = "Ottoman_HipsAttachment"
	hips_attach.bone_name = "mixamorig_Hips"
	hips_attach.bone_idx = hips_idx
	skel.add_child(hips_attach)
	
	# Geniş Kırmızı İpek Acem Kuşağı (Bel çevresini saran canlı kuşak)
	var sash = MeshInstance3D.new()
	var sash_box = BoxMesh.new()
	sash_box.size = Vector3(44.0, 18.0, 28.0)
	sash.mesh = sash_box
	sash.position = Vector3(0, 3.0, 0)
	var sash_mat = StandardMaterial3D.new()
	sash_mat.albedo_color = Color(0.78, 0.12, 0.12) # Canlı Osmanlı Kırmızı Kuşağı
	sash_mat.roughness = 0.8
	sash.set_surface_override_material(0, sash_mat)
	hips_attach.add_child(sash)
	
	# Kuşak Üstü Deri Kemer ve Pirinç Toka
	var belt = MeshInstance3D.new()
	var bb = BoxMesh.new()
	bb.size = Vector3(45.0, 5.5, 29.0)
	belt.mesh = bb
	belt.position = Vector3(0, 3.0, 0)
	var leather_mat = StandardMaterial3D.new()
	leather_mat.albedo_color = Color(0.25, 0.15, 0.08)
	belt.set_surface_override_material(0, leather_mat)
	hips_attach.add_child(belt)
	
	var buckle = MeshInstance3D.new()
	var bkb = BoxMesh.new()
	bkb.size = Vector3(8.0, 7.0, 2.0)
	buckle.mesh = bkb
	buckle.position = Vector3(0, 3.0, 15.0)
	var gold_mat = StandardMaterial3D.new()
	gold_mat.albedo_color = Color(0.96, 0.82, 0.22)
	gold_mat.metallic = 0.95
	buckle.set_surface_override_material(0, gold_mat)
	hips_attach.add_child(buckle)
	
	if role == "player":
		# Kuşağa Sokulu Gümüş Kakmalı Osmanlı Kaması / Hançeri
		var dagger = MeshInstance3D.new()
		var db = BoxMesh.new()
		db.size = Vector3(3.5, 26.0, 2.5)
		dagger.mesh = db
		dagger.position = Vector3(-16.0, 5.0, 14.0)
		dagger.rotation.z = 0.4
		var silver_mat = StandardMaterial3D.new()
		silver_mat.albedo_color = Color(0.9, 0.92, 0.95)
		silver_mat.metallic = 0.95
		dagger.set_surface_override_material(0, silver_mat)
		hips_attach.add_child(dagger)
		
		# Sağ Kalçada Deri Tabanca Kılıfı
		var holster = MeshInstance3D.new()
		var hb = BoxMesh.new()
		hb.size = Vector3(7.5, 22.0, 12.0)
		holster.mesh = hb
		holster.position = Vector3(23.0, -6.0, 2.0)
		holster.rotation.z = -0.15
		holster.set_surface_override_material(0, leather_mat)
		hips_attach.add_child(holster)

# ----------------- SOL KOL: HİLÂL-İ AHMER PAZUBENDİ -----------------
static func build_hilal_armband(skel: Skeleton3D) -> void:
	var arm_idx = skel.find_bone("mixamorig_LeftArm")
	if arm_idx == -1:
		return
		
	var arm_attach = BoneAttachment3D.new()
	arm_attach.name = "Ottoman_ArmAttachment"
	arm_attach.bone_name = "mixamorig_LeftArm"
	arm_attach.bone_idx = arm_idx
	skel.add_child(arm_attach)
	
	# Beyaz Kumaş Pazubent (cm ölçeğinde)
	var band = MeshInstance3D.new()
	var bcyl = CylinderMesh.new()
	bcyl.top_radius = 8.0
	bcyl.bottom_radius = 7.5
	bcyl.height = 11.5
	band.mesh = bcyl
	band.position = Vector3(0, 14.0, 0)
	var white_mat = StandardMaterial3D.new()
	white_mat.albedo_color = Color(0.96, 0.96, 0.96)
	white_mat.roughness = 0.8
	band.set_surface_override_material(0, white_mat)
	arm_attach.add_child(band)
	
	# Kırmızı Hilâl Sembolü
	var crescent = MeshInstance3D.new()
	var cc = CylinderMesh.new()
	cc.top_radius = 2.8
	cc.bottom_radius = 2.8
	cc.height = 1.0
	crescent.mesh = cc
	crescent.position = Vector3(-8.2, 14.0, 0)
	crescent.rotation.z = PI / 2.0
	var red_mat = StandardMaterial3D.new()
	red_mat.albedo_color = Color(0.85, 0.08, 0.08)
	crescent.set_surface_override_material(0, red_mat)
	arm_attach.add_child(crescent)

# ----------------- AYAKLAR: DERİ ZAPTİYE ÇİZMELERİ & CAMİ ÇORAPLARI -----------------
static func set_shoes_visible(root_node: Node, worn: bool) -> void:
	var skel: Skeleton3D = root_node.find_child("Skeleton3D", true, false)
	if not skel:
		return
	var body_mesh: MeshInstance3D = skel.get_node_or_null("vanguard_Mesh")
	if body_mesh:
		var mat = body_mesh.get_surface_override_material(0)
		if mat is ShaderMaterial:
			mat.set_shader_parameter("is_barefoot_or_socks", not worn)

