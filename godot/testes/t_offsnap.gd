extends SceneTree
var m
const OUT = "/tmp/claude-0/-home-claude/03cb57f4-a453-5d33-87b7-2efcd6ebbd73/scratchpad/godot/t/k/"
func pl(team, role):
	for p in m.jogo.players:
		if p.team == team and p.role == role: return p
func shot(n):
	if DisplayServer.get_name() == "headless": print("shot ", n, " linhas ", m.sc.get("true_lines"), " cam ", m.cam_mode, " fov ", m.cam.fov, " pos ", m.cam.global_position, " att ", m.att.body_pos(), " def ", m.def.body_pos()); return
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png(OUT + n + ".png")
	print("shot ", n)
func _initialize():
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	for i in 10: await process_frame
	m.on_ui("partida", null)
	for i in 30: await process_frame
	for k in [0]:
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
			if q.team == 1 and q.role != "gk": q.p.x = min(q.p.x, 77.0)
		pl(1, "lcb").p = Vector2(80, 30); pl(1, "rcb").p = Vector2(79.5, 40)
		r.p = Vector2(80 + (-0.25 if k == 0 else -0.05), 33); r.v = Vector2(6, 0); ps.p = Vector2(62, 36)
		J.bp = ps.p; J.offside_snap(ps, r); var oi = J.off_info; J.off_info = {}
		J.start_offside(oi)
		while not (m.modo in ["lance", "var"]): await process_frame
		while not m.dec_shown: await process_frame
		var l = m.L
		print("margem ", l.oi.margin, " ", l.truth)
		m._decide(l.truth); print("decidi ", m.modo, " ", l.has("decided"))
		var n := 0
		while not l.has("decided") or m.modo in ["lance", "var", "gesto", "flash"]:
			if m.modo == "gesto": m._end_gesture()
			if m.modo == "var" and m.dec_shown: m._decide(m.L.truth)
			n += 1
			if n % 120 == 0: print("modo ", m.modo, " ", m.jogo.mode)
			await process_frame
		m._review(l)
		m.cam_mode = 4 if false else m.cam_mode
		print("rever ", m.modo, " t ", m.t)
		for i in 60: await process_frame
		print("depois ", m.modo, " t ", m.t, " p ", m.paused, " s ", m.speed, " ts ", Engine.time_scale, " tree ", paused)
		while m.t < m.TC: await process_frame
		print("em TC ", m.t)
		for i in 20: await process_frame
		await shot("off_rever_%d" % k)
		# vista de cima como o VAR
		m.modo = "var"; m.sc.lines = true; m.var_line = m.sc.true_lines.duplicate()
		for i in 3: await process_frame
		await shot("off_var_%d" % k)
		m.modo = "rever"; m._end_review()
	quit()
