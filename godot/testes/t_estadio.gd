extends SceneTree
var m
const OUT = "/tmp/claude-0/-home-claude/03cb57f4-a453-5d33-87b7-2efcd6ebbd73/scratchpad/godot/t/e/"
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
	m.on_ui("treino3d", null)
	for i in 30: await process_frame
	m.set_process(false)
	m._set_night(OS.get_environment("NOITE") != "")
	await shot("tv", Vector3(52, 17, -15), Vector3(52, 0, 34), 55)
	await shot("baliza", Vector3(-6, 3, 34), Vector3(20, 1, 34), 60)
	await shot("rasante", Vector3(60, 1.75, 50), Vector3(40, 3, 10), 55)
	await shot("rede", Vector3(6, 1.6, 30), Vector3(-1, 1.2, 34), 50)
	await shot("canto", Vector3(20, 3, 20), Vector3(-15, 8, -13), 60)
	await shot("canto2", Vector3(52, 30, 34), Vector3(-15, 0, -13), 60)
	print("FEITO")
	quit()
