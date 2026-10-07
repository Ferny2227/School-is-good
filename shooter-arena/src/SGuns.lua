-- SGuns (ModuleScript)
-- Location: ServerScriptService > SGuns
-- Builds every gun as a Tool out of plain parts.
--   G.tool(def) -> Tool
-- The gun points along -Z of its Handle (the default tool grip holds it pointing forward).
-- Every Tool carries its numbers in a folder called "Stats" (the GunClient LocalScript reads them),
-- plus "Ammo" and "Reserve" NumberValues and a "Reloading" BoolValue that the server keeps up to date.
-- Plain 2016-style Lua.

local G = {}

local function setMat(p, name)
	if name then
		pcall(function()
			p.Material = Enum.Material[name]
		end)
	end
end

local function A(x, y, z)
	return CFrame.Angles(x or 0, y or 0, z or 0)
end

-- one look per gun style: body = receiver size, barrel = {length, thickness}, plus extras
local LOOKS = {
	pistol = { body = Vector3.new(0.32, 0.42, 1.15), barrel = { 0.25, 0.18 }, grip = 0.25, gripLen = 0.75 },
	deagle = { body = Vector3.new(0.38, 0.55, 1.45), barrel = { 0.35, 0.22 }, grip = 0.22, gripLen = 0.8 },
	revolver = { body = Vector3.new(0.32, 0.45, 0.75), barrel = { 1.0, 0.2 }, grip = 0.35, gripLen = 0.8, drum = true },
	rpg = { body = Vector3.new(0.55, 0.55, 3.6), barrel = { 0.3, 0.5 }, grip = 0.05, gripLen = 0.7, rocket = true },
	smg = { body = Vector3.new(0.38, 0.55, 1.6), barrel = { 0.55, 0.18 }, grip = 0.15, gripLen = 0.7, mag = { 0.25, 1.0, 0.4, -0.35, 0 }, stock = 0.6 },
	uzi = { body = Vector3.new(0.4, 0.65, 1.15), barrel = { 0.3, 0.18 }, grip = 0.05, gripLen = 1.1, gripMag = true },
	p90 = { body = Vector3.new(0.55, 0.8, 2.0), barrel = { 0.3, 0.2 }, grip = -0.1, gripLen = 0.7, topMag = true },
	rifle = { body = Vector3.new(0.38, 0.62, 2.1), barrel = { 1.3, 0.16 }, grip = 0.25, gripLen = 0.75, mag = { 0.28, 1.1, 0.5, -0.3, 0.2 }, stock = 1.0, rail = true },
	ak = { body = Vector3.new(0.38, 0.62, 2.1), barrel = { 1.3, 0.16 }, grip = 0.25, gripLen = 0.75, mag = { 0.28, 1.15, 0.5, -0.3, 0.45 }, stock = 1.1, wood = true },
	famas = { body = Vector3.new(0.42, 0.72, 2.4), barrel = { 0.7, 0.16 }, grip = -0.15, gripLen = 0.75, mag = { 0.28, 0.9, 0.5, 0.8, 0 }, carry = true },
	shotgun = { body = Vector3.new(0.36, 0.5, 1.5), barrel = { 2.1, 0.22 }, grip = 0.3, gripLen = 0.7, pump = true, stock = 1.2, wood = true },
	autoshotgun = { body = Vector3.new(0.48, 0.68, 1.9), barrel = { 1.2, 0.25 }, grip = 0.2, gripLen = 0.75, drumMag = true, stock = 0.9 },
	dmr = { body = Vector3.new(0.38, 0.6, 2.2), barrel = { 1.9, 0.15 }, grip = 0.3, gripLen = 0.75, mag = { 0.28, 0.7, 0.45, -0.3, 0 }, stock = 1.2, scope = 1.1, wood = true },
	sniper = { body = Vector3.new(0.38, 0.55, 2.5), barrel = { 2.5, 0.14 }, grip = 0.35, gripLen = 0.75, mag = { 0.28, 0.5, 0.4, -0.3, 0 }, stock = 1.4, scope = 1.7, bipod = true },
	barrett = { body = Vector3.new(0.5, 0.8, 3.0), barrel = { 2.8, 0.26 }, grip = 0.3, gripLen = 0.8, mag = { 0.35, 0.7, 0.6, -0.4, 0 }, stock = 1.3, scope = 1.8, bipod = true, brake = true },
	lmg = { body = Vector3.new(0.5, 0.75, 2.3), barrel = { 1.8, 0.24 }, grip = 0.3, gripLen = 0.75, boxMag = true, stock = 1.0, bipod = true, carry = true },
	minigun = { body = Vector3.new(0.9, 0.9, 1.5), barrel = { 3.0, 0.16 }, grip = 0.6, gripLen = 0.6, minigun = true },
	knife = { body = Vector3.new(0.18, 0.32, 0.75), knife = true },
}

