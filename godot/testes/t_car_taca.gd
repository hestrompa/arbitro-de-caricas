extends SceneTree
func _init():
	var car := Carreira.new()
	car.new_career()
	car.C.tier = 5; car.C.round = 0
	var B := car.match_brief()
	var P := Partida.new(Carreira.teams_for(B.h, B.a, car.C.tier))
	car.setup_match(P)
	print(B.comp, " taca=", P.taca)
	quit()
