extends SceneTree
func _initialize():
	var m = load("res://main.tscn").instantiate()
	root.add_child(m)
	await process_frame
	var j = m.def
	for c in OS.get_environment("CLIPS").split(","):
		var an = j.anim.get_animation(c)
		print("== %s %.2f s" % [c, an.length])
		var tm := 0.0
		while tm < an.length:
			var r: Vector3 = j.clip_bone(c, tm, "root")
			var h: Vector3 = j.clip_bone(c, tm, "head")
			var fl: Vector3 = j.clip_bone(c, tm, "foot_L")
			var fr: Vector3 = j.clip_bone(c, tm, "foot_R")
			var wl: Vector3 = j.clip_bone(c, tm, "wrist_L")
			print("%.2f root(%.2f %.2f %.2f) head(%.2f %.2f %.2f) feetY %.2f %.2f  wristL(%.2f %.2f %.2f)" % [tm, r.x, r.y, r.z, h.x, h.y, h.z, fl.y, fr.y, wl.x, wl.y, wl.z])
			tm += 0.1
	quit()
