extends SceneTree
# Folha de contacto: clips ainda sem uso, 5 instantes de cada (OUT/clip_N.png).
var m
var OUT := OS.get_environment("OUT")
const C := Vector2(52.5, 34.0)
func _initialize():
	var clips: PackedStringArray = OS.get_environment("CLIPS").split(",")
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	for i in 10: await process_frame
	m.on_ui("treino3d", null)
	for i in 5: await process_frame
	m.modo = "clips"; m.set_process(false); m.set_physics_process(false)
	m.ui.hide_all()
	for e in m.extras: e.node.visible = false
	m.refj.node.visible = false; m.def.node.visible = false
	var j: Jogador = m.att
	for c in clips:
		if not j.anim.has_animation(c): print("falta ", c); continue
		var L: float = j.anim.get_animation(c).length
		j.reset(); j.snap = true
		j.move(C, Vector2(0.5, 0.86).normalized(), 0.0)
		j.play(c, 0.0)
		var t := 0.0
		for k in 5:
			var alvo := L * (0.1 + 0.2 * k)
			while t < alvo:
				j.move(C, Vector2(0.5, 0.86).normalized(), 0.0); j.update(1.0 / 30.0, t); j.ground(); t += 1.0 / 30.0
			m.cam.fov = 30
			m.cam.look_at_from_position(Vector3(C.x, 1.6, C.y + 6.5), Vector3(C.x, 0.9, C.y))
			await process_frame; await process_frame
			root.get_texture().get_image().save_png(OUT + c + "_%d.png" % k)
		print(c, " ", L)
	quit()
