# Applies the loading / lag / bug fixes to the casino place file.
#   python3 patch.py <original.rbxl> <fixed.rbxl>
import sys, os, struct, collections
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rbxlw import Editable
from attrs import parse_attrs, write_attrs

src_path, out_path = sys.argv[1], sys.argv[2]
E = Editable(open(src_path, 'rb').read())
LOG = []

paths = collections.defaultdict(list)
for r in E.loc:
    paths[E.path(r)].append(r)

def find(path):
    refs = paths.get(path, [])
    assert len(refs) == 1, (path, len(refs))
    return refs[0]

def edit(path, old, new, count=1):
    r = find(path)
    src = E.get_string(r, 'Source').decode('utf8')
    n = src.count(old)
    assert n == count, (path, 'found', n, 'expected', count, old[:80])
    E.set_string(r, 'Source', src.replace(old, new))
    LOG.append('edited ' + path)

GM = 'ServerScriptService.Environment.GameManager'

# ---------------------------------------------------------------------------------------------
# 1. "loading..." forever: ProfileService only switched to its offline (mock) store inside Studio
#    and only for two exact error texts. Anywhere else (unpublished place, API access off, a test
#    server) LoadProfileAsync retried forever, so the Playtime attribute never arrived and the
#    disclaimer never showed PLAY. Now any failure / 10 s timeout uses the mock store.
def live_check(ind):
    body = '''-- [fix] The DataStore check now runs everywhere, not only in Studio. If the DataStore can't be
-- reached (unpublished place, Studio API access off, no internet, test servers) the offline store
-- is used, so players still load in (their data just isn't saved that session).
IsLiveCheckActive = true
task.spawn(function()
	local finished = false
	task.delay(10, function()
		if not finished then
			finished = true
			UseMockDataStore = true
			ProfileService._use_mock_data_store = true
			warn("[ProfileService]: DataStore check timed out - data will not be saved this session")
			IsLiveCheckActive = false
		end
	end)
	local status, message
	for attempt = 1, (IsStudio == true and 1 or 3) do
		status, message = pcall(function()
			DataStoreService:GetDataStore("____PS"):SetAsync("____PS", os.time())
		end)
		if status == true or finished == true then
			break
		end
		task.wait(1)
	end
	if finished == true then
		return
	end
	finished = true
	if status == false then
		UseMockDataStore = true
		ProfileService._use_mock_data_store = true
		warn("[ProfileService]: Roblox API services unavailable (" .. tostring(message) .. ") - data will not be saved")
	else
		print("[ProfileService]: Roblox API services available - data will be saved")
	end
	IsLiveCheckActive = false
end)'''
    return '\n'.join((ind + l) if l else l for l in body.split('\n'))

def fix_profile_service(path):
    r = find(path)
    src = E.get_string(r, 'Source').decode('utf8')
    for ind in ('\t', ''):
        head = ind + 'if IsStudio == true then\n' + ind + '\tIsLiveCheckActive = true\n'
        i = src.find(head)
        if i >= 0 and (i == 0 or src[i - 1] == '\n'):
            tail = ind + '\t\tIsLiveCheckActive = false\n' + ind + '\tend)\n' + ind + 'end'
            j = src.index(tail, i) + len(tail)
            assert src.count(head) == 1
            src = src[:i] + live_check(ind) + src[j:]
            E.set_string(r, 'Source', src)
            LOG.append('edited ' + path)
            return
    raise AssertionError('live check not found in ' + path)

fix_profile_service('ServerStorage.Modules.ProfileService')
fix_profile_service('ServerScriptService.BetterChat V3.Config.Loader.src.core.services.profile')

# ---------------------------------------------------------------------------------------------
# 2. PlayerManager
PM = 'ServerScriptService.Player.PlayerManager'
# group / chat-rank colour lookup errors used to abort playerAdded, so the playtime clocks and the
# leaderstats updates never started
edit(PM, '\tgivePlayerListColor(player);\n',
     '\tpcall(givePlayerListColor, player); -- [fix] a failed group-rank lookup must not stop loading\n')
# workspace.Suites doesn't exist in this place: the per-second loop crashed when suite time ran out
edit(PM, 'for each, suite in pairs(workspace.Suites:GetChildren()) do',
     'for each, suite in pairs(workspace:FindFirstChild("Suites") and workspace.Suites:GetChildren() or {}) do -- [fix] no Suites folder in this place')
# players already in the server were loaded one by one BEFORE PlayerAdded was connected, so anyone
# joining during that time was never loaded (stuck on "loading..." for good)
edit(PM, '''for _, player in ipairs(Players:GetPlayers()) do
	playerAdded(player);
end
Players.PlayerAdded:Connect(function(player)
	playerAdded(player);
end);''', '''Players.PlayerAdded:Connect(function(player)
	playerAdded(player);
end);
-- [fix] connect first, then load players who were already here (in parallel)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(playerAdded, player);
end''')

