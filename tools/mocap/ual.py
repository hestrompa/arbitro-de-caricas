"""Clips da Universal Animation Library (Quaternius, CC0) para o esqueleto do jogo.
O t_ualdump.gd lê os GLB e grava as poses globais (dump_ual.json, formato do fbxdump); aqui os nomes dos
ossos passam para os do CMU e reaproveita-se retarget.py tal como está, como no mx.py."""
import json, os, numpy as np, retarget as rt

D = json.load(open(os.environ.get('UAL_DUMP', '../quat/dump_ual.json')))
REN = {'pelvis': 'Hips', 'spine_01': 'LowerBack', 'spine_02': 'Spine', 'spine_03': 'Spine1', 'neck_01': 'Neck1', 'Head': 'Head'}
for s, S in (('l', 'Left'), ('r', 'Right')):
    REN.update({'clavicle_' + s: S + 'Shoulder', 'upperarm_' + s: S + 'Arm', 'lowerarm_' + s: S + 'ForeArm', 'hand_' + s: S + 'Hand',
                'thigh_' + s: S + 'UpLeg', 'calf_' + s: S + 'Leg', 'foot_' + s: S + 'Foot', 'ball_' + s: S + 'ToeBase'})
FT = 1 / 30

def q2m(q):
    x, y, z, w = q
    return np.array([[1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)], [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)], [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)]])

def src(name):
    mirror = name.endswith('@m')
    r = D[name.replace('@m', '')]
    names = [REN.get(n, n) for n in r['names']]
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

def length(name): return (len(D[name.replace('@m', '')]['pos']) - 1) * FT

def clip(name, t0, t1, settle=False, **kw):
    Q, RP, sc = rt.retarget(name, t0 + FT, t1 + FT, **kw)
    if settle:
        n = len(RP); RP[:, 1] -= RP[0, 1] * (1 - np.arange(n) / (n - 1))
    for f in range(1, len(Q)):
        for i in range(Q.shape[1]):
            if np.dot(Q[f, i], Q[f - 1, i]) < 0: Q[f, i] = -Q[f, i]
    return Q, RP
