extends SceneTree
# Folha de contacto dos clips novos (vista de lado), para ver se o retarget ficou bem.
var m
const OUT = "/tmp/claude-0/-home-claude/03cb57f4-a453-5d33-87b7-2efcd6ebbd73/scratchpad/godot/t/c/"
func _initialize():
	DirAccess.make_dir_recursive_absolute(OUT)
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	for i in 10: await process_frame
	m.on_ui("treino3d", null)
	for i in 5: await process_frame
	m.modo = "clips"; m.set_process(false); m.set_physics_process(false)
	m.ui.hide_all()
	for e in m.extras: e.node.visible = false
	m.def.node.visible = false; m.ball.visible = false; m.refj.node.visible = false
	var j: Jogador = m.att
	var clips = OS.get_environment("CLIPS").split(",")
	for c in clips:
		var an := j.anim.get_animation(c)
		for k in 8:
			var tm: float = an.length * k / 7.0
			j.state = ""; j.play(c, 0.0); j.anim.speed_scale = 1.0; j.anim.seek(tm, true); j.anim.advance(0)
			j.node.position = Vector3(50, 0, 34); j.node.rotation.y = 0
			var low := 99.0
			for i in j.skel.get_bone_count(): low = min(low, (j.skel.global_transform * j.skel.get_bone_global_pose(i)).origin.y)
			j.node.position.y = 0.06 - low
			var bp := j.skel.global_transform * j.skel.get_bone_global_pose(0).origin
			m.cam.fov = 40
			m.cam.look_at_from_position(Vector3(bp.x + 5.5, 1.0, bp.z), Vector3(bp.x, 0.7, bp.z))
			await process_frame
			await process_frame
			root.get_viewport().get_texture().get_image().save_png(OUT + "%s_%d.png" % [c, k])
		print("feito ", c)
	quit()
