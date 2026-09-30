import sys, numpy as np, retarget as rt
from PIL import Image, ImageDraw
def model_fk(qs, rp):
    n = len(rt.BONES); W = [None] * n; P = [None] * n
    for i in range(n):
        p = rt.PAR[i]; L = rt.q2m(qs[i])
        if p < 0: W[i] = L; P[i] = rt.JO[i] + rp
        else: W[i] = W[p] @ L; P[i] = P[p] + W[p] @ (rt.JO[i] - rt.JO[p])
    # ponta do pé
    tips = {}
    for s in 'LR':
        i = rt.BONES.index('foot.' + s); tips[s] = P[i] + W[i] @ np.array([0, -0.06, 0.2])
    return np.array(P), tips
def sheet(name, Q, RP, n=16):
    W_, H_ = 200, 230
    idx = np.linspace(0, len(Q) - 1, n).astype(int)
    im = Image.new('RGB', (W_ * 8, H_ * 4), 'white'); d = ImageDraw.Draw(im)
    for k, f in enumerate(idx):
        P, tips = model_fk(Q[f], RP[f])
        for view in range(2):
            ox, oy = (k % 8) * W_, (k // 8) * 2 * H_ + view * H_
            ax = 2 if view == 0 else 0; s = 90
            pt = lambda p: (ox + W_ / 2 + p[ax] * s, oy + H_ - 12 - p[1] * s)
            for i, p in enumerate(rt.PAR):
                if p < 0: continue
                col = 'red' if rt.BONES[i].endswith('.L') else ('blue' if rt.BONES[i].endswith('.R') else 'black')
                d.line([pt(P[p]), pt(P[i])], fill=col, width=2)
            for s_, c in (('L', 'red'), ('R', 'blue')): d.line([pt(P[rt.BONES.index('foot.' + s_)]), pt(tips[s_])], fill=c, width=2)
            d.line([(ox, oy + H_ - 12), (ox + W_, oy + H_ - 12)], fill='gray')
            d.text((ox + 3, oy + 3), '%s f%d %s' % (name, f, 'lado' if view == 0 else 'frente'), fill='black')
    im.save('model_%s.png' % name)
if __name__ == '__main__':
    c, t0, t1 = sys.argv[1], float(sys.argv[2]), float(sys.argv[3]); ip = len(sys.argv) > 4
    Q, RP, sc = rt.retarget(c, t0, t1, inplace=ip)
    print('frames', len(Q), 'scale', sc, 'root y range', RP[:, 1].min(), RP[:, 1].max())
    sheet(c, Q, RP)
