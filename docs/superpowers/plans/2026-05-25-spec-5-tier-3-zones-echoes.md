# Spec 5 — Tier-3 Zones & Echoes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement Spec 5 — 2 new Tier-3 zones (Bloomwither Hollow + The Glowing Vein), 3 Echo bosses with 3-phase HP-gated combat, 3 cleansing actions in Town Square, 3 narrative cleansing rituals, 3 Echo Essence + 3 Cleansing Token items, 4 new T3 resources, breach/first-breach/nexus flag wiring.

**Architecture:** Additive on top of Spec 4's combat depth. New `EchoPhase` class + `BeastPassive` enum extend the existing `Beast` model. Phase transitions wired into `_resolveCombatRound`. Cleansing rituals reuse the existing Masterwork narrative-trial machinery (3 new `MasterworkTask` constants). Cleansing dispatch flows through a new `_onCleansingComplete` helper that bypasses Masterwork cap-unlock logic and instead sets breach flags + grants Tokens + advances `comingSoon` quest objectives manually.

**Tech Stack:** Flutter (Dart ^3.11.4), Provider state management, `flutter_test` + `fake_async`. No new dependencies.

**Reference spec:** [docs/superpowers/specs/2026-05-25-spec-5-tier-3-zones-echoes-design.md](../specs/2026-05-25-spec-5-tier-3-zones-echoes-design.md)

---

## File Structure

**Files created:**
- `test/spec5_items_test.dart` — 10 new items + single-emoji enforcement
- `test/spec5_zones_test.dart` — Bloomwither + Glowing Vein content
- `test/echo_combat_test.dart` — phase transitions, passives, post-fight narrative
- `test/cleansing_test.dart` — burn action visibility, ritual dispatch, flag cascade

**Files modified:**
- `lib/models/item.dart` — add 10 new items (4 resources + 3 Essences + 3 Tokens)
- `lib/models/beast.dart` — extend `Beast` with `phases` field; add `EchoPhase` + `BeastPassive`; add 3 Echo beasts + shared ability constants
- `lib/models/zone.dart` — add `whisperingWoodsTier3` (Bloomwither Hollow), `darkstoneMineTier3` (Glowing Vein); append `hunt_echo_of_tide` to Coast III; wire `approach_lamp_room` to set `drowned_lighthouse_spoken` flag; append 3 burn actions to `townSquare.actions`
- `lib/models/masterwork.dart` — add 3 cleansing ritual MasterworkTask constants; extend `MasterworkTasks.all` / `findById`
- `lib/models/milestone.dart` — add 7 new MilestoneEvents (3 Breach Introductions + 4 cleansing-celebration)
- `lib/engine/game_engine.dart` — extend `CombatState` with phase fields; add `_checkEchoPhaseTransition`; wire phase passives in `_resolveCombatRound`; extend `isActionVisible`; extend `_completeAction` for burn actions + `approach_lamp_room`; add `_startCleansingRitual` + `_onCleansingComplete`; modify `_onMasterworkSuccess` to dispatch cleansings; add post-Echo-defeat narrative log entry
- `test/quest_engine_test.dart` — extend with Spec 5 end-to-end smoke test

---

## Task 1: Add 4 new T3 resources

**Files:**
- Modify: `lib/models/item.dart`
- Test: `test/spec5_items_test.dart` (new)

- [ ] **Step 1: Write failing test**

Create `test/spec5_items_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/models/item.dart';

void main() {
  group('Spec 5 T3 resources', () {
    test('4 new resources exist', () {
      for (final id in ['ironbark_log', 'glinting_ore', 'corrupted_wildflower', 'corrupted_iron_dust']) {
        expect(Items.findById(id), isNotNull, reason: 'Missing: $id');
      }
    });

    test('Ironbark Log has value 50', () {
      expect(Items.findById('ironbark_log')!.value, 50);
    });

    test('All Spec 5 resources are ItemType.resource', () {
      for (final id in ['ironbark_log', 'glinting_ore', 'corrupted_wildflower', 'corrupted_iron_dust']) {
        expect(Items.findById(id)!.type, ItemType.resource);
      }
    });
  });
}
```

- [ ] **Step 2: Run test, verify it fails**

Run: `flutter test test/spec5_items_test.dart`

Expected: FAIL.

- [ ] **Step 3: Add 4 items to lib/models/item.dart**

```dart
static const Item ironbarkLog = Item(
  id: 'ironbark_log',
  name: 'Ironbark Log',
  description: 'A log of true Ironbark, rare and impossibly hard. Sought by master weaponsmiths.',
  icon: '🪵',
  type: ItemType.resource,
  value: 50,
);

static const Item glintingOre = Item(
  id: 'glinting_ore',
  name: 'Glinting Ore',
  description: 'A pulsing chunk of stone that glows faintly without flame. Heavier than it should be.',
  icon: '💎',
  type: ItemType.resource,
  value: 55,
);

static const Item corruptedWildflower = Item(
  id: 'corrupted_wildflower',
  name: 'Corrupted Wildflower',
  description: 'A bluebell veined with black sap. Smells of old iron. Useful as a crafting modifier.',
  icon: '🪻',
  type: ItemType.resource,
  value: 30,
);

static const Item corruptedIronDust = Item(
  id: 'corrupted_iron_dust',
  name: 'Corrupted Iron Dust',
  description: 'A fine glittering dust skimmed from the Glinting wall. Pungent. Used as a crafting modifier.',
  icon: '🧂',
  type: ItemType.resource,
  value: 35,
);
```

Append all 4 to `Items.all`.

- [ ] **Step 4: Run tests, verify pass**

- [ ] **Step 5: Commit**

```bash
git add lib/models/item.dart test/spec5_items_test.dart
git commit -m "feat(items): add 4 Tier-3 resources (Ironbark Log, Glinting Ore, Corrupted Wildflower, Corrupted Iron Dust)"
```

---

## Task 2: Add 3 Echo Essence + 3 Cleansing Token items

**Files:**
- Modify: `lib/models/item.dart`
- Test: `test/spec5_items_test.dart` (extend)

- [ ] **Step 1: Write failing test**

Add to `test/spec5_items_test.dart`:

```dart
group('Echo Essences and Cleansing Tokens', () {
  test('3 Essences and 3 Tokens exist', () {
    for (final id in [
      'wilds_echo_essence', 'stone_echo_essence', 'tide_echo_essence',
      'wilds_cleansing_token', 'stone_cleansing_token', 'tide_cleansing_token',
    ]) {
      expect(Items.findById(id), isNotNull, reason: 'Missing: $id');
    }
  });

  test('Essences and Tokens are value 0 (quest items)', () {
    for (final id in [
      'wilds_echo_essence', 'stone_echo_essence', 'tide_echo_essence',
      'wilds_cleansing_token', 'stone_cleansing_token', 'tide_cleansing_token',
    ]) {
      expect(Items.findById(id)!.value, 0, reason: 'Should be unsellable: $id');
    }
  });

  test('All Spec 5 icons are single-emoji glyphs (no compound emoji)', () {
    final ids = [
      'ironbark_log', 'glinting_ore', 'corrupted_wildflower', 'corrupted_iron_dust',
      'wilds_echo_essence', 'stone_echo_essence', 'tide_echo_essence',
      'wilds_cleansing_token', 'stone_cleansing_token', 'tide_cleansing_token',
    ];
    for (final id in ids) {
      final icon = Items.findById(id)!.icon;
      // Single emoji should be 1-2 codepoints (variation selectors allowed)
      expect(icon.runes.length, lessThanOrEqualTo(2),
          reason: 'Compound emoji forbidden in: $id (icon=$icon)');
    }
  });
});
```

- [ ] **Step 2: Run test, verify it fails**

Expected: FAIL.

- [ ] **Step 3: Add 6 items to lib/models/item.dart**

