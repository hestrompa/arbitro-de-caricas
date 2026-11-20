extends SceneTree
# Teste das mudanças das Leis do Jogo 2026/27 (IFAB) no jogo:
#  1) Lei 15: lançamento atrasado de propósito -> contagem de 5 s com a mão (tecla G) -> passa para o adversário
#  2) Lei 16: pontapé de baliza atrasado -> pergunta -> contagem -> canto para o adversário
#  3) Lei 12: ocasião de golo negada com vantagem: com golo, sem cartão; sem golo, amarelo
#  4) Leis 10/14: penálti com dois toques sem querer e golo -> repete-se
#  5) Lei 5: lançamento mal feito com a bola no adversário -> vantagem vale; regresso 1 minuto depois da assistência
#  6) Lei 3: substituído que demora mais de 10 s -> suplente só entra daqui a 1 minuto
# uso: godot --headless --path godot/projeto -s ../testes/t_leis26.gd
var falhas := 0
func ok(c: bool, txt: String) -> void:
	print(("  ok    " if c else "  FALHA ") + txt)
	if not c: falhas += 1

func resolve(S: Partida) -> void:
	match S.mode:
		"lance", "var": S.decide(str(S.lance.truth))
		"gesto": S.finish_after()
		"pergunta": S.ask_pick(int(S.ask.get("def", 0)))
		"protesto": S.resolve_protest("afastar")
		"intervalo": S.second_half("descanso")

func nova(seed: int, af := {}) -> Partida:
	var tm: Array = Carreira.default_teams()
	var S := Partida.new(tm)
	S.rng.seed = seed
	S.af = af.duplicate()
	var g := 0
	while not (S.mode == "play" and S.parado_dono == null and S.t > 1.0) and g < 4000:
		g += 1; resolve(S); S.tick(1.0 / 30.0)
	# 2.ª parte, os Azuis a ganhar
	S.t = Partida.MATCH_SECONDS * 0.7; S.half = 1; S.score = [1, 0]; S.lance_cd = 99.0; S.add_min = 9
	S.rep = {}; S.rep_n = 0; S.ask = {}; S.timers.clear(); S.pend_card = {}
	return S

# corre até aparecer uma pergunta (ou acabar o tempo); devolve as opções
func ate_pergunta(S: Partida, maxs: float, g_tecla := false) -> Array:
	var tt := 0.0
	while tt < maxs:
		if g_tecla and not S.mao_alvo().is_empty() and int(S.mao_alvo().falta) < 0: S.conta_mao()
		S.tick(1.0 / 30.0); tt += 1.0 / 30.0
		if OS.get_environment("TRACE") != "" and int(tt * 30) % 10 == 0: print("    t=%.1f mode=%s rep=%s dono=%s owner=%s pause=%.1f" % [tt, S.mode, str(S.rep), str(S.parado_dono.id) if S.parado_dono else "-", str(S.owner.id) if S.owner else "-", S.pause])
		if S.mode == "pergunta": return S.ask.opts.map(func(o): return str(o.d))
		if S.mode != "play": resolve(S)
	return []
func escolhe(S: Partida, d: String) -> void:
	for i in S.ask.opts.size():
		if str(S.ask.opts[i].d) == d: S.ask_pick(i); return
	print("  (opção %s não existe)" % d)

