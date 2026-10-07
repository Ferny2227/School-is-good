# Runs ShooterMain in the fake Roblox: players join, vote, pick teams, shoot; every mode is played.
import sys, os
from lupa import lua51
SP = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(SP, '..', '..', 'src')
L = lua51.LuaRuntime(unpack_returned_tuples=True)
L.execute(open(os.path.join(SP, 'mock.lua')).read())
L.execute(open(os.path.join(SP, 'server_env.lua')).read())
g = L.globals()
for n in ['SConfig', 'SGuns', 'SMaps', 'ShooterMain']:
    g['SRC_' + n] = open(os.path.join(SRC, n + '.lua')).read()
L.execute(open(os.path.join(SP, 'server_scenario.lua')).read())
