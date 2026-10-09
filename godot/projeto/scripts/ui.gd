class_name UI
extends CanvasLayer
const VERSAO := preload("res://scripts/versao.gd")   # gerado pelo publicar.sh
# Todos os ecrãs e avisos: menu, carreira, decisões, perguntas, protestos, intervalo, relatório,
# rádio, relato, frase do árbitro, tutorial e ficha do jogador. Cada botão chama main.on_ui(ação, valor).

const DEC_COL := {"siga": Color("2f8a4a"), "falta": Color("3a5fa8"), "amarelo": Color("c9a514"), "vermelho": Color("c0392b"), "simulacao": Color("7d4fb3"),
	"vantagem": Color("1f8f8a"), "emjogo": Color("2f8a4a"), "fora": Color("c0392b"), "mao": Color("3a5fa8"), "maoAmarelo": Color("c9a514"), "penalti": Color("c0392b"),
	"ataque": Color("3a5fa8"), "valido": Color("2f8a4a"), "anular": Color("c0392b"), "entrou": Color("2f8a4a"), "naoEntrou": Color("c0392b")}
const BG := Color(0.04, 0.07, 0.05, 0.9)
const INK := Color(0.96, 0.96, 0.93)
const DIM := Color(0.72, 0.78, 0.74)
const GOLD := Color(1.0, 0.86, 0.35)
const OK := Color("58d27a")
const HALF := Color("e6c04a")
const BAD := Color("ef6b5b")

var main: Node
var root: Control
var menu: PanelContainer
var menu_v: VBoxContainer
var career: PanelContainer
var career_v: VBoxContainer
var dec: PanelContainer
var dec_row: HBoxContainer
var dec_lbl: Label
var ask: PanelContainer
var ask_v: VBoxContainer
var half: PanelContainer
var half_v: VBoxContainer
var report: PanelContainer
var report_v: VBoxContainer
var toast_l: Label
var toast_t := 0.0
var radio_p: PanelContainer
var radio_who: Label
var radio_txt: Label
var radio_t := 0.0
var ticker: Label
var ticker_t := 0.0
var say_p: PanelContainer
var say_l: Label
var top_l: Label
var sub_l: Label
var flash_l: Label
var flash_t := 0.0
var tut_p: PanelContainer
var tut_l: Label
var tut_s: Label
var tut_b: Button
var card_p: PanelContainer
var card_v: VBoxContainer
var card_t := 0.0
var var_frame: Panel
var talk := "descanso"
var talk_btns := {}
var entrevista_box: VBoxContainer = null
var reset_armed := false

func _init(m: Node) -> void:
	main = m
	layer = 10

