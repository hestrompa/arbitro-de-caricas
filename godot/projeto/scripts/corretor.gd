class_name Corretor
extends Node
# Corre depois de tudo (animações incluídas) em cada frame: impede que os corpos dos jogadores se atravessem.
var main: Node
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
func _process(_dt: float) -> void:
	if main: main._sem_atravessar()
