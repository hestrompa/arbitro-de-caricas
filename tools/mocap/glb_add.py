"""Junta clips novos do Mixamo ao jogador.glb sem refazer os que já lá estão.
(As fontes dos clips antigos, BVH da CMU e FBX, não estão no repositório; assim não são precisas.)
uso, a partir de uma pasta com ../mh/human.json e ../fbxdump/dump.json (ver LEIA-ME):
    python3 glb_add.py lista.py jogador.glb
lista.py define CLIPS = {nome: (clip_do_dump, t0, t1 ou None, {opções do retarget: loop, inplace, settle})}
Um clip com o mesmo nome é substituído."""
import json, struct, sys, runpy, numpy as np, mx
lista, path = sys.argv[1], sys.argv[2]
CLIPS = runpy.run_path(lista)['CLIPS']
raw = open(path, 'rb').read()
jl = struct.unpack('<I', raw[12:16])[0]
gl = json.loads(raw[20:20 + jl]); bl = struct.unpack('<I', raw[20 + jl:24 + jl])[0]
buf = bytearray(raw[28 + jl:28 + jl + bl])
views, accs = gl['bufferViews'], gl['accessors']
NB = len(gl['skins'][0]['joints'])
j0 = np.array(gl['nodes'][2]['translation'], np.float32)
def add(arr, typ, minmax=False):
    while len(buf) % 4: buf.append(0)
    b = arr.astype(np.float32).tobytes(); views.append({'buffer': 0, 'byteOffset': len(buf), 'byteLength': len(b)}); buf.extend(b)
    a = {'bufferView': len(views) - 1, 'componentType': 5126, 'count': int(arr.shape[0]), 'type': typ}
    if minmax: a['min'] = [float(arr.min())]; a['max'] = [float(arr.max())]
    accs.append(a); return len(accs) - 1
for name, (src, t0, t1, kw) in CLIPS.items():
    kw = dict(kw); settle = kw.pop('settle', False)
    if t1 is None: t1 = mx.length(src) - (1 / 30 if kw.get('loop') else 0.04)
    Q, P = mx.clip(src, t0, t1, settle=settle, **kw)
    Q = np.round(Q * 32767) / 32767; Q = Q / np.linalg.norm(Q, axis=2, keepdims=True); P = np.round(P * 1000) / 1000
    loop = bool(kw.get('loop'))
    if loop: Q = np.concatenate([Q, Q[:1]]); P = np.concatenate([P, P[:1]])
    tm = np.arange(len(Q), dtype=np.float32) / 30
    aT = add(tm, 'SCALAR', True); sm, ch = [], []
    for b in range(NB):
        sm.append({'input': aT, 'output': add(np.ascontiguousarray(Q[:, b]), 'VEC4'), 'interpolation': 'LINEAR'})
        ch.append({'sampler': len(sm) - 1, 'target': {'node': 2 + b, 'path': 'rotation'}})
    sm.append({'input': aT, 'output': add(np.ascontiguousarray(P + j0), 'VEC3'), 'interpolation': 'LINEAR'})
    ch.append({'sampler': len(sm) - 1, 'target': {'node': 2, 'path': 'translation'}})
    full = name + ('_loop' if loop else '')
    gl['animations'] = [a for a in gl['animations'] if a['name'] != full] + [{'name': full, 'samplers': sm, 'channels': ch}]
    print(full, len(Q))
while len(buf) % 4: buf.append(0)
gl['buffers'][0]['byteLength'] = len(buf)
js = json.dumps(gl, separators=(',', ':')).encode()
while len(js) % 4: js += b' '
out = struct.pack('<III', 0x46546C67, 2, 28 + len(js) + len(buf)) + struct.pack('<II', len(js), 0x4E4F534A) + js + struct.pack('<II', len(buf), 0x004E4942) + bytes(buf)
open(path, 'wb').write(out)
print('glb', len(out), 'anims', len(gl['animations']))
