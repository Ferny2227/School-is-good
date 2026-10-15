import sys
sys.path.insert(0, '.')
from rbxlw import *
def same(a_path, b_path):
    A = Place(open(a_path, 'rb').read()); B = Place(open(b_path, 'rb').read())
    m = {}
    for cid in A.classes:
        a = A.classes[cid]; b = B.classes[cid]
        assert a['name'] == b['name'] and len(a['refs']) == len(b['refs'])
        for x, y in zip(a['refs'], b['refs']): m[x] = y
    m[-1] = -1
    for cid in A.classes:
        a = A.classes[cid]; b = B.classes[cid]
        assert a['porder'] == b['porder'], a['name']
        for pn in a['porder']:
            ta, ra = a['props'][pn]; tb, rb = b['props'][pn]
            assert ta == tb
            if ta == 19:
                n = len(a['refs'])
                assert [m.get(v, -1) for v in refs_decode(ra, n)] == refs_decode(rb, n), (a['name'], pn)
            else:
                assert ra == rb, (a['name'], pn)
    assert {m[k]: m.get(v, -1) for k, v in A.parent.items()} == B.parent
    print('identical content (after id renumbering)')
if __name__ == "__main__": same(sys.argv[1], sys.argv[2])