```dart
static const Item wildsEchoEssence = Item(
  id: 'wilds_echo_essence', name: 'Wilds Echo Essence',
  description: 'A pulsing green mote you tore from the Echo of the Wilds. Carry it to the Town Center and burn it.',
  icon: '🌿', type: ItemType.resource, value: 0,
);

static const Item stoneEchoEssence = Item(
  id: 'stone_echo_essence', name: 'Stone Echo Essence',
  description: 'A cold crystalline mote you wrested from the Echo of the Stone. Carry it to the Town Center and burn it.',
  icon: '💎', type: ItemType.resource, value: 0,
);

static const Item tideEchoEssence = Item(
  id: 'tide_echo_essence', name: 'Tide Echo Essence',
  description: 'A briny pulsing mote you pulled from the Echo of the Tide. Carry it to the Town Center and burn it.',
  icon: '🌊', type: ItemType.resource, value: 0,
);

static const Item wildsCleansingToken = Item(
  id: 'wilds_cleansing_token', name: 'Wilds Cleansing Token',
  description: 'A small carved seed-shape, warm to the touch. Proof that the Wilds breach is sealed.',
  icon: '🟢', type: ItemType.resource, value: 0,
);

static const Item stoneCleansingToken = Item(
  id: 'stone_cleansing_token', name: 'Stone Cleansing Token',
  description: 'A smooth stone disc, cold and silent. Proof that the Stone breach is sealed.',
  icon: '⚪', type: ItemType.resource, value: 0,
);

static const Item tideCleansingToken = Item(
  id: 'tide_cleansing_token', name: 'Tide Cleansing Token',
  description: 'A salt-crusted shell-fragment that hums quietly. Proof that the Tide breach is sealed.',
  icon: '🔵', type: ItemType.resource, value: 0,
);
```

Append all 6 to `Items.all`.

- [ ] **Step 4: Run tests, verify pass**

- [ ] **Step 5: Commit**

```bash
git add lib/models/item.dart test/spec5_items_test.dart
git commit -m "feat(items): add 3 Echo Essences + 3 Cleansing Tokens"
```

---

## Task 3: Extend Beast model with EchoPhase + BeastPassive

**Files:**
- Modify: `lib/models/beast.dart`
- Test: `test/echo_combat_test.dart` (new)

- [ ] **Step 1: Write failing test**

Create `test/echo_combat_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/models/beast.dart';

void main() {
  group('EchoPhase model', () {
    test('EchoPhase carries hpThreshold, ability, narration, passive', () {
      const ability = BeastAbility(
        id: 'test', name: 'Test', cooldownRounds: 3,
        telegraphText: 'test telegraph',
        effect: BeastSpecialEffect.bigHit,
      );
      const phase = EchoPhase(
        hpThreshold: 0.5,
        ability: ability,
        entryNarration: 'entering phase 2',
        passive: BeastPassive.healOnHit,
      );
      expect(phase.hpThreshold, 0.5);
      expect(phase.passive, BeastPassive.healOnHit);
    });

    test('BeastPassive has 5 values', () {
      expect(BeastPassive.values.length, 5);
      expect(BeastPassive.values, containsAll([
        BeastPassive.none,
        BeastPassive.healOnHit,
        BeastPassive.damageReduction,
        BeastPassive.reducedAccuracy,
        BeastPassive.enrage,
      ]));
    });
  });
}
```

- [ ] **Step 2: Run, verify it fails**

Expected: FAIL — classes undefined.

- [ ] **Step 3: Extend lib/models/beast.dart**

Add at top of file (alongside existing `BeastAbility` from Spec 4):

```dart
enum BeastPassive {
  none,
  healOnHit,
  damageReduction,
  reducedAccuracy,
  enrage,
}

class EchoPhase {
  final double hpThreshold;
  final BeastAbility ability;
  final String entryNarration;
  final BeastPassive? passive;

  const EchoPhase({
    required this.hpThreshold,
    required this.ability,
    required this.entryNarration,
    this.passive,
  });
}
```

Extend `Beast` class with a new field:

```dart
class Beast {
  // existing fields...
  final List<EchoPhase>? phases;

  const Beast({
    // existing required + optional...
    this.phases,
  });
}
```

- [ ] **Step 4: Run, verify pass**

- [ ] **Step 5: Commit**

```bash
git add lib/models/beast.dart test/echo_combat_test.dart
git commit -m "feat(beast): add EchoPhase + BeastPassive + phases field on Beast"
```

---

## Task 4: Add 3 Echo beasts with phase configurations

**Files:**
- Modify: `lib/models/beast.dart`
- Test: `test/echo_combat_test.dart` (extend)

- [ ] **Step 1: Write failing test**

Add to `test/echo_combat_test.dart`:

```dart
group('3 Echo beasts exist with 3 phases each', () {
  test('Echo of the Wilds has 3 phases', () {
    final echo = Beasts.findById('echo_of_wilds')!;
    expect(echo.phases, isNotNull);
    expect(echo.phases!.length, 3);
    expect(echo.phases![0].passive, BeastPassive.none);
    expect(echo.phases![1].passive, BeastPassive.healOnHit);
    expect(echo.phases![2].passive, BeastPassive.enrage);
    expect(echo.icon, '👁️');
    expect(echo.maxHealth, 240);
  });

  test('Echo of the Stone has 3 phases with damageReduction at P2', () {
    final echo = Beasts.findById('echo_of_stone')!;
    expect(echo.phases![1].passive, BeastPassive.damageReduction);
    expect(echo.maxHealth, 280);
    expect(echo.defense, 8);
  });

  test('Echo of the Tide has 3 phases with reducedAccuracy at P2', () {
    final echo = Beasts.findById('echo_of_tide')!;
    expect(echo.phases![1].passive, BeastPassive.reducedAccuracy);
    expect(echo.maxHealth, 260);
  });

  test('All 3 Echoes use single 👁️ emoji', () {
    for (final id in ['echo_of_wilds', 'echo_of_stone', 'echo_of_tide']) {
      expect(Beasts.findById(id)!.icon, '👁️');
    }
  });

  test('Phase thresholds are 1.0 / 0.66 / 0.33', () {
    final echo = Beasts.findById('echo_of_wilds')!;
    expect(echo.phases![0].hpThreshold, 1.0);
    expect(echo.phases![1].hpThreshold, closeTo(0.66, 0.01));
    expect(echo.phases![2].hpThreshold, closeTo(0.33, 0.01));
  });
});
```

- [ ] **Step 2: Run, verify it fails**

- [ ] **Step 3: Add 3 Echoes + shared ability constants**

In `lib/models/beast.dart`, in the `Beasts` class:

