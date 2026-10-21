#!/usr/bin/env python3
"""Build AirportTycoon-Admin.rbxl from base/AirportTycoon.rbxl and the Lua sources in src/.

- ServerScriptService.AirportServer source = src/server/*.lua joined in file-name order
- StarterGui.AirportClient source        = src/client/AirportClient.lua + src/client/BuildTag.lua
- adds ServerScriptService.AdminServer (+ AdminClient inside it) and StarterGui.AdminAnnounce
- turns Workspace.FilteringEnabled on

Needs: pip install lz4   (lupa is optional: if present every script is syntax-checked as Lua 5.1)
Usage: python3 tools/build.py [out.rbxl]
"""
import glob
import os
import struct
import sys

import lz4.block

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BASE = os.path.join(ROOT, "base", "AirportTycoon.rbxl")
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "AirportTycoon-Admin.rbxl")


def read(path):
    with open(os.path.join(ROOT, path), encoding="utf8") as f:
        return f.read()


def server_source():
    parts = [open(p, encoding="utf8").read() for p in sorted(glob.glob(os.path.join(ROOT, "src", "server", "s*.lua")))]
    return "\n" + "\n".join(parts)


SOURCES = {  # existing scripts whose Source is replaced
    "AirportServer": server_source(),
    "AirportClient": read("src/client/AirportClient.lua") + read("src/client/BuildTag.lua"),
}
NEW = [  # (class, name, source file, parent: service name or the name of another new script)
    ("Script", "AdminServer", "src/AdminServer.lua", "ServerScriptService"),
    ("LocalScript", "AdminClient", "src/AdminClient.lua", "AdminServer"),
    ("LocalScript", "AdminAnnounce", "src/AdminAnnounce.lua", "StarterGui"),
]


def check_syntax():
    try:
        import lupa.lua51 as lupa
    except ImportError:
        print("(lupa not installed: skipping the Lua syntax check)")
        return
    lua = lupa.LuaRuntime()
    check = lua.eval("function(s, n) local f, e = loadstring(s, n) return e end")
    bad = False
    for name, src in list(SOURCES.items()) + [(n, read(f)) for _, n, f, _ in NEW]:
        err = check(src, name)
        if err:
            print("SYNTAX ERROR:", err)
            bad = True
    if bad:
        sys.exit(1)
    print("Lua syntax OK")


# ---------------------------------------------------------------- binary format helpers
def unzig(v):
    return (v >> 1) ^ -(v & 1)


def zig(v):
    return ((v << 1) ^ (v >> 31)) & 0xFFFFFFFF


def dec_refs(buf, n):
    out, acc = [], 0
    for i in range(n):
        v = (buf[i] << 24) | (buf[n + i] << 16) | (buf[2 * n + i] << 8) | buf[3 * n + i]
        acc += unzig(v)
        out.append(acc)
    return out


def enc_refs(refs):
    n, prev, b = len(refs), 0, bytearray(4 * len(refs))
    for i, r in enumerate(refs):
        v = zig(r - prev)
        prev = r
        b[i], b[n + i], b[2 * n + i], b[3 * n + i] = (v >> 24) & 255, (v >> 16) & 255, (v >> 8) & 255, v & 255
    return bytes(b)


def lstr(s):
    b = s.encode("utf8")
    return struct.pack("<i", len(b)) + b


def read_strings(body, n):
    out, q = [], 0
    for _ in range(n):
        k, = struct.unpack("<i", body[q:q + 4])
        out.append(bytes(body[q + 4:q + 4 + k]).decode("utf8"))
        q += 4 + k
    return out


