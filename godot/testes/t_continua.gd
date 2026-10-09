extends SceneTree
# Mede se o 3D continua as caricas: cada figura 3D (no início e no contacto) contra a sua posição 2D no flash.
var m
var n := 0
var fase := ""
var jogos := 0
var p2 := {}
var b2 := Vector2.ZERO
var kind := ""
var stats := {}
func _initialize():
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
func _pos3(j) -> Vector2:
	var b: Vector3 = j.body_pos()
	return Vector2(b.x, b.z)
func _mede(tag: String) -> void:
	var s := ""
	var tot := 0.0
	var cnt := 0
	for j in [m.att, m.def] + m.extras:
		if not j.node.visible: continue
		var id := int(j.get_meta("pid", -1))
		if not p2.has(id): continue
		var ref: Vector2 = p2[id]
		if m.t2d >= 0.0 and m.t < m.t2d:
			var hp = m._hist_pos(id, m.t - m.t2d)
			if hp != null: ref = hp
		var d: float = _pos3(j).distance_to(ref)
		tot += d; cnt += 1
		s += " %.0f" % d
	var bb := Vector2(m.ball.position.x, m.ball.position.z)
	var db := bb.distance_to(b2)
	print("   %s jog média %.1f m [%s ]  bola %.1f m" % [tag, tot / maxf(cnt, 1), s, db])
	var k := kind + "_" + tag
	if not stats.has(k): stats[k] = [0.0, 0.0, 0]
	stats[k][0] += tot / maxf(cnt, 1); stats[k][1] += db; stats[k][2] += 1
func _process(dt: float) -> bool:
	n += 1
	if n < 5: return false
	if m.modo == "menu":
		if jogos >= int(OS.get_environment("JOGOS") if OS.get_environment("JOGOS") != "" else "2"):
			print("==== resumo")
			for k in stats: print("%-14s n=%d jog %.1f m  bola %.1f m" % [k, stats[k][2], stats[k][0] / stats[k][2], stats[k][1] / stats[k][2]])
			quit(); return true
		jogos += 1; fase = ""; m.on_ui("partida", null); return false
	if m.modo == "flash" and fase != "flash":
		fase = "flash"
		p2 = {}
		for q in m.jogo.active(): p2[int(q.id)] = q.p
		b2 = m.jogo.bp
		kind = m.jogo.kind_of(m.L)
		print("%2d' %s" % [m.L.minute, kind])
	if m.modo == "lance" and fase == "flash" and m.t > 0.04:
		fase = "t0"; _mede("ini")
	if m.modo == "lance" and fase == "t0" and m.t > m.TC:
		fase = "tc"; _mede("TC ")
	if m.modo in ["lance", "var"] and m.dec_shown and m.t > m.TC + 0.3:
		fase = ""; m._decide(m.L.truth)
	if m.modo == "gesto" and m.G.get("t", 0.0) > 0.4: m._end_gesture()
	if m.modo == "jogo":
		if m.jogo.mode == "pergunta": m.on_ui("ask", 0)
		if m.jogo.mode == "protesto": m.on_ui("protest", "afastar")
	if m.modo == "intervalo": m.on_ui("second_half", "capitaes")
	if m.modo == "fim": m.on_ui("menu", null)
	if n > 400000: quit(); return true
	return false
