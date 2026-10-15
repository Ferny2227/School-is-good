# When did each API member first appear? Uses the RobloxAPI/archive dumps.
import json, os, sys
A = '/home/user/robloxapi/archive'
b = json.load(open(A + '/builds.json'))
order = []
for x in b:
    if os.path.exists('%s/data/api-dump/json/%s.json' % (A, x['Hash'])):
        if not order or order[-1][0] != x['Hash']: order.append((x['Hash'], x['Date'][:10], x['Version']))
_cache = {}
def members(h):
    if h in _cache: return _cache[h]
    d = json.load(open('%s/data/api-dump/json/%s.json' % (A, h)))
    s = set(); sup = {}
    for c in d['Classes']:
        s.add(c['Name']); sup[c['Name']] = c['Superclass']
        for m in c.get('Members', []):
            s.add(c['Name'] + '.' + m['Name'])
    for e in d.get('Enums', []):
        s.add('Enum.' + e['Name'])
        for it in e.get('Items', []): s.add('Enum.' + e['Name'] + '.' + it['Name'])
    _cache[h] = (s, sup)
    return _cache[h]
def has(h, w):
    s, sup = members(h)
    if w in s: return True
    if '.' in w and not w.startswith('Enum.'):
        cls, m = w.split('.', 1)
        while cls in sup:
            cls = sup[cls]
            if cls + '.' + m in s: return True
    return False
def first(w):
    for h, d, v in order:
        if has(h, w): return d, v
    return None
if __name__ == '__main__':
    print('builds', len(order), order[0][1], order[-1][1])
    for w in sys.argv[1:]:
        print('%-45s %s' % (w, first(w)))
