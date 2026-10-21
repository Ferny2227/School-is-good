-- ==== s00_header.lua
-- ServerScriptService.AirportServer  (built from airport/src/server/*.lua by airport/tools/build.py)
-- Airport Tycoon: 10 airports to claim, 300 things to buy in each (a 3-storey terminal, a hotel guests stay in), staff to hire, passengers who walk
-- through your airport, pay and leave reviews, an inspector, NPC airliners, and planes you can fly.
-- Written for 2016 Roblox engines: lowercase :connect, ypcall, no TweenService/typeof/AnchorPoint,
-- FormFactor Custom on new parts, BodyGyro/BodyVelocity with lowercase property names.
local pcall = ypcall or pcall
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local CATALOG = {{key = "road", name = "Entrance Road", price = 0, deps = {}, kind = "road", at = {}, pad = {24, 9}, floor = 0, phase = 1, eff = {}}, {key = "sidewalk", name = "Sidewalk", price = 40, deps = {"road"}, kind = "sidewalk", at = {}, pad = {0, 30}, floor = 0, phase = 1, eff = {cat = {comfort = 0.02}}}, {key = "sign", name = "Airport Sign", price = 60, deps = {"road"}, kind = "airportsign", at = {x = -170, z = 9}, pad = {-150, 9}, floor = 0, phase = 1, eff = {}}, {key = "parking", name = "Parking Lot", price = 120, deps = {"road"}, kind = "parking", at = {}, pad = {-178, 66}, floor = 0, phase = 1, eff = {inc = 10, cnt = {transport = 1}}}, {key = "taxi", name = "Taxi Stand", price = 200, deps = {"sidewalk"}, kind = "taxi", at = {}, pad = {178, 70}, floor = 0, phase = 1, eff = {inc = 15, cnt = {transport = 1}}}, {key = "foundation", name = "Terminal Floor", price = 350, deps = {"sidewalk"}, kind = "floor", at = {}, pad = {0, 50}, floor = 0, phase = 1, eff = {}}, {key = "walls", name = "Terminal Walls", price = 800, deps = {"foundation"}, kind = "walls", at = {}, pad = {0, 70}, floor = 1, phase = 1, eff = {cat = {comfort = 0.04}}}, {key = "doors", name = "Sliding Doors", price = 500, deps = {"walls"}, kind = "doors", at = {}, pad = {30, 50}, floor = 0, phase = 1, eff = {cat = {comfort = 0.03}, cnt = {transport = 1}}}, {key = "lights", name = "Ceiling Lights", price = 650, deps = {"walls"}, kind = "lights", at = {}, pad = {-30, 70}, floor = 1, phase = 1, eff = {cat = {comfort = 0.05}}}, {key = "infodesk", name = "Information Desk", price = 450, deps = {"foundation"}, kind = "infodesk", at = {x = -112, z = 74}, pad = {-112, 74}, floor = 1, phase = 1, eff = {cat = {comfort = 0.03, checkin = 0.03}}}, {key = "benches", name = "Outdoor Benches", price = 150, deps = {"sidewalk"}, kind = "benches", at = {}, pad = {-60, 50}, floor = 0, phase = 1, eff = {cat = {comfort = 0.02}}}, {key = "flags", name = "Flag Poles", price = 300, deps = {"sidewalk"}, kind = "flags", at = {}, pad = {80, 50}, floor = 0, phase = 1, eff = {cat = {comfort = 0.02}}}, {key = "trash", name = "Trash Bins", price = 900, deps = {"foundation"}, kind = "trash", at = {}, pad = {30, 70}, floor = 1, phase = 1, eff = {cat = {clean = 0.08}}}, {key = "bus", name = "Bus Stop", price = 1600, deps = {"sidewalk"}, kind = "bus", at = {}, pad = {178, 122}, floor = 0, phase = 1, eff = {inc = 30, cnt = {transport = 1}}}, {key = "billboards", name = "Billboards", price = 2500, deps = {"road"}, kind = "billboards", at = {}, pad = {-100, 9}, floor = 0, phase = 1, eff = {inc = 40}}, {key = "desk1", name = "Check-in Desk 1", price = 700, deps = {"foundation"}, kind = "desk", at = {x = -112, z = 100, n = 1}, pad = {-112, 96}, floor = 1, phase = 2, eff = {cat = {checkin = 0.12}, cnt = {desk = 1}}}, {key = "desk2", name = "Check-in Desk 2", price = 1200, deps = {"desk1"}, kind = "desk", at = {x = -80, z = 100, n = 2}, pad = {-80, 96}, floor = 1, phase = 2, eff = {cat = {checkin = 0.12}, cnt = {desk = 1}}}, {key = "desk3", name = "Check-in Desk 3", price = 1900, deps = {"desk2"}, kind = "desk", at = {x = -48, z = 100, n = 3}, pad = {-48, 96}, floor = 1, phase = 2, eff = {cat = {checkin = 0.12}, cnt = {desk = 1}}}, {key = "desk4", name = "Check-in Desk 4", price = 2800, deps = {"desk3"}, kind = "desk", at = {x = 48, z = 100, n = 4}, pad = {48, 96}, floor = 1, phase = 2, eff = {cat = {checkin = 0.12}, cnt = {desk = 1}}}, {key = "desk5", name = "Check-in Desk 5", price = 4000, deps = {"desk4"}, kind = "desk", at = {x = 80, z = 100, n = 5}, pad = {80, 96}, floor = 1, phase = 2, eff = {cat = {checkin = 0.12}, cnt = {desk = 1}}}, {key = "desk6", name = "Check-in Desk 6", price = 5500, deps = {"desk5"}, kind = "desk", at = {x = 112, z = 100, n = 6}, pad = {112, 96}, floor = 1, phase = 2, eff = {cat = {checkin = 0.12}, cnt = {desk = 1}}}, {key = "queue", name = "Queue Barriers", price = 700, deps = {"desk1"}, kind = "queue", at = {}, pad = {-96, 84}, floor = 1, phase = 2, eff = {cat = {checkin = 0.03}}}, {key = "carts", name = "Luggage Carts", price = 500, deps = {"desk1"}, kind = "carts", at = {}, pad = {36, 84}, floor = 1, phase = 2, eff = {cat = {comfort = 0.02}}}, {key = "belt", name = "Baggage Belt", price = 2200, deps = {"desk2"}, kind = "belt", at = {}, pad = {-64, 113}, floor = 1, phase = 2, eff = {cat = {checkin = 0.06}, cnt = {belt = 1}}}, {key = "kioskA", name = "Self Check-in Kiosks", price = 2600, deps = {"desk2"}, kind = "kiosks", at = {x = -62}, pad = {-62, 72}, floor = 1, phase = 2, eff = {cat = {checkin = 0.07}}}, {key = "kioskB", name = "More Check-in Kiosks", price = 3600, deps = {"kioskA"}, kind = "kiosks", at = {x = 62}, pad = {62, 72}, floor = 1, phase = 2, eff = {cat = {checkin = 0.07}}}, {key = "board", name = "Departures Board", price = 1800, deps = {"walls"}, kind = "board", at = {}, pad = {0, 112}, floor = 1, phase = 2, eff = {cat = {checkin = 0.03, gates = 0.03}}}, {key = "atm", name = "ATMs", price = 3000, deps = {"doors"}, kind = "atm", at = {}, pad = {-30, 84}, floor = 1, phase = 2, eff = {inc = 40}}, {key = "secwall", name = "Security Checkpoint", price = 2500, deps = {"desk1"}, kind = "secwall", at = {}, pad = {0, 120}, floor = 1, phase = 3, eff = {cat = {security = 0.04}}}, {key = "lane1", name = "Security Lane 1", price = 3500, deps = {"secwall"}, kind = "lane", at = {x = -30}, pad = {-30, 142}, floor = 1, phase = 3, eff = {cat = {security = 0.13}, cnt = {lane = 1}}}, {key = "lane2", name = "Security Lane 2", price = 5500, deps = {"lane1"}, kind = "lane", at = {x = 30}, pad = {30, 142}, floor = 1, phase = 3, eff = {cat = {security = 0.13}, cnt = {lane = 1}}}, {key = "lane3", name = "Security Lane 3", price = 8000, deps = {"lane2"}, kind = "lane", at = {x = -60}, pad = {-60, 142}, floor = 1, phase = 3, eff = {cat = {security = 0.13}, cnt = {lane = 1}}}, {key = "lane4", name = "Security Lane 4", price = 11000, deps = {"lane3"}, kind = "lane", at = {x = 60}, pad = {60, 142}, floor = 1, phase = 3, eff = {cat = {security = 0.13}, cnt = {lane = 1}}}, {key = "office", name = "Security Office", price = 6000, deps = {"lane1"}, kind = "office", at = {}, pad = {-125, 143}, floor = 1, phase = 3, eff = {cat = {security = 0.06}}}, {key = "cctv", name = "CCTV Cameras", price = 3000, deps = {"lane1"}, kind = "cctv", at = {}, pad = {-104, 150}, floor = 1, phase = 3, eff = {cat = {security = 0.05}}}, {key = "scanner1", name = "Body Scanner A", price = 14000, deps = {"lane2"}, kind = "scanner", at = {x = -92}, pad = {-92, 142}, floor = 1, phase = 3, eff = {cat = {security = 0.1}, cnt = {lane = 1}}}, {key = "scanner2", name = "Body Scanner B", price = 18000, deps = {"scanner1"}, kind = "scanner", at = {x = 92}, pad = {92, 142}, floor = 1, phase = 3, eff = {cat = {security = 0.1}, cnt = {lane = 1}}}, {key = "k9", name = "K9 Unit", price = 9000, deps = {"lane2"}, kind = "k9", at = {}, pad = {118, 143}, floor = 1, phase = 3, eff = {cat = {security = 0.07}}}, {key = "gate1", name = "Gate 1", price = 5000, deps = {"lane1"}, kind = "gate", at = {x = -105, n = 1}, pad = {-105, 300}, floor = 1, phase = 4, eff = {cat = {gates = 0.12}, cnt = {gate = 1}, ticket = 15}}, {key = "gate2", name = "Gate 2", price = 8000, deps = {"gate1"}, kind = "gate", at = {x = -35, n = 2}, pad = {-35, 300}, floor = 1, phase = 4, eff = {cat = {gates = 0.12}, cnt = {gate = 1}, ticket = 15}}, {key = "gate3", name = "Gate 3", price = 12000, deps = {"gate2"}, kind = "gate", at = {x = 35, n = 3}, pad = {35, 300}, floor = 1, phase = 4, eff = {cat = {gates = 0.12}, cnt = {gate = 1}, ticket = 15}}, {key = "gate4", name = "Gate 4", price = 17000, deps = {"gate3"}, kind = "gate", at = {x = 105, n = 4}, pad = {105, 300}, floor = 1, phase = 4, eff = {cat = {gates = 0.12}, cnt = {gate = 1}, ticket = 15}}, {key = "apron", name = "Apron", price = 6000, deps = {"gate1"}, kind = "apron", at = {}, pad = {-170, 380}, floor = 0, phase = 4, eff = {}}, {key = "bridge1", name = "Jet Bridge 1", price = 8000, deps = {"apron", "gate1"}, kind = "bridge", at = {x = -105, n = 1}, pad = {-105, 340}, floor = 0, phase = 4, eff = {cat = {gates = 0.08}, cnt = {bridge = 1}, ticket = 25}}, {key = "bridge2", name = "Jet Bridge 2", price = 11000, deps = {"apron", "gate2"}, kind = "bridge", at = {x = -35, n = 2}, pad = {-35, 340}, floor = 0, phase = 4, eff = {cat = {gates = 0.08}, cnt = {bridge = 1}, ticket = 25}}, {key = "bridge3", name = "Jet Bridge 3", price = 15000, deps = {"apron", "gate3"}, kind = "bridge", at = {x = 35, n = 3}, pad = {35, 340}, floor = 0, phase = 4, eff = {cat = {gates = 0.08}, cnt = {bridge = 1}, ticket = 25}}, {key = "bridge4", name = "Jet Bridge 4", price = 20000, deps = {"apron", "gate4"}, kind = "bridge", at = {x = 105, n = 4}, pad = {105, 340}, floor = 0, phase = 4, eff = {cat = {gates = 0.08}, cnt = {bridge = 1}, ticket = 25}}, {key = "vehicles", name = "Ground Vehicles", price = 7000, deps = {"apron"}, kind = "groundvehicles", at = {}, pad = {0, 430}, floor = 0, phase = 4, eff = {cat = {gates = 0.03}}}, {key = "taxiway", name = "Taxiway", price = 8000, deps = {"apron"}, kind = "taxiway", at = {}, pad = {0, 460}, floor = 0, phase = 4, eff = {cat = {gates = 0.03}}}, {key = "runway", name = "Runway", price = 15000, deps = {"taxiway"}, kind = "runway", at = {}, pad = {0, 525}, floor = 0, phase = 4, eff = {cat = {gates = 0.1}, cnt = {runway = 1}, ticket = 50}}, {key = "rwlights", name = "Runway Lights", price = 12000, deps = {"runway"}, kind = "rwlights", at = {}, pad = {-120, 525}, floor = 0, phase = 4, eff = {cat = {gates = 0.04}, ticket = 15}}, {key = "windsock", name = "Windsock", price = 1500, deps = {"runway"}, kind = "windsock", at = {}, pad = {195, 575}, floor = 0, phase = 4, eff = {cat = {gates = 0.01}}}, {key = "tower", name = "Control Tower", price = 50000, deps = {"runway"}, kind = "tower", at = {}, pad = {-192, 338}, floor = 0, phase = 4, eff = {cat = {gates = 0.08}, cnt = {tower = 1}, ticket = 40}}, {key = "radar", name = "Radar", price = 22000, deps = {"tower"}, kind = "radar", at = {}, pad = {-168, 362}, floor = 0, phase = 4, eff = {cat = {gates = 0.04}}}, {key = "helipad", name = "Helipad", price = 30000, deps = {"apron"}, kind = "helipad", at = {}, pad = {178, 400}, floor = 0, phase = 4, eff = {inc = 50, cat = {comfort = 0.03}}}, {key = "hangar", name = "Hangar", price = 18000, deps = {"runway"}, kind = "hangar", at = {}, pad = {160, 592}, floor = 0, phase = 4, eff = {cnt = {hangar = 1}}}, {key = "smallplane", name = "Small Plane (you can fly it!)", price = 8000, deps = {"hangar"}, kind = "planepad", at = {plane = "small", x = 128}, pad = {128, 572}, floor = 0, phase = 4, eff = {}}, {key = "jet", name = "Fighter Jet (you can fly it!)", price = 90000, deps = {"smallplane"}, kind = "planepad", at = {plane = "jet", x = 158}, pad = {158, 572}, floor = 0, phase = 4, eff = {}}, {key = "privatejet", name = "Private Jet (you can fly it!)", price = 400000, deps = {"jet"}, kind = "planepad", at = {plane = "private", x = 188}, pad = {188, 572}, floor = 0, phase = 4, eff = {}}, {key = "fuel", name = "Fuel Depot", price = 38000, deps = {"runway"}, kind = "fuel", at = {}, pad = {-175, 592}, floor = 0, phase = 4, eff = {inc = 175}}, {key = "fire", name = "Fire Station", price = 55000, deps = {"runway"}, kind = "firestation", at = {}, pad = {70, 592}, floor = 0, phase = 4, eff = {cat = {gates = 0.05, security = 0.03}, cnt = {fire = 1}, ticket = 20}}, {key = "cargo", name = "Cargo Terminal", price = 100000, deps = {"runway"}, kind = "cargo", at = {}, pad = {-85, 592}, floor = 0, phase = 4, eff = {inc = 450}}, {key = "foodfloor", name = "Food Court", price = 5000, deps = {"lane1"}, kind = "foodcourt", at = {}, pad = {-80, 205}, floor = 1, phase = 5, eff = {cat = {food = 0.05}}}, {key = "stall1", name = "Burger Joint", price = 6000, deps = {"foodfloor"}, kind = "stall", at = {x = -131, z = 171, face = "x", color = "Bright red", title = "BURGER JOINT", n = 1}, pad = {-117, 171}, floor = 1, phase = 5, eff = {cat = {food = 0.12}, cnt = {stall = 1}, spend = 12}}, {key = "stall2", name = "Pizza Place", price = 9000, deps = {"stall1"}, kind = "stall", at = {x = -131, z = 189, face = "x", color = "Bright orange", title = "PIZZA PLACE", n = 2}, pad = {-117, 189}, floor = 1, phase = 5, eff = {cat = {food = 0.12}, cnt = {stall = 1}, spend = 14}}, {key = "stall3", name = "Coffee Shop", price = 12000, deps = {"stall2"}, kind = "stall", at = {x = -131, z = 207, face = "x", color = "Brown", title = "COFFEE SHOP", n = 3}, pad = {-117, 207}, floor = 1, phase = 5, eff = {cat = {food = 0.12}, cnt = {stall = 1}, spend = 10}}, {key = "stall4", name = "Sushi Bar", price = 17000, deps = {"stall3"}, kind = "stall", at = {x = -131, z = 225, face = "x", color = "Institutional white", title = "SUSHI BAR", n = 4}, pad = {-117, 225}, floor = 1, phase = 5, eff = {cat = {food = 0.12}, cnt = {stall = 1}, spend = 22}}, {key = "stall5", name = "Taco Stand", price = 23000, deps = {"stall4"}, kind = "stall", at = {x = -100, z = 243, face = "-z", color = "Bright yellow", title = "TACO STAND", n = 5}, pad = {-100, 229}, floor = 1, phase = 5, eff = {cat = {food = 0.12}, cnt = {stall = 1}, spend = 16}}, {key = "stall6", name = "Ice Cream", price = 30000, deps = {"stall5"}, kind = "stall", at = {x = -66, z = 243, face = "-z", color = "Pink", title = "ICE CREAM", n = 6}, pad = {-66, 229}, floor = 1, phase = 5, eff = {cat = {food = 0.12}, cnt = {stall = 1}, spend = 12}}, {key = "tables1", name = "Food Court Tables 1", price = 2500, deps = {"foodfloor"}, kind = "tables", at = {x = -95, z = 182}, pad = {-95, 182}, floor = 1, phase = 5, eff = {cat = {food = 0.04}}}, {key = "tables2", name = "Food Court Tables 2", price = 4500, deps = {"foodfloor"}, kind = "tables", at = {x = -60, z = 182}, pad = {-60, 182}, floor = 1, phase = 5, eff = {cat = {food = 0.04}}}, {key = "tables3", name = "Food Court Tables 3", price = 7000, deps = {"foodfloor"}, kind = "tables", at = {x = -78, z = 214}, pad = {-78, 214}, floor = 1, phase = 5, eff = {cat = {food = 0.04}}}, {key = "vending", name = "Vending Machines", price = 3500, deps = {"lane1"}, kind = "vending", at = {}, pad = {128, 160}, floor = 1, phase = 5, eff = {cat = {food = 0.03}, inc = 20}}, {key = "shop1", name = "Souvenir Shop", price = 12000, deps = {"lane1"}, kind = "shop", at = {x = 131, z = 171, face = "-x", color = "Bright green", title = "SOUVENIR SHOP", n = 1}, pad = {117, 171}, floor = 1, phase = 6, eff = {cat = {shopping = 0.14}, cnt = {shop = 1}, spend = 20}}, {key = "shop2", name = "Bookstore", price = 15000, deps = {"shop1"}, kind = "shop", at = {x = 131, z = 189, face = "-x", color = "Brown", title = "BOOKSTORE", n = 2}, pad = {117, 189}, floor = 1, phase = 6, eff = {cat = {shopping = 0.14}, cnt = {shop = 1}, spend = 15}}, {key = "shop3", name = "Pharmacy", price = 19000, deps = {"shop2"}, kind = "shop", at = {x = 131, z = 207, face = "-x", color = "Institutional white", title = "PHARMACY", n = 3}, pad = {117, 207}, floor = 1, phase = 6, eff = {cat = {shopping = 0.14}, cnt = {shop = 1}, spend = 18}}, {key = "shop4", name = "Duty Free", price = 26000, deps = {"shop3"}, kind = "shop", at = {x = 131, z = 225, face = "-x", color = "Royal purple", title = "DUTY FREE", n = 4}, pad = {117, 225}, floor = 1, phase = 6, eff = {cat = {shopping = 0.14}, cnt = {shop = 1}, spend = 40}}, {key = "shop5", name = "Tech Store", price = 34000, deps = {"shop4"}, kind = "shop", at = {x = 100, z = 243, face = "-z", color = "Really black", title = "TECH STORE", n = 5}, pad = {100, 229}, floor = 1, phase = 6, eff = {cat = {shopping = 0.14}, cnt = {shop = 1}, spend = 50}}, {key = "shop6", name = "Fashion Boutique", price = 44000, deps = {"shop5"}, kind = "shop", at = {x = 66, z = 243, face = "-z", color = "Hot pink", title = "FASHION BOUTIQUE", n = 6}, pad = {66, 229}, floor = 1, phase = 6, eff = {cat = {shopping = 0.14}, cnt = {shop = 1}, spend = 45}}, {key = "seats1", name = "Waiting Seats 1", price = 2000, deps = {"lane1"}, kind = "seats", at = {x = 50, z = 186}, pad = {50, 186}, floor = 1, phase = 6, eff = {cat = {comfort = 0.05}, cnt = {seat = 1}}}, {key = "seats2", name = "Waiting Seats 2", price = 3500, deps = {"seats1"}, kind = "seats", at = {x = 88, z = 186}, pad = {88, 186}, floor = 1, phase = 6, eff = {cat = {comfort = 0.05}, cnt = {seat = 1}}}, {key = "seats3", name = "Waiting Seats 3", price = 5000, deps = {"seats2"}, kind = "seats", at = {x = 50, z = 216}, pad = {50, 216}, floor = 1, phase = 6, eff = {cat = {comfort = 0.05}, cnt = {seat = 1}}}, {key = "seats4", name = "Waiting Seats 4", price = 7000, deps = {"seats3"}, kind = "seats", at = {x = 88, z = 216}, pad = {88, 216}, floor = 1, phase = 6, eff = {cat = {comfort = 0.05}, cnt = {seat = 1}}}, {key = "restrooms", name = "Restrooms", price = 9000, deps = {"lane1"}, kind = "restrooms", at = {}, pad = {-126, 266}, floor = 1, phase = 6, eff = {cat = {comfort = 0.1, clean = 0.1}, cnt = {restroom = 1}}}, {key = "plants", name = "Indoor Plants", price = 2500, deps = {"walls"}, kind = "plants", at = {}, pad = {-60, 152}, floor = 1, phase = 6, eff = {cat = {comfort = 0.03}}}, {key = "charging", name = "Charging Stations", price = 7000, deps = {"seats1"}, kind = "charging", at = {}, pad = {69, 200}, floor = 1, phase = 6, eff = {cat = {comfort = 0.04}}}, {key = "arcade", name = "Arcade", price = 38000, deps = {"lane2"}, kind = "arcade", at = {}, pad = {-39, 266}, floor = 1, phase = 6, eff = {cat = {comfort = 0.06}, inc = 125}}, {key = "kids", name = "Kids Play Area", price = 28000, deps = {"lane2"}, kind = "kids", at = {}, pad = {120, 266}, floor = 1, phase = 6, eff = {cat = {comfort = 0.06}}}, {key = "lounge", name = "VIP Lounge", price = 75000, deps = {"gate2"}, kind = "lounge", at = {}, pad = {-84, 266}, floor = 1, phase = 6, eff = {cat = {comfort = 0.1}, ticket = 40}}, {key = "spa", name = "Spa & Massage", price = 55000, deps = {"gate2"}, kind = "spa", at = {}, pad = {40, 266}, floor = 1, phase = 6, eff = {cat = {comfort = 0.07}, inc = 150}}, {key = "aquarium", name = "Aquarium", price = 95000, deps = {"lounge"}, kind = "aquarium", at = {}, pad = {78, 266}, floor = 1, phase = 6, eff = {cat = {comfort = 0.08}}}, {key = "fountain", name = "Terminal Fountain", price = 40000, deps = {"foodfloor"}, kind = "fountain", at = {}, pad = {0, 205}, floor = 1, phase = 6, eff = {cat = {comfort = 0.05}}}, {key = "roof", name = "Glass Roof", price = 85000, deps = {"walls"}, kind = "roof", at = {}, pad = {-20, 300}, floor = 1, phase = 6, eff = {cat = {comfort = 0.1}}}, {key = "chandeliers", name = "Chandeliers", price = 45000, deps = {"roof"}, kind = "chandeliers", at = {}, pad = {20, 300}, floor = 1, phase = 6, eff = {cat = {comfort = 0.04}}}, {key = "bigscreen", name = "Giant Screen", price = 60000, deps = {"walls"}, kind = "bigscreen", at = {}, pad = {-40, 50}, floor = 0, phase = 6, eff = {cat = {comfort = 0.03}, inc = 100}}, {key = "statue", name = "Golden Plane Statue", price = 140000, deps = {"walls"}, kind = "planestatue", at = {x = 100, z = 9}, pad = {100, 9}, floor = 0, phase = 6, eff = {cat = {comfort = 0.04}}}, {key = "rental", name = "Car Rental", price = 18000, deps = {"taxi"}, kind = "rental", at = {}, pad = {178, 170}, floor = 0, phase = 7, eff = {inc = 110, cnt = {transport = 1}}}, {key = "garage", name = "Parking Garage", price = 55000, deps = {"parking"}, kind = "garage", at = {}, pad = {-178, 250}, floor = 0, phase = 7, eff = {inc = 275, cnt = {transport = 1}}}, {key = "hotel", name = "Airport Hotel", price = 180000, deps = {"rental"}, kind = "hotel", at = {}, pad = {178, 260}, floor = 0, phase = 7, eff = {inc = 800}}, {key = "train", name = "Train Station", price = 320000, deps = {"bus"}, kind = "train", at = {}, pad = {-80, 9}, floor = 0, phase = 7, eff = {inc = 1300, cnt = {transport = 2}}}, {key = "intl", name = "International Status", price = 800000, deps = {"tower", "gate4"}, kind = "intlsign", at = {}, pad = {-60, 300}, floor = 1, phase = 8, eff = {cat = {gates = 0.05}, tmult = 2}}, {key = "fireworks", name = "Fireworks Show", price = 250000, deps = {"roof"}, kind = "fireworks", at = {}, pad = {60, 300}, floor = 1, phase = 8, eff = {cat = {comfort = 0.03}}}, {key = "mascot", name = "Airport Mascot", price = 200000, deps = {"statue"}, kind = "mascot", at = {}, pad = {180, 9}, floor = 0, phase = 8, eff = {cat = {comfort = 0.03}}}, {key = "golden", name = "Golden Terminal", price = 1500000, deps = {"intl"}, kind = "golden", at = {}, pad = {-100, 300}, floor = 1, phase = 8, eff = {cat = {checkin = 0.05, security = 0.05, food = 0.05, shopping = 0.05, comfort = 0.05, clean = 0.05, gates = 0.05}, inc = 2000}}}
local STAFF = {{key = "agent", name = "Check-in Agent", fee = 400, need = "desk", capbase = 0, capper = 1, cat = {checkin = 0.07}, desc = "Works a check-in desk. Faster check-in.", shirt = "Bright blue"}, {key = "officer", name = "Security Officer", fee = 700, need = "lane", capbase = 0, capper = 2, cat = {security = 0.06}, desc = "Runs a security lane. Faster, safer security.", shirt = "Really black"}, {key = "chef", name = "Chef", fee = 1100, need = "stall", capbase = 0, capper = 1, cat = {food = 0.07}, desc = "Cooks at a food stall. Better food, more spending.", shirt = "Institutional white"}, {key = "clerk", name = "Shop Clerk", fee = 1300, need = "shop", capbase = 0, capper = 1, cat = {shopping = 0.06}, desc = "Runs a shop. Passengers spend more.", shirt = "Bright green"}, {key = "janitor", name = "Janitor", fee = 500, capbase = 2, capper = 0, capextra = {"restroom", 3}, cat = {clean = 0.14}, desc = "Keeps the airport clean.", shirt = "Bright orange"}, {key = "gateagent", name = "Gate Agent", fee = 2200, need = "gate", capbase = 0, capper = 1, cat = {gates = 0.05}, desc = "Boards passengers at a gate.", shirt = "Navy blue"}, {key = "pilot", name = "Pilot", fee = 4500, need = "bridge", capbase = 0, capper = 1, cat = {gates = 0.05}, desc = "Flies your airliners. More flights, +10% tickets.", shirt = "Institutional white", ticketpct = 10}, {key = "handler", name = "Baggage Handler", fee = 1800, need = "belt", capbase = 0, capper = 4, cat = {checkin = 0.04}, desc = "Moves bags. Faster check-in.", shirt = "Bright yellow"}, {key = "atc", name = "Air Traffic Controller", fee = 14000, need = "tower", capbase = 0, capper = 2, cat = {gates = 0.06}, desc = "Works in the control tower. Flights on time.", shirt = "Sand blue"}, {key = "mechanic", name = "Mechanic", fee = 8000, need = "hangar", capbase = 0, capper = 2, cat = {gates = 0.03}, desc = "Tunes your planes: +15% flying speed each.", shirt = "Dark stone grey"}, {key = "firefighter", name = "Firefighter", fee = 6000, need = "fire", capbase = 0, capper = 3, cat = {security = 0.03, comfort = 0.02}, desc = "Keeps everyone safe.", shirt = "Bright red"}}
local CATS = {"checkin", "security", "food", "shopping", "comfort", "clean", "gates"}
local CONST = {startCash = 250, baseTicket = 15, walkSpeed = 10, clean_base = 0.15, paxMult = 6, checkinFee = 8}
local PHASES = {"Arrival", "Check-in", "Security", "Gates & Planes", "Food Court", "Shops & Comfort", "Business", "Mega Airport",
	"Second Floor", "Third Floor", "Hotel", "Expansion", "Ground Operations"}


local MAP = workspace:WaitForChild("AirportMap")
local G = { plots = {}, byPlayer = {}, walkers = {}, movers = {}, spinners = {}, flyers = {}, saved = {}, pitch = {}, ctl = {} }
local U = {}     -- small helpers
local M = {}     -- models: people, airliners, flyable planes
local K = {}     -- item builders (one per catalog "kind")
local A = {}     -- airport logic
local NPC = {}   -- passengers, staff, inspector
local FLY = {}   -- planes

------------------------------------------------------------------ helpers
function U.money(n)
	n = math.floor(n or 0)
	local s = tostring(math.abs(n))
	local out = ""
	while #s > 3 do out = "," .. s:sub(-3) .. out s = s:sub(1, -4) end
	return (n < 0 and "-$" or "$") .. s .. out
end

function U.L(x, y, z, ry, rx, rz)
	return CFrame.new(x, y, z) * CFrame.Angles(math.rad(rx or 0), math.rad(ry or 0), math.rad(rz or 0))
end

function U.newPart(class)
	local p = Instance.new(class or "Part")
	pcall(function() p.FormFactor = Enum.FormFactor.Custom end)
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	return p
end

-- b = { model = parent, cf = CFrame everything is relative to }
function U.P(b, name, size, lcf, color, mat, opt)
	opt = opt or {}
	local p = U.newPart(opt.class)
	p.Name = name
	p.Anchored = true
	if opt.shape == "ball" then p.Shape = Enum.PartType.Ball
	elseif opt.shape == "cyl" then p.Shape = Enum.PartType.Cylinder end
	p.Size = size
	p.BrickColor = BrickColor.new(color or "Medium stone grey")
	if mat then pcall(function() p.Material = Enum.Material[mat] end) end
	if opt.tr then p.Transparency = opt.tr end
	if opt.refl then p.Reflectance = opt.refl end
	if opt.nc then p.CanCollide = false end
	p.CFrame = b.cf * lcf
	p.Parent = b.model
	return p
end
-- a box standing on y0 (bottom), centred on x, z
function U.blk(b, name, sx, sy, sz, x, y0, z, color, mat, opt, ry)
	return U.P(b, name, Vector3.new(sx, sy, sz), U.L(x, y0 + sy / 2, z, ry), color, mat, opt)
end
-- vertical cylinder standing on y0
function U.cyl(b, name, d, h, x, y0, z, color, mat, opt)
	opt = opt or {}
	opt.shape = "cyl"
	return U.P(b, name, Vector3.new(h, d, d), U.L(x, y0 + h / 2, z) * CFrame.Angles(0, 0, math.rad(90)), color, mat, opt)
end
function U.ball(b, name, d, x, y, z, color, mat, opt)
	opt = opt or {}
	opt.shape = "ball"
	return U.P(b, name, Vector3.new(d, d, d), U.L(x, y, z), color, mat, opt)
end
function U.seat(b, x, y0, z, ry, color, w)
	return U.P(b, "Seat", Vector3.new(w or 2, 1, 2), U.L(x, y0 + 0.5, z, ry), color or "Bright blue", "Fabric", { class = "Seat" })
end
function U.light(p, color, range, bright)
	local l = Instance.new("PointLight")
	l.Color = color or Color3.new(1, 0.95, 0.8)
	l.Range = range or 16
	l.Brightness = bright or 1.5
	l.Parent = p
	return l
end
function U.fx(p, kind)
	local e = Instance.new(kind)
	e.Parent = p
	return e
end
-- text on a face of a part
function U.text(p, text, color, bg, face, font)
	local sg = Instance.new("SurfaceGui")
	sg.Name = "Text"
	pcall(function() sg.Face = Enum.NormalId[face or "Front"] end)
	local w, h = p.Size.X, p.Size.Y
	if face == "Top" or face == "Bottom" then h = p.Size.Z end
	if face == "Left" or face == "Right" then w = p.Size.Z end
	pcall(function() sg.CanvasSize = Vector2.new(math.max(50, w * 25), math.max(20, h * 25)) end)
	local t = Instance.new("TextLabel")
	t.Name = "Label"
	t.Size = UDim2.new(1, 0, 1, 0)
	t.BackgroundTransparency = bg and 0 or 1
	if bg then t.BackgroundColor3 = bg end
	t.BorderSizePixel = 0
	t.TextScaled = true
	t.TextWrapped = true
	t.Text = text
	t.TextColor3 = color or Color3.new(1, 1, 1)
	pcall(function() t.Font = font or Enum.Font.SourceSansBold end)
	t.Parent = sg
	sg.Parent = p
	return t
end
-- floating label (sized in studs so it shrinks with distance)
function U.bill(p, text, w, h, up, color)
	local bb = Instance.new("BillboardGui")
	bb.Name = "Label"
	bb.Size = UDim2.new(w or 10, 0, h or 2.5, 0)
	bb.StudsOffset = Vector3.new(0, up or 3, 0)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.new(1, 0, 1, 0)
	t.TextScaled = true
	t.TextWrapped = true
	t.Text = text
	t.TextColor3 = color or Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0.2
	pcall(function() t.Font = Enum.Font.SourceSansBold end)
	t.Parent = bb
	bb.Parent = p
	return t
end
function U.weld(root, p)
	local w = Instance.new("Weld")
	w.Part0 = root
	w.Part1 = p
	w.C0 = root.CFrame:inverse() * p.CFrame
	w.Parent = root
	return w
end
-- make a model move as one piece by setting root.CFrame: root anchored, everything else welded to it
function U.rig(model, root, collide)
	for _, p in ipairs(model:GetChildren()) do
		if p:IsA("BasePart") then
			if not collide then p.CanCollide = false end
			if p ~= root then U.weld(root, p) p.Anchored = false end
		end
	end
	root.Anchored = true
end
function U.spin(parts, center, axis, speed)
	local rel = {}
	for i, p in ipairs(parts) do rel[i] = center:inverse() * p.CFrame end
	table.insert(G.spinners, { parts = parts, rel = rel, center = center, axis = axis, speed = speed })
end
function U.pick(t) return t[math.random(1, #t)] end
function U.clamp(x, a, b) if x < a then return a elseif x > b then return b end return x end

