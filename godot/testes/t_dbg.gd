extends SceneTree
func _initialize():
	var m = load("res://main.tscn").instantiate()
	root.add_child(m)
	await process_frame
	var a = m.fan_mesh.surface_get_arrays(0)
	var c = a[Mesh.ARRAY_COLOR]
	print("ncol=", c.size() if c else -1, " fmt=", m.fan_mesh.surface_get_format(0) & Mesh.ARRAY_FORMAT_COLOR)
	if c: print(c[0], c[40], c[80], c[c.size()-1])
	quit()