func _ready() -> void:
	root = Control.new(); root.set_anchors_preset(Control.PRESET_FULL_RECT); root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var th := Theme.new()
	th.default_font_size = 17
	th.set_color("font_color", "Label", INK)
	th.set_color("font_color", "Button", INK)
	var bn := StyleBoxFlat.new(); bn.bg_color = Color(0.16, 0.22, 0.18); bn.set_corner_radius_all(9); bn.set_content_margin_all(10)
	var bh := bn.duplicate(); bh.bg_color = Color(0.22, 0.31, 0.25)
	var bd := bn.duplicate(); bd.bg_color = Color(0.12, 0.14, 0.13)
	th.set_stylebox("normal", "Button", bn); th.set_stylebox("hover", "Button", bh); th.set_stylebox("pressed", "Button", bh); th.set_stylebox("disabled", "Button", bd)
	th.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	root.theme = th
	# avisos
	top_l = _lbl("", 17, INK); top_l.position = Vector2(14, 10); root.add_child(top_l)
	sub_l = _lbl("", 16, GOLD); sub_l.position = Vector2(14, 36); root.add_child(sub_l)
	flash_l = _lbl("", 54, GOLD); flash_l.set_anchors_preset(Control.PRESET_CENTER); flash_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	flash_l.grow_horizontal = Control.GROW_DIRECTION_BOTH; flash_l.grow_vertical = Control.GROW_DIRECTION_BOTH; flash_l.visible = false
	flash_l.add_theme_constant_override("outline_size", 12); flash_l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	root.add_child(flash_l)
	toast_l = _lbl("", 21, GOLD); toast_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_l.anchor_left = 0; toast_l.anchor_right = 1; toast_l.anchor_top = 1; toast_l.anchor_bottom = 1; toast_l.offset_top = -118; toast_l.offset_bottom = -88
	toast_l.add_theme_constant_override("outline_size", 8); toast_l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85)); toast_l.visible = false
	root.add_child(toast_l)
	ticker = _lbl("", 15, DIM); ticker.anchor_top = 1; ticker.anchor_bottom = 1; ticker.offset_top = -30; ticker.offset_left = 14; ticker.offset_right = 900
	ticker.add_theme_constant_override("outline_size", 6); ticker.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8)); ticker.visible = false
	root.add_child(ticker)
	radio_p = _panel(Color(0.05, 0.08, 0.12, 0.92)); radio_p.anchor_left = 1; radio_p.anchor_right = 1; radio_p.offset_left = -400; radio_p.offset_right = -14; radio_p.offset_top = 56
	var rv := VBoxContainer.new(); radio_p.add_child(rv)
	radio_who = _lbl("", 14, Color("8fc3ff")); rv.add_child(radio_who)
	radio_txt = _lbl("", 17, INK); radio_txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; radio_txt.custom_minimum_size = Vector2(360, 0); rv.add_child(radio_txt)
	radio_p.visible = false; root.add_child(radio_p)
	say_p = _panel(Color(0, 0, 0, 0.72)); say_p.anchor_left = 0.5; say_p.anchor_right = 0.5; say_p.anchor_top = 1; say_p.anchor_bottom = 1
	say_p.offset_left = -360; say_p.offset_right = 360; say_p.offset_top = -190; say_p.offset_bottom = -130
	say_l = _lbl("", 22, INK); say_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; say_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; say_p.add_child(say_l)
	say_p.visible = false; root.add_child(say_p)
	# moldura do monitor do VAR
	var_frame = Panel.new(); var_frame.set_anchors_preset(Control.PRESET_FULL_RECT); var_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vs := StyleBoxFlat.new(); vs.draw_center = false; vs.border_color = Color("2a7dff"); vs.set_border_width_all(6)
	var_frame.add_theme_stylebox_override("panel", vs); var_frame.visible = false; root.add_child(var_frame)
	# barra de decisão
	dec = _panel(Color(0, 0, 0, 0.55)); dec.anchor_left = 0; dec.anchor_right = 1; dec.anchor_top = 1; dec.anchor_bottom = 1; dec.offset_top = -86; dec.offset_bottom = 0
	var dv := VBoxContainer.new(); dec.add_child(dv)
	dec_lbl = _lbl("", 15, GOLD); dec_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; dv.add_child(dec_lbl)
	dec_row = HBoxContainer.new(); dec_row.alignment = BoxContainer.ALIGNMENT_CENTER; dec_row.add_theme_constant_override("separation", 8); dv.add_child(dec_row)
	dec.visible = false; root.add_child(dec)
	# painéis centrais
	ask = _center_panel(560); ask_v = ask.get_meta("v")
	half = _center_panel(860, true); half_v = half.get_meta("v")
	report = _center_panel(980, true); report_v = report.get_meta("v")
	menu = _center_panel(560); menu_v = menu.get_meta("v")
	career = _center_panel(980, true); career_v = career.get_meta("v")
	# tutorial
	tut_p = _panel(Color(0.1, 0.12, 0.2, 0.94)); tut_p.anchor_left = 0.5; tut_p.anchor_right = 0.5; tut_p.offset_left = -330; tut_p.offset_right = 330; tut_p.offset_top = 58
	var tv := VBoxContainer.new(); tut_p.add_child(tv)
	tut_s = _lbl("", 13, DIM); tv.add_child(tut_s)
	tut_l = _lbl("", 18, INK); tut_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; tut_l.custom_minimum_size = Vector2(620, 0); tv.add_child(tut_l)
	tut_b = Button.new(); tut_b.pressed.connect(func(): main.on_ui("tut_click", null)); tv.add_child(tut_b)
	tut_p.visible = false; root.add_child(tut_p)
	# ficha do jogador
	card_p = _panel(Color(0.06, 0.08, 0.07, 0.95)); card_p.anchor_left = 1; card_p.anchor_right = 1; card_p.anchor_top = 1; card_p.anchor_bottom = 1
	card_p.offset_left = -330; card_p.offset_right = -14; card_p.offset_top = -330; card_p.offset_bottom = -100
	card_v = VBoxContainer.new(); card_p.add_child(card_v); card_p.visible = false; root.add_child(card_p)
	card_p.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed: card_p.visible = false)

