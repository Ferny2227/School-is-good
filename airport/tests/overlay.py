# Top-down map of a plot from a parts dump, with passenger routes (lines) and plane positions (dots) on top.
#   python3 overlay.py parts.txt trace.txt out.png x0 x1 z0 z1
import sys
from PIL import Image, ImageDraw
sys.argv += []
parts_f, trace_f, out = sys.argv[1:4]
x0, x1, z0, z1 = (float(v) for v in sys.argv[4:8])
S = 1600 / (x1 - x0)
W, H = 1600, int((z1 - z0) * S)
img = Image.new('RGB', (W, H), (60, 120, 60)); d = ImageDraw.Draw(img, 'RGBA')
def P(x, z): return ((x - x0) * S, (z - z0) * S)
from render3d_pal import PAL
rows = []
for line in open(parts_f):
    f = line.rstrip('\n').split('|')
    if f[0] not in ('plot', 'map'): continue
    pos = [float(v) for v in f[3].split()]; size = [float(v) for v in f[4].split()]
    R = [float(v) for v in f[5].split()]; U = [float(v) for v in f[6].split()]; L = [float(v) for v in f[7].split()]
    tr = float(f[9])
    if tr >= 0.9 or not (x0 - 50 < pos[0] < x1 + 50 and z0 - 50 < pos[2] < z1 + 50): continue
    if pos[1] > 27: continue   # skip the roof and things above it
    col = PAL.get(f[11].lstrip('#'), (128, 128, 128))
    hx, hy, hz = size[0] / 2, size[1] / 2, size[2] / 2
    pts = []
    for sx in (-1, 1):
        for sy in (-1, 1):
            for sz in (-1, 1):
                wx = pos[0] + R[0] * sx * hx + U[0] * sy * hy - L[0] * sz * hz
                wz = pos[2] + R[2] * sx * hx + U[2] * sy * hy - L[2] * sz * hz
                pts.append(P(wx, wz))
    pts = sorted(set(pts))
    def cross(o, a, b): return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])
    lower, upper = [], []
    for q in pts:
        while len(lower) >= 2 and cross(lower[-2], lower[-1], q) <= 0: lower.pop()
        lower.append(q)
    for q in reversed(pts):
        while len(upper) >= 2 and cross(upper[-2], upper[-1], q) <= 0: upper.pop()
        upper.append(q)
    corners = lower[:-1] + upper[:-1]
    if len(corners) < 3: continue
    top = pos[1] + abs(U[1]) * hy
    rows.append((top, corners, col, int(255 * (1 - tr))))
rows.sort(key=lambda r: r[0])
for top, c, col, a in rows: d.polygon(c, fill=col + (a,), outline=(0, 0, 0, 50))
for line in open(trace_f):
    w = line.split()
    if w[0] == 'route':
        pts = [tuple(float(v) for v in p.split(',')) for p in w[2:]]
        d.line([P(p[0], p[2]) for p in pts], fill=(255, 0, 255, 150) if w[1] == 'Passenger' else (255, 200, 0, 255), width=2)
    elif w[0] == 'plane':
        x, y, z = float(w[3]), float(w[4]), float(w[5])
        if y < 1000:
            c = P(x, z); r = 3 if y < 20 else 2
            d.ellipse([c[0] - r, c[1] - r, c[0] + r, c[1] + r], fill=(0, 255, 255, 255) if w[2] == 'departing' else (255, 80, 0, 255))
img.save(out); print('saved', out, W, H)
