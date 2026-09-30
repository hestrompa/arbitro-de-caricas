// ---------- estádio 3D: bancadas inclinadas com público, cobertura, publicidade e torres de luz ----------
const SPONSORS = ['ÁRBITRO DE CARICAS', 'APITO DOURADO', 'CARICA COLA', 'BANDEIRINHA SEGUROS', 'RELVADO VERDE', 'TAÇA DAS CARICAS'];
function adTexture(T, txt, i) {
  const c = document.createElement('canvas'); c.width = 512; c.height = 64;
  const g = c.getContext('2d'), bgs = ['#1f3b7a', '#f2cf3a', '#15161a', '#c9302c', '#1d6b3a', '#eeeeea'], fgs = ['#f7f7f2', '#15161a', '#f2cf3a', '#f7f7f2', '#f7f7f2', '#1f3b7a'];
  g.fillStyle = bgs[i % 6]; g.fillRect(0, 0, 512, 64);
  g.fillStyle = fgs[i % 6]; g.font = '700 40px "Barlow Condensed", "Arial Narrow", sans-serif'; g.textAlign = 'center'; g.textBaseline = 'middle';
  g.fillText(txt, 256, 34);
  const t = new T.CanvasTexture(c); t.anisotropy = 4; return t;
}
// público: cada lugar é uma cabeça e uma camisola; a bancada de cada equipa veste as cores dela
function paintCrowd(cv, mix) {
  const g = cv.getContext('2d'), cw = 8, ch = 10;
  g.fillStyle = '#20252f'; g.fillRect(0, 0, cv.width, cv.height);
  const skins = ['#f1c9a5', '#d9a47a', '#a8714a', '#6b4429'], neutral = ['#e8e8e8', '#5b6475', '#2a3140', '#c9a15a', '#7a1f2e'];
  for (let y = 0; y < cv.height; y += ch) {
    g.fillStyle = 'rgba(0,0,0,.25)'; g.fillRect(0, y + ch - 2, cv.width, 2);                       // degrau
    for (let x = 0; x < cv.width; x += cw) {
      if (Math.random() < 0.13) continue;                                                         // lugar vazio
      const r = Math.random(); let shirt = neutral[Math.floor(Math.random() * neutral.length)];
      for (const [col, share] of mix) { if (r < share) { shirt = col; break; } }
      const jx = x + Math.random() * 1.5;
      g.fillStyle = shirt; g.fillRect(jx + 1, y + 4, cw - 2, ch - 5);
      g.fillStyle = skins[Math.floor(Math.random() * 4)]; g.fillRect(jx + 2.5, y + 1, 3, 3);
    }
  }
}
function buildStadium(T, scene) {
  const st = { stands: [], key: '' };
  // publicidade à volta do relvado
  const boardH = 0.9;
  const addBoards = (x0, z0, x1, z1, faceY, side) => {
    const L = len(x1 - x0, z1 - z0), n = Math.max(1, Math.round(L / 10)), dx = (x1 - x0) / n, dz = (z1 - z0) / n;
    for (let i = 0; i < n; i++) {
      const mat = [new T.MeshLambertMaterial({ color: '#222' }), new T.MeshLambertMaterial({ color: '#222' }), new T.MeshLambertMaterial({ color: '#222' }), new T.MeshLambertMaterial({ color: '#222' }),
        new T.MeshLambertMaterial({ map: adTexture(T, SPONSORS[(i + side) % SPONSORS.length], i + side), emissive: '#222', emissiveIntensity: 0.4 }), new T.MeshLambertMaterial({ color: '#222' })];
      const bd = new T.Mesh(new T.BoxGeometry(L / n - 0.15, boardH, 0.12), mat);
      bd.position.set(x0 + dx * (i + 0.5), boardH / 2, z0 + dz * (i + 0.5)); bd.rotation.y = faceY; scene.add(bd);
    }
  };
  addBoards(-3, -5, W + 3, -5, 0, 0); addBoards(W + 3, H + 5, -3, H + 5, Math.PI, 3);
  addBoards(-5, H + 3, -5, -3, Math.PI / 2, 1); addBoards(W + 5, -3, W + 5, H + 3, -Math.PI / 2, 4);
  // bancadas: grupo com a frente no eixo x, virado para +z; inclinação de 30 graus
  const slope = Math.PI / 6, Ls = 28, concrete = new T.MeshLambertMaterial({ color: '#3b4250' }), dark = new T.MeshLambertMaterial({ color: '#1a1e27' });
  const stand = (cx, cz, rotY, w, side) => {
    const grp = new T.Group(); grp.position.set(cx, 0, cz); grp.rotation.y = rotY; scene.add(grp);
    const cv = document.createElement('canvas'); cv.width = 1024; cv.height = 256;
    const tex = new T.CanvasTexture(cv); tex.wrapS = tex.wrapT = T.RepeatWrapping; tex.repeat.set(w / 64, Ls / 12);
    const seats = new T.Mesh(new T.PlaneGeometry(w, Ls), new T.MeshLambertMaterial({ map: tex }));
    seats.rotation.x = -(Math.PI / 2 - slope); seats.position.set(0, 1.6 + Ls / 2 * Math.sin(slope), -Ls / 2 * Math.cos(slope)); grp.add(seats);
    const wall = new T.Mesh(new T.BoxGeometry(w, 1.6, 0.4), concrete); wall.position.set(0, 0.8, 0.2); grp.add(wall);
    const topY = 1.6 + Ls * Math.sin(slope), backZ = -Ls * Math.cos(slope);
    const back = new T.Mesh(new T.BoxGeometry(w, topY + 5, 0.6), dark); back.position.set(0, (topY + 5) / 2, backZ - 0.3); grp.add(back);
    // cobertura com uma faixa de luz por baixo
    const roof = new T.Mesh(new T.BoxGeometry(w + 2, 0.5, Ls * 0.75), dark); roof.position.set(0, topY + 5, backZ + Ls * 0.37); roof.rotation.x = -0.08; grp.add(roof);
    const strip = new T.Mesh(new T.PlaneGeometry(w, 0.35), new T.MeshBasicMaterial({ color: '#fff6d8' })); strip.rotation.x = Math.PI / 2; strip.position.set(0, topY + 4.7, backZ + Ls * 0.72); grp.add(strip);
    st.stands.push({ cv, tex, side, ph: Math.random() * 6 });
  };
  stand(W / 2, -8, 0, W + 24, 'main'); stand(W / 2, H + 8, Math.PI, W + 24, 'opp');
  stand(-8, H / 2, Math.PI / 2, H + 16, 'end0'); stand(W + 8, H / 2, -Math.PI / 2, H + 16, 'end1');
  // torres de luz nos cantos
  const lampMat = new T.MeshBasicMaterial({ color: '#fffbe8' });
  const glowCv = document.createElement('canvas'); glowCv.width = glowCv.height = 64;
  const gg = glowCv.getContext('2d'), grd = gg.createRadialGradient(32, 32, 0, 32, 32, 32); grd.addColorStop(0, 'rgba(255,250,225,1)'); grd.addColorStop(0.3, 'rgba(255,245,210,.5)'); grd.addColorStop(1, 'rgba(255,240,200,0)');
  gg.fillStyle = grd; gg.fillRect(0, 0, 64, 64);
  const glowMat = new T.SpriteMaterial({ map: new T.CanvasTexture(glowCv), blending: T.AdditiveBlending, depthWrite: false, fog: false });
  for (const [x, z] of [[-18, -18], [W + 18, -18], [-18, H + 18], [W + 18, H + 18]]) {
    const pole = new T.Mesh(new T.CylinderGeometry(0.5, 0.8, 42, 8), concrete); pole.position.set(x, 21, z); scene.add(pole);
    const head = new T.Group(); head.position.set(x, 43, z); head.lookAt(W / 2, 0, H / 2); scene.add(head);
    const panel = new T.Mesh(new T.BoxGeometry(7, 4, 0.4), dark); head.add(panel);
    for (let i = 0; i < 12; i++) { const l = new T.Mesh(new T.PlaneGeometry(0.9, 0.9), lampMat); l.position.set(-2.7 + (i % 6) * 1.08, i < 6 ? 0.8 : -0.8, 0.22); head.add(l); }
    const glow = new T.Sprite(glowMat); glow.scale.set(22, 22, 1); glow.position.set(0, 0, 1); head.add(glow);
  }
  return st;
}
// cores do público: a bancada principal e o topo 0 são da casa, o topo 1 é dos visitantes
function paintStadium() {
  const st = R3 && R3.stadium; if (!st) return;
  const key = TEAMS[0].color + TEAMS[1].color;
  if (st.key === key) return;
  st.key = key;
  const h = TEAMS[0].color, a = TEAMS[1].color;
  for (const s of st.stands) {
    const mix = s.side === 'end1' ? [[a, 0.7], [h, 0.76]] : s.side === 'end0' ? [[h, 0.75], [a, 0.8]] : [[h, 0.5], [a, 0.62]];
    paintCrowd(s.cv, mix); s.tex.needsUpdate = true;
  }
}
// o público mexe-se mais quando a pressão sobe
function animStadium() {
  const st = R3 && R3.stadium; if (!st) return;
  const now = performance.now() / 1000, k = S ? 0.3 + S.crowd / 100 : 0.4;
  for (const s of st.stands) s.tex.offset.y = Math.abs(Math.sin(now * (4 + k * 6) + s.ph)) * 0.012 * k;
}

// ---------- app instalável: só quando o jogo é servido com o manifesto ao lado (GitHub Pages), não dentro do artefacto ----------
(function pwaSetup() {
  if (!('serviceWorker' in navigator) || !/^https?:$/.test(location.protocol)) return;
  let evt = null;
  window.addEventListener('beforeinstallprompt', e => { e.preventDefault(); evt = e; $('installBtn').hidden = false; });
  $('installBtn').addEventListener('click', () => { if (!evt) return; evt.prompt(); evt.userChoice.finally(() => { evt = null; $('installBtn').hidden = true; }); });
  fetch('manifest.webmanifest', { method: 'HEAD', cache: 'no-store' }).then(r => {
    if (!r.ok) return;
    for (const [rel, href] of [['manifest', 'manifest.webmanifest'], ['apple-touch-icon', 'icon-180.png']]) { const l = document.createElement('link'); l.rel = rel; l.href = href; document.head.appendChild(l); }
    navigator.serviceWorker.register('sw.js').catch(() => { /* sem modo offline */ });
  }).catch(() => { /* dentro do artefacto não há manifesto */ });
})();
