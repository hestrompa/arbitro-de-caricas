extends SceneTree
# Fumo: as animações da Quaternius entram no jogo (protestos dos outros, festa do marcador do penálti).
var m
var n := 0
var fase := ""
var estados := {}
var festa := false
var tiros := 0
func _initialize():
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
func _process(dt: float) -> bool:
	n += 1
	if n == 5: m.on_ui("partida", null); return false
	if n < 60: return false
	var J = m.jogo
	if m.modo == "jogo" and fase == "" and J.mode == "play" and J.pause <= 0:
		var att = J.active().filter(func(p): return p.role == "st" and p.team == 0)[0]
		J.lance_cd = 99
		J.penalty(att); J.pen_3d = true; J.pen_forca = "nenhuma"; fase = "espera"; tiros += 1
	if m.modo == "lance":
		for e in m.extras: estados[e.state] = true
		if m.att.state == "q_festa": festa = true
		if m.t > m.TC + 3.0 and fase == "espera":
			print("penalti golo=", m.L.golo, " festa=", festa, " marcador=", m.att.state)
			m._decide(m.L.truth); fase = "dec"
	if fase == "dec" and m.modo == "jogo": fase = ""; if tiros >= 4: return _fim()
	if n > 6000: return _fim()
	return false
func _fim() -> bool:
	print("estados dos outros: ", estados.keys())
	quit(); return true
