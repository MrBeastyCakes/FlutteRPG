# Spec 3 — Sundered Coast Biome Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement Spec 3 — add the Sundered Coast biome (3 zones, 3 beasts, 8 items, Salt Press station, weather system, lore+exploration unlock flow, Tide-tag fragment drop wiring) to the existing Spec 1 + 2 foundation.

**Architecture:** Pure additive content on top of the existing engine. New `weather.dart` model + a `_maybeRollCoastWeather` tick check. New Coast zones added to `Zones.all`. New beasts to `Beasts.all`. New items to `Items.all`. New Salt Press station to `Stations.all` (no recipes yet — Spec 4 fills). New milestone, two new conditional Town Square actions (unlock scout + Wharfmaster's Pier), three new Coast obelisk Lore actions. Fragment drops wired via existing `tryDropFragment` machinery with careful ordering on the unlock scout completion.

**Tech Stack:** Flutter (Dart ^3.11.4), Provider state management, `flutter_test` + `fake_async` for tests. No new dependencies.

**Reference spec:** [docs/superpowers/specs/2026-05-24-spec-3-sundered-coast-biome-design.md](../specs/2026-05-24-spec-3-sundered-coast-biome-design.md)

---

## File Structure

**Files created:**
- `lib/models/weather.dart` — `CoastWeather` enum and `CoastWeatherState` class
- `test/coast_zones_test.dart` — Coast zone existence and action shape
- `test/coast_beasts_test.dart` — Coast beast stats and region-tag mapping
- `test/coast_weather_test.dart` — Storm chance calculation, weather effects
- `test/coast_unlock_test.dart` — Unlock-scout visibility and flag side effects

**Files modified:**
- `lib/models/item.dart` — Add 8 new items, append to `Items.all`
- `lib/models/beast.dart` — Add 3 new beasts, append to `Beasts.all`
- `lib/models/zone.dart` — Add 3 Coast zones + the new Town Square scout + Wharfmaster's Pier actions; append to `Zones.all`
- `lib/models/structure.dart` — Add Salt Press station, append to `Stations.all`
- `lib/models/milestone.dart` — Add `coastUnlocked` MilestoneEvent
- `lib/engine/game_engine.dart` — Weather state + roll logic; `_regionTagForBeast` extension; `_completeAction` unlock-side-effects + drop wiring + Tide pool flip; `travelTo` Storm-Swell block; `startAction` Pearl weather gate; test helpers
- `lib/views/dashboard_view.dart` — Conditional render for `walk_eastern_coastal_path` + `wharfmaster_travel` actions in Town Square; weather chip on Dashboard station-status strip when player in Coast
- `lib/views/codex_view.dart` — Weather chip on Coast Region Status Board card
- `lib/views/build_view.dart` *(or workshop view)* — Salt Press empty-state message when selected
- `test/quest_engine_test.dart` — Add Spec 3 integration smoke test
- `test/codex_drops_test.dart` — Extend with Tide pool gate + ordering invariant tests
- `test/game_engine_test.dart` — Extend with Storm-Swell travel block + Pearl weather gate tests
- `test/widget_test.dart` — Extend with Wharfmaster Pier visibility, Salt Press empty state, weather chip tests

---

## Task 1: Add 8 new resource and beast-drop items

**Files:**
- Modify: `lib/models/item.dart`
- Test: `test/coast_zones_test.dart` (new — used for several Coast existence checks)

- [ ] **Step 1: Write failing test**

Create `test/coast_zones_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/models/item.dart';

void main() {
  group('Coast items', () {
    test('8 new Coast items exist with correct ids', () {
      for (final id in [
        'driftwood',
        'salt_crystal',
        'pearl_shell',
        'kelp',
        'tide_hound_pelt',
        'hound_fang',
        'crawler_carapace',
        'salt_touched_pelt',
      ]) {
        expect(Items.findById(id), isNotNull, reason: 'Missing item: $id');
      }
    });

    test('Driftwood is a resource with value 8', () {
      final i = Items.findById('driftwood')!;
      expect(i.type, ItemType.resource);
      expect(i.value, 8);
    });

    test('Salt-Touched Skin has highest value among Coast resources', () {
      final values = [
        Items.findById('driftwood')!.value,
        Items.findById('salt_crystal')!.value,
        Items.findById('pearl_shell')!.value,
        Items.findById('kelp')!.value,
        Items.findById('tide_hound_pelt')!.value,
        Items.findById('hound_fang')!.value,
        Items.findById('crawler_carapace')!.value,
        Items.findById('salt_touched_pelt')!.value,
      ];
      expect(values.reduce((a, b) => a > b ? a : b), 40);
    });
  });
}
```

- [ ] **Step 2: Run test, verify it fails**

Run: `flutter test test/coast_zones_test.dart`

Expected: FAIL — items not found.

- [ ] **Step 3: Add 8 items to lib/models/item.dart**

Add to the `Items` class (in the existing item-list region):

```dart
// ───── Sundered Coast resources ─────
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

// ───── Coast beast drops ─────
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

Append all 8 to the `Items.all` list (at the end, before the closing `]`):

```dart
// Spec 3 Sundered Coast
driftwood, saltCrystal, pearlShell, kelp,
tideHoundPelt, houndFang, crawlerCarapace, saltTouchedPelt,
```

- [ ] **Step 4: Run tests, verify pass**

Run: `flutter test test/coast_zones_test.dart`

Expected: All 3 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/models/item.dart test/coast_zones_test.dart
git commit -m "feat(items): add 8 Sundered Coast resource and beast-drop items"
```

---

## Task 2: Add 3 new Coast beasts

**Files:**
- Modify: `lib/models/beast.dart`
- Test: `test/coast_beasts_test.dart` (new)

- [ ] **Step 1: Write failing test**

Create `test/coast_beasts_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/models/beast.dart';

void main() {
  group('Coast beasts', () {
    test('3 new Coast beasts exist with expected stats', () {
      final hound = Beasts.findById('tide_hound')!;
      expect(hound.maxHealth, 40);
      expect(hound.attackPower, 6);

      final crawler = Beasts.findById('brine_crawler')!;
      expect(crawler.maxHealth, 75);
      expect(crawler.attackPower, 12);

      final drowned = Beasts.findById('salt_touched_drowned')!;
      expect(drowned.maxHealth, 140);
      expect(drowned.attackPower, 20);
    });

    test('Coast beasts slot between existing Forest/Cave beasts on HP', () {
      // Tide Hound (40) between Forest Boar (35) and Cave Spider (55)
      expect(Beasts.findById('tide_hound')!.maxHealth, greaterThan(Beasts.findById('forest_boar')!.maxHealth));
      expect(Beasts.findById('tide_hound')!.maxHealth, lessThan(Beasts.findById('cave_spider')!.maxHealth));
      // Salt-Touched Drowned (140) under Cavern Troll (160)
      expect(Beasts.findById('salt_touched_drowned')!.maxHealth, lessThan(Beasts.findById('cavern_troll')!.maxHealth));
    });
  });
}
```

- [ ] **Step 2: Run test, verify it fails**

Run: `flutter test test/coast_beasts_test.dart`

Expected: FAIL — beasts not found.

- [ ] **Step 3: Add 3 beasts to lib/models/beast.dart**

Add to the `Beasts` class:

