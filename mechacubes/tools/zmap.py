# Picks how to squeeze ZIndex values into 1..10 (2016 engines) so overlapping GUI objects keep
# their draw order. Input: lines "dfsOrder <tab> z <tab> x y w h <tab> path".
import sys, itertools, bisect

def load(path):
    items = []
    for line in open(path):
        p = line.rstrip('\n').split('\t')
        if len(p) < 7 or not p[0].isdigit(): continue
        items.append((int(p[0]), int(p[1]), float(p[2]), float(p[3]), float(p[4]), float(p[5]), p[6]))
    return items

def bad_pairs(items):
    """pairs where modern draws b over a (zb > za) but tree order alone would draw a over b"""
    out = []
    for a, b in itertools.combinations(items, 2):
        if a[1] == b[1]: continue
        if a[1] > b[1]: a, b = b, a
        if a[0] < b[0]: continue  # tree order agrees with z order: fine whatever the mapping
        if a[4] <= 0 or a[5] <= 0 or b[4] <= 0 or b[5] <= 0: continue
        if a[2] < b[2] + b[4] and b[2] < a[2] + a[4] and a[3] < b[3] + b[5] and b[3] < a[3] + a[5]:
            pa, pb = a[6].split('.')[:3], b[6].split('.')[:3]
            same = pa == pb  # same panel (StarterGui.gui.<panel>) -> always on screen together
            out.append((a[1], b[1], a[6], b[6], 50 if same else 1))
    return out

def best_mapping(items, levels=10):
    values = sorted(set(it[1] for it in items))
    pairs = bad_pairs(items)
    idx = {v: i for i, v in enumerate(values)}
    K = len(values)
    # cost[i][j] = pairs with both values inside values[i..j] (they'd get the same level)
    cnt = [[0] * K for _ in range(K)]
    for za, zb, _, _, w in pairs:
        cnt[idx[za]][idx[zb]] += w
    cost = [[0] * K for _ in range(K)]
    for i in range(K):
        acc = 0
        for j in range(i, K):
            # add pairs (k, j) with i <= k <= j
            acc += sum(cnt[k][j] for k in range(i, j + 1))
            cost[i][j] = acc
    INF = float('inf')
    # dp[l][j] = best cost covering values[0..j-1] with l levels
    dp = [[INF] * (K + 1) for _ in range(levels + 1)]
    cut = [[0] * (K + 1) for _ in range(levels + 1)]
    dp[0][0] = 0
    for l in range(1, levels + 1):
        for j in range(1, K + 1):
            for i in range(0, j):
                c = dp[l - 1][i] + cost[i][j - 1]
                if c < dp[l][j]:
                    dp[l][j] = c; cut[l][j] = i
    best_l = min(range(1, levels + 1), key=lambda l: dp[l][K])
    # rebuild the groups
    groups = []
    j, l = K, best_l
    while l > 0:
        i = cut[l][j]
        groups.insert(0, values[i:j])
        j, l = i, l - 1
    mapping = {}
    for lvl, g in enumerate(groups, 1):
        for v in g: mapping[v] = lvl
    return mapping, groups, dp[best_l][K], len(pairs)

if __name__ == '__main__':
    items = load(sys.argv[1])
    clamp = {v: max(1, min(10, v)) for v in set(it[1] for it in items)}
    pairs = bad_pairs(items)
    wrong_clamp = sum(1 for za, zb, _, _, w in pairs if clamp[za] == clamp[zb])
    same_clamp = sum(1 for za, zb, _, _, w in pairs if clamp[za] == clamp[zb] and w > 1)
    mapping, groups, wrong, total = best_mapping(items)
    print('overlapping pairs that need z to be drawn right:', total)
    left = [(za, zb, a, b, w) for za, zb, a, b, w in pairs if mapping[za] == mapping[zb]]
    print('drawn wrong with 2016 clamping (1..10):', wrong_clamp, '(inside one panel: %d)' % same_clamp)
    print('drawn wrong with the best squeeze      :', len(left), '(inside one panel: %d)' % sum(1 for x in left if x[4] > 1))
    for lvl, g in enumerate(groups, 1):
        print('  level %2d <- %s' % (lvl, g))
    for za, zb, a, b, w in [x for x in left if x[4] > 1][:15]:
        print('   still wrong: %s (z%d) over %s (z%d)' % (a.replace('StarterGui.gui.', ''), za, b.replace('StarterGui.gui.', ''), zb))


def per_panel(items, levels=10):
    """one squeeze per panel (StarterGui.gui.<panel>); returns {panel: mapping}"""
    panels = {}
    for it in items:
        key = '.'.join(it[6].split('.')[:3])
        panels.setdefault(key, []).append(it)
    maps = {}
    for key, its in panels.items():
        m, groups, wrong, total = best_mapping(its, levels)
        maps[key] = m
    return maps


def evaluate(items, level_of):
    pairs = bad_pairs(items)
    wrong_same = wrong_cross = 0
    # also pairs where tree order agrees but levels now disagree the other way
    for a, b in itertools.combinations(items, 2):
        if a[4] <= 0 or a[5] <= 0 or b[4] <= 0 or b[5] <= 0: continue
        if not (a[2] < b[2] + b[4] and b[2] < a[2] + a[4] and a[3] < b[3] + b[5] and b[3] < a[3] + a[5]): continue
        modern_a_over = (a[1], a[0]) > (b[1], b[0])
        la, lb = level_of(a), level_of(b)
        old_a_over = (la, a[0]) > (lb, b[0])
        if modern_a_over != old_a_over:
            if a[6].split('.')[:3] == b[6].split('.')[:3]: wrong_same += 1
            else: wrong_cross += 1
    return wrong_same, wrong_cross
