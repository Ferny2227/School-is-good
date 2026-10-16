------------------------------------------------------------------ people
local SKIN = { "Nougat", "Light orange", "Brown", "Reddish brown", "Pastel brown", "Brick yellow" }
local SHIRT = { "Bright red", "Bright blue", "Bright green", "Bright yellow", "Bright orange", "Royal purple", "Hot pink",
	"Cyan", "Institutional white", "Really black", "Teal", "Sand blue", "Lime green", "Pastel light blue" }
local PANTS = { "Navy blue", "Really black", "Dark stone grey", "Brown", "Sand blue", "Medium stone grey" }
local BAGS = { "Bright red", "Really black", "Bright blue", "Royal purple", "Bright orange", "Lime green", "Hot pink" }

-- a blocky person standing at feet CFrame `cf` (facing -z). look = { shirt, pants, skin, hat, hatColor, bag, extra }
-- returns model, torso
function M.person(parent, cf, look, name)
	look = look or {}
	local m = Instance.new("Model")
	m.Name = name or "Person"
	local b = { model = m, cf = cf }
	local shirt, pants, skin = look.shirt or U.pick(SHIRT), look.pants or U.pick(PANTS), look.skin or U.pick(SKIN)
	U.P(b, "Legs", Vector3.new(2, 2, 1), U.L(0, 1, 0), pants)
	local torso = U.P(b, "Torso", Vector3.new(2, 2, 1), U.L(0, 3, 0), shirt)
	U.P(b, "LeftArm", Vector3.new(1, 2, 1), U.L(-1.5, 3, 0), look.arms or shirt)
	U.P(b, "RightArm", Vector3.new(1, 2, 1), U.L(1.5, 3, 0), look.arms or shirt)
	U.P(b, "Head", Vector3.new(1.2, 1.2, 1.2), U.L(0, 4.6, 0), skin)
	U.P(b, "Eyes", Vector3.new(0.8, 0.2, 0.05), U.L(0, 4.75, -0.61), "Really black")
	if look.hat == "cap" then
		U.P(b, "Hat", Vector3.new(1.4, 0.4, 1.4), U.L(0, 5.4, 0), look.hatColor or shirt)
		U.P(b, "Brim", Vector3.new(1.3, 0.15, 0.6), U.L(0, 5.25, -0.9), look.hatColor or shirt)
	elseif look.hat == "chef" then
		U.P(b, "Hat", Vector3.new(1.2, 1.4, 1.2), U.L(0, 5.9, 0), "Institutional white")
	elseif look.hat == "helmet" then
		U.P(b, "Hat", Vector3.new(1.5, 0.7, 1.5), U.L(0, 5.5, 0), look.hatColor or "Bright yellow")
	elseif look.hat == "hair" then
		U.P(b, "Hair", Vector3.new(1.3, 0.5, 1.3), U.L(0, 5.35, 0.05), U.pick({ "Brown", "Really black", "Bright yellow", "Reddish brown", "Bright orange" }))
	end
	if look.tie then U.P(b, "Tie", Vector3.new(0.3, 1.4, 0.05), U.L(0, 3.2, -0.53), look.tie) end
	if look.bag then
		U.P(b, "Bag", Vector3.new(1.2, 1.6, 0.6), U.L(2.4, 0.9, 0.2), look.bag)
		U.P(b, "Handle", Vector3.new(0.2, 1.2, 0.2), U.L(2.4, 2.2, 0.2), "Dark stone grey")
	end
	if look.clipboard then U.P(b, "Clipboard", Vector3.new(1, 1.3, 0.2), U.L(1.6, 3.2, -0.7, 0, -30), "Brown") end
	if look.mop then
		U.P(b, "Mop", Vector3.new(0.2, 5, 0.2), U.L(1.9, 2.5, -0.4, 0, 0, 10), "Brown")
		U.P(b, "MopHead", Vector3.new(1.2, 0.4, 0.8), U.L(2.3, 0.2, -0.4), "Light stone grey")
	end
	m.Parent = parent
	return m, torso
end

function M.passengerLook()
	local r = math.random()
	return { shirt = U.pick(SHIRT), pants = U.pick(PANTS), skin = U.pick(SKIN),
		hat = r < 0.35 and "hair" or (r < 0.5 and "cap" or nil), hatColor = U.pick(SHIRT),
		bag = math.random() < 0.8 and U.pick(BAGS) or nil }
end

------------------------------------------------------------------ an airliner (NPC). cf = centre of the body; nose points -z.
-- lowest point (wheels) is 7 studs below the centre. Returns model, root (anchored; the rest is welded to it).
function M.airliner(parent, cf, tail, name)
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
		U.P(b, "Windows", Vector3.new(0.2, 0.9, 40), U.L(3.52 * x, 1.1, -1), "Really black", "SmoothPlastic")
		U.P(b, "Stripe", Vector3.new(0.2, 1, 46), U.L(3.5 * x, -0.6, 0), tail, "SmoothPlastic")
		U.P(b, "Wing", Vector3.new(20, 0.9, 9), U.L(12.5 * x, -1.8, 4, -18 * x), "Light stone grey", "SmoothPlastic")
		U.P(b, "Engine", Vector3.new(7, 3.6, 3.6), U.L(9 * x, -4, 0, 90), "Light stone grey", "Metal", { shape = "cyl" })
		U.P(b, "EngineFront", Vector3.new(0.4, 3, 3), U.L(9 * x, -4, -3.6, 90), tail, "Metal", { shape = "cyl" })
		U.P(b, "Gear", Vector3.new(1.4, 2, 2), U.L(3 * x, -6, 4, 0, 0, 90), "Really black", nil, { shape = "cyl" })
	end
	U.P(b, "Gear", Vector3.new(1.4, 2, 2), U.L(0, -6, -18, 0, 0, 90), "Really black", nil, { shape = "cyl" })
	U.P(b, "Stabiliser", Vector3.new(16, 0.8, 5), U.L(0, 0.8, 26.5), "Light stone grey", "SmoothPlastic")
	U.P(b, "Fin", Vector3.new(0.8, 10, 9), U.L(0, 8, 25.5), tail, "SmoothPlastic", { class = "WedgePart" })
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
