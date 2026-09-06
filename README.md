# Eat the World — Roblox restaurant tycoon

Claim a plot, stock a menu of rarity-rolled food, serve customers, upgrade
your restaurant. Built with a team of specialized Claude Code subagents
(`.claude/agents/`) — see `CLAUDE.md` for how they divide the work.

## The team (`.claude/agents/`)

| Agent | Role |
|---|---|
| `roblox-game-designer` | Mechanics, systems, progression, game design docs |
| `roblox-scripter` | Luau gameplay code — client, server, shared modules |
| `roblox-ui-artist` | In-game UI/UX (HUD, menus, mobile/console layout) |
| `roblox-monetization` | Game passes, dev products, economy balance, policy |
| `roblox-qa` | Test plans, exploit/edge-case review, performance review |

## Project layout

Code is synced into Studio with Rojo. `default.project.json` maps:

| Source | Studio location |
|---|---|
| `src/server/` | `ServerScriptService` (systems + `Modules/`) |
| `src/client/` | `StarterPlayer.StarterPlayerScripts` (UI controllers) |
| `src/shared/Data/` | `ReplicatedStorage.Data` (catalogs, food defs, rarity table) |
| `src/serverstorage/RestaurantStages/` | `ServerStorage.RestaurantStages` (`Stage1/2/3` building models) |
| *(project.json)* | `ReplicatedStorage.Remotes` (RemoteEvents, declared in the project file) |

**What Rojo does NOT manage:** the built world — `Workspace.Plots`,
`Workspace.Hub`, `Workspace.Destinations`, `Lighting`, etc. That geometry
lives only in `eattheworld.rbxl` (committed as the source of record until
it moves to real art). `docs/place-structure.txt` snapshots that hierarchy.

**Generator / helper scripts** (`lune run scripts/<name>`):

| Script | Purpose |
|---|---|
| `build-stages` | regenerate the 3 `RestaurantStages` models from code |
| `check-stages` | assert the models still meet the `KitchenBuilder` contract |
| `check` | Luau syntax-check everything under `src/` |
| `patch-place` | one-time `eattheworld.rbxl` surgery (already run) |
| `extract` / `inspect-plots` | pull scripts / dump plot geometry from a place file |

## Studio syncing (Rojo)

Toolchain is pinned in `rokit.toml`. On a fresh machine:

```
rokit install          # installs Rojo + Lune (needs Rokit: winget install Rojo.Rokit)
rojo plugin install    # installs the Rojo plugin into Roblox Studio
```

Day-to-day:

```
rojo serve             # serves default.project.json on localhost:34872
```

Open `eattheworld.rbxl` in Studio, open the **Rojo** panel, click
**Connect**. Files under `src/` are the source of truth — one-way sync
pushes them into the place (leave Two-Way Sync **off**).
