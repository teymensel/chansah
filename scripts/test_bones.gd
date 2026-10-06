extends SceneTree

func _init():
	var sc = load("res://assets/models/Soldier.glb")
	var node = sc.instantiate()
	var skel = node.find_child("Skeleton3D", true, false)
	for b_name in ["mixamorig_Spine2", "mixamorig_Hips", "mixamorig_LeftArm"]:
		var idx = skel.find_bone(b_name)
		print(b_name, " idx=", idx, " rest_pos=", skel.get_bone_rest(idx).origin, " global_origin=", skel.get_bone_global_rest(idx).origin)
	quit()
