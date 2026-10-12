extends SceneTree
var q: Array = []
func on_ev(n: String, d: Dictionary) -> void:
	if n in ["lance", "decided", "ask", "protest", "half", "var"]: q.append([n, d])
func _init():
	var vistos := 0
	for i in 8:
		var S := Partida.new(Carreira.default_teams())
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
						if e[1].tag == "Jogador a sangrar": vistos += 1; print("  ", e[1].msg)
						if e[1].tag == "Jogador caído": S.ask_pick(1)
						else: S.ask_pick(i % e[1].opts.size())
					"protest": S.resolve_protest("capitao")
					"half": S.second_half("descanso")
		for x in S.manage.filter(func(x): return str(x.what).begins_with("Jogador a sangrar")): print("   ", x.dec, " ", x.pts)
	print("sangue: ", vistos)
	quit()
