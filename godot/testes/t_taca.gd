extends SceneTree
# taça: força empate no fim, prolongamento e desempate por penáltis (decide sempre a verdade)
func _initialize():
	var n := int(OS.get_environment("N")) if OS.get_environment("N") != "" else 3
	for j in n:
		var S := Partida.new(Carreira.default_teams())
		S.taca = true
		var guard := 0
		var viu_prol := false
		var lances_pen := 0
		while S.mode != "fim" and guard < 60000:
			guard += 1
			if S.prol == 0 and S.t > Partida.MATCH_SECONDS * 0.98: S.score = [1, 1]
			if S.prol == 2 and S.t - S.prol_t0 > Partida.PROL_SECONDS * 0.98 and S.desempate.is_empty(): S.score = [1, 1]
			if S.prol > 0: viu_prol = true
			match S.mode:
				"lance":
					if S.lance.get("desempate", false): lances_pen += 1
					S.decide(str(S.lance.truth))
				"gesto": S.finish_after()
				"pergunta": S.ask_pick(int(S.ask.get("def", 0)))
				"protesto": S.resolve_protest("afastar")
				"intervalo": S.second_half("descanso")
			S.tick(1.0 / 30.0)
		var D: Dictionary = S.desempate
		print("jogo ", j, " fim=", S.mode, " t=", snappedf(S.t, 0.1), " prol=", viu_prol, " min=", S.minute(), " pen ", D.get("g", []), " n ", D.get("n", []), " res ", D.get("res", []), " lances3d ", lances_pen)
		for f in S.feed_list.slice(-6): print("   ", f.min, " ", f.txt)
	quit()
