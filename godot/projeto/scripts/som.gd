class_name Som
extends Node
# Som: tudo sintetizado em _ready (PCM em AudioStreamWAV), sem ficheiros.
# Port do módulo Sfx + Voice da versão browser (Web Audio + speechSynthesis).

const SR: int = 22050          # apito, chuto, bip, rádio
const SR_BAIXO: int = 11025    # público (tudo abaixo de ~3 kHz)
const POOL: int = 10
const MASTER: float = 0.8
const LP: int = 0
const HP: int = 1
const BP: int = 2
const BUS_SOM: String = "Som"
const BUS_PUBLICO: String = "Publico"
const CFG: String = "user://voz.cfg"
# vozes por papel: tom, velocidade, índice da voz (como o P do JS)
const PAPEIS: Dictionary = {
	"VAR": [0.75, 1.05, 0], "Assistente": [1.15, 1.1, 1], "4.º árbitro": [0.95, 1.08, 2],
	"Relato": [1.05, 1.18, 0], "Árbitro": [0.9, 1.08, 1],
}

var muted: bool = false: set = _set_muted
var voice_on: bool = true: set = _set_voice_on
var synth_us: int = 0           # tempo total de síntese (µs)
var pronto: bool = false        # todos os sons gerados

var _sons: Dictionary = {}
var _pool: Array[AudioStreamPlayer] = []
var _prox: int = 0
var _murmurio: AudioStreamPlayer
var _bus_publico: int = -1
var _filtro: AudioEffectBandPassFilter
var _nivel: float = 0.0
var _ganho: float = 0.0
var _freq: float = 650.0
var _boost: float = 0.0
var _boost_t: float = 0.0
var _vozes: PackedStringArray = PackedStringArray()
# Falas gravadas (voz neural pt-PT com rádio e ambiente já misturados), em assets/voz/<md5 do texto>.ogg
const VOZ_DIR: String = "res://assets/voz/"
var _voz: AudioStreamPlayer
var _fila: Array = []           # falas à espera: [stream, papel]
var _voz_cache: Dictionary = {}
var faltas: PackedStringArray = PackedStringArray()   # textos sem fala gravada (para os testes)


# Cria os buses e o murmúrio; os outros sons geram-se um por frame para não engasgar.
func _ready() -> void:
	var t0: int = Time.get_ticks_usec()
	_criar_buses()
	for i in POOL:
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		p.bus = BUS_SOM
		add_child(p)
		_pool.append(p)
	_voz = AudioStreamPlayer.new()
	_voz.bus = BUS_SOM
	add_child(_voz)
	_voz.finished.connect(_proxima_fala)
	_murmurio = AudioStreamPlayer.new()
	_murmurio.stream = _gera_murmurio()
	_murmurio.bus = BUS_PUBLICO
	add_child(_murmurio)
	_murmurio.play()
	_sons["short"] = _gera_apito([0.22])
	_sons["kick"] = _gera_chuto()
	_sons["beep"] = _gera_bip()
	_sons["radio"] = _gera_radio()
	_sons["alerta"] = _gera_alerta()
	synth_us += Time.get_ticks_usec() - t0
	_carregar_voz()
	_gerar_resto()


# Gera os sons mais pesados, um por frame.
func _gerar_resto() -> void:
	var lista: Array[String] = ["long", "double", "end", "cheer", "boo", "ooh"]
	for nome in lista:
		await get_tree().process_frame
		var t0: int = Time.get_ticks_usec()
		match nome:
			"long": _sons[nome] = _gera_apito([0.75])
			"double": _sons[nome] = _gera_apito([0.14, 0.4])
			"end": _sons[nome] = _gera_apito([0.35, 0.35, 1.1])
			"cheer": _sons[nome] = _gera_festa()
			"boo": _sons[nome] = _gera_vaia()
			"ooh": _sons[nome] = _gera_ooh()
		synth_us += Time.get_ticks_usec() - t0
	pronto = true


