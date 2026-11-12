extends SceneTree
# Teste de cenário do contra-ataque (motor novo das caricas).
# Os Laranjas atacam com seis jogadores perto da área dos Azuis e perdem a bola para um médio azul.
# Corre-se o lance N vezes (sementes fixas) e conta-se quantas vezes os Azuis chegam ao último terço,
# rematam e marcam antes de perderem a bola, e com quanta gente chegam contra quantos defesas.
# O mesmo cenário corre sem contra-ataque (m2_ca 0) para comparar.
# uso: godot --headless --path godot/projeto -s ../testes/t_contra.gd      (N=40 por omissão; AF='{"m2_ca_dur":8}' muda afinações)
# Passa se, com contra-ataque: chega ao último terço em pelo menos 50% e remata em pelo menos 25% das vezes,
# e chega mais vezes do que sem contra-ataque.
const DUR := 11.0
# sítio de cada papel (metros a contar da baliza dos Azuis, y a contar do meio) -- Azuis a defender em bloco
const AZ := {"gk": [4, 0], "lb": [17, -20], "lcb": [14, -6], "rcb": [14, 6], "rb": [17, 20], "lcm": [25, -12], "cm": [24, 2], "rcm": [26, 13], "lw": [40, -24], "st": [46, 0], "rw": [40, 24]}
# Laranjas a atacar: dois centrais à entrada do meio-campo, laterais subidos, médios e avançados à volta da área
const LA := {"gk": [99, 0], "lcb": [56, 7], "rcb": [58, -8], "lb": [30, 27], "rb": [31, -27], "lcm": [28, 9], "cm": [34, 0], "rcm": [27, -8], "lw": [15, 17], "st": [12, 1], "rw": [16, -15]}

func cenario(S: Partida) -> void:
	for p in S.active():
		var q: Array = (AZ if p.team == 0 else LA).get(p.role, [50, 0])
		p.p = Vector2(S.abs_x(0, float(q[0])), S.H / 2 + float(q[1]) * (1.0 if p.team == 0 else -1.0))
		p.v = Vector2.ZERO; p.cd = 0.0; p.run = 0.0; p.reage = 0.0; p.down = 0.0; p.dest = Vector2(-1, -1); p.tackle_cd = 0.6
		p.dribble = Vector2.ZERO; p.set_piece = false; p.penalty = false
	var dono = S.active().filter(func(p): return p.team == 0 and p.role == "cm")[0]
	S.reset_ball(dono.p)
	S.owner = dono; dono.cd = 0.25; dono.desde = 0.0
	S.parado_dono = null; S.pause = 0.0; S.espera_todos = -1.0
	S.poss_last = 1; S.last = 0          # a bola era dos Laranjas: o motor vê a recuperação no passo seguinte
	S.lance_cd = 99.0

func resolve(S: Partida) -> void:
	match S.mode:
		"lance", "var": S.decide(str(S.lance.truth))
		"gesto": S.finish_after()
		"pergunta": S.ask_pick(int(S.ask.get("def", 0)))
		"protesto": S.resolve_protest("afastar")
		"intervalo": S.second_half("descanso")

