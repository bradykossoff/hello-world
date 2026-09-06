# Kitchen / Restaurant Building — Design Doc

**Game:** Eat the World (Roblox restaurant tycoon)
**Status:** Redesign of the current procedural `KitchenBuilder`. Real commissioned art incoming.
**Owners:** modeler (builds the stage models), roblox-scripter (rebuilds `KitchenBuilder`), roblox-ui-artist (billboards / seat-state read).

---

## 1. Core loop

**Roll food in New York → slot it into your menu book → customers fill every seat, eat, and pay → spend the money on a bigger restaurant with more seats → repeat.**

The building is the visible scoreboard for that loop. Every upgrade to "Restaurant Size" must be readable in under one second from across the hub: bigger footprint, new silhouette, new color, one signature prop.

---

## 2. Recommendation: prebuilt stage models, not procedural resize

Switch from procedural part-scaling to **3 pre-authored building models, swapped on upgrade.**

Why:

- Real Roblox-style art cannot be stretched along one axis. The moment a mesh, texture, awning, or trim exists, `part.Size = Vector3.new(newSpread, ...)` produces garbage.
- Procedurally destroying and respawning `Table` models throws away all authored detail (chairs, place settings, wear).
- Swap-on-load is *already* the pattern: `PlotManager.assignPlot` calls `KitchenBuilder.SetStage(plot, savedStage)` on every join. A returning Stage 3 player already gets their building rebuilt from scratch at spawn.
- A model swap is deterministic and art-safe. A resize is neither.

Costs we accept:

- 3x the modeling work (Stage 1 / 2 / 3).
- Master models live in `ServerStorage` and are cloned on demand; only the active stage sits in `Workspace`. Memory per plot stays at one building.
- An upgrade briefly despawns the dining room (see §5 edge cases). Acceptable — it is a rare, player-initiated action.

### Storage layout

```
ServerStorage/
  RestaurantStages/
    Stage1  (Model)   -- Cozy Kitchen
    Stage2  (Model)   -- Bigger Kitchen
    Stage3  (Model)   -- Grand Kitchen
```

Each plot gets one build slot. **Rename the per-plot child `Stage1Building` → `Restaurant`** (it is no longer "stage 1"). This touches three files — hand to roblox-scripter:

- `src/server/Modules/KitchenBuilder.luau`
- `src/server/CustomerSystem.server.luau` (`getFreeSeat`, `runCustomerVisit`)
- `src/server/Modules/PlotUtils.luau` (`getSpawnCFrame`)

Each plot also gets one new invisible anchor part: **`plot.BuildAnchor`** — a small non-collidable part whose `CFrame` is where the stage model's pivot lands. Placed once, per plot, in the .rbxl. Its `LookVector` defines "front of restaurant faces the street."

---

## 3. Stage progression

Entrance position, orientation, and the `BuildAnchor` pivot are **identical across all three stages.** The building only grows *sideways* (add tables along the dining-room width) and *upward/outward in dressing*, never toward the street. This keeps customer spawn points and pathing constant.

| Stage | Name | Tables / Seats | Cook stations | Footprint (guide) | Read-at-a-glance |
|---|---|---|---|---|---|
| 1 | Cozy Kitchen | 2 / 4 | 1 (built, may be inert) | ~24 x 24 studs | Wooden shack, single window, hand-painted sign, one stool-height counter. Humble, warm. |
| 2 | Bigger Kitchen | 3 / 6 | 2 | ~32 x 28 studs | Proper storefront: striped awning, glass front, brick base, small lit sign, a couple of planters. |
| 3 | Grand Kitchen | 4 / 8 | 2 (+ visible pass window) | ~40 x 32 studs | Full restaurant: bold roofline, neon/emissive sign, outdoor rail, distinct accent color. Reads as "rich" from anywhere in the hub. |

Footprints are guidance. **Hard constraint:** at Stage 3 the model must fit inside `plot.PlotFloor` with at least a 4-stud margin on every side. The exact `PlotFloor` size is set in the .rbxl — modeler must measure it in Studio before finalizing Stage 3, not guess.

Feel targets:

- Stage 1 → 2 is the "I get it, this game is about growing" moment. Make it a big visual jump (shack → storefront), not a subtle one.
- Stage 2 → 3 is the flex. New silhouette, emissive sign, an obvious color the other 5 plots don't have.
- Every stage keeps the same *interior camera read*: open front or low front wall, tables clearly visible from a normal over-the-shoulder Roblox camera (see §6).