# Suaviza o ganho e o filtro do murmúrio (como o setTargetAtTime).
func _process(delta: float) -> void:
	if _bus_publico < 0:
		return
	var b: float = _cur_boost()
	var alvo_g: float = 0.06 + _nivel * 0.12 + b * 0.25
	var alvo_f: float = 480.0 + _nivel * 380.0 + b * 650.0
	var tau: float = 0.15 if b > 0.05 else 0.5
	_ganho += (alvo_g - _ganho) * (1.0 - exp(-delta / tau))
	_freq += (alvo_f - _freq) * (1.0 - exp(-delta / 0.3))
	AudioServer.set_bus_volume_db(_bus_publico, linear_to_db(maxf(_ganho * 2.0, 0.0001)))
	_filtro.cutoff_hz = _freq


# Pára tudo ao sair (evita playbacks pendurados no servidor de áudio).
func _exit_tree() -> void:
	for p in _pool:
		p.stop()
		p.stream = null
	if _murmurio:
		_murmurio.stop()


# ---------- API pública ----------

# Apito: "short", "long", "double" ou "end" (três apitos).
func whistle(kind: String = "short") -> void:
	var k: String = kind if kind in ["short", "long", "double", "end"] else "short"
	_tocar(k, 1.0)


# Pancada seca do chuto, mais forte com vol.
func kick(vol: float) -> void:
	if vol <= 0.02:
		return
	_tocar("kick", vol)


# Festa do público.
func cheer(vol: float) -> void:
	react(vol)
	_tocar("cheer", vol)


# Vaias e assobios.
func boo(vol: float) -> void:
	react(vol * 0.8)
	_tocar("boo", vol)


# "Uuuh" de remate ao lado.
func ooh() -> void:
	react(0.55)
	_tocar("ooh", 1.0)


# Aviso de lance para analisar: dois toques claros, como um pager.
func alerta() -> void:
	_tocar("alerta", 1.0)


# Bip duplo do VAR.
func beep() -> void:
	_tocar("beep", 1.0)


# Estalido curto do auricular.
func radio() -> void:
	_tocar("radio", 1.0)


# Pressão do público (0..1, ou 0..100); burst > 0 é um react() extra.
func set_crowd(level: float, burst: float = 0.0) -> void:
	var l: float = level / 100.0 if level > 1.0 else level
	_nivel = clampf(l, 0.0, 1.0)
	if burst > 0.0:
		react(burst)


# O murmúrio sobe por uns segundos a cada acontecimento e volta a baixar.
func react(v: float) -> void:
	_boost = maxf(_cur_boost(), v)
	_boost_t = _agora()


# Liga/desliga o som; devolve true se ficou mudo.
func toggle() -> bool:
	muted = not muted
	return muted


# Há fala gravada para este texto (inteiro ou frase a frase)?
func tem_fala(text: String) -> bool:
	return not _falas(text).is_empty()


# Fala em português: primeiro as falas gravadas; se faltar alguma, a voz do sistema (TTS).
func say(text: String, who: String = "Relato") -> void:
	if not voice_on or muted:
		return
	var f: Array = _falas(text)
	if not f.is_empty():
		if who == "Relato" and (_voz.playing or not _fila.is_empty()):
			return      # o relato nunca corta o rádio
		if who != "Relato" and _voz.playing and _fila.is_empty() and _voz.get_meta("who", "") == "Relato":
			_voz.stop()
		for st in f:
			_fila.append([st, who])
		if not _voz.playing:
			_proxima_fala()
		return
	if not faltas.has(text): faltas.append(text)
	if text.begins_with("relato_") or not _tts_ok():
		return
	var q: Array = PAPEIS.get(who, PAPEIS["Relato"])
	var voz: String = ""
	if _vozes.size() > 0:
		voz = _vozes[int(q[2]) % _vozes.size()]
	if who == "Relato" and DisplayServer.tts_is_speaking():
		return
	DisplayServer.tts_speak(text, voz, 95, float(q[0]), float(q[1]), 0, who != "Relato")


# Fluxos das falas gravadas: o texto inteiro, ou cada frase em separado.
func _falas(text: String) -> Array:
	var t: String = text.strip_edges()
	var a: AudioStream = _fala(t)
	if a:
		return [a]
	# junta frases seguidas, a maior combinação que existir primeiro
	var fr: Array = []
	var rx: RegEx = RegEx.create_from_string("[^.!?]+[.!?]+")
	for m in rx.search_all(t):
		fr.append(m.get_string().strip_edges())
	var out: Array = []
	var i: int = 0
	while i < fr.size():
		var achou: bool = false
		for j in range(fr.size(), i, -1):
			var b: AudioStream = _fala(" ".join(fr.slice(i, j)))
			if b:
				out.append(b); i = j; achou = true
				break
		if not achou:
			return []
	return out