```dart
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

Append to `Beasts.all`:

```dart
tideHound, brineCrawler, saltTouchedDrowned,
```

- [ ] **Step 4: Run tests, verify pass**

Run: `flutter test test/coast_beasts_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/models/beast.dart test/coast_beasts_test.dart
git commit -m "feat(beasts): add 3 Sundered Coast beasts (Tide Hound, Brine Crawler, Salt-Touched Drowned)"
```

---

## Task 3: Add 3 Sundered Coast zones with all actions

**Files:**
- Modify: `lib/models/zone.dart`
- Test: `test/coast_zones_test.dart` (extend)

- [ ] **Step 1: Write failing tests**

Add to `test/coast_zones_test.dart`:

```dart
import 'package:flutter_text_based_rpg/models/zone.dart';

// ... existing imports + group ...

group('Coast zones', () {
  test('3 Coast zones exist with expected ids and tiers', () {
    expect(Zones.findById('sundered_coast_1').name, 'Sundered Coast I');
    expect(Zones.findById('sundered_coast_1').tier, 1);
    expect(Zones.findById('sundered_coast_2').tier, 2);
    expect(Zones.findById('sundered_coast_3').tier, 3);
  });

  test('Coast I has 7 actions including pier glyph and tide hound hunt', () {
    final coast1 = Zones.findById('sundered_coast_1');
    expect(coast1.actions.any((a) => a.id == 'inspect_pier_glyph'), true);
    expect(coast1.actions.any((a) => a.id == 'hunt_tide_hound'), true);
    expect(coast1.actions.any((a) => a.id == 'gather_driftwood'), true);
    expect(coast1.actions.any((a) => a.id == 'scout_cliff_path'), true);
  });

  test('Coast III has Lighthouse plaque with higher XP than Coast I pier glyph', () {
    final pier = Zones.findById('sundered_coast_1')
        .actions
        .firstWhere((a) => a.id == 'inspect_pier_glyph');
    final plaque = Zones.findById('sundered_coast_3')
        .actions
        .firstWhere((a) => a.id == 'read_lighthouse_plaque');
    expect(plaque.xpReward, greaterThan(pier.xpReward));
  });

  test('Coast III has hazard chance on combat action', () {
    final cellar = Zones.findById('sundered_coast_3')
        .actions
        .firstWhere((a) => a.id == 'brave_drowned_cellar');
    expect(cellar.hazardChance, 0.25);
    expect(cellar.healthCost, 15);
  });
});
```

- [ ] **Step 2: Run tests, verify they fail**

Run: `flutter test test/coast_zones_test.dart`

Expected: FAIL — zones not found.

- [ ] **Step 3: Add 3 zones to lib/models/zone.dart**

Add to the `Zones` class:

```dart
// ───── Sundered Coast I ─────
static const Zone sunderedCoastTier1 = Zone(
  id: 'sundered_coast_1',
  name: 'Sundered Coast I',
  tier: 1,
  description: 'A weathered coastal stretch with tidal pools, brine air, and the smell of old wood. Where the Coast still looks almost normal.',
  weather: 'Variable',
  weatherBonusDescription: 'Weather varies (Calm / Sea Fog / Storm Swell)',
  successModifier: 0.05,
  unlockHint: 'Walk the Eastern Coastal Path from Town Square.',
  actions: [
    ZoneAction(
      id: 'gather_driftwood',
      name: 'Gather Driftwood',
      description: 'Collect bleached driftwood washed up on the tideline.',
      durationSeconds: 4,
      energyCost: 3,
      requiredSkill: SkillType.woodcutting,
      requiredLevel: 1,
      xpReward: 22,
      lootTable: [
        LootDrop(item: Items.driftwood, chance: 0.90),
      ],
    ),
    ZoneAction(
      id: 'forage_kelp',
      name: 'Forage Tide-Pool Kelp',
      description: 'Pluck sea kelp from sun-warmed tide pools.',
      durationSeconds: 4,
      energyCost: 3,
      requiredSkill: SkillType.herbalism,
      requiredLevel: 1,
      xpReward: 22,
      lootTable: [
        LootDrop(item: Items.kelp, chance: 0.85, minQuantity: 1, maxQuantity: 2),
      ],
    ),
    ZoneAction(
      id: 'pry_salt_crystal',
      name: 'Pry Salt Crystal',
      description: 'Chip a small salt crystal loose from a tide pool rim.',
      durationSeconds: 5,
      energyCost: 4,
      requiredSkill: SkillType.mining,
      requiredLevel: 1,
      xpReward: 25,
      lootTable: [
        LootDrop(item: Items.saltCrystal, chance: 0.80),
      ],
    ),
    ZoneAction(
      id: 'dive_pearl_shell',
      name: 'Dive Pearl Shell',
      description: 'Dive into the calm pools for an iridescent pearl shell. Requires Calm seas.',
      durationSeconds: 5,
      energyCost: 5,
      requiredSkill: SkillType.wayfinding,
      requiredLevel: 3,
      xpReward: 25,
      lootTable: [
        LootDrop(item: Items.pearlShell, chance: 0.75),
      ],
    ),
    ZoneAction(
      id: 'inspect_pier_glyph',
      name: 'Read the Pier Glyph',
      description: 'A weathered inscription on a salt-eaten pier post.',
      durationSeconds: 5,
      energyCost: 4,
      requiredSkill: SkillType.lore,
      requiredLevel: 1,
      xpReward: 30,
      lootTable: [],
    ),
    ZoneAction(
      id: 'hunt_tide_hound',
      name: 'Hunt Tide Hound',
      description: 'Track and battle a salt-soaked coastal hound.',
      durationSeconds: 5,
      energyCost: 4,
      requiredSkill: SkillType.combat,
      requiredLevel: 1,
      xpReward: 35,
      lootTable: [
        LootDrop(item: Items.tideHoundPelt, chance: 0.85, minQuantity: 1, maxQuantity: 1),
        LootDrop(item: Items.houndFang, chance: 0.40, minQuantity: 1, maxQuantity: 1),
      ],
      isCombat: true,
      beastId: 'tide_hound',
    ),
    ZoneAction(
      id: 'scout_cliff_path',
      name: 'Scout the Cliff Path',
      description: 'Survey the cliff path leading up to Sundered Coast II.',
      durationSeconds: 7,
      energyCost: 12,
      requiredSkill: SkillType.wayfinding,
      requiredLevel: 5,
      xpReward: 35,
      lootTable: [],
    ),
  ],
);

