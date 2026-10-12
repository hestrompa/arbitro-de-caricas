extends SceneTree
func _init():
	for c in [0, 1]:
		var S := Partida.new(Carreira.default_teams())
		for i in 30: S.tick(1.0 / 60)
		S.ask = {}; S.mode = "play"; S.taca = true; S.score = [1, 1]; S.prol = 2
		S.players[15].off = true      # um vermelho nos Laranjas
		S.inicia_desempate()
		S.ask_pick(0)                 # sorteio
		print(S.ask.get("opts", []).map(func(o): return o.label))
		var pick := 0
		for k in S.ask.opts.size():
			if (S.ask.opts[k].d == "reduz") == (c == 0): pick = k
		S.ask_pick(pick)
		print("  ", S.manage.back().what, " · ", S.manage.back().dec, " ", S.manage.back().pts, " ordem ", S.desempate.ordem[0].size(), "/", S.desempate.ordem[1].size())
		var n := 0
		while S.desempate.get("tk", -1) == -1 and n < 600:
			S.tick(1.0 / 60); n += 1
		print("  primeiro penálti tk=", S.desempate.tk)
	quit()
