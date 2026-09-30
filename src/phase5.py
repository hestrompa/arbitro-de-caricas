t = open('game.js').read()


def rep(a, b, cnt=1):
    global t
    assert t.count(a) == cnt, (a, t.count(a))
    t = t.replace(a, b)


# estado novo do jogo
rep("varN: 0,", "varN: 0, manage: [], added: 0, stall: null, stallN: 0, warned: [false, false], pendCard: null, ask: null, feed: [], addMin: 0,")
# quem chutou por último (para a mão na bola e o relato)
rep("Object.assign(b, { owner: null, vx: n.x * sp, vy: n.y * sp, vz, z:", "Object.assign(b, { owner: null, kicker: p, vx: n.x * sp, vy: n.y * sp, vz, z:")
rep("Object.assign(b, { owner: null, vx: n.x * sp, vy: n.y * sp, vz: pen", "Object.assign(b, { owner: null, kicker: p, vx: n.x * sp, vy: n.y * sp, vz: pen")
# gatilhos dos lances novos
rep("  if (best.role === 'gk' && sp > 12 && b.last !== best.team) {", "  if (handCheck(best, sp)) return;\n  if (best.role === 'gk' && sp > 12 && b.last !== best.team) {")
rep("  best.cd = best.role === 'gk' ? rand(0.9, 1.4) : rand(0.7, 1.4); best.dribble = null;\n}", "  best.cd = best.role === 'gk' ? rand(0.9, 1.4) : rand(0.7, 1.4); best.dribble = null;\n  if (best.role === 'gk' && mode === 'play') stallCheck(best);\n}")
rep("gk.cd = 1.2; gk.setPiece = true; }", "gk.cd = 1.2; gk.setPiece = true; stallCheck(gk); }")
rep("  toast('Canto para ' + artT(team), 1.4);\n  S.pause = 1.1;\n}", "  toast('Canto para ' + artT(team), 1.4);\n  S.pause = 1.1;\n  if (p) cornerCheck(team, p);\n}")
rep("    if (b.owner === p) { if (p.role === 'gk')", "    if (b.owner === p && gkChance(p, dt)) return;\n    if (b.owner === p) { if (p.role === 'gk')")
# faltas: guarda-redes, reiteradas, táticas, vantagem
rep("  const wts = { siga: 0.24,", "  const wts = def.role === 'gk' ? { siga: 0.4, falta: 0.22, amarelo: 0.14, simulacao: 0.24 } : { siga: 0.24,")
rep("  const phiDeg = { siga: rand(115, 160)", "  let phiDeg = { siga: rand(115, 160)")
rep("simulacao: rand(85, 135) }[truth];", "simulacao: rand(85, 135) }[truth];\n  if (def.role === 'gk') phiDeg = rand(140, 170);")
rep("  S.lance = { att: { id: att.id, team: att.team, num: att.num, role: att.role }, def:", "  const X5 = foulExtras(att, def, truth, P, A, inBox); truth = X5.truth;\n  S.lance = { att: { id: att.id, team: att.team, num: att.num, role: att.role }, def:")
rep("decided: null, cam: null, ideal: false };\n  mode = 'lance';\n  att.vx", "decided: null, cam: null, ideal: false };\n  Object.assign(S.lance, X5);\n  mode = 'lance';\n  att.vx")
rep("  const { a, d, others } = L.rig, { P, A, D, truth } = L, off = L.dOff || { x: 0, y: 0 };", "  const { a, d, others } = L.rig, { P, A, D } = L, truth = L.look || L.truth, off = L.dOff || { x: 0, y: 0 };")
rep("  if (truth === 'siga' || truth === 'falta') {\n    const k = smooth((t - (TC - 0.3)) / 0.3), out", "  if (L.def.role === 'gk') gkPose(L, d, t, dRun);\n  else if (truth === 'siga' || truth === 'falta') {\n    const k = smooth((t - (TC - 0.3)) / 0.3), out")
rep("    else { const c = carry(touchT), u = t - touchT, s = 10 * (1 - Math.exp(-u * 0.8)) / 0.8; bx = c.x + A.x * s; by = c.y + A.y * s; }",
    "    else if (L.ballTo) { const c = carry(touchT), u = t - touchT, bt = L.ballTo, dd = len(bt.x - c.x, bt.y - c.y), dr = norm(bt.x - c.x, bt.y - c.y), s = dd * Math.min(1, (1 - Math.exp(-u * 1.3)) / (1 - Math.exp(-1.3 * 2.1))); bx = c.x + dr.x * s; by = c.y + dr.y * s; }\n"
    "    else { const c = carry(touchT), u = t - touchT, s = 10 * (1 - Math.exp(-u * 0.8)) / 0.8; bx = c.x + A.x * s; by = c.y + A.y * s; }")
