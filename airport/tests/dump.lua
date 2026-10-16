-- writes every part of Airport1 (and the map around it) to $OUT: name|class|pos|size|right|up|look|color|transparency|shape
local rows = {}
local function shapeOf(p) local ok, s = pcall(function() return p.Shape.Name end) return ok and s or "Block" end
local function add(p, tag)
	local cf = p.CFrame
	local c = p.BrickColor.Color
	local r, u, l = cf.rightVector, cf.upVector, cf.lookVector
	rows[#rows + 1] = string.format("%s|%s|%s|%.2f %.2f %.2f|%.2f %.2f %.2f|%.3f %.3f %.3f|%.3f %.3f %.3f|%.3f %.3f %.3f|%d %d %d|%.2f|%s|%s",
		tag, p.Name, p.ClassName, cf.p.x, cf.p.y, cf.p.z, p.Size.x, p.Size.y, p.Size.z, r.x, r.y, r.z, u.x, u.y, u.z, l.x, l.y, l.z,
		c.r * 255, c.g * 255, c.b * 255, p.Transparency, shapeOf(p), tostring(p.BrickColor.Name))
end
local function walk(o, tag)
	for _, c in ipairs(o:GetChildren()) do
		if c:IsA("BasePart") then add(c, tag) end
		walk(c, tag)
	end
end
walk(workspace.Airport1, "plot")
walk(workspace.AirportMap, "map")
walk(workspace.SkyTraffic, "sky")
local f = io.open(os.getenv("OUT"), "w") f:write(table.concat(rows, "\n")) f:close()
return { "dumped " .. #rows }
