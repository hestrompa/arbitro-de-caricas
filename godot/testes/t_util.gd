extends SceneTree
var q: Array = []
func on_ev(n: String, d: Dictionary) -> void:
	if n in ["lance", "decided", "ask", "protest", "half", "var"]: q.append([n, d])
func _init():
	for i in 3:
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
					"ask": S.ask_pick(0)
					"protest": S.resolve_protest("capitao")
					"half": S.second_half("descanso")
		print("util ", int(S.util / S.MATCH_SECONDS * 90), " de ", int(S.t / S.MATCH_SECONDS * 90))
	quit()