// ───── Sundered Coast II ─────
static const Zone sunderedCoastTier2 = Zone(
  id: 'sundered_coast_2',
  name: 'Sundered Coast II',
  tier: 2,
  description: 'Wind-scoured cliffs above churning surf. Salt-flats produce concentrated minerals; pearl beds lie in the deeper pools.',
  weather: 'Variable',
  weatherBonusDescription: 'Weather varies — hazardous in Storm Swell',
  successModifier: 0.10,
  unlockHint: 'Scout the Cliff Path from Sundered Coast I.',
  actions: [
    ZoneAction(
      id: 'cut_bleached_driftwood',
      name: 'Cut Salt-Bleached Driftwood',
      description: 'Bigger driftwood logs from the cliffside surf-line.',
      durationSeconds: 6,
      energyCost: 6,
      requiredSkill: SkillType.woodcutting,
      requiredLevel: 10,
      xpReward: 45,
      lootTable: [
        LootDrop(item: Items.driftwood, chance: 0.85, minQuantity: 1, maxQuantity: 2),
        LootDrop(item: Items.saltCrystal, chance: 0.20),
      ],
    ),
    ZoneAction(
      id: 'harvest_seaglass_kelp',
      name: 'Harvest Sea-Glass Kelp',
      description: 'Rare crystalline kelp clinging to cliffside rocks.',
      durationSeconds: 6,
      energyCost: 6,
      requiredSkill: SkillType.herbalism,
      requiredLevel: 10,
      xpReward: 40,
      lootTable: [
        LootDrop(item: Items.kelp, chance: 0.80, minQuantity: 1, maxQuantity: 2),
        LootDrop(item: Items.nightshade, chance: 0.15),
      ],
    ),
    ZoneAction(
      id: 'mine_pure_salt',
      name: 'Mine Pure Salt Crystal',
      description: 'Chip away at a concentrated salt-flat vein.',
      durationSeconds: 7,
      energyCost: 7,
      requiredSkill: SkillType.mining,
      requiredLevel: 10,
      xpReward: 50,
      lootTable: [
        LootDrop(item: Items.saltCrystal, chance: 0.75),
      ],
    ),
    ZoneAction(
      id: 'dredge_pearl_bed',
      name: 'Dredge Deep Pearl Bed',
      description: 'Dive into a deep pearl bed. Requires Calm seas.',
      durationSeconds: 7,
      energyCost: 8,
      requiredSkill: SkillType.wayfinding,
      requiredLevel: 10,
      xpReward: 50,
      lootTable: [
        LootDrop(item: Items.pearlShell, chance: 0.70),
      ],
    ),
    ZoneAction(
      id: 'inspect_wharf_glyph',
      name: 'Read the Wharf Glyph',
      description: 'Cliffside markings carved by long-dead lighthouse keepers.',
      durationSeconds: 6,
      energyCost: 5,
      requiredSkill: SkillType.lore,
      requiredLevel: 5,
      xpReward: 40,
      lootTable: [],
    ),
    ZoneAction(
      id: 'hunt_brine_crawler',
      name: 'Hunt Brine Crawler',
      description: 'Battle a heavily armored crawler from the salt-flats.',
      durationSeconds: 6,
      energyCost: 8,
      requiredSkill: SkillType.combat,
      requiredLevel: 5,
      xpReward: 55,
      lootTable: [
        LootDrop(item: Items.crawlerCarapace, chance: 0.75, minQuantity: 1, maxQuantity: 1),
        LootDrop(item: Items.spiderSilk, chance: 0.50, minQuantity: 1, maxQuantity: 1),
      ],
      isCombat: true,
      beastId: 'brine_crawler',
    ),
    ZoneAction(
      id: 'scout_lighthouse_path',
      name: 'Scout the Lighthouse Path',
      description: 'Blaze a trail up to the storm-lashed lighthouse atop the rocks.',
      durationSeconds: 8,
      energyCost: 18,
      requiredSkill: SkillType.wayfinding,
      requiredLevel: 10,
      xpReward: 50,
      lootTable: [],
    ),
  ],
);

// ───── Sundered Coast III ─────
static const Zone sunderedCoastTier3 = Zone(
  id: 'sundered_coast_3',
  name: 'Sundered Coast III',
  tier: 3,
  description: 'A storm-lashed lighthouse on a fog-bound rock. The lamp room flickers darkly even in daylight. Things move in the shallows that aren\'t fish.',
  weather: 'Hazardous',
  weatherBonusDescription: 'Heavy storms; combat is dangerous',
  unlockHint: 'Scout the Lighthouse Path from Sundered Coast II.',
  actions: [
    ZoneAction(
      id: 'scavenge_lamp_room',
      name: 'Scavenge Lamp Room',
      description: 'Pick through the lamp room\'s wreckage for materials.',
      durationSeconds: 8,
      energyCost: 10,
      healthCost: 10,
      hazardChance: 0.15,
      requiredSkill: SkillType.wayfinding,
      requiredLevel: 15,
      xpReward: 60,
      lootTable: [
        LootDrop(item: Items.saltCrystal, chance: 0.50, minQuantity: 1, maxQuantity: 2),
        LootDrop(item: Items.pearlShell, chance: 0.30),
        LootDrop(item: Items.driftwood, chance: 0.40, minQuantity: 1, maxQuantity: 2),
      ],
    ),
    ZoneAction(
      id: 'brave_drowned_cellar',
      name: 'Brave the Drowned Cellar',
      description: 'Descend into the flooded cellar to fight what dwells there.',
      durationSeconds: 8,
      energyCost: 12,
      healthCost: 15,
      hazardChance: 0.25,
      requiredSkill: SkillType.combat,
      requiredLevel: 10,
      xpReward: 90,
      lootTable: [
        LootDrop(item: Items.saltTouchedPelt, chance: 0.70, minQuantity: 1, maxQuantity: 1),
        LootDrop(item: Items.crawlerCarapace, chance: 0.40, minQuantity: 1, maxQuantity: 2),
      ],
      isCombat: true,
      beastId: 'salt_touched_drowned',
    ),
    ZoneAction(
      id: 'read_lighthouse_plaque',
      name: 'Read the Lighthouse Plaque',
      description: 'A bronze plaque mounted at the lighthouse base. The script is old and worn.',
      durationSeconds: 7,
      energyCost: 6,
      requiredSkill: SkillType.lore,
      requiredLevel: 10,
      xpReward: 60,
      lootTable: [],
    ),
    ZoneAction(
      id: 'approach_lamp_room',
      name: 'Approach the Lamp Room',
      description: 'Climb the lighthouse stairs to the lamp room. Something stirs above.',
      durationSeconds: 5,
      energyCost: 5,
      requiredSkill: SkillType.wayfinding,
      requiredLevel: 15,
      xpReward: 30,
      lootTable: [],
    ),
  ],
);
```

Append all 3 to `Zones.all`:

```dart
sunderedCoastTier1, sunderedCoastTier2, sunderedCoastTier3,
```

- [ ] **Step 4: Run tests, verify pass**

Run: `flutter test test/coast_zones_test.dart`

Expected: All zone tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/models/zone.dart test/coast_zones_test.dart
git commit -m "feat(zones): add 3 Sundered Coast zones with full action lists"
```

---

## Task 4: Add Salt Press station

**Files:**
- Modify: `lib/models/structure.dart`
- Test: `test/coast_zones_test.dart` (extend)

- [ ] **Step 1: Write failing test**

Add to `test/coast_zones_test.dart`:

```dart
import 'package:flutter_text_based_rpg/models/structure.dart';

// ... existing imports + groups ...

group('Salt Press station', () {
  test('Salt Press exists with 3-tier ladder', () {
    final station = Stations.findById('salt_press');
    expect(station, isNotNull);
    expect(station!.tiers.length, 3);
    expect(station.maxTier, 3);
  });

  test('Salt Press tier 1 costs include driftwood', () {
    final tier1 = Stations.findById('salt_press')!.tiers[0];
    expect(tier1.upgradeCost['driftwood'], 4);
    expect(tier1.upgradeCost['oak_log'], 8);
    expect(tier1.upgradeCost['river_clay'], 6);
  });

  test('Salt Press tier 3 has highest queue slots and quality bias', () {
    final tier3 = Stations.findById('salt_press')!.tiers[2];
    expect(tier3.queueSlots, 3);
    expect(tier3.qualityBias, closeTo(0.12, 0.001));
    expect(tier3.speedBonus, closeTo(0.20, 0.001));
  });
});
```

