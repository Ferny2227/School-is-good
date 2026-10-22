#!/usr/bin/env python3
"""Build Area51-Zombies.rbxl from base/Area51.rbxl.

- adds ServerScriptService.ZombieDirector (src/ZombieDirector.lua)
- switches off the zombies' own respawn / chase / reward / regen scripts (the director does all of that now) and
  every script in zombie models that have no body (they only made errors)
- switches off the two duplicate payday scripts that each made a second leaderstats, and the PlayerPoints script
- badge awarders only award a badge the player doesn't have yet, once
Usage: python3 tools/build.py
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
from rbxl import Place  # noqa: E402

p = Place(os.path.join(ROOT, "base", "Area51.rbxl"))
kids = {}
for c, par in p.parent.items():
    kids.setdefault(par, []).append(c)


def children(r):
    return kids.get(r, [])


def desc(r):
    out = []
    for c in children(r):
        out.append(c)
        out += desc(c)
    return out


def child(r, name):
    for c in children(r):
        if p.names.get(c) == name:
            return c
    return None


def is_zombie(m):
    if p.cls_of.get(m) != "Model":
        return False
    hum = [c for c in children(m) if p.cls_of.get(c) == "Humanoid"]
    if not hum:
        return False
    n = p.names.get(m, "").lower()
    return "zombie" in n or "necromorph" in n or child(m, "zarm") is not None or \
        any(p.names.get(h) == "Zombie" for h in hum)


src = {r: s for (_, r, _, s) in p.scripts()}
OFF_NAMES = {"Respawn", "Points", "Cash", "Robot", "Follow", "chase&kill", "Motivation", "BackupRemove"}
off = []
zombies = [m for m in p.cls_of if is_zombie(m)]
for m in zombies:
    has_body = any(p.cls_of.get(c) in ("Part", "WedgePart") for c in children(m))
    for s in desc(m):
        if p.cls_of.get(s) != "Script":
            continue
        name = p.names.get(s, "")
        code = src.get(s, b"")
        if not has_body or name in OFF_NAMES or (name == "Script" and b"findNearestTorso" in code) or \
                (name == "Health" and b"regeneration" in code):
            off.append(s)

# duplicate leaderstats makers + PlayerPoints spam
for (cn, r, path, code) in p.scripts():
    if cn == "Script" and path == "Workspace.Model.Payday" and b'stats.Name = "leaderstats"' in code:
        off.append(r)
    if cn == "Script" and b"AwardPoints" in code:
        off.append(r)

for r in set(off):
    assert p.set_bool("Script", "Disabled", r, True), r
print("switched off %d scripts in %d zombie models + extras" % (len(set(off)), len(zombies)))

# badge awarders: once per player, only if they don't have it
BADGE = '''-- awards the badge once, and only if the player doesn't have it yet
local BadgeService = game:GetService("BadgeService")
local done = {}
local id = script.Parent:WaitForChild("BadgeID").Value
script.Parent.Touched:connect(function(part)
	local p = part.Parent and game.Players:GetPlayerFromCharacter(part.Parent)
	if not p or done[p.userId] then return end
	done[p.userId] = true
	pcall(function()
		if not BadgeService:UserHasBadge(p.userId, id) then BadgeService:AwardBadge(p.userId, id) end
	end)
end)
'''
new = {}
for (cn, r, path, code) in p.scripts():
    if p.names.get(r) == "BadgeAwarderScript":
        new[r] = BADGE
p.set_sources(new)
print("fixed %d badge awarders" % len(new))

sss = [r for r, c in p.cls_of.items() if c == "ServerScriptService"][0]
director = open(os.path.join(ROOT, "src", "ZombieDirector.lua"), encoding="utf8").read()
try:
    import lupa.lua51 as lupa
    lupa.LuaRuntime().execute("return function() " + director + "\nend")
    print("Lua syntax OK")
except ImportError:
    pass
p.add_scripts([("Script", "ZombieDirector", director, sss)])
out = os.path.join(ROOT, "Area51-Zombies.rbxl")
p.save(out)
print("wrote", out, os.path.getsize(out), "bytes")
