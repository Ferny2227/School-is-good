-- Builds the DataModel from PLACE (export.py), adds the services the scripts use, and plays a join.
local OPT = OPTIONS or {}
local function P(o) return rawget(o, "_p") end

------------------------------------------------------------------------------- build the place
local CLASS = API.classes
local byId = {}
local dropped = { classes = {}, props = {} }
game = makeInstance("DataModel")
P(game).Name = "Game"
-- enum properties: convert {_enum=n} into EnumItems of the property's enum type
local function convertProp(cls, name, v)
	local m
	for _, cn in ipairs((function()
		local t, c = {}, cls
		while c and CLASS[c] do table.insert(t, c) c = CLASS[c].super end
		return t
	end)()) do
		if CLASS[cn].props[name] then m = CLASS[cn].props[name] break end
	end
	if not m then return nil, false end
	if type(v) == "table" and rawget(v, "_enum") then
		local items = API.enums[m.t]
		if items then
			for itemName, val in pairs(items) do
				if val == rawget(v, "_enum") then return Enum[m.t][itemName], true end
			end
			return nil, false
		end
		return nil, false
	end
	return v, true
end
for _, rec in ipairs(PLACE) do
	if CLASS[rec.class] then
		local o = makeInstance(rec.class)
		byId[rec.id] = o
		for k, v in pairs(rec.props) do
			if k == "Source" then
				rawset(o, "_scriptSource", v)
			elseif type(v) == "table" and rawget(v, "_ref") then
				P(o)["\1ref" .. k] = rawget(v, "_ref")
			else
				local cv, ok = convertProp(rec.class, k, v)
				if ok then
					P(o)[k] = cv
				else
					dropped.props[rec.class .. "." .. k] = true
				end
			end
		end
	else
		dropped.classes[rec.class] = (dropped.classes[rec.class] or 0) + 1
	end
end
-- references (ObjectValue.Value etc.)
for id, o in pairs(byId) do
	local refs = {}
	for k, v in pairs(P(o)) do
		if type(k) == "string" and k:sub(1, 4) == "\1ref" then refs[k] = v end
	end
	for k, v in pairs(refs) do
		P(o)[k] = nil
		if v >= 0 and byId[v] then P(o)[k:sub(5)] = byId[v] end
	end
end
-- parents in file order; children of dropped classes are dropped too (like old engines)
local parentOf = {}
for _, rec in ipairs(PLACE) do parentOf[rec.id] = rec.parent end
for _, id in ipairs(ORDER) do
	local o = byId[id]
	if o then
		local pid = parentOf[id]
		local p = (pid == -1) and game or byId[pid]
		if p then
			rawset(o, "_parent", p)
			table.insert(rawget(p, "_children"), o)
		else
			byId[id] = nil
		end
	end
end
DROPPED = dropped

------------------------------------------------------------------------------- services
local services = {}
for _, c in ipairs(rawget(game, "_children")) do services[rawget(c, "_class")] = c end
local function service(cls)
	if services[cls] then return services[cls] end
	if not CLASS[cls] then error("'" .. tostring(cls) .. "' is not a valid Service name", 3) end
	local s = makeInstance(cls)
	P(s).Name = cls
	rawset(s, "_parent", game)
	table.insert(rawget(game, "_children"), s)
	services[cls] = s
	return s
end
function GETSERVICE(name) return service(name) end
local function addMethod(name, f) _G.SIM_METHODS[name] = f end
workspace = service("Workspace")
local Players = service("Players")
local RS = service("ReplicatedStorage")
local RF = service("ReplicatedFirst")
local SG = service("StarterGui")
local SP = service("StarterPlayer")
local Lighting = service("Lighting")
local RunService = service("RunService")
local UIS = service("UserInputService")
local CAS = service("ContextActionService")
local GuiService = service("GuiService")

BASE_ENV.game = game
BASE_ENV.Game = game
BASE_ENV.workspace = workspace
BASE_ENV.Workspace = workspace

-- camera
local camera
for _, c in ipairs(rawget(workspace, "_children")) do if rawget(c, "_class") == "Camera" then camera = c end end
if not camera then
	camera = makeInstance("Camera")
	camera.Parent = workspace
end
P(workspace).CurrentCamera = camera
P(camera).ViewportSize = SCREEN

