# Spec 3 — Sundered Coast Biome

**Date:** 2026-05-24
**Status:** Approved (pending spec review)
**Parent:** [Echoes from the Deep umbrella vision](2026-05-24-echoes-from-the-deep-vision.md)
**Depends on:** [Spec 1 — Quest Engine & Codex Foundation](2026-05-24-spec-1-quest-codex-foundation-design.md), [Spec 2 — Codex Content & Story](2026-05-24-spec-2-codex-content-story-design.md)
**Scope:** Third of six sub-specs from the umbrella. Introduces the Sundered Coast biome with 3 new zones, 3 new beasts (Echo deferred to Spec 5), 4 new resources, 4 beast-drop items, the Salt Press station (recipes deferred to Spec 4), Coast weather system, the lore+exploration Coast unlock flow, and Tide-tag fragment drop wiring.

---

## 1. Goals & Acceptance Criteria

### 1.1 What Spec 3 ships

- New Town Square Wayfinding scout: **"Walk the Eastern Coastal Path"** — appears once `breaches_concept_known` flag is set (Spec 2 milestone)
- Completing the scout fires a refugee event (modal World Event), reveals the **Wharfmaster's Pier** action in Town Square, and unlocks Sundered Coast I
- **3 new zones:** Sundered Coast I (tidal flats), II (cliffs + salt flats), III (Drowned Lighthouse — gathering only; Echo combat deferred)
- **3 new beasts:** Tide Hound (T1), Brine Crawler (T2), Salt-Touched Drowned (T3)
- **8 new items:** 4 resources (Driftwood, Salt Crystal, Pearl Shell, Kelp) + 4 beast drops (Tide Hound Pelt, Hound Fang, Crawler Carapace, Salt-Touched Skin)
- **Salt Press station** with 3-tier ladder; buildable in Coast zones only; **no recipes yet** (Spec 4 fills)
- **Coast weather:** Calm / Sea Fog / Storm Swell rolling every ~5 min; Storm chance = 5% baseline + 5% per uncleansed breach the player has fragments from; Storm Swell blocks `travelTo` Coast zones
- **3 new Coast Obelisk actions:** `inspect_pier_glyph` (Coast I), `inspect_wharf_glyph` (Coast II), `read_lighthouse_plaque` (Coast III)
- **Tide-tag fragment drop wiring** through Coast obelisks (10%/10%/15%), Coast beasts (8%), Coast scouts (5%), and the unlock-scout itself (20% on each completion)
- **Tide pool gate** in `_isFragmentPoolOpen` is the existing Spec 2 check; Spec 3 sets the `coast_unlocked` flag that flips it
- **Main quest 4 (Investigate the Tide)** offered when Coast unlocks (factory exists from Spec 2)
- **`_regionTagForBeast`** extended with the 3 Coast beasts

### 1.2 What Spec 3 does NOT do

