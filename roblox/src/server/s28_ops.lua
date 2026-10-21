-- ==== s28_ops.lua
------------------------------------------------------------------ ground operations: vehicles that drive around, the sky train
-- Each vehicle is a rigged model (invisible root, everything welded to it) that follows a looping path at
-- ground level; the main loop moves them (OPS.step). The sky train shuttles between its three stations.
local OPS = {}
-- a vehicle facing -z, standing on the ground at its root. kind = "bus" | "car" | "tug" | "tanker" | "box" | "sweeper" | "fire"
function M.vehicle(parent, kind, color, opt)
	opt = opt or {}
	local m = Instance.new("Model")
	m.Name = opt.name or kind
	local b = { model = m, cf = CFrame.new() }
	local root = U.P(b, "Root", Vector3.new(1, 1, 1), U.L(0, 0.5, 0), "Institutional white", nil, { tr = 1, nc = true })
	local function wheels(xs, zs, d)
		for _, x in ipairs(xs) do for _, z in ipairs(zs) do U.P(b, "Wheel", Vector3.new(0.8, d, d), U.L(x, d / 2, z), "Really black", nil, { shape = "cyl" }) end end
	end
	if kind == "bus" then
		U.blk(b, "Body", 9, 8.4, 30, 0, 1, 0, color, "SmoothPlastic")
		U.blk(b, "Windows", 9.1, 2.6, 26, 0, 5, 1, "Really black", "Glass")
		U.blk(b, "Windscreen", 8, 3.4, 0.2, 0, 4.6, -15.05, "Really black", "Glass")
		local s = U.blk(b, "Sign", 7, 1.2, 0.2, 0, 8.2, -15.1, "Really black", "Neon")
		U.text(s, opt.sign or "AIRPORT SHUTTLE", Color3.new(1, 0.6, 0.1), nil, "Front")
		wheels({ -4.3, 4.3 }, { -10, 10 }, 3)
	elseif kind == "van" then
		U.blk(b, "Body", 6, 6, 13, 0, 0.8, 0, color, "SmoothPlastic")
		U.blk(b, "Windows", 6.1, 2, 10, 0, 4, 0.8, "Really black", "Glass")
		U.blk(b, "Windscreen", 5.4, 2.4, 0.2, 0, 3.6, -6.55, "Really black", "Glass")
		local s = U.blk(b, "Side", 0.2, 1.4, 8, 3.06, 2, 0.8, opt.stripe or "Navy blue", "SmoothPlastic")
		U.text(s, opt.sign or "SHUTTLE", Color3.new(1, 1, 1), nil, "Right")
		if opt.lights then U.light(U.blk(b, "LightBar", 4, 0.5, 1, 0, 6.8, -4, opt.lights, "Neon"), BrickColor.new(opt.lights).Color, 12) end
		wheels({ -2.8, 2.8 }, { -4, 4 }, 2)
	elseif kind == "car" then
		U.blk(b, "Body", 5, 2, 9, 0, 0.6, 0, color, "SmoothPlastic")
		U.P(b, "Top", Vector3.new(4.4, 1.6, 4.5), U.L(0, 3.4, 0.5), color, "SmoothPlastic")
		U.P(b, "Glass", Vector3.new(4.5, 1.2, 4.6), U.L(0, 3.4, 0.5), "Pastel light blue", "Glass", { tr = 0.5 })
		if opt.lights then
			U.light(U.blk(b, "LightBar", 3.4, 0.5, 1, 0, 4.2, 0.5, opt.lights, "Neon"), BrickColor.new(opt.lights).Color, 12)
		end
		if opt.roofSign then
			local s = U.blk(b, "RoofSign", 3, 1, 0.3, 0, 4.2, 0.5, "Bright yellow", "SmoothPlastic")
			U.text(s, opt.roofSign, Color3.new(0, 0, 0), nil, "Front")
			U.text(s, opt.roofSign, Color3.new(0, 0, 0), nil, "Back")
		end
		wheels({ -2.4, 2.4 }, { -3, 3 }, 1.6)
	elseif kind == "tug" then
		U.blk(b, "Tug", 4, 2.6, 5, 0, 0.4, -6, color, "SmoothPlastic")
		U.blk(b, "Seat", 2, 1, 1.6, 0, 3, -5.4, "Really black")
		for i = 0, 2 do
			U.blk(b, "Cart", 4, 1, 5, 0, 0.6, i * 6.2, "Light stone grey", "Metal")
			U.blk(b, "Bags", 3.4, 1.6, 4, 0, 1.6, i * 6.2, U.pick({ "Bright red", "Bright blue", "Really black", "Bright yellow" }))
		end
		wheels({ -1.8, 1.8 }, { -7, -5 }, 1.2)
	elseif kind == "tanker" or kind == "box" then
		U.blk(b, "Cab", 5, 4.6, 4, 0, 0.6, -6, color, "SmoothPlastic")
		U.blk(b, "CabGlass", 4.6, 1.8, 0.2, 0, 3, -8.05, "Really black", "Glass")
		if kind == "tanker" then
			U.P(b, "Tank", Vector3.new(11, 4.6, 4.6), U.L(0, 3.4, 1.6, 90), "Institutional white", "Metal", { shape = "cyl" })
			local s = U.blk(b, "Label", 0.2, 1.4, 6, 2.4, 3.4, 1.6, "Bright red", "SmoothPlastic")
			U.text(s, "JET FUEL", Color3.new(1, 1, 1), nil, "Right")
		else
			U.blk(b, "Box", 5.4, 6, 10, 0, 0.6, 2, "Institutional white", "SmoothPlastic")
			local s = U.blk(b, "Label", 0.2, 2, 7, 2.75, 3, 2, opt.stripe or "Bright red", "SmoothPlastic")
			U.text(s, opt.sign or "CATERING", Color3.new(1, 1, 1), nil, "Right")
		end
		wheels({ -2.4, 2.4 }, { -6, 4 }, 1.8)
	elseif kind == "sweeper" then
		U.blk(b, "Body", 5, 3.6, 8, 0, 0.6, 0, "Bright orange", "SmoothPlastic")
		U.P(b, "Brush", Vector3.new(6, 1.4, 1.4), U.L(0, 0.7, -4.8), "Bright yellow", "Fabric", { shape = "cyl" })
		U.light(U.blk(b, "Beacon", 0.8, 0.8, 0.8, 0, 4.2, 0, "Bright orange", "Neon"), Color3.new(1, 0.6, 0.1), 12)
		wheels({ -2.4, 2.4 }, { -2, 3 }, 1.6)
	elseif kind == "fire" then
		U.blk(b, "Truck", 8, 7, 18, 0, 0.8, 0, "Bright red", "SmoothPlastic")
		U.blk(b, "Ladder", 1.4, 0.8, 14, 0, 7.8, 1, "Light stone grey", "Metal")
		U.light(U.blk(b, "Siren", 3, 0.6, 1, 0, 7.8, -7, "Really red", "Neon"), Color3.new(1, 0.1, 0.1), 14)
		U.blk(b, "Windscreen", 7, 2.4, 0.2, 0, 4.6, -9.05, "Really black", "Glass")
		wheels({ -3.8, 3.8 }, { -6, 6 }, 2.4)
	end
	U.rig(m, root, false)
	m.Parent = parent
	return m, root