```dart
// Shared ability constants — referenced by Echo phases:
static const BeastAbility _strangleVines = BeastAbility(
  id: 'strangle_vines',
  name: 'Strangle Vines',
  cooldownRounds: 3,
  telegraphText: 'Roots burst around your feet.',
  effect: BeastSpecialEffect.drainOverTime,
);

static const BeastAbility _quake = BeastAbility(
  id: 'quake',
  name: 'Quake',
  cooldownRounds: 3,
  telegraphText: 'The cavern wall groans.',
  effect: BeastSpecialEffect.bigHitStun,
);

static const BeastAbility _stormShroud = BeastAbility(
  id: 'storm_shroud',
  name: 'Storm Shroud',
  cooldownRounds: 3,
  telegraphText: 'The fog thickens. You lose the lamp.',
  effect: BeastSpecialEffect.accuracyDebuff,
);

static const Beast echoOfWilds = Beast(
  id: 'echo_of_wilds',
  name: 'Echo of the Wilds',
  icon: '👁️',
  maxHealth: 240,
  attackPower: 18,
  defense: 4,
  xpReward: 280,
  lootTable: [
    LootDrop(item: Items.wildsEchoEssence, chance: 1.0, minQuantity: 1, maxQuantity: 1),
    LootDrop(item: Items.ironbarkLog, chance: 0.50, minQuantity: 1, maxQuantity: 2),
    LootDrop(item: Items.wolfPelt, chance: 0.40, minQuantity: 1, maxQuantity: 1),
  ],
  ability: _strangleVines,
  phases: [
    EchoPhase(hpThreshold: 1.0, ability: _strangleVines, entryNarration: 'You face the Echo of the Wilds.', passive: BeastPassive.none),
    EchoPhase(hpThreshold: 0.66, ability: _strangleVines, entryNarration: 'The Echo trembles — vines knit closed its wounds. It heals as it fights.', passive: BeastPassive.healOnHit),
    EchoPhase(hpThreshold: 0.33, ability: _strangleVines, entryNarration: 'The Hollow itself rises against you. The Echo will not slow.', passive: BeastPassive.enrage),
  ],
);

static const Beast echoOfStone = Beast(
  id: 'echo_of_stone',
  name: 'Echo of the Stone',
  icon: '👁️',
  maxHealth: 280,
  attackPower: 16,
  defense: 8,
  xpReward: 320,
  lootTable: [
    LootDrop(item: Items.stoneEchoEssence, chance: 1.0, minQuantity: 1, maxQuantity: 1),
    LootDrop(item: Items.glintingOre, chance: 0.50, minQuantity: 1, maxQuantity: 2),
    LootDrop(item: Items.trollClaw, chance: 0.40, minQuantity: 1, maxQuantity: 1),
  ],
  ability: _quake,
  phases: [
    EchoPhase(hpThreshold: 1.0, ability: _quake, entryNarration: 'You face the Echo of the Stone.', passive: BeastPassive.none),
    EchoPhase(hpThreshold: 0.66, ability: _quake, entryNarration: "The Echo's surface hardens to crystal. Your blade rings dull.", passive: BeastPassive.damageReduction),
    EchoPhase(hpThreshold: 0.33, ability: _quake, entryNarration: "The cavern wall pulses with the Echo's heartbeat. It will not be slowed.", passive: BeastPassive.enrage),
  ],
);

static const Beast echoOfTide = Beast(
  id: 'echo_of_tide',
  name: 'Echo of the Tide',
  icon: '👁️',
  maxHealth: 260,
  attackPower: 17,
  defense: 5,
  xpReward: 300,
  lootTable: [
    LootDrop(item: Items.tideEchoEssence, chance: 1.0, minQuantity: 1, maxQuantity: 1),
    LootDrop(item: Items.pearlShell, chance: 0.50, minQuantity: 1, maxQuantity: 2),
    LootDrop(item: Items.saltTouchedPelt, chance: 0.40, minQuantity: 1, maxQuantity: 1),
  ],
  ability: _stormShroud,
  phases: [
    EchoPhase(hpThreshold: 1.0, ability: _stormShroud, entryNarration: 'You face the Echo of the Tide.', passive: BeastPassive.none),
    EchoPhase(hpThreshold: 0.66, ability: _stormShroud, entryNarration: 'The fog thickens around the Echo. You can barely see your own hands.', passive: BeastPassive.reducedAccuracy),
    EchoPhase(hpThreshold: 0.33, ability: _stormShroud, entryNarration: 'The Drowned rise from the surf. The Echo summons its kin.', passive: BeastPassive.enrage),
  ],
);
```

Append all 3 to `Beasts.all`.

- [ ] **Step 4: Run, verify pass**

- [ ] **Step 5: Commit**

```bash
git add lib/models/beast.dart test/echo_combat_test.dart
git commit -m "feat(beast): add 3 Echo bosses with 3-phase HP-gated configurations"
```

---

## Task 5: Add Bloomwither Hollow zone

**Files:**
- Modify: `lib/models/zone.dart`
- Test: `test/spec5_zones_test.dart` (new)

- [ ] **Step 1: Write failing test**

Create `test/spec5_zones_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/models/zone.dart';

void main() {
  group('Bloomwither Hollow (Whispering Woods III)', () {
    test('Zone exists with id whispering_woods_3', () {
      final zone = Zones.findById('whispering_woods_3');
      expect(zone, isNotNull);
      expect(zone!.tier, 3);
    });

    test('Has 5 actions including Echo hunt', () {
      final zone = Zones.findById('whispering_woods_3')!;
      final ids = zone.actions.map((a) => a.id).toSet();
      expect(ids, containsAll([
        'fell_ironbark',
        'pluck_corrupted_bloom',
        'read_hollow_plaque',
        'hunt_corrupted_wolf',
        'hunt_echo_of_wilds',
      ]));
    });

    test('Reuses shadow_wolf beastId for corrupted guard', () {
      final zone = Zones.findById('whispering_woods_3')!;
      final corruptedWolf = zone.actions.firstWhere((a) => a.id == 'hunt_corrupted_wolf');
      expect(corruptedWolf.beastId, 'shadow_wolf');
    });

    test('Fell Ironbark has 0.20 hazard chance', () {
      final zone = Zones.findById('whispering_woods_3')!;
      final fell = zone.actions.firstWhere((a) => a.id == 'fell_ironbark');
      expect(fell.hazardChance, closeTo(0.20, 0.001));
      expect(fell.healthCost, 12);
    });
  });
}
```

- [ ] **Step 2: Run, verify it fails**

- [ ] **Step 3: Add zone to lib/models/zone.dart**

```dart
static const Zone whisperingWoodsTier3 = Zone(
  id: 'whispering_woods_3',
  name: 'Bloomwither Hollow',
  tier: 3,
  description: 'A twilight grove where corruption manifests visibly. Black sap weeps from Ironbarks; the rotted shrine at the center pulses faintly.',
  weather: 'Twilight',
  weatherBonusDescription: 'The Hollow watches.',
  unlockHint: 'Scout the deep groves from Whispering Woods II.',
  actions: [
    ZoneAction(
      id: 'fell_ironbark',
      name: 'Fell Ironbark',
      description: 'Cut a true Ironbark tree. The wood fights back.',
      durationSeconds: 9,
      energyCost: 12,
      healthCost: 12,
      hazardChance: 0.20,
      requiredSkill: SkillType.woodcutting,
      requiredLevel: 15,
      xpReward: 75,
      lootTable: [
        LootDrop(item: Items.ironbarkLog, chance: 0.65, minQuantity: 1, maxQuantity: 1),
        LootDrop(item: Items.oakLog, chance: 0.30, minQuantity: 1, maxQuantity: 2),
      ],
    ),
    ZoneAction(
      id: 'pluck_corrupted_bloom',
      name: 'Pluck Corrupted Wildflower',
      description: 'A bluebell veined with black sap. Be careful what you breathe.',
      durationSeconds: 7,
      energyCost: 10,
      healthCost: 8,
      hazardChance: 0.15,
      requiredSkill: SkillType.herbalism,
      requiredLevel: 15,
      xpReward: 65,
      lootTable: [
        LootDrop(item: Items.corruptedWildflower, chance: 0.70, minQuantity: 1, maxQuantity: 1),
        LootDrop(item: Items.nightshade, chance: 0.20, minQuantity: 1, maxQuantity: 1),
      ],
    ),
    ZoneAction(
      id: 'read_hollow_plaque',
      name: 'Read the Hollow Plaque',
      description: 'A bronze plaque mounted at the rotted shrine. The script is wrong somehow.',
      durationSeconds: 8,
      energyCost: 8,
      requiredSkill: SkillType.lore,
      requiredLevel: 12,
      xpReward: 70,
      lootTable: [],
    ),
    ZoneAction(
      id: 'hunt_corrupted_wolf',
      name: 'Hunt the Corrupted Wolf',
      description: 'A wolf with mismatched eyes that does not retreat.',
      durationSeconds: 7,
      energyCost: 10,
      requiredSkill: SkillType.combat,
      requiredLevel: 12,
      xpReward: 75,
      lootTable: [
        LootDrop(item: Items.wolfPelt, chance: 0.70, minQuantity: 1, maxQuantity: 1),
        LootDrop(item: Items.corruptedWildflower, chance: 0.30, minQuantity: 1, maxQuantity: 1),
      ],
      isCombat: true,
      beastId: 'shadow_wolf',
    ),
    ZoneAction(
      id: 'hunt_echo_of_wilds',
      name: 'Hunt the Echo of the Wilds',
      description: 'Approach the rotted shrine. Whatever waits there waits for you.',
      durationSeconds: 12,
      energyCost: 18,
      requiredSkill: SkillType.combat,
      requiredLevel: 15,
      xpReward: 200,
      lootTable: [
        LootDrop(item: Items.wildsEchoEssence, chance: 1.0, minQuantity: 1, maxQuantity: 1),
        LootDrop(item: Items.ironbarkLog, chance: 0.50, minQuantity: 1, maxQuantity: 2),
        LootDrop(item: Items.wolfPelt, chance: 0.40, minQuantity: 1, maxQuantity: 1),
      ],
      isCombat: true,
      beastId: 'echo_of_wilds',
    ),
  ],
);
```

