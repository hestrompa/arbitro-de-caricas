extends SceneTree
# descontos: pergunta aos 90', registo na gestão do jogo e o jogo acaba depois dos minutos escolhidos
var q: Array = []
func on_ev(n: String, d: Dictionary) -> void:
	if n in ["lance", "decided", "ask", "protest", "half", "var"]: q.append([n, d])
func _init():
	for i in 6:
		var S := Partida.new(Carreira.default_teams())
		S.ev = on_ev
		var msg := ""
		var steps := 0
		while S.mode != "fim" and steps < 60 * 60 * 12:
			steps += 1
			S.tick(1.0 / 60)
			while q.size():
				var e = q.pop_front()
				match e[0]:
					"lance", "var": S.decide(str(e[1].L.truth))
					"decided": S.finish_after()
					"ask":
						if e[1].tag == "Descontos": msg = e[1].msg + "  [" + " ".join(e[1].opts.map(func(o): return o.label)) + "]"; S.ask_pick(i % e[1].opts.size())
						else: S.ask_pick(0)
					"protest": S.resolve_protest("capitao")
					"half": S.second_half("descanso")
		var m: Array = S.manage.filter(func(x): return str(x.what).begins_with("Descontos"))
		print("jogo ", i, " add_min=", S.add_min, " added=", snappedf(S.added, 0.1), " fim t=", snappedf(S.t, 0.1), " ~min ", S.minute(), " ", m)
		print("   ", msg)
	quit()
