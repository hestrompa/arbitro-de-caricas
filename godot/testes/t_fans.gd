extends SceneTree
var m
const OUT = "/tmp/claude-0/-home-claude/03cb57f4-a453-5d33-87b7-2efcd6ebbd73/scratchpad/godot/t/f/"
func shot(nome: String, eye: Vector3, look: Vector3, fov := 50.0) -> void:
	m.cam.fov = fov
	m.cam.look_at_from_position(eye, look)
	for i in 3: await process_frame
	root.get_viewport().get_texture().get_image().save_png(OUT + nome + ".png")
func _initialize():
	DirAccess.make_dir_recursive_absolute(OUT)
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	for i in 10: await process_frame
	m.on_ui("partida", null)
	for i in 30: await process_frame
	m.L = {"ref": Vector2(52, 33)}
	var who: int = m.jogo.players[3].id
	m._start_gesture({"say": "Amarelo.", "gest": {"type": "card", "col": "yellow", "who": who, "spot": Vector2(50, 30), "dur": 30.0}, "d": "amarelo"})
	m.set_process(false)
	m._set_night(false)
	for i in 10: m._gesture_process(1.0 / 60.0); await process_frame
	var n := 0
	for f in m.fan_mms: n += f[0].instance_count
	print("ADEPTOS=", n)
	await shot("calmo", Vector3(40, 2, 2), Vector3(40, 7, -15), 40)
	m.fan_mat.set_shader_parameter("festa", 1.0)
	await shot("festa", Vector3(40, 2, 2), Vector3(40, 7, -15), 40)
	m.fan_mat.set_shader_parameter("festa", 0.0); m.fan_mat.set_shader_parameter("protesto", 1.0)
	await shot("protesto", Vector3(30, 3, 20), Vector3(30, 9, -18), 35)
	m.fan_mat.set_shader_parameter("protesto", 0.0)
	await shot("lado", Vector3(105, 4, 35), Vector3(130, 8, 35), 60)
	print("FEITO")
	quit()