func _process(dt: float) -> void:
	if toast_t > 0:
		toast_t -= dt
		if toast_t <= 0: toast_l.visible = false
	if radio_t > 0:
		radio_t -= dt
		if radio_t <= 0: radio_p.visible = false
	if ticker_t > 0:
		ticker_t -= dt
		ticker.modulate.a = clamp(ticker_t / 1.5, 0.35, 1.0)
	if flash_t > 0:
		flash_t -= dt
		flash_l.scale = Vector2.ONE * (1.0 + maxf(0, flash_t - 0.4) * 0.3)
		if flash_t <= 0: flash_l.visible = false
	if card_t > 0:
		card_t -= dt
		if card_t <= 0: card_p.visible = false

# ---------- construtores ----------
func _lbl(t: String, fs := 17, c := INK) -> Label:
	var l := Label.new(); l.text = t
	l.add_theme_font_size_override("font_size", fs); l.add_theme_color_override("font_color", c)
	return l
func _wrap(t: String, fs := 17, c := INK, w := 0.0) -> Label:
	var l := _lbl(t, fs, c); l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if w > 0: l.custom_minimum_size = Vector2(w, 0)
	return l
func _panel(c: Color) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new(); sb.bg_color = c; sb.set_corner_radius_all(12); sb.set_content_margin_all(14)
	p.add_theme_stylebox_override("panel", sb)
	return p
func _center_panel(w: float, scroll := false) -> PanelContainer:
	var p := _panel(BG)
	p.anchor_left = 0.5; p.anchor_right = 0.5; p.anchor_top = 0.5; p.anchor_bottom = 0.5
	p.offset_left = -w / 2; p.offset_right = w / 2
	p.grow_vertical = Control.GROW_DIRECTION_BOTH
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 10)
	if scroll:
		p.anchor_top = 0; p.anchor_bottom = 1; p.offset_top = 14; p.offset_bottom = -14
		var sc := ScrollContainer.new(); sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sc.add_child(v); p.add_child(sc)
	else:
		p.add_child(v)
	p.set_meta("v", v)
	p.visible = false
	root.add_child(p)
	return p
func _btn(t: String, cb: Callable, col := Color(), minw := 0.0, fs := 18) -> Button:
	var b := Button.new(); b.text = t
	b.add_theme_font_size_override("font_size", fs)
	if minw > 0: b.custom_minimum_size = Vector2(minw, 44)
	if col != Color():
		var st := StyleBoxFlat.new(); st.bg_color = col; st.set_corner_radius_all(9); st.set_content_margin_all(10)
		b.add_theme_stylebox_override("normal", st)
		var sh := st.duplicate(); sh.bg_color = col.lightened(0.18); b.add_theme_stylebox_override("hover", sh); b.add_theme_stylebox_override("pressed", sh)
	b.pressed.connect(cb)
	return b
func _clear(c: Node) -> void:
	for ch in c.get_children():
		c.remove_child(ch); ch.queue_free()
func _sep(v: Control) -> void:
	var s := HSeparator.new(); s.add_theme_constant_override("separation", 6); v.add_child(s)
func _h(t: String, fs := 20, c := GOLD) -> Label: return _lbl(t, fs, c)
func _table(rows: Array, cols: int, widths: Array, cls_col := -1, ver: bool = false) -> GridContainer:
	var g := GridContainer.new(); g.columns = cols + (1 if ver else 0)
	g.add_theme_constant_override("h_separation", 12); g.add_theme_constant_override("v_separation", 4)
	for r in rows:
		var cells: Array = r.cells
		for i in cols:
			var l := _wrap(str(cells[i]) if i < cells.size() else "", 15, INK, widths[i] if i < widths.size() else 0.0)
			if i == cls_col and r.has("cls"): l.add_theme_color_override("font_color", {"ok": OK, "half": HALF, "bad": BAD}.get(r.cls, INK))
			g.add_child(l)
		if ver:
			var L: Dictionary = r.L
			g.add_child(_btn("Ver lance", func(): main.on_ui("ver_lance", L), Color(0.14, 0.2, 0.3), 0, 14))
	return g

func hide_all() -> void:
	for p in [menu, career, ask, half, report, dec]: p.visible = false
	say_p.visible = false; var_frame.visible = false; tut_p.visible = false; card_p.visible = false

# ---------- avisos ----------
func toast(t: String, secs := 2.0) -> void:
	toast_l.text = t; toast_l.visible = true; toast_t = secs
func radio(w: String, t: String) -> void:
	radio_who.text = w; radio_txt.text = t; radio_p.visible = true; radio_t = 4.2
func feed(f: Dictionary) -> void:
	ticker.text = str(f.min) + "  " + str(f.txt); ticker.visible = true; ticker_t = 6.0
	ticker.add_theme_color_override("font_color", {"goal": GOLD, "card": Color("ffd84a"), "pen": Color("ff9a6b"), "var": Color("8fc3ff"), "protest": Color("ffb0a0")}.get(f.kind, INK))
