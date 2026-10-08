extends SceneTree
# Compara a posição do lance nas caricas (2D) com o 3D: imagem 2D no flash, 3D vista do árbitro e 3D de cima.
var m
var n := 0
var fase := ""
var k := 0
var feitos := 0
var cima: Camera3D = null
const OUT = "/tmp/claude-0/-home-claude/03cb57f4-a453-5d33-87b7-2efcd6ebbd73/scratchpad/godot/t/al/"
func _initialize():
	DirAccess.make_dir_recursive_absolute(OUT)
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
func shot(nome: String) -> void:
	root.get_viewport().get_texture().get_image().save_png(OUT + nome + ".png")
func _process(dt: float) -> bool:
	n += 1
	if n < 5: return false
	if m.modo == "menu" and fase == "":
		fase = "jogo"; m.on_ui("partida", null); return false
	if m.modo == "flash" and fase != "flash":
		fase = "flash"; k += 1
		shot("%d_a_2d" % k)
		var L: Dictionary = m.jogo.lance if m.jogo.lance else {}
		print("lance %d kind %s P %s ref %s" % [k, m.jogo.kind_of(m.L) if not m.L.is_empty() else "?", str(m.L.get("P")), str(m.L.get("ref"))])
	if m.modo == "lance" and fase == "flash" and m.t > 0.4:
		fase = "l1"; shot("%d_b_pov" % k)
		print("   3D REF %s cam %s look-> P %s" % [str(m.REF), str(m.cam.global_position), str(m.P)])
	if m.modo == "lance" and fase == "l1" and m.t > m.TC:
		fase = "l2"; shot("%d_c_pov_tc" % k)
		if cima == null:
			cima = Camera3D.new(); m.add_child(cima); cima.fov = 62
			cima.look_at_from_position(Vector3(52.5, 90, 34.01), Vector3(52.5, 0, 34))
		cima.make_current()
	if m.modo == "lance" and fase == "l2" and m.t > m.TC + 0.5:
		fase = "l3"; shot("%d_d_cima" % k); m.cam.make_current()
	if m.modo in ["lance", "var"] and m.dec_shown and fase == "l3":
		fase = "dec"; m.cam_mode = 0
		m._decide(m.L.truth)
		feitos += 1
		if feitos >= 1: quit(); return true
	if m.modo == "gesto" and m.G.get("t", 0.0) > 0.4: m._end_gesture()
	if m.modo == "jogo":
		if fase == "dec": fase = "jogo"
		if m.jogo.mode == "pergunta": m.on_ui("ask", 0)
		if m.jogo.mode == "protesto": m.on_ui("protest", "afastar")
	if m.modo == "intervalo": m.on_ui("second_half", "capitaes")
	if n > 200000: quit(); return true
	return false
