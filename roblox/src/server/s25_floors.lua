-- ==== s25_floors.lua
------------------------------------------------------------------ elevators (terminal + hotel)
-- a glass shaft from y0, h tall, at plot (x, z). `open` is the side riders walk in from: "+x", "-x", "+z" or "-z".
function U.shaft(b, x, z, y0, h, open, color)
	local glass, frame = "Pastel light blue", color or "Institutional white"
	local walls = { ["+x"] = { 4, 0, 0.4, 8 }, ["-x"] = { -4, 0, 0.4, 8 }, ["+z"] = { 0, 4, 8, 0.4 }, ["-z"] = { 0, -4, 8, 0.4 } }
	for side, w in pairs(walls) do
		if side ~= open then U.blk(b, "ShaftGlass", w[3], h, w[4], x + w[1], y0, z + w[2], glass, "Glass", { tr = 0.55 }) end
	end
	for _, c in ipairs({ { -4, -4 }, { 4, -4 }, { -4, 4 }, { 4, 4 } }) do U.blk(b, "ShaftPost", 0.6, h, 0.6, x + c[1], y0, z + c[2], frame, "Metal") end
	U.blk(b, "ShaftTop", 8.6, 0.4, 8.6, x, y0 + h - 0.4, z, frame, "Metal")
	U.blk(b, "CabFloor", 7.6, 0.2, 7.6, x, y0, z, "Dark stone grey", "DiamondPlate")