func flash(t: String) -> void:
	flash_l.text = t; flash_l.visible = true; flash_t = 0.7; flash_l.pivot_offset = flash_l.size / 2
func info(top: String, sub := "") -> void:
	top_l.text = top; sub_l.text = sub
func ref_say(t: String) -> void:
	say_l.text = t; say_p.visible = t != ""

# ---------- decisão ----------
func show_dec(choices: Array, extra: String) -> void:
	_clear(dec_row)
	var i := 0
	for c in choices:
		i += 1
		var d: String = c
		dec_row.add_child(_btn("%d  %s" % [i, Partida.DEC_LABEL[d]], func(): main.on_ui("decide", d), DEC_COL.get(d, Color(0.25, 0.3, 0.35)), 130, 18))
	dec_row.add_child(_btn("R  Rever", func(): main.on_ui("replay", null), Color(0.2, 0.24, 0.3), 0, 16))
	dec_row.add_child(_btn("C  Câmara", func(): main.on_ui("camera", null), Color(0.2, 0.24, 0.3), 0, 16))
	if main.modo != "lance" and main.lance != 9:
		dec_row.add_child(_btn("T  Repetição TV", func(): main.on_ui("tv", null), Color("12305e"), 0, 16))
	dec_lbl.text = extra
	dec.visible = true
func dec_text(t: String) -> void: dec_lbl.text = t

# ---------- perguntas (vantagem, livre, antijogo, banco) e protestos ----------
func show_ask(msg: String, tag: String, opts: Array) -> void:
	_clear(ask_v)
	ask_v.add_child(_lbl(tag.to_upper(), 14, GOLD))
	ask_v.add_child(_wrap(msg, 19, INK, 520))
	var i := 0
	for o in opts:
		var k := i
		var b := _btn("%d  %s" % [i + 1, o.label] + ("  ·  " + o.small if o.has("small") else ""), func(): main.on_ui("ask", k), DEC_COL.get(o.get("sw", ""), Color()), 0, 17)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		ask_v.add_child(b); i += 1
	ask.visible = true
func show_protest(txt: String) -> void:
	_clear(ask_v)
	ask_v.add_child(_lbl("PROTESTO", 14, BAD))
	ask_v.add_child(_wrap(txt, 19, INK, 520))
	var opts := [["ignorar", "Ignorar", "seguir em frente"], ["afastar", "Afastar", "mandar recuar com firmeza"], ["capitao", "Capitão", "pedir ao capitão que os acalme"], ["amarelo", "Amarelo", "a quem protesta mais"]]
	var i := 0
	for o in opts:
		i += 1
		var k: String = o[0]
		var b := _btn("%d  %s  ·  %s" % [i, o[1], o[2]], func(): main.on_ui("protest", k), DEC_COL["amarelo"] if k == "amarelo" else Color(), 0, 17)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		ask_v.add_child(b)
	ask.visible = true
func hide_ask() -> void: ask.visible = false

# ---------- intervalo ----------
func show_half(d: Dictionary) -> void:
	_clear(half_v)
	half_v.add_child(_h(d.title, 26))
	half_v.add_child(_wrap(d.txt, 17, INK, 800))
	if d.rows.size(): half_v.add_child(_table(d.rows, 4, [70, 300, 140, 240], 3, true))
	_sep(half_v)
	half_v.add_child(_lbl("Antes de recomeçar:", 17, GOLD))
	var hb := HBoxContainer.new(); hb.add_theme_constant_override("separation", 8); half_v.add_child(hb)
	talk_btns.clear()
	for o in [["capitaes", "Falar com os capitães"], ["assist", "Acertar com os assistentes"], ["descanso", "Descansar no balneário"]]:
		var k: String = o[0]
		var b := _btn(o[1], func(): _talk(k), Color(), 0, 16)
		b.toggle_mode = true
		talk_btns[k] = b; hb.add_child(b)
	_talk("descanso")
	half_v.add_child(_btn("Começar a 2.ª parte", func(): main.on_ui("second_half", talk), Color("2f8a4a"), 0, 20))
	half.visible = true
func _talk(k: String) -> void:
	talk = k
	for kk in talk_btns: talk_btns[kk].button_pressed = kk == k

