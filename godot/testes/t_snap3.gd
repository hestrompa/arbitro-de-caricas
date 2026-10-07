extends SceneTree
var m
const OUT = "/tmp/claude-0/-home-claude/03cb57f4-a453-5d33-87b7-2efcd6ebbd73/scratchpad/godot/t/j/"
func shot(n):
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png(OUT + n + ".png")
func _initialize():
	DirAccess.make_dir_recursive_absolute(OUT)
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	for i in 30: await process_frame
	m.on_ui("partida", null)
	var k := 0
	var n := 0
	while k < 3 and n < 20000:
		n += 1
		await process_frame
		if m.modo == "jogo" and m.jogo.mode == "pergunta": m.on_ui("ask", 0)
		if m.modo == "jogo" and m.jogo.mode == "protesto": m.on_ui("protest", "afastar")
		if m.modo == "gesto" and m.G.get("t", 0.0) > 0.4: m._end_gesture()
		if m.modo == "jogo" and m.jogo.t > 8 + k * 30 and k < 1:
			await shot("c%d" % k); k += 1
		if m.modo == "lance" and m.dec_shown == false and m.t > m.TC - 0.3 and k >= 1:
			m.cam_mode = 0
			while m.t < m.TC + 0.2: await process_frame
			await shot("l%d_tua" % k)
			m.cam_mode = 1
			await shot("l%d_ideal" % k)
			m.cam_mode = 3
			await shot("l%d_perto" % k)
			while not m.dec_shown: await process_frame
			m._decide(m.L.truth)
			k += 1
	quit()
