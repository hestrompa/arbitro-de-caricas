import sys, json
from PIL import Image, ImageDraw
src, out = sys.argv[1], sys.argv[2]
title = sys.argv[3] if len(sys.argv) > 3 else ''
fr = [json.loads(l[2:]) for l in open(src) if l.startswith('F ')]
K = 7; W, H = 105, 68; M = 12
imgs = []
for f in fr[::2]:
    im = Image.new('RGB', (W*K+2*M, H*K+2*M+22), (40, 110, 50)); d = ImageDraw.Draw(im)
    X = lambda x: M + x*K; Y = lambda y: M + 22 + y*K
    d.rectangle([X(0), Y(0), X(W), Y(H)], outline=(230,230,230))
    d.line([X(W/2), Y(0), X(W/2), Y(H)], fill=(230,230,230))
    d.ellipse([X(W/2)-9.15*K, Y(H/2)-9.15*K, X(W/2)+9.15*K, Y(H/2)+9.15*K], outline=(230,230,230))
    for gx, s in ((0, 1), (W, -1)):
        d.rectangle(sorted([X(gx), X(gx+s*16.5)]) and [min(X(gx),X(gx+s*16.5)), Y(H/2-20.15), max(X(gx),X(gx+s*16.5)), Y(H/2+20.15)], outline=(230,230,230))
    for t, x, y, o, r, role in f['p']:
        c = (220, 40, 40) if t == 0 else (40, 80, 220)
        if role == 'gk': c = (240, 200, 40) if t == 0 else (40, 200, 200)
        rr = 0.9*K
        d.ellipse([X(x)-rr, Y(y)-rr, X(x)+rr, Y(y)+rr], fill=c, outline=(255,255,255) if o else ((0,0,0) if not r else (255,150,0)), width=3 if (o or r) else 1)
    bx, by, bz = f['b']
    d.ellipse([X(bx)-4-bz*2, Y(by)-4-bz*2, X(bx)+4+bz*2, Y(by)+4+bz*2], fill=(255,255,255), outline=(0,0,0))
    d.text((M, 4), '%s  t=%.1f  %s  (vermelhos atacam para a %s)' % (title, f['t'], f['m'], 'direita' if f['d0'] > 0 else 'esquerda'), fill=(255,255,255))
    imgs.append(im)
imgs[0].save(out, save_all=True, append_images=imgs[1:], duration=133, loop=0)
print(len(imgs), 'frames')
