# Casino ("Las Vegas at home") – load + lag fixes

`Casino_fixed.rbxl` is the fixed place. Open it in Studio (File > Open from File) and press Play.

## Why it was stuck on "loading..."
The PLAY button only appears after the server gives you your `Playtime` value, and that only happened
after ProfileService loaded your save. ProfileService only fell back to "offline mode" **inside Studio
and only for 2 exact error messages**. Everywhere else (an unpublished place, Studio API access off,
a test or private server) it kept retrying forever, so you never got in.

A fake DataStore that always fails (or never answers) reproduces it. The original stays stuck in every
case. The fixed version loads in 1 to 10 seconds. With a working DataStore both behave the same.

## Fixes
| Problem | Fix |
|---|---|
| Stuck on "loading..." when the DataStore can't be reached | ProfileService (and BetterChat's copy of it) switches to offline mode on any error or after a 10 s timeout. Data isn't saved in that session. |
| Disclaimer waits forever if data never arrives | PLAY shows up after 20 s anyway. The 60 s first-time timer is skipped in Studio. |
| `PlayerManager` loaded players already in the server *before* connecting `PlayerAdded` (people joining meanwhile never loaded) | Connects first, then loads the others in parallel |
| A failed group-rank lookup aborted loading (no playtime clock, no leaderstats updates) | Protected with pcall (also in `Permissions` and the `Overhead` nametag) |
| `workspace.Suites` doesn't exist, so the per-second clock crashed when suite time ran out | Guarded |
| RankGun crashed the playtime loop (it decoded the reply of a failed request; the API key is empty) | Skipped when there is no key; failed requests are handled |
| `GameManager` crashed in unpublished places (DataStore / MessagingService) before switching on any game | Protected |
| `Leaderboards` crashed the same way | Protected |
| One failed avatar download killed the NPC spawner for the whole server; endless recursion when no names load | Each spawn is protected; waits at most 60 s for names |
| **Lag:** every table got its own copy of its game script **inside Workspace**, so every player downloaded all of it on join (the poker lookup module alone is 1.7 MB × 10 poker tables) | The copies run from ServerScriptService (never sent to players) and use a `Target` value to find their table. The poker tables share one lookup module. |
| **Lag:** 21,306 unused objects: animation editor saves inside the dealers (465 animations, 17,036 poses), `RBX_ANIMSAVES`, an unused old copy of BetterChat, a duplicate poker module set | Deleted (68,247 → 46,941 objects, 4.8 MB → 3.4 MB file) |
| **Lag:** all 610 lights cast shadows | Shadows off |
| **Lag:** up to 50 NPCs, each a full player avatar | Limit 20 (attribute `GlobalNPCLimit` on `ServerScriptService.Environment.NPCs`) |
| Disclaimer background kept animating every frame after it was closed | Stops when closed |

Every changed line is marked `-- [fix]`.

## Saving your progress in Studio
Studio only saves when *Game Settings > Security > Enable Studio Access to API Services* is on and the
place is published. Otherwise it plays in offline mode (the Output says `data will not be saved`).

## Tools
`tools/patch.py original.rbxl fixed.rbxl` applies all the fixes. `tools/rbxl.py` and `tools/rbxlw.py`
read and write the binary place format, `tools/dump.py` exports every script to .lua files, and
`tools/verify.py` compares two places.
