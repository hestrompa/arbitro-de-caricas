"""Retarget de clips CMU (BVH do cgspeed) para o esqueleto MakeHuman do jogo.
Cada osso do jogo recebe a rotação global do segmento CMU correspondente, relativa à pose T do ficheiro,
e depois um ajuste de direção para o membro apontar exatamente para onde aponta na captura."""
import json, numpy as np, bvh

H = json.load(open('../mh/human.json'))
BONES, PAR, JO = H['bones'], H['parent'], np.array(H['joints'])
CH = {i: [j for j, p in enumerate(PAR) if p == i] for i in range(len(BONES))}

def rz(deg):
    return bvh.rotm('Z', deg)

# osso do jogo -> (juntas CMU a misturar, peso da segunda, correção da pose de repouso)
SRC = {
    'root': ('Hips', None, 0, None),
    'spine05': ('LowerBack', None, 0, None), 'spine04': ('LowerBack', 'Spine', .5, None), 'spine03': ('Spine', None, 0, None),
    'spine02': ('Spine', 'Spine1', .5, None), 'spine01': ('Spine1', None, 0, None),
    'neck01': ('Neck1', None, 0, None), 'head': ('Head', None, 0, None),
    'clavicle.L': ('LeftShoulder', None, 0, None), 'upperarm01.L': ('LeftArm', None, 0, rz(90)), 'lowerarm01.L': ('LeftForeArm', None, 0, rz(90)), 'wrist.L': ('LeftHand', None, 0, rz(90)),
    'clavicle.R': ('RightShoulder', None, 0, None), 'upperarm01.R': ('RightArm', None, 0, rz(-90)), 'lowerarm01.R': ('RightForeArm', None, 0, rz(-90)), 'wrist.R': ('RightHand', None, 0, rz(-90)),
    'upperleg01.L': ('LeftUpLeg', None, 0, None), 'lowerleg01.L': ('LeftLeg', None, 0, None), 'foot.L': ('LeftFoot', None, 0, None),
    'upperleg01.R': ('RightUpLeg', None, 0, None), 'lowerleg01.R': ('RightLeg', None, 0, None), 'foot.R': ('RightFoot', None, 0, None),
}
# membros com direção acertada: osso do jogo -> (junta CMU de início, junta CMU de fim, vetor de repouso no jogo)
AIM = {
    'upperleg01.L': ('LeftUpLeg', 'LeftLeg'), 'lowerleg01.L': ('LeftLeg', 'LeftFoot'), 'foot.L': ('LeftFoot', 'LeftToeBase'),
    'upperleg01.R': ('RightUpLeg', 'RightLeg'), 'lowerleg01.R': ('RightLeg', 'RightFoot'), 'foot.R': ('RightFoot', 'RightToeBase'),
    'upperarm01.L': ('LeftArm', 'LeftForeArm'), 'lowerarm01.L': ('LeftForeArm', 'LeftHand'),
    'upperarm01.R': ('RightArm', 'RightForeArm'), 'lowerarm01.R': ('RightForeArm', 'RightHand'),
}
def rest_dir(b):
    i = BONES.index(b)
    if b.startswith('foot'): return np.array([0, -0.35, 1.0]) / np.linalg.norm([0, -0.35, 1.0])
    c = CH[i][0]; d = JO[c] - JO[i]; return d / np.linalg.norm(d)

def m2q(m):
    t = np.trace(m)
    if t > 0:
        s = np.sqrt(t + 1) * 2; return np.array([(m[2, 1] - m[1, 2]) / s, (m[0, 2] - m[2, 0]) / s, (m[1, 0] - m[0, 1]) / s, s / 4])
    i = np.argmax([m[0, 0], m[1, 1], m[2, 2]])
    if i == 0:
        s = np.sqrt(1 + m[0, 0] - m[1, 1] - m[2, 2]) * 2; return np.array([s / 4, (m[0, 1] + m[1, 0]) / s, (m[0, 2] + m[2, 0]) / s, (m[2, 1] - m[1, 2]) / s])
    if i == 1:
        s = np.sqrt(1 + m[1, 1] - m[0, 0] - m[2, 2]) * 2; return np.array([(m[0, 1] + m[1, 0]) / s, s / 4, (m[1, 2] + m[2, 1]) / s, (m[0, 2] - m[2, 0]) / s])
    s = np.sqrt(1 + m[2, 2] - m[0, 0] - m[1, 1]) * 2; return np.array([(m[0, 2] + m[2, 0]) / s, (m[1, 2] + m[2, 1]) / s, s / 4, (m[1, 0] - m[0, 1]) / s])