# 3. Permissions: GetRankInGroup can throw (HTTP error / offline) and killed the playtime loop
edit('ReplicatedStorage.Modules.Permissions', '''	if actualPlayer then
		return actualPlayer:GetRankInGroup(groupID);
	end''', '''	if actualPlayer then
		local ok, rank = pcall(actualPlayer.GetRankInGroup, actualPlayer, groupID); -- [fix] can error
		return ok and rank or 0;
	end''')

# 4. RankGun: decoded response.Body even when the request failed (crash), and the API key is empty
edit('ServerStorage.Modules.RankGun', '''local function URLGenerator(Endpoint, Method, Bot, Data)
	local result''', '''local function URLGenerator(Endpoint, Method, Bot, Data)
	if Bot.ApiKey == "" then -- [fix] no key set: don't send a request every minute for every player
		return {
			status_code = 401,
			detail = "RankGun API key not set",
		}
	end
	local result''')
edit('ServerStorage.Modules.RankGun', '''	local body = HttpService:JSONDecode(response.Body)
	if not success then''', '''	local body
	if success and type(response) == "table" then -- [fix] response is an error string when the request fails
		local ok, decoded = pcall(HttpService.JSONDecode, HttpService, response.Body)
		if ok then
			body = decoded
		else
			success = false
		end
	end
	if not success then''')

# ---------------------------------------------------------------------------------------------
# 5. GameManager
# DataStore / MessagingService calls errored in unpublished places / Studio and killed the script
# before any table game was switched on
edit(GM, 'local VersionStore = DataStoreService:GetDataStore("GameVersion");',
     'local VersionStore;\npcall(function() VersionStore = DataStoreService:GetDataStore("GameVersion"); end); -- [fix] errors when the place has no DataStore access')
edit(GM, 'MessagingService:SubscribeAsync("Shutdown", function(message)',
     'task.spawn(pcall, MessagingService.SubscribeAsync, MessagingService, "Shutdown", function(message) -- [fix] protected, doesn\'t block startup')
edit(GM, 'MessagingService:SubscribeAsync("Announcement", function(message)',
     'task.spawn(pcall, MessagingService.SubscribeAsync, MessagingService, "Announcement", function(message)')
# LAG: every game model got its own copy of its game script INSIDE Workspace. Everything under it
# (ModuleScripts, GUI templates, LocalScripts) was downloaded by every player on join, including a
# 1.7 MB poker lookup module per poker table (10 tables = 17 MB). The copies now run from
# ServerScriptService (never sent to players) and find their table through a "Target" value.
edit(GM, '''	for each, thing in pairs(Games:GetDescendants()) do
		if thing:IsA("Model") and script:FindFirstChild(thing.Name.."Core") then
			local source = script[thing.Name.."Core"]:Clone();
			source.Parent, source.Enabled = thing, true;
		end
	end''', '''	-- [fix] one shared poker hand evaluator for every poker table (was a 1.7 MB copy per table)
	local pokerEval = Instance.new("Folder");
	pokerEval.Name = "PokerEval";
	for _, moduleName in ipairs({"Card", "Prob", "Lookup", "Analysis", "Underscore", "Bitop"}) do
		local module = script.TexasHoldemCore:FindFirstChild(moduleName);
		if module then
			module.Parent = pokerEval;
		end
		local duplicate = script.TournamentHoldemCore:FindFirstChild(moduleName);
		if duplicate then
			duplicate:Destroy();
		end
	end
	pokerEval.Parent = ServerModules;

	-- [fix] the game scripts run from ServerScriptService (players never download them) and find
	-- their table through the "Target" value instead of script.Parent
	local runningCores = Instance.new("Folder");
	runningCores.Name = "RunningGameCores";
	runningCores.Parent = game:GetService("ServerScriptService");
	for each, thing in pairs(Games:GetDescendants()) do
		if thing:IsA("Model") and script:FindFirstChild(thing.Name.."Core") then
			local source = script[thing.Name.."Core"]:Clone();
			local target = Instance.new("ObjectValue");
			target.Name = "Target";
			target.Value = thing;
			target.Parent = source;
			source.Name = thing.Name.."Core"..each;
			source.Parent = runningCores;
			source.Enabled = true;
		end
	end''')

