extends SceneTree
func _initialize():
	var m = load("res://main.tscn").instantiate()
	root.add_child(m)
	await process_frame
	var j: Jogador = m.att
	print(j.anim.get_animation_list())
	for nm in ["getup_back", "getup_front", "fall", "dive", "kick"]:
		var an := j.anim.get_animation(nm)
		print(nm, " len ", an.length)
		for k in 12:
			var tm := an.length * k / 11.0
			var f: Array = j.fk(nm, tm)
			var r: Vector3 = f[0].origin; var h: Vector3 = f[j.bi["head"]].origin
			var fl: Vector3 = f[j.bi["foot_L"]].origin; var fr: Vector3 = f[j.bi["foot_R"]].origin
			print("  t %.2f root %s head %s footL %s footR %s" % [tm, str(r.snapped(Vector3.ONE*0.01)), str(h.snapped(Vector3.ONE*0.01)), str(fl.snapped(Vector3.ONE*0.01)), str(fr.snapped(Vector3.ONE*0.01))])
	quit()
