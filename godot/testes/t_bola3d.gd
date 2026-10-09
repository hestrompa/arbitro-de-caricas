extends SceneTree
# Bola vs jogador no 3D (treino): distância da bola ao pé mais próximo do atacante, e no aéreo à cabeça em TC.
var m
func _initialize():
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	for i in 10: await process_frame
	m.on_ui("treino3d", null)
	for i in 5: await process_frame
	for c in [{"lance": 0, "force": 1.0, "side": 1.0, "sim": false, "clean": false, "phi": 50.0, "vD": 8.0},
			{"lance": 2, "force": 0.9, "side": 1.0, "sim": false, "clean": false},
			{"lance": 3, "force": 1.0, "side": 1.0, "sim": false, "clean": false},
			{"lance": 4, "force": 0.95, "side": 1.0, "sim": false, "clean": false, "phi": 172.0, "vD": 5.6}]:
		m.cur = c.duplicate(); m._restart()
		var s := "lance %d: " % c.lance
		while m.t < m.TC + 0.2:
			await process_frame
			if fmod(m.t, 0.3) < 0.017:
				var fl: Vector3 = m.att.bone_world("foot_L"); var fr: Vector3 = m.att.bone_world("foot_R")
				var b: Vector3 = m.ball.position
				var ab: Vector3 = m.att.body_pos()
				var ahead := Vector2(b.x - ab.x, b.z - ab.z).dot(m.A)
				s += "%.1f:%.1f/%.1f " % [m.t, minf(b.distance_to(fl), b.distance_to(fr)), ahead]
		print(s)
	quit()
