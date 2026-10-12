extends SceneTree
# Lei 9: a bola bate no árbitro
func _init():
	for c in [0, 1, 2]:
		var S := Partida.new(Carreira.default_teams())
		for i in 60: S.tick(1.0 / 60)
		S.ask = {}; S.mode = "play"; S.owner = null; S.last = 0
		S.bp = S.ref + Vector2(0.3, 0); S.bv = Vector2(-9, 0)
		S.physics(1.0 / 60)
		print(S.mode, " ", S.ask.get("opts", []).map(func(o): return o.label))
		S.ask_pick(c)
		print("  ", S.manage.back().what, " · ", S.manage.back().dec, " ", S.manage.back().pts, " owner ", S.owner.team if S.owner else -1, " parado ", S.parado_dono != null)
		for i in 120: S.tick(1.0 / 60)
		print("  continua: mode ", S.mode, " t ", snappedf(S.t, 0.1))
	quit()
