local out = {}
local p = JOINER
local n, yards = 0, 0
for _, t in ipairs(workspace:GetChildren()) do
	if t.Name == "tycoon" and t:FindFirstChild("BackyardPads") then yards = yards + 1 n = n + #t.BackyardPads:GetChildren() end
end
out[#out+1] = "before anyone owns: backyards " .. yards .. ", pads showing " .. n
local Y for _, t in ipairs(workspace:GetChildren()) do if t.Name == "tycoon" then Y = t break end end
CTX = SERVER Y.BackyardPads:GetChildren()[1].Touched:_fire(p.Character.Torso) runFor(1)
out[#out+1] = "touching a pad without owning: " .. p.PlayerGui.BackyardUI.Toast.Text .. " | cash " .. p.leaderstats.Cash.Value .. " | items " .. #Y.BackyardItems:GetChildren()
return out
