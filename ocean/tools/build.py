#!/usr/bin/env python3
"""Build DisasterOcean.rbxl: starts from the airport's base place (an almost empty 2016 place), puts the ocean
game's scripts in (src/server/o*.lua -> ServerScriptService.OceanServer, src/OceanClient.lua ->
StarterGui.OceanClient), adds the admin scripts (asdasda only, money = Coins) and turns FilteringEnabled on.
The server script removes the old airport map when the game starts and builds the ocean world.
Usage: python3 tools/build.py
"""
import os
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
REPO = os.path.dirname(ROOT)
sys.path.insert(0, os.path.join(REPO, "area51", "tools"))
from rbxl import Place, read_strings, lstr  # noqa: E402

p = Place(os.path.join(REPO, "roblox", "base", "AirportTycoon.rbxl"))
import glob
src = lambda f: open(os.path.join(ROOT, "src", f), encoding="utf8").read()
server_source = "\n".join(open(f, encoding="utf8").read() for f in sorted(glob.glob(os.path.join(ROOT, "src", "server", "o*.lua"))))
admin = lambda f: open(os.path.join(REPO, "roblox", "src", f), encoding="utf8").read()
try:
    import lupa.lua51 as lupa
    for code in (server_source, src("OceanClient.lua")):
        lupa.LuaRuntime().execute("return function() " + code + "\nend")
    print("Lua syntax OK")
except ImportError:
    pass

refs = {p.path(r): r for (cn, r, path, s) in p.scripts()}
server, client = refs["ServerScriptService.AirportServer"], refs["StarterGui.AirportClient"]
p.set_sources({server: server_source, client: src("OceanClient.lua")})
# rename them
for cid, (cn, _, rs) in p.classes.items():
    if cn in ("Script", "LocalScript"):
        for pn, c, off in p.props(cid):
            if pn == "Name":
                vals = read_strings(c[1][off:], len(rs))
                for i, r in enumerate(rs):
                    if r == server:
                        vals[i] = b"OceanServer"
                    if r == client:
                        vals[i] = b"OceanClient"
                c[1][:] = c[1][:off] + b"".join(lstr(v) for v in vals)
sss = [r for r, c in p.cls_of.items() if c == "ServerScriptService"][0]
sg = [r for r, c in p.cls_of.items() if c == "StarterGui"][0]
p.add_scripts([
    ("Script", "AdminServer", admin("AdminServer.lua").replace('FindFirstChild("Cash")', 'FindFirstChild("Coins")'), sss),
    ("LocalScript", "AdminClient", admin("AdminClient.lua"), "AdminServer"),
    ("LocalScript", "AdminAnnounce", admin("AdminAnnounce.lua"), sg),
])
for cid, (cn, _, rs) in p.classes.items():
    if cn == "Workspace":
        for pn, c, off in p.props(cid):
            if pn == "FilteringEnabled":
                c[1][off] = 1
out = os.path.join(ROOT, "DisasterOcean.rbxl")
p.save(out)
print("wrote", out, os.path.getsize(out), "bytes")
