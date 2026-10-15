import struct, lz4.block, zstandard

def rd_chunks(data):
    assert data[:8] == b'<roblox!'
    ver, ncls, ninst = struct.unpack_from('<Hii', data, 14)
    pos = 32
    chunks = []
    while pos < len(data):
        name = data[pos:pos+4]; clen, ulen, res = struct.unpack_from('<III', data, pos+4); pos += 16
        if clen == 0:
            body = data[pos:pos+ulen]; pos += ulen
        else:
            raw = data[pos:pos+clen]; pos += clen
            if raw[:4] == b'\x28\xb5\x2f\xfd':
                body = zstandard.ZstdDecompressor().decompress(raw, max_output_size=ulen)
            else:
                body = lz4.block.decompress(raw, uncompressed_size=ulen)
        chunks.append([name, body])
        if name == b'END\0': break
    return (ver, ncls, ninst), chunks

def untransform_i32(b, n):
    # interleaved big-endian, zigzag
    out = []
    for i in range(n):
        v = (b[i] << 24) | (b[n+i] << 16) | (b[2*n+i] << 8) | b[3*n+i]
        out.append((v >> 1) ^ -(v & 1))
    return out
def transform_i32(vals):
    n = len(vals); arr = bytearray(4*n)
    for i, v in enumerate(vals):
        z = ((v << 1) ^ (v >> 31)) & 0xffffffff
        arr[i] = z >> 24; arr[n+i] = (z >> 16) & 255; arr[2*n+i] = (z >> 8) & 255; arr[3*n+i] = z & 255
    return bytes(arr)
def refs_decode(b, n):
    v = untransform_i32(b, n); acc = 0; out = []
    for x in v: acc += x; out.append(acc)
    return out
def refs_encode(vals):
    prev = 0; d = []
    for x in vals: d.append(x - prev); prev = x
    return transform_i32(d)

def rstr(b, p):
    l = struct.unpack_from('<I', b, p)[0]; return b[p+4:p+4+l], p+4+l
def wstr(s):
    return struct.pack('<I', len(s)) + s

class Place:
    def __init__(self, data):
        self.hdr, self.chunks = rd_chunks(data)
        self.classes = {}  # id -> dict(name, refs, props{name:(type, raw)})
        self.parent = {}
        self.order = []
        for name, body in self.chunks:
            if name == b'INST':
                cid, = struct.unpack_from('<I', body, 0)
                cn, p = rstr(body, 4)
                fmt = body[p]; n, = struct.unpack_from('<I', body, p+1)
                refs = refs_decode(body[p+5:p+5+4*n], n)
                self.classes[cid] = dict(name=cn.decode(), refs=refs, fmt=fmt, extra=body[p+5+4*n:], props={}, porder=[])
            elif name == b'PROP':
                cid, = struct.unpack_from('<I', body, 0)
                pn, p = rstr(body, 4)
                t = body[p]
                c = self.classes[cid]
                c['props'][pn.decode()] = (t, body[p+1:]); c['porder'].append(pn.decode())
            elif name == b'PRNT':
                n, = struct.unpack_from('<I', body, 1)
                ch = refs_decode(body[5:5+4*n], n); pa = refs_decode(body[5+4*n:5+8*n], n)
                for a, b2 in zip(ch, pa): self.parent[a] = b2
                self.prnt_order = ch
        self.inst = {}
        for cid, c in self.classes.items():
            for i, r in enumerate(c['refs']): self.inst[r] = (cid, i)
    def strings(self, cid, prop):
        c = self.classes[cid]
        if prop not in c['props']: return None
        t, raw = c['props'][prop]
        if t not in (1,): return None
        out = []; p = 0
        for _ in c['refs']:
            s, p = rstr(raw, p); out.append(s)
        return out
    def name(self, r):
        cid, i = self.inst[r]
        ns = self.strings(cid, 'Name')
        return ns[i].decode('utf8', 'replace') if ns else '?'
    def path(self, r):
        parts = []
        while r in self.inst:
            parts.append(self.name(r)); r = self.parent.get(r, -1)
        return '.'.join(reversed(parts))
