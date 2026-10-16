extends SceneTree
func _initialize():
	var S := Partida.new(Carreira.default_teams())
	S.dbg_on = true
	var guard := 0
	var parado := 0.0
	var lt := -1.0
	while S.mode != "fim" and guard < 30000:
		guard += 1
		match S.mode:
			"lance": S.decide(str(S.lance.truth))
			"gesto": S.finish_after()
			"pergunta": S.ask_pick(int(S.ask.get("def", 0)))
			"protesto": S.resolve_protest("afastar")
			"intervalo": S.second_half("descanso")
			"var": S.decide(str(S.lance.truth))
		S.tick(1.0 / 30.0)
		if S.mode == "play" and S.t == lt: parado += 1.0 / 30.0
		else: parado = 0.0
		lt = S.t
		if parado > 15.0:
			var pd = S.parado_dono
			print("PRESO t=", S.t, " pd ", pd.num if pd else -1, " role ", pd.role if pd else "", " p ", pd.p if pd else Vector2.ZERO, " dest ", pd.dest if pd else Vector2.ZERO, " dest_t ", pd.dest_t if pd else 0.0, " espera ", S.espera_todos, " troca ", S.troca_gr, " pausa ", S.pause, " festa ", S.festa.size(), " fk ", S.fk.size(), " owner ", S.owner.num if S.owner else -1, " bp ", S.bp)
			var n := 0
			for p in S.active():
				if p.dest.x >= 0: n += 1
			for p in S.active():
				if p.dest.x >= 0: print("   ", p.num, " t", p.team, " ", p.role, " p ", p.p, " dest ", p.dest, " dt ", p.dest_t, " v ", p.v, " down ", p.down, " reage ", p.reage)
			print("  com dest ", n, " feed ", S.feed_list.slice(-2).map(func(x): return x.txt))
			break
	print("fim t=", S.t)
	quit()
