extends SceneTree
# Levantar de costas: força quedas para trás e mede se o corpo salta quando começa e quando acaba o levantar.
var m
func _initialize():
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	for i in 10: await process_frame
	m.on_ui("treino3d", null)
	for i in 5: await process_frame
	var FOTO := OS.get_environment("FOTO") != ""
	var nr := 2 if FOTO else 6
	for r in nr:
		m.cur = {"lance": 3, "force": 0.8, "side": -1.0, "sim": false, "clean": true, "phi": 50.0, "vD": 8.0}
		m._restart()
		while m.t < m.TC + 0.6: await process_frame
		var j: Jogador = m.def
		j.hurt = 0.0 if r % 2 == 0 else 1.0
		var fw := Vector3(sin(j.node.rotation.y), 0, cos(j.node.rotation.y))
		j.fall(-fw * 2.4 + Vector3(0, 0.3, 0), ["spine03"], -fw * 2.8 + Vector3(0, 0.2, 0), "fallback", 0.5)
		var antes := Vector3.INF
		var maxs := 0.0
		var prev := Vector3.INF
		var anim_l := ""
		var fase_prev := ""
		var t0 := 0.0
		var quando := ""
		var fotos := 0
		while m.t < m.TC + 7.0:
			await process_frame
			var p: Vector3 = j.skel.global_transform * j.skel.get_bone_global_pose(0).origin
			if j.phase == "levantar" and fase_prev != "levantar": anim_l = j.getup_anim; t0 = m.t
			if prev != Vector3.INF and (j.phase == "levantar" or fase_prev == "levantar") and (p - prev).length() > maxs:
				maxs = (p - prev).length(); quando = "%.2f s %s->%s getupT=%.2f" % [m.t - t0, fase_prev, j.phase, j.getupT]
			prev = p; fase_prev = j.phase
			if FOTO and Engine.get_process_frames() % 4 == 0 and fotos < 40 and j.groundT > 1.0 and (j.phase == "chao" or (j.phase == "levantar") or m.t - t0 < 2.2) and t0 >= 0.0:
				var bp: Vector3 = j.bones[0].global_position if j.rag else p
				m.set_process(false)
				m.cam.fov = 45
				m.cam.look_at_from_position(bp + Vector3(4.5, 1.6, 2.5), bp + Vector3(0, 0.4, 0))
				await process_frame
				root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/-home-claude/03cb57f4-a453-5d33-87b7-2efcd6ebbd73/scratchpad/quat/lev/%d_%03d.png" % [r, fotos])
				fotos += 1
				m.set_process(true)
		print("queda ", r, " levantar=", anim_l, " fase final=", j.phase, " maior passo da bacia por frame=%.2f m" % maxs, " em ", quando)
	quit()
