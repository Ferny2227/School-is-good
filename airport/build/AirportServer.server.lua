
-- ==== s00_header.lua
-- ServerScriptService.AirportServer  (built from airport/src/server/*.lua by airport/tools/build.py)
-- Airport Tycoon: 10 airports to claim, 100+ things to buy in each, staff to hire, passengers who walk
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
local PHASES = {"Arrival", "Check-in", "Security", "Gates & Planes", "Food Court", "Shops & Comfort", "Business", "Mega Airport"}


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

local CATNAME = { checkin = "Check-in", security = "Security", food = "Food", shopping = "Shopping",
	comfort = "Comfort", clean = "Cleanliness", gates = "Flights" }
local ITEM = {}       -- key -> catalog item
for i, it in ipairs(CATALOG) do it.index = i ITEM[it.key] = it end
local ROLE = {}
for _, st in ipairs(STAFF) do ROLE[st.key] = st end

-- ==== s10_models.lua
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

-- ==== s20_items.lua
------------------------------------------------------------------ item builders
-- K.<kind>(b, o): b = { model, cf (plot origin), plot }, o = the item's "at" table from the catalog.
-- Plot space: x -210..210, z 0 (front) .. 620 (back). Terminal floor top is y = 1 (x -140..140, z 60..320).
local F = 1
local WALL_H = 28
-- staff stand here (role -> list of CFrames), passengers walk to these points
local function SPOT(b, role, x, y, z, ry)
	local s = b.plot.spots
	s[role] = s[role] or {}
	table.insert(s[role], b.cf * U.L(x, y, z, ry or 0))
end
local POSKEYS = { a = true, b = true, c = true, p = true, q = true, door = true, e = true }
local function PT(b, kind, t)
	local out = {}
	for k, v in pairs(t) do out[k] = POSKEYS[k] and b.cf * v or v end
	local p = b.plot.pts
	p[kind] = p[kind] or {}
	table.insert(p[kind], out)
end
local V = Vector3.new

local function car(b, x, z, ry, color)
	U.blk(b, "Car", 5, 2, 9, x, 0.6, z, color, "SmoothPlastic", nil, ry)
	U.P(b, "CarTop", V(4.4, 1.6, 4.5), U.L(x, 3.4, z, ry) * CFrame.new(0, 0, 0.5), color, "SmoothPlastic")
	U.P(b, "CarGlass", V(4.5, 1.2, 4.6), U.L(x, 3.4, z, ry) * CFrame.new(0, 0, 0.5), "Pastel light blue", "Glass", { tr = 0.5 })
	for _, w in ipairs({ { -2.4, -3 }, { 2.4, -3 }, { -2.4, 3 }, { 2.4, 3 } }) do
		U.P(b, "Wheel", V(0.8, 1.6, 1.6), U.L(x, 0.8, z, ry) * CFrame.new(w[1], 0, w[2]), "Really black", nil, { shape = "cyl" })
	end
end
local function counter(b, w, d, h, x, z, ry, color)
	return U.P(b, "Counter", V(w, h, d), U.L(x, F + h / 2, z, ry), color, "SmoothPlastic")
end
local function hangSign(b, text, w, h, x, y, z, ry, bg, fg)
	local s = U.P(b, "Sign", V(w, h, 0.4), U.L(x, y, z, ry), "Really black", "SmoothPlastic")
	U.text(s, text, fg or Color3.new(1, 1, 1), bg or Color3.new(0.1, 0.12, 0.18), "Front")
	U.text(s, text, fg or Color3.new(1, 1, 1), bg or Color3.new(0.1, 0.12, 0.18), "Back")
	return s
end
-- a booth/room against a wall: frame `c` is the room's centre on the floor, its open front faces -z (local)
local function booth(b, c, w, d, h, color, title, glass)
	local bb = { model = b.model, cf = c, plot = b.plot }
	U.blk(bb, "Back", w, h, 0.6, 0, F, d / 2, color, "SmoothPlastic")
	U.blk(bb, "Side", 0.6, h, d, -w / 2, F, 0, color, "SmoothPlastic")
	U.blk(bb, "Side", 0.6, h, d, w / 2, F, 0, color, "SmoothPlastic")
	U.blk(bb, "Roof", w + 0.6, 0.6, d + 0.6, 0, F + h, 0, color, "SmoothPlastic")
	if glass then U.blk(bb, "Window", w - 6, h - 4, 0.3, 0, F + 3, -d / 2, "Pastel light blue", "Glass", { tr = 0.6, nc = true }) end
	if title then
		local s = U.blk(bb, "Sign", w, 2.4, 0.4, 0, F + h - 2.4, -d / 2 - 0.3, "Really black", "SmoothPlastic")
		U.text(s, title, Color3.new(1, 1, 1), BrickColor.new(color).Color, "Front")
	end
	return bb
end
local function faceCF(x, z, face)
	local ry = 0
	if face == "x" then ry = -90 elseif face == "-x" then ry = 90 end
	return U.L(x, 0, z, ry)
end

------------------------------------------------------------------ 1. arrival
function K.road(b)
	U.blk(b, "Road", 420, 0.3, 24, 0, 0, 30, "Dark stone grey", "Concrete")
	for x = -200, 200, 20 do U.blk(b, "Line", 8, 0.05, 0.6, x, 0.3, 30, "Institutional white", "SmoothPlastic", { nc = true }) end
	for _, x in ipairs({ -100, 100 }) do U.blk(b, "Driveway", 24, 0.3, 32, x, 0, 2, "Dark stone grey", "Concrete") end
end
function K.sidewalk(b)
	U.blk(b, "Sidewalk", 420, 0.5, 14, 0, 0, 49, "Light stone grey", "Concrete")
	U.blk(b, "Curb", 420, 0.7, 0.8, 0, 0, 42.4, "Institutional white", "Concrete")
end
function K.airportsign(b, o)
	for _, dx in ipairs({ -13, 13 }) do U.blk(b, "Post", 1.4, 16, 1.4, o.x + dx, 0, o.z, "Dark stone grey", "Metal") end
	local s = U.blk(b, "Board", 32, 9, 1, o.x, 12, o.z, "Navy blue", "SmoothPlastic")
	b.plot.signLabel = U.text(s, "AIRPORT", Color3.new(1, 0.85, 0.25), Color3.new(0.05, 0.1, 0.3), "Front")
	U.blk(b, "Trim", 32.4, 0.6, 1.2, o.x, 21, o.z, b.plot.color, "Neon")
end
function K.parking(b)
	U.blk(b, "Lot", 55, 0.3, 140, -177.5, 0, 130, "Dark stone grey", "Concrete")
	for z = 64, 196, 12 do U.blk(b, "Line", 14, 0.05, 0.4, -196, 0.3, z, "Institutional white", nil, { nc = true }) U.blk(b, "Line", 14, 0.05, 0.4, -159, 0.3, z, "Institutional white", nil, { nc = true }) end
	local cols = { "Bright red", "Bright blue", "Institutional white", "Really black", "Bright yellow", "Bright green" }
	for i = 0, 5 do car(b, i % 2 == 0 and -196 or -159, 70 + i * 22, 90, cols[i + 1]) end
	local s = U.blk(b, "P", 4, 4, 0.4, -177, 6, 62, "Bright blue", "SmoothPlastic")
	U.text(s, "P", Color3.new(1, 1, 1), nil, "Front")
	U.blk(b, "Pole", 0.4, 6, 0.4, -177, 0, 62.4, "Dark stone grey", "Metal")
	PT(b, "arrive", { p = V(-170, 0, 120) })
end
function K.taxi(b)
	U.blk(b, "Island", 12, 0.6, 40, 168, 0, 80, "Light stone grey", "Concrete")
	U.blk(b, "Pole", 0.4, 8, 0.4, 168, 0, 62, "Dark stone grey", "Metal")
	local s = U.blk(b, "Sign", 8, 3, 0.4, 168, 8, 62, "Bright yellow", "SmoothPlastic")
	U.text(s, "TAXI", Color3.new(0, 0, 0), nil, "Front")
	car(b, 190, 72, 0, "Bright yellow") car(b, 190, 90, 0, "Bright yellow")
	PT(b, "arrive", { p = V(162, 0, 80) })
end
function K.floor(b)
	U.blk(b, "Floor", 280, 1, 260, 0, 0, 190, "Institutional white", "Marble")
	U.blk(b, "Step", 40, 0.5, 4, 0, 0, 58, "Light stone grey", "Marble")
	for _, p in ipairs({ { -60, 140 }, { 70, 120 } }) do SPOT(b, "janitor", p[1], F, p[2], 30) end
end
function K.walls(b)
	local h = WALL_H
	-- front: glass with white frames, door gap in the middle
	for _, seg in ipairs({ { -140, -12 }, { 12, 140 } }) do
		local w = seg[2] - seg[1]
		U.blk(b, "FrontGlass", w, h, 0.6, (seg[1] + seg[2]) / 2, F, 60, "Pastel light blue", "Glass", { tr = 0.55 })
		for x = seg[1], seg[2], 16 do U.blk(b, "Frame", 1.2, h, 1.2, x, F, 60, "Institutional white", "SmoothPlastic") end
	end
	U.blk(b, "Lintel", 26, h - 13, 1.2, 0, F + 13, 60, "Institutional white", "SmoothPlastic")
	-- sides
	for _, x in ipairs({ -140, 140 }) do
		U.blk(b, "SideWall", 1.4, h, 261, x, F, 190, "Institutional white", "SmoothPlastic")
		U.blk(b, "Stripe", 1.6, 2, 261, x, F + 20, 190, b.plot.color, "SmoothPlastic")
	end
	-- back (airside): glass with openings for the 4 jet bridges
	local gx = { -105, -35, 35, 105 }
	local edges = { -140 }
	for _, x in ipairs(gx) do table.insert(edges, x - 5) table.insert(edges, x + 5) end
	table.insert(edges, 140)
	for i = 1, #edges, 2 do
		local a, c = edges[i], edges[i + 1]
		U.blk(b, "BackGlass", c - a, h, 0.6, (a + c) / 2, F, 320, "Pastel light blue", "Glass", { tr = 0.55 })
	end
	for _, x in ipairs(gx) do U.blk(b, "Lintel", 10, h - 12, 1.2, x, F + 12, 320, "Institutional white", "SmoothPlastic") end
	for x = -140, 140, 20 do U.blk(b, "Frame", 1.2, h, 1.2, x, F, 320, "Institutional white", "SmoothPlastic") end
	U.blk(b, "Cornice", 284, 2, 2, 0, F + h, 60, b.plot.color, "SmoothPlastic")
	U.blk(b, "Cornice", 284, 2, 2, 0, F + h, 320, b.plot.color, "SmoothPlastic")
end
function K.doors(b)
	for _, x in ipairs({ -6, 6 }) do U.blk(b, "Door", 11.6, 12, 0.4, x, F, 60, "Pastel light blue", "Glass", { tr = 0.65, nc = true }) end
	U.blk(b, "DoorFrame", 26, 1, 1.4, 0, F + 12, 60, "Dark stone grey", "Metal")
	local s = U.blk(b, "Sign", 26, 3, 0.4, 0, F + 13.2, 59.2, "Navy blue", "SmoothPlastic")
	U.text(s, "DEPARTURES", Color3.new(1, 1, 1), Color3.new(0.05, 0.1, 0.3), "Front")
	U.blk(b, "Canopy", 34, 0.8, 10, 0, F + 16, 55, b.plot.color, "SmoothPlastic")
end
function K.lights(b)
	for _, x in ipairs({ -100, -50, 0, 50, 100 }) do
		for _, z in ipairs({ 80, 130, 180, 230, 290 }) do
			local p = U.blk(b, "Light", 10, 0.4, 3, x, F + 25, z, "Institutional white", "Neon", { nc = true })
			if (x == -50 or x == 50) and (z == 130 or z == 230) then U.light(p, Color3.new(1, 0.97, 0.9), 50, 1) end
		end
	end
end
function K.infodesk(b, o)
	U.cyl(b, "Desk", 10, 3.6, o.x, F, o.z, "Institutional white", "Marble")
	U.cyl(b, "Top", 10.6, 0.4, o.x, F + 3.6, o.z, b.plot.color, "SmoothPlastic")
	local s = U.blk(b, "Sign", 4, 4, 0.4, o.x, F + 7, o.z, "Bright blue", "SmoothPlastic")
	U.text(s, "i", Color3.new(1, 1, 1), nil, "Front") U.text(s, "i", Color3.new(1, 1, 1), nil, "Back")
	U.blk(b, "Pole", 0.3, 3, 0.3, o.x, F + 4, o.z, "Dark stone grey")
	SPOT(b, "janitor", o.x + 8, F, o.z + 6, 0)
end
function K.benches(b)
	for _, x in ipairs({ -130, -70, 70, 130 }) do
		U.seat(b, x - 1.6, 0.5, 51.5, 180, "Brown", 3) U.seat(b, x + 1.6, 0.5, 51.5, 180, "Brown", 3)
		U.blk(b, "Back", 6.4, 2, 0.4, x, 1.5, 52.8, "Brown", "Wood")
	end
end
function K.flags(b)
	local cols = { "Bright red", "Bright blue", "Bright green", "Bright yellow" }
	for i, x in ipairs({ -110, -90, 90, 110 }) do
		U.cyl(b, "Pole", 0.5, 20, x, 0.5, 50, "Light stone grey", "Metal")
		U.blk(b, "Flag", 5, 3, 0.2, x + 2.7, 17, 50, cols[i], "Fabric")
	end
end
function K.trash(b)
	for _, p in ipairs({ { 25, 70 }, { -25, 70 }, { 25, 166 }, { -25, 166 }, { 22, 284 }, { -22, 284 } }) do
		U.cyl(b, "Bin", 1.8, 2.8, p[1], F, p[2], "Dark stone grey", "Metal")
		U.cyl(b, "Lid", 2, 0.3, p[1], F + 2.8, p[2], "Bright green", "Metal")
	end
end
function K.bus(b)
	U.blk(b, "Shelter", 10, 0.5, 18, 170, 9, 122, "Light stone grey", "Metal")
	U.blk(b, "Back", 0.4, 8, 18, 175, 0.5, 122, "Pastel light blue", "Glass", { tr = 0.5 })
	U.seat(b, 172, 0.5, 118, 90, "Bright blue", 3) U.seat(b, 172, 0.5, 126, 90, "Bright blue", 3)
	U.blk(b, "Bus", 9, 9, 32, 192, 0.8, 122, "Bright green", "SmoothPlastic")
	U.blk(b, "BusWindows", 9.1, 3, 28, 192, 5, 122, "Really black", "Glass")
	U.blk(b, "BusSign", 7, 1.4, 0.2, 192, 8, 105.9, "Really black", "Neon")
	for _, z in ipairs({ 112, 132 }) do for _, x in ipairs({ 187.5, 196.5 }) do U.P(b, "Wheel", V(1, 3, 3), U.L(x, 1.5, z), "Really black", nil, { shape = "cyl" }) end end
	PT(b, "arrive", { p = V(166, 0, 122) })
end
function K.billboards(b)
	for i, x in ipairs({ -30, 50 }) do
		for _, dx in ipairs({ -8, 8 }) do U.blk(b, "Post", 0.8, 22, 0.8, x + dx, 0, 6, "Dark stone grey", "Metal") end
		local s = U.blk(b, "Billboard", 22, 8, 0.6, x, 20, 6, "Institutional white", "SmoothPlastic")
		U.text(s, i == 1 and "FLY WITH US!" or "BEST AIRPORT IN TOWN", Color3.new(1, 1, 1), BrickColor.new(b.plot.color).Color, "Front")
	end
end

------------------------------------------------------------------ 2. check-in
function K.desk(b, o)
	counter(b, 26, 3, 4, o.x, 100, 0, "Institutional white")
	U.blk(b, "Top", 26.4, 0.4, 3.4, o.x, F + 4, 100, b.plot.color, "SmoothPlastic")
	for _, dx in ipairs({ -6, 6 }) do
		U.blk(b, "Screen", 2.4, 1.6, 0.2, o.x + dx, F + 4.6, 100.6, "Really black", "Neon")
		U.blk(b, "Scale", 3, 0.6, 3, o.x + dx, F, 96.6, "Dark stone grey", "Metal")
	end
	hangSign(b, "CHECK-IN " .. o.n, 14, 3, o.x, F + 14, 101, 0)
	SPOT(b, "agent", o.x, F, 104, 0)
	PT(b, "desk", { q = V(o.x, F, 94), n = o.n, lx = o.x })
end
function K.queue(b)
	for _, g in ipairs({ { -128, -32 }, { 32, 128 } }) do
		for x = g[1], g[2], 8 do
			for _, z in ipairs({ 82, 88 }) do U.cyl(b, "Post", 0.5, 3, x, F, z, "Light stone grey", "Metal") end
		end
		for _, z in ipairs({ 82, 88 }) do U.blk(b, "Rope", g[2] - g[1], 0.3, 0.2, (g[1] + g[2]) / 2, F + 2.6, z, "Bright red", "Fabric", { nc = true }) end
	end
end
function K.carts(b)
	for i = 0, 3 do
		local x = 30 + i * 3.2
		U.blk(b, "Cart", 2.4, 0.3, 4, x, F + 1, 84, "Light stone grey", "Metal")
		U.blk(b, "Handle", 2.4, 2.4, 0.2, x, F + 1, 86, "Light stone grey", "Metal")
		U.blk(b, "Suitcase", 1.8, 1.4, 2, x, F + 1.3, 83.5, U.pick({ "Bright red", "Bright blue", "Really black" }))
	end
end
function K.belt(b)
	for _, g in ipairs({ { -128, -32 }, { 32, 128 } }) do
		U.blk(b, "Belt", g[2] - g[1], 1.2, 3, (g[1] + g[2]) / 2, F, 112, "Really black", "DiamondPlate")
		U.blk(b, "BeltSide", g[2] - g[1], 0.4, 0.4, (g[1] + g[2]) / 2, F + 1.2, 113.6, "Dark stone grey", "Metal")
		for x = g[1] + 8, g[2] - 8, 18 do U.blk(b, "Bag", 2, 1.4, 1.6, x, F + 1.2, 112, U.pick({ "Bright red", "Bright blue", "Bright yellow", "Royal purple" })) end
	end
	for _, x in ipairs({ -100, -60, 60, 100 }) do SPOT(b, "handler", x, F, 116, 180) end
end
function K.kiosks(b, o)
	for _, dx in ipairs({ -6, 6 }) do
		U.blk(b, "Kiosk", 2.4, 5, 1.6, o.x + dx, F, 70, "Institutional white", "SmoothPlastic")
		U.blk(b, "Screen", 2, 1.6, 0.2, o.x + dx, F + 3.2, 69.1, "Cyan", "Neon")
	end
	PT(b, "desk", { q = V(o.x, F, 66), kiosk = true, lx = o.x })
end
function K.board(b)
	local s = U.P(b, "Board", V(44, 10, 1), U.L(0, F + 19, 123), "Really black", "SmoothPlastic")
	local lines = "DEPARTURES\nSKY 101   LONDON     BOARDING\nSKY 202   TOKYO      ON TIME\nSKY 303   PARIS      ON TIME\nSKY 404   NEW YORK   DELAYED"
	U.text(s, lines, Color3.new(1, 0.85, 0.2), Color3.new(0.02, 0.02, 0.05), "Front", Enum.Font.Code)
	U.text(s, lines, Color3.new(1, 0.85, 0.2), Color3.new(0.02, 0.02, 0.05), "Back", Enum.Font.Code)
	for _, dx in ipairs({ -18, 18 }) do U.blk(b, "Cable", 0.2, 6, 0.2, dx, F + 24, 123, "Dark stone grey", nil, { nc = true }) end
end
function K.atm(b)
	for _, x in ipairs({ -26, -32 }) do
		U.blk(b, "ATM", 4, 7, 2.4, x, F, 64, "Bright green", "SmoothPlastic")
		U.blk(b, "Screen", 2.4, 1.6, 0.2, x, F + 4.4, 65.3, "Cyan", "Neon")
	end
end

------------------------------------------------------------------ 3. security
function K.secwall(b)
	local edges = { { -140, -96 }, { -88, -64 }, { -56, -34 }, { -26, -4 }, { 4, 26 }, { 34, 56 }, { 64, 88 }, { 96, 140 } }
	for _, e in ipairs(edges) do
		U.blk(b, "Partition", e[2] - e[1], 7, 0.5, (e[1] + e[2]) / 2, F, 126, "Pastel light blue", "Glass", { tr = 0.5 })
		U.blk(b, "PartitionTop", e[2] - e[1], 0.4, 0.7, (e[1] + e[2]) / 2, F + 7, 126, "Dark stone grey", "Metal")
	end
	hangSign(b, "SECURITY", 24, 3.4, 0, F + 15, 126, 0, Color3.new(0.6, 0.05, 0.05))
end
local function lanePoints(b, x)
	PT(b, "lane", { a = V(x, F, 120), b = V(x, F, 140), c = V(x, F, 156), lx = x })
end
function K.lane(b, o)
	local x = o.x
	U.blk(b, "XRay", 3.6, 3.6, 8, x + 5.5, F + 0.8, 136, "Light stone grey", "Metal")
	U.blk(b, "XRayHole", 3.7, 1.6, 2, x + 5.5, F + 1.4, 136, "Really black", nil, { nc = true })
	U.blk(b, "Conveyor", 2.4, 1, 20, x + 5.5, F, 136, "Really black", "DiamondPlate")
	U.blk(b, "Screen", 2, 1.4, 0.2, x + 8.8, F + 4, 132, "Lime green", "Neon")
	for _, dx in ipairs({ -2.4, 2.4 }) do U.blk(b, "Detector", 0.8, 7, 1.2, x + dx, F, 140, "Light stone grey", "Metal") end
	U.blk(b, "DetectorTop", 5.6, 0.8, 1.2, x, F + 7, 140, "Light stone grey", "Metal")
	U.blk(b, "DetectorLight", 1.2, 0.4, 0.4, x, F + 7.9, 140, "Lime green", "Neon")
	U.blk(b, "Bins", 1.8, 1.4, 2.6, x + 9, F, 126.5, "Dark stone grey")
	SPOT(b, "officer", x - 4.5, F, 140, -90)
	SPOT(b, "officer", x + 9.5, F, 144, 90)
	lanePoints(b, x)
end
function K.office(b)
	local c = { model = b.model, cf = b.cf * U.L(-126, 0, 143), plot = b.plot }
	U.blk(c, "Wall", 28, 10, 0.5, 0, F, -15, "Light stone grey", "SmoothPlastic")
	U.blk(c, "Wall", 28, 10, 0.5, 0, F, 15, "Light stone grey", "SmoothPlastic")
	U.blk(c, "Wall", 0.5, 10, 10, 14, F, -10, "Light stone grey", "SmoothPlastic")
	U.blk(c, "Wall", 0.5, 10, 10, 14, F, 10, "Light stone grey", "SmoothPlastic")
	U.blk(c, "Window", 0.4, 4, 8, 14, F + 4, 0, "Pastel light blue", "Glass", { tr = 0.5 })
	U.blk(c, "Desk", 8, 3, 3, -5, F, 0, "Brown", "Wood")
	for _, z in ipairs({ -1, 1 }) do U.blk(c, "Monitor", 0.3, 2, 2.4, -5.5, F + 3, z * 1.6, "Lime green", "Neon") end
	local s = U.blk(c, "Sign", 0.4, 2, 12, 14.4, F + 10.5, 0, "Really black")
	U.text(s, "SECURITY OFFICE", Color3.new(1, 1, 1), Color3.new(0.5, 0.05, 0.05), "Right")
	SPOT(b, "officer", -130, F, 143, 90)
end
function K.cctv(b)
	for _, p in ipairs({ { -139, 130 }, { -139, 200 }, { 139, 130 }, { 139, 200 }, { -139, 270 }, { 139, 270 } }) do
		local x = p[1]
		local cam = U.blk(b, "Camera", 1.2, 1.2, 2.2, x + (x < 0 and 1 or -1), F + 20, p[2], "Institutional white", "SmoothPlastic", nil, x < 0 and -60 or 60)
		U.blk(b, "CameraLight", 0.4, 0.4, 0.4, x + (x < 0 and 1.8 or -1.8), F + 20.4, p[2], "Really red", "Neon", { nc = true })
	end
end
function K.scanner(b, o)
	local x = o.x
	U.cyl(b, "Base", 6, 0.4, x, F, 140, "Light stone grey", "Metal")
	for _, dx in ipairs({ -2.6, 2.6 }) do U.blk(b, "Panel", 0.8, 8, 4, x + dx, F + 0.4, 140, "Institutional white", "SmoothPlastic") end
	U.cyl(b, "Top", 6, 0.6, x, F + 8.4, 140, "Institutional white", "SmoothPlastic")
	U.blk(b, "Scan", 4.4, 7.6, 0.2, x, F + 0.6, 140, "Cyan", "Neon", { tr = 0.5, nc = true })
	SPOT(b, "officer", x + (x < 0 and -5 or 5), F, 140, x < 0 and -90 or 90)
	lanePoints(b, x)
end
function K.k9(b)
	local c = { model = b.model, cf = b.cf * U.L(118, F, 143, 90), plot = b.plot }
	U.blk(c, "Dog", 1.4, 1.4, 3.4, 0, 1, -4, "Brown")
	U.P(c, "DogHead", V(1.2, 1.2, 1.6), U.L(0, 2.6, -6.1), "Brown")
	U.P(c, "Ear", V(0.3, 0.8, 0.3), U.L(0.4, 3.4, -5.9), "Really black")
	U.P(c, "Ear", V(0.3, 0.8, 0.3), U.L(-0.4, 3.4, -5.9), "Really black")
	for _, p in ipairs({ { -0.5, -5.3 }, { 0.5, -5.3 }, { -0.5, -2.7 }, { 0.5, -2.7 } }) do U.blk(c, "Leg", 0.4, 1, 0.4, p[1], 0, p[2], "Brown") end
	U.blk(c, "Vest", 1.5, 0.8, 2, 0, 1.6, -4, "Really black", "Fabric")
	M.person(b.model, b.cf * U.L(118, F, 143, 90), { shirt = "Really black", pants = "Navy blue", hat = "cap", hatColor = "Really black" }, "K9 Officer")
end

------------------------------------------------------------------ 4. gates, planes and airside
function K.gate(b, o)
	local x = o.x
	U.blk(b, "GateDesk", 8, 3.6, 2.4, x + 10, F, 308, "Institutional white", "SmoothPlastic")
	U.blk(b, "GateDeskTop", 8.4, 0.4, 2.8, x + 10, F + 3.6, 308, b.plot.color, "SmoothPlastic")
	for row = 0, 1 do
		for i = 0, 5 do U.seat(b, x - 16 + i * 2.4, F, 286 + row * 6, 180, b.plot.color, 2) end
		U.blk(b, "SeatBack", 14.4, 2.4, 0.4, x - 10, F + 1, 287.3 + row * 6, "Dark stone grey", "Metal")
	end
	hangSign(b, "GATE " .. o.n, 12, 3.6, x, F + 15, 317, 0, Color3.new(0.95, 0.75, 0.1), Color3.new(0, 0, 0))
	SPOT(b, "gateagent", x + 10, F, 311, 0)
	PT(b, "gate", { p = V(x, F, 300), door = V(x, F, 317), n = o.n, lx = x })
end
function K.apron(b)
	U.blk(b, "Apron", 420, 0.3, 124, 0, 0, 384, "Medium stone grey", "Concrete")
	for _, x in ipairs({ -105, -35, 35, 105 }) do
		U.blk(b, "LeadIn", 0.8, 0.05, 110, x, 0.3, 390, "Bright yellow", nil, { nc = true })
		U.blk(b, "StopBar", 8, 0.05, 0.8, x, 0.3, 356, "Bright yellow", nil, { nc = true })
	end
	U.blk(b, "Edge", 420, 0.05, 1, 0, 0.3, 445, "Bright yellow", nil, { nc = true })
end
function K.bridge(b, o)
	local x = o.x
	-- a tube from the terminal back wall (z 320, floor height) rising to the plane door (z 352, y ~6)
	local a, c = Vector3.new(x, F + 4, 321), Vector3.new(x, 9.2, 350)
	local mid = (a + c) / 2
	local len = (c - a).magnitude
	U.P(b, "Tube", V(7, 8, len), CFrame.new(mid, c), "Light stone grey", "Metal")
	U.P(b, "TubeWindows", V(7.1, 1.6, len - 4), CFrame.new(mid + Vector3.new(0, 1.4, 0), c + Vector3.new(0, 1.4, 0)), "Really black", "Glass")
	U.blk(b, "Rotunda", 10, 9, 8, x, 4.8, 352, "Light stone grey", "Metal")
	U.blk(b, "Leg", 1, 5, 1, x - 3, 0.3, 346, "Dark stone grey", "Metal")
	U.blk(b, "Leg", 1, 5, 1, x + 3, 0.3, 346, "Dark stone grey", "Metal")
	U.blk(b, "Wheels", 6, 1.4, 2, x, 0.3, 346, "Really black")
	SPOT(b, "pilot", x + 2, 5.2, 350, 0)
	PT(b, "bridge", { e = V(x, 6, 351), lx = x, n = o.n })
	A.gatePlane(b.plot, o.n, x)
end
function K.groundvehicles(b)
	-- baggage tug + carts, fuel truck, stairs truck
	U.blk(b, "Tug", 4, 2.6, 5, 60, 0.3, 436, "Bright yellow", "SmoothPlastic")
	for i = 1, 3 do U.blk(b, "BagCart", 4, 2.4, 5, 60, 0.6, 436 + i * 6.4, "Light stone grey", "Metal") U.blk(b, "Bags", 3.4, 1.4, 4, 60, 3, 436 + i * 6.4, U.pick({ "Bright red", "Bright blue", "Really black" })) end
	U.blk(b, "FuelTruck", 5, 5, 14, -70, 0.6, 438, "Institutional white", "SmoothPlastic")
	U.P(b, "FuelTank", V(10, 4.4, 4.4), U.L(-70, 4.8, 440, 90), "Light stone grey", "Metal", { shape = "cyl" })
	U.blk(b, "Stairs", 4, 6, 10, 0, 0.3, 436, "Institutional white", "SmoothPlastic")
	U.P(b, "StairRamp", V(3.6, 6, 8), U.L(0, 9, 434), "Light stone grey", "Metal", { class = "WedgePart" })
end
function K.taxiway(b)
	U.blk(b, "Taxiway", 420, 0.3, 24, 0, 0, 460, "Dark stone grey", "Concrete")
	for x = -200, 200, 14 do U.blk(b, "Line", 7, 0.05, 0.6, x, 0.3, 460, "Bright yellow", nil, { nc = true }) end
	for _, x in ipairs({ -190, 190 }) do U.blk(b, "Connector", 24, 0.3, 20, x, 0, 481, "Dark stone grey", "Concrete") end
end
function K.runway(b)
	U.blk(b, "Runway", 410, 0.3, 70, 0, 0, 525, "Really black", "Concrete")
	for x = -170, 170, 25 do U.blk(b, "Center", 12, 0.05, 1, x, 0.3, 525, "Institutional white", nil, { nc = true }) end
	for _, x in ipairs({ -195, 195 }) do
		for z = 498, 552, 6 do U.blk(b, "Threshold", 10, 0.05, 2.4, x, 0.3, z, "Institutional white", nil, { nc = true }) end
	end
	for _, e in ipairs({ { -178, "09", -90 }, { 178, "27", 90 } }) do
		local n = U.P(b, "Number", V(14, 0.05, 10), U.L(e[1], 0.33, 525, e[3]), "Really black", nil, { nc = true })
		U.text(n, e[2], Color3.new(1, 1, 1), nil, "Top")
	end
	U.blk(b, "EdgeL", 410, 0.05, 1, 0, 0.3, 491, "Institutional white", nil, { nc = true })
	U.blk(b, "EdgeR", 410, 0.05, 1, 0, 0.3, 559, "Institutional white", nil, { nc = true })
	b.plot.hasRunway = true
	A.startDepartures(b.plot)
end
function K.rwlights(b)
	for x = -200, 200, 25 do
		for _, z in ipairs({ 489.6, 560.4 }) do U.blk(b, "RunwayLight", 0.8, 0.5, 0.8, x, 0.3, z, x < 0 and "Lime green" or "Really red", "Neon", { nc = true }) end
	end
	for i = 1, 5 do U.blk(b, "Approach", 1, 1, 3, -205 - i * 0, 0.3, 525 + (i - 3) * 4, "Bright yellow", "Neon", { nc = true }) end
end
function K.windsock(b)
	U.cyl(b, "Pole", 0.4, 10, 205, 0, 575, "Light stone grey", "Metal")
	U.P(b, "Sock", V(1.6, 1.6, 6), U.L(205, 9.5, 572, 0, -10), "Bright orange", "Fabric", { class = "WedgePart" })
end
function K.tower(b)
	U.cyl(b, "Shaft", 8, 52, -192, 0, 338, "Institutional white", "Concrete")
	U.cyl(b, "Cab", 15, 8, -192, 52, 338, "Pastel light blue", "Glass", { tr = 0.35 })
	U.cyl(b, "CabFloor", 16, 1, -192, 51.5, 338, "Dark stone grey", "Metal")
	U.cyl(b, "Roof", 17, 1.4, -192, 60, 338, b.plot.color, "SmoothPlastic")
	U.cyl(b, "Antenna", 0.4, 8, -192, 61.4, 338, "Really red", "Metal")
	U.light(U.ball(b, "Beacon", 1, -192, 69.6, 338, "Really red", "Neon"), Color3.new(1, 0.2, 0.2), 20)
	U.blk(b, "Desk", 6, 2.5, 2, -192, 52.5, 334, "Dark stone grey")
	SPOT(b, "atc", -194, 52.5, 340, 180)
	SPOT(b, "atc", -189, 52.5, 340, 180)
end
function K.radar(b)
	U.cyl(b, "Mast", 1.2, 10, -168, 0, 362, "Light stone grey", "Metal")
	local dish = U.P(b, "Dish", V(9, 4, 0.6), U.L(-168, 11.5, 362, 0, 15), "Institutional white", "Metal")
	local arm = U.P(b, "Arm", V(0.4, 0.4, 3), U.L(-168, 11, 363), "Dark stone grey", "Metal")
	U.spin({ dish, arm }, b.cf * U.L(-168, 11, 362), "y", 60)
end
function K.helipad(b)
	U.cyl(b, "Pad", 32, 0.3, 178, 0, 400, "Dark stone grey", "Concrete")
	U.blk(b, "H1", 1.6, 0.05, 12, 174, 0.3, 400, "Institutional white", nil, { nc = true })
	U.blk(b, "H2", 1.6, 0.05, 12, 182, 0.3, 400, "Institutional white", nil, { nc = true })
	U.blk(b, "H3", 8, 0.05, 1.6, 178, 0.3, 400, "Institutional white", nil, { nc = true })
	-- helicopter
	U.P(b, "HeliBody", V(5, 5, 7), U.L(178, 3.4, 410), b.plot.color, "SmoothPlastic", { shape = "ball" })
	U.P(b, "HeliTail", V(1, 1, 9), U.L(178, 3.8, 417), b.plot.color, "SmoothPlastic")
	U.P(b, "HeliGlass", V(4, 2.4, 2), U.L(178, 4, 407), "Really black", "Glass", { tr = 0.3 })
	for _, x in ipairs({ -2, 2 }) do U.P(b, "Skid", V(0.4, 0.4, 7), U.L(178 + x, 0.6, 410), "Dark stone grey", "Metal") end
	local r1 = U.P(b, "Rotor", V(14, 0.2, 0.8), U.L(178, 6.4, 410), "Really black", nil, { nc = true })
	local r2 = U.P(b, "Rotor", V(0.8, 0.2, 14), U.L(178, 6.4, 410), "Really black", nil, { nc = true })
	U.spin({ r1, r2 }, b.cf * U.L(178, 6.4, 410), "y", 140)
end
function K.hangar(b)
	U.blk(b, "Floor", 80, 0.3, 44, 160, 0, 593, "Medium stone grey", "Concrete")
	U.blk(b, "Back", 80, 20, 1, 160, 0, 615, "Light stone grey", "CorrodedMetal")
	U.blk(b, "Side", 1, 20, 44, 120, 0, 593, "Light stone grey", "CorrodedMetal")
	U.blk(b, "Side", 1, 20, 44, 200, 0, 593, "Light stone grey", "CorrodedMetal")
	U.P(b, "Roof", V(81, 6, 22.5), U.L(160, 23, 582), "Medium stone grey", "CorrodedMetal", { class = "WedgePart" })
	U.P(b, "Roof", V(81, 6, 22.5), U.L(160, 23, 604, 180), "Medium stone grey", "CorrodedMetal", { class = "WedgePart" })
	U.blk(b, "DoorTop", 80, 3, 1, 160, 17, 571, "Light stone grey", "CorrodedMetal")
	local s = U.blk(b, "Sign", 30, 4, 0.4, 160, 21, 570.4, b.plot.color, "SmoothPlastic")
	U.text(s, "HANGAR", Color3.new(1, 1, 1), nil, "Front")
	U.blk(b, "Toolbox", 4, 4, 2, 192, 0.3, 610, "Bright red", "Metal")
	SPOT(b, "mechanic", 135, 0.3, 600, 180)
	SPOT(b, "mechanic", 185, 0.3, 600, 180)
end
function K.planepad(b, o)
	local pad = U.blk(b, "FlyPad", 9, 0.4, 7, o.x, 0, 566, "Cyan", "Neon")
	local names = { small = "FLY SMALL PLANE", jet = "FLY FIGHTER JET", private = "FLY PRIVATE JET" }
	U.bill(pad, names[o.plane] .. "\n(step here)", 12, 3, 5, Color3.new(0.6, 1, 1))
	U.light(pad, Color3.new(0.3, 0.9, 1), 12)
	b.plot.flyPads[o.plane] = pad
	A.flyPad(b.plot, pad, o.plane)
end
function K.fuel(b)
	U.blk(b, "Base", 52, 0.3, 44, -176, 0, 593, "Medium stone grey", "Concrete")
	for i, x in ipairs({ -192, -176, -160 }) do
		U.cyl(b, "Tank", 12, 12, x, 0.3, 598, "Institutional white", "Metal")
		U.cyl(b, "TankTop", 12.4, 0.6, x, 12.3, 598, "Bright red", "Metal")
	end
	U.blk(b, "Pipe", 40, 1, 1, -176, 1.5, 588, "Bright yellow", "Metal")
	local s = U.blk(b, "Sign", 14, 3, 0.4, -176, 14, 590.8, "Bright red", "SmoothPlastic")
	U.text(s, "FUEL", Color3.new(1, 1, 1), nil, "Front")
end
function K.firestation(b)
	U.blk(b, "Station", 58, 16, 40, 70, 0, 595, "Bright red", "Brick")
	for _, x in ipairs({ 56, 84 }) do U.blk(b, "Door", 18, 12, 0.4, x, 0, 574.8, "Light stone grey", "Metal") end
	local s = U.blk(b, "Sign", 30, 3, 0.4, 70, 12.5, 574.6, "Institutional white", "SmoothPlastic")
	U.text(s, "FIRE STATION", Color3.new(0.8, 0, 0), nil, "Front")
	-- fire truck parked outside
	U.blk(b, "Truck", 8, 7, 18, 100, 0.8, 578, "Bright red", "SmoothPlastic", nil, 90)
	U.blk(b, "Ladder", 1.4, 0.8, 14, 100, 7.8, 578, "Light stone grey", "Metal", nil, 90)
	U.light(U.blk(b, "Siren", 3, 0.6, 1, 100, 7.8, 578, "Really red", "Neon", nil, 90), Color3.new(1, 0.1, 0.1), 14)
	for _, x in ipairs({ 50, 64, 78 }) do SPOT(b, "firefighter", x, 0.3, 571, 0) end
end
function K.cargo(b)
	U.blk(b, "Warehouse", 90, 18, 30, -85, 0, 600, "Sand blue", "CorrodedMetal")
	U.blk(b, "Dock", 90, 2, 6, -85, 0, 582, "Medium stone grey", "Concrete")
	local cols = { "Bright red", "Bright blue", "Bright green", "Bright orange", "Bright yellow" }
	for i = 0, 4 do U.blk(b, "Container", 14, 6, 6, -120 + i * 17, 0.3, 576, cols[i + 1], "CorrodedMetal") end
	U.blk(b, "Container", 14, 6, 6, -103, 6.3, 576, "Teal", "CorrodedMetal")
	local s = U.blk(b, "Sign", 30, 3, 0.4, -85, 18.5, 584.8, "Institutional white", "SmoothPlastic")
	U.text(s, "CARGO", Color3.new(0.1, 0.2, 0.5), nil, "Front")
end

------------------------------------------------------------------ 5. food court
function K.foodcourt(b)
	U.blk(b, "FoodFloor", 120, 0.1, 86, -80, F, 205, "Brick yellow", "SmoothPlastic", { nc = true })
	hangSign(b, "FOOD COURT", 30, 4, -80, F + 16, 163, 0, Color3.new(0.85, 0.35, 0.1))
end
function K.stall(b, o)
	local c = b.cf * faceCF(o.x, o.z, o.face)
	local bb = booth(b, c, 16, 10, 10, o.color, o.title)
	U.blk(bb, "Counter", 14, 3.6, 2, 0, F, -3.5, "Institutional white", "SmoothPlastic")
	U.blk(bb, "CounterTop", 14.4, 0.4, 2.4, 0, F + 3.6, -3.5, o.color, "SmoothPlastic")
	U.blk(bb, "Menu", 10, 3, 0.2, 0, F + 5.4, 4.6, "Really black", "Neon")
	for i = -1, 1 do U.blk(bb, "Food", 1.4, 0.8, 1.4, i * 4, F + 4, -3.5, U.pick({ "Bright yellow", "Bright orange", "Brown", "Bright red" })) end
	U.light(U.blk(bb, "Lamp", 2, 0.4, 2, 0, F + 9.2, 0, "Cool yellow", "Neon", { nc = true }), Color3.new(1, 0.9, 0.6), 14)
	b.plot.spots.chef = b.plot.spots.chef or {}
	table.insert(b.plot.spots.chef, c * U.L(0, F, 1, 0))
	local lp = b.cf:inverse() * (c * Vector3.new(0, F, -9))
	PT(b, "stall", { p = lp, spend = ITEM["stall" .. o.n].eff.spend, lx = lp.x, n = o.n })
end
function K.tables(b, o)
	for _, dx in ipairs({ -6, 6 }) do
		local x = o.x + dx
		U.cyl(b, "Table", 4.4, 0.4, x, F + 3, o.z, "Institutional white", "SmoothPlastic")
		U.cyl(b, "TableLeg", 0.6, 3, x, F, o.z, "Dark stone grey", "Metal")
		for a = 0, 270, 90 do
			local r = math.rad(a)
			U.seat(b, x + math.cos(r) * 3.4, F, o.z + math.sin(r) * 3.4, -a - 90, "Bright orange", 1.6)
		end
	end
end
function K.vending(b)
	local cols = { "Bright red", "Bright blue", "Bright green" }
	for i, z in ipairs({ 147, 152, 157 }) do
		U.blk(b, "Vending", 3, 7, 4.4, 137, F, z, cols[i], "SmoothPlastic")
		U.blk(b, "Glass", 0.2, 4, 3, 135.4, F + 2.4, z, "Pastel light blue", "Neon", { tr = 0.3 })
	end
end

------------------------------------------------------------------ 6. shops and comfort
function K.shop(b, o)
	local c = b.cf * faceCF(o.x, o.z, o.face)
	local bb = booth(b, c, 16, 10, 12, o.color, o.title, true)
	for _, dx in ipairs({ -5, 0, 5 }) do
		U.blk(bb, "Shelf", 3.6, 6, 1.6, dx, F, 3, "Light stone grey", "SmoothPlastic")
		for y = 1, 3 do U.blk(bb, "Goods", 3, 1, 1.2, dx, F + y * 1.6, 3, U.pick({ "Bright red", "Bright blue", "Bright yellow", "Lime green", "Hot pink", "Cyan" })) end
	end
	U.blk(bb, "Till", 4, 3.6, 2, 5, F, -2.5, "Institutional white", "SmoothPlastic")
	U.light(U.blk(bb, "Lamp", 3, 0.4, 3, 0, F + 11.2, 0, "Cool yellow", "Neon", { nc = true }), Color3.new(1, 0.95, 0.8), 14)
	b.plot.spots.clerk = b.plot.spots.clerk or {}
	table.insert(b.plot.spots.clerk, c * U.L(5, F, 0, 0))
	local lp = b.cf:inverse() * (c * Vector3.new(0, F, -9))
	PT(b, "shop", { p = lp, spend = ITEM["shop" .. o.n].eff.spend, lx = lp.x, n = o.n })
end
function K.seats(b, o)
	for row = 0, 1 do
		for i = -3, 3 do U.seat(b, o.x + i * 2.3, F, o.z + row * 5, 0, b.plot.color, 2) end
		U.blk(b, "SeatBack", 16, 2.4, 0.4, o.x, F + 1, o.z + row * 5 + 1.2, "Dark stone grey", "Metal")
	end
	PT(b, "seat", { p = V(o.x + math.random(-6, 6), F, o.z - 2.5), lx = o.x })
end
function K.restrooms(b)
	local c = { model = b.model, cf = b.cf * U.L(-126, 0, 266), plot = b.plot }
	U.blk(c, "Wall", 28, 12, 0.5, 0, F, -14, "Pastel light blue", "SmoothPlastic")
	U.blk(c, "Wall", 28, 12, 0.5, 0, F, 14, "Pastel light blue", "SmoothPlastic")
	U.blk(c, "Wall", 0.5, 12, 9, 14, F, -9.5, "Pastel light blue", "SmoothPlastic")
	U.blk(c, "Wall", 0.5, 12, 9, 14, F, 9.5, "Pastel light blue", "SmoothPlastic")
	for z = -10, 10, 5 do U.blk(c, "Stall", 6, 7, 0.3, -9, F, z, "Institutional white") end
	for z = -9, 9, 6 do U.blk(c, "Sink", 2, 3, 2, 10, F, z, "Institutional white", "Marble") end
	local s = U.blk(c, "Sign", 0.4, 2.4, 12, 14.4, F + 12.5, 0, "Bright blue")
	U.text(s, "RESTROOMS", Color3.new(1, 1, 1), nil, "Right")
	for _, z in ipairs({ -6, 0, 6 }) do SPOT(b, "janitor", -118, F, 266 + z, 90) end
end
function K.plants(b)
	for _, p in ipairs({ { -134, 70 }, { 134, 70 }, { -134, 120 }, { 134, 120 }, { -16, 160 }, { 16, 160 }, { -16, 244 }, { 16, 244 } }) do
		U.cyl(b, "Pot", 3, 2.4, p[1], F, p[2], "Reddish brown", "SmoothPlastic")
		U.ball(b, "Leaves", 4, p[1], F + 4, p[2], "Bright green", "Grass")
		U.ball(b, "Leaves", 3, p[1] + 0.8, F + 5.6, p[2], "Dark green", "Grass")
	end
end
function K.charging(b)
	for i, z in ipairs({ 196, 201, 206 }) do
		U.blk(b, "Charger", 1.6, 4.4, 1.6, 69, F, z, "Institutional white", "SmoothPlastic")
		U.blk(b, "Screen", 1.2, 1.2, 0.2, 69, F + 3, z - 0.9, "Lime green", "Neon")
	end
end
local function room(b, x0, x1, title, color, floorColor)
	local c = { model = b.model, cf = b.cf * U.L((x0 + x1) / 2, 0, 266), plot = b.plot }
	local w = x1 - x0
	U.blk(c, "RoomFloor", w, 0.1, 28, 0, F, 0, floorColor or color, "Fabric", { nc = true })
	U.blk(c, "Wall", w, 10, 0.5, 0, F, 14, color, "SmoothPlastic")
	U.blk(c, "Wall", 0.5, 10, 28, -w / 2, F, 0, color, "SmoothPlastic")
	U.blk(c, "Wall", 0.5, 10, 28, w / 2, F, 0, color, "SmoothPlastic")
	local s = U.blk(c, "Sign", w - 2, 2.6, 0.4, 0, F + 10, -13.8, "Really black", "SmoothPlastic")
	U.text(s, title, Color3.new(1, 1, 1), BrickColor.new(color).Color, "Front")
	return c
end
function K.arcade(b)
	local c = room(b, -54, -24, "ARCADE", "Royal purple", "Really black")
	for i = -1, 1 do
		U.blk(c, "Cabinet", 3.4, 6.4, 3, i * 8, F, 8, "Really black", "SmoothPlastic")
		U.blk(c, "Screen", 2.6, 2, 0.2, i * 8, F + 4, 6.4, U.pick({ "Lime green", "Cyan", "Hot pink" }), "Neon")
		U.blk(c, "Buttons", 2.6, 0.4, 1, i * 8, F + 2.8, 6, "Bright red", "Neon")
	end
	U.light(U.blk(c, "Glow", 2, 0.4, 2, 0, F + 9.4, 0, "Hot pink", "Neon", { nc = true }), Color3.new(1, 0.3, 1), 20)
end
function K.kids(b)
	local c = room(b, 100, 140, "KIDS PLAY AREA", "Bright yellow", "Bright blue")
	U.blk(c, "SlideTower", 6, 5, 6, 10, F, 6, "Bright red", "SmoothPlastic")
	U.P(c, "Slide", V(3, 0.4, 10), U.L(10, F + 2.8, -2, 0, -28), "Bright yellow", "SmoothPlastic")
	U.blk(c, "BallPit", 12, 1.6, 10, -8, F, 4, "Bright blue", "SmoothPlastic")
	for i = 1, 14 do U.ball(c, "Ball", 1, -8 + math.random(-5, 5), F + 1.8, 4 + math.random(-4, 4), U.pick({ "Bright red", "Bright yellow", "Lime green", "Hot pink" }), nil, { nc = true }) end
end
function K.lounge(b)
	local c = room(b, -108, -60, "VIP LOUNGE", "Gold", "Bright red")
	for i = -2, 2 do U.seat(c, i * 7, F, 2, 180, "Really black", 4) U.blk(c, "SofaBack", 4.4, 2.4, 1, i * 7, F + 0.5, 3.6, "Really black", "Fabric") end
	U.blk(c, "Bar", 20, 4, 2.4, 0, F, 10, "Brown", "Wood")
	U.blk(c, "BarTop", 20.4, 0.4, 2.8, 0, F + 4, 10, "Gold", "Metal", { refl = 0.3 })
	U.light(U.blk(c, "Glow", 2, 0.4, 2, 0, F + 9.4, 0, "Gold", "Neon", { nc = true }), Color3.new(1, 0.8, 0.4), 22)
end
function K.spa(b)
	local c = room(b, 24, 56, "SPA & MASSAGE", "Teal", "Institutional white")
	for i = -1, 1 do
		U.seat(c, i * 9, F, 4, 180, "Institutional white", 3)
		U.P(c, "ChairBack", V(3, 3, 1), U.L(i * 9, F + 2.4, 5.6, 0, -15), "Institutional white", "Fabric")
	end
	for _, x in ipairs({ -13, 13 }) do U.cyl(c, "Pot", 2.4, 2, x, F, 10, "Reddish brown") U.ball(c, "Plant", 3, x, F + 3.2, 10, "Dark green", "Grass") end
end
function K.aquarium(b)
	local c = room(b, 60, 96, "AQUARIUM", "Navy blue", "Navy blue")
	U.blk(c, "Tank", 30, 9, 8, 0, F + 0.5, 6, "Cyan", "Glass", { tr = 0.45 })
	for i = 1, 8 do
		local fish = U.blk(c, "Fish", 1.4, 0.6, 0.5, math.random(-12, 12), F + 2 + math.random() * 6, 6 + math.random(-2, 2), U.pick({ "Bright orange", "Bright yellow", "Hot pink", "Institutional white" }), nil, { nc = true })
	end
	U.blk(c, "Coral", 4, 2, 3, -6, F + 0.5, 6, "Hot pink", "Slate")
	U.light(U.blk(c, "Glow", 2, 0.4, 2, 0, F + 9.4, 6, "Cyan", "Neon", { nc = true }), Color3.new(0.3, 0.8, 1), 22)
end
function K.fountain(b)
	U.cyl(b, "Basin", 13, 1.6, 0, F, 205, "Light stone grey", "Marble")
	U.cyl(b, "Water", 12, 0.2, 0, F + 1.5, 205, "Cyan", "Neon", { tr = 0.4, nc = true })
	U.cyl(b, "Pillar", 1.6, 5, 0, F + 1.6, 205, "Light stone grey", "Marble")
	local top = U.cyl(b, "Top", 4, 0.6, 0, F + 6.6, 205, "Light stone grey", "Marble")
	U.fx(top, "Sparkles")
	U.light(top, Color3.new(0.5, 0.9, 1), 18)
end
function K.roof(b)
	U.blk(b, "GlassRoof", 282, 0.6, 262, 0, F + WALL_H + 0.6, 190, "Pastel light blue", "Glass", { tr = 0.6 })
	for x = -140, 140, 35 do U.blk(b, "Beam", 1.2, 1.4, 262, x, F + WALL_H, 190, "Institutional white", "Metal") end
	for z = 60, 320, 40 do U.blk(b, "Beam", 282, 1.4, 1.2, 0, F + WALL_H, z, "Institutional white", "Metal") end
end
function K.chandeliers(b)
	for _, p in ipairs({ { -60, 140 }, { 60, 140 }, { -60, 230 }, { 60, 230 } }) do
		U.blk(b, "Chain", 0.2, 6, 0.2, p[1], F + 22, p[2], "Gold", "Metal", { nc = true })
		local c = U.cyl(b, "Ring", 7, 0.6, p[1], F + 21.4, p[2], "Gold", "Metal", { refl = 0.4, nc = true })
		for a = 0, 300, 60 do U.ball(b, "Crystal", 1, p[1] + math.cos(math.rad(a)) * 3.2, F + 21, p[2] + math.sin(math.rad(a)) * 3.2, "Cool yellow", "Neon", { nc = true }) end
		U.light(c, Color3.new(1, 0.9, 0.6), 30)
	end
end
function K.bigscreen(b)
	local s = U.P(b, "Screen", V(44, 12, 1), U.L(0, F + 21, 59), "Really black", "SmoothPlastic")
	b.plot.screenLabel = U.text(s, "WELCOME!", Color3.new(1, 1, 1), Color3.new(0.05, 0.05, 0.12), "Front")
	U.blk(b, "ScreenFrame", 45.4, 0.8, 1.4, 0, F + 27, 59, b.plot.color, "Neon")
	U.blk(b, "ScreenFrame", 45.4, 0.8, 1.4, 0, F + 14.2, 59, b.plot.color, "Neon")
end
function K.planestatue(b, o)
	U.cyl(b, "Pedestal", 8, 3, o.x, 0, o.z, "Light stone grey", "Marble")
	U.cyl(b, "Pole", 1, 8, o.x, 3, o.z, "Dark stone grey", "Metal")
	local c = { model = b.model, cf = b.cf * U.L(o.x, 13, o.z, 30, 20), plot = b.plot }
	U.P(c, "Body", V(14, 2.4, 2.4), U.L(0, 0, 0, 90), "Gold", "Metal", { shape = "cyl", refl = 0.4 })
	U.P(c, "Nose", V(2.4, 2.4, 2.4), U.L(0, 0, -7), "Gold", "Metal", { shape = "ball", refl = 0.4 })
	U.P(c, "Wing", V(14, 0.4, 3), U.L(0, -0.4, 1), "Gold", "Metal", { refl = 0.4 })
	U.P(c, "Tail", V(0.4, 3, 2.4), U.L(0, 1.6, 6.4), "Gold", "Metal", { class = "WedgePart", refl = 0.4 })
	U.fx(b.model:FindFirstChild("Pedestal"), "Sparkles")
end

------------------------------------------------------------------ 7. landside business
function K.rental(b)
	U.blk(b, "Office", 14, 9, 10, 196, 0, 150, "Institutional white", "SmoothPlastic")
	local s = U.blk(b, "Sign", 14, 2.6, 0.4, 196, 9, 144.8, "Bright orange", "SmoothPlastic")
	U.text(s, "CAR RENTAL", Color3.new(1, 1, 1), nil, "Front")
	U.blk(b, "Lot", 40, 0.3, 36, 178, 0, 176, "Dark stone grey", "Concrete")
	local cols = { "Institutional white", "Really black", "Bright red", "Bright blue" }
	for i = 0, 3 do car(b, 164 + i * 10, 178, 0, cols[i + 1]) end
end
function K.garage(b)
	for lvl = 0, 2 do
		U.blk(b, "Deck", 55, 1, 92, -177.5, lvl * 8, 252, "Light stone grey", "Concrete")
		if lvl > 0 then
			local cols = { "Bright red", "Institutional white", "Bright blue", "Really black" }
			for i = 0, 3 do car(b, -196, 215 + i * 22, 90, U.pick(cols)) end
		end
	end
	for _, x in ipairs({ -203, -152 }) do for z = 210, 294, 21 do U.blk(b, "Pillar", 1.6, 24, 1.6, x, 0, z, "Light stone grey", "Concrete") end end
	U.blk(b, "Roof", 55, 1, 92, -177.5, 24, 252, "Medium stone grey", "Concrete")
	local s = U.blk(b, "Sign", 20, 4, 0.4, -177.5, 18, 205.6, "Bright blue", "SmoothPlastic")
	U.text(s, "PARKING", Color3.new(1, 1, 1), nil, "Front")
end
function K.hotel(b)
	U.blk(b, "Hotel", 54, 70, 100, 178, 0, 262, "Institutional white", "Concrete")
	for y = 6, 64, 7 do
		U.blk(b, "Windows", 0.4, 3.6, 96, 150.8, y, 262, "Pastel light blue", "Glass", { tr = 0.2 })
		U.blk(b, "Windows", 50, 3.6, 0.4, 178, y, 211.8, "Pastel light blue", "Glass", { tr = 0.2 })
	end
	local s = U.blk(b, "Sign", 30, 6, 0.6, 178, 71, 212, "Really black", "SmoothPlastic")
	U.text(s, "HOTEL", Color3.new(1, 0.85, 0.3), nil, "Front")
	U.light(s, Color3.new(1, 0.85, 0.4), 30)
	U.blk(b, "Canopy", 20, 0.8, 8, 162, 8, 214, b.plot.color, "SmoothPlastic")
end
function K.train(b)
	U.blk(b, "Platform", 80, 1.2, 8, -80, 0, 12, "Light stone grey", "Concrete")
	U.blk(b, "Canopy", 80, 0.6, 9, -80, 9, 12, b.plot.color, "SmoothPlastic")
	for x = -116, -44, 18 do U.blk(b, "Post", 0.6, 8, 0.6, x, 1.2, 15, "Dark stone grey", "Metal") end
	for _, dz in ipairs({ -1.2, 1.2 }) do U.blk(b, "Rail", 80, 0.4, 0.4, -80, 0, 3 + dz, "Dark stone grey", "Metal") end
	for i = 0, 2 do
		local x = -105 + i * 25
		U.blk(b, "TrainCar", 22, 8, 6, x, 0.6, 3, i == 0 and "Bright red" or "Institutional white", "SmoothPlastic")
		U.blk(b, "TrainWindows", 18, 2, 6.1, x, 4.4, 3, "Really black", "Glass")
	end
	local s = U.blk(b, "Sign", 20, 2.4, 0.4, -80, 9.6, 7.4, "Navy blue", "SmoothPlastic")
	U.text(s, "AIRPORT EXPRESS", Color3.new(1, 1, 1), nil, "Front")
	PT(b, "arrive", { p = V(-80, 1.2, 14) })
end

------------------------------------------------------------------ 8. mega airport
function K.intlsign(b)
	local s = U.P(b, "IntlSign", V(110, 9, 1), U.L(0, F + WALL_H + 7, 61), "Really black", "SmoothPlastic")
	U.text(s, "INTERNATIONAL AIRPORT", Color3.new(1, 0.85, 0.25), Color3.new(0.05, 0.05, 0.1), "Front")
	U.light(s, Color3.new(1, 0.85, 0.4), 40)
	local cols = { "Bright red", "Bright blue", "Bright green", "Bright yellow", "Royal purple", "Bright orange", "Cyan", "Hot pink" }
	for i, x in ipairs({ -126, -90, -54, -18, 18, 54, 90, 126 }) do
		U.cyl(b, "Pole", 0.4, 10, x, F + WALL_H + 2, 64, "Light stone grey", "Metal")
		U.blk(b, "Flag", 4, 2.4, 0.2, x + 2.2, F + WALL_H + 9, 64, cols[i], "Fabric")
	end
	b.plot.intl = true
end
function K.fireworks(b)
	for _, x in ipairs({ -130, 130 }) do U.blk(b, "Launcher", 4, 3, 4, x, F + WALL_H + 1.2, 70, "Really black", "Metal") end
	b.plot.fireworks = true
end
function K.mascot(b)
	local c = { model = b.model, cf = b.cf * U.L(180, 0, 9), plot = b.plot }
	U.cyl(c, "Base", 10, 2, 0, 0, 0, "Light stone grey", "Marble")
	U.P(c, "Body", V(18, 9, 9), U.L(0, 10, 0, 90), b.plot.color, "SmoothPlastic", { shape = "cyl" })
	U.P(c, "Face", V(9, 9, 9), U.L(0, 10, -9), "Institutional white", "SmoothPlastic", { shape = "ball" })
	for _, x in ipairs({ -2, 2 }) do U.ball(c, "Eye", 2, x, 11.5, -13, "Really black") end
	U.blk(c, "Smile", 4, 0.6, 0.4, 0, 8.4, -13.3, "Really black")
	U.P(c, "Wing", V(26, 1, 6), U.L(0, 9, 1), "Institutional white", "SmoothPlastic")
	U.P(c, "Tail", V(1, 8, 6), U.L(0, 15, 9), b.plot.color, "SmoothPlastic", { class = "WedgePart" })
	U.P(c, "Cap", V(5, 1.6, 5), U.L(0, 15.2, -8), "Navy blue", "SmoothPlastic")
end
function K.golden(b)
	for _, x in ipairs({ -60, -36, -18, 18, 36, 60 }) do
		U.cyl(b, "GoldPillar", 3, 26, x, F, 57, "Gold", "Metal", { refl = 0.4 })
	end
	U.blk(b, "GoldTrim", 284, 1, 2.4, 0, F + WALL_H + 2, 59, "Gold", "Metal", { refl = 0.4 })
	U.blk(b, "GoldCarpet", 20, 0.1, 40, 0, F, 80, "Gold", "Fabric", { nc = true })
	U.fx(b.model:FindFirstChild("GoldTrim"), "Sparkles")
end

-- ==== s30_airport.lua
------------------------------------------------------------------ airports (plots)
local PLOT_COLORS = { "Bright red", "Bright blue", "Bright green", "Bright orange", "Royal purple",
	"Cyan", "Hot pink", "Teal", "Bright yellow", "Navy blue" }
local remote = RS:FindFirstChild("AirportEvent")
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = "AirportEvent"
	remote.Parent = RS
end
G.remote = remote

function A.toast(player, text, color)
	if player then pcall(function() remote:FireClient(player, "toast", text, color or "white") end) end
end
function A.cash(player)
	local ls = player and player:FindFirstChild("leaderstats")
	return ls and ls:FindFirstChild("Cash")
end

local function folder(parent, name)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

function A.init()
	local plots = MAP:WaitForChild("Plots")
	for i = 1, 10 do
		local pm = plots:WaitForChild("Plot" .. i)
		local plot = { i = i, cf = pm:WaitForChild("Origin").CFrame, color = PLOT_COLORS[i] }
		plot.root = folder(workspace, "Airport" .. i)
		for _, n in ipairs({ "Items", "Pads", "Staff", "People", "Planes" }) do plot[n] = folder(plot.root, n) end
		-- the pylon at the front-left corner shows who owns it
		local b = { model = plot.root, cf = plot.cf, plot = plot }
		U.blk(b, "Pylon", 3, 22, 3, -204, 0, 4, "Dark stone grey", "Metal")
		local s = U.blk(b, "PylonSign", 16, 8, 1, -204, 22, 4, "Really black", "SmoothPlastic")
		plot.header = U.text(s, "AIRPORT " .. i, Color3.new(1, 1, 1), BrickColor.new(plot.color).Color, "Front")
		U.text(s, "AIRPORT " .. i, Color3.new(1, 1, 1), BrickColor.new(plot.color).Color, "Back")
		G.plots[i] = plot
		A.reset(plot)
	end
end

function A.reset(plot)
	for _, n in ipairs({ "Items", "Pads", "Staff", "People", "Planes" }) do plot[n]:ClearAllChildren() end
	for _, f in pairs(G.flyers) do if f.plot == plot then pcall(function() f.model:Destroy() end) end end
	plot.owner = nil
	plot.bought, plot.staff, plot.spots, plot.pts, plot.cnt, plot.items, plot.pads = {}, {}, {}, {}, {}, {}, {}
	plot.reviews, plot.served, plot.earnLog, plot.incomeRate = {}, 0, {}, 0
	plot.gatePlanes, plot.flyPads = {}, {}
	plot.hasRunway, plot.intl, plot.fireworks = false, false, false
	plot.signLabel, plot.screenLabel, plot.lastReport = nil, nil, nil
	plot.spawnT, plot.nextInspect = 3, tick() + 150
	plot.header.Text = "AIRPORT " .. plot.i .. "\nFREE"
	-- claim pad
	local pad = U.blk({ model = plot.Pads, cf = plot.cf }, "Claim", 10, 0.4, 10, 0, 0, 9, "Lime green", "Neon")
	U.bill(pad, "CLAIM AIRPORT " .. plot.i .. "\n(step here, it's free)", 14, 3.5, 5, Color3.new(0.6, 1, 0.6))
	U.light(pad, Color3.new(0.4, 1, 0.4), 14)
	local busy = false
	pad.Touched:connect(function(hit)
		local player = hit.Parent and Players:GetPlayerFromCharacter(hit.Parent)
		if not player or busy then return end
		busy = true
		A.claim(plot, player)
		wait(1)
		busy = false
	end)
end

function A.claim(plot, player)
	if plot.owner then
		if plot.owner ~= player then A.toast(player, "Airport " .. plot.i .. " belongs to " .. plot.owner.Name, "red") end
		return
	end
	local mine = G.byPlayer[player]
	if mine then A.toast(player, "You already own Airport " .. mine.i, "red") return end
	plot.owner = player
	G.byPlayer[player] = plot
	plot.Pads:ClearAllChildren()
	plot.header.Text = player.Name .. "'s\nAIRPORT " .. plot.i
	plot.nextInspect = tick() + 150
	-- rebuild what this player had saved
	local saved = G.saved[player]
	if saved and saved.items then
		local have = {}
		for _, k in ipairs(saved.items) do have[k] = true end
		for _, it in ipairs(CATALOG) do
			if have[it.key] and ITEM[it.key] then A.build(plot, it, true) end
		end
		if saved.staff then
			for _, st in ipairs(STAFF) do
				local n = tonumber(saved.staff[st.key]) or 0
				for _ = 1, math.min(n, A.staffCap(plot, st)) do
					plot.staff[st.key] = (plot.staff[st.key] or 0) + 1
					NPC.spawnStaff(plot, st.key, plot.staff[st.key])
				end
			end
		end
		plot.served = tonumber(saved.served) or 0
	end
	A.refreshPads(plot)
	A.updateSigns(plot)
	A.toast(player, "Welcome to your airport! Step on the gold pads to build it.", "green")
end

------------------------------------------------------------------ buy pads
function A.available(plot, it)
	if plot.bought[it.key] then return false end
	for _, d in ipairs(it.deps) do if not plot.bought[d] then return false end end
	return true
end

function A.refreshPads(plot)
	for _, it in ipairs(CATALOG) do
		local pad = plot.pads[it.key]
		local show = plot.owner ~= nil and A.available(plot, it)
		if show and not pad then
			plot.pads[it.key] = A.makePad(plot, it)
		elseif not show and pad then
			pad:Destroy()
			plot.pads[it.key] = nil
		end
	end
end

function A.makePad(plot, it)
	local y = it.floor == 1 and 1 or 0
	local pad = U.newPart()
	pad.Name = "Buy " .. it.name
	pad.Anchored = true
	pad.Size = Vector3.new(6, 0.4, 6)
	pad.BrickColor = BrickColor.new(it.price == 0 and "Lime green" or "Bright yellow")
	pcall(function() pad.Material = Enum.Material.Neon end)
	pad.CFrame = plot.cf * CFrame.new(it.pad[1], y + 0.25, it.pad[2])
	U.bill(pad, it.name .. "\n" .. (it.price == 0 and "FREE" or U.money(it.price)), 11, 3, 9, Color3.new(1, 1, 1))
	local beam = U.newPart()
	beam.Name = "Beam"
	beam.Anchored = true
	beam.CanCollide = false
	beam.Size = Vector3.new(0.5, 7, 0.5)
	beam.BrickColor = pad.BrickColor
	pcall(function() beam.Material = Enum.Material.Neon end)
	beam.Transparency = 0.5
	beam.CFrame = pad.CFrame * CFrame.new(0, 3.7, 0)
	beam.Parent = pad
	local busy = false
	pad.Touched:connect(function(hit)
		local player = hit.Parent and Players:GetPlayerFromCharacter(hit.Parent)
		if busy or not player then return end
		busy = true
		A.buy(plot, it, player)
		wait(0.6)
		busy = false
	end)
	pad.Parent = plot.Pads
	return pad
end

function A.buy(plot, it, player)
	if plot.owner ~= player then
		A.toast(player, "This is " .. (plot.owner and plot.owner.Name or "nobody") .. "'s airport", "red")
		return
	end
	if not A.available(plot, it) then return end
	local cash = A.cash(player)
	if not cash then return end
	if cash.Value < it.price then
		A.toast(player, "You need " .. U.money(it.price - cash.Value) .. " more for " .. it.name, "red")
		return
	end
	cash.Value = cash.Value - it.price
	A.build(plot, it, false)
	A.refreshPads(plot)
	A.toast(player, "Built: " .. it.name .. "!", "green")
	local n = 0
	for _ in pairs(plot.bought) do n = n + 1 end
	if n == #CATALOG then
		-- the whole airport is done: fireworks and a shout-out to everyone
		plot.fireworks = true
		for _, p in ipairs(Players:GetPlayers()) do
			A.toast(p, player.Name .. " finished the ULTIMATE INTERNATIONAL AIRPORT!", "gold")
		end
	end
end

function A.build(plot, it, quiet)
	if plot.bought[it.key] then return end
	plot.bought[it.key] = true
	if plot.pads[it.key] then plot.pads[it.key]:Destroy() plot.pads[it.key] = nil end
	local cnt = it.eff.cnt
	if cnt then for k, v in pairs(cnt) do plot.cnt[k] = (plot.cnt[k] or 0) + v end end
	local m = Instance.new("Model")
	m.Name = it.name
	local b = { model = m, cf = plot.cf, plot = plot }
	local ok, err = pcall(function() K[it.kind](b, it.at) end)
	if not ok then print("Airport: building " .. it.name .. " failed: " .. tostring(err)) end
	m.Parent = plot.Items
	plot.items[it.key] = m
	if not quiet then A.updateSigns(plot) end
end

function A.updateSigns(plot)
	local name = plot.owner and plot.owner.Name or "?"
	if plot.signLabel then plot.signLabel.Text = string.upper(name) .. "'S AIRPORT" end
end

------------------------------------------------------------------ ratings
function A.cats(plot)
	local c = {}
	for _, k in ipairs(CATS) do c[k] = 0 end
	c.clean = CONST.clean_base
	for key in pairs(plot.bought) do
		local e = ITEM[key] and ITEM[key].eff.cat
		if e then for k, v in pairs(e) do c[k] = c[k] + v end end
	end
	for role, n in pairs(plot.staff) do
		local st = ROLE[role]
		if st then for k, v in pairs(st.cat) do c[k] = c[k] + v * n end end
	end
	for k, v in pairs(c) do c[k] = math.min(1, v) end
	return c
end
function A.stars(plot)
	local c = A.cats(plot)
	local s = 0
	for _, k in ipairs(CATS) do s = s + c[k] end
	return 1 + 4 * s / #CATS, c
end
function A.rating(plot)
	local n = #plot.reviews
	if n == 0 then return (A.stars(plot)) end
	local s, cnt = 0, 0
	for i = math.max(1, n - 29), n do s = s + plot.reviews[i].stars cnt = cnt + 1 end
	return s / cnt
end
function A.mult(plot) return 0.5 + 0.3 * A.rating(plot) end

function A.pay(plot, amount, who)
	if not plot.owner then return end
	local cash = A.cash(plot.owner)
	if not cash then return end
	amount = math.floor(amount * A.mult(plot) * CONST.paxMult + 0.5)
	if amount <= 0 then return end
	cash.Value = cash.Value + amount
	table.insert(plot.earnLog, { t = tick(), a = amount })
	if who and who.Parent then
		local head = who:FindFirstChild("Head")
		if head then
			local l = U.bill(head, "+" .. U.money(amount), 4, 1.2, 2.5, Color3.new(0.4, 1, 0.4))
			Debris:AddItem(l.Parent, 1.4)
		end
	end
end

function A.ticket(plot)
	local t = CONST.baseTicket
	local tm = 1
	for key in pairs(plot.bought) do
		local e = ITEM[key].eff
		t = t + (e.ticket or 0)
		tm = tm * (e.tmult or 1)
	end
	local pilots = plot.staff.pilot or 0
	return t * tm * (1 + 0.1 * pilots)
end

------------------------------------------------------------------ staff
function A.staffCap(plot, st)
	local cap = st.capbase + (st.need and (plot.cnt[st.need] or 0) * st.capper or 0)
	if st.capextra then cap = cap + (plot.cnt[st.capextra[1]] or 0) * st.capextra[2] end
	return cap
end
function A.staffFee(st, n) return math.floor(st.fee * 1.35 ^ n) end

function A.hire(player, key)
	local plot = G.byPlayer[player]
	local st = ROLE[key]
	if not plot or not st then return end
	local n = plot.staff[key] or 0
	local cap = A.staffCap(plot, st)
	if n >= cap then
		A.toast(player, cap == 0 and ("Build what a " .. st.name .. " needs first") or ("No more room for a " .. st.name), "red")
		return
	end
	local fee = A.staffFee(st, n)
	local cash = A.cash(player)
	if not cash or cash.Value < fee then A.toast(player, "You need " .. U.money(fee - (cash and cash.Value or 0)) .. " more to hire a " .. st.name, "red") return end
	cash.Value = cash.Value - fee
	plot.staff[key] = n + 1
	NPC.spawnStaff(plot, key, n + 1)
	A.toast(player, "Hired a " .. st.name .. "!", "green")
end

------------------------------------------------------------------ what the UI shows
local NEED_NAME = { desk = "check-in desks", lane = "security lanes", stall = "food stalls", shop = "shops", gate = "gates",
	bridge = "jet bridges", belt = "a baggage belt", tower = "a control tower", hangar = "a hangar", fire = "a fire station" }
function A.state(player)
	local plot = G.byPlayer[player]
	local list = {}
	for i, p in ipairs(G.plots) do list[i] = p.owner and p.owner.Name or "" end
	local d = { plot = plot and plot.i or 0, plots = list }
	if not plot then return d end
	local stars, cats = A.stars(plot)
	d.rating = A.rating(plot)
	d.stars = stars
	d.nreviews = #plot.reviews
	d.cats = cats
	d.reviews = {}
	for i = #plot.reviews, math.max(1, #plot.reviews - 7), -1 do table.insert(d.reviews, plot.reviews[i]) end
	d.staff = {}
	for _, st in ipairs(STAFF) do
		local n = plot.staff[st.key] or 0
		table.insert(d.staff, { key = st.key, name = st.name, n = n, cap = A.staffCap(plot, st), fee = A.staffFee(st, n),
			desc = st.desc, need = st.need and NEED_NAME[st.need] or "" })
	end
	d.income = plot.incomeRate
	d.served = plot.served
	local bought = 0
	for _ in pairs(plot.bought) do bought = bought + 1 end
	d.bought, d.total = bought, #CATALOG
	d.phases = {}
	for pi, name in ipairs(PHASES) do
		local b, t = 0, 0
		for _, it in ipairs(CATALOG) do if it.phase == pi then t = t + 1 if plot.bought[it.key] then b = b + 1 end end end
		table.insert(d.phases, { name = name, b = b, t = t })
	end
	local avail = {}
	for _, it in ipairs(CATALOG) do if A.available(plot, it) then table.insert(avail, it) end end
	table.sort(avail, function(a, b) return a.price < b.price end)
	d.next = {}
	for i = 1, math.min(5, #avail) do table.insert(d.next, { name = avail[i].name, price = avail[i].price }) end
	d.report = plot.lastReport
	d.ticket = math.floor(A.ticket(plot) * A.mult(plot) * CONST.paxMult)
	return d
end

------------------------------------------------------------------ saving (DataStores may be missing on some servers: the game works without)
pcall(function() G.store = game:GetService("DataStoreService"):GetDataStore("AirportTycoon_v1") end)
function A.load(player)
	G.saved[player] = { loaded = false }
	spawn(function()
		local data
		if G.store then
			local ok, res = pcall(function() return G.store:GetAsync("p" .. tostring(player.userId)) end)
			if ok then data = res end
		end
		local s = type(data) == "table" and data or {}
		s.loaded = true
		G.saved[player] = s
		local cash = A.cash(player)
		if cash and tonumber(s.cash) and tonumber(s.cash) > cash.Value then cash.Value = tonumber(s.cash) end
	end)
end
function A.save(player)
	local s = G.saved[player]
	if not G.store or not s or not s.loaded then return end
	local plot = G.byPlayer[player]
	local cash = A.cash(player)
	local data = { cash = cash and cash.Value or 0, items = s.items, staff = s.staff, served = s.served }
	if plot then
		data.items = {}
		for _, it in ipairs(CATALOG) do if plot.bought[it.key] then table.insert(data.items, it.key) end end
		data.staff = {}
		for k, n in pairs(plot.staff) do data.staff[k] = n end
		data.served = plot.served
	end
	spawn(function() pcall(function() G.store:SetAsync("p" .. tostring(player.userId), data) end) end)
end

-- ==== s40_npc.lua
------------------------------------------------------------------ walking people
-- route = list of { p = feet position (world), wait = seconds, act = function(walker) }
function NPC.walk(plot, model, root, route, speed, onDone)
	local w = { plot = plot, model = model, root = root, route = route, i = 1, pos = route[1].p, wt = 0,
		speed = speed or CONST.walkSpeed, onDone = onDone, dir = Vector3.new(0, 0, -1) }
	table.insert(G.walkers, w)
	return w
end

function NPC.step(dt)
	local now = tick()
	for i = #G.walkers, 1, -1 do
		local w = G.walkers[i]
		local done = false
		if not w.model.Parent then
			done = true
		elseif w.wt > 0 then
			w.wt = w.wt - dt
		else
			local target = w.route[w.i]
			if not target then
				done = true
			else
				local d = target.p - w.pos
				local dist = d.magnitude
				local step = w.speed * dt
				if dist <= step then
					w.pos = target.p
					if dist > 0.05 then w.dir = d.unit end
					w.wt = target.wait or 0
					w.i = w.i + 1
					if target.act then
						local ok, err = pcall(target.act, w)
						if not ok then print("Airport: walker action failed: " .. tostring(err)) end
					end
				else
					w.dir = d.unit
					w.pos = w.pos + w.dir * step
				end
			end
		end
		if done then
			table.remove(G.walkers, i)
			if w.onDone then pcall(w.onDone, w) end
			pcall(function() w.model:Destroy() end)
		elseif w.model.Parent then
			local flat = Vector3.new(w.dir.x, 0, w.dir.z)
			if flat.magnitude < 0.01 then flat = Vector3.new(0, 0, -1) end
			local bob = w.wt > 0 and 0 or math.abs(math.sin(now * 9 + i)) * 0.25
			local p = w.pos + Vector3.new(0, 3 + bob, 0)
			w.root.CFrame = CFrame.new(p, p + flat)
		end
	end
end

------------------------------------------------------------------ reviews
local NAMES = { "Sarah", "Tom", "Aisha", "Leo", "Mia", "Carlos", "Yuki", "Noah", "Emma", "Omar", "Lily", "Jack", "Priya",
	"Lucas", "Zoe", "Ivan", "Chloe", "Mateo", "Ava", "Ben", "Grace", "Sam", "Nina", "Kai" }
local GOOD = {
	checkin = { "Check-in was super quick!", "The check-in staff were so nice.", "Checked in in no time!" },
	security = { "Security was smooth and friendly.", "Fastest security line ever!", "I felt really safe here." },
	food = { "The food court was amazing!", "Best sushi I've had at an airport!", "Loved the burgers and ice cream." },
	shopping = { "Great shops, I bought so much!", "Duty free had everything!", "Awesome souvenirs!" },
	comfort = { "So comfy, I loved the lounges.", "The spa was so relaxing.", "Beautiful terminal, so many seats!" },
	clean = { "Spotless airport!", "Everything was so clean.", "The restrooms were sparkling!" },
	gates = { "My flight left right on time!", "Boarding was super easy.", "Smooth takeoff, great airport!" } }
local BAD = {
	checkin = { "The check-in line took forever.", "Not enough check-in desks!", "Waited ages to drop my bag." },
	security = { "Security was a nightmare.", "Only one security lane?!", "The security line was huge." },
	food = { "I was starving, no good food.", "Where is the food court?", "Nothing to eat here..." },
	shopping = { "Nothing to buy here...", "No shops at all!", "I wanted souvenirs but there were none." },
	comfort = { "Nowhere nice to sit!", "So boring, nothing to do.", "My feet hurt, no seats anywhere." },
	clean = { "It was so dirty...", "The bins were overflowing!", "Hire some janitors please!" },
	gates = { "My flight was delayed!", "The gate was so far and crowded.", "Where are the planes?!" } }
-- a random category among the strongest (best) and among the weakest (worst)
local function bestWorst(cats)
	local hi, lo = -1, 2
	for _, k in ipairs(CATS) do hi = math.max(hi, cats[k]) lo = math.min(lo, cats[k]) end
	local tops, bots = {}, {}
	for _, k in ipairs(CATS) do
		if cats[k] >= hi - 0.1 then table.insert(tops, k) end
		if cats[k] <= lo + 0.1 then table.insert(bots, k) end
	end
	return U.pick(tops), U.pick(bots)
end

function NPC.review(plot, flew)
	local stars, cats = A.stars(plot)
	local s = stars + (math.random() - 0.5) * 1.5 - (flew and 0 or 0.8)
	s = U.clamp(math.floor(s + 0.5), 1, 5)
	local best, worst = bestWorst(cats)
	local good, bad = U.pick(GOOD[best]), U.pick(BAD[worst])
	local text
	if s >= 4 then text = good
	elseif s <= 2 then text = bad
	else text = good .. " But " .. bad:sub(1, 1):lower() .. bad:sub(2) end
	if not flew then text = "There were no flights! " .. text end
	local r = { name = U.pick(NAMES), stars = s, text = text }
	table.insert(plot.reviews, r)
	while #plot.reviews > 40 do table.remove(plot.reviews, 1) end
	plot.served = plot.served + 1
	if plot.owner then pcall(function() G.remote:FireClient(plot.owner, "review", r) end) end
end

------------------------------------------------------------------ passengers
local F = 1
function NPC.passenger(plot)
	local inv = plot.cf:inverse()
	local function W(x, y, z) return plot.cf * Vector3.new(x, y, z) end
	local function loc(v) return inv * v end
	local route = {}
	local cur
	local function go(v, wait, act) table.insert(route, { p = v, wait = wait, act = act }) cur = loc(v) end
	local aisle = (math.random() < 0.5 and -12 or 12) + math.random(-2, 2)
	-- walk along the central aisle, then across to the target (keeps people out of the rooms)
	local function moveTo(v, wait, act)
		local l = loc(v)
		if cur and cur.z > 58 and math.abs(l.z - cur.z) > 6 then
			go(W(aisle, F, cur.z))
			go(W(aisle, F, l.z))
		end
		go(v, wait, act)
	end
	local pts = plot.pts
	local look = M.passengerLook()
	-- where they come from
	local start = W(math.random(-40, 40), 0.5, 50)
	if pts.arrive and #pts.arrive > 0 and math.random() < 0.7 then start = U.pick(pts.arrive).p end
	go(start)
	-- walk outside the terminal to the sidewalk first (straight lines from the car park cut through the walls)
	if cur.z > 54 or cur.z < 40 then go(W(cur.x, 0.5, 51)) end
	go(W(math.random(-6, 6), 0.5, 52))
	go(W(math.random(-4, 4), F, 64))
	local flew = false
	local mult = 1
	-- check-in
	if pts.desk and #pts.desk > 0 then
		local d = U.pick(pts.desk)
		local agents = plot.staff.agent or 0
		local desks = math.max(1, plot.cnt.desk or 1)
		local wait = d.kiosk and 1.5 or (3 / (1 + agents / desks) - 0.1 * (plot.staff.handler or 0))
		moveTo(d.q, math.max(0.8, wait), function(w) A.pay(plot, CONST.checkinFee, w.model) end)
	end
	-- security
	if pts.lane and #pts.lane > 0 then
		local l = U.pick(pts.lane)
		moveTo(l.a)
		local officers = plot.staff.officer or 0
		go(l.b, math.max(0.6, 2.4 - 0.25 * officers))
		go(l.c)
	else
		-- no lanes yet: through the opening in the middle of the security wall
		moveTo(W(aisle, F, 120))
		go(W(0, F, 122)) go(W(0, F, 131)) go(W(aisle, F, 150))
	end
	go(W(aisle, F, 166))
	-- food, shops, seats
	if pts.stall and #pts.stall > 0 and math.random() < 0.6 then
		local s = U.pick(pts.stall)
		moveTo(s.p, 3, function(w) A.pay(plot, s.spend * (1 + 0.1 * (plot.staff.chef or 0)), w.model) end)
	end
	if pts.shop and #pts.shop > 0 and math.random() < 0.5 then
		local s = U.pick(pts.shop)
		moveTo(s.p, 3, function(w) A.pay(plot, s.spend * (1 + 0.1 * (plot.staff.clerk or 0)), w.model) end)
	end
	if pts.seat and #pts.seat > 0 and math.random() < 0.35 then
		moveTo(U.pick(pts.seat).p, 4)
	end
	-- board a flight
	if pts.gate and #pts.gate > 0 then
		local g = U.pick(pts.gate)
		moveTo(g.p, 2)
		go(g.door)
		local bridge
		for _, br in ipairs(pts.bridge or {}) do if br.n == g.n then bridge = br end end
		local function board(w) flew = true A.pay(plot, A.ticket(plot), w.model) end
		if bridge then go(bridge.e, 0.2, board) else route[#route].act = board end
	else
		moveTo(W(aisle, F, 250), 2)
		moveTo(W(aisle, F, 134))
		go(W(0, F, 131)) go(W(0, F, 122)) go(W(aisle, F, 116))
		moveTo(W(0, F, 64))
		go(W(0, 0.5, 50))
	end
	local feet = route[1].p
	local model, root = M.person(plot.People, CFrame.new(feet), look, "Passenger")
	U.rig(model, root, false)
	NPC.walk(plot, model, root, route, CONST.walkSpeed + math.random() * 2, function() NPC.review(plot, flew) end)
end

------------------------------------------------------------------ the airport inspector: walks everything, gives an official rating and a bonus
function NPC.inspector(plot)
	local route = {}
	local function W(x, y, z) return plot.cf * Vector3.new(x, y, z) end
	local function go(v, wait) table.insert(route, { p = v, wait = wait }) end
	go(W(0, 0.5, 46))
	go(W(0, F, 64), 1)
	local pts = plot.pts
	for _, kind in ipairs({ "desk", "lane", "stall", "shop", "gate" }) do
		local p = pts[kind] and pts[kind][1]
		if p then
			local v = p.q or p.a or p.p
			local l = plot.cf:inverse() * v
			go(W(0, F, l.z))
			go(v, 2.5)
			go(W(0, F, l.z))
		end
	end
	go(W(0, F, 64))
	go(W(0, 0.5, 46))
	local model, root = M.person(plot.People, CFrame.new(route[1].p), { shirt = "Really black", pants = "Really black", skin = "Nougat",
		tie = "Gold", clipboard = true, hat = "cap", hatColor = "Gold" }, "Inspector")
	local head = model:FindFirstChild("Head")
	if head then U.bill(head, "AIRPORT INSPECTOR", 7, 1.4, 2.5, Color3.new(1, 0.85, 0.2)) end
	U.rig(model, root, false)
	NPC.walk(plot, model, root, route, 7, function()
		if not plot.owner then return end
		local stars, cats = A.stars(plot)
		local best, worst = bestWorst(cats)
		local bonus = math.floor(150 * stars ^ 3 + 10 * (plot.incomeRate or 0) * stars)
		local cash = A.cash(plot.owner)
		if cash then cash.Value = cash.Value + bonus end
		plot.lastReport = { stars = math.floor(stars * 10 + 0.5) / 10, best = CATNAME[best], worst = CATNAME[worst], bonus = bonus }
		pcall(function() G.remote:FireClient(plot.owner, "inspector", plot.lastReport) end)
	end)
	if plot.owner then A.toast(plot.owner, "The Airport Inspector has arrived! Make your airport shine!", "gold") end
end

------------------------------------------------------------------ staff (they stand at their station)
local LOOKS = {
	agent = { shirt = "Bright blue", pants = "Navy blue", tie = "Bright red" },
	officer = { shirt = "Really black", pants = "Navy blue", hat = "cap", hatColor = "Really black" },
	chef = { shirt = "Institutional white", pants = "Really black", hat = "chef" },
	clerk = { shirt = "Bright green", pants = "Really black" },
	janitor = { shirt = "Bright orange", pants = "Navy blue", hat = "cap", hatColor = "Bright orange", mop = true },
	gateagent = { shirt = "Navy blue", pants = "Navy blue", tie = "Gold" },
	pilot = { shirt = "Institutional white", pants = "Really black", hat = "cap", hatColor = "Navy blue", tie = "Really black" },
	handler = { shirt = "Bright yellow", pants = "Navy blue", hat = "helmet", hatColor = "Bright orange" },
	atc = { shirt = "Sand blue", pants = "Really black", hat = "cap", hatColor = "Sand blue" },
	mechanic = { shirt = "Dark stone grey", pants = "Dark stone grey", hat = "helmet", hatColor = "Bright yellow" },
	firefighter = { shirt = "Bright red", pants = "Really black", hat = "helmet", hatColor = "Bright yellow" },
}
function NPC.spawnStaff(plot, role, index)
	local spots = plot.spots[role] or {}
	local cf = spots[index] or (plot.cf * U.L(-30 + index * 3, F, 70, 0))
	local look = {}
	for k, v in pairs(LOOKS[role] or {}) do look[k] = v end
	local st = ROLE[role]
	local m = M.person(plot.Staff, cf, look, st and st.name or role)
	local head = m:FindFirstChild("Head")
	if head and st then U.bill(head, st.name, 6, 1.1, 2.2, Color3.new(0.8, 0.9, 1)) end
end

-- ==== s50_planes.lua
------------------------------------------------------------------ paths for NPC planes
-- points = list of { p = Vector3, v = speed (studs/s), back = true while being pushed backwards }
function FLY.path(points, loop)
	local P = { pts = points, t = { 0 }, loop = loop }
	for i = 2, #points do
		local d = (points[i].p - points[i - 1].p).magnitude
		P.t[i] = P.t[i - 1] + d / math.max(1, (points[i].v + points[i - 1].v) / 2)
	end
	P.total = P.t[#points]
	if loop then
		local d = (points[1].p - points[#points].p).magnitude
		P.total = P.total + d / math.max(1, (points[1].v + points[#points].v) / 2)
	end
	return P
end
function FLY.at(P, t)
	if P.loop then t = t % P.total else t = U.clamp(t, 0, P.total) end
	local n = #P.pts
	for i = 1, n do
		local t1 = (i < n) and P.t[i + 1] or P.total
		if t <= t1 or i == n then
			local a = P.pts[i]
			local b = (i < n) and P.pts[i + 1] or (P.loop and P.pts[1] or P.pts[n])
			local span = t1 - P.t[i]
			local f = span > 0 and (t - P.t[i]) / span or 1
			return a.p + (b.p - a.p) * U.clamp(f, 0, 1), a.back
		end
	end
	return P.pts[n].p, false
end
-- round the corners of a path so planes turn smoothly
function FLY.round(points, r)
	local out = { points[1] }
	for i = 2, #points - 1 do
		local a, b, c = points[i - 1], points[i], points[i + 1]
		local d1, d2 = (b.p - a.p), (c.p - b.p)
		if d1.magnitude > 2 * r and d2.magnitude > 2 * r and (d1.unit - d2.unit).magnitude > 0.05 then
			local p0, p2 = b.p - d1.unit * r, b.p + d2.unit * r
			for k = 0, 4 do
				local t = k / 4
				local q = p0 * (1 - t) * (1 - t) + b.p * 2 * (1 - t) * t + p2 * t * t
				table.insert(out, { p = q, v = b.v, back = b.back })
			end
		else
			table.insert(out, b)
		end
	end
	table.insert(out, points[#points])
	return out
end
-- move a plane along a path with a smoothly turning nose
function FLY.place(pl, P, t, dt)
	local p, back = FLY.at(P, t)
	local ahead = FLY.at(P, t + 0.6)
	local behind = FLY.at(P, t - 0.6)
	local dir = ahead - behind
	if dir.magnitude < 0.05 then dir = pl.look or Vector3.new(0, 0, -1) end
	if back then dir = -dir end
	dir = dir.unit
	local old = pl.look or dir
	local a = math.min(1, (dt or 0.05) * 2.5)
	local new = old * (1 - a) + dir * a
	if new.magnitude < 0.05 then new = dir end
	pl.look = new.unit
	-- bank into turns
	local turn = old:Cross(pl.look).y
	pl.bank = (pl.bank or 0) * 0.9 + U.clamp(-turn * 40, -0.6, 0.6) * 0.1
	local cf = CFrame.new(p, p + pl.look) * CFrame.Angles(0, 0, pl.bank)
	pl.root.CFrame = cf
end

------------------------------------------------------------------ planes flying around the whole map
local H = 7.3   -- airliner centre above the ground when it's on its wheels
local function pt(x, y, z, v) return { p = Vector3.new(x, y, z), v = v } end
function FLY.initGlobal()
	local sky = Instance.new("Model")
	sky.Name = "SkyTraffic"
	sky.Parent = workspace
	G.global = {}
	-- touch-and-go on the big runway in the middle of the map, then a big loop to the north
	local loopA = FLY.path(FLY.round({
		pt(-2600, 260, 0, 115), pt(-1400, 70, 0, 100), pt(-1050, H + 0.3, 0, 85), pt(0, H + 0.3, 0, 75), pt(650, H + 0.3, 0, 85),
		pt(1100, 50, 0, 100), pt(1900, 240, 0, 115), pt(2600, 330, 400, 120), pt(2850, 350, 1200, 120), pt(2400, 350, 2000, 120),
		pt(1500, 350, 2300, 120), pt(-1500, 350, 2300, 120), pt(-2400, 340, 2000, 120), pt(-2850, 320, 1200, 120),
		pt(-2900, 290, 400, 115) }, 180), true)
	-- a high loop over the south
	local loopB = FLY.path(FLY.round({
		pt(2900, 480, -300, 130), pt(-2900, 480, -300, 130), pt(-3200, 480, -1300, 130), pt(-2500, 480, -2300, 130),
		pt(2500, 480, -2300, 130), pt(3200, 480, -1300, 130) }, 260), true)
	-- small planes around the edge of the map
	local loopC = FLY.path(FLY.round({
		pt(-1900, 200, -1400, 70), pt(1900, 220, -1400, 70), pt(1900, 240, 1400, 70), pt(-1900, 220, 1400, 70) }, 250), true)
	local tails = { "Bright red", "Bright blue", "Bright green", "Royal purple", "Bright orange" }
	for i = 1, 3 do
		local m, root = M.airliner(sky, CFrame.new(0, 3000, 0), tails[i], "Airliner")
		table.insert(G.global, { root = root, path = loopA, off = (i - 1) * loopA.total / 3 })
	end
	for i = 1, 2 do
		local m, root = M.airliner(sky, CFrame.new(0, 3000, 0), tails[3 + i], "Airliner")
		table.insert(G.global, { root = root, path = loopB, off = (i - 1) * loopB.total / 2 })
	end
	-- airliners parked at the hub terminal next to the plaza
	for i, x in ipairs({ -380, -300, -220 }) do M.airliner(sky, CFrame.new(x, 7.6, -112), tails[i + 1], "Parked Airliner") end
	for i = 1, 2 do
		local m, body, seat, gyro, vel = M.flyable(sky, "small", CFrame.new(0, 3000, 0), i == 1 and "Bright yellow" or "Bright red")
		seat:Destroy() gyro:Destroy() vel:Destroy()
		for _, p in ipairs(m:GetChildren()) do if p:IsA("BasePart") then p.CanCollide = false end end
		body.Anchored = true
		table.insert(G.global, { root = body, path = loopC, off = (i - 1) * loopC.total / 2 })
	end
end

------------------------------------------------------------------ airliners at your gates: board, push back, taxi, take off, come back, land
function A.gatePlane(plot, n, x)
	if plot.gatePlanes[n] then return end
	local park = plot.cf * U.L(x, H, 388)
	local m, root = M.airliner(plot.Planes, park, plot.color, "Flight " .. plot.i .. "0" .. n)
	plot.gatePlanes[n] = { plot = plot, n = n, x = x, model = m, root = root, state = "parked", t0 = tick(), park = park, look = park.lookVector }
end
function A.startDepartures(plot)
	for _, gp in pairs(plot.gatePlanes) do gp.t0 = tick() - math.random(0, 20) end
end
local function localPath(plot, list)
	local out = {}
	for _, q in ipairs(list) do table.insert(out, { p = plot.cf * Vector3.new(q[1], q[2], q[3]), v = q[4], back = q[5] }) end
	return FLY.path(FLY.round(out, 10), false)
end
function FLY.departure(plot, x)
	return localPath(plot, {
		{ x, H, 388, 4, true }, { x, H, 425, 4, true }, { x + 6, H, 442, 4, true }, { x - 10, H, 460, 10 }, { -185, H, 460, 14 },
		{ -192, H, 490, 12 }, { -186, H, 525, 12 }, { -150, H, 525, 25 }, { -40, H, 525, 55 }, { 110, H, 525, 85 },
		{ 230, 40, 525, 95 }, { 600, 170, 525, 110 }, { 1200, 320, 525, 120 } })
end
function FLY.arrival(plot, x)
	return localPath(plot, {
		{ -1300, 320, 525, 120 }, { -600, 150, 525, 105 }, { -215, H + 0.3, 525, 90 }, { -60, H, 525, 65 }, { 110, H, 525, 30 },
		{ 182, H, 525, 14 }, { 190, H, 490, 10 }, { 185, H, 460, 10 }, { x + 14, H, 460, 8 }, { x, H, 440, 6 }, { x, H, 388, 4 } })
end
function FLY.gateStep(gp, dt)
	local plot, now = gp.plot, tick()
	if not gp.model.Parent then return end
	if gp.state == "parked" then
		gp.root.CFrame = gp.park
		gp.look = gp.park.lookVector
		local pilots, atc = plot.staff.pilot or 0, plot.staff.atc or 0
		local wait = math.max(18, 50 - 6 * pilots - 4 * atc)
		if plot.hasRunway and now - gp.t0 > wait then
			gp.state, gp.t0, gp.path = "departing", now, FLY.departure(plot, gp.x)
		end
	elseif gp.state == "departing" or gp.state == "arriving" then
		local t = now - gp.t0
		FLY.place(gp, gp.path, t, dt)
		if t >= gp.path.total then
			if gp.state == "departing" then
				gp.state, gp.t0 = "away", now
				gp.root.CFrame = CFrame.new(plot.cf.p + Vector3.new(0, 5000, 0))
			else
				gp.state, gp.t0 = "parked", now
			end
		end
	elseif gp.state == "away" then
		if now - gp.t0 > 12 then
			gp.state, gp.t0, gp.path = "arriving", now, FLY.arrival(plot, gp.x)
			gp.look = nil
		end
	end
end

------------------------------------------------------------------ planes you can fly
function A.flyPad(plot, pad, kind)
	local busy = false
	pad.Touched:connect(function(hit)
		local player = hit.Parent and Players:GetPlayerFromCharacter(hit.Parent)
		if busy or not player then return end
		if player ~= plot.owner then A.toast(player, "Only the owner can fly these planes", "red") return end
		busy = true
		FLY.spawn(plot, kind, player)
		wait(3)
		busy = false
	end)
end

function FLY.spawn(plot, kind, player)
	local old = G.flyers[player]
	if old then pcall(function() old.model:Destroy() end) G.flyers[player] = nil end
	local T = FLY.TYPES[kind]
	local cf = plot.cf * U.L(-178, T.lift + 0.4, 525, -90)
	local m, body, seat, gyro, vel = M.flyable(plot.Planes, kind, cf, plot.color, player)
	local look = cf.lookVector
	G.flyers[player] = { player = player, plot = plot, kind = kind, model = m, body = body, seat = seat, gyro = gyro, vel = vel,
		speed = 0, yaw = math.atan2(-look.x, -look.z), pitch = 0, bank = 0 }
	-- put the pilot on the seat
	local char = player.Character
	local torso = char and (char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart"))
	if torso then torso.CFrame = seat.CFrame + Vector3.new(0, 3, 0) end
	A.toast(player, "W/S = speed, A/D = turn, E = up, Q = down. Space to jump out.", "cyan")
end

function FLY.step(dt)
	for player, f in pairs(G.flyers) do
		if not f.model.Parent or not f.body.Parent then
			G.flyers[player] = nil
		else
			local T = FLY.TYPES[f.kind]
			local weld = f.seat and f.seat:FindFirstChild("SeatWeld")
			local driving = weld and weld.Part1 and weld.Part1.Parent == player.Character
			local thr, steer = 0, 0
			if driving then
				thr, steer = f.seat.Throttle, f.seat.Steer
				local c = G.ctl[player]
				if c then
					if c.t and c.t ~= 0 then thr = c.t end
					if c.s and c.s ~= 0 then steer = c.s end
				end
			end
			local max = T.max * (1 + 0.15 * (f.plot.staff.mechanic or 0))
			if driving then
				f.speed = f.speed + thr * T.accel * dt
				if thr == 0 then f.speed = f.speed - 2 * dt end
			else
				f.speed = f.speed - 30 * dt
			end
			f.speed = U.clamp(f.speed, 0, max)
			local air = f.speed >= T.takeoff
			f.yaw = f.yaw - steer * math.rad(T.turn) * dt * (air and 1 or 0.7)
			local pin = driving and (G.pitch[player] or 0) or 0
			local target = air and pin * math.rad(28) or 0
			f.pitch = f.pitch + (target - f.pitch) * math.min(1, dt * 3)
			f.bank = f.bank + ((air and -steer * math.rad(30) or 0) - f.bank) * math.min(1, dt * 3)
			local rot = CFrame.Angles(0, f.yaw, 0) * CFrame.Angles(f.pitch, 0, 0) * CFrame.Angles(0, 0, f.bank)
			f.gyro.cframe = rot
			local look = rot.lookVector
			if air then
				local v = look * f.speed
				if f.body.Position.y > 1500 and v.y > 0 then v = Vector3.new(v.x, 0, v.z) end
				f.vel.maxForce = Vector3.new(4e6, 4e6, 4e6)
				f.vel.velocity = v
			else
				local flat = Vector3.new(look.x, 0, look.z)
				if flat.magnitude < 0.01 then flat = Vector3.new(0, 0, -1) end
				f.vel.maxForce = Vector3.new(4e6, 0, 4e6)
				f.vel.velocity = flat.unit * f.speed
			end
			f.air = air
			if f.body.Position.y < -100 then pcall(function() f.model:Destroy() end) end
		end
	end
end

-- ==== s60_main.lua
------------------------------------------------------------------ start
A.init()
FLY.initGlobal()
-- text on the plaza's welcome board and the hub
pcall(function()
	local board = MAP.Plaza:FindFirstChild("WelcomeBoard")
	if board then
		U.text(board, "WELCOME TO AIRPORT TYCOON\nPress AIRPORTS to claim your own airport!", Color3.new(1, 0.85, 0.3), Color3.new(0.03, 0.08, 0.25), "Front")
		U.text(board, "10 AIRPORTS - 104 THINGS TO BUILD - FLY YOUR OWN PLANE", Color3.new(1, 1, 1), Color3.new(0.03, 0.08, 0.25), "Back")
	end
	local hs = MAP.Hub:FindFirstChild("HubSign")
	if hs then U.text(hs, "INTERNATIONAL HUB", Color3.new(1, 1, 1), Color3.new(0.03, 0.08, 0.25), "Back") U.text(hs, "INTERNATIONAL HUB", Color3.new(1, 1, 1), Color3.new(0.03, 0.08, 0.25), "Front") end
end)
_G.AirportDebug = { G = G, A = A, FLY = FLY, NPC = NPC, CATALOG = CATALOG, STAFF = STAFF }   -- for the test harness

local function teleport(player, cf)
	local char = player.Character
	local torso = char and (char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart"))
	if torso then torso.CFrame = cf end
end
local function home(plot) return plot.cf * CFrame.new(0, 4, 14) end

------------------------------------------------------------------ players
local function setup(player)
	if player:FindFirstChild("leaderstats") then return end
	local ls = Instance.new("IntValue")
	ls.Name = "leaderstats"
	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = CONST.startCash
	cash.Parent = ls
	local rating = Instance.new("StringValue")
	rating.Name = "Rating"
	rating.Value = "-"
	rating.Parent = ls
	ls.Parent = player
	A.load(player)
	player.CharacterAdded:connect(function(char)
		local plot = G.byPlayer[player]
		if plot then
			char:WaitForChild("Torso")
			wait(0.3)
			teleport(player, home(plot))
		end
	end)
end
Players.PlayerAdded:connect(setup)
for _, p in ipairs(Players:GetPlayers()) do setup(p) end

Players.PlayerRemoving:connect(function(player)
	A.save(player)
	local f = G.flyers[player]
	if f then pcall(function() f.model:Destroy() end) G.flyers[player] = nil end
	local plot = G.byPlayer[player]
	G.byPlayer[player] = nil
	if plot then
		for i = #G.walkers, 1, -1 do if G.walkers[i].plot == plot then pcall(function() G.walkers[i].model:Destroy() end) table.remove(G.walkers, i) end end
		A.reset(plot)
	end
	G.saved[player], G.pitch[player], G.ctl[player] = nil, nil, nil
end)
pcall(function()
	game:BindToClose(function()
		for _, p in ipairs(Players:GetPlayers()) do A.save(p) end
		wait(2)
	end)
end)

------------------------------------------------------------------ what the UI asks for
G.remote.OnServerEvent:connect(function(player, what, a, b)
	if what == "hire" then
		A.hire(player, a)
	elseif what == "pitch" then
		G.pitch[player] = U.clamp(tonumber(a) or 0, -1, 1)
	elseif what == "ctl" then
		G.ctl[player] = { t = U.clamp(tonumber(a) or 0, -1, 1), s = U.clamp(tonumber(b) or 0, -1, 1) }
	elseif what == "tp" then
		local plot = G.byPlayer[player]
		if plot then teleport(player, home(plot)) else A.toast(player, "Pick an airport to claim first!", "gold") end
	elseif what == "visit" then
		local plot = G.plots[tonumber(a) or 0]
		if plot then teleport(player, home(plot)) end
	elseif what == "plaza" then
		local sp = MAP:FindFirstChild("Spawn")
		if sp then teleport(player, sp.CFrame + Vector3.new(0, 4, 0)) end
	elseif what == "state" then
		pcall(function() G.remote:FireClient(player, "state", A.state(player)) end)
	end
end)

------------------------------------------------------------------ fast loop: walkers, NPC planes, flying
spawn(function()
	local last = tick()
	while true do
		wait()
		local now = tick()
		local dt = math.min(0.2, now - last)
		last = now
		NPC.step(dt)
		FLY.step(dt)
		for _, g in ipairs(G.global) do FLY.place(g, g.path, now + g.off, dt) end
		for _, plot in ipairs(G.plots) do
			for _, gp in pairs(plot.gatePlanes) do FLY.gateStep(gp, dt) end
		end
	end
end)

-- spinning things (radar, rotors)
spawn(function()
	local start = tick()
	while true do
		wait(0.1)
		local t = tick() - start
		for i = #G.spinners, 1, -1 do
			local s = G.spinners[i]
			if not s.parts[1].Parent then
				table.remove(G.spinners, i)
			else
				local a = math.rad(s.speed * t)
				local r = s.axis == "y" and CFrame.Angles(0, a, 0) or CFrame.Angles(0, 0, a)
				for k, p in ipairs(s.parts) do p.CFrame = s.center * r * s.rel[k] end
			end
		end
	end
end)

------------------------------------------------------------------ every second: income, passengers, inspector, UI
local screenLines = 0
spawn(function()
	while true do
		wait(1)
		screenLines = screenLines + 1
		local now = tick()
		for _, plot in ipairs(G.plots) do
			local owner = plot.owner
			if owner then
				-- passive income
				local inc = 0
				for key in pairs(plot.bought) do inc = inc + (ITEM[key].eff.inc or 0) end
				local cash = A.cash(owner)
				if cash and inc > 0 then cash.Value = cash.Value + inc end
				-- money per second over the last 30 seconds
				local sum = 0
				for i = #plot.earnLog, 1, -1 do
					if now - plot.earnLog[i].t > 30 then table.remove(plot.earnLog, i) else sum = sum + plot.earnLog[i].a end
				end
				plot.incomeRate = math.floor(inc + sum / 30)
				-- passengers
				if plot.bought.foundation then
					local c = plot.cnt
					local interval = math.max(2.5, 16 / (1 + 0.3 * (c.transport or 0) + 0.15 * (c.desk or 0) + 0.25 * (c.gate or 0)))
					local cap = math.min(16, 3 + (c.desk or 0) + 2 * (c.gate or 0))
					plot.spawnT = plot.spawnT - 1
					if plot.spawnT <= 0 and #plot.People:GetChildren() < cap then
						plot.spawnT = interval * (0.8 + math.random() * 0.4)
						local ok, err = pcall(NPC.passenger, plot)
						if not ok then print("Airport: passenger failed: " .. tostring(err)) end
					end
					if now > plot.nextInspect then
						plot.nextInspect = now + 300
						pcall(NPC.inspector, plot)
					end
				end
				-- leaderboard + the big screen
				local ls = owner:FindFirstChild("leaderstats")
				if ls and ls:FindFirstChild("Rating") then
					ls.Rating.Value = #plot.reviews > 0 and string.format("%.1f", A.rating(plot)) or "-"
				end
				if plot.screenLabel and screenLines % 5 == 0 then
					local lines = { "WELCOME TO " .. string.upper(owner.Name) .. "'S AIRPORT",
						"RATING " .. string.format("%.1f", A.rating(plot)) .. " / 5", plot.served .. " HAPPY PASSENGERS", "HAVE A NICE FLIGHT!" }
					plot.screenLabel.Text = lines[(math.floor(screenLines / 5) % #lines) + 1]
				end
				if plot.fireworks and screenLines % 20 == 0 then
					for k = 1, 5 do
						local p = U.newPart()
						p.Anchored = true
						p.CanCollide = false
						p.Size = Vector3.new(2, 2, 2)
						p.Shape = Enum.PartType.Ball
						p.BrickColor = BrickColor.new(U.pick({ "Bright red", "Lime green", "Cyan", "Hot pink", "New Yeller" }))
						pcall(function() p.Material = Enum.Material.Neon end)
						p.CFrame = plot.cf * CFrame.new(math.random(-120, 120), 60 + math.random(0, 40), math.random(80, 300))
						U.fx(p, "Sparkles")
						U.light(p, p.BrickColor.Color, 40, 3)
						p.Parent = plot.Items
						Debris:AddItem(p, 2.5)
					end
				end
			end
		end
		for _, p in ipairs(Players:GetPlayers()) do
			pcall(function() G.remote:FireClient(p, "state", A.state(p)) end)
		end
	end
end)

spawn(function()
	while true do
		wait(120)
		for _, p in ipairs(Players:GetPlayers()) do A.save(p) end
	end
end)

print("AirportServer ready: " .. #G.plots .. " airports, " .. #CATALOG .. " things to buy, " .. #STAFF .. " jobs")