Append to `Zones.all`: `whisperingWoodsTier3`.

- [ ] **Step 4: Run, verify pass**

- [ ] **Step 5: Commit**

```bash
git add lib/models/zone.dart test/spec5_zones_test.dart
git commit -m "feat(zone): add Bloomwither Hollow (Whispering Woods III)"
```

---

## Task 6: Add Glowing Vein zone

**Files:**
- Modify: `lib/models/zone.dart`
- Test: `test/spec5_zones_test.dart` (extend)

- [ ] **Step 1: Write failing test**

Add to `test/spec5_zones_test.dart`:

```dart
group('Glowing Vein (Darkstone Mine III)', () {
  test('Zone exists with id darkstone_mine_3', () {
    final zone = Zones.findById('darkstone_mine_3');
    expect(zone, isNotNull);
    expect(zone!.tier, 3);
  });

  test('Has 5 actions including Echo hunt', () {
    final zone = Zones.findById('darkstone_mine_3')!;
    final ids = zone.actions.map((a) => a.id).toSet();
    expect(ids, containsAll([
      'mine_glinting_ore',
      'sift_iron_dust',
      'read_vein_glyph',
      'slay_corrupted_troll',
      'hunt_echo_of_stone',
    ]));
  });

  test('Reuses cavern_troll for corrupted guard', () {
    final zone = Zones.findById('darkstone_mine_3')!;
    final troll = zone.actions.firstWhere((a) => a.id == 'slay_corrupted_troll');
    expect(troll.beastId, 'cavern_troll');
  });
});
```

- [ ] **Step 2: Run, verify it fails**

- [ ] **Step 3: Add zone to lib/models/zone.dart**

```dart
static const Zone darkstoneMineTier3 = Zone(
  id: 'darkstone_mine_3',
  name: 'The Glowing Vein',
  tier: 3,
  description: 'A deep cavern where corruption has crystallized into a pulsing lens of stone. The foreman\'s lantern still hangs unlit at the entrance.',
  weather: 'Pulsing Glow',
  weatherBonusDescription: 'The wound watches.',
  unlockHint: 'Survey the deepest shafts from Darkstone Mine II.',
  actions: [
    ZoneAction(
      id: 'mine_glinting_ore',
      name: 'Mine the Glinting Ore',
      description: 'A vein that pulses like a slow heart. Keep your distance.',
      durationSeconds: 9,
      energyCost: 12,
      healthCost: 12,
      hazardChance: 0.20,
      requiredSkill: SkillType.mining,
      requiredLevel: 15,
      xpReward: 75,
      lootTable: [
        LootDrop(item: Items.glintingOre, chance: 0.65, minQuantity: 1, maxQuantity: 1),
        LootDrop(item: Items.ironOre, chance: 0.40, minQuantity: 1, maxQuantity: 2),
      ],
    ),
    ZoneAction(
      id: 'sift_iron_dust',
      name: 'Sift Corrupted Iron Dust',
      description: 'Scrape the wall — it leaves a fine glittering dust.',
      durationSeconds: 7,
      energyCost: 10,
      healthCost: 8,
      hazardChance: 0.15,
      requiredSkill: SkillType.mining,
      requiredLevel: 15,
      xpReward: 65,
      lootTable: [
        LootDrop(item: Items.corruptedIronDust, chance: 0.70, minQuantity: 1, maxQuantity: 1),
        LootDrop(item: Items.ironOre, chance: 0.30, minQuantity: 1, maxQuantity: 1),
      ],
    ),
    ZoneAction(
      id: 'read_vein_glyph',
      name: 'Read the Vein Glyph',
      description: 'Faintly glowing runes carved into the cavern wall.',
      durationSeconds: 8,
      energyCost: 8,
      requiredSkill: SkillType.lore,
      requiredLevel: 12,
      xpReward: 70,
      lootTable: [],
    ),
    ZoneAction(
      id: 'slay_corrupted_troll',
      name: 'Slay the Corrupted Troll',
      description: 'A troll that watches you with the wrong patience.',
      durationSeconds: 8,
      energyCost: 12,
      requiredSkill: SkillType.combat,
      requiredLevel: 12,
      xpReward: 100,
      lootTable: [
        LootDrop(item: Items.trollClaw, chance: 0.70, minQuantity: 1, maxQuantity: 1),
        LootDrop(item: Items.corruptedIronDust, chance: 0.30, minQuantity: 1, maxQuantity: 1),
      ],
      isCombat: true,
      beastId: 'cavern_troll',
    ),
    ZoneAction(
      id: 'hunt_echo_of_stone',
      name: 'Hunt the Echo of the Stone',
      description: 'Approach the Glinting Vein. The wound is awake.',
      durationSeconds: 14,
      energyCost: 20,
      requiredSkill: SkillType.combat,
      requiredLevel: 15,
      xpReward: 220,
      lootTable: [
        LootDrop(item: Items.stoneEchoEssence, chance: 1.0, minQuantity: 1, maxQuantity: 1),
        LootDrop(item: Items.glintingOre, chance: 0.50, minQuantity: 1, maxQuantity: 2),
        LootDrop(item: Items.trollClaw, chance: 0.40, minQuantity: 1, maxQuantity: 1),
      ],
      isCombat: true,
      beastId: 'echo_of_stone',
    ),
  ],
);
```

Append to `Zones.all`: `darkstoneMineTier3`.

- [ ] **Step 4: Run, verify pass**

- [ ] **Step 5: Commit**

```bash
git add lib/models/zone.dart test/spec5_zones_test.dart
git commit -m "feat(zone): add The Glowing Vein (Darkstone Mine III)"
```

---

## Task 7: Wire Coast III Echo + Lamp Room flag

**Files:**
- Modify: `lib/models/zone.dart`
- Test: `test/spec5_zones_test.dart` (extend)

- [ ] **Step 1: Write failing test**

Add to `test/spec5_zones_test.dart`:

```dart
group('Coast III Spec 5 additions', () {
  test('hunt_echo_of_tide action added to Sundered Coast III', () {
    final zone = Zones.findById('sundered_coast_3')!;
    expect(zone.actions.any((a) => a.id == 'hunt_echo_of_tide'), true);
  });

  test('Echo of Tide combat action references echo_of_tide beast', () {
    final zone = Zones.findById('sundered_coast_3')!;
    final echoAction = zone.actions.firstWhere((a) => a.id == 'hunt_echo_of_tide');
    expect(echoAction.beastId, 'echo_of_tide');
    expect(echoAction.isCombat, true);
  });
});
```

- [ ] **Step 2: Run, verify it fails**

- [ ] **Step 3: Add hunt_echo_of_tide to Coast III actions**

In `lib/models/zone.dart`, find `sunderedCoastTier3` and append to its `actions` list:

```dart
ZoneAction(
  id: 'hunt_echo_of_tide',
  name: 'Hunt the Echo of the Tide',
  description: 'Climb to the lamp room. Sing the note. Then fight what answers.',
  durationSeconds: 14,
  energyCost: 20,
  requiredSkill: SkillType.combat,
  requiredLevel: 15,
  xpReward: 220,
  lootTable: [
    LootDrop(item: Items.tideEchoEssence, chance: 1.0, minQuantity: 1, maxQuantity: 1),
    LootDrop(item: Items.pearlShell, chance: 0.50, minQuantity: 1, maxQuantity: 2),
    LootDrop(item: Items.saltTouchedPelt, chance: 0.40, minQuantity: 1, maxQuantity: 1),
  ],
  isCombat: true,
  beastId: 'echo_of_tide',
),
```