# ---------- relatório ----------
func show_report(S: Partida, d: Dictionary, career_note: String, is_career: bool) -> void:
	_clear(report_v)
	report_v.add_child(_h(d.title, 26))
	var hb := HBoxContainer.new(); hb.add_theme_constant_override("separation", 18); report_v.add_child(hb)
	var g := _lbl(("%.1f" % d.grade).replace(".", ","), 64, GOLD); hb.add_child(g)
	hb.add_child(_wrap(d.txt, 18, INK, 760))
	if career_note != "":
		var cn := _panel(Color(0.12, 0.16, 0.24, 0.9)); cn.add_child(_wrap(career_note, 17, INK, 880)); report_v.add_child(cn)
	if not S.paper.is_empty():
		var pp := _panel(Color(0.93, 0.91, 0.84)); var pv := VBoxContainer.new(); pp.add_child(pv)
		pv.add_child(_lbl(S.paper.paper + "   · %d em 5" % int(S.paper.stars), 15, Color(0.3, 0.25, 0.2)))
		pv.add_child(_wrap(S.paper.head, 24, Color(0.08, 0.08, 0.08), 880))
		pv.add_child(_wrap(S.paper.body, 15, Color(0.2, 0.2, 0.2), 880))
		if S.paper.quote != "": pv.add_child(_wrap(S.paper.quote, 15, Color(0.25, 0.2, 0.15), 880))
		report_v.add_child(pp)
	var rows := S.report_rows()
	var maus: Array = rows.filter(func(r): return r.cls != "ok").map(func(r): return r.L)
	if maus.size():
		var ob := _btn("Ver o vídeo do observador (%d %s)" % [maus.size(), "lance" if maus.size() == 1 else "lances"], func(): main.on_ui("obs_video", maus), Color("8a3a2f"), 0, 18)
		report_v.add_child(ob)
	var soc: Dictionary = main.social
	if not soc.is_empty():
		_sep(report_v)
		report_v.add_child(_lbl("Nas redes sociais · em alta: " + str(soc.trend), 18, GOLD))
		for p in soc.posts:
			var pc := _panel(Color(0.1, 0.12, 0.17, 0.95)); var pv2 := VBoxContainer.new(); pc.add_child(pv2)
			var top := HBoxContainer.new(); top.add_theme_constant_override("separation", 8); pv2.add_child(top)
			top.add_child(_lbl(p.who, 15, INK)); top.add_child(_lbl(p.at, 13, DIM))
			pv2.add_child(_wrap(p.txt, 15, {-1: Color("ffb0a0"), 1: Color("a8e6b0")}.get(int(p.tom), INK), 880))
			pv2.add_child(_lbl("Gosto  " + str(p.lk), 12, DIM))
			report_v.add_child(pc)
	if not main.entrevista.is_empty():
		var iv := _panel(Color(0.16, 0.13, 0.08, 0.95)); var ivv := VBoxContainer.new(); iv.add_child(ivv); report_v.add_child(iv)
		ivv.add_child(_lbl("Zona de entrevistas", 16, GOLD))
		ivv.add_child(_wrap("Jornalista: «" + str(main.entrevista.q) + "»", 16, INK, 880))
		entrevista_box = ivv
		for i in main.entrevista.opts.size():
			var o: Dictionary = main.entrevista.opts[i]
			var k: int = i
			ivv.add_child(_btn(o.t, func(): main.on_ui("entrevista", k), Color(0.22, 0.2, 0.16), 0, 15))
	_sep(report_v)
	report_v.add_child(_lbl("Lances", 18, GOLD))
	if rows.is_empty(): report_v.add_child(_lbl("Nenhum lance para avaliar.", 16, DIM))
	else:
		report_v.add_child(_table([{"cells": ["Min.", "O que foi", "Decidiste", "Como viste", "Observador"]}], 5, [80, 250, 140, 200, 220]))
		report_v.add_child(_table(rows, 5, [80, 250, 140, 200, 220], 4, true))
	if S.manage.size():
		report_v.add_child(_lbl("Gestão do jogo", 18, GOLD))
		var mr: Array = []
		for m in S.manage: mr.append({"cells": ["%d'" % m.minute, m.what, m.dec, m.why], "cls": "ok" if m.pts == 1 else ("half" if m.pts > 0 else "bad")})
		report_v.add_child(_table(mr, 4, [80, 330, 160, 330], 3))
	var key: Array = S.feed_list.filter(func(f): return f.kind != "info")
	report_v.add_child(_lbl("Momentos do jogo", 18, GOLD))
	if key.is_empty(): report_v.add_child(_lbl("Jogo sem golos, cartões nem VAR.", 16, DIM))
	for f in key: report_v.add_child(_wrap(str(f.min) + "  " + str(f.txt), 15, INK, 900))
	_sep(report_v)
	var bb := HBoxContainer.new(); bb.add_theme_constant_override("separation", 10); report_v.add_child(bb)
	if is_career: bb.add_child(_btn("Continuar carreira", func(): main.on_ui("career", null), Color("2f8a4a")))
	else: bb.add_child(_btn("Jogar outra vez", func(): main.on_ui("again", null), Color("2f8a4a")))
	bb.add_child(_btn("Menu", func(): main.on_ui("menu", null)))
	report.visible = true