end

-- a looping drive along plot-local points { x, z [, speed] } at ground level
local function drive(b, model, root, list, speed, off)
	local pts = {}
	for _, q in ipairs(list) do table.insert(pts, { p = b.cf * Vector3.new(q[1], 0.3, q[2]), v = q[3] or speed }) end
	local P = FLY.path(FLY.round(pts, 6), true)
	table.insert(b.plot.movers, { root = root, path = P, off = (off or 0) * P.total })
end
local function fleet(b, kind, color, opt, list, speed, n)
	for i = 1, n or 1 do
		local m, root = M.vehicle(b.model, kind, type(color) == "table" and color[i] or color, opt)
		drive(b, m, root, list, speed, (i - 1) / (n or 1))
	end
end

function OPS.step(dt)
	local now = tick()
	for _, plot in ipairs(G.plots) do
		for _, mv in ipairs(plot.movers or {}) do
			if mv.root.Parent then
				if mv.train then
					OPS.train(mv, dt)
				else
					local t = now + mv.off
					local p = FLY.at(mv.path, t)
					local ahead = FLY.at(mv.path, t + 0.5)
					local d = Vector3.new(ahead.x - p.x, 0, ahead.z - p.z)
					if d.magnitude > 0.05 then mv.look = d.unit end
					mv.root.CFrame = CFrame.new(p, p + (mv.look or Vector3.new(0, 0, -1)))
				end
			end
		end
	end
end

