# Fixes Zombie Defense 3 for 2016 Roblox engines (guns, shops, gamepass checks).
#   python3 patch.py <original.rbxl> <fixed.rbxl>
import sys, os, re
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'casino', 'tools'))
from rbxlw import Editable

SRC = os.path.join(HERE, '..', 'src')
E = Editable(open(sys.argv[1], 'rb').read())
LOG = []
paths = {}
for r in E.loc:
    paths.setdefault(E.path(r), []).append(r)

def find(path):
    refs = paths.get(path, [])
    assert len(refs) == 1, (path, len(refs))
    return refs[0]

def src(r): return E.get_string(r, 'Source').decode('utf8', 'replace')
def setsrc(r, s): E.set_string(r, 'Source', s.encode('utf8'))
def disable(r): E.set_prop(r, 'Disabled', b'\x01')

PASS_HELPER = ('local __passCache = {}; local function __ownsPass(userId, id) local key = tostring(userId) .. ":" .. tostring(id); '
               'if __passCache[key] == nil then local ok, r = (ypcall or pcall)(function() return game:GetService("MarketplaceService"):UserOwnsGamePassAsync(userId, id) end); '
               '__passCache[key] = ok and r or false end; return __passCache[key] end; ')

# ------------------------------------------------------------------ 1. every script
counts = {'signals': 0, 'sound': 0, 'pass': 0}
for r in list(E.loc):
    if E.classof(r) not in ('Script', 'LocalScript', 'ModuleScript'):
        continue
    s = src(r)
    new = s
    # :Connect / :Wait / :Disconnect (capital letters) don't exist on 2016 engines; lowercase works everywhere
    new = re.sub(r':Connect\(', ':connect(', new)
    new = re.sub(r':Disconnect\(', ':disconnect(', new)
    new = re.sub(r':Wait\(\)', ':wait()', new)
    if new != s: counts['signals'] += 1
    # Sound.Playing came in June 2016; IsPlaying works on every engine (guns crashed when firing)
    n2 = re.sub(r'(FireSound)\.Playing\b', r'\1.IsPlaying', new)
    if n2 != new: counts['sound'] += 1
    new = n2
    # UserOwnsGamePassAsync is from 2018: protected and remembered (zombie mode called it every frame)
    if 'UserOwnsGamePassAsync' in new:
        new = re.sub(r'[A-Za-z_][\w.]*\s*:\s*UserOwnsGamePassAsync\(', '__ownsPass(', new)
        new = PASS_HELPER + new
        counts['pass'] += 1
    if new != s:
        setsrc(r, new)
LOG.append('scripts: capital Connect/Wait fixed in %(signals)d, gun sound check fixed in %(sound)d, gamepass checks protected in %(pass)d' % counts)

# ------------------------------------------------------------------ 2. players who joined before the script ran get TEAM too
cs = find('Workspace.CharacterSpawn')
s = src(cs)
old = 'game.Players.PlayerAdded:connect(function(Player)'
assert s.count(old) == 1
s = s.replace(old, 'local function __setup(Player)', 1)
s = s.rstrip()
assert s.endswith('end)')
s = s[:-len('end)')] + '''end
game.Players.PlayerAdded:connect(__setup)
-- [fix] players already in the game (and characters that already spawned) get set up too
for _, Player in pairs(game.Players:GetPlayers()) do
	__setup(Player)
	if Player.Character and not Player.Character:FindFirstChild("TEAM") then
		local TEAM = Instance.new("BrickColorValue", Player.Character)
		TEAM.Value = BrickColor.new("Bright red")
		TEAM.Name = "TEAM"
	end
end
'''
setsrc(cs, s)
LOG.append('CharacterSpawn: also sets up players who were already in the game')

# ------------------------------------------------------------------ 3. shops: buttons on the client, buying on the server
tmpl_local = find('StarterGui.AutoShop')
tmpl_script = find('ServerScriptService.ShopGuiGiver')
tmpl_remote = next(r for r in E.loc if E.classof(r) == 'RemoteEvent' and E.parent.get(r) == find('ReplicatedStorage'))
rs = find('ReplicatedStorage')
E.add_instance(tmpl_remote, rs, 'ShopBuy')
srv = E.add_instance(tmpl_script, find('ServerScriptService'), 'ShopBuyServer')
setsrc(srv, open(os.path.join(SRC, 'ShopBuyServer.server.lua')).read())
for shop in ('Automatic weapon shop', 'Semi Automatic and Melee weapon shop', 'Unique weapon shop', 'Weapon skin shop'):
    base = 'Workspace.Map.%s.Head.Dialog.ShopGui' % shop
    gui = find(base)
    for old in ('.TextLabel.BuyScript', '.TextLabel.TooltipScript', '.TextLabel.TextButton.Script'):
        disable(find(base + old))
    cl = E.add_instance(tmpl_local, gui, 'ShopClient')
    E.set_prop(cl, 'Disabled', b'\x00')
    setsrc(cl, open(os.path.join(SRC, 'ShopClient.client.lua')).read())
LOG.append('shops: 4 shop windows now buy through ShopBuy (works with FilteringEnabled on or off)')

# ------------------------------------------------------------------ 4. on-screen error box
rep = E.add_instance(tmpl_local, find('ReplicatedFirst'), 'errorReport')
E.set_prop(rep, 'Disabled', b'\x00')
setsrc(rep, open(os.path.join(SRC, 'errorReport.client.lua')).read())
E.add_instance(tmpl_remote, rs, 'errorReport')
rel = E.add_instance(tmpl_script, find('ServerScriptService'), 'errorRelay')
setsrc(rel, open(os.path.join(SRC, 'errorRelay.server.lua')).read())
LOG.append('added the on-screen error box')

data = E.save()
open(sys.argv[2], 'wb').write(data)
for l in LOG: print(l)
print('wrote', sys.argv[2], len(data), 'bytes')
