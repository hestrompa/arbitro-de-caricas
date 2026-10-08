class_name Redes
extends RefCounted
# Depois do jogo: o que se diz nas redes sociais e a pergunta do jornalista na zona de entrevistas.
# Tudo depende do que aconteceu: o erro mais grave, contra quem foi, a nota, os cartões e o VAR.

const COMENTADORES := ["Rui Tavares, comentador", "Marta Gouveia, ex-árbitra", "Zé Pedro Lopes, jornalista", "Paulo Sá, analista de arbitragem"]

static func slug(nome: String) -> String:
	var s := nome.to_lower()
	for p in [["ã", "a"], ["á", "a"], ["à", "a"], ["â", "a"], ["é", "e"], ["ê", "e"], ["í", "i"], ["ó", "o"], ["ô", "o"], ["õ", "o"], ["ú", "u"], ["ç", "c"], [" ", ""], [".", ""], ["-", ""]]:
		s = s.replace(p[0], p[1])
	return s

static func likes(base: int) -> String:
	var n := int(base * randf_range(0.6, 1.6))
	if n >= 1000: return ("%.1f mil" % (n / 1000.0)).replace(".", ",")
	return str(n)

# o lance errado mais falado (o mesmo critério do jornal) e quem saiu prejudicado
static func grande_erro(S: Partida) -> Dictionary:
	var inc: Array = S.incidents.filter(func(l): return not l.get("training", false))
	var wrong: Array = inc.filter(func(l): return l.pts < 1)
	for test in [func(l): return l.get("goal_ctx", false), func(l): return l.get("in_box", false) and S.kind_of(l) != "offside",
			func(l): return l.get("decided", "") == "vermelho" or l.truth == "vermelho", func(l): return S.kind_of(l) == "offside", func(l): return true]:
		for l in wrong:
			if test.call(l): return l
	return {}

static func prejudicado(S: Partida, l: Dictionary) -> int:
	if l.is_empty(): return -1
	var a = l.get("against", null)
	if a != null: return int(a)
	if l.has("att"): return int(l.att.team)
	return -1

static func resumo_erro(S: Partida, l: Dictionary) -> String:
	var d: String = l.get("decided", "")
	if S.kind_of(l) == "pen": return "penálti mal resolvido (%s)" % str(Partida.DEC_LABEL.get(d, d)).to_lower()
	if S.kind_of(l) == "offside": return "fora de jogo inventado" if d == "fora" else "fora de jogo por assinalar"
	if l.get("goal_ctx", false): return "golo mal validado" if d in ["valido", "entrou", "emjogo"] else "golo limpo anulado"
	if l.get("in_box", false): return "penálti inventado" if S.is_foul(d) else "penálti por marcar"
	if d == "vermelho": return "vermelho exagerado"
	if l.truth == "vermelho": return "vermelho perdoado"
	if d == "simulacao": return "simulação que não existiu"
	return "falta mal assinalada" if S.is_foul(d) else "falta por marcar"

