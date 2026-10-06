extends SceneTree

func _init():
	var sc = load("res://assets/models/Soldier.glb")
	var node = sc.instantiate()
	var skel = node.find_child("Skeleton3D", true, false)
	var head_attach = skel.get_node_or_null("mixamorig_Head")
	if head_attach:
		print("head_attach bone_name: ", head_attach.bone_name)
		print("head_attach bone_idx: ", head_attach.bone_idx)
		print("head_attach child count: ", head_attach.get_child_count())
		for c in head_attach.get_children():
			print("  child: ", c.name, " pos: ", c.position)
	quit()
