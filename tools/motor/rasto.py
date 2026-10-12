import json, sys
from PIL import Image, ImageDraw
W, H = 105.0, 68.0
fr = json.load(open(sys.argv[1]))
out = sys.argv[2]
mode = sys.argv[3] if len(sys.argv) > 3 else "remates"
K = 6.0  # px por metro
def draw(f, title=""):
    im = Image.new("RGB", (int(W*K)+20, int(H*K)+40), (40, 110, 50))
    d = ImageDraw.Draw(im)
    ox, oy = 10, 30
    def P(x, y): return (ox + x*K, oy + y*K)
    d.rectangle([P(0,0), P(W,H)], outline=(230,230,230))
    d.line([P(W/2,0), P(W/2,H)], fill=(230,230,230))
    for gx, s in ((0, 1), (W, -1)):
        d.rectangle([P(min(gx, gx+s*16.5), H/2-20.15), P(max(gx, gx+s*16.5), H/2+20.15)], outline=(230,230,230))
        d.rectangle([P(min(gx, gx-s*1.5), H/2-3.66), P(max(gx, gx-s*1.5), H/2+3.66)], fill=(255,255,255))
    for i, p in enumerate(f["ps"]):
        t, role, x, y, run, num = p[:6]
        if len(p) > 6 and p[6] != 0:
            d.line([P(x, y), P(p[6], p[7])], fill=(255, 180, 180) if t == 0 else (180, 200, 255), width=1)
        c = (220, 40, 40) if t == 0 else (40, 90, 230)
        if role == "gk": c = (240, 200, 40) if t == 0 else (40, 220, 220)
        r = 1.0*K
        x0, y0 = P(x, y)
        d.ellipse([x0-r, y0-r, x0+r, y0+r], fill=c, outline=(255,255,255) if run else (0,0,0), width=2 if run else 1)
        d.text((x0-4, y0-5), str(num), fill=(255,255,255))
    bx, by, bz = f["b"]
    x0, y0 = P(bx, by)
    r = 0.55*K + bz*1.5
    d.ellipse([x0-r, y0-r, x0+r, y0+r], fill=(255,255,255), outline=(0,0,0))
    att = "verm -> dir" if f["d0"] > 0 else "verm -> esq"
    d.text((10, 8), "t=%.1f  %s  %s  %s %s" % (f["t"], f["sc"], att, f["ev"], title), fill=(255,255,255))
    return im
# instantes de remate: grelha 3x3 dos 4 s antes
idx = [i for i, f in enumerate(fr) if f["ev"] == "remate"]
if mode == "t":
    ts = [float(x) for x in sys.argv[6].split(",")]
    idx = [min(range(len(fr)), key=lambda q: abs(fr[q]["t"]-(tt+4.0))) for tt in ts]
n = int(sys.argv[4]) if len(sys.argv) > 4 else 4
start = int(sys.argv[5]) if len(sys.argv) > 5 else 0
for k, i in enumerate(idx[start:start+n]):
    t1 = fr[i]["t"]
    want = [t1 - 4.0 + j*0.5 for j in range(9)]
    sel = []
    for w in want:
        j = min(range(len(fr)), key=lambda q: abs(fr[q]["t"]-w))
        sel.append(fr[j])
    tiles = [draw(f) for f in sel]
    tw, th = tiles[0].size
    sheet = Image.new("RGB", (tw*3, th*3))
    for j, tl in enumerate(tiles): sheet.paste(tl, ((j%3)*tw, (j//3)*th))
    sheet = sheet.resize((tw*3*2//3, th*3*2//3))
    sheet.save("%s_%d.png" % (out, k+start))
print(len(idx), "remates")
