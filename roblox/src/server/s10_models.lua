-- ==== s10_models.lua
------------------------------------------------------------------ people
local SKIN = { "Nougat", "Light orange", "Brown", "Reddish brown", "Pastel brown", "Brick yellow" }
local SHIRT = { "Bright red", "Bright blue", "Bright green", "Bright yellow", "Bright orange", "Royal purple", "Hot pink",
	"Cyan", "Institutional white", "Really black", "Teal", "Sand blue", "Lime green", "Pastel light blue" }
local PANTS = { "Navy blue", "Really black", "Dark stone grey", "Brown", "Sand blue", "Medium stone grey" }
local BAGS = { "Bright red", "Really black", "Bright blue", "Royal purple", "Bright orange", "Lime green", "Hot pink" }

-- a Roblox-style character standing at feet CFrame `cf` (facing -z): separate arms and legs, the classic head
-- mesh and face. look = { shirt, pants, skin, arms, hat, hatColor, bag, tie, clipboard, mop }. Returns model, root.
function M.person(parent, cf, look, name)
	look = look or {}
	local m = Instance.new("Model")
	m.Name = name or "Person"
	local b = { model = m, cf = cf }
	local shirt, pants, skin = look.shirt or U.pick(SHIRT), look.pants or U.pick(PANTS), look.skin or U.pick(SKIN)
	local arms = look.arms or shirt
	U.P(b, "Left Leg", Vector3.new(1, 2, 1), U.L(-0.5, 1, 0), pants)
	U.P(b, "Right Leg", Vector3.new(1, 2, 1), U.L(0.5, 1, 0), pants)
	-- an invisible root carries the body (walkers move it); the visible torso is welded to it like the limbs
	local root = U.P(b, "Root", Vector3.new(2, 2, 1), U.L(0, 3, 0), shirt, nil, { tr = 1, nc = true })
	U.P(b, "Body", Vector3.new(2, 2, 1), U.L(0, 3, 0), shirt)
	U.P(b, "Left Arm", Vector3.new(1, 2, 1), U.L(-1.5, 3, 0), arms)
	U.P(b, "Right Arm", Vector3.new(1, 2, 1), U.L(1.5, 3, 0), arms)
	local head = U.P(b, "Head", Vector3.new(2, 1, 1), U.L(0, 4.5, 0), skin)
	local mesh = Instance.new("SpecialMesh")
	pcall(function() mesh.MeshType = Enum.MeshType.Head end)
	mesh.Scale = Vector3.new(1.25, 1.25, 1.25)
	mesh.Parent = head
	local face = Instance.new("Decal")
	face.Name = "face"
	face.Texture = "rbxasset://textures/face.png"
	pcall(function() face.Face = Enum.NormalId.Front end)
	face.Parent = head
	if look.hat == "cap" then
		U.P(b, "Hat", Vector3.new(1.5, 0.4, 1.5), U.L(0, 5.25, 0), look.hatColor or shirt)
		U.P(b, "Brim", Vector3.new(1.4, 0.15, 0.7), U.L(0, 5.1, -0.95), look.hatColor or shirt)
	elseif look.hat == "chef" then
		U.P(b, "Hat", Vector3.new(1.3, 1.4, 1.3), U.L(0, 5.8, 0), "Institutional white")
	elseif look.hat == "helmet" then
		U.P(b, "Hat", Vector3.new(1.6, 0.7, 1.6), U.L(0, 5.35, 0), look.hatColor or "Bright yellow")
	elseif look.hat == "hair" then
		local hair = U.pick({ "Brown", "Really black", "Bright yellow", "Reddish brown", "Bright orange" })
		U.P(b, "Hair", Vector3.new(1.5, 0.45, 1.45), U.L(0, 5.2, 0.05), hair)
		if math.random() < 0.5 then U.P(b, "Hair", Vector3.new(1.5, 1.1, 0.4), U.L(0, 4.7, 0.6), hair) end
	elseif look.hat == "bun" then
		U.P(b, "Hair", Vector3.new(1.5, 0.45, 1.45), U.L(0, 5.2, 0.05), look.hatColor or "Brown")
		U.P(b, "Bun", Vector3.new(0.8, 0.8, 0.8), U.L(0, 5.4, 0.7), look.hatColor or "Brown", nil, { shape = "ball" })
	end
	if look.tie then U.P(b, "Tie", Vector3.new(0.3, 1.4, 0.05), U.L(0, 3.2, -0.53), look.tie) end
	if look.bag then
		U.P(b, "Bag", Vector3.new(1.2, 1.6, 0.6), U.L(2.6, 0.9, 0.2), look.bag)
		U.P(b, "Handle", Vector3.new(0.2, 1.2, 0.2), U.L(2.6, 2.2, 0.2), "Dark stone grey")
	end
	if look.clipboard then U.P(b, "Clipboard", Vector3.new(1, 1.3, 0.2), U.L(1.6, 3.2, -0.8, 0, -30), "Brown") end
	if look.mop then
		U.P(b, "Mop", Vector3.new(0.2, 5, 0.2), U.L(2.1, 2.5, -0.5, 0, 0, 10), "Brown")
		U.P(b, "MopHead", Vector3.new(1.2, 0.4, 0.8), U.L(2.5, 0.2, -0.5), "Light stone grey")
	end
	m.Parent = parent
	return m, root