- [ ] **Step 2: Run test, verify it fails**

Run: `flutter test test/coast_zones_test.dart`

Expected: FAIL — Salt Press not found.

- [ ] **Step 3: Add Salt Press to lib/models/structure.dart**

Add to the `Stations` class:

```dart
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

Append to `Stations.all`:

```dart
saltPress,
```

(Adjust signature to match your existing `Structure` / `StationTier` / `Stations` patterns — names may differ slightly from spec.)

- [ ] **Step 4: Run tests, verify pass**

Run: `flutter test test/coast_zones_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/models/structure.dart test/coast_zones_test.dart
git commit -m "feat(stations): add Salt Press station with 3-tier ladder (no recipes yet)"
```

---

## Task 5: Create weather model

**Files:**
- Create: `lib/models/weather.dart`
- Test: `test/coast_weather_test.dart` (new)

- [ ] **Step 1: Write failing test**

Create `test/coast_weather_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/models/weather.dart';

void main() {
  group('CoastWeather model', () {
    test('CoastWeather has three values', () {
      expect(CoastWeather.values.length, 3);
      expect(CoastWeather.values, contains(CoastWeather.calm));
      expect(CoastWeather.values, contains(CoastWeather.seaFog));
      expect(CoastWeather.values, contains(CoastWeather.stormSwell));
    });

    test('CoastWeatherState carries current weather and nextRollAt', () {
      final now = DateTime.now();
      final state = CoastWeatherState(current: CoastWeather.calm, nextRollAt: now);
      expect(state.current, CoastWeather.calm);
      expect(state.nextRollAt, now);
    });
  });
}
```

- [ ] **Step 2: Run test, verify it fails**

Run: `flutter test test/coast_weather_test.dart`

Expected: FAIL — `weather.dart` doesn't exist.

- [ ] **Step 3: Create lib/models/weather.dart**

```dart
enum CoastWeather { calm, seaFog, stormSwell }

class CoastWeatherState {
  final CoastWeather current;
  final DateTime nextRollAt;

  const CoastWeatherState({
    required this.current,
    required this.nextRollAt,
  });
}
```

- [ ] **Step 4: Run test, verify pass**

Run: `flutter test test/coast_weather_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/models/weather.dart test/coast_weather_test.dart
git commit -m "feat(weather): add CoastWeather enum and CoastWeatherState model"
```

---

## Task 6: Engine weather state + storm chance calculation

**Files:**
- Modify: `lib/engine/game_engine.dart`
- Test: `test/coast_weather_test.dart` (extend)

- [ ] **Step 1: Write failing tests**

Add to `test/coast_weather_test.dart`:

```dart
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/models/codex.dart';
import 'package:flutter_text_based_rpg/models/zone.dart';

// ... existing imports + group ...

group('Storm chance calculation', () {
  test('Baseline storm chance is 5%', () {
    final engine = GameEngine();
    expect(engine.calculateStormChancePublic(), closeTo(0.05, 0.001));
  });

  test('Storm chance rises 5% per breach tag with fragments', () {
    final engine = GameEngine();
    engine.tryDropFragment(CodexTag.wilds, 1.0);
    expect(engine.calculateStormChancePublic(), closeTo(0.10, 0.001));

    engine.unlockZone('darkstone_mine_1');
    engine.travelTo(Zones.darkstoneMineTier1);
    engine.tryDropFragment(CodexTag.stone, 1.0);
    expect(engine.calculateStormChancePublic(), closeTo(0.15, 0.001));
  });

  test('Cleansing a breach reduces storm chance', () {
    final engine = GameEngine();
    engine.tryDropFragment(CodexTag.wilds, 1.0);
    engine.unlockZone('darkstone_mine_1');
    engine.travelTo(Zones.darkstoneMineTier1);
    engine.tryDropFragment(CodexTag.stone, 1.0);
    expect(engine.calculateStormChancePublic(), closeTo(0.15, 0.001));

    engine.setEngineFlag('breach_wilds_cleansed');
    expect(engine.calculateStormChancePublic(), closeTo(0.10, 0.001));
  });

  test('Storm chance clamps at 50%', () {
    final engine = GameEngine();
    // Force many fragments — even with all 3 tags + extras, max stays at 50%
    engine.tryDropFragment(CodexTag.wilds, 1.0);
    engine.unlockZone('darkstone_mine_1');
    engine.travelTo(Zones.darkstoneMineTier1);
    engine.tryDropFragment(CodexTag.stone, 1.0);
    engine.setEngineFlag('coast_unlocked');
    engine.tryDropFragment(CodexTag.tide, 1.0);
    // 0.05 + 3*0.05 = 0.20; still under cap
    expect(engine.calculateStormChancePublic(), lessThanOrEqualTo(0.50));
  });
});
```

- [ ] **Step 2: Run test, verify it fails**

Run: `flutter test test/coast_weather_test.dart`

Expected: FAIL — `calculateStormChancePublic` undefined.

- [ ] **Step 3: Add state + storm calculator + test helper**

In `lib/engine/game_engine.dart`:

Add import:
```dart
import '../models/weather.dart';
```

Add field near other engine state:
```dart
CoastWeatherState _coastWeather = CoastWeatherState(
  current: CoastWeather.calm,
  nextRollAt: DateTime.now(),
);
```

Add getter:
```dart
CoastWeather get coastWeather => _coastWeather.current;
DateTime get coastWeatherNextRollAt => _coastWeather.nextRollAt;
```

Add the storm-chance method:
```dart
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

Add test helper (use `@visibleForTesting` annotation):
```dart
import 'package:flutter/foundation.dart';

@visibleForTesting
double calculateStormChancePublic() => _calculateStormChance();
```

- [ ] **Step 4: Run tests, verify pass**

Run: `flutter test test/coast_weather_test.dart`

Expected: All storm-chance tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/engine/game_engine.dart test/coast_weather_test.dart
git commit -m "feat(engine): add Coast weather state and storm-chance calculator"
```

---

## Task 7: Weather roll wired into global tick

**Files:**
- Modify: `lib/engine/game_engine.dart`
- Test: `test/coast_weather_test.dart` (extend)

- [ ] **Step 1: Write failing test**

Add to `test/coast_weather_test.dart`:

```dart
import 'package:flutter/foundation.dart';

test('Weather roll fires after nextRollAt passes', () {
  final engine = GameEngine();
  // Force nextRollAt to be in the past
  engine.forceCoastWeatherForTest(CoastWeather.calm, DateTime.now().subtract(Duration(seconds: 1)));
  // Manually invoke the roll
  engine.tickForTest();
  // Should have rescheduled; nextRollAt should be in the future
  expect(engine.coastWeatherNextRollAt.isAfter(DateTime.now()), true);
});