------------------------------------------------------------------------------- method implementations
local MT = SIM_METHODS
MT["DataModel.GetService"] = function(self, name) return service(name) end
MT["ServiceProvider.GetService"] = MT["DataModel.GetService"]
MT["ServiceProvider.getService"] = MT["DataModel.GetService"]
MT["ServiceProvider.FindService"] = function(self, name) return services[name] end
MT["DataModel.BindToClose"] = function() end
MT["DataModel.IsLoaded"] = function() return true end

-- Players
local playerList = {}
function PLAYERS_LIST() local t = {} for i, p in ipairs(playerList) do t[i] = p end return t end
MT["Players.GetPlayers"] = PLAYERS_LIST
MT["Players.getPlayers"] = PLAYERS_LIST
MT["Players.GetChildren"] = nil
MT["Players.GetPlayerFromCharacter"] = function(self, ch)
	for _, p in ipairs(playerList) do if P(p).Character == ch then return p end end
end
MT["Players.getPlayerFromCharacter"] = MT["Players.GetPlayerFromCharacter"]
MT["Players.playerFromCharacter"] = MT["Players.GetPlayerFromCharacter"]
MT["Players.GetPlayerByUserId"] = function(self, id)
	for _, p in ipairs(playerList) do if P(p).UserId == id then return p end end
end
MT["Players.GetNameFromUserIdAsync"] = function(self, id)
	wait(0.1)
	if OPT.webApisFail then error("HTTP 403 (Forbidden)", 2) end
	return "User" .. tostring(id)
end
MT["Players.GetUserIdFromNameAsync"] = function(self, name)
	wait(0.1)
	if OPT.webApisFail then error("HTTP 403 (Forbidden)", 2) end
	return 1000 + #name
end
MT["Players.GetCharacterAppearanceAsync"] = function() error("HTTP 403") end
SPECIAL_GET.Players = {
	LocalPlayer = function() return CTX.kind == "client" and CTX.player or nil end,
	localPlayer = function() return CTX.kind == "client" and CTX.player or nil end,
	NumPlayers = function() return #playerList end,
}
-- Player
MT["Player.Kick"] = function(self, msg)
	SIMLOG("KICK", P(self).Name .. ": " .. tostring(msg))
	KICKED = msg or "kicked"
	self.Parent = nil
end
MT["Player.GetMouse"] = function(self)
	local m = rawget(self, "_mouse")
	if not m then
		m = makeInstance(CLASS.PlayerMouse and "PlayerMouse" or "Mouse")
		P(m).Name = "Mouse"
		P(m).Hit = CFrame.new()
		P(m).ViewSizeX = SCREEN.X
		P(m).ViewSizeY = SCREEN.Y
		rawset(self, "_mouse", m)
	end
	return m
end
MT["Player.IsFriendsWith"] = function() wait(0.05) return false end
MT["Player.GetRankInGroup"] = function() wait(0.05) return 0 end
MT["Player.IsInGroup"] = function() wait(0.05) return false end
MT["Player.GetRoleInGroup"] = function() wait(0.05) return "Guest" end
MT["Player.LoadCharacter"] = function(self) SPAWN_CHARACTER(self) end
MT["Player.HasAppearanceLoaded"] = function() return true end
MT["Player.Move"] = function() end

-- Model / Humanoid / misc parts
MT["Humanoid.LoadAnimation"] = function()
	return { Play = function() end, Stop = function() end, AdjustSpeed = function() end, Stopped = NEWSIGNAL("Stopped") }
end
MT["Humanoid.MoveTo"] = function() end
MT["Humanoid.TakeDamage"] = function(self, n) self.Health = self.Health - n end
MT["Humanoid.UnequipTools"] = function() end
MT["Humanoid.EquipTool"] = function() end

-- Workspace
MT["Workspace.FindPartOnRay"] = function(self, ray, ignore)
	if RAYHIT and RAYHIT.Parent then return RAYHIT, Vector3.new() end
	return nil, Vector3.new()
end
MT["Workspace.FindPartOnRayWithIgnoreList"] = function() return nil, Vector3.new() end
MT["Workspace.FindPartOnRayWithWhitelist"] = function() return nil, Vector3.new() end
MT["Camera.Interpolate"] = function() end
MT["Camera.ScreenPointToRay"] = function() return Ray.new(Vector3.new(), Vector3.new(0, 0, -1)) end
MT["Camera.ViewportPointToRay"] = MT["Camera.ScreenPointToRay"]
MT["Camera.WorldToScreenPoint"] = function() return Vector3.new(100, 100, 10), true end
MT["Camera.WorldToViewportPoint"] = MT["Camera.WorldToScreenPoint"]

