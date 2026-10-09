extends SceneTree
# Fim do jogo: com um penálti marcado no último segundo, o penálti é batido antes do apito final.
# CENA=1 usa o penálti em 3D.
var m
var n := 0
var feito := false
var batido := false
func _initialize():
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
func _process(dt: float) -> bool:
	n += 1
	if n < 5: return false
	if m.modo == "menu" and not feito: m.on_ui("partida", null); return false
	var j = m.jogo
	if m.modo == "jogo" and j.mode == "play" and not feito and n > 60:
		feito = true
		j.half = 1; j.add_min = 1
		j.t = j.MATCH_SECONDS * (1 + 1 / 90.0) - 0.05
		var att = null
		for p in j.active():
			if p.team == 0 and p.role == "st": att = p
		j.penalty(att, OS.get_environment("CENA") != "")
		print("penálti marcado aos %.2f (fim aos %.2f)" % [j.t, j.MATCH_SECONDS * (1 + 1 / 90.0)])
	if feito and j.bpen and not batido: batido = true; print("bola do penálti a caminho, t=%.2f" % j.t)
	if m.modo == "lance" and not batido: batido = true; print("penálti em 3D, t=%.2f" % j.t)
	if m.modo in ["lance", "var"] and m.dec_shown and m.t > m.TC + 0.3: m._decide(m.L.truth)
	if m.modo == "gesto" and m.G.get("t", 0.0) > 0.4: m._end_gesture()
	if m.modo == "jogo":
		if j.mode == "pergunta": m.on_ui("ask", 0)
		if j.mode == "protesto": m.on_ui("protest", "afastar")
	if feito and (m.modo == "fim" or j.mode == "fim"):
		print("FIM aos %.2f; penálti batido: %s; resultado %d-%d" % [j.t, str(batido), j.score[0], j.score[1]]); quit(); return true
	if n > 20000: print("sem fim?"); quit(); return true
	return false
