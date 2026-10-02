class_name Carreira
extends RefCounted
# Carreira do árbitro (port de p4/p10/p11/p13/p15): escalões dos distritais ao Mundial, épocas com jornadas,
# dérbis e histórias, clubes com plantéis (à Football Manager), atributos, classificação dos árbitros,
# jornais, castigos e rancores dos jogadores, critério de jogo para jogo. Guardada em user://carreira.json.

const PATH := "user://carreira.json"
const KITS := {
	"azul": {"color": "3569dc", "dark": "1d3f8f", "sock": "1d3f8f", "shorts": "f1f1f1"},
	"laranja": {"color": "ee7d2c", "dark": "a4521a", "sock": "ee7d2c", "shorts": "23242a"},
	"vermelho": {"color": "d23a3a", "dark": "8a1f1f", "sock": "d23a3a", "shorts": "f1f1f1"},
	"verde": {"color": "2f9e57", "dark": "1c6636", "sock": "f1f1f1", "shorts": "f1f1f1"},
	"branco": {"color": "eeeeea", "dark": "9a9a96", "sock": "eeeeea", "shorts": "1f2f6b", "text": "1f2f6b"},
	"preto": {"color": "26272c", "dark": "111111", "sock": "26272c", "shorts": "26272c"},
	"celeste": {"color": "6fb7e8", "dark": "3d7fae", "sock": "f1f1f1", "shorts": "f1f1f1", "text": "12304a"},
	"roxo": {"color": "7b4bc4", "dark": "4d2c80", "sock": "7b4bc4", "shorts": "f1f1f1"},
	"grena": {"color": "7a1f2e", "dark": "4a111b", "sock": "7a1f2e", "shorts": "f1f1f1"},
	"amarelo": {"color": "f2cf3a", "dark": "b39320", "sock": "f2cf3a", "shorts": "1f2f6b", "text": "1f2f6b"},
	"marinho": {"color": "1f2f6b", "dark": "101a40", "sock": "1f2f6b", "shorts": "f1f1f1"},
}
# clubes: [nome, equipamento, alternativo, calções ("" = do equipamento), artigo]; o dérbi são os dois primeiros
const TIERS := [
	{"name": "Distrital", "games": 6, "target": 6.5, "var": false, "derby": "Dérbi da vila", "clubs": [["Vila Nova", "verde", "branco", "", "o"], ["Vila Velha", "grena", "branco", "", "o"], ["Unidos da Ribeira", "azul", "branco", "", "os"], ["Recreativo das Pedras", "amarelo", "preto", "", "o"], ["Atlético da Serra", "vermelho", "branco", "", "o"], ["Académico do Moinho", "preto", "branco", "", "o"]]},
	{"name": "Liga 3", "games": 6, "target": 7.0, "var": false, "derby": "Dérbi do rio", "clubs": [["Oriental da Foz", "verde", "branco", "", "o"], ["Marítimo da Barra", "laranja", "branco", "", "o"], ["Estrela do Norte", "vermelho", "branco", "", "a"], ["Desportivo de Alvor", "celeste", "marinho", "", "o"], ["União de Belmar", "azul", "branco", "", "a"], ["Operário de Vale Fundo", "preto", "branco", "", "o"]]},
	{"name": "Liga 2", "games": 7, "target": 7.4, "var": true, "derby": "Dérbi da serra", "clubs": [["Penafria FC", "vermelho", "branco", "", "o"], ["Clube de Montalto", "azul", "branco", "", "o"], ["Lusitano de Arcos", "verde", "branco", "", "o"], ["Naval da Enseada", "marinho", "branco", "", "o"], ["Imortal de Ferreiros", "roxo", "branco", "", "o"], ["Juventude de Sertã", "amarelo", "marinho", "", "a"]]},
	{"name": "Primeira Liga", "games": 7, "target": 7.8, "var": true, "derby": "Clássico", "clubs": [["Real Lusitano", "vermelho", "branco", "", "o"], ["Clube Oceano", "azul", "branco", "", "o"], ["Leões da Estrela", "verde", "branco", "", "os"], ["Atlético Capital", "grena", "branco", "", "o"], ["Vitória do Sul", "preto", "branco", "", "o"], ["Desportivo Atlântico", "celeste", "marinho", "", "o"]]},
	{"name": "Taça Europeia", "games": 6, "target": 8.1, "var": true, "derby": "Dérbi de Velgrad", "clubs": [["Dinamo Velgrad", "azul", "branco", "", "o"], ["Lokomotiv Velgrad", "vermelho", "branco", "", "o"], ["Olympique Mireval", "celeste", "marinho", "", "o"], ["Athletic Norbridge", "grena", "branco", "", "o"], ["Real Castellar", "branco", "roxo", "", "o"], ["FC Lindenau", "amarelo", "preto", "", "o"]]},
	{"name": "Mundial", "games": 4, "target": 7.6, "var": true, "cup": true, "derby": "Clássico sul-americano", "clubs": [["Brasil", "amarelo", "azul", "", "o"], ["Argentina", "celeste", "marinho", "", "a"], ["França", "marinho", "branco", "", "a"], ["Espanha", "vermelho", "branco", "1f2f6b", "a"], ["Alemanha", "branco", "preto", "26272c", "a"], ["Inglaterra", "branco", "vermelho", "", "a"], ["Países Baixos", "laranja", "marinho", "", "os"], ["Itália", "azul", "branco", "", "a"]]},
]
const CUP_ROUNDS := ["Oitavos de final", "Quartos de final", "Meias-finais", "Final"]
const ATTRS := [
	{"k": "fis", "name": "Físico", "txt": "Corres mais depressa e cansas-te menos."},
	{"k": "leit", "name": "Leitura de jogo", "txt": "Antecipas o lance e vês de mais perto."},
	{"k": "aut", "name": "Autoridade", "txt": "Protestos mais brandos; os erros custam menos controlo."},
	{"k": "calma", "name": "Calma", "txt": "Menos nervos e mais tempo para decidir quando o público aperta."},
]
const STORIES := {
	"subida": {"txt": "Os dois precisam de ganhar para chegar aos lugares de cima.", "aggr": [0.08, 0.08], "crowd": 8},
	"expulsoes": {"txt": "O último jogo entre eles acabou com duas expulsões.", "aggr": [0.15, 0.15], "crowd": 5},
	"crise": {"txt": "A equipa da casa não ganha há seis jogos e o público está impaciente.", "aggr": [0.04, 0.0], "crowd": 18},
	"calmo": {"txt": "Jogo a meio da tabela, sem muito em jogo.", "aggr": [-0.03, -0.03], "crowd": -6},
}
const REF_NAMES := ["Rui Matos", "Carla Pinto", "Nuno Teixeira", "Sofia Ramos", "Hélder Costa", "Marta Faria", "Tiago Lobo", "Inês Barros", "Paulo Seabra", "Joana Prata", "Vasco Nunes", "Ana Lemos", "Bruno Sá", "Filipa Rocha", "Duarte Leal", "Rita Calado"]
const COACH_F := ["Abel", "Jorge", "Carlos", "Vítor", "Leonel", "Manuel", "Sérgio", "Fernando", "Artur", "Rogério", "Beatriz", "Luísa"]
const COACH_L := ["Fontes", "Mourão", "Guerreiro", "Pacheco", "Valente", "Carvalhal", "Bento", "Simões", "Quaresma", "Lacerda", "Rebelo", "Peixoto"]
const PAPERS := ["Gazeta da Carica", "O Apito", "Diário do Relvado", "A Bancada"]
const FIRST := ["Rui", "Tiago", "João", "André", "Diogo", "Bruno", "Pedro", "Hugo", "Nuno", "Ricardo", "Miguel", "Fábio", "Gonçalo", "Rafael", "Vítor", "Luís", "Daniel", "Filipe", "Marco", "Sérgio", "Ivo", "Paulo", "Joel", "Renato"]
const LAST := ["Tavares", "Moreira", "Lopes", "Pires", "Sousa", "Antunes", "Carvalho", "Neves", "Fonseca", "Mendes", "Correia", "Teixeira", "Barros", "Coelho", "Monteiro", "Vaz", "Rocha", "Matias", "Gomes", "Faria", "Brito", "Cunha", "Lemos", "Seixas", "Dias", "Marques", "Patrício", "Aguiar", "Quintela", "Sobral"]
const NUMS := [1, 3, 4, 5, 2, 8, 6, 10, 11, 9, 7]

