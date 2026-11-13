extends SceneTree
# Teste de cenário das jogadas ensaiadas de bola parada (motor novo das caricas).
# 1) Cantos: N cantos iguais para os Azuis, com as jogadas ensaiadas ligadas e desligadas (ensaio_k 0).
# 2) Livres laterais: N livres iguais a 30 m da linha de golo, junto à linha lateral, ligadas e desligadas.
# 3) Livres diretos: N livres a 25 m em frente à baliza, com o toque para o lado sempre e nunca.
# Conta-se, até 7 s depois do pontapé: se a bola chega ao alvo combinado, remates, ocasiões e golos.
# uso: godot --headless --path godot/projeto -s ../testes/t_ensaio.gd     (N=120 por omissão; TIPO=segundo força uma jogada)
# Passa se: aparecem todas as jogadas (5 nos cantos, 3 nos livres), a bola chega ao alvo combinado em pelo menos um sexto
# dos cantos e um terço dos livres, os golos ficam entre 3% e 20% das bolas paradas (sem as jogadas, com a área cheia ao
# acaso, mais de um terço dos cantos dava golo), e o toque para o lado no livre direto acaba em remate.
const AZ := {"gk": [6, 0], "lb": [60, -24], "lcb": [50, -8], "rcb": [50, 8], "rb": [60, 24], "lcm": [70, -12], "cm": [76, 4], "rcm": [72, 14], "lw": [93, -9], "st": [87, 0], "rw": [94, 8]}
const LA := {"gk": [102, 0], "lcb": [95, 5], "rcb": [95, -5], "lb": [92, 16], "rb": [92, -16], "lcm": [80, 9], "cm": [82, -8], "rcm": [78, -14], "lw": [66, 16], "st": [56, 0], "rw": [66, -18]}

func monta(S: Partida) -> void:
	for p in S.active():
		var q: Array = (AZ if p.team == 0 else LA).get(p.role, [50, 0])
		p.p = Vector2(S.abs_x(0, float(q[0])), S.H / 2 + float(q[1]))
		p.v = Vector2.ZERO; p.cd = 0.0; p.run = 0.0; p.reage = 0.0; p.down = 0.0; p.dest = Vector2(-1, -1); p.tackle_cd = 0.6
		p.dribble = Vector2.ZERO; p.set_piece = false; p.penalty = false
	S.owner = null; S.parado_dono = null; S.pause = 0.0; S.espera_todos = -1.0; S.poss_last = 0; S.last = 0; S.lance_cd = 99.0
	S.festa = {}; S.fk = {}; S.ask = {}

func resolve(S: Partida) -> void:
	match S.mode:
		"lance", "var": S.decide(str(S.lance.truth))
		"gesto": S.finish_after()
		"pergunta": S.ask_pick(int(S.ask.get("def", 0)))
		"protesto": S.resolve_protest("afastar")
		"intervalo": S.second_half("descanso")

func nova(k: int, af: Dictionary) -> Partida:
	var tm: Array = Carreira.default_teams()
	tm[0].rating = 70.0; tm[1].rating = 70.0
	var S := Partida.new(tm)
	S.rng.seed = 6000 + k
	S.dbg_on = true; S.af = af.duplicate()
	var g := 0
	while not (S.mode == "play" and S.parado_dono == null and S.t > 1.0 and S.dirs(0) != 0) and g < 4000:
		g += 1; resolve(S); S.tick(1.0 / 30.0)
	return S

# corre a bola parada até ao fim da jogada e junta o resultado a r
func corre(S: Partida, r: Dictionary) -> void:
	var d0: Dictionary = S.dbg.duplicate()
	var g0: int = S.score[0]; var rem0: int = S.est.remates[0]; var oc0: int = S.est.ocasioes[0]; var xg0: float = S.est.xg[0]
	var tipo: String = str(S.ensaio.get("tipo", "")) if not S.ensaio.is_empty() else ""
	if tipo != "": r.tipos[tipo] = int(r.tipos.get(tipo, 0)) + 1
	var tt := 0.0
	var bateu := -1.0
	var perdeu := 0.0
	while tt < 40.0:
		if S.mode != "play" or not S.ask.is_empty(): resolve(S)
		S.tick(1.0 / 30.0); tt += 1.0 / 30.0
		if bateu < 0.0:
			if S.parado_dono == null and S.fk.is_empty(): bateu = tt; r.espera += tt
			continue
		if S.score[0] > g0 or S.parado_dono != null or tt > bateu + 7.0: break
		if S.owner != null and S.owner.team == 1: perdeu += 1.0 / 30.0
		else: perdeu = 0.0
		if perdeu > 1.0: break
	if bateu >= 0.0: r.batidos += 1
	r.alvo += int(S.dbg.get("ens_remate", 0)) - int(d0.get("ens_remate", 0))
	r.remates += S.est.remates[0] - rem0
	r.ocasioes += S.est.ocasioes[0] - oc0
	r.xg += S.est.xg[0] - xg0
	r.golos += S.score[0] - g0
	r.golos_ens += int(S.dbg.get("golo_ensaio", 0)) - int(d0.get("golo_ensaio", 0))
	for kk in ["ens_xg", "golo_recarga", "golo_poste_golo", "parada", "parada_fora", "primeira", "ferro", "desvio", "ens_alivio", "ens_corta"]:
		r.dbg[kk] = float(r.dbg.get(kk, 0.0)) + float(S.dbg.get(kk, 0.0)) - float(d0.get(kk, 0.0))
	if S.score[0] > g0 and tipo != "": r.golos_tipo[tipo] = int(r.golos_tipo.get(tipo, 0)) + 1

