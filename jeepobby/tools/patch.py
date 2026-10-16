# Rebuilds Jeep Obby: removes the piled-up jeeps, adds the stage/car system, 4 new harder levels,
# car unlocks by wins, a UI, and fixes for the map.
#   python3 patch.py <original.rbxl> <fixed.rbxl>
import sys, os, struct
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from vals import *          # also puts casino/tools on the path
from rbxlw import Editable
import levels as LV

SRC = os.path.join(HERE, '..', 'src')
E = Editable(open(sys.argv[1], 'rb').read())
LOG = []

def by_class(c): return [r for r in list(E.loc) if E.classof(r) == c]
def one(c): r = by_class(c); assert len(r) == 1, c; return r[0]
def kids(r, name=None): return [k for k in E.children(r) if name is None or E.name(k) == name]
def src(r): return E.get_string(r, 'Source').decode('utf8', 'replace')
def setsrc(r, s): E.set_string(r, 'Source', s.encode('utf8'))
def disable(r): E.set_prop(r, 'Disabled', b'\x01')
def read(name): return open(os.path.join(SRC, name)).read()

WS, SS, RS = one('Workspace'), one('ServerStorage'), one('ReplicatedStorage')
SSS, SG, RF = one('ServerScriptService'), one('StarterGui'), one('ReplicatedFirst')

# ------------------------------------------------------------------ templates (picked before anything is removed)
T_PART = next(r for r in kids(WS, 'Part') if E.classof(r) == 'Part' and E.prop(r, 'Anchored')[1] == b'\x01')
T_WEDGE = next(r for r in kids(WS, 'Wedge') if E.classof(r) == 'WedgePart')
T_MODEL = next(r for r in by_class('Model') if 'Jeep' not in E.path(r))
T_INT = next(r for r in by_class('IntValue') if 'Jeep' not in E.path(r))
T_STR = next(r for r in by_class('StringValue') if 'Jeep' not in E.path(r))
T_SCRIPT = next(r for r in by_class('Script') if E.prop(r, 'Disabled')[1] == b'\x00' and 'Jeep' not in E.path(r))
T_LOCAL = by_class('LocalScript')[0]

def new_model(parent, name):
    m = E.add_instance(T_MODEL, parent, name)
    E.set_prop(m, 'PrimaryPart', -1)
    E.set_prop(m, 'ModelInPrimary', CFRAME((0, 0, 0)))
    return m

def new_value(tmpl, parent, name, value):
    v = E.add_instance(tmpl, parent, name)
    if tmpl == T_INT: E.set_prop(v, 'Value', I32(value))
    else: E.set_string(v, 'Value', value)
    return v

SURF = ('Top', 'Bottom', 'Front', 'Back', 'Left', 'Right')
def new_part(parent, d):
    r = E.add_instance(T_WEDGE if d['cls'] == 'WedgePart' else T_PART, parent, d['name'])
    E.set_prop(r, 'Anchored', b'\x01')
    E.set_prop(r, 'CFrame', CFRAME(d['pos'], d.get('rot')))
    E.set_prop(r, 'size', VEC3(*d['size']))
    E.set_prop(r, 'BrickColor', U32(d['color']))
    E.set_prop(r, 'Material', U32(d['mat']))
    E.set_prop(r, 'Transparency', F32(d.get('transp') or 0))
    E.set_prop(r, 'Reflectance', F32(d.get('refl') or 0))
    E.set_prop(r, 'CanCollide', BOOL(d.get('collide', True)))
    E.set_prop(r, 'Locked', b'\x00')
    E.set_prop(r, 'formFactorRaw', U32(3))        # Custom: any size
    if d['cls'] != 'WedgePart': E.set_prop(r, 'shape', U32(1))
    E.set_prop(r, 'Velocity', VEC3(*(d.get('velocity') or (0, 0, 0))))
    E.set_prop(r, 'RotVelocity', VEC3(0, 0, 0))
    E.set_prop(r, 'Friction', F32(0.3 if d['mat'] != LV.ICE else 0.05))
    E.set_prop(r, 'Elasticity', F32(0.5))
    for s in SURF:   # smooth faces: nothing gets glued to the road or obstacles
        E.set_prop(r, s + 'Surface', U32(0)); E.set_prop(r, s + 'SurfaceInput', U32(0))
        E.set_prop(r, s + 'ParamA', F32(-0.5)); E.set_prop(r, s + 'ParamB', F32(0.5))
    if d.get('move'): new_value(T_STR, r, 'Move', d['move'])
    return r

def marker(parent, name, pos, rot=None):
    return new_part(parent, dict(cls='Part', name=name, pos=pos, rot=rot, size=(2, 1, 2), color=LV.LIME, mat=LV.SMOOTH,
                                 collide=False, transp=1))

