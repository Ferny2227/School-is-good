# Plays "a player joins MechaCubes" in the fake engine and reports what happened.
#   python3 run.py <place.rbxl> [--api v270|v227|v2018] [--datastore ok|unpublished|forbidden|fail|hang]
#                  [--seconds 60] [--echo] [--drop-queue] [--modern]
import sys, os, argparse, subprocess
from lupa import lua51
HERE = os.path.dirname(os.path.abspath(__file__))
ap = argparse.ArgumentParser()
ap.add_argument('place')
ap.add_argument('--api', default='v270')
ap.add_argument('--datastore', default='unpublished')
ap.add_argument('--seconds', type=float, default=60)
ap.add_argument('--echo', action='store_true')
ap.add_argument('--drop-queue', action='store_true')
ap.add_argument('--modern', action='store_true', help='2018 Lua helpers (typeof, math.clamp, Color3.fromRGB/HSV, :Connect, TweenInfo)')
ap.add_argument('--web-fail', action='store_true')
ap.add_argument('--quiet', action='store_true')
ap.add_argument('--click', action='store_true', help='after loading, click every visible button')
a = ap.parse_args()

cache = os.path.join(HERE, '.cache')
os.makedirs(cache, exist_ok=True)
placeLua = os.path.join(cache, os.path.basename(a.place) + '.lua')
if not os.path.exists(placeLua) or os.path.getmtime(placeLua) < os.path.getmtime(a.place):
    subprocess.run([sys.executable, os.path.join(HERE, 'export.py'), a.place, placeLua], check=True, stdout=subprocess.DEVNULL)

L = lua51.LuaRuntime(unpack_returned_tuples=True)
g = L.globals()
modern = a.modern or a.api == 'v2018'
L.execute('OPTIONS = {}')
opt = g.OPTIONS
opt.datastore = a.datastore
opt.echo = a.echo
opt.dropRemoteQueue = a.drop_queue
opt.webApisFail = a.web_fail
if os.environ.get('TRACE'):
    opt.traceName, opt.traceProp = os.environ['TRACE'].split('.')
for k in ('typeof', 'mathClamp', 'color3FromRGB', 'color3FromHSV', 'modernSignals', 'tweenInfo', 'udim2Lerp'):
    opt[k] = modern
# Color3.fromRGB arrived during 2016; assume the late-2016 engine has it but not the early one
if a.api == 'v270': opt.color3FromRGB = True
g.API = L.execute(open(os.path.join(HERE, 'api', a.api + '.lua')).read())
L.execute(open(os.path.join(HERE, '..', '..', 'shooter-arena', 'tools', 'tests', 'mock.lua')).read())
L.execute(open(os.path.join(HERE, 'engine.lua')).read())
src = open(placeLua).read()
L.execute(src.replace('return T', 'PLACE = T'))
L.execute(open(os.path.join(HERE, 'world.lua')).read())

L.execute('''
START_SERVER()
runFor(1)
JOINER = ADD_PLAYER("asdasda")
runFor(%f)
''' % a.seconds)
if a.click:
    if os.environ.get('SNAPS'):
        import json
        snapdir = os.environ['SNAPS']; os.makedirs(snapdir, exist_ok=True)
        dumpsrc = open(os.path.join(HERE, 'dumpgui.lua')).read()
        snaps = {}
        def snap(label):
            items = L.execute(dumpsrc)
            snaps[label] = [{k: (list(v.values()) if hasattr(v, 'values') else v) for k, v in it.items()} for it in items.values()]
        g.SNAP = snap
    L.execute('ROUNDS = %d' % int(os.environ.get('ROUNDS', '3')))
    L.execute(open(os.path.join(HERE, 'click.lua')).read())
    if os.environ.get('SNAPS'):
        json.dump({'api': a.api, 'snaps': snaps}, open(os.path.join(snapdir, 'snaps.json'), 'w'))
if os.environ.get('EXTRA'):
    print('EXTRA:', L.execute(open(os.environ['EXTRA']).read()))

lua = L.eval
def p(*x):
    if not a.quiet: print(*x)
dropped = g.DROPPED
dc = dict(dropped.classes.items())
p('== engine', a.api, '| datastore', a.datastore, '| modern helpers', modern)
p('dropped classes (not in this engine):', dc)
logs = list(g.LOG.values())
p('\n== log (%d lines, prints/warnings/errors)' % len(logs))
for l in logs:
    if not a.quiet and (' RUN ' not in l):
        print('  ' + l[:300])
errs = [(e.msg, e.tb, e.ctx) for e in g.ERRORS.values()]
seen = set()
p('\n== errors: %d' % len(errs))
for m, tb, c in errs:
    if m in seen: continue
    seen.add(m)
    p('  [%s] %s' % (c, m))
    tbs = [x for x in str(tb).split('\n') if x.strip() and 'engine.lua' not in x and 'world.lua' not in x and '[C]' not in x and 'stack traceback' not in x]
    for x in tbs[:4]: p('       ' + x.strip())
p('\n== engine functions the test engine only faked:', dict(g.SIM_MISSING.items()))
p('\n== threads still waiting')
for t in lua('blockedThreads')().values():
    tb = [x.strip() for x in str(t.tb).split('\n') if x.strip() and 'engine.lua' not in x and 'world.lua' not in x and '[C]' not in x and 'stack traceback' not in x]
    p('  [%s] %s  @ %s' % (t.ctx, t.why, ' <- '.join(tb[:3])))
state = L.execute('''
local p = JOINER
local out = {}
local pg = p:FindFirstChild("PlayerGui")
local lg = pg and pg:FindFirstChild("loadGui")
local ls = lg and lg:FindFirstChild("loadscreen")
out.loadGui = lg ~= nil
out.loadVisible = ls and ls.Visible
out.loadText = ls and ls:FindFirstChild("label") and ls.label.Text
local gui = pg and pg:FindFirstChild("gui")
out.gui = gui ~= nil
if gui and gui:FindFirstChild("topbar") then
	out.cash = gui.topbar.statsHolder.cash.label.Text
	out.rank = gui.topbar.statsHolder.rank.label.Text
	out.xp = gui.topbar.bar.label.Text
end
out.leaderstats = p:FindFirstChild("leaderstats") ~= nil
out.kicked = KICKED
return out
''')
st = dict(state.items())
p('\n== result after %gs:' % a.seconds, st)
ok = st.get('loadGui') and not st.get('loadVisible') and st.get('leaderstats') and st.get('cash') not in (None, ' 100')
if a.click:
    clicks = list(g.CLICKED.values())
    bad = [(c.path, list(c.errors.values())) for c in clicks if len(c.errors) > 0]
    print('CLICKED %d buttons, %d caused errors' % (len(clicks), len(bad)))
    for path, errs in bad:
        print('  CLICK %s' % path.replace('Players.asdasda.PlayerGui.', ''))
        for e in errs[:3]: print('      ' + e[:240])
print('RESULT[%s %s]: %s' % (a.api, a.datastore, 'LOADED' if ok else 'STUCK'), '| errors', len(seen))

# ---- optional: dump what is on screen for render.py
if os.environ.get('DUMP'):
    import json
    items = L.execute(open(os.path.join(HERE, 'dumpgui.lua')).read())
    out = []
    for it in items.values():
        out.append({k: (list(v.values()) if hasattr(v, 'values') else v) for k, v in it.items()})
    json.dump({'api': a.api, 'items': out}, open(os.environ['DUMP'], 'w'))
    print('dumped', len(out), 'gui items to', os.environ['DUMP'])
