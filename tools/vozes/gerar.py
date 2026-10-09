# Gera as falas do jogo com vozes neurais portuguesas (Piper pt_PT "dii" e "miro", CC BY-NC-SA 4.0)
# e aplica o "ambiente" de cada papel: rádio (banda estreita, estalido, estática),
# respiração e passos de quem corre (assistente), público ao fundo.
# Uso: python3 gerar.py <pasta com as vozes vits-piper-pt_PT-*> <pasta de saída>
import sys, json, re, hashlib
import numpy as np, soundfile as sf, sherpa_onnx
from scipy.signal import butter, sosfilt, resample_poly

VOZ, OUT = sys.argv[1], sys.argv[2]
SR = 22050
rng = np.random.default_rng(7)

NUM = ["zero", "um", "dois", "três", "quatro", "cinco", "seis", "sete", "oito", "nove"]
F = {}   # chave (texto mostrado) -> (papel, texto falado)
def add(who, txt, fala=None): F[txt] = (who, fala or txt)

for t in ["Levantei: para mim o recetor está fora.", "Bandeira em baixo: vi-o em linha.",
          "Daqui pareceu-me lance limpo.", "Daqui vi falta.", "Entrada imprudente, eu dava amarelo.", "Foi muito forte, pode ser vermelho.",
          "Para mim atirou-se.", "Vi mão, braço aberto.", "Mão deliberada.", "Vi o empurrão do defesa.", "Foi o atacante que empurrou."]:
    add("Assistente", t)
for t in ["Golo verificado. Pode recomeçar.", "Check completo. Decisão confirmada.", "Estamos a ver o golo. Decide tu primeiro.",
          "Golo em verificação: possível fora de jogo no passe. Recomendo revisão.", "Possível erro no fora de jogo. Recomendo revisão no monitor.",
          "Tenho imagens da linha de golo. Recomendo revisão.", "Golo em verificação: possível falta antes do remate.",
          "Possível vermelho. Recomendo revisão no monitor.", "Possível penálti. Recomendo revisão no monitor.", "Rádio ligado."]:
    add("VAR", t, t.replace("Check completo", "Verificação completa"))
for n in range(1, 10):
    add("4.º árbitro", "Tempo cumprido. Vou mostrar +%d." % n, "Tempo cumprido. Vou mostrar mais %s." % NUM[n])
add("4.º árbitro", "O treinador está fora da área técnica!")
for t in ["Golo anulado: estavas em fora de jogo no passe.", "Estava em jogo. O golo conta!", "Fora de jogo: estavas à frente do penúltimo defesa.", "Estava em jogo, siga!",
          "Os dois foram à bola. Siga!", "Empurraste-o nas costas no salto. Falta.", "Usaste o braço como alavanca. Amarelo.", "Cotovelada na cara. Vermelho!",
          "Tocaste na bola. Siga!", "Pisaste-lhe o calcanhar. Falta.", "Pitões no tendão. Amarelo.", "Pisão com força, por trás. Vermelho!",
          "Último homem, fora da área e sem tocar na bola. Vermelho!", "O guarda-redes chegou primeiro à bola. Siga!",
          "Houve toque, mas não chega para penálti. Siga!", "Tocou-lhe no pé, é penálti!",
          "Foi só um toque. Siga!", "Agarraste a camisola. Falta.", "Agarraste e paraste o contra-ataque. Amarelo.", "Agarrão a impedir um golo. Vermelho!",
          "Foi ombro com ombro. O golo conta!", "Empurraste o defesa antes do remate. Golo anulado.",
          "A bola passou toda a linha. É golo!", "Não passou toda a linha. Não há golo.",
          "Braço junto ao corpo, posição natural. Siga!", "Braço aberto, a fazer o corpo maior. É mão.", "Mão deliberada a cortar o remate: amarelo.",
          "Disputa normal na área. Siga, levanta-te!", "Empurrou-o pelas costas. Penálti!", "Afastaste o defesa com o braço. Falta atacante.",
          "Jogou a bola primeiro. Siga!", "Chegaste atrasado e derrubaste-o. Penálti!", "Chegaste atrasado. Falta.",
          "Já são faltas a mais. Amarelo.", "Cortaste o contra-ataque. Amarelo.", "Entrada imprudente. Amarelo.",
          "Entrada com força excessiva, pões o adversário em risco. Vermelho!", "Atiraste-te para o chão. Amarelo por simulação.",
          "Vantagem! Joguem, joguem!", "Siga!", "É o segundo: rua!"]:
    add("Árbitro", t)
