extends SceneTree
func _init():
	for c in [0, 1, 2]:
		var S := Partida.new(Carreira.default_teams())
		for i in 60: S.tick(1.0 / 60)
		S.ask = {}; S.mode = "play"; S.parado_dono = null; S.lance = {}
		var p = S.players[3]
		S._lanc_check(p, Vector2(30, -0.4), p.team)
		print(S.mode, " ", S.ask.opts.size() if S.ask.size() else 0)
		S.ask_pick(c)
		print("  ", S.manage.back(), " owner ", S.owner.team if S.owner else -1, " parado ", S.parado_dono != null)
	quit()
