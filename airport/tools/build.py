# Builds AirportTycoon.rbxl: takes a 2016 place as a container (Mansion Tycoon: it has all the classes we
# need), removes everything in it, bakes the world (ground, ocean, the big runway, roads, plaza, 10 plots,
# trees, lamps) and adds the scripts.
#   python3 build.py <base.rbxl> <out.rbxl>
import sys, os, glob, random
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import catalog as CAT
sys.path.insert(0, os.path.join(HERE, '..', '..', 'jeepobby', 'tools'))
from vals import *          # also puts casino/tools on the path
from rbxlw import Editable

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
SRC = os.path.join(ROOT, 'src')
random.seed(2016)
E = Editable(open(sys.argv[1], 'rb').read())
LOG = []

def by_class(c): return [r for r in list(E.loc) if E.classof(r) == c]
def one(c): r = by_class(c); assert len(r) == 1, c; return r[0]
def kids(r, name=None): return [k for k in E.children(r) if name is None or E.name(k) == name]

WS, SSS, SG, RF, RSv, SS = one('Workspace'), one('ServerScriptService'), one('StarterGui'), one('ReplicatedFirst'), one('ReplicatedStorage'), one('ServerStorage')
LIGHT, SP, TEAMS = one('Lighting'), one('StarterPack'), one('Teams')
OLD = set(E.loc)    # everything from the base place (removed at the end)

T_PART = next(r for r in by_class('Part') if E.path(r) == 'Workspace.Map.Baseplate')
T_SPAWN = by_class('SpawnLocation')[0]
T_MODEL = by_class('Model')[0]
T_SCRIPT = next(r for r in by_class('Script') if E.prop(r, 'Disabled')[1] == b'\x00')
T_LOCAL = by_class('LocalScript')[0]
T_LIGHT = by_class('PointLight')[0]

BC = dict(white=1001, grass=37, dgreen=28, grey=194, dgrey=199, black=1003, yellow=24, sand=5, blue=23, ocean=102,
          red=21, lightgrey=208, neonyellow=1009, lime=1020, cyan=1013, brown=192, navy=1012, rred=1004)
MAT = dict(plastic=256, smooth=272, neon=288, wood=512, concrete=816, grass=1280, sand=1296, glass=1568, metal=1088, marble=784)
SURF = ('Top', 'Bottom', 'Front', 'Back', 'Left', 'Right')
ROTZ90 = [0, -1, 0, 1, 0, 0, 0, 0, 1]   # cylinders stand up
ROT180 = [-1, 0, 0, 0, 1, 0, 0, 0, -1]

def model(parent, name):
    m = E.add_instance(T_MODEL, parent, name)
    E.set_prop(m, 'PrimaryPart', -1)
    E.set_prop(m, 'ModelInPrimary', CFRAME((0, 0, 0)))
    return m

n_parts = [0]
def part(parent, name, pos, size, color, mat, rot=None, collide=True, transp=0.0, shape=1, tmpl=None):
    r = E.add_instance(tmpl or T_PART, parent, name)
    E.set_prop(r, 'Anchored', b'\x01')
    E.set_prop(r, 'CFrame', CFRAME(pos, rot))
    E.set_prop(r, 'size', VEC3(*size))
    E.set_prop(r, 'BrickColor', U32(BC.get(color, color) if isinstance(color, str) else color))
    E.set_prop(r, 'Material', U32(MAT[mat]))
    E.set_prop(r, 'Transparency', F32(transp))
    E.set_prop(r, 'Reflectance', F32(0))
    E.set_prop(r, 'CanCollide', BOOL(collide))
    E.set_prop(r, 'Locked', b'\x01')
    E.set_prop(r, 'formFactorRaw', U32(3))
    E.set_prop(r, 'shape', U32(shape))
    E.set_prop(r, 'Velocity', VEC3(0, 0, 0))
    for s in SURF:
        E.set_prop(r, s + 'Surface', U32(0))
    n_parts[0] += 1
    return r