func novo_r() -> Dictionary:
	return {"batidos": 0, "alvo": 0, "remates": 0, "ocasioes": 0, "xg": 0.0, "golos": 0, "golos_ens": 0, "tipos": {}, "golos_tipo": {}, "espera": 0.0, "dbg": {}}

func cantos(n: int, af: Dictionary) -> Dictionary:
	var r := novo_r()
	var S: Partida = null
	for k in n:
		if k % 20 == 0: S = nova(k, af)
		S.rng.seed = 9700 + k
		monta(S)
		S.corner(0, 0.5 if k % 2 == 0 else S.H - 0.5)
		S.lance_cd = 99.0
		corre(S, r)
	return r

func livres(n: int, af: Dictionary, direto: bool) -> Dictionary:
	var r := novo_r()
	var S: Partida = null
	for k in n:
		if k % 20 == 0: S = nova(k, af)
		S.rng.seed = 9800 + k
		monta(S)
		var lado := -1.0 if k % 2 == 0 else 1.0
		var at := Vector2(S.abs_x(0, 80.0), S.H / 2 + lado * 3.0) if direto else Vector2(S.abs_x(0, 75.0), S.H / 2 + lado * 25.0)
		var tk = S.active().filter(func(p): return p.team == 0 and p.role == "cm")[0]
		S.reset_ball(at)
		tk.p = at - Vector2(S.dirs(0) * 0.8, 0)
		S.owner = tk; S.last = 0; tk.cd = 0.9; tk.set_piece = true; S.parado_dono = tk
		for p in S.active():
			if p.team == 1 and p.p.distance_to(at) < 6.0: p.p = at + (p.p - at).normalized() * 6.0
		S.fk_check(tk)
		S.ensaio_livre(0, tk)
		corre(S, r)
	return r

func linha(nome: String, r: Dictionary, n: int) -> String:
	if OS.get_environment("DBG") != "": print("    ", r.dbg)
	return "  %s: batidos %d · bola no alvo %d · remates %d · ocasiões %d · xG %.1f · golos %d (ensaiados %d) · espera média %.1f s" % [nome, r.batidos, r.alvo, r.remates, r.ocasioes, r.xg, r.golos, r.golos_ens, r.espera / maxf(r.batidos, 1)]

func _initialize():
	var n := int(OS.get_environment("N")) if OS.get_environment("N") != "" else 120
	var base := {"motor2": 1.0}
	if OS.get_environment("LOG") != "": base["rem_log"] = 1.0
	if OS.get_environment("TIPO") != "": base["ensaio_tipo"] = OS.get_environment("TIPO")
	var sem := {"motor2": 1.0, "ensaio_k": 0.0}
	var c1 := cantos(n, base)
	var c0 := cantos(n, sem)
	print("Cantos: %d cantos iguais para os Azuis" % n)
	print(linha("com jogadas ensaiadas", c1, n))
	print("    jogadas: %s · golos por jogada: %s" % [str(c1.tipos), str(c1.golos_tipo)])
	print(linha("sem jogadas ensaiadas", c0, n))
	var l1 := livres(n, base, false)
	var l0 := livres(n, sem, false)
	print("Livres laterais: %d livres iguais a 30 m da linha de golo" % n)
	print(linha("com jogadas ensaiadas", l1, n))
	print("    jogadas: %s · golos por jogada: %s" % [str(l1.tipos), str(l1.golos_tipo)])
	print(linha("sem jogadas ensaiadas", l0, n))
	var m := maxi(n / 2, 30)
	var d1 := livres(m, {"motor2": 1.0, "ensaio_fk_lado": 1.0}, true)
	var d0 := livres(m, {"motor2": 1.0, "ensaio_fk_lado": 0.0}, true)
	print("Livres diretos: %d livres iguais a 25 m, em frente à baliza" % m)
	print(linha("toque para o lado", d1, m))
	print(linha("remate por cima da barreira", d0, m))
	var gc: float = float(c1.golos) / n
	var gl: float = float(l1.golos) / n
	print("Golos por bola parada: cantos %.0f%% · livres laterais %.0f%%" % [gc * 100.0, gl * 100.0])
	var ok: bool = c1.alvo >= n / 6 and l1.alvo >= n / 3 and gc >= 0.03 and gc <= 0.2 and gl >= 0.03 and gl <= 0.2 and d1.alvo > m / 2
	if OS.get_environment("TIPO") == "": ok = ok and c1.tipos.size() == 5 and l1.tipos.size() == 3
	print("PASSOU" if ok else "FALHOU")
	quit(0 if ok else 1)
