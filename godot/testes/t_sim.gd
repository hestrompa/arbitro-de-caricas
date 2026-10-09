extends SceneTree
# Simula partidas só com o motor das caricas (sem 3D) e mede: resultado, posse, remates, passes, desarmes, faltas.
# RA/RB força das equipas, EA/EB estilo, N jogos, LANCES=0 para jogar sem lances.
func _initialize():
	var n := int(OS.get_environment("N")) if OS.get_environment("N") != "" else 10
	var ra := float(OS.get_environment("RA")) if OS.get_environment("RA") != "" else 70.0
	var rb := float(OS.get_environment("RB")) if OS.get_environment("RB") != "" else 70.0
	var sem := OS.get_environment("LANCES") == "0"
	var tot := {}
	var dbgt := {}
	var cal := {}
	var todas: Array = []
	var res := [0, 0, 0]
	var golos := [0, 0]
	var t0 := Time.get_ticks_msec()
	for j in n:
		var tm: Array = Carreira.default_teams()
		tm[0].rating = ra; tm[1].rating = rb
		if OS.get_environment("EA") != "": tm[0].estilo = OS.get_environment("EA")
		if OS.get_environment("EB") != "": tm[1].estilo = OS.get_environment("EB")
		var S := Partida.new(tm)
		S.dbg_on = true
		S.sem_ment = OS.get_environment("MENT") == "0"
		var guard := 0
		while S.mode != "fim" and guard < 40000:
			guard += 1
			if sem: S.lance_cd = 99.0
			match S.mode:
				"lance": S.decide(str(S.lance.truth))
				"gesto": S.finish_after()
				"pergunta": S.ask_pick(int(S.ask.get("def", 0)))
				"protesto": S.resolve_protest("afastar")
				"intervalo": S.second_half("descanso")
				"var": S.decide(str(S.lance.truth))
			S.tick(1.0 / 30.0)
		for k in S.dbg: dbgt[k] = dbgt.get(k, 0.0) + float(S.dbg[k])
		for k in S.calib:
			if not cal.has(k): cal[k] = [[0.0, 0, 0], [0.0, 0, 0], [0.0, 0, 0], [0.0, 0, 0], [0.0, 0, 0]]
			for b in 5:
				for x in 3: cal[k][b][x] += S.calib[k][b][x]
		todas.append_array(S.amostras)
		golos[0] += S.score[0]; golos[1] += S.score[1]
		res[0 if S.score[0] > S.score[1] else (2 if S.score[0] < S.score[1] else 1)] += 1
		for k in S.est:
			if not tot.has(k): tot[k] = [0.0, 0.0]
			tot[k][0] += float(S.est[k][0]); tot[k][1] += float(S.est[k][1])
		if OS.get_environment("V") != "": print("jogo %d: %d-%d  %s" % [j, S.score[0], S.score[1], str(S.est)])
		print("R %d %d" % [S.score[0], S.score[1]])
	var pos: float = tot.posse[0] / maxf(tot.posse[0] + tot.posse[1], 0.01) * 100
	print("== %d jogos  força %.0f vs %.0f  (%.1f s)" % [n, ra, rb, (Time.get_ticks_msec() - t0) / 1000.0])
	print("vitórias A %d  empates %d  vitórias B %d   golos/jogo %.2f - %.2f" % [res[0], res[1], res[2], golos[0] / float(n), golos[1] / float(n)])
	print("posse %.0f%% - %.0f%%" % [pos, 100 - pos])
	for k in ["remates", "alvo", "passes", "desarmes", "faltas", "cantos"]: print("%s/jogo  %.1f - %.1f" % [k, tot[k][0] / n, tot[k][1] / n])
	print("passes certos  %.0f%% - %.0f%%" % [tot.passes_ok[0] / maxf(tot.passes[0], 1) * 100, tot.passes_ok[1] / maxf(tot.passes[1], 1) * 100])
	var sdb := ""
	for k in dbgt: sdb += "%s %.1f  " % [k, dbgt[k] / n]
	print("escolhas/jogo: ", sdb)
	if OS.get_environment("AMOSTRAS") != "":
		var f := FileAccess.open(OS.get_environment("AMOSTRAS"), FileAccess.WRITE)
		f.store_string(JSON.stringify(todas))
	for k in cal:
		var row: String = str(k) + ":"
		for b in 5:
			var c: Array = cal[k][b]
			if c[2] > 0: row += "  prev %.2f real %.2f (%d)" % [c[0] / c[2], float(c[1]) / c[2], c[2]]
		print(row)
	quit()
