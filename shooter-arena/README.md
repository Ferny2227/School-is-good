# Shooter Arena (Roblox) – v6

`ShooterGame_v6.rbxlx` is the game. Open it in Roblox Studio (File > Open from File) and press Play.
The full guide (modes, maps, controls, admin commands) is the `README` script inside the game, and the
same text is in `src/README.lua`.

## What's new in v6
- **Team selection:** RED / BLUE / AUTO in the lobby (buttons or team pads), **T** to switch mid-match. Bots keep the teams even.
- **Third person works on a Chromebook:** a custom shoulder camera that turns with the touchpad without clicking, plus the arrow keys. **Q** aims, **F** shoots, **X** swaps shoulder.
- **3 new big maps:** Desert Outpost, Frozen Harbor, Timber Forest.
- **Weather:** rain, thunderstorm, snow, fog, night with flashlights, sandstorm. You can vote for it.
- **New modes:** King of the Hill and Gun Game.
- **Extras:**
  - Medals and assists.
  - Ammo drops.
  - Touch-screen buttons.
  - A redesigned UI that shrinks to fit small screens.
  - Only the active map is loaded, which is faster on Chromebooks.

## Folder
| Path | What |
|---|---|
| `ShooterGame_v6.rbxlx` | The place file to open in Studio |
| `src/*.lua` | The same scripts as plain files (easy to read and diff) |
| `tools/build_rbxlx.py` | Puts `src/*.lua` back into a place file |
| `tools/tests/` | A fake Roblox engine in Lua that runs the scripts outside Studio |

## Rebuilding after editing `src/`
```
python3 tools/build_rbxlx.py ShooterGame_v6.rbxlx ShooterGame_v6.rbxlx
```

## Tests (needs `pip install lupa pillow`)
```
python3 tools/tests/test_maps.py     # every spawn has a floor and isn't inside a wall
python3 tools/tests/test_server.py   # plays TDM, KOTH, Gun Game, Elimination, FFA with fake players
python3 tools/tests/test_client.py   # runs the HUD / menus / camera for a fake player (add "touch" for touch screens)
```
They catch Lua errors and broken logic. They can't show what the game looks or feels like, so still try it in Studio.