TARGET = ' = script:FindFirstChild("Target") and script.Target.Value or script.Parent; -- [fix] runs from ServerScriptService now'
cores = {'BaccaratCore': 'TableGame', 'BigWheelCore': 'tableGame', 'BlackjackCore': 'Table', 'CashWheelCore': 'tableGame',
         'CatalogHavenCore': 'Slots', 'GoldenEggCore': 'Slots', 'GreenHotCore': 'Slots', 'HorseRacingCore': 'tableGame',
         'OkamiSlotsCore': 'Slots', 'PlinkoCore': 'Plinko', 'RouletteCore': 'tableGame', 'SevensAndCherriesCore': 'Slots',
         'SuiteCore': 'suite', 'TexasHoldemCore': 'tableGame', 'ThreeCardPokerCore': 'tableGame', 'TournamentHoldemCore': 'tableGame'}
for core, var in cores.items():
    edit(GM + '.' + core, 'local %s = script.Parent;' % var, 'local %s%s' % (var, TARGET))
for core in ('BaccaratCore', 'BlackjackCore', 'TexasHoldemCore', 'ThreeCardPokerCore', 'TournamentHoldemCore'):
    edit(GM + '.' + core + '.Voicelines', 'local tableGame = script.Parent.Parent;',
         'local tableGame = script.Parent:FindFirstChild("Target") and script.Parent.Target.Value or script.Parent.Parent; -- [fix]')
for core in ('TexasHoldemCore', 'TournamentHoldemCore'):
    edit(GM + '.' + core, '''local Card = require(script.Card);
local Prob = require(script.Prob);
local Lookup = require(script.Lookup);
local Analysis = require(script.Analysis);''', '''local PokerEval = ServerStorage:WaitForChild("Modules"):WaitForChild("PokerEval"); -- [fix] shared copy, see GameManager
local Card = require(PokerEval.Card);
local Prob = require(PokerEval.Prob);
local Lookup = require(PokerEval.Lookup);
local Analysis = require(PokerEval.Analysis);''')

# ---------------------------------------------------------------------------------------------
# 6. NPCs
NP = 'ServerScriptService.Environment.NPCs'
edit(NP, '''local function GetAllNPCsTemplates()
	AllNPCs = NPCs:GetAllNPCs();
	if #AllNPCs < 50 then
		task.wait(1);
		GetAllNPCsTemplates();
	end
end''', '''local function GetAllNPCsTemplates()
	-- [fix] was endless recursion when the leaderboards can't load names; now waits at most 60 s
	local started = os.clock();
	AllNPCs = NPCs:GetAllNPCs();
	while #AllNPCs < 50 and os.clock() - started < 60 do
		task.wait(1);
		AllNPCs = NPCs:GetAllNPCs();
	end
end''')
edit(NP, '''			SpawnNPC(randomGame, randomStool, randomGame.Name);
			script:SetAttribute("GlobalNPCCount", script:GetAttribute("GlobalNPCCount") + 1);''', '''			-- [fix] one failed avatar download used to stop NPC spawning for the rest of the server
			local ok, err = pcall(SpawnNPC, randomGame, randomStool, randomGame.Name);
			if ok then
				script:SetAttribute("GlobalNPCCount", script:GetAttribute("GlobalNPCCount") + 1);
			else
				warn("NPC spawn failed: " .. tostring(err));
			end''')
edit('ServerStorage.Modules.NPCs', '''		if not ss then
			error("ERROR 4")
			return
		end''', '''		if not ss then
			dummy.Name = username -- [fix] used to error and leave a broken NPC behind
		end''')
# 50 full player avatars (layered clothing, own scripts, animations) is a lot for phones / Chromebooks
r = find(NP)
t, v = E.prop(r, 'AttributesSerialize')
a = parse_attrs(v[4:])
a['GlobalNPCLimit'] = 20.0
E.set_string(r, 'AttributesSerialize', write_attrs(a, {}))
LOG.append('NPC limit 50 -> 20')

# 7. Overhead nametag: GetRankInGroup / missing chat config errors meant no nametag at all
edit('StarterPlayer.StarterCharacterScripts.Overhead', '''local groupRank = Player:GetRankInGroup(ReplicatedStorage:GetAttribute("GroupID"));
local groupRole = BetterChatConfig.Permissions.Groups[ReplicatedStorage:GetAttribute("GroupID")][groupRank];
local chatRank = 1;
for rank, role in pairs(BetterChatConfig.Permissions.Ranks) do
	if role == groupRole then
		chatRank = rank;
		break;
	end
end
local roleColor = BetterChatConfig.ChatTags.Ranks[chatRank][1]["Color"];''', '''local groupRole, roleColor;
pcall(function() -- [fix] group / chat-rank lookups can fail; the nametag still shows ("Guest")
	local groupRank = Player:GetRankInGroup(ReplicatedStorage:GetAttribute("GroupID"));
	groupRole = BetterChatConfig.Permissions.Groups[ReplicatedStorage:GetAttribute("GroupID")][groupRank];
	local chatRank = 1;
	for rank, role in pairs(BetterChatConfig.Permissions.Ranks) do
		if role == groupRole then
			chatRank = rank;
			break;
		end
	end
	roleColor = BetterChatConfig.ChatTags.Ranks[chatRank][1]["Color"];
end)''')

