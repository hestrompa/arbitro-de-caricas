extends SceneTree
func _initialize():
	var cont := {}
	for j in 4:
		var S := Partida.new(Carreira.default_teams())
		S.var_mode = true; S.no_var = false
		var guard := 0
		while S.mode != "fim" and guard < 40000:
			guard += 1
			match S.mode:
				"lance":
					var L: Dictionary = S.lance
					if not L.has("var_campo"):
						L.var_campo = S.ai_campo(L); L.var_done = true
						var k := "golo-" + S.kind_of(L) if L.get("goal_ctx", false) else S.kind_of(L)
						if L.get("atrasada", false): k += "-atrasada"
						cont[k] = cont.get(k, 0) + 1
						if not S.var_eligible(L, L.var_campo) and not S.var_eligible(L, str(L.truth)): L.ia = true
					S.decide(str(L.var_campo))
				"gesto": S.finish_after()
				"pergunta": S.ask_pick(int(S.ask.get("def", 0)))
				"protesto": S.resolve_protest("afastar")
				"intervalo": S.second_half("descanso")
			S.tick(1.0 / 30.0)
		cont["golos"] = cont.get("golos", 0) + S.score[0] + S.score[1]
		cont["atrasos"] = cont.get("atrasos", 0) + S.atrasos_n
		cont["checks"] = cont.get("checks", 0) + S.var_checks.size()
	print(cont)
	quit()
