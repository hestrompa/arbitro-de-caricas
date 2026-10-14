extends SceneTree
# grava posições do jogo das caricas (sem árbitro a decidir mal) para ver o motor: uma linha JSON a cada 0,1 s
func _initialize():
	var tm: Array = Carreira.default_teams()
	var S := Partida.new(tm)
	S.dbg_on = true
	S.rng.seed = int(OS.get_environment("SEED")) if OS.get_environment("SEED") != "" else 7
	if OS.get_environment("AF") != "": S.af = JSON.parse_string(OS.get_environment("AF"))
	var t0 := float(OS.get_environment("T0")) if OS.get_environment("T0") != "" else 20.0
	var dur := float(OS.get_environment("DUR")) if OS.get_environment("DUR") != "" else 40.0
	var guard := 0
	var acc := 0.0
	while S.mode != "fim" and guard < 40000 and S.t < t0 + dur:
		guard += 1
		match S.mode:
			"lance": S.decide(str(S.lance.truth))
			"gesto": S.finish_after()
			"pergunta": S.ask_pick(int(S.ask.get("def", 0)))
			"protesto": S.resolve_protest("afastar")
			"intervalo": S.second_half("descanso")
			"var": S.decide(str(S.lance.truth))
		S.tick(1.0 / 30.0)
		acc += 1.0 / 30.0
		if S.t >= t0 and acc >= 0.1:
			acc = 0.0
			var ps := []
			for p in S.active(): ps.append([p.team, snappedf(p.p.x, 0.1), snappedf(p.p.y, 0.1), 1 if p == S.owner else 0, 1 if p.run > 0 else 0, p.role])
			print("F ", JSON.stringify({"t": snappedf(S.t, 0.1), "b": [snappedf(S.bp.x, 0.1), snappedf(S.bp.y, 0.1), snappedf(S.bz, 0.1)], "p": ps, "m": S.mode, "d0": S.teams[0].dir}))
	quit()
