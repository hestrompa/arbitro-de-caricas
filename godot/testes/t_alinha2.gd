extends SceneTree
# Números: onde está a ação nas caricas (bola 2D) no instante do lance e onde o 3D a mostra.
var m
var n := 0
var fase := ""
var bp2 := Vector2.ZERO
var jogos := 0
func _initialize():
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
func _process(dt: float) -> bool:
	n += 1
	if n < 5: return false
	if m.modo == "menu":
		if jogos >= 2: quit(); return true
		jogos += 1; fase = ""; m.on_ui("partida", null); return false
	if m.modo == "flash" and fase != "flash":
		fase = "flash"
		bp2 = m.jogo.bp
		var L: Dictionary = m.L
		var k: String = m.jogo.kind_of(L)
		var extra := ""
		if k == "offside": extra = " ast3D %s ast2D %s" % [str(L.oi.ast), str(m.jogo.ast)]
		var a2: Vector2 = L.att.p if L.has("att") and L.att is Dictionary and L.att.has("p") else Vector2(-1, -1)
		print("%2d' %-8s P %s  bola2D %s (dist %.1f)  att2D %s (dist %.1f)%s" % [L.minute, k, str(L.P.round()), str(bp2.round()), bp2.distance_to(L.P), str(a2.round()), a2.distance_to(L.P), extra])
	if m.modo == "lance" and fase == "flash" and m.t > m.TC:
		fase = "tc"
		var a3: Vector3 = m.att.body_pos()
		print("      3D em TC: atacante %s (dist P %.1f) bola %s  olhar %s" % [str(Vector2(a3.x, a3.z).round()), Vector2(a3.x, a3.z).distance_to(m.P), str(Vector2(m.ball.position.x, m.ball.position.z).round()), str(m._focus().round())])
	if m.modo in ["lance", "var"] and m.dec_shown and m.t > m.TC + 0.3:
		fase = ""; m._decide(m.L.truth)
	if m.modo == "gesto" and m.G.get("t", 0.0) > 0.4: m._end_gesture()
	if m.modo == "jogo":
		if m.jogo.mode == "pergunta": m.on_ui("ask", 0)
		if m.jogo.mode == "protesto": m.on_ui("protest", "afastar")
	if m.modo == "intervalo": print("---- intervalo"); m.on_ui("second_half", "capitaes")
	if m.modo == "fim": m.on_ui("menu", null)
	if n > 300000: quit(); return true
	return false
