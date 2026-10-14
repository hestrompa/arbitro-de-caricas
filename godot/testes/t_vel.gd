extends SceneTree
func _initialize():
	var m = load("res://main.tscn").instantiate()
	root.add_child(m)
	for i in 5: await process_frame
	for c in Jogador.clip_vel.keys(): print(c, " vel ", Jogador.clip_vel[c], " |v| ", snappedf(Jogador.clip_vel[c].length(), 0.01), " fase ", snappedf(Jogador.clip_fase[c], 0.01), " len ", snappedf(m.att.anim.get_animation(c).length, 0.01))
	quit()
