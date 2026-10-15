# Makes MechaCubes run on 2016 Roblox engines. Called from patch.py.
import os, re, struct, collections

SRC = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'src')

def f32(b):
    z = int.from_bytes(b, 'big'); z = (z >> 1) | ((z & 1) << 31); return struct.unpack('>f', struct.pack('>I', z))[0]
def enc_f32(x):
    z = struct.unpack('>I', struct.pack('>f', x))[0]; z = ((z << 1) | (z >> 31)) & 0xffffffff; return z.to_bytes(4, 'big')
def i32(b):
    z = int.from_bytes(b, 'big'); return (z >> 1) ^ -(z & 1)
def enc_i32(v):
    z = ((v << 1) ^ (v >> 31)) & 0xffffffff; return z.to_bytes(4, 'big')
def u32(b): return int.from_bytes(b, 'big')

GUI_CLASSES = ('Frame', 'TextLabel', 'TextButton', 'TextBox', 'ImageLabel', 'ImageButton', 'ScrollingFrame', 'ViewportFrame', 'VideoFrame')
PRELUDE = ('local pcall = ypcall or pcall; local __compat = require(game:GetService("ReplicatedStorage"):WaitForChild("compat2016")); '
           'local Color3, typeof, math = __compat.Color3, __compat.typeof, __compat.math; ')
EXPR = r'[A-Za-z_]\w*(?:\.[A-Za-z_]\w*|\[[^\]\n]+\]|:[A-Za-z_]\w*\(\))*'


def lua_string(s):
    return '"' + s.replace('\\', '\\\\').replace('"', '\\"') + '"'


def split_comment(rest):
    """value -- comment  ->  (value, ' -- comment')  (ignores -- inside strings)"""
    q = None
    i = 0
    while i < len(rest):
        ch = rest[i]
        if q:
            if ch == '\\': i += 1
            elif ch == q: q = None
        elif ch in '"\'':
            q = ch
        elif rest.startswith('--', i):
            return rest[:i].rstrip(), ' ' + rest[i:]
        i += 1
    return rest.rstrip(), ''


def rewrite_gui_moves(src):
    """GUI moves/resizes go through __compat so the old AnchorPoints keep working."""
    out = []
    for line in src.split('\n'):
        if line.lstrip().startswith('--'):
            out.append(line)
            continue
        m = re.match(r'^(\s*)(' + EXPR + r')\.(Position|Size)\s*=(?!=)\s*(.*)$', line)
        if m and not m.group(2).startswith('local'):
            ind, obj, prop, rest = m.groups()
            val, comment = split_comment(rest)
            val = rewrite_reads(val)
            fn = 'setPos' if prop == 'Position' else 'setSize'
            out.append('%s__compat.%s(%s, %s)%s' % (ind, fn, obj, val, comment))
            continue
        line = re.sub(r'(' + EXPR + r'):TweenPosition\(', r'__compat.tweenPos(\1, ', line)
        line = re.sub(r'(' + EXPR + r'):TweenSize\(', r'__compat.tweenSize(\1, ', line)
        line = rewrite_reads(line)
        out.append(line)
    return '\n'.join(out)


def rewrite_reads(text):
    # obj.Position (reading it) -> __compat.getPos(obj); skip "x.Position =" assignments
    return re.sub(r'(' + EXPR + r')\.Position\b(?!\s*=[^=])', lambda m: '__compat.getPos(%s)' % m.group(1), text)


