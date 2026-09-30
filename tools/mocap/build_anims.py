import json, base64, numpy as np, bvh, retarget as rt
def clip(c, t0, t1, settle=False, **kw):
    Q, RP, sc = rt.retarget(c, t0, t1, **kw)
    if settle:   # a queda começa à altura de quem corre, não no ar
        n = len(RP); RP[:, 1] -= RP[0, 1] * (1 - np.arange(n) / (n - 1))
    # sinal contínuo dos quaterniões (para interpolar sem saltos)
    for f in range(1, len(Q)):
        for i in range(Q.shape[1]):
            if np.dot(Q[f, i], Q[f - 1, i]) < 0: Q[f, i] = -Q[f, i]
    q16 = np.round(Q * 32767).astype('<i2').tobytes()
    p16 = np.round(RP * 1000).astype('<i2').tobytes()
    return {'n': len(Q), 'fps': 30, 'loop': bool(kw.get('loop')), 'q': base64.b64encode(q16).decode(), 'p': base64.b64encode(p16).decode()}
def end_heading(c, t_end):
    """rumo em que a cabeça fica apontada no fim da queda (para a queda ir para a frente)"""
    b = bvh.load(c + '.bvh'); pos, rot = bvh.fk(b); N = b['names']; f = int(round(t_end / b['ft']))
    d = pos[f, N.index('Head')] - pos[f, N.index('Hips')]; return np.arctan2(d[0], d[2])
def kick_heading():
    b = bvh.load('10_01.bvh'); pos, rot = bvh.fk(b); N = b['names']; ft = b['ft']; f = int(round(4.975 / ft))
    d = pos[f + 3, N.index('RightToeBase')] - pos[f - 3, N.index('RightToeBase')]; return np.arctan2(d[0], d[2])
A = {}
A['run'] = clip('35_22', 0.55, 1.192, inplace=True, loop=True)
A['jog'] = clip('16_35', 0.142, 0.95, inplace=True, loop=True)
A['idle'] = clip('111_28', 0.3, 3.3, inplace=True, loop=True)
A['dive'] = clip('90_16', 3.35, 4.45, settle=True, fix_h=end_heading('90_16', 4.4))
A['fallback'] = clip('90_18', 0.45, 1.65)
kt = 4.975; A['kick'] = clip('10_01', kt - 0.7, kt + 0.5, fix_h=kick_heading()); A['kick']['key'] = 0.7
json.dump(A, open('anims.json', 'w'))
print({k: v['n'] for k, v in A.items()}, 'bytes', len(open('anims.json').read()))