# gerador com semente: o mesmo clube tem sempre os mesmos jogadores
class Seeded:
	var s := 1
	func _init(seed: int) -> void:
		s = (seed * 2654435761) % 4294967296
		if s == 0: s = 1
	func next() -> float:
		s = (s * 1664525 + 1013904223) % 4294967296
		return s / 4294967296.0

static func hash_s(t: String) -> int:
	var h := 7
	for i in t.length(): h = (h * 31 + t.unicode_at(i)) % 100003
	return h
static func coach_name(name: String) -> String:
	var h := hash_s(name)
	return COACH_F[h % COACH_F.size()] + " " + COACH_L[(h / 7) % COACH_L.size()]
static func club_index(name: String, tier: int) -> int:
	var cl: Array = TIERS[tier].clubs
	for i in cl.size():
		if cl[i][0] == name: return i
	return -1
# força do clube: sobe com o escalão; os dois do dérbi são os grandes
static func club_rating(name: String, tier: int) -> int:
	var i := club_index(name, tier)
	var r := Seeded.new(hash_s(name) + 11).next()
	return int(round(clamp(52 + tier * 6.5 + (6 if i >= 0 and i < 2 else 0) + (r - 0.5) * 12, 40, 92)))
static func squad_for(name: String, rating: float) -> Array:
	var r := Seeded.new(hash_s(name) + 3)
	var g := func() -> float: return (r.next() + r.next() + r.next() - 1.5) * 1.15
	var star_i := 7 + int(r.next() * 4)
	var sim_i := 5 + int(r.next() * 6)
	var hard_i := 1 + int(r.next() * 6)
	var used := {}
	var out: Array = []
	for i in 11:
		var nm := ""
		while true:
			nm = FIRST[int(r.next() * FIRST.size())] + " " + LAST[int(r.next() * LAST.size())]
			if not used.has(nm): break
		used[nm] = 1
		var ovr := int(round(clamp(rating + g.call() * 6 + (11 if i == star_i else 0), 35, 95)))
		var tr: Array = []
		if i == star_i: tr.append("estrela")
		if i == sim_i and r.next() < 0.75: tr.append("simulador")
		if i == hard_i and r.next() < 0.8: tr.append("duro")
		out.append({"name": nm, "short": nm.split(" ")[1], "ovr": float(ovr), "tr": tr, "num": NUMS[i]})
	return out