# 8. Leaderboards: GetOrderedDataStore errors in unpublished places and killed the script
LB = 'ServerScriptService.Player.Leaderboards'
edit(LB, 'local CashOrderedStore = DataStoreService:GetOrderedDataStore("Cash");', '''local function orderedStore(name) -- [fix] GetOrderedDataStore errors without DataStore access
	local ok, store = pcall(DataStoreService.GetOrderedDataStore, DataStoreService, name);
	return ok and store or nil;
end
local CashOrderedStore = orderedStore("Cash");''')
for n, var in (('Playtime', 'Playtime'), ('Credits', 'Credits'), ('Tickets', 'Tickets'), ('Tournaments2', 'Tournaments')):
    edit(LB, 'local %sOrderedStore = DataStoreService:GetOrderedDataStore("%s");' % (var, n),
         'local %sOrderedStore = orderedStore("%s");' % (var, n))

# 9. Disclaimer screen
DC = 'StarterGui.Disclaimers.Disclaimer.DisclaimerLocalCore'
edit(DC, '''repeat task.wait(0.1); until LocalPlayer:GetAttribute("Playtime") and not Backing.Parent.Mobile.Visible;
if LocalPlayer:GetAttribute("Playtime") < 3 then''', '''-- [fix] never stay on "loading..." forever: after 20 s without data the PLAY button comes anyway.
-- The 60 s first-time timer is skipped when testing in Studio.
local waitStart = os.clock();
repeat task.wait(0.1); until (LocalPlayer:GetAttribute("Playtime") or os.clock() - waitStart > 20) and not Backing.Parent.Mobile.Visible;
if (LocalPlayer:GetAttribute("Playtime") or 0) < 3 and not game:GetService("RunService"):IsStudio() then''')
# the spinning background kept running every frame after the screen was closed
for path, rng in ((DC, '-180, 180, 2'), ('StarterGui.Disclaimers.Mobile.MobileLocalCore', '180, -180, -2')):
    edit(path, '''	while true do
		for i = %s do
			Backing.UIGradient.Rotation = i;
			task.wait();
		end
	end''' % rng, '''	while true do
		if Backing.Visible then
			for i = %s do
				if not Backing.Visible then break; end -- [fix] stop animating once closed
				Backing.UIGradient.Rotation = i;
				task.wait();
			end
		else
			task.wait(0.5);
		end
	end''' % rng)

# ---------------------------------------------------------------------------------------------
# 10. Delete things nobody uses
dead = set()
def kill(r):
    dead.update(E.descendants(r))
n_ks = 0
for r in list(E.loc):
    if E.classof(r) == 'KeyframeSequence':
        n_ks += 1
        p = E.parent.get(r)
        # the AnimSaves container of the animation editor goes too
        if p in E.loc and E.name(p) == 'AnimSaves':
            kill(p)
        else:
            kill(r)
kill(find('ServerStorage.RBX_ANIMSAVES'))
LOG.append('animation editor saves: %d KeyframeSequences' % n_ks)
kill(find('ServerScriptService.BetterChat V3.Config.Loader.oldsrc'))   # unused old copy (the loader requires "src")
for m in ('Card', 'Prob', 'Lookup', 'Analysis', 'Underscore', 'Bitop'):
    kill(find(GM + '.TournamentHoldemCore.' + m))                       # identical to TexasHoldemCore's (shared now)
for r in dead:
    if E.classof(r) in ('Script', 'LocalScript', 'ModuleScript'):
        assert not any(E.path(r).startswith(p) for p in ('ServerScriptService.Player', 'StarterGui')), E.path(r)
before = len(E.loc)
E.delete(dead)
LOG.append('deleted %d objects (%d -> %d)' % (before - len(E.loc), before, len(E.loc)))

# 11. 610 lights all had Shadows on
n = 0
for c in E.cls:
    if c['name'] in ('PointLight', 'SpotLight', 'SurfaceLight'):
        for p in c['props']:
            if p[0] == 'Shadows':
                n += sum(1 for x in p[2] if x == b'\x01')
                p[2] = [b'\x00'] * len(p[2])
LOG.append('light shadows off: %d' % n)

data = E.save()
open(out_path, 'wb').write(data)
for l in LOG: print(l)
print('wrote', out_path, len(data), 'bytes')
