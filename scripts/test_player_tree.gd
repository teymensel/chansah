extends SceneTree

func _init():
	quit()










func print_tree_nodes(node: Node, depth: int):
	var ind = ""
	for i in range(depth):
		ind += "  "
	print(ind + node.name + " (" + node.get_class() + ") vis=" + str(node.get("visible")) + " pos=" + str(node.get("position")))
	for c in node.get_children():
		print_tree_nodes(c, depth + 1)
