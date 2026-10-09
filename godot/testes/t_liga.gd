extends SceneTree
# testa o campeonato da carreira: calendário, jornadas simuladas, tabela, histórias e fim de época
func _initialize():
	var car := Carreira.new()
	car.C = {}
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Carreira.PATH))
	car.new_career()
	for f in car.C.fixtures: print(f.h, "-", f.a, " ", f.story, " ", f.jogos)
	for k in 8:
		var B := car.match_brief()
		print("--- ", B.comp, ": ", B.h[0], " - ", B.a[0], "  história=", B.story, " urg=", B.urg)
		for l in B.lines: print("   ", l)
		var tm := car.career_teams(B)
		print("   forças ", tm[0].rating, " ", tm[1].rating)
		var S := Partida.new(tm)
		car.setup_match(S)
		S.score = [randi() % 3, randi() % 3]
		print("   ", car.after(S, 7.2, "fim"))
		for r in car.league_table(): print("      %d %-24s J%d V%d E%d D%d %d-%d %d  %s" % [0, r.n, r.j, r.v, r.e, r.d, r.gm, r.gs, r.pts, car.forma(r.i)])
	print(car.C.news)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Carreira.PATH))
	quit()
