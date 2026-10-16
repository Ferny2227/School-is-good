# Renders a parts dump (tests/dump.lua) as a shaded isometric picture.
#   python3 render3d.py parts.txt out.png --center x,y,z --size 700 --yaw 35 --pitch 35 [--tags plot,map] [--w 1600 --h 1000]
import sys, math, argparse
from PIL import Image, ImageDraw
ap = argparse.ArgumentParser()
ap.add_argument('dump'); ap.add_argument('out')
ap.add_argument('--center', default='0,0,0'); ap.add_argument('--size', type=float, default=700)
ap.add_argument('--yaw', type=float, default=35); ap.add_argument('--pitch', type=float, default=35)
ap.add_argument('--tags', default='plot,map,sky'); ap.add_argument('--w', type=int, default=1600); ap.add_argument('--h', type=int, default=1000)
ap.add_argument('--radius', type=float, default=0, help='only parts within this distance (xz) of the centre')
a = ap.parse_args()
cx, cy, cz = (float(v) for v in a.center.split(','))
tags = set(a.tags.split(','))
yaw, pitch = math.radians(a.yaw), math.radians(a.pitch)
# camera basis: looking down at `pitch`, rotated by `yaw` around y
fwd = (math.sin(yaw) * math.cos(pitch), -math.sin(pitch), math.cos(yaw) * math.cos(pitch))
right = (math.cos(yaw), 0, -math.sin(yaw))
up = (right[1] * fwd[2] - right[2] * fwd[1], right[2] * fwd[0] - right[0] * fwd[2], right[0] * fwd[1] - right[1] * fwd[0])
up = tuple(-x for x in up) if up[1] < 0 else up
S = a.w / a.size
def proj(p):
    d = (p[0] - cx, p[1] - cy, p[2] - cz)
    sx = d[0] * right[0] + d[1] * right[1] + d[2] * right[2]
    sy = d[0] * up[0] + d[1] * up[1] + d[2] * up[2]
    depth = d[0] * fwd[0] + d[1] * fwd[1] + d[2] * fwd[2]
    return (a.w / 2 + sx * S, a.h / 2 - sy * S), depth
PAL = {  # Roblox BrickColor RGB, by name and number
 'Institutional white': (248, 248, 248), '1001': (248, 248, 248), 'White': (242, 243, 243), 'Bright green': (75, 151, 75), '37': (75, 151, 75),
 'Dark green': (40, 127, 71), '28': (40, 127, 71), 'Earth green': (39, 70, 45), '141': (39, 70, 45), 'Medium stone grey': (163, 162, 165), '194': (163, 162, 165),
 'Dark stone grey': (99, 95, 98), '199': (99, 95, 98), 'Really black': (17, 17, 17), '1003': (17, 17, 17), 'Bright yellow': (245, 205, 48), '24': (245, 205, 48),
 'Brick yellow': (215, 197, 154), '5': (215, 197, 154), 'Bright blue': (13, 105, 172), '23': (13, 105, 172), 'Medium blue': (110, 153, 202), '102': (110, 153, 202),
 'Bright red': (196, 40, 28), '21': (196, 40, 28), 'Light stone grey': (229, 228, 223), '208': (229, 228, 223), 'New Yeller': (255, 255, 0), '1009': (255, 255, 0),
 'Lime green': (0, 255, 0), '1020': (0, 255, 0), 'Cyan': (4, 175, 236), '1013': (4, 175, 236), 'Reddish brown': (105, 64, 40), '192': (105, 64, 40),
 'Navy blue': (0, 32, 96), '1012': (33, 84, 185), 'Really red': (255, 0, 0), '1004': (255, 0, 0), 'Bright orange': (218, 133, 65), 'Royal purple': (98, 37, 209),
 'Hot pink': (255, 0, 191), 'Teal': (18, 238, 212), 'Pastel light blue': (175, 221, 255), 'Brown': (124, 92, 70), 'Gold': (239, 184, 56), 'Nougat': (204, 142, 105),
 'Light orange': (234, 184, 146), 'Pastel brown': (255, 204, 153), 'Sand blue': (116, 134, 157), 'Pink': (255, 102, 204), 'Neon orange': (213, 115, 61),
 'Cool yellow': (253, 234, 141), 'Bright violet': (107, 50, 124), 'Toothpaste': (0, 255, 255),
}
light = (0.4, 0.8, -0.45)
ln = math.sqrt(sum(x * x for x in light)); light = tuple(x / ln for x in light)
faces = []
for line in open(a.dump):
    f = line.rstrip('\n').split('|')
    if len(f) < 11 or f[0] not in tags: continue
    pos = [float(x) for x in f[3].split()]; size = [float(x) for x in f[4].split()]
    if a.radius and math.hypot(pos[0] - cx, pos[2] - cz) > a.radius: continue
    R = [float(x) for x in f[5].split()]; Up = [float(x) for x in f[6].split()]; L = [float(x) for x in f[7].split()]
    B = [-x for x in L]   # back vector = +z of the part
    col = tuple(int(float(x)) for x in f[8].split()); tr = float(f[9])
    cname = f[11].lstrip('#') if len(f) > 11 else ''
    if cname in PAL: col = PAL[cname]
    big = size[0] > 300 or size[2] > 300 or ((size[0] > 60 or size[2] > 60) and size[1] < 3)
    if tr >= 0.95: continue
    shape = f[10] if len(f) > 10 else 'Block'
    hx, hy, hz = size[0] / 2, size[1] / 2, size[2] / 2
    if shape == 'Ball' and max(size) - min(size) < 0.01: hx = hy = hz = hx * 0.8
    def corner(sx, sy, sz):
        return tuple(pos[i] + R[i] * sx * hx + Up[i] * sy * hy + B[i] * sz * hz for i in range(3))
    quads = [((1, -1, -1), (1, 1, -1), (1, 1, 1), (1, -1, 1), R), ((-1, -1, 1), (-1, 1, 1), (-1, 1, -1), (-1, -1, -1), [-x for x in R]),
             ((-1, 1, -1), (-1, 1, 1), (1, 1, 1), (1, 1, -1), Up), ((-1, -1, 1), (-1, -1, -1), (1, -1, -1), (1, -1, 1), [-x for x in Up]),
             ((-1, -1, 1), (1, -1, 1), (1, 1, 1), (-1, 1, 1), B), ((1, -1, -1), (-1, -1, -1), (-1, 1, -1), (1, 1, -1), [-x for x in B])]
    for q in quads:
        n = q[4]
        if n[0] * fwd[0] + n[1] * fwd[1] + n[2] * fwd[2] >= 0: continue  # facing away
        pts, dep = [], 0
        for c in q[:4]:
            s, d = proj(corner(*c)); pts.append(s); dep += d
        shade = 0.55 + 0.45 * max(0, n[0] * light[0] + n[1] * light[1] + n[2] * light[2])
        top = pos[1] + abs(Up[1]) * hy
        faces.append(((1e7 - top * 1000) if big else dep / 4, pts, tuple(min(255, int(c * shade)) for c in col), int(255 * (1 - tr))))
faces.sort(key=lambda f: -f[0])
img = Image.new('RGB', (a.w, a.h), (150, 190, 235))
d = ImageDraw.Draw(img, 'RGBA')
for dep, pts, col, alpha in faces:
    d.polygon(pts, fill=col + (alpha,), outline=(0, 0, 0, 40) if alpha > 200 else None)
img.save(a.out)
print('rendered', len(faces), 'faces to', a.out)
