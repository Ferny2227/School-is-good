#!/usr/bin/env python3
"""Run OceanServer in the mock Roblox. Usage: python3 tools/test/runner.py"""
import os
import lupa.lua51 as lupa
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
lua = lupa.LuaRuntime()
g = lua.globals()
g.SERVER_SOURCE = open(os.path.join(ROOT, "src", "OceanServer.lua"), encoding="utf8").read()
g.CLIENT_SOURCE = open(os.path.join(ROOT, "src", "OceanClient.lua"), encoding="utf8").read()
lua.execute("math.randomseed(5)")
lua.execute(open(os.path.join(ROOT, "..", "roblox", "tools", "test", "mockrbx.lua")).read())
lua.execute(open(os.path.join(HERE, "run.lua")).read())
print(g.TEST_OUT)
