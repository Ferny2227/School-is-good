# 2016 engines only have ZIndex 1..10 (anything higher is cut to 10), which made shadows cover their
# buttons and menus show through popups. This picks a level 1..10 for every (panel, ZIndex) so that
# overlapping GUI objects are drawn in the same order as on new engines.
import struct, itertools, collections

W, H = 1366, 732
BASE = {'topbar', 'textBoxes', 'play', 'towers'}                       # always on screen
FLOATING = {'alert', 'notify', 'prompt', 'selecter', 'requestGui', 'perkView', 'cash', 'gamepasses'}  # on top of anything

def f32(b):
    z = int.from_bytes(b, 'big'); z = (z >> 1) | ((z & 1) << 31); return struct.unpack('>f', struct.pack('>I', z))[0]
def i32(b):
    z = int.from_bytes(b, 'big'); return (z >> 1) ^ -(z & 1)

GUI = ('Frame', 'TextLabel', 'TextButton', 'TextBox', 'ImageLabel', 'ImageButton', 'ScrollingFrame', 'ViewportFrame')


def panel_order(E, gui_root):
    """top-level panels sorted so the tree order matches how new engines stack them:
    by the panel's highest ZIndex, floating popups last"""
    kids = [r for r in E.prnt_order if E.parent.get(r) == gui_root]
    sub = collections.defaultdict(list)
    for r in E.prnt_order: sub[E.parent.get(r)].append(r)
    def maxz(r):
        best = -10**9
        st = [r]
        while st:
            x = st.pop()
            pr = E.prop(x, 'ZIndex') if E.classof(x) in GUI else None
            if pr: best = max(best, i32(pr[1]))
            st.extend(sub[x])
        return best
    return sorted(kids, key=lambda r: (E.name(r) in FLOATING, maxz(r)))


def collect(E, gui_root, extra_panels=(), reorder=False):
    """[(dfs, z, x, y, w, h, panel, ref)] for every GUI object under gui_root (positions from the file)"""
    kids = collections.defaultdict(list)
    for r in E.prnt_order: kids[E.parent.get(r)].append(r)
    if reorder:
        kids[gui_root] = panel_order(E, gui_root)
    items = []
    def rect(r, parent_rect):
        px, py, pw, ph = parent_rect
        _, s = E.prop(r, 'Size'); _, p = E.prop(r, 'Position')
        w, h = f32(s[0]) * pw + i32(s[2]), f32(s[1]) * ph + i32(s[3])
        x, y = px + f32(p[0]) * pw + i32(p[2]), py + f32(p[1]) * ph + i32(p[3])
        ap = E.prop(r, 'AnchorPoint')
        if ap: x, y = x - f32(ap[1][0]) * w, y - f32(ap[1][1]) * h
        return x, y, w, h
    def draws(r):
        """does this object put any pixels on screen?"""
        bgt = E.prop(r, 'BackgroundTransparency')
        if bgt and f32(bgt[1]) < 0.99: return True
        if E.prop(r, 'Text'):
            t = E.get_string(r, 'Text')
            tt = E.prop(r, 'TextTransparency')
            if t.strip() and (not tt or f32(tt[1]) < 0.99): return True
        if E.prop(r, 'Image'):
            im = E.get_string(r, 'Image')
            it = E.prop(r, 'ImageTransparency')
            if im and (not it or f32(it[1]) < 0.99): return True
        return False
    def visit(r, prect, panel, zextra):
        for c in kids[r]:
            if E.classof(c) not in GUI: continue
            rc = rect(c, prect)
            pn = panel or E.name(c)
            _, zb = E.prop(c, 'ZIndex')
            items.append([len(items), i32(zb) + zextra, rc[0], rc[1], rc[2], rc[3], pn, c, draws(c)])
            visit(c, rc, pn, zextra)
    visit(gui_root, (0, 0, W, H), None, 0)
    for panel_ref, zextra, key in extra_panels:   # e.g. prompt copies drawn last with +250
        _, zb = E.prop(panel_ref, 'ZIndex')
        rc = rect(panel_ref, (0, 0, W, H))
        items.append([len(items), i32(zb) + zextra, rc[0], rc[1], rc[2], rc[3], key, panel_ref, draws(panel_ref)])
        visit(panel_ref, rc, key, zextra)
    return items


