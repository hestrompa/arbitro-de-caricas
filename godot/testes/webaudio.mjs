import { chromium } from '/opt/node22/lib/node_modules/playwright/index.mjs';
// Mede se o jogo web produz som: liga um analisador antes do destino do Web Audio.
const b = await chromium.launch({ args:['--use-gl=angle','--use-angle=swiftshader','--enable-webgl','--ignore-gpu-blocklist','--enable-unsafe-swiftshader','--autoplay-policy=no-user-gesture-required'] });
const pg = await b.newPage({ viewport:{width:1280,height:720} });
const logs=[]; pg.on('console',m=>{ const t=m.text(); if(m.type()==='error'||t.startsWith('AUD')) logs.push(t); }); pg.on('pageerror',e=>logs.push('PE '+e.message));
await pg.addInitScript(() => {
  window.__aud = {an: [], starts: 0, peak: 0, ctxs: []};
  const oc = AudioNode.prototype.connect;
  AudioNode.prototype.connect = function(dest, ...r) {
    if (dest instanceof AudioDestinationNode) {
      const ctx = dest.context;
      if (!ctx.__an) { ctx.__an = ctx.createAnalyser(); ctx.__an.fftSize = 2048; oc.call(ctx.__an, dest); window.__aud.an.push(ctx.__an); window.__aud.ctxs.push(ctx); }
      return oc.call(this, ctx.__an, ...r);
    }
    return oc.call(this, dest, ...r);
  };
  const os = AudioBufferSourceNode.prototype.start;
  AudioBufferSourceNode.prototype.start = function(...a) { window.__aud.starts++; return os.apply(this, a); };
  setInterval(() => { const buf = new Float32Array(2048); for (const a of window.__aud.an) { a.getFloatTimeDomainData(buf); for (const v of buf) window.__aud.peak = Math.max(window.__aud.peak, Math.abs(v)); } }, 50);
});
await pg.goto('http://localhost:8767/index.html');
await pg.waitForTimeout(30000);
const rep = async (tag) => { const r = await pg.evaluate(() => { const a = window.__aud; const o = {starts: a.starts, peak: a.peak.toFixed(4), ctx: a.ctxs.map(c => c.state).join(','), n: a.an.length}; a.peak = 0; return o; }); console.log(tag, JSON.stringify(r)); };
await rep('menu');
await pg.mouse.click(640, 264);
for (let i = 0; i < 6; i++) { await pg.waitForTimeout(5000); await rep('jogo' + i); }
console.log(logs.slice(0, 10));
await b.close();
