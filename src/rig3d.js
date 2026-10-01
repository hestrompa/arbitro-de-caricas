// jogador: corpo humano do MakeHuman (CC0) com esqueleto; as poses do jogo rodam os ossos
const SKINS = ['light', 'mid', 'brown', 'dark'];
const HAIR = ['#161310', '#2a1a10', '#4a2f1a', '#6b4a2b', '#b08850', '#1b1b1b', '#8a3b1c'];
const BOOTS = ['#141414', '#141414', '#f4f4f4', '#d8f23a', '#ff5a2c', '#2a7dff', '#e8e8e8'];
function lookOf(id) {
  let s = ((id + 7) * 2654435761) % 4294967296;
  const r = () => (s = (s * 1664525 + 1013904223) % 4294967296) / 4294967296;
  return { skin: SKINS[Math.floor(r() * SKINS.length)], hair: HAIR[Math.floor(r() * HAIR.length)], bald: r() < 0.12,
    boot: BOOTS[Math.floor(r() * BOOTS.length)], h: 0.95 + r() * 0.08 };
}
let HUMAN_GEO = null, BOOTG = null;
function BOOT_GEO(T) {
  if (BOOTG) return BOOTG;
  const up = new T.SphereGeometry(1, 18, 12); up.scale(0.052, 0.045, 0.14);
  const sole = new T.BoxGeometry(0.098, 0.014, 0.27);
  BOOTG = { up, sole }; return BOOTG;
}
function humanGeo(T) {
  if (HUMAN_GEO) return HUMAN_GEO;
  const H = window.HUMAN, hd = H.h;
  const raw = Uint8Array.from(atob(H.bin), c => c.charCodeAt(0)).buffer;
  let o = 0;
  const pos16 = new Int16Array(raw, o, hd.nv * 3); o += hd.nv * 6;
  const uv16 = new Uint16Array(raw, o, hd.nv * 2); o += hd.nv * 4;
  const ski = new Uint8Array(raw, o, hd.nv * 4); o += hd.nv * 4;
  const skw = new Uint8Array(raw, o, hd.nv * 4); o += hd.nv * 4;
  const fl = new Uint8Array(raw, o, hd.nv); o += hd.nv + (hd.nv % 2);
  const idx = new Uint16Array(raw.slice(o, o + hd.nt * 6));
  const pos = new Float32Array(hd.nv * 3); for (let i = 0; i < pos.length; i++) pos[i] = pos16[i] / 10000;
  const g = new T.BufferGeometry();
  g.setAttribute('position', new T.BufferAttribute(pos, 3));
  g.setAttribute('uv', new T.BufferAttribute(new Uint16Array(uv16), 2, true));
  g.setAttribute('skinIndex', new T.BufferAttribute(new Uint16Array(ski), 4));
  g.setAttribute('skinWeight', new T.BufferAttribute(new Float32Array(Array.from(skw, v => v / 255)), 4));
  g.setIndex(new T.BufferAttribute(idx, 1));
  // partes do corpo por vértice: braço, perna, cabeça, cabelo, olho (o equipamento é pintado no shader por altura)
  const kit = new Float32Array(hd.nv * 4), kit2 = new Float32Array(hd.nv * 2);
  for (let i = 0; i < hd.nv; i++) { const f = fl[i]; kit[i * 4] = f & 1 ? 1 : 0; kit[i * 4 + 1] = f & 2 ? 1 : 0; kit[i * 4 + 2] = f & 4 ? 1 : 0; kit[i * 4 + 3] = f & 8 ? 1 : 0; kit2[i * 2] = f & 16 ? 1 : 0; }
  g.setAttribute('kit', new T.BufferAttribute(kit, 4));
  g.setAttribute('kit2', new T.BufferAttribute(kit2, 2));
  g.computeVertexNormals();
  g.computeBoundingSphere(); g.boundingSphere.radius = 2.5;
  const tex = {};
  for (const k of SKINS) {
    const im = new Image(); const t = new T.Texture(im); im.onload = () => { t.needsUpdate = true; }; im.src = H.skins[k];
    tex[k] = t;
  }
  HUMAN_GEO = { g, hd, tex };
  return HUMAN_GEO;
}

