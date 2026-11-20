extends SceneTree
# Golo em revisão (falta antes do remate, cena 3D "golo"): o remate tem de entrar na baliza, porque no 2D foi golo.
# CASO=golo (falta antes do remate) | linha (bola em cima da linha, golo dado no 2D). N cenas seguidas, OUT para imagens.
var m
var n := 0
var fase := ""
var k := 0
var feitos := 0
var dentro := 0
var OUT := OS.get_environment("OUT")
var CASO := OS.get_environment("CASO") if OS.get_environment("CASO") != "" else "golo"
var N := int(OS.get_environment("N")) if OS.get_environment("N") != "" else 4
var maxz := 0.0
var passou := false
func _initialize():
	if OUT != "": DirAccess.make_dir_recursive_absolute(OUT)
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
func _process(dt: float) -> bool:
	n += 1
	if n == 5: m.on_ui("partida", null); return false
	if n < 60: return false
	var J = m.jogo
	if n % 150 == 0: print("  n=%d modo=%s jogo=%s fase=%s t=%.1f" % [n, m.modo, J.mode, fase, J.t])
	if m.modo == "jogo" and J.mode == "pergunta": m.on_ui("ask", 0)
	if m.modo == "jogo" and J.mode == "protesto": m.on_ui("protest", "afastar")
	if m.modo == "jogo" and fase == "" and J.mode == "play" and J.pause <= 0 and J.festa.is_empty() and J.t > 3.0:
		J.lance_cd = 99
		var st = J.active().filter(func(p): return p.role == "st" and p.team == 0)[0]
		var gx: float = J.opp_goal_x(0)
		st.p = Vector2(J.abs_x(0, 88.0), 34.0 + randf_range(-8, 8))
		J.shot_from = st.p; J.kicker = st; J.bp = Vector2(gx, 34.0 + randf_range(-3, 3))
		var ok: bool = J.start_goal_foul(0, st) if CASO == "golo" else J.start_line(0, st, "entrou", false)
		if not ok: print("não abriu a cena"); quit(1); return true
		fase = "cena"; k = 0; passou = false; maxz = 0.0
	if fase == "cena" and m.modo == "lance":
		var b: Vector3 = m.b3
		var gx3: float = float(m.sc.gx); var di: float = float(m.sc.dir_in)
		if (b.x - gx3) * di > 0.11 and absf(b.z - J.H / 2) < J.GOAL_W / 2 and b.y < 2.44: passou = true
		maxz = maxf(maxz, (b.x - gx3) * di)
		if OUT != "" and m.t >= m.TC - 0.2 + k * 0.12 and k < 22:
			root.get_viewport().get_texture().get_image().save_png(OUT + "%d_%02d.png" % [feitos, k]); k += 1
		if m.t > m.TC + 2.6:
			feitos += 1
			# a bola tem de acabar dentro da baliza (no 2D foi golo), não só passar a linha e voltar
			if (b.x - gx3) * di < 0.11: passou = false
			if passou: dentro += 1
			print("cena %d (%s, verdade %s): bola %s · mais fundo %.2f m depois da linha · b3 final %s" % [feitos, CASO, m.sc.truth, "ENTROU" if passou else "NÃO ENTROU", maxz, str(b.snapped(Vector3(0.01, 0.01, 0.01)))])
			m._decide(str(m.L.dflt)); fase = "dec"
	if fase == "dec" and m.modo == "var":
		k += 1
		if k > 20: m._decide(str(m.L.truth)); k = 0
	if fase == "dec" and m.modo == "ir_var": m.IV.t = 99.0
	if fase == "dec" and m.modo == "gesto":
		if m.G.get("t", 0.0) > 1.0: m._end_gesture()
	if fase == "dec" and m.modo == "jogo":
		fase = ""
		if feitos >= N:
			print("%d de %d remates entraram" % [dentro, feitos])
			print("PASSOU" if dentro == feitos else "FALHOU")
			quit(0 if dentro == feitos else 1); return true
	if n > 20000: print("FALHOU: tempo esgotado em ", fase, " modo ", m.modo); quit(1); return true
	return false