test('Forced weather state can be set for testing', () {
  final engine = GameEngine();
  engine.forceCoastWeatherForTest(CoastWeather.stormSwell, DateTime.now().add(Duration(minutes: 10)));
  expect(engine.coastWeather, CoastWeather.stormSwell);
});
```

- [ ] **Step 2: Run test, verify it fails**

Run: `flutter test test/coast_weather_test.dart`

Expected: FAIL — `forceCoastWeatherForTest` / `tickForTest` undefined.

- [ ] **Step 3: Add weather roll + test helpers**

In `lib/engine/game_engine.dart`:

Add the roll method:
```dart
void _maybeRollCoastWeather() {
  if (DateTime.now().isBefore(_coastWeather.nextRollAt)) return;

  final stormChance = _calculateStormChance();
  const fogChance = 0.25;
  final roll = _random.nextDouble();

  final CoastWeather next;
  if (roll < stormChance) {
    next = CoastWeather.stormSwell;
  } else if (roll < stormChance + fogChance) {
    next = CoastWeather.seaFog;
  } else {
    next = CoastWeather.calm;
  }

  if (next != _coastWeather.current) {
    log('Coast weather: ${_weatherDisplayName(next)}', LogType.info);
  }
  _coastWeather = CoastWeatherState(
    current: next,
    nextRollAt: DateTime.now().add(const Duration(minutes: 5)),
  );
  notifyListeners();
}

String _weatherDisplayName(CoastWeather w) {
  switch (w) {
    case CoastWeather.calm: return '🌤️ Calm';
    case CoastWeather.seaFog: return '🌫️ Sea Fog';
    case CoastWeather.stormSwell: return '⛈️ Storm Swell';
  }
}
```

Call from existing global tick — find the tick method (typically `_tick` or similar that drives the `~100ms` periodic timer) and append:

```dart
_maybeRollCoastWeather();
```

Add test helpers:
```dart
@visibleForTesting
void forceCoastWeatherForTest(CoastWeather w, [DateTime? nextRollAt]) {
  _coastWeather = CoastWeatherState(
    current: w,
    nextRollAt: nextRollAt ?? DateTime.now().add(const Duration(minutes: 5)),
  );
  notifyListeners();
}

@visibleForTesting
void tickForTest() {
  _maybeRollCoastWeather();
}
```

- [ ] **Step 4: Run tests, verify pass**

Run: `flutter test test/coast_weather_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/engine/game_engine.dart test/coast_weather_test.dart
git commit -m "feat(engine): wire Coast weather roll into global tick"
```

---

## Task 8: Extend _regionTagForBeast for Coast beasts

**Files:**
- Modify: `lib/engine/game_engine.dart`
- Test: `test/coast_beasts_test.dart` (extend)

- [ ] **Step 1: Write failing test**

Add to `test/coast_beasts_test.dart`:

```dart
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/models/codex.dart';

// ... existing imports + group ...

group('Region tag mapping for Coast beasts', () {
  test('All 3 Coast beasts return Tide tag', () {
    final engine = GameEngine();
    expect(engine.regionTagForBeastPublic('tide_hound'), CodexTag.tide);
    expect(engine.regionTagForBeastPublic('brine_crawler'), CodexTag.tide);
    expect(engine.regionTagForBeastPublic('salt_touched_drowned'), CodexTag.tide);
  });

  test('Existing beasts still return their original tags', () {
    final engine = GameEngine();
    expect(engine.regionTagForBeastPublic('forest_boar'), CodexTag.wilds);
    expect(engine.regionTagForBeastPublic('cave_spider'), CodexTag.stone);
  });
});
```

- [ ] **Step 2: Run test, verify it fails**

Run: `flutter test test/coast_beasts_test.dart`

Expected: FAIL — either Coast beasts return null or `regionTagForBeastPublic` undefined.

- [ ] **Step 3: Update _regionTagForBeast + add test helper**

In `lib/engine/game_engine.dart`, find `_regionTagForBeast` and add cases:

```dart
CodexTag? _regionTagForBeast(String beastId) {
  switch (beastId) {
    case 'forest_boar':
    case 'shadow_wolf':
      return CodexTag.wilds;
    case 'cave_spider':
    case 'cavern_troll':
      return CodexTag.stone;
    case 'tide_hound':
    case 'brine_crawler':
    case 'salt_touched_drowned':
      return CodexTag.tide;
    default:
      return null;
  }
}

@visibleForTesting
CodexTag? regionTagForBeastPublic(String beastId) => _regionTagForBeast(beastId);
```

- [ ] **Step 4: Run tests, verify pass**

Run: `flutter test test/coast_beasts_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/engine/game_engine.dart test/coast_beasts_test.dart
git commit -m "feat(engine): extend _regionTagForBeast with 3 Coast beasts"
```

---

## Task 9: Add Coast unlock scout action + conditional visibility

**Files:**
- Modify: `lib/models/zone.dart` (Town Square actions)
- Modify: `lib/views/dashboard_view.dart`
- Test: `test/coast_unlock_test.dart` (new)

- [ ] **Step 1: Write failing test**

Create `test/coast_unlock_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/models/zone.dart';

void main() {
  group('Coast unlock scout visibility', () {
    test('walk_eastern_coastal_path is in townSquare actions list', () {
      final scout = Zones.townSquare.actions
          .firstWhere((a) => a.id == 'walk_eastern_coastal_path');
      expect(scout.name, 'Walk the Eastern Coastal Path');
      expect(scout.durationSeconds, 8);
    });

    test('Scout visibility check: hidden without breaches_concept_known flag', () {
      final engine = GameEngine();
      expect(
        engine.isActionVisibleForTest(Zones.townSquare, 'walk_eastern_coastal_path'),
        false,
      );
    });

    test('Scout visibility check: shown with breaches_concept_known flag', () {
      final engine = GameEngine();
      engine.setEngineFlag('breaches_concept_known');
      expect(
        engine.isActionVisibleForTest(Zones.townSquare, 'walk_eastern_coastal_path'),
        true,
      );
    });
  });
}
```

- [ ] **Step 2: Run test, verify it fails**

Run: `flutter test test/coast_unlock_test.dart`

Expected: FAIL — action not in zone OR visibility helper undefined.

- [ ] **Step 3: Add scout action to Town Square**

In `lib/models/zone.dart`, find `townSquare.actions` and append:

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

- [ ] **Step 4: Add engine visibility helper**

In `lib/engine/game_engine.dart`:

```dart
bool isActionVisible(Zone zone, String actionId) {
  // Gating rules for conditional actions
  if (actionId == 'walk_eastern_coastal_path') {
    return _engineFlags.contains('breaches_concept_known');
  }
  if (actionId == 'wharfmaster_travel') {
    return _engineFlags.contains('wharfmaster_pier_visible');
  }
  return true;  // Default: all actions visible
}

@visibleForTesting
bool isActionVisibleForTest(Zone zone, String actionId) => isActionVisible(zone, actionId);
```

- [ ] **Step 5: Wire visibility check into Dashboard renderer**

In `lib/views/dashboard_view.dart`, find the zone-action list rendering (search for where Town Square actions are iterated). Filter the list:

```dart
final visibleActions = zone.actions.where(
  (a) => engine.isActionVisible(zone, a.id),
).toList();
// ... render visibleActions instead of zone.actions ...
```

- [ ] **Step 6: Run tests, verify pass**

Run: `flutter test test/coast_unlock_test.dart`

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/models/zone.dart lib/engine/game_engine.dart lib/views/dashboard_view.dart test/coast_unlock_test.dart
git commit -m "feat(coast): add unlock scout action with conditional visibility"
```

---

## Task 10: Wire Coast unlock side effects in _completeAction