func _fala(t: String) -> AudioStream:
	if t == "":
		return null
	if _voz_cache.has(t):
		return _voz_cache[t]
	var path: String = VOZ_DIR + t.md5_text().substr(0, 10) + ".ogg"
	var a: AudioStream = load(path) if ResourceLoader.exists(path) else null
	_voz_cache[t] = a
	return a


func _proxima_fala() -> void:
	if _fila.is_empty():
		return
	var it: Array = _fila.pop_front()
	_voz.stream = it[0]
	_voz.set_meta("who", it[1])
	_voz.volume_db = linear_to_db(0.8 if it[1] == "Relato" else 1.0)
	_voz.play()


# Liga/desliga a voz; devolve o novo estado.
func toggle_voice() -> bool:
	voice_on = not voice_on
	return voice_on


# Cala a voz já.
func stop_voice() -> void:
	_fila.clear()
	if _voz:
		_voz.stop()
	if _tts_ok():
		DisplayServer.tts_stop()


# ---------- interno ----------

func _set_muted(v: bool) -> void:
	muted = v
	var i: int = AudioServer.get_bus_index(BUS_SOM)
	if i >= 0:
		AudioServer.set_bus_mute(i, v)


func _set_voice_on(v: bool) -> void:
	voice_on = v
	if not v:
		stop_voice()
	var cf: ConfigFile = ConfigFile.new()
	cf.set_value("voz", "on", v)
	cf.save(CFG)


func _carregar_voz() -> void:
	var cf: ConfigFile = ConfigFile.new()
	if cf.load(CFG) == OK:
		voice_on = bool(cf.get_value("voz", "on", true))


# TTS só existe com audio/general/text_to_speech ligado nas definições do projeto.
func _tts_ok() -> bool:
	if not bool(ProjectSettings.get_setting("audio/general/text_to_speech", false)):
		return false
	if _vozes.is_empty():
		_vozes = _vozes_pt()
	return true


# Vozes portuguesas, pt-PT primeiro.
func _vozes_pt() -> PackedStringArray:
	var pt: PackedStringArray = PackedStringArray()
	var outras: PackedStringArray = PackedStringArray()
	for v: Dictionary in DisplayServer.tts_get_voices():
		var lang: String = String(v.get("language", "")).to_lower().replace("-", "_")
		if not lang.begins_with("pt"):
			continue
		if lang.begins_with("pt_pt"):
			pt.append(String(v.get("id", "")))
		else:
			outras.append(String(v.get("id", "")))
	if pt.is_empty() and outras.is_empty():
		outras = DisplayServer.tts_get_voices_for_language("pt")
	pt.append_array(outras)
	return pt


func _agora() -> float:
	return Time.get_ticks_msec() / 1000.0


func _cur_boost() -> float:
	return _boost * exp(-(_agora() - _boost_t) / 2.2)


# Toca um som pré-gerado num leitor livre do conjunto (se ainda não existir, fica calado).
func _tocar(nome: String, vol: float) -> void:
	if _pool.is_empty() or not _sons.has(nome):
		return
	var p: AudioStreamPlayer = null
	for i in POOL:
		var c: AudioStreamPlayer = _pool[(_prox + i) % POOL]
		if not c.playing:
			p = c
			_prox = (_prox + i + 1) % POOL
			break
	if p == null:
		p = _pool[_prox]
		_prox = (_prox + 1) % POOL
	p.stream = _sons[nome]
	p.volume_db = linear_to_db(clampf(vol, 0.001, 4.0))
	p.play()