def box(parent, name, x0, x1, y0, y1, z0, z1, color, mat, **kw):
    """box by its extents (keeps every dimension under the 2048 stud limit)"""
    return part(parent, name, ((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2), (x1 - x0, y1 - y0, z1 - z0), color, mat, **kw)
def tiles(parent, name, x0, x1, y0, y1, z0, z1, color, mat, n_x=1, n_z=1, **kw):
    for i in range(n_x):
        for j in range(n_z):
            a = x0 + (x1 - x0) * i / n_x; b = x0 + (x1 - x0) * (i + 1) / n_x
            c = z0 + (z1 - z0) * j / n_z; d = z0 + (z1 - z0) * (j + 1) / n_z
            box(parent, name, a, b, y0, y1, c, d, color, mat, **kw)
def cyl(parent, name, x, y0, z, d, h, color, mat, **kw):
    return part(parent, name, (x, y0 + h / 2, z), (h, d, d), color, mat, rot=ROTZ90, shape=2, **kw)
def ball(parent, name, x, y, z, d, color, mat, **kw):
    return part(parent, name, (x, y, z), (d, d, d), color, mat, shape=0, **kw)

MAP = model(WS, 'AirportMap')
# ------------------------------------------------------------------ ground, beach, ocean
GX, GZ = 1750, 1300
g = model(MAP, 'Ground')
tiles(g, 'Grass', -GX, GX, -4, 0, -GZ, GZ, 'grass', 'grass', 2, 2)
for name, a in (('BeachN', (-GX - 40, GX + 40, GZ, GZ + 40)), ('BeachS', (-GX - 40, GX + 40, -GZ - 40, -GZ)),
                ('BeachW', (-GX - 40, -GX, -GZ, GZ)), ('BeachE', (GX, GX + 40, -GZ, GZ))):
    tiles(g, name, a[0], a[1], -3, -0.4, a[2], a[3], 'sand', 'sand', 2 if a[1] - a[0] > 2048 else 1, 1)
OX, OZ = 3800, 3300
tiles(g, 'Ocean', -OX, OX, -6, -1.5, GZ + 40, OZ, 'ocean', 'smooth', 4, 1, transp=0.15)
tiles(g, 'Ocean', -OX, OX, -6, -1.5, -OZ, -GZ - 40, 'ocean', 'smooth', 4, 1, transp=0.15)
tiles(g, 'Ocean', -OX, -GX - 40, -6, -1.5, -GZ - 40, GZ + 40, 'ocean', 'smooth', 2, 2, transp=0.15)
tiles(g, 'Ocean', GX + 40, OX, -6, -1.5, -GZ - 40, GZ + 40, 'ocean', 'smooth', 2, 2, transp=0.15)

# ------------------------------------------------------------------ the international runway in the middle
rw = model(MAP, 'InternationalRunway')
tiles(rw, 'Runway', -1300, 1300, 0, 0.3, -60, 60, 'black', 'concrete', 2, 1)
for x in range(-1200, 1201, 50):
    box(rw, 'Center', x - 15, x + 15, 0.3, 0.35, -1, 1, 'white', 'smooth', collide=False)
for end in (-1, 1):
    for k in range(10):
        z = -45 + k * 10
        box(rw, 'Threshold', end * 1270 - 15, end * 1270 + 15, 0.3, 0.35, z - 2, z + 2, 'white', 'smooth', collide=False)
for z in (-58, 58):
    tiles(rw, 'Edge', -1300, 1300, 0.3, 0.35, z - 0.6, z + 0.6, 'white', 'smooth', 2, 1, collide=False)
for x in range(-1300, 1301, 100):
    for z in (-61.5, 61.5):
        box(rw, 'EdgeLight', x - 0.6, x + 0.6, 0.3, 0.9, z - 0.6, z + 0.6, 'neonyellow', 'neon', collide=False)
tiles(rw, 'Taxiway', -1200, 1200, 0, 0.3, 120, 160, 'dgrey', 'concrete', 2, 1)
for x in (-1200, 0, 1200):
    box(rw, 'Connector', x - 20, x + 20, 0, 0.3, 60, 120, 'dgrey', 'concrete')
for x in range(-1180, 1181, 30):
    box(rw, 'TaxiLine', x - 8, x + 8, 0.3, 0.35, 139.5, 140.5, 'yellow', 'smooth', collide=False)

# ------------------------------------------------------------------ roads, plaza, tower, hub
rd = model(MAP, 'Roads')
for zc in (325, -325):
    tiles(rd, 'Boulevard', -GX, GX, 0, 0.3, zc - 25, zc + 25, 'dgrey', 'concrete', 2, 1)
    for x in range(-GX + 20, GX, 40):
        box(rd, 'Line', x - 8, x + 8, 0.3, 0.35, zc - 0.6, zc + 0.6, 'yellow', 'smooth', collide=False)
    for x in range(-GX + 50, GX, 100):
        for side in (-1, 1):
            z = zc + side * 28
            box(rd, 'LampPost', x - 0.5, x + 0.5, 0, 16, z - 0.5, z + 0.5, 'dgrey', 'metal')
            head = box(rd, 'Lamp', x - 1.4, x + 1.4, 16, 17, z - 1.4, z + 1.4, 'white', 'neon', collide=False)
            if (x // 100) % 3 == 0:
                l = E.add_instance(T_LIGHT, head, 'PointLight')
box(rd, 'PlazaRoad', -15, 15, 0, 0.3, -350, -260, 'dgrey', 'concrete')
box(rd, 'Path', -10, 10, 0, 0.3, -140, -60, 'lightgrey', 'concrete')
box(rd, 'Path', -10, 10, 0, 0.3, 160, 300, 'lightgrey', 'concrete')
box(rd, 'Path', -10, 10, 0, 0.3, 60, 120, 'lightgrey', 'concrete')

pl = model(MAP, 'Plaza')
box(pl, 'Plaza', -90, 90, 0, 0.5, -260, -140, 'lightgrey', 'concrete')
for x in range(-80, 81, 20):
    box(pl, 'Tile', x - 9, x + 9, 0.5, 0.55, -255, -145, 'white', 'marble', collide=False)
cyl(pl, 'FountainBasin', 0, 0.5, -170, 22, 2, 'white', 'marble')
cyl(pl, 'FountainWater', 0, 2.2, -170, 20, 0.3, 'cyan', 'neon', collide=False, transp=0.4)
cyl(pl, 'FountainPillar', 0, 2.5, -170, 3, 8, 'white', 'marble')
sp = E.add_instance(T_SPAWN, MAP, 'Spawn')
E.set_prop(sp, 'CFrame', CFRAME((0, 1, -215)))
E.set_prop(sp, 'size', VEC3(14, 1, 14))
E.set_prop(sp, 'Anchored', b'\x01')
E.set_prop(sp, 'Neutral', b'\x01')
E.set_prop(sp, 'Transparency', F32(0))
E.set_prop(sp, 'BrickColor', U32(BC['lime']))
for side in (-1, 1):
    box(pl, 'BoardPost', side * 30 - 1, side * 30 + 1, 0.5, 22, -246, -244, 'dgrey', 'metal')
box(pl, 'WelcomeBoard', -32, 32, 12, 26, -246, -245, 'navy', 'smooth')
# central control tower and the hub building
tw = model(MAP, 'ControlTower')
cyl(tw, 'Shaft', 300, 0, -200, 14, 80, 'white', 'concrete')
cyl(tw, 'Cab', 300, 80, -200, 26, 12, 'cyan', 'glass', transp=0.35)
cyl(tw, 'Roof', 300, 92, -200, 28, 2, 'navy', 'smooth')
cyl(tw, 'Antenna', 300, 94, -200, 1, 14, 'red', 'metal')
ball(tw, 'Beacon', 300, 109, -200, 2, 'rred', 'neon')
hb = model(MAP, 'Hub')
box(hb, 'HubBase', -420, -180, 0, 2, -260, -170, 'lightgrey', 'concrete')
box(hb, 'HubGlass', -410, -190, 2, 32, -250, -180, 'cyan', 'glass', transp=0.45)
box(hb, 'HubRoof', -415, -185, 32, 34, -255, -175, 'white', 'smooth')
for x in range(-410, -189, 22):
    box(hb, 'Pillar', x - 1, x + 1, 2, 32, -181, -179, 'white', 'smooth')
box(hb, 'HubSign', -360, -240, 35, 45, -178, -177, 'navy', 'smooth')

# ------------------------------------------------------------------ the 10 airport plots
PLOT_X = [-1400, -700, 0, 700, 1400]
plots = model(MAP, 'Plots')
ORIGINS = []
for i in range(10):
    north = i < 5
    x = PLOT_X[i % 5]
    z0 = 360 if north else -360
    rot = None if north else ROT180
    s = 1 if north else -1
    m = model(plots, 'Plot%d' % (i + 1))
    part(m, 'Origin', (x, 0.5, z0), (1, 1, 1), 'white', 'smooth', rot=rot, collide=False, transp=1)
    ORIGINS.append((x, z0, s))
    zc = z0 + s * 310
    box(m, 'Base', x - 210, x + 210, 0, 0.1, min(z0, z0 + s * 620), max(z0, z0 + s * 620), 'dgreen', 'grass')
    for (a, b, c, d) in ((x - 211, x - 209, 0, 620), (x + 209, x + 211, 0, 620), (x - 211, x + 211, 0, 1), (x - 211, x + 211, 619, 620)):
        za, zb = sorted((z0 + s * c, z0 + s * d))
        box(m, 'Curb', a, b, 0.1, 0.7, za, zb, 'white', 'concrete')
LOG.append('baked the world: ground, beaches, ocean, international runway, taxiway, 2 boulevards, plaza, tower, hub, 10 plots')

# ------------------------------------------------------------------ scenery: forests, lakes, hub apron, plaza details
tr = model(MAP, 'Trees')
def tree(x, z, big=1.0):
    h = random.uniform(9, 16) * big
    box(tr, 'Trunk', x - 1.2 * big, x + 1.2 * big, 0, h, z - 1.2 * big, z + 1.2 * big, 'brown', 'wood')
    ball(tr, 'Leaves', x, h + 3 * big, z, random.uniform(10, 15) * big, random.choice(['grass', 'dgreen', 141]), 'grass', collide=False)
def clear(x, z):
    """no trees on plots, roads, runways, the plaza or lakes"""
    for i in range(10):
        px = PLOT_X[i % 5]; north = i < 5
        if abs(x - px) < 225 and ((north and 345 < z < 995) or (not north and -995 < z < -345)): return False
    if abs(z) < 360 and abs(x) < 1350: return False          # runway, taxiway, plaza, hub, boulevards
    if abs(abs(z) - 325) < 40: return False                   # boulevards
    for lx, lz, r in LAKES:
        if (x - lx) ** 2 + (z - lz) ** 2 < (r + 20) ** 2: return False
    return abs(x) < GX - 15 and abs(z) < GZ - 15
LAKES = [(-1550, 0, 110), (1550, 0, 110)]
lk = model(MAP, 'Lakes')
for lx, lz, r in LAKES:
    cyl(lk, 'Sand', lx, -0.2, lz, 2 * r + 24, 0.4, 'sand', 'sand')
    cyl(lk, 'Lake', lx, -0.15, lz, 2 * r, 0.5, 'ocean', 'smooth', transp=0.15)
    for k in range(10):
        import math
        a = k * 2 * math.pi / 10
        ball(lk, 'Rock', lx + math.cos(a) * (r + 8), 0.5, lz + math.sin(a) * (r + 8), random.uniform(3, 6), 'grey', 'concrete')
n_trees = 0
# forests: clusters of trees in the gaps between plots, behind the plots and around the edge
centres = []
for gx in (-1050, -350, 350, 1050):
    for zs in (1, -1):
        for z in (480, 640, 800, 940):
            centres.append((gx, zs * z, 70))
for x in range(-1600, 1601, 200):
    centres.append((x, 1110, 80)); centres.append((x, -1110, 80))
for z in (-900, -650, 650, 900):
    centres.append((-1640, z, 60)); centres.append((1640, z, 60))
for cx, cz, r in centres:
    for k in range(5):
        x, z = cx + random.uniform(-r, r), cz + random.uniform(-r, r)
        if clear(x, z):
            tree(x, z, random.uniform(0.8, 1.4)); n_trees += 1
LOG.append('%d trees, 2 lakes' % n_trees)
# hub apron (3 airliners park here at runtime) and plaza details
box(hb, 'HubApron', -430, -170, 0, 0.3, -165, -65, 'grey', 'concrete')
for x in (-380, -300, -220):
    box(hb, 'LeadIn', x - 0.5, x + 0.5, 0.3, 0.35, -160, -70, 'yellow', 'smooth', collide=False)
for x, z in ((-70, -150), (70, -150), (-70, -250), (70, -250)):
    box(pl, 'FlowerBed', x - 12, x + 12, 0.5, 1.5, z - 4, z + 4, 'brown', 'grass')
    for k in range(6):
        ball(pl, 'Flower', x - 10 + k * 4, 2, z, 2.2, random.choice(['red', 'yellow', 24, 1032 if False else 21]), 'smooth', collide=False)
for k, col in enumerate(['red', 'blue', 'grass', 'yellow', 'navy', 'cyan']):
    x = -50 + k * 20
    cyl(pl, 'FlagPole', x, 0.5, -140.5, 0.6, 22, 'lightgrey', 'metal')
    box(pl, 'Flag', x + 0.3, x + 6.3, 18, 22, -140.7, -140.3, col, 'smooth')
LOG.append('%d parts in the baked world' % n_parts[0])


# ------------------------------------------------------------------ scripts
def lua(v):
    if isinstance(v, bool): return 'true' if v else 'false'
    if isinstance(v, (int, float)): return repr(v)
    if isinstance(v, str): return '"' + v.replace('\\', '\\\\').replace('"', '\\"') + '"'
    if isinstance(v, (list, tuple)): return '{' + ', '.join(lua(x) for x in v) + '}'
    if isinstance(v, dict):
        out = []
        for k, x in v.items():
            if x is None: continue
            key = k if k.isidentifier() else '[' + lua(k) + ']'
            out.append('%s = %s' % (key, lua(x)))
        return '{' + ', '.join(out) + '}'
    raise TypeError(v)
cat = []
for it in CAT.ITEMS:
    cat.append(dict(key=it['key'], name=it['name'], price=it['price'], deps=it['deps'], kind=it['kind'], at=it['at'],
                    pad=list(it['pad']), floor=it['floor'], phase=it['phase'], eff=it['eff']))
catalog_lua = ('local CATALOG = ' + lua(cat) + '\nlocal STAFF = ' + lua(CAT.STAFF) + '\nlocal CATS = ' + lua(CAT.CATS) +
               '\nlocal CONST = ' + lua(CAT.CONST) + '\nlocal PHASES = ' + lua(CAT.PHASES) + '\n')
server = ''
for f in sorted(glob.glob(os.path.join(SRC, 'server', 's*.lua'))):
    server += '\n-- ==== ' + os.path.basename(f) + '\n' + open(f).read()
server = server.replace('--#CATALOG', catalog_lua)
open(os.path.join(ROOT, 'build', 'AirportServer.server.lua'), 'w').write(server) if os.path.isdir(os.path.join(ROOT, 'build')) else None
def add_script(tmpl, parent, name, source):
    r = E.add_instance(tmpl, parent, name)
    E.set_prop(r, 'Disabled', b'\x00')
    E.set_string(r, 'Source', source.encode('utf8'))
    E.set_string(r, 'LinkedSource', b'')
    return r
NEW_SCRIPTS = [
    add_script(T_SCRIPT, SSS, 'AirportServer', server),
    add_script(T_LOCAL, SG, 'AirportClient', open(os.path.join(SRC, 'AirportClient.client.lua')).read()),
    add_script(T_LOCAL, RF, 'AirportNPCs', open(os.path.join(SRC, 'AirportNPCs.client.lua')).read()),
    add_script(T_LOCAL, RF, 'errorReport', open(os.path.join(ROOT, '..', 'mansion', 'src', 'errorReport.client.lua')).read()),
    add_script(T_SCRIPT, SSS, 'errorRelay', open(os.path.join(ROOT, '..', 'mansion', 'src', 'errorRelay.server.lua')).read()),
]
LOG.append('added AirportServer (%d lines), AirportClient, and the on-screen error box' % server.count('\n'))

# ------------------------------------------------------------------ remove everything that came with the base place
keep_services = set(r for r in OLD if E.parent.get(r, -1) == -1)
keep = keep_services | set(r for r in OLD if E.classof(r) in ('Terrain', 'Camera', 'Sky', 'StarterPlayerScripts'))
dead = set(r for r in OLD if r not in keep)
E.delete(dead)
LOG.append('removed %d objects from the base place' % len(dead))

data = E.save()
open(sys.argv[2], 'wb').write(data)
for l in LOG: print(l)
print('wrote', sys.argv[2], len(data), 'bytes')