rep("  if (truth === 'siga') {\n    const hit = TC - 0.04;", "  if (truth === 'siga' && L.def.role === 'gk') {\n    // o guarda-redes fica com a bola nas mãos\n    const c = carry(Math.min(t, TC - 0.04));\n    if (t <= TC - 0.04) { bx = c.x; by = c.y; } else { d.outer.updateMatrixWorld(true); const hp = d.handR.getWorldPosition(new R3.T.Vector3()); bx = hp.x; by = hp.z; bh = Math.max(0.11, hp.y); }\n  } else if (truth === 'siga') {\n    const hit = TC - 0.04;")
rep("  for (const o of others) {\n    const k = clamp(t - TC, -1.5, 1.5) * 0.6, sp = len(o.o.vx, o.o.vy);", "  for (const o of others) {\n    if (L.ballTo && o.o.id === L.getId) { poseGetter(L, o, t); continue; }\n    const k = clamp(t - TC, -1.5, 1.5) * 0.6, sp = len(o.o.vx, o.o.vy);")
i0 = t.index("function calibFoul(L) {"); i1 = t.index("\n}\n", i0)
cf = t[i0:i1].replace("L.truth", "(L.look || L.truth)").replace("const foot = d.bootR.getWorldPosition(v());", "const foot = (L.def.role === 'gk' ? d.handR : d.bootR).getWorldPosition(v());")
t = t[:i0] + cf + t[i1:]
rep("    armL: B('upperarm01.R'), elL:", "    handL: B('wrist.R'), handR: B('wrist.L'), armL: B('upperarm01.R'), elL:")
rep("    pre(r.hipL, A.hlz); pre(r.hipR, A.hrz); pre(r.armL, A.alz); pre(r.armR, A.arz);", "    pre(r.hipL, A.hlz); pre(r.hipR, A.hrz); pre(r.armL, A.alz); pre(r.armR, A.arz);\n    const X = new T.Vector3(1, 0, 0), preX = (b, a) => { if (a) b.quaternion.premultiply(q.setFromAxisAngle(X, a)); };\n    preX(r.armL, A.alx); preX(r.armR, A.arx);")
# 3D: preparar, posar, legendas
rep("  } else {\n    const a = R.rigs[0], d = R.rigs[1], ref = R.rigs[22];", "  } else if (L.scene) {\n    setupScene(L, R);\n  } else {\n    const a = R.rigs[0], d = R.rigs[1], ref = R.rigs[22];")
rep("    L.others.slice(0, 18).forEach((o, i) => {", "    if (L.getId !== undefined) L.others.sort((p, q) => (q.id === L.getId) - (p.id === L.getId));\n    L.others.slice(0, 18).forEach((o, i) => {")
rep("      : 'Lance aos ' + L.minute + \"'. Qual é a tua decisão?\";", "      : lanceMsg(L);")
rep("$('scKey').textContent = L.kind === 'offside' ? 'Passe' : 'Duelo';", "$('scKey').textContent = KEYLBL[L.kind] || 'Duelo';")
rep("  if (L.kind === 'offside') { poseOffside(L, t); return; }\n  $('pip').hidden = true;", "  if (L.kind === 'offside') { poseOffside(L, t); return; }\n  if (L.scene) { poseScene(L, t); return; }\n  $('pip').hidden = true;")
rep("const keyTime = L => L.kind === 'offside' ? OFF_KT : TC;", "const keyTime = L => L.keyT || (L.kind === 'offside' ? OFF_KT : TC);")
rep("  const off = !!(S && S.lance && S.lance.kind === 'offside');\n  document.querySelectorAll('.foul-choice').forEach(b => b.hidden = off);\n  document.querySelectorAll('.off-choice').forEach(b => b.hidden = !off);", "  choicesFor(S && S.lance);")
# decisões
rep("  if (L.kind === 'offside') { decideOffside(L, d, timedOut); return; }", "  if (L.kind === 'offside') { decideOffside(L, d, timedOut); return; }\n  if (L.scene) { decideScene(L, d, timedOut); return; }")
rep("  } else if (d === 'simulacao') {\n    pts = 0; dc = -11;", "  } else if (d === 'vantagem') {\n    const o = advScore(L); pts = o.pts; dc = o.dc;\n  } else if (d === 'simulacao') {\n    pts = 0; dc = -11;")
rep("    if (diff > 0) S.aggr[defT] += 0.12 * diff;\n  }", "    if (diff > 0) S.aggr[defT] += 0.12 * diff;\n  }\n  if (L.adv && d !== 'vantagem' && FOUL(d) && pts === 1) { pts = 0.7; L.missAdv = true; }")
rep("  } else if (d === 'simulacao') {\n    att.yellow++; b.owner = def;", "  } else if (d === 'vantagem') {\n    msg = advPlay(L);\n  } else if (d === 'simulacao') {\n    att.yellow++; b.owner = def;")
rep("  if (foul) {\n    if (d === 'amarelo')", "  if (foul) {\n    def.fouls = (def.fouls || 0) + 1;\n    if (d === 'amarelo')")
rep("  hide3D(); showDecide(false); toast(msg, 2.6);\n  mode = 'play'; S.pause = Math.max(S.pause, 1.2);", "  feedDecision(L, d, msg);\n  hide3D(); showDecide(false); toast(msg, 2.6);\n  mode = 'play'; S.pause = Math.max(S.pause, 1.2);")
rep("  hide3D(); showDecide(false); toast(msg, 2.4);", "  feedDecision(L, d, msg);\n  hide3D(); showDecide(false); toast(msg, 2.4);")
rep("S.incidents.push(L); stressAfter(L);", "S.incidents.push(L); stressAfter(L); S.added += 0.2;", 2)
rep("function needsVar(L, d) {\n", "function needsVar(L, d) {\n  if (L.scene) return L.inBox && scenePen(L, d) !== scenePen(L, L.truth);\n")
rep("function varEligible(L, d) { return", "function varEligible(L, d) { if (L.scene) return L.inBox && (scenePen(L, d) || scenePen(L, L.truth)); return")
rep("S.varN++;", "S.varN++; S.added += 0.7; feed('O VAR chama o árbitro ao monitor.', 'var');")
# teclas
rep("    const map = S.lance && S.lance.kind === 'offside' ? OKEYS : DKEYS;", "    const map = keyMap(S.lance);")
rep("  if (mode === 'protesto') {", "  if (mode === 'pergunta') { askKey(k); return; }\n  if (mode === 'protesto') {")
# ciclo: perguntas, antijogo, descontos
rep("    if (S.t >= MATCH_SECONDS) { endMatch('fim'); return; }", "    if (S.addMin && S.t >= MATCH_SECONDS * (1 + S.addMin / 90)) { endMatch('fim'); return; }")
rep("    S.crowd += ((S.crowdBase || 35) - S.crowd) * 0.02 * dt; stressStep(dt);", "    S.crowd += ((S.crowdBase || 35) - S.crowd) * 0.02 * dt; stressStep(dt);\n    addedTimeCheck(); pendStep(dt); stallStep(dt);\n    if (mode !== 'play') return;")
rep("  } else if (mode === 'protesto' && S.protest) {", "  } else if (mode === 'pergunta' && S.ask) {\n    askStep(dt); physics(0);\n  } else if (mode === 'protesto' && S.protest) {")
rep("  $('clock').textContent = Math.min(90, Math.floor(S.t / MATCH_SECONDS * 90)) + \"'\";", "  $('clock').textContent = clockTxt();")
# relatório
rep("  const pts = inc.reduce((a, l) => a + l.pts, 0);\n  const acc = inc.length ? pts / inc.length : 0.7;", "  const mg = S.manage || [], pts = inc.reduce((a, l) => a + l.pts, 0) + mg.reduce((a, m) => a + m.pts, 0);\n  const acc = inc.length + mg.length ? pts / (inc.length + mg.length) : 0.7;")
rep("  careerAfter(grade, kind);\n", "  manageRows(); summaryRows();\n  careerAfter(grade, kind);\n")
rep("$('toast').hidden = true; $('protest').hidden = true; S.protest = null;", "$('toast').hidden = true; $('protest').hidden = true; S.protest = null; $('ask').hidden = true; S.ask = null; S.pendCard = null;")
rep("$('toast').hidden = true; $('protest').hidden = true;\n  mode = 'play';", "$('toast').hidden = true; $('protest').hidden = true; $('ask').hidden = true; $('ticker').hidden = true;\n  mode = 'play';")
rep(": LABEL[l.truth];\n    const seen", ": LABEL[l.truth] + (l.why ? ' (' + WHY[l.why] + ')' : '');\n    const seen")
rep("DEC_LABEL[l.decided] + (l.timedOut ? ' (tempo)' : '')", "DEC_LABEL[l.decided] + (l.cardLater && l.cardLater !== 'nenhum' ? ' + ' + DEC_LABEL[l.cardLater].toLowerCase() : '') + (l.timedOut ? ' (tempo)' : '')")
rep("const why = l.training ?", "const why = l.missAdv ? 'Certo, mas havia vantagem' : l.decided === 'vantagem' && l.adv && l.pts < 1 ? 'Vantagem certa, cartão errado' : l.decided === 'vantagem' && !l.adv && l.pts < 1 ? 'Não havia vantagem: a bola era do adversário' : l.training ?")
# relato
rep("  S.score[team]++;\n", "  S.score[team]++; S.added += 0.4;\n")
rep("  Sfx.cheer(team === HOME ? 1 : 0.4); Sfx.whistle('short');", "  Sfx.cheer(team === HOME ? 1 : 0.4); Sfx.whistle('short'); feedGoal(team);")
rep("  S.offsides++;", "  S.offsides++; feed('Bandeira no ar: fora de jogo ' + deT(oi.team) + '.', 'info');")
rep("  S.protests.push({", "  feed(msg + '.', 'info');\n  S.protests.push({")
rep("  Sfx.init(); Sfx.whistle('long');\n}", "  Sfx.init(); Sfx.whistle('long');\n  feed('Apito inicial: ' + TEAMS[0].name + ' contra ' + TEAMS[1].name + '.', 'info');\n}")
# 2D: relógio do antijogo
rep("  for (const a of S.ast) {\n    drawCap(a.x, a.y, CAP_R * 0.8", "  if (S.stall) { const p = S.players[S.stall.id]; ctx.fillStyle = '#f2cf3a'; ctx.font = '700 ' + Math.round(1.5 * s) + 'px \"Barlow Condensed\", sans-serif'; ctx.textAlign = 'center'; ctx.fillText('⏱ ' + Math.ceil(S.stall.t), view.ox + p.x * s, view.oy + (p.y - 1.7) * s); }\n  for (const a of S.ast) {\n    drawCap(a.x, a.y, CAP_R * 0.8")
rep("openCareer, startCareerMatch, endMatch, saveCareer, protestAfter, start,", "openCareer, startCareerMatch, endMatch, saveCareer, protestAfter, startHand, cornerCheck, gkChance, askPick, start,")


