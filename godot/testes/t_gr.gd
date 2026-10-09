extends SceneTree
# Guarda-redes no penálti: imagens a cada 0,1 s de TC-1,2 a TC+1,5 (um penálti; CAM, N penáltis)
var m
var cam: Camera3D
var n := 0
var fase := ""
var vistos := {}
var k := 0
var tiros := 0
const OUT = "/tmp/claude-0/-home-claude/03cb57f4-a453-5d33-87b7-2efcd6ebbd73/scratchpad/godot/t/gr/"
var DTS := range(-12, 16).map(func(i): return i * 0.1)
func _initialize():
	DirAccess.make_dir_recursive_absolute(OUT)
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
		vistos[tiros] = true; fase = "filma"; k = 0
		m.cam_mode = int(OS.get_environment("CAM")) if OS.get_environment("CAM") != "" else 1
		print("== ", infr, " golo=", m.L.golo, " verdade=", m.L.truth)
	if m.modo == "lance" and fase == "filma":
		if cam == null:
			cam = Camera3D.new(); m.add_child(cam); cam.fov = 40
		var gx: float = float(m.sc.gx); var di: float = float(m.sc.dir_in)
		cam.look_at_from_position(Vector3(gx - di * 9.0, 1.5, m.H / 2 + 4.0), Vector3(gx, 0.9, m.H / 2))
		cam.make_current()
		if k < DTS.size() and m.t >= m.TC + DTS[k]:
			root.get_viewport().get_texture().get_image().save_png(OUT + "p%d_%02d.png" % [tiros, k]); k += 1
		if absf(m.t - m.TC) < 0.02:
			var g: Vector3 = m.def.body_pos()
			print("   em TC: guarda-redes a %.2f m da linha; invasor dentro da área %s" % [absf(g.x - float(m.sc.gx)), str(m.sc.get("inv_marca", "-"))])
		if k >= DTS.size() and m.dec_shown:
			cam.queue_free(); cam = null
			print("   bola final ", m.b3.round(), " defende=", m.sc.get("defende", false), " ", m.outcome)
			m._decide(m.L.truth); fase = "dec"
	if m.modo == "gesto" and m.G.get("t", 0.0) > 0.4: m._end_gesture()
	if m.modo == "jogo" and fase == "dec":
		fase = ""
		print("   placar ", J.score, " dono ", J.owner.num if J.owner else -1)
		if tiros >= (int(OS.get_environment("N")) if OS.get_environment("N") != "" else 1): quit(); return true
	if m.modo == "jogo" and J.mode == "pergunta": m.on_ui("ask", 0)
	if m.modo == "jogo" and J.mode == "protesto": m.on_ui("protest", "afastar")
	if n > 60000: quit(); return true
	return false