static func _hex_dist(a: Color, b: Color) -> float: return Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length() * 255.0
static func kit_of(club: Array, alt: bool) -> Dictionary:
	var k: Dictionary = KITS[club[2] if alt else club[1]]
	var o := {"color": Color(k.color), "dark": Color(k.dark), "sock": Color(k.sock), "shorts": Color(k.shorts), "text": Color(k.get("text", "ffffff"))}
	if not alt and club[3] != "": o.shorts = Color(club[3])
	# padrão da camisola (riscas, aros, faixa, metades, mangas) fixo por clube
	var h := hash_s(club[0])
	var pats := [0, 0, 1, 2, 3, 4, 5, 0]
	o.pat = float(pats[h % pats.size()]) if not alt else 0.0
	o.shirt2 = Color("f1f1f1") if o.color.get_luminance() < 0.6 else o.dark
	return o
static func default_teams() -> Array:
	var r := randf()
	return [
		{"name": "Azuis", "art": "os", "color": Color("3569dc"), "dark": Color("1d3f8f"), "sock": Color("1d3f8f"), "shorts": Color("f1f1f1"), "text": Color.WHITE, "gk": Color("2fa36b"), "pat": 0.0, "shirt2": Color("f1f1f1"), "rating": round(64 + r * 14), "dir": 1},
		{"name": "Laranjas", "art": "os", "color": Color("ee7d2c"), "dark": Color("a4521a"), "sock": Color("ee7d2c"), "shorts": Color("23242a"), "text": Color.WHITE, "gk": Color("8a5bd6"), "pat": 1.0, "shirt2": Color("23242a"), "rating": round(78 - r * 14 + randf_range(-3, 3)), "dir": -1},
	]
# equipas de um jogo da carreira: equipamento alternativo quando as cores chocam
static func teams_for(h: Array, a: Array, tier: int) -> Array:
	var hk := kit_of(h, false)
	var ak := kit_of(a, false)
	if _hex_dist(hk.color, ak.color) < 120: ak = kit_of(a, true)
	if _hex_dist(hk.color, ak.color) < 120: ak = kit_of(["", "preto" if hk.color == Color("eeeeea") else "branco", "", "", ""], false)
	var gks := [Color("2fa36b"), Color("8a5bd6"), Color("d8d8d8"), Color("f08fb6")]
	gks.sort_custom(func(x, y): return minf(_hex_dist(x, hk.color), _hex_dist(x, ak.color)) > minf(_hex_dist(y, hk.color), _hex_dist(y, ak.color)))
	hk.merge({"name": h[0], "art": h[4], "gk": gks[0], "rating": club_rating(h[0], tier), "dir": 1}, true)
	ak.merge({"name": a[0], "art": a[4], "gk": gks[1], "rating": club_rating(a[0], tier), "dir": -1}, true)
	return [hk, ak]
static func c_art(c: Array) -> String: return c[4] + " " + c[0]
static func round_name(T: Dictionary, r: int) -> String: return CUP_ROUNDS[mini(r, 3)] if T.get("cup", false) else "Jornada %d de %d" % [r + 1, T.games]
static func f1(x: float) -> String: return ("%.1f" % x).replace(".", ",")
static func gauss() -> float: return (randf() + randf() + randf() - 1.5) * 1.15
static func sim_grade(sk: float) -> float: return round(clamp(sk + gauss() * 0.75, 3.5, 9.8) * 10) / 10.0

