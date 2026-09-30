import numpy as np, re

def rotm(axis, deg):
    a = np.radians(deg); c, s = np.cos(a), np.sin(a)
    if axis == 'X': return np.array([[1, 0, 0], [0, c, -s], [0, s, c]])
    if axis == 'Y': return np.array([[c, 0, s], [0, 1, 0], [-s, 0, c]])
    return np.array([[c, -s, 0], [s, c, 0], [0, 0, 1]])

def load(path):
    txt = open(path).read()
    head, mot = txt.split('MOTION')
    names, parents, offsets, chans = [], [], [], []
    stack = []
    toks = head.split('\n')
    cur = None
    for line in toks:
        l = line.strip()
        if l.startswith('ROOT') or l.startswith('JOINT'):
            names.append(l.split()[1]); parents.append(stack[-1] if stack else -1); offsets.append(None); chans.append([]); cur = len(names) - 1
        elif l.startswith('End Site'):
            names.append(names[stack[-1]] + '_end'); parents.append(stack[-1]); offsets.append(None); chans.append([]); cur = len(names) - 1
        elif l == '{':
            stack.append(cur)
        elif l == '}':
            stack.pop()
        elif l.startswith('OFFSET'):
            offsets[cur] = np.array([float(x) for x in l.split()[1:4]])
        elif l.startswith('CHANNELS'):
            chans[cur] = l.split()[2:]
    ml = mot.strip().split('\n')
    n = int(ml[0].split()[1]); ft = float(ml[1].split()[2])
    data = np.array([[float(x) for x in r.split()] for r in ml[2:2 + n]])
    return dict(names=names, parents=parents, offsets=np.array(offsets), chans=chans, data=data, ft=ft)

def fk(b):
    """posições e rotações globais por frame"""
    names, par, off, chans, data = b['names'], b['parents'], b['offsets'], b['chans'], b['data']
    F, J = len(data), len(names)
    pos = np.zeros((F, J, 3)); rot = np.zeros((F, J, 3, 3))
    for f in range(F):
        c = 0; row = data[f]
        for j in range(J):
            R = np.eye(3); t = off[j].copy()
            for ch in chans[j]:
                v = row[c]; c += 1
                if ch.endswith('position'): t['XYZ'.index(ch[0])] = v
                else: R = R @ rotm(ch[0], v)
            p = par[j]
            if p < 0: rot[f, j] = R; pos[f, j] = t
            else: rot[f, j] = rot[f, p] @ R; pos[f, j] = pos[f, p] + rot[f, p] @ t
    return pos, rot
