extends SceneTree
# Atraso ao guarda-redes: COMO=pe|cabeca|corte. Mede se a bola chega às mãos; SHOT=1 grava imagens em S/godot/t/atraso/
var m
var n := 0
var feito := false
var fase := 0
var como := OS.get_environment("COMO") if OS.get_environment("COMO") != "" else "pe"
var shot := OS.get_environment("SHOT") != ""
var D := "/tmp/claude-0/-home-claude/03cb57f4-a453-5d33-87b7-2efcd6ebbd73/scratchpad/godot/t/atraso"
func _initialize():
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	if shot: DirAccess.make_dir_recursive_absolute(D)
func _grava(nm: String) -> void:
	if shot: root.get_texture().get_image().save_png("%s/%s_%s.png" % [D, como, nm])
func _process(dt: float) -> bool:
	n += 1
	if n < 5: return false
	if m.modo == "menu" and not feito: m.on_ui("partida", null); return false
	var j = m.jogo
	if m.modo == "jogo" and j.mode == "play" and not feito and n > 40:
		feito = true
		var gk = null; var k = null
		for p in j.active():
			if p.team == 0 and p.role == "gk": gk = p
			if p.team == 0 and p.role == "lcb": k = p
		j.atraso_forca = como; j.lance_cd = 0
		j.start_atraso(gk, k)
		print("atraso %s, verdade %s" % [como, j.lance.truth])
	if m.modo == "lance":
		var tc: float = m.TC
		if fase == 0 and m.t > 0.3:
			fase = 1; _grava("a_inicio")
			for q in [m.att, m.def] + m.extras:
				if q.node.visible: print("  pid %d equipa %d pos %s cor %s" % [q.get_meta("pid", -1), q.team, str(q.body_pos().round()), str(q.mat.get_shader_parameter("shirt"))])
			print("  árbitro %s  G %s K %s" % [str(m.REF.round()), str(m.sc.G.round()), str(m.sc.K.round())])
			var e = m.extras[0]
			print("rival: visível %s pid %s pos %s R %s sc.rival %s L.rival %s" % [e.node.visible, e.get_meta("pid", -1), str(e.body_pos().round()), str(m.L.R.round()), m.sc.get("rival"), m.L.get("rival")])
		if fase == 1 and m.t > tc - 1.0: fase = 2; _grava("b_toque")
		if fase == 2 and m.t >= tc:
			fase = 3
			var mao: Vector3 = (m.def.bone_world("wrist_L") + m.def.bone_world("wrist_R")) * 0.5
			print("em TC: bola a %.2f m das mãos (bola y %.2f, mãos y %.2f)" % [m.ball.position.distance_to(mao), m.ball.position.y, mao.y])
			_grava("c_agarra")
		if fase == 3 and m.t > tc + 0.8: fase = 4; _grava("d_depois"); m.cam_mode = 1
		if fase == 4 and m.t > tc + 0.85: fase = 5
		if fase == 5 and m.t > tc + 1.0: fase = 6; _grava("e_ideal")
		if fase == 6 and m.dec_shown and m.t > tc + 1.2: fase = 7; m._decide(m.L.truth)
	if m.modo == "gesto" and m.G.get("t", 0.0) > 0.4: m._end_gesture()
	if fase == 7 and m.modo == "jogo":
		print("depois: modo %s, dono %s, bola %s, msg %s" % [j.mode, str(j.owner.num if j.owner else -1), str(j.bp.round()), str(j.incidents[-1].get("msg", ""))]); quit(); return true
	if n > 8000: print("timeout"); quit(); return true
	return false
