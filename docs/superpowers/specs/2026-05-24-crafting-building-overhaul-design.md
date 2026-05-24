# Crafting & Building Overhaul — Design

**Date:** 2026-05-24
**Status:** Approved (pending spec review)
**Scope:** Monolithic single-PR overhaul. One unified implementation, staged internally for compilable intermediate commits.

---

## 1. Vision & Goals

### Vision

Crafting and building become the gravitational center of progression. Players restore Town Square's stations to earn back its hub status, then expand their reach by building tiered and specialist stations across exploration zones. Every craft is a small loot moment (quality + affixes), every blueprint scroll is a discovery, and stations work for the player in parallel — set a queue, go gather, come back to a fresh haul.

### Goals (priority order)

1. **Make building essential.** Town Square stations start broken; players must restore them. All crafting requires a station — no free crafting anywhere by default.
2. **Make crafting decision-rich.** Quality variance with affixes, optional modifiers, and ingredient substitution turn "should I craft now or wait/improve?" into a real question.
3. **Reduce tap fatigue.** Per-station queues run in parallel — the player can gather while their kitchen and bench produce.
4. **Improve discoverability.** A dedicated Workshop tab replaces the Build tab; recipes browsable by skill, category, station, and known status, with search.
5. **Reward exploration.** Rare/legendary recipes drop as blueprint scrolls from gathering, beasts, and zone exploration.

### Non-goals

