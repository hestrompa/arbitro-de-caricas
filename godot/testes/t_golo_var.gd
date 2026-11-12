extends SceneTree
# Golo com dúvida de fora de jogo (jogos com VAR): a jogada segue, o golo conta e festeja-se, o VAR verifica,
# o árbitro vai ao monitor em 3D (imagens em OUT) e a decisão (DEC=fora|emjogo) tira ou confirma o golo.
var m
var n := 0
var fase := ""
var k := 0
var s0 := 0
var t_ir := 0.0
var OUT := OS.get_environment("OUT")
var DEC := OS.get_environment("DEC") if OS.get_environment("DEC") != "" else "fora"
var falhas := 0
func ok(c: bool, txt: String) -> void:
	print(("  ok  " if c else "  FALHOU  ") + txt)
	if not c: falhas += 1
func _initialize():
	if OUT != "": DirAccess.make_dir_recursive_absolute(OUT)
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
func _process(dt: float) -> bool:
	n += 1
	if n == 5: m.on_ui("partida", null); return false
	if n < 60: return false
	var J = m.jogo
	if m.modo == "jogo" and J.mode == "pergunta": m.on_ui("ask", 0)
	if m.modo == "jogo" and J.mode == "protesto": m.on_ui("protest", "afastar")
	if m.modo == "jogo" and fase == "" and J.mode == "play" and J.pause <= 0 and J.festa.is_empty() and J.t > 3.0:
		J.no_var = false; J.lance_cd = 99
		var st = J.active().filter(func(p): return p.role == "st" and p.team == 0)[0]
		var pas = J.active().filter(func(p): return p.role != "gk" and p.team == 0 and p != st)[0]
		# o avançado recebe meio metro à frente do penúltimo defesa
		var defs: Array = J.active().filter(func(p): return p.team == 1)
		defs.sort_custom(func(a, b): return J.rel(0, a.p.x) > J.rel(0, b.p.x))
		var lx: float = maxf(J.rel(0, defs[1].p.x), J.W / 2 + 12.0)
		defs[1].p.x = J.abs_x(0, lx)
		st.p = Vector2(J.abs_x(0, lx + (0.5 if DEC == "fora" else -0.4)), 30.0)
		pas.p = Vector2(J.abs_x(0, lx - 14.0), 38.0); J.bp = pas.p
		J.offside_snap(pas, st)
		var oi: Dictionary = J.off_info
		J.off_info = {}
		print("margem ", snappedf(oi.margin, 0.01))
		J.atraso_band = {"oi": oi, "flag": false, "team": 0, "t": J.t}
		J.kicker = st; J.bp = Vector2(J.opp_goal_x(0), 34.0)
		s0 = J.score[0]
		J.goal(0)
		ok(J.score[0] == s0 + 1, "o golo conta logo (%d -> %d)" % [s0, J.score[0]])
		ok(not J.festa.is_empty() and not J.golo_pend.is_empty(), "há festejo e o golo fica em verificação")
		fase = "festa"
	if fase == "festa" and m.modo == "ir_var":
		ok(m.L.get("ja_dado", false) and J.mode == "lance", "depois do festejo o VAR chama o árbitro ao monitor")
		fase = "ir"; k = 0; t_ir = 0.0
	if fase == "ir" and m.modo == "ir_var":
		var tt: float = m.IV.t
		if OUT != "" and tt >= k * 0.3:
			root.get_viewport().get_texture().get_image().save_png(OUT + "iv_%02d.png" % k); k += 1
	if fase == "ir" and m.modo == "var":
		ok(true, "a revisão abre no monitor (escolhas: %s)" % str(J.choices_for(m.L)))
		fase = "var"; k = 0
	if fase == "var" and m.modo == "var":
		k += 1
		if k == 40 and OUT != "": root.get_viewport().get_texture().get_image().save_png(OUT + "monitor.png")
		if k > 45: m._decide(DEC); fase = "dec"
	if fase == "dec" and m.modo == "gesto":
		k += 1
		if OUT != "" and k % 12 == 0 and k < 140: root.get_viewport().get_texture().get_image().save_png(OUT + "gesto_%03d.png" % k)
		if m.G.get("t", 0.0) > 2.2: m._end_gesture()
	if fase == "dec" and m.modo == "jogo":
		if DEC == "fora": ok(J.score[0] == s0 and J.anulados == 1, "golo anulado: o marcador volta atrás (%d)" % J.score[0])
		else: ok(J.score[0] == s0 + 1, "golo confirmado: o marcador fica (%d)" % J.score[0])
		print("  lance: ", m.L.get("msg", J.incidents[-1].get("msg", "")), " pts ", J.incidents[-1].get("pts"))
		print("PASSOU" if falhas == 0 else "FALHOU (%d)" % falhas)
		quit(); return true
	if n > 6000: print("FALHOU: tempo esgotado em ", fase, " modo ", m.modo, " jogo ", J.mode); quit(); return true
	return false