end
-- call pads inside a shaft. levels = floor tops, keys[i] = item that must be bought before level i can be visited,
-- i = the level these pads are on, (ex, ez) = where riders step out, relative to the shaft.
function U.liftPads(b, x, z, levels, keys, i, ex, ez)
	local plot = b.plot
	local function make(dir, dz, color, text)
		local pad = U.blk(b, "Lift" .. text, 3, 0.3, 3, x, levels[i], z + dz, color, "Neon")
		U.bill(pad, text, 3, 1.1, 2, Color3.new(1, 1, 1))
		local busy = {}
		pad.Touched:connect(function(hit)
			local player = hit.Parent and Players:GetPlayerFromCharacter(hit.Parent)
			if not player or busy[player] then return end
			busy[player] = true
			local j = i + dir
			local key = keys[j]
			if key and not plot.bought[key] then
				A.toast(player, "Build " .. (ITEM[key] and ITEM[key].name or "the next floor") .. " first!", "red")
			else
				local char = player.Character
				local torso = char and (char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart"))
				if torso then torso.CFrame = plot.cf * CFrame.new(x + ex, levels[j] + 3.5, z + ez) end
			end
			wait(1.5)
			busy[player] = nil
		end)
	end
	if levels[i + 1] then make(1, -1.7, "Lime green", "UP") end
	if levels[i - 1] then make(-1, 1.7, "Really red", "DOWN") end
end

local TLIFT = { levels = { LV[1], LV[2], LV[3], LV_ROOF }, keys = { "elevators", "f2floor", "f3floor", "f3roof" } }
-- the terminal elevators stand at x = -30 and 30 (open towards the middle), z = LIFT_Z
local function terminalLift(b, level)
	for _, x in ipairs({ -30, 30 }) do
		local top = TLIFT.levels[level + 1]
		local open = x < 0 and "+x" or "-x"
		if top then U.shaft(b, x, LIFT_Z, TLIFT.levels[level], top - 1 - TLIFT.levels[level], open, b.plot.color) end
		U.liftPads(b, x, LIFT_Z, TLIFT.levels, TLIFT.keys, level, x < 0 and 6 or -6, 0)
	end
end

function K.elevators(b)
	terminalLift(b, 1)
	for _, x in ipairs({ -30, 30 }) do
		local s = U.blk(b, "LiftSign", 6, 1.6, 0.3, x + (x < 0 and 4.3 or -4.3), LV[1] + 9, LIFT_Z, "Really black", "SmoothPlastic", nil, 90)
		U.text(s, "ELEVATOR", Color3.new(1, 1, 1), nil, "Front")
		U.text(s, "ELEVATOR", Color3.new(1, 1, 1), nil, "Back")
	end
end

------------------------------------------------------------------ upper floors of the terminal
-- footprint x -140..140, z 60..320, same as the ground floor
function K.upfloor(b, o)
	local y = LV[o.fl]
	U.blk(b, "Floor" .. o.fl, 282, 1, 262, 0, y - 1, 190, o.fl == 2 and "Institutional white" or "Light stone grey", "Marble")
	U.blk(b, "Edge", 284, 1, 1, 0, y - 1, 59, b.plot.color, "SmoothPlastic")
	U.blk(b, "Edge", 284, 1, 1, 0, y - 1, 321, b.plot.color, "SmoothPlastic")
	-- the floor is see-through around the elevators (a glass ring)
	for _, x in ipairs({ -30, 30 }) do U.blk(b, "LiftRing", 10, 0.1, 10, x, y, LIFT_Z, "Gold", "Metal", { nc = true }) end
	-- a carpet runner down the middle aisle
	U.blk(b, "Runner", 30, 0.1, 250, 0, y, 190, o.fl == 2 and "Bright red" or "Navy blue", "Fabric", { nc = true })
	terminalLift(b, o.fl)
	for _, p in ipairs({ { -70, 120 }, { 70, 250 } }) do SPOT(b, "janitor", p[1], y, p[2], 45) end
end

function K.upwalls(b, o)
	local y, h = LV[o.fl], 15
	for _, z in ipairs({ 60, 320 }) do
		U.blk(b, "Glass", 280, h, 0.6, 0, y, z, "Pastel light blue", "Glass", { tr = 0.5 })
		for x = -140, 140, 20 do U.blk(b, "Frame", 1.2, h, 1.2, x, y, z, "Institutional white", "SmoothPlastic") end
	end
	for _, x in ipairs({ -140, 140 }) do
		U.blk(b, "SideGlass", 0.6, h, 260, x, y, 190, "Pastel light blue", "Glass", { tr = 0.5 })
		for z = 60, 320, 20 do U.blk(b, "Frame", 1.2, h, 1.2, x, y, z, "Institutional white", "SmoothPlastic") end
	end
	U.blk(b, "Cornice", 284, 1.4, 2, 0, y + h - 0.4, 60, b.plot.color, "SmoothPlastic")
	U.blk(b, "Cornice", 284, 1.4, 2, 0, y + h - 0.4, 320, b.plot.color, "SmoothPlastic")
	local s = U.blk(b, "FloorSign", 40, 5, 0.4, 0, y + 5, 58.8, "Really black", "SmoothPlastic")
	U.text(s, o.fl == 2 and "SKY MALL" or "SKY DECK", Color3.new(1, 0.85, 0.3), Color3.new(0.04, 0.06, 0.15), "Front")
	U.light(s, Color3.new(1, 0.85, 0.5), 30)
end

function K.uplights(b, o)
	local y = LV[o.fl] + 14.2
	for _, x in ipairs({ -100, -50, 0, 50, 100 }) do
		for _, z in ipairs({ 90, 150, 210, 270 }) do
			local p = U.blk(b, "Light", 12, 0.4, 3, x, y, z, "Institutional white", "Neon", { nc = true })
			if x ~= 0 and (z == 150 or z == 270) then U.light(p, Color3.new(1, 0.97, 0.9), 45, 1) end
		end
	end
end

function K.banners(b, o)
	local y = LV[o.fl]
	local cols = { "Bright red", "Bright blue", "Bright yellow", "Lime green", "Hot pink", "Bright orange" }
	local words = { "SALE!", "SKY MALL", "EAT", "SHOP", "PLAY", "RELAX" }
	for i, z in ipairs({ 90, 130, 170, 230, 270, 300 }) do
		for _, x in ipairs({ -18, 18 }) do
			local s = U.blk(b, "Banner", 0.3, 5, 3, x, y + 7.5, z, cols[i], "Fabric", { nc = true })
			U.text(s, words[i], Color3.new(1, 1, 1), nil, x < 0 and "Right" or "Left")
			U.blk(b, "Rod", 0.3, 2.5, 0.3, x, y + 12.5, z, "Dark stone grey", "Metal", { nc = true })
		end
	end
end

function K.uproof(b)
	local y = LV_ROOF
	U.blk(b, "Roof", 284, 1, 264, 0, y - 1, 190, "Dark stone grey", "Concrete")
	for _, z in ipairs({ 58.5, 321.5 }) do U.blk(b, "Parapet", 284, 2, 1, 0, y, z, b.plot.color, "SmoothPlastic") end
	for _, x in ipairs({ -141.5, 141.5 }) do U.blk(b, "Parapet", 1, 2, 264, x, y, 190, b.plot.color, "SmoothPlastic") end
	for _, p in ipairs({ { -90, 140 }, { 90, 140 }, { -90, 250 }, { 90, 250 } }) do
		U.blk(b, "Skylight", 30, 1, 40, p[1], y, p[2], "Pastel light blue", "Glass", { tr = 0.3 })
	end
	for _, p in ipairs({ { -40, 300 }, { 40, 300 } }) do
		U.blk(b, "AirCon", 10, 5, 8, p[1], y, p[2], "Light stone grey", "Metal")
		U.cyl(b, "Fan", 5, 0.4, p[1], y + 5, p[2], "Dark stone grey", "Metal")
	end
	U.cyl(b, "Antenna", 0.6, 20, 120, y, 300, "Light stone grey", "Metal")
	U.light(U.ball(b, "AntennaLight", 1.2, 120, y + 20.6, 300, "Really red", "Neon"), Color3.new(1, 0.2, 0.2), 20)
	-- elevator rooms on the roof
	for _, x in ipairs({ -30, 30 }) do
		U.blk(b, "LiftRoom", 9, 9, 0.6, x, y, LIFT_Z + 4.3, "Light stone grey", "Concrete")
		U.blk(b, "LiftRoom", 0.6, 9, 9, x + (x < 0 and -4.3 or 4.3), y, LIFT_Z, "Light stone grey", "Concrete")
		U.blk(b, "LiftRoof", 9.6, 0.6, 9.6, x, y + 9, LIFT_Z, b.plot.color, "SmoothPlastic")
		U.liftPads(b, x, LIFT_Z, TLIFT.levels, TLIFT.keys, 4, x < 0 and 6 or -6, 0)
	end
end

function K.roofgarden(b)
	local y = LV_ROOF
	for _, p in ipairs({ { -60, 100 }, { 60, 100 }, { -100, 200 }, { 100, 200 }, { -60, 290 }, { 60, 200 } }) do
		U.blk(b, "Grass", 24, 0.6, 24, p[1], y, p[2], "Bright green", "Grass")
		U.cyl(b, "Trunk", 1.4, 7, p[1], y + 0.6, p[2], "Brown", "Wood")
		U.ball(b, "Leaves", 8, p[1], y + 9, p[2], "Dark green", "Grass")
		U.seat(b, p[1] + 9, y + 0.6, p[2], 90, "Brown", 4)
	end
	for x = -120, 120, 40 do U.blk(b, "FlowerBox", 12, 1.6, 3, x, y, 72, U.pick({ "Bright red", "Bright yellow", "Hot pink", "Royal purple" }), "Grass") end
end

------------------------------------------------------------------ shops, restaurants and rooms on the upper floors
-- every booth is 16 wide, 10 deep and 12 tall; inside it (0, F, 0) is the middle of its floor, -z is the open front
local STYLE = {}
local function gear(bb, n, x0, step, y, z, size, colors, mat)
	for i = 0, n - 1 do U.blk(bb, "Goods", size.x, size.y, size.z, x0 + i * step, y, z, U.pick(colors), mat) end
end
local BRIGHT = { "Bright red", "Bright blue", "Bright yellow", "Lime green", "Hot pink", "Cyan", "Bright orange", "Royal purple" }
local function counterAt(bb, color, z, w)
	U.blk(bb, "Counter", w or 12, 3.6, 2, 0, F, z or -3.2, "Institutional white", "SmoothPlastic")
	U.blk(bb, "CounterTop", (w or 12) + 0.4, 0.4, 2.4, 0, F + 3.6, z or -3.2, color, "SmoothPlastic")
end
function STYLE.food(bb, o)
	counterAt(bb, o.color)
	U.blk(bb, "Menu", 10, 3, 0.2, 0, F + 6, 4.6, "Really black", "Neon")
	U.blk(bb, "Grill", 6, 3.4, 2.4, -3, F, 3.4, "Dark stone grey", "Metal")
	U.blk(bb, "Fire", 5, 0.3, 2, -3, F + 3.4, 3.4, "Neon orange", "Neon", { nc = true })
	for i = -1, 1 do U.cyl(bb, "Plate", 1.6, 0.2, i * 4, F + 4, -3.2, "Institutional white") U.ball(bb, "Food", 1, i * 4, F + 4.6, -3.2, U.pick({ "Brown", "Bright orange", "Bright yellow", "Bright red" })) end
end
function STYLE.bakery(bb, o)
	U.blk(bb, "Display", 12, 3.4, 2.4, 0, F, -3.2, "Pastel light blue", "Glass", { tr = 0.4 })
	for i = -2, 2 do U.cyl(bb, "Cake", 1.6, 1, i * 2.4, F + 1.4, -3.2, U.pick({ "Hot pink", "Brown", "Institutional white", "Bright yellow" })) end
	for y = 1, 3 do U.blk(bb, "Shelf", 12, 0.3, 1.4, 0, F + y * 2.2, 4, "Brown", "Wood") gear(bb, 4, -4.5, 3, F + y * 2.2 + 0.3, 4, Vector3.new(1.8, 0.8, 1), { "Brick yellow", "Brown", "Nougat" }) end
end
function STYLE.juice(bb, o)
	counterAt(bb, o.color)
	for i = -2, 2 do U.ball(bb, "Fruit", 1.1, i * 1.8, F + 4.4, -3.2, U.pick({ "Bright orange", "Lime green", "Bright red", "Bright yellow" })) end
	for i = -1, 1 do U.cyl(bb, "Blender", 1, 2.2, i * 3.5, F + 3.6, 3.6, "Pastel light blue", "Glass", { tr = 0.3 }) end
	U.blk(bb, "Menu", 10, 3, 0.2, 0, F + 6, 4.6, o.color, "Neon")
end
function STYLE.shop(bb, o)
	for _, dx in ipairs({ -5, 0, 5 }) do
		U.blk(bb, "Shelf", 3.6, 6, 1.6, dx, F, 3.2, "Light stone grey", "SmoothPlastic")
		gear(bb, 3, dx, 0, F + 1.6, 3.2, Vector3.new(3, 1, 1.2), BRIGHT)
		for y = 1, 3 do U.blk(bb, "Goods", 3, 1, 1.2, dx, F + y * 1.8, 3.2, U.pick(BRIGHT)) end
	end
	U.blk(bb, "Till", 4, 3.6, 2, 5, F, -2.6, "Institutional white", "SmoothPlastic")
end
function STYLE.toys(bb, o)
	STYLE.shop(bb, o)
	U.ball(bb, "Teddy", 3, -5, F + 1.5, -2, "Brown") U.ball(bb, "TeddyHead", 2, -5, F + 3.8, -2, "Brown")
	U.ball(bb, "Ball", 1.6, -1.5, F + 0.8, -3, "Bright red")
end
function STYLE.shoes(bb, o)
	for y = 1, 4 do U.blk(bb, "WallShelf", 14, 0.3, 1.2, 0, F + y * 2, 4.2, "Institutional white") gear(bb, 5, -6, 3, F + y * 2 + 0.3, 4.2, Vector3.new(1.6, 0.7, 1), BRIGHT) end
	U.seat(bb, -2, F, -1, 0, o.color, 6)
end
function STYLE.sports(bb, o)
	STYLE.shop(bb, o)
	for i = 0, 2 do U.ball(bb, "SportBall", 1.4, -6 + i * 1.6, F + 0.7, -3.4, U.pick({ "Bright orange", "Institutional white", "Bright yellow" })) end
	U.blk(bb, "Mannequin", 2, 5, 1, -2, F, -1.5, o.color)
end
function STYLE.jewel(bb, o)
	for _, x in ipairs({ -4.5, 4.5 }) do
		U.blk(bb, "Case", 5, 3.4, 2.4, x, F, -2.6, "Institutional white", "Marble")
		U.blk(bb, "CaseGlass", 5, 1.4, 2.4, x, F + 3.4, -2.6, "Pastel light blue", "Glass", { tr = 0.5 })
		for i = -1, 1 do U.ball(bb, "Gem", 0.6, x + i * 1.4, F + 3.8, -2.6, U.pick({ "Gold", "Cyan", "Really red", "Lime green" }), "Neon") end
	end
	local g = U.blk(bb, "BackGlow", 14, 6, 0.3, 0, F + 3, 4.6, o.color, "Neon", { tr = 0.3 })
	U.fx(g, "Sparkles")
end
function STYLE.candy(bb, o)
	counterAt(bb, o.color)
	for i = -2, 2 do
		U.cyl(bb, "Jar", 2, 3, i * 2.8, F, 3.4, "Pastel light blue", "Glass", { tr = 0.5 })
		gear(bb, 2, i * 2.8, 0, F + 0.4, 3.4, Vector3.new(1, 0.8, 1), BRIGHT)
	end
	for _, x in ipairs({ -6.5, 6.5 }) do U.cyl(bb, "Stick", 0.3, 5, x, F, -4.4, "Institutional white") U.cyl(bb, "Lollipop", 2.4, 0.4, x, F + 5, -4.4, U.pick(BRIGHT), "Neon") end
end
function STYLE.music(bb, o)
	for i = -1, 1 do
		U.blk(bb, "GuitarBody", 1.8, 2.4, 0.5, i * 4, F + 4, 4.5, U.pick({ "Bright red", "Really black", "Brown" }))
		U.blk(bb, "GuitarNeck", 0.4, 3, 0.3, i * 4, F + 6.4, 4.5, "Brown", "Wood")
	end
	U.cyl(bb, "Drum", 3, 2, -4, F, -1, "Bright red") U.cyl(bb, "Drum", 2, 1.6, -1.5, F, -0.5, "Institutional white")
	U.blk(bb, "Keyboard", 6, 0.6, 2, 3.5, F + 3, -1.5, "Institutional white")
	U.blk(bb, "KeyStand", 0.4, 3, 1.6, 3.5, F, -1.5, "Really black")
end
function STYLE.bank(bb, o)
	counterAt(bb, o.color, -3, 14)
	U.blk(bb, "Partition", 14, 3, 0.2, 0, F + 4, -3, "Pastel light blue", "Glass", { tr = 0.5 })
	U.P(bb, "Vault", Vector3.new(0.6, 5, 5), U.L(0, F + 3.4, 4.4, 90, 0, 90), "Dark stone grey", "Metal", { shape = "cyl" })
	U.cyl(bb, "VaultWheel", 2, 0.4, 0, F + 3, 4, "Gold", "Metal")
end
function STYLE.post(bb, o)
	counterAt(bb, o.color)
	for i = 0, 5 do U.blk(bb, "Parcel", 1.6 + (i % 2), 1.2, 1.4, -5 + i * 2, F + (i % 3) * 1.2, 3.6, "Brown", "Wood") end
	U.blk(bb, "Mailbox", 1.6, 3.6, 1.6, 6.4, F, -4.4, o.color)
end
function STYLE.service(bb, o)
	U.blk(bb, "Desk", 8, 3, 3, 0, F, 0, "Brown", "Wood")
	U.seat(bb, -2, F, -2.6, 180, "Really black", 2) U.seat(bb, 2, F, -2.6, 180, "Really black", 2)
	U.ball(bb, "Globe", 3, 5, F + 5, 3, "Bright blue")
	for i = -1, 1 do U.blk(bb, "Poster", 3, 4, 0.2, i * 4, F + 6, 4.6, U.pick({ "Cyan", "Bright yellow", "Lime green" }), "Neon") end
end
function STYLE.barber(bb, o)
	for i = -1, 1 do
		U.seat(bb, i * 4.5, F + 1, 2, 0, o.color, 2)
		U.blk(bb, "ChairBase", 1, 1, 1, i * 4.5, F, 2, "Dark stone grey", "Metal")
		U.blk(bb, "Mirror", 3, 4, 0.2, i * 4.5, F + 3.5, 4.6, "Institutional white", "Glass", { refl = 0.5 })
	end
	U.cyl(bb, "Pole", 0.8, 4, -7, F + 2, -4.4, "Institutional white") U.cyl(bb, "Stripe", 0.9, 1, -7, F + 3.5, -4.4, "Bright red")
end
function STYLE.games(bb, o)
	STYLE.shop(bb, o)
	U.blk(bb, "TV", 8, 4.5, 0.4, 0, F + 7, 4.5, "Really black") U.blk(bb, "Screen", 7.4, 4, 0.1, 0, F + 7.2, 4.25, "Lime green", "Neon")
end
function STYLE.phones(bb, o)
	for _, x in ipairs({ -4, 4 }) do
		U.blk(bb, "Table", 6, 3.4, 3, x, F, -1, "Institutional white", "SmoothPlastic")
		for i = -1, 1 do U.blk(bb, "Phone", 0.8, 0.1, 1.5, x + i * 1.8, F + 3.4, -1, "Cyan", "Neon") end
	end
	U.blk(bb, "Poster", 12, 6, 0.2, 0, F + 4, 4.6, o.color, "Neon")
end
function STYLE.luggage(bb, o)
	for i = 0, 5 do
		local x = -6 + (i % 3) * 5
		U.blk(bb, "Suitcase", 3, 4, 1.6, x, F + (i >= 3 and 0 or 0), i >= 3 and 3 or -1, U.pick(BRIGHT), "SmoothPlastic")
		U.blk(bb, "Handle", 1, 1, 0.3, x, F + 4, i >= 3 and 3 or -1, "Dark stone grey", "Metal")
	end
end
function STYLE.news(bb, o)
	counterAt(bb, o.color)
	for y = 1, 4 do gear(bb, 6, -6, 2.4, F + y * 1.6, 4.4, Vector3.new(2, 1.4, 0.2), BRIGHT) end
end
function STYLE.cinema(bb, o)
	U.blk(bb, "Screen", 14, 6, 0.2, 0, F + 4, 4.6, "Institutional white", "Neon")
	for row = 0, 2 do for i = -2, 2 do U.seat(bb, i * 2.6, F + row * 0.8, -3 + row * 2.4, 180, "Bright red", 2) end end
	U.blk(bb, "Popcorn", 2, 4, 2, -6.5, F, -4, "Bright red", "SmoothPlastic")
	U.blk(bb, "PopcornGlass", 2, 2, 2, -6.5, F + 4, -4, "Bright yellow", "Glass", { tr = 0.3 })
end
function STYLE.bowling(bb, o)
	for _, x in ipairs({ -4, 4 }) do
		U.blk(bb, "Lane", 5, 0.2, 9, x, F, 0, "Brick yellow", "Wood")
		for i = -1, 1 do U.cyl(bb, "Pin", 0.5, 1.6, x + i * 1.2, F + 0.2, 3.6, "Institutional white") end
		U.ball(bb, "BowlingBall", 1.2, x, F + 0.8, -3.6, U.pick({ "Really black", "Bright blue", "Bright red" }))
	end
	U.blk(bb, "Score", 14, 2, 0.2, 0, F + 8, 4.6, "Really black", "Neon")
end
function STYLE.laser(bb, o)
	U.blk(bb, "DarkFloor", 15, 0.1, 9, 0, F, 0, "Really black", nil, { nc = true })
	for i = 0, 3 do U.blk(bb, "Barrier", 3, 3, 0.8, -5 + i * 3.4, F, -1 + (i % 2) * 3, U.pick({ "Hot pink", "Lime green", "Cyan" }), "Neon") end
	U.blk(bb, "VestRack", 6, 4, 0.6, 4, F, 4.4, "Dark stone grey", "Metal")
end
function STYLE.vr(bb, o)
	for i = -1, 1 do
		U.cyl(bb, "Platform", 4, 0.4, i * 5, F, 0, "Really black", "Metal")
		U.cyl(bb, "Ring", 4.2, 0.1, i * 5, F + 0.4, 0, "Cyan", "Neon", { nc = true })
		U.blk(bb, "Headset", 1.2, 0.6, 0.8, i * 5, F + 4, 3.6, "Really black")
	end
end
function STYLE.escape(bb, o)
	U.blk(bb, "Door", 4, 8, 0.4, 0, F, 4.6, "Reddish brown", "Wood")
	U.cyl(bb, "Lock", 1, 0.6, 1.4, F + 4, 4.3, "Gold", "Metal")
	U.blk(bb, "Bookcase", 4, 7, 1.4, -5, F, 3.8, "Brown", "Wood")
	U.blk(bb, "PuzzleBox", 1.4, 1.4, 1.4, 4, F, 0, "Gold", "Metal")
	U.cyl(bb, "Clock", 2.4, 0.3, 5, F + 7, 4.4, "Institutional white")
end
function STYLE.karaoke(bb, o)
	U.blk(bb, "Stage", 14, 0.8, 4, 0, F, 2.6, "Really black", "Wood")
	U.cyl(bb, "Mic", 0.2, 4, 0, F + 0.8, 1.6, "Dark stone grey", "Metal")
	U.blk(bb, "Screen", 8, 4, 0.2, 0, F + 5, 4.6, o.color, "Neon")
	local d = U.ball(bb, "DiscoBall", 1.6, 0, F + 10, 0, "Institutional white", "Glass", { refl = 0.8 })
	U.fx(d, "Sparkles")
	U.seat(bb, -4, F, -2.5, 180, "Hot pink", 4) U.seat(bb, 4, F, -2.5, 180, "Hot pink", 4)
end
function STYLE.comedy(bb, o)
	U.blk(bb, "Bricks", 15, 9, 0.3, 0, F, 4.6, "Bright red", "Brick")
	U.blk(bb, "Stage", 8, 1, 3, 0, F, 3, "Really black", "Wood")
	U.cyl(bb, "Mic", 0.2, 4, 0, F + 1, 2.6, "Dark stone grey", "Metal")
	for _, x in ipairs({ -4.5, 4.5 }) do U.cyl(bb, "Table", 2.4, 3, x, F, -2, "Really black") end
end
function STYLE.minigolf(bb, o)
	U.blk(bb, "Green", 15, 0.2, 9, 0, F, 0, "Bright green", "Grass")
	U.cyl(bb, "Hole", 0.8, 0.05, 4, F + 0.2, 2.5, "Really black", nil, { nc = true })
	U.cyl(bb, "FlagPole", 0.2, 4, 4, F + 0.2, 2.5, "Institutional white")
	U.blk(bb, "Flag", 1.4, 1, 0.1, 4.7, F + 3.6, 2.5, "Bright red")
	U.blk(bb, "Windmill", 2.4, 4, 2.4, -4, F, 1, "Bright red", "Wood")
	local blade1 = U.blk(bb, "Blade", 0.3, 5, 0.6, -4, F + 2.6, -0.4, "Institutional white", nil, { nc = true })
	local blade2 = U.blk(bb, "Blade", 5, 0.6, 0.3, -4, F + 4.8, -0.4, "Institutional white", nil, { nc = true })
	U.spin({ blade1, blade2 }, bb.cf * U.L(-4, F + 5.1, -0.4), "z", 50)
end
function STYLE.gym(bb, o)
	for i = -1, 1 do
		U.blk(bb, "Treadmill", 2.4, 0.8, 5, i * 4.5, F, 1.5, "Really black", "Metal")
		U.blk(bb, "Console", 2.4, 4, 0.4, i * 4.5, F, -1.2, "Dark stone grey", "Metal")
	end
	U.P(bb, "Barbell", Vector3.new(7, 0.3, 0.3), U.L(0, F + 3.5, -3.6), "Dark stone grey", "Metal")
	for _, x in ipairs({ -3.4, 3.4 }) do U.P(bb, "Weight", Vector3.new(0.5, 2, 2), U.L(x, F + 3.5, -3.6), "Really black", "Metal", { shape = "cyl" }) end
end
function STYLE.yoga(bb, o)
	for i = 0, 5 do U.blk(bb, "Mat", 2, 0.1, 5, -6 + (i % 3) * 6, F, -2 + math.floor(i / 3) * 5, U.pick({ "Teal", "Hot pink", "Royal purple", "Lime green" }), "Fabric", { nc = true }) end
	U.cyl(bb, "Pot", 2, 2, 6.5, F, 4, "Reddish brown") U.ball(bb, "Plant", 3, 6.5, F + 3, 4, "Dark green", "Grass")
end
function STYLE.pods(bb, o)
	for i = 0, 3 do
		U.P(bb, "Pod", Vector3.new(8, 3.4, 3.4), U.L(-3.4 + (i % 2) * 6.8, F + 1.8 + math.floor(i / 2) * 3.8, 2.6, 90, 0, 0), "Institutional white", "SmoothPlastic", { shape = "cyl" })
		U.blk(bb, "PodLight", 0.4, 0.4, 0.4, -3.4 + (i % 2) * 6.8, F + 1.8 + math.floor(i / 2) * 3.8, -1.5, "Cyan", "Neon", { nc = true })
	end
end
function STYLE.business(bb, o)
	for _, x in ipairs({ -4.5, 0, 4.5 }) do
		U.blk(bb, "Desk", 3.6, 3, 2.4, x, F, 2.6, "Institutional white", "SmoothPlastic")
		U.blk(bb, "Monitor", 2, 1.6, 0.2, x, F + 3, 3.4, "Cyan", "Neon")
		U.seat(bb, x, F, 0.4, 180, "Really black", 2)
	end
	U.blk(bb, "Printer", 2, 1.6, 2, -6.5, F, -3.5, "Light stone grey")
end
function STYLE.library(bb, o)
	for _, x in ipairs({ -4.5, 0, 4.5 }) do
		U.blk(bb, "Bookshelf", 4, 9, 1.6, x, F, 4, "Brown", "Wood")
		for y = 1, 4 do gear(bb, 3, x - 1.2, 1.2, F + y * 2, 3.8, Vector3.new(1, 1.6, 1.2), { "Bright red", "Bright blue", "Dark green", "Bright yellow" }) end
	end
	U.seat(bb, -3, F, -2, 180, "Bright red", 3) U.seat(bb, 3, F, -2, 180, "Bright red", 3)
end
function STYLE.gallery(bb, o)
	for i = -1, 1 do
		U.blk(bb, "Frame", 4, 3.4, 0.3, i * 5, F + 5, 4.6, "Gold", "Metal")
		U.blk(bb, "Painting", 3.4, 2.8, 0.1, i * 5, F + 5.3, 4.4, U.pick(BRIGHT), "SmoothPlastic")
	end
	U.cyl(bb, "Pedestal", 2, 3.6, 0, F, -1, "Institutional white", "Marble")
	U.ball(bb, "Sculpture", 2, 0, F + 4.6, -1, "Gold", "Metal")
end
function STYLE.science(bb, o)
	local cols = { "Bright orange", "Bright blue", "Bright red", "Brick yellow" }
	for i = 1, 4 do U.ball(bb, "Planet", 1 + i * 0.5, -6 + i * 2.6, F + 8, 1, cols[i], "SmoothPlastic", { nc = true }) end
	U.ball(bb, "Sun", 3, 6.5, F + 8.5, 1, "New Yeller", "Neon", { nc = true })
	for i = 0, 7 do U.ball(bb, "DNA", 0.6, math.cos(i) * 1.2 - 4, F + 0.6 + i * 0.8, 3, i % 2 == 0 and "Bright blue" or "Bright red", "Neon") end
	U.blk(bb, "Robot", 2, 4, 2, 4, F, 2.5, "Light stone grey", "Metal")
end
function STYLE.quiet(bb, o)
	for i = -1, 1 do U.blk(bb, "Cushion", 3, 0.6, 3, i * 4.5, F, 0, "Sand blue", "Fabric") end
	U.light(U.blk(bb, "SoftLight", 10, 0.3, 1, 0, F + 10.5, 0, "Cool yellow", "Neon", { nc = true }), Color3.new(1, 0.9, 0.7), 12, 0.6)
end
function STYLE.bar(bb, o)
	U.blk(bb, "Bar", 14, 3.6, 2, 0, F, -2.6, "Brown", "Wood")
	U.blk(bb, "BarTop", 14.4, 0.4, 2.4, 0, F + 3.6, -2.6, "Gold", "Metal", { refl = 0.3 })
	for i = -2, 2 do U.seat(bb, i * 2.8, F + 1.2, -4.6, 180, o.color, 1.4) end
	for y = 1, 2 do
		U.blk(bb, "BottleShelf", 12, 0.3, 1, 0, F + 3 + y * 2, 4.4, "Brown", "Wood")
		for i = 0, 5 do U.cyl(bb, "Bottle", 0.5, 1.4, -5 + i * 2, F + 3.3 + y * 2, 4.4, U.pick({ "Lime green", "Bright orange", "Cyan", "Bright red" }), "Neon") end
	end
end
function STYLE.planemuseum(bb, o)
	U.P(bb, "PlaneBody", Vector3.new(10, 1.6, 1.6), U.L(0, F + 8, 0, 90), "Institutional white", "SmoothPlastic", { shape = "cyl", nc = true })
	U.blk(bb, "PlaneWing", 12, 0.3, 2, 0, F + 7.8, 0, o.color, nil, { nc = true })
	U.blk(bb, "PlaneTail", 0.3, 2, 1.6, 0, F + 8.4, 4.4, o.color, nil, { nc = true })
	U.blk(bb, "Propeller", 0.3, 4, 0.4, 0, F + 6, 4.6, "Brown", "Wood")
	for _, x in ipairs({ -5, 5 }) do U.blk(bb, "Plinth", 2, 3, 2, x, F, 2, "Institutional white", "Marble") U.blk(bb, "Model", 1.4, 0.6, 1.8, x, F + 3, 2, U.pick(BRIGHT)) end
end
function STYLE.simulator(bb, o)
	U.P(bb, "Cockpit", Vector3.new(8, 5, 6), U.L(0, F + 2.5, 1.5), "Institutional white", "SmoothPlastic", { class = "WedgePart" })
	U.blk(bb, "Window", 7, 2.4, 0.2, 0, F + 4.6, -1.4, "Cyan", "Neon", { tr = 0.2 })
	U.seat(bb, 0, F, -2.6, 180, "Really black", 2)
	U.blk(bb, "Yoke", 1.6, 0.4, 0.4, 0, F + 2.6, -3.6, "Dark stone grey", "Metal")
end
function STYLE.academy(bb, o)
	U.blk(bb, "Whiteboard", 10, 4, 0.2, 0, F + 4, 4.6, "Institutional white", "SmoothPlastic")
	for row = 0, 1 do for i = -1, 1 do
		U.blk(bb, "Desk", 3, 2.6, 1.6, i * 4.5, F, row * 3 - 1.6, "Brown", "Wood")
		U.seat(bb, i * 4.5, F, row * 3 - 3.2, 180, o.color, 1.6)
	end end
end
function STYLE.spotting(bb, o)
	U.blk(bb, "BigWindow", 14, 7, 0.2, 0, F + 2, 4.6, "Pastel light blue", "Glass", { tr = 0.6 })
	for _, x in ipairs({ -4, 4 }) do
		U.cyl(bb, "Tripod", 0.4, 3.4, x, F, 2, "Dark stone grey", "Metal")
		U.P(bb, "Binoculars", Vector3.new(1, 1, 2.4), U.L(x, F + 3.8, 2.4, 0, 15), "Really black", "Metal")
	end
	U.seat(bb, 0, F, 0, 0, o.color, 6)
end
function STYLE.lounge(bb, o)
	for _, x in ipairs({ -4.5, 4.5 }) do
		U.seat(bb, x, F, 1.6, 180, "Really black", 5)
		U.blk(bb, "SofaBack", 5.4, 2.4, 1, x, F + 0.5, 3.2, "Really black", "Fabric")
	end
	U.cyl(bb, "Table", 3, 2, 0, F, 0, "Gold", "Metal", { refl = 0.3 })
	U.light(U.ball(bb, "Chandelier", 2, 0, F + 10, 0, "Cool yellow", "Neon", { nc = true }), Color3.new(1, 0.85, 0.5), 18)
	U.blk(bb, "Carpet", 15, 0.1, 9, 0, F, 0, o.color, "Fabric", { nc = true })
end

local function slotCF(b, sl, fl)
	local ry = 0
	if sl.face == "x" then ry = -90 elseif sl.face == "-x" then ry = 90 elseif sl.face == "+z" then ry = 180 end
	return b.cf * U.L(sl.x, LV[fl] - F, sl.z, ry)
end
local FOODSTYLE = { food = true, bakery = true, juice = true, bar = true, candy = true }
function K.ubooth(b, o)
	local sl = SLOT[o.slot]
	local c = slotCF(b, sl, o.fl)
	local bb = booth(b, c, 16, 10, 12, o.color, o.title, false)
	U.blk(bb, "BoothFloor", 15.4, 0.1, 9.4, 0, F, 0, o.color, "SmoothPlastic", { nc = true })
	local ok, err = pcall(STYLE[o.style] or STYLE.shop, bb, o)
	if not ok then print("Airport: booth style " .. tostring(o.style) .. " failed: " .. tostring(err)) end
	U.light(U.blk(bb, "Lamp", 3, 0.4, 3, 0, F + 11.2, 0, "Cool yellow", "Neon", { nc = true }), Color3.new(1, 0.95, 0.8), 16)
	local role = FOODSTYLE[o.style] and "chef" or "clerk"
	b.plot.spots[role] = b.plot.spots[role] or {}
	table.insert(b.plot.spots[role], c * U.L(4.5, F, 2, 0))
	local it = ITEM[o.key]
	local lp = b.cf:inverse() * (c * Vector3.new(0, F, -9))
	PT(b, "up" .. o.fl, { p = lp, spend = it and it.eff.spend or 0, wait = 3 })
end

------------------------------------------------------------------ things on the islands between the rows
-- inside an island (0, F, 0) is its middle on the floor; keep within x -10..10, z -5..5 (centre ones: x -6..6)
local ISLAND = {}
function ISLAND.tables(bb)
	for _, dx in ipairs({ -5, 5 }) do
		U.cyl(bb, "Table", 4, 0.4, dx, F + 3, 0, "Institutional white", "SmoothPlastic")
		U.cyl(bb, "TableLeg", 0.6, 3, dx, F, 0, "Dark stone grey", "Metal")
		for a = 0, 270, 90 do
			local r = math.rad(a)
			U.seat(bb, dx + math.cos(r) * 3, F, math.sin(r) * 3, -a - 90, "Bright orange", 1.4)
		end
	end
end
function ISLAND.cart(bb)
	local col = U.pick(BRIGHT)
	U.blk(bb, "Cart", 6, 3.4, 3, 0, F + 0.6, 0, col, "SmoothPlastic")
	for _, x in ipairs({ -2.4, 2.4 }) do U.P(bb, "Wheel", Vector3.new(0.6, 1.4, 1.4), U.L(x, F + 0.7, 1.6), "Really black", nil, { shape = "cyl" }) end
	U.cyl(bb, "UmbrellaPole", 0.3, 5, 0, F + 4, 0, "Institutional white")
	U.cyl(bb, "Umbrella", 7, 0.4, 0, F + 9, 0, col, "Fabric")
	for i = -1, 1 do U.ball(bb, "Treat", 0.9, i * 1.6, F + 4.5, -0.6, U.pick({ "Bright yellow", "Hot pink", "Brown", "Institutional white" })) end
end
function ISLAND.massage(bb)
	for i = -1, 1 do
		U.seat(bb, i * 5, F + 0.8, 0, 180, "Really black", 3)
		U.P(bb, "ChairBack", Vector3.new(3, 3.6, 1), U.L(i * 5, F + 3, 1.6, 0, -12), "Really black", "Fabric")
		U.blk(bb, "Base", 3, 0.8, 3, i * 5, F, 0, "Dark stone grey", "Metal")
	end
end
function ISLAND.kiosk(bb)
	U.cyl(bb, "Kiosk", 7, 3.6, 0, F, 0, "Institutional white", "SmoothPlastic")
	U.cyl(bb, "Top", 8, 0.6, 0, F + 8, 0, U.pick(BRIGHT), "SmoothPlastic")
	U.cyl(bb, "Post", 0.6, 4.4, 0, F + 3.6, 0, "Dark stone grey", "Metal")
	for a = 0, 300, 60 do U.blk(bb, "Item", 1, 1, 1, math.cos(math.rad(a)) * 2.6, F + 3.6, math.sin(math.rad(a)) * 2.6, U.pick(BRIGHT), "Neon") end
end
function ISLAND.claw(bb)
	for _, x in ipairs({ -4, 4 }) do
		U.blk(bb, "Base", 4, 3, 4, x, F, 0, "Hot pink", "SmoothPlastic")
		U.blk(bb, "Glass", 4, 4, 4, x, F + 3, 0, "Pastel light blue", "Glass", { tr = 0.6 })
		for i = 1, 4 do U.ball(bb, "Prize", 1, x + math.random(-1, 1), F + 3.5, math.random(-1, 1), U.pick(BRIGHT)) end
		U.blk(bb, "Claw", 0.6, 1, 0.6, x, F + 6, 0, "Gold", "Metal")
		U.blk(bb, "Top", 4.2, 0.6, 4.2, x, F + 7, 0, "Hot pink", "Neon")
	end
end
function ISLAND.photobooth(bb)
	U.blk(bb, "Booth", 6, 8, 5, 0, F, 0, "Royal purple", "SmoothPlastic")
	U.blk(bb, "Curtain", 3, 6, 0.2, -1.2, F + 1, -2.6, "Bright red", "Fabric")
	U.blk(bb, "Sign", 5, 1.2, 0.2, 0, F + 7, -2.6, "Bright yellow", "Neon")
	U.light(U.blk(bb, "Flash", 1, 1, 0.2, 2, F + 5, -2.6, "Institutional white", "Neon"), Color3.new(1, 1, 1), 8)
end
function ISLAND.piano(bb)
	U.blk(bb, "Piano", 6, 2.4, 7, 0, F + 1.6, 0, "Really black", "SmoothPlastic", { refl = 0.3 })
	U.P(bb, "Lid", Vector3.new(6, 0.2, 7), U.L(0, F + 5, 0.8, 0, 30), "Really black", "SmoothPlastic", { refl = 0.3 })
	U.blk(bb, "Keys", 6, 0.3, 1.2, 0, F + 3, -4, "Institutional white")
	for _, p in ipairs({ { -2.6, -2.6 }, { 2.6, -2.6 }, { 0, 3 } }) do U.blk(bb, "Leg", 0.6, 1.6, 0.6, p[1], F, p[2], "Really black") end
	U.blk(bb, "Bench", 4, 1.8, 1.6, 0, F, -6, "Really black", "Fabric")
end
function ISLAND.benches(bb)
	for row = 0, 1 do
		for i = -3, 3 do U.seat(bb, i * 2.4, F, -2 + row * 4, row == 0 and 180 or 0, bb.plot.color, 2) end
		U.blk(bb, "SeatBack", 17, 2.4, 0.4, 0, F + 1, -0.8 + row * 1.6, "Dark stone grey", "Metal")
	end
end
function ISLAND.charging(bb)
	U.blk(bb, "Bar", 14, 3.6, 2, 0, F, 0, "Institutional white", "SmoothPlastic")
	for i = -2, 2 do U.blk(bb, "Charger", 0.8, 0.8, 0.8, i * 2.8, F + 3.6, 0, "Lime green", "Neon") end
	for i = -2, 2 do U.seat(bb, i * 2.8, F + 1.4, -2.2, 180, "Really black", 1.4) end
end
function ISLAND.rides(bb)
	for _, x in ipairs({ -4.5, 4.5 }) do
		U.cyl(bb, "Base", 4, 0.8, x, F, 0, "Bright yellow", "SmoothPlastic")
		U.blk(bb, "RideCar", 2.2, 1.8, 3.4, x, F + 0.8, 0, U.pick({ "Bright red", "Bright blue", "Lime green" }), "SmoothPlastic")
		U.seat(bb, x, F + 2.6, 0.4, 0, "Really black", 1.4)
		U.ball(bb, "Light", 0.6, x, F + 3.4, -1.6, "Bright yellow", "Neon")
	end
end
function ISLAND.sculpture(bb)
	U.blk(bb, "Plinth", 6, 1, 6, 0, F, 0, "Institutional white", "Marble")
	U.blk(bb, "Cube", 3, 3, 3, 0, F + 1, 0, "Gold", "Metal", { refl = 0.4 }, 45)
	U.ball(bb, "Orb", 2.4, 0, F + 5.2, 0, "Gold", "Metal", { refl = 0.5 })
	U.P(bb, "Ring", Vector3.new(0.5, 6, 6), U.L(0, F + 7.6, 0, 0, 0, 0), "Gold", "Metal", { shape = "cyl", refl = 0.4 })
end
function ISLAND.planter(bb)
	U.blk(bb, "Planter", 8, 2, 8, 0, F, 0, "Brown", "Wood")
	U.blk(bb, "Soil", 7.4, 0.2, 7.4, 0, F + 2, 0, "Reddish brown", "Grass")
	U.cyl(bb, "Trunk", 0.8, 5, 0, F + 2, 0, "Brown", "Wood")
	U.ball(bb, "Leaves", 5, 0, F + 8, 0, "Bright green", "Grass")
	for _, p in ipairs({ { -2.6, -2.6 }, { 2.6, 2.6 } }) do U.ball(bb, "Flowers", 1.6, p[1], F + 2.6, p[2], U.pick({ "Hot pink", "Bright yellow", "Bright red" }), "Grass") end
end
function ISLAND.infoscreen(bb)
	U.blk(bb, "Pillar", 4, 9, 4, 0, F, 0, "Institutional white", "SmoothPlastic")
	for _, f in ipairs({ "Front", "Back", "Left", "Right" }) do
		local s = U.blk(bb, "Screen", 4.2, 3, 4.2, 0, F + 5, 0, "Really black", "SmoothPlastic", { nc = true })
		U.text(s, "SKY MALL\nSHOPS - FOOD - FUN", Color3.new(1, 0.85, 0.3), Color3.new(0.02, 0.05, 0.15), f)
	end
end
function ISLAND.minifountain(bb)
	U.cyl(bb, "Basin", 10, 1.4, 0, F, 0, "Light stone grey", "Marble")
	U.cyl(bb, "Water", 9, 0.2, 0, F + 1.3, 0, "Cyan", "Neon", { tr = 0.4, nc = true })
	U.cyl(bb, "Spout", 1, 4, 0, F + 1.4, 0, "Light stone grey", "Marble")
	U.fx(U.ball(bb, "Jet", 1.6, 0, F + 5.8, 0, "Cyan", "Neon", { tr = 0.3, nc = true }), "Sparkles")
end
function ISLAND.pooltable(bb)
	for _, x in ipairs({ -5, 5 }) do
		U.blk(bb, "Table", 4.4, 0.6, 8, x, F + 2.6, 0, "Dark green", "Fabric")
		U.blk(bb, "Rim", 4.8, 0.4, 8.4, x, F + 2.4, 0, "Reddish brown", "Wood")
		U.blk(bb, "Legs", 3.6, 2.4, 7, x, F, 0, "Reddish brown", "Wood")
		for i = 1, 3 do U.ball(bb, "Ball", 0.5, x + math.random(-1, 1), F + 3.4, math.random(-3, 3), U.pick(BRIGHT)) end
	end
end
function ISLAND.pingpong(bb)
	U.blk(bb, "Table", 5, 0.3, 9, 0, F + 2.6, 0, "Bright blue", "SmoothPlastic")
	U.blk(bb, "Net", 5.4, 0.6, 0.1, 0, F + 2.9, 0, "Institutional white", "Fabric")
	U.blk(bb, "Legs", 4, 2.6, 7, 0, F, 0, "Dark stone grey", "Metal")
	U.ball(bb, "Ball", 0.3, 1, F + 3.4, -2, "Bright orange")
end
function ISLAND.loungechairs(bb)
	for i = 0, 3 do
		local x = -7.5 + i * 5
		U.seat(bb, x, F + 0.6, 0, 180, U.pick({ "Bright red", "Navy blue", "Sand blue" }), 3)
		U.blk(bb, "Back", 3.4, 3, 0.8, x, F + 0.6, 1.6, "Dark stone grey", "Fabric")
		U.blk(bb, "Base", 3, 0.6, 3, x, F, 0, "Dark stone grey")
	end
end
function ISLAND.beanbags(bb)
	for i = 0, 5 do U.blk(bb, "BeanBag", 3, 1.8, 3, -7 + (i % 3) * 7, F, -2 + math.floor(i / 3) * 4, U.pick(BRIGHT), "Fabric") end
end
function ISLAND.airhockey(bb)
	U.blk(bb, "Table", 4.6, 3, 8, 0, F, 0, "Institutional white", "SmoothPlastic")
	U.blk(bb, "Rim", 5, 0.4, 8.4, 0, F + 3, 0, "Really red", "Neon")
	U.cyl(bb, "Puck", 0.8, 0.2, 0, F + 3.1, 0, "Really black")
	for _, z in ipairs({ -3, 3 }) do U.cyl(bb, "Paddle", 1, 0.5, 0, F + 3.1, z, "Bright blue") end
end
function ISLAND.foosball(bb)
	for _, x in ipairs({ -4, 4 }) do
		U.blk(bb, "Table", 3.4, 3, 6, x, F, 0, "Brown", "Wood")
		U.blk(bb, "Field", 3, 0.1, 5.6, x, F + 3, 0, "Bright green", "Grass")
		for z = -2, 2, 1.3 do U.blk(bb, "Rod", 5, 0.2, 0.2, x, F + 3.3, z, "Light stone grey", "Metal") end
	end
end
function ISLAND.reading(bb)
	U.blk(bb, "Shelf", 10, 6, 1.4, 0, F, 3.6, "Brown", "Wood")
	for y = 1, 2 do for i = -2, 2 do U.blk(bb, "Book", 1.6, 1.6, 1.2, i * 2, F + y * 2.4, 3.6, U.pick(BRIGHT)) end end
	for _, x in ipairs({ -4, 4 }) do U.seat(bb, x, F + 0.6, -1, 180, "Bright red", 3) U.blk(bb, "ArmChair", 3.6, 3, 1, x, F, 0.6, "Bright red", "Fabric") end
	U.cyl(bb, "Lamp", 0.3, 5, 0, F, -1, "Dark stone grey") U.light(U.ball(bb, "Bulb", 1.4, 0, F + 5.4, -1, "Cool yellow", "Neon"), Color3.new(1, 0.9, 0.6), 10)
end
function ISLAND.racers(bb)
	for _, x in ipairs({ -4.5, 4.5 }) do
		U.blk(bb, "Cabinet", 4, 6, 2, x, F, 3, "Really black", "SmoothPlastic")
		U.blk(bb, "Screen", 3.4, 2.4, 0.2, x, F + 3.4, 1.9, "Cyan", "Neon")
		U.seat(bb, x, F, -1.6, 0, "Bright red", 2)
		U.P(bb, "Wheel", Vector3.new(0.3, 1.6, 1.6), U.L(x, F + 2.6, 0.6, 90), "Really black", nil, { shape = "cyl" })
	end
end
function ISLAND.pinball(bb)
	for i = -1, 1 do
		U.P(bb, "Pinball", Vector3.new(2.4, 1, 5), U.L(i * 5, F + 3.2, 0, 0, 8), U.pick({ "Bright red", "Royal purple", "Bright blue" }), "SmoothPlastic")
		U.blk(bb, "Legs", 2, 2.8, 4, i * 5, F, 0, "Dark stone grey", "Metal")
		U.blk(bb, "Backbox", 2.4, 3, 0.6, i * 5, F + 3.6, 2.4, "Really black")
		U.blk(bb, "Lights", 2, 2, 0.1, i * 5, F + 4, 2.05, U.pick({ "Lime green", "Hot pink" }), "Neon")
	end
end
function ISLAND.trees(bb)
	for _, x in ipairs({ -5, 5 }) do
		U.cyl(bb, "Pot", 4, 2.4, x, F, 0, "Reddish brown", "SmoothPlastic")
		U.cyl(bb, "Trunk", 0.8, 6, x, F + 2.4, 0, "Brown", "Wood")
		U.ball(bb, "Leaves", 6, x, F + 10, 0, "Dark green", "Grass")
		U.ball(bb, "Leaves", 4, x + 1, F + 12, 0.6, "Bright green", "Grass")
	end
end
function ISLAND.telescope(bb)
	for _, a in ipairs({ 0, 120, 240 }) do U.P(bb, "TripodLeg", Vector3.new(0.3, 4, 0.3), U.L(math.cos(math.rad(a)) * 0.8, F + 1.9, math.sin(math.rad(a)) * 0.8, 0, 0, 12), "Dark stone grey", "Metal") end
	U.P(bb, "Tube", Vector3.new(1.2, 1.2, 5), U.L(0, F + 4.4, 1, 0, 20), "Institutional white", "Metal", { shape = "cyl" })
	U.P(bb, "Tube", Vector3.new(5, 1.2, 1.2), U.L(0, F + 4.4, 1, 90, 0, 20), "Institutional white", "Metal", { shape = "cyl" })
	U.blk(bb, "Sign", 2, 1, 0.2, 0, F, -2.4, "Navy blue")
end
function ISLAND.hoops(bb)
	for _, x in ipairs({ -4.5, 4.5 }) do
		U.blk(bb, "Ramp", 3.6, 2.6, 7, x, F, 0, "Bright orange", "SmoothPlastic")
		U.blk(bb, "Backboard", 3.6, 3, 0.3, x, F + 6, 3.4, "Institutional white")
		U.P(bb, "Hoop", Vector3.new(0.2, 2, 2), U.L(x, F + 6, 2.2, 0, 0, 90), "Bright red", "Metal", { shape = "cyl", nc = true })
		U.ball(bb, "Basketball", 1, x, F + 3.1, -1, "Bright orange")
	end
end
function ISLAND.dancefloor(bb)
	for i = 0, 15 do
		local t = U.blk(bb, "Tile", 4.6, 0.2, 2.3, -6.9 + (i % 4) * 4.6, F, -3.45 + math.floor(i / 4) * 2.3, U.pick({ "Hot pink", "Cyan", "Lime green", "Bright yellow", "Royal purple" }), "Neon")
		if i == 5 then U.light(t, Color3.new(1, 0.3, 1), 20) end
	end
	U.fx(U.ball(bb, "DiscoBall", 2, 0, F + 12, 0, "Institutional white", "Glass", { refl = 0.8, nc = true }), "Sparkles")
end
function ISLAND.koi(bb)
	U.cyl(bb, "Rim", 10, 1.2, 0, F, 0, "Dark stone grey", "Slate")
	U.cyl(bb, "Water", 9, 0.2, 0, F + 1, 0, "Bright blue", "Glass", { tr = 0.3, nc = true })
	for i = 1, 5 do U.blk(bb, "Koi", 1.2, 0.3, 0.5, math.random(-3, 3), F + 0.8, math.random(-3, 3), U.pick({ "Bright orange", "Institutional white", "Bright red" }), nil, { nc = true }, math.random(0, 180)) end
	U.ball(bb, "Rock", 2, 3, F + 1.2, 2, "Medium stone grey", "Slate")
end
function ISLAND.rocket(bb)
	U.cyl(bb, "Pad", 6, 0.6, 0, F, 0, "Dark stone grey", "Metal")
	U.cyl(bb, "Body", 3, 9, 0, F + 0.6, 0, "Institutional white", "Metal")
	U.ball(bb, "Nose", 3, 0, F + 9.8, 0, "Bright red", "Metal")
	for _, a in ipairs({ 0, 120, 240 }) do U.P(bb, "Fin", Vector3.new(0.3, 3, 2), U.L(math.cos(math.rad(a)) * 1.8, F + 2.1, math.sin(math.rad(a)) * 1.8, -a), "Bright red", "Metal") end
	U.blk(bb, "Flame", 1.6, 0.6, 1.6, 0, F + 0.6, 0, "Neon orange", "Neon", { nc = true })
end
function ISLAND.trampoline(bb)
	for _, x in ipairs({ -4.5, 4.5 }) do
		U.cyl(bb, "Frame", 7, 0.6, x, F + 1.4, 0, "Bright blue", "Metal")
		U.cyl(bb, "Mat", 6, 0.3, x, F + 1.7, 0, "Really black", "Fabric")
		for _, d in ipairs({ -2.6, 2.6 }) do U.blk(bb, "Leg", 0.4, 1.4, 0.4, x + d, F, 0, "Dark stone grey", "Metal") end
	end
end
function ISLAND.dj(bb)
	U.blk(bb, "Booth", 8, 3.6, 3, 0, F, 0, "Really black", "SmoothPlastic")
	U.blk(bb, "Front", 8, 2, 0.1, 0, F + 1, -1.55, "Royal purple", "Neon")
	for _, x in ipairs({ -2, 2 }) do U.cyl(bb, "Deck", 2, 0.3, x, F + 3.6, 0, "Dark stone grey", "Metal") end
	for _, x in ipairs({ -7, 7 }) do U.blk(bb, "Speaker", 3, 6, 3, x, F, 0, "Really black") U.cyl(bb, "Cone", 2, 0.2, x, F + 4, -1.5, "Dark stone grey") end
end
function ISLAND.carousel(bb)
	U.cyl(bb, "Base", 10, 1, 0, F, 0, "Bright red", "SmoothPlastic")
	U.cyl(bb, "Pole", 1, 8, 0, F + 1, 0, "Gold", "Metal")
	U.cyl(bb, "Top", 10, 1, 0, F + 9, 0, "Bright yellow", "SmoothPlastic")
	local turning = {}
	for a = 0, 270, 90 do
		local x, z = math.cos(math.rad(a)) * 3.4, math.sin(math.rad(a)) * 3.4
		table.insert(turning, U.blk(bb, "Horse", 1, 2, 2.6, x, F + 2.4, z, U.pick({ "Institutional white", "Brown", "Pink" }), nil, { nc = true }, -a))
		table.insert(turning, U.blk(bb, "HorsePole", 0.3, 8, 0.3, x, F + 1, z, "Gold", "Metal", { nc = true }))
	end
	U.spin(turning, bb.cf * U.L(0, F, 0), "y", 40)
end
function ISLAND.zen(bb)
	U.blk(bb, "Sand", 16, 0.4, 8, 0, F, 0, "Brick yellow", "Sand")
	for i = -3, 3 do U.blk(bb, "Rake", 15, 0.05, 0.2, 0, F + 0.4, i, "Light stone grey", nil, { nc = true }) end
	for _, p in ipairs({ { -4, 1 }, { 3, -1 }, { 6, 2 } }) do U.ball(bb, "Stone", 2, p[1], F + 0.8, p[2], "Dark stone grey", "Slate") end
	U.cyl(bb, "Bonsai", 0.6, 2, -6, F + 0.4, -2, "Brown") U.ball(bb, "BonsaiTop", 2.4, -6, F + 3, -2, "Dark green", "Grass")
end
function ISLAND.balloon(bb)
	U.blk(bb, "Basket", 3, 2, 3, 0, F + 1, 0, "Brown", "Wood")
	for _, p in ipairs({ { -1.2, -1.2 }, { 1.2, -1.2 }, { -1.2, 1.2 }, { 1.2, 1.2 } }) do U.blk(bb, "Rope", 0.1, 3, 0.1, p[1], F + 3, p[2], "Brown", nil, { nc = true }) end
	U.ball(bb, "Balloon", 8, 0, F + 9, 0, U.pick({ "Bright red", "Bright yellow", "Royal purple" }), "Fabric", { nc = true })
	U.blk(bb, "Stand", 0.4, 1, 0.4, 0, F, 0, "Dark stone grey")
end
function ISLAND.chess(bb)
	for i = 0, 15 do
		local x, z = i % 4, math.floor(i / 4)
		U.blk(bb, "Square", 2.4, 0.2, 2.4, -3.6 + x * 2.4, F, -3.6 + z * 2.4, (x + z) % 2 == 0 and "Institutional white" or "Really black", "Marble")
	end
	U.cyl(bb, "King", 1.4, 4, -1.2, F + 0.2, -1.2, "Institutional white") U.ball(bb, "Crown", 1, -1.2, F + 4.6, -1.2, "Gold", "Metal")
	U.cyl(bb, "Pawn", 1.2, 2, 1.2, F + 0.2, 1.2, "Really black") U.ball(bb, "Head", 1.2, 1.2, F + 2.6, 1.2, "Really black")
end
function ISLAND.jukebox(bb)
	U.blk(bb, "Jukebox", 3.4, 6, 2, 0, F, 2.4, "Bright red", "SmoothPlastic")
	U.blk(bb, "Glow", 2.6, 2.4, 0.1, 0, F + 3, 1.35, "Bright yellow", "Neon")
	for _, x in ipairs({ -6, 6 }) do U.cyl(bb, "Table", 3, 3, x, F, 0, "Institutional white") U.seat(bb, x, F, -2.6, 180, "Bright red", 1.6) end
end
function ISLAND.robot(bb)
	U.blk(bb, "Legs", 2.4, 3, 1.4, 0, F, 0, "Light stone grey", "Metal")
	U.blk(bb, "Body", 3.4, 3.4, 2, 0, F + 3, 0, "Light stone grey", "Metal")
	U.blk(bb, "Head", 2.4, 2, 2, 0, F + 6.4, 0, "Light stone grey", "Metal")
	for _, x in ipairs({ -0.6, 0.6 }) do U.blk(bb, "Eye", 0.5, 0.5, 0.1, x, F + 7.4, -1.05, "Cyan", "Neon") end
	for _, x in ipairs({ -2.2, 2.2 }) do U.blk(bb, "Arm", 0.8, 3, 0.8, x, F + 3.2, 0, "Dark stone grey", "Metal") end
	U.blk(bb, "Tray", 3, 0.2, 1.6, 2.2, F + 4.6, -1.2, "Institutional white", "Metal")
end
function ISLAND.globe(bb)
	U.cyl(bb, "Pedestal", 5, 3, 0, F, 0, "Institutional white", "Marble")
	local g = U.ball(bb, "Globe", 5, 0, F + 6, 0, "Gold", "Metal", { refl = 0.5 })
	U.fx(g, "Sparkles")
	U.P(bb, "Ring", Vector3.new(0.4, 6.6, 6.6), U.L(0, F + 6, 0, 90, 0, 23), "Gold", "Metal", { shape = "cyl", nc = true })
end
function ISLAND.lightart(bb)
	for i = 0, 4 do U.P(bb, "Ring", Vector3.new(0.4, 6 - i, 6 - i), U.L(0, F + 2 + i * 2, 0, i * 36, 0, 90), U.pick({ "Hot pink", "Cyan", "Lime green", "Bright yellow" }), "Neon", { shape = "cyl", nc = true }) end
	U.cyl(bb, "Base", 3, 1, 0, F, 0, "Really black", "Metal")
end

function K.uisland(b, o)
	local c = b.cf * U.L(o.x, LV[o.fl] - F, o.z)
	local bb = { model = b.model, cf = c, plot = b.plot }
	local ok, err = pcall(ISLAND[o.style] or ISLAND.planter, bb, o)
	if not ok then print("Airport: island " .. tostring(o.style) .. " failed: " .. tostring(err)) end
	if o.x ~= 0 then
		-- people come and look/sit/play here, from the walkway in front of it
		local it = ITEM[o.key]
		PT(b, "up" .. o.fl, { p = Vector3.new(o.x + math.random(-3, 3), LV[o.fl], o.z - 8), spend = it and it.eff.spend or 0, wait = 4 })
	end
end
