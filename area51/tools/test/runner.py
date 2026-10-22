#!/usr/bin/env python3
"""Run ZombieDirector in the mock Roblox. Usage: python3 tools/test/runner.py"""
import os
import lupa.lua51 as lupa
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
MOCKRBX = os.path.join(ROOT, "..", "roblox", "tools", "test", "mockrbx.lua")
lua = lupa.LuaRuntime()
g = lua.globals()
g.DIRECTOR_SOURCE = open(os.path.join(ROOT, "src", "ZombieDirector.lua"), encoding="utf8").read()
lua.execute("math.randomseed(3)")
lua.execute(open(MOCKRBX).read())
lua.execute(open(os.path.join(HERE, "run.lua")).read())
print(g.TEST_OUT)
