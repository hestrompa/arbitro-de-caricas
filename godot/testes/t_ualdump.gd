extends SceneTree
# Grava as poses globais dos ossos dos clips UAL (Quaternius) a 30 fps, no formato do fbxdump (para o mx.py).
const DL = "/tmp/claude-0/-home-claude/03cb57f4-a453-5d33-87b7-2efcd6ebbd73/scratchpad/quat/dl/"
const OUT = "/tmp/claude-0/-home-claude/03cb57f4-a453-5d33-87b7-2efcd6ebbd73/scratchpad/quat/dump_ual.json"
const CLIPS = {"UAL1.glb": ["A_TPose", "Sprint_Loop", "Walk_Loop", "Jog_Fwd_Loop", "Idle_Loop", "Idle_Tired_Loop", "Idle_Talking_Loop", "Hit_Chest", "Hit_Head", "Hit_Shoulder_L", "Hit_Shoulder_R", "Hit_Stomach", "Push_Enter", "Push_Loop", "Celebration", "Death01", "Death02", "Dodge_Left", "Dodge_Right", "Kick"],
	"UAL2.glb": ["Hit_Knockback", "IdleToLay", "LayToIdle", "KipUp", "Idle_No_Loop", "Idle_FoldArms_Loop", "Yes", "Surprise", "Walk_Bwd_Loop"]}
func _initialize():
	await process_frame
	var out := {}
	for f in CLIPS:
		var doc := GLTFDocument.new(); var st := GLTFState.new()
		doc.append_from_file(DL + f, st)
		var sc: Node3D = doc.generate_scene(st)
		root.add_child(sc)
		await process_frame
		var sk: Skeleton3D = sc.find_children("*", "Skeleton3D", true, false)[0]
		var ap: AnimationPlayer = sc.find_children("*", "AnimationPlayer", true, false)[0]
		var names := []; var par := []; var rest_p := []; var rest_q := []
		for i in sk.get_bone_count():
			names.append(sk.get_bone_name(i)); par.append(sk.get_bone_parent(i))
			var g := sk.global_transform * sk.get_bone_global_rest(i)
			rest_p.append([g.origin.x, g.origin.y, g.origin.z])
			var q := g.basis.orthonormalized().get_rotation_quaternion(); rest_q.append([q.x, q.y, q.z, q.w])
		for an_name in CLIPS[f]:
			var an := ap.get_animation(an_name)
			var rec := {"names": names, "parent": par, "rest_p": rest_p, "rest_q": rest_q, "fps": 30, "pos": [], "rot": [], "anim": an_name, "length": an.length}
			ap.play(an_name)
			var n := int(floor(an.length * 30.0)) + 1
			for k in n:
				ap.seek(min(k / 30.0, an.length), true)
				var fp := []; var fq := []
				for i in sk.get_bone_count():
					var g := sk.global_transform * sk.get_bone_global_pose(i)
					fp.append([g.origin.x, g.origin.y, g.origin.z])
					var q := g.basis.orthonormalized().get_rotation_quaternion(); fq.append([q.x, q.y, q.z, q.w])
				rec.pos.append(fp); rec.rot.append(fq)
			out[an_name] = rec
			print(an_name, " frames ", rec.pos.size(), " len ", an.length, " loop ", an.loop_mode)
		sc.queue_free()
	var fa := FileAccess.open(OUT, FileAccess.WRITE); fa.store_string(JSON.stringify(out)); fa.close()
	quit()