-- ReplicatedFirst
MT["ReplicatedFirst.RemoveDefaultLoadingScreen"] = function() DEFAULT_LOADING_REMOVED = true end

-- StarterGui
local coreGui = {}
MT["StarterGui.SetCoreGuiEnabled"] = function(self, t, on) coreGui[tostring(t)] = on end
MT["StarterGui.GetCoreGuiEnabled"] = function(self, t) return coreGui[tostring(t)] ~= false end
MT["StarterGui.SetCore"] = function(self, name, value)
	if OPT.setCoreStrict and name ~= "TopbarEnabled" and name ~= "ChatMakeSystemMessage" and name ~= "SendNotification" and name ~= "ChatWindowPosition" and name ~= "ChatBarDisabled" then
		error("SetCore: " .. tostring(name) .. " has not been registered by the CoreScripts", 2)
	end
	SIMLOG("core", "SetCore " .. tostring(name))
end
MT["StarterGui.GetCore"] = function(self, name) return nil end

-- RunService
local renderBinds = {}
MT["RunService.IsStudio"] = function() return OPT.studio == true end
MT["RunService.IsServer"] = function() return CTX.kind == "server" end
MT["RunService.IsClient"] = function() return CTX.kind == "client" end
MT["RunService.IsRunMode"] = function() return false end
MT["RunService.BindToRenderStep"] = function(self, name, prio, fn) renderBinds[name] = { fn = fn, ctx = CTX } end
MT["RunService.UnbindFromRenderStep"] = function(self, name) renderBinds[name] = nil end
local lastFrame = 0
FRAME = function()
	if NOW - lastFrame < 1 / 30 then return end
	local dt = NOW - lastFrame
	lastFrame = NOW
	local rs = rawget(RunService, "_events")
	if rs.RenderStepped then
		-- RenderStepped only exists on clients
		local prev = CTX
		rs.RenderStepped:_fire(dt)
	end
	if rs.Heartbeat then rs.Heartbeat:_fire(dt) end
	if rs.Stepped then rs.Stepped:_fire(NOW, dt) end
	for name, b in pairs(renderBinds) do
		local co = newThread(function() b.fn(dt) end, b.ctx)
		local ok, err = coroutine.resume(co)
		if not ok then SIMLOG("ERROR", "render step " .. name .. ": " .. tostring(err)) table.insert(ERRORS, { msg = "render " .. name .. ": " .. tostring(err), tb = "" }) renderBinds[name] = nil end
	end
end

-- UserInputService / ContextActionService / GuiService
MT["UserInputService.GetConnectedGamepads"] = function() return {} end
MT["UserInputService.GetNavigationGamepads"] = function() return {} end
MT["UserInputService.GetGamepadConnected"] = function() return false end
MT["UserInputService.GetFocusedTextBox"] = function() return nil end
MT["UserInputService.IsKeyDown"] = function() return false end
MT["UserInputService.GetLastInputType"] = function() return Enum.UserInputType.MouseMovement end
MT["UserInputService.GetKeysPressed"] = function() return {} end
P(UIS).KeyboardEnabled = true
P(UIS).MouseEnabled = true
MT["ContextActionService.BindAction"] = function(self, name, fn, touch, ...) end
MT["ContextActionService.BindActionToInputTypes"] = function() end
MT["ContextActionService.UnbindAction"] = function() end
MT["ContextActionService.SetTitle"] = function() end
MT["ContextActionService.SetImage"] = function() end
MT["ContextActionService.GetButton"] = function() return nil end
MT["GuiService.GetGuiInset"] = function() return Vector2.new(0, 36), Vector2.new(0, 0) end
MT["GuiService.AddSelectionParent"] = function() end
MT["GuiService.RemoveSelectionGroup"] = function() end
MT["GuiService.IsTenFootInterface"] = function() return false end
MT["GuiService.CloseInspectMenu"] = function() end

-- MarketplaceService
local MPS = service("MarketplaceService")
MT["MarketplaceService.PlayerOwnsAsset"] = function(self, player, id)
	if OPT.webApisHang then while true do wait(1) end end
	wait(0.2)
	if OPT.webApisFail then error("HTTP 500", 2) end
	return false
