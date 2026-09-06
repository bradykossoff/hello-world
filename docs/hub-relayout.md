# Hub plot re-layout — proposal

**Status:** proposal only. The garden pass (`WorldDress` + `ParkKit`) dresses the
**current** layout and needs no .rbxl changes. This doc is a separate idea for
rearranging the six plots later, if we decide the current shape is holding the
hub back.

---

## Why change it

The six plots today sit in **two columns of three down a 200-stud straight
corridor** (`MainRoad`, `X ±8`, `Z -146…70`), plazas bolted on the north end:

| | left column (X −40) | right column (X +40) |
|---|---|---|
| Z 40 | Plot 1 | Plot 2 |
| Z −40 | Plot 3 | Plot 4 |
| Z −120 | Plot 5 | Plot 6 |

Problems:

- **Unequal access.** Plot 5/6 are ~180 studs and two "blocks" from the plaza
  and the airport; Plot 1/2 are right next to them. That's a real disadvantage
  for whoever lands in the back.
- **It's a hallway.** You walk past every other restaurant to get anywhere.
  There's no centre, no "town square" the hub revolves around.
- **No arrival moment.** Spawn pads drop you onto a narrow road facing a wall.
- **Doesn't show the game off.** In a tycoon, seeing other players' restaurants
  grow is the pull. A straight line hides them behind each other.

---

## Recommended: village green (horseshoe)

Put the six plots in a **horseshoe around a central green**, with the plaza,
fountain and travel board closing the open end.

```
                 ┌─────────  PLAZA / FOUNTAIN / TRAVEL  ─────────┐
                 │                                              │
        Plot 6 ──┤                                              ├── Plot 1
                 │                                              │
        Plot 5 ──┤            central green + spawn              ├── Plot 2
                 │          (fountain, lawn, benches)            │
        Plot 4 ──┤                                              ├── Plot 3
                 │                                              │
                 └──────────────────────────────────────────────┘
```

- All six restaurants **face inward** onto one shared green. Every plot is the
  same short walk (~35 studs) from the centre, the plaza and each other.
- The green is the spawn area and the social hub — you can see all six
  restaurants and the fountain the moment you arrive.
- The garden (pond, pergola, gazebo, flower beds) fills the green and the gaps
  between plots instead of being squeezed into side yards.

### Rough coordinates

Keep the plot floors 50×50. Centre the green on the old plaza area so the
existing plaza/airport/travel wiring barely moves.

| plot | floor centre (X, Z) | faces |
|---|---|---|
| 1 | ( 78,  40) | −X |
| 2 | ( 88, −10) | −X |
| 3 | ( 78, −60) | −X |
| 4 | (−78, −60) | +X |
| 5 | (−88, −10) | +X |
| 6 | (−78,  40) | +X |

- Green: roughly `X[-55,55] Z[-75,55]`, fountain at `(0, , -10)`.
- Plaza / travel board / airport: shift ~40 studs so the plaza sits at the
  north (open) end of the horseshoe, `Z ≈ 75…130`.
- `BuildAnchor` for each plot stays 15 studs toward the green from the floor
  centre, `LookVector` pointing at the green.
- Spawn pads: one arc of six on the green just inside each plot's arch.

### Alternatives considered

- **Ring road** — plots evenly around a full circle, hub buildings on the
  centre island. Cleaner symmetry but the plaza has nowhere natural to go, and
  a full ring is a bigger footprint.
- **Two greens of three** — left triad + right triad around two small greens,
  plaza between them. Less of a single social centre; better if we later want
  6 → 12 plots (add a third green).

The horseshoe is the best fit for **6 plots + one plaza** and leaves the door
open to a second horseshoe later.

---

## What it costs

### .rbxl surgery (one Lune script, like `scripts/patch-place.luau`)

1. Move the 6 `PlotFloor` parts and their `BoundaryPost1..4` to the new centres.
2. Move each `plot.BuildAnchor` to `floorCentre + 15 studs toward the green`,
   yaw so `LookVector` faces the green.
3. Move the 6 `Hub.PlayerSpawnPads.SpawnPad_PlotN` onto the green in front of
   each plot.
4. Shift `PlazaFloor`, `PlazaSign`, `PlazaAirportPath`, `AirportFloor`,
   `RunwayStripe`, plane placeholder, `AirportSign`, `TravelBoard`,
   `PlazaTeleportPoint`, `Kiosks.PassportKiosk` by the plaza offset (~+40 Z).
5. Replace `MainRoad` with the green (or repurpose it as the plaza approach).

### Code — mostly unaffected

Nothing keys off plot **position**; systems find plots by iterating
`Workspace.Plots` and reading attributes:

| System | Uses | Safe after move? |
|---|---|---|
| `PlotManager` | folder iteration, `OwnerUserId` attr, `SignPost.Nameplate` | yes |
| `KitchenBuilder.SetStage` | `plot.BuildAnchor.CFrame` (pivots the model there) | yes — moves with the plot |
| `CustomerSystem`, `PlotUtils` | `Restaurant.EntranceMarker` (relative to the build) | yes |
| `PlazaTeleportSystem` | `Hub.PlazaTeleportPoint` | yes — just move the part |
| `TravelSystem` | `Hub.TravelBoard…`, `NewYork…` | yes |
| `WorldDress.dressHub` | reads each `PlotFloor.Position` for the per-plot arch / hedge / trees | **auto-follows** — only the hard-coded avenue / cross-garden / fountain positions need retuning (≈30 lines) |

### Migration

- Existing players' saved data is money + upgrade levels + menu — all
  position-independent, so **no data migration**.
- Do it behind a flag or on a fresh place copy, playtest the six spawn points
  and customer pathing, then swap.

---

## If we don't

The garden pass already makes the current corridor a pleasant place — numbered
entry arches for wayfinding, a fountain square, the back dead-end turned into a
sitting garden. The re-layout is an upgrade, not a fix.
