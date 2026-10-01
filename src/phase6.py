t = open('game.js').read()


def rep(a, b, cnt=1):
    global t
    assert t.count(a) == cnt, (a, t.count(a))
    t = t.replace(a, b)


# estado novo: livres, treinadores, gestos do árbitro, lances de golo, jornal
rep("manage: [], added: 0,", "manage: [], fk: null, coach: null, coachW: [0, 0], coachOff: [false, false], coachN: 0, gesture: null, lastOff: null, anulados: 0, paper: null, added: 0,")
rep("Object.assign(b, { owner: null, kicker: p, vx: n.x * sp, vy: n.y * sp, vz: pen", "Object.assign(b, { owner: null, kicker: p, shotFrom: { x: p.x, y: p.y }, vx: n.x * sp, vy: n.y * sp, vz: pen")
# golos: o lance é revisto antes de contar
rep("function goal(team) {\n", "function goalAward(team) {\n")
rep("  if (oi && best.id === oi.receiver && oi.margin > -1.0 && !best.off) {", "  if (oi && best.id === oi.receiver && oi.margin > -1.8 && oi.margin <= 1.2 && !best.off) S.lastOff = { oi, t: S.t, n: S.incidents.length, o: S.offsides };\n  if (oi && best.id === oi.receiver && oi.margin > -1.0 && !best.off) {")
rep("  if (handCheck(best, sp)) return;\n", "  if (handCheck(best, sp)) return;\n  if (lineCheck(best, sp)) return;\n")
rep("  if (L.scene) { decideScene(L, d, timedOut); return; }", "  if (L.scene && L.goalCtx) { decideGoal(L, d, timedOut); return; }\n  if (L.scene) { decideScene(L, d, timedOut); return; }")
rep("      if (!msg) msg = 'Livre para ' + artT(att.team);", "      if (!msg) msg = 'Livre para ' + artT(att.team);\n      fkCheck(att);")
rep("  if (d === 'fora') { flagOffside(L.oi); msg = 'Fora de jogo: livre para '", "  if (L.goal !== undefined) msg = goalVerdict(L, d !== 'fora');\n  else if (d === 'fora') { flagOffside(L.oi); msg = 'Fora de jogo: livre para '")
rep("function needsVar(L, d) {\n", "function needsVar(L, d) {\n  if (L.goalCtx && L.kind !== 'offside') return d !== L.truth;\n")
rep("function varEligible(L, d) { if (L.scene)", "function varEligible(L, d) { if (L.goalCtx) return true; if (L.scene)")
rep("if (L.decideT <= 0) decide('siga', true);", "if (L.decideT <= 0) decide(L.dflt || 'siga', true);")
rep("    $('decideMsg').textContent = L.kind === 'offside'\n      ? 'Passe aos ", "    $('decideMsg').textContent = L.kind === 'offside' && L.goal !== undefined ? goalOffMsg(L) : L.kind === 'offside'\n      ? 'Passe aos ")
rep("  if (L.kind === 'offside') { poseOffside(L, t); return; }\n  if (L.scene) { poseScene(L, t); return; }", "  if (!L.scene) glassPosts(null);\n  if (L.kind === 'offside') { poseOffside(L, t); return; }\n  if (L.scene) { poseScene(L, t); return; }")
rep("R3 = { T, renderer, scene, cam, rigs, ball, sun, lines, stadium };", "R3 = { T, renderer, scene, cam, rigs, ball, sun, lines, stadium, postMat };")
# o árbitro comunica a decisão em 3D antes de o jogo seguir
rep("  feedDecision(L, d, msg);\n  hide3D(); showDecide(false); toast(msg, 2.6);\n  mode = 'play'; S.pause = Math.max(S.pause, 1.2);\n  protestAfter(against, sev, wrong);\n  if (S.control <= 10) endMatch('abandonado');\n}",
    "  feedDecision(L, d, msg);\n  finishDecision(L, d, msg, () => {\n    hide3D(); toast(msg, 2.6);\n    mode = 'play'; S.pause = Math.max(S.pause, 1.2);\n    protestAfter(against, sev, wrong);\n    if (S.control <= 10) endMatch('abandonado');\n  });\n}")
