extends SceneTree
func _initialize():
	var m = load("res://main.tscn").instantiate()
	root.add_child(m)
	await process_frame
	var a = m.fan_mesh.surface_get_arrays(0)
	var u2 = a[Mesh.ARRAY_TEX_UV2]
	var n := 0
	if u2: for v in u2: if v.x > 0.5: n += 1
	print("verts=", a[Mesh.ARRAY_VERTEX].size(), " uv2=", u2.size() if u2 else -1, " maos=", n)
	quit()
