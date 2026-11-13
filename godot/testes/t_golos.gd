extends SceneTree
# Teste de cenário dos golos variados (motor novo das caricas): ferros, recargas e chapéus.
# 1) Remates: o avançado remata N vezes de 18 m com colegas na área. Conta-se quantas bolas vão ao poste ou à barra,
#    se a bola fica viva dentro do campo depois do ferro, e quantos golos nascem de recargas (ferro ou defesa para a frente).
# 2) Chapéu: o avançado aparece isolado a 30 m, com a defesa toda atrás dele. Conta-se quantas vezes o guarda-redes sai,
#    quantos chapéus se tentam e quantos entram, com o chapéu ligado e desligado (chapeu_k 0).
# uso: godot --headless --path godot/projeto -s ../testes/t_golos.gd     (N=300 por omissão)
# Passa se: há bolas ao ferro e todas ficam vivas em campo, há golos de recarga, e só há chapéus (e golos de chapéu) com ele ligado.
const AZ := {"gk": [6, 0], "lb": [60, -24], "lcb": [50, -8], "rcb": [50, 8], "rb": [60, 24], "lcm": [70, -12], "cm": [76, 4], "rcm": [72, 14], "lw": [93, -9], "st": [87, 0], "rw": [94, 8]}
const LA := {"gk": [102, 0], "lcb": [95, 5], "rcb": [95, -5], "lb": [92, 16], "rb": [92, -16], "lcm": [80, 9], "cm": [82, -8], "rcm": [78, -14], "lw": [66, 16], "st": [56, 0], "rw": [66, -18]}
# chapéu: a defesa dos Laranjas ficou toda lá na frente e o avançado dos Azuis vai sozinho
const AZ2 := {"gk": [6, 0], "lb": [40, -24], "lcb": [30, -8], "rcb": [30, 8], "rb": [40, 24], "lcm": [50, -12], "cm": [52, 4], "rcm": [50, 14], "lw": [62, -22], "st": [75, 0], "rw": [62, 22]}
const LA2 := {"gk": [102, 0], "lcb": [63, 6], "rcb": [63, -6], "lb": [60, 20], "rb": [60, -20], "lcm": [52, 9], "cm": [50, -3], "rcm": [52, -14], "lw": [42, 16], "st": [38, 0], "rw": [42, -18]}

func monta(S: Partida, az: Dictionary, la: Dictionary) -> Partida.Pl:
	for p in S.active():
		var q: Array = (az if p.team == 0 else la).get(p.role, [50, 0])
		p.p = Vector2(S.abs_x(0, float(q[0])), S.H / 2 + float(q[1]))
		p.v = Vector2.ZERO; p.cd = 0.0; p.run = 0.0; p.reage = 0.0; p.down = 0.0; p.dest = Vector2(-1, -1); p.tackle_cd = 0.6
		p.dribble = Vector2.ZERO; p.set_piece = false; p.penalty = false
	var st = S.active().filter(func(p): return p.team == 0 and p.role == "st")[0]
	S.reset_ball(st.p)
	S.owner = st; st.cd = 0.3; st.desde = 0.0
	S.parado_dono = null; S.pause = 0.0; S.espera_todos = -1.0; S.poss_last = 0; S.last = 0; S.lance_cd = 99.0
	S.festa = {}
	return st

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
	S.rng.seed = 9700 + k
	return S

