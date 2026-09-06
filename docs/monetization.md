# Monetization Plan — Eat the World

**Game:** Eat the World (Roblox restaurant tycoon)
**Status:** Design + pricing + policy call. Drives implementation by roblox-scripter and roblox-ui-artist.
**Author:** roblox-monetization

This doc replaces the placeholder shop (`src/shared/Data/ShopCatalog.luau`: 3 cash products + 2 passes). It specifies a wide catalog, prices it against comparable top games, draws the pay-to-skip / pay-to-win line for this specific game, and flags what to exclude on policy grounds.

---

## 0. Context: how the current economy actually works

Read before pricing anything.

| Lever | Current value | Source |
|---|---|---|
| Starting money | $250 | `PlotManager.STARTING_MONEY` |
| Pizza roll cost | $50 | `Foods/Pizza.luau` `Price` |
| Customer payout | `BaseRestaurantValue (25) × variant ValueMultiplier × TipMultiplier × MoneyMultiplier` | `CustomerSystem.runCustomerVisit` |
| Variant multipliers | Common 1 / Uncommon 2 / Rare 5 / Epic 12 / Legendary 30 / Secret 100 | `Foods/Pizza.luau` |
| Roll odds | Common 70 / Uncommon 20 / Rare 7 / Epic 2.5 / Legendary 0.45 / Secret 0.05 | `RarityTable.luau` |
| Seats per plot | Stage 1: 4 / Stage 2: 6 / Stage 3: 8 (2 chairs per table) | `UpgradeCatalog.KitchenStage.TableCounts` × `CHAIR_NAMES` |
| Customer spawn | every 5–9 s per plot | `CustomerSystem.SPAWN_INTERVAL_*` |
| Eat time | 14–20 s at Kitchen Speed L1, down to ~0.4× at L10 | `CustomerSystem.BASE_EAT_TIME_*` × `Upgrades.GetEatSpeedMultiplier` |
| Autosave | every 120 s (plus on leave / BindToClose) | `PlotManager.AUTOSAVE_INTERVAL` |

**The loop:** pay $50 → roll a rarity → the eaten pizza becomes a *permanent* menu item → every customer who orders it pays out forever. One good roll is a permanent income asset. Curating the menu (only slotting Uncommon+ items) is the core skill.

**Cost to fully max a plot from scratch (free progression):**

| Track | Levels | Total cost |
|---|---|---|
| Restaurant Size | L1→L3 | $2,500 |
| Kitchen Speed | 10 | ~$9,300 |
| Luck | 10 | ~$11,300 |
| Customer Tips | 10 | ~$11,300 |
| Menu Slots | 5 | ~$3,950 |
| **Total** | | **~$38,400** |

Rough early earn rate at Stage 1 (4 seats, uncurated menu): **$40–80/min**. A curated Uncommon+ menu at Stage 3 with Tips/Speed maxed is several hundred $/min.

**Two consequences that drive every decision below:**

1. **The pizza roll is a "paid random item" the moment cash packs ship.** Money is purchasable with Robux (cash packs) and money buys rolls. Roblox's Paid Random Items policy explicitly covers "indirect purchases like spin tickets." See §7.
2. **The existing `$75,000 Cash` product hands a player ~2× the entire cost of maxing their restaurant in one purchase.** That deletes progression for that player. It must be rescaled (§3, §4).

---

## 1. Full proposed catalog

Prices are in Robux (R$). Every game pass is gated server-side by `MarketplaceService:UserOwnsGamePassAsync` (the `Shop.OwnsPass` pattern already in `Shop.luau`). Every developer product is granted only in `MarketplaceService.ProcessReceipt` (the pattern already in `Shop.luau`), never on a client signal. Client code only ever *prompts* (`PromptProductPurchase` / `PromptGamePassPurchase`) — see §6 guardrail.

### 1a. Permanent boosts — Game Passes

