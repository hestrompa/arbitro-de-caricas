extends SceneTree
# Penálti e reinícios: a bola fica parada no sítio até ser batida; ninguém a conduz.
var m
var n := 0
var etapa := 0
var J
var spot := Vector2.ZERO
var t0 := 0
var maxmov := 0.0
var taker
func _initialize():
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
func _process(dt: float) -> bool:
	n += 1
	if n == 5: m.on_ui("partida", null); return false
	if n < 60: return false
	J = m.jogo
	if m.modo != "jogo": 
		if m.jogo and m.jogo.mode == "pergunta": m.on_ui("ask", 0)
		return false
	match etapa:
		0, 2, 4:
			J.lance_cd = 99
			var att = J.active().filter(func(p): return p.role == "st")[0]
			if etapa == 0: J.penalty(att); print("== penálti")
			elif etapa == 2: J.corner(0, 0.5); J.lance_cd = 99; print("== canto")
			else: J.throw_in(); print("== lançamento")
			spot = J.bp; taker = J.owner; maxmov = 0.0; t0 = n; etapa += 1
			if taker == null: print("  (virou lance, sem marcador)"); etapa += 1
		1, 3, 5:
			if J.owner == taker:
				maxmov = maxf(maxmov, J.bp.distance_to(spot))
				if etapa == 5 and (n - t0) % 10 == 0:
					var ds: Array = J.active().filter(func(q): return q != taker).map(func(q): return "%d/%d:%.1f" % [q.team, q.num, q.p.distance_to(spot)])
					ds.sort_custom(func(a, b): return float(a.split(":")[1]) < float(b.split(":")[1]))
					print("   t=%.2f pause=%.2f bp=%s %s" % [(n - t0) / 60.0, J.pause, str(J.bp), str(ds.slice(0, 3))])
			else:
				print("  novo dono ", J.owner.num if J.owner else -1, " equipa ", J.owner.team if J.owner else -1, " marcador equipa ", taker.team, " dist ", J.owner.p.distance_to(spot) if J.owner else -1.0)
				print("  batido após %.2f s; a bola mexeu-se %.2f m antes do pontapé; marcador a %.2f m da bola; bola sai a %.1f m/s" % [(n - t0) / 60.0, maxmov, taker.p.distance_to(spot), J.bv.length()])
				etapa += 1
				if etapa == 6: quit(); return true
			if n - t0 > 600: print("  NUNCA BATIDO, dono ", J.owner); etapa += 1
	return false
