"""Minimal reader/writer for binary Roblox places (.rbxl): instances, names, parents and script sources.

Strings are kept as raw bytes (old places contain non-UTF-8 text). Only Source/Name strings are edited; every other
chunk is written back untouched.
"""
import struct
import lz4.block


def unzig(v):
    return (v >> 1) ^ -(v & 1)


def zig(v):
    return ((v << 1) ^ (v >> 31)) & 0xffffffff


def dec_ints(buf, n):
    out = []
    for i in range(n):
        v = (buf[i] << 24) | (buf[n + i] << 16) | (buf[2 * n + i] << 8) | buf[3 * n + i]
        out.append(unzig(v))
    return out


def dec_refs(buf, n):
    out, acc = [], 0
    for v in dec_ints(buf, n):
        acc += v
        out.append(acc)
    return out


def enc_ints(vals):
    n = len(vals)
    zs = [zig(v) for v in vals]
    b = bytearray(4 * n)
    for i, z in enumerate(zs):
        b[i], b[n + i], b[2 * n + i], b[3 * n + i] = (z >> 24) & 255, (z >> 16) & 255, (z >> 8) & 255, z & 255
    return bytes(b)


def enc_refs(refs):
    prev, d = 0, []
    for r in refs:
        d.append(r - prev)
        prev = r
    return enc_ints(d)


def read_strings(body, n):
    out, q = [], 0
    for _ in range(n):
        k, = struct.unpack("<I", body[q:q + 4])
        out.append(bytes(body[q + 4:q + 4 + k]))
        q += 4 + k
    return out


def lstr(b):
    if isinstance(b, str):
        b = b.encode("utf8")
    return struct.pack("<I", len(b)) + b


