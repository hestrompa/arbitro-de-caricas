extends SceneTree
func _init():
	var S := Partida.new(Carreira.default_teams())
	for i in 30: S.tick(1.0 / 60)
	S.ask = {}; S.mode = "play"; S.taca = true; S.score = [1, 1]; S.prol = 2
	S.inicia_desempate()
	print(S.mode, " ", S.ask.opts.map(func(o): return o.label) if S.ask.size() else [])
	S.ask_pick(0)
	print(S.manage.back(), " ", S.feed_list.back().txt)
	var n := 0
	while S.desempate.get("tk", -1) == -1 and n < 600:
		S.tick(1.0 / 60); n += 1
	print("primeiro penálti marcado: tk=", S.desempate.tk, " mode ", S.mode)
	quit()