REL = {"relato_golo_1": "Golo! Que golo! O estádio vem abaixo!", "relato_golo_2": "É golo! A bola está lá dentro!", "relato_golo_3": "Golooo! Que momento!",
       "relato_amarelo_1": "Cartão amarelo. O árbitro não perdoa.", "relato_amarelo_2": "Amarelo! Fica avisado.",
       "relato_vermelho_1": "Cartão vermelho! Vai para a rua!", "relato_vermelho_2": "Expulso! A equipa fica reduzida!",
       "relato_penalti_1": "Penálti! O árbitro aponta para a marca!", "relato_penalti_2": "É penálti! Que momento de tensão!"}
for k, v in REL.items(): add("Relato", k, v)

# papel: tom (reamostragem), velocidade, rádio, ambiente
# (voz, tom, velocidade, rádio, ambiente). dii = voz feminina, miro = masculina (as mais claras
# num teste com reconhecimento de voz; a tugão percebia-se pior).
PAP = {"Assistente": ("dii", 1.0, 0.97, True, "corre"), "VAR": ("miro", 0.96, 0.92, True, "sala"), "4.º árbitro": ("dii", 0.95, 0.95, True, "publico"),
       "Árbitro": ("miro", 1.0, 0.95, False, "campo"), "Relato": ("miro", 1.04, 1.0, False, "relato")}

def carrega(nome):
    d = f"{VOZ}/vits-piper-pt_PT-{nome}-high"
    return sherpa_onnx.OfflineTts(sherpa_onnx.OfflineTtsConfig(model=sherpa_onnx.OfflineTtsModelConfig(
        vits=sherpa_onnx.OfflineTtsVitsModelConfig(model=f"{d}/pt_PT-{nome}-high.onnx", tokens=f"{d}/tokens.txt", data_dir=f"{d}/espeak-ng-data"),
        num_threads=4)))
TTS = {n: carrega(n) for n in ["dii", "miro"]}

def bp(x, lo, hi, o=4): return sosfilt(butter(o, [lo, hi], "bandpass", fs=SR, output="sos"), x)
def lp(x, f, o=2): return sosfilt(butter(o, f, "lowpass", fs=SR, output="sos"), x)
def hp(x, f, o=2): return sosfilt(butter(o, f, "highpass", fs=SR, output="sos"), x)
def noise(n): return rng.standard_normal(n)

def publico(n, g):
    # murmúrio de estádio: ruído rosa-ish com ondulação lenta
    x = lp(noise(n), 900) + 0.4 * bp(noise(n), 900, 2500, 2)
    t = np.arange(n) / SR
    m = 0.7 + 0.3 * np.sin(2 * np.pi * 0.23 * t + rng.uniform(0, 6)) * np.sin(2 * np.pi * 0.11 * t)
    return x * m * g / (np.std(x) + 1e-9)

def corrida(n):
    # passos na relva (baque grave + roçar) e respiração ofegante
    t = np.arange(n) / SR
    out = np.zeros(n)
    step = 0.34
    k = rng.uniform(0, step)
    while k < n / SR:
        i = int(k * SR); L = min(int(0.12 * SR), n - i)
        tt = np.arange(L) / SR
        thump = np.sin(2 * np.pi * (70 + 30 * rng.random()) * tt) * np.exp(-tt * 38)
        crunch = bp(noise(L), 1200, 4500, 2) * np.exp(-tt * 60) * 0.35
        out[i:i + L] += (thump + crunch) * rng.uniform(0.6, 1.0)
        k += step * rng.uniform(0.93, 1.07)
    br = np.zeros(n)
    k = rng.uniform(0, 0.3)
    while k < n / SR:
        i = int(k * SR); L = min(int(0.28 * SR), n - i)
        tt = np.arange(L) / SR
        env = np.sin(np.pi * np.clip(tt / 0.28, 0, 1)) ** 2
        br[i:i + L] += bp(noise(L), 500, 2600, 2) * env * rng.uniform(0.6, 1.0)
        k += rng.uniform(0.42, 0.55)
    return out * 0.22 + br * 0.09

