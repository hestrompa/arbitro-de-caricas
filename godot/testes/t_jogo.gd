extends SceneTree
var m
func _initialize():
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	await process_frame
	m._start_match()
	var n := 0; var frames := 0; var lowest := 99.0; var kinds := {}
	var decs := ["siga", "falta", "amarelo", "vermelho", "simulacao"]
	while m.modo != "fim" and frames < 60 * 900:
		await process_frame
		frames += 1
		if m.modo == "lance":
			for p in [m.att, m.def] + m.extras:
				if not p.rag and p.phase != "levantar":
					for q in p.gpts(): lowest = min(lowest, q[0].y - (q[2] if q[2] > 0.0 else q[1]))
			if m.decided == "" and m.t > m.TC + 2.0:
				var d = m.L.truth if randf() < 0.6 else decs[randi() % 5]
				kinds[m.cur.lance] = kinds.get(m.cur.lance, 0) + 1
				print("%d' %s → lance %d força %.2f limpo=%s sim=%s | %s | decidiu %s | dist %d" % [m.L.minute, m.L.truth, m.cur.lance, m.cur.force, m.cur.clean, m.cur.sim, m.outcome, d, int(m.L.dist)])
				m._decide(d)
				n += 1
	print("fim: modo=%s t=%.1f frames=%d golos %s lances %d tipos %s foras %d controlo %d nota %.1f mais_baixo %.3f" % [m.modo, m.jogo.t, frames, str(m.jogo.score), n, str(kinds), m.jogo.offsides, m.jogo.control, m.jogo.grade(), lowest])
	print(m.menu_lbl.text)
	quit()
