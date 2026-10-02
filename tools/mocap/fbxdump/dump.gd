extends SceneTree
# Lê cada FBX do Mixamo (importado pelo Godot) e grava as poses globais dos ossos a 30 fps.
func _initialize():
	await process_frame
	var out := {}
	var d := DirAccess.open("res://fbx")
	for f in d.get_files():
		if not f.ends_with(".fbx"): continue
		var ps = load("res://fbx/" + f)
		if ps == null: print("falhou ", f); continue
		var sc: Node = ps.instantiate()
		root.add_child(sc)
		await process_frame
		var sk: Skeleton3D = sc.find_children("*", "Skeleton3D", true, false)[0]
		var ap_list := sc.find_children("*", "AnimationPlayer", true, false)
		var names := []; var par := []; var rest_p := []; var rest_q := []
		for i in sk.get_bone_count():
			names.append(sk.get_bone_name(i)); par.append(sk.get_bone_parent(i))
			var g := sk.global_transform * sk.get_bone_global_rest(i)
			rest_p.append([g.origin.x, g.origin.y, g.origin.z])
			var q := g.basis.orthonormalized().get_rotation_quaternion(); rest_q.append([q.x, q.y, q.z, q.w])
		var rec := {"names": names, "parent": par, "rest_p": rest_p, "rest_q": rest_q, "fps": 30, "pos": [], "rot": []}
		if ap_list.size() > 0:
			var ap: AnimationPlayer = ap_list[0]
			var an_names := ap.get_animation_list()
			var an_name: String = an_names[0]
			for a in an_names:
				if a != "RESET": an_name = a
			var an := ap.get_animation(an_name)
			rec.anim = an_name; rec.length = an.length
			ap.play(an_name)
			var n := int(floor(an.length * 30.0)) + 1
			for k in n:
				ap.seek(min(k / 30.0, an.length), true)
				var fp := []; var fq := []
				for i in sk.get_bone_count():
					var g := sk.global_transform * sk.get_bone_global_pose(i)
					fp.append([g.origin.x, g.origin.y, g.origin.z])
					var q := g.basis.orthonormalized().get_rotation_quaternion(); fq.append([q.x, q.y, q.z, q.w])
				rec.pos.append(fp); rec.rot.append(fq)
		out[f.get_basename()] = rec
		print(f, " ossos ", names.size(), " frames ", rec.pos.size(), " anim ", rec.get("anim", "-"))
		sc.queue_free()
	var fa := FileAccess.open("res://dump.json", FileAccess.WRITE); fa.store_string(JSON.stringify(out)); fa.close()
	quit()
