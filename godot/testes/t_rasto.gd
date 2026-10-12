extends SceneTree
# rasto de um jogo sem lances (só futebol): posições a cada 0,1 s num JSON para desenhar em Python
func _initialize():
	var tm: Array = Carreira.default_teams()
	tm[0].rating = 70.0; tm[1].rating = 70.0
	var S := Partida.new(tm)
	S.dbg_on = true
	var out := []
	var acc := 0.0
	var rem := 0
	var guard := 0
	var tmax := float(OS.get_environment("TMAX")) if OS.get_environment("TMAX") != "" else 135.0
	while S.mode != "fim" and S.t < tmax and guard < 40000:
		guard += 1
		S.lance_cd = 1e9
		match S.mode:
			"pergunta": S.ask_pick(int(S.ask.get("def", 0)))
			"protesto": S.resolve_protest("afastar")
			"gesto": S.finish_after()
			"intervalo": S.second_half("descanso")
		S.tick(1.0 / 30.0)
		acc += 1.0 / 30.0
		var ev := ""
		if S.est.remates[0] + S.est.remates[1] != rem: rem = S.est.remates[0] + S.est.remates[1]; ev = "remate"
		if acc >= 0.1 or ev != "":
			acc = 0.0
			var ps := []
			for p in S.players:
				if p.off: continue
				ps.append([p.team, p.role, snappedf(p.p.x, 0.1), snappedf(p.p.y, 0.1), 1 if p.run > 0 else 0, p.num, snappedf(p.alvo.x, 0.1), snappedf(p.alvo.y, 0.1)])
			out.append({"t": snappedf(S.t, 0.01), "b": [snappedf(S.bp.x, 0.1), snappedf(S.bp.y, 0.1), snappedf(S.bz, 0.1)], "o": S.owner.id if S.owner else -1, "ps": ps, "ev": ev, "sc": S.score.duplicate(), "d0": S.teams[0].dir})
	var f := FileAccess.open(OS.get_environment("OUT"), FileAccess.WRITE)
	f.store_string(JSON.stringify(out))
	print("frames ", out.size(), " remates ", S.est.remates, " golos ", S.score)
	quit()
