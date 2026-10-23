# Escape the Hog (2016 edition)

An original Piggy-style escape game for 2016 Roblox. Open/upload `EscapeTheHog.rbxl`.

- **Lobby = a menu on the screen** (like Piggy): the title, a big **PLAY** button and four buttons under it
  (**ITEMS**, **MAPS**, **HOW TO**, **STATS**), in front of a dark hallway where the Hog stands with its bat raised.
  After PLAY comes the **HOG VOTING** screen (countdown in the title): 6 mode cards with pictures and vote counts, and
  the 2 maps. The countdown only runs once someone has pressed PLAY; only players who pressed PLAY go in.
- **Modes**:
  - **Bot** - a bot Hog hunts you. **Swarm** - THREE bot Hogs.
  - **Player** - a random player is the Hog (pig mask, a bit faster, 3 traps). **Player + Bot** - a player Hog AND a bot.
  - **Infection** - a player Hog; everyone it catches turns into a Hog too.
  - **Traitor** - a bot Hog, and one of the survivors is secretly the Traitor (they can tag someone every 25 s).
  - Player modes need 2+ players (alone you get Bot). If a Hog player leaves, a bot takes over.
- **Maps** (all have door frames, skirting boards, rugs, furniture in every room and flickering lights):
  - Hog Manor and the School are built 1.25x bigger with taller ceilings, so the rooms feel big and roomy.
  - **Hog Manor** (207 x 147 studs, 16 rooms): nursery, laundry room, study, library, greenhouse, bedroom, bathroom,
    kitchen, pantry, garage, living room, dining room, cellar, the security room (keycard door), the hallway and the
    Hog's pen.
  - **School** (222 x 202, 16 rooms): two classrooms, the science lab, library, computer lab (keycard door),
    cafeteria, gym, principal's office, entrance, art room, music room, locker room, nurse's office, auditorium, the
    hallway and the janitor's closet.
  - **Circus** (300 x 250 - the biggest, made like Piggy's Carnival): no rooms - one big OPEN fair at night inside a
    purple fence with a white picket fence, cobblestone paths, lamp posts with glowing lanterns and trees. Standing
    around in it: the giant red-and-white striped **Big Top** (ring, bleachers, trapezes, spotlights, and two metal
    platforms up high with ladders - the Hog can't climb them), the **cafeteria**, a red **storage shed** (Red Door),
    the **arcade** (game machines, claw machine), the **security office** (keycard door), the **haunted house**
    (coffins, tombstones, a bubbling cauldron), the **roller coaster** "The Pig Dipper" behind a blue gate (Blue
    Door), a big **ferris wheel**, a **carousel** with horses, ticket booths, food carts, a popcorn stand, game
    stalls, balloons and benches. The Hog waits in the clowns' trailer; the way out is the gate under the big
    **HOG'S CARNIVAL** arch (boards, padlock, bolt). The bot walks a grid of paths all over the fair, round the
    buildings and rides.
- **Puzzles like Piggy** (nothing tells you what goes where):
  - Items look like the real thing: keys with a round bow and teeth (red, blue, gold), a claw hammer, a wrench, a
    glass fuse, a keycard with a chip, and the stun gun - and you hold the same model in your hand.
  - **Keycard doors**: grey metal doors with a card reader (green light). The keycard is behind another locked door.
  - **The exit** needs everything: boards (hammer), a padlock (gold key), a **generator** (wrench - Manor and Circus)
    or the **fuse box** (fuse - School), and a **keypad**: find the **code note** lying somewhere (a new 4-digit code
    every round), click the keypad and type it in. A wrong code beeps loudly and the Hog comes running.
- **Harder**: picking items up makes a noise the Hog can hear nearby, it hears every lock you open, it gets a bit
  faster with every lock (up to +6%), and it lays 4 traps.
- **Vents** (like Piggy): every map has 3 vents. Each one is a square hole in the floor with a ladder, a metal
  tunnel under the floor, and another hole in a different room. The tunnel is only 4.6 studs high: standing up you
  don't fit - you have to **crouch (C or Ctrl)** and crawl through. The Hog can't follow you, can't see you and can't
  catch you down there, and you can't stand up until you're out. Climb the ladder at the other end to get out.
- **Stun Gun**: one is hidden on every map. Hold it and **click at the Hog**: it's frozen for **20 seconds** (bot
  Hogs and player Hogs). 2 shots, then it's used up and another one turns up somewhere 40 seconds later.
- **The round**: everyone is locked inside. The Hog waits in its pen and gets out after 15 seconds. You have 8 minutes.
- **Items**: keys, a hammer, a wrench, a fuse and the stun gun are hidden in random places each round (they glow a little).
  **Click** one to pick it up (it lights up and shows its name when you point at it). You can only carry **one**;
  clicking another swaps them. **No hints**: locked doors are plain wooden doors with a handle and keyhole the colour
  of their key, and nothing tells you what goes where - work it out and **click** the lock with the right item.
  - Hog Manor's front door: boards, a padlock and a bolt. The School's main doors: boards, a padlock and the fuse box.
  - When every lock on the exit is open, the door swings open: run outside to **escape** (+50 Coins, +1 Escape).
- **Crouch**: press **C** or **Ctrl** (or the CROUCH button): you walk slower and lower, and a bot Hog only sees you from 32
  studs (not 75) and only hears you right next to it.
- **The Hog**: caught = jumpscare and you're out (you drop your item). The screen edges glow red when a Hog is close.
  The bot walks the halls, chases anyone it sees, comes to check when it hears a lock being opened, and leaves bear
  traps in doorways (stuck for 5 seconds).
- **Saved**: Coins and Escapes are saved between visits (DataStore, if the server allows it).
- **Admin**: the admin panel works only for asdasda (checked on the server, FilteringEnabled on).
- Built for Chromebooks: 550-620 parts per map, only the map being played exists, and the Hogs' walking is drawn
  on each player's computer (no physics).

Build: `python3 tools/build.py`. Test (mock Roblox): `python3 tools/test/runner.py`.
