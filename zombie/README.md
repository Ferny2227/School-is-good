# Zombie Defense 3 – fixed for 2016 Roblox (revival)

`ZombieDefense3_fixed.rbxl` is the fixed place. `tools/patch.py original.rbxl fixed.rbxl` re-applies the fixes.

| Problem | Fix |
|---|---|
| Guns did nothing when firing on engines before June 2016 (`FireSound.Playing` didn't exist yet) | `IsPlaying` in all 34 gun scripts |
| Shops never opened, mercenaries couldn't be hired (`:Connect` with a capital C isn't in 2016 Roblox) | lowercase `:connect` |
| Buying used server scripts inside the shop window, which can't see clicks with FilteringEnabled on | buttons handled by `ShopClient` (LocalScript), buying done by `ServerScriptService.ShopBuyServer` (checks the price) |
| `UserOwnsGamePassAsync` (2018) crashed zombie mode (it was called every frame) and the gamepass tools | protected and cached |
| Players already in the server never got a `TEAM` value (guns wait for it) | `CharacterSpawn` sets them up too |
| Hard to see errors on the revival | on-screen error box (client + server errors) |

Tested in the fake Roblox engine from `mechacubes/tests` (2016 API): the pistol kills a test zombie,
the Automatic weapon shop opens, buys Dual Pistols for 250 Coin and closes. The original fails both.