# ---------- menu ----------
func show_menu(has_career: bool, best: String, voz: bool, som: bool, publico := true) -> void:
	hide_all()
	_clear(menu_v)
	menu_v.add_child(_lbl("ÁRBITRO DE CARICAS", 34, GOLD))
	menu_v.add_child(_wrap("És o árbitro. Acompanha o jogo de caricas de perto: os lances aparecem em 3D, vistos de onde estás, e tens poucos segundos para decidir.", 16, DIM, 500))
	for it in [["Jogar partida", "partida", Color("2f8a4a")], ["Continuar carreira" if has_career else "Carreira", "carreira", Color("3a5fa8")], ["Treinar o VAR", "treino_var", Color()],
			["Primeiro jogo guiado", "tutorial", Color()], ["Treino de lances 3D", "treino3d", Color()]]:
		var k: String = it[1]
		menu_v.add_child(_btn(it[0], func(): main.on_ui(k, null), it[2], 500, 20))
	var hb := HBoxContainer.new(); hb.add_theme_constant_override("separation", 8); menu_v.add_child(hb)
	hb.add_child(_btn("Voz ligada" if voz else "Voz desligada", func(): main.on_ui("voz", null), Color(), 0, 16))
	hb.add_child(_btn("Público ligado" if publico else "Público desligado", func(): main.on_ui("publico", null), Color(), 0, 16))
	hb.add_child(_btn("Todo o som ligado" if som else "Todo o som desligado", func(): main.on_ui("som", null), Color(), 0, 16))
	if best != "": menu_v.add_child(_lbl("Melhor nota: " + best, 15, DIM))
	menu_v.add_child(_wrap("Teclas: WASD/setas mover · Shift correr · 1–6 decidir · R rever · C câmara · Espaço pausa · Esc menu", 13, DIM, 500))
	menu_v.add_child(_lbl("Versão " + VERSAO.TXT, 13, DIM))
	menu.visible = true

