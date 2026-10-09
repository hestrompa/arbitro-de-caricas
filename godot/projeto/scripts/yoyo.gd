class_name TesteFisico
extends Control
# Teste físico dos árbitros (yo-yo intermitente): correr 20 m e voltar ao ritmo dos apitos, cada vez mais depressa.
# Carrega em Espaço (ou toca no ecrã) no instante em que chegas à linha. Cedo ou tarde demais é um aviso;
# dois avisos e o teste acaba. O nível alcançado dá experiência no Físico.

signal fim(percursos: int, nivel: String)

const JANELA := 0.16          # segundos de folga em cada linha
var t := 0.0                  # tempo dentro do percurso atual
var dur := 3.2                # quanto demora o percurso (encurta a cada nível)
var n := 0                    # percursos feitos
var avisos := 0
var dir := 1.0                # 1 = para a direita
var estado := "pronto"        # pronto | corre | pausa | fim
var pausa := 0.0
var flash := ""
var flash_t := 0.0
var flash_c := Color.WHITE
var font: Font
var som: Node

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	font = ThemeDB.fallback_font

func nivel_txt() -> String: return "%d.%d" % [5 + n / 4, n % 4 + 1]

func _process(dt: float) -> void:
	if flash_t > 0.0: flash_t -= dt
	match estado:
		"corre":
			t += dt
			if t > dur + JANELA:
				_falha("Atrasado!")
		"pausa":
			pausa -= dt
			if pausa <= 0.0:
				estado = "corre"; t = 0.0
				if som: som.whistle("short")
	queue_redraw()

func _carrega() -> void:
	if estado == "pronto":
		estado = "corre"; t = 0.0
		if som: som.whistle("short")
		return
	if estado != "corre": return
	var erro := t - dur
	if absf(erro) <= JANELA:
		n += 1; dir = -dir
		flash = "Na linha!" if absf(erro) < JANELA * 0.5 else "Mesmo a tempo"; flash_c = Color("58d27a"); flash_t = 0.6
		# a cada dois percursos, 4 s de recuperação (como no teste a sério) e mais depressa
		dur = maxf(1.25, 3.2 * pow(0.955, n))
		estado = "pausa"; pausa = 1.2 if n % 2 == 0 else 0.25
	elif erro < 0.0:
		_falha("Cedo demais!")

func _falha(txt: String) -> void:
	avisos += 1
	flash = txt; flash_c = Color("ef6b5b"); flash_t = 0.9
	if avisos >= 2:
		estado = "fim"
		if som: som.whistle("long")
		var tw := create_tween(); tw.tween_interval(1.4); tw.tween_callback(func(): fim.emit(n, nivel_txt()))
		return
	dir = -dir; estado = "pausa"; pausa = 1.4

func _gui_input(e: InputEvent) -> void:
	if (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed): _carrega(); accept_event()
func _unhandled_input(e: InputEvent) -> void:
	if not visible: return
	if e is InputEventKey and e.pressed and not e.echo and e.keycode in [KEY_SPACE, KEY_ENTER]: _carrega(); get_viewport().set_input_as_handled()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.09, 0.06, 0.97))
	var cx := size.x / 2
	var gold := Color(1.0, 0.86, 0.35)
	draw_string(font, Vector2(0, 70), "Teste físico · yo-yo", HORIZONTAL_ALIGNMENT_CENTER, size.x, 30, gold)
	draw_string(font, Vector2(0, 104), "Carrega em Espaço (ou toca) no instante em que chegas à linha. Dois avisos e acaba.", HORIZONTAL_ALIGNMENT_CENTER, size.x, 16, Color(0.75, 0.8, 0.76))
	# pista de 20 m
	var w := minf(size.x - 120, 900.0)
	var x0 := cx - w / 2
	var y := size.y * 0.5
	draw_rect(Rect2(x0 - 30, y - 50, w + 60, 100), Color(0.16, 0.42, 0.2))
	for k in 2:
		var lx := x0 + w * k
		draw_line(Vector2(lx, y - 50), Vector2(lx, y + 50), Color.WHITE, 4)
		# zona boa na linha de chegada
		if estado == "corre" and ((dir > 0 and k == 1) or (dir < 0 and k == 0)):
			var zw := w * JANELA / dur
			draw_rect(Rect2(lx - zw, y - 50, zw * 2, 100), Color(0.35, 0.95, 0.45, 0.18))
	draw_string(font, Vector2(x0 - 30, y + 80), "20 m", HORIZONTAL_ALIGNMENT_CENTER, w + 60, 14, Color(0.75, 0.8, 0.76))
	# o árbitro
	var f := clampf(t / dur, 0.0, 1.08) if estado == "corre" else (0.0 if estado != "fim" else 1.0)
	var px := x0 + w * (f if dir > 0 else 1.0 - f)
	if estado == "pausa" or estado == "pronto": px = x0 + (0.0 if dir > 0 else w)
	draw_circle(Vector2(px, y), 18, Color("f4e04d"))
	draw_arc(Vector2(px, y), 18, 0, TAU, 24, Color("111111"), 2.5)
	draw_string(font, Vector2(px - 20, y + 7), "Á", HORIZONTAL_ALIGNMENT_CENTER, 40, 20, Color("111111"))
	# apito: barra do tempo até ao apito
	if estado == "corre":
		var q := clampf(t / dur, 0.0, 1.0)
		draw_rect(Rect2(x0, y + 110, w, 10), Color(1, 1, 1, 0.12))
		draw_rect(Rect2(x0, y + 110, w * q, 10), gold)
	draw_string(font, Vector2(0, y - 90), "Nível %s   ·   percursos %d   ·   avisos %d/2" % [nivel_txt(), n, avisos], HORIZONTAL_ALIGNMENT_CENTER, size.x, 22, Color(0.96, 0.96, 0.93))
	var msg := ""
	if estado == "pronto": msg = "Carrega para começar"
	elif estado == "fim": msg = "Fim do teste: nível %s" % nivel_txt()
	elif estado == "pausa" and pausa > 0.6: msg = "Recupera..."
	if msg != "": draw_string(font, Vector2(0, y + 170), msg, HORIZONTAL_ALIGNMENT_CENTER, size.x, 24, gold)
	if flash_t > 0.0: draw_string(font, Vector2(0, y + 210), flash, HORIZONTAL_ALIGNMENT_CENTER, size.x, 28, flash_c)
