# Converte o corpo base do MakeHuman num jogador de futebol compacto para three.js:
# forma masculina atlética, braços caídos, esqueleto reduzido, regiões do equipamento, binário quantizado.
import json, struct, base64, io
import numpy as np
from PIL import Image

D = 'package/public/data/'
d = json.load(open(D + 'models/human_full_size.json'))
V = np.array(d['vertices'], dtype=float).reshape(-1, 3)
UVS = np.array(d['uvs'][0], dtype=float).reshape(-1, 2)
B = d['bones']
names = [b['name'] for b in B]
JP = d['metadata']['joint_pos_idxs']

# ---- forma: homem jovem, atlético
keys = sorted(json.load(open('package/src/json/targets/target-list.json'))['targets'].keys())
mm = np.memmap(D + 'targets/targets.bin', dtype=np.int16, mode='r', shape=(1258, V.size))
def T(n): return np.array(mm[keys.index('data/targets/' + n + '.target')], dtype=float).reshape(-1, 3) / 1000.0
V = V + 0.34 * T('macrodetails/caucasian-male-young') + 0.33 * T('macrodetails/african-male-young') + 0.33 * T('macrodetails/asian-male-young')
V = V + 0.55 * T('macrodetails/universal-male-young-maxmuscle-averageweight') + 0.35 * T('macrodetails/universal-male-young-averagemuscle-minweight')
V = V + 0.5 * T('macrodetails/proportions/male-young-averagemuscle-averageweight-idealproportions')

def joint(n): return V[JP[n]].mean(0)

# ---- faces
f = d['faces']; i = 0; quads = []
while i < len(f):
    t = f[i]; i += 1
    assert t == 11
    vs = f[i:i + 4]; i += 4; m = f[i]; i += 1; uv = f[i:i + 4]; i += 4
    quads.append((vs, m, uv))
mat = [m['DbgName'] for m in d['materials']]
keepm = {'body', 'helper-l-eye', 'helper-r-eye'}
quads = [q for q in quads if mat[q[1]] in keepm]

# ---- esqueleto reduzido
KEEP = ['root', 'spine05', 'spine04', 'spine03', 'spine02', 'spine01', 'neck01', 'head',
        'clavicle.L', 'upperarm01.L', 'lowerarm01.L', 'wrist.L', 'clavicle.R', 'upperarm01.R', 'lowerarm01.R', 'wrist.R',
        'upperleg01.L', 'lowerleg01.L', 'foot.L', 'upperleg01.R', 'lowerleg01.R', 'foot.R']
jidx = {n: names.index(n + '____head') for n in KEEP}
def up(bi):                      # sobe na hierarquia até um osso mantido
    while bi >= 0:
        nm = names[bi]
        base = nm[:-8] if nm.endswith('____head') else nm
        if base in KEEP and nm.endswith('____head'): return KEEP.index(base)
        if base in KEEP and not nm.endswith('____head'): return KEEP.index(base)
        bi = B[bi]['parent']
    return 0
remap = [up(bi) for bi in range(len(B))]
parent = []
for n in KEEP:
    p = B[jidx[n]]['parent']; parent.append(-1 if n == 'root' else up(p))
    if n == 'root': continue
    assert parent[-1] != KEEP.index(n), n
jpos = np.array([joint(n + '____head') for n in KEEP])

SI = np.array(d['skinIndices']).reshape(-1, 4); SW = np.array(d['skinWeights'], dtype=float).reshape(-1, 4)
nv = len(V)
W = np.zeros((nv, len(KEEP)))
for k in range(4):
    for v in range(nv):
        if SW[v, k] > 0: W[v, remap[SI[v, k]]] += SW[v, k]
# osso original dominante (para as regiões do equipamento)
dom = [names[SI[v, np.argmax(SW[v])]].replace('____head', '') for v in range(nv)]

# ---- braços caídos e pernas direitas: skinning offline para a nova pose de repouso
def rotz(a):
    c, s = np.cos(a), np.sin(a); return np.array([[c, -s, 0], [s, c, 0], [0, 0, 1]])
def rotx(a):
    c, s = np.cos(a), np.sin(a); return np.array([[1, 0, 0], [0, c, -s], [0, s, c]])