# ---------- dados da carreira ----------
var C: Dictionary = {}
var note := ""            # texto depois do jogo

func exists() -> bool: return FileAccess.file_exists(PATH)
func load_c() -> bool:
	C = {}
	if not exists(): return false
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null: return false
	var d = JSON.parse_string(f.get_as_text())
	if typeof(d) != TYPE_DICTIONARY: return false
	C = d
	# o JSON devolve números como float: voltar a inteiros onde importa
	for k in ["tier", "season", "round", "pts", "finals"]: C[k] = int(C.get(k, 0))
	for k in C.attrs: C.attrs[k] = int(C.attrs[k])
	for f2 in C.fixtures: f2.h = int(f2.h); f2.a = int(f2.a)
	for k in C.get("grudge", {}): C.grudge[k] = int(C.grudge[k])
	for k in C.get("pl", {}):
		for q in ["j", "y", "r", "f", "ban", "grudge"]: C.pl[k][q] = int(C.pl[k][q])
	if not C.has("refs"): C.refs = make_refs(C.tier, C.sg.size())
	if not C.has("papers"): C.papers = []
	if not C.has("pl"): C.pl = {}
	if not C.has("critS"): C.critS = []
	return true
func save_c() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(C))
func new_career() -> void:
	C = {"v": 2, "tier": 0, "season": 1, "round": 0, "sg": [], "log": [], "attrs": {"fis": 3, "leit": 3, "aut": 3, "calma": 3}, "pts": 2, "grudge": {}, "finals": 0,
		"news": "Começas nos distritais. O observador vê todos os teus jogos: com média acima do que pede, sobes de escalão no fim da época.",
		"fixtures": make_fixtures(0), "refs": make_refs(0, 0), "papers": [], "pl": {}, "critS": []}
	save_c()

func make_fixtures(ti: int) -> Array:
	var T: Dictionary = TIERS[ti]
	var n: int = T.clubs.size()
	var out: Array = []
	var cup: bool = T.get("cup", false)
	var dr: int = T.games - 1 if cup else randi() % int(T.games)
	for i in T.games:
		var h := 0
		var a := 1
		if i == dr:
			if randf() < 0.5: h = 1; a = 0
		else:
			while true:
				h = randi() % n; a = randi() % n
				if h != a and h + a != 1: break
		var story = "derby" if i == dr else ("" if cup else [ "", "", "subida", "expulsoes", "crise", "calmo"].pick_random())
		out.append({"h": h, "a": a, "story": story})
	return out
func make_refs(ti: int, played: int) -> Array:
	var T: Dictionary = TIERS[ti]
	var names := REF_NAMES.duplicate()
	names.shuffle()
	var out: Array = []
	for n in names.slice(0, 7):
		var sk: float = T.target + randf_range(-1.1, 0.45)
		var g: Array = []
		for i in played: g.append(sim_grade(sk))
		out.append({"n": n, "sk": sk, "g": g})
	return out
func ref_table() -> Array:
	var avg := func(g: Array) -> float:
		var s := 0.0
		for x in g: s += float(x)
		return s / g.size() if g.size() else 0.0
	var rows: Array = [{"n": "Tu", "me": true, "j": C.sg.size(), "a": avg.call(C.sg)}]
	for r in C.refs: rows.append({"n": r.n, "me": false, "j": r.g.size(), "a": avg.call(r.g)})
	rows.sort_custom(func(p, q): return p.a > q.a or (p.a == q.a and p.me and not q.me))
	return rows
func tier() -> Dictionary: return TIERS[C.tier]
func fixture() -> Dictionary: return C.fixtures[mini(C.round, C.fixtures.size() - 1)]
func clubs_of(f: Dictionary) -> Array: return [tier().clubs[f.h], tier().clubs[f.a]]

# o dossiê antes do jogo: favorito, estrela e quem é preciso vigiar
func brief_squads(h: Array, a: Array, ti: int) -> Array:
	var rh := club_rating(h[0], ti)
	var ra := club_rating(a[0], ti)
	var out: Array = []
	out.append(("Jogo equilibrado" if absi(rh - ra) < 4 else "Favorito: " + (h[0] if rh > ra else a[0])) + " (força %d contra %d)." % [rh, ra])
	for pr in [[h, rh], [a, ra]]:
		var c: Array = pr[0]
		var sq: Array = squad_for(c[0], pr[1]).filter(func(q): return int(C.pl.get(c[0] + "#" + str(q.num), {}).get("ban", 0)) == 0)
		var bits: Array = []
		for q in sq:
			if "estrela" in q.tr: bits.append("a estrela é %s (%d, %d)" % [q.name, q.num, q.ovr])
		for q in sq:
			if "simulador" in q.tr: bits.append("%s (%d) tem fama de se atirar" % [q.short, q.num]); break
		for q in sq:
			if "duro" in q.tr: bits.append("%s (%d) entra duro" % [q.short, q.num]); break
		if bits.size(): out.append(c[0] + ": " + "; ".join(bits) + ".")
	return out