# ---------- carreira ----------
func show_career(car: Carreira) -> void:
	hide_all()
	_clear(career_v)
	reset_armed = false
	var C: Dictionary = car.C
	var T: Dictionary = car.tier()
	var B := car.match_brief()
	career_v.add_child(_h("Época %d · %s" % [C.season, T.name], 28))
	if str(C.get("news", "")) != "": career_v.add_child(_wrap(C.news, 16, DIM, 920))
	var pb := _panel(Color(0.08, 0.2, 0.12, 0.95)); var pv := VBoxContainer.new(); pb.add_child(pv); career_v.add_child(pb)
	pv.add_child(_lbl(B.comp, 15, GOLD))
	pv.add_child(_lbl(B.h[0] + " – " + B.a[0], 26, INK))
	var lines: Array = B.lines if B.lines.size() else ["Jogo sem história especial. O observador pede %s de média." % Carreira.f1(T.target)]
	for l in lines: pv.add_child(_wrap("• " + l, 15, INK, 900))
	var bb := HBoxContainer.new(); bb.add_theme_constant_override("separation", 10); pv.add_child(bb)
	bb.add_child(_btn("Apitar o jogo", func(): main.on_ui("career_play", null), Color("2f8a4a"), 220, 20))
	bb.add_child(_btn("Menu", func(): main.on_ui("menu", null)))
	# escada
	var ld := HBoxContainer.new(); ld.add_theme_constant_override("separation", 6); career_v.add_child(ld)
	for i in Carreira.TIERS.size():
		var l := _lbl(Carreira.TIERS[i].name + ("  ›" if i < Carreira.TIERS.size() - 1 else ""), 15, GOLD if i == C.tier else (OK if i < C.tier else DIM))
		ld.add_child(l)
	# jornadas
	career_v.add_child(_lbl("Jogos da época", 18, GOLD))
	var fr: Array = []
	for i in C.fixtures.size():
		var f: Dictionary = C.fixtures[i]
		var played: bool = i < C.round
		var g: float = float(C.sg[i]) if played and i < C.sg.size() else 0.0
		var res := ""
		for lg in C.log:
			if int(lg.s) == int(C.season) and int(lg.t) == int(C.tier) and int(lg.r) == i: res = "  %d–%d" % [int(lg.sc[0]), int(lg.sc[1])]
		var nm: String = T.clubs[f.h][0] + " – " + T.clubs[f.a][0] + res + ((" · clássico" if str(T.derby).begins_with("Clássico") else " · dérbi") if f.story == "derby" else "")
		fr.append({"cells": [Carreira.CUP_ROUNDS[i] if T.get("cup", false) else str(i + 1), nm, Carreira.f1(g) if played else ("Próximo" if i == C.round else "")],
			"cls": ("ok" if g >= T.target else ("half" if g >= T.target - 1.5 else "bad")) if played else ""})
	career_v.add_child(_table(fr, 3, [140, 520, 120], 2))
	var lt := car.league_table()
	if lt.size():
		career_v.add_child(_lbl("Classificação · " + T.name, 18, GOLD))
		var lr: Array = [{"cells": ["", "Clube", "Força", "J", "V", "E", "D", "Golos", "Pts", "Forma"]}]
		for i in lt.size():
			var r: Dictionary = lt[i]
			var joga: bool = r.i == int(B.f.h) or r.i == int(B.f.a)
			lr.append({"cells": [str(i + 1), r.n, str(r.f), str(r.j), str(r.v), str(r.e), str(r.d), "%d-%d" % [r.gm, r.gs], str(r.pts), " ".join(car.forma(r.i))], "cls": "ok" if joga else ""})
		career_v.add_child(_table(lr, 10, [30, 250, 55, 35, 35, 35, 35, 70, 45, 120], 1))
		career_v.add_child(_lbl("A verde: as equipas do teu próximo jogo. Força = qualidade do plantel.", 13, DIM))
	if not T.get("cup", false):
		career_v.add_child(_lbl("Classificação dos árbitros", 18, GOLD))
		var rr: Array = []
		var tb := car.ref_table()
		for i in tb.size():
			var r: Dictionary = tb[i]
			rr.append({"cells": [str(i + 1), r.n, str(r.j), Carreira.f1(r.a) if r.j else "–"], "cls": "ok" if r.me else ""})
		career_v.add_child(_table(rr, 4, [40, 260, 60, 80], 1))
	# atributos
	career_v.add_child(_lbl("Atributos · " + ("%d %s para gastar" % [C.pts, "pontos" if C.pts > 1 else "ponto"] if C.pts else "sem pontos: ganhas um por jogo, mais com notas de 8 e 9"), 18, GOLD))
	for a in Carreira.ATTRS:
		var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 10); career_v.add_child(row)
		var tx := VBoxContainer.new(); tx.custom_minimum_size = Vector2(420, 0); row.add_child(tx)
		tx.add_child(_lbl(a.name, 17, INK)); tx.add_child(_lbl(a.txt, 13, DIM))
		var v: int = C.attrs[a.k]
		# barra desenhada (a letra da versão web não tem ● nem ○)
		var bar := HBoxContainer.new(); bar.add_theme_constant_override("separation", 3); bar.alignment = BoxContainer.ALIGNMENT_CENTER
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		for i in 10:
			var seg := ColorRect.new(); seg.custom_minimum_size = Vector2(14, 14)
			seg.color = GOLD if i < v else Color(1, 1, 1, 0.12)
			bar.add_child(seg)
		row.add_child(bar)
		row.add_child(_lbl("%d/10" % v, 16, GOLD))
		var k: String = a.k
		var b := _btn("+1", func(): main.on_ui("attr", k), Color(), 0, 16); b.disabled = C.pts <= 0 or v >= 10; row.add_child(b)
	var img: int = int(C.get("imagem", 50))
	var ir := HBoxContainer.new(); ir.add_theme_constant_override("separation", 10); career_v.add_child(ir)
	ir.add_child(_lbl("Imagem pública", 18, GOLD))
	var ib := HBoxContainer.new(); ib.add_theme_constant_override("separation", 3); ib.size_flags_vertical = Control.SIZE_SHRINK_CENTER; ir.add_child(ib)
	for i in 10:
		var seg := ColorRect.new(); seg.custom_minimum_size = Vector2(14, 14)
		seg.color = (OK if img >= 60 else (GOLD if img >= 40 else BAD)) if i < int(round(img / 10.0)) else Color(1, 1, 1, 0.12)
		ib.add_child(seg)
	ir.add_child(_lbl("%d/100 · %s" % [img, "o público confia em ti" if img >= 60 else ("estádios mais hostis e capitães desconfiados" if img < 40 else "neutra")], 14, DIM))
	if str(C.get("trend", "")) != "": career_v.add_child(_lbl("Último jogo nas redes: " + str(C.trend), 14, DIM))
	if C.papers.size():
		career_v.add_child(_lbl("Jornais", 18, GOLD))
		for p in C.papers.slice(0, 5):
			career_v.add_child(_wrap(p.h, 16, INK, 900))
			career_v.add_child(_lbl(p.p + " · " + "%d em 5" % int(p.st) + " · " + Carreira.TIERS[int(p.t)].name, 13, DIM))
	var dr := car.discipline_rows()
	if dr.size():
		career_v.add_child(_lbl("Disciplina", 18, GOLD))
		for r in dr: career_v.add_child(_wrap(r.title + "  ·  " + r.sub, 14, INK, 900))
	if C.finals: career_v.add_child(_lbl("Finais do Mundial apitadas: %d" % C.finals, 16, GOLD))
	var rb := _btn("Apagar carreira", func(): _reset_career(), Color(0.35, 0.12, 0.12), 0, 14)
	rb.set_meta("rb", true)
	career_v.add_child(rb)
	career.visible = true