class Place:
    def __init__(self, path):
        d = open(path, "rb").read()
        self.hdr = bytearray(d[:32])
        p, self.chunks = 32, []
        while p < len(d):
            name = d[p:p + 4]
            cl, ul, _ = struct.unpack("<iii", d[p + 4:p + 16])
            p += 16
            if cl:
                data = lz4.block.decompress(d[p:p + cl], uncompressed_size=ul)
                p += cl
            else:
                data = d[p:p + ul]
                p += ul
            self.chunks.append([name, bytearray(data), bool(cl)])
        self.classes = {}   # class id -> [class name, chunk, refs]
        for c in self.chunks:
            if c[0] == b"INST":
                cid, l = struct.unpack("<ii", c[1][:8])
                cn = bytes(c[1][8:8 + l]).decode()
                q = 9 + l
                n, = struct.unpack("<i", c[1][q:q + 4])
                self.classes[cid] = [cn, c, dec_refs(c[1][q + 4:q + 4 + 4 * n], n)]
        self.cls_of = {r: v[0] for v in self.classes.values() for r in v[2]}
        self.names, self.parent = {}, {}
        for cid, (cn, _, refs) in self.classes.items():
            for pn, c, off in self.props(cid):
                if pn == "Name":
                    for r, s in zip(refs, read_strings(c[1][off:], len(refs))):
                        self.names[r] = s.decode("utf8", "replace")
        for c in self.chunks:
            if c[0] == b"PRNT":
                n, = struct.unpack("<i", c[1][1:5])
                cs = dec_refs(c[1][5:5 + 4 * n], n)
                ps = dec_refs(c[1][5 + 4 * n:5 + 8 * n], n)
                self.parent.update(zip(cs, ps))

    def props(self, cid):
        for c in self.chunks:
            if c[0] == b"PROP" and struct.unpack("<i", c[1][:4])[0] == cid:
                l, = struct.unpack("<i", c[1][4:8])
                yield bytes(c[1][8:8 + l]).decode(), c, 9 + l

    def path(self, r):
        out = []
        while r in self.names:
            out.append(self.names[r])
            r = self.parent.get(r, -1)
        return ".".join(reversed(out))

    def scripts(self):
        """[(class, ref, path, source bytes)]"""
        out = []
        for cid, (cn, _, refs) in self.classes.items():
            if cn in ("Script", "LocalScript", "ModuleScript"):
                srcs = {}
                for pn, c, off in self.props(cid):
                    if pn == "Source":
                        srcs = dict(zip(refs, read_strings(c[1][off:], len(refs))))
                for r in refs:
                    out.append((cn, r, self.path(r), srcs.get(r, b"")))
        return out

    def set_sources(self, new):
        """new: {ref: source str/bytes}"""
        for cid, (cn, _, refs) in self.classes.items():
            if cn not in ("Script", "LocalScript", "ModuleScript"):
                continue
            for pn, c, off in self.props(cid):
                if pn == "Source":
                    vals = read_strings(c[1][off:], len(refs))
                    for i, r in enumerate(refs):
                        if r in new:
                            v = new[r]
                            vals[i] = v.encode("utf8") if isinstance(v, str) else v
                    c[1][:] = c[1][:off] + b"".join(lstr(v) for v in vals)

    def set_bool(self, cls, prop, ref, value):
        for cid, (cn, _, refs) in self.classes.items():
            if cn == cls:
                for pn, c, off in self.props(cid):
                    if pn == prop:
                        c[1][off + refs.index(ref)] = 1 if value else 0
                        return True
        return False

    def add_scripts(self, items):
        """items: [(class 'Script'|'LocalScript', name, source, parent ref or name of an earlier item)]. The class
        must already exist in the place."""
        ncls, ninst = struct.unpack("<ii", self.hdr[16:24])
        nxt, newref, prnt_c, prnt_p = ninst, {}, [], []
        for cn in ("Script", "LocalScript"):
            group = [x for x in items if x[0] == cn]
            if not group:
                continue
            cid = [k for k, v in self.classes.items() if v[0] == cn][0]
            _, c, refs = self.classes[cid]
            l, = struct.unpack("<i", c[1][4:8])
            q = 9 + l
            new_refs = list(range(nxt, nxt + len(group)))
            self.classes[cid][2] = refs + new_refs
            c[1][:] = c[1][:q] + struct.pack("<i", len(refs) + len(group)) + enc_refs(refs + new_refs)
            for r, (_, nm, src, par) in zip(new_refs, group):
                newref[nm] = r
                prnt_c.append(r)
                prnt_p.append(par if isinstance(par, int) else newref[par])
            nxt += len(group)
            for pn, pc, off in self.props(cid):
                if pn == "Name":
                    pc[1] += b"".join(lstr(x[1]) for x in group)
                elif pn == "Source":
                    pc[1] += b"".join(lstr(x[2]) for x in group)
                elif pn == "ScriptGuid":
                    import uuid
                    pc[1] += b"".join(lstr("{%s}" % str(uuid.uuid4()).upper()) for _ in group)
                elif pn in ("LinkedSource",):
                    pc[1] += b"".join(lstr("") for _ in group)
                elif pn == "Disabled":
                    pc[1] += bytes(len(group))
                else:
                    raise SystemExit("unexpected %s property %s" % (cn, pn))
        for c in self.chunks:
            if c[0] == b"PRNT":
                n, = struct.unpack("<i", c[1][1:5])
                cs = dec_refs(c[1][5:5 + 4 * n], n) + prnt_c
                ps = dec_refs(c[1][5 + 4 * n:5 + 8 * n], n) + prnt_p
                c[1][:] = b"\0" + struct.pack("<i", len(cs)) + enc_refs(cs) + enc_refs(ps)
        self.hdr[16:24] = struct.pack("<ii", ncls, nxt)
        return newref

    def find(self, path):
        for r in self.names:
            if self.path(r) == path:
                return r
        return None

    def save(self, path):
        out = bytearray(self.hdr)
        for name, data, comp in self.chunks:
            if comp:
                cdata = lz4.block.compress(bytes(data), store_size=False)
                out += name + struct.pack("<iii", len(cdata), len(data), 0) + cdata
            else:
                out += name + struct.pack("<iii", 0, len(data), 0) + data
        open(path, "wb").write(out)
