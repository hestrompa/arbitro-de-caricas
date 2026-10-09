extends SceneTree
# Cantos: a área enche-se nas caricas e o 3D começa com toda a gente nesses sítios.
# SHOT=1 (com ecrã) grava o flash 2D e o primeiro instante 3D em S/godot/t/canto/
var m
var n := 0
var fase := ""
var feitos := 0
var p2 := {}
var espera := 0
var shot := OS.get_environment("SHOT") != ""
func _initialize():
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	if shot: DirAccess.make_dir_recursive_absolute("/tmp/claude-0/-home-claude/03cb57f4-a453-5d33-87b7-2efcd6ebbd73/scratchpad/godot/t/canto")
var cantos := 0
func _grava(nm: String) -> void:
	if not shot or m.jogo.kind_of(m.L) != "canto": return
	var img := root.get_texture().get_image()
	img.save_png("/tmp/claude-0/-home-claude/03cb57f4-a453-5d33-87b7-2efcd6ebbd73/scratchpad/godot/t/canto/%d_%s.png" % [feitos, nm])
func _mede(tag: String) -> void:
	var s := ""
	var tot := 0.0
	var cnt := 0
	for j in [m.att, m.def] + m.extras:
		if not j.node.visible: continue
		var id := int(j.get_meta("pid", -1))
		if not p2.has(id): continue
		var b: Vector3 = j.body_pos()
		var d: float = Vector2(b.x, b.z).distance_to(p2[id])
		tot += d; cnt += 1; s += " %.1f" % d
	var naarea := 0
	for id in p2:
		if absf((p2[id] as Vector2).x - m.L.gx) < 17 and absf((p2[id] as Vector2).y - 34) < 20.5: naarea += 1
	print("   %s %d figuras, média %.2f m [%s ]  na área 2D: %d" % [tag, cnt, tot / maxf(cnt, 1), s, naarea])
func _process(dt: float) -> bool:
	n += 1
	if n < 5: return false
	if m.modo == "menu":
		if feitos >= int(OS.get_environment("N") if OS.get_environment("N") != "" else "4"): quit(); return true
		m.on_ui("partida", null); espera = 0; return false
	if m.modo == "jogo" and m.jogo.mode == "play":
		espera += 1
		if espera > 90:
			espera = 0
			m.jogo.lance_cd = 0
			m.jogo.corner(feitos % 2, 0.5 if feitos % 4 < 2 else 67.5)
	if m.modo == "flash" and fase != "flash":
		fase = "flash"; espera = 0
		p2 = {}
		for q in m.jogo.active(): p2[int(q.id)] = q.p
		print("%s (%s)" % [m.jogo.kind_of(m.L), m.L.truth])
	if m.modo == "flash" and fase == "flash":
		espera += 1
		if espera == 20: _grava("a_caricas")
	if m.modo == "lance" and fase == "flash" and m.t > 0.04:
		fase = "t0"; _mede("3D início vs flash:"); _grava("b_3d")
	if m.modo == "lance" and fase == "t0" and m.t > m.TC - 1.3:
		fase = "tk"; _mede("3D pontapé vs flash:"); _grava("c_pontape")
		if m.jogo.kind_of(m.L) == "canto":
			cantos += 1
			if cantos >= int(OS.get_environment("N") if OS.get_environment("N") != "" else "4"): quit()
	if m.modo in ["lance", "var"] and m.dec_shown and m.t > m.TC + 0.3:
		fase = ""; feitos += 1; m._decide("siga" if m.jogo.kind_of(m.L) == "canto" else m.L.truth)
	if m.modo == "gesto" and m.G.get("t", 0.0) > 0.4: m._end_gesture()
	if m.modo == "jogo":
		if m.jogo.mode == "pergunta": m.on_ui("ask", 0)
		if m.jogo.mode == "protesto": m.on_ui("protest", "afastar")
	if m.modo == "intervalo": m.on_ui("second_half", "capitaes")
	if m.modo == "fim": m.on_ui("menu", null)
	if n > 200000: quit(); return true
	return false
