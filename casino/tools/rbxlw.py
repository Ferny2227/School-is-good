# Per-instance property splitting and a writer for binary .rbxl, built on rbxl.py
import struct, lz4.block
from rbxl import *

def deinter(raw, p, n, k):
    """k-byte interleaved planes -> list of n byte strings (big-endian order kept)"""
    out = [bytes(raw[p + j * n + i] for j in range(k)) for i in range(n)]
    return out, p + n * k
def inter(vals, k):
    n = len(vals); b = bytearray(n * k)
    for i, v in enumerate(vals):
        for j in range(k): b[j * n + i] = v[j]
    return bytes(b)

def split(t, raw, n):
    """returns list of n per-instance values (opaque tuples) and checks the whole blob was used"""
    p = 0
    if t in (1,):
        out = []
        for _ in range(n):
            l, = struct.unpack_from('<I', raw, p); out.append(raw[p:p + 4 + l]); p += 4 + l
    elif t in (2, 9, 10):
        out = [raw[i:i + 1] for i in range(n)]; p = n
    elif t in (3, 4, 11, 18, 28):
        out, p = deinter(raw, 0, n, 4)
    elif t == 19:
        out = refs_decode(raw, n); p = 4 * n
    elif t in (27, 33):
        out, p = deinter(raw, 0, n, 8)
    elif t == 31:
        out, p = deinter(raw, 0, n, 16)
    elif t in (5, 23):
        sz = 8; out = [raw[i * sz:(i + 1) * sz] for i in range(n)]; p = n * sz
    elif t == 20:
        out = [raw[i * 6:(i + 1) * 6] for i in range(n)]; p = n * 6
    elif t in (6, 7, 12, 13, 14, 24):
        g = {6: 2, 7: 4, 12: 3, 13: 2, 14: 3, 24: 4}[t]
        groups = []
        for _ in range(g):
            v, p = deinter(raw, p, n, 4); groups.append(v)
        out = list(zip(*groups)) if n else []
    elif t == 26:
        out = [(raw[i], raw[n + i], raw[2 * n + i]) for i in range(n)]; p = 3 * n
    elif t in (16, 30):
        if t == 30:
            assert raw[0] == 0x10; p = 1
        rots = []
        for _ in range(n):
            if raw[p] == 0:
                rots.append(raw[p:p + 37]); p += 37
            else:
                rots.append(raw[p:p + 1]); p += 1
        groups = []
        for _ in range(3):
            v, p = deinter(raw, p, n, 4); groups.append(v)
        out = list(zip(rots, *groups))
        if t == 30:
            assert raw[p] == 0x02; p += 1
            flags = [raw[p + i:p + i + 1] for i in range(n)]; p += n
            out = [(a, f) for a, f in zip(out, flags)]
    elif t in (21, 22):
        sz = 12 if t == 21 else 20; out = []
        for _ in range(n):
            c, = struct.unpack_from('<I', raw, p); out.append(raw[p:p + 4 + c * sz]); p += 4 + c * sz
    elif t == 25:
        out = []
        for _ in range(n):
            f = raw[p]
            sz = 1 + (20 if f & 1 else 0) + (4 if f & 2 else 0)
            out.append(raw[p:p + sz]); p += sz
    elif t == 32:
        out = []
        for _ in range(n):
            s = p
            l, = struct.unpack_from('<I', raw, p); p += 4 + l + 3
            l, = struct.unpack_from('<I', raw, p); p += 4 + l
            out.append(raw[s:p])
    else:
        raise ValueError('unknown type %d' % t)
    assert p == len(raw), ('size mismatch', t, p, len(raw))
    return out

def join(t, vals):
    n = len(vals)
    if t in (1, 2, 9, 10, 5, 23, 20, 21, 22, 25, 32):
        return b''.join(vals)
    if t in (3, 4, 11, 18, 28):
        return inter(vals, 4)
    if t == 19:
        return refs_encode(vals)
    if t in (27, 33):
        return inter(vals, 8)
    if t == 31:
        return inter(vals, 16)
    if t in (6, 7, 12, 13, 14, 24):
        g = {6: 2, 7: 4, 12: 3, 13: 2, 14: 3, 24: 4}[t]
        return b''.join(inter([v[j] for v in vals], 4) for j in range(g))
    if t == 26:
        return bytes(v[0] for v in vals) + bytes(v[1] for v in vals) + bytes(v[2] for v in vals)
    if t in (16, 30):
        cf = [v[0] for v in vals] if t == 30 else vals
        b = b''.join(v[0] for v in cf) + b''.join(inter([v[j] for v in cf], 4) for j in (1, 2, 3))
        if t == 30:
            b = b'\x10' + b + b'\x02' + b''.join(v[1] for v in vals)
        return b
    raise ValueError(t)

