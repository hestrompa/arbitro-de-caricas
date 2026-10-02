# Ambiente de estádio em loop, feito com muitas vozes a falar ao mesmo tempo (as mesmas vozes
# neurais das falas, baixinho e longe), mais ruído de multidão, palmas e assobios.
# Uso: python3 publico.py <pasta das vozes> <pasta de saída>
import sys, numpy as np, soundfile as sf
from gerar_lib import TTS, bp, lp, hp, noise, SR
from scipy.signal import resample_poly, fftconvolve
OUT = sys.argv[2]
rng = np.random.default_rng(11)
L = 30 * SR   # 30 s em loop (na web cada volta do loop recomeça o som, quanto mais longo menos vezes)

FRASES = ["Vamos lá, rapazes!", "Isso é falta, senhor árbitro!", "Passa a bola!", "Remata, remata!", "Que jogada!", "Olha o fora de jogo!",
          "Anda, defende!", "Ó árbitro, vê lá isso!", "Vai, vai, vai!", "Não acredito!", "Boa defesa!", "Corre!", "Cruza para a área!",
          "Isso é cartão!", "Joga para a frente!", "Tira daí!", "Que falhanço!", "Aguenta!", "Ataca pela esquerda!", "Golo, golo!"]
falas = []
for i, f in enumerate(FRASES * 2):
    v = TTS["dii" if i % 3 == 0 else "miro"]
    x = np.array(v.generate(f, sid=0, speed=rng.uniform(0.9, 1.25)).samples, dtype=np.float64)
    tom = rng.uniform(0.85, 1.15)
    x = resample_poly(x, 100, int(round(100 * tom)))
    falas.append(x / (np.max(np.abs(x)) + 1e-9))

# reverberação de estádio: resposta ao impulso de ruído a decair
ir_n = int(1.6 * SR)
t = np.arange(ir_n) / SR
ir = noise(ir_n) * np.exp(-t * 3.2); ir = lp(ir, 3000); ir[0] = 3.0; ir /= np.sqrt(np.sum(ir ** 2))

def em_loop(y):
    # dobra o fim para o início, para o loop não ter costura
    out = y[:L].copy(); extra = y[L:]
    out[:len(extra)] += extra
    return out

def conversa(n_vozes, ganho):
    y = np.zeros(L + 3 * SR)
    for _ in range(n_vozes):
        x = falas[rng.integers(len(falas))]
        i = rng.integers(0, L)
        d = rng.uniform(0.15, 1.0)          # longe = mais baixo e mais abafado
        x = lp(x, 1200 + 2500 * d) * d * rng.uniform(0.5, 1.0)
        y[i:i + len(x)] += x[: len(y) - i]
    y = fftconvolve(y, ir)[: len(y)]
    return em_loop(y) * ganho

def multidao(lo, hi, ganho, ondula=0.25):
    y = bp(noise(L + 3 * SR), lo, hi, 2)
    tt = np.arange(len(y)) / SR
    y *= 0.75 + ondula * np.sin(2 * np.pi * 0.13 * tt + 1.0) * np.sin(2 * np.pi * 0.07 * tt)
    return em_loop(y) * ganho

def palmas(bpm, ganho):
    y = np.zeros(L + 3 * SR)
    per = 60.0 / bpm
    for k in range(int((L / SR) / per)):
        base = int(k * per * SR)
        for _ in range(60):   # muitas pessoas, ligeiramente fora de tempo
            i = base + int(rng.normal(0, 0.025) * SR)
            if i < 0: continue
            n = int(0.03 * SR); tt = np.arange(n) / SR
            c = bp(noise(n), 900, 4000, 2) * np.exp(-tt * 140) * rng.uniform(0.3, 1.0)
            y[i:i + n] += c[: len(y) - i]
    y = fftconvolve(y, ir)[: len(y)]
    return em_loop(y) * ganho

def norm(y, pk=0.7): return y / (np.max(np.abs(y)) + 1e-9) * pk

calmo = norm(conversa(480, 1.0) / 6 + multidao(150, 900, 0.5), 0.6)
festa = norm(conversa(940, 1.0) / 6 + multidao(250, 2200, 1.4, 0.15) + multidao(80, 400, 0.8), 0.75)
apoio = norm(palmas(132, 1.0) + multidao(200, 1200, 0.4), 0.7)
for nome, y in [("publico_calmo", calmo), ("publico_festa", festa), ("publico_palmas", apoio)]:
    sf.write(f"{OUT}/{nome}.ogg", y.astype(np.float32), SR, format="OGG", subtype="VORBIS")
    print(nome, round(len(y) / SR, 1), "s")
