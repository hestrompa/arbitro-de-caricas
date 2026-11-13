extends SceneTree
# Teste de cenário das estrelas (motor novo das caricas).
# A estrela dos Azuis recebe a bola a 33 m da baliza, com um médio adversário pela frente, os centrais atrás dele
# e os colegas nas posições de ataque. Corre-se o mesmo lance N vezes (sementes fixas) com as jogadas da estrela
# ligadas (m2_est 1) e desligadas (m2_est 0: o mesmo jogador, com os mesmos atributos, a jogar como os outros)
# e conta-se quantas vezes remata, marca, dá um golo a marcar, passa pelo defesa e perde a bola.
# uso: godot --headless --path godot/projeto -s ../testes/t_estrela.gd     (N=80 por omissão; AF='{"m2_est_finta":0.5}' muda afinações)
# Passa se, com as jogadas da estrela: há mais golos da jogada, a estrela pesa em mais golos (marca ou assiste)
# e não perde mais vezes a bola (com 5% de folga).
const DUR := 9.0
const AZ := {"gk": [6, 0], "lb": [58, -24], "lcb": [48, -8], "rcb": [48, 8], "rb": [58, 24], "lcm": [62, -12], "cm": [72, -3], "rcm": [64, 12], "lw": [82, -20], "st": [87, 2], "rw": [82, 20]}
const LA := {"gk": [101, 0], "lcb": [89, 5], "rcb": [89, -5], "lb": [86, 20], "rb": [86, -20], "lcm": [70, 9], "cm": [77, -2], "rcm": [70, -11], "lw": [60, 16], "st": [52, 0], "rw": [60, -18]}

func cenario(S: Partida) -> Partida.Pl:
	for p in S.active():
		var q: Array = (AZ if p.team == 0 else LA).get(p.role, [50, 0])
		p.p = Vector2(S.abs_x(0, float(q[0])), S.H / 2 + float(q[1]))
		p.v = Vector2.ZERO; p.cd = 0.0; p.run = 0.0; p.reage = 0.0; p.down = 0.0; p.dest = Vector2(-1, -1); p.tackle_cd = 0.6
		p.dribble = Vector2.ZERO; p.set_piece = false; p.penalty = false
	var estrela = S.active().filter(func(p): return p.team == 0 and "estrela" in p.tr)[0]
	var cm = S.active().filter(func(p): return p.team == 0 and p.role == "cm")[0]
	if estrela != cm:
		var a: Vector2 = estrela.p; estrela.p = cm.p; cm.p = a
	S.reset_ball(estrela.p)
	S.owner = estrela; estrela.cd = 0.25; estrela.desde = 0.0
	S.parado_dono = null; S.pause = 0.0; S.espera_todos = -1.0
	S.poss_last = 0; S.last = 0
	S.lance_cd = 99.0
	return estrela

func resolve(S: Partida) -> void:
	match S.mode:
		"lance", "var": S.decide(str(S.lance.truth))
		"gesto": S.finish_after()
		"pergunta": S.ask_pick(int(S.ask.get("def", 0)))
		"protesto": S.resolve_protest("afastar")
		"intervalo": S.second_half("descanso")

func corre(af: Dictionary, n: int) -> Dictionary:
	var r := {"n": n, "remata": 0, "golo": 0, "dela": 0, "assiste": 0, "fintas": 0, "perdeu": 0, "perdeu_ela": 0, "parou": 0, "xg": 0.0}
	for k in n:
		var tm: Array = Carreira.default_teams()
		tm[0].rating = 70.0; tm[1].rating = 70.0
		var S := Partida.new(tm)
		S.rng.seed = 5000 + k
		S.dbg_on = true; S.af = af.duplicate()
		var g := 0
		while not (S.mode == "play" and S.parado_dono == null and S.t > 1.0 and S.dirs(0) != 0) and g < 4000:
			g += 1; resolve(S); S.tick(1.0 / 30.0)
		S.rng.seed = 9500 + k
		var e = cenario(S)
		var rem0: int = S.est.remates[0]; var gol0: int = S.score[0]; var xg0: float = S.est.xg[0]
		var f0: int = e.fintas; var g0: int = e.golos; var a0: int = e.assist
		var tt := 0.0
		var tinha := true
		while tt < DUR:
			if S.mode != "play": resolve(S)
			S.tick(1.0 / 30.0); tt += 1.0 / 30.0
			if S.est.remates[0] > rem0 or S.score[0] > gol0: break
			if S.owner and S.owner.team == 1 and S.owner.role != "gk":
				r.perdeu += 1
				if tinha: r.perdeu_ela += 1
				break
			if S.owner: tinha = S.owner == e
			if S.mode == "play" and S.parado_dono != null: r.parou += 1; break
		var extra := 0.0
		while extra < 2.0 and S.est.remates[0] > rem0 and S.score[0] == gol0:
			if S.mode != "play": resolve(S)
			S.tick(1.0 / 30.0); extra += 1.0 / 30.0
		if S.est.remates[0] > rem0: r.remata += 1
		if S.score[0] > gol0: r.golo += 1
		r.xg += float(S.est.xg[0]) - xg0
		r.dela += e.golos - g0; r.assiste += e.assist - a0; r.fintas += e.fintas - f0
	return r

func linha(nome: String, r: Dictionary) -> void:
	print("%-22s remata %3d%%  golo %3d%% (xG %.2f)  | a estrela marca %d, assiste %d, finta %d | perde a bola %d (a estrela %d), lance parado %d" %
		[nome, round(100.0 * r.remata / r.n), round(100.0 * r.golo / r.n), r.xg / r.n, r.dela, r.assiste, r.fintas, r.perdeu, r.perdeu_ela, r.parou])

func _initialize():
	var n := int(OS.get_environment("N")) if OS.get_environment("N") != "" else 80
	var af := {"motor2": 1.0}
	if OS.get_environment("AF") != "": af.merge(JSON.parse_string(OS.get_environment("AF")), true)
	var sem := af.duplicate(); sem["m2_est"] = 0.0
	var a := corre(sem, n)
	var b := corre(af, n)
	print("Estrela: %d lances iguais, a estrela com a bola a 33 m da baliza e um médio pela frente" % n)
	linha("a jogar como os outros", a)
	linha("com as suas jogadas", b)
	var ok: bool = b.golo > a.golo and b.dela + b.assiste > a.dela + a.assiste and b.perdeu_ela <= a.perdeu_ela + int(n * 0.05)
	print("PASSOU" if ok else "FALHOU")
	quit(0 if ok else 1)