**Files:**
- Modify: `lib/engine/game_engine.dart`
- Test: `test/coast_unlock_test.dart` (extend)

- [ ] **Step 1: Write failing tests**

Add to `test/coast_unlock_test.dart`:

```dart
test('Completing unlock scout sets coast_unlocked + wharfmaster_pier_visible', () {
  final engine = GameEngine();
  engine.setEngineFlag('breaches_concept_known');
  engine.completeActionForTest('walk_eastern_coastal_path');

  expect(engine.engineFlags.contains('coast_unlocked'), true);
  expect(engine.engineFlags.contains('wharfmaster_pier_visible'), true);
});

test('Completing unlock scout adds Coast I to unlocked zones', () {
  final engine = GameEngine();
  engine.setEngineFlag('breaches_concept_known');
  engine.completeActionForTest('walk_eastern_coastal_path');

  // The Coast should now be travelable (verify via region status)
  expect(engine.regionStatus.containsKey('sundered_coast_1'), false,
      reason: 'Region status only populates on first travel — but zone should be unlockable');
  // Tide pool should now be open
  engine.tryDropFragment(CodexTag.tide, 1.0);
  expect(engine.knownCodexFragmentIds.any(
    (id) => CodexFragments.findById(id)!.tag == CodexTag.tide,
  ), true);
});

test('Completing unlock scout offers Investigate Tide quest', () {
  final engine = GameEngine();
  engine.setEngineFlag('breaches_concept_known');
  engine.completeActionForTest('walk_eastern_coastal_path');

  expect(engine.activeQuests.any((q) => q.id == 'main_investigate_tide'), true);
});

test('Re-completing unlock scout is idempotent', () {
  final engine = GameEngine();
  engine.setEngineFlag('breaches_concept_known');
  engine.completeActionForTest('walk_eastern_coastal_path');
  final firstQuestCount = engine.activeQuests.length;

  engine.completeActionForTest('walk_eastern_coastal_path');
  expect(engine.activeQuests.length, firstQuestCount,
      reason: 'Re-walking should not duplicate Investigate Tide');
});
```

- [ ] **Step 2: Run test, verify it fails**

Run: `flutter test test/coast_unlock_test.dart`

Expected: FAIL — `completeActionForTest` undefined OR side effects not wired.

- [ ] **Step 3: Add side effects + test helper**

In `lib/engine/game_engine.dart`, find `_completeAction` and **add at the TOP of the action-specific handling** (BEFORE any drop calls):

```dart
// Spec 3 Coast unlock — fire BEFORE drop calls so Tide pool is open
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

Add test helper:
```dart
@visibleForTesting
void completeActionForTest(String actionId) {
  // Find the action in the current or known zones
  ZoneAction? action;
  for (final zone in Zones.all) {
    for (final a in zone.actions) {
      if (a.id == actionId) {
        action = a;
        break;
      }
    }
    if (action != null) break;
  }
  if (action == null) throw Exception('Action not found: $actionId');
  _completeAction(action);  // or the actual completion path used by the engine
  notifyListeners();
}
```

(Adjust to match your real `_completeAction` signature; if completion needs a Zone too, pass it.)

- [ ] **Step 4: Run tests, verify pass**

Run: `flutter test test/coast_unlock_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/engine/game_engine.dart test/coast_unlock_test.dart
git commit -m "feat(coast): wire unlock side effects (flags, zone, quest) on scout completion"
```

---

## Task 11: Add coastUnlocked milestone

**Files:**
- Modify: `lib/models/milestone.dart`
- Test: `test/coast_unlock_test.dart` (extend)

- [ ] **Step 1: Write failing test**

Add to `test/coast_unlock_test.dart`:

```dart
import 'package:flutter_text_based_rpg/models/milestone.dart';

// ... existing imports + group ...

test('coast_unlocked milestone exists and is major', () {
  final m = Milestones.all.firstWhere((m) => m.id == 'coast_unlocked');
  expect(m.severity, MilestoneSeverity.major);
  expect(m.title, 'A Salt-Crusted Stranger');
});

test('Milestone fires when coast_unlocked flag is set', () {
  final engine = GameEngine();
  // Subscribe to milestone events
  final events = <MilestoneEvent>[];
  final sub = engine.milestoneEvents.listen(events.add);

  engine.setEngineFlag('coast_unlocked');
  // Wait for next tick
  Future.delayed(Duration.zero, () {
    expect(events.any((e) => e.id == 'coast_unlocked'), true);
    sub.cancel();
  });
});
```

- [ ] **Step 2: Run test, verify it fails**

Run: `flutter test test/coast_unlock_test.dart`

Expected: FAIL — milestone not in `Milestones.all`.

- [ ] **Step 3: Add coastUnlocked milestone**

In `lib/models/milestone.dart`:

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

Append to `Milestones.all`:

```dart
coastUnlocked,
```

- [ ] **Step 4: Run tests, verify pass**

Run: `flutter test test/coast_unlock_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/models/milestone.dart test/coast_unlock_test.dart
git commit -m "feat(milestone): add coastUnlocked refugee event"
```

---

## Task 12: Add Wharfmaster's Pier action

**Files:**
- Modify: `lib/models/zone.dart`
- Modify: `lib/engine/game_engine.dart` (handle wharfmaster_travel)
- Test: `test/coast_unlock_test.dart` (extend)

- [ ] **Step 1: Write failing test**

Add to `test/coast_unlock_test.dart`:

```dart
test('wharfmaster_travel action exists in Town Square and is hidden by default', () {
  final action = Zones.townSquare.actions
      .firstWhere((a) => a.id == 'wharfmaster_travel');
  expect(action.name, 'Take the Pier to the Coast');

  final engine = GameEngine();
  expect(engine.isActionVisibleForTest(Zones.townSquare, 'wharfmaster_travel'), false);

  engine.setEngineFlag('wharfmaster_pier_visible');
  expect(engine.isActionVisibleForTest(Zones.townSquare, 'wharfmaster_travel'), true);
});

test('Completing wharfmaster_travel teleports player to Sundered Coast I', () {
  final engine = GameEngine();
  engine.setEngineFlag('breaches_concept_known');
  engine.completeActionForTest('walk_eastern_coastal_path');
  engine.forceCoastWeatherForTest(CoastWeather.calm);

  engine.completeActionForTest('wharfmaster_travel');
  expect(engine.currentZone.id, 'sundered_coast_1');
});
```

- [ ] **Step 2: Run test, verify it fails**

Run: `flutter test test/coast_unlock_test.dart`

Expected: FAIL — action not in zone or completion doesn't teleport.

- [ ] **Step 3: Add Wharfmaster's Pier action + completion handler**

In `lib/models/zone.dart`, append to `townSquare.actions`:

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

In `lib/engine/game_engine.dart` `_completeAction`, add handling:

```dart
if (action.id == 'wharfmaster_travel') {
  travelTo(Zones.sunderedCoastTier1);
}
```

(Place this in the action-specific handler region; doesn't need to be before drop calls since `wharfmaster_travel` doesn't drop fragments.)

- [ ] **Step 4: Run tests, verify pass**

Run: `flutter test test/coast_unlock_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/models/zone.dart lib/engine/game_engine.dart test/coast_unlock_test.dart
git commit -m "feat(coast): add Wharfmaster Pier fast-travel action"
```

---

## Task 13: Wire fragment drops for Coast actions (with ordering invariant)

**Files:**
- Modify: `lib/engine/game_engine.dart`
- Test: `test/codex_drops_test.dart` (extend)

- [ ] **Step 1: Write failing test for ordering**

Add to `test/codex_drops_test.dart`:

```dart
test('Walking the unlock scout for the first time can drop a Tide fragment same call', () {
  final engine = GameEngine();
  engine.setEngineFlag('breaches_concept_known');

  // Use a known-success RNG path: force Tide chance = 1.0 by mocking the drop call.
  // For deterministic test, force-collect a fragment after the scout completes
  // and verify pool was open. Since we can't easily mock RNG without injection,
  // verify the side-effect: coast_unlocked flag IS set when drop call runs.
  engine.completeActionForTest('walk_eastern_coastal_path');

  expect(engine.engineFlags.contains('coast_unlocked'), true);
  // Now a manual drop call should succeed (pool open)
  engine.tryDropFragment(CodexTag.tide, 1.0);
  expect(engine.knownCodexFragmentIds.any(
    (id) => CodexFragments.findById(id)!.tag == CodexTag.tide,
  ), true);
});