function makeRig(T) {
  const { g, hd, tex } = humanGeo(T);
  const outer = new T.Group(), body = new T.Group(); outer.add(body);
  const std = (c, rough) => new T.MeshStandardMaterial({ color: c, roughness: rough, metalness: 0, skinning: true });
  const boot = std('#141414', 0.35);
  const U = { uShirt: { value: new T.Color('#3569dc') }, uShorts: { value: new T.Color('#f1f1f1') }, uSock: { value: new T.Color('#1d3f8f') }, uHair: { value: new T.Color('#2a1a10') },
    uCut: { value: new T.Vector4(hd.cut.hip, hd.cut.knee, hd.cut.foot, hd.cut.sh) }, uBald: { value: 0 },
    uShirt2: { value: new T.Color('#f2f2f2') }, uTrim: { value: new T.Color('#1d3f8f') }, uPat: { value: 0 } };
  const skin = new T.MeshStandardMaterial({ map: tex.light, roughness: 0.66, metalness: 0, skinning: true });
  skin.onBeforeCompile = sh => {
    Object.assign(sh.uniforms, U);
    sh.vertexShader = 'attribute vec4 kit;\nattribute vec2 kit2;\nvarying vec4 vKit;\nvarying vec2 vKit2;\nvarying float vRestY;\nvarying vec2 vRXZ;\n' +
      sh.vertexShader.replace('#include <begin_vertex>', '#include <begin_vertex>\nvKit = kit; vKit2 = kit2; vRestY = position.y; vRXZ = position.xz;');
    sh.fragmentShader = 'uniform vec3 uShirt, uShorts, uSock, uHair, uShirt2, uTrim;\nuniform vec4 uCut;\nuniform float uBald, uPat;\nvarying vec2 vRXZ;\nvarying vec4 vKit;\nvarying vec2 vKit2;\nvarying float vRestY;\n' +
      sh.fragmentShader.replace('#include <map_fragment>', `#include <map_fragment>
      {
        float y = vRestY; vec3 c = diffuseColor.rgb; float cloth = 0.0; float x = vRXZ.x;
        vec3 shirtC = uShirt;
        if (uPat > 0.5 && uPat < 1.5 && fract((x + 0.5) * 8.0) > 0.5) shirtC = uShirt2;
        if (uPat > 1.5 && uPat < 2.5 && fract(y * 7.0) > 0.5) shirtC = uShirt2;
        if (uPat > 2.5 && uPat < 3.5 && abs(x * 0.95 - (y - 1.27)) < 0.06) shirtC = uShirt2;
        if (uPat > 3.5 && uPat < 4.5 && x > 0.0) shirtC = uShirt2;
        if (vKit2.x > 0.5) { c = vec3(0.07, 0.05, 0.04); }
        else if (vKit.w > 0.5 && uBald < 0.5) { c = uHair * (0.8 + 0.4 * diffuseColor.g); }
        else if (vKit.z > 0.5) { }
        else if (vKit.x > 0.5) { if (y > uCut.w - 0.2) { c = uPat > 4.5 ? uShirt2 : (uPat > 3.5 && x < 0.0 ? uShirt : (uPat > 3.5 ? uShirt2 : uShirt)); if (y < uCut.w - 0.175) c = uTrim; cloth = 1.0; } }
        else if (vKit.y > 0.5) {
          if (y < uCut.z + 0.035) discard;
          else if (y < uCut.y - 0.08) { c = y > uCut.y - 0.115 ? uTrim : uSock; cloth = 1.0; }
          else if (y < uCut.y + 0.16) { }
          else { c = abs(abs(x) - 0.135) < 0.012 && abs(x) > 0.1 ? uTrim : uShorts; cloth = 1.0; }
        } else if (y > uCut.w + 0.085) { } else { c = y > uCut.x + 0.11 ? (y > uCut.w + 0.06 ? uTrim : shirtC) : uShorts; cloth = 1.0; }
        diffuseColor.rgb = c;
      }`);
  };
  skin.customProgramCacheKey = () => 'kit';
  // esqueleto
  const bones = hd.bones.map(() => new T.Bone());
  hd.bones.forEach((n, i) => {
    const p = hd.parent[i], j = hd.joints[i], pj = p >= 0 ? hd.joints[p] : [0, 0, 0];
    bones[i].name = n; bones[i].position.set(j[0] - pj[0], j[1] - pj[1], j[2] - pj[2]);
    if (p >= 0) bones[p].add(bones[i]);
  });
  const mesh = new T.SkinnedMesh(g, skin);
  mesh.add(bones[0]); mesh.castShadow = true; mesh.frustumCulled = false;
  body.add(mesh);
  mesh.updateMatrixWorld(true);
  mesh.bind(new T.Skeleton(bones));
  const B = n => bones[hd.bones.indexOf(n)];
  // marcadores nas partes do corpo que contam para o fora de jogo (braços excluídos)
  const scoring = [];
  const mark = (bone, x, y, z) => { const m = new T.Object3D(); m.position.set(x, y, z); bone.add(m); scoring.push(m); return m; };
  mark(B('head'), 0, 0.13, 0.1); mark(B('head'), 0, 0.2, -0.02); mark(B('head'), 0, 0.12, -0.11); mark(B('head'), 0, 0.02, 0.11);
  mark(B('spine01'), 0, 0.05, 0.13); mark(B('spine01'), 0, 0.05, -0.12); mark(B('spine03'), 0, 0, 0.12); mark(B('spine03'), 0, 0, -0.12);
  mark(B('root'), 0, -0.05, 0.12); mark(B('root'), 0, -0.08, -0.14);
  for (const s of ['L', 'R']) {
    const sx = s === 'L' ? 1 : -1;
    mark(B('clavicle.' + s), sx * 0.17, 0.02, 0);
    mark(B('upperleg01.' + s), 0, -0.2, 0.08); mark(B('upperleg01.' + s), 0, -0.2, -0.09);
    mark(B('lowerleg01.' + s), 0, 0, 0.07); mark(B('lowerleg01.' + s), 0, -0.2, 0.06); mark(B('lowerleg01.' + s), 0, -0.15, -0.08);
    mark(B('foot.' + s), 0, -0.06, 0.2); mark(B('foot.' + s), 0, -0.06, -0.07);
  }
  const bootL = new T.Object3D(); bootL.position.set(0, -0.06, 0.06); B('foot.R').add(bootL);
  const bootR = new T.Object3D(); bootR.position.set(0, -0.06, 0.06); B('foot.L').add(bootR);
  // chuteiras: gáspea arredondada e sola
  for (const f of [B('foot.L'), B('foot.R')]) {
    const up = new T.Mesh(BOOT_GEO(T).up, boot); up.position.set(0, -0.035, 0.05); up.castShadow = true; f.add(up);
    const so = new T.Mesh(BOOT_GEO(T).sole, boot); so.position.set(0, -0.07, 0.05); f.add(so);
  }
  // número nas costas
  const numCv = document.createElement('canvas'); numCv.width = 256; numCv.height = 224;
  const numTex = new T.CanvasTexture(numCv);
  const numMesh = new T.Mesh(new T.PlaneGeometry(0.27, 0.236), new T.MeshStandardMaterial({ map: numTex, transparent: true, roughness: 0.7, polygonOffset: true, polygonOffsetFactor: -4 }));
  const sp = B('spine02'); numMesh.position.set(0, 0.05, -0.135); numMesh.rotation.y = Math.PI; sp.add(numMesh);
  const crCv = document.createElement('canvas'); crCv.width = crCv.height = 64;
  const crTex = new T.CanvasTexture(crCv);
  const crMesh = new T.Mesh(new T.PlaneGeometry(0.065, 0.065), new T.MeshStandardMaterial({ map: crTex, transparent: true, roughness: 0.6, polygonOffset: true, polygonOffsetFactor: -4 }));
  crMesh.position.set(0.075, 0.13, 0.125); crMesh.rotation.y = 0.18; sp.add(crMesh);
  return { crCv, crTex, crMesh, outer, body, mesh, bones, head: B('head'), neck: B('neck01'), spine: B('spine03'),
    hipL: B('upperleg01.R'), kneeL: B('lowerleg01.R'), ankleL: B('foot.R'), bootL,
    hipR: B('upperleg01.L'), kneeR: B('lowerleg01.L'), ankleR: B('foot.L'), bootR,
    armL: B('upperarm01.R'), elL: B('lowerarm01.R'), armR: B('upperarm01.L'), elR: B('lowerarm01.L'),
    skin, boot, U, numCv, numTex, numMesh, scoring, num: null, tex };
}
function styleRig(r, team, role, num, id) {
  const lk = lookOf(team < 0 ? 97 : id), U = r.U;
  r.skin.map = r.tex[lk.skin];
  U.uHair.value.set(lk.hair); U.uBald.value = lk.bald ? 1 : 0;
  r.boot.color.set(team < 0 ? '#141414' : lk.boot);
  r.outer.scale.setScalar(lk.h);
  if (team < 0) { const dark = TEAMS.some(t => hexDist(t.color, '#17181c') < 120), rc = dark ? '#e9d23a' : '#17181c'; U.uShirt.value.set(rc); U.uShorts.value.set('#17181c'); U.uSock.value.set(rc); U.uTrim.value.set('#17181c'); U.uPat.value = 0; r.numMesh.visible = false; r.crMesh.visible = false; return; }
  const t = TEAMS[team], gk = role === 'gk';
  U.uShirt.value.set(gk ? t.gk : t.color); U.uShorts.value.set(t.shorts); U.uSock.value.set(gk ? t.gk : t.sock);
  const K = kitStyle(t); U.uPat.value = gk ? 0 : K.pat; U.uShirt2.value.set(K.c2); U.uTrim.value.set(gk ? '#1b1b1b' : K.trim);
  r.numMesh.visible = true; r.crMesh.visible = true;
  const pl = typeof S !== 'undefined' && S && S.players && S.players[id] && S.players[id].num === num ? S.players[id] : null, nm = pl && pl.short ? pl.short.toUpperCase() : '';
  const key = team + ':' + role + ':' + num + ':' + nm + ':' + t.name;
  if (r.num !== key) {
    r.num = key;
    const gx = r.numCv.getContext('2d'); gx.clearRect(0, 0, 256, 224);
    const ink = K.ink;
    gx.textAlign = 'center'; gx.textBaseline = 'middle';
    if (nm) { gx.font = '600 34px "Barlow Condensed", "Arial Narrow", sans-serif'; gx.fillStyle = ink; gx.fillText(nm, 128, 22, 230); }
    gx.font = '700 150px "Barlow Condensed", "Arial Narrow", sans-serif';
    gx.lineWidth = 7; gx.strokeStyle = 'rgba(10,12,20,.45)'; gx.strokeText(String(num), 128, 136);
    gx.fillStyle = ink; gx.fillText(String(num), 128, 136);
    r.numTex.needsUpdate = true;
    drawCrest(r.crCv.getContext('2d'), t); r.crTex.needsUpdate = true;
  }
}
// equipamento de cada clube: padrão da camisola, segunda cor, gola e punhos, e emblema
function kitStyle(t) {
  const h = hashS(t.name || 'x'), lum = c => { const n = parseInt(c.slice(1), 16); return ((n >> 16) * 0.3 + ((n >> 8) & 255) * 0.59 + (n & 255) * 0.11) / 255; };
  const pats = [0, 0, 1, 2, 3, 4, 5, 0, 1, 5];
  const pat = DEFAULT_TEAMS.some(d => d.name === t.name) ? 0 : pats[h % pats.length];
  const c2 = lum(t.color) > 0.6 ? t.dark : (h >> 4) % 3 === 0 ? t.dark : '#f2f2f2';
  const trim = pat === 0 ? (lum(t.color) > 0.6 ? t.dark : '#f2f2f2') : t.dark;
  const ink = lum(t.color) > 0.62 || (pat && lum(c2) > 0.62 && pat !== 3 && pat !== 5) ? '#16181e' : '#f7f7f2';
  return { pat, c2, trim, ink };
}
function drawCrest(gx, t) {
  gx.clearRect(0, 0, 64, 64);
  gx.beginPath(); gx.moveTo(8, 6); gx.lineTo(56, 6); gx.lineTo(56, 34); gx.quadraticCurveTo(56, 52, 32, 60); gx.quadraticCurveTo(8, 52, 8, 34); gx.closePath();
  gx.fillStyle = t.dark || '#222'; gx.fill(); gx.lineWidth = 4; gx.strokeStyle = '#f2cf3a'; gx.stroke();
  const ini = (t.name || '').split(/\s+/).filter(w => w.length > 2 || /^[A-Z]/.test(w)).map(w => w[0].toUpperCase()).join('').slice(0, 3) || 'FC';
  gx.fillStyle = '#f7f7f2'; gx.font = '700 ' + (ini.length > 2 ? 17 : 22) + 'px "Barlow Condensed", sans-serif'; gx.textAlign = 'center'; gx.textBaseline = 'middle'; gx.fillText(ini, 32, 30);
}
function placeRig(r, x, y, fx, fy) { r.outer.position.set(x, 0, y); r.outer.rotation.y = Math.atan2(fx, fy); }
let _v = null;
// ---- animações captadas (base de dados CMU, livre): corrida, trote, parado, quedas e remate
let ANIM = null;
const NB = 22;
function anims() {
  if (ANIM) return ANIM;
  ANIM = {};
  const A = window.ANIMS || {};
  const dec = s => new Int16Array(Uint8Array.from(atob(s), c => c.charCodeAt(0)).buffer);
  for (const k in A) {
    const a = A[k];
    ANIM[k] = { n: a.n, fps: a.fps, loop: a.loop, key: a.key || 0, q: Float32Array.from(dec(a.q), v => v / 32767), p: Float32Array.from(dec(a.p), v => v / 1000), dur: (a.loop ? a.n : a.n - 1) / a.fps };
  }
  return ANIM;
}
// escreve nos ossos a pose do clip no instante t (segundos); pp = vai e volta, para os clips parados
function applyClip(r, name, t, pp) {
  const a = anims()[name]; if (!a) return false;
  if (pp) { const d = a.dur, m = ((t % (2 * d)) + 2 * d) % (2 * d); t = m > d ? 2 * d - m : m; }
  let f = t * a.fps;
  f = a.loop && !pp ? ((f % a.n) + a.n) % a.n : clamp(f, 0, a.n - 1);
  const i0 = Math.floor(f), i1 = a.loop && !pp ? (i0 + 1) % a.n : Math.min(a.n - 1, i0 + 1), k = f - i0;
  for (let b = 0; b < NB; b++) {
    const o0 = (i0 * NB + b) * 4, o1 = (i1 * NB + b) * 4, q = a.q;
    let x = q[o0] + (q[o1] - q[o0]) * k, y = q[o0 + 1] + (q[o1 + 1] - q[o0 + 1]) * k, z = q[o0 + 2] + (q[o1 + 2] - q[o0 + 2]) * k, w = q[o0 + 3] + (q[o1 + 3] - q[o0 + 3]) * k;
    const l = Math.hypot(x, y, z, w) || 1; r.bones[b].quaternion.set(x / l, y / l, z / l, w / l);
  }
  const p = a.p, j0 = i0 * 3, j1 = i1 * 3;
  r.body.rotation.set(0, 0, 0);
  r.body.position.set(p[j0] + (p[j1] - p[j0]) * k, p[j0 + 1] + (p[j1 + 1] - p[j0 + 1]) * k, p[j0 + 2] + (p[j1 + 2] - p[j0 + 2]) * k);
  return true;
}
// misturas: guarda a pose atual num buffer e interpola com outra
const PBUF = [];
function grabPose(r, d) {
  const B = PBUF[d] || (PBUF[d] = { q: new Float32Array(NB * 4 + 4), p: new Float32Array(3) });
  r.bones.forEach((b, i) => { const q = b.quaternion; B.q[i * 4] = q.x; B.q[i * 4 + 1] = q.y; B.q[i * 4 + 2] = q.z; B.q[i * 4 + 3] = q.w; });
  const bq = r.body.quaternion; B.q[NB * 4] = bq.x; B.q[NB * 4 + 1] = bq.y; B.q[NB * 4 + 2] = bq.z; B.q[NB * 4 + 3] = bq.w;
  B.p[0] = r.body.position.x; B.p[1] = r.body.position.y; B.p[2] = r.body.position.z;
  return B;
}
function nlerpInto(A, B, w, set) {
  for (let i = 0; i <= NB; i++) {
    const o = i * 4; let s = 1;
    if (A.q[o] * B.q[o] + A.q[o + 1] * B.q[o + 1] + A.q[o + 2] * B.q[o + 2] + A.q[o + 3] * B.q[o + 3] < 0) s = -1;
    const x = A.q[o] + (s * B.q[o] - A.q[o]) * w, y = A.q[o + 1] + (s * B.q[o + 1] - A.q[o + 1]) * w, z = A.q[o + 2] + (s * B.q[o + 2] - A.q[o + 2]) * w, ww = A.q[o + 3] + (s * B.q[o + 3] - A.q[o + 3]) * w;
    const l = Math.hypot(x, y, z, ww) || 1; set(i, x / l, y / l, z / l, ww / l);
  }
}
let poseDepth = 0;
function applyPose(r, o) {
  if (o.mix) {
    const [pa, pb, w] = o.mix;
    if (w <= 0) return applyPose(r, pa);
    if (w >= 1) return applyPose(r, pb);
    const d = poseDepth; poseDepth += 2;
    applyPose(r, pa); const A = grabPose(r, d);
    applyPose(r, pb); const B = grabPose(r, d + 1);
    poseDepth = d;
    nlerpInto(A, B, w, (i, x, y, z, ww) => (i < NB ? r.bones[i].quaternion : r.body.quaternion).set(x, y, z, ww));
    r.body.position.set(lerp(A.p[0], B.p[0], w), lerp(A.p[1], B.p[1], w), lerp(A.p[2], B.p[2], w));
  } else if (o.clip) {
    if (!applyClip(r, o.clip, o.t || 0, o.pp)) applyPose(r, o.alt || {});
  } else {
    for (const b of r.bones) b.quaternion.set(0, 0, 0, 1);
    setLegacy(r, o);
  }
}
const plantOf = o => o.mix ? plantOf(o.mix[2] >= 0.5 ? o.mix[1] : o.mix[0]) : o.clip ? (o.air ? 'none' : 'floor') : (!o.air && Math.abs(o.pitch || 0) < 0.6 && Math.abs(o.roll || 0) < 0.6 ? 'full' : 'none');
function setPose(r, o) {
  if (!_v) _v = new R3.T.Vector3();
  applyPose(r, o);
  if (o.add) {
    // gestos por cima do clip, rodados no referencial do osso pai (o clip pode trazer o braço torcido)
    const A = o.add, T = R3.T, Z = new T.Vector3(0, 0, 1), q = new T.Quaternion(), pre = (b, a) => { if (a) b.quaternion.premultiply(q.setFromAxisAngle(Z, a)); };
    pre(r.hipL, A.hlz); pre(r.hipR, A.hrz); pre(r.armL, A.alz); pre(r.armR, A.arz);
  }
  // pés assentes no relvado: o pé mais baixo toca no chão (clips: só não deixa o pé entrar na relva)
  const pl = plantOf(o);
  if (pl !== 'none') {
    const y0 = r.body.position.y;
    r.outer.updateMatrixWorld(true);
    const low = Math.min(r.bootL.getWorldPosition(_v).y, r.bootR.getWorldPosition(_v).y) - 0.03;
    if (pl === 'full' || low < 0) r.body.position.y = y0 - low / r.outer.scale.y;
  }
}
// passada: parado, trote e corrida, com a cadência que a velocidade pede (amp ≈ velocidade / 7,5)
function gait(u, amp) {
  const an = anims();
  if (!an.run) return legacyRun(u * 6.283, amp);
  const jog = { clip: 'jog', t: u * an.jog.dur }, run = { clip: 'run', t: u * an.run.dur };
  if (amp < 0.3) return { mix: [{ clip: 'idle', t: u * 0.4, pp: true }, jog, smooth(amp / 0.3)] };
  if (amp < 0.7) return { mix: [jog, run, (amp - 0.3) / 0.4] };
  return run;
}
function runAt(t, off, amp) {
  const sp = Math.max(1.6, amp * 7.5), stride = 2.37 * Math.sqrt(sp / 3.7);
  return gait(t * sp / stride + off / 6.283, amp);
}
const idleAt = (t, off) => ({ clip: 'idle', t: t + off * 0.7, pp: true, alt: { pitch: 0.02, hp: 0.05 } });
function setLegacy(r, o) {
  r.hipL.rotation.set(o.hl || 0, 0, o.hlz || 0); r.kneeL.rotation.x = o.kl || 0; r.ankleL.rotation.x = o.fl || 0;
  r.hipR.rotation.set(o.hr || 0, 0, o.hrz || 0); r.kneeR.rotation.x = o.kr || 0; r.ankleR.rotation.x = o.fr || 0;
  r.armL.rotation.set(o.al || 0, 0, o.alz === undefined ? -0.1 : o.alz);
  r.armR.rotation.set(o.ar || 0, 0, o.arz === undefined ? 0.1 : o.arz);
  r.elL.rotation.x = o.el === undefined ? -0.25 : o.el; r.elR.rotation.x = o.er === undefined ? -0.25 : o.er;
  r.head.rotation.set(o.hp || 0, o.hy || 0, 0);
  r.body.rotation.set(o.pitch || 0, 0, o.roll || 0); r.body.position.set(0, o.y || 0, 0);
}
const runPose = (ph, amp) => gait(ph / 6.283, amp);
function legacyRun(ph, amp) {
  const s = Math.sin(ph);
  return { hl: -s * amp, hr: s * amp, kl: Math.max(0, Math.sin(ph + 1.3)) * amp * 1.7, kr: Math.max(0, Math.sin(ph + 1.3 + Math.PI)) * amp * 1.7,
    fl: Math.max(0, Math.sin(ph + 0.6)) * amp * 0.5, fr: Math.max(0, Math.sin(ph + 0.6 + Math.PI)) * amp * 0.5,
    al: s * amp * 0.9, ar: -s * amp * 0.9, el: -0.35 - amp * 1.1 + s * 0.25 * amp, er: -0.35 - amp * 1.1 - s * 0.25 * amp,
    pitch: 0.14 * amp, hp: -0.1 * amp, y: -Math.abs(Math.cos(ph)) * 0.04 * amp };
}
const smooth = k => k <= 0 ? 0 : k >= 1 ? 1 : k * k * (3 - 2 * k);
const OFF_KT = 1.2, OFF_DUR = 2.6;
const keyTime = L => L.kind === 'offside' ? OFF_KT : TC;
const lanceDur = L => L.dur || DUR;

