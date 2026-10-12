extends SceneTree
# medir o motor das caricas: N jogos sem árbitro a decidir mal (decide a verdade); imprime uma linha JSON por jogo
func _initialize():
	var n := int(OS.get_environment("N")) if OS.get_environment("N") != "" else 4
	var ra := float(OS.get_environment("RA")) if OS.get_environment("RA") != "" else 70.0
	var rb := float(OS.get_environment("RB")) if OS.get_environment("RB") != "" else 70.0
	for j in n:
		var tm: Array = Carreira.default_teams()
		tm[0].rating = ra; tm[1].rating = rb
		var S := Partida.new(tm)
		S.dbg_on = true
		if OS.get_environment("AF") != "": S.af = JSON.parse_string(OS.get_environment("AF"))
		var guard := 0
		while S.mode != "fim" and guard < 40000:
			guard += 1
			match S.mode:
				"lance": S.decide(str(S.lance.truth))
				"gesto": S.finish_after()
				"pergunta": S.ask_pick(int(S.ask.get("def", 0)))
				"protesto": S.resolve_protest("afastar")
				"intervalo": S.second_half("descanso")
				"var": S.decide(str(S.lance.truth))
			S.tick(1.0 / 30.0)
		var lk := {}
		for L in S.incidents: lk[str(L.get("kind", "?"))] = lk.get(str(L.get("kind", "?")), 0) + 1
		var o := {"golos": S.score.duplicate(), "dbg": S.dbg, "foras": S.offsides, "lances": lk}
		for k in S.est: o[k] = S.est[k]
		print("JSON ", JSON.stringify(o))
	quit()
