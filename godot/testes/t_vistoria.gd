extends SceneTree
var q: Array = []
func on_ev(n: String, d: Dictionary) -> void:
	if n in ["ask"]: q.append([n, d])
func _init():
	var n := 0
	for i in 12:
		var S := Partida.new(Carreira.default_teams())
		S.ev = on_ev
		for k in 120:
			S.tick(1.0 / 60)
			while q.size():
				var e = q.pop_front()
				if e[1].tag == "Vistoria aos equipamentos":
					n += 1
					if n <= 4: print(e[1].msg)
				S.ask_pick(i % 3)
		var m: Array = S.manage.filter(func(x): return str(x.what).begins_with("Vistoria"))
		if m.size(): print("  ", m[0].dec, " ", m[0].pts, " ", m[0].why)
	print("vistorias ", n, "/12")
	quit()