end
MT["MarketplaceService.UserOwnsGamePassAsync"] = MT["MarketplaceService.PlayerOwnsAsset"]
MT["MarketplaceService.GetProductInfo"] = function() wait(0.1) return { Name = "Thing", PriceInRobux = 10 } end
MT["MarketplaceService.PromptPurchase"] = function() end
MT["MarketplaceService.PromptProductPurchase"] = function() end
MT["MarketplaceService.PromptGamePassPurchase"] = function() end

-- TeleportService
local TS = service("TeleportService")
MT["TeleportService.ReserveServer"] = function() wait(0.1) error("ReserveServer: can't reserve a server in this place", 2) end
MT["TeleportService.Teleport"] = function(self, id, p) SIMLOG("TP", "teleport to " .. tostring(id)) end
MT["TeleportService.TeleportToPrivateServer"] = function() SIMLOG("TP", "teleport to private server") end
MT["TeleportService.GetLocalPlayerTeleportData"] = function() return nil end
MT["TeleportService.SetTeleportGui"] = function() end

-- HttpService
local Http = service("HttpService")
MT["HttpService.GetAsync"] = function() wait(0.1) error("Http requests are not enabled", 2) end
MT["HttpService.PostAsync"] = MT["HttpService.GetAsync"]
MT["HttpService.JSONEncode"] = function(self, t) return "{}" end
MT["HttpService.JSONDecode"] = function(self, s) return {} end
MT["HttpService.GenerateGUID"] = function() return "{00000000-0000-0000-0000-000000000000}" end

-- DataStoreService: "ok" | "unpublished" (errors like Studio without API access) | "hang" | "fail"
local DSS = service("DataStoreService")
local STORES = {}
local function dsCheck()
	local mode = OPT.datastore or "ok"
	if CTX.kind ~= "server" then error("DataStore can't be accessed from the client", 3) end
	if mode == "hang" then while true do wait(1) end end
	wait(0.05)
	if mode == "fail" then error("502: API Services rejected request", 3) end
	if mode == "forbidden" then error("403: Cannot write to DataStore from studio if API access is not enabled.", 3) end
end
local function makeStore(name, ordered)
	if OPT.datastore == "unpublished" then error("You must publish this place to the web to access DataStore.", 3) end
	STORES[name] = STORES[name] or {}
	local data = STORES[name]
	local st = makeInstance(ordered and "OrderedDataStore" or "GlobalDataStore")
	P(st).Name = name
	rawset(st, "_data", data)
	return st
end
MT["DataStoreService.GetDataStore"] = function(self, name, scope) return makeStore("ds:" .. tostring(name) .. ":" .. tostring(scope)) end
MT["DataStoreService.GetGlobalDataStore"] = function(self) return makeStore("global") end
MT["DataStoreService.GetOrderedDataStore"] = function(self, name, scope) return makeStore("ods:" .. tostring(name) .. ":" .. tostring(scope), true) end
MT["GlobalDataStore.GetAsync"] = function(self, k) dsCheck() return rawget(self, "_data")[k] end
MT["GlobalDataStore.SetAsync"] = function(self, k, v) dsCheck() rawget(self, "_data")[k] = v end
MT["GlobalDataStore.UpdateAsync"] = function(self, k, f)
	dsCheck()
	local d = rawget(self, "_data")
	local v = f(d[k])
	if v ~= nil then d[k] = v end
	return v
end
MT["GlobalDataStore.IncrementAsync"] = function(self, k, n) dsCheck() local d = rawget(self, "_data") d[k] = (d[k] or 0) + (n or 1) return d[k] end
MT["GlobalDataStore.RemoveAsync"] = function(self, k) dsCheck() local d = rawget(self, "_data") local v = d[k] d[k] = nil return v end
MT["GlobalDataStore.OnUpdate"] = function(self, k, f) return { disconnect = function() end } end
MT["OrderedDataStore.GetSortedAsync"] = function(self, asc, size)
	dsCheck()
	local list = {}
	for k, v in pairs(rawget(self, "_data")) do table.insert(list, { key = k, value = v }) end
	table.sort(list, function(a, b) if asc then return a.value < b.value end return a.value > b.value end)
	local pages = makeInstance("DataStorePages")
	rawset(pages, "_page", list)
	return pages
