extends SceneTree
# Trajetória das mãos nos clips do guarda-redes (para escolher o instante em que a bola chega às mãos)
func _initialize():
	var m = load("res://main.tscn").instantiate()
	root.add_child(m)
	await process_frame
	var j = m.def
	for c in ["gk_scoop", "gk_catch", "gk_catch2"]:
		var an = j.anim.get_animation(c)
		print("== %s %.2f s" % [c, an.length])
		var tm := 0.0
		while tm < an.length:
			var r: Vector3 = j.clip_bone(c, tm, "root")
			var wl: Vector3 = j.clip_bone(c, tm, "wrist_L")
			var wr: Vector3 = j.clip_bone(c, tm, "wrist_R")
			var mid := (wl + wr) / 2
			print("%.2f root(%.2f %.2f %.2f) mãos(%.2f %.2f %.2f) afast %.2f" % [tm, r.x, r.y, r.z, mid.x, mid.y, mid.z, wl.distance_to(wr)])
			tm += 0.1
	quit()