- [ ] **Step 4: Run, verify pass**

- [ ] **Step 5: Commit**

```bash
git add lib/models/zone.dart test/spec5_zones_test.dart
git commit -m "feat(zone): add hunt_echo_of_tide action to Sundered Coast III"
```

---

## Task 8: Add 3 Town Square burn actions + isActionVisible wiring

**Files:**
- Modify: `lib/models/zone.dart`
- Modify: `lib/engine/game_engine.dart`
- Test: `test/cleansing_test.dart` (new)

- [ ] **Step 1: Write failing test**

Create `test/cleansing_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/models/item.dart';
import 'package:flutter_text_based_rpg/models/zone.dart';

void main() {
  group('Burn action visibility', () {
    test('Hidden without Essence', () {
      final engine = GameEngine();
      expect(engine.isActionVisible(Zones.townSquare, 'burn_wilds_echo_essence'), false);
      expect(engine.isActionVisible(Zones.townSquare, 'burn_stone_echo_essence'), false);
      expect(engine.isActionVisible(Zones.townSquare, 'burn_tide_echo_essence'), false);
    });

    test('Visible when matching Essence in inventory', () {
      final engine = GameEngine();
      engine.inventory = engine.inventory.addItem(Items.wildsEchoEssence, 1);
      expect(engine.isActionVisible(Zones.townSquare, 'burn_wilds_echo_essence'), true);
      expect(engine.isActionVisible(Zones.townSquare, 'burn_stone_echo_essence'), false);
    });

    test('Burn actions defined in townSquare actions list', () {
      final ids = Zones.townSquare.actions.map((a) => a.id).toSet();
      expect(ids, containsAll([
        'burn_wilds_echo_essence',
        'burn_stone_echo_essence',
        'burn_tide_echo_essence',
      ]));
    });
  });
}
```

- [ ] **Step 2: Run, verify it fails**

- [ ] **Step 3: Append 3 burn actions to townSquare.actions**

```dart
ZoneAction(
  id: 'burn_wilds_echo_essence',
  name: 'Burn the Wilds Echo Essence',
  description: 'Take the Essence to the Town Center fire and let it consume itself.',
  durationSeconds: 6, energyCost: 8,
  requiredSkill: SkillType.lore, requiredLevel: 1,
  xpReward: 100, lootTable: [],
),
ZoneAction(
  id: 'burn_stone_echo_essence',
  name: 'Burn the Stone Echo Essence',
  description: 'Take the Essence to the Town Center fire and let it consume itself.',
  durationSeconds: 6, energyCost: 8,
  requiredSkill: SkillType.lore, requiredLevel: 1,
  xpReward: 100, lootTable: [],
),
ZoneAction(
  id: 'burn_tide_echo_essence',
  name: 'Burn the Tide Echo Essence',
  description: 'Take the Essence to the Town Center fire and let it consume itself.',
  durationSeconds: 6, energyCost: 8,
  requiredSkill: SkillType.lore, requiredLevel: 1,
  xpReward: 100, lootTable: [],
),
```

- [ ] **Step 4: Extend isActionVisible in lib/engine/game_engine.dart**

```dart
// In GameEngine.isActionVisible():
if (actionId == 'burn_wilds_echo_essence') return _inventory.hasItem('wilds_echo_essence', 1);
if (actionId == 'burn_stone_echo_essence') return _inventory.hasItem('stone_echo_essence', 1);
if (actionId == 'burn_tide_echo_essence') return _inventory.hasItem('tide_echo_essence', 1);
```

- [ ] **Step 5: Run, verify pass**

- [ ] **Step 6: Commit**

```bash
git add lib/models/zone.dart lib/engine/game_engine.dart test/cleansing_test.dart
git commit -m "feat(town): add 3 conditional burn actions for Echo Essence cleansing"
```

---

## Task 9: Engine phase mechanics — _checkEchoPhaseTransition

**Files:**
- Modify: `lib/engine/game_engine.dart`
- Test: `test/echo_combat_test.dart` (extend)

- [ ] **Step 1: Write failing test**

Add to `test/echo_combat_test.dart`:

```dart
import 'package:flutter_text_based_rpg/engine/game_engine.dart';

group('Phase transition logic', () {
  test('Echo phase transitions at hpThreshold', () {
    final engine = GameEngine();
    // Test helper to start an Echo fight
    engine.startEchoFightForTest('echo_of_wilds');
    expect(engine.activeCombat!.activePhaseIndex, 0);

    // Drop beast HP to 66% of 240 = 158
    engine.setBeastHpForTest(158);
    engine.checkEchoPhaseTransitionForTest();
    expect(engine.activeCombat!.activePhaseIndex, 1);
    expect(engine.activeCombat!.activePhasePassive, BeastPassive.healOnHit);

    // Drop to 33% = 79
    engine.setBeastHpForTest(79);
    engine.checkEchoPhaseTransitionForTest();
    expect(engine.activeCombat!.activePhaseIndex, 2);
    expect(engine.activeCombat!.activePhasePassive, BeastPassive.enrage);
  });
});
```

- [ ] **Step 2: Run, verify it fails**

- [ ] **Step 3: Extend CombatState + add _checkEchoPhaseTransition**

In `lib/engine/game_engine.dart`, extend `CombatState`:

```dart
class CombatState {
  // existing fields...
  final int activePhaseIndex;            // -1 = no phase entered yet
  final BeastAbility? activePhaseAbility;
  final BeastPassive? activePhasePassive;

  // Update constructor + copyWith
}
```

Add method:

```dart
void _checkEchoPhaseTransition() {
  if (_activeCombat == null) return;
  final beast = _activeCombat!.beast;
  if (beast.phases == null) return;

  final hpPct = _activeCombat!.beastCurrentHealth / beast.maxHealth;
  EchoPhase? currentPhase;
  for (final phase in beast.phases!) {
    if (hpPct <= phase.hpThreshold) {
      currentPhase = phase;
    }
  }
  if (currentPhase == null) return;

  final newIndex = beast.phases!.indexOf(currentPhase);
  if (_activeCombat!.activePhaseIndex != newIndex) {
    _activeCombat = _activeCombat!.copyWith(
      activePhaseIndex: newIndex,
      activePhaseAbility: currentPhase.ability,
      activePhasePassive: currentPhase.passive,
    );
    log(currentPhase.entryNarration, LogType.warning);
    playSfx('ui_info_chime');
  }
}
```

Add test helpers:

```dart
@visibleForTesting
void startEchoFightForTest(String beastId) {
  final beast = Beasts.findById(beastId)!;
  _activeCombat = CombatState(
    beast: beast,
    beastCurrentHealth: beast.maxHealth,
    playerStartHealth: _playerStats.currentHealth,
    combatLog: [],
    roundHistory: [],
    roundsSinceLastTelegraph: 0,
    activeTelegraph: null,
    pendingStance: null,
    roundDeadline: DateTime.now().add(const Duration(seconds: 2)),
    pendingQuickslotIndex: null,
    currentRoundNumber: 1,
    activePhaseIndex: 0,
    activePhaseAbility: beast.phases?.first.ability ?? beast.ability,
    activePhasePassive: beast.phases?.first.passive,
  );
  notifyListeners();
}

@visibleForTesting
void setBeastHpForTest(int hp) {
  if (_activeCombat == null) return;
  _activeCombat = _activeCombat!.copyWith(beastCurrentHealth: hp);
}

@visibleForTesting
void checkEchoPhaseTransitionForTest() => _checkEchoPhaseTransition();
```

- [ ] **Step 4: Run, verify pass**

- [ ] **Step 5: Commit**

