extends SceneTree
func _init():
	var tms := Carreira.default_teams()
	var S := Partida.new(tms)
	print("ok ", S.players.size(), " ", S.players[9].name)
	quit()
