extends SceneTree
func _initialize():
	for n in ["Azuis", "Laranjas"]:
		var sq: Array = Carreira.squad_for(n, 70.0)
		var s := 0.0
		var t := ""
		for q in sq: s += q.ovr; t += "%d " % int(q.ovr)
		print(n, " média %.1f : " % (s / 11.0), t, " estrela ", sq.filter(func(q): return "estrela" in q.tr).map(func(q): return q.num))
	quit()
