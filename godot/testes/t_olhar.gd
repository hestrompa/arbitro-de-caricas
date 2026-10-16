extends SceneTree
# a cabeça segue a bola: o "nariz" da cabeça aproxima-se da direção da bola (e não se afasta)
func _initialize():
	var m = load("res://main.tscn").instantiate()
	root.add_child(m)
	for i in 10: await process_frame
	m.on_ui("treino3d", null)
	for i in 5: await process_frame
	m.modo = "clips"; m.set_process(false); m.set_physics_process(false)
	var j = m.att
	j.reset(); j.snap = true
	j.move(Vector2(50, 30), Vector2(0, 1), 0.0)
	j.play("idle", 0.0)
	var nariz := func() -> Basis:
		var b: Basis = j.skel.global_transform.basis * j.skel.get_bone_global_pose(j.bi["head"]).basis
		return b
	for caso in [["sem bola", Vector3.INF], ["bola à esquerda (+x)", Vector3(56, 0.1, 30)], ["bola à direita (-x)", Vector3(44, 0.1, 30)], ["bola em frente", Vector3(50, 0.1, 38)]]:
		Jogador.bola3 = caso[1]
		for i in 40: j.update(1.0 / 30.0, i / 30.0)
		var b: Basis = nariz.call()
		print(caso[0], ": eixos da cabeça x ", b.x.normalized().snapped(Vector3.ONE * 0.01), " y ", b.y.normalized().snapped(Vector3.ONE * 0.01), " z ", b.z.normalized().snapped(Vector3.ONE * 0.01), " olhar ", j.olhar_yp)
	quit()
