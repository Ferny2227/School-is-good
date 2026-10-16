# Airport Tycoon (made for 2016 Roblox engines)

`AirportTycoon.rbxl` is the game. Open it in Studio and press Play, or upload it to the revival.

## The map
- **10 airports** to claim, in two rows of 5, spread far apart (280 studs between plots, each plot 420 x 620).
- A huge **international runway** down the middle with markings, edge lights and a taxiway. NPC airliners
  do touch-and-goes on it and fly big loops around the whole map; small planes circle the edge.
- A spawn plaza with a fountain and welcome board, a big control tower, a hub terminal, two boulevards with
  street lamps, hundreds of trees, beaches and ocean around the island.

## Your airport: 104 things to buy, about an hour to finish
Step on the green **CLAIM** pad of a free airport, then on the gold pads. New pads appear as you build.
1. **Arrival:** entrance road, sidewalk, airport sign, parking lot, taxi stand, bus stop, terminal floor,
   walls, sliding doors, lights, info desk, benches, flags, bins, billboards.
2. **Check-in:** 6 check-in desks, kiosks, baggage belt, queue barriers, luggage carts, departures board, ATMs.
3. **Security:** the checkpoint, 4 security lanes (x-ray + metal detector), 2 body scanners, K9 unit,
   security office, CCTV.
4. **Gates & planes:** 4 gates, apron, 4 jet bridges, taxiway, runway, runway lights, control tower,
   radar, windsock, helipad, ground vehicles, fuel depot, fire station, cargo terminal, hangar, and
   **3 planes you can fly**: Small Plane, Fighter Jet, Private Jet.
5. **Food court:** burger joint, pizza, coffee, sushi, tacos, ice cream, tables, vending machines.
6. **Shops & comfort:** souvenirs, books, pharmacy, duty free, tech store, fashion, waiting seats,
   restrooms, plants, chargers, arcade, kids play area, VIP lounge, spa, aquarium, fountain, glass roof,
   chandeliers, giant screen, golden plane statue.
7. **Business:** car rental, parking garage, airport hotel, train station.
8. **Mega airport:** International Status (2x tickets), fireworks show, airport mascot, Golden Terminal.

## Passengers, ratings, staff
- **Passengers** arrive by car, taxi, bus or train, check in, go through security, eat, shop, sit, then board
  a plane through a jet bridge. They pay at check-in, the food court, shops and when they fly.
- Each passenger leaves a **review** (1-5 stars) based on 7 things: Check-in, Security, Food, Shopping,
  Comfort, Cleanliness, Flights. A thing only counts once your airport has it (check-in after the first desk,
  security after the checkpoint, flights after Gate 1, food after the Food Court, shopping after the first shop),
  so a new airport isn't stuck at 1 star. Your rating multiplies your money (1 star = 0.8x, 5 stars = 2x).
- The **Airport Inspector** visits every 5 minutes, walks through everything and pays a bonus.
- **Hire staff** (HIRE STAFF button): check-in agents, security officers, chefs, shop clerks, janitors,
  gate agents, pilots, baggage handlers, air traffic controllers, mechanics, firefighters. They stand at
  their stations and raise your ratings (pilots and controllers mean more flights, mechanics make your
  planes faster).
- **Airliners** park at your jet bridges, push back, taxi, take off from your runway, fly away and come
  back to land.

## Flying
Build the runway and hangar, buy a plane, then step on its blue **FLY** pad. W/S = speed, A/D = turn,
E = up, Q = down, Space = jump out. On a phone/tablet use the UP/DOWN/FAST/SLOW/LEFT/RIGHT buttons.

## UI
Top bar: money, income per second, rating stars, passengers served, ticket price, % of the airport built.
Buttons: MY AIRPORT (teleport home), HIRE STAFF, RATINGS (categories, tips, reviews, inspector report),
GOALS (progress per phase and what to buy next), AIRPORTS (claim or visit any airport), HELP, HIDE UI.
New reviews pop up in the corner. Progress saves if the server has DataStores.

## Rebuilding / changing it
- Prices, effects and staff: `tools/catalog.py`. Check the pace with `python3 tools/sim.py`.
- What things look like: `src/server/s20_items.lua`. Passengers: `s40_npc.lua`. Planes: `s50_planes.lua`.
- Moving people and planes: 2016 clients don't drag welded parts along with an anchored part that the server
  moves, so the server only moves one invisible marker per NPC (`workspace.AirportMovers`). The model waits in
  `ReplicatedStorage.AirportNPCModels`, and `src/AirportNPCs.client.lua` (in ReplicatedFirst) keeps a copy of
  each one in the player's camera and puts it on its marker every frame.
- `python3 tools/build.py <any 2016 place>.rbxl AirportTycoon.rbxl` builds the place
  (the Mansion Tycoon file was used as the empty container).
- `python3 tests/run.py AirportTycoon.rbxl --api v227` plays it in the fake 2016 engine.
