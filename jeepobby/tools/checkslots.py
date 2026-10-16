# Checks every car spawn slot: when a car is placed there, no part of it may touch any part of the map
# (touching parts get joined by MakeJoints and the car hangs in the air). Prints problems; exit 1 if any.
import sys
from vals import *
from rbxlw import Editable
E = Editable(open(sys.argv[1], 'rb').read())
PARTS = ('Part', 'WedgePart', 'TrussPart', 'SpawnLocation', 'VehicleSeat', 'Seat', 'CornerWedgePart')
def mat_t(R): return [R[0], R[3], R[6], R[1], R[4], R[7], R[2], R[5], R[8]]
def mv(R, v): return tuple(R[3 * i] * v[0] + R[3 * i + 1] * v[1] + R[3 * i + 2] * v[2] for i in range(3))
def mm(A, B): return [sum(A[r * 3 + k] * B[k * 3 + c] for k in range(3)) for r in range(3) for c in range(3)]
def aabb(p, R, s):
    h = [abs(R[3 * i]) * s[0] / 2 + abs(R[3 * i + 1]) * s[1] / 2 + abs(R[3 * i + 2]) * s[2] / 2 for i in range(3)]
    return [p[i] - h[i] for i in range(3)], [p[i] + h[i] for i in range(3)]
def touching(a, b, eps=0.15):
    return all(a[0][i] <= b[1][i] + eps and b[0][i] <= a[1][i] + eps for i in range(3))
by = {E.path(r): r for r in E.loc}
tmpl = by['ServerStorage.CarTemplate']
seat = [k for k in E.children(tmpl) if E.classof(k) == 'VehicleSeat'][0]
sp, sR = cframe(E.prop(seat, 'CFrame')[1])
car = [(cframe(E.prop(d, 'CFrame')[1]), vec3(E.prop(d, 'size')[1])) for d in E.descendants(tmpl) if E.classof(d) in PARTS]
world = []
for r in E.descendants(by['Workspace']):
    if E.classof(r) in PARTS:
        p, R = cframe(E.prop(r, 'CFrame')[1])
        world.append((aabb(p, R, vec3(E.prop(r, 'size')[1])), E.path(r), E.prop(r, 'CanCollide')[1]))
bad = 0
nslots = 0
for r in E.descendants(by['ServerStorage.StageData']):
    if E.name(r) != 'Slot': continue
    nslots += 1
    tp, tR = cframe(E.prop(r, 'CFrame')[1])
    M = mm(tR, mat_t(sR))                       # slot * seat^-1 rotation
    boxes = []
    low = 1e9
    for (p, R), s in car:
        d = mv(M, tuple(p[i] - sp[i] for i in range(3)))
        wp = tuple(tp[i] + d[i] for i in range(3))
        b = aabb(wp, mm(M, R), s); boxes.append(b); low = min(low, b[0][1])
    hits = set()
    for b in boxes:
        for wb, path, coll in world:
            if touching(b, wb) and coll == b'\x01':
                hits.add(path)
    # ground under the car: highest solid top below the car's lowest point, overlapping its footprint
    fx0 = min(b[0][0] for b in boxes); fx1 = max(b[1][0] for b in boxes)
    fz0 = min(b[0][2] for b in boxes); fz1 = max(b[1][2] for b in boxes)
    tops = [wb[1][1] for wb, path, coll in world if coll == b'\x01' and wb[1][1] <= low + 0.01
            and wb[0][0] < fx1 and fx0 < wb[1][0] and wb[0][2] < fz1 and fz0 < wb[1][2]]
    gap = low - max(tops) if tops else 999
    print(E.path(E.parent[r]), [round(x, 1) for x in tp], 'drop to ground %.2f' % gap, ('TOUCHES ' + ', '.join(sorted(hits))) if hits else 'clear')
    if hits or gap > 3: bad += 1
print(nslots, 'slots,', bad, 'problems')
sys.exit(1 if bad else 0)