# Buses: Som (geral, mudo) e Publico (murmúrio com filtro) que manda para Som.
func _criar_buses() -> void:
	if AudioServer.get_bus_index(BUS_SOM) < 0:
		AudioServer.add_bus(-1)
		var i: int = AudioServer.bus_count - 1
		AudioServer.set_bus_name(i, BUS_SOM)
		AudioServer.set_bus_send(i, "Master")
		AudioServer.set_bus_volume_db(i, linear_to_db(MASTER))
	if AudioServer.get_bus_index(BUS_PUBLICO) < 0:
		AudioServer.add_bus(-1)
		var j: int = AudioServer.bus_count - 1
		AudioServer.set_bus_name(j, BUS_PUBLICO)
		AudioServer.set_bus_send(j, BUS_SOM)
		var f: AudioEffectBandPassFilter = AudioEffectBandPassFilter.new()
		f.cutoff_hz = 650.0
		f.resonance = 0.3
		AudioServer.add_bus_effect(j, f)
	_bus_publico = AudioServer.get_bus_index(BUS_PUBLICO)
	_filtro = AudioServer.get_bus_effect(_bus_publico, 0) as AudioEffectBandPassFilter
	AudioServer.set_bus_volume_db(_bus_publico, linear_to_db(0.0001))
	AudioServer.set_bus_mute(AudioServer.get_bus_index(BUS_SOM), muted)


# Envolvente: subida linear, patamar, descida exponencial até 0.0001 (como env() do JS).
func _env(t: float, a: float, hold: float, rel: float, peak: float) -> float:
	if t < 0.0:
		return 0.0
	if t < a:
		return peak * t / a
	var t2: float = t - a - hold
	if t2 <= 0.0:
		return peak
	if t2 >= rel:
		return 0.0
	return peak * pow(0.0001 / peak, t2 / rel)


# Coeficientes biquad (RBJ, os mesmos do BiquadFilter do Web Audio).
func _coefs(tipo: int, f: float, q: float, rate: int) -> PackedFloat32Array:
	var w0: float = TAU * f / rate
	var cs: float = cos(w0)
	var al: float = sin(w0) / (2.0 * q)
	var b0: float = al
	var b1: float = 0.0
	var b2: float = -al
	if tipo == LP:
		b0 = (1.0 - cs) * 0.5
		b1 = 1.0 - cs
		b2 = b0
	elif tipo == HP:
		b0 = (1.0 + cs) * 0.5
		b1 = -(1.0 + cs)
		b2 = b0
	var a0: float = 1.0 + al
	return PackedFloat32Array([b0 / a0, b1 / a0, b2 / a0, -2.0 * cs / a0, (1.0 - al) / a0])


# Filtra o buffer com frequência fixa.
func _biquad(buf: PackedFloat32Array, tipo: int, f: float, q: float, rate: int) -> PackedFloat32Array:
	var c: PackedFloat32Array = _coefs(tipo, f, q, rate)
	var b0: float = c[0]
	var b1: float = c[1]
	var b2: float = c[2]
	var a1: float = c[3]
	var a2: float = c[4]
	var x1: float = 0.0
	var x2: float = 0.0
	var y1: float = 0.0
	var y2: float = 0.0
	for i in buf.size():
		var x: float = buf[i]
		var y: float = b0 * x + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
		x2 = x1
		x1 = x
		y2 = y1
		y1 = y
		buf[i] = y
	return buf


func _ruido(n: int) -> PackedFloat32Array:
	var b: PackedFloat32Array = PackedFloat32Array()
	b.resize(n)
	for i in n:
		b[i] = randf() * 2.0 - 1.0
	return b


# Converte para PCM 16-bit mono.
func _wav(buf: PackedFloat32Array, rate: int, loop: bool = false) -> AudioStreamWAV:
	var n: int = buf.size()
	var d: PackedByteArray = PackedByteArray()
	d.resize(n * 2)
	for i in n:
		d.encode_s16(i * 2, int(clampf(buf[i], -1.0, 1.0) * 32767.0))
	var w: AudioStreamWAV = AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = d
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = n
	return w


# Apito de ervilha: duas notas agudas com trilo rápido; um blast por duração.
func _gera_apito(pat: Array) -> AudioStreamWAV:
	var total: float = 0.0
	for d: float in pat:
		total += d + 0.16
	var buf: PackedFloat32Array = PackedFloat32Array()
	buf.resize(int(total * SR) + 1)
	var x: float = 0.0
	for d: float in pat:
		_blast(buf, x, d, 0.16)
		x += d + 0.16
	return _wav(buf, SR)