| # | Name | Price | Mechanic | Hooks into | Comparables |
|---|---|---|---|---|---|
| P1 | **2× Money** *(exists)* | **249** | All customer payouts ×2 (additive +1.0 to the money-multiplier sum) | `Shop.GetMoneyMultiplier` → `CustomerSystem` value calc | Mall Tycoon 2× Cash 600 (high end); typical tycoon 99–299 |
| P2 | **2× Luck** *(exists, "coming soon")* | **299** | Doubles the player's Luck-upgrade bonus in the roll (adds up to +0.8 `luckBonus`) | `PizzaVendor` roll → `Upgrades.GetLuckBonus` / `RarityRoller.Roll` | Clicking Legends 2× Luck 440; others ~199 |
| P3 | **Richer Customers** | **149** | Customer payouts +40% (additive +0.4) | same as P1 | Mall Tycoon Extra Tips 180; My Restaurant "Richer Customers" |
| P4 | **VIP** (bundle) | **499** | +25% money, +1 menu slot over cap, VIP nametag + chef-hat cosmetic, VIP food color variants (cosmetic only) | `Shop.GetMoneyMultiplier` (+0.25), `Upgrades.GetMaxMenuSlots` (+1), cosmetic system | Mall Tycoon VIP 800; Pet Store Tycoon 2 VIP 250; typical 199–499 |
| P5 | **Extra Menu Slots** | **199** | +2 permanent menu slots above the L5 upgrade cap (8 → 10) | `Upgrades.GetMaxMenuSlots` | generic slot passes ~150–250 |
| P6 | **Sous Chef** (auto-bite) | **399** | Server auto-consumes the pizza the owner is holding, no prompt spam; still one menu item per pizza, still costs $50/roll | `EatingSystem` bite loop | My Restaurant Auto Collect 400; Mall Tycoon Auto Collect 350 |
| P7 | **Golden Touch** (cosmetic) | **249** | Gold building trim, gold customer models, sparkle VFX on payout. Zero stat effect | cosmetic system | cosmetic theme passes 150–350 |
| P8 | **Restaurant Mascot** (cosmetic) | **199** | A mascot NPC that idles/walks the plot. Zero stat effect | cosmetic NPC spawner | pet/mascot cosmetic passes 100–250 |

### 1b. Consumable boosts — Developer Products (timed / one-shot)

| # | Name | Price | Mechanic | Hooks into |
|---|---|---|---|---|
| D1 | **2× Money — 30 min** | **49** | Adds +1.0 to money-multiplier sum until `now + 1800` | persisted `MoneyBoostExpiry` attr → `Shop.GetMoneyMultiplier` |
| D2 | **3× Money — 30 min** | **99** | Adds +2.0 until expiry | same |
| D3 | **2× Luck — 60 min** | **79** | Adds +0.4 `luckBonus` until expiry. **Probability modifier — odds UI must update (§7)** | persisted `LuckBoostExpiry` → roll |
| D4 | **Rush Hour — 15 min** | **79** | Spawn interval → 2–3 s and every empty seat fills immediately | `CustomerSystem.SPAWN_INTERVAL_*` + one-time seat fill, gated on `RushExpiry` |
| D5 | **Full House** (one-shot) | **25** | Instantly seats one paying customer at every currently-empty seat, once | `CustomerSystem` — spawn a visit per free seat |
| D6 | **10× Lucky Rolls** | **99** | Next 10 rolls get +0.4 `luckBonus`. **Probability modifier — odds UI must update (§7)** | persisted `LuckyRollsRemaining` counter → `PizzaVendor` |

### 1c. Cash packs — Developer Products

Rescaled so no single purchase erases progression. Framed as **time saved**, never as "free."

| # | Name | Grant | Price | ≈ play time skipped (early game) |
|---|---|---|---|---|
| C1 | **Snack Fund** | $2,500 | **49** | ~40 min |
| C2 | **Lunch Rush Fund** | $10,000 | **149** | ~2–4 hr |
| C3 | **Franchise Fund** | $50,000 | **599** | ~1 week casual |
| C4 | **Empire Fund** | $150,000 | **1,499** | whale tier; still below "buy 2 maxed plots" |

