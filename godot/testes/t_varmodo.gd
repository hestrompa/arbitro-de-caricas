extends SceneTree
# Sala do VAR: um jogo inteiro sem perguntas novas (vistoria, descontos, anúncio) e sem encravar
var q: Array = []
func on_ev(n: String, d: Dictionary) -> void:
	if n in ["lance", "decided", "ask", "protest", "half", "var"]: q.append([n, d])
func _init():
	var tags := {}
	var S := Partida.new(Carreira.default_teams())
	S.var_mode = true; S.no_var = false; S.lance_k = 0.75
	S.ev = on_ev
	var steps := 0
	while S.mode != "fim" and steps < 60 * 60 * 12:
		steps += 1
		S.tick(1.0 / 60)
		while q.size():
			var e = q.pop_front()
			match e[0]:
				"lance", "var":
					var L: Dictionary = e[1].L
					S.decide(str(L.truth))
				"decided": S.finish_after()
				"ask": tags[e[1].tag] = tags.get(e[1].tag, 0) + 1; S.ask_pick(0)
				"protest": S.resolve_protest("capitao")
				"half": S.second_half("descanso")
	print("fim=", S.mode, " t=", int(S.t), " asks ", tags, " add_min ", S.add_min, " manage ", S.manage.map(func(x): return x.what))
	quit()