------------------------------------------------------------------ the items
-- drivers holding name boards on the sidewalk, like the arrivals hall of a real airport
function K.greeters(b)
	local names = { "MR SMITH", "WELCOME HOME!", "DR LEE", "TEAM TRIP", "MS GARCIA", "JOHNSON" }
	for i, x in ipairs({ -44, -36, -28, -20, 20, 28 }) do
		local m = M.person(b.model, b.cf * U.L(x, 0.5, 55, 180), { shirt = i % 2 == 0 and "Really black" or "Navy blue", pants = "Really black", tie = "Really black" }, "Greeter")
		local s = U.blk(b, "NameBoard", 2.6, 1.4, 0.2, x, 3.6, 56.4, "Institutional white", "SmoothPlastic")
		U.text(s, names[i], Color3.new(0, 0, 0), nil, "Back")
	end
	for x = -48, -16, 8 do U.cyl(b, "RopePost", 0.4, 3, x, 0.5, 52.4, "Gold", "Metal") end
	U.blk(b, "Rope", 32, 0.3, 0.2, -32, 3, 52.4, "Really red", "Fabric", { nc = true })
end
function K.shuttle(b)
	fleet(b, "bus", { "Bright blue", "Bright green" }, { sign = "AIRPORT SHUTTLE" }, { { -290, 24 }, { 290, 24 }, { 290, 36 }, { -290, 36 } }, 26, 2)
end
function K.taxis(b)
	fleet(b, "car", "Bright yellow", { roofSign = "TAXI" }, { { -285, 27 }, { 285, 27 }, { 285, 33 }, { -285, 33 } }, 32, 3)
end
function K.policecar(b)
	fleet(b, "car", "Institutional white", { lights = "Bright blue" }, { { 285, 21 }, { -285, 21 }, { -285, 39 }, { 285, 39 } }, 30, 1)
end
function K.tugs(b)
	fleet(b, "tug", "Bright yellow", nil, { { -150, 330 }, { 150, 330 }, { 150, 440 }, { -150, 440 } }, 14, 2)
end
function K.fueltruck(b)
	fleet(b, "tanker", "Institutional white", nil, { { 190, 336 }, { -190, 336 }, { -190, 434 }, { 190, 434 } }, 16, 1)
end
function K.followme(b)
	fleet(b, "car", "Bright yellow", { roofSign = "FOLLOW ME", lights = "Bright orange" }, { { -280, 455 }, { 280, 455 }, { 280, 465 }, { -280, 465 } }, 24, 1)
end
function K.firetruck(b)
	fleet(b, "fire", "Bright red", nil, { { -150, 564 }, { 150, 564 }, { 150, 568 }, { -150, 568 } }, 12, 1)
end
function K.cateringtruck(b)
	fleet(b, "box", b.plot.color, { sign = "SKY CATERING", stripe = b.plot.color }, { { 80, 706 }, { -60, 706 }, { -60, 758 }, { 80, 758 } }, 12, 2)
end
function K.sweeper(b)
	fleet(b, "sweeper", "Bright orange", nil, { { -280, 772 }, { 280, 772 }, { 280, 778 }, { -280, 778 } }, 10, 1)
end
-- ground power units plugged in at the four gates
function K.gpu(b)
	for _, x in ipairs({ -105, -35, 35, 105 }) do
		U.blk(b, "GPU", 4, 3, 6, x + 9, 0.3, 360, "Bright yellow", "SmoothPlastic")
		U.blk(b, "GPUPanel", 0.2, 1.4, 2, x + 11.1, 1.6, 360, "Really black")
		U.P(b, "Cable", Vector3.new(0.3, 0.3, 8), U.L(x + 6, 1.5, 364, 50), "Really black")
	end
end
-- instrument landing system: the localizer antenna row past the runway end, and the glide slope mast
function K.ils(b)
	for i = -5, 5 do
		U.cyl(b, "Antenna", 0.4, 5, 297, 0.3, 525 + i * 3, "Really red", "Metal")
		U.blk(b, "Dipole", 0.3, 0.3, 2, 297, 5.3, 525 + i * 3, "Institutional white", "Metal")
	end
	U.blk(b, "LocalizerHut", 4, 4, 6, 292, 0.3, 545, "Institutional white")
	U.cyl(b, "GlideSlope", 0.8, 14, -150, 0.3, 574, "Really red", "Metal")
	for y = 4, 12, 4 do U.blk(b, "Panel", 0.4, 2, 1.6, -149.4, y, 574, "Institutional white", "Metal") end