end
MT["DataStorePages.GetCurrentPage"] = function(self) return rawget(self, "_page") end
MT["Pages.GetCurrentPage"] = MT["DataStorePages.GetCurrentPage"]
MT["Pages.AdvanceToNextPageAsync"] = function(self) rawset(self, "_page", {}) end

-- Debris / Teams / Chat / Sound
local Debris = service("Debris")
MT["Debris.AddItem"] = function(self, o, t) delay(t or 10, function() if rawget(o, "_parent") then o:Destroy() end end) end
MT["Debris.addItem"] = MT["Debris.AddItem"]
MT["Sound.Play"] = function() end
MT["Sound.Stop"] = function() end
MT["Sound.Pause"] = function() end
MT["Sound.Resume"] = function() end
MT["ParticleEmitter.Emit"] = function() end
MT["Teams.GetTeams"] = function(self) return self:GetChildren() end
MT["Chat.Chat"] = function() end
MT["ValueBase.Changed"] = nil

-- TweenService (for engines that have it)
MT["TweenService.Create"] = function(self, obj, info, props)
	local tw = makeInstance("Tween")
	rawset(tw, "_go", function()
		delay(info.Time or 1, function()
			for k, v in pairs(props) do obj[k] = v end
			tw.Completed:_fire(Enum.PlaybackState.Completed)
		end)
	end)
	return tw
end
MT["Tween.Play"] = function(self) rawget(self, "_go")() end
MT["TweenBase.Play"] = MT["Tween.Play"]
MT["Tween.Cancel"] = function() end
MT["TweenBase.Cancel"] = function() end

------------------------------------------------------------------------------- script runner hooks
-- Scripts start when they land somewhere they can run (like Roblox).
local function contextFor(o)
	local cls = rawget(o, "_class")
	local p = rawget(o, "_parent")
	local chain = {}
	while p do table.insert(chain, p) p = rawget(p, "_parent") end
	if cls == "Script" then
		for _, a in ipairs(chain) do
			if a == workspace or a == services.ServerScriptService then return SERVER end
			local ac = rawget(a, "_class")
			if ac == "Backpack" or ac == "PlayerGui" then return SERVER end
		end
	elseif cls == "LocalScript" then
		for _, a in ipairs(chain) do
			local ac = rawget(a, "_class")
			if ac == "PlayerGui" or ac == "Backpack" or ac == "PlayerScripts" then
				local pl = rawget(a, "_parent")
				return { kind = "client", player = pl }
			end
			for _, pl in ipairs(playerList) do
				if P(pl).Character == a then return { kind = "client", player = pl } end
			end
		end
	end
end
ONPARENT = function(o)
	local function check(x)
		local cls = rawget(x, "_class")
		if (cls == "Script" or cls == "LocalScript") and not P(x).Disabled and not rawget(x, "_ran") then
			local ctx = contextFor(x)
			if ctx then
				local co = newThread(function() runScript(x, ctx) end, ctx)
				SCHEDULE_NOW(co)
			end
		end
		for _, c in ipairs(rawget(x, "_children")) do check(c) end
	end
	check(o)
end

------------------------------------------------------------------------------- start the server
function START_SERVER()
	local scripts = {}
	local function collect(x)
		for _, c in ipairs(rawget(x, "_children")) do
			if rawget(c, "_class") == "Script" and not P(c).Disabled then table.insert(scripts, c) end
			collect(c)
		end
	end
	collect(workspace)
	collect(service("ServerScriptService"))
	for _, s in ipairs(scripts) do runScript(s, SERVER) end
end

