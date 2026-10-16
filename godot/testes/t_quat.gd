extends SceneTree
# Lado a lado: o nosso jogador (esquerda) contra o boneco da Quaternius com as animações UAL 1 e 2 (direita).
# Os GLB são lidos em tempo de execução (GLTFDocument), por isso não entram no projeto nem na exportação.
var m
const DL = "/tmp/claude-0/-home-claude/03cb57f4-a453-5d33-87b7-2efcd6ebbd73/scratchpad/quat/dl/"
const OUT = "/tmp/claude-0/-home-claude/03cb57f4-a453-5d33-87b7-2efcd6ebbd73/scratchpad/quat/f3/"
const FPS = 12.0
const DUR = 2.5
# [o nosso clip atual ou "", o mesmo movimento da Quaternius já no nosso jogador, o original no boneco, legenda]
const PARES = [
	["run", "q_sprint", "Sprint_Loop", "Corrida"],
	["jog", "q_jog", "Jog_Fwd_Loop", "Trote"],
	["walk", "q_walk", "Walk_Loop", "Andar"],
	["idle", "q_idle", "Idle_Loop", "Parado"],
	["trip", "q_projetado", "u2/Hit_Knockback", "Queda depois de um toque"],
	["standup", "q_levanta", "u2/LayToIdle", "Levantar do chao"],
	["", "q_toque_ombro_l", "Hit_Shoulder_L", "Toque no ombro"],
	["", "q_toque_barriga", "Hit_Stomach", "Toque na barriga"],
	["", "q_empurra", "Push_Loop", "Empurrar"],
	["", "q_nao", "u2/Idle_No_Loop", "Protestar"],
	["", "q_cansado", "Idle_Tired_Loop", "Cansado"],
	["", "q_festa", "Celebration", "Festejar"],
	["", "q_cai1", "Death01", "Cair"],
	["", "q_surpresa", "u2/Surprise", "Surpresa"],
	["", "q_bracos", "u2/Idle_FoldArms_Loop", "Bracos cruzados"],
	["", "q_sim", "u2/Yes", "Sim com a cabeca"],
	["", "q_fala", "Idle_Talking_Loop", "Falar"],
]

func _carrega(f: String) -> Node3D:
	var doc := GLTFDocument.new()
	var st := GLTFState.new()
	var err := doc.append_from_file(DL + f, st)
	if err != OK: push_error("gltf " + f + " " + str(err))
	return doc.generate_scene(st)

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
	m.ball.visible = false; m.refj.node.visible = false
	var j: Jogador = m.att
	var j2: Jogador = m.def
	# mais leve para o render por software: sem público
	for mi in m.find_children("*", "MultiMeshInstance3D", true, false): mi.visible = false
	print("clips nossos: ", j.anim.get_animation_list())
	# boneco da Quaternius
	var q := _carrega("UAL1.glb")
	m.add_child(q)
	var qa: AnimationPlayer = q.find_children("*", "AnimationPlayer", true, false)[0]
	var q2 := _carrega("UAL2.glb")
	var qa2: AnimationPlayer = q2.find_children("*", "AnimationPlayer", true, false)[0]
	var lib2 := AnimationLibrary.new()
	for n in qa2.get_animation_list(): lib2.add_animation(n, qa2.get_animation(n))
	qa.add_animation_library("u2", lib2)
	var qs: Skeleton3D = q.find_children("*", "Skeleton3D", true, false)[0]
	# mesma altura que o nosso (cabeça em pé)
	qa.play("Idle_Loop"); qa.seek(0.0, true)
	j.state = ""; j.play("idle", 0.0); j.anim.seek(0.0, true); j.anim.advance(0)
	await process_frame
	var hq: float = (qs.global_transform * qs.get_bone_global_pose(qs.find_bone("Head"))).origin.y - q.global_position.y
	var hj: float = (j.skel.global_transform * j.skel.get_bone_global_pose(j.skel.find_bone("head"))).origin.y - j.node.global_position.y
	print("altura cabeça q=", hq, " nosso=", hj)
	q.scale = Vector3.ONE * (hj / hq)
	var cx := 50.0; var cz := 34.0
	var lj := Label3D.new(); m.add_child(lj); lj.font_size = 48; lj.pixel_size = 0.004; lj.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	var lq := Label3D.new(); m.add_child(lq); lq.font_size = 48; lq.pixel_size = 0.004; lq.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	var lt := Label3D.new(); m.add_child(lt); lt.font_size = 64; lt.pixel_size = 0.004; lt.billboard = BaseMaterial3D.BILLBOARD_ENABLED; lt.outline_size = 12
	var so := OS.get_environment("SO")
	var pi := 0
	var l2 := Label3D.new(); m.add_child(l2); l2.font_size = 48; l2.pixel_size = 0.004; l2.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	for P in PARES:
		pi += 1
		if so != "" and not (str(pi) in so.split(",")): continue
		var c: String = P[0]; var c2: String = P[1]; var cq: String = P[2]
		var aq := qa.get_animation(cq)
		var n := int(DUR * FPS)
		if not aq.loop_mode: n = maxi(n, int(minf(aq.length + 0.4, 4.5) * FPS))
		if c != "" and not j.anim.get_animation(c).loop_mode: n = maxi(n, int(minf(j.anim.get_animation(c).length + 0.4, 4.5) * FPS))
		for k in n:
			var tm: float = k / FPS
			for J in [[j, c if c != "" else "idle"], [j2, c2]]:
				var jj: Jogador = J[0]; var cc: String = J[1]
				var an := jj.anim.get_animation(cc)
				jj.state = cc; jj.anim.play(cc, 0.0); jj.anim.speed_scale = 1.0   # direto ao clip (o play() escolhe a corrida pela velocidade)
				jj.anim.seek(fmod(tm, an.length) if an.loop_mode else minf(tm, an.length), true); jj.anim.advance(0)
			qa.play(cq); qa.seek(fmod(tm, aq.length) if aq.loop_mode else minf(tm, aq.length), true); qa.advance(0)
			j.node.position = Vector3(cx, 0, cz + 2.0); j.node.rotation.y = 0
			j2.node.position = Vector3(cx, 0, cz); j2.node.rotation.y = 0
			q.position = Vector3(cx, 0, cz - 2.0); q.rotation.y = 0.0
			# os pés no chão: acerta a altura pelo osso mais baixo
			for jj in [j, j2]:
				var low := 99.0
				for i in jj.skel.get_bone_count(): low = min(low, (jj.skel.global_transform * jj.skel.get_bone_global_pose(i)).origin.y)
				jj.node.position.y += 0.06 - low
			var lowq := 99.0
			for i in qs.get_bone_count(): lowq = min(lowq, (qs.global_transform * qs.get_bone_global_pose(i)).origin.y)
			q.position.y += 0.03 - lowq
			lj.text = ("atual: " + c) if c != "" else "atual: nao existe"
			l2.text = "novo (Quaternius)"
			lq.text = "original"
			lj.position = Vector3(cx, 2.25, cz + 2.0); l2.position = Vector3(cx, 2.25, cz); lq.position = Vector3(cx, 2.25, cz - 2.0)
			lt.text = P[3]; lt.position = Vector3(cx, 2.7, cz)
			m.cam.fov = 40
			m.cam.look_at_from_position(Vector3(cx + 9.5, 1.3, cz), Vector3(cx, 0.95, cz))
			await process_frame
			await process_frame
			root.get_viewport().get_texture().get_image().save_png(OUT + "%02d_%03d.png" % [pi, k])
		print("feito ", pi, " ", P[3], " ", n)
	quit()
