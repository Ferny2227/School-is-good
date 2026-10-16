local out = {}
local function say(...) local t = {} for i = 1, select("#", ...) do t[#t + 1] = tostring((select(i, ...))) end out[#out + 1] = table.concat(t, " ") end
local p = JOINER
local torso = p.Character.Torso
local function touch(part, hit) CTX = SERVER part.Touched:_fire(hit or torso) runFor(0.7) end
local function errs() return #ERRORS end
-- claim a mansion
local Y, F
for _, t in ipairs(workspace:GetChildren()) do
	if t.Name == "tycoon" and t:FindFirstChild("Factory") and t.Factory:FindFirstChild("Become Owner") then Y = t break end
end
F = Y.Factory
touch(F["Become Owner"].Head) runFor(4)
say("owner:", F.OwnerName.Value, "| leaderstats cash", p.leaderstats.Cash.Value)
-- a cheap tycoon button still works with the new price
local drop2
for _, c in ipairs(F:GetChildren()) do if c.Name:sub(1, 6) == "Drop2 " then drop2 = c end end
p.leaderstats.Cash.Value = 200
touch(drop2.Head)
say("bought", drop2.Name, "-> cash", p.leaderstats.Cash.Value, "| drop2 exists", F:FindFirstChild("Drop2") ~= nil)
-- backyard
runFor(2)
local function visiblePads() local n = 0 for _, c in ipairs(Y.BackyardPads:GetChildren()) do n = n + 1 end return n end
say("pads visible after owning:", visiblePads())
p.leaderstats.Cash.Value = 50000000
local bought, failed = 0, {}
for round = 1, 30 do
	local pads = Y.BackyardPads:GetChildren()
	if #pads == 0 then break end
	for _, pad in ipairs(pads) do
		local before = errs()
		touch(pad)
		if errs() > before then table.insert(failed, pad.Name .. ": " .. ERRORS[#ERRORS].msg) end
		bought = bought + 1
	end
end
local items, parts, empty = 0, 0, {}
for _, m in ipairs(Y.BackyardItems:GetChildren()) do
	items = items + 1
	local n = #m:GetChildren()
	parts = parts + n
	if n == 0 then table.insert(empty, m.Name) end
end
say("touched", bought, "pads -> built", items, "items,", parts, "parts | empty items:", table.concat(empty, ", "))
say("cash left", p.leaderstats.Cash.Value, "| BackyardItems", p.BackyardItems.Value, "| income/s", p.BackyardIncome.Value)
for _, f in ipairs(failed) do say("  FAILED " .. f) end
local money
for _, c in ipairs(F:GetChildren()) do if c:FindFirstChild("Money") then money = c.Money end end
local m0 = money.Value runFor(3) say("collector money in 3s:", m0, "->", money.Value)
-- teleport button
local before = torso.CFrame.p
CTX = CLIENT_CTX game.ReplicatedStorage.BackyardEvent:FireServer("tp") CTX = SERVER runFor(1)
say("tp:", tostring(before), "->", tostring(p.Character.Torso.CFrame.p))
CTX = CLIENT_CTX game.ReplicatedStorage.BackyardEvent:FireServer("tp") CTX = SERVER runFor(1)
say("tp back:", tostring(p.Character.Torso.CFrame.p))
-- UI
local ui = p.PlayerGui:FindFirstChild("BackyardUI")
say("UI:", ui and ui.Box.Stats.Text, "| toast", ui and ui.Toast.Text)
-- owner leaves: backyard resets
F.OwnerName.Value = "" runFor(2)
local left = 0 for _ in ipairs(Y.BackyardItems:GetChildren()) do left = left + 1 end
say("after owner left: items", left, "pads", visiblePads())
return out
