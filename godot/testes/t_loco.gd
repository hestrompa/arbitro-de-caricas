extends SceneTree
# Pista de locomoção: três jogadores a correr, travar, virar, recuar e andar de lado a olhar para a bola.
# Imagens a 10 por segundo para comparar o antes e o depois (OUT/TAG_NNN.png).
var m
var OUT := "/tmp/claude-0/-home-claude/03cb57f4-a453-5d33-87b7-2efcd6ebbd73/scratchpad/godot/t/loco/"
const C := Vector2(52.5, 34.0)
# trajetória de cada um: lista de [t, posição] e para onde olha (null = para onde anda)
func caminho(k: int, t: float) -> Vector2:
	match k:
		0:   # corre em frente, trava, vira 180 e volta a trote
			if t < 2.0: return C + Vector2(-8 + t * 6.5, -4)
			if t < 2.8: var u := (t - 2.0) / 0.8; return C + Vector2(5 + 6.5 * 0.8 * (u - u * u / 2), -4)
			return C + Vector2(7.6 - (t - 2.8) * 3.2, -4)
		1:   # recua a olhar para a bola, depois passos de lado
			if t < 3.0: return C + Vector2(4 - t * 2.6, 2)
			return C + Vector2(4 - 3.0 * 2.6, 2 + (t - 3.0) * 2.2)
		_:   # anda devagar, para, volta a andar
			if t < 2.5: return C + Vector2(-6 + t * 1.3, 7)
			if t < 3.5: return C + Vector2(-6 + 2.5 * 1.3, 7)
			return C + Vector2(-6 + 2.5 * 1.3 + (t - 3.5) * 1.3, 7 - (t - 3.5) * 0.6)
func _initialize():
	var tag := OS.get_environment("TAG") if OS.get_environment("TAG") != "" else "antes"
	DirAccess.make_dir_recursive_absolute(OUT)
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	for i in 10: await process_frame
	m.on_ui("treino3d", null)
	for i in 5: await process_frame
	m.modo = "clips"; m.set_process(false); m.set_physics_process(false)
	Jogador.natural = OS.get_environment("NATURAL") != "0"
	m.ui.hide_all()
	for e in m.extras: e.node.visible = false
	m.refj.node.visible = false
	var js: Array = [m.att, m.def, m.extras[0]]
	js[2].node.visible = true
	var bola := C + Vector2(10, 0)
	m.ball.position = Vector3(bola.x, 0.11, bola.y)
	Jogador.bola3 = m.ball.position
	var dt := 1.0 / 30.0
	var t := 0.0
	var k := 0
	var prev: Array = []
	for j in js: prev.append(null)
	for j in js: j.reset(); j.snap = true
	while t < 6.0:
		for i in 3:
			var j: Jogador = js[i]
			var p := caminho(i, t)
			var v := (caminho(i, t + 0.05) - p) / 0.05
			var face: Vector2 = v.normalized() if v.length() > 0.3 else j.dir
			if i == 1: face = (bola - p).normalized()        # o 2.º olha sempre para a bola
			j.move(p, face, v.length())
			j.play("run" if v.length() > 4.2 else ("jog" if v.length() > 0.7 else "idle"), 0.3)
			j.update(dt, t)
			j.ground()
		m.cam.fov = 34
		m.cam.look_at_from_position(Vector3(C.x - 0.5, 4.2, C.y + 17), Vector3(C.x - 0.5, 0.9, C.y + 2.5))
		if OS.get_environment("SEGUE") != "":          # câmara de perto atrás de um deles
			var q: Vector2 = js[int(OS.get_environment("SEGUE"))].pos
			m.cam.fov = 40
			m.cam.look_at_from_position(Vector3(q.x + 1.5, 2.2, q.y + 7.0), Vector3(q.x, 0.9, q.y))
		await process_frame
		if int(round(t * 30)) % 3 == 0:
			await process_frame
			root.get_viewport().get_texture().get_image().save_png(OUT + "%s_%03d.png" % [tag, k]); k += 1
		t += dt
	print("feito ", k)
	quit()