- No Echo of the Tide combat (Spec 5)
- No Drowned Lighthouse cleansing ritual (Spec 5)
- No Salt Press recipes (Spec 4 — they need modifier-slot crafting depth)
- No Sea Fog combat-crit bonus (Spec 4 — Stance combat doesn't exist yet)
- No new Codex fragments (all 10 Tide-tag fragments already exist from Spec 2)
- No new combat depth (Spec 4)

### 1.3 Acceptance criteria

A player after Spec 3 ships:

1. Collects fragments from 2 breach tags (Wilds + Stone) → second_breach_concept milestone fires → in Town Square actions, **"Walk the Eastern Coastal Path"** scout appears
2. Completes the scout → refugee event modal: *"A salt-crusted stranger limps into Town Square..."* → Wharfmaster's Pier appears in Town Square actions
3. Region Status Board now shows Sundered Coast I as Anomalous
4. Travels to Sundered Coast I (~5 sec) → can gather Kelp, Driftwood, Salt Crystal, hunt Tide Hound, inspect Pier Glyph, scout to Coast II
5. Tide-tag fragments now drop from Coast sources
6. Investigate the Tide quest appears in Quest Log
7. Sometimes Storm Swell rolls → Coast travel blocked with: *"The Wharfmaster shakes his head. 'No travel today.'"*
8. Builds Salt Press at any Coast zone (cost: oak_log×8, river_clay×6, driftwood×4); appears in Workshop with *"No recipes available yet"* empty state
9. Pearl Shell and Salt Crystal stockpile with no consumers (Spec 4 wires them)
10. Reaches Drowned Lighthouse at Coast III → reads plaque (higher Old Empire chance) → senses Echo waits but cannot fight it (Spec 5)

### 1.4 Design principles inherited

- **No art** — emoji icons throughout: 🦀 Tide Hound, 🦞 Brine Crawler, 🧟 Salt-Touched Drowned, ⚓ Wharfmaster's Pier, 🧂 Salt Press, 🐚 Pearl Shell, 🌊 Sea Fog, ⛈️ Storm Swell
- **Progressive discovery** — Coast doesn't exist in Region Status until first scout completes; Salt Press recipes only appear when they exist; Wharfmaster's Pier action gated by `wharfmaster_pier_visible` flag
- **Thin story spine** — refugee event is narrative-only (no quest giver dialog tree); Wharfmaster is flavor presence not NPC
- **Systems converse** — Coast unlock requires both lore (Spec 2 milestone) AND exploration (new scout); weather corruption-scales with uncleansed breach work; Coast beasts feed Tide fragments which feed Tide puzzle which gates Tide Reading which Spec 5 needs for cleansing

---

## 2. Zone & Beast Content

### 2.1 Sundered Coast I — Tidal Flats

**Tier 1.** Weathered coastal stretch with tidal pools and brine air. Where the Coast still looks almost normal.

| ZoneAction id | Name | Skill | Lvl | Energy | Dur | XP | Loot |
|---|---|---|---|---|---|---|---|
| `gather_driftwood` | Gather Driftwood | Woodcutting | 1 | 3 | 4s | 22 | Driftwood (0.90, 1) |
| `forage_kelp` | Forage Tide-Pool Kelp | Herbalism | 1 | 3 | 4s | 22 | Kelp (0.85, 1–2) |
| `pry_salt_crystal` | Pry Salt Crystal | Mining | 1 | 4 | 5s | 25 | Salt Crystal (0.80, 1) |
| `dive_pearl_shell` | Dive Pearl Shell | Wayfinding | 3 | 5 | 5s | 25 | Pearl Shell (0.75, 1) — *requires Calm weather* |
| `inspect_pier_glyph` | Read the Pier Glyph | Lore | 1 | 4 | 5s | 30 | (fragments — see §4) |
| `hunt_tide_hound` | Hunt Tide Hound | Combat | 1 | 4 | 5s | 35 | Tide Hound Pelt (0.85, 1), Hound Fang (0.40, 1); `isCombat: true`, `beastId: 'tide_hound'` |
| `scout_cliff_path` | Scout the Cliff Path | Wayfinding | 5 | 12 | 7s | 35 | (unlocks Sundered Coast II) |

`successModifier: +0.05` (Calm). Storm Swell blocks entry entirely.

### 2.2 Sundered Coast II — Cliffside Salt Flats

**Tier 2.** Wind-scoured cliffs above churning surf.

| ZoneAction id | Name | Skill | Lvl | Energy | Dur | XP | Loot |
|---|---|---|---|---|---|---|---|
| `cut_bleached_driftwood` | Cut Salt-Bleached Driftwood | Woodcutting | 10 | 6 | 6s | 45 | Driftwood (0.85, 1–2), Salt Crystal (0.20, 1) |
| `harvest_seaglass_kelp` | Harvest Sea-Glass Kelp | Herbalism | 10 | 6 | 6s | 40 | Kelp (0.80, 1–2), Nightshade (0.15, 1) |
| `mine_pure_salt` | Mine Pure Salt Crystal | Mining | 10 | 7 | 7s | 50 | Salt Crystal (0.75, 1) |
| `dredge_pearl_bed` | Dredge Deep Pearl Bed | Wayfinding | 10 | 8 | 7s | 50 | Pearl Shell (0.70, 1) — *requires Calm* |
| `inspect_wharf_glyph` | Read the Wharf Glyph | Lore | 5 | 5 | 6s | 40 | (fragments — see §4) |
| `hunt_brine_crawler` | Hunt Brine Crawler | Combat | 5 | 8 | 6s | 55 | Crawler Carapace (0.75, 1), Spider Silk (0.50, 1); `isCombat: true`, `beastId: 'brine_crawler'` |
| `scout_lighthouse_path` | Scout the Lighthouse Path | Wayfinding | 10 | 18 | 8s | 50 | (unlocks Sundered Coast III) |

`successModifier: +0.10` (when Calm or Sea Fog).

### 2.3 Sundered Coast III — Drowned Lighthouse

**Tier 3.** Storm-lashed lighthouse on a fog-bound rock. **No Echo combat in Spec 3.**

| ZoneAction id | Name | Skill | Lvl | Energy | Dur | XP | Loot |
|---|---|---|---|---|---|---|---|
| `scavenge_lamp_room` | Scavenge Lamp Room | Wayfinding | 15 | 10 | 8s | 60 | Salt Crystal (0.50, 1–2), Pearl Shell (0.30, 1), Driftwood (0.40, 1–2) |
| `brave_drowned_cellar` | Brave the Drowned Cellar | Combat | 10 | 12 | 8s | 90 | Salt-Touched Skin (0.70, 1), Crawler Carapace (0.40, 1–2); `isCombat: true`, `beastId: 'salt_touched_drowned'` |
| `read_lighthouse_plaque` | Read the Lighthouse Plaque | Lore | 10 | 6 | 7s | 60 | (fragments — see §4) |
| `approach_lamp_room` | Approach the Lamp Room | Wayfinding | 15 | 5 | 5s | 30 | fires one-time "Something stirs..." event (Spec 5 hooks here for Echo encounter) |

**Hazards:** 15% chance / 10 damage on gathering; 25% / 15 damage on combat. **Tier-3 Source-tag drop wiring (already from Spec 2):** 3% per gather, gated by `first_breach_cleansed` (Spec 5).

### 2.4 New beasts

```dart
// In lib/models/beast.dart:

static const Beast tideHound = Beast(
  id: 'tide_hound',
  name: 'Tide Hound',
  icon: '🐕',
  maxHealth: 40,
  attackPower: 6,
  defense: 1,
  xpReward: 32,
  lootTable: [
    LootDrop(item: Items.tideHoundPelt, chance: 0.85, minQuantity: 1, maxQuantity: 1),
    LootDrop(item: Items.houndFang, chance: 0.40, minQuantity: 1, maxQuantity: 1),
  ],
);

static const Beast brineCrawler = Beast(
  id: 'brine_crawler',
  name: 'Brine Crawler',
  icon: '🦞',
  maxHealth: 75,
  attackPower: 12,
  defense: 3,
  xpReward: 60,
  lootTable: [
    LootDrop(item: Items.crawlerCarapace, chance: 0.75, minQuantity: 1, maxQuantity: 1),
    LootDrop(item: Items.spiderSilk, chance: 0.50, minQuantity: 1, maxQuantity: 1),
  ],
);

static const Beast saltTouchedDrowned = Beast(
  id: 'salt_touched_drowned',
  name: 'Salt-Touched Drowned',
  icon: '🧟',
  maxHealth: 140,
  attackPower: 20,
  defense: 5,
  xpReward: 100,
  lootTable: [
    LootDrop(item: Items.saltTouchedPelt, chance: 0.70, minQuantity: 1, maxQuantity: 1),
    LootDrop(item: Items.crawlerCarapace, chance: 0.40, minQuantity: 1, maxQuantity: 2),
  ],
);
```

Tuning slots: Tide Hound (40 HP) between Forest Boar (35) and Cave Spider (55); Brine Crawler (75) matches Shadow Wolf (85); Salt-Touched Drowned (140) under Cavern Troll (160) so Coast III is reachable before maxing other biomes.

### 2.5 New items

```dart
// In lib/models/item.dart — resources:
static const Item driftwood = Item(
  id: 'driftwood',
  name: 'Driftwood',
  description: 'Salt-bleached wood washed up from deep water. Lighter than oak, harder than willow.',
  icon: '🪵',
  type: ItemType.resource,
  value: 8,
);

static const Item saltCrystal = Item(
  id: 'salt_crystal',
  name: 'Salt Crystal',
  description: 'A clear, faintly singing crystal of sea-salt. The Wharfmaster says they were used in the old beacons.',
  icon: '🧂',
  type: ItemType.resource,
  value: 14,
);

static const Item pearlShell = Item(
  id: 'pearl_shell',
  name: 'Pearl Shell',
  description: 'An iridescent shell from the deep tide pools. Coveted by armorers.',
  icon: '🐚',
  type: ItemType.resource,
  value: 22,
);

static const Item kelp = Item(
  id: 'kelp',
  name: 'Sea Kelp',
  description: 'Long ribbons of edible kelp. Tastes of the deep ocean.',
  icon: '🌿',
  type: ItemType.resource,
  value: 6,
);

// Beast drops:
static const Item tideHoundPelt = Item(
  id: 'tide_hound_pelt',
  name: 'Tide Hound Pelt',
  description: 'A wet, mottled pelt from a coastal hound.',
  icon: '🐕',
  type: ItemType.resource,
  value: 18,
);

static const Item houndFang = Item(
  id: 'hound_fang',
  name: 'Hound Fang',
  description: 'A long curved fang. Slightly luminescent in the dark.',
  icon: '🦷',
  type: ItemType.resource,
  value: 12,
);

static const Item crawlerCarapace = Item(
  id: 'crawler_carapace',
  name: 'Crawler Carapace',
  description: 'A jagged plate from a brine crawler\'s shell.',
  icon: '🛡️',
  type: ItemType.resource,
  value: 20,
);

static const Item saltTouchedPelt = Item(
  id: 'salt_touched_pelt',
  name: 'Salt-Touched Skin',
  description: 'Translucent, salt-encrusted skin from a drowned thing. Buyers won\'t look you in the eye.',
  icon: '🥥',
  type: ItemType.resource,
  value: 40,
);
```

All 8 items appended to `Items.all`. In Spec 3 they stockpile with no consumers beyond shop sale value. Spec 4 wires them into recipes.

### 2.6 Cross-biome wiring updates

- **`_regionTagForBeast`** extended:
  ```dart
  case 'tide_hound':
  case 'brine_crawler':
  case 'salt_touched_drowned':
    return CodexTag.tide;
  ```
- **`Zones.all`** extended with `sunderedCoastTier1`, `sunderedCoastTier2`, `sunderedCoastTier3`
- **`Beasts.all`** extended with 3 new beasts
- Shop integration: **Maeve (Wilderness Outfitter)** gets new buy listings for Driftwood/Salt Crystal/Pearl Shell/Kelp at typical sell-fractions

---

## 3. Weather & Unlock Event

### 3.1 Coast weather system

New file `lib/models/weather.dart`:

```dart
enum CoastWeather { calm, seaFog, stormSwell }

class CoastWeatherState {
  final CoastWeather current;
  final DateTime nextRollAt;
  const CoastWeatherState({required this.current, required this.nextRollAt});
}
```

Engine state:

```dart
CoastWeatherState _coastWeather = CoastWeatherState(
  current: CoastWeather.calm,
  nextRollAt: DateTime.now(),
);

CoastWeather get coastWeather => _coastWeather.current;
```

Global tick checks `nextRollAt`, rolls when due, schedules 5 minutes out:

```dart
void _maybeRollCoastWeather() {
  if (DateTime.now().isBefore(_coastWeather.nextRollAt)) return;

  final stormChance = _calculateStormChance();
  const fogChance = 0.25;
  final roll = _random.nextDouble();

  final CoastWeather next;
  if (roll < stormChance) next = CoastWeather.stormSwell;
  else if (roll < stormChance + fogChance) next = CoastWeather.seaFog;
  else next = CoastWeather.calm;

  if (next != _coastWeather.current) {
    log('Coast weather: ${_weatherDisplayName(next)}', LogType.info);
  }
  _coastWeather = CoastWeatherState(
    current: next,
    nextRollAt: DateTime.now().add(const Duration(minutes: 5)),
  );
  notifyListeners();
}

double _calculateStormChance() {
  double chance = 0.05;
  final breachTagsWithFragments = <CodexTag>{};
  for (final id in _knownCodexFragmentIds) {
    final f = CodexFragments.findById(id);
    if (f != null && (f.tag == CodexTag.wilds || f.tag == CodexTag.stone || f.tag == CodexTag.tide)) {
      breachTagsWithFragments.add(f.tag);
    }
  }
  if (_engineFlags.contains('breach_wilds_cleansed')) breachTagsWithFragments.remove(CodexTag.wilds);
  if (_engineFlags.contains('breach_stone_cleansed')) breachTagsWithFragments.remove(CodexTag.stone);
  if (_engineFlags.contains('breach_tide_cleansed')) breachTagsWithFragments.remove(CodexTag.tide);
  chance += breachTagsWithFragments.length * 0.05;
  return chance.clamp(0.0, 0.50);
}
```

### 3.2 Weather effects

- **`travelTo(Zone zone)`** — if destination is a Coast zone AND current weather is `stormSwell`, refuse with log: *"The Wharfmaster shakes his head. 'No travel today. The seas have swallowed the pier.'"*
- **`startAction`** — for `dive_pearl_shell` and `dredge_pearl_bed`, require `CoastWeather.calm` specifically; show *"The pools churn. Wait for the seas to settle."* if Sea Fog or Storm Swell
- **Sea Fog** is cosmetic in Spec 3; Spec 4 will wire the Combat-crit bonus once Stance combat lands

### 3.3 Weather display

- Small chip on the Coast Region Status Board card: 🌤️ Calm (green) / 🌫️ Sea Fog (gray) / ⛈️ Storm Swell (red, pulsing)
- Chip on Dashboard station-status strip when player in a Coast zone: shows weather + time-to-next-roll countdown

### 3.4 Coast unlock flow

**Prereq:** `breaches_concept_known` flag (set by Spec 2's `second_breach_concept` milestone when player has fragments from 2 different breach tags).

**Step 1 — Conditional Town Square action:**

```dart
ZoneAction(
  id: 'walk_eastern_coastal_path',
  name: 'Walk the Eastern Coastal Path',
  description: 'A traveler\'s tale points east along an old footpath. Set out to see where it leads.',
  durationSeconds: 8,
  energyCost: 10,
  requiredSkill: SkillType.wayfinding,
  requiredLevel: 1,
  xpReward: 40,
  lootTable: [],
),
```

Conditionally rendered in Town Square — Dashboard's zone-action renderer checks `engine.engineFlags.contains('breaches_concept_known')`.

**Step 2 — Completion side effects (in `_completeAction`):**

```dart
if (action.id == 'walk_eastern_coastal_path') {
  if (!_engineFlags.contains('coast_unlocked')) {
    _engineFlags.add('coast_unlocked');
    _engineFlags.add('wharfmaster_pier_visible');
    _unlockedZoneIds.add('sundered_coast_1');
    _checkMilestones();
    offerQuest(MainQuests.investigateTide());
  }
}
```

**Step 3 — New milestone:**

```dart
static final MilestoneEvent coastUnlocked = MilestoneEvent(
  id: 'coast_unlocked',
  severity: MilestoneSeverity.major,
  title: 'A Salt-Crusted Stranger',
  body: 'A salt-crusted stranger limps into Town Square, leaning on a driftwood cane. "I came from the Coast. The lighthouse is dark. The lamp will not stay lit. The drowned are walking up the pier." She presses a tarnished key into your palm — the key to the Wharfmaster\'s old pier. "Go. Someone has to go."',
  icon: '⚓',
  trigger: (engine) => engine.engineFlags.contains('coast_unlocked'),
  onFire: null,
);
```

Added to `Milestones.all`.

**Step 4 — Wharfmaster's Pier action:**

```dart
ZoneAction(
  id: 'wharfmaster_travel',
  name: 'Take the Pier to the Coast',
  description: 'Board a small craft at the Wharfmaster\'s Pier. Quick passage to the Sundered Coast.',
  durationSeconds: 3,
  energyCost: 3,
  requiredSkill: SkillType.wayfinding,
  requiredLevel: 1,
  xpReward: 5,
  lootTable: [],
),
```

Conditionally rendered on `wharfmaster_pier_visible` flag. On completion, calls `travelTo(Zones.sunderedCoastTier1)`. Flavor-wrapped fast-travel.

**Step 5 — Spec 5 alternate route (placeholder contract):**

Spec 5's breach-cleansing handler will additionally set `coast_unlocked` if not yet set, firing the same milestone via the existing flag-check trigger. A player who somehow cleanses a breach without Coast yet unlocked still gets the refugee event.

### 3.5 The Wharfmaster

Placeholder NPC — no dialog tree, no quests, no portrait. Small flavor chip on the Wharfmaster's Pier action card: *"Wharfmaster Eorin nods. 'Mind the weather, traveler.'"* (rotates with 2–3 greeting variants like existing merchants). No emoji avatar; just text. Future expansions can give him quests.

---

## 4. Drop Wiring & Tag Pool Gate

### 4.1 Tide pool gate flip

Spec 2 wired `_isFragmentPoolOpen(CodexTag.tide)` to check `engine.engineFlags.contains('coast_unlocked')`. Spec 3 sets that flag via the unlock flow (§3.4 Step 2). No code change to `_isFragmentPoolOpen`.

### 4.2 New Coast drop sources & rates

| ZoneAction id | Tide chance | Old Empire chance |
|---|---|---|
| `inspect_pier_glyph` | 0.10 | 0.01 |
| `inspect_wharf_glyph` | 0.10 | 0.02 |
| `read_lighthouse_plaque` | 0.15 | 0.03 |
| `walk_eastern_coastal_path` | 0.20 (on each completion — re-runnable) | — |
| `scout_cliff_path` | 0.05 | — |
| `scout_lighthouse_path` | 0.05 | — |
| Coast beast defeats (via `_regionTagForBeast`) | 0.08 (existing Spec 2 wiring) | — |
| Coast T3 gather (any non-combat at Coast III) | 0.03 Source (gated by `first_breach_cleansed`) | — |

### 4.3 Drop calls appended in `_completeAction`

```dart
// Spec 3 Coast Obelisks
if (action.id == 'inspect_pier_glyph') {
  tryDropFragment(CodexTag.tide, 0.10);
  tryDropFragment(CodexTag.oldEmpire, 0.01);
}
if (action.id == 'inspect_wharf_glyph') {
  tryDropFragment(CodexTag.tide, 0.10);
  tryDropFragment(CodexTag.oldEmpire, 0.02);
}
if (action.id == 'read_lighthouse_plaque') {
  tryDropFragment(CodexTag.tide, 0.15);
  tryDropFragment(CodexTag.oldEmpire, 0.03);
}

// Coast scout actions
if (action.id == 'walk_eastern_coastal_path') {
  tryDropFragment(CodexTag.tide, 0.20);
}
if (action.id == 'scout_cliff_path') {
  tryDropFragment(CodexTag.tide, 0.05);
}
if (action.id == 'scout_lighthouse_path') {
  tryDropFragment(CodexTag.tide, 0.05);
}
```

### 4.4 Critical ordering invariant

The unlock-side-effects block for `walk_eastern_coastal_path` MUST fire BEFORE the fragment-drop block on the same action completion:

```dart
// CORRECT ORDER:

// 1. Unlock side effects FIRST
if (action.id == 'walk_eastern_coastal_path') {
  if (!_engineFlags.contains('coast_unlocked')) {
    _engineFlags.add('coast_unlocked');
    _engineFlags.add('wharfmaster_pier_visible');
    _unlockedZoneIds.add('sundered_coast_1');
    _checkMilestones();
    offerQuest(MainQuests.investigateTide());
  }
}

// 2. THEN fragment drop attempts
if (action.id == 'walk_eastern_coastal_path') {
  tryDropFragment(CodexTag.tide, 0.20);
  // Pool is now open if just flipped — drop can succeed on first walk
}
```

Test must verify: walking the scout for the first time can drop a Tide fragment in the same completion.

### 4.5 Beast drops

The Spec 2 `_resolveCombat` hook already calls `tryDropFragment(regionTag, 0.08)` after `_regionTagForBeast(beast.id)`. Spec 3 just extends `_regionTagForBeast` with 3 Coast beasts (see §2.6). No further wiring needed.

### 4.6 Quest auto-advance

Spec 2's existing `_matches` with `targetTag` filter advances `codexRead × 10 with targetTag: CodexTag.tide` on Tide fragment reads. Investigate the Tide auto-progresses; completing it chains Cleanse the Tide per Main 4's `offerQuest` reward (Spec 5 fulfills cleanse).

---

## 5. Salt Press, Testing & Rollout

### 5.1 Salt Press station (placeholder)

```dart
// In lib/models/structure.dart:

static const Structure saltPress = Structure(
  id: 'salt_press',
  name: 'Salt Press',
  icon: '🧂',
  primarySkill: SkillType.cooking,
  enabledSkills: [SkillType.cooking, SkillType.herbalism],
  maxTier: 3,
  tiers: [
    StationTier(
      tier: 1,
      upgradeCost: {'driftwood': 4, 'oak_log': 8, 'river_clay': 6},
      upgradeDurationSeconds: 12,
      upgradeEnergyCost: 8,
      requiredSkillLevel: 3,
      qualityBias: 0.0,
      queueSlots: 1,
      speedBonus: 0.0,
    ),
    StationTier(
      tier: 2,
      upgradeCost: {'driftwood': 8, 'salt_crystal': 6, 'pearl_shell': 2},
      upgradeDurationSeconds: 20,
      upgradeEnergyCost: 14,
      requiredSkillLevel: 8,
      qualityBias: 0.05,
      queueSlots: 2,
      speedBonus: 0.10,
    ),
    StationTier(
      tier: 3,
      upgradeCost: {'driftwood': 12, 'salt_crystal': 12, 'pearl_shell': 5},
      upgradeDurationSeconds: 30,
      upgradeEnergyCost: 22,
      requiredSkillLevel: 14,
      qualityBias: 0.12,
      queueSlots: 3,
      speedBonus: 0.20,
    ),
  ],
  description: 'Presses salt, cures provisions, and stabilizes brine reagents. The lighthouse keepers used these before the storm.',
);
```

**Build availability:** Coast zones only. Workshop Build tab filters by zone; Salt Press won't appear in non-Coast build options.

**Crafting view behavior:**
- Recipe browser: *"No recipes available yet. (Future content)"*
- Queue panel: *"Idle — no recipes to queue."*
- Tier upgrade button works (player can upgrade the empty station toward Spec 4's higher-tier recipes)

### 5.2 Test strategy

**New `test/coast_zones_test.dart`:**
- 3 Coast zones exist with expected ids, tiers, and key actions
- Action XP scales by tier (Lighthouse plaque > Pier glyph)
- Hazard chances on T3 actions are 0.15 (gather) and 0.25 (combat)

**New `test/coast_beasts_test.dart`:**
- 3 new beasts exist with expected HP/atk/def
- `_regionTagForBeast` returns `CodexTag.tide` for all three

**New `test/coast_weather_test.dart`:**
- Storm chance is 0.05 baseline with no fragments
- Storm chance rises +0.05 per breach-tag with fragments (capped at 0.50)
- Cleansing flag reduces storm chance
- Storm Swell blocks `travelTo` Coast zones
- Calm allows Coast travel

**New `test/coast_unlock_test.dart`:**
- `walk_eastern_coastal_path` action hidden before `breaches_concept_known`
- Action visible once flag set
- Completing scout sets `coast_unlocked` flag, `wharfmaster_pier_visible` flag, adds Coast I to unlocked zones, offers Investigate Tide quest
- Re-completing scout is idempotent — no duplicate quest offers

**Extend `test/codex_drops_test.dart`:**
- Tide pool closed before `coast_unlocked`; open after
- Unlock scout's drop attempt succeeds on the same completion that flips the flag (ordering invariant)

**Extend `test/widget_test.dart`:**
- Wharfmaster's Pier action visible only after `wharfmaster_pier_visible` flag
- Salt Press shows "No recipes available yet" empty state
- Storm weather chip displays on Coast Region Status card

**Extend `test/quest_engine_test.dart` — integration smoke:**

```dart
test('Spec 3 acceptance — Coast unlock through scout', () {
  final engine = GameEngine();
  // Collect fragments from 2 breach tags
  engine.tryDropFragment(CodexTag.wilds, 1.0);
  engine.unlockZone('darkstone_mine_1');
  engine.travelTo(Zones.darkstoneMineTier1);
  engine.tryDropFragment(CodexTag.stone, 1.0);
  engine.travelTo(Zones.townSquare);

  expect(engine.engineFlags.contains('breaches_concept_known'), true);

  engine.completeScoutForTest('walk_eastern_coastal_path');

  expect(engine.engineFlags.contains('coast_unlocked'), true);
  expect(engine.engineFlags.contains('wharfmaster_pier_visible'), true);
  expect(engine.activeQuests.any((q) => q.id == 'main_investigate_tide'), true);

  engine.forceCoastWeatherForTest(CoastWeather.calm);
  engine.travelTo(Zones.sunderedCoastTier1);
  expect(engine.currentZone.id, 'sundered_coast_1');

  engine.tryDropFragment(CodexTag.tide, 1.0);
  expect(engine.knownCodexFragmentIds.any(
    (id) => CodexFragments.findById(id)!.tag == CodexTag.tide,
  ), true);
});
```

Test helpers (`@visibleForTesting`): `completeScoutForTest`, `forceCoastWeatherForTest`, `calculateStormChancePublic`, `regionTagForBeastPublic`.

### 5.3 Implementation order

Single PR, internally staged:

1. **Resource items** — Add 8 new items to `lib/models/item.dart` + `Items.all`. Tests verify items load.
2. **Coast beasts** — Add 3 new beasts to `lib/models/beast.dart` + `Beasts.all`.
3. **Coast zones** — Add 3 new Zone definitions to `lib/models/zone.dart` + `Zones.all` with full action lists.
4. **Salt Press station** — Add to `lib/models/structure.dart` + `Stations.all` with 3-tier ladder, no recipes.
5. **Weather model + engine state** — Create `lib/models/weather.dart`. Add `_coastWeather` field + `_maybeRollCoastWeather` + `_calculateStormChance` to GameEngine. Wire into global tick.
6. **`_regionTagForBeast` extension** — Add 3 Coast beast cases.
7. **Coast unlock action** — Define `walk_eastern_coastal_path`. Wire conditional visibility check in Dashboard zone-action renderer.
8. **Coast unlock side effects** — In `_completeAction`, add unlock-side-effect block for `walk_eastern_coastal_path` (sets flags, unlocks zone, offers Investigate Tide).
9. **Coast unlock milestone** — Add `coastUnlocked` MilestoneEvent to `Milestones.all`.
10. **Wharfmaster's Pier action** — Define `wharfmaster_travel`. Conditional render on `wharfmaster_pier_visible` flag.
11. **Coast obelisk actions** — Add 3 obelisk-equivalent actions to their respective Coast zones.
12. **Fragment drop wiring** — Append drop calls in `_completeAction` for each new action id. Ensure unlock side-effects fire BEFORE drop calls for `walk_eastern_coastal_path`.
13. **Storm-Swell travel block** — In `travelTo`, refuse Coast zones during Storm Swell with log message.
14. **Pearl gather weather gate** — In `startAction`, refuse `dive_pearl_shell` / `dredge_pearl_bed` when weather != Calm.
15. **Weather display** — Add weather chip to Coast Region Status Board card. Add chip to Dashboard station-status strip when player in Coast.
16. **Salt Press empty state** — Workshop Craft sub-tab: empty-state message when Salt Press has no recipes.
17. **Tests** — written alongside each step.

Each numbered step compiles and the game runs.

### 5.4 Migration & backward compatibility

No persistence; no save migration. Player first-launch change:
- Existing fragment progression (Wilds + Stone) unchanged
- Once `breaches_concept_known` fires (Spec 2 milestone), new Town Square action appears
- Coast becomes the next exploration goal

For sessions where `breaches_concept_known` already fired pre-Spec-3, the scout appears immediately.

### 5.5 Documentation updates

- `README.md` — extend "World" section noting the Sundered Coast biome
- Inline `///` doc comments on `_maybeRollCoastWeather`, `_calculateStormChance`, unlock-flow block, Storm-Swell `travelTo` refusal

### 5.6 Risks & deferrals

- **Storm-Swell at 15% chance may feel oppressive** for new Coast arrivals. Cap at 50% prevents worst case but baseline 15% means ~9 minutes of storm per hour. Mitigation: rates are numeric literals in `_calculateStormChance` — single-PR balance pass post-Spec-3.
- **Resources without consumers in Spec 3.** Players may feel "what's the point?" Mitigation: shop value gives gold-conversion; Spec 4 lands recipes within a sprint.
- **Salt Press as visible-but-empty station.** Could confuse new players. Mitigation: clear empty-state message + tier upgrades work mechanically.
- **Coast III hazards aggressive** (15% gather, 25% combat). Mitigation: matches Darkstone II pattern.
- **Deferred to Spec 4:** Salt Press recipes; Sea Fog combat-crit bonus; Driftwood as substitute in tool recipes
- **Deferred to Spec 5:** Echo of the Tide combat; Drowned Lighthouse cleansing ritual; breach-cleansed flags affecting weather; Source-tag drop activation
- **Deferred to Spec 6:** Wharfmaster as merchant; Coast achievements; daily tasks involving Coast resources

### 5.7 Player walkthrough

A player after Spec 3 ships:

1. Continues normal play through Whispering Woods + Darkstone Mine
2. Collects fragments from both biomes → second_breach_concept milestone fires
3. Returns to Town Square → new card: **"Walk the Eastern Coastal Path"**
4. Taps it → 8-second Wayfinding action → completion fires major modal: *"A salt-crusted stranger limps into Town Square..."*
5. Town Square now shows: **"⚓ Take the Pier to the Coast"**
6. Region Status Board: **Sundered Coast I** as Anomalous
7. **Investigate the Tide** quest in Quest Log
8. Travels to Coast → new actions: Kelp, Driftwood, Salt Crystal, Tide Hounds, pier glyph
9. Eventually sees Storm Swell chip → tries to travel Coast: *"The Wharfmaster shakes his head."*
10. Reads pier glyph multiple times → Tide-tag fragments → Tide tab fills
11. Collects 10 Tide → solves puzzle → reads *The Keeper's Last Page* → Cleanse the Tide quest unlocks with Coming Soon objectives
12. Builds Salt Press → no recipes yet but upgradable
13. Pushes to Tier 2 → Tier 3 Drowned Lighthouse → reads plaque (Old Empire chance) → approaches lamp room → senses Echo waits (Spec 5)

The game now has three biomes, real weather, and a third major content arc.
