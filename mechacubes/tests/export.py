# Turns a binary .rbxl into a Lua file that rebuilds the whole instance tree in the fake engine.
#   python3 export.py place.rbxl out.lua
import sys, os, struct
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'casino', 'tools'))
from rbxlw import Editable, RawBlob

def f32(b):  # roblox float: sign bit rotated to the end
    z = int.from_bytes(b, 'big')
    z = (z >> 1) | ((z & 1) << 31)
    return struct.unpack('>f', struct.pack('>I', z))[0]
def i32(b):
    z = int.from_bytes(b, 'big')
    return (z >> 1) ^ -(z & 1)
def u32(b): return int.from_bytes(b, 'big')

def lstr(s):
    return lbytes(s.encode('utf8'))
def lbytes(b):
    return '"' + ''.join(chr(x) if (32 <= x < 127 and chr(x) not in '"\\') else '\\%03d' % x for x in b) + '"'
def num(x):
    if x != x or x in (float('inf'), float('-inf')): return '0'
    r = repr(float(x)) if isinstance(x, float) else str(x)
    return r

def value(t, v):
    if t == 1: return lbytes(v[4:])
    if t == 2: return 'true' if v[0] else 'false'
    if t == 3: return num(i32(v))
    if t == 4: return num(round(f32(v), 6))
    if t == 5: return num(struct.unpack('<d', v)[0])
    if t == 6: return 'UDim.new(%s,%s)' % (num(round(f32(v[0]), 6)), i32(v[1]))
    if t == 7: return 'UDim2.new(%s,%s,%s,%s)' % (num(round(f32(v[0]), 6)), i32(v[2]), num(round(f32(v[1]), 6)), i32(v[3]))
    if t == 11: return 'BrickColor.new(%d)' % u32(v)
    if t == 12: return 'Color3.new(%s,%s,%s)' % tuple(num(round(f32(x), 6)) for x in v)
    if t == 13: return 'Vector2.new(%s,%s)' % tuple(num(round(f32(x), 4)) for x in v)
    if t == 14: return 'Vector3.new(%s,%s,%s)' % tuple(num(round(f32(x), 4)) for x in v)
    if t == 16: return 'CFrame.new(%s,%s,%s)' % tuple(num(round(f32(x), 4)) for x in v[1:])
    if t == 18: return '{_enum=%d}' % u32(v)
    if t == 19: return '{_ref=%d}' % v
    if t == 26: return 'Color3.new(%r,%r,%r)' % tuple(round(x / 255, 6) for x in v)
    if t == 27: return num(i32(v[4:]))  # good enough for small int64
    return None

E = Editable(open(sys.argv[1], 'rb').read())
out = ['local T = {}']
for c in E.cls:
    cols = [(pn, t, vals) for pn, t, vals in c['props'] if not isinstance(vals, RawBlob)]
    # older files save some part properties under their old names ("size", "shape"): load them as the real ones
    have = set(pn for pn, _, _ in cols)
    cols = [({'size': 'Size', 'shape': 'Shape'}.get(pn, pn) if {'size': 'Size', 'shape': 'Shape'}.get(pn) not in have else pn, t, vals) for pn, t, vals in cols]
    for i, r in enumerate(c['refs']):
        props = []
        for pn, t, vals in cols:
            v = value(t, vals[i])
            if v is not None:
                props.append('[%s]=%s' % (lstr(pn), v))
        out.append('T[#T+1]={id=%d,class=%s,parent=%d,props={%s}}' % (r, lstr(c['name']), E.parent.get(r, -1), ','.join(props)))
# children order as in the file
out.append('ORDER={%s}' % ','.join(str(r) for r in E.prnt_order))
out.append('return T')
open(sys.argv[2], 'w').write('\n'.join(out))
print('exported', len(E.loc), 'instances')