> Retire the current `$75,000 Cash` (`money_large`) SKU as-is. If you keep three tiers instead of four, use C1/C2/C3.

### 1d. Cosmetics — Developer Products

All zero stat effect. Safest category on Roblox; ship as art lands.

| # | Name | Price | Notes |
|---|---|---|---|
| X1 | Food skins (Rainbow Pizza, Pixel Pizza, …) | 99–149 | reskin of a menu item's appearance, `ValueMultiplier` untouched |
| X2 | Restaurant themes (Diner / Neon / Cottage / Sci-Fi) | 199–299 | floor, wall, lighting, prop pack |
| X3 | Customer skin packs (Robots, Animals, Aliens) | 149 | swaps `createCustomerModel` visuals |
| X4 | Chef emote / animation pack | 79 | |
| X5 | Billboard / nameplate styles | 79 | restyles `SignPost.Nameplate` |

### 1e. Convenience / QoL

| # | Name | Type | Price | Mechanic |
|---|---|---|---|---|
| Q1 | **Sous Chef** (= P6) | pass | 399 | listed above |
| Q2 | **Extra Menu Slots** (= P5) | pass | 199 | listed above |
| Q3 | **Restaurant Rename** | product | 49 | only if custom restaurant names ship (today the name is the player name) — **hold** |

### 1f. Gacha / roll-related

| # | Name | Verdict |
|---|---|---|
| G1 | 2× Luck pass (P2), timed luck (D3), Lucky Rolls (D6) | **Ship — with full odds disclosure + PolicyService gating (§7).** Probability-modifier items on an *already-disclosed* roll. |
| G2 | **Paid "Mystery Food Crate"** (Robux → random menu item) | **Cut at launch.** A dedicated paid loot box aimed at a young audience is the highest-scrutiny mechanic on Roblox right now (Korea-driven global odds-disclosure rollout, June 2026). If revisited it needs full odds UI, `PolicyService` restriction checks, no pity-timer countdown, no minor-targeted marketing. |
| G3 | **Guaranteed Legendary / Secret roll for Robux** | **Cut.** A guaranteed top-tier outcome is not "random" — it sells a ×30–×100 income item directly for Robux. Pay-to-win against pacing. |
| G4 | **Sell a specific high-value menu item directly** | **Cut.** Same reason as G3. |

---

## 2. Category safety summary

| Category | Items | Risk | Call |
|---|---|---|---|
| Permanent money passes | P1, P3, P4 | Low — no PvP, per-plot economy. Pay-to-skip. | **Safe.** Keep multiplier ceiling bounded (§5). |
| Permanent luck pass | P2 | Medium — probability modifier | **Safe with §7 work.** |
| Permanent QoL passes | P5, P6 | Low | **Safe.** |
| Cosmetic passes | P7, P8 | Very low | **Safe.** |
| Timed money/throughput boosts | D1, D2, D4, D5 | Low | **Safe.** |
| Timed / count luck boosts | D3, D6 | Medium — probability modifier | **Safe with §7 work.** |
| Cash packs | C1–C4 | Medium — can trivialize a player's own progression; makes the roll a paid random item | **Safe if rescaled (done) + §7 done.** Retire the $75k SKU. |
| Cosmetics | X1–X5 | Very low | **Safe.** |
| Dedicated paid loot box | G2 | High | **Cut.** |
| Direct sale of RNG outcomes / guaranteed rares | G3, G4 | High — pay-to-win + policy | **Cut.** |
| Permanent seat-cap raiser ("Bigger Restaurant Pass") | — | High — income ceiling free players can't reach | **Cut / rework** (§3). |

---

## 3. Economy-balance analysis (does it break free progression?)

**The pay-to-skip / pay-to-win line for this game:** there is no PvP and every player has their own plot, so nothing a buyer does mechanically harms another player. "Pay-to-win" here collapses into **"pay to skip past the game's own pacing so hard that retention dies"** plus **"gate content behind Robux that free players can't reach."** Judge every item against those two.

