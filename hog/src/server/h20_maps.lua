-- ==== h20_maps.lua
------------------------------------------------------------------ the maps
-- A map is a set of rectangular rooms (x1..x2, z1..z2 in studs) and the doorways between them. The builder puts up
-- walls with gaps for the doorways, floors, ceilings, lamps and furniture, and makes the paths the bot Hog walks
-- (room centres, doorways, and points along the corridors). Locked doors are solid until someone uses the right key.
-- items = { item name, "open" (any room that isn't locked) or the id of the room it's always in }
local MAPS = {}
MAPS["Hog Manor"] = {
	H = 18, scale = 1.25, start = "living", pen = "pen", outside = "Earth green", trim = "Dark orange",
	rooms = {
		{ id = "nursery", name = "Nursery", x1 = 0, z1 = -34, x2 = 36, z2 = 0, floor = "Pastel light blue", fmat = "Fabric", wall = "Pink", kind = "nursery" },
		{ id = "laundry", name = "Laundry Room", x1 = 36, z1 = -34, x2 = 64, z2 = 0, floor = "Institutional white", fmat = "Marble", wall = "Light stone grey", kind = "laundry" },
		{ id = "study", name = "Study", x1 = 64, z1 = -34, x2 = 104, z2 = 0, floor = "Reddish brown", wall = "Dark green", kind = "study" },
		{ id = "books", name = "Library", x1 = 104, z1 = -34, x2 = 132, z2 = 0, floor = "Brown", wall = "Pine Cone", kind = "library" },
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
		{ id = "greenhouse", name = "Greenhouse", x1 = 132, z1 = -34, x2 = 166, z2 = 0, floor = "Brown", fmat = "Slate", wall = "Pastel blue-green", wmat = "Glass", kind = "greenhouse" },
		{ id = "security", name = "Security Room", x1 = 132, z1 = 48, x2 = 160, z2 = 84, floor = "Dark stone grey", fmat = "DiamondPlate", wall = "Medium stone grey", kind = "security" },
	},
	doors = {
		{ "hall", "bedroom", 18, lock = "Red Door" }, { "hall", "bath", 50 }, { "hall", "kitchen", 84 }, { "hall", "pantry", 118 },
		{ "hall", "garage", 18 }, { "hall", "living", 58 }, { "hall", "dining", 94 }, { "hall", "cellar", 120, lock = "Blue Door" },
		{ "bath", "kitchen", 15 }, { "kitchen", "pantry", 15 }, { "garage", "living", 66 }, { "living", "dining", 66 },
		{ "laundry", "bath", 50 }, { "study", "kitchen", 84 }, { "books", "pantry", 118 },
		{ "nursery", "laundry", -17 }, { "laundry", "study", -17 }, { "study", "books", -17 },
		{ "books", "greenhouse", -17 }, { "cellar", "security", 66, lock = "Green Door" },
		{ "pantry", "pen", 15, gate = true }, { "living", "out", 58, side = "S", exit = true },
	},
	vents = { { "garage", "study" }, { "laundry", "dining" }, { "nursery", "living" } },
	items = { { "Hammer", "open" }, { "Blue Key", "open" }, { "Red Key", "open" }, { "Keycard", "cellar" }, { "Gold Key", "security" }, { "Wrench", "bedroom" }, { "Stun Gun", "open" } },
	exitLocks = { { "Boards", "Hammer" }, { "Padlock", "Gold Key" }, { "Generator", "Wrench" }, { "Keypad" } },
}
MAPS["School"] = {
	H = 19, scale = 1.25, start = "cafeteria", pen = "pen", outside = "Dark stone grey", trim = "Medium stone grey",
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
		{ id = "art", name = "Art Room", x1 = 0, z1 = 94, x2 = 30, z2 = 128, floor = "Light stone grey", fmat = "Concrete", wall = "Pastel violet", kind = "art" },
		{ id = "music", name = "Music Room", x1 = 30, z1 = 94, x2 = 60, z2 = 128, floor = "Reddish brown", wall = "Dark orange", kind = "music" },
		{ id = "lockers", name = "Locker Room", x1 = 60, z1 = 94, x2 = 86, z2 = 128, floor = "Medium stone grey", fmat = "Concrete", wall = "Bright blue", kind = "lockers" },
		{ id = "nurse", name = "Nurse's Office", x1 = 86, z1 = 94, x2 = 112, z2 = 128, floor = "Institutional white", fmat = "Marble", wall = "Pastel light blue", kind = "nurse" },
		{ id = "computers", name = "Computer Lab", x1 = 120, z1 = -34, x2 = 160, z2 = 0, floor = "Dark stone grey", fmat = "Fabric", wall = "Pastel Blue", kind = "computers" },
		{ id = "stage", name = "Auditorium", x1 = 112, z1 = 94, x2 = 140, z2 = 128, floor = "Reddish brown", wall = "Crimson", wmat = "Fabric", kind = "stage" },
	},
	doors = {
		{ "hall", "classA", 20 }, { "hall", "classB", 60 }, { "hall", "lab", 100, lock = "Red Door" }, { "hall", "library", 140 },
		{ "hall", "cafeteria", 30 }, { "hall", "gym", 86 }, { "hall", "office", 126, lock = "Blue Door" }, { "hall", "entrance", 150 },
		{ "classA", "classB", 17 }, { "cafeteria", "gym", 74 }, { "hall", "pen", 44, gate = true },
		{ "cafeteria", "art", 15 }, { "cafeteria", "music", 45 }, { "gym", "lockers", 73 }, { "gym", "nurse", 99 },
		{ "art", "music", 111 }, { "music", "lockers", 111 }, { "lockers", "nurse", 111 },
		{ "library", "computers", 140, lock = "Green Door" }, { "nurse", "stage", 111 },
		{ "entrance", "out", 150, side = "S", exit = true },
	},
	vents = { { "classA", "nurse" }, { "library", "art" }, { "classB", "lockers" } },
	items = { { "Hammer", "open" }, { "Blue Key", "open" }, { "Red Key", "open" }, { "Fuse", "lab" }, { "Keycard", "office" }, { "Gold Key", "computers" }, { "Stun Gun", "open" } },
	exitLocks = { { "Boards", "Hammer" }, { "Padlock", "Gold Key" }, { "Fuse Box", "Fuse" }, { "Keypad" } },
}
-- THE CIRCUS (like Piggy's Carnival): one big OPEN fair at night inside a purple fence, with buildings and rides
-- standing around in it - the Big Top (a giant striped tent with metal platforms you can climb), the cafeteria, a red
-- storage shed, the arcade, the roller coaster behind a blue gate, the ferris wheel, a carousel, food carts, benches,
-- trees and lamp posts. The Hog waits in the clowns' trailer. The way out is the big gate under the CARNIVAL arch.
MAPS["Circus"] = {
	H = 18, start = "cafeteria", pen = "pen", outside = "Dark green", trim = "White", noRoof = true,
	rooms = {
		{ id = "cafeteria", name = "Cafeteria", x1 = 20, z1 = 30, x2 = 80, z2 = 80, floor = "Institutional white", fmat = "Marble", wall = "Bright yellow", kind = "cafeteria", h = 14, inside = true },
		{ id = "storage", name = "Storage Shed", x1 = 225, z1 = 22, x2 = 265, z2 = 58, floor = "Dark stone grey", fmat = "Concrete", wall = "Really red", wmat = "WoodPlanks", kind = "storage", h = 13, inside = true },
		{ id = "bigtop", name = "The Big Top", x1 = 100, z1 = 80, x2 = 200, z2 = 160, floor = "Brown", fmat = "Sand", wall = "White", wmat = "Fabric", kind = "bigtop", h = 30, tent = { "Really red", "White" }, inside = true },
		{ id = "arcade", name = "Arcade", x1 = 232, z1 = 82, x2 = 285, z2 = 122, floor = "Black", fmat = "SmoothPlastic", wall = "Bright violet", kind = "arcade", h = 14, inside = true },
		{ id = "coaster", name = "Roller Coaster", x1 = 18, z1 = 180, x2 = 122, z2 = 236, floor = "Brick yellow", fmat = "Cobblestone", wall = "Bright blue", wmat = "WoodPlanks", kind = "coaster", h = 14, outdoor = true, inside = true },
		{ id = "pen", name = "Clown Trailer", x1 = 255, z1 = 195, x2 = 290, z2 = 232, floor = "Brown", fmat = "WoodPlanks", wall = "Bright green", kind = "pen", h = 13, inside = true },
		{ id = "security", name = "Security Office", x1 = 248, z1 = 130, x2 = 280, z2 = 166, floor = "Dark stone grey", fmat = "DiamondPlate", wall = "Medium stone grey", kind = "security", h = 13, inside = true },
		{ id = "haunted", name = "Haunted House", x1 = 140, z1 = 178, x2 = 200, z2 = 232, floor = "Black", fmat = "WoodPlanks", wall = "Dark indigo", wmat = "WoodPlanks", kind = "haunted", h = 16, inside = true },
		{ id = "fair", name = "The Fair", x1 = 0, z1 = 0, x2 = 300, z2 = 250, floor = "Brick yellow", fmat = "Cobblestone", wall = "Bright violet", kind = "open", outdoor = true },
	},
	doors = {
		{ "cafeteria", "fair", 55, side = "E" }, { "cafeteria", "fair", 50, side = "S" },
		{ "storage", "fair", 40, side = "W", lock = "Red Door" },
		{ "bigtop", "fair", 150, side = "N", w = 12 }, { "bigtop", "fair", 120, side = "W", w = 9 }, { "bigtop", "fair", 120, side = "E", w = 9 },
		{ "arcade", "fair", 102, side = "W" },
		{ "coaster", "fair", 70, side = "N", lock = "Blue Door" },
		{ "pen", "fair", 213, side = "W", gate = true },
		{ "security", "fair", 148, side = "W", lock = "Green Door" }, { "haunted", "fair", 170, side = "N" },
		{ "fair", "out", 150, side = "N", exit = true },
	},
	-- the rides and stalls standing out in the open: { kind, x, z }
	props = {
		{ "ferris", 225, 178 }, { "carousel", 60, 128 }, { "arch", 150, 6 },
		{ "booth", 122, 14 }, { "booth", 178, 14 },
		{ "cart", 105, 45, "Bright blue" }, { "cart", 195, 50, "Bright red" }, { "cart", 110, 168, "Lime green" },
		{ "popcorn", 215, 70 }, { "balloons", 92, 172 }, { "balloons", 215, 86 },
		{ "bench", 205, 205 }, { "bench", 245, 205 }, { "bench", 30, 100 }, { "bench", 275, 70 },
		{ "games", 8, 160 }, { "games", 8, 200 }, { "games", 8, 120 },
		{ "tree", 10, 15 }, { "tree", 290, 12 }, { "tree", 12, 240 }, { "tree", 215, 240 }, { "tree", 294, 184 }, { "tree", 88, 100 },
		{ "tree", 215, 100 }, { "tree", 130, 60 },
	},
	vents = { { "cafeteria", "bigtop" }, { "arcade", { "fair", 270, 66 } }, { "haunted", { "fair", 60, 168 } } },
	items = { { "Hammer", "open" }, { "Blue Key", "open" }, { "Red Key", "open" }, { "Keycard", "storage" }, { "Gold Key", "security" }, { "Wrench", "coaster" }, { "Stun Gun", "open" } },
	exitLocks = { { "Boards", "Hammer" }, { "Padlock", "Gold Key" }, { "Generator", "Wrench" }, { "Keypad" } },
}
-- how much ground each ride or stall takes up (the bot walks around these)
local PROP_SIZE = { ferris = { 44, 10 }, carousel = { 26, 26 }, booth = { 8, 6 }, cart = { 7, 6 }, popcorn = { 5, 5 },
	balloons = { 3, 3 }, bench = { 7, 3 }, games = { 10, 14 }, tree = { 3, 3 } }
local ITEM_LOOK = {
	["Hammer"] = { "Reddish brown", "Dark stone grey" }, ["Blue Key"] = { "Really blue" }, ["Red Key"] = { "Really red" },
	["Gold Key"] = { "Gold" }, ["Wrench"] = { "Medium stone grey" }, ["Fuse"] = { "New Yeller" }, ["Stun Gun"] = { "Black", "New Yeller" }, ["Keycard"] = { "Lime green" },
}
local DOOR_COLOR = { ["Red Door"] = "Really red", ["Blue Door"] = "Really blue", ["Green Door"] = "Lime green" }
local DOOR_KEY = { ["Red Door"] = "Red Key", ["Blue Door"] = "Blue Key", ["Green Door"] = "Keycard" }
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

-- (the new Hog Manor rooms)
KITS.nursery = {
	{ "ns", bx("Crib", 6, 3.5, 4, 0, 0, 0.5, "Institutional white", "Wood"), bx("CribMattress", 5.4, 0.6, 3.4, 0, 1.5, 0.8, "Pastel light blue", "Fabric", { top = true }) },
	{ "we", bx("ToyBox", 4, 2.5, 3, 0, 0, 0, "Bright red", "Wood", { top = true }), bx("Teddy", 1.2, 1.6, 1.2, 0, 2.5, 1, "Brown", "Fabric") },
	{ "ns", bx("RockingChair", 3, 4, 3, 0, 0, 0.5, "Brown", "Wood") },
	{ "we", bx("Dresser", 5, 4, 2.5, 0, 0, 0, "Pastel yellow", "Wood", { top = true }) },
}
KITS.laundry = {
	{ "ns", bx("Washer", 4, 4, 4, -2.2, 0, 0, "Institutional white", "Metal", { top = true }), bx("Dryer", 4, 4, 4, 2.2, 0, 0, "Institutional white", "Metal"),
		bx("Door", 2.4, 2.4, 0.2, -2.2, 0.8, 4, "Black", "Glass") },
	{ "we", bx("Basket", 3, 2, 3, 0, 0, 0, "Brick yellow", "Fabric", { top = true }) },
	{ "ns", bx("Sink", 4, 3.5, 3, 0, 0, 0, "Medium stone grey", "Metal", { top = true }) },
	{ "we", bx("Shelf", 6, 7, 2, 0, 0, 0, "Brown", "Wood") },
}
KITS.study = {
	{ "ns", bx("Desk", 8, 3.4, 4, 0, 0, 1, "Reddish brown", "Wood", { top = true }), bx("Lamp", 1, 2, 1, 3, 3.4, 2, "New Yeller", "Neon") },
	{ "we", bx("Bookshelf", 8, 9, 2.5, 0, 0, 0, "Reddish brown", "Wood"), bx("Books", 7, 1.6, 1.4, 0, 3, 0.8, "Bright red", "Fabric") },
	{ "ns", bx("Armchair", 4, 2, 4, 0, 0, 0.5, "Dark green", "Fabric", { top = true }), bx("ChairBack", 4, 4, 1, 0, 0, 0, "Dark green", "Fabric") },
	{ "we", bx("Globe", 2, 4, 2, 0, 0, 1, "Bright blue", "SmoothPlastic", { top = true }) },
}
-- (the new School rooms)
KITS.art = {
	{ "ns", bx("Easel", 3, 6, 1, 0, 0, 2, "Brown", "Wood"), bx("Canvas", 3, 3, 0.2, 0, 3, 1.6, "Institutional white", "Fabric") },
	{ "we", bx("PaintTable", 6, 3, 4, 0, 0, 1, "Brick yellow", "Wood", { top = true }), bx("Paint", 1, 0.6, 1, 1, 3, 2, "Bright violet", "SmoothPlastic") },
	{ "ns", bx("Easel", 3, 6, 1, 0, 0, 2, "Brown", "Wood"), bx("Canvas", 3, 3, 0.2, 0, 3, 1.6, "Bright orange", "Fabric") },
	{ "we", bx("Cubbies", 6, 5, 2, 0, 0, 0, "Bright yellow", "Wood", { top = true }) },
}
KITS.music = {
	{ "ns", bx("Piano", 7, 4, 3, 0, 0, 0, "Really black", "SmoothPlastic", { top = true }), bx("Keys", 6, 0.3, 1, 0, 3, 3, "Institutional white", "SmoothPlastic") },
	{ "we", bx("Drum", 3, 2.5, 3, 0, 0, 0.5, "Bright red", "SmoothPlastic", { top = true }), bx("Cymbal", 2, 0.2, 2, 0, 4, 0.5, "Gold", "Metal") },
	{ "ns", bx("MusicStands", 5, 4, 1, 0, 0, 2, "Black", "Metal") },
	{ "we", bx("Tuba", 2, 3, 2, 0, 0, 0.5, "Gold", "Metal") },
}
KITS.lockers = {
	{ "ns", bx("Lockers", 10, 8, 2, 0, 0, 0, "Bright blue", "Metal") },
	{ "we", bx("Bench", 8, 2, 2, 0, 0, 2, "Brown", "Wood", { top = true }) },
	{ "ns", bx("Lockers", 10, 8, 2, 0, 0, 0, "Bright blue", "Metal") },
	{ "we", bx("Showers", 6, 9, 1, 0, 0, 0, "Institutional white", "Marble") },
}
KITS.nurse = {
	{ "ns", bx("Cot", 4, 2.4, 8, 0, 0, 0, "Institutional white", "Fabric", { top = true }), bx("Pillow", 3, 0.6, 1.6, 0, 2.4, 0.4, "White", "Fabric") },
	{ "we", bx("Cabinet", 5, 6, 2.5, 0, 0, 0, "Institutional white", "Metal", { top = true }), bx("Cross", 1.6, 0.4, 0.2, 0, 4, 2.6, "Really red", "Neon") },
	{ "ns", bx("Scale", 2, 5, 2, 0, 0, 0, "Medium stone grey", "Metal") },
	{ "we", bx("Desk", 5, 3, 3, 0, 0, 0, "Brick yellow", "Wood", { top = true }) },
}
-- (the Circus)
KITS.bigtop = {
	{ "ns", bx("Bleacher1", 30, 2, 3, 0, 0, 6, "Bright red", "WoodPlanks"), bx("Bleacher2", 30, 4, 3, 0, 0, 3, "White", "WoodPlanks"), bx("Bleacher3", 30, 6, 3, 0, 0, 0, "Bright red", "WoodPlanks") },
	{ "ns", bx("Bleacher1", 30, 2, 3, 0, 0, 6, "Bright blue", "WoodPlanks"), bx("Bleacher2", 30, 4, 3, 0, 0, 3, "White", "WoodPlanks"), bx("Bleacher3", 30, 6, 3, 0, 0, 0, "Bright blue", "WoodPlanks") },
	{ "ns", bx("Bleacher1", 30, 2, 3, 0, 0, 6, "Bright red", "WoodPlanks", { top = true }), bx("Bleacher2", 30, 4, 3, 0, 0, 3, "White", "WoodPlanks"), bx("Bleacher3", 30, 6, 3, 0, 0, 0, "Bright red", "WoodPlanks") },
	{ "ns", bx("Bleacher1", 30, 2, 3, 0, 0, 6, "Bright blue", "WoodPlanks", { top = true }), bx("Bleacher2", 30, 4, 3, 0, 0, 3, "White", "WoodPlanks"), bx("Bleacher3", 30, 6, 3, 0, 0, 0, "Bright blue", "WoodPlanks") },
}
KITS.greenhouse = {
	{ "ns", bx("PlantBed", 12, 2, 4, 0, 0, 0.5, "Brown", "WoodPlanks", { top = true }), bx("Plants", 11, 2.5, 3, 0, 2, 1, "Bright green", "Grass") },
	{ "we", bx("Pots", 6, 2, 2, 0, 0, 0.5, "Bright orange", "SmoothPlastic"), bx("Flowers", 6, 1.5, 2, 0, 2, 0.5, "Hot pink", "Grass") },
	{ "ns", bx("PlantBed", 12, 2, 4, 0, 0, 0.5, "Brown", "WoodPlanks", { top = true }), bx("Plants", 11, 3, 3, 0, 2, 1, "Lime green", "Grass") },
	{ "we", bx("WaterTank", 4, 6, 4, 0, 0, 0, "Bright blue", "Metal"), bx("Hose", 0.5, 0.5, 4, 0, 1, 4, "Bright green", "SmoothPlastic") },
}
KITS.security = {
	{ "ns", bx("Monitors", 10, 3.5, 3, 0, 0, 0.5, "Black", "Metal", { top = true }), bx("Screens", 9, 3, 0.2, 0, 4.5, 0.4, "Toothpaste", "Neon") },
	{ "we", bx("Lockers", 6, 8, 2, 0, 0, 0, "Dark stone grey", "Metal") },
	{ "ns", bx("Desk", 6, 3, 3, 0, 0, 0, "Medium stone grey", "Metal", { top = true }), bx("Chair", 2, 3, 2, 0, 0, 3.4, "Black", "Fabric") },
	{ "we", bx("Safe", 3.5, 4, 3, 0, 0, 0, "Dark stone grey", "DiamondPlate", { top = true }), bx("Dial", 1, 1, 0.3, 0, 2, 3, "Gold", "Metal") },
}
KITS.computers = {
	{ "ns", bx("ComputerDesk", 12, 3, 3, 0, 0, 0, "Institutional white", "SmoothPlastic", { top = true }), bx("Screen", 2, 1.6, 0.3, -3, 3, 0.6, "Toothpaste", "Neon"), bx("Screen", 2, 1.6, 0.3, 3, 3, 0.6, "Toothpaste", "Neon") },
	{ "ns", bx("ComputerDesk", 12, 3, 3, 0, 0, 0, "Institutional white", "SmoothPlastic", { top = true }), bx("Screen", 2, 1.6, 0.3, -3, 3, 0.6, "Lime green", "Neon"), bx("Screen", 2, 1.6, 0.3, 3, 3, 0.6, "Toothpaste", "Neon") },
	{ "we", bx("Server", 4, 9, 3, 0, 0, 0, "Black", "Metal"), bx("Lights", 0.3, 6, 0.2, 1, 1.5, 3, "Lime green", "Neon") },
	{ "we", bx("Printer", 4, 3, 3, 0, 0, 0, "Medium stone grey", "SmoothPlastic", { top = true }) },
}
KITS.stage = {
	{ "ns", bx("Stage", 14, 3, 8, 0, 0, 0, "Brown", "WoodPlanks", { top = true }), bx("Curtain", 14, 10, 0.4, 0, 3, 0, "Crimson", "Fabric") },
	{ "ns", bx("Piano", 6, 4, 3, 0, 0, 0, "Really black", "SmoothPlastic", { top = true }) },
	{ "ns", bx("Seats", 12, 2.4, 3, 0, 0, 1, "Bright red", "Fabric", { top = true }), bx("SeatBacks", 12, 2, 0.6, 0, 2.4, 0.8, "Bright red", "Fabric") },
	{ "ns", bx("Seats", 12, 2.4, 3, 0, 0, 1, "Bright red", "Fabric"), bx("SeatBacks", 12, 2, 0.6, 0, 2.4, 0.8, "Bright red", "Fabric") },
}
KITS.haunted = {
	{ "ns", bx("Coffin", 3, 2, 7, 0, 0, 0.5, "Reddish brown", "Wood", { top = true }), bx("Lid", 3.2, 0.4, 7.2, 0, 2, 0.4, "Black", "Wood") },
	{ "we", bx("Tombstone", 3, 4, 1, 0, 0, 1, "Dark stone grey", "Slate"), bx("Tombstone", 3, 3, 1, 0, 0, 4, "Dark stone grey", "Slate") },
	{ "ns", bx("Cauldron", 4, 3, 4, 0, 0, 0.5, "Black", "Metal"), bx("Brew", 3.4, 0.2, 3.4, 0, 3, 0.8, "Lime green", "Neon") },
	{ "we", bx("Skeleton", 2, 6, 1, 0, 0, 1, "Institutional white", "SmoothPlastic"), bx("Cobweb", 5, 5, 0.1, 0, 7, 0, "White", "Fabric", { tr = 0.5 }) },
}
KITS.storage = {
	{ "ns", bx("Crate", 5, 5, 5, -3, 0, 0, "Dark orange", "WoodPlanks", { top = true }), bx("Crate", 4, 4, 4, 3, 0, 0.5, "Dark orange", "WoodPlanks") },
	{ "we", bx("Barrel", 3, 4, 3, 0, 0, 0, "Reddish brown", "Wood", { top = true }), bx("Barrel", 3, 4, 3, 0, 0, 3.4, "Reddish brown", "Wood") },
	{ "ns", bx("Shelf", 10, 8, 2.5, 0, 0, 0, "Medium stone grey", "Metal"), bx("Paint", 9, 1.4, 1.4, 0, 3, 0.6, "Bright blue", "Metal") },
	{ "we", bx("ClownCar", 7, 3, 4, 0, 0.6, 0.5, "Bright yellow", "SmoothPlastic", { top = true }), bx("Wheel", 1.6, 1.6, 4.6, -2.2, 0, 0.2, "Black", "SmoothPlastic") },
}
KITS.arcade = {
	{ "ns", bx("Machine", 3.4, 7, 3, -2, 0, 0, "Bright blue", "SmoothPlastic"), bx("Screen", 2.6, 2, 0.2, -2, 4, 3, "Lime green", "Neon"),
		bx("Machine", 3.4, 7, 3, 2, 0, 0, "Bright red", "SmoothPlastic"), bx("Screen", 2.6, 2, 0.2, 2, 4, 3, "Toothpaste", "Neon") },
	{ "ns", bx("ClawMachine", 5, 8, 5, 0, 0, 0, "Hot pink", "SmoothPlastic"), bx("Glass", 4.4, 3.5, 4.4, 0, 4, 0.3, "Pastel light blue", "Glass", { tr = 0.5 }) },
	{ "we", bx("PrizeCounter", 8, 3.5, 3, 0, 0, 1, "Bright yellow", "WoodPlanks", { top = true }), bx("Prizes", 7, 2, 1.4, 0, 3.5, 1.5, "Bright violet", "Fabric") },
	{ "we", bx("Machine", 3.4, 7, 3, 0, 0, 0, "New Yeller", "SmoothPlastic", { top = true }), bx("Screen", 2.6, 2, 0.2, 0, 4, 3, "Hot pink", "Neon") },
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
		local k = def.scale or 1
		local R = { def = r, id = r.id, name = r.name, x1 = r.x1 * k, z1 = r.z1 * k, x2 = r.x2 * k, z2 = r.z2 * k, kind = r.kind, open = {}, blocked = {}, spots = {} }
		R.cx, R.cz, R.w, R.d = (R.x1 + R.x2) / 2, (R.z1 + R.z2) / 2, R.x2 - R.x1, R.z2 - R.z1
		table.insert(M.rooms, R)
		M.byId[r.id] = R
		minX, minZ, maxX, maxZ = math.min(minX, R.x1), math.min(minZ, R.z1), math.max(maxX, R.x2), math.max(maxZ, R.z2)
	end
	M.minX, M.minZ, M.maxX, M.maxZ = minX, minZ, maxX, maxZ
	-- the ground around the building
	local gm = def.outside == "Dark stone grey" and "Concrete" or "Grass"
	local cxm, czm, wm, dm = (minX + maxX) / 2, (minZ + maxZ) / 2, maxX - minX, maxZ - minZ
	wpart("Ground", wm + 200, 2, 100, cxm, -2.2, minZ - 50, def.outside, gm)
	wpart("Ground", wm + 200, 2, 100, cxm, -2.2, maxZ + 50, def.outside, gm)
	wpart("Ground", 100, 2, dm, minX - 50, -2.2, czm, def.outside, gm)
	wpart("Ground", 100, 2, dm, maxX + 50, -2.2, czm, def.outside, gm)
	if not def.noRoof then wpart("Roof", maxX - minX + 4, 1, maxZ - minZ + 4, (minX + maxX) / 2, H + 1, (minZ + maxZ) / 2, "Black", "Slate") end
	-- doorways: where each one cuts the walls, and a path point in the middle of it
	local function addNode(x, z, room) local n = { p = V(x, 0, z), links = {}, room = room } table.insert(M.nodes, n) return n end
	local function link(a, b) table.insert(a.links, b) table.insert(b.links, a) end
	M.doorNodes = {}
	for _, d in ipairs(def.doors) do
		local A, B = M.byId[d[1]], M.byId[d[2]]
		local at = d[3] * (def.scale or 1)
		local x, z, sideA, sideB
		if d[2] == "out" or (B and B.kind == "open") then
			sideA = d.side
			if sideA == "S" then x, z = at, A.z2 elseif sideA == "N" then x, z = at, A.z1 elseif sideA == "E" then x, z = A.x2, at else x, z = A.x1, at end
		elseif A.x2 == B.x1 then x, z, sideA, sideB = A.x2, at, "E", "W"
		elseif A.x1 == B.x2 then x, z, sideA, sideB = A.x1, at, "W", "E"
		elseif A.z2 == B.z1 then x, z, sideA, sideB = at, A.z2, "S", "N"
		else x, z, sideA, sideB = at, A.z1, "N", "S" end
		local w = d.exit and 9 or d.w or DW
		table.insert(A.open, { side = sideA, c = (sideA == "N" or sideA == "S") and x or z, w = w })
		if B and sideB then table.insert(B.open, { side = sideB, c = (sideB == "N" or sideB == "S") and x or z, w = w }) end
		local node = addNode(x, z, nil)
		node.door, node.A, node.B, node.vertical = d, A, B, (sideA == "E" or sideA == "W")
		table.insert(M.doorNodes, node)
		d.node = node
	end
	-- VENTS (like Piggy): a square hole in the floor of one room, a tunnel under the floor, and a hole in another room.
	-- The tunnel is only 4.6 studs high: you must CROUCH to crawl through it. Ladders get you back out. The Hog can't
	-- follow you down there (and can't see you).
	M.vents = {}
	local holes = {}
	for vi, v in ipairs(def.vents or {}) do
		local ends = {}
		for k = 1, 2 do
			local e = v[k]
			local R, q
			if type(e) == "table" then
				R, q = M.byId[e[1]], V(e[2], 0, e[3])
			else
				-- the middle of a wall with no doorway near it, 4 studs out from the wall
				R = M.byId[e]
				local cands = { V(R.cx, 0, R.z1 + 4.5), V(R.cx, 0, R.z2 - 4.5), V(R.x1 + 4.5, 0, R.cz), V(R.x2 - 4.5, 0, R.cz) }
				for _, c in ipairs(cands) do
					local ok = true
					for _, dn in ipairs(M.doorNodes) do if (flat(dn.p) - c).magnitude < 9 then ok = false end end
					for _, h in ipairs(holes) do if (h - c).magnitude < 8 then ok = false end end
					if ok and not q then q = c end
				end
				q = q or V(R.cx + R.w / 4, 0, R.cz + R.d / 4)
			end
			table.insert(holes, q)
			ends[k] = { at = q, room = R }
		end
		table.insert(M.vents, { a = ends[1], b = ends[2], level = vi - 1 })
	end
	-- floors, ceilings, walls with gaps, a lamp in every room
	for _, R in ipairs(M.rooms) do
		local r = R.def
		local RH = r.h or H
		R.h = RH
		-- the floor, in pieces round any vent holes
		local fy = r.inside and -0.95 or -1
		local function floorPiece(x1, z1, x2, z2, list)
			if x2 - x1 < 0.05 or z2 - z1 < 0.05 then return end
			for i2, h in ipairs(list) do
				if h.X + 2 > x1 and h.X - 2 < x2 and h.Z + 2 > z1 and h.Z - 2 < z2 then
					local rest = {}
					for j2, h2 in ipairs(list) do if j2 ~= i2 then table.insert(rest, h2) end end
					local hx1, hx2, hz1, hz2 = math.max(x1, h.X - 2), math.min(x2, h.X + 2), math.max(z1, h.Z - 2), math.min(z2, h.Z + 2)
					floorPiece(x1, z1, hx1, z2, rest)
					floorPiece(hx2, z1, x2, z2, rest)
					floorPiece(hx1, z1, hx2, hz1, rest)
					floorPiece(hx1, hz2, hx2, z2, rest)
					return
				end
			end
			wpart("Floor", x2 - x1, 1, z2 - z1, (x1 + x2) / 2, fy, (z1 + z2) / 2, r.floor, r.fmat or "WoodPlanks")
		end
		floorPiece(R.x1, R.z1, R.x2, R.z2, holes)
		if not r.outdoor then wpart("Ceiling", R.w, 1, R.d, R.cx, RH, R.cz, r.tent and r.tent[2] or "Dark stone grey", r.tent and "Fabric" or "SmoothPlastic") end
		if r.tent then
			-- a striped tent roof going up to a point, with a flag on top
			for i = 0, 5 do
				local k = 1 - i * 0.16
				wpart("TentRoof", R.w * k + 2, 3, R.d * k + 2, R.cx, RH + 1 + i * 3, R.cz, r.tent[(i % 2) + 1], "Fabric")
			end
			wpart("TentPole", 0.6, 8, 0.6, R.cx, RH + 19, R.cz, "Brown", "Wood")
			wpart("Flag", 3, 2, 0.2, R.cx + 1.6, RH + 24, R.cz, "Bright yellow", "Fabric")
		end
		for _, side in ipairs({ "N", "S", "W", "E" }) do
			local ns = side == "N" or side == "S"
			local lo, hi = ns and R.x1 or R.z1 + 1, ns and R.x2 or R.z2 - 1
			local fixed = side == "N" and R.z1 + 0.5 or side == "S" and R.z2 - 0.5 or side == "W" and R.x1 + 0.5 or R.x2 - 0.5
			local gaps = {}
			for _, o in ipairs(R.open) do if o.side == side then table.insert(gaps, o) end end
			table.sort(gaps, function(a, b) return a.c < b.c end)
			local inward = (side == "N" or side == "W") and 1 or -1
			local function seg(a, b, y0, h)
				if b - a < 0.05 then return end
				if ns then wpart("Wall", b - a, h, 1, (a + b) / 2, y0, fixed, r.wall, r.wmat or "SmoothPlastic")
				else wpart("Wall", 1, h, b - a, fixed, y0, (a + b) / 2, r.wall, r.wmat or "SmoothPlastic") end
				if r.tent and y0 == 0 then
					-- red (or blue) stripes down the inside of the tent
					local f3 = fixed + inward * 0.55
					local q = math.ceil(a / 8) * 8
					while q + 4 <= b do
						if ns then wpart("Stripe", 4, h, 0.1, q + 2, 0, f3, r.tent[1], "Fabric")
						else wpart("Stripe", 0.1, h, 4, f3, 0, q + 2, r.tent[1], "Fabric") end
						q = q + 8
					end
				end
				if y0 == 0 and b - a > 1 and not r.outdoor then
					-- a skirting board along the bottom
					local f2 = fixed + inward * 0.65
					if ns then wpart("Skirting", b - a, 0.9, 0.3, (a + b) / 2, 0, f2, def.trim, "Wood")
					else wpart("Skirting", 0.3, 0.9, b - a, f2, 0, (a + b) / 2, def.trim, "Wood") end
				end
			end
			local cur = lo
			for _, g in ipairs(gaps) do
				seg(cur, g.c - g.w / 2, 0, RH)
				seg(g.c - g.w / 2, g.c + g.w / 2, DH, RH - DH)
				cur = g.c + g.w / 2
			end
			seg(cur, hi, 0, RH)
		end
		-- a skirting strip and a ceiling lamp
		if r.kind == "open" then
			-- (lamp posts: put up with the rides below)
		elseif r.outdoor then
			-- strings of coloured bulbs across the open-air plazas
			local long = R.w >= R.d
			local n = math.floor((long and R.w or R.d) / 10)
			for i = 1, n - 1 do
				local t = -0.5 + i / n
				local bx_, bz_ = long and R.cx + t * R.w or R.cx - R.w * 0.25, long and R.cz - R.d * 0.25 or R.cz + t * R.d
				for k = 0, 1 do
					local x2 = long and bx_ or bx_ + k * R.w * 0.5
					local z2 = long and bz_ + k * R.d * 0.5 or bz_
					local bulb = wpart("Bulb", 0.8, 0.8, 0.8, x2, RH - 3 - (i % 2) * 0.6, z2, pick({ "Really red", "New Yeller", "Lime green", "Toothpaste", "Hot pink" }), "Neon", { nc = true })
					if i % 3 == 0 and k == 0 then light(bulb, Color3.new(1, 0.85, 0.6), 34, 0.9) end
				end
			end
		else
			local lamp = wpart("Lamp", 3, 0.6, 3, R.cx, RH - 0.6, R.cz, "Pastel yellow", "Neon")
			light(lamp, Color3.new(1, 0.85, 0.6), math.max(R.w, R.d) * 0.75, R.kind == "cellar" and 0.5 or 0.9)
			R.lamp = lamp
		end
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
		elseif R.kind == "open" then
			local rects = {}
			for _, Q in ipairs(M.rooms) do
				if Q ~= R then table.insert(rects, { Q.x1 - 2.5, Q.z1 - 2.5, Q.x2 + 2.5, Q.z2 + 2.5 }) end
			end
			for _, pr in ipairs(def.props or {}) do
				local f = PROP_SIZE[pr[1]]
				if f then table.insert(rects, { pr[2] - f[1] / 2 - 2, pr[3] - f[2] / 2 - 2, pr[2] + f[1] / 2 + 2, pr[3] + f[2] / 2 + 2 }) end
			end
			R.rects = rects
			local function free(x, z)
				if x < R.x1 + 3 or x > R.x2 - 3 or z < R.z1 + 3 or z > R.z2 - 3 then return false end
				for _, b in ipairs(rects) do if x > b[1] and x < b[3] and z > b[2] and z < b[4] then return false end end
				return true
			end
			local function clear(a, b, skip)
				local d = b - a
				local n = math.ceil(d.magnitude / 2)
				for k = 0, n do
					local q = a + d * (k / math.max(1, n))
					if (q - a).magnitude >= (skip or 0) and not free(q.X, q.Z) then return false end
				end
				return true
			end
			R.free, R.clear = free, clear
			local G = 10
			local grid = {}
			R.nodes = {}
			for gx = R.x1 + 8, R.x2 - 8, G do
				for gz = R.z1 + 8, R.z2 - 8, G do
					if free(gx, gz) then
						local n = addNode(gx, gz, R)
						grid[gx .. "," .. gz] = n
						table.insert(R.nodes, n)
					end
				end
			end
			for _, n in ipairs(R.nodes) do
				for _, o in ipairs({ { G, 0 }, { 0, G }, { G, G }, { G, -G } }) do
					local m2 = grid[(n.p.X + o[1]) .. "," .. (n.p.Z + o[2])]
					if m2 and clear(n.p, m2.p) then link(n, m2) end
				end
			end
			-- keep only the biggest connected set of points (a point boxed in by rides would be a dead end)
			local best, bestN = nil, 0
			local done = {}
			for _, n in ipairs(R.nodes) do
				if not done[n] then
					local comp, q, k = {}, { n }, 1
					done[n] = true
					while q[k] do
						local x = q[k]
						k = k + 1
						table.insert(comp, x)
						for _, l in ipairs(x.links) do if not done[l] and l.room == R then done[l] = true table.insert(q, l) end end
					end
					if #comp > bestN then best, bestN = comp, #comp end
				end
			end
			R.nodes = best or {}
			-- each doorway joins the nearest grid points it can walk straight to
			for _, dn in ipairs(M.doorNodes) do
				if dn.A == R or dn.B == R then
					local list = {}
					for _, n in ipairs(R.nodes) do table.insert(list, { n, (n.p - dn.p).magnitude }) end
					table.sort(list, function(a, b) return a[2] < b[2] end)
					local got = 0
					for _, e in ipairs(list) do
						if got < 2 and e[2] < 40 and clear(dn.p, e[1].p, 4) then link(dn, e[1]) got = got + 1 end
					end
				end
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
	-- windows on the outside walls (moonlight coming in), rugs on the floors
	local RUG = { bedroom = "Bright violet", living = "Crimson", dining = "Dark green", office = "Bright red", library = "Navy blue", bath = "Pastel blue-green", class = "Bright yellow", entrance = "Crimson", kitchen = "Bright orange" }
	for _, R in ipairs(M.rooms) do
		for _, side in ipairs({ "N", "S", "W", "E" }) do
			local outside = (side == "N" and R.z1 == minZ) or (side == "S" and R.z2 == maxZ) or (side == "W" and R.x1 == minX) or (side == "E" and R.x2 == maxX)
			local free = true
			for _, o in ipairs(R.open) do if o.side == side then free = false end end
			if outside and free and not (side == "N" and KITS[R.kind] and KITS[R.kind].board) and R.kind ~= "pen" and R.kind ~= "hall" and not R.def.outdoor and not R.def.tent then
				local ns = side == "N" or side == "S"
				local f = side == "N" and R.z1 + 1.1 or side == "S" and R.z2 - 1.1 or side == "W" and R.x1 + 1.1 or R.x2 - 1.1
				local wx, wz = ns and R.cx or f, ns and f or R.cz
				local glass = wpart("Window", ns and 7 or 0.2, 5, ns and 0.2 or 7, wx, 4, wz, "Navy blue", "Glass", { tr = 0.1 })
				light(glass, Color3.new(0.55, 0.65, 1), 18, 0.6)
				wpart("WindowFrame", ns and 7.6 or 0.4, 0.5, ns and 0.4 or 7.6, wx, 3.6, wz, def.trim, "Wood")
				wpart("WindowFrame", ns and 7.6 or 0.4, 0.5, ns and 0.4 or 7.6, wx, 9, wz, def.trim, "Wood")
				wpart("WindowFrame", ns and 0.4 or 0.4, 5, ns and 0.4 or 0.4, wx, 4, wz, def.trim, "Wood")
				wpart("WindowFrame", ns and 7 or 0.4, 0.3, ns and 0.4 or 7, wx, 6.35, wz, def.trim, "Wood")
			end
		end
		if RUG[R.kind] then
			wpart("Rug", R.w * 0.4, 0.1, R.d * 0.4, R.cx, 0, R.cz, RUG[R.kind], "Fabric", { nc = true })
		end
	end
	-- the circus extras: the ring in the Big Top, trapezes, and a ferris wheel
	for _, R in ipairs(M.rooms) do
		if R.kind == "bigtop" then
			P(m, "Ring", V(0.5, 36, 36), CFrame.new(R.cx, 0.25, R.cz) * CFrame.Angles(0, 0, math.pi / 2), "Really red", "SmoothPlastic", { shape = "cyl", nc = true })
			P(m, "RingSand", V(0.52, 32, 32), CFrame.new(R.cx, 0.26, R.cz) * CFrame.Angles(0, 0, math.pi / 2), "Brick yellow", "Sand", { shape = "cyl", nc = true })
			for _, sx in ipairs({ -1, 1 }) do
				wpart("TrapezePole", 1, R.h - 2, 1, R.cx + sx * 30, 0, R.cz - 14, "Medium stone grey", "Metal")
				wpart("TrapezePole", 1, R.h - 2, 1, R.cx + sx * 30, 0, R.cz + 14, "Medium stone grey", "Metal")
				wpart("Trapeze", 0.4, 0.4, 6, R.cx + sx * 30, R.h - 12, R.cz, "Bright yellow", "Metal", { nc = true })
				local spot = wpart("Spotlight", 2, 2, 2, R.cx + sx * 20, R.h - 3, R.cz, "New Yeller", "Neon", { nc = true })
				light(spot, Color3.new(1, 0.9, 0.6), 50, 1.2)
				-- a metal platform up high, with a ladder (items can be up there; the Hog can't climb)
				for _, sz in ipairs({ -1, 1 }) do
					local px, pz = R.cx + sx * 40, R.cz + sz * 17
					wpart("Platform", 8, 1, 8, px, 10, pz, "Medium stone grey", "DiamondPlate")
					for _, lx in ipairs({ -3.5, 3.5 }) do wpart("PlatformLeg", 0.6, 10, 0.6, px + lx, 0, pz + lx, "Dark stone grey", "Metal") end
					P(m, "Ladder", V(2, 10, 2), CFrame.new(px - sx * 5, 5, pz), "Dark stone grey", "Metal", { class = "TrussPart" })
					table.insert(R.spots, V(px, 11, pz))
				end
			end
		elseif R.kind == "coaster" then
			-- a track loop up on posts round the yard, a lift hill and a train of cars at the station
			local inset, y = 8, 7
			local x1, x2, z1, z2 = R.x1 + inset, R.x2 - inset, R.z1 + inset, R.z2 - inset
			local door = R.open[1]
			local function rail(ax, az, bx2, bz, hy)
				local a, b = V(ax, hy, az), V(bx2, hy, bz)
				P(m, "Track", V(2.4, 0.5, (b - a).magnitude + 2.4), CFrame.new((a + b) / 2, b), "Dark stone grey", "Metal")
				P(m, "Rail", V(0.3, 0.4, (b - a).magnitude + 2.4), CFrame.new((a + b) / 2 + V(0, 0.4, 0), b + V(0, 0.4, 0)), "Really red", "Metal")
			end
			rail(x1, z1, x2, z1, y) rail(x2, z1, x2, z2, y + 6) rail(x2, z2, x1, z2, y) rail(x1, z2, x1, z1, y)
			for x = x1, x2, 12 do
				for _, z in ipairs({ z1, z2 }) do
					if not (door and math.abs(x - door.c) < 6 and z == z1) then wpart("Support", 0.8, y, 0.8, x, 0, z, "Bright red", "Metal") end
				end
			end
			for z = z1, z2, 12 do
				wpart("Support", 0.8, y, 0.8, x1, 0, z, "Bright red", "Metal")
				wpart("Support", 0.8, y + 6, 0.8, x2, 0, z, "Bright red", "Metal")
			end
			for k = 0, 2 do
				local car = wpart("CoasterCar", 3, 2, 4, x1 + 12 + k * 5, y + 0.8, z2, k == 1 and "New Yeller" or "Really red", "SmoothPlastic")
				car.CFrame = CFrame.new(car.Position) * CFrame.Angles(0, math.pi / 2, 0)
			end
			wpart("Station", 20, 1, 6, x1 + 16, 0, z2 - 6, "Brown", "WoodPlanks")
			local sg = wpart("StationSign", 12, 3, 0.4, x1 + 16, 9, z2 - 9, "Really black", "SmoothPlastic")
			sign(sg, "THE PIG DIPPER", "Front", Color3.new(1, 0.85, 0.2))
		elseif R.kind == "open" then
			local function block(x, z, w, d) table.insert(R.blocked, { x - w / 2, z - d / 2, x + w / 2, z + d / 2 }) end
			for _, pr in ipairs(def.props or {}) do
				local k, x, z = pr[1], pr[2], pr[3]
				local f = PROP_SIZE[k] or { 4, 4 }
				block(x, z, f[1], f[2])
				if k == "ferris" then
					local c = V(x, 24, z)
					for i = 0, 15 do
						local a = i / 16 * math.pi * 2
						local rim = V(math.cos(a) * 18, math.sin(a) * 18, 0)
						P(m, "WheelRim", V(7.4, 0.8, 0.8), CFrame.new(c + rim) * CFrame.Angles(0, 0, a + math.pi / 2), "White", "Metal")
						if i % 2 == 0 then
							P(m, "Spoke", V(18, 0.4, 0.4), CFrame.new(c + rim * 0.5) * CFrame.Angles(0, 0, a), "Medium stone grey", "Metal", { nc = true })
							P(m, "Cabin", V(3.6, 3, 3.2), CFrame.new(c + rim - V(0, 2.4, 0)), pick({ "Really red", "Bright blue", "New Yeller", "Lime green", "Hot pink" }), "SmoothPlastic")
						else
							local bulb = P(m, "WheelBulb", V(1, 1, 1), CFrame.new(c + rim * 1.06), pick({ "Really red", "New Yeller", "Toothpaste" }), "Neon", { nc = true })
							if i % 4 == 1 then light(bulb, bulb.BrickColor.Color, 26, 1) end
						end
					end
					P(m, "Hub", V(2, 3, 3), CFrame.new(c) * CFrame.Angles(0, math.pi / 2, 0), "Dark stone grey", "Metal", { shape = "cyl" })
					for _, sx in ipairs({ -1, 1 }) do
						local foot = V(x + sx * 11, 0, z)
						P(m, "Leg", V(1.4, (c - foot).magnitude, 1.4), CFrame.new((foot + c) / 2, c) * CFrame.Angles(math.pi / 2, 0, 0), "Medium stone grey", "Metal")
					end
					wpart("WheelBase", 26, 1, 8, x, 0, z, "Dark stone grey", "Concrete")
				elseif k == "carousel" then
					P(m, "CarouselBase", V(1, 24, 24), CFrame.new(x, 0.5, z) * CFrame.Angles(0, 0, math.pi / 2), "Institutional white", "WoodPlanks", { shape = "cyl" })
					wpart("CenterPole", 3, 12, 3, x, 1, z, "Gold", "Metal")
					P(m, "CarouselRoof", V(1.5, 27, 27), CFrame.new(x, 13.5, z) * CFrame.Angles(0, 0, math.pi / 2), "Really red", "Fabric", { shape = "cyl" })
					P(m, "CarouselRoof", V(2, 16, 16), CFrame.new(x, 15, z) * CFrame.Angles(0, 0, math.pi / 2), "White", "Fabric", { shape = "cyl" })
					for i = 0, 7 do
						local a = i / 8 * math.pi * 2
						local hx, hz = x + math.cos(a) * 9, z + math.sin(a) * 9
						wpart("HorsePole", 0.4, 12, 0.4, hx, 1, hz, "Gold", "Metal")
						local horse = P(m, "Horse", V(1.2, 2, 4), CFrame.new(hx, 4, hz) * CFrame.Angles(0, -a, 0), pick({ "Institutional white", "Pastel brown", "Black" }), "SmoothPlastic")
						P(m, "HorseHead", V(1, 2, 1.4), horse.CFrame * CFrame.new(0, 1.2, -2), horse.BrickColor.Name, "SmoothPlastic")
					end
					light(wpart("CarouselLight", 2, 1, 2, x, 12, z, "New Yeller", "Neon"), Color3.new(1, 0.85, 0.5), 30, 1.2)
				elseif k == "arch" then
					-- the big entrance arch over the exit gate
					for _, sx in ipairs({ -1, 1 }) do
						for i = 0, 5 do wpart("ArchPillar", 3, 3, 3, x + sx * 13, i * 3, z, i % 2 == 0 and "Really red" or "White", "SmoothPlastic") end
						local ball = wpart("ArchBall", 3, 3, 3, x + sx * 13, 18, z, "Gold", "Neon")
						light(ball, Color3.new(1, 0.8, 0.3), 26, 1)
					end
					local top = wpart("ArchSign", 29, 4, 1.2, x, 18, z, "Bright violet", "SmoothPlastic")
					sign(top, "HOG'S CARNIVAL", "Back", Color3.new(1, 0.9, 0.3))
					sign(top, "HOG'S CARNIVAL", "Front", Color3.new(1, 0.9, 0.3))
				elseif k == "booth" then
					wpart("Booth", 7, 9, 5, x, 0, z, "Bright red", "WoodPlanks")
					wpart("BoothWindow", 4, 2.5, 0.2, x, 4, z + 2.6, "Black", "Glass")
					wpart("BoothRoof", 8, 1, 6, x, 9, z, "White", "Fabric")
					local t = wpart("BoothSign", 6, 1.4, 0.2, x, 7, z + 2.6, "New Yeller", "SmoothPlastic")
					sign(t, "TICKETS", "Back", Color3.new(0.6, 0, 0))
				elseif k == "cart" then
					local c = pr[4] or "Bright blue"
					wpart("CartBody", 6, 3, 4, x, 1.2, z, c, "SmoothPlastic")
					table.insert(R.spots, V(x, 4.2, z))
					for _, sx in ipairs({ -1, 1 }) do
						P(m, "Wheel", V(0.6, 2.6, 2.6), CFrame.new(x + sx * 1.8, 1.3, z + 2.2) * CFrame.Angles(0, math.pi / 2, 0), "Black", "SmoothPlastic", { shape = "cyl" })
						wpart("Post", 0.4, 4, 0.4, x + sx * 2.6, 4.2, z - 1.6, c, "Metal")
						wpart("Post", 0.4, 4, 0.4, x + sx * 2.6, 4.2, z + 1.6, c, "Metal")
					end
					wpart("Canopy", 7, 0.6, 5, x, 8.2, z, "Institutional white", "Fabric")
				elseif k == "popcorn" then
					wpart("Popcorn", 4, 7, 4, x, 0, z, "Bright red", "SmoothPlastic")
					wpart("PopcornTop", 4.4, 1.6, 4.4, x, 7, z, "New Yeller", "SmoothPlastic")
					table.insert(R.spots, V(x, 8.6, z))
				elseif k == "balloons" then
					wpart("String", 0.2, 8, 0.2, x, 0, z, "White", "SmoothPlastic", { nc = true })
					for i = 0, 4 do
						P(m, "Balloon", V(2, 2.4, 2), CFrame.new(x + math.cos(i * 1.3) * 1.5, 9 + (i % 2) * 1.5, z + math.sin(i * 1.3) * 1.5),
							pick({ "Really red", "Bright blue", "New Yeller", "Lime green", "Hot pink" }), "SmoothPlastic", { shape = "ball", nc = true })
					end
				elseif k == "bench" then
					wpart("Bench", 6, 2, 2, x, 0, z, "Brown", "Wood")
					wpart("BenchBack", 6, 2, 0.4, x, 2, z - 0.8, "Brown", "Wood")
					table.insert(R.spots, V(x, 2, z))
				elseif k == "games" then
					-- a game stall against the fence: counter, striped awning, prizes
					local face = x < R.cx and 1 or -1
					wpart("Stall", 4, 7, 14, x - face * 1, 0, z, "Bright yellow", "WoodPlanks")
					wpart("Counter", 2, 3.5, 14, x + face * 2.5, 0, z, "Bright red", "WoodPlanks")
					table.insert(R.spots, V(x + face * 2.5, 3.5, z))
					for i = -3, 3 do wpart("Awning", 6, 0.5, 2, x + face * 1.5, 8, z + i * 2, i % 2 == 0 and "Really red" or "White", "Fabric") end
					for i = -2, 2 do P(m, "Prize", V(1.2, 1.6, 1.2), CFrame.new(x - face * 0.5, 5, z + i * 2.4), pick({ "Hot pink", "Bright blue", "Lime green" }), "Fabric") end
				elseif k == "tree" then
					wpart("Trunk", 1.8, 10, 1.8, x, 0, z, "Brown", "Wood")
					wpart("Leaves", 8, 7, 8, x, 9, z, "Bright green", "Grass")
					wpart("Leaves2", 5, 3, 5, x, 15.5, z, "Bright green", "Grass")
					wpart("GrassPatch", 10, 0.1, 10, x, 0, z, "Bright green", "Grass", { nc = true })
				end
			end
			-- lamp posts between the paths (glowing lanterns light up the fair)
			local n = 0
			for lx = R.x1 + 30, R.x2 - 20, 45 do
				for lz = R.z1 + 30, R.z2 - 20, 45 do
					if R.free(lx, lz) then
						n = n + 1
						wpart("LampPost", 0.6, 12, 0.6, lx, 0, lz, "Black", "Metal")
						local lan = wpart("Lantern", 1.6, 1.6, 1.6, lx, 12, lz, "New Yeller", "Neon")
						light(lan, Color3.new(1, 0.85, 0.55), 40, 1.1)
					end
				end
			end
			-- a white picket fence along the inside of the purple wall
			for _, side in ipairs({ { R.x1 + 2, R.cz, 0.4, R.d - 4 }, { R.x2 - 2, R.cz, 0.4, R.d - 4 }, { R.cx, R.z2 - 2, R.w - 4, 0.4 } }) do
				wpart("FenceRail", side[3], 0.4, side[4], side[1], 1.2, side[2], "Institutional white", "Wood")
				wpart("FenceRail", side[3], 0.4, side[4], side[1], 2.6, side[2], "Institutional white", "Wood")
			end
			-- items lie about the fair too
			for idx, nd in ipairs(R.nodes) do
				if idx % 3 == 0 then
					local q = nd.p + V(4, 0, 4)
					if R.free(q.X, q.Z) and not blocked(R, q.X, q.Z, 1) then table.insert(R.spots, q) end
				end
			end
		end
	end
	-- places items can be: on furniture, and on the floor next to the walls (away from doorways)
	for _, R in ipairs(M.rooms) do
		local cand = R.kind == "open" and {} or { V(R.cx - R.w / 2 + 4, 0, R.cz), V(R.cx + R.w / 2 - 4, 0, R.cz), V(R.cx, 0, R.cz - R.d / 2 + 4), V(R.cx, 0, R.cz + R.d / 2 - 4),
			V(R.cx - R.w / 4, 0, R.cz - R.d / 4), V(R.cx + R.w / 4, 0, R.cz + R.d / 4), V(R.cx + R.w / 4, 0, R.cz - R.d / 4), V(R.cx - R.w / 4, 0, R.cz + R.d / 4) }
		for _, q in ipairs(cand) do
			local nearDoor = false
			for _, dn in ipairs(M.doorNodes) do if (flat(dn.p) - flat(q)).magnitude < 7 then nearDoor = true end end
			for _, h in ipairs(holes) do if (h - flat(q)).magnitude < 5 then nearDoor = true end end
			if not nearDoor and not blocked(R, q.X, q.Z, 1.5) then table.insert(R.spots, q) end
		end
	end
	-- the vent tunnels: an L under the floors from one hole to the other (each vent at its own depth so they never cross)
	local DUCT, DH2 = "Medium stone grey", 4.6
	for _, v in ipairs(M.vents) do
		local top = -1.6 - v.level * 6.5          -- the bottom of the tunnel's ceiling
		local bot = top - DH2                     -- the tunnel's floor
		local A, B = v.a.at, v.b.at
		local function slab(x1, z1, x2, z2, y0, h, name)
			local lx, lz = math.abs(x2 - x1), math.abs(z2 - z1)
			if lx < 0.05 or lz < 0.05 then return end
			wpart(name or "Duct", lx, h, lz, (x1 + x2) / 2, y0, (z1 + z2) / 2, DUCT, "DiamondPlate")
		end
		local sx = (B.X >= A.X) and 1 or -1
		local sz = (B.Z >= A.Z) and 1 or -1
		local C = V(B.X, 0, A.Z)
		-- along X from A to the corner, then along Z to B
		slab(A.X - sx * 2.5, A.Z - 2.5, C.X + sx * 2.5, A.Z + 2.5, bot - 0.6, 0.6, "DuctFloor")
		slab(C.X - 2.5, A.Z, C.X + 2.5, B.Z + sz * 2.5, bot - 0.6, 0.6, "DuctFloor")
		-- the ceiling, with a gap under each hole
		local function topPiece(x1, z1, x2, z2)
			local lo, hi = math.min(x1, x2), math.max(x1, x2)
			local lz, hz = math.min(z1, z2), math.max(z1, z2)
			local cut = {}
			for _, q in ipairs({ A, B }) do if q.X > lo - 2 and q.X < hi + 2 and q.Z > lz - 2 and q.Z < hz + 2 then table.insert(cut, q) end end
			-- split along the tunnel round the holes (holes are 4 x 4, tunnels 5 wide)
			local alongX = (hi - lo) >= (hz - lz)
			local a0, a1 = alongX and lo or lz, alongX and hi or hz
			table.sort(cut, function(p1, p2) if alongX then return p1.X < p2.X end return p1.Z < p2.Z end)
			local cur = a0
			for _, q in ipairs(cut) do
				local c = alongX and q.X or q.Z
				if alongX then slab(cur, lz, c - 2, hz, top, 0.6, "DuctTop") else slab(lo, cur, hi, c - 2, top, 0.6, "DuctTop") end
				cur = c + 2
			end
			if alongX then slab(cur, lz, a1, hz, top, 0.6, "DuctTop") else slab(lo, cur, hi, a1, top, 0.6, "DuctTop") end
		end
		topPiece(A.X - sx * 2.5, A.Z - 2.5, C.X + sx * 2.5, A.Z + 2.5)
		if math.abs(B.Z - A.Z) > 2.5 then topPiece(C.X - 2.5, A.Z + sz * 2.5, C.X + 2.5, B.Z + sz * 2.5) end
		slab(A.X - sx * 2.5, A.Z + sz * 2.5, C.X - sx * 2.5, A.Z + sz * 3.1, bot, DH2)          -- the inside wall
		slab(A.X - sx * 2.5, A.Z - sz * 3.1, C.X + sx * 3.1, A.Z - sz * 2.5, bot, DH2)          -- the outside wall
		slab(C.X - sx * 3.1, A.Z + sz * 2.5, C.X - sx * 2.5, B.Z + sz * 2.5, bot, DH2)
		slab(C.X + sx * 2.5, A.Z - sz * 2.5, C.X + sx * 3.1, B.Z + sz * 3.1, bot, DH2)
		slab(A.X - sx * 3.1, A.Z - 2.5, A.X - sx * 2.5, A.Z + 2.5, bot, DH2)                    -- the ends
		slab(C.X - 2.5, B.Z + sz * 2.5, C.X + 2.5, B.Z + sz * 3.1, bot, DH2)
		-- at each end: a shaft up to the room (deeper vents), a metal frame round the hole, a ladder
		for _, e in ipairs({ v.a, v.b }) do
			local q = e.at
			if top + 0.6 < -1 then
				slab(q.X - 2.6, q.Z - 2.6, q.X + 2.6, q.Z - 2, top + 0.6, -1 - top - 0.6, "Shaft")
				slab(q.X - 2.6, q.Z + 2, q.X + 2.6, q.Z + 2.6, top + 0.6, -1 - top - 0.6, "Shaft")
				slab(q.X - 2.6, q.Z - 2, q.X - 2, q.Z + 2, top + 0.6, -1 - top - 0.6, "Shaft")
				slab(q.X + 2, q.Z - 2, q.X + 2.6, q.Z + 2, top + 0.6, -1 - top - 0.6, "Shaft")
			end
			for _, o in ipairs({ { 0, -2.2, 4.8, 0.4 }, { 0, 2.2, 4.8, 0.4 }, { -2.2, 0, 0.4, 4 }, { 2.2, 0, 0.4, 4 } }) do
				wpart("VentFrame", o[3], 0.3, o[4], q.X + o[1], 0, q.Z + o[2], "Dark stone grey", "Metal")
			end
			P(m, "VentLadder", V(2, math.floor((-bot + 1) / 2) * 2, 2), CFrame.new(q.X + 1, bot + (-bot + 1) / 2, q.Z + 1), "Dark stone grey", "Metal", { class = "TrussPart" })
			light(wpart("DuctLight", 0.6, 0.3, 0.6, q.X - 1.5, top - 0.3, q.Z - 1.5, "Pastel yellow", "Neon", { nc = true }), Color3.new(1, 0.9, 0.6), 10, 0.4)
		end
		v.top, v.bot = top, bot
	end
	-- locked doors (a coloured door in the doorway; use the key on it), the Hog's gate, the exit
	M.partItem, M.partLock = {}, {}
	function M.clickable(part)
		local cd = Instance.new("ClickDetector")
		cd.MaxActivationDistance = 16
		cd.Parent = part
		return cd
	end
	for _, dn in ipairs(M.doorNodes) do
		local d = dn.door
		if not d.exit then
			local x, z = dn.p.X, dn.p.Z
			local dw = d.w or DW
			for _, s2 in ipairs({ -1, 1 }) do
				if dn.vertical then wpart("DoorFrame", 2.6, DH + 0.6, 0.6, x, 0, z + s2 * (dw / 2 + 0.3), def.trim, "Wood")
				else wpart("DoorFrame", 0.6, DH + 0.6, 2.6, x + s2 * (dw / 2 + 0.3), 0, z, def.trim, "Wood") end
			end
			if dn.vertical then wpart("DoorFrame", 2.6, 0.6, dw + 1.2, x, DH, z, def.trim, "Wood")
			else wpart("DoorFrame", dw + 1.2, 0.6, 2.6, x, DH, z, def.trim, "Wood") end
		end
	end
	for _, dn in ipairs(M.doorNodes) do
		local d = dn.door
		local x, z = dn.p.X, dn.p.Z
		local sx, sz = dn.vertical and 2 or DW, dn.vertical and DW or 2
		if d.lock then
			local card = d.lock == "Green Door"
			local door = wpart("LockedDoor", sx, DH, sz, x, 0, z, card and "Medium stone grey" or "Reddish brown", card and "DiamondPlate" or "Wood")
			local L = { name = d.lock, need = DOOR_KEY[d.lock], part = door, node = dn, parts = { door } }
			local col = DOOR_COLOR[d.lock]
			for _, f in ipairs({ -1, 1 }) do
				-- panels, a handle and a keyhole plate on both sides
				local off = f * 1.08
				local function onDoor(n, along, y0, w, h, depth, c, mat)
					local px, pz = x + (dn.vertical and off + f * depth / 2 or along), z + (dn.vertical and along or off + f * depth / 2)
					local part = P(m, n, dn.vertical and V(depth, h, w) or V(w, h, depth), CFrame.new(px, y0 + h / 2, pz), c, mat)
					table.insert(L.parts, part)
					return part
				end
				if card then
					onDoor("DoorStripe", 0, 4, DW - 0.6, 0.6, 0.1, "New Yeller", "SmoothPlastic")
					onDoor("CardReader", DW / 2 - 1.1, 3.8, 0.8, 1.4, 0.3, "Black", "SmoothPlastic")
					onDoor("ReaderLight", DW / 2 - 1.1, 5, 0.5, 0.3, 0.35, col, "Neon")
				else
					onDoor("DoorPanel", -1.6, 1, 2.4, 3, 0.12, "Dark orange", "Wood")
					onDoor("DoorPanel", 1.6, 1, 2.4, 3, 0.12, "Dark orange", "Wood")
					onDoor("DoorPanel", -1.6, 5, 2.4, 3, 0.12, "Dark orange", "Wood")
					onDoor("DoorPanel", 1.6, 5, 2.4, 3, 0.12, "Dark orange", "Wood")
					onDoor("Keyhole", DW / 2 - 1.1, 3.4, 0.6, 1.3, 0.1, col, "Metal")
					onDoor("Handle", DW / 2 - 1.1, 4.3, 0.9, 0.35, 0.45, col, "Metal")
				end
			end
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
				elseif el[1] == "Generator" then
					-- a broken generator by the door (fix it with the wrench)
					local gx = x - math.min(9, A.w / 2 - 4)
					local gz = zi - out * 1.6
					table.insert(L.parts, P(m, "Generator", V(4, 3.6, 2.6), CFrame.new(gx, 1.8, gz), "Olive", "Metal"))
					for i = -1, 1 do table.insert(L.parts, P(m, "GenGrille", V(0.3, 2.2, 2.7), CFrame.new(gx + i * 1.1, 1.9, gz), "Black", "Metal")) end
					table.insert(L.parts, P(m, "GenBolt", V(0.8, 0.8, 0.8), CFrame.new(gx + 1.4, 3.8, gz), "Medium stone grey", "Metal"))
					table.insert(L.parts, P(m, "GenCable", V(0.4, 0.4, math.abs(x - gx)), CFrame.new((x + gx) / 2, 0.3, zi - out * 0.3) * CFrame.Angles(0, math.pi / 2, 0), "Black", "SmoothPlastic", { nc = true }))
					L.bulb = P(m, "GenLight", V(0.6, 0.6, 0.6), CFrame.new(gx - 1.3, 3.9, gz), "Really red", "Neon")
				elseif el[1] == "Keypad" then
					-- type in the code from the note
					local kx = x - 5.6
					table.insert(L.parts, P(m, "Keypad", V(1.4, 2, 0.3), CFrame.new(kx, 5, zi - out * 0.15), "Black", "SmoothPlastic"))
					table.insert(L.parts, P(m, "KeypadKeys", V(1, 1, 0.1), CFrame.new(kx, 4.7, zi - out * 0.35), "Medium stone grey", "SmoothPlastic"))
					L.bulb = P(m, "KeypadScreen", V(1, 0.4, 0.1), CFrame.new(kx, 5.6, zi - out * 0.35), "Really red", "Neon")
					L.keypad = true
					L.need = "the code"
				elseif el[1] == "Fuse Box" then
					local fx = x + math.min(7.5, A.w / 2 - 4.5)
					local box = P(m, "Fuse Box", V(2.6, 3.2, 0.7), CFrame.new(fx, 4.5, zi - out * 0.1), "Medium stone grey", "Metal")
					table.insert(L.parts, P(m, "FuseSlot", V(0.8, 1.6, 0.2), CFrame.new(fx, 4.3, zi - out * 0.5), "Black", "Metal"))
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
