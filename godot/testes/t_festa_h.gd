extends SceneTree
func _init():
	var J := Partida.new(Carreira.default_teams())
	for i in 30: J.tick(1.0 / 60)
	J.ask = {}; J.mode = "play"; J.pause = 0
	var st = null
	for p in J.active():
		if p.team == 0 and p.role == "st": st = p
	st.p = Vector2(J.W - 12, J.H / 2 + 6)
	J.kicker = st; J.last = 0; J.owner = null
	J.bp = Vector2(J.W + 0.5, J.H / 2)
	J.goal(0)
	print("k=", J.festa.k.num if J.festa.k else null, " alvo ", J.festa.alvo, " st ", st.p)
	for i in 240:
		J.tick(1.0 / 60)
		if J.mode == "pergunta": J.ask_pick(0)
		if i % 40 == 0 and not J.festa.is_empty(): print(snappedf(J.festa.t, 0.1), " st ", st.p.round(), " v ", st.v.round())
	quit()