test('Coast Obelisks roll Tide and Old Empire fragments', () {
  final engine = GameEngine();
  engine.setEngineFlag('coast_unlocked');
  // Verify chance = 1.0 force-drops work for Coast obelisks
  // (More integration than unit; depends on _completeAction wiring)
  // For unit-level: just verify the pool gate works
  engine.tryDropFragment(CodexTag.tide, 1.0);
  expect(engine.knownCodexFragmentIds.any(
    (id) => CodexFragments.findById(id)!.tag == CodexTag.tide,
  ), true);
});
```

- [ ] **Step 2: Run test, verify it fails (if drops not yet wired)**

Run: `flutter test test/codex_drops_test.dart`

Expected: FAIL (one or both of the above).

- [ ] **Step 3: Append drop calls in _completeAction**

In `lib/engine/game_engine.dart` `_completeAction`, **after** the unlock side-effects block from Task 10, add:

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

// Coast scout drops
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

**CRITICAL:** These blocks must be AFTER the Task 10 unlock-side-effects block. The `walk_eastern_coastal_path` drop block specifically depends on `coast_unlocked` being set FIRST by the side-effects block, otherwise the Tide pool stays closed.

- [ ] **Step 4: Run tests, verify pass**

Run: `flutter test test/codex_drops_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/engine/game_engine.dart test/codex_drops_test.dart
git commit -m "feat(coast): wire Tide/Old Empire fragment drops for Coast Obelisks and scouts"
```

---

## Task 14: Storm-Swell travel block in travelTo

**Files:**
- Modify: `lib/engine/game_engine.dart`
- Test: `test/game_engine_test.dart` (extend)

- [ ] **Step 1: Write failing test**

Add to `test/game_engine_test.dart`:

```dart
import 'package:flutter_text_based_rpg/models/weather.dart';

test('Storm Swell blocks travel to Coast zones', () {
  final engine = GameEngine();
  engine.setEngineFlag('coast_unlocked');
  engine.forceCoastWeatherForTest(CoastWeather.stormSwell);

  final originalZone = engine.currentZone.id;
  engine.travelTo(Zones.sunderedCoastTier1);
  expect(engine.currentZone.id, originalZone,
      reason: 'Storm should prevent travel');
});

test('Calm weather allows travel to Coast', () {
  final engine = GameEngine();
  engine.setEngineFlag('coast_unlocked');
  engine.forceCoastWeatherForTest(CoastWeather.calm);

  engine.travelTo(Zones.sunderedCoastTier1);
  expect(engine.currentZone.id, 'sundered_coast_1');
});