```bash
git add lib/engine/game_engine.dart test/echo_combat_test.dart
git commit -m "feat(combat): add _checkEchoPhaseTransition + CombatState phase fields"
```

---

## Task 10: Wire phase passives into _resolveCombatRound

**Files:**
- Modify: `lib/engine/game_engine.dart`
- Test: `test/echo_combat_test.dart` (extend)

- [ ] **Step 1: Write tests for each passive**

Add to `test/echo_combat_test.dart`:

```dart
test('healOnHit passive heals beast 3 HP per round', () {
  final engine = GameEngine();
  engine.startEchoFightForTest('echo_of_wilds');
  engine.setBeastHpForTest(158);
  engine.checkEchoPhaseTransitionForTest();  // enter P2

  // Manually apply passive (simulating a combat round)
  engine.applyEchoPassiveForTest();
  expect(engine.activeCombat!.beastCurrentHealth, 158 + 3);
});

test('enrage passive reduces telegraph cooldown', () {
  // After P3, _stanceCost or cooldown reads enrage-modified value
  // (verify via getStanceCost or telegraph fire logic — implementation-specific)
});
```

- [ ] **Step 2: Implement passive resolution in _resolveCombatRound**

In `_resolveCombatRound`, after damage application and before the phase transition check:

```dart
// healOnHit (Wilds P2)
if (_activeCombat != null && _activeCombat!.activePhasePassive == BeastPassive.healOnHit) {
  final healed = (_activeCombat!.beastCurrentHealth + 3).clamp(0, beast.maxHealth);
  _activeCombat = _activeCombat!.copyWith(beastCurrentHealth: healed);
  log("The Echo healed 3 HP.", LogType.info);
}
```

For `damageReduction` (Stone P2) — apply in player damage branch BEFORE assigning to `playerDmgDealt`:

```dart
if (_activeCombat?.activePhasePassive == BeastPassive.damageReduction) {
  playerDmgDealt = (playerDmgDealt * 0.75).round();
}
```

For `reducedAccuracy` (Tide P2) — apply in crit chance calc:

```dart
if (_activeCombat?.activePhasePassive == BeastPassive.reducedAccuracy) {
  critChance *= 0.5;
}
```

For `enrage` (any P3) — modify cooldown when checking telegraph fire:

```dart
final ability = _activeCombat!.activePhaseAbility ?? beast.ability;
final effectiveCooldown = (_activeCombat?.activePhasePassive == BeastPassive.enrage)
    ? max(1, ability!.cooldownRounds - 1)
    : ability!.cooldownRounds;
// Use effectiveCooldown in telegraph fire check
```

Add test helper:

```dart
@visibleForTesting
void applyEchoPassiveForTest() {
  if (_activeCombat == null || _activeCombat!.activePhasePassive != BeastPassive.healOnHit) return;
  final beast = _activeCombat!.beast;
  final healed = (_activeCombat!.beastCurrentHealth + 3).clamp(0, beast.maxHealth);
  _activeCombat = _activeCombat!.copyWith(beastCurrentHealth: healed);
}
```

- [ ] **Step 3: Run tests, verify pass**

- [ ] **Step 4: Commit**

```bash
git add lib/engine/game_engine.dart test/echo_combat_test.dart
git commit -m "feat(combat): wire 4 Echo phase passives (heal, damage reduction, accuracy debuff, enrage)"
```

---

## Task 11: Add 3 Cleansing Ritual MasterworkTasks

**Files:**
- Modify: `lib/models/masterwork.dart`
- Test: `test/cleansing_test.dart` (extend)

- [ ] **Step 1: Write failing test**

Add to `test/cleansing_test.dart`:

```dart
import 'package:flutter_text_based_rpg/models/masterwork.dart';

group('Cleansing ritual tasks', () {
  test('3 cleansing rituals exist', () {
    for (final id in ['cleansing_wilds', 'cleansing_stone', 'cleansing_tide']) {
      expect(MasterworkTasks.findById(id), isNotNull, reason: 'Missing: $id');
    }
  });

  test('Each cleansing ritual has 3 steps (start + 2 terminals)', () {
    for (final id in ['cleansing_wilds', 'cleansing_stone', 'cleansing_tide']) {
      final task = MasterworkTasks.findById(id)!;
      expect(task.steps.length, 3, reason: 'Wrong step count for $id');
    }
  });

  test('Each terminal option has isSuccess: true', () {
    for (final id in ['cleansing_wilds', 'cleansing_stone', 'cleansing_tide']) {
      final task = MasterworkTasks.findById(id)!;
      // Verify both branch terminals are isSuccess
      final terminals = task.steps.values
          .expand((s) => s.options)
          .where((o) => o.nextStepId == null);
      expect(terminals.length, 2);
      expect(terminals.every((o) => o.isSuccess), true);
    }
  });
});
```

- [ ] **Step 2: Run, verify it fails**

- [ ] **Step 3: Add 3 ritual MasterworkTask constants**

In `lib/models/masterwork.dart`, in `MasterworkTasks`:

```dart
static final MasterworkTask cleansingWilds = MasterworkTask(
  id: 'cleansing_wilds',
  skillType: SkillType.lore,
  levelGate: 1,
  title: 'Burning the Hollow',
  description: 'The Wilds Echo Essence sits in the Town Center fire. The flame won\'t take. The cartographer watches.',
  startStepId: 'start',
  steps: {
    'start': MasterworkStep(
      id: 'start',
      prompt: 'The Essence won\'t catch. The cartographer hands you a thin bundle of dry kindling. "You\'ll need to speak to it. The Wilds want a word, not an offering. Make a name for the place."',
      options: [
        MasterworkOption(
          text: 'Name the Hollow as the Warden named it in her last journal.',
          nextStepId: 'wardens_name',
          requiredSkill: SkillType.lore,
          requiredLevel: 5,
          feedback: 'You speak the name the Warden wrote in her last entry. The Essence flares green.',
        ),
        MasterworkOption(
          text: 'Name the Hollow yourself, in your own tongue.',
          nextStepId: 'own_name',
          feedback: 'You speak a name of your own choosing. The Essence smolders, uncertain.',
        ),
      ],
    ),
    'wardens_name': MasterworkStep(
      id: 'wardens_name',
      prompt: 'The Essence burns clean, green-gold. The Hollow speaks once, softly, in a voice you almost recognize. Then silence.',
      options: [
        MasterworkOption(
          text: 'Take what remains from the ashes.',
          nextStepId: null,
          isSuccess: true,
          energyCost: 8,
          feedback: 'A small carved seed-shape sits in the ash, warm to the touch. The Wilds Breach is sealed.',
        ),
      ],
    ),
    'own_name': MasterworkStep(
      id: 'own_name',
      prompt: 'The Essence burns dim. Your name does not catch. The cartographer murmurs the Warden\'s name; the flame catches at last.',
      options: [
        MasterworkOption(
          text: 'Take what remains from the ashes.',
          nextStepId: null,
          isSuccess: true,
          energyCost: 10,
          feedback: 'A small carved seed-shape sits in the ash, warm to the touch. The Wilds Breach is sealed — though the cartographer notes the name to remember next time.',
        ),
      ],
    ),
  },
);
```

Add similar `cleansingStone` and `cleansingTide` constants using the full text from spec §4.2. Append all 3 to `MasterworkTasks.all` and extend `findById`:

```dart
case 'cleansing_wilds': return cleansingWilds;
case 'cleansing_stone': return cleansingStone;
case 'cleansing_tide': return cleansingTide;
```

- [ ] **Step 4: Run, verify pass**

- [ ] **Step 5: Commit**

```bash
git add lib/models/masterwork.dart test/cleansing_test.dart
git commit -m "feat(masterwork): add 3 cleansing ritual MasterworkTask constants"
```

---

## Task 12: Add 7 new MilestoneEvents

**Files:**
- Modify: `lib/models/milestone.dart`
- Test: `test/cleansing_test.dart` (extend)

- [ ] **Step 1: Write failing test**

