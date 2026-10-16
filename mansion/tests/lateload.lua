local out = {}
local function count() local n = 0 for _, t in ipairs(workspace:GetChildren()) do if t.Name == "tycoon" and t:FindFirstChild("BackyardPads") then n = n + 1 end end return n end
out[#out+1] = "backyards at start: " .. count()
local m = makeInstance("Model") m.Name = "tycoon" m.Parent = workspace
runFor(1)
local base = makeInstance("Part") base.Name = "BackyardBase" base.Size = Vector3.new(182, 2, 196) base.CFrame = CFrame.new(1000, 1.4, 1000) base.Parent = m
runFor(2)
out[#out+1] = "after a tycoon (and then its base) loaded late: " .. count() .. " | pads on it " .. (m:FindFirstChild("BackyardPads") and #m.BackyardPads:GetChildren() or 0)
return out
