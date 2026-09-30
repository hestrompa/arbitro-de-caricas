import sys, numpy as np, bvh
from PIL import Image, ImageDraw
c = sys.argv[1]; t0 = float(sys.argv[2]) if len(sys.argv) > 2 else 0; t1 = float(sys.argv[3]) if len(sys.argv) > 3 else None; n = 16
b = bvh.load(c + '.bvh'); pos, rot = bvh.fk(b); N = b['names']; par = b['parents']; ft = b['ft']
F = len(pos); t1 = t1 or F * ft
fr = [min(F - 1, max(1, int((t0 + (t1 - t0) * k / (n - 1)) / ft))) for k in range(n)]
W_, H_ = 220, 260
im = Image.new('RGB', (W_ * 8, H_ * 4), 'white'); d = ImageDraw.Draw(im)
for k, f in enumerate(fr):
    for view in range(2):
        ox, oy = (k % 8) * W_, (k // 8) * 2 * H_ // 1 + view * H_
        if oy >= H_ * 4: continue
        P = pos[f]; hip = P[N.index('Hips')]
        ax = 2 if view == 0 else 0   # vista lateral (z horizontal) e frontal (x horizontal)
        s = 5
        def pt(p): return (ox + W_ / 2 + (p[ax] - hip[ax]) * s, oy + H_ - 10 - p[1] * s)
        for j, p in enumerate(par):
            if p < 0 or N[j].endswith('_end'): continue
            col = 'red' if 'Left' in N[j] or N[j].startswith('L') else ('blue' if 'Right' in N[j] or N[j].startswith('R') else 'black')
            d.line([pt(P[p]), pt(P[j])], fill=col, width=2)
        d.line([(ox, oy + H_ - 10), (ox + W_, oy + H_ - 10)], fill='gray')
        d.text((ox + 4, oy + 4), '%s %.2fs %s' % (c, f * ft, 'lado(z)' if view == 0 else 'frente(x)'), fill='black')
im.save('sheet_%s.png' % c)