end

-- after U.rig(model, root): remember the limb welds so walkers can swing their arms and legs
local LIMBS = { ["Left Leg"] = { -0.5, -1, 1 }, ["Right Leg"] = { 0.5, -1, -1 }, ["Left Arm"] = { -1.5, 0.5, -0.8 }, ["Right Arm"] = { 1.5, 0.5, 0.8 } }
function M.limbs(root)
	local out = {}
	for _, w in ipairs(root:GetChildren()) do
		local d = w:IsA("Weld") and w.Part1 and LIMBS[w.Part1.Name]
		if d then table.insert(out, { weld = w, x = d[1], y = d[2], k = d[3] }) end
	end
	return out
end
-- a = swing angle (radians); legs and opposite arms swing the other way
function M.pose(limbs, a)
	for _, l in ipairs(limbs) do
		l.weld.C0 = CFrame.new(l.x, l.y, 0) * CFrame.Angles(a * l.k, 0, 0) * CFrame.new(0, l.y < 0 and -1 or -0.5, 0)
	end
end

function M.passengerLook()
	local r = math.random()
	local skin = U.pick(SKIN)
	return { shirt = U.pick(SHIRT), pants = U.pick(PANTS), skin = skin,
		arms = math.random() < 0.4 and skin or nil,   -- t-shirt: bare arms
		hat = r < 0.3 and "hair" or (r < 0.45 and "bun" or (r < 0.6 and "cap" or nil)),
		hatColor = U.pick(r < 0.45 and { "Brown", "Really black", "Bright yellow", "Reddish brown" } or SHIRT),
		bag = math.random() < 0.8 and U.pick(BAGS) or nil }
end

------------------------------------------------------------------ an airliner (NPC). cf = centre of the body; nose points -z.
-- lowest point (wheels) is 7 studs below the centre. Returns model, root (anchored; the rest is welded to it).
function M.airliner(parent, cf, tail, name, cargo)
	local m = Instance.new("Model")
	m.Name = name or "Airliner"
	local b = { model = m, cf = cf }
	-- an invisible, unrotated root: moving it moves the plane (the body cylinder itself is turned 90 degrees)
	local root = U.P(b, "Root", Vector3.new(1, 1, 1), U.L(0, 0, 0), "Institutional white", nil, { tr = 1, nc = true })
	U.P(b, "Body", Vector3.new(50, 7, 7), U.L(0, 0, 0, 90), "Institutional white", "SmoothPlastic", { shape = "cyl" })
	U.P(b, "Nose", Vector3.new(7, 7, 7), U.L(0, 0, -25), "Institutional white", "SmoothPlastic", { shape = "ball" })
	U.P(b, "TailCone", Vector3.new(6.6, 6.6, 6.6), U.L(0, 0.3, 25), "Institutional white", "SmoothPlastic", { shape = "ball" })
	U.P(b, "Cockpit", Vector3.new(4, 1.2, 1.4), U.L(0, 1.6, -27.4, 0, -25), "Really black", "Glass")
	for _, x in ipairs({ -1, 1 }) do
		if not cargo then U.P(b, "Windows", Vector3.new(0.2, 0.9, 40), U.L(3.52 * x, 1.1, -1), "Really black", "SmoothPlastic") end
		U.P(b, "Stripe", Vector3.new(0.2, 1, 46), U.L(3.5 * x, -0.6, 0), tail, "SmoothPlastic")
		U.P(b, "Wing", Vector3.new(20, 0.9, 9), U.L(12.5 * x, -1.8, 4, -18 * x), "Light stone grey", "SmoothPlastic")
		U.P(b, "Engine", Vector3.new(7, 3.6, 3.6), U.L(9 * x, -4, 0, 90), "Light stone grey", "Metal", { shape = "cyl" })
		U.P(b, "EngineFront", Vector3.new(0.4, 3, 3), U.L(9 * x, -4, -3.6, 90), tail, "Metal", { shape = "cyl" })
		U.P(b, "Gear", Vector3.new(1.4, 2, 2), U.L(3 * x, -6, 4, 0, 0, 90), "Really black", nil, { shape = "cyl" })
	end
	U.P(b, "Gear", Vector3.new(1.4, 2, 2), U.L(0, -6, -18, 0, 0, 90), "Really black", nil, { shape = "cyl" })
	U.P(b, "Stabiliser", Vector3.new(16, 0.8, 5), U.L(0, 0.8, 26.5), "Light stone grey", "SmoothPlastic")
	U.P(b, "Fin", Vector3.new(0.8, 10, 9), U.L(0, 8, 25.5), tail, "SmoothPlastic", { class = "WedgePart" })
	if cargo then
		U.P(b, "CargoDoor", Vector3.new(0.3, 4, 8), U.L(-3.55, 0.5, -12), tail, "SmoothPlastic")
		U.P(b, "Hump", Vector3.new(5, 2.4, 14), U.L(0, 3.4, -16), "Institutional white", "SmoothPlastic")
	end
	U.rig(m, root, false)
	m.Parent = parent
	return m, root