function show3D(L, review) {
  const R = init3D();
  if (!R) { $('capL').textContent = 'Sem 3D: não foi possível carregar o motor gráfico'; $('cap3d').hidden = false; if (!review) showDecide(true); return; }
  L.time = 0; L.speed = review ? 0.5 : 1; L.cam = null; L.paused = false;
  R.rigs.forEach(r => r.outer.visible = false);
  R.lines.def.visible = R.lines.att.visible = false;
  if (L.kind === 'offside') {
    const oi = L.oi;
    L.dur = OFF_DUR;
    L.rig = { list: oi.snap.slice(0, 22).map((q, i) => { const r = R.rigs[i]; styleRig(r, q.team, q.role, q.num, q.id); r.outer.visible = true; return { r, q, ph: (q.id * 1.7) % 6.28 }; }), ref: R.rigs[22] };
    if (!L.precise) offsidePrecise(L);
  } else {
    const a = R.rigs[0], d = R.rigs[1], ref = R.rigs[22];
    styleRig(a, L.att.team, L.att.role, L.att.num, L.att.id); styleRig(d, L.def.team, L.def.role, L.def.num, L.def.id); styleRig(ref, -1);
    a.outer.visible = d.outer.visible = true;
    L.rig = { a, d, ref, others: [] };
    L.others.slice(0, 18).forEach((o, i) => {
      const r = R.rigs[i + 2]; styleRig(r, o.team, o.role, o.num, o.id); r.outer.visible = true;
      L.rig.others.push({ r, o, ph: (o.id * 1.7) % 6.28 });
    });
    if (!L.dOff) calibFoul(L);
  }
  L.review = review;
  $('toast').hidden = true;
  resize3D();
  stage.classList.add('view3d');
  $('cap3d').hidden = false;
  $('viewBtns').hidden = !review;
  $('scrub').hidden = false;
  $('scKey').textContent = L.kind === 'offside' ? 'Passe' : 'Duelo';
  $('scMark').style.left = (keyTime(L) / lanceDur(L) * 100) + '%';
  captions3D(L);
  if (!review) {
    $('decideMsg').textContent = L.kind === 'offside'
      ? 'Passe aos ' + L.minute + "'. Bandeira " + (L.flag ? 'levantada' : 'em baixo') + '. O recetor estava em jogo?'
      : 'Lance aos ' + L.minute + "'. Qual é a tua decisão?";
    showDecide(true);
  }
  syncScrub();
  pose3D(L, 0);
}
function captions3D(L) {
  if (L.kind === 'offside') {
    const m = Math.abs(L.oi.margin).toFixed(2).replace('.', ',');
    if (L.review) { $('capL').textContent = LABEL[L.truth] + ' por ' + m + ' m' + (L.ideal ? ' · vista do vídeo-árbitro' : ' · vista do assistente'); $('capR').textContent = 'Decidiste: ' + DEC_LABEL[L.decided]; }
    else { $('capL').textContent = 'Vista do assistente · ' + (L.mis < 0.8 ? 'alinhado' : 'desalinhado ' + L.mis.toFixed(1).replace('.', ',') + ' m'); $('capR').textContent = 'Bandeira ' + (L.flag ? 'levantada' : 'em baixo'); }
    return;
  }
  if (L.review) {
    $('capL').textContent = LABEL[L.truth] + (L.ideal ? ' · vista ideal' : ' · a tua vista');
    $('capR').textContent = 'Decidiste: ' + DEC_LABEL[L.decided];
  } else {
    $('capL').textContent = 'A tua vista · ' + Math.round(L.dist) + ' m';
    $('capR').textContent = L.blockers ? L.blockers + (L.blockers > 1 ? ' jogadores à frente' : ' jogador à frente') : 'Linha de vista livre';
  }
}
function hide3D() { stage.classList.remove('view3d'); $('cap3d').hidden = true; $('viewBtns').hidden = true; $('scrub').hidden = true; }
function resize3D() {
  if (!R3) return;
  const r = stage.getBoundingClientRect(), dpr = Math.min(2, window.devicePixelRatio || 1);
  const L = mode === 'fim' ? reviewing : (S && S.lance);
  // longe do lance vês com menos detalhe: menos resolução e mais neblina
  const sharp = L && !L.ideal ? clamp(L.distScore, 0.28, 1) : 1;
  R3.renderer.setPixelRatio(dpr * sharp);
  R3.renderer.setSize(r.width, r.height, false);
  R3.cam.aspect = r.width / Math.max(1, r.height); R3.cam.updateProjectionMatrix();
  R3.scene.fog.near = L && !L.ideal ? 6 + 30 * sharp : 60;
  R3.scene.fog.far = L && !L.ideal ? 30 + 120 * sharp : 180;
}

