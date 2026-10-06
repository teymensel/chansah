extends SceneTree

func _init():
	var sc = load("res://assets/models/Soldier.glb")
	var node = sc.instantiate()
	var skel = node.find_child("Skeleton3D", true, false)
	if skel:
		var head_idx = skel.find_bone("mixamorig_Head")
		var hips_idx = skel.find_bone("mixamorig_Hips")
		print("Bone global rest head: ", skel.get_bone_global_rest(head_idx).origin)
		print("Bone global rest hips: ", skel.get_bone_global_rest(hips_idx).origin)
		var char_node = node.get_node_or_null("Character")
		print("node scale: ", node.scale)
		if char_node:
			print("Character scale: ", char_node.scale)
		print("Skeleton scale: ", skel.scale)
		var mesh = skel.get_node_or_null("vanguard_Mesh")
		if mesh:
			print("vanguard_Mesh scale: ", mesh.scale)
			print("vanguard_Mesh aabb: ", mesh.get_aabb())
	quit()
