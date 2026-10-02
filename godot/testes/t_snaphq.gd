extends SceneTree
var m
const OUT = "/tmp/claude-0/-home-claude/03cb57f4-a453-5d33-87b7-2efcd6ebbd73/scratchpad/godot/t/jhq/"
func shot(n):
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png(OUT + n + ".png")
func _initialize():
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	for i in 30: await process_frame
	await shot("0_menu")
	m._start_match()
	var k := 0
	while k < 2:
		await process_frame
		if m.modo == "jogo": m.jogo.ref_target = m.jogo.bp + Vector2(0, 9)
		if m.modo == "jogo" and m.jogo.t > 6 and k == 0 and m.flash_t <= 0:
			await shot("1_campo"); k = 1
		if m.modo == "lance" and k == 1:
			while m.t < m.TC + 0.25: await process_frame
			await shot("2_lance_contacto")
			while m.t < m.TC + 1.7: await process_frame
			await shot("3_decide")
			m._decide(m.L.truth)
			for i in 20: await process_frame
			await shot("4_veredicto")
			k = 2
	while m.modo != "jogo": await process_frame
	for i in 10: await process_frame
	await shot("5_campo_depois")
	m.jogo.t = 299.5
	while m.modo != "fim": await process_frame
	await shot("6_relatorio")
	quit()
