extends SceneTree
# Linhas do fora de jogo no monitor do VAR (Lei 11): a linha vermelha sai da parte mais adiantada do atacante e a azul da
# parte mais adiantada do penúltimo adversário; contam cabeça, tronco, pernas e pés, braços e mãos não. Imagens em OUT.
var m
var OUT := OS.get_environment("OUT")
var falhas := 0
const OSSOS := ["head", "neck01", "clavicle_L", "clavicle_R", "spine03", "spine01", "upperleg01_L", "upperleg01_R", "lowerleg01_L", "lowerleg01_R", "foot_L", "foot_R"]
func ok(c: bool, txt: String) -> void:
	print(("  ok  " if c else "  FALHOU  ") + txt)
	if not c: falhas += 1
func pl(team, role):
	for p in m.jogo.players:
		if p.team == team and p.role == role: return p
func foto(nome: String) -> void:
	if OUT != "": root.get_viewport().get_texture().get_image().save_png(OUT + nome)
func _initialize():
	if OUT != "": DirAccess.make_dir_recursive_absolute(OUT)
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	for i in 10: await process_frame
	m.on_ui("partida", null)
	for i in 30: await process_frame
	for k in 4:
		while m.modo != "jogo" or m.jogo.mode != "play" or m.jogo.pause > 0:
			if m.modo == "gesto": m._end_gesture()
			if m.modo == "ir_var": m._ir_var_fim()
			if m.jogo.mode == "pergunta": m.on_ui("ask", 0)
			if m.jogo.mode == "protesto": m.on_ui("protest", "afastar")
			await process_frame
		var J: Partida = m.jogo
		J.no_var = false; J.lance_cd = 0
		var r = pl(0, "st"); var ps = pl(0, "cm"); var gk = pl(1, "gk")
		for q in J.players:
			if q.team == 1 and q.role != "gk": q.p.x = min(q.p.x, 80.0)
		pl(1, "lcb").p = Vector2(80, 30); pl(1, "rcb").p = Vector2(79.5, 40)
		# caso 3: o guarda-redes saiu da baliza e está à frente dos centrais; o penúltimo adversário passa a ser outro
		if k == 3:
			gk.p = Vector2(74.0, 34.0)
			for q in J.players:
				if q.team == 1 and q.role != "gk" and not (q.role in ["lcb", "rcb"]): q.p.x = min(q.p.x, 77.0)
		var mg: float = [-0.3, 0.1, 0.45, 0.2][k]
		r.p = Vector2(80 + mg, 33); r.v = Vector2(6, 0); ps.p = Vector2(62, 36)
		J.bp = ps.p; J.offside_snap(ps, r); var oi = J.off_info; J.off_info = {}
		J.start_offside(oi)
		while m.modo != "lance" or not m.dec_shown: await process_frame
		J.start_var(m.L, "emjogo")
		while m.modo == "ir_var":
			m._ir_var_fim()
			await process_frame
		while not m.sc.has("lines"): await process_frame
		for i in 3: await process_frame
		var sd: float = float(m.sc.dir)
		print("caso %d: 2D %.2f · %s · %s · margem 3D %.2f (%s)" % [k, mg, m.sc.true_txt[0], m.sc.true_txt[1], m.L.oi.margin, m.L.truth])
		ok(m.var_line[0] == m.sc.true_lines[0] and m.var_line[1] == m.sc.true_lines[1], "as linhas abrem logo no sítio medido")
		# conferência pelos ossos: nenhum osso que conta passa da linha, e o mais adiantado fica a menos de 20 cm dela
		for par in [[m.att, 0, "atacante"], [m.sc.line_j, 1, "penúltimo defesa"]]:
			var j = par[0]
			var mx := -INF
			for o in OSSOS: mx = maxf(mx, j.bone_world(o).x * sd)
			var lin: float = float(m.sc.true_lines[par[1]]) * sd
			ok(mx <= lin + 0.005 and lin - mx < 0.2, "%s: osso mais adiantado a %d cm da linha (por dentro)" % [par[2], int(round((lin - mx) * 100))])
			var mao: float = maxf(j.bone_world("wrist_L").x, j.bone_world("wrist_R").x * 1.0) * sd if sd > 0 else maxf(j.bone_world("wrist_L").x * sd, j.bone_world("wrist_R").x * sd)
			if mao > lin: print("      a mão do %s passa %d cm da linha e não conta" % [par[2], int(round((mao - lin) * 100))])
		if k == 3:
			ok(int(m.sc.line_j.get_meta("pid")) == pl(1, "rcb").id, "com o guarda-redes fora da baliza, o penúltimo adversário é o segundo central (o %d), não o mais recuado" % m.sc.line_j.num)
		m.cam_mode = 2
		for i in 4: await process_frame
		foto("linhas_%d_cima.png" % k)
		m.cam_mode = 3
		for i in 4: await process_frame
		foto("linhas_%d_rasante.png" % k)
		m._decide(str(m.L.truth))
		for i in 5: await process_frame
	print("PASSOU" if falhas == 0 else "FALHOU (%d)" % falhas)
	quit()
