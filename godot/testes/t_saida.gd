extends SceneTree
# Pontapé de saída: quanto tempo (de jogo) fica a bola parada no centro até ser batida.
var m
var n := 0
var t0 := -1.0
var saidas := 0
var piores := 0.0
func _initialize():
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
func _process(dt: float) -> bool:
	n += 1
	if n < 5: return false
	if m.modo == "menu": m.on_ui("partida", null); return false
	var j = m.jogo
	if j == null: return false
	if m.modo == "jogo":
		if j.mode == "pergunta": m.on_ui("ask", 0)
		if j.mode == "protesto": m.on_ui("protest", "afastar")
	if m.modo in ["flash", "lance", "var"] and m.get("dec_shown") and m.t > m.TC + 0.3: m._decide(m.L.truth)
	if m.modo == "gesto" and m.G.get("t", 0.0) > 0.4: m._end_gesture()
	if m.modo == "intervalo": m.on_ui("second_half", "capitaes")
	var centro: bool = j.bp.distance_to(Vector2(j.W / 2, j.H / 2)) < 0.05 and j.parado_dono != null
	if centro and t0 < 0: t0 = j.t
	elif not centro and t0 >= 0:
		var d: float = j.t - t0
		saidas += 1; piores = maxf(piores, d)
		print("saída %d: bola parada %.1f s de jogo" % [saidas, d])
		t0 = -1.0
	if saidas >= 6 or m.modo == "fim" or n > 60000:
		print("pior: %.1f s" % piores); quit(); return true
	return false