func corre(af: Dictionary, n: int) -> Dictionary:
	var r := {"n": n, "chega": 0, "remata": 0, "golo": 0, "t": 0.0, "ata": 0.0, "def": 0.0, "lancados": 0, "perdeu": 0, "parou": 0, "tempo": 0}
	for k in n:
		var tm: Array = Carreira.default_teams()
		tm[0].rating = 70.0; tm[1].rating = 70.0
		var S := Partida.new(tm)
		S.rng.seed = 4000 + k
		S.dbg_on = true; S.af = af.duplicate()
		var g := 0
		while not (S.mode == "play" and S.parado_dono == null and S.t > 1.0 and S.dirs(0) != 0) and g < 4000:
			g += 1; resolve(S); S.tick(1.0 / 30.0)
		S.rng.seed = 9000 + k
		cenario(S)
		var d0: Dictionary = S.dbg.duplicate()
		var rem0: int = S.est.remates[0]; var gol0: int = S.score[0]
		var tt := 0.0
		var chegou := false
		var ult = null
		var tr := OS.get_environment("TRACE") != ""
		while tt < DUR:
			if S.mode != "play": resolve(S)
			S.tick(1.0 / 30.0); tt += 1.0 / 30.0
			if tr and af.get("m2_ca", 1.0) > 0.0:
				var on = S.owner
				if on != ult:
					ult = on
					if on: print("   %d  %.1fs  %s %s a %.0f m (y %.0f)" % [k, tt, "AZ" if on.team == 0 else "LA", on.role, S.rel(0, on.p.x), on.p.y - S.H / 2])
					else:
						var dp: Array = S.dbg_ps
						print("   %d  %.1fs  bola solta: vel %.0f, alt %.1f, para %s%s  %s" % [k, tt, S.bv.length(), S.bz, (S.target.role if S.target else "-"),
							(" a %.0f m (y %.0f)" % [S.rel(0, S.target.p.x), S.target.p.y - S.H / 2]) if S.target else "", ("%s p=%.2f" % [dp[0], dp[1]]) if dp.size() > 1 else ""])
						var ds := ""
						for q in S.active():
							if q.team == 1 and q.role != "gk" and S.rel(0, q.p.x) > S.rel(0, S.bp.x) - 6.0: ds += " %s(%.0f,%.0f)" % [q.role, S.rel(0, q.p.x), q.p.y - S.H / 2]
						print("        defesas perto ou à frente da bola:", ds)
			if S.est.remates[0] > rem0 or S.score[0] > gol0: break
			if S.owner and S.owner.team == 1 and S.owner.role != "gk": r.perdeu += 1; break   # perderam a bola
			if S.mode == "play" and S.parado_dono != null: r.parou += 1; break              # falta, fora: o lance morreu
			if tt >= DUR: r.tempo += 1
			if not chegou and S.owner and S.owner.team == 0 and S.rel(0, S.owner.p.x) >= 70.0:
				chegou = true; r.chega += 1; r.t += tt
				var bx: float = S.rel(0, S.bp.x)
				r.ata += S.active().filter(func(p): return p.team == 0 and p.role != "gk" and S.rel(0, p.p.x) >= bx - 12.0).size()
				r.def += S.active().filter(func(p): return p.team == 1 and p.role != "gk" and S.rel(0, p.p.x) >= bx - 2.0).size()
		# o remate pode sair logo a seguir à entrada: dá-se mais um instante para a bola chegar à baliza
		var extra := 0.0
		while extra < 2.0 and S.est.remates[0] > rem0 and S.score[0] == gol0:
			if S.mode != "play": resolve(S)
			S.tick(1.0 / 30.0); extra += 1.0 / 30.0
		if S.est.remates[0] > rem0: r.remata += 1
		if S.score[0] > gol0: r.golo += 1
		r.lancados += int(S.dbg.get("ca_n", 0))
		if OS.get_environment("DBG") != "":
			for kk in S.dbg:
				if kk.begins_with("perde") or kk in ["pass", "through", "dribble", "clear", "shoot", "cruza"]: r[kk] = r.get(kk, 0) + int(S.dbg[kk]) - int(d0.get(kk, 0))
	return r

func linha(nome: String, r: Dictionary) -> void:
	var c: float = maxf(float(r.chega), 1.0)
	print("%-18s (perde a bola %d, lance parado %d, sem tempo %d)" % ["", r.perdeu, r.parou, r.tempo])
	if OS.get_environment("DBG") != "": print(r)
	print("%-18s chega ao último terço %3d%%  remata %3d%%  golo %3d%%  | chega em %.1f s com %.1f atacantes contra %.1f defesas" %
		[nome, round(100.0 * r.chega / r.n), round(100.0 * r.remata / r.n), round(100.0 * r.golo / r.n), r.t / c, r.ata / c, r.def / c])

func _initialize():
	var n := int(OS.get_environment("N")) if OS.get_environment("N") != "" else 40
	var af := {"motor2": 1.0}
	if OS.get_environment("AF") != "": af.merge(JSON.parse_string(OS.get_environment("AF")), true)
	var sem := af.duplicate(); sem["m2_ca"] = 0.0
	var a := corre(sem, n)
	var b := corre(af, n)
	print("Contra-ataque: %d lances iguais, bola recuperada a 24 m da própria baliza com 8 adversários à volta da área" % n)
	linha("sem contra-ataque", a)
	linha("com contra-ataque", b)
	var ok: bool = b.chega >= 0.5 * n and b.remata >= 0.25 * n and b.chega > a.chega and b.lancados >= 0.9 * n
	print("contra-ataque lançado em %d de %d lances" % [b.lancados, n])
	print("PASSOU" if ok else "FALHOU")
	quit(0 if ok else 1)
