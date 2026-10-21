#!/usr/bin/env python3
"""Run AirportServer (src/server/*.lua) in the mock Roblox. Usage: python3 tools/test/runner.py [seconds]"""
import glob, os, sys, time
import lupa.lua51 as lupa
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
src = "\n" + "\n".join(open(p, encoding="utf8").read() for p in sorted(glob.glob(os.path.join(ROOT, "src", "server", "s*.lua"))))
lua = lupa.LuaRuntime()
g = lua.globals()
g.SERVER_SOURCE = src
args = [a for a in sys.argv[1:] if not a.startswith("--")]
g.SIM_SECONDS = int(args[0]) if args else 240
g.CRUISE_SECONDS = int(args[1]) if len(args) > 1 else 45
lua.execute("math.randomseed(7)")
lua.execute(open(os.path.join(HERE, "mockrbx.lua")).read())
t0 = time.time()
lua.execute(open(os.path.join(HERE, "run.lua")).read())
print(g.TEST_OUT)
if "--client" in sys.argv:
    g.CLIENT_SOURCE = open(os.path.join(ROOT, "src", "client", "AirportClient.lua"), encoding="utf8").read()
    lua.execute(open(os.path.join(HERE, "client.lua")).read())
    print(g.CLIENT_OUT)
if "--geo" in sys.argv:
    g.GEO_SECONDS = 150
    lua.execute(open(os.path.join(HERE, "geo.lua")).read())
    print(g.GEO_OUT)
print("(%.1fs)" % (time.time() - t0))