static func gerar(S: Partida, grade: float, kind: String) -> Dictionary:
	var T: Array = S.teams
	var h0: String = T[0].name; var h1: String = T[1].name
	var tag := "#" + slug(h0).left(3).to_upper() + slug(h1).left(3).to_upper()
	var big := grande_erro(S)
	var vit := prejudicado(S, big)
	var inc: Array = S.incidents.filter(func(l): return not l.get("training", false))
	var erros := inc.filter(func(l): return l.pts < 1).size()
	var posts: Array = []
	var trend := tag
	var min_txt := ("aos %d'" % int(big.minute)) if big.has("minute") else ""
	if kind == "abandonado":
		trend = "#ArbitroNaRua"
		posts.append({"who": "Liga Portuguesa de Futebol", "at": "@ligaportugal", "txt": "O jogo %s foi interrompido. O caso segue para o Conselho de Disciplina." % (h0 + "-" + h1), "lk": likes(4000), "tom": 0})
	if not big.is_empty() and vit >= 0:
		var club: String = T[vit].name; var outro: String = T[1 - vit].name
		var e := resumo_erro(S, big)
		trend = "#" + ["Roubo", "VergonhaNoApito", "VAREsteveOnde", "ArbitragemAQuestao"].pick_random()
		posts.append({"who": "Adepto " + club, "at": "@" + slug(club) + "_ate_morrer", "txt": "%s %s. Isto é vergonhoso! Quem é que escolhe estes árbitros? %s" % [e.left(1).to_upper() + e.substr(1), min_txt, tag], "lk": likes(2400), "tom": -1})
		posts.append({"who": "Adepto " + outro, "at": "@" + slug(outro) + "_naveia", "txt": ["Chorem mais. Ganhámos em campo. %s" % tag, "Até parece que o jogo foi só aquele lance... %s" % tag, "Erro? Eu vi um lance normal. Chorões. %s" % tag].pick_random(), "lk": likes(900), "tom": 0})
		posts.append({"who": COMENTADORES.pick_random(), "at": "@analise_arbitragem", "txt": "Revi o lance %s: %s. Era %s. O árbitro %s." % [min_txt, e, str(Partida.LABEL.get(big.truth, big.truth)).to_lower(),
			"estava a %d metros e mal colocado" % int(big.get("dist", 20)) if big.get("clarity", 1.0) < 0.45 else "até estava bem colocado, decidiu mal"], "lk": likes(1500), "tom": -1})
		posts.append({"who": club + " (oficial)", "at": "@" + slug(club) + "_oficial", "txt": ["Vamos pedir explicações à arbitragem. Os nossos adeptos merecem respeito.", "Não comentamos arbitragens. Mas as imagens falam por si.", "Hoje foi difícil jogar contra 12."].pick_random(), "lk": likes(6000), "tom": -1})
	elif grade >= 8.0:
		trend = "#" + ["ArbitragemDeLuxo", "ApitoDeOuro", "SemPolemica"].pick_random()
		posts.append({"who": COMENTADORES.pick_random(), "at": "@analise_arbitragem", "txt": "Arbitragem de nota alta no %s-%s. Bem colocado, critério igual para os dois lados. É assim." % [h0, h1], "lk": likes(1200), "tom": 1})
		posts.append({"who": "Adepto " + h0, "at": "@" + slug(h0) + "_sempre", "txt": "Pela primeira vez nesta época não se fala do árbitro. Bom trabalho %s" % tag, "lk": likes(500), "tom": 1})
	else:
		posts.append({"who": COMENTADORES.pick_random(), "at": "@analise_arbitragem", "txt": "Arbitragem com altos e baixos no %s-%s: %d %s." % [h0, h1, erros, "lance mal decidido" if erros == 1 else "lances mal decididos"], "lk": likes(700), "tom": 0})
	# golos, cartões e VAR dão sempre conversa
	var reds := 0
	for l in inc:
		if l.get("decided", "") == "vermelho": reds += 1
	if reds > 0:
		posts.append({"who": "Futebol em Direto", "at": "@futebol_direto", "txt": "%d %s no %s-%s. Concordas? %s" % [reds, "vermelho" if reds == 1 else "vermelhos", h0, h1, tag], "lk": likes(3000), "tom": 0})
	if S.var_n > 0:
		posts.append({"who": "Memes da Bola", "at": "@memesdabola", "txt": ["O VAR hoje trabalhou mais que o meio-campo do %s" % [h0, h1].pick_random(), "Árbitro a ir ao monitor pela %d.ª vez: modo cinema ativado" % S.var_n].pick_random(), "lk": likes(5000), "tom": 0})
	posts.append({"who": "Resultados ao Minuto", "at": "@resultados", "txt": "Final: %s %d-%d %s. Nota do observador para o árbitro: %s." % [h0, S.score[0], S.score[1], h1, ("%.1f" % grade).replace(".", ",")], "lk": likes(800), "tom": 0})
	return {"trend": trend, "posts": posts.slice(0, 6), "big": big, "vit": vit}

# A pergunta do jornalista à saída e as três respostas possíveis (efeito na imagem pública).
static func entrevista(S: Partida, big: Dictionary, grade: float) -> Dictionary:
	if big.is_empty():
		return {"q": "Jogo tranquilo, poucas polémicas. Que balanço faz?", "opts": [
			{"t": "A equipa de arbitragem esteve concentrada.", "img": 3, "r": "Resposta serena. Os comentadores elogiam a postura."},
			{"t": "O mérito é dos jogadores.", "img": 4, "r": "Os adeptos gostam da humildade."},
			{"t": "Não falo aos jornalistas.", "img": -3, "r": "Fica a ideia de arrogância."}]}
	var e := resumo_erro(S, big)
	return {"q": "As imagens mostram um %s aos %d'. Viu bem o lance?" % [e, int(big.get("minute", 0))], "opts": [
		{"t": "Vi o lance de outra forma no campo. Depois das imagens, admito que errei.", "img": 6, "r": "Honestidade rara. A imprensa respeita e a polémica esfria."},
		{"t": "Estava bem colocado e mantenho a decisão.", "img": -7, "r": "As imagens desmentem-no. A polémica dura a semana toda."},
		{"t": "Sem comentários. O relatório segue para o Conselho de Arbitragem.", "img": -2, "r": "Resposta fria. Ninguém fica satisfeito."}]}
