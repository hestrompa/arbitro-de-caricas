extends SceneTree
# Pormenores 3D de perto: número nas costas, cartão na mão do árbitro, cara.
var m
const OUT = "/tmp/claude-0/-home-claude/03cb57f4-a453-5d33-87b7-2efcd6ebbd73/scratchpad/godot/t/d/"
func shot(nome: String, eye: Vector3, look: Vector3, fov := 30.0) -> void:
	m.cam.fov = fov
	m.cam.look_at_from_position(eye, look)
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png(OUT + nome + ".png")
func _initialize():
	DirAccess.make_dir_recursive_absolute(OUT)
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	for i in 10: await process_frame
	m.on_ui("partida", null)
	for i in 30: await process_frame
	var who: int = m.jogo.players.filter(func(p): return p.num >= 10)[0].id
	m.L = {"ref": Vector2(52, 33)}
	m._start_gesture({"say": "Entrada imprudente. Amarelo.", "gest": {"type": "card", "col": "yellow", "who": who, "spot": Vector2(50, 30), "dur": 30.0}, "d": "amarelo"})
	m.set_process(false)
	for i in 70: m._gesture_process(1.0 / 60.0); await process_frame
	var r: Jogador = m.refj; var a: Jogador = m.att
	var hand: Vector3 = r.bone_world("wrist_R")
	await shot("cartao_geral", r.node.position + Vector3(2.6, 1.7, 2.6), r.node.position + Vector3(0, 1.4, 0), 40)
	await shot("cartao_mao", hand + Vector3(0.9, 0.1, 0.9), hand, 30)
	var ab: Vector3 = a.node.position
	var bk: Vector3 = -a.node.global_transform.basis.z
	await shot("costas", ab + Vector3(0, 1.3, 0) - Vector3(sin(a.node.rotation.y), 0, cos(a.node.rotation.y)) * 2.2, ab + Vector3(0, 1.2, 0), 40)
	await shot("frente", ab + Vector3(0, 1.5, 0) + Vector3(sin(a.node.rotation.y), 0, cos(a.node.rotation.y)) * 1.2, a.bone_world("head"), 30)
	print("FEITO num=", a.num)
	quit()
