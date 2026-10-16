# Encode/decode single property values as stored by rbxlw.Editable (binary .rbxl planes).
import struct, sys, os
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'casino', 'tools'))

def f32(b):
    z = int.from_bytes(b, 'big'); z = (z >> 1) | ((z & 1) << 31)
    return struct.unpack('>f', struct.pack('>I', z))[0]
def F32(x):
    z, = struct.unpack('>I', struct.pack('>f', x)); z = ((z << 1) & 0xffffffff) | (z >> 31)
    return z.to_bytes(4, 'big')
def i32(b):
    z = int.from_bytes(b, 'big'); return (z >> 1) ^ -(z & 1)
def I32(x):
    return (((x << 1) ^ (x >> 31)) & 0xffffffff).to_bytes(4, 'big')
def u32(b): return int.from_bytes(b, 'big')
def U32(x): return x.to_bytes(4, 'big')
def vec3(v): return tuple(f32(x) for x in v)
def VEC3(x, y, z): return (F32(x), F32(y), F32(z))
def BOOL(b): return b'\x01' if b else b'\x00'
def boolv(b): return b != b'\x00'

def cf_rot(v0):
    if len(v0) == 37: return [struct.unpack('<f', v0[1 + 4 * i:5 + 4 * i])[0] for i in range(9)]
    rid = v0[0] - 1
    vec = [(1, 0, 0), (0, 1, 0), (0, 0, 1), (-1, 0, 0), (0, -1, 0), (0, 0, -1)]
    a, b = vec[rid // 6], vec[rid % 6]
    c = (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])
    return [a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]]
def cframe(v): return vec3(v[1:]), cf_rot(v[0])
def CFRAME(pos, rot=None):
    """rot: 9 floats row-major (R00 R01 R02 R10 ...) or None for identity"""
    if rot is None:
        r = b'\x02'
    else:
        r = b'\x00' + b''.join(struct.pack('<f', x) for x in rot)
    return (r,) + VEC3(*pos)
def roty(deg):
    import math
    a = math.radians(deg); c, s = math.cos(a), math.sin(a)
    # CFrame.Angles(0, a, 0)
    return [c, 0, s, 0, 1, 0, -s, 0, c]
def rotz(deg):
    import math
    a = math.radians(deg); c, s = math.cos(a), math.sin(a)
    return [c, -s, 0, s, c, 0, 0, 0, 1]
def rotx(deg):
    import math
    a = math.radians(deg); c, s = math.cos(a), math.sin(a)
    return [1, 0, 0, 0, c, -s, 0, s, c]
def mul(A, B):
    return [sum(A[r * 3 + k] * B[k * 3 + c] for k in range(3)) for r in range(3) for c in range(3)]
