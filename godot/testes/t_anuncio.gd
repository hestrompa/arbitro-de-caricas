extends SceneTree
# anúncio ao estádio depois de uma revisão do VAR: aparece a pergunta e fica registado na gestão do jogo
var q: Array = []
var n_anuncio := 0
var vistos: Array = []
func on_ev(n: String, d: Dictionary) -> void:
	if n in ["lance", "decided", "ask", "protest", "half", "end", "var"]: q.append([n, d])
func run(S: Partida) -> void:
	S.ev = on_ev
	var steps := 0
	while S.mode != "fim" and steps < 60 * 60 * 12:
		steps += 1
		S.tick(1.0 / 60)
		while q.size():
			var e = q.pop_front()
			match e[0]:
				"lance":
					var L: Dictionary = e[1].L
					var ch: Array = S.choices_for(L)
					var errado: Array = ch.filter(func(x): return x != L.truth and S.needs_var(L, x))
					S.decide(errado.pick_random() if errado.size() else str(L.truth))
				"var":
					var L2: Dictionary = e[1].L
					S.decide(str(L2.truth))
				"decided": S.finish_after()
				"ask":
					if e[1].tag == "Anúncio ao estádio":
						n_anuncio += 1
						if vistos.size() < 4: vistos.append(e[1].msg + " | " + " / ".join(e[1].opts.map(func(o): return o.label + ": " + o.get("small", ""))))
						S.ask_pick(randi() % e[1].opts.size())
					else: S.ask_pick(0)
				"protest": S.resolve_protest("capitao")
				"half": S.second_half("descanso")
func _init():
	for i in 3:
		var S := Partida.new(Carreira.default_teams())
		run(S)
		var m: Array = S.manage.filter(func(x): return str(x.what).begins_with("Anúncio"))
		print("jogo ", i, " var_n=", S.var_n, " anuncios=", m.size(), " ", m.map(func(x): return [x.dec, x.pts]), " nota=", S.grade)
	print("perguntas de anúncio: ", n_anuncio)
	for v in vistos: print("  ", v)
	quit()
