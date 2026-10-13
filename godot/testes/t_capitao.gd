extends SceneTree
# protocolo do capitão: sinal "só o capitão", quem continua a protestar leva a pergunta do amarelo
var q: Array = []
func on_ev(n: String, d: Dictionary) -> void:
	if n in ["lance", "decided", "ask", "protest", "half", "var"]: q.append([n, d])
func _init():
	var n := 0; var np := 0
	for i in 6:
		var S := Partida.new(Carreira.default_teams())
		S.ev = on_ev
		var steps := 0
		while S.mode != "fim" and steps < 60 * 60 * 12:
			steps += 1
			S.tick(1.0 / 60)
			while q.size():
				var e = q.pop_front()
				match e[0]:
					"lance", "var": S.decide(str(e[1].L.truth) if randf() < 0.6 else "siga")
					"decided": S.finish_after()
					"ask":
						if e[1].tag == "Só o capitão fala": n += 1; print("  ", e[1].msg, " ", e[1].opts.map(func(o): return o.label))
						S.ask_pick(i % e[1].opts.size())
					"protest": np += 1; S.resolve_protest("so_capitao")
					"half": S.second_half("descanso")
		for x in S.manage.filter(func(x): return str(x.what).contains("sinal do capitão")): print("   ", x.dec, " ", x.pts, " ", x.why)
		for f in S.feed_list.filter(func(f): return str(f.txt).contains("sinal")): print("   feed ", f.txt)
		if S.mode != "fim": print("NAO ACABOU ", S.mode)
	print("protestos: ", np, "  teimosos: ", n)
	quit()
