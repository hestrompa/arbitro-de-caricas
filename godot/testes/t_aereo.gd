extends SceneTree
# Bola longa: a bola tem de chegar à cabeça de quem cabeceia em TC.
var m
var n := 0
var feito := false
var ok := false
func _initialize():
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
func _process(dt: float) -> bool:
	n += 1
	if n < 5: return false
	if m.modo == "menu" and not feito: m.on_ui("partida", null); return false
	var j = m.jogo
	if m.modo == "jogo" and j.mode == "play" and not feito and n > 40:
		var p = null; var r = null; var o = null
		for q in j.active():
			if q.team == 0 and q.role == "lcb": p = q
			if q.team == 0 and q.role == "st": r = q
			if q.team == 1 and q.role == "rcb": o = q
		o.p = r.p + Vector2(1.5, 0)
		for i in 200:
			j.lance_cd = 0
			j.aerial_check(p, r)
			if j.mode == "lance": break
		feito = true
	if m.modo == "lance":
		if not ok and m.t >= m.TC - 0.02:
			ok = true
			var h: Vector3 = m.att.bone_world("head")
			print("TC-0.02: bola %s cabeça %s dist %.2f  K %s P %s" % [str(m.ball.position), str(h), m.ball.position.distance_to(h), str(m.sc.K), str(m.P)])
		if fmod(m.t, 0.25) < 0.017 and m.t < m.TC + 0.5:
			print("t %.2f bola %s cabeça %s" % [m.t, str(m.ball.position.snapped(Vector3.ONE * 0.1)), str(m.att.bone_world("head").snapped(Vector3.ONE * 0.1))])
		if m.t > m.TC + 0.6: quit(); return true
	if n > 5000: quit(); return true
	return false