| Item | Breaks free progression? | Verdict |
|---|---|---|
| P1 2× Money / P3 Richer Customers | No. Free players still earn; buyers just reach Stage 3 faster. Loop structure unchanged. | Keep |
| P2 2× Luck | No. Caps at +0.8 `luckBonus`; `RarityRoller` floors Common weight at 20% of original, so even stacked luck (§5) keeps Secret ≈0.14%. Doesn't hand out rares. | Keep |
| P4 VIP | No. +25% money and +1 slot are modest; cosmetics are the headline. | Keep |
| P5 Extra Menu Slots (+2) | No. Free cap is 8; +2 is variety/expression, marginal income. | Keep |
| P6 Sous Chef | No. Removes clicking, not cost. Still $50/roll, one item per pizza. Pure QoL. | Keep |
| P7/P8/X1–X5 cosmetics | No. Zero stat effect. | Keep |
| D1–D6 timed boosts | No. Expire. A player who never buys them still maxes out. | Keep |
| C1 $2,500 | No. ~40 min of play. | Keep |
| C2 $10,000 | Barely. ~1/4 of a full max. Acceptable meaningful skip. | Keep |
| C3 $50,000 | Yes-ish. Exceeds a full max ($38.4k). "Skip most of the mid-game" tier — acceptable only because there is no competitive ladder and content beyond maxing (new food areas) is planned. Watch retention. | Keep, monitor |
| C4 $150,000 | Yes for one plot. Justified only as an explicit whale SKU; still can't buy a second plot or exclusive content. | Keep, monitor |
| **$75,000 SKU (current)** | Yes — ~2× full max in one tap. | **Cut / replace with C1–C4** |
| **"Bigger Restaurant Pass" (Stage 4, 10 seats)** | **Yes — crosses the line.** Income scales with seats; a permanent seat count free players can't reach is a Robux-gated income ceiling = pay-to-win against pacing. | **Cut.** If wanted: make it a **cosmetic-only** grander building at the same 8 seats, OR first add a free grind-gated Stage 4 so the pass becomes a pay-to-*skip*. |
| G3/G4 guaranteed / direct rares | Yes — buys the ×30–×100 income asset outright. | **Cut** |

**Leaderboard caveat (future work):** the moment a global "richest restaurant" or "total earnings" leaderboard is added, every money multiplier and cash pack becomes pay-to-win *for rank*. If you add leaderboards: rank on a **non-purchasable** stat (lifetime customers served, distinct rare foods discovered), or bucket paying vs non-paying, or make the board opt-in/cosmetic. Do **not** rank on total earnings / net worth.

---

## 4. Interrupted-purchase / pending-item handling

**Current bug in `Shop.luau` `ProcessReceipt` (load-bearing — hand to roblox-scripter):**

1. It is **not idempotent.** No record of handled `receiptInfo.PurchaseId` is kept. Roblox re-calls `ProcessReceipt` on a later session for any receipt not yet confirmed `PurchaseGranted`; a grant that isn't deduped can double-pay.
2. It returns `PurchaseGranted` **before the grant is durably persisted.** Money only persists on the 120 s autosave or on leave (`PlotManager`). If the server crashes between `Economy.Add` and the next autosave, the player paid Robux and lost the cash — the game silently stole Robux from them.

**Required pattern for every developer product:**

```
ProcessReceipt(receiptInfo):
  key = receiptInfo.PlayerId .. ":" .. receiptInfo.PurchaseId
  if handledSet[key] then return PurchaseGranted            -- idempotent replay
  player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
  if not player then return NotProcessed                    -- retry next session
  apply grant (cash / set boost expiry / increment counter / one-shot effect)
  ok = forceSavePlayerData(player)  -- immediate DataStore write, not the autosave
  if not ok then
      roll back the in-memory grant
      return NotProcessed                                   -- Roblox retries
  handledSet[key] = true ; persist handledSet in the player's DataStore record
  return PurchaseGranted
```

Per-product specifics:

| Product | On offline receipt | On rejoin replay | Persist |
|---|---|---|---|
| C1–C4 cash | `NotProcessed` (no player) | grant $, force-save, then confirm | `Money` + `handledPurchases` set |
| D1/D2 money boost | `NotProcessed` | set/extend `MoneyBoostExpiry = max(now, existing) + 1800`, force-save | `MoneyBoostExpiry` in the DataStore record so a boost bought 5 s before a disconnect survives rejoin |
| D3 luck boost | `NotProcessed` | set/extend `LuckBoostExpiry`, force-save | `LuckBoostExpiry` persisted |
| D4 Rush Hour | `NotProcessed` | set `RushExpiry`, force-save | persisted |
| D5 Full House | `NotProcessed` (needs a loaded plot to apply) | apply once on the loaded plot, force-save the dedupe key | `handledPurchases` only |
| D6 Lucky Rolls | `NotProcessed` | `LuckyRollsRemaining += 10`, force-save | `LuckyRollsRemaining` persisted, decremented per roll and saved |
| X1–X5 cosmetics | `NotProcessed` | add cosmetic id to owned set, force-save | `ownedCosmetics` set persisted |

Boost-expiry timestamps: store as absolute `os.time()` values in the DataStore record. On join, `PlotManager.loadPlayerData` reads them back; a boost whose expiry is still in the future resumes with correct remaining time. Game passes (P1–P8) need none of this — ownership lives on Roblox's servers and `UserOwnsGamePassAsync` is the source of truth every session.

**Client guardrail:** `PromptGamePassPurchaseFinished` / `PromptProductPurchaseFinished` on the client must **only** refresh UI, never grant. `ShopPlazaUI` today correctly only prompts — keep it that way; document it so no one "optimizes" by granting on the client callback.

---

## 5. Money-multiplier & luck stacking (keep the ceiling bounded)

`Shop.GetMoneyMultiplier` currently loops the catalog and early-returns `2` or `1`. Refactor to **sum additive bonuses**:

```
multiplier = 1
           + (owns P1 2xMoney      and 1.0 or 0)
           + (owns P3 RicherCust   and 0.4 or 0)
           + (owns P4 VIP          and 0.25 or 0)
           + (isPremium            and 0.10 or 0)
           + (now < MoneyBoostExpiry and boostAmount or 0)   -- 1.0 (D1) or 2.0 (D2)
```

Worst-case stack: `1 + 1.0 + 0.4 + 0.25 + 0.10 + 2.0 = 4.75×`. Fine for a solo tycoon — a maxed free player at Stage 3 already out-earns an un-upgraded buyer.

Luck: `luckBonus = upgradeBonus (≤0.8) + (P2 ? upgradeBonus : 0) + (D3 active ? 0.4 : 0) + (D6 rolls left ? 0.4 : 0)`, worst case ≈ 2.4. `RarityRoller` already caps the Common→rare shift at 80% of Common's weight (`maxShift = min(weights[common] * 0.8, luckBonus * total)`), so Secret tops out ≈0.14% (from 0.05%). Luck accelerates Uncommon/Rare, never trivializes the top tiers — desired shape, no change to `RarityRoller`.

---

## 6. Roblox Premium (Creator Rewards / engagement-based payouts)

Premium Payouts became **Creator Rewards / engagement-based payouts** (rolled out 2025). You earn a share of a Robux pool proportional to the Premium playtime your game captures; ~28-day reporting delay. 2026 weighting favors **high-retention niche games** — a curation-driven tycoon fits well, so retention work pays double: passive Robux **plus** better pass conversion.

**Enable it:** publish, opt in on the Creator Dashboard. No gameplay code needed for the payout itself.

**Premium-only perks (non-tactical, per Roblox guidance — no competitive edge, no "paywall" modal on join, describe honestly in the game description):**