# depois de responder ao jornalista: tira os botões e mostra a reação
func entrevista_feita(o: Dictionary, img_txt: String) -> void:
	if entrevista_box == null: return
	for c in entrevista_box.get_children():
		if c is Button: c.queue_free()
	entrevista_box.add_child(_wrap("Respondeste: «" + str(o.t) + "»", 15, INK, 880))
	entrevista_box.add_child(_wrap(str(o.r) + img_txt, 15, GOLD, 880))
	entrevista_box = null

func _reset_career() -> void:
	if not reset_armed:
		reset_armed = true; toast("Carrega outra vez para apagar a carreira e começar nos distritais", 3); return
	main.on_ui("career_reset", null)

# ---------- tutorial ----------
func show_tut(d: Dictionary) -> void:
	tut_l.text = d.txt; tut_s.text = "Primeiro jogo guiado · " + d.step
	tut_b.text = d.btn; tut_b.visible = d.btn != ""
	tut_p.visible = true

# ---------- ficha do jogador ----------
func show_card(S: Partida, p, extra: String) -> void:
	_clear(card_v)
	var tm: Dictionary = S.teams[p.team]
	var hb := HBoxContainer.new(); card_v.add_child(hb)
	var n := _panel(tm.color); n.custom_minimum_size = Vector2(48, 48); var nl := _lbl(str(p.num), 22, tm.get("text", Color.WHITE)); nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; n.add_child(nl); hb.add_child(n)
	var nv := VBoxContainer.new(); hb.add_child(nv)
	nv.add_child(_lbl(p.name if p.name != "" else "Jogador %d" % p.num, 19, INK))
	nv.add_child(_lbl(str(tm.name) + " · " + str(Partida.ROLE_PT.get(p.role, "")) + " · %d" % int(p.ovr), 14, DIM))
	for it in [["Velocidade", p.pac], ["Passe", p.pas], ["Remate", p.fin], ["Desarme", p.tck], ["Drible", p.drb], ["Decisão", p.dec]]:
		var row := HBoxContainer.new(); card_v.add_child(row)
		var l := _lbl(it[0], 14, DIM); l.custom_minimum_size = Vector2(90, 0); row.add_child(l)
		var pbar := ProgressBar.new(); pbar.max_value = 100; pbar.value = it[1]; pbar.show_percentage = false; pbar.custom_minimum_size = Vector2(150, 12)
		pbar.size_flags_vertical = Control.SIZE_SHRINK_CENTER; row.add_child(pbar)
		row.add_child(_lbl(str(int(it[1])), 14, INK))
	var tags: Array = []
	for x in p.tr: tags.append("estrela" if x == "estrela" else ("entra duro" if x == "duro" else "atira-se"))
	if p.reserve: tags.append("suplente: " + p.banned + " está castigado")
	if p.grudge: tags.append("lembra-se da expulsão")
	if p.yellow: tags.append("%d amarelo%s hoje" % [p.yellow, "s" if p.yellow > 1 else ""])
	if p.fouls: tags.append("%d falta%s hoje" % [p.fouls, "s" if p.fouls > 1 else ""])
	if extra != "": tags.append(extra)
	if tags.size(): card_v.add_child(_wrap(" · ".join(tags), 14, GOLD, 290))
	card_p.visible = true; card_t = 5.0