def weight(pa, pb):
    if pa == pb: return 1000
    if pa in BASE or pb in BASE or pa in FLOATING or pb in FLOATING: return 5
    return 1   # two big menus: usually not open together


def solve(items, levels=10, sweeps=25):
    def overlap(a, b):
        return a[4] > 0 and a[5] > 0 and b[4] > 0 and b[5] > 0 and a[2] < b[2] + b[4] and b[2] < a[2] + a[4] and a[3] < b[3] + b[5] and b[3] < a[3] + a[5]
    keys = sorted(set((it[6], it[1]) for it in items))
    kid = {k: i for i, k in enumerate(keys)}
    pairs = []  # (ka, kb, a_after_b_in_tree, modern_a_over_b, weight)
    by_key = collections.defaultdict(list)
    for a, b in itertools.combinations(items, 2):
        if not (a[8] and b[8]) or not overlap(a, b): continue
        ka, kb = kid[(a[6], a[1])], kid[(b[6], b[1])]
        if ka == kb: continue  # same level whatever we pick -> tree order, same as new engines
        modern = (a[1], a[0]) > (b[1], b[0])
        pairs.append((ka, kb, a[0] > b[0], modern, weight(a[6], b[6])))
        by_key[ka].append(len(pairs) - 1)
        by_key[kb].append(len(pairs) - 1)

    def wrong(pi, L):
        ka, kb, after, modern, w = pairs[pi]
        la, lb = L[ka], L[kb]
        old = la > lb or (la == lb and after)
        return w if old != modern else 0

    import random
    rng = random.Random(1)
    clampL = [max(1, min(levels, k[1])) for k in keys]
    clamp_total = sum(wrong(i, clampL) for i in range(len(pairs)))

    def descend(L):
        for _ in range(sweeps):
            improved = False
            order = list(range(len(keys)))
            rng.shuffle(order)
            for k in order:
                cur = L[k]
                base = sum(wrong(i, L) for i in by_key[k])
                best, best_cost = cur, base
                for lv in range(1, levels + 1):
                    if lv == cur: continue
                    L[k] = lv
                    c = sum(wrong(i, L) for i in by_key[k])
                    if c < best_cost: best, best_cost = lv, c
                L[k] = best
                if best != cur: improved = True
            if not improved: break
        return sum(wrong(i, L) for i in range(len(pairs)))

    starts = []
    zs = sorted(set(k[1] for k in keys))
    starts.append([1 + (zs.index(k[1]) * levels) // len(zs) for k in keys])        # one shared squeeze
    per = collections.defaultdict(list)
    for k in keys: per[k[0]].append(k[1])
    starts.append([1 + (sorted(per[k[0]]).index(k[1]) * levels) // max(1, len(per[k[0]])) for k in keys])  # each panel spread out
    starts.append([levels - len(per[k[0]]) + 1 + sorted(per[k[0]]).index(k[1]) for k in keys])  # each panel packed at the top
    best_L, total = None, None
    for s0 in starts:
        L = list(s0)
        c = descend(L)
        if total is None or c < total: best_L, total = list(L), c
    # shake the best a few times
    for _ in range(12):
        L = list(best_L)
        for k in rng.sample(range(len(keys)), max(1, len(keys) // 8)):
            L[k] = rng.randint(1, levels)
        c = descend(L)
        if c < total: best_L, total = list(L), c
    L = best_L
    left = collections.Counter()
    for i, p in enumerate(pairs):
        if wrong(i, L): left["same panel" if p[4] == 1000 else 'with base/popup' if p[4] == 5 else 'menu vs menu'] += 1
    stats = {'pairs': len(pairs), 'weighted_clamp': clamp_total, 'weighted_after': total, 'still_wrong': dict(left)}
    return {keys[i]: L[i] for i in range(len(keys))}, stats