func brief_players(h: Array, a: Array) -> Array:
	var out: Array = []
	for c in [h, a]:
		var ban: Array = []
		var gr: Array = []
		for k in C.pl:
			if not k.begins_with(c[0] + "#"): continue
			var r: Dictionary = C.pl[k]
			var num: String = k.split("#")[1]
			if r.ban > 0: ban.append("%s (%s, %d %s)" % [r.n, num, r.ban, "jogos" if r.ban > 1 else "jogo"])
			elif r.grudge: gr.append("%s (%s)" % [r.n, num])
		if ban.size(): out.append(c[0] + ": castigado" + ("s " if ban.size() > 1 else " ") + ", ".join(ban) + ".")
		if gr.size(): out.append(c[0] + ": " + ", ".join(gr) + (" não esqueceram" if gr.size() > 1 else " não esqueceu") + " a expulsão que lhe mostraste. Vai entrar com tudo.")
	return out
# o que o jogo seguinte traz: dérbi, história da época e o que as equipas se lembram de ti
func match_brief() -> Dictionary:
	var T := tier()
	var f := fixture()
	var cl := clubs_of(f)
	var h: Array = cl[0]
	var a: Array = cl[1]
	var lines: Array = []
	var aggr := [0.0, 0.0]
	var crowd := 0.0
	if f.story == "derby":
		lines.append(T.derby + " entre " + c_art(h) + " e " + c_art(a) + ": estádio cheio e ninguém quer perder.")
		aggr[0] += 0.12; aggr[1] += 0.12; crowd += 15
	elif f.story != "":
		var s: Dictionary = STORIES[f.story]
		lines.append(s.txt); aggr[0] += s.aggr[0]; aggr[1] += s.aggr[1]; crowd += s.crowd
	for i in 2:
		var c: Array = [h, a][i]
		var g: int = C.grudge.get(c[0], 0)
		if g > 0:
			lines.append("Os jogadores d" + c_art(c) + " lembram-se de ti: no último jogo tiveram " + ("%d decisões erradas" % g if g > 1 else "uma decisão errada") + " contra eles.")
			aggr[i] += minf(0.3, 0.1 * g)
			lines.append("O capitão d" + c_art(c) + " vai confiar menos em ti quando falares com ele.")
	lines.append_array(brief_squads(h, a, C.tier))
	lines.append_array(brief_players(h, a))
	if not T.var: lines.append("Não há VAR neste escalão: o que decidires fica decidido.")
	return {"T": T, "f": f, "h": h, "a": a, "lines": lines, "aggr": aggr, "crowd": crowd, "comp": T.name + " · " + round_name(T, C.round)}

# prepara a partida da carreira (depois de Partida.new(teams_for(...)))
func setup_match(S: Partida) -> void:
	var B := match_brief()
	var ti: int = C.tier
	S.career = {"tier": ti, "round": C.round, "attrs": C.attrs.duplicate(), "wrong": [0, 0], "h": B.h[0], "a": B.a[0]}
	career_squad(S)
	S.no_var = not B.T.var
	S.lance_k = 1.1 - 0.05 * ti; S.sim_k = 0.7 + 0.15 * ti
	S.crowd_base = clamp(25 + 7 * ti + B.crowd, 10, 90); S.crowd = S.crowd_base
	for i in 2: S.aggr[i] = clamp(0.06 + 0.035 * ti + B.aggr[i], 0.05, 0.8)
	S.stress_base = clamp(12 + 5 * ti + (12 if B.f.story == "derby" else 0) - (C.attrs.calma - 3) * 1.5, 5, 60); S.stress = S.stress_base
	# imagem pública: estádios mais hostis e capitães desconfiados quando está em baixo
	var img: float = float(C.get("imagem", 50))
	S.crowd_base = clamp(S.crowd_base + (50.0 - img) * 0.2, 10, 95); S.crowd = S.crowd_base
	for i in 2: S.cap_trust[i] = clamp(0.55 - 0.12 * int(C.grudge.get([B.h, B.a][i][0], 0)) + (img - 50.0) / 250.0, 0.1, 0.9)
	S.toast(B.comp, 2.5)

