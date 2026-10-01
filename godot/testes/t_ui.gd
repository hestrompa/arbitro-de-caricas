extends SceneTree
var m
var n := 0
var stage := 0
var scen: Array = ["treino_var", "career_play", "partida"]
var kinds := {}
var last := ""
func _initialize():
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
func _process(dt: float) -> bool:
	n += 1
	if n < 5: return false
	if m.modo != last:
		last = m.modo
	if m.modo == "menu" or m.modo == "carreira":
		if stage >= scen.size():
			print("FIM DOS TESTES"); quit(); return true
		var a: String = scen[stage]; stage += 1
		print("== cenário ", a, " frame ", n)
		if a == "career_play": m.on_ui("carreira", null)
		m.on_ui(a, null)
		return false
	if m.modo in ["lance", "var"] and m.dec_shown and m.t > m.TC + 0.3:
		var L: Dictionary = m.L
		kinds[m.jogo.kind_of(L)] = kinds.get(m.jogo.kind_of(L), 0) + 1
		var ch: Array = m.jogo.choices_for(L)
		m._decide(L.truth if randf() < 0.7 else ch.pick_random())
	if m.modo == "gesto" and m.G.get("t", 0.0) > 0.4: m._end_gesture()
	if m.modo == "jogo" and m.jogo.mode == "pergunta": m.on_ui("ask", 0)
	if m.modo == "jogo" and m.jogo.mode == "protesto": m.on_ui("protest", "afastar")
	if m.modo == "intervalo": m.on_ui("second_half", "capitaes")
	if m.modo == "fim":
		print("fim: ", m.end_data.get("kind"), " nota ", m.end_data.get("grade"), " lances ", kinds, " frame ", n)
		print("  ", m.end_data.get("txt"))
		if m.is_career: print("  carreira: ", m.car.note)
		kinds = {}
		m.on_ui("menu", null)
	if n > 400000: print("demasiado"); quit(); return true
	return false