children = {i: [j for j in range(len(KEEP)) if parent[j] == i] for i in range(len(KEEP))}
def subtree(i):
    out = [i]
    for c in children[i]: out += subtree(c)
    return out
R = [np.eye(3) for _ in KEEP]     # rotação mundo de cada osso
def rot_bone(n, M):
    i = KEEP.index(n)
    for j in subtree(i): R[j] = M @ R[j]
def ang(a, b):
    v = jpos[KEEP.index(b)] - jpos[KEEP.index(a)]; return v
for s in ('L', 'R'):
    v = ang('upperarm01.' + s, 'lowerarm01.' + s)
    a = np.arctan2(v[0], -v[1])                 # ângulo a partir da vertical
    rot_bone('upperarm01.' + s, rotz(-a + (0.1 if s == 'L' else -0.1)))
    # antebraço também a cair na vertical (vem dobrado para a frente)
    va = jpos[KEEP.index('wrist.' + s)] - jpos[KEEP.index('lowerarm01.' + s)]
    va = rotz(-a + (0.1 if s == 'L' else -0.1)) @ va
    rot_bone('lowerarm01.' + s, rotx(np.arctan2(va[2], -va[1])) @ rotz(-np.arctan2(va[0], -va[1]) + (0.05 if s == 'L' else -0.05)))
    v = ang('upperleg01.' + s, 'lowerleg01.' + s)
    a = np.arctan2(v[0], -v[1])
    rot_bone('upperleg01.' + s, rotz(-a))
# posições novas das articulações (cada osso roda à volta da sua articulação, em cadeia)
newj = jpos.copy()
order = subtree(0)
Mw = [None] * len(KEEP)          # transform afim mundo: x' = A x + t
for i in order:
    if parent[i] < 0: Mw[i] = (np.eye(3), np.zeros(3)); continue
    # rotação local = R[i] relativamente ao pai
    A_p, t_p = Mw[parent[i]]
    Rl = R[i] @ np.linalg.inv(R[parent[i]])
    # novo ponto da articulação = transform do pai aplicado à articulação original
    newj[i] = A_p @ jpos[i] + t_p
    A = Rl @ A_p
    t = newj[i] - A @ jpos[i]
    Mw[i] = (A, t)
V2 = np.zeros_like(V)
for b in range(len(KEEP)):
    A, t = Mw[b]
    wb = W[:, b:b + 1]
    if wb.max() == 0: continue
    V2 += wb * (V @ A.T + t)
wsum = W.sum(1, keepdims=True); wsum[wsum == 0] = 1
V2 /= wsum

# ---- escala e chão
used = sorted({v for q in quads for v in q[0]})
body_verts = [v for q in quads if mat[q[1]] == 'body' for v in q[0]]
ymin = V2[body_verts, 1].min(); ymax = V2[body_verts, 1].max()
S = 1.80 / (ymax - ymin)
V2 = (V2 - np.array([0, ymin, 0])) * S
newj = (newj - np.array([0, ymin, 0])) * S

# ---- regiões: 0 pele, 1 camisola, 2 calção, 3 meia, 4 chuteira, 5 cabelo, 6 olho
LEG = ('upperleg', 'lowerleg', 'foot', 'toe', 'pelvis', 'root', 'genital')
ARM = ('upperarm', 'lowerarm', 'wrist', 'finger', 'metacarpal')
kneeY = newj[KEEP.index('lowerleg01.L'), 1]; hipY = newj[KEEP.index('upperleg01.L'), 1]
footY = newj[KEEP.index('foot.L'), 1]; shY = newj[KEEP.index('upperarm01.L'), 1]
def region(v, m):
    if m.startswith('helper'): return 6
    n = dom[v]; y = V2[v, 1]
    if n.startswith(('head', 'jaw', 'neck', 'eye', 'oris', 'levator', 'special', 'temporalis', 'tongue', 'orbicularis', 'oculi', 'risorius')): return 0
    if n.startswith(ARM):
        return 1 if y > shY - 0.2 else 0
    if n.startswith(LEG) or y < hipY - 0.05:
        if y < footY + 0.035 or n.startswith(('foot', 'toe')): return 4
        if y < kneeY - 0.08: return 3
        if y < kneeY + 0.16: return 0
        return 2
    return 1 if y > hipY + 0.11 else 2