// ---- fora de jogo: todos se mexem, o passe sai no instante OFF_KT e a bola viaja até ao recetor
function poseOffActors(L, t) {
  const R = R3, oi = L.oi, k = t - OFF_KT;
  if (L.kickPt === undefined && anims().kick) {
    L.kickPt = null; poseOffActors(L, OFF_KT);
    const e = L.rig.list.find(o => o.q.id === oi.passer);
    if (e) { e.r.outer.updateMatrixWorld(true); const f = e.r.bootL.getWorldPosition(new R.T.Vector3()); L.kickPt = { x: f.x, y: f.z }; }
  }
  const recv = oi.snap.find(q => q.id === oi.receiver), pb = oi.snap.find(q => q.id === oi.passer);
  const pdir = pb && recv ? norm(recv.x - pb.x, recv.y - pb.y) : { x: TEAMS[oi.team].dir, y: 0 };
  for (const { r, q, ph } of L.rig.list) {
    const sp = len(q.vx, q.vy);
    if (q.id === oi.passer) {
      // abranda, arma o remate e passa com o pé direito; o apoio fica ao lado da bola
      const kk = Math.min(k, 0.25);
      const x = q.x + q.vx * 0.35 * (k < 0 ? k : kk), y = q.y + q.vy * 0.35 * (k < 0 ? k : kk);
      placeRig(r, x, y, pdir.x, pdir.y);
      const ck = anims().kick;
      if (ck) {
        // remate captado: o contacto com a bola cai exatamente no instante do passe
        const k0 = -ck.key, run = runAt(t, ph, 0.45);
        setPose(r, k < k0 ? run : { mix: [run, { clip: 'kick', t: k + ck.key }, smooth((k - k0) / 0.2)] });
        continue;
      }
      const sw = clamp((t - (OFF_KT - 0.3)) / 0.45, 0, 1);         // 0 = atrás, 0.67 = contacto, 1 = acompanhamento
      if (t < OFF_KT - 0.3) setPose(r, legacyRun(t * 8 + ph, 0.45));
      else setPose(r, { hr: lerp(0.75, -1.25, smooth(sw)), kr: 1.2 * (1 - smooth(sw)) + 0.1, fr: 0.5, hl: -0.1, kl: 0.25, pitch: -0.06, al: 0.4, ar: -0.3, alz: -0.7, arz: 0.5, el: -0.4, er: -0.4, hp: 0.25 });
      continue;
    }
    placeRig(r, q.x + q.vx * k, q.y + q.vy * k, sp > 0.5 ? q.vx : (oi.ball.x - q.x), sp > 0.5 ? q.vy : (oi.ball.y - q.y));
    setPose(r, sp > 0.5 ? runAt(t, ph, Math.min(0.85, sp / 7.5)) : idleAt(t, ph));
  }
  // bola: no pé do passador até ao passe, depois segue para onde o recetor vai estar
  const side = { x: -pdir.y, y: pdir.x };                       // direita do passador
  const b0 = pb ? { x: pb.x + pdir.x * 0.32 + side.x * -0.1, y: pb.y + pdir.y * 0.32 + side.y * -0.1 } : { x: oi.ball.x, y: oi.ball.y };
  if (L.kickPt) { b0.x = L.kickPt.x + pdir.x * 0.13; b0.y = L.kickPt.y + pdir.y * 0.13; }
  let bx = b0.x, by = b0.y;
  if (t < OFF_KT && pb && !L.kickPt) { const lead = (OFF_KT - t) * 0.35; bx = b0.x - pb.vx * lead; by = b0.y - pb.vy * lead; }
  if (t > OFF_KT && recv) {
    const d0 = len(recv.x - b0.x, recv.y - b0.y), T = d0 / 19;
    const tx = recv.x + recv.vx * T, ty = recv.y + recv.vy * T, u = clamp(k / T, 0, 1);
    bx = lerp(b0.x, tx, u); by = lerp(b0.y, ty, u);
    R.ball.rotation.x += 0.3;
  }
  R.ball.position.set(bx, 0.11, by);
}
// verdade medida no corpo 3D no instante do passe: parte do corpo mais adiantada que pode marcar golo
function offsidePrecise(L) {
  const oi = L.oi, ti = oi.team, box = new R3.T.Box3();
  poseOffActors(L, OFF_KT);
  const pv = new R3.T.Vector3();
  const ext = r => { r.outer.updateMatrixWorld(true); let m = -1e9; for (const mk of r.scoring) { mk.getWorldPosition(pv); m = Math.max(m, rel(ti, pv.x)); } return m; };
  let attRel = null; const defs = [];
  for (const { r, q } of L.rig.list) {
    if (q.id === oi.receiver) attRel = ext(r);
    else if (q.team !== ti) defs.push(ext(r));
  }
  if (attRel === null) return;
  defs.sort((a, b) => b - a);
  const secondLast = defs.length > 1 ? defs[1] : defs.length ? defs[0] : W;
  const ballRel = rel(ti, R3.ball.position.x) + 0.11;
  const lineRel = Math.max(secondLast, ballRel, W / 2);
  L.precise = { center: oi.margin };
  oi.margin = attRel - lineRel;
  oi.lineX = absX(ti, lineRel); oi.attX = absX(ti, attRel);
  L.truth = oi.margin > 0 ? 'fora' : 'emjogo';
}
function poseOffside(L, t) {
  const R = R3, oi = L.oi;
  poseOffActors(L, t);
  for (const { r } of L.rig.list) r.outer.visible = true;
  let cx, cy, ch, lx, ly, fov;
  const attX = oi.attX !== undefined ? oi.attX : oi.recvX;
  if (L.ideal) {
    R.lines.def.position.x = oi.lineX; R.lines.att.position.x = attX;
    R.lines.def.visible = R.lines.att.visible = t >= OFF_KT - 0.02 && t <= OFF_KT + 0.5;
    const sideY = oi.ast.y < H / 2 ? -9 : H + 9;
    cx = oi.lineX; cy = sideY; ch = 7; lx = oi.lineX; ly = oi.recvY; fov = 30;
  } else {
    R.lines.def.visible = R.lines.att.visible = false;
    cx = oi.ast.x; cy = oi.ast.y; ch = 1.75; lx = oi.ast.x; ly = oi.recvY;
    // ninguém fica colado ao assistente: quem estiver a menos de 2,5 m sai do plano
    for (const { r } of L.rig.list) if (len(r.outer.position.x - cx, r.outer.position.z - cy) < 2.5) r.outer.visible = false;
    const across = Math.max(4, Math.abs(ly - cy)), spread = Math.abs(attX - oi.ast.x) * 2 + Math.abs(oi.lineX - oi.ast.x) * 2 + 7;
    fov = clamp(2 * Math.atan(spread / 2 / across / R.cam.aspect) * 180 / Math.PI, 10, 46);
  }
  L.rig.ref.outer.visible = false;
  R.cam.fov = fov; R.cam.updateProjectionMatrix();
  R.cam.position.set(cx, ch, cy);
  R.cam.lookAt(lx, 0.9, ly);
  R.renderer.render(R.scene, R.cam);
}

