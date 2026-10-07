extends SceneTree
# Corte limpo: a bola tem de estar no pé do defesa no instante do toque. Falta: a bola segue em frente.
var m
func _initialize():
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	for i in 10: await process_frame
	m.on_ui("treino3d", null)
	for i in 5: await process_frame
	for c in [["limpo", {"lance": 0, "force": 0.6, "sim": false, "clean": true, "phi": 50.0, "vD": 8.0}],
			["area_siga", {"lance": 0, "force": 0.6, "sim": false, "clean": true, "de_pe": true, "phi": 65.0, "vD": 7.2}],
			["falta", {"lance": 0, "force": 1.0, "sim": false, "clean": false, "phi": 50.0, "vD": 8.0}]]:
		for sd in [1.0, -1.0]:
			var cc: Dictionary = c[1].duplicate(); cc.side = sd
			m.cur = cc; m._restart()
			var dpe := 99.0; var dv := Vector2.ZERO; var bri := 0
			while m.t < m.TC + 0.3:
				await process_frame
				if not m.hit_done:
					var pe: Vector3 = m._bico_do_pe(m.def, Vector3(m.bpos.x, 0.11, m.bpos.y))
					var fd := 99.0
					for cp in m.def.capsulas():
						if cp[3] == "pe": fd = minf(fd, Jogador.seg_dist(cp[0], cp[1], m.ball.global_position, m.ball.global_position) - cp[2] - 0.11)
					dpe = fd
				elif dv == Vector2.ZERO: dv = m.bvel; bri = m.brilhos.size()
			print("%-10s %+d  pé-bola no toque %.2f m  bola sai %s (A=%s D=%s) brilhos %d" % [c[0], int(sd), dpe, str(dv.normalized()), str(m.A), str(m.D), bri])
	quit()