end

------------------------------------------------------------------ planes you can fly. cf = body centre, nose -z.
-- every part is welded to the body; the body gets a BodyGyro + BodyVelocity (FLY drives them).
local PLANES = {
	small = { name = "Small Plane", max = 110, takeoff = 45, accel = 26, turn = 55, lift = 3.4 },
	jet = { name = "Fighter Jet", max = 230, takeoff = 60, accel = 48, turn = 75, lift = 3.2 },
	private = { name = "Private Jet", max = 280, takeoff = 60, accel = 52, turn = 60, lift = 3.6 },
}
FLY.TYPES = PLANES

function M.flyable(parent, kind, cf, color, owner)
	local m = Instance.new("Model")
	m.Name = (owner and (owner.Name .. "'s ") or "") .. PLANES[kind].name
	local b = { model = m, cf = cf }
	local body, wheels = nil, {}
	if kind == "small" then
		body = U.P(b, "Body", Vector3.new(3.2, 3.2, 14), U.L(0, 0, 0), "Institutional white", "SmoothPlastic")
		U.P(b, "Nose", Vector3.new(2.6, 2.6, 1.6), U.L(0, 0, -7.7), color)
		U.P(b, "Spinner", Vector3.new(1.2, 1.2, 1.2), U.L(0, 0, -8.7), "Light stone grey", "Metal", { shape = "ball" })
		U.P(b, "Propeller", Vector3.new(0.3, 7, 0.4), U.L(0, 0, -9), "Really black")
		U.P(b, "Glass", Vector3.new(2.8, 1.6, 4), U.L(0, 2.3, -2), "Pastel light blue", "Glass", { tr = 0.4 })
		U.P(b, "Wing", Vector3.new(22, 0.5, 4), U.L(0, 1.5, -1), color)
		U.P(b, "Fin", Vector3.new(0.4, 3.4, 3), U.L(0, 2.8, 6), color)
		U.P(b, "Stabiliser", Vector3.new(8, 0.4, 2.4), U.L(0, 0.6, 6.4), color)
		for _, w in ipairs({ { -1.9, -1 }, { 1.9, -1 }, { 0, -5.6 } }) do
			table.insert(wheels, U.P(b, "Wheel", Vector3.new(0.8, 1.6, 1.6), U.L(w[1], -2.4, w[2]), "Really black", nil, { shape = "cyl" }))
			U.P(b, "Strut", Vector3.new(0.2, 1.4, 0.2), U.L(w[1], -1.6, w[2]), "Dark stone grey")
		end
	elseif kind == "jet" then
		body = U.P(b, "Body", Vector3.new(3, 3, 18), U.L(0, 0, 0), "Medium stone grey", "Metal")
		U.P(b, "Nose", Vector3.new(3, 3, 6), U.L(0, 0, -12), "Medium stone grey", "Metal", { class = "WedgePart" })
		U.P(b, "Glass", Vector3.new(2.4, 1.6, 5), U.L(0, 2, -4), "Really black", "Glass", { tr = 0.25 })
		U.P(b, "WingL", Vector3.new(10, 0.5, 6), U.L(-5.5, -0.2, 3, 32), "Medium stone grey", "Metal")
		U.P(b, "WingR", Vector3.new(10, 0.5, 6), U.L(5.5, -0.2, 3, -32), "Medium stone grey", "Metal")
		U.P(b, "FinL", Vector3.new(0.4, 4, 4), U.L(-1.2, 3, 8, 0, 0, -12), color, "Metal", { class = "WedgePart" })
		U.P(b, "FinR", Vector3.new(0.4, 4, 4), U.L(1.2, 3, 8, 0, 0, 12), color, "Metal", { class = "WedgePart" })
		U.P(b, "Exhaust", Vector3.new(1, 2.4, 2.4), U.L(0, 0, 9.5, 90), "Neon orange", "Neon", { shape = "cyl" })
		U.P(b, "Stripe", Vector3.new(3.05, 0.6, 12), U.L(0, 0.6, 1), color, "Metal")
		for _, w in ipairs({ { -1.6, 1 }, { 1.6, 1 }, { 0, -6 } }) do
			table.insert(wheels, U.P(b, "Wheel", Vector3.new(0.8, 1.4, 1.4), U.L(w[1], -2.2, w[2]), "Really black", nil, { shape = "cyl" }))
		end
	else -- private jet
		body = U.P(b, "Body", Vector3.new(3.6, 3.6, 20), U.L(0, 0, 0), "Institutional white", "SmoothPlastic")
		U.P(b, "Nose", Vector3.new(3.6, 3.6, 3.6), U.L(0, 0, -10), "Institutional white", "SmoothPlastic", { shape = "ball" })
		U.P(b, "Glass", Vector3.new(3, 1.2, 2.4), U.L(0, 1.4, -10.4, 0, -20), "Really black", "Glass")
		U.P(b, "Windows", Vector3.new(3.65, 0.7, 12), U.L(0, 0.8, -1), "Really black", "SmoothPlastic")
		U.P(b, "GoldStripe", Vector3.new(3.65, 0.5, 18), U.L(0, -0.4, 0), "Gold", "Metal", { refl = 0.3 })
		U.P(b, "WingL", Vector3.new(11, 0.5, 4), U.L(-6.5, -1.2, 1.5, 15), "Institutional white", "SmoothPlastic")
		U.P(b, "WingR", Vector3.new(11, 0.5, 4), U.L(6.5, -1.2, 1.5, -15), "Institutional white", "SmoothPlastic")
		U.P(b, "EngineL", Vector3.new(4, 1.8, 1.8), U.L(-2.8, 0.8, 7, 90), color, "Metal", { shape = "cyl" })
		U.P(b, "EngineR", Vector3.new(4, 1.8, 1.8), U.L(2.8, 0.8, 7, 90), color, "Metal", { shape = "cyl" })
		U.P(b, "Fin", Vector3.new(0.4, 5, 4), U.L(0, 4, 9), color, "SmoothPlastic", { class = "WedgePart" })
		U.P(b, "TTail", Vector3.new(7, 0.4, 2), U.L(0, 6.4, 10), "Gold", "Metal", { refl = 0.3 })
		for _, w in ipairs({ { -1.8, 1 }, { 1.8, 1 }, { 0, -7 } }) do
			table.insert(wheels, U.P(b, "Wheel", Vector3.new(0.8, 1.6, 1.6), U.L(w[1], -2.6, w[2]), "Really black", nil, { shape = "cyl" }))
		end
	end
	local seat = U.P(b, "PilotSeat", Vector3.new(2, 1, 2), U.L(0, kind == "small" and 2 or 1.9, kind == "private" and -7 or -2), "Really black", "Fabric", { class = "VehicleSeat" })
	pcall(function() seat.MaxSpeed = 0 seat.Torque = 0 seat.HeadsUpDisplay = false end)
	-- everything welded to the body; only the body and wheels touch the ground
	for _, p in ipairs(m:GetChildren()) do
		if p:IsA("BasePart") then
			p.Anchored = false
			p.CanCollide = (p == body)
			if p ~= body then U.weld(body, p) end
		end
	end
	for _, w in ipairs(wheels) do w.CanCollide = true w.Friction = 0.05 end
	local gyro = Instance.new("BodyGyro")
	gyro.maxTorque = Vector3.new(4e6, 4e6, 4e6)
	gyro.P = 2e4
	gyro.D = 1500
	gyro.cframe = cf
	gyro.Parent = body
	local vel = Instance.new("BodyVelocity")
	vel.maxForce = Vector3.new(4e6, 0, 4e6)
	vel.velocity = Vector3.new(0, 0, 0)
	vel.P = 1e4
	vel.Parent = body
	m.Parent = parent
	return m, body, seat, gyro, vel
end