def main():
    check_syntax()
    d = open(BASE, "rb").read()
    hdr = bytearray(d[:32])
    p, chunks = 32, []
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
        chunks.append([name, bytearray(data), bool(cl)])

    ncls, ninst = struct.unpack("<ii", hdr[16:24])
    inst = {}  # class name -> [class id, INST chunk, referents]
    for c in chunks:
        if c[0] == b"INST":
            cid, l = struct.unpack("<ii", c[1][:8])
            cn = bytes(c[1][8:8 + l]).decode()
            q = 9 + l
            n, = struct.unpack("<i", c[1][q:q + 4])
            inst[cn] = [cid, c, dec_refs(c[1][q + 4:q + 4 + 4 * n], n)]

    def props(cid):
        for c in chunks:
            if c[0] == b"PROP" and struct.unpack("<i", c[1][:4])[0] == cid:
                l, = struct.unpack("<i", c[1][4:8])
                yield bytes(c[1][8:8 + l]).decode(), c, 9 + l

    names = {}  # class -> names of its instances, in referent order
    for cn in ("Script", "LocalScript"):
        cid, _, refs = inst[cn]
        for pn, c, off in props(cid):
            if pn == "Name":
                names[cn] = read_strings(c[1][off:], len(refs))

    # 1. replace sources of existing scripts
    found = set()
    for cn in ("Script", "LocalScript"):
        cid, _, refs = inst[cn]
        for pn, c, off in props(cid):
            if pn == "Source":
                vals = read_strings(c[1][off:], len(refs))
                for i, nm in enumerate(names[cn]):
                    if nm in SOURCES:
                        vals[i] = SOURCES[nm]
                        found.add(nm)
                c[1][:] = c[1][:off] + b"".join(lstr(v) for v in vals)
    missing = set(SOURCES) - found
    assert not missing, "scripts not found in the base place: %s" % missing

    # 2. add the new scripts
    svc = {cn: v[2][0] for cn, v in inst.items() if cn in ("ServerScriptService", "StarterGui")}
    nxt, newref, prnt_c, prnt_p = ninst, {}, [], []
    for cn in ("Script", "LocalScript"):
        items = [x for x in NEW if x[0] == cn]
        cid, c, refs = inst[cn]
        l, = struct.unpack("<i", c[1][4:8])
        q = 9 + l
        new_refs = list(range(nxt, nxt + len(items)))
        inst[cn][2] = refs + new_refs
        c[1][:] = c[1][:q] + struct.pack("<i", len(refs) + len(items)) + enc_refs(refs + new_refs)
        for r, (_, nm, f, par) in zip(new_refs, items):
            newref[nm] = r
            prnt_c.append(r)
            prnt_p.append(svc.get(par, newref.get(par)))
        nxt += len(items)
        for pn, pc, off in props(cid):
            if pn == "Name":
                pc[1] += b"".join(lstr(x[1]) for x in items)
            elif pn == "Source":
                pc[1] += b"".join(lstr(read(x[2])) for x in items)
            elif pn == "LinkedSource":
                pc[1] += b"".join(lstr("") for _ in items)
            elif pn == "Disabled":
                pc[1] += bytes(len(items))
            else:
                raise SystemExit("unexpected %s property %s" % (cn, pn))
    assert None not in prnt_p
    for c in chunks:
        if c[0] == b"PRNT":
            n, = struct.unpack("<i", c[1][1:5])
            cs = dec_refs(c[1][5:5 + 4 * n], n) + prnt_c
            ps = dec_refs(c[1][5 + 4 * n:5 + 8 * n], n) + prnt_p
            c[1][:] = b"\0" + struct.pack("<i", len(cs)) + enc_refs(cs) + enc_refs(ps)

    # 3. FilteringEnabled on (exploiters' client-side changes stop replicating)
    for pn, c, off in props(inst["Workspace"][0]):
        if pn == "FilteringEnabled":
            assert c[1][off - 1] == 2
            c[1][-1] = 1

    hdr[16:24] = struct.pack("<ii", ncls, nxt)
    out = bytearray(hdr)
    for name, data, comp in chunks:
        if comp:
            z = lz4.block.compress(bytes(data), store_size=False, mode="high_compression")
            out += name + struct.pack("<iii", len(z), len(data), 0) + z
        else:
            out += name + struct.pack("<iii", 0, len(data), 0) + data
    with open(OUT, "wb") as f:
        f.write(out)
    print("wrote %s (%d bytes, server %d bytes)" % (OUT, len(out), len(SOURCES["AirportServer"])))


if __name__ == "__main__":
    main()
