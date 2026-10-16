extends SceneTree
# guarda-redes expulso: sai um jogador e entra o suplente a pé (ou um colega veste a camisola sem substituições)
func _initialize():
	for caso in ["suplente", "sem_subs"]:
		var S := Partida.new(Carreira.default_teams())
		S.lance_cd = 999
		for i in 300: S.tick(1.0 / 30.0)
		while S.mode != "play": S.tick(1.0 / 30.0); if S.mode == "pergunta": S.ask_pick(0)
		if caso == "sem_subs": S.subs[1].n = 5
		var gk: Partida.Pl = null
		for p in S.active():
			if p.team == 1 and p.role == "gk": gk = p
		gk.off = true
		var n0 := S.active().size()
		var visto := ""
		var tmax := 0.0
		var pos := {}
		var salto := 0.0
		for i in 900:
			if S.mode == "pergunta": S.ask_pick(0)
			if S.mode == "lance": S.decide(str(S.lance.truth))
			if S.mode == "gesto": S.finish_after()
			S.tick(1.0 / 30.0)
			for p in S.active():
				if pos.has(p.id) and S.mode == "play": salto = maxf(salto, p.p.distance_to(pos[p.id]))
				pos[p.id] = p.p
			if not S.troca_gr.is_empty(): visto = str(S.troca_gr.fase); tmax += 1.0 / 30.0
		var novo: Partida.Pl = null
		for p in S.active():
			if p.team == 1 and p.role == "gk": novo = p
		print(caso, ": activos ", n0, " -> ", S.active().size(), " novo gr ", novo.num if novo else -1, " em ", novo.p if novo else Vector2.ZERO, " fase ", visto, " troca durou ", snappedf(tmax, 0.1), " s, maior passo ", snappedf(salto, 0.01), " m, subs ", S.subs[1].n, " feed ", S.feed_list.slice(-3).map(func(x): return x.txt))
		print("  expulso a sair: ", gk.sai_p)
	quit()
