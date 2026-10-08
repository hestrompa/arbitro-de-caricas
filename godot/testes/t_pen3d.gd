extends SceneTree
# Penálti em 3D: um de cada tipo (limpo, guarda-redes adiantado, paradinha, invasão), imagens e medidas.
var m
var n := 0
var fase := ""
var vistos := {}
var k := 0
var tiros := 0
const OUT = "/tmp/claude-0/-home-claude/03cb57f4-a453-5d33-87b7-2efcd6ebbd73/scratchpad/godot/t/pen/"
const DTS = [-1.0, -0.4, -0.05, 0.25, 0.7]
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
		J.penalty(att); J.pen_3d = true; J.pen_forca = OS.get_environment("FORCA"); fase = "espera"; tiros += 1
	if m.modo == "lance" and fase == "espera":
		var infr: String = m.L.infr
		if vistos.has(infr) and vistos.size() < 4 and tiros < 30:
			m._decide(m.L.truth); fase = "dec"; return false
		vistos[infr] = true; fase = "filma"; k = 0
		m.cam_mode = int(OS.get_environment("CAM")) if OS.get_environment("CAM") != "" else 1
		print("== ", infr, " golo=", m.L.golo, " verdade=", m.L.truth)
	if m.modo == "lance" and fase == "filma":
		if k < DTS.size() and m.t >= m.TC + DTS[k]:
			root.get_viewport().get_texture().get_image().save_png(OUT + "%s_%d.png" % [m.L.infr, k]); k += 1
		if absf(m.t - m.TC) < 0.02:
			var g: Vector3 = m.def.body_pos()
			print("   em TC: guarda-redes a %.2f m da linha; invasor dentro da área %s" % [absf(g.x - float(m.sc.gx)), str(m.sc.get("inv_marca", "-"))])
		if k >= DTS.size() and m.dec_shown:
			print("   bola final ", m.b3.round(), " defende=", m.sc.get("defende", false), " ", m.outcome)
			m._decide(m.L.truth); fase = "dec"
	if m.modo == "gesto" and m.G.get("t", 0.0) > 0.4: m._end_gesture()
	if m.modo == "jogo" and fase == "dec":
		fase = ""
		print("   placar ", J.score, " dono ", J.owner.num if J.owner else -1)
		if vistos.size() >= 4 or tiros >= 30: quit(); return true
	if m.modo == "jogo" and J.mode == "pergunta": m.on_ui("ask", 0)
	if m.modo == "jogo" and J.mode == "protesto": m.on_ui("protest", "afastar")
	if n > 60000: quit(); return true
	return false
