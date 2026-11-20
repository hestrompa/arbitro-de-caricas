extends SceneTree
# Caricas a saltar de sítio, também entre o jogo e os lances: compara cada posição em jogo com a última posição
# em jogo (mesmo que pelo meio tenha havido um lance 3D, uma pergunta ou o VAR). Salto = mais de 1,5 m entre
# duas imagens seguidas do 2D. Conta por causa (o tipo do lance que houve pelo meio, ou "jogo" se foi em jogo).
# uso: godot --headless --path godot/projeto -s ../testes/t_salto2.gd   (N jogos, 4 por omissão; LOG=1 imprime cada salto)
func _initialize():
	var n := int(OS.get_environment("N")) if OS.get_environment("N") != "" else 4
	var tot := 0
	var por := {}
	for j in n:
		var S := Partida.new(Carreira.default_teams())
		S.rng.seed = 300 + j
		S.af = {"motor2": 1.0}
		var prev := {}
		var via := ""
		var guard := 0
		while S.mode != "fim" and guard < 60000:
			guard += 1
			if S.mode != "play":
				if S.mode in ["lance", "var"] and not S.lance.is_empty(): via = str(S.lance.get("kind", "lance")) if S.lance.get("scene", false) else ("offside" if S.lance.has("oi") else ("gk_out" if S.lance.get("gk_out", false) else ("light" if S.lance.get("light", false) else "falta")))
				elif via == "": via = S.mode
			match S.mode:
				"lance", "var": S.decide(str(S.lance.truth))
				"gesto": S.finish_after()
				"pergunta": S.ask_pick(int(S.ask.get("def", 0)))
				"protesto": S.resolve_protest("afastar")
				"intervalo": S.second_half("descanso"); prev = {}
			S.tick(1.0 / 30.0)
			if S.mode != "play": continue
			var cur := {}
			for p in S.active(): cur[p.id] = p.p
			for id in cur:
				if prev.has(id) and cur[id].distance_to(prev[id]) > 1.5:
					var k: String = via if via != "" else "jogo"
					por[k] = int(por.get(k, 0)) + 1; tot += 1
					if OS.get_environment("LOG") != "": print("SALTO %s %s %.1f m t=%.1f %s" % [k, S.players[id].role, cur[id].distance_to(prev[id]), S.t, S.feed_list.back().txt if S.feed_list.size() else ""])
			prev = cur; via = ""
		print("jogo %d: golos %s, saltos até agora %d" % [j, str(S.score), tot])
	print("SALTOS %d em %d jogos: %s" % [tot, n, str(por)])
	quit()
