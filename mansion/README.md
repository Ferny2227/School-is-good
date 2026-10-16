# Mansion Tycoon (fixed for 2016 Roblox engines)

`MansionTycoon_fixed.rbxl` is the game. Open it in Studio and press Play, or upload it to the revival.

## What changed
- **Cheaper:** every one of the 41 buttons in each mansion costs a quarter of what it did, and the price
  on the button changed to match (Pool $90K -> $22K, Helicopter $700K -> $180K, Diamond Production
  $5M -> $1.2M). Class promotions need a quarter of the money, and they no longer kill you when you're short.
- **Double income:** every brick is worth 2x at the collector.
- **Less lag:** removed 414 "Fire.Spread" virus scripts on the helicopters (each copied itself into anything
  it touched and grew its fire by 1,000,000), 73 empty virus scripts ("OH SNAP YOU GOT INFECTED XD"),
  and a script that deleted the starter pack. Turned off a second reset script that fought with the first
  one, and 2 scripts that never worked.
- **Backyard with 100 more things to buy** behind every mansion. Walk on a gold pad (with a light beam above it) to buy (owner only).
  - The first row of 10 always shows; buy 5 in a row to open the next row. Prices go from $100 to about $2M.
  - **Every item adds money per second** to your "Cash to collect". Money makers (lemonade stand, hot dog
    stand, ATM, money printer, bank vault, money tree...) pay the most.
  - Lots of them do something: benches, swings, hammock, gazebo, hot tub and throne you can sit on;
    trampolines and jump pads bounce you; speed pads make you fast; the slide and tree house ladder;
    the carousel, ferris wheel, wind turbine, windmill, lighthouse beam and UFO spin; the disco floor blinks;
    the hot dog stand, soda machine, frisbee shed, spray paint shed, disco floor, cloud garage and motorcycle
    garage give you the game's tools; the Mansion Portal takes you back to your mansion.
  - The full list: Mailbox, Garden Gnome, Red Flowers, Bird Bath, Wooden Bench, Lamp Post, Lemonade Stand,
    Small Tree, Hedge Row, Yellow Flowers, Picnic Table, Dog House, Swing Set, Sandbox, Campfire, Hammock,
    BBQ Grill, Basketball Hoop, Rock Garden, Blue Flowers, Trampoline, Slide, Tree House, Pond, Little Bridge,
    Flag Pole, Big Oak Tree, Hot Dog Stand, Soda Machine, Garden Shed, Gazebo, Hot Tub, Speed Pad,
    Frisbee Shed, Stone Statue, Garden Fountain, Greenhouse, Solar Panels, Pine Trees, Pink Gnome, Carousel,
    Wind Turbine, Jump Pad, Pizza Oven, Arcade Corner, Telescope, Mini Golf, Palm Tree, Koi Pond, Big Campfire,
    Disco Floor, Spray Paint Shed, Cloud Garage, Motorcycle Garage, Money Printer, Lighthouse, Windmill,
    Apple Tree, Super Trampoline, Ice Cream Stand, ATM, Satellite Dish, Water Tower, Observatory,
    Rocket Statue, Pyramid, Hedge Maze, Ferris Wheel, Golden Bench, Mega Speed Pad, Bank Vault, Crystal Tree,
    Lava Lamp Tower, Castle Tower, Golden Gnome, Diamond Fountain, Rainbow Bridge, Neon Sign, Hero Statue,
    Dragon Statue, Robot Butler, UFO, Volcano, Golden Tree, Rocket Ship, Treasure Chest, Waterfall,
    Ice Castle, Crown Statue, Mansion Portal, Diamond Tree, Golden Throne, Money Tree, Mega Printer,
    Rainbow Fountain, Giant Trophy, Moon Statue, Golden Rocket, Golden Pyramid, Mansion Monument.
  - The backyard resets with the mansion when its owner leaves.
- **UI:** a BACKYARD / MANSION button (teleports you between them), how many of the 100 you own and what
  they pay per second, and a pop-up when you buy something or need more money.

## Changing things
- Prices/income of the old buttons: `PRICE` and `INCOME` at the top of `tools/patch.py`.
- The 100 backyard things (names, what they look like, prices): `src/Backyard.server.lua`.

## Rebuilding
    python3 tools/patch.py <original.rbxl> MansionTycoon_fixed.rbxl
    python3 tests/run.py MansionTycoon_fixed.rbxl --api v227   # plays it in the fake 2016 engine
