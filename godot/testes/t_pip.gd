extends SceneTree
# Câmara do passe no fora de jogo: fotografias antes, no instante e depois do passe
var m
func pl(team, role):
	for p in m.jogo.players:
		if p.team == team and p.role == role: return p
func _initialize():
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	for i in 10: await process_frame
	m.on_ui("partida", null)
	for i in 30: await process_frame
	while m.modo != "jogo" or m.jogo.mode != "play": await process_frame
	var J: Partida = m.jogo
	J.lance_cd = 0
	var r = pl(0, "st"); var ps = pl(0, "cm")
	for q in J.players:
		if q.team == 1 and q.role != "gk": q.p.x = min(q.p.x, 80.0)
	pl(1, "lcb").p = Vector2(80, 30); pl(1, "rcb").p = Vector2(79.5, 40)
	r.p = Vector2(80.2, 33); r.v = Vector2(6, 0); ps.p = Vector2(62, 36); ps.v = Vector2(3, 0)
	J.bp = ps.p; J.offside_snap(ps, r); var oi = J.off_info; J.off_info = {}
	J.start_offside(oi)
	while not (m.modo in ["lance", "var"]): await process_frame
	var o := OS.get_environment("OUT")
	var k := 0
	for tt in [m.TC - 1.2, m.TC - 0.3, m.TC + 0.05, m.TC + 0.6, m.TC + 1.2]:
		while m.t < tt: await process_frame
		root.get_viewport().get_texture().get_image().save_png(o + "/pip%d.png" % k); k += 1
		print("t ", m.t - m.TC, " passer ", m.sc.passer.node.global_position, " ball ", m.ball.global_position, " alvo ", m.pip_alvo, " cam ", m.pip_cam.global_position, " vis ", m.sc.passer.node.visible, " sv ", m.pip_cam.get_viewport().size, " cont ", m.pip_cam.get_viewport().get_parent().size, " cur ", m.pip_cam.current, " fov ", m.pip_cam.fov, " vpcam ", m.pip_cam.get_viewport().get_camera_3d())
	quit()
