extends SceneTree
var q: Array = []
func on_ev(n: String, d: Dictionary) -> void:
	if n in ["ask"]: q.append([n, d])
func _init():
	var tags := {}
	for i in 20:
		var S := Partida.new(Carreira.default_teams())
		S.ev = on_ev
		for k in 90:
			S.tick(1.0 / 60)
			while q.size():
				var e = q.pop_front()
				tags[e[1].tag] = tags.get(e[1].tag, 0) + 1
				if e[1].tag == "Sorteio inicial" and tags[e[1].tag] == 1: print(e[1].msg, " ", e[1].opts.map(func(o): return o.label))
				S.ask_pick(i % 3)
		for m in S.manage.filter(func(x): return str(x.what).begins_with("Sorteio")): print("  ", m.dec, " ", m.pts)
	print(tags)
	quit()