HEADB = ('head', 'jaw', 'neck', 'eye', 'oris', 'levator', 'special', 'temporalis', 'tongue', 'orbicularis', 'oculi', 'risorius')
def flags(v, m):
    n = dom[v]; f = 0
    if n.startswith(ARM): f |= 1
    elif n.startswith(LEG) or V2[v, 1] < hipY - 0.05: f |= 2
    if n.startswith(HEADB) and not n.startswith('neck'): f |= 4
    if m.startswith('helper'): f |= 16
    return f
# cabelo: couro cabeludo acima da testa e atrás das orelhas
hj = newj[KEEP.index('head')]
# ---- vértices únicos (posição, uv)
uniq = {}; P = []; UV = []; SK = []; RG = []; FL = []; tris = []
for vs, m, uv in quads:
    idx = []
    for v, u in zip(vs, uv):
        key = (v, u)
        if key not in uniq:
            uniq[key] = len(P); P.append(V2[v]); UV.append(UVS[u]); SK.append(W[v]); RG.append(region(v, mat[m])); FL.append(flags(v, mat[m]))
        idx.append(uniq[key])
    tris += [(idx[0], idx[1], idx[2]), (idx[0], idx[2], idx[3])]
P = np.array(P); UV = np.array(UV); SK = np.array(SK); RG = np.array(RG); FL = np.array(FL); tris = np.array(tris)
# cabelo pela geometria da cabeça
top = P[:, 1].max()
for k in range(len(P)):
    if RG[k] != 0: continue
    x, y, z = P[k]; rel = y - hj[1]
    front = z - hj[2]
    if rel > 0.135 and (front < 0.06 or rel > 0.175): RG[k] = 5
    elif rel > 0.03 and front < -0.02 and abs(x) < 0.085: RG[k] = 5
    elif rel > 0.09 and front < 0.0: RG[k] = 5
FL[RG == 5] |= 8
# normais para inflar o equipamento
N = np.zeros_like(P)
for a, b, c in tris:
    n = np.cross(P[b] - P[a], P[c] - P[a]); N[a] += n; N[b] += n; N[c] += n
# soldar normais em costuras de uv (mesma posição)
posk = {}
for k, p in enumerate(P): posk.setdefault(tuple(np.round(p, 5)), []).append(k)
for ks in posk.values():
    if len(ks) > 1:
        s_ = N[ks].sum(0)
        for k in ks: N[k] = s_
N /= np.linalg.norm(N, axis=1, keepdims=True) + 1e-9
infl = {1: 0.012, 2: 0.024, 3: 0.006, 4: 0.01, 5: 0.004}
for k in range(len(P)):
    P[k] += N[k] * infl.get(RG[k], 0)
# região por triângulo (maioria)
TR = np.array([np.bincount(RG[t], minlength=7).argmax() for t in tris])
order_t = np.argsort(TR, kind='stable'); tris = tris[order_t]; TR = TR[order_t]
groups = []
for r in range(7):
    ix = np.where(TR == r)[0]
    if len(ix): groups.append([int(r), int(ix[0] * 3), int(len(ix) * 3)])

# ---- 4 influências por vértice
SKI = np.zeros((len(P), 4), dtype=np.uint8); SKW = np.zeros((len(P), 4), dtype=np.uint8)
for k in range(len(P)):
    o = np.argsort(-SK[k])[:4]; w = SK[k][o]; w = w / (w.sum() or 1)
    q = np.round(w * 255).astype(int); q[0] += 255 - q.sum()
    SKI[k] = o; SKW[k] = q
print('verts', len(P), 'tris', len(tris), 'groups', groups, 'height', P[:, 1].max())

# ---- binário
Pq = np.round(P * 10000).astype(np.int16)            # 0,1 mm
UVq = np.round(np.clip(UV, 0, 1) * 65535).astype(np.uint16)
buf = io.BytesIO()
buf.write(Pq.tobytes()); buf.write(UVq.tobytes()); buf.write(SKI.tobytes()); buf.write(SKW.tobytes())
buf.write(FL.astype(np.uint8).tobytes()); buf.write(b'\0' * ((-len(FL)) % 2))
buf.write(tris.astype(np.uint16).tobytes())
header = {'cut': {'hip': float(hipY), 'knee': float(kneeY), 'foot': float(footY), 'sh': float(shY)}, 'nv': len(P), 'nt': len(tris), 'groups': groups, 'bones': KEEP, 'parent': parent,
          'joints': [[round(float(c), 5) for c in j] for j in newj]}
