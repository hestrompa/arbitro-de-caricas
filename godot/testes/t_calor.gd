extends SceneTree
# calor: pausas de hidratação por volta dos 30' e dos 75', na primeira bola parada
var q: Array = []
func on_ev(n: String, d: Dictionary) -> void:
	if n in ["lance", "decided", "ask", "protest", "half", "var"]: q.append([n, d])
func _init():
	for i in 3:
		var S := Partida.new(Carreira.default_teams())
		S.clima = "calor"; S.temp = 35
		S.ev = on_ev
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
						if e[1].tag == "Calor extremo": print("  ", S.minute(), "' ", e[1].msg); S.ask_pick(i % 3)
						else: S.ask_pick(0)
					"protest": S.resolve_protest("capitao")
					"half": S.second_half("descanso")
		print("jogo ", i, " ", S.manage.filter(func(x): return str(x.what).begins_with("Calor")).map(func(x): return [x.minute, x.dec, x.pts]))
	quit()
