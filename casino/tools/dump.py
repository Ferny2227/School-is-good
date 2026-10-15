import sys, os, re, collections
sys.path.insert(0, '.')
from rbxl import *
P = Place(open(sys.argv[1], 'rb').read())
out = sys.argv[2]
os.makedirs(out, exist_ok=True)
seen = collections.Counter()
idx = []
for cid, c in P.classes.items():
    if c['name'] in ('Script', 'LocalScript', 'ModuleScript'):
        src = P.strings(cid, 'Source')
        dis = c['props'].get('Disabled')
        for i, r in enumerate(c['refs']):
            p = P.path(r)
            fn = re.sub(r'[^A-Za-z0-9_.]+', '_', p)
            seen[fn] += 1
            if seen[fn] > 1: fn += f'__{seen[fn]}'
            fn += {'Script': '.server.lua', 'LocalScript': '.client.lua', 'ModuleScript': '.lua'}[c['name']]
            disabled = dis and dis[1][i] == 1
            open(os.path.join(out, fn), 'wb').write(src[i])
            idx.append((len(src[i]), c['name'], 'DISABLED' if disabled else '', p, fn))
idx.sort(key=lambda x: x[3])
with open(os.path.join(out, '_index.txt'), 'w') as f:
    for x in idx: f.write('%8d %-12s %-8s %s\n' % x[:4])