json.dump(header, open('human.json', 'w'))
open('human.bin', 'wb').write(buf.getvalue())
print('bin bytes', len(buf.getvalue()))

# ---- texturas de pele (512, jpg)
for name, src in [('light', 'young_caucasian_male/textures/young_lightskinned_male_diffuse.png'),
                  ('dark', 'young_african_male/textures/young_darkskinned_male_diffuse.png'),
                  ('mid', 'young_asian_male/textures/young_lightskinned_male_diffuse3.png'), ('brown', 'middleage_african_male/textures/middleage_darkskinned_male_diffuse.png')]:
    try:
        im = Image.open(D + 'skins/' + src).convert('RGB').resize((512, 512))
        im.save('skin_' + name + '.jpg', quality=82)
        print(name, 'ok')
    except Exception as e:
        print(name, 'fail', e)

# ---- acessórios da cara (proxies do MakeHuman): cabelos, sobrancelhas e olhos.
# Cada vértice do proxy = combinação de 3 vértices do corpo base + desvio; depois a mesma pose e escala do corpo.
PX = [('hair_short02', 'hair/short02'), ('hair_short04', 'hair/short04'), ('hair_short01', 'hair/short01'), ('hair_afro01', 'hair/afro01'),
      ('eyebrows', 'eyebrows/eyebrow001'), ('eyes', 'eyes/Low-Poly'), ('lashes', 'eyelashes/Eyelashes01')]
def skin_pos(X, Wx):
    out = np.zeros_like(X)
    for b in range(len(KEEP)):
        A, t = Mw[b]; wb = Wx[:, b:b + 1]
        if wb.max() == 0: continue
        out += wb * (X @ A.T + t)
    s = Wx.sum(1, keepdims=True); s[s == 0] = 1
    return out / s
prox = {}
for nome, path in PX:
    pd = json.load(open(D + 'proxies/' + path + '/' + path.split('/')[1] + '.json'))
    ref = np.array(pd['ref_vIdxs']); w = np.array(pd['weights'], dtype=float); off = np.array(pd['offsets'], dtype=float)
    X = (V[ref] * w[:, :, None]).sum(1) + off
    Wx = (W[ref] * w[:, :, None]).sum(1)
    X = (skin_pos(X, Wx) - np.array([0, ymin, 0])) * S
    puv = np.array(pd['uvs'][0], dtype=float).reshape(-1, 2)
    f = pd['faces']; i = 0; vv = {}; PP = []; UU = []; WW = []; TT = []
    while i < len(f):
        t = f[i]; i += 1
        n = 4 if t & 1 else 3
        vs = f[i:i + n]; i += n
        if t & 2: i += 1
        us = f[i:i + n] if t & 8 else vs
        if t & 8: i += n
        ix = []
        for v, u in zip(vs, us):
            if (v, u) not in vv:
                vv[(v, u)] = len(PP); PP.append(X[v]); UU.append(puv[u]); WW.append(Wx[v])
            ix.append(vv[(v, u)])
        TT.append((ix[0], ix[1], ix[2]))
        if n == 4: TT.append((ix[0], ix[2], ix[3]))
    WW = np.array(WW); ski = np.argsort(-WW, 1)[:, :4]; skw = np.take_along_axis(WW, ski, 1); skw /= skw.sum(1, keepdims=True) + 1e-9
    prox[nome + '_pos'] = np.array(PP, np.float32); prox[nome + '_uv'] = np.array(UU, np.float32)
    prox[nome + '_ji'] = ski.astype(np.uint16); prox[nome + '_jw'] = skw.astype(np.float32); prox[nome + '_tri'] = np.array(TT, np.uint32)
    tex = pd['materials'][2 if nome == 'eyes' else 0]['mapDiffuse']
    Image.open(D + 'proxies/' + path + '/' + tex).save('rosto_' + nome + '.png')
    print('proxy', nome, len(PP), 'verts', len(TT), 'tris', 'y', round(float(np.array(PP)[:, 1].min()), 3), round(float(np.array(PP)[:, 1].max()), 3))
np.savez('proxies.npz', **prox)
