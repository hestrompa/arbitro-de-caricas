import { chromium } from '/opt/node22/lib/node_modules/playwright/index.mjs';
// Conta quebras no som: janelas de 2048 amostras em silêncio total durante o jogo
// (o murmúrio do público é contínuo, por isso silêncio = buffer vazio), a mexer o árbitro.
const PORT = process.argv[2] || '8767';
const b = await chromium.launch({ args:['--use-gl=angle','--use-angle=swiftshader','--enable-webgl','--ignore-gpu-blocklist','--enable-unsafe-swiftshader','--autoplay-policy=no-user-gesture-required'] });
const pg = await b.newPage({ viewport:{width:1280,height:720} });
await pg.addInitScript(() => {
  window.__g = {an: null, win: 0, mudo: 0, peak: 0};
  const oc = AudioNode.prototype.connect;
  AudioNode.prototype.connect = function(dest, ...r) {
    if (dest instanceof AudioDestinationNode) {
      const ctx = dest.context;
      if (!ctx.__an) { ctx.__an = ctx.createAnalyser(); ctx.__an.fftSize = 1024; oc.call(ctx.__an, dest); window.__g.an = ctx.__an; }
      return oc.call(this, ctx.__an, ...r);
    }
    return oc.call(this, dest, ...r);
  };
  setInterval(() => { const a = window.__g.an; if (!a) return; const buf = new Float32Array(1024); a.getFloatTimeDomainData(buf);
    let m = 0; for (const v of buf) m = Math.max(m, Math.abs(v)); window.__g.win++; if (m < 1e-5) window.__g.mudo++; window.__g.peak = Math.max(window.__g.peak, m); }, 21);
});
await pg.goto(`http://localhost:${PORT}/index.html`);
await pg.waitForTimeout(30000);
await pg.mouse.click(640, 264);
await pg.waitForTimeout(8000);
const rep = async (tag) => { const r = await pg.evaluate(() => { const g = window.__g; const o = {win: g.win, mudo: g.mudo, pct: (100 * g.mudo / Math.max(1, g.win)).toFixed(1), peak: g.peak.toFixed(3)}; g.win = 0; g.mudo = 0; g.peak = 0; return o; }); console.log(tag, JSON.stringify(r)); };
await rep('arranque');
await pg.waitForTimeout(8000); await rep('parado');
for (const k of ['KeyD', 'KeyW', 'KeyA', 'KeyS']) { await pg.keyboard.down(k); await pg.waitForTimeout(2500); await pg.keyboard.up(k); }
await rep('a mexer');
const fps = await pg.evaluate(() => new Promise(r => { let n = 0; const t0 = performance.now(); const f = () => { n++; if (performance.now() - t0 < 3000) requestAnimationFrame(f); else r(n / 3); }; requestAnimationFrame(f); }));
console.log('fps', fps.toFixed(1));
await b.close();