func _blast(buf: PackedFloat32Array, t0: float, dur: float, vol: float) -> void:
	var n: int = int((dur + 0.08) * SR)
	var tmp: PackedFloat32Array = PackedFloat32Array()
	tmp.resize(n)
	var p1: float = 0.0
	var p2: float = 0.0
	var k: float = TAU * 34.0 / SR
	for i in n:
		var dv: float = 110.0 * sin(k * i)
		p1 += (2860.0 + dv) / SR
		if p1 >= 1.0:
			p1 -= 1.0
		p2 += (3010.0 + dv) / SR
		if p2 >= 1.0:
			p2 -= 1.0
		tmp[i] = (1.0 if p1 < 0.5 else -1.0) + (2.0 * p2 - 1.0)
	tmp = _biquad(tmp, BP, 3000.0, 3.0, SR)
	var i0: int = int(t0 * SR)
	for i in n:
		var j: int = i0 + i
		if j >= buf.size():
			break
		var t: float = float(i) / SR
		buf[j] += tmp[i] * (0.7 + 0.3 * sin(k * i)) * _env(t, 0.015, dur, 0.06, vol)


# Chuto: nota grave que cai de 140 para 48 Hz mais um clique de ruído.
func _gera_chuto() -> AudioStreamWAV:
	var n: int = int(0.15 * SR)
	var buf: PackedFloat32Array = PackedFloat32Array()
	buf.resize(n)
	var ph: float = 0.0
	for i in n:
		var t: float = float(i) / SR
		var f: float = 140.0 * pow(48.0 / 140.0, minf(t / 0.09, 1.0))
		ph += TAU * f / SR
		buf[i] = sin(ph) * _env(t, 0.003, 0.01, 0.09, 0.5)
	var nn: int = int(0.05 * SR)
	var r: PackedFloat32Array = _biquad(_ruido(nn), HP, 1800.0, 1.12, SR)
	for i in nn:
		buf[i] += r[i] * _env(float(i) / SR, 0.002, 0.005, 0.03, 0.12)
	return _wav(buf, SR)


# Festa: ruído largo com filtro que sobe de 700 para 1300 Hz.
func _gera_festa() -> AudioStreamWAV:
	var n: int = int(3.3 * SR_BAIXO)
	var buf: PackedFloat32Array = _ruido(n)
	var x1: float = 0.0
	var x2: float = 0.0
	var y1: float = 0.0
	var y2: float = 0.0
	var c: PackedFloat32Array = PackedFloat32Array()
	for i in n:
		var t: float = float(i) / SR_BAIXO
		if i % 32 == 0 and (t < 0.55 or c.is_empty()):
			c = _coefs(BP, 700.0 + 600.0 * minf(t / 0.5, 1.0), 0.7, SR_BAIXO)
		var x: float = buf[i]
		var y: float = c[0] * x + c[1] * x1 + c[2] * x2 - c[3] * y1 - c[4] * y2
		x2 = x1
		x1 = x
		y2 = y1
		y1 = y
		buf[i] = y * _env(t, 0.25, 1.2, 1.8, 0.4)
	return _wav(buf, SR_BAIXO)


# Vaias: nove vozes graves com vibrato, filtradas, e assobios agudos por cima.
func _gera_vaia() -> AudioStreamWAV:
	var n: int = int(2.7 * SR_BAIXO)
	var buf: PackedFloat32Array = PackedFloat32Array()
	buf.resize(n)
	for v in 9:
		var f0: float = 105.0 + randf() * 60.0
		var kv: float = TAU * (4.0 + randf() * 3.0) / SR_BAIXO
		var ph: float = randf()
		for i in n:
			ph += (f0 + 5.0 * sin(kv * i)) / SR_BAIXO
			if ph >= 1.0:
				ph -= 1.0
			buf[i] += 2.0 * ph - 1.0
	buf = _biquad(buf, LP, 520.0, 1.12, SR_BAIXO)
	for i in n:
		buf[i] *= _env(float(i) / SR_BAIXO, 0.35, 1.1, 1.2, 0.11)
	for w in 3:
		var t1: float = 0.2 + randf() * 0.8
		var fa: float = 1900.0 + randf() * 900.0
		var fb: float = 1500.0 + randf() * 600.0
		var i0: int = int(t1 * SR_BAIXO)
		var ph2: float = 0.0
		for i in int(1.1 * SR_BAIXO):
			if i0 + i >= n:
				break
			var t: float = float(i) / SR_BAIXO
			ph2 += TAU * lerpf(fa, fb, minf(t / 0.9, 1.0)) / SR_BAIXO
			buf[i0 + i] += sin(ph2) * _env(t, 0.08, 0.6, 0.3, 0.025)
	return _wav(buf, SR_BAIXO)