end
-- a fence round the back and sides of the airside
function K.fence(b)
	local h = 7
	U.blk(b, "FenceBack", PLOT_W - 4, h, 0.2, 0, 0.3, PLOT_D - 3, "Dark stone grey", "DiamondPlate", { tr = 0.5 })
	for _, x in ipairs({ -PLOT_W / 2 + 2, PLOT_W / 2 - 2 }) do
		U.blk(b, "FenceSide", 0.2, h, PLOT_D - 450, x, 0.3, (450 + PLOT_D - 3) / 2, "Dark stone grey", "DiamondPlate", { tr = 0.5 })
	end
	for x = -PLOT_W / 2 + 2, PLOT_W / 2 - 2, 50 do U.blk(b, "Post", 0.6, h + 1, 0.6, x, 0.3, PLOT_D - 3, "Light stone grey", "Metal") end
	for z = 450, PLOT_D - 3, 50 do
		for _, x in ipairs({ -PLOT_W / 2 + 2, PLOT_W / 2 - 2 }) do U.blk(b, "Post", 0.6, h + 1, 0.6, x, 0.3, z, "Light stone grey", "Metal") end
	end
	U.blk(b, "Wire", PLOT_W - 4, 0.3, 0.3, 0, h + 0.5, PLOT_D - 3, "Light stone grey", "Metal", { nc = true })
end

------------------------------------------------------------------ the sky train: an elevated track along the front, three stations
local TRACK_Y, TRACK_Z = 22, 49
local STATIONS = { { x = -255, name = "PARKING" }, { x = 0, name = "TERMINAL" }, { x = 256, name = "HOTEL" } }
function K.skytrack(b)
	U.blk(b, "Track", PLOT_W - 20, 1.4, 6, 0, TRACK_Y - 1.4, TRACK_Z, "Light stone grey", "Concrete")
	for _, dz in ipairs({ -1.6, 1.6 }) do U.blk(b, "Rail", PLOT_W - 20, 0.4, 0.4, 0, TRACK_Y, TRACK_Z + dz, "Dark stone grey", "Metal") end
	for x = -260, 260, 40 do U.cyl(b, "Pillar", 2.4, TRACK_Y - 1.4, x, 0, TRACK_Z, "Light stone grey", "Concrete") end
	for _, st in ipairs(STATIONS) do
		U.blk(b, "Platform", 34, 1, 7, st.x, TRACK_Y - 1, TRACK_Z - 6.5, "Light stone grey", "Concrete")
		U.blk(b, "Canopy", 34, 0.6, 9, st.x, TRACK_Y + 9, TRACK_Z - 3, b.plot.color, "SmoothPlastic")
		for _, dx in ipairs({ -15, 15 }) do U.blk(b, "CanopyPost", 0.6, 9, 0.6, st.x + dx, TRACK_Y, TRACK_Z - 9.6, "Dark stone grey", "Metal") end
		local s = U.blk(b, "StationSign", 14, 2, 0.3, st.x, TRACK_Y + 6.4, TRACK_Z - 9.8, "Navy blue", "SmoothPlastic")
		U.text(s, "SKY TRAIN - " .. st.name, Color3.new(1, 1, 1), nil, "Front")
		U.text(s, "SKY TRAIN - " .. st.name, Color3.new(1, 1, 1), nil, "Back")
	end
