extends SceneTree
func _init():
	var n: Node = load("res://assets/jogador.glb").instantiate()
	var sk: Skeleton3D = n.find_children("*", "Skeleton3D", true, false)[0]
	var names := []
	for i in sk.get_bone_count(): names.append(sk.get_bone_name(i))
	print(names)
	for m in n.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		print(mi.name, " surfaces ", mi.mesh.get_surface_count(), " skin ", mi.skin, " path ", mi.skeleton)
		for s in mi.mesh.get_surface_count():
			var a: Array = mi.mesh.surface_get_arrays(s)
			print(" verts ", (a[Mesh.ARRAY_VERTEX] as PackedVector3Array).size(), " bones ", (a[Mesh.ARRAY_BONES] as PackedInt32Array).size(), " fmt ", mi.mesh.surface_get_format(s) & Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS)
		if mi.skin: print(" binds ", mi.skin.get_bind_count(), " ", mi.skin.get_bind_name(0), " ", mi.skin.get_bind_bone(0))
	quit()