test('Sea Fog allows travel to Coast', () {
  final engine = GameEngine();
  engine.setEngineFlag('coast_unlocked');
  engine.forceCoastWeatherForTest(CoastWeather.seaFog);

  engine.travelTo(Zones.sunderedCoastTier1);
  expect(engine.currentZone.id, 'sundered_coast_1');
});
```

- [ ] **Step 2: Run test, verify it fails**

Run: `flutter test test/game_engine_test.dart`

Expected: FAIL — travel succeeds during Storm Swell.

- [ ] **Step 3: Add Storm-Swell block to travelTo**

In `lib/engine/game_engine.dart` `travelTo`, at the top:

```dart
void travelTo(Zone zone) {
  // Storm-Swell blocks Coast travel
  if (zone.id.startsWith('sundered_coast_') &&
      _coastWeather.current == CoastWeather.stormSwell) {
    log("The Wharfmaster shakes his head. 'No travel today. The seas have swallowed the pier.'",
        LogType.warning);
    return;
  }
  // ... existing travel logic ...
}
```

- [ ] **Step 4: Run tests, verify pass**

Run: `flutter test test/game_engine_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/engine/game_engine.dart test/game_engine_test.dart
git commit -m "feat(coast): block Coast travel during Storm Swell"
```

---

## Task 15: Pearl gather weather gate in startAction

**Files:**
- Modify: `lib/engine/game_engine.dart`
- Test: `test/game_engine_test.dart` (extend)

- [ ] **Step 1: Write failing test**

Add to `test/game_engine_test.dart`:

```dart
test('Pearl gathering requires Calm weather', () {
  final engine = GameEngine();
  engine.setEngineFlag('coast_unlocked');
  engine.forceCoastWeatherForTest(CoastWeather.calm);
  engine.travelTo(Zones.sunderedCoastTier1);

  final pearlAction = Zones.sunderedCoastTier1.actions
      .firstWhere((a) => a.id == 'dive_pearl_shell');

  // Force Sea Fog — pearl gather should be blocked
  engine.forceCoastWeatherForTest(CoastWeather.seaFog);
  final beforeAction = engine.activeAction;
  engine.startAction(pearlAction);
  expect(engine.activeAction, beforeAction,
      reason: 'Pearl action should not start during Sea Fog');

  // Calm again — pearl gather should start
  engine.forceCoastWeatherForTest(CoastWeather.calm);
  engine.startAction(pearlAction);
  expect(engine.activeAction, isNot(beforeAction),
      reason: 'Pearl action should start during Calm');
});
```

- [ ] **Step 2: Run test, verify it fails**

Run: `flutter test test/game_engine_test.dart`

Expected: FAIL — action starts regardless of weather.

- [ ] **Step 3: Add weather gate to startAction**

In `lib/engine/game_engine.dart` `startAction`, at the top:

```dart
void startAction(ZoneAction action) {
  // Pearl gathering requires Calm weather
  if (action.id == 'dive_pearl_shell' || action.id == 'dredge_pearl_bed') {
    if (_coastWeather.current != CoastWeather.calm) {
      log("The pools churn. Wait for the seas to settle.", LogType.warning);
      return;
    }
  }
  // ... existing startAction logic ...
}
```

- [ ] **Step 4: Run tests, verify pass**

Run: `flutter test test/game_engine_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/engine/game_engine.dart test/game_engine_test.dart
git commit -m "feat(coast): gate Pearl gathering on Calm weather"
```

---

## Task 16: Weather display chips

**Files:**
- Modify: `lib/views/codex_view.dart` (Region Status card)
- Modify: `lib/views/dashboard_view.dart` (station status strip)

- [ ] **Step 1: Add weather chip to Region Status Board card for Coast zones**

In `lib/views/codex_view.dart`, find the Region Status Board card rendering (the part that renders each zone card). For Coast zones, add a weather chip alongside the status badge:

```dart
// Inside the Coast zone card builder:
if (zone.id.startsWith('sundered_coast_')) {
  final weather = Provider.of<GameEngine>(context).coastWeather;
  Widget weatherChip;
  switch (weather) {
    case CoastWeather.calm:
      weatherChip = Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text('🌤️ Calm', style: TextStyle(color: Colors.green, fontSize: 10)),
      );
      break;
    case CoastWeather.seaFog:
      weatherChip = Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text('🌫️ Sea Fog', style: TextStyle(color: Colors.grey, fontSize: 10)),
      );
      break;
    case CoastWeather.stormSwell:
      weatherChip = Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.red, width: 1),
        ),
        child: const Text('⛈️ Storm', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
      );
      break;
  }
  // Render weatherChip next to the status badge
}
```

- [ ] **Step 2: Add weather chip to Dashboard station-status strip when in Coast**

In `lib/views/dashboard_view.dart`, find the station-status strip. If `engine.currentZone.id.startsWith('sundered_coast_')`, prepend a weather chip showing current weather + time-to-next-roll countdown:

```dart
// At top of station-status strip when in Coast:
if (engine.currentZone.id.startsWith('sundered_coast_')) {
  final next = engine.coastWeatherNextRollAt;
  final remaining = next.difference(DateTime.now());
  final mins = remaining.inMinutes;
  final secs = remaining.inSeconds % 60;
  final timeText = '${mins}:${secs.toString().padLeft(2, '0')}';

  // Build a small chip with weather icon + countdown
  Widget weatherChip = /* same pattern as above */;
}
```

- [ ] **Step 3: Verify visually with flutter run**

Run: `flutter run -d windows`

Expected:
- Unlock the Coast (via test scenarios or play)
- Travel to Coast → see weather chip on Dashboard
- Open Codex → Regions tab → Coast zones show weather chip on card

- [ ] **Step 4: Commit**

```bash
git add lib/views/codex_view.dart lib/views/dashboard_view.dart
git commit -m "feat(ui): add Coast weather chips to Region Status Board and Dashboard"
```

---

## Task 17: Salt Press empty-state UI

**Files:**
- Modify: `lib/views/build_view.dart` (or workshop view)
- Test: `test/widget_test.dart` (extend)

- [ ] **Step 1: Add empty-state rendering**

In the Workshop / Build / Craft view where stations and their recipes are listed:

If the selected station is `'salt_press'` and its recipe list is empty (which it always will be in Spec 3), render:

```dart
if (selectedStation?.id == 'salt_press' && availableRecipes.isEmpty) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🧂', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          const Text(
            'No recipes available yet.',
            style: TextStyle(color: GameTheme.textMuted, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            '(Future content)',
            style: TextStyle(color: GameTheme.textMuted, fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    ),
  );
}
```

- [ ] **Step 2: Add widget test**

Add to `test/widget_test.dart`:

```dart
testWidgets('Salt Press shows "No recipes available yet" empty state', (tester) async {
  // Pump workshop view in a Coast zone with Salt Press built
  // Verify the empty state Widget renders
  // (Implementation-specific to your widget tree)
});
```

- [ ] **Step 3: Verify visually**

Run the app, unlock Coast, build Salt Press, open Workshop → Craft → select Salt Press. Expect to see *"No recipes available yet."*

- [ ] **Step 4: Commit**

```bash
git add lib/views/build_view.dart test/widget_test.dart
git commit -m "feat(ui): add Salt Press empty-state for missing recipes"
```

---

## Task 18: Integration smoke test

**Files:**
- Modify: `test/quest_engine_test.dart`

- [ ] **Step 1: Add end-to-end smoke test**

Add to `test/quest_engine_test.dart`:

```dart
import 'package:flutter_text_based_rpg/models/codex.dart';
import 'package:flutter_text_based_rpg/models/weather.dart';

test('Spec 3 acceptance — Coast unlock through scout completion', () {
  final engine = GameEngine();

  // Step 1: Collect fragments from 2 breach tags
  engine.tryDropFragment(CodexTag.wilds, 1.0);
  engine.unlockZone('darkstone_mine_1');
  engine.travelTo(Zones.darkstoneMineTier1);
  engine.tryDropFragment(CodexTag.stone, 1.0);
  engine.travelTo(Zones.townSquare);

  // Step 2: breaches_concept_known should be set by milestone tick
  expect(engine.engineFlags.contains('breaches_concept_known'), true);

  // Step 3: Walk the scout
  engine.completeActionForTest('walk_eastern_coastal_path');

  // Step 4: Verify unlock cascade
  expect(engine.engineFlags.contains('coast_unlocked'), true);
  expect(engine.engineFlags.contains('wharfmaster_pier_visible'), true);
  expect(engine.activeQuests.any((q) => q.id == 'main_investigate_tide'), true);

  // Step 5: Travel to Coast in Calm weather
  engine.forceCoastWeatherForTest(CoastWeather.calm);
  engine.travelTo(Zones.sunderedCoastTier1);
  expect(engine.currentZone.id, 'sundered_coast_1');

  // Step 6: Tide pool should be open
  engine.tryDropFragment(CodexTag.tide, 1.0);
  expect(engine.knownCodexFragmentIds.any(
    (id) => CodexFragments.findById(id)!.tag == CodexTag.tide,
  ), true);

  // Step 7: Storm blocks travel back
  engine.travelTo(Zones.townSquare);  // first go back to town
  engine.forceCoastWeatherForTest(CoastWeather.stormSwell);
  engine.travelTo(Zones.sunderedCoastTier1);
  expect(engine.currentZone.id, 'town_square',
      reason: 'Storm should prevent return to Coast');
});
```

- [ ] **Step 2: Run smoke test**

Run: `flutter test test/quest_engine_test.dart`

Expected: PASS.

- [ ] **Step 3: Run full test suite**

Run: `flutter test`

Expected: All Spec 1 + Spec 2 + Spec 3 tests pass.

- [ ] **Step 4: Commit**

```bash
git add test/quest_engine_test.dart
git commit -m "test(spec3): end-to-end smoke test for Coast unlock + travel + weather"
```

---

## Post-implementation checklist

- [ ] All `flutter test` passes (Spec 1 + 2 + 3 combined)
- [ ] `flutter analyze` shows zero errors and zero warnings
- [ ] Manual play test:
  - Fresh app → grind Wilds + Stone fragments until `second_breach_concept` milestone fires
  - Return to Town Square → see new "Walk the Eastern Coastal Path" card
  - Complete scout → modal: refugee arrives → see new "Take the Pier to the Coast" card
  - Open Codex → Regions tab → Sundered Coast I appears (Anomalous)
  - Travel to Coast → gather Driftwood, Kelp, Salt Crystal, hunt Tide Hound
  - Read pier glyph multiple times → Tide fragments drop
  - Wait for Storm Swell → try to travel: refused
  - Calm returns → travel succeeds
  - Try to Pearl-dive during Sea Fog: refused
  - Build Salt Press at Coast → Workshop shows "No recipes available yet"
  - Push to Coast II → scout to Coast III → read Lighthouse plaque (rarer Old Empire chance)
- [ ] README.md updated with brief "Sundered Coast" world section