def q2m(q):
    x, y, z, w = q
    return np.array([[1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)], [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)], [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)]])
def slerpm(a, b, k):
    qa, qb = m2q(a), m2q(b)
    if np.dot(qa, qb) < 0: qb = -qb
    q = qa * (1 - k) + qb * k; return q2m(q / np.linalg.norm(q))
def swing(a, b):
    """rotação mínima que leva o vetor a ao vetor b"""
    a = a / np.linalg.norm(a); b = b / np.linalg.norm(b); v = np.cross(a, b); c = np.dot(a, b)
    if c < -0.9999: return rz(180)
    K = np.array([[0, -v[2], v[1]], [v[2], 0, -v[0]], [-v[1], v[0], 0]])
    return np.eye(3) + K + K @ K / (1 + c)
def roty(a):
    return bvh.rotm('Y', np.degrees(a))

def retarget(c, t0, t1, fps=30, head_ref=None, inplace=False, ref_t=None, loop=False, fix_h=None):
    b = bvh.load(c + '.bvh'); pos, rot = bvh.fk(b); N = b['names']; ix = N.index; ft = b['ft']
    leg_m = np.linalg.norm(pos[0, ix('LeftUpLeg')] - pos[0, ix('LeftLeg')]) + np.linalg.norm(pos[0, ix('LeftLeg')] - pos[0, ix('LeftFoot')])
    leg_g = np.linalg.norm(JO[BONES.index('upperleg01.L')] - JO[BONES.index('lowerleg01.L')]) + np.linalg.norm(JO[BONES.index('lowerleg01.L')] - JO[BONES.index('foot.L')])
    sc = leg_g / leg_m
    hip0 = pos[0, ix('Hips')]
    times = np.arange(t0, t1 - 1e-6, (t1 - t0) / round((t1 - t0) * fps)) if loop else np.arange(t0, t1 + 1e-6, 1 / fps)
    # direção do corpo: a bacia a apontar para +z no instante de referência
    def heading(f):
        z = (rot[f, ix('Hips')] @ np.linalg.inv(rot[0, ix('Hips')]))[:, 2]; return np.arctan2(z[0], z[2])
    fr = lambda t: int(round(t / ft))
    if fix_h is not None:
        h0 = fix_h
    elif inplace:
        hs = [heading(fr(t)) for t in times]; h0 = np.arctan2(np.mean(np.sin(hs)), np.mean(np.cos(hs)))
    else:
        h0 = heading(fr(ref_t if ref_t is not None else t0))
    Hn = roty(-h0)
    out_q, out_p = [], []
    p_start = Hn @ (pos[fr(times[0]), ix('Hips')] * sc)
    p_end = Hn @ (pos[fr(t1 if loop else times[-1]), ix('Hips')] * sc)
    for k, t in enumerate(times):
        f = fr(t)
        D = lambda j: rot[f, ix(j)] @ np.linalg.inv(rot[0, ix(j)])
        Wd = {}
        for bn, (j1, j2, w, C) in SRC.items():
            m = D(j1) if not j2 else slerpm(D(j1), D(j2), w)
            if C is not None: m = m @ C
            Wd[bn] = Hn @ m
        for bn, (ja, jb) in AIM.items():
            tgt = Hn @ (pos[f, ix(jb)] - pos[f, ix(ja)])
            Wd[bn] = swing(Wd[bn] @ rest_dir(bn), tgt) @ Wd[bn]
        qs = []
        for i, bn in enumerate(BONES):
            p = PAR[i]; loc = Wd[bn] if p < 0 else np.linalg.inv(Wd[BONES[p]]) @ Wd[bn]
            q = m2q(loc); qs.append(q / np.linalg.norm(q))
        hp = Hn @ (pos[f, ix('Hips')] * sc)
        if inplace:   # tira o avanço médio, deixa o balanço
            u = k / (len(times) if loop else max(1, len(times) - 1)); drift = p_start + (p_end - p_start) * u
            rp = [hp[0] - drift[0], (pos[f, ix('Hips')][1] - hip0[1]) * sc, hp[2] - drift[2]]
        else:
            rp = [hp[0] - p_start[0], (pos[f, ix('Hips')][1] - hip0[1]) * sc, hp[2] - p_start[2]]
        # a pose T do cgspeed nem sempre tem a bacia à altura de pé: acerta pela altura parada
        out_q.append(qs); out_p.append(rp)
    return np.array(out_q), np.array(out_p), sc
