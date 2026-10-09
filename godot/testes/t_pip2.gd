extends SceneTree
# a câmara do passe tem de desaparecer quando o jogo volta às caricas
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
	while m.modo != "jogo" or m.jogo.mode != "play": await process_frame
	var J: Partida = m.jogo
	J.lance_cd = 0
	var r = pl(0, "st"); var ps = pl(0, "cm")
	for q in J.players:
		if q.team == 1 and q.role != "gk": q.p.x = min(q.p.x, 80.0)
	pl(1, "lcb").p = Vector2(80, 30); pl(1, "rcb").p = Vector2(79.5, 40)
	r.p = Vector2(80.2, 33); r.v = Vector2(6, 0); ps.p = Vector2(62, 36); ps.v = Vector2(3, 0)
	J.bp = ps.p; J.offside_snap(ps, r); var oi = J.off_info; J.off_info = {}
	J.start_offside(oi)
	while not (m.modo in ["lance", "var"]): await process_frame
	while m.t < m.TC + 0.2: await process_frame
	print("no lance: pip visível = ", m.pip_box.visible)
	var n := 0
	while m.modo != "jogo" and n < 3000:
		n += 1
		if m.modo == "gesto": m._end_gesture()
		if m.jogo.mode == "pergunta": m.on_ui("ask", 0)
		if m.jogo.mode == "protesto": m.on_ui("protest", "afastar")
		if m.modo == "lance" and m.dec_shown: m._decide(m.L.truth)
		if m.modo == "var": m._decide(m.L.truth)
		await process_frame
	for i in 10: await process_frame
	print("de volta às caricas (", m.modo, "): pip visível = ", m.pip_box.visible)
	quit()