def radio(x):
    # banda de rádio, saturação, estática, estalido ao carregar e ao largar o botão
    pre = int(0.16 * SR); post = int(0.22 * SR)
    x = np.concatenate([np.zeros(pre), x, np.zeros(post)])
    n = len(x)
    y = bp(x, 250, 3800, 2)
    y = np.tanh(y * 1.2) / np.tanh(1.2)
    y = y / (np.max(np.abs(y)) + 1e-9) * 0.8
    hiss = bp(noise(n), 1500, 5000, 2) * 0.004
    y = y + hiss
    # estalido de abertura + chiado curto
    c = int(0.012 * SR); y[:c] += np.linspace(0.6, 0, c) * np.sign(noise(c))
    s = int(0.09 * SR); y[c:c + s] += bp(noise(s), 800, 4000, 2) * np.linspace(0.25, 0, s)
    # fecho: "kssh" da squelch
    s2 = int(0.16 * SR); y[n - post: n - post + s2] += bp(noise(s2), 1000, 5000, 2) * np.linspace(0.3, 0.0, s2) ** 0.5 * 0.6
    return y

def compress(x, thr=0.25, ratio=3.0):
    env = lp(np.abs(x), 30, 1) + 1e-6
    g = np.where(env > thr, (thr + (env - thr) / ratio) / env, 1.0)
    return x * g

# os jogadores aprendem com o critério do árbitro (avisos do 4.º árbitro)
for t in ["Cuidado: viram que a simulação passou. Vão tentar outra vez.", "Ficaram avisados: aqui quem se atira vê amarelo.",
          "Perceberam que podem entrar duro sem cartão. Vai aquecer.", "O cartão acalmou-os. Estão a medir as entradas.",
          "Deixaste-os falar e agora protestam tudo.", "Depois do cartão, ninguém se quer chegar a protestar."]:
    add("4.º árbitro", t)

add("Árbitro", "Fui ver as imagens. Mudo a decisão.")
for t in ["Atenção: o guarda-redes saiu da linha antes do pontapé.", "Guarda-redes na linha, da minha parte está tudo bem."]:
    add("Assistente", t)

import os
if os.environ.get("SO"): F = {k: v for k, v in F.items() if os.environ["SO"] in k}   # gerar só algumas
idx = {}
for key, (who, fala) in F.items():
    voz, tom, vel, rad, amb = PAP[who]
    a = TTS[voz].generate(fala, sid=0, speed=vel / tom)
    x = np.array(a.samples, dtype=np.float64)
    if tom != 1.0:
        up, dn = 100, int(round(100 * tom))
        x = resample_poly(x, up, dn)   # mais curto => mais agudo
    x = hp(x, 90)
    x = x / (np.max(np.abs(x)) + 1e-9) * 0.8
    lead = int(0.05 * SR)
    x = np.concatenate([np.zeros(lead), x, np.zeros(int(0.1 * SR))])
    if who == "Relato": x = compress(x * 1.4, 0.3, 4.0)
    n = len(x)
    # o ambiente fica bem abaixo da voz (nível relativo à voz falada, não ao pico)
    fala_rms = np.sqrt(np.mean(x[np.abs(x) > 0.02] ** 2))
    def nivel(b, db): return b / (np.sqrt(np.mean(b ** 2)) + 1e-9) * fala_rms * 10 ** (db / 20)
    # (medido com reconhecimento de voz: mais alto que isto e as falas deixam de se perceber)
    if amb == "corre": bed = nivel(corrida(n), -22) + nivel(publico(n, 1), -30)
    elif amb == "sala": bed = nivel(lp(noise(n), 300), -36)
    elif amb == "publico": bed = nivel(publico(n, 1), -27)
    elif amb == "campo": bed = nivel(publico(n, 1), -30) + nivel(corrida(n), -28)
    else: bed = nivel(publico(n, 1), -26)
    y = x + bed
    if rad: y = radio(y)
    y = y / (np.max(np.abs(y)) + 1e-9) * 0.9
    fn = hashlib.md5(key.encode()).hexdigest()[:10]   # o jogo encontra o ficheiro pelo md5 do texto
    sf.write(f"{OUT}/{fn}.ogg", y.astype(np.float32), SR, format="OGG", subtype="VORBIS")
    idx[key] = {"f": fn + ".ogg", "who": who, "dur": round(len(y) / SR, 2)}
json.dump(idx, open(f"{OUT}/voz.json", "w"), ensure_ascii=False, indent=0)
print(len(idx), "falas")