// ---- faltas: guião por tipo de verdade. O pé do defesa é acertado ao ponto de contacto (bola, tornozelo ou joelho)
function poseFoul(L, t) {
  const { a, d, others } = L.rig, { P, A, D, truth } = L, off = L.dOff || { x: 0, y: 0 };
  const vA = 5.4;
  const vD = { siga: 6.2, falta: 6.6, amarelo: 8.2, vermelho: 9.6, simulacao: 6.2 }[truth];
  const perpSide = Math.sign(A.x * D.y - A.y * D.x) || 1;
  const touchT = { siga: 99, falta: TC - 0.55, amarelo: TC - 0.6, vermelho: TC - 0.65, simulacao: 99 }[truth];
  const fallT = { siga: TC + 0.3, falta: TC + 0.06, amarelo: TC + 0.04, vermelho: TC + 0.03, simulacao: TC + 0.35 }[truth];
  const st = L.struck === 0 ? { h: 'hl', k: 'kl', z: 'hlz', oh: 'hr', ok: 'kr' } : { h: 'hr', k: 'kr', z: 'hrz', oh: 'hl', ok: 'kl' };

  // ---- atacante
  let ax, ay;
  if (t < TC) { ax = P.x + A.x * vA * (t - TC); ay = P.y + A.y * vA * (t - TC); }
  else {
    const u = t - TC, go = L.fall ? 1.7 * (1 - Math.exp(-u * 2.6)) : Math.min(u, 1.4) * vA * (1 - Math.min(u, 1.4) / 3);
    ax = P.x + A.x * go; ay = P.y + A.y * go;
  }
  placeRig(a, ax, ay, A.x, A.y);
  const yaw = Math.atan2(A.x, A.y), dxl = D.x * Math.cos(yaw) - D.y * Math.sin(yaw);
  const rollDir = -Math.sign(dxl) || 1, push = (dxl > 0 ? -1 : 1);
  if (L.fall && t >= fallT && anims().dive) {
    // queda captada: de cara para a frente (rasteira, simulação) ou de costas (pernas levadas no vermelho)
    const u = t - fallT, nm = truth === 'vermelho' ? 'fallback' : 'dive';
    setPose(a, { mix: [runAt(fallT, 0, 0.72), { clip: nm, t: u * (truth === 'simulacao' ? 0.95 : 1.15) }, smooth(u / 0.16)] });
  } else if (L.fall && t >= fallT) {
    const u = t - fallT;
    if (truth === 'simulacao') {
      const k = smooth(u / 0.55);
      setPose(a, { air: true, pitch: 1.4 * k, y: 0.15 * Math.sin(Math.min(1, u / 0.55) * Math.PI), al: -2.8 * k, ar: -2.6 * k, alz: -0.3, arz: 0.3, el: -0.2, er: -0.2, hl: 0.5 * k, hr: 0.2 * k, kl: 0.6 * k, kr: 0.9 * k, fl: 0.6 * k, fr: 0.6 * k, hp: -0.6 * k });
    } else if (truth === 'siga') {
      const k = smooth(u / 0.45);
      setPose(a, { air: true, pitch: 1.35 * k, al: -1.3 * k, ar: -1.5 * k, el: -0.5, er: -0.5, hl: 0.3 * k, kl: 0.8 * k, hr: -0.2, kr: 0.4, hp: -0.7 * k });
    } else {
      const hard = truth === 'falta' ? 0 : truth === 'amarelo' ? 1 : 1.7;
      const k = smooth(u / (0.38 - hard * 0.05));
      const hop = hard * 0.28 * Math.max(0, Math.sin(Math.min(1, u / 0.45) * Math.PI));
      const spin = truth === 'vermelho' ? Math.sin(u * 8) * 0.3 * Math.exp(-u * 2) : 0;
      const o = { air: true, pitch: (0.45 + hard * 0.25) * k, roll: rollDir * (1.35 + spin) * k, y: hop, al: -1.1 * k, ar: -1.6 * k, alz: -0.8 * k, arz: 0.8 * k, el: -0.6, er: -0.6, hp: -0.4 * k };
      o[st.z] = push * 0.9 * Math.min(1, u / 0.12); o[st.h] = 0.4 * k; o[st.k] = 1.1 * k; o[st.oh] = -0.5 * k; o[st.ok] = 0.4;
      setPose(a, o);
    }
  } else if (t >= TC && !L.fall) {
    setPose(a, runAt(t, 0, 0.72 * Math.max(0.1, 1 - (t - TC) / 1.4)));
  } else {
    const po = runAt(t, 0, 0.72);
    // a perna atingida é desviada no instante do contacto
    if (truth !== 'siga' && truth !== 'simulacao' && t >= TC && t < fallT) po.add = { [st.z]: push * 0.6 };
    setPose(a, po);
  }

  // ---- defesa
  let target = P, reach = 0.8;
  if (truth === 'siga') { target = { x: P.x + A.x * 0.75, y: P.y + A.y * 0.75 }; reach = 0.95; }
  if (truth === 'simulacao') reach = 2.0;
  if (truth === 'vermelho') reach = 1.05;
  const C = { x: target.x - D.x * reach + off.x, y: target.y - D.y * reach + off.y };
  let dxp, dyp;
  if (truth === 'simulacao') {
    const stopT = TC - 0.1, dStop = t < stopT ? vD * (stopT - t) + 0.4 : 0.4 * Math.exp(-(t - stopT) * 4);
    dxp = C.x - D.x * dStop; dyp = C.y - D.y * dStop;
  } else if (t < TC) { dxp = C.x - D.x * vD * (TC - t); dyp = C.y - D.y * vD * (TC - t); }
  else {
    const u = t - TC, glide = { siga: 0.35, falta: 0.45, amarelo: 2.3, vermelho: 1.9 }[truth];
    dxp = C.x + D.x * glide * (1 - Math.exp(-u * 4)); dyp = C.y + D.y * glide * (1 - Math.exp(-u * 4));
  }
  placeRig(d, dxp, dyp, D.x, D.y);
  // corrida captada até ao corte; depois do gesto volta a correr (mais devagar) ou fica no chão
  const dAmp = vD / 7.5 * (t > TC ? Math.max(0.05, 1 - (t - TC) / 0.6) : 1), dRun = runAt(t, 1, dAmp);
  if (truth === 'siga' || truth === 'falta') {
    const k = smooth((t - (TC - 0.3)) / 0.3), out = t > TC + 0.5 ? smooth(1 - (t - TC - 0.5) / 0.45) : 1;
    setPose(d, k <= 0 ? dRun : { mix: [dRun, { pitch: -0.12 * k, hr: -0.78 * k, kr: 0.1, fr: -0.3 * k, hl: -0.2 * k, kl: 0.95 * k, al: -0.5 * k, ar: 0.3 * k, alz: -0.5 * k, arz: 0.4 * k, el: -0.6, er: -0.5, hp: 0.35 * k }, Math.min(1, k * 2.5) * out] });
  } else if (truth === 'amarelo') {
    // entrada tardia, pitões à frente, à altura da canela
    const k = smooth((t - (TC - 0.45)) / 0.35);
    setPose(d, k <= 0 ? dRun : { mix: [dRun, { pitch: -1.1 * k, y: -0.28 * k, hr: -0.5 * k, kr: 0, fr: -0.9 * k, hl: -0.1 * k, kl: 1.3 * k, al: 0.6 * k, ar: -0.3, alz: -0.9 * k, arz: 0.4, el: -0.3, er: -0.5, hp: 0.9 * k }, Math.min(1, k * 2.5)] });
  } else if (truth === 'vermelho') {
    // tesoura com os dois pés no ar à altura do joelho; depois cai de costas (queda captada)
    const k = smooth((t - (TC - 0.4)) / 0.3), air = Math.max(0, Math.sin(clamp((t - (TC - 0.4)) / 0.6, 0, 1) * Math.PI));
    const jump = { air: true, pitch: -0.75 * k, y: 0.32 * air, hr: -1.75 * k, kr: 0.05, fr: -0.8 * k, hl: -1.55 * k, kl: 0.15, fl: -0.8 * k, al: 0.9 * k, ar: 0.9 * k, alz: -1 * k, arz: 1 * k, el: -0.3, er: -0.3, hp: 0.6 * k };
    const land = smooth((t - TC - 0.15) / 0.35), jumpP = k <= 0 ? dRun : { mix: [dRun, jump, Math.min(1, k * 2.5)] };
    setPose(d, land <= 0 ? jumpP : { mix: [jumpP, { clip: 'fallback', t: 0.55 + (t - TC - 0.15), alt: jump }, land] });
  } else {
    // simulação: trava, perna mal esticada, e depois braços abertos a dizer que não tocou
    const k = smooth((t - (TC - 0.45)) / 0.35), arms = smooth((t - (TC + 0.3)) / 0.4);
    const brake = { pitch: -0.3 * k, hr: -0.45 * k, kr: 0.2, hl: 0.2 * k, kl: 0.5 * k, el: -0.4, er: -0.4 };
    const stand = { clip: 'idle', t: t, pp: true, alt: brake, add: { alz: -1.15 * arms, arz: 1.15 * arms } };
    setPose(d, k <= 0 ? dRun : arms <= 0 ? { mix: [dRun, brake, Math.min(1, k * 2.5)] } : { mix: [brake, stand, Math.min(1, arms * 1.5)], add: stand.add });
  }

  // ---- bola
  let bx, by, bh = 0.11;
  const bob = tt => 0.55 + 0.25 * Math.abs(Math.sin(tt * 4.2));
  const carry = tt => ({ x: P.x + A.x * (vA * (tt - TC) + bob(tt)), y: P.y + A.y * (vA * (tt - TC) + bob(tt)) });
  if (truth === 'siga') {
    const hit = TC - 0.04;
    if (t < hit) { const c = carry(t); bx = c.x; by = c.y; }
    else {
      const c = carry(hit), dir = norm(D.x - perpSide * A.y * 0.2 + A.x * 0.3, D.y + perpSide * A.x * 0.2 + A.y * 0.3), u = t - hit;
      const s = 10 * (1 - Math.exp(-u * 1.3)) / 1.3; bx = c.x + dir.x * s; by = c.y + dir.y * s;
      bh = 0.11 + Math.max(0, Math.sin(u * 5) * 0.6 * Math.exp(-u * 2.2));
    }
  } else if (truth === 'simulacao') {
    const rel0 = TC + 0.3;
    if (t < rel0) { const c = carry(Math.min(t, TC)); const extra = t > TC ? (t - TC) * vA * 0.8 : 0; bx = c.x + A.x * extra; by = c.y + A.y * extra; }
    else { const c = carry(TC), e0 = 0.3 * vA * 0.8, u = t - rel0, s = e0 + 4 * (1 - Math.exp(-u * 1.2)) / 1.2; bx = c.x + A.x * s; by = c.y + A.y * s; }
  } else {
    // toque longo antes do contacto: a bola já foi quando o defesa chega
    if (t < touchT) { const c = carry(t); bx = c.x; by = c.y; }
    else { const c = carry(touchT), u = t - touchT, s = 10 * (1 - Math.exp(-u * 0.8)) / 0.8; bx = c.x + A.x * s; by = c.y + A.y * s; }
  }
  R3.ball.position.set(bx, bh, by);
  if (!L.paused) { R3.ball.rotation.x += 0.15; R3.ball.rotation.z += 0.05; }

  // ---- os outros continuam a mexer-se
  for (const o of others) {
    const k = clamp(t - TC, -1.5, 1.5) * 0.6, sp = len(o.o.vx, o.o.vy);
    const x = o.o.x + o.o.vx * k, y = o.o.y + o.o.vy * k;
    const fx = sp > 0.6 ? o.o.vx : P.x - o.o.x, fy = sp > 0.6 ? o.o.vy : P.y - o.o.y;
    placeRig(o.r, x, y, fx, fy);
    setPose(o.r, sp > 0.6 ? runAt(t, o.ph, Math.min(0.85, sp / 7.5)) : idleAt(t, o.ph));
  }
  return { ax, ay, dxp, dyp };
}
// acerta o guião: o pé do defesa chega exatamente ao ponto de contacto (ou fica a um metro, na simulação)
function calibFoul(L) {
  const T = R3.T, { a, d } = L.rig, v = () => new T.Vector3();
  L.dOff = { x: 0, y: 0 }; L.struck = 1;
  const tc = L.truth === 'siga' ? TC - 0.04 : TC - 0.01;
  poseFoul(L, tc - 0.25);
  a.outer.updateMatrixWorld(true);
  const dp = d.outer.position, fl = a.bootL.getWorldPosition(v()), fr = a.bootR.getWorldPosition(v());
  L.struck = len(fr.x - dp.x, fr.z - dp.z) <= len(fl.x - dp.x, fl.z - dp.z) ? 1 : 0;
  poseFoul(L, tc);
  a.outer.updateMatrixWorld(true); d.outer.updateMatrixWorld(true);
  const leg = L.struck ? { boot: a.bootR, knee: a.kneeR } : { boot: a.bootL, knee: a.kneeL };
  let tgt;
  if (L.truth === 'siga') { const b = R3.ball.position; tgt = { x: b.x - L.D.x * 0.12, y: b.z - L.D.y * 0.12 }; }
  else if (L.truth === 'vermelho') { const k = leg.knee.getWorldPosition(v()); tgt = { x: k.x, y: k.z }; }
  else if (L.truth === 'simulacao') { const f = leg.boot.getWorldPosition(v()); tgt = { x: f.x - L.D.x * 1.1, y: f.z - L.D.y * 1.1 }; }
  else { const f = leg.boot.getWorldPosition(v()); tgt = { x: f.x, y: f.z }; }
  const foot = d.bootR.getWorldPosition(v());
  let ox = tgt.x - foot.x, oy = tgt.y - foot.z;
  const l = len(ox, oy); if (l > 1.6) { ox *= 1.6 / l; oy *= 1.6 / l; }
  L.dOff = { x: ox, y: oy };
}