# castigados ficam de fora (entra um suplente) e quem foi expulso por ti lembra-se
func career_squad(S: Partida) -> void:
	for p in S.players:
		var club: String = S.teams[p.team].name
		var rec: Dictionary = C.pl.get(club + "#" + str(p.num), {})
		if rec.is_empty(): continue
		if rec.ban > 0:
			var r := Seeded.new(hash_s(club) + p.num * 31 + int(C.season) * 7)
			var nm: String = FIRST[int(r.next() * FIRST.size())] + " " + LAST[int(r.next() * LAST.size())]
			p.name = nm; p.short = nm.split(" ")[1]; p.ovr -= 6; p.tr = []; p.reserve = true; p.banned = rec.n
			p.pac = max(30.0, p.pac - 6); p.pas = max(30.0, p.pas - 6); p.fin = max(30.0, p.fin - 6); p.tck = max(30.0, p.tck - 6); p.drb = max(30.0, p.drb - 6)
			p.foul_k = 1; p.hard_k = 1; p.sim_k = 1; p.rel -= 6
		elif rec.grudge:
			p.grudge = true; p.foul_k *= 1.25; p.hard_k *= 1.3; p.sim_k *= 1.2

# ---------- depois do apito final ----------
func pl_rec(club: String, num: int) -> Dictionary:
	var k := club + "#" + str(num)
	if not C.pl.has(k): C.pl[k] = {"n": "", "j": 0, "y": 0, "r": 0, "f": 0, "ban": 0, "grudge": 0}
	return C.pl[k]
func career_players(S: Partida) -> String:
	var notes: Array = []
	for ti in 2:
		var club: String = S.teams[ti].name
		for k in C.pl:
			if k.begins_with(club + "#") and C.pl[k].ban > 0: C.pl[k].ban -= 1
		for p in S.players:
			if p.team != ti or p.reserve: continue
			var r := pl_rec(club, p.num)
			r.n = p.name if p.name != "" else (r.n if r.n != "" else "n.º %d" % p.num)
			r.j += 1; r.f += p.fouls
			if r.grudge and not p.off: r.grudge = max(0, r.grudge - 1)
			var second: bool = p.off and p.yellow >= 2
			var direct: bool = p.off and not second
			if p.yellow and not second:
				var y0: int = r.y
				r.y += mini(1, p.yellow)
				if r.y / 5 > y0 / 5: r.ban += 1; notes.append("%s chega aos %d amarelos: 1 jogo de castigo" % [r.n, r.y])
			if second: r.y += 1; r.r += 1; r.ban += 1; r.grudge = 2; notes.append("%s (%s): 1 jogo de castigo" % [r.n, club])
			if direct: r.r += 1; r.ban += 2; r.grudge = 2; notes.append("%s (%s): 2 jogos de castigo" % [r.n, club])
	return " Castigos: " + "; ".join(notes) + "." if notes.size() else ""
func season_reset_players() -> void:
	for k in C.pl:
		var r: Dictionary = C.pl[k]
		r.j = 0; r.y = 0; r.r = 0; r.f = 0
func discipline_rows() -> Array:
	var rows: Array = []
	for k in C.pl:
		var r: Dictionary = C.pl[k]
		if r.y or r.r or r.ban: rows.append([k, r])
	rows.sort_custom(func(x, y): return x[1].r * 3 + x[1].y > y[1].r * 3 + y[1].y)
	var out: Array = []
	for row in rows.slice(0, 6):
		var r: Dictionary = row[1]
		var parts: PackedStringArray = row[0].split("#")
		out.append({"title": "%s · %s" % [r.n, parts[1]], "sub": "%s · %d %s · %d %s · %d %s" % [parts[0], r.j, "jogo" if r.j == 1 else "jogos", r.y, "amarelo" if r.y == 1 else "amarelos", r.r, "vermelho" if r.r == 1 else "vermelhos"]
			+ (" · castigado %d %s" % [r.ban, "jogos" if r.ban > 1 else "jogo"] if r.ban else "") + (" · tem-te de olho" if r.grudge else "")})
	return out

# critério de jogo para jogo
func crit_career(S: Partida) -> void:
	var m := S.crit_mean()
	if m >= 0 and S.crit.size() >= 2: C.critS.append(round(m * 100) / 100.0)
func crit_season_adj() -> float:
	var a: Array = C.critS
	if a.size() < 2: return 0.0
	var mu := 0.0
	for x in a: mu += float(x)
	mu /= a.size()
	var v := 0.0
	for x in a: v += (float(x) - mu) * (float(x) - mu)
	var sd := sqrt(v / a.size())
	return round((clamp(1 - sd * 2.5, 0, 1) - 0.6) * 5) / 10.0
