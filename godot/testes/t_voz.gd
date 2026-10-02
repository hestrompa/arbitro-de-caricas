extends SceneTree
# Falas gravadas: todas as chaves de assets/voz/voz.json carregam no jogo,
# e um jogo simulado não pede nenhuma fala que falte (fica em som.faltas).
func _initialize():
	var m = load("res://main.tscn").instantiate()
	root.add_child(m)
	await process_frame
	var idx: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/voz/voz.json"))
	var bad := 0
	for k in idx:
		if not m.som.tem_fala(k): bad += 1; print("NÃO CARREGA: ", k)
	print("falas no índice ", idx.size(), " em falta ", bad)
	for k in ["Vi as imagens. Chegaste atrasado. Falta.", "Entrada imprudente. Amarelo. É o segundo: rua!"]:
		print(k, " -> ", m.som._falas(k).size())
	quit()