function pose3D(L, t) {
  const R = R3; if (!R) return;
  if (L.kind === 'offside') { poseOffside(L, t); return; }
  const { ax, ay, dxp, dyp } = poseFoul(L, t);
  const { ref, others } = L.rig, { P, A, D } = L;
  const mid = { x: (ax + dxp) / 2, y: (ay + dyp) / 2 };
  const gap = len(ax - dxp, ay - dyp);
  let cx, cy, ch, look, width;
  if (L.ideal) {
    // câmara perpendicular à linha defesa-atacante, para os dois ficarem lado a lado e o ponto de contacto à vista
    const perp = { x: -D.y, y: D.x };
    const sgn = (perp.x * A.x + perp.y * A.y) <= 0 ? 1 : -1;       // do lado de onde o atacante vem, não para onde corre
    const camAt = sg => { const sd = norm(perp.x * sg, perp.y * sg); return { x: P.x + sd.x * 7, y: P.y + sd.y * 7 }; };
    const inside = c => c.x > -2.5 && c.x < W + 2.5 && c.y > -2.5 && c.y < H + 2.5;
    let cp = camAt(sgn);
    if (!inside(cp) && inside(camAt(-sgn))) cp = camAt(-sgn);
    cx = clamp(cp.x, -2.5, W + 2.5); cy = clamp(cp.y, -2.5, H + 2.5); ch = 1.9;
    look = { x: lerp(ax, mid.x, 0.5), y: lerp(ay, mid.y, 0.5) };
    width = clamp(gap + 4, 6.5, 18);
    placeRig(ref, L.ref.x, L.ref.y, P.x - L.ref.x, P.y - L.ref.y); setPose(ref, idleAt(t, 2)); ref.outer.visible = true;
  } else {
    cx = L.ref.x; cy = L.ref.y; ch = 1.75;
    const toP = norm(P.x - cx, P.y - cy);
    if (len(P.x - cx, P.y - cy) < 3.5) { cx = P.x - toP.x * 3.5; cy = P.y - toP.y * 3.5; }
    look = gap < 12 ? mid : { x: lerp(ax, dxp, 0.3), y: lerp(ay, dyp, 0.3) };
    width = clamp(gap + 4.5, 6, 18);
    ref.outer.visible = false;
  }
  // ninguém fica colado à câmara
  for (const o of others) o.r.outer.visible = len(o.r.outer.position.x - cx, o.r.outer.position.z - cy) > 2;
  const camDist = Math.max(1, len(look.x - cx, look.y - cy));
  const hfov = 2 * Math.atan(width / 2 / camDist);
  const vfov = clamp(2 * Math.atan(Math.tan(hfov / 2) / R.cam.aspect) * 180 / Math.PI, 6, 55);
  if (!L.cam || t === 0 || L.paused) L.cam = { x: look.x, y: look.y, fov: vfov };
  L.cam.x = lerp(L.cam.x, look.x, 0.12); L.cam.y = lerp(L.cam.y, look.y, 0.12); L.cam.fov = lerp(L.cam.fov, vfov, 0.08);
  R.cam.fov = L.cam.fov; R.cam.updateProjectionMatrix();
  R.cam.position.set(cx, ch, cy);
  R.cam.lookAt(L.cam.x, 0.85, L.cam.y);
  R.renderer.render(R.scene, R.cam);
}
