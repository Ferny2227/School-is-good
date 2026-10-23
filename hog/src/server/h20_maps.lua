-- ==== h20_maps.lua
------------------------------------------------------------------ the maps
-- A map is a set of rectangular rooms (x1..x2, z1..z2 in studs) and the doorways between them. The builder puts up
-- walls with gaps for the doorways, floors, ceilings, lamps and furniture, and makes the paths the bot Hog walks
-- (room centres, doorways, and points along the corridors). Locked doors are solid until someone uses the right key.
-- items = { item name, "open" (any room that isn't locked) or the id of the room it's always in }
local MAPS = {}
MAPS["Hog Manor"] = {
	H = 14, start = "living", pen = "pen", outside = "Earth green",
	rooms = {
		{ id = "bedroom", name = "Bedroom", x1 = 0, z1 = 0, x2 = 36, z2 = 30, floor = "Reddish brown", wall = "Lavender", kind = "bedroom" },
		{ id = "bath", name = "Bathroom", x1 = 36, z1 = 0, x2 = 64, z2 = 30, floor = "Institutional white", fmat = "Marble", wall = "Pastel blue-green", kind = "bath" },
		{ id = "kitchen", name = "Kitchen", x1 = 64, z1 = 0, x2 = 104, z2 = 30, floor = "Black", fmat = "Slate", wall = "Pastel yellow", kind = "kitchen" },
		{ id = "pantry", name = "Pantry", x1 = 104, z1 = 0, x2 = 132, z2 = 30, floor = "Brown", wall = "Brick yellow", kind = "pantry" },
		{ id = "pen", name = "The Hog Pen", x1 = 132, z1 = 0, x2 = 150, z2 = 30, floor = "Brown", fmat = "Sand", wall = "Dark stone grey", kind = "pen" },
		{ id = "hall", name = "Hallway", x1 = 0, z1 = 30, x2 = 132, z2 = 48, floor = "Dark orange", wall = "Burlap", kind = "hall" },
		{ id = "garage", name = "Garage", x1 = 0, z1 = 48, x2 = 36, z2 = 84, floor = "Medium stone grey", fmat = "Concrete", wall = "Mid gray", kind = "garage" },
		{ id = "living", name = "Living Room", x1 = 36, z1 = 48, x2 = 80, z2 = 84, floor = "Reddish brown", wall = "Sand red", kind = "living" },
		{ id = "dining", name = "Dining Room", x1 = 80, z1 = 48, x2 = 108, z2 = 84, floor = "Brown", wall = "Olive", kind = "dining" },
		{ id = "cellar", name = "Cellar", x1 = 108, z1 = 48, x2 = 132, z2 = 84, floor = "Dark stone grey", fmat = "Cobblestone", wall = "Black", kind = "cellar" },
	},
	doors = {
		{ "hall", "bedroom", 18, lock = "Red Door" }, { "hall", "bath", 50 }, { "hall", "kitchen", 84 }, { "hall", "pantry", 118 },
		{ "hall", "garage", 18 }, { "hall", "living", 58 }, { "hall", "dining", 94 }, { "hall", "cellar", 120, lock = "Blue Door" },
		{ "bath", "kitchen", 15 }, { "kitchen", "pantry", 15 }, { "garage", "living", 66 }, { "living", "dining", 66 },
		{ "pantry", "pen", 15, gate = true }, { "living", "out", 58, side = "S", exit = true },
	},
	items = { { "Hammer", "open" }, { "Blue Key", "open" }, { "Red Key", "open" }, { "Gold Key", "cellar" }, { "Wrench", "bedroom" } },
	exitLocks = { { "Boards", "Hammer" }, { "Padlock", "Gold Key" }, { "Bolt", "Wrench" } },
}
MAPS["School"] = {
	H = 15, start = "cafeteria", pen = "pen", outside = "Dark stone grey",
	rooms = {
		{ id = "classA", name = "Classroom A", x1 = 0, z1 = 0, x2 = 40, z2 = 34, floor = "Light stone grey", fmat = "Marble", wall = "Pastel light blue", kind = "class" },
		{ id = "classB", name = "Classroom B", x1 = 40, z1 = 0, x2 = 80, z2 = 34, floor = "Light stone grey", fmat = "Marble", wall = "Pastel yellow", kind = "class" },
		{ id = "lab", name = "Science Lab", x1 = 80, z1 = 0, x2 = 120, z2 = 34, floor = "White", fmat = "Marble", wall = "Pastel blue-green", kind = "lab" },
		{ id = "library", name = "Library", x1 = 120, z1 = 0, x2 = 160, z2 = 34, floor = "Reddish brown", wall = "Pine Cone", kind = "library" },
		{ id = "hall", name = "Hallway", x1 = 0, z1 = 34, x2 = 160, z2 = 54, floor = "Institutional white", fmat = "Marble", wall = "Pastel Blue", kind = "hall" },
		{ id = "pen", name = "Janitor's Closet", x1 = 160, z1 = 34, x2 = 178, z2 = 54, floor = "Dark stone grey", fmat = "Concrete", wall = "Mid gray", kind = "pen" },
		{ id = "cafeteria", name = "Cafeteria", x1 = 0, z1 = 54, x2 = 60, z2 = 94, floor = "Pastel yellow", fmat = "Marble", wall = "Bright orange", kind = "cafeteria" },
		{ id = "gym", name = "Gym", x1 = 60, z1 = 54, x2 = 112, z2 = 94, floor = "Nougat", fmat = "WoodPlanks", wall = "Bright red", kind = "gym" },
		{ id = "office", name = "Principal's Office", x1 = 112, z1 = 54, x2 = 140, z2 = 94, floor = "Dark green", fmat = "Fabric", wall = "Brick yellow", kind = "office" },
		{ id = "entrance", name = "Entrance", x1 = 140, z1 = 54, x2 = 160, z2 = 94, floor = "Institutional white", fmat = "Marble", wall = "Pastel Blue", kind = "entrance" },
	},
	doors = {
		{ "hall", "classA", 20 }, { "hall", "classB", 60 }, { "hall", "lab", 100, lock = "Red Door" }, { "hall", "library", 140 },
		{ "hall", "cafeteria", 30 }, { "hall", "gym", 86 }, { "hall", "office", 126, lock = "Blue Door" }, { "hall", "entrance", 150 },
		{ "classA", "classB", 17 }, { "cafeteria", "gym", 74 }, { "hall", "pen", 44, gate = true },
		{ "entrance", "out", 150, side = "S", exit = true },
	},
	items = { { "Hammer", "open" }, { "Blue Key", "open" }, { "Red Key", "open" }, { "Gold Key", "lab" }, { "Fuse", "office" } },
	exitLocks = { { "Boards", "Hammer" }, { "Padlock", "Gold Key" }, { "Fuse Box", "Fuse" } },
}
local ITEM_LOOK = {
	["Hammer"] = { "Reddish brown", "Dark stone grey" }, ["Blue Key"] = { "Really blue" }, ["Red Key"] = { "Really red" },
	["Gold Key"] = { "Gold" }, ["Wrench"] = { "Medium stone grey" }, ["Fuse"] = { "New Yeller" },
}
local DOOR_COLOR = { ["Red Door"] = "Really red", ["Blue Door"] = "Really blue" }
local DOOR_KEY = { ["Red Door"] = "Red Key", ["Blue Door"] = "Blue Key" }
local DW, DH = 7, 9                -- doorway width and height

------------------------------------------------------------------ furniture: objects stand in the corners of a room
-- each object is a list of boxes { name, along the wall, height, out from the wall, offset along, y0, offset out,
-- colour, material, opt } - opt.top = an item can lie on top of it
local KITS = {}
local function bx(n, sx, sy, sz, ox, y0, oz, c, m, o) return { n, sx, sy, sz, ox, y0, oz, c, m, o } end
KITS.bedroom = {
	{ "ns", bx("Bed", 7, 2, 11, 0, 0, 0, "Reddish brown", "Wood"), bx("Mattress", 6.4, 1, 10, 0, 2, 0.3, "Institutional white", "Fabric", { top = true }),
		bx("Blanket", 6.6, 0.4, 6, 0, 2.8, 4.6, "Crimson", "Fabric"), bx("Pillow", 4, 0.8, 2, 0, 3, 0.8, "White", "Fabric"), bx("Headboard", 7, 5, 0.6, 0, 0, 0, "Reddish brown", "Wood") },
	{ "ns", bx("Wardrobe", 6, 10, 3, 0, 0, 0, "Dark orange", "Wood"), bx("Handle", 0.3, 1.5, 0.3, 0.6, 4.5, 3, "Gold", "Metal") },
	{ "we", bx("Nightstand", 3, 3, 3, 0, 0, 0, "Dark orange", "Wood", { top = true }), bx("Lamp", 1, 1.6, 1, 0, 3, 1, "Pastel yellow", "Neon") },
	{ "ns", bx("Desk", 6, 3, 3, 0, 0, 0, "Reddish brown", "Wood", { top = true }), bx("Chair", 2, 2, 2, 0, 0, 3.4, "Black", "SmoothPlastic") },
}
KITS.bath = {
	{ "ns", bx("Bathtub", 10, 2.6, 5, 0, 0, 0, "Institutional white", "Marble"), bx("Water", 9, 0.2, 4, 0, 2.2, 0.5, "Pastel light blue", "Glass", { tr = 0.3 }) },
	{ "ns", bx("ToiletBase", 2, 2, 2.6, 0, 0, 0.4, "Institutional white", "Marble"), bx("Tank", 2.6, 2.4, 0.9, 0, 1.4, 0, "Institutional white", "Marble") },
	{ "we", bx("Sink", 3, 3, 2, 0, 0, 0, "Institutional white", "Marble", { top = true }), bx("Mirror", 3, 3, 0.2, 0, 5, 0, "Pastel light blue", "Glass") },
	{ "ns", bx("Towels", 4, 5, 1.5, 0, 0, 0, "Light orange", "Fabric") },
}
KITS.kitchen = {
	{ "ns", bx("Counter", 12, 3.5, 3, 0, 0, 0, "Institutional white", "Marble", { top = true }), bx("Cupboard", 12, 3, 2, 0, 7, 0, "Dark orange", "Wood") },
	{ "ns", bx("Fridge", 4, 9, 4, 0, 0, 0, "White", "Metal"), bx("FridgeLine", 0.2, 6, 0.2, 1.4, 2.5, 4, "Black", "Metal") },
	{ "we", bx("Stove", 4, 3.5, 4, 0, 0, 0, "Black", "Metal", { top = true }), bx("Burner", 1.4, 0.2, 1.4, 0, 3.5, 1, "Really red", "Neon") },
	{ "ns", bx("Table", 6, 3, 5, 0, 0, 1.5, "Brown", "Wood", { top = true }), bx("Chair", 2, 2, 2, -2, 0, 7.2, "Brown", "Wood"), bx("Chair", 2, 2, 2, 2, 0, 7.2, "Brown", "Wood") },
}
KITS.pantry = {
	{ "ns", bx("Shelf", 8, 9, 2.5, 0, 0, 0, "Brown", "Wood"), bx("Jars", 7, 1.2, 1.2, 0, 3, 0.6, "Bright orange", "Glass"), bx("Cans", 7, 1.2, 1.2, 0, 6, 0.6, "Bright red", "Metal") },
	{ "we", bx("Shelf", 8, 9, 2.5, 0, 0, 0, "Brown", "Wood"), bx("Sacks", 7, 2, 1.6, 0, 0.5, 0.4, "Brick yellow", "Fabric") },
	{ "ns", bx("Crate", 4, 4, 4, 0, 0, 0, "Dark orange", "WoodPlanks", { top = true }) },
	{ "we", bx("Barrel", 3, 4, 3, 0, 0, 0, "Reddish brown", "Wood", { top = true }) },
}
KITS.pen = {
	{ "ns", bx("Hay", 6, 3, 4, 0, 0, 0, "Bright yellow", "Grass") },
	{ "we", bx("Trough", 6, 2, 2.5, 0, 0, 0, "Reddish brown", "Wood"), bx("Slop", 5.4, 0.2, 1.8, 0, 1.9, 0.35, "Brown", "Sand") },
	{ "ns", bx("Bones", 3, 0.6, 2, 0, 0, 0, "Institutional white", "SmoothPlastic") },
	{ "we", bx("Hay", 4, 3, 4, 0, 0, 0, "Bright yellow", "Grass") },
}
KITS.garage = {
	{ "ns", bx("CarBody", 12, 3, 6, 0, 1, 0.5, "Bright blue", "SmoothPlastic", { top = true }), bx("CarTop", 7, 2.4, 5.4, -0.5, 4, 0.8, "Bright blue", "SmoothPlastic"),
		bx("Windshield", 0.2, 2, 5, 3, 4.2, 0.8, "Black", "Glass", { tr = 0.3 }), bx("Wheel", 2, 2, 6.6, -3.5, 0, 0.2, "Black", "SmoothPlastic"), bx("Wheel", 2, 2, 6.6, 3.5, 0, 0.2, "Black", "SmoothPlastic") },
	{ "we", bx("Workbench", 8, 3.5, 3, 0, 0, 0, "Reddish brown", "WoodPlanks", { top = true }), bx("Pegboard", 8, 4, 0.3, 0, 5, 0, "Brick yellow", "Wood") },
	{ "ns", bx("OilBarrel", 3, 4, 3, 0, 0, 0, "Bright red", "Metal", { top = true }) },
	{ "we", bx("Tires", 3, 3, 3, 0, 0, 0, "Black", "SmoothPlastic", { top = true }) },
}
KITS.living = {
	{ "ns", bx("Sofa", 9, 2, 4, 0, 0, 0.5, "Bright red", "Fabric", { top = true }), bx("SofaBack", 9, 4, 1, 0, 0, 0, "Bright red", "Fabric") },
	{ "we", bx("TVStand", 6, 2.5, 2.5, 0, 0, 0, "Black", "Wood"), bx("TV", 5, 3, 0.4, 0, 2.5, 0.6, "Really black", "SmoothPlastic") },
	{ "ns", bx("Fireplace", 7, 7, 2.5, 0, 0, 0, "Dark stone grey", "Brick"), bx("Fire", 3, 1.5, 0.6, 0, 0.5, 2.4, "Bright orange", "Neon") },
	{ "we", bx("Armchair", 4, 2, 4, 0, 0, 0.5, "Bright red", "Fabric", { top = true }), bx("ChairBack", 4, 4, 1, 0, 0, 0, "Bright red", "Fabric") },
}
KITS.dining = {
	{ "ns", bx("Cabinet", 7, 6, 2.5, 0, 0, 0, "Reddish brown", "Wood", { top = true }), bx("Plates", 6, 1, 0.3, 0, 4, 2.6, "Institutional white", "SmoothPlastic") },
	{ "we", bx("Plant", 2, 5, 2, 0, 0, 0, "Bright green", "Grass") },
	{ "ns", bx("Clock", 2.5, 8, 2, 0, 0, 0, "Dark orange", "Wood"), bx("Face", 1.8, 1.8, 0.2, 0, 5.5, 2, "Institutional white", "SmoothPlastic") },
	{ "we", bx("Cabinet", 6, 6, 2.5, 0, 0, 0, "Reddish brown", "Wood", { top = true }) },
}
KITS.cellar = {
	{ "ns", bx("Barrel", 3, 4, 3, -2, 0, 0, "Reddish brown", "Wood", { top = true }), bx("Barrel", 3, 4, 3, 2, 0, 0, "Reddish brown", "Wood") },
	{ "we", bx("Crate", 4, 4, 4, 0, 0, 0, "Dark orange", "WoodPlanks", { top = true }), bx("Crate", 3, 3, 3, 0, 4, 0.5, "Dark orange", "WoodPlanks") },
	{ "ns", bx("WineRack", 8, 8, 2, 0, 0, 0, "Brown", "Wood") },
	{ "we", bx("Furnace", 5, 7, 4, 0, 0, 0, "Black", "Metal"), bx("Glow", 2, 1, 0.3, 0, 1.5, 4, "Bright orange", "Neon") },
}
KITS.class = {
	{ "ns", bx("Desk", 5, 3, 3, -3, 0, 2, "Brick yellow", "Wood", { top = true }), bx("Desk", 5, 3, 3, 3, 0, 2, "Brick yellow", "Wood") },
	{ "ns", bx("TeacherDesk", 7, 3.4, 3.5, 0, 0, 0.5, "Reddish brown", "Wood", { top = true }), bx("Apple", 0.8, 0.8, 0.8, 2, 3.4, 1.5, "Really red", "SmoothPlastic") },
	{ "we", bx("Desk", 5, 3, 3, 0, 0, 2, "Brick yellow", "Wood", { top = true }), bx("Chair", 2, 2, 2, 0, 0, 5.5, "Bright blue", "SmoothPlastic") },
	{ "we", bx("Cubbies", 8, 5, 2, 0, 0, 0, "Bright yellow", "Wood", { top = true }) },
	board = true,
}
KITS.lab = {
	{ "ns", bx("LabBench", 10, 3.5, 4, 0, 0, 1, "Black", "Slate", { top = true }), bx("Beaker", 0.8, 1.2, 0.8, 2, 3.5, 2.5, "Lime green", "Neon") },
	{ "ns", bx("LabBench", 10, 3.5, 4, 0, 0, 1, "Black", "Slate", { top = true }), bx("Flask", 1, 1.4, 1, -2, 3.5, 2.5, "Hot pink", "Neon") },
	{ "we", bx("Skeleton", 2, 6, 1, 0, 0, 1, "Institutional white", "SmoothPlastic") },
	{ "we", bx("Cabinet", 7, 7, 2.5, 0, 0, 0, "Institutional white", "Metal", { top = true }) },
	board = true,
}
KITS.library = {
	{ "ns", bx("Bookshelf", 10, 9, 2.5, 0, 0, 0, "Reddish brown", "Wood"), bx("Books", 9, 1.6, 1.4, 0, 2.5, 0.8, "Bright blue", "Fabric"), bx("Books", 9, 1.6, 1.4, 0, 5.5, 0.8, "Bright red", "Fabric") },
	{ "ns", bx("Bookshelf", 10, 9, 2.5, 0, 0, 0, "Reddish brown", "Wood"), bx("Books", 9, 1.6, 1.4, 0, 2.5, 0.8, "Bright green", "Fabric") },
	{ "we", bx("ReadTable", 6, 3, 4, 0, 0, 3, "Brown", "Wood", { top = true }) },
	{ "we", bx("Globe", 2, 4, 2, 0, 0, 1, "Bright blue", "SmoothPlastic", { top = true }) },
}
KITS.cafeteria = {
	{ "ns", bx("LunchTable", 14, 3, 5, 0, 0, 4, "Institutional white", "SmoothPlastic", { top = true }), bx("Bench", 14, 1.8, 1.5, 0, 0, 1.5, "Bright blue", "SmoothPlastic"), bx("Bench", 14, 1.8, 1.5, 0, 0, 10, "Bright blue", "SmoothPlastic") },
	{ "ns", bx("ServingCounter", 14, 3.5, 3, 0, 0, 0, "Medium stone grey", "Metal", { top = true }), bx("Trays", 4, 0.5, 2, 3, 3.5, 0.5, "Bright orange", "SmoothPlastic") },
	{ "ns", bx("LunchTable", 14, 3, 5, 0, 0, 4, "Institutional white", "SmoothPlastic", { top = true }), bx("Bench", 14, 1.8, 1.5, 0, 0, 1.5, "Bright blue", "SmoothPlastic") },
	{ "we", bx("VendingMachine", 5, 8, 3, 0, 0, 0, "Bright red", "SmoothPlastic"), bx("Glass", 3, 4, 0.2, 0, 3, 3, "Pastel light blue", "Neon") },
}
KITS.gym = {
	{ "we", bx("Bleachers", 14, 2, 3, 0, 0, 0, "Brown", "WoodPlanks"), bx("Bleachers2", 14, 2, 3, 0, 2, 0, "Brown", "WoodPlanks"), bx("Bleachers3", 14, 2, 3, 0, 4, 0, "Brown", "WoodPlanks") },
	{ "ns", bx("BallRack", 6, 3, 2, 0, 0, 0, "Medium stone grey", "Metal", { top = true }), bx("Ball", 1.4, 1.4, 1.4, -1.5, 3, 0.5, "Bright orange", "SmoothPlastic") },
	{ "we", bx("Mats", 8, 1.5, 6, 0, 0, 0, "Bright blue", "Fabric", { top = true }) },
	{ "ns", bx("HoopPole", 1, 12, 1, 0, 0, 0, "Medium stone grey", "Metal"), bx("Backboard", 6, 4, 0.3, 0, 9, 1, "Institutional white", "SmoothPlastic") },
}
KITS.office = {
	{ "ns", bx("BigDesk", 8, 3.4, 4, 0, 0, 1.5, "Reddish brown", "Wood", { top = true }), bx("BossChair", 2.4, 4, 2.4, 0, 0, 0, "Black", "Fabric") },
	{ "we", bx("FilingCabinet", 3, 6, 3, 0, 0, 0, "Medium stone grey", "Metal", { top = true }) },
	{ "ns", bx("Plant", 2, 5, 2, 0, 0, 0, "Bright green", "Grass") },
	{ "we", bx("Trophies", 6, 7, 2, 0, 0, 0, "Reddish brown", "Wood"), bx("Cup", 1, 1.5, 1, 0, 3, 0.5, "Gold", "Metal") },
}
KITS.entrance = {
	{ "we", bx("TrophyCase", 6, 7, 2.5, 0, 0, 0, "Reddish brown", "Wood"), bx("CaseGlass", 5.6, 4, 0.2, 0, 2.5, 2.5, "Pastel light blue", "Glass", { tr = 0.5 }) },
	{ "we", bx("Bench", 6, 2, 2, 0, 0, 0, "Brown", "Wood", { top = true }) },
	{ "we", bx("Plant", 2, 5, 2, 0, 0, 0, "Bright green", "Grass") },
	{ "we", bx("Lockers", 6, 8, 2, 0, 0, 0, "Bright blue", "Metal") },
}

------------------------------------------------------------------ build a map
local MAP = nil
local function buildMap(name)
	local def = MAPS[name]
	local H = def.H
	local M = { name = name, def = def, rooms = {}, byId = {}, nodes = {}, locks = {}, spots = {}, items = {}, exitDone = false }
	local m = model(WORLD, "Map")
	M.model = m
	local function wpart(n, sx, sy, sz, x, y0, z, color, mat, opt)
		return blk(m, n, sx, sy, sz, x, y0, z, color, mat, opt)
	end
	local minX, minZ, maxX, maxZ = 1e9, 1e9, -1e9, -1e9
	for _, r in ipairs(def.rooms) do
		local R = { def = r, id = r.id, name = r.name, x1 = r.x1, z1 = r.z1, x2 = r.x2, z2 = r.z2, kind = r.kind, open = {}, blocked = {}, spots = {} }
		R.cx, R.cz, R.w, R.d = (r.x1 + r.x2) / 2, (r.z1 + r.z2) / 2, r.x2 - r.x1, r.z2 - r.z1
		table.insert(M.rooms, R)
		M.byId[r.id] = R
		minX, minZ, maxX, maxZ = math.min(minX, r.x1), math.min(minZ, r.z1), math.max(maxX, r.x2), math.max(maxZ, r.z2)
	end
	M.minX, M.minZ, M.maxX, M.maxZ = minX, minZ, maxX, maxZ
	-- the ground around the building
	wpart("Ground", maxX - minX + 200, 2, maxZ - minZ + 200, (minX + maxX) / 2, -2.2, (minZ + maxZ) / 2, def.outside, def.outside == "Earth green" and "Grass" or "Concrete")
	wpart("Roof", maxX - minX + 4, 1, maxZ - minZ + 4, (minX + maxX) / 2, H + 1, (minZ + maxZ) / 2, "Black", "Slate")
	-- doorways: where each one cuts the walls, and a path point in the middle of it
	local function addNode(x, z, room) local n = { p = V(x, 0, z), links = {}, room = room } table.insert(M.nodes, n) return n end
	local function link(a, b) table.insert(a.links, b) table.insert(b.links, a) end
	M.doorNodes = {}
	for _, d in ipairs(def.doors) do
		local A, B = M.byId[d[1]], M.byId[d[2]]
		local at = d[3]
		local x, z, sideA, sideB
		if d[2] == "out" then
			sideA = d.side
			if sideA == "S" then x, z = at, A.z2 elseif sideA == "N" then x, z = at, A.z1 elseif sideA == "E" then x, z = A.x2, at else x, z = A.x1, at end
		elseif A.x2 == B.x1 then x, z, sideA, sideB = A.x2, at, "E", "W"
		elseif A.x1 == B.x2 then x, z, sideA, sideB = A.x1, at, "W", "E"
		elseif A.z2 == B.z1 then x, z, sideA, sideB = at, A.z2, "S", "N"
		else x, z, sideA, sideB = at, A.z1, "N", "S" end
		local w = d.exit and 9 or DW
		table.insert(A.open, { side = sideA, c = (sideA == "N" or sideA == "S") and x or z, w = w })
		if B then table.insert(B.open, { side = sideB, c = (sideB == "N" or sideB == "S") and x or z, w = w }) end
		local node = addNode(x, z, nil)
		node.door, node.A, node.B, node.vertical = d, A, B, (sideA == "E" or sideA == "W")
		table.insert(M.doorNodes, node)
		d.node = node
	end
	-- floors, ceilings, walls with gaps, a lamp in every room
	for _, R in ipairs(M.rooms) do
		local r = R.def
		wpart("Floor", R.w, 1, R.d, R.cx, -1, R.cz, r.floor, r.fmat or "WoodPlanks")
		wpart("Ceiling", R.w, 1, R.d, R.cx, H, R.cz, "Dark stone grey", "SmoothPlastic")
		for _, side in ipairs({ "N", "S", "W", "E" }) do
			local ns = side == "N" or side == "S"
			local lo, hi = ns and R.x1 or R.z1 + 1, ns and R.x2 or R.z2 - 1
			local fixed = side == "N" and R.z1 + 0.5 or side == "S" and R.z2 - 0.5 or side == "W" and R.x1 + 0.5 or R.x2 - 0.5
			local gaps = {}
			for _, o in ipairs(R.open) do if o.side == side then table.insert(gaps, o) end end
			table.sort(gaps, function(a, b) return a.c < b.c end)
			local function seg(a, b, y0, h)
				if b - a < 0.05 then return end
				if ns then wpart("Wall", b - a, h, 1, (a + b) / 2, y0, fixed, r.wall, "SmoothPlastic")
				else wpart("Wall", 1, h, b - a, fixed, y0, (a + b) / 2, r.wall, "SmoothPlastic") end
			end
			local cur = lo
			for _, g in ipairs(gaps) do
				seg(cur, g.c - g.w / 2, 0, H)
				seg(g.c - g.w / 2, g.c + g.w / 2, DH, H - DH)
				cur = g.c + g.w / 2
			end
			seg(cur, hi, 0, H)
		end
		-- a skirting strip and a ceiling lamp
		local lamp = wpart("Lamp", 3, 0.6, 3, R.cx, H - 0.6, R.cz, "Pastel yellow", "Neon")
		light(lamp, Color3.new(1, 0.85, 0.6), math.max(R.w, R.d) * 0.75, R.kind == "cellar" and 0.5 or 0.9)
		R.lamp = lamp
	end
	-- the path the bot walks: room centres (and points along corridors) joined to the doorways
	for _, R in ipairs(M.rooms) do
		if R.kind == "hall" then
			local long = R.w >= R.d
			local pts = {}
			for _, n in ipairs(M.doorNodes) do
				if n.A == R or n.B == R then
					local q = long and V(n.p.X, 0, R.cz) or V(R.cx, 0, n.p.Z)
					table.insert(pts, { q = q, door = n })
				end
			end
			table.insert(pts, { q = long and V(R.x1 + 4, 0, R.cz) or V(R.cx, 0, R.z1 + 4) })
			table.insert(pts, { q = long and V(R.x2 - 4, 0, R.cz) or V(R.cx, 0, R.z2 - 4) })
			table.sort(pts, function(a, b) if long then return a.q.X < b.q.X end return a.q.Z < b.q.Z end)
			local prev
			R.nodes = {}
			for _, pt in ipairs(pts) do
				local n = addNode(pt.q.X, pt.q.Z, R)
				table.insert(R.nodes, n)
				if pt.door then link(n, pt.door) end
				if prev then link(prev, n) end
				prev = n
			end
		else
			local n = addNode(R.cx, R.cz, R)
			R.nodes = { n }
			for _, dn in ipairs(M.doorNodes) do if dn.A == R or dn.B == R then link(n, dn) end end
		end
	end
	-- furniture in the corners
	local function blocked(R, x, z, pad)
		for _, b in ipairs(R.blocked) do
			if x > b[1] - pad and x < b[3] + pad and z > b[2] - pad and z < b[4] + pad then return true end
		end
		return false
	end
	local function placeObj(R, cx, cz, kit)
		local wall = kit[1]
		local L, Dp = 0, 0
		for i = 2, #kit do
			local b = kit[i]
			L = math.max(L, math.abs(b[5]) + b[2] / 2)
			Dp = math.max(Dp, b[7] + b[4])
		end
		local along, nrm, ext, alongC
		if wall == "ns" then
			along, nrm, ext = V(1, 0, 0), V(0, 0, -cz), R.d
			alongC = cx * (R.w / 2 - 2 - L)
		else
			along, nrm, ext = V(0, 0, 1), V(-cx, 0, 0), R.w
			alongC = cz * (R.d / 2 - 2 - L)
		end
		local C = V(R.cx, 0, R.cz)
		for i = 2, #kit do
			local b = kit[i]
			local o = b[10] or {}
			local pos = C + along * (alongC + b[5]) + nrm * (-(ext / 2) + 1 + b[7] + b[4] / 2)
			local cf = CFrame.new(V(pos.X, b[6] + b[3] / 2, pos.Z), V(pos.X, b[6] + b[3] / 2, pos.Z) + nrm)
			local part = P(m, b[1], V(b[2], b[3], b[4]), cf, b[8], b[9], { tr = o.tr, nc = b[9] == "Neon" })
			if o.top then table.insert(R.spots, V(pos.X, b[6] + b[3], pos.Z)) end
			if b[9] == "Neon" then light(part, part.BrickColor.Color, 8, 0.6) end
		end
		-- the area it covers (items don't land inside furniture)
		local c0 = C + along * alongC + nrm * (-(ext / 2) + 1 + Dp / 2)
		local hx = wall == "ns" and L or Dp / 2
		local hz = wall == "ns" and Dp / 2 or L
		table.insert(R.blocked, { c0.X - hx, c0.Z - hz, c0.X + hx, c0.Z + hz })
	end
	for _, R in ipairs(M.rooms) do
		local kit = KITS[R.kind]
		if kit then
			local corners = { { -1, -1 }, { 1, -1 }, { 1, 1 }, { -1, 1 } }
			for i, k in ipairs(kit) do
				local c = corners[i]
				-- keep doorways in the corners clear (e.g. a side door near a corner)
				placeObj(R, c[1], c[2], k)
			end
			if kit.board then
				-- a chalkboard on the wall opposite the door
				local b = wpart("Chalkboard", 14, 5, 0.4, R.cx, 4, R.z1 + 1.2, "Dark green", "Slate")
				sign(b, pick({ "2 + 2 = 4", "DON'T GET CAUGHT", "HOMEWORK: ESCAPE", "H2O", "THE HOG IS WATCHING" }), "Back", Color3.new(1, 1, 1))
			end
		elseif R.kind == "hall" then
			wpart("Runner", R.w - 6, 0.1, 4, R.cx, 0, R.cz, "Crimson", "Fabric")
			for x = R.x1 + 10, R.x2 - 10, 26 do
				local clear = true
				for _, dn in ipairs(M.doorNodes) do if math.abs(dn.p.Z - R.z1) < 1 and math.abs(dn.p.X - x) < 7 then clear = false end end
				if clear then
				local frame = wpart("Painting", 4, 3, 0.3, x, 5, R.z1 + 1.15, pick({ "Bright blue", "Bright green", "Bright orange", "Pink" }), "SmoothPlastic")
				sign(frame, pick({ "OINK", ":)", "HOME", "RUN", "?" }), "Back", Color3.new(0.1, 0.1, 0.1))
				end
			end
		end
	end
	-- places items can be: on furniture, and on the floor next to the walls (away from doorways)
	for _, R in ipairs(M.rooms) do
		local cand = { V(R.cx - R.w / 2 + 4, 0, R.cz), V(R.cx + R.w / 2 - 4, 0, R.cz), V(R.cx, 0, R.cz - R.d / 2 + 4), V(R.cx, 0, R.cz + R.d / 2 - 4),
			V(R.cx - R.w / 4, 0, R.cz - R.d / 4), V(R.cx + R.w / 4, 0, R.cz + R.d / 4), V(R.cx + R.w / 4, 0, R.cz - R.d / 4), V(R.cx - R.w / 4, 0, R.cz + R.d / 4) }
		for _, q in ipairs(cand) do
			local nearDoor = false
			for _, dn in ipairs(M.doorNodes) do if (flat(dn.p) - flat(q)).magnitude < 7 then nearDoor = true end end
			if not nearDoor and not blocked(R, q.X, q.Z, 1.5) then table.insert(R.spots, q) end
		end
	end
	-- locked doors (a coloured door in the doorway; use the key on it), the Hog's gate, the exit
	local function clicker(part, fn)
		local cd = Instance.new("ClickDetector")
		cd.MaxActivationDistance = 16
		cd.Parent = part
		cd.MouseClick:connect(fn)
		return cd
	end
	M.clicker = clicker
	for _, dn in ipairs(M.doorNodes) do
		local d = dn.door
		local x, z = dn.p.X, dn.p.Z
		local sx, sz = dn.vertical and 2 or DW, dn.vertical and DW or 2
		if d.lock then
			local door = wpart(d.lock, sx, DH, sz, x, 0, z, DOOR_COLOR[d.lock], "SmoothPlastic")
			for _, face in ipairs(dn.vertical and { "Left", "Right" } or { "Front", "Back" }) do
				sign(door, string.upper(d.lock) .. "\nneeds the " .. DOOR_KEY[d.lock], face, Color3.new(1, 1, 1))
			end
			local L = { name = d.lock, need = DOOR_KEY[d.lock], part = door, node = dn, parts = { door } }
			table.insert(M.locks, L)
			dn.lock = L
		elseif d.gate then
			local L = { name = "Gate", node = dn, parts = {}, gate = true }
			local blocker = wpart("GateBlock", sx, DH, sz, x, 0, z, "Black", "SmoothPlastic", { tr = 1 })
			table.insert(L.parts, blocker)
			for i = -3, 3 do
				local bar = wpart("GateBar", 0.4, DH, 0.4, x + (dn.vertical and 0 or i), 0, z + (dn.vertical and i or 0), "Dark stone grey", "Metal")
				table.insert(L.parts, bar)
			end
			dn.lock = L
			M.gate = L
		elseif d.exit then
			-- the exit: a big double door with its locks on the inside
			local A = dn.A
			local out = d.side == "S" and 1 or -1
			local zf = z - out * 0.5
			M.exitDoor = {}
			for _, s in ipairs({ -1, 1 }) do
				local half = wpart("ExitDoor", 4.5, DH, 0.8, x + s * 2.25, 0, zf, "Reddish brown", "Wood")
				table.insert(M.exitDoor, half)
			end
			local sgn = wpart("ExitSign", 5, 1.4, 0.3, x, DH + 0.6, zf - out * 0.6, "Really red", "Neon")
			sign(sgn, "EXIT", d.side == "S" and "Front" or "Back", Color3.new(1, 1, 1))
			local zi = zf - out * 0.6      -- the inner face
			M.exitLocks = {}
			for _, el in ipairs(def.exitLocks) do
				local L = { name = el[1], need = el[2], parts = {}, exit = true }
				if el[1] == "Boards" then
					for _, a in ipairs({ -0.35, 0.35 }) do
						local plank = P(m, "Boards", V(9.5, 0.9, 0.3), CFrame.new(x, 4.5, zi - out * 0.2) * CFrame.Angles(0, 0, a), "Brown", "WoodPlanks")
						table.insert(L.parts, plank)
					end
				elseif el[1] == "Padlock" then
					table.insert(L.parts, P(m, "Padlock", V(1.2, 1.4, 0.6), CFrame.new(x + 1.4, 3.2, zi - out * 0.4), "Gold", "Metal"))
					table.insert(L.parts, P(m, "Padlock", V(0.8, 0.8, 0.2), CFrame.new(x + 1.4, 4.2, zi - out * 0.4), "Medium stone grey", "Metal"))
				elseif el[1] == "Bolt" then
					table.insert(L.parts, P(m, "Bolt", V(3, 0.6, 0.6), CFrame.new(x - 1.2, 6.4, zi - out * 0.4), "Dark stone grey", "Metal"))
				elseif el[1] == "Fuse Box" then
					local fx = x + math.min(7.5, A.w / 2 - 4.5)
					local box = P(m, "Fuse Box", V(2.6, 3.2, 0.7), CFrame.new(fx, 4.5, zi - out * 0.1), "Medium stone grey", "Metal")
					sign(box, "FUSE BOX\n(power for the exit)", d.side == "S" and "Front" or "Back", Color3.new(1, 0.9, 0.2))
					local bulb = P(m, "FuseLight", V(0.6, 0.6, 0.3), CFrame.new(fx, 6.5, zi - out * 0.3), "Really red", "Neon")
					L.bulb = bulb
					table.insert(L.parts, box)
				end
				table.insert(M.locks, L)
				table.insert(M.exitLocks, L)
			end
			-- outside: a porch and the way out
			wpart("Porch", 18, 0.6, 14, x, -0.4, z + out * 7.5, "Brown", "WoodPlanks")
			for _, s in ipairs({ -1, 1 }) do wpart("PorchPost", 0.8, H, 0.8, x + s * 8, 0, z + out * 14, "Reddish brown", "Wood") end
			local glow = wpart("ExitGlow", 16, 0.2, 10, x, 0, z + out * 8, "Lime green", "Neon", { tr = 1, nc = true })
			M.exitGlow = glow
			M.exitZone = { x - 10, math.min(z + out * 2, z + out * 16), x + 10, math.max(z + out * 2, z + out * 16) }
		end
	end
	M.start = M.byId[def.start]
	M.pen = M.byId[def.pen]
	MAP = M
	return M
end
local function roomAt(pos)
	if not MAP then return nil end
	for _, R in ipairs(MAP.rooms) do
		if pos.X >= R.x1 and pos.X <= R.x2 and pos.Z >= R.z1 and pos.Z <= R.z2 then return R end
	end
	return nil
end
