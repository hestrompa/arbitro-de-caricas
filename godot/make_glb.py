# Converte o corpo MakeHuman (human.json/bin) e as animações CMU (anims.json) num jogador.glb para o Godot.
# Malha com pele (22 ossos), UV da pele, cor por vértice = partes do corpo, UV2 = posição de repouso (x, y) para pintar o equipamento.
import base64, json, struct, sys
import numpy as np

MH, AN, OUT = sys.argv[1], sys.argv[2], sys.argv[3]
h = json.load(open(MH + '/human.json'))
raw = open(MH + '/human.bin', 'rb').read()
nv, nt = h['nv'], h['nt']
o = 0
pos = np.frombuffer(raw, np.int16, nv * 3, o).reshape(-1, 3).astype(np.float32) / 10000; o += nv * 6
uv = np.frombuffer(raw, np.uint16, nv * 2, o).reshape(-1, 2).astype(np.float32) / 65535; o += nv * 4
ski = np.frombuffer(raw, np.uint8, nv * 4, o).reshape(-1, 4).astype(np.uint16); o += nv * 4
skw = np.frombuffer(raw, np.uint8, nv * 4, o).reshape(-1, 4).astype(np.float32) / 255; o += nv * 4
fl = np.frombuffer(raw, np.uint8, nv, o); o += nv + (nv % 2)
idx = np.frombuffer(raw, np.uint16, nt * 3, o).astype(np.uint32)
skw = skw / np.maximum(skw.sum(1, keepdims=True), 1e-6)
col = np.zeros((nv, 4), np.float32)
col[:, 0] = (fl & 1) > 0; col[:, 1] = (fl & 2) > 0; col[:, 2] = (fl & 4) > 0
col[:, 3] = np.where((fl & 16) > 0, 1.0, np.where((fl & 8) > 0, 0.5, 0.0))
uv2 = pos[:, :2].copy()

# normais suaves
nrm = np.zeros_like(pos)
tri = idx.reshape(-1, 3)
fn = np.cross(pos[tri[:, 1]] - pos[tri[:, 0]], pos[tri[:, 2]] - pos[tri[:, 0]])
for k in range(3): np.add.at(nrm, tri[:, k], fn)
nrm /= np.maximum(np.linalg.norm(nrm, axis=1, keepdims=True), 1e-9)

bones, parent, joints = h['bones'], h['parent'], np.array(h['joints'], np.float32)
NB = len(bones)
A = json.load(open(AN))

buf = bytearray(); views = []; accs = []
def add(arr, comp, typ, target=None, minmax=False):
    global buf
    while len(buf) % 4: buf += b'\0'
    b = arr.tobytes(); off = len(buf); buf += b
    v = {'buffer': 0, 'byteOffset': off, 'byteLength': len(b)}
    if target: v['target'] = target
    views.append(v)
    a = {'bufferView': len(views) - 1, 'componentType': comp, 'count': int(arr.shape[0]), 'type': typ}
    if minmax:
        a['min'] = [float(x) for x in arr.reshape(arr.shape[0], -1).min(0)]; a['max'] = [float(x) for x in arr.reshape(arr.shape[0], -1).max(0)]
    accs.append(a); return len(accs) - 1
F, U16, U32 = 5126, 5123, 5125
aP = add(pos, F, 'VEC3', 34962, True); aN = add(nrm, F, 'VEC3', 34962); aT = add(uv, F, 'VEC2', 34962); aT2 = add(uv2, F, 'VEC2', 34962)
aC = add(col, F, 'VEC4', 34962); aJ = add(ski, U16, 'VEC4', 34962); aW = add(skw, F, 'VEC4', 34962); aI = add(idx, U32, 'SCALAR', 34963)
# nós: 0 = Jogador, 1 = malha, 2.. = ossos
nodes = [{'name': 'Jogador', 'children': [1, 2]}, {'name': 'Corpo', 'mesh': 0, 'skin': 0}]
for i, n in enumerate(bones):
    p = parent[i]; t = joints[i] - (joints[p] if p >= 0 else 0)
    nodes.append({'name': n.replace('.', '_'), 'translation': [float(x) for x in t], 'children': [2 + j for j in range(NB) if parent[j] == i]})
ibm = np.zeros((NB, 16), np.float32)
for i in range(NB):
    m = np.eye(4, dtype=np.float32); m[:3, 3] = -joints[i]; ibm[i] = m.T.reshape(-1)
aIBM = add(ibm, F, 'MAT4')
anims = []
for name, a in A.items():
    q = np.frombuffer(base64.b64decode(a['q']), np.int16).astype(np.float32).reshape(a['n'], NB, 4) / 32767
    q /= np.linalg.norm(q, axis=2, keepdims=True)
    p = np.frombuffer(base64.b64decode(a['p']), np.int16).astype(np.float32).reshape(a['n'], 3) / 1000
    n = a['n'] + (1 if a['loop'] else 0)
    if a['loop']: q = np.concatenate([q, q[:1]]); p = np.concatenate([p, p[:1]])
    tm = (np.arange(n, dtype=np.float32) / a['fps'])
    aTm = add(tm, F, 'SCALAR', minmax=True)
    samplers, chans = [], []
    for b in range(NB):
        samplers.append({'input': aTm, 'output': add(np.ascontiguousarray(q[:, b]), F, 'VEC4'), 'interpolation': 'LINEAR'})
        chans.append({'sampler': len(samplers) - 1, 'target': {'node': 2 + b, 'path': 'rotation'}})
    samplers.append({'input': aTm, 'output': add(np.ascontiguousarray(p + joints[0]), F, 'VEC3'), 'interpolation': 'LINEAR'})
    chans.append({'sampler': len(samplers) - 1, 'target': {'node': 2, 'path': 'translation'}})
    anims.append({'name': name + ('_loop' if a['loop'] else ''), 'samplers': samplers, 'channels': chans})
gl = {'asset': {'version': '2.0', 'generator': 'arbitro make_glb'}, 'scene': 0, 'scenes': [{'nodes': [0]}], 'nodes': nodes,
      'meshes': [{'name': 'corpo', 'primitives': [{'attributes': {'POSITION': aP, 'NORMAL': aN, 'TEXCOORD_0': aT, 'TEXCOORD_1': aT2, 'COLOR_0': aC, 'JOINTS_0': aJ, 'WEIGHTS_0': aW}, 'indices': aI, 'material': 0}]}],
      'materials': [{'name': 'kit', 'pbrMetallicRoughness': {'baseColorFactor': [1, 1, 1, 1], 'metallicFactor': 0, 'roughnessFactor': 0.7}}],
      'skins': [{'joints': [2 + i for i in range(NB)], 'inverseBindMatrices': aIBM, 'skeleton': 2}], 'animations': anims,
      'buffers': [{'byteLength': len(buf)}], 'bufferViews': views, 'accessors': accs}
js = json.dumps(gl, separators=(',', ':')).encode()
while len(js) % 4: js += b' '
while len(buf) % 4: buf += b'\0'
out = struct.pack('<III', 0x46546C67, 2, 12 + 8 + len(js) + 8 + len(buf)) + struct.pack('<II', len(js), 0x4E4F534A) + js + struct.pack('<II', len(buf), 0x004E4942) + bytes(buf)
open(OUT, 'wb').write(out)
print('glb', len(out), 'verts', nv, 'tris', nt, 'anims', [x['name'] for x in anims])
