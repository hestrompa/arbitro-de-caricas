extends SceneTree
# Leis 3, 12, 13 e 16: substituições, festejos, atacante na barreira, adversário na área no pontapé de baliza.
# Joga N partidas só com o motor; nas perguntas escolhe a resposta certa (ou a 1.ª com ERRADO=1) e conta o que aconteceu.
func _initialize():
	var n := int(OS.get_environment("N")) if OS.get_environment("N") != "" else 6
	var cont := {}
	var subs_tot := 0
	var paragens_tot := 0
	var certo := {"Pontapé de baliza": "repetir", "Festejos": "amarelo", "Substituição": "linha"}
	for j in n:
		var S := Partida.new(Carreira.default_teams())
		var guard := 0
		var vistos := {}
		while S.mode != "fim" and guard < 40000:
			guard += 1
			match S.mode:
				"lance": S.decide(str(S.lance.truth))
				"gesto": S.finish_after()
				"pergunta":
					var o: Array = S.ask.opts
					var ds: Array = o.map(func(x): return x.d)
					var pick := int(S.ask.get("def", 0))
					var sm: Array = o.map(func(x): return x.get("small", ""))
					if "obrigatório (Lei 12)" in sm: pick = 1; cont["festejos (pergunta)"] = cont.get("festejos (pergunta)", 0) + 1
					elif "esperar" in ds: pick = ds.find("linha")
					elif "repetir" in ds and "pontapé de baliza outra vez" in sm: pick = ds.find("repetir")
					elif o[1].get("label", "") == "Afastar a 1 m": pick = 1
					if o[1].get("label", "") == "Afastar a 1 m": cont["barreira 1 m"] = cont.get("barreira 1 m", 0) + 1
					S.ask_pick(pick)
				"protesto": S.resolve_protest("afastar")
				"intervalo": S.second_half("descanso")
				"var": S.decide(str(S.lance.truth))
			S.tick(1.0 / 30.0)
		for m in S.manage:
			var w: String = m.what
			if w.begins_with("Festejos") or w.contains("pontapé de baliza") or w.contains("devagar") or w.contains("barreira"):
				cont[w] = cont.get(w, 0) + 1
				print("  jogo %d  %d'  %s -> %s  (%s)" % [j, m.minute, w, m.dec, m.pts])
		for ti in 2: subs_tot += S.subs[ti].n; paragens_tot += S.subs[ti].paragens
		print("jogo %d: %d-%d  subs %s / %s  feed subs: %s" % [j, S.score[0], S.score[1], S.subs[0].n, S.subs[1].n, S.feed_list.filter(func(f): return f.txt.begins_with("Substituição")).map(func(f): return f.min).size()])
	print("subs por equipa e jogo: %.2f   paragens: %.2f" % [subs_tot / (2.0 * n), paragens_tot / (2.0 * n)])
	print(cont)
	quit()
