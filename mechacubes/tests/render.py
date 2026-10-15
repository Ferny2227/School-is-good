# Draws a GUI dump (from DUMP=file python3 run.py ...) into a PNG, like a screenshot of the GUI.
#   python3 render.py dump.json out.png [--old]
# --old draws like a 2016 engine: ZIndex is clamped to 1..10 (newer engines allow any value).
import sys, json
from PIL import Image, ImageDraw, ImageFont

d = json.load(open(sys.argv[1]))
old = '--old' in sys.argv or d['api'] in ('v227', 'v270')
items = d['items']
W = int(max([1366] + [0])); H = 768 - 36
img = Image.new('RGB', (W, H + 36), (70, 110, 70))   # green = the 3D world behind the GUI
dr = ImageDraw.Draw(img, 'RGBA')
dr.rectangle([0, 0, W, 36], fill=(30, 30, 30))       # roblox topbar
try:
    FONT = '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
    ImageFont.truetype(FONT, 12)
except Exception:
    FONT = None

def font(size):
    size = max(6, int(size))
    if FONT: return ImageFont.truetype(FONT, size)
    return ImageFont.load_default()

def zkey(it):
    z = it['z']
    if old: z = max(1, min(10, z))
    return (it['gui'], z, it['order'])

for it in sorted(items, key=zkey):
    x, y, w, h = it['x'], it['y'] + 36, it['w'], it['h']
    if w <= 0 or h <= 0: continue
    if x > W or y > H + 36 or x + w < 0 or y + h < 0: continue
    a = int(255 * (1 - max(0, min(1, it['bgt']))))
    if a > 0:
        c = tuple(int(255 * v) for v in it['bg'])
        dr.rectangle([x, y, x + w, y + h], fill=c + (a,))
    if it.get('image') and it['it'] < 1:
        # images can't be loaded here (or on most revivals): show where they are
        ia = int(90 * (1 - it['it']))
        c = tuple(int(255 * v) for v in it['ic'])
        dr.rectangle([x, y, x + w, y + h], outline=c + (ia + 60,))
    t = it.get('text')
    if t and it['tt'] < 1:
        ta = int(255 * (1 - it['tt']))
        c = tuple(int(255 * v) for v in it['tc'])
        if it['scaled']:
            size = max(6, min(h * 0.8, (w / max(1, len(t))) * 1.8))
        else:
            size = it['ts'] or 14
            if old and it.get('fontsize'):
                try: size = int(it['fontsize'].replace('Size', ''))
                except ValueError: pass
        f = font(size)
        tw = dr.textlength(t, font=f)
        dr.text((x + (w - tw) / 2, y + (h - size) / 2), t, font=f, fill=c + (ta,))
img.save(sys.argv[2])
print('saved', sys.argv[2], len(items), 'items', '(2016 drawing rules)' if old else '')
