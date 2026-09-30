s = open('jogo-base.js').read().split('\n')
new = open('rig3d.js').read().rstrip('\n').split('\n')
assert s[708].startswith('function makeRig'), s[708]
assert s[1017] == '}', s[1017]
assert s[1019].startswith('// ---------- desenho 2D'), s[1019]
s = s[:708] + new + s[1018:]
t = '\n'.join(s)


def rep(a, b, cnt=1):
    global t
    assert t.count(a) == cnt, (a, t.count(a))
    t = t.replace(a, b)


def between(a, b):
    i = t.index(a)
    j = t.index(b, i)
    return t[i:j]


rep("for (let i = 0; i < 22; i++) { const r = makeRig(T);", "for (let i = 0; i < 23; i++) { const r = makeRig(T);")
rep("new T.SphereGeometry(0.22, 18, 14), new T.MeshLambertMaterial({ map: new T.CanvasTexture(ballTex) })",
    "new T.SphereGeometry(0.11, 20, 16), new T.MeshStandardMaterial({ map: new T.CanvasTexture(ballTex), roughness: 0.45 })")
rep("snap: active().map(q => ({ id: q.id, team: q.team, role: q.role, x:", "snap: active().map(q => ({ id: q.id, team: q.team, role: q.role, num: q.num, x:")
rep("decideT: 12, decided: null, cam: null, ideal: false, dur: 1.3,", "decideT: 15, decided: null, cam: null, ideal: false,")
rep("time: 0, speed: 1, replays: 0, decideT: 12, decided: null, cam: null, ideal: false };", "time: 0, speed: 1, replays: 0, decideT: 15, decided: null, cam: null, ideal: false };")
rep(between("  } else if (mode === 'lance' && S.lance && stage.classList.contains('view3d')) {", "let last = performance.now()"), open('step.part').read())
rep("if (L && L.rig) pose3D(L, Math.min(L.time, L.dur || DUR));", "if (L && L.rig) pose3D(L, Math.min(L.time, lanceDur(L)));")
rep(between("function replay() {", "$('viewMine').addEventListener"), open('ctrl.part').read())
rep(between("window.addEventListener('keydown', e => {", "window.addEventListener('keyup'"), open('keys.part').read())
rep("$('replayBtn').disabled = !on || (S.lance && S.lance.replays >= 2);", "$('replayBtn').disabled = !on;")
rep("reviewing.ideal = ideal; reviewing.time = 0; reviewing.cam = null;", "reviewing.ideal = ideal; reviewing.time = 0; reviewing.cam = null; reviewing.paused = false;")
rep("$('viewClose').addEventListener('click', e => { e.stopPropagation(); hide3D(); reviewing = null; });",
    "$('viewClose').addEventListener('click', e => { e.stopPropagation(); hide3D(); reviewing = null; });\n$('viewBtns').addEventListener('pointerdown', e => e.stopPropagation());")
open('game.js', 'w').write(t)
print('ok')
