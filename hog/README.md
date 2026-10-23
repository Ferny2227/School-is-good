# Escape the Hog (2016 edition)

An original Piggy-style escape game for 2016 Roblox. Open/upload `EscapeTheHog.rbxl`.

- **Lobby = a menu on the screen** (like Piggy): the title, a big **PLAY** button and four buttons under it
  (**ITEMS**, **MAPS**, **HOW TO**, **STATS**), in front of a dark hallway where the Hog stands with its bat raised.
  After PLAY you get the vote screen:
  - the **map**: **Hog Manor** (a house: bedroom, bathroom, kitchen, pantry, garage, living room, dining room,
    cellar) or the **School** (classrooms, science lab, library, cafeteria, gym, principal's office, entrance);
  - the **Hog**: a **Bot Hog** or a **Player Hog** (one random player becomes the Hog; needs 2+ players).
  The countdown only runs once someone has pressed PLAY; only players who pressed PLAY go in.
- **The round**: everyone is locked inside. The Hog waits in its pen (the Janitor's Closet in the School) and gets
  out after 15 seconds. You have 8 minutes.
- **Items**: keys, a hammer, a wrench and a fuse are hidden in random places each round (they glow a little).
  **Walk over** one to pick it up (or click it). You can only carry **one** at a time; clicking another swaps them.
  - Hog Manor: Red Key -> Red Door (bedroom, where the Wrench is), Blue Key -> Blue Door (cellar, where the Gold Key
    is). The front door has **Boards** (Hammer), a **Padlock** (Gold Key) and a **Bolt** (Wrench).
  - School: Red Key -> the Science Lab (Gold Key), Blue Key -> the Principal's Office (Fuse). The main doors have
    **Boards** (Hammer), a **Padlock** (Gold Key) and the **Fuse Box** (Fuse).
  - **Walk up to** a lock (or click it) while holding the right item to use it. The list on the right shows what's still shut.
  - When every lock on the exit is open, the door swings open: run outside to **escape** (+50 Coins, +1 Escape).
- **The Hog**: caught = jumpscare and you're out for the round (you drop your item). The screen edges glow red when
  the Hog is close. The bot walks the halls, chases anyone it sees, comes to check when it hears a lock being opened,
  and leaves bear traps in doorways (stuck for 5 seconds). A Player Hog is a bit faster, wears the pig mask and has
  3 traps (Trap tool or the SET TRAP button). If the Hog player leaves, the bot takes over.
- **Saved**: Coins and Escapes are saved between visits (DataStore, if the server allows it).
- **Admin**: the admin panel works only for asdasda (checked on the server, FilteringEnabled on).
- Built for Chromebooks: about 230 parts per map, only the map being played exists, and the Hog's walking is drawn
  on each player's computer (no physics).

Build: `python3 tools/build.py`. Test (mock Roblox): `python3 tools/test/runner.py`.
