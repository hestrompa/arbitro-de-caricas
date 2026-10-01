extends SceneTree
# Testa a medição do fora de jogo no corpo 3D: vários passes com margens 2D diferentes.
var m
func pl(team, role):
	for p in m.jogo.players:
		if p.team == team and p.role == role: return p
func _initialize():
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	for i in 10: await process_frame
	m.on_ui("partida", null)
	for i in 30: await process_frame
	for k in 6:
		while m.modo != "jogo" or m.jogo.mode != "play":
			if m.modo == "gesto": m._end_gesture()
			if m.jogo.mode == "pergunta": m.on_ui("ask", 0)
			if m.jogo.mode == "protesto": m.on_ui("protest", "afastar")
			if m.modo == "lance" and m.dec_shown: m._decide(m.L.truth)
			if m.modo == "var": m._decide(m.L.truth)
			await process_frame
		var J: Partida = m.jogo
		J.lance_cd = 0
		var r = pl(0, "st"); var ps = pl(0, "cm")
		for q in J.players:
			if q.team == 1 and q.role != "gk": q.p.x = min(q.p.x, 80.0)
		pl(1, "lcb").p = Vector2(80, 30); pl(1, "rcb").p = Vector2(79.5, 40)
		var mg := -0.6 + k * 0.24
		r.p = Vector2(80 + mg, 33); r.v = Vector2(6, 0); ps.p = Vector2(62, 36)
		J.bp = ps.p; J.offside_snap(ps, r); var oi = J.off_info; J.off_info = {}
		if oi.is_empty(): print("sem oi"); continue
		var m2: float = oi.margin
		J.start_offside(oi)
		while not (m.modo in ["lance", "var"]): await process_frame
		while m.t < m.TC + 0.05: await process_frame
		var t0 := Time.get_ticks_msec()
		var dv := Vector3(float(m.sc.dir), 0, 0)
		m.att.extreme(dv)
		print("dir ", m.sc.dir, " ball ", m.b3.x, " "); print("2D %.2f  3D %.2f  truth %s  linhas %s  centros att %.2f def %.2f  (medição %d ms)" % [m2, m.L.oi.margin, m.L.truth, str(m.sc.true_lines), m.att.node.position.x, m.def.node.position.x, Time.get_ticks_msec() - t0])
	quit()