# "Uuuh": sete vozes que sobem de tom, num passa-banda a 480 Hz.
func _gera_ooh() -> AudioStreamWAV:
	var n: int = int(1.65 * SR_BAIXO)
	var buf: PackedFloat32Array = PackedFloat32Array()
	buf.resize(n)
	for v in 7:
		var fa: float = 160.0 + randf() * 70.0
		var fb: float = 230.0 + randf() * 70.0
		var ph: float = randf()
		for i in n:
			var t: float = float(i) / SR_BAIXO
			ph += lerpf(fa, fb, minf(t / 0.7, 1.0)) / SR_BAIXO
			if ph >= 1.0:
				ph -= 1.0
			buf[i] += 2.0 * ph - 1.0
	buf = _biquad(buf, BP, 480.0, 1.5, SR_BAIXO)
	for i in n:
		buf[i] *= _env(float(i) / SR_BAIXO, 0.2, 0.5, 0.9, 0.12)
	return _wav(buf, SR_BAIXO)


# Bip duplo do VAR a 988 Hz.
func _gera_bip() -> AudioStreamWAV:
	var n: int = int(0.47 * SR)
	var buf: PackedFloat32Array = PackedFloat32Array()
	buf.resize(n)
	var k: float = TAU * 988.0 / SR
	for i in n:
		var t: float = float(i) / SR
		var e: float = _env(t, 0.01, 0.12, 0.05, 0.1) + _env(t - 0.22, 0.01, 0.12, 0.05, 0.1)
		buf[i] = sin(k * i) * e
	return _wav(buf, SR)


# Aviso de lance: dois toques (880 e 1320 Hz) com harmónico, a decair.
func _gera_alerta() -> AudioStreamWAV:
	var n: int = int(0.75 * SR)
	var buf: PackedFloat32Array = PackedFloat32Array()
	buf.resize(n)
	for i in n:
		var t: float = float(i) / SR
		var v: float = 0.0
		for k in 2:
			var tk: float = t - k * 0.16
			if tk >= 0.0:
				var f: float = 880.0 if k == 0 else 1320.0
				v += (sin(TAU * f * tk) + 0.35 * sin(TAU * f * 2.0 * tk)) * exp(-tk * 7.0) * minf(tk / 0.004, 1.0)
		buf[i] = v * 0.32
	return _wav(buf, SR)


# Estalido do auricular: ruído curto num passa-banda a 2400 Hz.
func _gera_radio() -> AudioStreamWAV:
	var n: int = int(0.09 * SR)
	var buf: PackedFloat32Array = _biquad(_ruido(n), BP, 2400.0, 2.0, SR)
	for i in n:
		buf[i] *= _env(float(i) / SR, 0.005, 0.03, 0.05, 0.06)
	return _wav(buf, SR)


# Murmúrio do estádio: ruído rosa em loop (o filtro e o volume ficam no bus).
func _gera_murmurio() -> AudioStreamWAV:
	var n: int = 4 * SR_BAIXO
	var fade: int = int(SR_BAIXO * 0.2)
	var buf: PackedFloat32Array = PackedFloat32Array()
	buf.resize(n + fade)
	var b0: float = 0.0
	var b1: float = 0.0
	var b2: float = 0.0
	for i in n + fade:
		var w: float = randf() * 2.0 - 1.0
		b0 = 0.99765 * b0 + w * 0.099
		b1 = 0.963 * b1 + w * 0.2965
		b2 = 0.57 * b2 + w * 1.0527
		buf[i] = (b0 + b1 + b2 + w * 0.1848) * 0.08
	# cruza o fim com o início para o loop não estalar
	for i in fade:
		var a: float = float(i) / fade
		buf[i] = buf[i] * a + buf[n + i] * (1.0 - a)
	buf.resize(n)
	return _wav(buf, SR_BAIXO, true)