------------------------------------------------------------------------------- a player joins
local userIdN = 0
function SPAWN_CHARACTER(player)
	local old = P(player).Character
	if old then old:Destroy() end
	local ch = makeInstance("Model")
	P(ch).Name = P(player).Name
	local hum = makeInstance("Humanoid")
	P(hum).Health = 100
	P(hum).MaxHealth = 100
	P(hum).WalkSpeed = 16
	hum.Parent = ch
	for _, n in ipairs({ "HumanoidRootPart", "Head", "Torso" }) do
		local part = makeInstance("Part")
		P(part).Name = n
		part.Parent = ch
	end
	P(ch).PrimaryPart = ch.HumanoidRootPart
	-- the GUI is reset when a character spawns (ResetOnSpawn guis; old engines reset everything)
	local pg = P(player).PlayerGui or player:FindFirstChild("PlayerGui")
	for _, g in ipairs(pg:GetChildren()) do
		local reset = true
		if API.classes.ScreenGui.props.ResetOnSpawn and rawget(g, "_class") == "ScreenGui" then reset = P(g).ResetOnSpawn ~= false end
		if reset and rawget(g, "_fromStarterGui") then g:Destroy() end
		if reset and not rawget(g, "_fromStarterGui") and rawget(g, "_class") == "ScreenGui" and OPT.resetNonStarterGuis then g:Destroy() end
	end
	for _, item in ipairs(SG:GetChildren()) do
		local keep = false
		for _, g in ipairs(pg:GetChildren()) do
			if rawget(g, "_starterSource") == item then keep = true end
		end
		if not keep then
			local c = item:Clone()
			if c then
				rawset(c, "_fromStarterGui", true)
				rawset(c, "_starterSource", item)
				c.Parent = pg
			end
		end
	end
	local sp = services.StarterPack
	local bp = player:FindFirstChild("Backpack")
	if sp and bp then
		for _, t in ipairs(bp:GetChildren()) do t:Destroy() end
		for _, t in ipairs(sp:GetChildren()) do
			local c = t:Clone()
			if c then c.Parent = bp end
		end
	end
	ch.Parent = workspace
	player.Character = ch
	player.CharacterAdded:_fire(ch)
end
function ADD_PLAYER(name)
	userIdN = userIdN + 1
	local p = makeInstance("Player")
	P(p).Name = name
	P(p).UserId = 100 + userIdN
	if API.classes.Player.props.userId then P(p).userId = 100 + userIdN end
	P(p).FollowUserId = 0
	P(p).CameraMaxZoomDistance = 400
	P(p).CameraMinZoomDistance = 0.5
	table.insert(playerList, p)
	local pg = makeInstance("PlayerGui") P(pg).Name = "PlayerGui"
	local bp = makeInstance("Backpack") P(bp).Name = "Backpack"
	rawset(pg, "_parent", p) table.insert(rawget(p, "_children"), pg)
	rawset(bp, "_parent", p) table.insert(rawget(p, "_children"), bp)
	local ps
	if API.classes.PlayerScripts then
		ps = makeInstance("PlayerScripts") P(ps).Name = "PlayerScripts"
		rawset(ps, "_parent", p) table.insert(rawget(p, "_children"), ps)
	end
	local ctx = { kind = "client", player = p }
	CLIENT_CTX = ctx
	p.Parent = Players
	-- server sees the join
	local co = newThread(function() Players.PlayerAdded:_fire(p) end, SERVER)
	SCHEDULE_NOW(co)
	-- client: ReplicatedFirst first, then PlayerScripts, then the character + PlayerGui
	delay(0.2, function()
		local all = {}
		local function rec(x) for _, c in ipairs(rawget(x, "_children")) do table.insert(all, c) rec(c) end end
		rec(RF)
		for _, s in ipairs(all) do
			if rawget(s, "_class") == "LocalScript" and not P(s).Disabled then
				local c2 = newThread(function() runScript(s, ctx) end, ctx)
				SCHEDULE_NOW(c2)
			end
		end
	end)
	delay(1.0, function()
		local sps = SP:FindFirstChild("StarterPlayerScripts")
		if sps and ps then
			for _, c in ipairs(sps:GetChildren()) do
				local cc = c:Clone()
				if cc then cc.Parent = ps end
			end
		end
	end)
	delay(1.5, function()
		if P(Players).CharacterAutoLoads ~= false then SPAWN_CHARACTER(p) end
	end)
	return p
end

------------------------------------------------------------------------------- UIListLayout / UIGridLayout (engines that have them)
local LAYOUTS = setmetatable({}, { __mode = "k" })
NEW_INSTANCE_HOOK = function(o)
	local c = rawget(o, "_class")
	if c == "UIListLayout" or c == "UIGridLayout" then LAYOUTS[o] = true end
end
for _, o in pairs(byId) do
	local c = rawget(o, "_class")
	if c == "UIListLayout" or c == "UIGridLayout" then LAYOUTS[o] = true end