### Stage 4 / 5 / Prestige — reserve, don't build

Keep `MaxLevel = 3` for launch. Design the contract so more stages drop in with zero code change:

- `UpgradeCatalog.KitchenStage.TableCounts` / `Names` / `UpgradeCost` are already data-driven arrays — extend them.
- Stage 4 "Double Decker" (5 tables / 10 seats, second floor or L-wing), Stage 5 "Food Hall" (6 tables / 12 seats). Seat-based capacity stays the unit.
- **Prestige** = cosmetic reset: after Stage 5, "prestige" swaps to a re-skinned Stage 1 with a badge/particle and a prestige counter, loop restarts with a global earnings multiplier. Purely a skin + multiplier layer on top of this same system.
- Server-load ceiling: customer visits are one coroutine per occupied seat. 6 plots x 12 seats = 72 concurrent walking customer models. That's fine with lerp-based movement, but do not exceed ~12 seats/plot without profiling (roblox-qa).

---

## 4. `SetStage(plot, stage)` contract

### Signature (unchanged)

`KitchenBuilder.SetStage(plot: Model, stage: number)` — no return value.

### New behavior

1. Look up `ServerStorage.RestaurantStages["Stage" .. stage]`. If missing → `warn` and return, leave current building untouched.
2. Destroy `plot.Restaurant` if it exists.
3. Clone the stage master, name the clone `Restaurant`, `PivotTo(plot.BuildAnchor.CFrame)`, parent to `plot`.
4. Set every seat's `Occupied` attribute to `false` (masters ship with it `false`, but be explicit).
5. `plot:SetAttribute("KitchenStage", stage)` — **must stay**, `PlotManager` and the client upgrade UI both listen on `KitchenStage`.

Idempotent: calling with the current stage is a full rebuild (used to recover a plot to a clean state on player release).

