extends SceneTree
func _initialize():
	for f in ["res://scripts/partida.gd", "res://scripts/carreira.gd"]:
		var s = load(f)
		print(f, " ", s != null)
	quit()
