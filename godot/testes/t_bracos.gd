extends SceneTree
# Braços nos ciclos de corrida: posição dos pulsos e cotovelos em relação à anca, ao longo do ciclo
func _initialize():
	var m = load("res://main.tscn").instantiate()
	root.add_child(m)
	await process_frame
	var j = m.def
	for c in ["run", "jog", "idle"]:
		var an = j.anim.get_animation(c)
		print("== %s %.2f s" % [c, an.length])
		for i in 8:
			var tm: float = an.length * i / 8.0
			var r: Vector3 = j.clip_bone(c, tm, "root")
			var wl: Vector3 = j.clip_bone(c, tm, "wrist_L") - r
			var wr: Vector3 = j.clip_bone(c, tm, "wrist_R") - r
			var el: Vector3 = j.clip_bone(c, tm, "lowerarm01_L") - r
			var sl: Vector3 = j.clip_bone(c, tm, "upperarm01_L") - r
			var fl: Vector3 = j.clip_bone(c, tm, "foot_L") - r
			print("%.2f pulsoE(y %.2f z %.2f) pulsoD(y %.2f z %.2f) cotovE(y %.2f z %.2f) ombroE(y %.2f z %.2f) péE z %.2f" % [tm, wl.y, wl.z, wr.y, wr.z, el.y, el.z, sl.y, sl.z, fl.z])
	print(j.skel.get_bone_count())
	for i in j.skel.get_bone_count(): printraw(j.skel.get_bone_name(i), " ")
	print("")
	quit()