class Editable:
    """Place loaded with every property split per instance."""
    def __init__(self, data):
        P = Place(data)
        self.P = P
        self.meta = [c for c in P.chunks if c[0] in (b'META', b'SSTR')]
        self.cls = []  # list of dict(name, fmt, refs[], extra, props[(name,type,vals)])
        for cid in sorted(P.classes):
            c = P.classes[cid]
            n = len(c['refs'])
            props = []
            for pn in c['porder']:
                t, raw = c['props'][pn]
                props.append([pn, t, split(t, raw, n)])
            self.cls.append(dict(name=c['name'], fmt=c['fmt'], refs=list(c['refs']), extra=c['extra'], props=props))
        self.parent = dict(P.parent)
        self.prnt_order = list(P.prnt_order)
        self.loc = {}
        self._index()
    def _index(self):
        self.loc = {}
        for ci, c in enumerate(self.cls):
            for i, r in enumerate(c['refs']): self.loc[r] = (ci, i)
    def classof(self, r): return self.cls[self.loc[r][0]]['name']
    def prop(self, r, name):
        ci, i = self.loc[r]
        for pn, t, vals in self.cls[ci]['props']:
            if pn == name: return t, vals[i]
    def set_prop(self, r, name, value):
        ci, i = self.loc[r]
        for p in self.cls[ci]['props']:
            if p[0] == name: p[2][i] = value; return
        raise KeyError(name)
    def get_string(self, r, name):
        t, v = self.prop(r, name); assert t == 1; return v[4:]
    def set_string(self, r, name, s):
        if isinstance(s, str): s = s.encode('utf8')
        self.set_prop(r, name, struct.pack('<I', len(s)) + s)
    def name(self, r): return self.get_string(r, 'Name').decode('utf8', 'replace')
    def children(self, r):
        return [c for c in self.prnt_order if self.parent.get(c) == r]
    def path(self, r):
        parts = []
        while r in self.loc:
            parts.append(self.name(r)); r = self.parent.get(r, -1)
        return '.'.join(reversed(parts))
    def descendants(self, r):
        kids = {}
        for c in self.prnt_order: kids.setdefault(self.parent.get(c, -1), []).append(c)
        out = []; st = [r]
        while st:
            x = st.pop(); out.append(x); st.extend(kids.get(x, []))
        return out
    def delete(self, refs):
        dead = set(refs)
        for c in self.cls:
            keep = [i for i, r in enumerate(c['refs']) if r not in dead]
            if len(keep) == len(c['refs']): continue
            c['refs'] = [c['refs'][i] for i in keep]
            for p in c['props']: p[2] = [p[2][i] for i in keep]
        self.cls = [c for c in self.cls if c['refs']]
        self.prnt_order = [r for r in self.prnt_order if r not in dead]
        for r in dead: self.parent.pop(r, None)
        # refs pointing at deleted objects become nil
        for c in self.cls:
            for p in c['props']:
                if p[1] == 19: p[2] = [(-1 if v in dead else v) for v in p[2]]
        self._index()
    def save(self):
        # dense renumbering
        order = [r for c in self.cls for r in c['refs']]
        remap = {r: i for i, r in enumerate(order)}
        rm = lambda v: remap.get(v, -1) if v >= 0 else -1
        def chunk(name, body, compress=True):
            if compress:
                comp = lz4.block.compress(body, store_size=False)
                return name + struct.pack('<III', len(comp), len(body), 0) + comp
            return name + struct.pack('<III', 0, len(body), 0) + body
        out = [b'<roblox!\x89\xff\r\n\x1a\n' + struct.pack('<Hii', 0, len(self.cls), len(order)) + b'\0' * 8]
        for name, body in self.meta: out.append(chunk(name, body))
        for ci, c in enumerate(self.cls):
            refs = [remap[r] for r in c['refs']]
            body = struct.pack('<I', ci) + wstr(c['name'].encode()) + bytes([c['fmt']]) + struct.pack('<I', len(refs)) + refs_encode(refs)
            if c['fmt'] == 1: body += b'\x01' * len(refs)  # services: isService flags
            out.append(chunk(b'INST', body))
        for ci, c in enumerate(self.cls):
            for pn, t, vals in c['props']:
                if t == 19: vals = [rm(v) for v in vals]
                body = struct.pack('<I', ci) + wstr(pn.encode()) + bytes([t]) + join(t, vals)
                out.append(chunk(b'PROP', body))
        ch = [remap[r] for r in self.prnt_order]
        pa = [rm(self.parent.get(r, -1)) for r in self.prnt_order]
        out.append(chunk(b'PRNT', b'\x00' + struct.pack('<I', len(ch)) + refs_encode(ch) + refs_encode(pa)))
        out.append(chunk(b'END\0', b'</roblox>', compress=False))
        return b''.join(out)