function G.tool(def)
	local look = LOOKS[def.look] or LOOKS.rifle
	local tool = Instance.new("Tool")
	tool.Name = def.name
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.ToolTip = def.name

	local origin = CFrame.new(0, 300, 0)
	local parts = {}
	local function part(name, size, cf, color, mat, shape)
		local p = Instance.new("Part")
		p.Name = name
		pcall(function()
			p.FormFactor = Enum.FormFactor.Custom
		end)
		p.Size = size
		p.BrickColor = BrickColor.new(color)
		p.CanCollide = false
		p.Anchored = false
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		setMat(p, mat or "SmoothPlastic")
		if shape == "ball" then
			p.Shape = Enum.PartType.Ball
		elseif shape == "cyl" then
			p.Shape = Enum.PartType.Cylinder
		elseif shape == "egg" then
			local m = Instance.new("SpecialMesh")
			m.MeshType = Enum.MeshType.Sphere
			m.Parent = p
		end
		if mat == "Metal" then
			p.Reflectance = 0.06
		end
		p.CFrame = origin * cf
		p.Parent = tool
		table.insert(parts, p)
		return p
	end
	-- a cylinder along the gun (Z): a cylinder part runs along X, so turn it
	local function tube(name, len, d, cf, color, mat)
		return part(name, Vector3.new(len, d, d), cf * A(0, math.pi / 2, 0), color, mat, "cyl")
	end

	local c1, c2 = def.c1, def.c2
	local metal = "Metal"
	local body = look.body
	local L = body.Z
	local handle = part("Handle", body, CFrame.new(), c1, metal)
	local front = -L / 2 -- z of the front of the body
	local muzzleZ = front

	if look.knife then
		local blade = part("Blade", Vector3.new(0.06, 0.3, 1.3), CFrame.new(0, 0.05, -1.0), "Light stone grey", "Metal")
		blade.Reflectance = 0.35
		local tip = part("Tip", Vector3.new(0.06, 0.3, 0.4), CFrame.new(0, 0.05, -1.85) * A(math.pi, 0, 0), "Light stone grey", "Metal", nil)
		tip.Reflectance = 0.35
		part("Edge", Vector3.new(0.065, 0.05, 1.3), CFrame.new(0, -0.08, -1.0), "Institutional white", "Metal")
		for i = 0, 4 do
			part("Serrations", Vector3.new(0.07, 0.06, 0.06), CFrame.new(0, 0.22, -0.55 - i * 0.12) * A(0.7, 0, 0), "Dark stone grey", "Metal")
		end
		part("Fuller", Vector3.new(0.07, 0.05, 0.9), CFrame.new(0, 0.1, -1.0), "Dark stone grey", "Metal")
		part("Guard", Vector3.new(0.3, 0.55, 0.1), CFrame.new(0, 0, -0.4), "Dark stone grey", "Metal")
		for i = 0, 2 do
			part("FingerGroove", Vector3.new(0.2, 0.36, 0.06), CFrame.new(0, 0, -0.2 + i * 0.2), "Dark stone grey", "Fabric")
		end
		part("Pommel", Vector3.new(0.22, 0.38, 0.12), CFrame.new(0, 0, 0.42), "Dark stone grey", "Metal")
		handle.BrickColor = BrickColor.new("Really black")
		tool.GripPos = Vector3.new(0, 0, 0.1)
	else
		-- barrel
		if look.minigun then
			for i = 0, 5 do
				local a = i / 6 * math.pi * 2
				tube("Barrel", look.barrel[1], look.barrel[2], CFrame.new(math.cos(a) * 0.25, math.sin(a) * 0.25, front - look.barrel[1] / 2), "Dark stone grey", metal)
			end
			tube("BarrelRing", 0.2, 0.75, CFrame.new(0, 0, front - look.barrel[1] + 0.3), c2, metal)
			tube("BarrelRing", 0.2, 0.75, CFrame.new(0, 0, front - 0.4), c2, metal)
			part("TopHandle", Vector3.new(0.15, 0.5, 1.0), CFrame.new(0, 0.7, 0.1), c2, metal)
			part("AmmoBox", Vector3.new(0.7, 0.6, 0.8), CFrame.new(-0.7, -0.2, 0.2), "Earth green", metal)
			muzzleZ = front - look.barrel[1]
		elseif look.rocket then
			tube("Tube", L, 0.55, CFrame.new(), c1, metal)
			part("Warhead", Vector3.new(0.5, 0.5, 0.9), CFrame.new(0, 0, front - 0.4), c2, metal, "egg")
			part("WarheadTip", Vector3.new(0.25, 0.25, 0.5), CFrame.new(0, 0, front - 0.95), "Dark stone grey", metal, "egg")
			part("Sight", Vector3.new(0.12, 0.35, 0.3), CFrame.new(0, 0.42, -0.4), "Really black", metal)
			part("FrontGrip", Vector3.new(0.2, 0.6, 0.25), CFrame.new(0, -0.5, -0.6) * A(0.2, 0, 0), "Really black")
			muzzleZ = front - 1.1
		else
			local bl, bd = look.barrel[1], look.barrel[2]
			tube("Barrel", bl, bd, CFrame.new(0, 0.08, front - bl / 2), "Dark stone grey", metal)
			muzzleZ = front - bl
			if look.brake then
				part("MuzzleBrake", Vector3.new(0.45, 0.35, 0.45), CFrame.new(0, 0.08, muzzleZ - 0.2), c2, metal)
				muzzleZ = muzzleZ - 0.4
			end
			if look.pump then
				tube("PumpTube", bl * 0.8, 0.2, CFrame.new(0, -0.15, front - bl * 0.4), "Dark stone grey", metal)
				part("Pump", Vector3.new(0.34, 0.3, 0.8), CFrame.new(0, -0.15, front - 0.6), c2, "Wood")
			end
			if look.wood then
				part("Handguard", Vector3.new(0.42, 0.42, math.min(bl, 1.0)), CFrame.new(0, 0, front - math.min(bl, 1.0) / 2), c2, "Wood")
			end
		end
		-- pistol grip (where your hand is)
		local gz = L / 2 * look.grip
		local gl = look.gripLen or 0.75
		part("Grip", Vector3.new(body.X * 0.85, gl, 0.38), CFrame.new(0, -body.Y / 2 - gl / 2 + 0.08, gz) * A(-0.2, 0, 0), look.wood and c2 or "Really black", look.wood and "Wood" or nil)
		part("Trigger", Vector3.new(0.06, 0.2, 0.15), CFrame.new(0, -body.Y / 2 - 0.12, gz - 0.3), "Really black", metal)
		tool.GripPos = Vector3.new(0, -body.Y / 2 - gl * 0.45, gz)
		-- magazine
		if look.mag then
			local m = look.mag
			part("Mag", Vector3.new(m[1], m[2], m[3]), CFrame.new(0, -body.Y / 2 - m[2] / 2 + 0.1, m[4]) * A(m[5], 0, 0), "Really black", metal)
		end
		if look.gripMag then
			part("MagBase", Vector3.new(body.X * 0.9, 0.12, 0.42), CFrame.new(0, -body.Y / 2 - gl + 0.05, gz), "Dark stone grey", metal)
		end
		if look.topMag then
			part("TopMag", Vector3.new(0.4, 0.15, 1.4), CFrame.new(0, body.Y / 2 + 0.07, -0.1), "Institutional white", nil)
			part("Thumbhole", Vector3.new(body.X, 0.25, 0.5), CFrame.new(0, -0.3, 0.75), c2, nil)
		end
		if look.drumMag then
			tube("Drum", 0.45, 0.95, CFrame.new(0, -0.65, -0.2) * A(0, math.pi / 2, 0), "Really black", metal)
		end
		if look.boxMag then
			part("BoxMag", Vector3.new(0.6, 0.65, 0.7), CFrame.new(0.15, -0.6, -0.2), c2, metal)
		end
		if look.drum then
			tube("Cylinder", 0.5, 0.55, CFrame.new(0, 0, front + 0.25), "Dark stone grey", metal)
		end
		-- stock
		if look.stock then
			part("Stock", Vector3.new(body.X * 0.9, body.Y * 0.8, look.stock), CFrame.new(0, -0.05, L / 2 + look.stock / 2), look.wood and c2 or c1, look.wood and "Wood" or nil)
			part("ButtPad", Vector3.new(body.X, body.Y * 0.95, 0.12), CFrame.new(0, -0.07, L / 2 + look.stock + 0.05), "Really black", nil)
		end
		-- sights / scope / carry handle / rail / bipod
		if look.scope then
			tube("Scope", look.scope, 0.32, CFrame.new(0, body.Y / 2 + 0.3, -0.1), "Really black", metal)
			tube("ScopeLens", 0.06, 0.4, CFrame.new(0, body.Y / 2 + 0.3, -0.1 - look.scope / 2), "Cyan", "Neon")
			part("ScopeMount", Vector3.new(0.15, 0.25, 0.5), CFrame.new(0, body.Y / 2 + 0.1, -0.1), "Dark stone grey", metal)
		elseif look.carry then
			part("CarryHandle", Vector3.new(0.12, 0.25, L * 0.6), CFrame.new(0, body.Y / 2 + 0.2, 0), c2, metal)
		elseif look.rail then
			part("Rail", Vector3.new(0.2, 0.1, L * 0.8), CFrame.new(0, body.Y / 2 + 0.05, 0), "Dark stone grey", metal)
			part("RedDot", Vector3.new(0.22, 0.25, 0.3), CFrame.new(0, body.Y / 2 + 0.2, -0.2), "Really black", metal)
			part("RedDotLens", Vector3.new(0.14, 0.14, 0.02), CFrame.new(0, body.Y / 2 + 0.22, -0.36), "Really red", "Neon")
		else
			part("FrontSight", Vector3.new(0.06, 0.12, 0.08), CFrame.new(0, body.Y / 2 + 0.06, front + 0.1), "Really black", metal)
		end
		if look.bipod then
			for _, sx in ipairs({ -1, 1 }) do
				part("Bipod", Vector3.new(0.06, 0.7, 0.06), CFrame.new(sx * 0.15, -0.35, front - 0.3) * A(0.4, 0, sx * 0.3), "Dark stone grey", metal)
				part("BipodFoot", Vector3.new(0.12, 0.06, 0.12), CFrame.new(sx * 0.27, -0.68, front - 0.42), "Really black", metal)
			end
		end

		-- DETAILS (v2): the small parts that make a gun look real
		local pistolish = def.look == "pistol" or def.look == "deagle" or def.look == "revolver"
		local dark, black = "Dark stone grey", "Really black"
		-- trigger guard
		part("TriggerGuard", Vector3.new(body.X * 0.45, 0.06, 0.55), CFrame.new(0, -body.Y / 2 - 0.34, gz - 0.32), black, metal)
		part("TriggerGuard", Vector3.new(body.X * 0.45, 0.32, 0.06), CFrame.new(0, -body.Y / 2 - 0.18, gz - 0.6), black, metal)
		if pistolish then
			-- slide on top (two-tone), serrations at the back, hammer, sights
			part("Slide", Vector3.new(body.X * 1.04, body.Y * 0.5, L * 1.02), CFrame.new(0, body.Y * 0.27, 0), c2 == "Gold" and "Gold" or c1, metal)
			for i = 0, 4 do
				part("Serration", Vector3.new(body.X * 1.08, body.Y * 0.4, 0.03), CFrame.new(0, body.Y * 0.27, L / 2 - 0.08 - i * 0.07), black, metal)
			end
			part("Hammer", Vector3.new(0.1, 0.18, 0.12), CFrame.new(0, body.Y / 2 + 0.02, L / 2 + 0.05) * A(-0.5, 0, 0), black, metal)
			part("RearSight", Vector3.new(body.X * 0.8, 0.08, 0.08), CFrame.new(0, body.Y / 2 + 0.06, L / 2 - 0.1), black, metal)
			part("EjectPort", Vector3.new(0.04, body.Y * 0.25, L * 0.25), CFrame.new(body.X * 0.53, body.Y * 0.3, -L * 0.05), black, metal)
			part("GripPanel", Vector3.new(body.X * 0.95, gl * 0.7, 0.3), CFrame.new(0, -body.Y / 2 - gl / 2 + 0.05, gz) * A(-0.2, 0, 0), c2 == "Gold" and "Brown" or dark, "Wood")
		elseif look.rocket then
			-- RPG: warhead fins, rear cone, grip wrap, optic
			for i = 0, 3 do
				part("Fin", Vector3.new(0.04, 0.35, 0.3), CFrame.new(0, 0, front - 0.05) * A(0, 0, i * math.pi / 2) * CFrame.new(0, 0.3, 0), "Dark stone grey", metal)
			end
			tube("RearCone", 0.5, 0.75, CFrame.new(0, 0, L / 2 + 0.2), "Really black", metal)
			tube("HeatShield", 1.0, 0.62, CFrame.new(0, 0, -0.1), "Brown", "Wood")
			part("Optic", Vector3.new(0.18, 0.25, 0.6), CFrame.new(-0.35, 0.3, 0.1), "Really black", metal)
			tube("OpticLens", 0.04, 0.16, CFrame.new(-0.35, 0.33, -0.21), "Cyan", "Neon")
		else
			-- receiver details
			part("EjectPort", Vector3.new(0.04, body.Y * 0.3, L * 0.18), CFrame.new(body.X * 0.52, body.Y * 0.08, -L * 0.04), black, metal)
			part("ChargingHandle", Vector3.new(0.3, 0.08, 0.12), CFrame.new(0, body.Y / 2 + 0.04, L * 0.42), black, metal)
			part("Selector", Vector3.new(0.04, 0.1, 0.1), CFrame.new(-body.X * 0.52, -body.Y * 0.15, gz), "Bright red", metal)
			part("BoltRelease", Vector3.new(0.04, 0.14, 0.2), CFrame.new(-body.X * 0.52, 0, gz - 0.35), dark, metal)
			-- seam line along the receiver
			part("Seam", Vector3.new(body.X * 1.02, 0.03, L * 0.95), CFrame.new(0, -body.Y * 0.05, 0), black, metal)
			-- muzzle device (flash hider)
			if not look.minigun and not look.brake then
				tube("FlashHider", 0.3, look.barrel[2] * 1.9, CFrame.new(0, 0.08, muzzleZ - 0.12), black, metal)
				for _, sx in ipairs({ -1, 1 }) do
					part("FlashSlot", Vector3.new(0.02, 0.03, 0.22), CFrame.new(sx * look.barrel[2] * 0.95, 0.08, muzzleZ - 0.12), dark, metal)
				end
			end
			-- top rail ribs (for scopes / red dots / carry handles)
			if look.rail or look.scope or look.carry or def.look == "smg" or def.look == "lmg" then
				local n = math.floor(L * 0.7 / 0.18)
				for i = 0, n - 1 do
					part("RailRib", Vector3.new(0.24, 0.05, 0.08), CFrame.new(0, body.Y / 2 + 0.03, -L * 0.35 + i * 0.18), dark, metal)
				end
			end
			-- handguard vents (rifles)
			if (def.look == "rifle" or def.look == "dmr" or def.look == "lmg" or def.look == "famas") then
				for i = 0, 3 do
					for _, sx in ipairs({ -1, 1 }) do
						part("Vent", Vector3.new(0.03, 0.09, 0.25), CFrame.new(sx * body.X * 0.52, 0.05, front + 0.25 + i * 0.32), black, metal)
					end
				end
				-- front sight block
				part("FrontPost", Vector3.new(0.08, 0.35, 0.08), CFrame.new(0, 0.3, front - 0.45), black, metal)
			end
			-- magazine well + mag base + mag ribs
			if look.mag then
				local m = look.mag
				part("MagWell", Vector3.new(m[1] + 0.1, 0.22, m[3] + 0.12), CFrame.new(0, -body.Y / 2 - 0.08, m[4]) * A(m[5] * 0.3, 0, 0), c1, metal)
				part("MagBase", Vector3.new(m[1] + 0.06, 0.08, m[3] + 0.06), CFrame.new(0, -body.Y / 2 - m[2] + 0.12, m[4] + m[5] * m[2] * 0.5) * A(m[5], 0, 0), dark, metal)
				for i = 1, 2 do
					part("MagRib", Vector3.new(m[1] + 0.02, 0.03, m[3] + 0.02), CFrame.new(0, -body.Y / 2 - m[2] * (0.3 * i), m[4] + m[5] * m[2] * 0.3 * i) * A(m[5], 0, 0), dark, metal)
				end
			end
			-- stock: cheek rest, sling loop
			if look.stock then
				part("CheekRest", Vector3.new(body.X * 0.95, 0.14, look.stock * 0.6), CFrame.new(0, body.Y * 0.38, L / 2 + look.stock * 0.45), look.wood and c2 or dark, look.wood and "Wood" or nil)
				part("SlingLoop", Vector3.new(0.05, 0.18, 0.18), CFrame.new(0, -body.Y * 0.45, L / 2 + look.stock * 0.8), dark, metal)
			end
			-- scope: rings, turrets, bigger front lens, eyepiece
			if look.scope then
				local sy = body.Y / 2 + 0.3
				for _, z in ipairs({ -0.1 - look.scope * 0.3, -0.1 + look.scope * 0.3 }) do
					tube("ScopeRing", 0.12, 0.42, CFrame.new(0, sy, z), dark, metal)
				end
				tube("Objective", look.scope * 0.25, 0.45, CFrame.new(0, sy, -0.1 - look.scope / 2 + look.scope * 0.1), black, metal)
				tube("Eyepiece", 0.25, 0.38, CFrame.new(0, sy, -0.1 + look.scope / 2), black, metal)
				part("TurretTop", Vector3.new(0.2, 0.2, 0.2), CFrame.new(0, sy + 0.22, -0.1), dark, metal, "ball")
				part("TurretSide", Vector3.new(0.2, 0.2, 0.2), CFrame.new(0.22, sy, -0.1), dark, metal, "ball")
				tube("BackLens", 0.03, 0.3, CFrame.new(0, sy, -0.1 + look.scope / 2 + 0.13), "Cyan", "Neon")
			end
			-- pump-action ribs
			if look.pump then
				for i = 0, 3 do
					part("PumpRib", Vector3.new(0.36, 0.33, 0.04), CFrame.new(0, -0.15, front - 0.3 - i * 0.18), black, "Wood")
				end
				part("ShellHolder", Vector3.new(0.05, 0.3, 0.6), CFrame.new(-body.X * 0.55, 0, 0.1), black, "Fabric")
				for i = 0, 3 do
					part("Shell", Vector3.new(0.06, 0.24, 0.1), CFrame.new(-body.X * 0.6, 0, -0.12 + i * 0.15), "Really red", nil)
				end
			end
			-- LMG / minigun ammo belt
			if look.boxMag or look.minigun then
				for i = 0, 5 do
					part("AmmoLink", Vector3.new(0.12, 0.08, 0.2), CFrame.new(look.minigun and -0.35 or 0.15, look.minigun and -0.1 - i * 0.08 or -0.25 + i * 0.05, (look.minigun and 0.2 or -0.2) - i * 0.12), "Gold", metal)
				end
			end
			if look.minigun then
				part("Motor", Vector3.new(0.6, 0.6, 0.6), CFrame.new(0, 0, L / 2 + 0.3), dark, metal)
				tube("MotorCap", 0.2, 0.55, CFrame.new(0, 0, L / 2 + 0.65), black, metal)
				part("SideHandle", Vector3.new(0.12, 0.6, 0.12), CFrame.new(0.6, 0.1, 0.4), black, nil)
			end
		end
	end

	-- weld everything to the handle
	for _, p in ipairs(parts) do
		if p ~= handle then
			local w = Instance.new("Weld")
			w.Part0 = handle
			w.Part1 = p
			w.C0 = handle.CFrame:inverse() * p.CFrame
			w.Parent = handle
		end
	end
	-- muzzle flash light (the server turns it on for a moment when you shoot)
	local flash = Instance.new("PointLight")
	flash.Name = "Flash"
	flash.Range = 10
	flash.Brightness = 4
	flash.Color = Color3.new(1, 0.8, 0.4)
	flash.Enabled = false
	flash.Parent = handle

	-- the numbers the client needs
	local stats = Instance.new("Configuration")
	stats.Name = "Stats"
	local function num(n, v)
		local o = Instance.new("NumberValue")
		o.Name = n
		o.Value = v
		o.Parent = stats
	end
	local function flag(n, v)
		local o = Instance.new("BoolValue")
		o.Name = n
		o.Value = v and true or false
		o.Parent = stats
	end
	num("RPM", def.rpm)
	num("Burst", def.burst or 1)
	num("Mag", def.mag)
	num("Zoom", def.zoom or 60)
	num("Recoil", def.recoil or 1)
	num("Spread", def.spread or 2)
	num("AdsSpread", def.ads or 1)
	num("Walk", def.walk or 16)
	num("MuzzleZ", muzzleZ)
	flag("Auto", def.auto)
	flag("Scope", def.scope)
	flag("Melee", def.melee)
	local slot = Instance.new("StringValue")
	slot.Name = "Slot"
	slot.Value = def.slot
	slot.Parent = stats
	stats.Parent = tool

	local ammo = Instance.new("NumberValue")
	ammo.Name = "Ammo"
	ammo.Value = def.mag
	ammo.Parent = tool
	local reserve = Instance.new("NumberValue")
	reserve.Name = "Reserve"
	reserve.Value = def.reserve
	reserve.Parent = tool
	local reloading = Instance.new("BoolValue")
	reloading.Name = "Reloading"
	reloading.Value = false
	reloading.Parent = tool
	return tool
end

-- a frag grenade tool (click to throw)
function G.grenade(count)
	local tool = Instance.new("Tool")
	tool.Name = "Frag Grenade"
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	local h = Instance.new("Part")
	h.Name = "Handle"
	pcall(function()
		h.FormFactor = Enum.FormFactor.Custom
	end)
	h.Shape = Enum.PartType.Ball
	h.Size = Vector3.new(0.8, 0.8, 0.8)
	h.BrickColor = BrickColor.new("Earth green")
	h.CanCollide = false
	h.Parent = tool
	tool.GripPos = Vector3.new(0, 0, 0)
	local stats = Instance.new("Configuration")
	stats.Name = "Stats"
	local slot = Instance.new("StringValue")
	slot.Name = "Slot"
	slot.Value = "grenade"
	slot.Parent = stats
	stats.Parent = tool
	local ammo = Instance.new("NumberValue")
	ammo.Name = "Ammo"
	ammo.Value = count
	ammo.Parent = tool
	local reserve = Instance.new("NumberValue")
	reserve.Name = "Reserve"
	reserve.Value = 0
	reserve.Parent = tool
	return tool
end

return G
