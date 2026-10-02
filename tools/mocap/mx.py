"""Clips do Mixamo (Soccer Game Pack) para o esqueleto do jogo.
O Godot importa os FBX e grava as poses globais (fbxdump/dump.json); aqui junta-se a pose T de repouso
como frame 0 (é a referência que o retarget dos CMU usa) e reaproveita-se retarget.py tal como está."""
import json, numpy as np, retarget as rt

D = json.load(open('../fbxdump/dump.json'))
REN = {'Spine': 'LowerBack', 'Spine1': 'Spine', 'Spine2': 'Spine1', 'Neck': 'Neck1'}
FT = 1 / 30

def q2m(q):
    x, y, z, w = q
    return np.array([[1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)], [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)], [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)]])

def src(name):
    mirror = name.endswith('@m')          # "clip@m": versão espelhada (esquerda <-> direita)
    r = D[name.replace('@m', '')]
    names = [REN.get(n.replace('mixamorig_', ''), n.replace('mixamorig_', '')) for n in r['names']]
    pos = np.array([r['rest_p']] + r['pos'])
    rot = np.array([[q2m(q) for q in r['rest_q']]] + [[q2m(q) for q in f] for f in r['rot']])
    if mirror:
        M = np.diag([-1.0, 1.0, 1.0])
        pos = pos * np.array([-1.0, 1.0, 1.0])
        rot = np.einsum('ij,fbjk,kl->fbil', M, rot, M)
        sw = lambda n: n.replace('Left', '#').replace('Right', 'Left').replace('#', 'Right')
        names = [sw(n) for n in names]
    return {'names': names, 'ft': FT, 'pos': pos, 'rot': rot, 'n': len(r['pos'])}

_cache = {}
def _load(path):
    c = path[:-4]
    if c not in _cache: _cache[c] = src(c)
    return _cache[c]
rt.bvh.load = _load
rt.bvh.fk = lambda b: (b['pos'], b['rot'])

def length(name): return len(D[name.replace('@m', '')]['pos']) * FT

def clip(name, t0, t1, settle=False, **kw):
    """t0, t1 em segundos do clip do Mixamo (o frame 0 do retarget é a pose de repouso)"""
    Q, RP, sc = rt.retarget(name, t0 + FT, t1 + FT, **kw)
    if settle:
        n = len(RP); RP[:, 1] -= RP[0, 1] * (1 - np.arange(n) / (n - 1))
    for f in range(1, len(Q)):
        for i in range(Q.shape[1]):
            if np.dot(Q[f, i], Q[f - 1, i]) < 0: Q[f, i] = -Q[f, i]
    return Q, RP
