# Plays Jeep Obby in the fake 2016 engine (mechacubes/tests): a player joins, the UI builds, a car spawns,
# then the scenario drives through checkpoints, level ends and the win pad, and uses every UI button.
#   python3 run.py <place.rbxl> [--api v227|v270|v2018] [--echo]
import sys, os, argparse, subprocess
from lupa import lua51
HERE = os.path.dirname(os.path.abspath(__file__))
ENG = os.path.join(HERE, '..', '..', 'mechacubes', 'tests')
ap = argparse.ArgumentParser()
ap.add_argument('place'); ap.add_argument('--api', default='v227'); ap.add_argument('--echo', action='store_true')
ap.add_argument('--datastore', default='unpublished')
a = ap.parse_args()
cache = os.path.join(HERE, '.cache'); os.makedirs(cache, exist_ok=True)
placeLua = os.path.join(cache, os.path.basename(a.place) + '.lua')
if not os.path.exists(placeLua) or os.path.getmtime(placeLua) < os.path.getmtime(a.place):
    subprocess.run([sys.executable, os.path.join(ENG, 'export.py'), a.place, placeLua], check=True, stdout=subprocess.DEVNULL)
L = lua51.LuaRuntime(unpack_returned_tuples=True)
g = L.globals()
L.execute('OPTIONS = {}')
opt = g.OPTIONS
opt.datastore = a.datastore; opt.echo = a.echo
modern = a.api == 'v2018'
for k in ('typeof', 'mathClamp', 'color3FromRGB', 'color3FromHSV', 'modernSignals', 'tweenInfo', 'udim2Lerp'):
    opt[k] = modern
opt.oldPcall = not modern
g.API = L.execute(open(os.path.join(ENG, 'api', a.api + '.lua')).read())
L.execute(open(os.path.join(ENG, '..', '..', 'shooter-arena', 'tools', 'tests', 'mock.lua')).read())
L.execute(open(os.path.join(ENG, 'engine.lua')).read())
L.execute(open(placeLua).read().replace('return T', 'PLACE = T'))
L.execute(open(os.path.join(ENG, 'world.lua')).read())
L.execute('START_SERVER() runFor(1) JOINER = ADD_PLAYER("tester") runFor(6)')
ROUNDS = 2
L.execute('ROUNDS = 2')
out = L.execute(open(os.environ.get('SCENARIO') or os.path.join(HERE, 'scenario.lua')).read())
if isinstance(out, str): out = {1: out}
for line in out.values(): print(line)
errs = [(e.msg, e.tb, e.ctx) for e in g.ERRORS.values()]
seen = set()
print('\n== errors: %d' % len(errs))
for m, tb, c in errs:
    if m in seen: continue
    seen.add(m)
    print('  [%s] %s' % (c, m))
    tbs = [x for x in str(tb).split('\n') if x.strip() and 'engine.lua' not in x and 'world.lua' not in x and '[C]' not in x and 'stack traceback' not in x]
    for x in tbs[:4]: print('       ' + x.strip())
print('== faked:', dict(g.SIM_MISSING.items()))
print('== dropped classes:', dict(g.DROPPED.classes.items()))
for l in g.LOG.values():
    if 'print' in l or 'warn' in l.lower(): print('  ' + l[:200])
if os.environ.get('DUMP'):
    import json
    for panel in ('', 'Garage', 'Levels', 'Win'):
        L.execute('local ui = JOINER.PlayerGui.JeepObbyUI ui.Garage.Visible=false ui.Levels.Visible=false ui.Win.Visible=false ' + (('ui.%s.Visible = true ' % panel) if panel else '') + 'ui.Toast.Visible=false')
        items = L.execute(open(os.path.join(ENG, 'dumpgui.lua')).read())
        out = [{k: (list(v.values()) if hasattr(v, 'values') else v) for k, v in it.items()} for it in items.values()]
        fn = os.environ['DUMP'] + (panel or 'HUD') + '.json'
        json.dump({'api': a.api, 'items': out}, open(fn, 'w'))
        print('dumped', fn)
