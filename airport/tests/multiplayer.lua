local out = {}
local function say(...) local t = {} for i = 1, select("#", ...) do t[#t + 1] = tostring((select(i, ...))) end out[#out + 1] = table.concat(t, " ") end
local a = JOINER
local b = ADD_PLAYER("friend") runFor(4)
local dbg = SERVER_G.AirportDebug
local function touch(part, pl) CTX = SERVER part.Touched:_fire(pl.Character.Torso) runFor(1.2) end
touch(workspace.Airport1.Pads.Claim, a)
touch(workspace.Airport2.Pads.Claim, b)
touch(workspace.Airport3.Pads.Claim, a)
say("A owns", dbg.G.byPlayer[a] and dbg.G.byPlayer[a].i, "| B owns", dbg.G.byPlayer[b] and dbg.G.byPlayer[b].i, "| airport 3 owner", tostring(dbg.G.plots[3].owner))
local toastA = a.PlayerGui.AirportUI.TextLabel
for _, c in ipairs(a.PlayerGui.AirportUI:GetChildren()) do if c:IsA("TextLabel") and c.Visible then toastA = c end end
say("A's message after trying a 2nd airport:", toastA.Text)
-- B steps on A's road pad
local road = workspace.Airport1.Pads:FindFirstChild("Buy Entrance Road")
touch(road, b)
say("B on A's pad -> A bought road?", dbg.G.plots[1].bought.road == true)
touch(road, a)
say("A on own pad -> bought road?", dbg.G.plots[1].bought.road == true)
-- A leaves
a.Parent = nil
CTX = SERVER game:GetService("Players").PlayerRemoving:_fire(a) runFor(2)
say("after A left: airport 1 owner", tostring(dbg.G.plots[1].owner), "| items", #workspace.Airport1.Items:GetChildren(), "| claim pad back", workspace.Airport1.Pads:FindFirstChild("Claim") ~= nil, "| B still owns", dbg.G.byPlayer[b] and dbg.G.byPlayer[b].i)
CTX = CLIENT_CTX
return out