| Perk | Detail | Hook |
|---|---|---|
| Premium daily bonus | +$500 on first login each day | `player.MembershipType == Enum.MembershipType.Premium`, once-per-day gate in DataStore |
| Small money bump | +10% money (folded into the §5 sum) | `Shop.GetMoneyMultiplier` |
| +1 menu slot | stacks with P5 | `Upgrades.GetMaxMenuSlots` |
| "Premium Chef" cosmetic | gold nametag + hat, distinct from VIP's | cosmetic system |

Do **not**: promise out-of-game rewards, show a Premium upsell modal when a non-Premium player joins, or give Premium a mechanic non-Premium players can't compete with. The +10%/+1 slot is deliberately at/below the paid Richer-Customers and Extra-Slots passes so it's a nudge, not a wall.

---

## 7. Paid Random Items compliance (REQUIRED before cash packs ship)

Because cash packs sell Money and Money buys pizza rolls, the roll is a **paid random item generator** under Roblox's Paid Random Items policy ("indirect purchases like spin tickets" are explicitly covered). This is true even if you never build a single "luck" SKU — **shipping C1–C4 alone triggers it.**

Required, hand to roblox-scripter + roblox-ui-artist:

1. **Odds disclosure UI, shown before the player commits to a roll.** The `RarityTable` percentages already exist — surface them. All outcomes listed, percentages summing to exactly 100%, reachable from the New York pizza stand (an "Odds" / "Details" button on the order prompt UI or `FoodRevealUI`).
2. **Dynamic odds.** When any luck source is active (Luck upgrade, P2, D3, D6), the displayed odds must update to the modified values (compute from `RarityRoller`'s weight-shift math). Probability-modifier SKUs (P2, D3, D6) must show the *new* odds before purchase.
3. **`PolicyService:GetPolicyInfoForPlayerAsync`** on join:
   - `ArePaidRandomItemsRestricted == true` → block that user from the paid path. Simplest compliant option: hide C1–C4, P2, D3, D6 from the shop for restricted users and let them play the free loop normally.
   - `IsPaidItemTradingAllowed` — Eat the World has no trading, so nothing to do, but don't add food/menu trading later without re-checking this flag.
4. **No dark patterns around the roll:** no countdown timers on the featured slot, no "only N left", no "free spin" language, no near-miss animations engineered to look like an almost-legendary. `FoodRevealUI` should show the true result plainly.

If the owner wants to **avoid this entire workstream**, the alternative is: **don't sell Money for Robux at all.** Monetize only passes P4–P8, cosmetics X1–X5, throughput boosts D1/D2/D4/D5, and Sous Chef. That removes C1–C4, P2, D3, D6 and the roll stops being a paid random item. It leaves meaningful revenue on the table but is the lowest-risk configuration. **Recommendation: do the compliance work — the odds UI is cheap and cash packs are a large revenue share in this genre.**

---

## 8. Items flagged and EXCLUDED

| Excluded | Why |
|---|---|
| `$75,000 Cash` SKU as currently specced | One tap ≈ 2× the full cost of maxing a plot. Deletes the player's own progression. Replaced by rescaled C1–C4. |
| "Bigger Restaurant Pass" (permanent Stage 4 / 10 seats) | Robux-gated permanent income ceiling free players can't reach = pay-to-win against pacing. Allowed only as a cosmetic-only building or after a free Stage 4 exists. |
| Guaranteed Legendary/Secret roll for Robux (G3) | Not random — sells a ×30/×100 income asset directly. Pay-to-win. |
| Direct sale of specific high-value menu items (G4) | Same as G3. |
| Dedicated paid "Mystery Food Crate" loot box (G2) | Highest-scrutiny mechanic on Roblox for a young audience; global odds-disclosure crackdown in 2026. Incremental revenue not worth the moderation/review risk. |
| Countdown timers / "only 2 left" / "limited stock" on the shop featured slot | Fake scarcity dark pattern; pressures minors; violates Community Standards. The existing random `rollFeaturedItem` is fine **only** if it never shows a timer or stock count. |
| Any SKU or button labeled or implied "FREE" that costs Robux or currency | Deceptive "free" framing is explicitly disallowed. |
| First-purchase "everyone's watching" / social-pressure popups, spin-to-win on join, "your friends bought this" nags | Manipulative patterns targeting minors. |
| Selling Robux-priced removal of an artificially harsh penalty ("customers leave angry unless you pay") | Designing a problem to sell the cure = dark pattern. Keep the free loop genuinely playable. |

---

## 9. Prioritized rollout

Ordered by revenue-per-effort. Each row: what changes for **roblox-scripter** / **roblox-ui-artist**.

### Phase 1 — ship with launch (mostly wiring existing patterns)

| Item | roblox-scripter | roblox-ui-artist |
|---|---|---|
| **RNG odds disclosure + `PolicyService` gate** (blocker for C/P2/D3/D6) | Add `PolicyService` check on join; compute modified odds from `RarityRoller` weights; expose an odds table via a remote or shared module | New "Odds" panel on the pizza-stand order UI / `FoodRevealUI`; live-updates when luck is active |
| **P1 2× Money** (repriced 249) | Create real pass on dashboard, swap `ProductId` in `ShopCatalog`; refactor `Shop.GetMoneyMultiplier` to the additive sum (§5) | Update shop row copy/price |
| **C1–C4 cash packs** (retire $75k) | Create 4 products; extend `CASH_GRANTS`; implement idempotent + force-save `ProcessReceipt` (§4) | Replace the 3 cash rows; add 4th; "time saved" framing copy, no "free" |
| **P2 2× Luck** (299, remove "coming soon") | Wire pass into `luckBonus` in `PizzaVendor`; update `ShopCatalog` desc + real `ProductId` | Update row copy; ensure odds panel reflects it |
| **ProcessReceipt hardening** | Idempotency set + immediate DataStore save + rollback-on-fail (§4); persist `handledPurchases` in `PlotManager` record | — |

### Phase 2 — fast follow (2–4 weeks)

| Item | roblox-scripter | roblox-ui-artist |
|---|---|---|
| **P3 Richer Customers** (149) | Add +0.4 branch to the money-multiplier sum; catalog entry | Shop row |
| **P5 Extra Menu Slots** (199) | `+2` in `Upgrades.GetMaxMenuSlots` when owned; catalog entry | Shop row; menu book shows "10 (max)" |
| **P4 VIP** (499) | Money +0.25, menu +1, cosmetic flags; catalog entry | Shop row + VIP nametag/hat art; VIP tab |
| **D1/D2 money boosts** (49/99) | `MoneyBoostExpiry` attr, persisted; read in the multiplier sum; `ProcessReceipt` cases | Shop rows; small active-boost timer chip on HUD |
| **D3 luck boost** (79) + **D6 Lucky Rolls** (99) | `LuckBoostExpiry` / `LuckyRollsRemaining`, persisted; feed `luckBonus`; decrement per roll and save | Shop rows; odds panel + HUD chip show them active |
| **D4 Rush Hour** (79) + **D5 Full House** (25) | `RushExpiry` gate in `CustomerSystem` spawn loop; one-shot seat fill; `ProcessReceipt` cases | Shop rows; "Rush Hour!" HUD banner while active |

### Phase 3 — cosmetics + Premium (as art lands)

| Item | roblox-scripter | roblox-ui-artist |
|---|---|---|
| **P6 Sous Chef** (399) | Auto-consume held pizza server-side for owners; catalog entry | Shop row; small "auto" toggle on HUD |
| **Premium perks** (§6) | `MembershipType` checks: daily bonus (DataStore day-gate), +10% money, +1 slot, cosmetic flag | "Premium Chef" cosmetic; optional non-intrusive Premium badge in shop |
| **P7 Golden Touch / P8 Mascot** (249 / 199) | Cosmetic ownership set (persisted); mascot NPC spawner | Gold building/customer/VFX set; mascot model |
| **X1–X5 cosmetic products** | `ownedCosmetics` set + apply on join; `ProcessReceipt` cases | The skins/themes/packs; a "Cosmetics" shop tab with preview |

### Phase 4 — only alongside new content

- Instant "max one track" products, Restaurant Rename (Q3), additional food-area cash sinks. Revisit the "Bigger Restaurant" question **only** after a free Stage 4 or a second food area exists, and re-run §3 against a leaderboard if one is added.

---

## 10. Files this plan touches

- `src/shared/Data/ShopCatalog.luau` — full catalog rewrite (real `ProductId`s once created on the Creator Dashboard)
- `src/server/Modules/Shop.luau` — additive multiplier sum; idempotent + force-save `ProcessReceipt`; boost-expiry reads; `PolicyService` result cache; cosmetic ownership
- `src/server/Modules/Upgrades.luau` — `GetMaxMenuSlots` reads P5/VIP/Premium; luck consumers read P2/D3/D6 (or a new `Shop.GetLuckBonus` wrapper)
- `src/server/CustomerSystem.server.luau` — value calc already calls `Shop.GetMoneyMultiplier`; add Rush Hour spawn gate + Full House hook
- `src/server/PizzaVendor.server.luau` — fold luck boosts into `luckBonus`; decrement `LuckyRollsRemaining`; `PolicyService` gate on the paid path
- `src/server/EatingSystem.server.luau` — Sous Chef auto-consume
- `src/server/PlotManager.server.luau` — persist `MoneyBoostExpiry`, `LuckBoostExpiry`, `RushExpiry`, `LuckyRollsRemaining`, `handledPurchases`, `ownedCosmetics`; expose a `forceSave(player)` for `ProcessReceipt`
- `src/client/ShopPlazaUI.client.luau` — render new categories/tabs; **no grant logic**; no countdowns on the featured slot
- `src/client/FoodRevealUI.client.luau` / pizza-stand UI — odds disclosure panel
- New: cosmetics module, HUD boost-timer chip, VIP/Premium cosmetic assets

---

## Sources / comparables

- [Mall Tycoon game passes (Fandom)](https://mall-tycoon-roblox.fandom.com/wiki/Gamepasses) — 2× Cash 600, Auto Collect 350, Extra Tips 180, VIP 800
- [My Restaurant! (Roblox Wiki / Fandom)](https://roblox.fandom.com/wiki/BIG_Games%E2%84%A2/My_Restaurant!) — Auto Collect Money 400, Golden Wishing Well 500, Richer Customers / restaurant size / money tree passes
- [My Restaurant game pass guide 2026](https://earnaldo.com/blog/my-restaurant-free-robux-guide)
- [Best game passes for a tycoon — Roblox DevForum](https://devforum.roblox.com/t/best-gamepasses-for-a-tycoon/485468)
- [2× Luck Gamepass — Clicking Legends (Fandom)](https://roblox-clicking-legends.fandom.com/wiki/2x_Luck_Gamepass) — 440 R$
- [Pet Store Tycoon 2 VIP (Rolimon's)](https://www.rolimons.com/gamepass/273070575) — 250 R$
- [How to Price Game Passes on Roblox (creation.dev)](https://www.creation.dev/learn/how-to-price-game-passes-roblox)
- [Roblox Game Pass Pricing Guide 2026 — retention (ugccraft)](https://ugccraft.com/blog/roblox-game-passes-pricing-guide/)
- [Paid Random Items policy — Roblox Creator Hub](https://create.roblox.com/docs/production/monetization/paid-random-items)
- [Clarifying Requirements for Paid Random Items — Roblox DevForum](https://devforum.roblox.com/t/clarifying-requirements-for-paid-random-items/4654622)
- [Korea's loot-box rules push Roblox to disclose item odds worldwide (TechTimes, 2026)](https://www.techtimes.com/articles/319148/20260626/koreas-loot-box-rules-push-roblox-disclose-item-odds-worldwide.htm)
- [Engagement-based payouts — Roblox Creator Hub](https://create.roblox.com/docs/production/monetization/engagement-based-payouts)
- [Roblox Premium Payouts Explained 2026 (rblxtax)](https://rblxtax.com/blog/roblox-premium-payouts-explained)