Add to `test/cleansing_test.dart`:

```dart
import 'package:flutter_text_based_rpg/models/milestone.dart';

group('Spec 5 milestones', () {
  test('7 new milestones exist', () {
    final ids = Milestones.all.map((m) => m.id).toSet();
    for (final id in [
      'bloomwither_entered', 'glowing_vein_entered', 'drowned_lighthouse_spoken',
      'breach_wilds_cleansed_milestone', 'breach_stone_cleansed_milestone',
      'breach_tide_cleansed_milestone', 'all_breaches_cleansed_milestone',
    ]) {
      expect(ids, contains(id), reason: 'Missing milestone: $id');
    }
  });
});
```

- [ ] **Step 2: Run, verify it fails**

- [ ] **Step 3: Add 7 milestones to lib/models/milestone.dart**

```dart
static final MilestoneEvent bloomwitherEntered = MilestoneEvent(
  id: 'bloomwither_entered',
  severity: MilestoneSeverity.major,
  title: 'The Hollow Speaks',
  body: 'The trees here stand wrong, and a deeper wrong watches from the heart of the hollow. The Warden\'s old advice runs through your mind — an Ironbark log, well-seasoned, and three Wildflowers cut at first light, burned at the rotted shrine within. But first: what waits in the Hollow will not let you near without a fight. Defeat it. Wrest its essence. Return to Town Square and burn the essence at the town center. That is how a Breach is sealed.',
  icon: '🌿',
  trigger: (engine) => engine.regionStatus.containsKey('whispering_woods_3'),
);

static final MilestoneEvent glowingVeinEntered = MilestoneEvent(
  id: 'glowing_vein_entered',
  severity: MilestoneSeverity.major,
  title: 'The Vein Pulses',
  body: 'The Glinting Vein is no vein — it is a wound. The foreman\'s last writing speaks of an alchemist\'s draught — wildflower tinctured with river clay, twice-distilled — that calms the pulse. The thing inside the wound will rise to defend it. Endure the rising. Then carry the wound\'s essence home, and burn it at the town center.',
  icon: '💎',
  trigger: (engine) => engine.regionStatus.containsKey('darkstone_mine_3'),
);

static final MilestoneEvent drownedLighthouseSpoken = MilestoneEvent(
  id: 'drowned_lighthouse_spoken',
  severity: MilestoneSeverity.major,
  title: 'The Lamp Speaks',
  body: 'You climb the lighthouse stairs. The lamp room is silent — but not empty. The keeper\'s last page warned you: do not relight the lamp with oil; carry a Salt Crystal — the pure kind from the deep tide pools — and set it within the lamp\'s heart. Something old in the sea will rise to silence the song. Do not let it. When you have its essence, carry it home and burn it at the town center.',
  icon: '🌊',
  trigger: (engine) => engine.engineFlags.contains('drowned_lighthouse_spoken'),
);

static final MilestoneEvent breachWildsCleansedMilestone = MilestoneEvent(
  id: 'breach_wilds_cleansed_milestone',
  severity: MilestoneSeverity.major,
  title: 'The Forest Returns',
  body: 'The forest hush returns. Birds are singing in the eastern groves for the first time in months. The Warden\'s gate has opened on its own.',
  icon: '🌿',
  trigger: (engine) => engine.engineFlags.contains('breach_wilds_cleansed'),
);

static final MilestoneEvent breachStoneCleansedMilestone = MilestoneEvent(
  id: 'breach_stone_cleansed_milestone',
  severity: MilestoneSeverity.major,
  title: 'The Foreman Returns',
  body: 'The tapping stops in your dreams. The foreman is found, alive, sitting at the lip of the deepest shaft. He does not remember the year. He cries when he sees the sun.',
  icon: '💎',
  trigger: (engine) => engine.engineFlags.contains('breach_stone_cleansed'),
);

static final MilestoneEvent breachTideCleansedMilestone = MilestoneEvent(
  id: 'breach_tide_cleansed_milestone',
  severity: MilestoneSeverity.major,
  title: 'The Lamp Lights Itself',
  body: 'The Lighthouse lamp lights itself at dusk. The Drowned are gone from the pier. The salt smells like salt again.',
  icon: '🌊',
  trigger: (engine) => engine.engineFlags.contains('breach_tide_cleansed'),
);

static final MilestoneEvent allBreachesCleansedMilestone = MilestoneEvent(
  id: 'all_breaches_cleansed_milestone',
  severity: MilestoneSeverity.major,
  title: 'The Bells Ring',
  body: 'Town Square\'s bells ring without being struck. Somewhere, a stone door opens beneath the world. The cartographer hands you a key you have never seen before.',
  icon: '🔔',
  trigger: (engine) =>
    engine.engineFlags.contains('breach_wilds_cleansed') &&
    engine.engineFlags.contains('breach_stone_cleansed') &&
    engine.engineFlags.contains('breach_tide_cleansed'),
  onFire: (engine) => engine.setEngineFlag('nexus_unlockable'),
);
```

Append all 7 to `Milestones.all`.

- [ ] **Step 4: Run, verify pass**

- [ ] **Step 5: Commit**

```bash
git add lib/models/milestone.dart test/cleansing_test.dart
git commit -m "feat(milestone): add 7 Spec 5 milestones (3 Breach Introductions + 4 cleansing celebrations)"
```

---

## Task 13: Wire approach_lamp_room flag + Echo defeat narrative

**Files:**
- Modify: `lib/engine/game_engine.dart`

- [ ] **Step 1: Wire approach_lamp_room flag in _completeAction**

In `_completeAction`:

```dart
if (action.id == 'approach_lamp_room') {
  if (!_engineFlags.contains('drowned_lighthouse_spoken')) {
    setEngineFlag('drowned_lighthouse_spoken');
  }
}
```

- [ ] **Step 2: Add post-Echo-defeat narrative in _resolveCombat (or wherever beast defeat is detected)**

```dart
// After beast defeat is determined:
if (beast.id == 'echo_of_wilds') {
  log("The Echo collapses into a brittle husk. A green mote pulses where its heart was — you pluck it free. Carry it home. Burn it where the cartographer keeps his fire.", LogType.worldEvent);
  playSfx('ui_masterwork_complete');
}
if (beast.id == 'echo_of_stone') {
  log("The Echo cracks open like a geode. A cold crystalline mote slides into your palm. Carry it home. Burn it at the town center.", LogType.worldEvent);
  playSfx('ui_masterwork_complete');
}
if (beast.id == 'echo_of_tide') {
  log("The Echo recedes into the surf, leaving a briny mote behind that pulses faintly in your hand. Carry it home. Burn it at the town center.", LogType.worldEvent);
  playSfx('ui_masterwork_complete');
}
```

- [ ] **Step 3: Verify game compiles + run existing tests**

Run: `flutter test`

Expected: All existing tests still pass.

- [ ] **Step 4: Commit**

```bash
git add lib/engine/game_engine.dart
git commit -m "feat(engine): wire approach_lamp_room flag + Echo defeat narrative log"
```

---

## Task 14: Cleansing dispatch — _startCleansingRitual, _onCleansingComplete, _onMasterworkSuccess routing

**Files:**
- Modify: `lib/engine/game_engine.dart`
- Test: `test/cleansing_test.dart` (extend)

- [ ] **Step 1: Write failing test**

Add to `test/cleansing_test.dart`:

```dart
import 'package:flutter_text_based_rpg/models/skill.dart';
import 'package:flutter_text_based_rpg/models/codex.dart';

group('Cleansing dispatch', () {
  test('Burn action consumes Essence and launches ritual', () {
    final engine = GameEngine();
    engine.inventory = engine.inventory.addItem(Items.wildsEchoEssence, 1);
    engine.completeActionForTest('burn_wilds_echo_essence');

    expect(engine.inventory.hasItem('wilds_echo_essence', 1), false);
    expect(engine.activeMasterwork?.task.id, 'cleansing_wilds');
  });

  test('Cleansing success sets breach flag + grants Token + sets first_breach_cleansed', () {
    final engine = GameEngine();
    engine.inventory = engine.inventory.addItem(Items.wildsEchoEssence, 1);
    engine.completeActionForTest('burn_wilds_echo_essence');
    engine.completeMasterworkForTest('cleansing_wilds', useFirstSuccessOption: true);

    expect(engine.engineFlags.contains('breach_wilds_cleansed'), true);
    expect(engine.engineFlags.contains('first_breach_cleansed'), true);
    expect(engine.inventory.hasItem('wilds_cleansing_token', 1), true);
  });

  test('All-three cleansed sets nexus_unlockable and offers Source Convergence', () {
    final engine = GameEngine();
    // Force all 3 cleansings
    for (final tag in ['wilds', 'stone', 'tide']) {
      engine.inventory = engine.inventory.addItem(Items.findById('${tag}_echo_essence')!, 1);
      engine.completeActionForTest('burn_${tag}_echo_essence');
      engine.completeMasterworkForTest('cleansing_$tag', useFirstSuccessOption: true);
    }

    expect(engine.engineFlags.contains('nexus_unlockable'), true);
    expect(engine.activeQuests.any((q) => q.id == 'main_source_convergence'), true);
  });
});
```

- [ ] **Step 2: Run, verify it fails**

- [ ] **Step 3: Implement dispatch logic in lib/engine/game_engine.dart**

In `_completeAction`:

```dart
if (action.id == 'burn_wilds_echo_essence') {
  _inventory = _inventory.removeItem('wilds_echo_essence', 1);
  _startCleansingRitual('wilds');
  return;
}
if (action.id == 'burn_stone_echo_essence') {
  _inventory = _inventory.removeItem('stone_echo_essence', 1);
  _startCleansingRitual('stone');
  return;
}
if (action.id == 'burn_tide_echo_essence') {
  _inventory = _inventory.removeItem('tide_echo_essence', 1);
  _startCleansingRitual('tide');
  return;
}
```

Add new methods:

```dart
void _startCleansingRitual(String breachTag) {
  final task = MasterworkTasks.findById('cleansing_$breachTag');
  if (task == null) return;
  startMasterworkChallenge(task);  // reuse existing Masterwork start logic
}

void _onCleansingComplete(String breachTag) {
  setEngineFlag('breach_${breachTag}_cleansed');

  if (!_engineFlags.contains('first_breach_cleansed')) {
    setEngineFlag('first_breach_cleansed');
  }

  final tokenId = '${breachTag}_cleansing_token';
  final token = Items.findById(tokenId);
  if (token != null) {
    _inventory = _inventory.addItem(token, 1);
  }

  // Advance cleanse main quest objective
  for (final quest in _activeQuests) {
    for (final obj in quest.objectives) {
      if (obj.kind == ObjectiveKind.cleanse && obj.targetId == 'breach_$breachTag') {
        obj.currentCount = obj.targetCount;
        obj.comingSoon = false;
      }
    }
    _maybeCompleteQuest(quest);
  }

  // Offer Source Convergence if all three cleansed
  if (_engineFlags.contains('breach_wilds_cleansed') &&
      _engineFlags.contains('breach_stone_cleansed') &&
      _engineFlags.contains('breach_tide_cleansed')) {
    if (!_activeQuests.any((q) => q.id == 'main_source_convergence') &&
        !_completedQuests.any((q) => q.id == 'main_source_convergence')) {
      offerQuest(MainQuests.sourceConvergence());
    }
  }

  playSfx('ui_masterwork_complete');
  notifyListeners();
}
```

Modify `_onMasterworkSuccess` to dispatch cleansings before cap-unlock logic:

```dart
void _onMasterworkSuccess(MasterworkRunState run, MasterworkOption terminalOption) {
  final task = run.task;

  // NEW: Detect cleansing ritual — bypass cap-unlock logic
  if (task.id.startsWith('cleansing_')) {
    _onCleansingComplete(task.id.substring('cleansing_'.length));
    return;
  }

  // Existing: unlock cap, record spec, etc.
  // ... existing Spec 4 logic stays unchanged ...
}
```

- [ ] **Step 4: Run, verify pass**

- [ ] **Step 5: Commit**

```bash
git add lib/engine/game_engine.dart test/cleansing_test.dart
git commit -m "feat(engine): wire cleansing dispatch — burn action → ritual → flag + Token + quest advancement"
```

---

## Task 15: Spec 5 integration smoke test

**Files:**
- Modify: `test/quest_engine_test.dart`

- [ ] **Step 1: Add end-to-end smoke test**

```dart
test('Spec 5 acceptance — full Wilds Breach arc', () {
  final engine = GameEngine();
  engine.unlockZoneForTest('whispering_woods_3');
  engine.travelTo(Zones.whisperingWoodsTier3);

  // Breach Introduction fires
  expect(engine.firedMilestoneIdsForTest, contains('bloomwither_entered'));

  // Defeat Echo via test helper
  engine.runCombatToVictoryForTest('echo_of_wilds');

  // Essence dropped
  expect(engine.inventory.hasItem('wilds_echo_essence', 1), true);

  // Travel to town and verify burn action visibility
  engine.travelTo(Zones.townSquare);
  expect(engine.isActionVisible(Zones.townSquare, 'burn_wilds_echo_essence'), true);

  // Burn → ritual → success
  engine.completeActionForTest('burn_wilds_echo_essence');
  engine.completeMasterworkForTest('cleansing_wilds', useFirstSuccessOption: true);

  // All post-cleansing assertions
  expect(engine.engineFlags.contains('breach_wilds_cleansed'), true);
  expect(engine.engineFlags.contains('first_breach_cleansed'), true);
  expect(engine.inventory.hasItem('wilds_cleansing_token', 1), true);
  expect(engine.inventory.hasItem('wilds_echo_essence', 1), false);
  expect(engine.isActionVisible(Zones.townSquare, 'burn_wilds_echo_essence'), false);
  expect(engine.completedQuests.any((q) => q.id == 'main_cleanse_hollow'), true);
  expect(engine.isFragmentPoolOpenForTest(CodexTag.source), true);
});
```

Test helpers used (`unlockZoneForTest`, `runCombatToVictoryForTest`, `completeActionForTest`, `completeMasterworkForTest`, `isFragmentPoolOpenForTest`, `firedMilestoneIdsForTest`) — most already exist from prior specs; add any missing ones with `@visibleForTesting`.

- [ ] **Step 2: Run full test suite**

Run: `flutter test`

Expected: All Spec 1 + 2 + 3 + 4 + 5 tests pass.

- [ ] **Step 3: Run flutter analyze**

Run: `flutter analyze`

Expected: Zero errors and zero warnings.

- [ ] **Step 4: Commit**

```bash
git add test/quest_engine_test.dart lib/engine/game_engine.dart
git commit -m "test(spec5): end-to-end smoke test for full Wilds Breach arc"
```

---

## Post-implementation checklist

- [ ] All `flutter test` passes (Spec 1-5 combined)
- [ ] `flutter analyze` zero errors and zero warnings
- [ ] Manual play test:
  - Travel to Whispering Woods III → Breach Introduction modal fires
  - Engage Echo of the Wilds → 3-phase fight with phase entry narrations
  - At ~66% HP, Echo starts healing 3 HP/round (logged); at ~33%, telegraphs come faster
  - Echo defeated → Wilds Echo Essence drops + post-fight narrative log entry
  - Travel to Town Square → "🔥 Burn the Wilds Echo Essence" action visible
  - Tap → 4-step ritual modal → choose Warden's name → ritual succeeds
  - Wilds Cleansing Token in inventory; Cleanse the Hollow quest completes
  - Per-breach + first-breach milestones fire (modal)
  - Repeat for Stone (Glowing Vein) and Tide (Drowned Lighthouse)
  - After third cleansing → capstone milestone fires; Source Convergence quest offered
  - Source-tag fragments start dropping after first breach (verify in Codex)
- [ ] README.md updated with Spec 5 notes