func remates(n: int) -> Dictionary:
	var r := {"ferro": 0, "viva": 0, "recarga": 0, "golos": 0, "frente": 0}
	var S: Partida = null
	for k in n:
		if k % 25 == 0: S = nova(k, {"motor2": 1.0})
		S.rng.seed = 9700 + k
		var st = monta(S, AZ, LA)
		var d0: Dictionary = S.dbg.duplicate()
		var g0: int = S.score[0]
		S.shoot(st, false, 0.1, S.active().filter(func(q): return q.team == 1))
		var tt := 0.0
		var bateu := false
		var t_ferro := -1.0
		while tt < 5.0:
			if S.mode != "play": resolve(S)
			S.tick(1.0 / 30.0); tt += 1.0 / 30.0
			if not bateu and int(S.dbg.get("ferro", 0)) > int(d0.get("ferro", 0)):
				bateu = true; t_ferro = tt; r.ferro += 1
			if bateu and t_ferro >= 0.0 and tt >= t_ferro + 0.15:
				t_ferro = -1.0
				if S.bp.x > 0.0 and S.bp.x < S.W and S.parado_dono == null: r.viva += 1
			if S.score[0] > g0 or (S.parado_dono != null and tt > 0.5): break
		r.frente += int(S.dbg.get("parada", 0)) - int(d0.get("parada", 0))
		r.recarga += int(S.dbg.get("golo_recarga", 0)) - int(d0.get("golo_recarga", 0))
		r.golos += S.score[0] - g0
	return r

func chapeus(n: int, af: Dictionary) -> Dictionary:
	var r := {"saiu": 0, "chapeu": 0, "golo_chapeu": 0, "golos": 0}
	var S: Partida = null
	for k in n:
		if k % 25 == 0: S = nova(k, af)
		S.rng.seed = 9900 + k
		var st = monta(S, AZ2, LA2)
		var gk = S.active().filter(func(p): return p.team == 1 and p.role == "gk")[0]
		var d0: Dictionary = S.dbg.duplicate()
		var g0: int = S.score[0]; var rem0: int = S.est.remates[0]
		var tt := 0.0
		var saiu := false
		while tt < 8.0:
			if S.mode != "play": resolve(S)
			S.tick(1.0 / 30.0); tt += 1.0 / 30.0
			if absf(gk.p.x - S.own_goal_x(1)) > 6.0: saiu = true
			if S.score[0] > g0 or (S.parado_dono != null and tt > 0.5): break
			if S.est.remates[0] > rem0 and S.owner != null: break
		if saiu: r.saiu += 1
		r.chapeu += int(S.dbg.get("chapeu", 0)) - int(d0.get("chapeu", 0))
		r.golo_chapeu += int(S.dbg.get("golo_chapeu", 0)) - int(d0.get("golo_chapeu", 0))
		r.golos += S.score[0] - g0
	return r

func _initialize():
	var n := int(OS.get_environment("N")) if OS.get_environment("N") != "" else 300
	var a := remates(n)
	print("Remates: %d remates iguais de 18 m" % n)
	print("  ao poste ou à barra %d (%.0f%%), a bola fica viva em campo em %d · defesas para a frente %d · golos %d, dos quais %d de recarga" %
		[a.ferro, 100.0 * a.ferro / n, a.viva, a.frente, a.golos, a.recarga])
	var m := maxi(n / 3, 40)
	var c1 := chapeus(m, {"motor2": 1.0})
	var c0 := chapeus(m, {"motor2": 1.0, "chapeu_k": 0.0})
	print("Chapéu: %d lances iguais, avançado isolado a 30 m da baliza" % m)
	print("  com chapéu:  o guarda-redes sai em %d · chapéus tentados %d, golos de chapéu %d · golos ao todo %d" % [c1.saiu, c1.chapeu, c1.golo_chapeu, c1.golos])
	print("  sem chapéu:  o guarda-redes sai em %d · chapéus tentados %d, golos de chapéu %d · golos ao todo %d" % [c0.saiu, c0.chapeu, c0.golo_chapeu, c0.golos])
	var ok: bool = a.ferro >= n * 0.03 and a.viva == a.ferro and a.recarga > 0 and c1.chapeu > 0 and c1.golo_chapeu > 0 and c0.chapeu == 0 and c1.saiu > m / 2
	print("PASSOU" if ok else "FALHOU")
	quit(0 if ok else 1)
