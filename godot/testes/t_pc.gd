extends SceneTree
func _initialize():
	for f in ["res://scripts/partida.gd", "res://scripts/carreira.gd", "res://scripts/main.gd", "res://scripts/campo2d.gd", "res://scripts/jogador.gd"]:
		var s = load(f)
		print(f, " ", s != null)
	quit()
