extends SceneTree
var m
var KINDS = ["offside", "mao", "linha"]
const OUT = "/tmp/claude-0/-home-claude/03cb57f4-a453-5d33-87b7-2efcd6ebbd73/scratchpad/godot/t/k/"
func shot(n):
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png(OUT + n + ".png")
	print("shot ", n)
func pl(team, role):
	for p in m.jogo.players:
		if p.team == team and p.role == role: return p
func force(kind: String) -> void:
	var J: Partida = m.jogo
	J.lance_cd = 0
	J.ref = Vector2(60, 40)
	match kind:
		"foul":
			var a = pl(0, "st"); var d = pl(1, "lcb"); a.p = Vector2(55, 30); d.p = Vector2(56, 32); a.v = Vector2(5, 0)
			J.start_lance(a, d)
		"mao":
			var a = pl(0, "st"); var d = pl(1, "lcb"); a.p = Vector2(80, 34); d.p = Vector2(90, 33)
			J.start_hand(a, d)
		"canto":
			while J.mode == "play":
				J.lance_cd = 0; J.bp = Vector2(105, 0.5); J.corner_check(0, pl(0, "lw"), false)
		"aereo":
			var a = pl(0, "st"); var d = pl(1, "lcb"); a.p = Vector2(60, 30); d.p = Vector2(61, 32)
			while J.mode == "play":
				J.lance_cd = 0; J.aerial_check(pl(0, "cm"), a)
		"pisao":
			var a = pl(0, "st"); var d = pl(1, "lcb"); a.p = Vector2(60, 30); d.p = Vector2(59, 30); a.v = Vector2(2, 0)
			while J.mode == "play": J.stamp_check(a, d)
		"golo":
			var k = pl(0, "st"); k.p = Vector2(90, 30); J.shot_from = Vector2(90, 30); J.bp = Vector2(104, 33)
			J.start_goal_foul(0, k)
		"linha":
			var k = pl(0, "st"); J.shot_from = Vector2(92, 28); J.bp = Vector2(104, 33)
			J.start_line(0, k, "entrou", true)
		"offside":
			J.lance_cd = 0
			var r = pl(0, "st"); var ps = pl(0, "cm")
			for q in J.players:
				if q.team == 1 and q.role != "gk": q.p.x = min(q.p.x, 80.0)
			pl(1, "lcb").p = Vector2(80, 30); pl(1, "rcb").p = Vector2(79.5, 40)
			r.p = Vector2(80.3, 33); r.v = Vector2(6, 0); ps.p = Vector2(62, 36)
			J.bp = ps.p; J.offside_snap(ps, r); var oi = J.off_info; J.off_info = {}
			J.start_offside(oi)
func _initialize():
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	for i in 30: await process_frame
	await shot("00_menu")
	m.on_ui("carreira", null)
	for i in 5: await process_frame
	await shot("01_carreira")
	m.on_ui("partida", null)
	for i in 200: await process_frame
	await shot("02_campo")
	for kind in KINDS:
		while m.modo != "jogo" or m.jogo.mode != "play": 
			if m.modo == "gesto": m._end_gesture()
			if m.jogo.mode == "pergunta": m.on_ui("ask", 0)
			if m.jogo.mode == "protesto": m.on_ui("protest", "afastar")
			await process_frame
		force(kind)
		while not (m.modo in ["lance", "var"]): await process_frame
		while m.t < m.TC + 0.05: await process_frame
		await shot("1_%s_a_tua_vista" % kind)
		m.cam_mode = 1
		await shot("1_%s_ideal" % kind)
		m.cam_mode = 0
		while not m.dec_shown: await process_frame
		if kind == "offside":
			await shot("2_offside_decide")
			m._decide("emjogo" if m.L.truth == "fora" else "fora")
			if m.modo == "var":
				while m.t < m.TC: await process_frame
				for i in 5: await process_frame
				await shot("2_offside_var")
				m.var_line[0] += 0.3
				await shot("2_offside_var_linhas")
				m._decide(m.L.truth)
		else:
			await shot("2_%s_decide" % kind)
			m._decide(m.L.truth)
			if m.modo == "var":
				await shot("2_%s_var" % kind)
				m._decide(m.L.truth)
		if m.modo == "gesto":
			for i in 70: await process_frame
			await shot("3_%s_gesto" % kind)
			m._end_gesture()
		m.jogo.training = {}
	m.jogo.t = 151
	while m.modo != "intervalo":
		if m.modo == "gesto": m._end_gesture()
		await process_frame
	await shot("4_intervalo")
	m.on_ui("second_half", "descanso")
	m.jogo.t = 299.9
	while m.modo != "fim":
		if m.modo == "gesto": m._end_gesture()
		if m.modo in ["lance", "var"] and m.dec_shown: m._decide(m.L.truth)
		if m.jogo.mode == "pergunta": m.on_ui("ask", 0)
		if m.jogo.mode == "protesto": m.on_ui("protest", "afastar")
		await process_frame
	for i in 5: await process_frame
	await shot("5_relatorio")
	quit()