Must **not** touch: `plot.Menu`, `plot.SignPost` (nameplate text is `PlotManager`'s job), `plot.UpgradeKiosk`, `plot.PlotFloor`, boundary posts, `plot` ownership attributes.

### Required named children of every stage model

Names are exact and case-sensitive. Anything not in this list goes in a `Decor` folder and is ignored by code.

```
Restaurant (Model)                 -- PrimaryPart = "Base"
  Base (Part)                      -- model pivot; anchored; sits under the whole build
  DiningFloor (Part)               -- walkable interior floor (CanCollide true)
  EntranceMarker (Part)            -- anchored, CanCollide false, Transparency 1
                                   --   .LookVector points OUT toward the street.
                                   --   Customers & the owner spawn along +LookVector.
  Tables (Folder)
    Table1 (Model)                 -- PrimaryPart = "Top"
      Top (Part)
      Chair1 (Part)                -- attribute Occupied (bool) = false
      Chair2 (Part)                -- attribute Occupied (bool) = false
      WalkPath (Folder)            -- optional; ordered Node1..NodeK, world-space
                                   --   parts forming the lane from the aisle to
                                   --   this table. Last node ~2 studs in front of
                                   --   the table. If absent, code walks a straight
                                   --   line EntranceMarker -> chair (graybox only).
    Table2 (Model) ...             -- Table1..TableN, N = stage table count
  Aisle (Folder)                   -- ordered Aisle1..AisleM parts down the centre
                                   --   of the dining room, entrance end -> back.
                                   --   Shared spine every WalkPath connects into.
  KitchenStations (Folder)
    Station1 (Model)               -- PrimaryPart = "Counter"
      Counter (Part)
      StandMarker (Part)           -- anchored, CanCollide false, Transp 1: where
                                   --   the player stands to man the station.
      PromptMount (Attachment)     -- on Counter: where a ProximityPrompt attaches.
    Station2 (Model) ...           -- Stage 1: Station1 only. Stage 2/3: Station1+2.
  SignMount (Attachment)           -- facade sign anchor (name / neon). On the front wall.
  KioskMount (Part)                -- reference marker: where plot.UpgradeKiosk should
                                   --   visually sit relative to this stage. Kiosk is
                                   --   NOT reparented by SetStage; this is for the
                                   --   .rbxl author to line the kiosk up. Optional.
  Decor (Folder)                   -- everything cosmetic; code never reads this.
```

Attribute conventions:

- `Chair1` / `Chair2`: `Occupied` (boolean, default `false`). This is the **unit of customer capacity** — `CustomerSystem.getFreeSeat` iterates `Table1..TableCount`, then `Chair1`, `Chair2`, and takes the first chair whose `Occupied` is falsy.
- Chairs must be authored so a customer standing at `chair.Position + (0, 1.2, 0)` and facing `Top` looks correctly seated. (Current code derives facing from the table top — keep chairs positioned to match.)
- Optional convenience: set `Restaurant` model attribute `TableCount` = N. Not required (code reads it from `Upgrades.GetTableCount(plot)`), but useful for QA.

### Downstream code that must keep working unchanged

| System | Depends on |
|---|---|
| `CustomerSystem.getFreeSeat` | `Restaurant.Tables.TableN.ChairX` + `Occupied` attr |
| `CustomerSystem.runCustomerVisit` | `Restaurant.EntranceMarker` (spawn + exit), chair & table `Top` positions |
| `PlotUtils.getSpawnCFrame` | `Restaurant.EntranceMarker` (owner spawns just outside, facing in) |
| `PlotManager.updateBillboard` | `plot:GetAttribute("KitchenStage")` |
| `Upgrades.Purchase` (KitchenStage branch) | `KitchenBuilder.SetStage` setting the `KitchenStage` attribute |

---

## 5. Edge cases

- **Upgrade mid-service.** `SetStage` destroys `Restaurant`, so chairs and customer models under it vanish. Every customer-visit coroutine must null-check its `chair`, `table`, and `customer` each step (walk loop, post-eat payout) and abort cleanly if any is gone or de-parented. Owner gets no payout for an evicted customer — acceptable, upgrades are rare and player-initiated. (Hand this guard to roblox-scripter as part of the `CustomerSystem` pass.)
- **`SetStage` before ownership.** `PlotManager` calls it during `assignPlot` before `LoadCharacter`. Model swap must not depend on an owner existing.
- **Missing stage master.** `warn` and no-op; never leave a plot with no building.
- **Missing `BuildAnchor`.** `warn`, no-op. Add `BuildAnchor` to all 6 plots in the .rbxl as part of this work.
- **Stage clamp.** `stage` outside `1..MaxLevel` (bad DataStore value) → clamp to `1..MaxLevel` before lookup.
- **Player release / plot recycle.** `PlotManager.releasePlot` calls `SetStage(plot, 1)` — full rebuild to a clean Cozy Kitchen with all seats free for the next owner. Menu is cleared separately.
- **Occupied leak.** If a visit coroutine errors, its chair could stay `Occupied` forever. `SetStage` clearing all `Occupied` on rebuild is the backstop; also add a per-visit `pcall` + cleanup (roblox-scripter).
- **WalkPath / Aisle absent on graybox.** Code falls back to a straight entrance→chair lerp. Fine for testing, will clip through walls — real models must ship the folders.

---

## 6. Mobile readability & camera

Roblox audience is mobile-majority on small screens with a default over-the-shoulder camera. The building must read at a glance on a phone.

- **Open front.** No full front wall, or a wall no taller than ~3 studs, so the player and customers see every seat from outside and from the standard camera. Roof sits on posts / partial walls, never fully enclosing the interior.
- **Wall height ceiling ~10–12 studs** even at Stage 3, so the camera doesn't collide/clip when the owner stands inside.
- **Seat state must read without UI.** Empty chair = visible empty chair (optionally a soft highlight or "sit" decal). Occupied = a clearly-colored customer model in it. Do not rely on a billboard to tell players a seat is taken.
- **High-contrast tables/chairs** against the floor so seat count is countable at a glance on a small screen.
- **Silhouette per stage.** From hub distance a player should identify a plot's stage by roofline + color alone. Give each stage a distinct roof shape and one accent color.
- **One building billboard** above the roofline (owner name + "Stage N"), large text, `AlwaysOnTop`, readable at hub scale — spec to roblox-ui-artist. This is separate from `plot.SignPost` (the roadside nameplate) and the facade `SignMount`.
- **Scale customers to the seats,** not the other way around — current customer torso is `2 x 2.5 x 1`. Chairs and table height must suit that so a seated customer isn't clipping or floating on a phone screen.

---

## 7. Kitchen stations (reserved, mostly inert at launch)

Design space for a later **active-cooking layer**: during a customer rush the owner mans a station (hold / tap a prompt) for a temporary payout multiplier on their plot.

Reserve now:

- Every stage model ships `KitchenStations` with `Station1` (Stage 1) or `Station1` + `Station2` (Stage 2/3), each with `Counter`, `StandMarker`, `PromptMount` as specced in §4.
- Stations are visually "on" (props, steam particles in `Decor`) but have **no gameplay effect at launch** — no prompt, no multiplier.
- When built later: `ProximityPrompt` on `PromptMount`, hold to "cook", server-authoritative multiplier attribute on the plot (e.g. `CookBonusUntil` timestamp), applied in `runCustomerVisit`'s payout the same place `GetTipMultiplier` is. Client may play the cook animation/particles predictively; the multiplier and its duration are server-only.
- Mobile input: single hold-prompt, no combo. One button, thumb-reachable.
- Multiplayer scaling: multiple players on one plot (friends helping) can each hold a different station — stations stack additively up to a cap. This makes a full server more fun, not less.

---

## 8. Customer flow & pathing

Movement is dumb lerp (`PivotTo` between CFrames), **no Humanoid, no PathfindingService.** The models must hand the code a clean route.

Sequence per visit (`runCustomerVisit`):

1. **Spawn** at `EntranceMarker.Position + EntranceMarker.LookVector * 8` (outside, on the street side).
2. **Walk in:** `EntranceMarker` → `Aisle1..AisleM` (in order, only the nodes before the target table's junction) → target `TableN.WalkPath.Node1..NodeK` → chair. Each hop is a timed lerp.
3. **Sit & eat:** parked at `chair.Position + (0, 1.2, 0)` facing `Top` for `getEatTime(plot)` seconds (14–20s base, shortened by Kitchen Speed).
4. **Pay:** server adds money (`Economy.Add`), floating `+$` text, owner notification. **Server-authoritative** — value = `BaseRestaurantValue * ValueMultiplier * TipMultiplier * MoneyMultiplier`, all computed server-side from a snapshot taken when the customer sat down.
5. **Walk out:** reverse of step 2, then `Destroy`.

What the models must provide:

- `EntranceMarker` with `LookVector` pointing **out** toward the street, same local position and facing in all 3 stages.
- `Aisle` folder: ordered parts down the dining-room centerline, entrance end → back wall. This is the shared spine.
- Per-table `WalkPath` folder: ordered parts from the aisle spine to a point ~2 studs in front of that table. Keeps customers from walking through tables/walls as the room widens at higher stages.
- Clear floor (`DiningFloor`) with nothing collidable in the lanes.
- Enough clearance in every lane for a `2 x 2.5 x 1` customer plus margin.

Client vs server:

- **Server-authoritative:** which seat a customer takes, `Occupied` attribute, eat timer, payout amount and the fact a payout happened, spawn/despawn of customer models.
- **Safe to predict client-side (feel only):** customer walk interpolation smoothing, floating `+$` text, eat/idle animation, station cook VFX. Never let the client report "a customer paid" or set currency.

---

## 9. "Done" looks like

- `ServerStorage.RestaurantStages` has `Stage1`, `Stage2`, `Stage3`, each passing the §4 checklist (verified by a checker script or roblox-qa).
- All 6 plots have `BuildAnchor`; per-plot child renamed to `Restaurant`.
- `KitchenBuilder.SetStage` rebuilt against §4: model swap, pivot to anchor, clears `Occupied`, sets `KitchenStage`, handles every §5 edge case.
- `CustomerSystem`, `PlotUtils` updated to the new child name; customer coroutines guard against a destroyed `Restaurant`.
- Buying "Restaurant Size" swaps the building with no error, no orphaned customers, seats immediately usable.
- Returning Stage 3 player spawns into a Stage 3 building; released plot resets to a clean Stage 1.
- On a phone at hub distance, a test player can tell Stage 1 / 2 / 3 apart and count the seats without moving the camera.
- Stations are visible and thematically "on" but have no gameplay effect yet.

---

## Handoffs

- **roblox-scripter:** rebuild `KitchenBuilder.SetStage` (§4), rename `Stage1Building` → `Restaurant` across the 3 files, add customer-coroutine guards (§5), add `stage` clamp. Later: active-cooking station system (§7).
- **modeler:** 3 stage models to the §4 spec, fit within `PlotFloor` (measure in Studio), open-front readable interiors (§6), `Aisle` + per-table `WalkPath` node folders (§8), inert-but-dressed `KitchenStations` (§7).
- **roblox-ui-artist:** per-building billboard (owner name + stage), empty-seat highlight/read (§6).
- **roblox-qa:** stage-model checker, upgrade-mid-service test, concurrent-customer load test at max seats x 6 plots.
- **roblox-monetization:** later — station cook-multiplier balance, any "instant upgrade" or "extra table" products, must stay server-authoritative.