def apply(E, find, edit, LOG, paths):
    # ------------------------------------------------------------------ 1. the compat module
    tmpl_module = find('ReplicatedStorage.utilities')
    rs = find('ReplicatedStorage')
    compat = E.add_instance(tmpl_module, rs, 'compat2016')
    E.set_string(compat, 'Source', open(os.path.join(SRC, 'compat2016.lua'), 'rb').read())
    tmpl_folder = next(r for r in E.loc if E.classof(r) == 'Folder')
    anchors = E.add_instance(tmpl_folder, compat, 'anchors')
    tmpl_image = next(r for r in E.loc if E.classof(r) == 'ImageLabel')
    markers = {}


    # ------------------------------------------------------------------ 2. layouts (UIListLayout / UIGridLayout, 2017)
    kids = collections.defaultdict(list)
    for r in E.prnt_order:
        kids[E.parent.get(r)].append(r)
    gui_root = find('StarterGui.gui')
    layout_containers = set()
    defs = []
    enum_names = {
        'FillDirection': {0: 'Horizontal', 1: 'Vertical'},
        'HorizontalAlignment': {0: 'Center', 1: 'Left', 2: 'Right'},
        'VerticalAlignment': {0: 'Center', 1: 'Top', 2: 'Bottom'},
        'SortOrder': {0: 'Name', 1: 'Custom', 2: 'LayoutOrder'},
        'StartCorner': {0: 'TopLeft', 1: 'TopRight', 2: 'BottomLeft', 3: 'BottomRight'},
    }
    for r in list(E.loc):
        cls = E.classof(r)
        if cls not in ('UIListLayout', 'UIGridLayout'):
            continue
        container = E.parent[r]
        layout_containers.add(container)
        segs = []
        x = container
        while x != gui_root and x in E.loc:
            segs.insert(0, E.name(x))
            x = E.parent.get(x)
        if x != gui_root:
            continue
        props = {}
        for name in ('FillDirection', 'HorizontalAlignment', 'VerticalAlignment', 'SortOrder', 'StartCorner'):
            pr = E.prop(r, name)
            if pr: props[name] = lua_string(enum_names[name].get(u32(pr[1]), 'Name'))
        pr = E.prop(r, 'Padding')
        if pr: props['Padding'] = 'UDim.new(%r, %d)' % (round(f32(pr[1][0]), 6), i32(pr[1][1]))
        for name in ('CellSize', 'CellPadding'):
            pr = E.prop(r, name)
            if pr:
                v = pr[1]
                props[name] = 'UDim2.new(%r, %d, %r, %d)' % (round(f32(v[0]), 6), i32(v[2]), round(f32(v[1]), 6), i32(v[3]))
        pr = E.prop(r, 'FillDirectionMaxCells')
        if pr: props['FillDirectionMaxCells'] = str(i32(pr[1]))
        defs.append('\t{class = %s, name = %s, path = {%s}, props = {%s}},' % (
            lua_string(cls), lua_string(E.name(r)), ', '.join(lua_string(s) for s in segs),
            ', '.join('%s = %s' % (k, v) for k, v in props.items())))
    layouts = E.add_instance(tmpl_module, compat, 'layouts')
    E.set_string(layouts, 'Source', '-- made by tools/compat_patch.py from the UIListLayouts / UIGridLayouts in the place\nreturn {\n%s\n}\n' % '\n'.join(defs))
    LOG.append('compat: %d layouts recorded for old engines' % len(defs))

    # ------------------------------------------------------------------ 3. ZIndex 1..10 + AnchorPoint -> plain positions
    # 2016 engines cut ZIndex to 1..10 and have no AnchorPoint. Every GUI object gets a level that keeps
    # overlapping things in the right order (zlevels.py) and a plain position; its original AnchorPoint
    # and ZIndex are remembered in a marker (SelectionImageObject) for scripts that move things.
    import zlevels
    prompt_tpl = find('StarterGui.gui.prompt')
    zitems = zlevels.collect(E, gui_root, [(prompt_tpl, 250, 'prompt+250')], reorder=True)
    zmap, zstats = zlevels.solve(zitems)
    LOG.append('compat: ZIndex squeezed into 1..10, overlaps drawn wrong %s -> %s (weighted), left: %s' % (
        zstats['weighted_clamp'], zstats['weighted_after'], zstats['still_wrong']))
    level_of = {}
    for it in zitems:
        if it[6] != 'prompt+250': level_of[it[7]] = (it[6], it[1], zmap[(it[6], it[1])])
    # top-level panels in stacking order (old engines break ZIndex ties by tree order)
    new_order = zlevels.panel_order(E, gui_root)
    first = min(E.prnt_order.index(r) for r in new_order)
    rest = [r for r in E.prnt_order if r not in set(new_order)]
    E.prnt_order = rest[:first] + new_order + rest[first:]
    # per-panel tables for scripts that change ZIndex while playing
    tables = collections.defaultdict(dict)
    for (panel, z), lv in zmap.items():
        tables['prompt' if panel == 'prompt+250' else panel][z] = lv
    zsrc = ['-- made by tools/compat_patch.py: ZIndex -> level 1..10 for each top-level panel of the gui', 'return {']
    for panel in sorted(tables):
        zsrc.append('\t[%s] = {%s},' % (lua_string(panel), ', '.join('{%d, %d}' % (z, lv) for z, lv in sorted(tables[panel].items()))))
    zsrc.append('}')
    zmod = E.add_instance(tmpl_module, compat, 'zlevels')
    E.set_string(zmod, 'Source', '\n'.join(zsrc) + '\n')

    def marker(ax, ay, z):
        key = (round(ax, 4), round(ay, 4), z)
        if key not in markers:
            mk = E.add_instance(tmpl_image, anchors, 'anchor %g %g z%d' % key)
            E.set_prop(mk, 'Position', (enc_f32(ax), enc_f32(ay), enc_i32(0), enc_i32(0)))
            E.set_prop(mk, 'Size', (enc_f32(0), enc_f32(0), enc_i32(z), enc_i32(0)))
            E.set_prop(mk, 'Visible', b'\x00')
            E.set_prop(mk, 'BackgroundTransparency', enc_f32(1))
            E.set_prop(mk, 'ImageTransparency', enc_f32(1))
            E.set_string(mk, 'Image', b'')
            E.set_prop(mk, 'AnchorPoint', (enc_f32(0), enc_f32(0)))
            markers[key] = mk
        return markers[key]

    n = 0
    for r in list(E.loc):
        if E.classof(r) not in GUI_CLASSES:
            continue
        ap = E.prop(r, 'AnchorPoint')
        if not ap:
            continue
        ax, ay = f32(ap[1][0]), f32(ap[1][1])
        in_layout = E.parent.get(r) in layout_containers
        if in_layout:
            ax = ay = 0.0  # positioned by the layout, not by Position
        if (abs(ax) > 1e-9 or abs(ay) > 1e-9):
            _, s = E.prop(r, 'Size')
            _, p = E.prop(r, 'Position')
            sx, sy, sox, soy = f32(s[0]), f32(s[1]), i32(s[2]), i32(s[3])
            px, py, pox, poy = f32(p[0]), f32(p[1]), i32(p[2]), i32(p[3])
            E.set_prop(r, 'Position', (enc_f32(px - ax * sx), enc_f32(py - ay * sy),
                                       enc_i32(int(round(pox - ax * sox))), enc_i32(int(round(poy - ay * soy)))))
            E.set_prop(r, 'AnchorPoint', (enc_f32(0), enc_f32(0)))
            n += 1
        if r in level_of:
            panel, z, lv = level_of[r]
            E.set_prop(r, 'ZIndex', enc_i32(lv))
            E.set_prop(r, 'SelectionImageObject', marker(ax, ay, z))
        elif abs(ax) > 1e-9 or abs(ay) > 1e-9:
            _, zb = E.prop(r, 'ZIndex')
            E.set_prop(r, 'SelectionImageObject', marker(ax, ay, i32(zb)))
    LOG.append('compat: %d AnchorPoints turned into plain positions, %d markers' % (n, len(markers)))

    # ------------------------------------------------------------------ 4. Font / FontSize for engines without FontFace / TextSize
    font_items = {'SourceSans': 4, 'SourceSansBold': 5, 'SourceSansLight': 9, 'SourceSansItalic': 8, 'Arial': 1, 'ArialBold': 2,
                  'Legacy': 0, 'Bodoni': 6, 'Garamond': 7, 'Cartoon': 10, 'Code': 11, 'Highway': 12, 'SciFi': 13, 'Arcade': 14, 'Fantasy': 15, 'Antique': 16}
    size_items = [(8, 0), (9, 1), (10, 2), (11, 3), (12, 4), (14, 5), (18, 6), (24, 7), (28, 10), (32, 11), (36, 8), (42, 12), (48, 9), (60, 13), (96, 14)]
    family_map = {'SourceSansPro': 'SourceSans', 'Balthazar': 'Garamond', 'Guru': 'Cartoon', 'Arial': 'Arial', 'GothamSSm': 'SourceSans',
                  'Gotham': 'SourceSans', 'Roboto': 'SourceSans', 'Merriweather': 'Bodoni', 'Highway': 'Highway', 'Ubuntu': 'SourceSans'}
    added = 0
    for c in E.cls:
        if c['name'] not in ('TextLabel', 'TextButton', 'TextBox'):
            continue
        names = [p[0] for p in c['props']]
        if 'Font' in names or 'FontFace' not in names:
            continue
        ff = next(p for p in c['props'] if p[0] == 'FontFace')
        fonts = []
        for v in ff[2]:
            l = int.from_bytes(v[:4], 'little')
            fam = v[4:4 + l].decode('utf8', 'replace').split('/')[-1].replace('.json', '')
            weight = int.from_bytes(v[4 + l:6 + l], 'little')
            style = v[6 + l]
            base = family_map.get(fam, 'SourceSans')
            name = base
            if base == 'SourceSans':
                name = 'SourceSansBold' if weight >= 600 else 'SourceSansLight' if weight <= 300 else 'SourceSansItalic' if style == 1 else 'SourceSans'
            fonts.append(font_items[name].to_bytes(4, 'big'))
        c['props'].insert(names.index('FontFace'), ['Font', 18, fonts])
        ts = next(p for p in c['props'] if p[0] == 'TextSize')
        sizes = []
        for v in ts[2]:
            want = f32(v)
            best = min(size_items, key=lambda it: abs(it[0] - want))
            sizes.append(best[1].to_bytes(4, 'big'))
        names = [p[0] for p in c['props']]
        c['props'].insert(names.index('TextSize'), ['FontSize', 18, sizes])
        added += len(fonts)
    LOG.append('compat: Font + FontSize added to %d text objects (2016 engines read these)' % added)

    # ------------------------------------------------------------------ 5. scripts
    whole = {
        'ReplicatedStorage.modules.tween': 'tween.lua',
        'ReplicatedFirst.load': 'load.client.lua',
    }
    for path, fn in whole.items():
        E.set_string(find(path), 'Source', open(os.path.join(SRC, fn), 'rb').read())
        LOG.append('compat: replaced ' + path)

    # BlurEffect (May 2016): menus still work without the background blur
    F = 'StarterGui.root.client.interface.focus'
    edit(F, 'local blur = Instance.new("BlurEffect", game:GetService("Lighting"))',
         'local blurOk, blur = pcall(function() return Instance.new("BlurEffect", game:GetService("Lighting")) end)\n'
         'if not blurOk then blur = {Size = 0, Enabled = false} end -- [fix] no BlurEffect before May 2016')
    edit(F, '	tween(blur, blurSize, "Size", tweenTime, Enum.EasingStyle.Linear)',
         '	if blurOk then tween(blur, blurSize, "Size", tweenTime, Enum.EasingStyle.Linear) end')
    edit(F, '''	tween(blur, 0, "Size", tweenTime, Enum.EasingStyle.Linear, Enum.EasingDirection.In, function()
		blur.Enabled = false
	end)''', '''	if not blurOk then blur.Enabled = false return end
	tween(blur, 0, "Size", tweenTime, Enum.EasingStyle.Linear, Enum.EasingDirection.In, function()
		blur.Enabled = false
	end)''')

    # on-screen error box (client + server errors) so problems on the revival can be screenshotted
    rep = E.add_instance(find('ReplicatedFirst.load'), find('ReplicatedFirst'), 'errorReport')
    E.set_string(rep, 'Source', open(os.path.join(SRC, 'errorReport.client.lua'), 'rb').read())
    tmpl_remote = next(r for r in E.loc if E.classof(r) == 'RemoteEvent')
    E.add_instance(tmpl_remote, rs, 'errorReport')
    relay = E.add_instance(find('ServerScriptService.server'), find('ServerScriptService'), 'errorRelay')
    E.set_string(relay, 'Source', open(os.path.join(SRC, 'errorRelay.server.lua'), 'rb').read())
    LOG.append('compat: added on-screen error report')

    skip = {compat, layouts, rep, relay}
    changed = 0
    for r in list(E.loc):
        if E.classof(r) not in ('Script', 'LocalScript', 'ModuleScript') or r in skip:
            continue
        path = E.path(r)
        if path in whole:
            continue
        src = E.get_string(r, 'Source').decode('utf8')
        new = src
        # RBXScriptSignal methods: lowercase works on every engine (Connect/Wait/Disconnect came later)
        new = re.sub(r':Connect\(', ':connect(', new)
        new = re.sub(r':Disconnect\(', ':disconnect(', new)
        new = re.sub(r':Wait\(\)', ':wait()', new)
        # the game's own event classes: give them the lowercase names too
        new = re.sub(r'function (\w+):Connect\(', r'function \1:connect(', new)
        new = re.sub(r'function (\w+):Disconnect\(', r'function \1:disconnect(', new)
        if path == 'ReplicatedStorage.shared.event':
            new = new.replace('\nreturn syncEvent', '\nsyncEvent.Connect = syncEvent.connect\nsyncEvent.Disconnect = syncEvent.disconnect\nsignal.Disconnect = signal.disconnect\n\nreturn syncEvent')
        if path == 'ReplicatedStorage.shared.interval':
            new = new.replace('\nreturn interval', '\ninterval.Connect = interval.connect\n\nreturn interval')
        # 2017 functions
        new = re.sub(r'(' + EXPR + r'):GetPropertyChangedSignal\(', r'__compat.changed(\1, ', new)
        new = re.sub(r'(' + EXPR + r'):FindFirstChildOfClass\(', r'__compat.findClass(\1, ', new)
        new = new.replace('workspace:FindPartOnRayWithWhitelist(', '__compat.rayWhitelist(')
        new = new.replace('game:BindToClose(', '__compat.bindToClose(')
        new = re.sub(r'(\w+)\.gridLayout\.', r'__compat.layoutChild(\1, "gridLayout").', new)
        # UITextSizeConstraint (Oct 2016): only a limit on text size, safe to skip on older engines
        new = re.sub(r'^(\s*)([^\n]*\.(?:UITextSizeConstraint|textSizeConstraint)\.MaxTextSize = [^\n]+)$', r'\1pcall(function() \2 end)', new, flags=re.M)
        # ZIndex (1..10 on 2016 engines): scripts work with the original numbers through __compat
        new = re.sub(r'^(\s*)(' + EXPR + r')\.ZIndex\s*=(?!=)\s*([^\n]+)$', lambda m: '%s__compat.setZ(%s, %s)' % (m.group(1), m.group(2), re.sub(r'(' + EXPR + r')\.ZIndex\b', r'__compat.getZ(\1)', m.group(3))), new, flags=re.M)
        new = re.sub(r'(' + EXPR + r')\.ZIndex\b(?!\s*=[^=])', r'__compat.getZ(\1)', new)
        # TextSize (Oct 2016)
        new = re.sub(r'^(\s*)(' + EXPR + r')\.TextSize\s*=(?!=)\s*([^\n]+)$', r'\1__compat.setTextSize(\2, \3)', new, flags=re.M)
        # LayoutOrder (2017)
        new = re.sub(r'^(\s*)(' + EXPR + r')\.LayoutOrder\s*=(?!=)\s*([^\n]+)$', r'\1__compat.setLayoutOrder(\2, \3)', new, flags=re.M)
        new = re.sub(r'(' + EXPR + r')\.LayoutOrder\b(?!\s*=[^=])', r'__compat.getLayoutOrder(\1)', new)
        # GUI moves (client side only)
        client_side = path.startswith('StarterGui.') or path.startswith('ReplicatedStorage.modules.') or path.startswith('StarterPlayer.')
        if client_side:
            new = rewrite_gui_moves(new)
        if path == 'StarterGui.root.client.interface':
            # one broken menu must not stop the others (Towers, Play, Shop...) from working
            new = new.replace("""	for _, sector in pairs(script:GetChildren()) do
		module[sector.Name] = require(sector)
	end""", """	for _, sector in pairs(script:GetChildren()) do
		local ok, result = pcall(require, sector)
		if ok then
			module[sector.Name] = result
		else
			warn("interface." .. sector.Name .. " failed to load: " .. tostring(result))
		end
	end""")
            assert 'failed to load' in new
        if path == 'StarterGui.root.client':
            new = new.replace('\ninterface.initialize()', '\n__compat.watchLayouts(script.Parent.Parent:WaitForChild("gui"))\ninterface.initialize()')
            assert '__compat.watchLayouts' in new
        needs = ('__compat' in new or re.search(r'Color3\.from(RGB|HSV)|typeof\(|math\.clamp|pcall\(', new))
        if needs and not new.startswith(PRELUDE):
            new = PRELUDE + new
        if new != src:
            E.set_string(r, 'Source', new)
            changed += 1
    LOG.append('compat: %d scripts updated for 2016 engines' % changed)