def split_big(d):
    """parts can't be longer than 2048 studs on old engines"""
    if d['size'][0] <= 2000: return [d]
    half = d['size'][0] / 2
    a, b = dict(d), dict(d)
    a['size'] = b['size'] = (half,) + tuple(d['size'][1:])
    a['pos'] = (d['pos'][0] - half / 2,) + tuple(d['pos'][1:])
    b['pos'] = (d['pos'][0] + half / 2,) + tuple(d['pos'][1:])
    return [a, b]

# ------------------------------------------------------------------ 1. jeeps: keep one as the car template, remove the pile
jeeps = kids(WS, 'Jeep')
info1 = {}   # seat CFrames of the old jeeps (where the cars used to sit) -> car pads for level 1
for j in jeeps:
    inner = kids(j, 'Jeep')[0]
    seat = [k for k in E.children(inner) if E.classof(k) == 'VehicleSeat'][0]
    info1[j] = E.prop(seat, 'CFrame')[1]
tmpl_outer = jeeps[0]
tmpl = kids(tmpl_outer, 'Jeep')[0]
E.parent[tmpl] = SS
E.set_string(tmpl, 'Name', 'CarTemplate')
for d in E.descendants(tmpl):
    if E.classof(d) == 'Script':
        n = E.name(d)
        p = E.path(d)
        # Welding (2.5 s late), Control (crashes when a non-player sits), SelfDestruct: the server does these now
        if n in ('Welding', 'SelfDestruct') or p.endswith('VehicleSeat.Control'):
            disable(d)
        elif p.endswith('VehicleSeat.Sound.Control'):
            setsrc(d, read('EngineSound.server.lua'))   # old loop errored forever once its car was deleted
# delete every old jeep (the template was moved out of its container first)
dead = set()
for j in jeeps:
    for x in E.descendants(j):
        dead.add(x)
tmpl_tree = set(E.descendants(tmpl))
dead -= tmpl_tree
E.delete(dead)
LOG.append('cars: removed the %d jeeps and their regen pads that piled up; one jeep kept as ServerStorage.CarTemplate' % len(jeeps))

# ------------------------------------------------------------------ 2. map fixes
E.delete(by_class('Team'))
for sp in by_class('SpawnLocation'):
    E.set_prop(sp, 'Neutral', b'\x01')
    E.set_prop(sp, 'AllowTeamChangeOnTouch', b'\x00')
spawns = {round(cframe(E.prop(s, 'CFrame')[1])[0][0]): s for s in by_class('SpawnLocation')}
START, CHECK, FINISH = spawns[1037], spawns[381], spawns[-1019]
E.set_prop(CHECK, 'Enabled', b'\x00')
E.set_prop(FINISH, 'Enabled', b'\x00')
LOG.append('teams removed (stages replace them); everyone spawns at the start and is moved to their checkpoint')
water = kids(WS, 'Water generator')[0]
for s in kids(water): disable(s)
LOG.append('Water generator turned off (it made a new part 10 times a second: lag)')
E.delete([r for r in kids(WS) if E.classof(r) == 'VelocityMotor'])

# kill bricks: spare drivers sitting in their car (people on foot still die)
nk = 0
for kb in kids(WS, 'Kill Brick'):
    for sc in kids(kb):
        if E.classof(sc) == 'Script':
            setsrc(sc, read('KillBrick.server.lua')); nk += 1
LOG.append('%d Kill Brick scripts: no longer kill players sitting in a car' % nk)
# the narrow bridge over the pit right after the start: 9 -> 14 studs wide (the jeep is 8.4 wide)
nb = 0
for r in kids(WS):
    if E.classof(r) != 'Part': continue
    p, R = cframe(E.prop(r, 'CFrame')[1]); sz = vec3(E.prop(r, 'size')[1])
    if abs(p[0] - 963.8) < 1 and abs(p[2] - 47.7) < 1 and abs(sz[0] - 9) < 0.1 and abs(sz[2] - 71) < 0.1:
        E.set_prop(r, 'size', VEC3(14, sz[1], sz[2])); nb += 1        # the bridge
    if E.name(r) == 'Kill Brick' and abs(p[0] - 951.8) < 1 and abs(p[2] - 47.7) < 1 and abs(sz[0] - 9) < 0.1:
        E.set_prop(r, 'size', VEC3(14, sz[1], sz[2])); nb += 1        # its kill brick (still kills walkers)
assert nb == 2, nb
LOG.append('widened the bridge over the pit after the start from 9 to 14 studs')

# ------------------------------------------------------------------ 3. JeepObby folder: stages, levels, cars
root = new_model(WS, 'JeepObby')
stages = new_model(root, 'Stages')
# spawn points and car pads are invisible marker parts kept in ServerStorage: in Workspace they touched the
# new cars, and MakeJoints welded each car to an anchored marker (the car hung in the air and couldn't drive)
stagedata = new_model(SS, 'StageData')
_sd = {}
def sd(n):
    if n not in _sd: _sd[n] = new_model(stagedata, 'Stage%d' % n)
    return _sd[n]
