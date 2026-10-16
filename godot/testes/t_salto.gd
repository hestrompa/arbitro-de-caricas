extends SceneTree
# caricas não podem saltar de sítio: mede deslocações impossíveis (> 0,6 m num passo de 1/30 s) em jogos inteiros
func _initialize():
	var n := int(OS.get_environment("N")) if OS.get_environment("N") != "" else 2
	var tot := 0
	var tipos := {}
	for j in n:
		var S := Partida.new(Carreira.default_teams())
		S.rng.seed = 100 + j
		var prev := {}
		var pm := ""
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
			var cur := {}
			for p in S.active(): cur[p.id] = p.p
			if S.mode == "play" and pm == "play":
				for id in cur:
					if prev.has(id) and cur[id].distance_to(prev[id]) > 0.6:
						tot += 1
						var k := "t=%d %s" % [int(S.t), S.players[id].role]
						if tipos.size() < 25: tipos[k] = cur[id].distance_to(prev[id])
						var pl = S.players[id]
						print("SALTO ", k, " de ", prev[id], " para ", cur[id], " dono ", S.owner == pl, " parado ", S.parado_dono == pl, " dest ", pl.dest, " bola ", S.bp, " pausa ", S.pause, " feed ", S.feed_list.back().txt if S.feed_list.size() else "")
			prev = cur; pm = S.mode
		print("jogo ", j, " golos ", S.score, " saltos ate agora ", tot)
	print("SALTOS ", tot, " ", tipos)
	quit()