rep("  feedDecision(L, d, msg);\n  hide3D(); showDecide(false); toast(msg, 2.4);\n  mode = 'play'; S.pause = Math.max(S.pause, 1);\n  protestAfter(against, d === 'fora' ? 0.28 : 0.18, !ok);\n  if (S.control <= 10) endMatch('abandonado');\n}",
    "  feedDecision(L, d, msg);\n  finishDecision(L, d, msg, () => {\n    hide3D(); toast(msg, 2.4);\n    mode = 'play'; S.pause = Math.max(S.pause, 1);\n    protestAfter(against, d === 'fora' ? 0.28 : 0.18, !ok);\n    if (S.control <= 10) endMatch('abandonado');\n  });\n}")
rep("    addedTimeCheck(); pendStep(dt); stallStep(dt);\n", "    addedTimeCheck(); pendStep(dt); stallStep(dt); fkStep(dt); coachStep(dt);\n")
rep("  } else if (mode === 'pergunta' && S.ask) {", "  } else if (mode === 'gesto' && S.gesture) {\n    gestureStep(dt);\n  } else if (mode === 'pergunta' && S.ask) {")
rep("    if (L && L.rig) pose3D(L, Math.min(L.time, lanceDur(L)));", "    if (mode === 'gesto' && S.gesture) poseGesture(S.gesture);\n    else if (L && L.rig) pose3D(L, Math.min(L.time, lanceDur(L)));")
rep("  if (mode === 'pergunta') { askKey(k); return; }", "  if (mode === 'gesto') { if (k === ' ' || k === 'Enter' || k === 'Escape') { gestureEnd(); e.preventDefault(); } return; }\n  if (mode === 'pergunta') { askKey(k); return; }")
# fim do jogo: jornal e limpeza
rep("S.ask = null; S.pendCard = null;", "S.ask = null; S.pendCard = null; S.fk = null; S.coach = null; S.gesture = null; $('refSay').hidden = true;")
rep("$('ask').hidden = true; $('ticker').hidden = true;", "$('ask').hidden = true; $('ticker').hidden = true; $('refSay').hidden = true;")
rep("  careerAfter(grade, kind);\n", "  paperShow(grade, kind);\n  careerAfter(grade, kind);\n")
rep("LABEL[l.truth] + (l.why ? ' (' + WHY[l.why] + ')' : '');", "LABEL[l.truth] + (l.why ? ' (' + WHY[l.why] + ')' : '') + (l.kind === 'linha' ? ' · ' + Math.abs(Math.round((l.m - LINE_IN) * 100)) + ' cm ' + (l.m >= LINE_IN ? 'para lá' : 'a faltar') : '') + (l.goal !== undefined && l.kind === 'offside' ? ' · no golo' : '');")
rep("  for (const a of S.ast) {\n    drawCap(a.x, a.y, CAP_R * 0.8", "  drawFK();\n  for (const a of S.ast) {\n    drawCap(a.x, a.y, CAP_R * 0.8")
rep("function protestAfter(team, sev, wrong) {\n  if (team === null || team === undefined || mode !== 'play' || S.training) return;\n", "function protestAfter(team, sev, wrong) {\n  if (team === null || team === undefined || mode !== 'play' || S.training) return;\n  coachCheck(team, sev, wrong);\n")
# carreira 2.0
rep("  if (!C) newCareer();\n", "  if (!C) newCareer();\n  migrateCareer();\n")
rep("  C.sg.push(g);\n", "  C.sg.push(g);\n  career2(g);\n")
rep("  msg += ' +' + gain", "  if (C.posNote) msg += ' ' + C.posNote;\n  msg += ' +' + gain")
rep("function endSeason(news, tier) {\n  C.news = news;", "function endSeason(news, tier) {\n  C.news = news + (C.rankNote ? ' ' + C.rankNote : ''); C.rankNote = '';")
rep("C.fixtures = makeFixtures(C.tier);\n}", "C.fixtures = makeFixtures(C.tier); C.refs = makeRefs(C.tier, 0);\n}")
rep("  $('carFinals').hidden = !C.finals;", "  renderCareer2();\n  $('carFinals').hidden = !C.finals;")
rep("startHand, cornerCheck, gkChance, askPick,", "startHand, cornerCheck, gkChance, askPick, startGoalFoul, startLine, fkCheck, gestureEnd, goal, renderCareer,")
rep("// ---------- desenho 2D ----------", open('p8.js').read() + '\n' + open('p9.js').read() + '\n' + open('p10.js').read() + '\n// ---------- desenho 2D ----------')
open('game.js', 'w').write(t)
print('phase6 ok')
