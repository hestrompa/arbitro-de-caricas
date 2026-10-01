// ---------- som: tudo sintetizado com Web Audio, sem ficheiros ----------
const Sfx = (() => {
  let ac = null, master = null, crowdGain = null, crowdFilter = null, muted = false;
  function init() {
    if (ac) { if (ac.state === 'suspended') ac.resume(); return; }
    const AC = window.AudioContext || window.webkitAudioContext; if (!AC) return;
    try { ac = new AC(); } catch (e) { return; }
    master = ac.createGain(); master.gain.value = muted ? 0 : 0.8; master.connect(ac.destination);
    // murmúrio do estádio: ruído rosa filtrado em loop, sobe com a pressão do público
    const n = ac.sampleRate * 4, buf = ac.createBuffer(2, n, ac.sampleRate);
    for (let c = 0; c < 2; c++) {
      const d = buf.getChannelData(c); let b0 = 0, b1 = 0, b2 = 0;
      for (let i = 0; i < n; i++) { const w = Math.random() * 2 - 1; b0 = 0.99765 * b0 + w * 0.099; b1 = 0.963 * b1 + w * 0.2965; b2 = 0.57 * b2 + w * 1.0527; d[i] = (b0 + b1 + b2 + w * 0.1848) * 0.16; }
    }
    const src = ac.createBufferSource(); src.buffer = buf; src.loop = true;
    crowdFilter = ac.createBiquadFilter(); crowdFilter.type = 'bandpass'; crowdFilter.frequency.value = 650; crowdFilter.Q.value = 0.5;
    crowdGain = ac.createGain(); crowdGain.gain.value = 0;
    src.connect(crowdFilter); crowdFilter.connect(crowdGain); crowdGain.connect(master); src.start();
  }
  const now = () => ac.currentTime;
  function env(g, t0, a, hold, rel, peak) {
    g.gain.setValueAtTime(0, t0); g.gain.linearRampToValueAtTime(peak, t0 + a);
    g.gain.setValueAtTime(peak, t0 + a + hold); g.gain.exponentialRampToValueAtTime(0.0001, t0 + a + hold + rel);
  }
  function noise(dur) {
    const b = ac.createBuffer(1, Math.ceil(ac.sampleRate * dur), ac.sampleRate), d = b.getChannelData(0);
    for (let i = 0; i < d.length; i++) d[i] = Math.random() * 2 - 1;
    const s = ac.createBufferSource(); s.buffer = b; return s;
  }
  // apito de ervilha: duas notas agudas com trilo rápido
  function blast(t0, dur, vol) {
    const g = ac.createGain(), bp = ac.createBiquadFilter(); bp.type = 'bandpass'; bp.frequency.value = 3000; bp.Q.value = 3;
    const o1 = ac.createOscillator(), o2 = ac.createOscillator(); o1.type = 'square'; o2.type = 'sawtooth';
    o1.frequency.value = 2860; o2.frequency.value = 3010;
    const lfo = ac.createOscillator(), lg = ac.createGain(); lfo.frequency.value = 34; lg.gain.value = 110;
    lfo.connect(lg); lg.connect(o1.frequency); lg.connect(o2.frequency);
    const trem = ac.createGain(); trem.gain.value = 0.7; const tl = ac.createOscillator(), tg = ac.createGain(); tl.frequency.value = 34; tg.gain.value = 0.3; tl.connect(tg); tg.connect(trem.gain);
    o1.connect(bp); o2.connect(bp); bp.connect(trem); trem.connect(g); g.connect(master);
    env(g, t0, 0.015, dur, 0.06, vol);
    [o1, o2, lfo, tl].forEach(o => { o.start(t0); o.stop(t0 + dur + 0.1); });
  }
  function whistle(kind) {
    if (!ac) return; const t = now() + 0.02;
    const pat = { short: [0.22], long: [0.75], double: [0.14, 0.4], end: [0.35, 0.35, 1.1] }[kind] || [0.22];
    let x = t; for (const d of pat) { blast(x, d, 0.16); x += d + 0.16; }
  }
  function kick(vol) {
    if (!ac || vol <= 0.02) return; const t = now();
    const o = ac.createOscillator(), g = ac.createGain(); o.frequency.setValueAtTime(140, t); o.frequency.exponentialRampToValueAtTime(48, t + 0.09);
    o.connect(g); g.connect(master); env(g, t, 0.003, 0.01, 0.09, 0.5 * vol); o.start(t); o.stop(t + 0.15);
    const s = noise(0.05), f = ac.createBiquadFilter(), g2 = ac.createGain(); f.type = 'highpass'; f.frequency.value = 1800;
    s.connect(f); f.connect(g2); g2.connect(master); env(g2, t, 0.002, 0.005, 0.03, 0.12 * vol); s.start(t);
  }
  // ondas de público: festa (ruído largo que sobe) e assobios/vaias (vozes graves com vibrato)
  // o murmúrio do estádio sobe por uns segundos a cada acontecimento (golo, remate, cartão) e volta a baixar
  let boost = 0, boostT = 0;
  function react(v) { if (!ac) return; boost = Math.max(curBoost(), v); boostT = now(); }
  const curBoost = () => ac ? boost * Math.exp(-(now() - boostT) / 2.2) : 0;
  function cheer(amount) {
    if (!ac) return; react(amount); const t = now(), s = noise(3.5), f = ac.createBiquadFilter(), g = ac.createGain();
    f.type = 'bandpass'; f.frequency.setValueAtTime(700, t); f.frequency.linearRampToValueAtTime(1300, t + 0.5); f.Q.value = 0.7;
    s.connect(f); f.connect(g); g.connect(master); env(g, t, 0.25, 1.2 * amount, 1.8, 0.4 * amount); s.start(t);
  }
  function boo(amount) {
    if (!ac) return; react(amount * 0.8); const t = now(), g = ac.createGain(), lp = ac.createBiquadFilter(); lp.type = 'lowpass'; lp.frequency.value = 520;
    lp.connect(g); g.connect(master); env(g, t, 0.35, 1.1 * amount, 1.2, 0.11 * amount);
    for (let i = 0; i < 9; i++) {
      const o = ac.createOscillator(), v = ac.createOscillator(), vg = ac.createGain();
      o.type = 'sawtooth'; o.frequency.value = 105 + Math.random() * 60; v.frequency.value = 4 + Math.random() * 3; vg.gain.value = 5;
      v.connect(vg); vg.connect(o.frequency); o.connect(lp); o.start(t); v.start(t); o.stop(t + 3.5); v.stop(t + 3.5);
    }
    // assobios agudos por cima
    for (let i = 0; i < Math.round(3 * amount); i++) {
      const o = ac.createOscillator(), g2 = ac.createGain(), t1 = t + 0.2 + Math.random() * 0.8;
      o.frequency.setValueAtTime(1900 + Math.random() * 900, t1); o.frequency.linearRampToValueAtTime(1500 + Math.random() * 600, t1 + 0.9);
      o.connect(g2); g2.connect(master); env(g2, t1, 0.08, 0.6, 0.3, 0.025); o.start(t1); o.stop(t1 + 1.1);
    }
  }
  function ooh() {
    if (!ac) return; react(0.55); const t = now(), g = ac.createGain(), bp = ac.createBiquadFilter(); bp.type = 'bandpass'; bp.frequency.value = 480; bp.Q.value = 1.5;
    bp.connect(g); g.connect(master); env(g, t, 0.2, 0.5, 0.9, 0.12);
    for (let i = 0; i < 7; i++) { const o = ac.createOscillator(); o.type = 'sawtooth'; o.frequency.setValueAtTime(160 + Math.random() * 70, t); o.frequency.linearRampToValueAtTime(230 + Math.random() * 70, t + 0.7); o.connect(bp); o.start(t); o.stop(t + 1.7); }
  }
  function beep() {
    if (!ac) return; const t = now();
    for (const k of [0, 0.22]) { const o = ac.createOscillator(), g = ac.createGain(); o.frequency.value = 988; o.connect(g); g.connect(master); env(g, t + k, 0.01, 0.12, 0.05, 0.1); o.start(t + k); o.stop(t + k + 0.25); }
  }
  function setCrowd(level) {
    if (!ac || !crowdGain) return;
    const b = curBoost();
    crowdGain.gain.setTargetAtTime(0.03 + level * 0.09 + b * 0.2, now(), b > 0.05 ? 0.15 : 0.5);
    crowdFilter.frequency.setTargetAtTime(480 + level * 380 + b * 650, now(), 0.3);
  }
  function toggle() { muted = !muted; if (master) master.gain.setTargetAtTime(muted ? 0 : 0.8, now(), 0.05); return muted; }
  return { init, whistle, kick, cheer, boo, ooh, beep, setCrowd, react, toggle, get muted() { return muted; } };
})();
