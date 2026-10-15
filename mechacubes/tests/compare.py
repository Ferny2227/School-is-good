# Lists GUI items whose position/size differs between two dumps (matched by name + order of appearance).
import sys, json, collections
a = json.load(open(sys.argv[1]))['items']; b = json.load(open(sys.argv[2]))['items']
def keyed(items):
    seen = collections.Counter(); out = {}
    for it in items:
        k = it.get('full', it['name']); seen[k] += 1
        out[(k, seen[k])] = it
    return out
A, B = keyed(a), keyed(b)
diffs = 0
for k in A:
    if k not in B:
        print('only in first :', k); diffs += 1; continue
    x, y = A[k], B[k]
    d = max(abs(x[f] - y[f]) for f in ('x', 'y', 'w', 'h'))
    if d > 3:
        diffs += 1
        print('%-22s first (%5.0f,%5.0f %4.0fx%4.0f)  second (%5.0f,%5.0f %4.0fx%4.0f)  text=%r' % (k[0] + '#' + str(k[1]), x['x'], x['y'], x['w'], x['h'], y['x'], y['y'], y['w'], y['h'], x.get('text')))
for k in B:
    if k not in A: print('only in second:', k); diffs += 1
print('differences:', diffs)