func crit_career_txt() -> String:
	if C.critS.size() < 2: return ""
	var adj := crit_season_adj()
	var s := " Critério " + ("igual de jogo para jogo" if adj >= 0.1 else ("quase sempre igual" if adj > -0.1 else "a mudar de jogo para jogo"))
	if adj != 0: s += " (" + ("+" if adj > 0 else "") + f1(adj) + " na média)"
	return s + "."

# jornal do dia seguinte: título, estrelas para o árbitro e o que disse o treinador
static func paper_of(S: Partida, grade: float, kind: String) -> Dictionary:
	var inc: Array = S.incidents.filter(func(l): return not l.get("training", false))
	var wrong: Array = inc.filter(func(l): return l.pts < 1)
	var game := "%s %d–%d %s" % [S.teams[0].name, S.score[0], S.score[1], S.teams[1].name]
	var stars := 1 if kind == "abandonado" else (5 if grade >= 9 else (4 if grade >= 8 else (3 if grade >= 6.5 else (2 if grade >= 5 else 1))))
	var big = null
	for test in [func(l): return l.get("goal_ctx", false), func(l): return l.get("in_box", false) and S.kind_of(l) != "offside",
			func(l): return l.get("decided", "") == "vermelho" or l.truth == "vermelho", func(l): return S.kind_of(l) == "offside"]:
		for l in wrong:
			if test.call(l): big = l; break
		if big != null: break
	var head: String
	if kind == "abandonado": head = "Jogo interrompido: o árbitro perdeu o controlo no " + game
	elif big != null:
		var d: String = big.get("decided", "")
		var t: String = big.truth
		if big.get("goal_ctx", false): head = ("Golo ilegal validado" if d == "valido" or d == "entrou" or (S.kind_of(big) == "offside" and d == "emjogo") else "Golo limpo anulado") + " marca o " + game
		elif S.kind_of(big) == "offside": head = ("Fora de jogo inventado" if d == "fora" else "Fora de jogo por assinalar") + " no " + game
		elif big.get("in_box", false): head = ("Penálti inventado" if S.scene_pen(big, d) or (not big.get("scene", false) and S.is_foul(d)) else "Penálti por marcar") + " no " + game
		else: head = ("Vermelho exagerado" if d == "vermelho" else ("Vermelho perdoado" if t == "vermelho" else "Erro grave")) + " no " + game
	elif inc.any(func(l): return l.has("var_first") and l.pts > 0): head = "O VAR salva o árbitro no " + game
	elif grade >= 8.5: head = ["Arbitragem de luxo no " + game, "Ninguém falou do árbitro no " + game + ", e isso é um elogio", "Árbitro impecável no " + game].pick_random()
	elif grade >= 6.5: head = ["Arbitragem segura no " + game, game + ": jogo bem conduzido, com uma ou outra dúvida"].pick_random()
	else: head = ["Árbitro em noite difícil no " + game, "Muitas dúvidas na arbitragem do " + game].pick_random()
	# o treinador mais prejudicado fala; se ninguém foi prejudicado, o que perdeu elogia ou resmunga
	var wr: Array = S.career.wrong if not S.career.is_empty() else [0, 0]
	var lost := 0 if S.score[0] < S.score[1] else (1 if S.score[1] < S.score[0] else -1)
	var ct: int = 0 if wr[0] > wr[1] else (1 if wr[1] > wr[0] else ((lost if lost >= 0 else 0) if wr[0] > 0 else lost))
	var quote := ""
	if ct >= 0:
		var bad: bool = wr[ct] > 0 or (S.career.is_empty() and wrong.size() >= 2)
		var q: String
		if bad: q = ["Hoje não perdemos com o adversário, perdemos com o árbitro.", "Vi o que toda a gente viu. O árbitro decidiu o jogo.", "Há decisões que não se explicam. Vamos fazer queixa.", "Trabalhamos a semana toda para isto? Não aceito."].pick_random()
		elif stars >= 4: q = ["Perdemos, mas o árbitro esteve bem. Não há desculpas.", "O árbitro foi justo. Fomos piores."].pick_random()
		else: q = ["Não vou falar da arbitragem.", "Há lances que vou rever com calma."].pick_random()
		quote = coach_name(S.teams[ct].name) + " (" + S.teams[ct].name + "): «" + q + "»"
	var right := inc.filter(func(l): return l.pts == 1).size()
	var body := "Nota do jornal para o árbitro: %d em 5. %d de %d decisões certas" % [stars, right, inc.size()]
	if S.anulados: body += ", %d %s" % [S.anulados, "golos anulados" if S.anulados > 1 else "golo anulado"]
	if S.var_n: body += ", %d ida%s ao VAR" % [S.var_n, "s" if S.var_n > 1 else ""]
	return {"paper": PAPERS.pick_random(), "head": head, "body": body + ".", "stars": stars, "quote": quote}