- No save/persistence work (the game currently doesn't persist; out of scope).
- No quality propagation through gathered resources (resource items stay tierless; quality only applies to crafted outputs).
- No new combat or zone content beyond drop-table additions.
- No changes to skill XP curves or the masterwork trial system.

---

## 2. Data Model

### 2.1 Quality & Affixes

Quality is a property of crafted items. Resources, raw drops, and shop-bought goods remain plain (no quality).

**New enum `QualityTier`:** `crude`, `standard`, `fine`, `masterwork`.

Stat multiplier and affix count per tier:

| Tier | Multiplier | Affix count |
|---|---|---|
| Crude | 0.75× | 0 |
| Standard | 1.00× | 0 |
| Fine | 1.25× | 1 |
| Masterwork | 1.60× | 2 |

The multiplier scales the item's combat stats (attack, defense), tool bonuses (speedBonus, successBonus), and food restoration (healAmount, energyAmount). Gold `value` also scales (Masterwork sells for ~1.6× a Standard).

**New class `Affix`** (constant pool, ~12 entries):

```dart
class Affix {
  final String id;           // 'keen', 'reinforced', ...
  final String name;
  final String description;
  final Set<ItemType> appliesTo;
  final AffixEffect effect;
}
```

Initial pool (12 affixes; subject to balance pass):

| Affix | Applies to | Effect |
|---|---|---|
| Keen | weapon | +10% attack |
| Brutal | weapon | +1 flat attack |
| Tempered | armor | +15% defense |
| Reinforced | armor | +1 flat defense |
| Swift | tool | +5% speed bonus |
| Lucky | tool | +5% success bonus |
| Ergonomic | tool | -1 energy when used (floor 0) |
| Hearty | food | +25% heal |
| Invigorating | food | +25% energy |
| Valued | any | +25% gold value |
| Sturdy | tool | +10% to both speed and success bonuses |
| Plentiful | food | +1 to a stack consumed at once (UI flourish: "double bite") |
| Frugal | any | -10% energy cost when this item is used/consumed |

Two affixes on a Masterwork item must be distinct. Affix pool is uniform random in v1 (no weights — easy to tune later).

**New class `CraftedItem`** (the inventory unit for items with quality):

```dart
class CraftedItem {
  final String itemId;       // base Item.id
  final QualityTier quality;
  final List<String> affixIds; // 0..2, sorted by id for stacking
}
```

### 2.2 Recipe rework

```dart
class Recipe {
  final String id;
  final String name, icon, description;
  final String resultItemId;
  final int resultQuantity;
  final SkillType requiredSkill;
  final int requiredLevel;
  final double xpReward;
  final int energyCost;
  final int durationSeconds;

  // NEW
  final List<RecipeSlot> inputs;          // replaces Map<String,int>
  final RecipeSlot? modifierSlot;          // optional modifier
  final String stationId;                  // which station hosts this
  final int requiredStationTier;           // 1, 2, or 3
  final RecipeRarity rarity;               // common | rare | legendary
}

class RecipeSlot {
  final int quantity;
  final List<SlotChoice> acceptedItems;    // ordered list; index 0 = canonical (+0 bias)
}

class SlotChoice {
  final String itemId;
  final double qualityBias;                // e.g. +0.03 for willow_log substituting oak_log; -0.10 for a below-canonical substitute
}

enum RecipeRarity { common, rare, legendary }
```

**Substitution:** A slot lists multiple accepted item ids. The first is canonical (+0 bias). Subsequent ids are typically "better" (positive bias, e.g. +0.03 for using willow_log where oak_log is canonical). A few recipes also list "worse" substitutes with negative bias (e.g. -0.10) so early-game players can craft without the canonical material.

**Modifier slot:** Optional. When filled at queue time, the modifier item is consumed regardless of craft outcome. Effects (one per modifier):

| Modifier item | Effect |
|---|---|
| `wildflower` | **Bonus XP** — +50% XP on this craft |
| `nightshade` | **Force affix** — picks a random affix for the result regardless of quality tier |
| `river_clay` | **Save materials** — 30% chance to refund all required inputs |
| `wild_berries` | **Quality floor** — guarantees Standard or better |
| `troll_claw` | **Force Fine floor** — guarantees Fine or better |
| `boar_tusk` | **Extra quantity** — output count +1 |

### 2.3 Blueprint scrolls

**New `ItemType.blueprint`.** A blueprint item carries a `recipeId`. The player tapping "Learn" on a blueprint consumes it and adds the recipe id to `_knownRecipeIds`.

A recipe is visible/usable when:

- `recipe.rarity == common` AND player meets the skill-level requirement, OR
- `recipe.id ∈ _knownRecipeIds` (learned via blueprint)

Starter set: all `common` recipes are auto-known once their skill-level requirement is met. Rare and legendary recipes are blueprint-gated.

Drop tables on existing zone actions and beast loot tables get optional `blueprint: true` LootDrop entries (low chance, ~1–3%). Zone tier gates which blueprints can drop (Tier 1 zones drop tier-1 blueprints, etc.). New `Blueprint` Item subclass carries a `recipeId` field.

### 2.4 Station model

`Structure` is renamed `Station` and gains a tier ladder.

```dart
class Station {
  final String id;
  final String name, icon, description;
  final SkillType primarySkill;
  final List<SkillType> enabledSkills;     // bench enables crafting + lore
  final int maxTier;                       // typically 3
  final List<StationTier> tiers;
}

class StationTier {
  final int tier;
  final Map<String, int> upgradeCost;      // mats to go from prev tier → this tier
  final int upgradeDurationSeconds;
  final int upgradeEnergyCost;
  final int requiredSkillLevel;
  final double qualityBias;                // tier 1 = +0.00, tier 2 = +0.05, tier 3 = +0.12
  final int queueSlots;                    // tier 1 = 1, tier 2 = 2, tier 3 = 3
  final double speedBonus;                 // tier 1 = +0%, tier 2 = +10%, tier 3 = +20%
}
```

**Station roster:**

| Station | Skills enabled | Notes |
|---|---|---|
| Crafting Bench | crafting, lore | Existing. Tier ladder added. |
| Field Kitchen | cooking, herbalism (basics only) | Existing. Tier ladder added. |
| Outpost Shelter | — (resting only) | Existing. Single-tier; no queue; behavior preserved. |
| **Smelter** | crafting (ingot recipes) | New. Gates all metal-ingot intermediates. |
| **Tannery** | crafting (leather processing) | New. Gates cured_leather, treated_silk. |
| **Apothecary** | herbalism (advanced) | New. Gates Elixir II/III + future high-tier potions. Moves these out of Field Kitchen. |

**Town Square restoration:** Town Square has a pre-placed Bench T1 and Kitchen T1 in **Ruined** state from game start. A `restorationCost` (mats + duration + energy) brings each from ruined → tier 1. Once restored, they upgrade like any built station. While ruined, the station is visible in the Workshop Build sub-tab with a prominent "Restore" CTA but cannot accept queue items.

### 2.5 Per-station active actions (engine refactor)

The engine moves from a single `_activeAction: ActiveActionState?` to:

- `_playerAction: ActiveActionState?` — the player's own in-flight action (gather, fight, rest, build, station-upgrade, station-restore, masterwork challenge).
- `_stationInstances: Map<String, StationInstance>` keyed by `"$zoneId::$stationId"`.

```dart
class StationInstance {
  final String zoneId;
  final String stationId;
  int tier;                                 // 1..maxTier
  bool isRuined;                            // Town Square stations start true
  ActiveActionState? currentCraft;          // head of queue, in progress
  List<QueuedCraft> queue;                  // pending entries behind head
  ActiveActionState? tierUpgrade;           // if upgrading right now
  ActiveActionState? restoration;           // if being restored right now
}

class QueuedCraft {
  final String recipeId;
  int count;                                // remaining iterations
  final Map<int, String> slotChoices;       // slotIndex -> chosen item id
  final String? modifierItemId;
}
```

A single periodic tick (~100ms) advances all in-progress states: `_playerAction` plus each station's `currentCraft`, `tierUpgrade`, and `restoration`. A station can run only one of {craft, upgrade, restore} at a time; queuing a craft is blocked while upgrading or restoring.

**Materials are reserved at queue time** — when the player adds "5× Iron Sword" to a station queue, the inputs for all 5 are removed from inventory immediately and held by the queue entry. Canceling an entry refunds the reserved materials. **Energy is charged per iteration at the start of each craft** (matches current per-craft semantics; lets a queue continue once the player eats and energy returns).

### 2.6 Recipe content additions (intermediates)

New intermediate items unlocked by the new specialist stations:

- **Smelter outputs:** `copper_ingot`, `tin_ingot`, `bronze_ingot`, `iron_ingot`, `steel_ingot`
- **Tannery outputs:** `cured_leather`, `treated_silk`

Existing weapon and armor recipes are rewritten to consume ingots and cured leather rather than raw ore and pelts. This anchors the specialist stations without changing the resource economy at the gathering layer.

~10 existing recipes get edited (input lists rewritten); ~7 new intermediate recipes added; ~5–8 new legendary blueprint-only recipes added (e.g., "Greater Steel Greatsword", "Alchemist's Elixir IV", "Glyph of Mastery").

---

## 3. Crafting Mechanics

### 3.1 Quality roll algorithm

On craft completion:

```
qualityScore =
    uniformRandom(0.0..1.0)
  + 0.020 * (skillLevel - recipe.requiredLevel)        // skill bonus
  + stationTier.qualityBias                             // 0 / +0.05 / +0.12
  + sum(slot.qualityBias for each chosen substitute)    // per-slot biases
  - 0.10 if any required slot was filled with a below-canonical substitute
  + modifierFloor                                       // if a floor modifier was used
```

Buckets:

| Score | Tier |
|---|---|
| < 0.10 | Crude |
| 0.10 – 0.65 | Standard |
| 0.65 – 0.90 | Fine |
| ≥ 0.90 | Masterwork |

At a fresh tier-1 station with `skillLevel == requiredLevel` and canonical inputs only, the distribution is approximately 85% Standard / 13% Fine / 2% Masterwork with a rare Crude. A maxed tier-3 station with skill 10 levels over req and best substitutes biases the distribution heavily toward Fine and Masterwork.

If the result is Fine, roll 1 affix from the pool filtered by `appliesTo`. If Masterwork, roll 2 distinct affixes. Uniform random within the filtered pool in v1.

Cooking, herbalism, and lore outputs are also quality-rolled. Fine and Masterwork food affixes mostly affect heal/energy/value.

### 3.2 Modifier slot effects

See §2.2 table for the v1 modifier mapping. Effects do not stack across multiple modifiers (the slot is 0–1). The modifier ingredient is consumed regardless of outcome — the gamble is part of the design.

### 3.3 Substitution per required slot

A `RecipeSlot.acceptedItems` is ordered: index 0 is canonical (+0 bias). Other entries are positive-bias substitutes (better materials) or negative-bias substitutes (worse, e.g., for early game). The UI shows each slot as a dropdown of materials the player actually has, with the bias visible (`+0.03 quality`, `-0.10 quality`).

### 3.4 Per-station queue & parallel execution

See §2.5 for the data structure. Player-facing semantics:

- Adding to a queue debits the player's inventory immediately for all reserved materials.
- The station processes the queue head; when complete, decrements `count` and re-spawns the iteration. When `count` hits 0, the entry is popped and the next entry becomes head.
- Energy is charged per iteration; if energy is insufficient, the station pauses and logs "Station idle: not enough energy". When energy returns (via food/rest), the queue resumes on the next tick that successfully charges energy.
- Cancelling a queued entry refunds its remaining reserved materials.
- `StationTier.queueSlots` caps the **total** number of `QueuedCraft` entries (including the current one being worked) a station can hold simultaneously: 1 at tier 1, 2 at tier 2, 3 at tier 3. Each entry's `count` field can still be >1 (a single entry "5× Iron Sword" occupies one slot).

### 3.5 Skill-level vs blueprint visibility

```dart
bool canSeeRecipe(Recipe r) {
  return (r.rarity == RecipeRarity.common && playerSkillLevel(r.requiredSkill) >= r.requiredLevel)
      || _knownRecipeIds.contains(r.id);
}
```

Locked recipes are hidden by default in the Workshop browser. A toggle "Show locked" reveals them greyed out with their unlock hint ("Reach Crafting Lvl 7" or "Find blueprint scroll").

---

## 4. UI

### 4.1 Workshop tab (renames Build tab)

Bottom-nav tab `Build` → `Workshop` (icon `🏗️`). Inside the Workshop:

```
┌─ Workshop ─────────────────────────────────┐
│  ╔═══════════╗  ╔═══════════╗              │
│  ║  CRAFT    ║  ║  BUILD    ║              │
│  ╚═══════════╝  ╚═══════════╝              │
│  Current zone: Whispering Woods Tier 1     │
│  Stations here: 🛠️ II ◯, 🍳 I ●            │
└────────────────────────────────────────────┘
```

A shared header always shows the current zone, the stations built there with tier badges, and a station status indicator (green = idle, yellow = working, blue = upgrading, red = ruined).

### 4.2 Craft sub-tab

Station-first navigation. The station chip row at the top is the primary selector; the rest of the screen is dedicated to that station's workspace. The screen does not vertically scroll under normal use.

```
┌─ Workshop ▸ Craft ───────────────────────┐
│ [🛠️ Bench II] [🍳 Kitchen I] [🔥 Smelter] │
├──────────────────────────────────────────┤
│ Crafting Bench II — Whispering Woods     │
│ Quality bias +0.05 | 2 queue slots       │
├──────────────────────────────────────────┤
│ [Tools] [Weapons] [Armor] [Glyphs] [☐Locked] [☐Craftable now]
├──────────────────────────────────────────┤
│  ┌──────────┐ ┌──────────┐  ● ○ ○        │
│  │ Iron Axe │ │Iron Sword│              │
│  │  Lv 12   │ │  Lv 7    │              │
│  │  [Queue] │ │  [Queue] │              │
│  └──────────┘ └──────────┘              │
│  ┌──────────┐ ┌──────────┐              │
│  │Iron Pick │ │Leather   │              │
│  │  Lv 12   │ │  Jerkin  │              │
│  │  [Queue] │ │  [Queue] │              │
│  └──────────┘ └──────────┘              │
├──────────────────────────────────────────┤
│ ▼ Queue: Iron Sword (53%) + 1 more  [↕] │
└──────────────────────────────────────────┘
```

- **Recipe area:** 2×2 grid in a horizontal `PageView` with dot indicators. Swipe between pages. Strong category and skill filters keep most filtered sets to a single page; pagination is the safety net.
- **Recipe card:** icon, name, level requirement, primary input preview, and a [Queue] button. Tapping the card body opens a configuration modal for substitutes, modifier slot, and count picker; the [Queue] button is a one-tap quick-queue with default choices.
- **Queue drawer:** always-visible single-line collapsed state at the bottom showing the current craft and queue count. Tap expands into a modal sheet with full queue entries, each cancellable.
- **Empty state:** when a station has no recipes the player can craft (e.g., new Smelter at low level), show a "No recipes available yet — level up Crafting or find a blueprint scroll" message.

### 4.3 Build sub-tab

Same 2×2 paginated grid pattern for station cards. Each card shows current state:

- **Not built:** "Build [Station Name]" with cost, duration, energy, XP, and skill requirement.
- **Built (idle / working):** current tier label (e.g., "Crafting Bench II"). Tap expands the card to show the upgrade path to the next tier (cost + requirements) and the [Upgrade] button.
- **Ruined (Town Square only):** prominent red-amber "Restore" card with a one-time XP reward.
- **Town Square restriction:** Building net-new stations in Town Square is still disabled — only ruined pre-placed stations can be restored there.

Build, upgrade, and restore actions are **player actions** (single `_playerAction` slot); only one in flight at a time. They do not consume station queue slots.

### 4.4 Dashboard station-status strip

A new strip at the top of the Dashboard above existing content. Horizontal chip row (scrolls horizontally if overflow). Each chip: station icon, tier badge, current craft icon, mini progress ring, status text.

Example: `[🛠️ II × Iron Sword 53%] [🍳 I × Baked Potato — idle: out of energy]`

Tap a chip jumps to the Workshop tab focused on that station.

### 4.5 Inventory implications

- Crafted items group by `(itemId, quality, sorted-affixIds)`. A color-coded quality band sits on the card: grey (Crude), white (Standard), blue (Fine), gold (Masterwork). Affix names listed under the item name.
- Tap-through modal: the "related recipes" section gets a "Craft at: Bench II in Whispering Woods (idle)" hint with a quick-queue button. If no suitable station exists, the hint becomes "Build a Crafting Bench in your current zone to make this."
- Resource items stay tierless and display unchanged.
- **Quality filter chip row** above the inventory grid: `[All] [Standard+] [Fine+] [Masterwork only]`. Default `All`. Per-session state (resets on app restart).

### 4.6 Blueprint scroll UX

Blueprint items in the inventory expose a "Learn" action. Learning fires a fanfare animation, removes the blueprint, adds the recipe id to `_knownRecipeIds`, and shows a snackbar: "Learned: Steel Greatsword recipe!" The recipe immediately becomes available in the Workshop ▸ Craft browser.

### 4.7 Notifications & log integration

- `LootEvent` extended with `(qualityTier, affixIds)` for color and affix display on the floating notification overlay.
- Activity log entries gain quality coloring: `"✨ Fine Iron Sword [Keen] crafted at Bench II (+72 Crafting XP)"`.

---

## 5. Migration & Rollout

### 5.1 Code-side migration

**Engine refactor (the biggest single change):**

- `_activeAction: ActiveActionState?` → `_playerAction: ActiveActionState?` + `_stationInstances: Map<String, StationInstance>`.
- The single `_actionTimer` periodic tick advances all in-progress states: player action + every station's currentCraft, tierUpgrade, restoration.
- `_zoneStructures: Map<String, List<String>>` is replaced by `_stationInstances` (which carries tier + status, not just presence).
- `startBuilding`, `startCrafting`, `cancelAction` rewrite: building/upgrading targets `_playerAction`; crafting targets a `StationInstance` queue. A new `cancelStationQueueEntry(stationKey, entryIndex)` is added.
- `getModifiedEnergyCost`, `getSkillSpeedBonus`, etc. are unchanged.

**Model rewrites:**

- `Recipe.inputs: Map<String,int>` → `List<RecipeSlot>`; adds `stationId`, `requiredStationTier`, `rarity`, `modifierSlot`.
- `Structure` → `Station` (rename, tier ladder added).
- New: `QualityTier`, `Affix`, `CraftedItem`, `RecipeSlot`, `StationTier`, `StationInstance`, `QueuedCraft`, `RecipeModifierEffect`, `Blueprint`.

**Inventory refactor:**

- `Inventory` stores `Map<InventoryKey, int>` where `InventoryKey = (itemId, quality?, sortedAffixIds?)`. Plain items use a single key with nulls; crafted items get distinct keys per (quality, affix-set).
- `getItemCount(itemId)` continues to sum across all quality variants (existing call sites unchanged).
- New `getItemCount(itemId, quality, affixes)` for precise checks used by queue refund logic.

**Recipe content migration:**

- All 30 existing recipes get a one-time rewrite: each gets a `stationId`, `requiredStationTier` (most → tier 1 or 2), `rarity: common` (a few promoted to `rare`), and inputs migrate to single-element `RecipeSlot` lists (substitutes added in a balance pass).
- New intermediate recipes added (ingots, cured leather, treated silk).
- Weapon/armor recipes rewritten to consume ingots/leather.
- ~5–8 new legendary blueprint-only recipes added.

### 5.2 Blueprint drop integration

- New `ItemType.blueprint` + a `Blueprint` Item subclass carrying `recipeId`.
- Existing `ZoneAction.lootTable` already supports `LootDrop`; add blueprint LootDrops to ~30% of zone actions and ~50% of beast loot tables at low chance (1–3%).
- Zone tier gates which blueprints can drop.

### 5.3 Tests

Existing `test/` directory hosts new tests:

- **Quality roll:** seeded RNG, verify distribution across 10k rolls for representative `(skill, tier, substitutes)` combos.
- **Per-station queue:** queue 3 items, advance 5 ticks, verify head/tail consistency; cancellations refund correct materials; energy-out pauses queue and resumes on next tick after energy returns.
- **Modifier effects:** each of the 6 modifier effects triggers correctly and consumes the modifier.
- **Substitution:** each substitute applies its `qualityBias`; below-canonical substitutes apply the -0.10 penalty once even if multiple are used.
- **Inventory keying:** stacking by `(id, quality, affixes)` is correct; same id different affixes don't merge.
- **Town Square restoration:** ruined stations exist at game start; restoration cost is required; post-restore station behaves identically to a freshly-built one.
- **Blueprint learning:** consuming a blueprint adds the recipe id to known set; locked rare recipes become visible after.
- **Backward compat:** existing tests touching `startCrafting`, `startBuilding`, `getAvailableRecipes`, `canCraftRecipe` are updated to the new APIs.

### 5.4 Internal rollout order (within the monolithic PR)

Staged internally so the codebase compiles and the app runs at the end of each step:

1. **Foundations.** Add new types (`QualityTier`, `Affix`, `RecipeSlot`, etc.) without using them. Game still works identically.
2. **Engine refactor.** Split `_activeAction` into `_playerAction` + `_stationInstances`. Migrate existing 3 structures to `StationInstance` with `tier:1`. Existing recipes still work (single-slot inputs, no quality yet, no queue).
3. **Quality + affixes.** Wire quality roll into craft completion; update inventory keying; update inventory_view rendering. All recipes produce Standard with no affixes (multiplier 1.0×) at this stage — quality band visible on cards but no behavioral change yet.
4. **Station tiers + new specialists.** Add tier ladders; introduce Smelter, Tannery, Apothecary; add intermediate ingot/leather recipes; introduce ruined Town Square stations + restoration.
5. **Per-station queues.** Add queue UI + persist queue state on `StationInstance`. Retire auto-repeat (replaced by `count` in `QueuedCraft`).
6. **Modifiers + substitution.** Activate `RecipeSlot.acceptedItems`; add modifier slot UI; apply quality biases.
7. **Blueprints + rare recipes.** Add blueprint item type, learn UX, drop tables, and the 5–8 legendary recipes.
8. **Workshop UI.** Replace Build view with the Workshop tab (PageView grid, station-first nav, queue drawer); add Dashboard station-status strip; add inventory quality filter.

### 5.5 Risks & deferrals

- **Quality balance is a guess.** Bands and the affix pool will need 1–2 tuning passes after step 8 — expected, not blocking.
- **Per-station parallel queues are the highest-risk piece.** If the engine refactor proves painful mid-implementation, fall back to a "cap at 1 active station + 1 player action" mode that preserves the new data shape but simulates the old behavior. Do not redesign mid-implementation.
- **No persistence.** All state is lost on app close — current behavior, not changed. Migration is a non-issue because there are no save files.
- **Affix-stat interactions** are not exhaustively specified per item type — the implementation will follow the principle "affix effect stacks multiplicatively on top of quality multiplier on top of base stat" and concrete formulas will be locked in during implementation.

### 5.6 Out of scope (future work)

- Zone-instance affix pools (different zones bias different affixes).
- Masterwork recipes that require Masterwork-tier ingredients to craft (would require quality propagation through resources).
- Station "specializations" that bias quality toward certain affixes.
- Recipe favorites / saved presets for queue entries.
- Craft history log.
- Saving / persistence of all game state across app restarts.
