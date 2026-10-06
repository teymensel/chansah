extends SceneTree

const CharacterStyler = preload("res://scripts/character_styler.gd")

func _init():
	var scene = load("res://assets/models/Soldier.glb")
	if scene:
		var node = scene.instantiate()
		CharacterStyler.style_character(node, "player")
		print("CharacterStyler applied to player without errors!")
		var node2 = scene.instantiate()
		CharacterStyler.style_character(node2, "pasha")
		print("CharacterStyler applied to pasha without errors!")
	quit()

func print_hierarchy(node: Node, depth: int):
	var indent = ""
	for i in range(depth):
		indent += "  "
	print(indent, node.name, " (", node.get_class(), ")")
	if node is MeshInstance3D:
		print(indent, "  Mesh: ", node.mesh, " surface_count: ", node.mesh.get_surface_count() if node.mesh else 0)
		for s in range(node.mesh.get_surface_count() if node.mesh else 0):
			print(indent, "    mat ", s, ": ", node.get_surface_override_material(s), " mesh_mat: ", node.mesh.surface_get_material(s))
	for c in node.get_children():
		print_hierarchy(c, depth + 1)
