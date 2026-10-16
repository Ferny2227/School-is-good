# Mansion Tycoon: cheaper prices, double income, lag viruses removed, and a backyard with 100 more things
# to buy behind every mansion.
#   python3 patch.py <original.rbxl> <fixed.rbxl>
import sys, os, re
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'jeepobby', 'tools'))
from vals import *          # also puts casino/tools on the path
from rbxlw import Editable

SRC = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'src')
PRICE = 0.25      # everything costs a quarter of what it did
INCOME = 2        # bricks are worth twice as much
E = Editable(open(sys.argv[1], 'rb').read())
LOG = []

def by_class(c): return [r for r in list(E.loc) if E.classof(r) == c]
def one(c): r = by_class(c); assert len(r) == 1, c; return r[0]
def kids(r, name=None): return [k for k in E.children(r) if name is None or E.name(k) == name]
def src(r): return E.get_string(r, 'Source').decode('utf8', 'replace')
def setsrc(r, s): E.set_string(r, 'Source', s.encode('utf8'))
def read(name): return open(os.path.join(SRC, name)).read()

WS, SSS, SG, RF = one('Workspace'), one('ServerScriptService'), one('StarterGui'), one('ReplicatedFirst')
T_SCRIPT = next(r for r in by_class('Script') if E.path(r) == 'Workspace.Scripts.vipscript')
T_LOCAL = by_class('LocalScript')[0]
T_PART = next(r for r in by_class('Part') if E.path(r) == 'Workspace.Map.Baseplate')

def nice(n):
    if n < 100: return int(round(n))
    mag = 10 ** (len(str(int(n))) - 2)
    return int(round(n / mag) * mag)
def label(n):
    if n >= 1_000_000:
        s = ('%.2f' % (n / 1e6)).rstrip('0').rstrip('.'); return s + 'M'
    if n >= 1000:
        s = ('%.1f' % (n / 1e3)).rstrip('0').rstrip('.'); return s + 'K'
    return str(n)

# ------------------------------------------------------------------ 1. prices x0.25 (and the price in the button's name)
n_btn = 0
for r in by_class('Script'):
    s = src(r)
    m = re.search(r'Upgradecost\s*=\s*(\d+)', s)
    if not m: continue
    old = int(m.group(1)); new = nice(old * PRICE)
    setsrc(r, s[:m.start(1)] + str(new) + s[m.end(1):])
    btn = E.parent[E.parent[r]]            # Script -> Head -> button model "Pool [90K]"
    name = E.name(btn)
    name2 = re.sub(r'([\[\(])[^\]\)]*([\]\)])', lambda mm: mm.group(1) + ('$' + label(new) if new else 'FREE') + mm.group(2), name, count=1)
    if name2 != name: E.set_string(btn, 'Name', name2)
    n_btn += 1
# class promotions: need 50K / 1M on hand (not charged), and they KILLED you if you didn't have it
n_pro = 0
for r in by_class('Script'):
    s = src(r)
    m = re.search(r'\npromotion\s*=\s*(\d+)', s)
    if not m or 'TeamColor' not in s: continue
    new = nice(int(m.group(1)) * PRICE)
    s = s[:m.start(1)] + str(new) + s[m.end(1):]
    s = s.replace('user.Character:BreakJoints()', '-- (used to kill you here when you were short of money)')
    setsrc(r, s)
    btn = E.parent[E.parent[r]]
    E.set_string(btn, 'Name', re.sub(r'\([^)]*\)', '($' + label(new) + ')', E.name(btn), count=1))
    n_pro += 1
LOG.append('class promotions: %d buttons need a quarter of the money and no longer kill you when you are short' % n_pro)
LOG.append('prices: %d buttons now cost a quarter (e.g. Pool $90K -> $22.5K, Diamond Production $5M -> $1.25M)' % n_btn)

# ------------------------------------------------------------------ 2. income x2
n_inc = 0
for r in by_class('Script'):
    p = E.path(r)
    if '.Get.' in p and 'Cash to collect' in p:
        s = src(r)
        s2 = re.sub(r'math\.random\((\d+)\s*,\s*(\d+)\)', lambda m: 'math.random(%d,%d)' % (int(m.group(1)) * INCOME, int(m.group(2)) * INCOME), s)
        if s2 != s: setsrc(r, s2); n_inc += 1
LOG.append('income: every brick is worth 2x (%d collector scripts)' % n_inc)

# ------------------------------------------------------------------ 3. lag viruses and junk
dead = set()
n_spread = n_empty = 0
for r in by_class('Script'):
    name = E.name(r); s = src(r).strip()
    par = E.parent.get(r)
    if name == 'Spread':      # clones itself into everything its fire touches and grows the fire by 1,000,000
        dead.add(r)
        if par is not None and E.classof(par) == 'Fire': dead.add(par)    # the copied fire goes too
        n_spread += 1
    elif s == '' and (name in ('Wormed', 'Anti-Lag', 'Anti Lag Script') or 'Wormed' in name):
        dead.add(r); n_empty += 1
        # the "OH SNAP YOU GOT INFECTED XD XD XD" holder
        if par is not None and 'INFECTED' in E.name(par): dead.add(par)
    elif 'starter pack deleted' in s:
        dead.add(r)
