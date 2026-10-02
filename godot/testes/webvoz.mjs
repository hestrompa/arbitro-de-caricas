import { chromium } from '/opt/node22/lib/node_modules/playwright/index.mjs';
// Desliga e liga a voz no menu ("Rádio ligado." do VAR) e regista os sons que o browser toca.
const PORT = process.argv[2] || '8767';
const b = await chromium.launch({ args:['--use-gl=angle','--use-angle=swiftshader','--enable-webgl','--ignore-gpu-blocklist','--enable-unsafe-swiftshader','--autoplay-policy=no-user-gesture-required'] });
const pg = await b.newPage({ viewport:{width:1280,height:720} });
await pg.addInitScript(() => {
  window.__s = [];
  const os = AudioBufferSourceNode.prototype.start;
  AudioBufferSourceNode.prototype.start = function(...a) { { const me = this; window.__s.push((performance.now()/1000).toFixed(1) + 's:' + (this.buffer ? this.buffer.duration.toFixed(2) : '?') + (this.loop ? 'L' : '')); setTimeout(() => window.__s.push('  loop depois=' + me.loop + ' ' + me.loopStart + '-' + me.loopEnd), 50); } return os.apply(this, a); };
  const sp = speechSynthesis.speak.bind(speechSynthesis);
  speechSynthesis.speak = (u) => { window.__s.push('TTS:' + u.text); return sp(u); };
});
await pg.goto(`http://localhost:${PORT}/index.html`);
await pg.waitForTimeout(30000);
console.log('menu', await pg.evaluate(() => window.__s.splice(0)));
await pg.mouse.click(422, 552); await pg.waitForTimeout(1500);
await pg.mouse.click(422, 552); await pg.waitForTimeout(4000);
console.log('depois de ligar a voz', await pg.evaluate(() => window.__s.splice(0)));
await b.close();