end
function K.skytrain(b)
	local m = Instance.new("Model")
	m.Name = "Sky Train"
	local tb = { model = m, cf = CFrame.new() }
	local root = U.P(tb, "Root", Vector3.new(1, 1, 1), U.L(0, 0.5, 0), "Institutional white", nil, { tr = 1, nc = true })
	for i = -1, 1 do
		local x = i * 15
		U.blk(tb, "Car", 14, 7, 5, x, 0.6, 0, "Institutional white", "SmoothPlastic")
		U.blk(tb, "Windows", 12, 2.6, 5.1, x, 3.4, 0, "Really black", "Glass")
		U.blk(tb, "Stripe", 14.1, 0.8, 5.1, x, 1.6, 0, b.plot.color, "SmoothPlastic")
		for _, dx in ipairs({ -2, 2 }) do U.blk(tb, "Door", 2.4, 5, 5.2, x + dx * 2, 0.8, 0, "Light stone grey", "Glass", { tr = 0.3 }) end
	end
	for _, s in ipairs({ -1, 1 }) do U.P(tb, "Nose", Vector3.new(5, 6.4, 5), U.L(s * 23.5, 3.8, 0), "Institutional white", "SmoothPlastic", { shape = "ball" }) end
	U.rig(m, root, false)
	m.Parent = b.model
	table.insert(b.plot.movers, { root = root, train = true, at = 1, dir = 1, wait = 4, x = STATIONS[1].x, cf = b.cf })
	OPS.placeTrain(b.plot.movers[#b.plot.movers])
end
function OPS.placeTrain(mv)
	mv.root.CFrame = mv.cf * CFrame.new(mv.x, TRACK_Y + 0.4, TRACK_Z)
end
function OPS.train(mv, dt)
	if mv.wait > 0 then
		mv.wait = mv.wait - dt
		return
	end
	local nxt = mv.at + mv.dir
	if not STATIONS[nxt] then
		mv.dir = -mv.dir
		nxt = mv.at + mv.dir
	end
	local goal = STATIONS[nxt].x
	local step = 22 * dt
	if math.abs(goal - mv.x) <= step then
		mv.x, mv.at, mv.wait = goal, nxt, 6
	else
		mv.x = mv.x + (goal > mv.x and step or -step)
	end
	OPS.placeTrain(mv)
end
function K.ambulance(b)
	fleet(b, "van", "Institutional white", { sign = "AMBULANCE", stripe = "Really red", lights = "Really red" }, { { -280, 22 }, { 280, 22 }, { 280, 38 }, { -280, 38 } }, 28, 1)
end
function K.rentalshuttle(b)
	fleet(b, "van", "Bright orange", { sign = "CAR RENTAL", stripe = "Really black" }, { { 290, 25 }, { -290, 25 }, { -290, 35 }, { 290, 35 } }, 24, 1)
end
function K.hotelvan(b)
	fleet(b, "van", "Really black", { sign = "HOTEL", stripe = "Gold" }, { { -260, 26 }, { 260, 26 }, { 260, 34 }, { -260, 34 } }, 22, 1)
end
function K.crewbus(b)
	fleet(b, "bus", "Navy blue", { sign = "CREW BUS" }, { { -120, 342 }, { 120, 342 }, { 120, 430 }, { -120, 430 } }, 12, 1)
end
function K.mailtruck(b)
	fleet(b, "box", "Bright red", { sign = "AIR MAIL", stripe = "Bright blue" }, { { 280, 30 }, { -280, 30 }, { -280, 37 }, { 280, 37 } }, 26, 1)
end
-- pushback tugs waiting by the gates
function K.pushback(b)
	for _, x in ipairs({ -105, -35, 35, 105 }) do
		U.blk(b, "Pushback", 5, 2, 8, x - 8, 0.3, 352, "Bright yellow", "SmoothPlastic")
		U.blk(b, "Cab", 3, 2, 2, x - 8, 2.3, 355, "Really black", "Glass")
		U.blk(b, "TowBar", 0.6, 0.6, 6, x - 8, 0.8, 345, "Dark stone grey", "Metal")
	end
end
-- two fire trucks making a water arch over the taxiway: the welcome a new airline gets
function K.watersalute(b)
	for _, x in ipairs({ -250, -210 }) do
		U.blk(b, "FireTruck", 8, 7, 18, x, 0.8, 478, "Bright red", "SmoothPlastic")
		U.blk(b, "Cannon", 1, 1, 3, x + (x < -230 and 3 or -3), 8, 478, "Light stone grey", "Metal")
	end
	for i = 0, 8 do
		local t = i / 8
		local x = -246 + 32 * t
		local y = 9 + math.sin(t * math.pi) * 12
		U.ball(b, "Water", 2.4, x, y, 478, "Cyan", "Glass", { tr = 0.45, nc = true })
	end
end
-- amber guard lights where the taxiways meet the runway
function K.guardlights(b)
	for _, x in ipairs({ -190, 190, -280, 280 }) do
		for _, dx in ipairs({ -8, 8 }) do
			U.blk(b, "LightPost", 0.4, 2, 0.4, x + dx, 0.3, 486, "Dark stone grey", "Metal")
			U.light(U.ball(b, "Amber", 0.8, x + dx, 2.6, 486, "Bright orange", "Neon"), Color3.new(1, 0.6, 0.1), 8)
		end
	end
end
NPC.OPS = OPS