for r in list(dead):
    dead.update(E.descendants(r))
E.delete(dead)
LOG.append('lag: removed %d "Fire.Spread" virus scripts (with their fires) and %d empty virus scripts' % (n_spread, n_empty))
for r in by_class('Script'):
    if E.name(r) == 'Tycoon Regen':
        E.set_prop(r, 'Disabled', b'\x01')
        LOG.append('turned off the second tycoon reset script (it fought with "Regener" when an owner left)')

# two scripts that never worked: a steering-wheel hint with a syntax error, and an admin tag script that
# crashed on every join (and would have given everyone $5000/s if it hadn't)
for r in by_class('Script'):
    if E.path(r).endswith('Chassis31.SteeringWheel.Script') or E.path(r) == 'Workspace.Scripts.lirldrboard.supervip_manual':
        E.set_prop(r, 'Disabled', b'\x01')
LOG.append('turned off 2 broken scripts (steering-wheel hint, admin tag)')

# ------------------------------------------------------------------ 4. a backyard behind every mansion
SURF = ('Top', 'Bottom', 'Front', 'Back', 'Left', 'Right')
def new_part(parent, name, pos, size, rot, color, mat):
    r = E.add_instance(T_PART, parent, name)
    E.set_prop(r, 'Anchored', b'\x01')
    E.set_prop(r, 'CFrame', CFRAME(pos, rot))
    E.set_prop(r, 'size', VEC3(*size))
    E.set_prop(r, 'BrickColor', U32(color))
    E.set_prop(r, 'Material', U32(mat))
    E.set_prop(r, 'Transparency', F32(0))
    E.set_prop(r, 'CanCollide', b'\x01')
    E.set_prop(r, 'Locked', b'\x01')
    E.set_prop(r, 'formFactorRaw', U32(3))
    for s in SURF:
        E.set_prop(r, s + 'Surface', U32(0))
    return r
GROUND = 2.4               # top of the tycoon floors
YARD_W, YARD_D = 182, 196  # 10 x 10 cells of 18 studs + a 14 stud path at the mansion end
n_yard = 0
for t in kids(WS, 'tycoon'):
    pts = []
    for d in E.descendants(t):
        if E.classof(d) in ('Part', 'WedgePart', 'TrussPart'):
            p, R = cframe(E.prop(d, 'CFrame')[1]); s = vec3(E.prop(d, 'size')[1])
            h = [abs(R[3 * i]) * s[0] / 2 + abs(R[3 * i + 1]) * s[1] / 2 + abs(R[3 * i + 2]) * s[2] / 2 for i in range(3)]
            pts.append(([p[i] - h[i] for i in range(3)], [p[i] + h[i] for i in range(3)]))
    x0 = min(a[0][0] for a in pts); x1 = max(a[1][0] for a in pts)
    z0 = min(a[0][2] for a in pts); z1 = max(a[1][2] for a in pts)
    cx = (x0 + x1) / 2
    if z1 > 0:     # south row: the back of the plot is at +z
        pos, rot = (cx, GROUND - 1, z1 + YARD_D / 2), None
    else:          # north row: back at -z (rotate so the backyard's +z points away from the mansion)
        pos, rot = (cx, GROUND - 1, z0 - YARD_D / 2), [-1, 0, 0, 0, 1, 0, 0, 0, -1]
    new_part(t, 'BackyardBase', pos, (YARD_W, 2, YARD_D), rot, 37, 1280)   # Bright green, Grass
    n_yard += 1
LOG.append('added a %dx%d backyard behind each of the %d mansions' % (YARD_W, YARD_D, n_yard))

# ------------------------------------------------------------------ 5. scripts
def add_script(tmpl, parent, name, source):
    r = E.add_instance(tmpl, parent, name)
    E.set_prop(r, 'Disabled', b'\x00')
    setsrc(r, source)
    return r
srv = add_script(T_SCRIPT, SSS, 'Backyard', read('Backyard.server.lua'))
ui = add_script(T_LOCAL, SG, 'BackyardClient', read('BackyardUI.client.lua'))
add_script(T_LOCAL, RF, 'errorReport', read('errorReport.client.lua'))
rel = add_script(T_SCRIPT, SSS, 'errorRelay', read('errorRelay.server.lua'))
LOG.append('added the Backyard server script, the backyard button/counter UI, and the on-screen error box')

data = E.save()
open(sys.argv[2], 'wb').write(data)
for l in LOG: print(l)
print('wrote', sys.argv[2], len(data), 'bytes')