end
local function en(v) return v and v.Name or nil end
local function applyLayout(layout)
	local container = rawget(layout, "_parent")
	if not container or not isA(rawget(container, "_class"), "GuiBase2d") then return end
	local _, _, W, H = ABSRECT(container)
	local p = rawget(layout, "_p")
	local list = {}
	for i, c in ipairs(rawget(container, "_children")) do
		if isA(rawget(c, "_class"), "GuiObject") and rawget(c, "_p").Visible ~= false then table.insert(list, { c = c, i = i }) end
	end
	local sort = en(p.SortOrder) or "Name"
	table.sort(list, function(a, b)
		if sort == "Name" then
			local na, nb = rawget(a.c, "_p").Name, rawget(b.c, "_p").Name
			if na ~= nb then return na < nb end
		elseif sort == "LayoutOrder" then
			local la, lb = rawget(a.c, "_p").LayoutOrder or 0, rawget(b.c, "_p").LayoutOrder or 0
			if la ~= lb then return la < lb end
		end
		return a.i < b.i
	end)
	local function setPos(c, x, y)
		local ap = rawget(c, "_p").AnchorPoint
		local _, _, w, h = ABSRECT(c)
		if ap then x, y = x + ap._x * w, y + ap._y * h end
		rawget(c, "_p").Position = UDim2.new(0, x, 0, y)
	end
	if rawget(layout, "_class") == "UIGridLayout" then
		local cs, cp = p.CellSize or UDim2.new(0, 100, 0, 100), p.CellPadding or UDim2.new(0, 5, 0, 5)
		local cw, ch = cs._a * W + cs._b, cs._c * H + cs._d
		local pw, ph = cp._a * W + cp._b, cp._c * H + cp._d
		local cols = math.max(1, math.floor((W + pw) / math.max(1, cw + pw)))
		if (p.FillDirectionMaxCells or 0) > 0 then cols = math.min(cols, p.FillDirectionMaxCells) end
		local n = math.min(#list, cols)
		local totalW = n * cw + math.max(0, n - 1) * pw
		local x0 = 0
		local ha = en(p.HorizontalAlignment)
		if ha == "Center" then x0 = (W - totalW) / 2 elseif ha == "Right" then x0 = W - totalW end
		for k, e in ipairs(list) do
			local col, row = (k - 1) % cols, math.floor((k - 1) / cols)
			rawget(e.c, "_p").Size = UDim2.new(0, cw, 0, ch)
			setPos(e.c, x0 + col * (cw + pw), row * (ch + ph))
		end
	else
		local vertical = en(p.FillDirection) ~= "Horizontal"
		local pad = p.Padding and (p.Padding.Scale * (vertical and H or W) + p.Padding.Offset) or 0
		local total = 0
		for k, e in ipairs(list) do
			local _, _, w, h = ABSRECT(e.c)
			total = total + (vertical and h or w) + (k > 1 and pad or 0)
		end
		local ha, va = en(p.HorizontalAlignment), en(p.VerticalAlignment)
		local at = 0
		if vertical then
			if va == "Center" then at = (H - total) / 2 elseif va == "Bottom" then at = H - total end
		else
			if ha == "Center" then at = (W - total) / 2 elseif ha == "Right" then at = W - total end
		end
		for _, e in ipairs(list) do
			local _, _, w, h = ABSRECT(e.c)
			if vertical then
				local x = 0
				if ha == "Center" then x = (W - w) / 2 elseif ha == "Right" then x = W - w end
				setPos(e.c, x, at)
				at = at + h + pad
			else
				local y = 0
				if va == "Center" then y = (H - h) / 2 elseif va == "Bottom" then y = H - h end
				setPos(e.c, at, y)
				at = at + w + pad
			end
		end
	end
end
local prevFrame = FRAME
FRAME = function()
	prevFrame()
	for l in pairs(LAYOUTS) do
		if rawget(l, "_parent") and not rawget(l, "_destroyed") then applyLayout(l) end
	end
end

-- DataModel shortcuts real Roblox has
SPECIAL_GET.DataModel = {
	workspace = function() return workspace end,
	Workspace = function() return workspace end,
	lighting = function() return GETSERVICE("Lighting") end,
	Lighting = function() return GETSERVICE("Lighting") end,
	Players = function() return GETSERVICE("Players") end,
	players = function() return GETSERVICE("Players") end,
}
SIM_METHODS["ServiceProvider.service"] = SIM_METHODS["DataModel.GetService"]

SPECIAL_GET.Humanoid = {
	Torso = function(h)
		local ch = rawget(h, "_parent")
		return ch and (ch:FindFirstChild("Torso") or ch:FindFirstChild("HumanoidRootPart"))
	end,
}
