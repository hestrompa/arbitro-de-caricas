extends SceneTree
# critério das entradas: o mesmo par (velocidade, direção, carrinho) dá sempre o mesmo nível
func _initialize():
	var S := Partida.new(Carreira.default_teams())
	var cont := {}
	var mal := 0
	for tr in ["falta", "amarelo", "vermelho"]:
		for i in 300:
			var g: Dictionary = S.entrada_params(tr)
			if S.grav_nivel(S.grav_pts(g.vel, g.phi, g.slide)) != tr: mal += 1
			var k: String = tr + ("_lim_" + g.lim if g.lim != "" else "")
			cont[k] = cont.get(k, 0) + 1
	print(cont, "  inconsistentes: ", mal)
	for tr in ["falta", "amarelo", "vermelho"]:
		var g: Dictionary = S.entrada_params(tr)
		print(tr, ": ", S.grav_txt({"grav": g}))
	quit()
