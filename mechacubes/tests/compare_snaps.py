# Compares the screen after each click between two tours (matched by the clicked button).
import sys, json, collections
A = json.load(open(sys.argv[1]))['snaps']; B = json.load(open(sys.argv[2]))['snaps']
def keyed(items):
    seen = collections.Counter(); out = {}
    for it in items:
        k = it.get('full', it['name']); seen[k] += 1
        out[(k, seen[k])] = it
    return out
total = 0
for label in A:
    if label not in B:
        print('not clicked in second run:', label); continue
    a, b = keyed(A[label]), keyed(B[label])
    diffs = []
    for k in a:
        if k not in b: diffs.append('missing %s#%d' % k); continue
        x, y = a[k], b[k]
        d = max(abs(x[f] - y[f]) for f in ('x', 'y', 'w', 'h'))
        if d > 3: diffs.append('%s#%d (%0.f,%0.f %0.fx%0.f) vs (%0.f,%0.f %0.fx%0.f)' % (k + (x['x'], x['y'], x['w'], x['h'], y['x'], y['y'], y['w'], y['h'])))
    for k in b:
        if k not in a: diffs.append('extra %s#%d' % k)
    total += len(diffs)
    short = label.replace('Players.asdasda.PlayerGui.gui.', '')
    print('%-55s %3d items, %d differ' % (short, len(a), len(diffs)))
    for d in diffs[:6]: print('      ' + d)
print('total differences:', total)