# vantagem: a câmara do árbitro acompanha a bola depois da falta, para se ver quem fica com ela
rep("  // ninguém fica colado à câmara\n  for (const o of others) o.r.outer.visible", "  if (L.ballTo && t > TC) { const k = smooth((t - TC) / 1.2), bt = L.ballTo, m2 = { x: (look.x + bt.x) / 2, y: (look.y + bt.y) / 2 }; width = lerp(width, Math.max(width, len(bt.x - look.x, bt.y - look.y) + 6), k); look = { x: lerp(look.x, m2.x, k), y: lerp(look.y, m2.y, k) }; }\n  // ninguém fica colado à câmara\n  for (const o of others) o.r.outer.visible")

# cruzamentos para a área também podem dar empurrões
rep("choices.push({ type: 'pass', m, lofted: lofted || cross, sc });", "choices.push({ type: 'pass', m, lofted: lofted || cross, cross, sc });")
rep("  else if (c.type === 'pass') { passTo(p, c.m, c.lofted); if (!wasSetPiece) offsideSnap(p, c.m); }", "  else if (c.type === 'pass') { passTo(p, c.m, c.lofted); if (!wasSetPiece) offsideSnap(p, c.m); if (c.cross && !wasSetPiece) cornerCheck(p.team, p, true); }")
# estádio novo
i0 = t.index("  const crowd = document.createElement('canvas'); crowd.width = 512;"); i1 = t.index("  addWall(W + 5, H / 2, H + 10, 8, Math.PI / 2);\n") + len("  addWall(W + 5, H / 2, H + 10, 8, Math.PI / 2);\n")
t = t[:i0] + "  const stadium = buildStadium(T, scene);\n" + t[i1:]
rep("R3 = { T, renderer, scene, cam, rigs, ball, sun, lines };", "R3 = { T, renderer, scene, cam, rigs, ball, sun, lines, stadium };")
rep("  R.rigs.forEach(r => r.outer.visible = false);", "  paintStadium();\n  R.rigs.forEach(r => r.outer.visible = false);")
rep("    if (L && L.rig) pose3D(L, Math.min(L.time, lanceDur(L)));", "    animStadium();\n    if (L && L.rig) pose3D(L, Math.min(L.time, lanceDur(L)));")
rep("// ---------- desenho 2D ----------", open('p5.js').read() + '\n' + open('p6.js').read() + '\n' + open('p7.js').read() + '\n// ---------- desenho 2D ----------')
open('game.js', 'w').write(t)
print('phase5 ok')
