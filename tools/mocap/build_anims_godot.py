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
A['getup_front'] = clip('77_16', 1.0, 3.8)
A['getup_back'] = clip('77_18', 1.2, 4.9)
A['pull'] = clip('18_03', 1.3, 2.6)
A['held'] = clip('19_03', 1.3, 2.3)
json.dump(A, open('anims_godot.json', 'w'))
print({k: v['n'] for k, v in A.items()}, 'bytes', len(open('anims_godot.json').read()))

# ---- clips do Mixamo (Soccer Game Pack, descarregado pelo Hugo) ----
import mx
def mclip(name, t0, t1, settle=False, **kw):
    Q, RP = mx.clip(name, t0, t1, settle=settle, **kw)
    q16 = np.round(Q * 32767).astype('<i2').tobytes()
    p16 = np.round(RP * 1000).astype('<i2').tobytes()
    return {'n': len(Q), 'fps': 30, 'loop': bool(kw.get('loop')), 'q': base64.b64encode(q16).decode(), 'p': base64.b64encode(p16).decode()}
L = mx.length
A['tackle'] = mclip('soccer_tackle_2', 0.0, L('soccer_tackle_2') - 0.04)
A['tackle_long'] = mclip('soccer_tackle', 0.0, L('soccer_tackle') - 0.04)
A['trip'] = mclip('soccer_trip', 0.0, L('soccer_trip') - 0.04)
A['lying'] = mclip('fallen_idle', 0.0, L('fallen_idle') - 0.04, loop=True, inplace=True)
A['standup'] = mclip('standing_up', 0.0, L('standing_up') - 0.04)
# corrida lenta e espera de jogador (posição atlética) do Mixamo substituem as do CMU
A['jog'] = mclip('jog_forward', 0.0, L('jog_forward') - 1 / 30, inplace=True, loop=True)
A['idle'] = mclip('offensive_idle', 0.0, 4.0, inplace=True, loop=True)
A['header'] = mclip('soccer_header', 0.0, L('soccer_header') - 0.04)
A['gk_dive'] = mclip('goalkeeper_diving_save', 0.0, L('goalkeeper_diving_save') - 0.04)
A['gk_dive_m'] = mclip('goalkeeper_diving_save@m', 0.0, L('goalkeeper_diving_save') - 0.04)
A['trip_m'] = mclip('soccer_trip@m', 0.0, L('soccer_trip') - 0.04)
A['kick_run'] = mclip('strike_foward_jog', 0.0, L('strike_foward_jog') - 0.04)
A['m_kick'] = mclip('kick_soccerball', 0.0, L('kick_soccerball') - 0.04)
# guarda-redes: apanhar a bola rasteira com as mãos e agarrar uma bola alta (atraso ao guarda-redes)
A['gk_scoop'] = mclip('goalkeeper_scoop', 0.0, L('goalkeeper_scoop') - 0.04)
A['gk_catch'] = mclip('goalkeeper_catch', 0.0, L('goalkeeper_catch') - 0.04)
A['gk_catch2'] = mclip('goalkeeper_catch_2', 0.0, L('goalkeeper_catch_2') - 0.04)
# guarda-redes à espera: meio agachado, braços abertos, a balançar o peso (em vez da espera de jogador de campo)
A['gk_idle'] = mclip('goalkeeper_idle', 0.0, L('goalkeeper_idle') - 1 / 30, inplace=True, loop=True)
json.dump(A, open('anims_godot.json', 'w'))
print('com mixamo', {k: v['n'] for k, v in A.items()})
