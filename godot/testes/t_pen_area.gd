extends SceneTree
# Lei 14: quando o penálti é batido (cena 3D ou remate 2D) não pode haver ninguém dentro da área,
# a menos de 9,15 m da marca ou à frente da bola, além do marcador e do guarda-redes.
var m
var n := 0
var fase := ""
var tiros := 0
var maus := 0
func _initialize():
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
func _process(_dt: float) -> bool:
	n += 1
	if n == 5: m.on_ui("partida", null); return false
	if n < 60: return false
	var J = m.jogo
	if m.modo == "jogo" and fase == "" and J.mode == "play" and J.pause <= 0:
		# penálti a meio de uma jogada com a área cheia: põe-se toda a gente dentro da área primeiro
		var att = J.active().filter(func(p): return p.role == "st" and p.team == 0)[0]
		var gx: float = J.opp_goal_x(0); var d: float = J.dirs(0)
		for p in J.active():
			if p.role != "gk": p.p = Vector2(gx - d * randf_range(2.0, 15.0), J.H / 2 + randf_range(-18.0, 18.0))
		J.lance_cd = 99
		J.penalty(att); J.pen_3d = true; J.pen_forca = "nenhuma" if tiros % 2 == 0 else "invasao"; fase = "espera"; tiros += 1
	if m.modo == "lance" and fase == "espera":
		var mal := 0
		for o in m.L.others:
			if J.pen_mal(0, o.p): mal += 1
		print("penálti ", tiros, " ", m.L.infr, ": ", m.L.others.size(), " outros, mal colocados ", mal)
		maus += mal
		m._decide(m.L.truth); fase = "dec"
	if m.modo == "gesto" and m.G.get("t", 0.0) > 0.4: m._end_gesture()
	if m.modo == "jogo" and fase == "dec": fase = ""
	if tiros >= 6 and fase == "":
		print("MAL COLOCADOS ", maus); quit(); return true
	if n > 40000: print("tempo esgotado em ", fase, " ", m.modo); quit(); return true
	return false
