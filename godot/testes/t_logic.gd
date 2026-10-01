extends SceneTree
var q: Array = []
var counts := {}
func on_ev(n: String, d: Dictionary) -> void:
	counts[n] = counts.get(n, 0) + 1
	if n in ["lance", "decided", "ask", "protest", "half", "end", "var"]: q.append([n, d])
func run(S: Partida, label: String) -> void:
	S.ev = on_ev
	var steps := 0
	var wait := 0.0
	while S.mode != "fim" and steps < 60 * 60 * 12:
		steps += 1
		S.tick(1.0 / 60)
		while q.size():
			var e = q.pop_front()
			match e[0]:
				"lance", "var":
					var L: Dictionary = e[1].L
					S.radio_lance(L)
					var ch: Array = S.choices_for(L)
					var d: String = L.truth if randf() < 0.7 else ch.pick_random()
					S.decide(d)
				"decided": S.finish_after()
				"ask": S.ask_pick(randi() % e[1].opts.size())
				"protest": S.resolve_protest(["ignorar", "afastar", "capitao", "amarelo"].pick_random())
				"half": S.second_half(["capitaes", "assist", "descanso"].pick_random())
	var kinds := {}
	for l in S.incidents: kinds[S.kind_of(l)] = kinds.get(S.kind_of(l), 0) + 1
	print(label, " fim=", S.over, " passos=", steps, " nota=", S.grade, " ", S.score, " incid=", kinds, " manage=", S.manage.size(), " feed=", S.feed_list.size(), " ev=", counts)
	for r in S.report_rows().slice(0, 4): print("  ", r.cells)
	counts = {}
func _init():
	var S := Partida.new(Carreira.default_teams())
	run(S, "normal")
	var T := Partida.new(Carreira.default_teams())
	T.start_training()
	run(T, "treino")
	var car := Carreira.new()
	car.new_career()
	for i in 3:
		var B := car.match_brief()
		print(B.comp, " ", B.lines)
		var P := Partida.new(Carreira.teams_for(B.h, B.a, car.C.tier))
		car.setup_match(P)
		run(P, "carreira")
		P.paper = Carreira.paper_of(P, P.grade, P.over)
		print(P.paper)
		print(car.after(P, P.grade, P.over))
	print(car.ref_table())
	print(car.discipline_rows())
	car.load_c(); print("load ok ", car.C.round)
	quit()