func _initialize():
	var af := {"rep_k": 10.0}
	# 1) lançamento lateral
	print("1) Lei 15: lançamento atrasado")
	var S := nova(11, af)
	S.bp = Vector2(50, -1.0); S.last = 1
	S.throw_in()
	ok(not S.rep.is_empty() and S.rep.tipo == "lanc", "os Azuis, a ganhar, atrasam o lançamento")
	var o := ate_pergunta(S, 12.0, true)
	ok(S.rep.is_empty() and o.has("troca"), "com a contagem feita (G), no fim pergunta-se e há a opção de passar ao adversário: %s" % str(o))
	if o.has("troca"):
		escolhe(S, "troca")
		ok(S.owner != null and S.owner.team == 1 and S.parado_dono != null, "o lançamento passou para os outros")
		ok(float(S.manage[-1].pts) == 1.0, "e a decisão vale 1 ponto: " + str(S.manage[-1].why))
	# 2) pontapé de baliza
	print("2) Lei 16: pontapé de baliza atrasado, sem contagem")
	S = nova(12, af)
	S.goal_kick(0)
	ok(not S.rep.is_empty() and S.rep.tipo == "baliza", "o guarda-redes dos Azuis atrasa o pontapé de baliza")
	o = ate_pergunta(S, 12.0)
	ok(o.has("conta"), "sem contagem, o árbitro é perguntado: %s" % str(o))
	escolhe(S, "conta")
	ok(float(S.manage[-1].pts) == 1.0, "contagem de 5 s é a decisão certa")
	S.rep.larga = false
	var c0: int = S.est.cantos[1]
	o = ate_pergunta(S, 12.0)
	ok(o.has("troca"), "a contagem acaba sem pontapé: %s" % str(o))
	escolhe(S, "troca")
	ok(S.est.cantos[1] == c0 + 1 and S.owner != null and S.owner.team == 1, "canto para o adversário")
	# 3) ocasião de golo negada com vantagem
	print("3) Lei 12: vantagem numa ocasião de golo negada")
	for golo in [true, false]:
		S = nova(13, af)
		var att = S.active().filter(func(p): return p.team == 0 and p.role == "st")[0]
		var mate = S.active().filter(func(p): return p.team == 0 and p.role == "lw")[0]
		var def = S.active().filter(func(p): return p.team == 1 and p.role == "lcb")[0]
		var L := {"truth": "vermelho", "adv": true, "dogso": true, "get_id": mate.id, "att": S.pinfo(att), "def": S.pinfo(def), "pts": 1.0}
		ok(S.adv_score(L).x == 1.0, "vantagem numa ocasião negada vale 1 ponto")
		S.adv_play(L)
		if golo: S.score[0] += 1
		for k in 6:
			o = ate_pergunta(S, 12.0)
			if o.has("nenhum") or o.is_empty(): break
			print("    (outra pergunta pelo meio: %s)" % str(o))
			S.ask_pick(int(S.ask.get("def", 0)))
		ok(o.has("nenhum"), "pergunta do cartão depois da vantagem (%s)" % ("com golo" if golo else "sem golo"))
		escolhe(S, "nenhum" if golo else "amarelo")
		ok(float(L.pts) == 1.0 and str(L.get("adv_why", "")).begins_with("Certo"), str(L.get("adv_why", "")))
	# 4) penálti com dois toques
	print("4) Leis 10 e 14: penálti com dois toques sem querer")
	S = nova(14, {"pen2t_p": 1.0})
	var tk = S.active().filter(func(p): return p.team == 0 and p.role == "st")[0]
	S.penalty(tk, false)
	o = ate_pergunta(S, 15.0)
	ok(o.has("repetir"), "pergunta dos dois toques: %s" % str(o))
	escolhe(S, "repetir")
	ok(float(S.manage[-1].pts) == 1.0 and S.parado_dono != null and S.parado_dono.penalty, "repete-se o penálti")
	# 5) Lei 5
	print("5) Lei 5: vantagem num lançamento mal feito; regresso depois de assistido")
	S = nova(15, af)
	var p0 = S.active().filter(func(p): return p.team == 0 and p.role == "lb")[0]
	S._lanc_res(p0, Vector2(40, -0.4), 0, ["lançou a bola só com uma mão", "adversario"], "siga", true)
	ok(float(S.manage[-1].pts) == 1.0, "siga com a bola no adversário: " + str(S.manage[-1].why))
	S._lanc_res(p0, Vector2(40, -0.4), 0, ["lançou a bola só com uma mão", "adversario"], "siga", false)
	ok(float(S.manage[-1].pts) == 0.0, "siga sem a bola no adversário continua errado")
	S._volta_ask(p0)
	o = S.ask.opts.map(func(x): return str(x.d)) if not S.ask.is_empty() else []
	ok(o.has("minuto"), "pergunta do regresso: %s" % str(o))
	escolhe(S, "minuto")
	ok(float(S.manage[-1].pts) == 1.0, "um minuto depois do recomeço")
	# 6) Lei 3
	print("6) Lei 3: substituído demora mais de 10 s")
	S = nova(16, af)
	S._sai_devagar(0, 9)
	o = S.ask.opts.map(func(x): return str(x.d)) if not S.ask.is_empty() else []
	ok(o.has("minuto"), "opções: %s" % str(o))
	escolhe(S, "minuto")
	ok(float(S.manage[-1].pts) == 1.0, str(S.manage[-1].why))
	print("PASSOU" if falhas == 0 else "FALHOU (%d)" % falhas)
	quit(0 if falhas == 0 else 1)
