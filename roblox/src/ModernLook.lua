-- ServerScriptService.ModernLook: makes the place look newer, using only what a 2016 game already has (no pictures):
--  * smooth surfaces everywhere (no studs and inlets: the biggest "old Roblox" look)
--  * no black outlines round every part, shadows on
--  * a little colour grading (contrast and colour), a soft glow on bright and neon things, and sun rays
-- Each effect is only made if this version of Roblox has it, so nothing breaks on an older one.
local pcall = ypcall or pcall
local Lighting = game:GetService("Lighting")
pcall(function() Lighting.Outlines = false end)
pcall(function() Lighting.GlobalShadows = true end)
local function effect(class, props)
	pcall(function()
		local e = Lighting:FindFirstChild("Modern" .. class) or Instance.new(class)
		e.Name = "Modern" .. class
		for k, v in pairs(props) do e[k] = v end
		e.Parent = Lighting
	end)
end
effect("ColorCorrectionEffect", { Brightness = 0.02, Contrast = 0.12, Saturation = 0.15, TintColor = Color3.new(1, 0.98, 0.96) })
effect("BloomEffect", { Intensity = 0.35, Size = 24, Threshold = 0.92 })
effect("SunRaysEffect", { Intensity = 0.05, Spread = 0.6 })

-- smooth every surface, now and for every part added later
local SIDES = { "TopSurface", "BottomSurface", "LeftSurface", "RightSurface", "FrontSurface", "BackSurface" }
local function smooth(p)
	if p:IsA("BasePart") then
		for _, side in ipairs(SIDES) do
			pcall(function() if p[side] ~= Enum.SurfaceType.Smooth then p[side] = Enum.SurfaceType.Smooth end end)
		end
	end
end
local function all(o)
	for _, c in ipairs(o:GetChildren()) do
		smooth(c)
		all(c)
	end
end
pcall(function() all(workspace) end)
workspace.DescendantAdded:connect(smooth)