# nota conta para a época, pontos de atributo, tabela, castigos, subidas e descidas
func after(S: Partida, grade: float, kind: String) -> String:
	if S.career.is_empty() or C.is_empty() or S.career.get("done", false): return note
	S.career.done = true
	var T := tier()
	var g: float = round(grade * 10) / 10.0
	var rnd: int = C.round
	C.sg.append(g)
	# os outros árbitros também apitam e a tabela mexe
	var pos_note := ""
	var rank_note := ""
	if not S.paper.is_empty():
		C.papers.push_front({"s": C.season, "t": C.tier, "r": rnd, "p": S.paper.paper, "h": S.paper.head, "st": S.paper.stars, "q": S.paper.quote})
		C.papers = C.papers.slice(0, 8)
	if not T.get("cup", false):
		for r in C.refs: r.g.append(sim_grade(r.sk))
		var tb := ref_table()
		var pos := 0
		for i in tb.size():
			if tb[i].me: pos = i + 1
		pos_note = "Estás em %d.º na classificação dos árbitros." % pos
		if rnd + 1 >= T.games:
			rank_note = "Acabaste a época em %d.º lugar entre %d árbitros" % [pos, tb.size()] + (": árbitro do ano, +2 pontos de atributo." if pos == 1 else ".")
			if pos == 1: C.pts += 2
	crit_career(S)
	var ban_note := career_players(S)
	C.log.push_front({"s": C.season, "t": C.tier, "r": rnd, "h": S.career.h, "a": S.career.a, "sc": S.score.duplicate(), "g": g})
	C.log = C.log.slice(0, 30)
	var gain := 1 + (1 if g >= 8 else 0) + (1 if g >= 9 else 0)
	C.pts += gain
	for k in C.grudge.keys():
		C.grudge[k] = max(0, int(C.grudge[k]) - 1)
		if C.grudge[k] == 0: C.grudge.erase(k)
	for i in 2:
		if S.career.wrong[i] > 0: C.grudge[[S.career.h, S.career.a][i]] = S.career.wrong[i]
	C.round += 1
	var s := 0.0
	for x in C.sg: s += float(x)
	var avg: float = s / C.sg.size() + crit_season_adj()
	var msg: String = T.name + " · " + round_name(T, rnd) + ". "
	if T.get("cup", false):
		if g < T.target:
			msg += "Com " + f1(g) + " o observador não te deixa continuar no Mundial."
			end_season("Foste dispensado do Mundial depois dos " + CUP_ROUNDS[rnd].to_lower() + " (" + f1(g) + "; pediam " + f1(T.target) + "). Voltas à Taça Europeia.", 4, rank_note)
		elif C.round >= T.games:
			C.finals += 1; msg += "Apitaste a final do Mundial!"
			end_season("Apitaste a final do Mundial com " + f1(g) + ". É o topo da carreira. Na época seguinte voltas à Taça Europeia para tentar outra vez.", 4, rank_note)
		else: msg += "Nota " + f1(g) + ": segues para os " + CUP_ROUNDS[C.round].to_lower() + "."
	else:
		msg += "Média da época " + f1(avg) + " (para subir: " + f1(T.target) + ")."
		if C.round >= T.games:
			if avg >= T.target: end_season(("Média de " + f1(avg) + " na Taça Europeia: foste escolhido para o Mundial.") if C.tier == 4 else ("Média de " + f1(avg) + ": sobes para a " + TIERS[C.tier + 1].name + "."), C.tier + 1, rank_note)
			elif avg < T.target - 1.5 and C.tier > 0: end_season("Média de " + f1(avg) + ": o observador manda-te descer para a " + TIERS[C.tier - 1].name + ".", C.tier - 1, rank_note)
			else: end_season("Média de " + f1(avg) + ": ficas na " + T.name + " mais uma época (para subir precisavas de " + f1(T.target) + ").", C.tier, rank_note)
	msg += crit_career_txt() + ban_note
	if pos_note != "": msg += " " + pos_note
	msg += " +%d %s de atributo." % [gain, "pontos" if gain > 1 else "ponto"]
	save_c()
	note = msg
	return msg
func end_season(news: String, ti: int, rank_note := "") -> void:
	C.news = news + (" " + rank_note if rank_note != "" else "")
	C.tier = clampi(ti, 0, TIERS.size() - 1); C.season += 1; C.round = 0; C.sg = []; C.critS = []
	season_reset_players()
	C.fixtures = make_fixtures(C.tier); C.refs = make_refs(C.tier, 0)
func add_attr(k: String) -> void:
	if C.pts <= 0 or C.attrs[k] >= 10: return
	C.attrs[k] += 1; C.pts -= 1; save_c()