levelsM = new_model(root, 'Levels')
new_model(root, 'Cars')

# level 1 = the original course. Stage 1 at the start, stage 2 at the old checkpoint room, finish -> level 2
sp_p, sp_R = cframe(E.prop(START, 'CFrame')[1])
s1 = new_part(stages, dict(cls='Part', name='Stage1', pos=sp_p, size=(6, 1, 6), color=LV.LIME, mat=LV.SMOOTH, collide=False, transp=1))
marker(sd(1), 'Spawn', (sp_p[0], sp_p[1] + 3, sp_p[2]), sp_R)
c_p, c_R = cframe(E.prop(CHECK, 'CFrame')[1])
s2 = new_part(stages, dict(cls='Part', name='Stage2', pos=(407, 40, -15), size=(75, 30, 60), color=LV.LIME, mat=LV.SMOOTH, collide=False, transp=1))
marker(sd(2), 'Spawn', (c_p[0], c_p[1] + 3, c_p[2]), c_R)
n1 = n2 = 0
for j, raw in info1.items():
    p, R = cframe(raw)
    if p[0] > 900:
        marker(sd(1), 'Slot', (p[0], p[1] + 1.0, p[2]), R); n1 += 1
    elif 300 < p[0] < 420:   # (the jeep at x=432 sat inside the VIP door: no car pad there)
        marker(sd(2), 'Slot', (p[0], p[1] + 1.0, p[2]), R); n2 += 1
f_p, f_R = cframe(E.prop(FINISH, 'CFrame')[1])
le = new_part(stages, dict(cls='Part', name='LevelEnd', pos=(f_p[0], f_p[1] + 4, f_p[2]), rot=f_R, size=(12, 8, 12), color=LV.LIME, mat=LV.NEON, collide=False, transp=0.5))
new_value(T_INT, le, 'NextStage', 3)
for x0, x1 in ((-1300, -25), (-25, 1250)):
    new_part(levelsM, dict(cls='Part', name='KillFloor', pos=((x0 + x1) / 2, -25, -50), size=(x1 - x0, 2, 740), color=LV.RRED, mat=LV.SMOOTH, collide=False, transp=1))
LOG.append('level 1 (the original course): stage 1 at the start (%d car pads), stage 2 at the old checkpoint (%d car pads), finish pad -> level 2' % (n1, n2))

FACE_X = LV.FACE_X
for L in LV.build():
    lm = new_model(levelsM, 'Level%d' % L.n)
    stage_parts = {id(s['pad']): s for s in L.stages}
    count = 0
    for d in L.parts:
        if id(d) in stage_parts:
            st = stage_parts[id(d)]
            pad = new_part(stages, d)
            marker(sd(st['stage']), 'Spawn', st['spawn'], FACE_X)
            for pos, rot in st['slots']:
                marker(sd(st['stage']), 'Slot', pos, rot)
        elif d['name'] in ('LevelEnd', 'WinPad'):
            pad = new_part(stages, d)
            if d['name'] == 'LevelEnd':
                new_value(T_INT, pad, 'NextStage', 2 * L.n + 1)
        else:
            for piece in split_big(d):
                new_part(lm, piece); count += 1
    LOG.append('level %d "%s": %d parts, stages %s' % (L.n, L.th['name'], count, [s['stage'] for s in L.stages]))

# ------------------------------------------------------------------ 4. scripts
cars = read('cars.lua')
server = E.add_instance(T_SCRIPT, SSS, 'JeepObbyServer')
E.set_prop(server, 'Disabled', b'\x00')
setsrc(server, read('JeepObbyServer.server.lua').replace('--#CARS', cars))
ui = E.add_instance(T_LOCAL, SG, 'JeepObbyClient')
E.set_prop(ui, 'Disabled', b'\x00')
setsrc(ui, read('JeepObbyUI.client.lua').replace('--#CARS', cars))
rep = E.add_instance(T_LOCAL, RF, 'errorReport')
E.set_prop(rep, 'Disabled', b'\x00')
setsrc(rep, read('errorReport.client.lua'))
rel = E.add_instance(T_SCRIPT, SSS, 'errorRelay')
E.set_prop(rel, 'Disabled', b'\x00')
setsrc(rel, read('errorRelay.server.lua'))
LOG.append('added JeepObbyServer, the JeepObbyUI screen, and the on-screen error box')

data = E.save()
open(sys.argv[2], 'wb').write(data)
for l in LOG: print(l)
print('wrote', sys.argv[2], len(data), 'bytes')
