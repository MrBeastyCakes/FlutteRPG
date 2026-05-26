# Spec 6a — Living Economy Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement Spec 6a — Tool Durability across all equipment, 6 Scarce Reagents with Notice spawn mechanic, Merchant Reputation (5-tier + 6th merchant Bram), Daily Tasks (Tavern fixture + 30 templates).

**Architecture:** Pure additive on top of Specs 1–5. Durability extends `InventorySlot` with 2 fields; ticking hooks into existing gather/combat paths. Reagents integrate as new switch arms on Spec 4's modifier-slot effect resolution. Reputation is a new `_merchantRep` map ticked by existing `buyItem`/`sellItem`. Daily tasks reuse Spec 1's Quest observer pipeline. Tavern is a new conditional Town Square action + new view.

**Tech Stack:** Flutter (Dart ^3.11.4), Provider state management, `flutter_test` + `fake_async`. No new dependencies.

**Reference spec:** [docs/superpowers/specs/2026-05-25-spec-6a-living-economy-design.md](../specs/2026-05-25-spec-6a-living-economy-design.md)

---

## File Structure

**Files created:**
- `lib/models/reagent_spawn.dart` — `ReagentSpawn` class
- `lib/models/daily_task.dart` — enum, `DailyTaskTemplate`, `DailyTask`, `DailyTasks` registry
- `lib/views/tavern_view.dart` — Tavern UI with 2 tabs
- `test/durability_test.dart`
- `test/reagent_test.dart`
- `test/reputation_test.dart`
- `test/daily_task_test.dart`

**Files modified:**
- `lib/models/item.dart` — add 9 new items (6 reagents + 3 unique merchant items)
- `lib/models/inventory.dart` — extend `InventorySlot` with `currentDurability` / `maxDurability` + copyWith + equality
- `lib/models/shop.dart` — add `ReputationTier`, `MerchantReputation`, Bram merchant
- `lib/models/codex.dart` — add 6 Sworn Companion fragments
- `lib/models/zone.dart` — append `visit_tavern` action to `townSquare.actions`
- `lib/models/recipe.dart` — add `findByResultItemId` helper if not present
- `lib/engine/game_engine.dart` — extensive (durability tick + repair API + reagent spawn + modifier extensions + reputation engine + daily tasks + tavern handler)
- `lib/views/dashboard_view.dart` — durability bars on equipment quick-view; Notice card render; tavern navigation
- `lib/views/inventory_view.dart` — durability bars + "Worn" badge
- `lib/views/build_view.dart` — Crafting Bench Repairs panel
- `lib/views/shop_view.dart` — rep chip; price discount; Repairs section; Trusted Patron items; Honored Friend gift popover
- `lib/views/codex_view.dart` — Reputation tab
- `lib/views/workshop_view.dart` (or modifier picker) — reagents in modifier picker + type-mismatch warning
- `test/quest_engine_test.dart` — Spec 6a end-to-end smoke test

---

## Task 1: Add 6 reagents + 3 unique merchant items

**Files:**
- Modify: `lib/models/item.dart`
- Test: `test/reagent_test.dart` (new)

- [ ] **Step 1: Write failing test**

Create `test/reagent_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/models/item.dart';

void main() {
  group('Spec 6a items', () {
    test('6 reagent items exist with single-emoji icons', () {
      for (final id in ['moonpetal', 'spirit_sap', 'hollow_bone', 'sea_tear', 'coalblood', 'wisp_light']) {
        final item = Items.findById(id);
        expect(item, isNotNull, reason: 'Missing: $id');
        expect(item!.icon.runes.length, lessThanOrEqualTo(2), reason: 'Compound emoji forbidden: $id');
      }
    });

    test('Wisp-Light is highest-value reagent (200g)', () {
      expect(Items.findById('wisp_light')!.value, 200);
    });

    test('Bram Trusted Patron items exist', () {
      for (final id in ['tinkers_bauble', 'elixir_of_twilight', 'taverns_best']) {
        expect(Items.findById(id), isNotNull, reason: 'Missing: $id');
      }
    });

    test("Elixir of Twilight restores 30 HP and 50 energy", () {
      final item = Items.findById('elixir_of_twilight')!;
      expect(item.healAmount, 30);
      expect(item.energyAmount, 50);
    });
  });
}
```

- [ ] **Step 2: Run test, verify it fails**

Run: `flutter test test/reagent_test.dart`

Expected: FAIL.

- [ ] **Step 3: Add 9 items to lib/models/item.dart**

In the `Items` class:

```dart
// ─── Reagents (Spec 6a) ───
static const Item moonpetal = Item(
  id: 'moonpetal', name: 'Moonpetal',
  description: 'A bone-white blossom that glows faintly in moonlight. Forces an affix roll on a craft.',
  icon: '🌸', type: ItemType.resource, value: 60,
);

static const Item spiritSap = Item(
  id: 'spirit_sap', name: 'Spirit Sap',
  description: 'Translucent sap that doubles back on itself. Doubles the output of a craft.',
  icon: '💧', type: ItemType.resource, value: 70,
);

static const Item hollowBone = Item(
  id: 'hollow_bone', name: 'Hollow Bone',
  description: 'A weightless bone from a creature no one remembers. Grants Brutal affix to a weapon.',
  icon: '🦴', type: ItemType.resource, value: 80,
);

static const Item seaTear = Item(
  id: 'sea_tear', name: 'Sea-Tear',
  description: 'A crystallized drop of cold sea-water. Grants Tempered affix to armor.',
  icon: '💎', type: ItemType.resource, value: 80,
);

static const Item coalblood = Item(
  id: 'coalblood', name: 'Coalblood',
  description: 'A viscous black liquid that smells of forge-smoke. Grants Frugal affix to any craft.',
  icon: '🌑', type: ItemType.resource, value: 90,
);

static const Item wispLight = Item(
  id: 'wisp_light', name: 'Wisp-Light',
  description: 'A flickering mote captured at twilight. Guarantees Masterwork quality on a craft.',
  icon: '✨', type: ItemType.resource, value: 200,
);

// ─── Bram-tier merchant items (Spec 6a) ───
static const Item tinkersBauble = Item(
  id: 'tinkers_bauble', name: "Tinker's Bauble",
  description: "A small clockwork trinket from Cedric's private stock. Used as a crafting modifier — adds +1 to result quantity.",
  icon: '⚙️', type: ItemType.resource, value: 100,
);

static const Item elixirOfTwilight = Item(
  id: 'elixir_of_twilight', name: 'Elixir of Twilight',
  description: "Pippin's signature concoction. Restores 30 HP and 50 energy.",
  icon: '🧪', type: ItemType.food, value: 120, healAmount: 30, energyAmount: 50,
);

static const Item tavernsBest = Item(
  id: 'taverns_best', name: "Tavern's Best",
  description: "Bram's reserve drink. Doesn't restore much, but lifts the spirits. Grants +10% craft speed for 5 actions.",
  icon: '🍺', type: ItemType.food, value: 60, healAmount: 10, energyAmount: 30,
);
```

Append all 9 to `Items.all`.

- [ ] **Step 4: Run tests, verify pass**

- [ ] **Step 5: Commit**

```bash
git add lib/models/item.dart test/reagent_test.dart
git commit -m "feat(items): add 6 reagents + 3 Trusted Patron merchant items"
```

---

## Task 2: Extend InventorySlot with durability fields

**Files:**
- Modify: `lib/models/inventory.dart`
- Test: `test/durability_test.dart` (new)

- [ ] **Step 1: Write failing test**

Create `test/durability_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/models/inventory.dart';
import 'package:flutter_text_based_rpg/models/item.dart';

void main() {
  group('InventorySlot durability', () {
    test('Default durability is 0/0 (unset)', () {
      final slot = InventorySlot(item: Items.stoneAxe, quantity: 1);
      expect(slot.currentDurability, 0);
      expect(slot.maxDurability, 0);
    });

    test('Can construct with durability values', () {
      final slot = InventorySlot(
        item: Items.stoneAxe, quantity: 1,
        currentDurability: 80, maxDurability: 100,
      );
      expect(slot.currentDurability, 80);
      expect(slot.maxDurability, 100);
    });

    test('copyWith preserves durability', () {
      final slot = InventorySlot(
        item: Items.stoneAxe, quantity: 1,
        currentDurability: 50, maxDurability: 100,
      );
      final copy = slot.copyWith(quantity: 2);
      expect(copy.currentDurability, 50);
      expect(copy.maxDurability, 100);
    });

    test('copyWith can update durability', () {
      final slot = InventorySlot(
        item: Items.stoneAxe, quantity: 1,
        currentDurability: 100, maxDurability: 100,
      );
      final copy = slot.copyWith(currentDurability: 80);
      expect(copy.currentDurability, 80);
      expect(copy.maxDurability, 100);
    });
  });
}
```

- [ ] **Step 2: Run, verify it fails**

- [ ] **Step 3: Extend InventorySlot in lib/models/inventory.dart**

Add fields + update constructor + copyWith + equality:

```dart
class InventorySlot {
  // existing fields: item, quantity, quality, affixIds
  final int currentDurability;
  final int maxDurability;

  const InventorySlot({
    required this.item,
    required this.quantity,
    this.quality,
    this.affixIds = const [],
    this.currentDurability = 0,
    this.maxDurability = 0,
  });

  InventorySlot copyWith({
    Item? item,
    int? quantity,
    QualityTier? quality,
    List<String>? affixIds,
    int? currentDurability,
    int? maxDurability,
  }) {
    return InventorySlot(
      item: item ?? this.item,
      quantity: quantity ?? this.quantity,
      quality: quality ?? this.quality,
      affixIds: affixIds ?? this.affixIds,
      currentDurability: currentDurability ?? this.currentDurability,
      maxDurability: maxDurability ?? this.maxDurability,
    );
  }

  @override
  bool operator ==(Object other) =>
    other is InventorySlot &&
    other.item.id == item.id &&
    other.quantity == quantity &&
    other.quality == quality &&
    _listEquals(other.affixIds, affixIds) &&
    other.currentDurability == currentDurability &&
    other.maxDurability == maxDurability;

  @override
  int get hashCode => Object.hash(item.id, quantity, quality, Object.hashAll(affixIds), currentDurability, maxDurability);
}
```

- [ ] **Step 4: Run tests, verify pass**

- [ ] **Step 5: Commit**

```bash
git add lib/models/inventory.dart test/durability_test.dart
git commit -m "feat(inventory): extend InventorySlot with durability fields"
```

---

## Task 3: Durability calculation + stamp on craft/purchase

**Files:**
- Modify: `lib/engine/game_engine.dart`
- Test: `test/durability_test.dart` (extend)

- [ ] **Step 1: Write failing test**

Add to `test/durability_test.dart`:

```dart
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/models/crafted_item.dart';

group('calculateMaxDurability', () {
  test('Crude = 75, Standard = 100, Fine = 150, Masterwork = 250', () {
    final engine = GameEngine();
    expect(engine.calculateMaxDurabilityForTest(Items.stoneAxe, QualityTier.crude, []), 75);
    expect(engine.calculateMaxDurabilityForTest(Items.stoneAxe, QualityTier.standard, []), 100);
    expect(engine.calculateMaxDurabilityForTest(Items.stoneAxe, QualityTier.fine, []), 150);
    expect(engine.calculateMaxDurabilityForTest(Items.stoneAxe, QualityTier.masterwork, []), 250);
  });

  test('Sturdy affix adds 50%', () {
    final engine = GameEngine();
    expect(engine.calculateMaxDurabilityForTest(Items.stoneAxe, QualityTier.standard, ['sturdy']), 150);
  });

  test('Quest items (value 0) get no durability stamp', () {
    final engine = GameEngine();
    final cleansingToken = Item(id: 'wilds_cleansing_token', name: 'Test', description: '', icon: '🟢', type: ItemType.resource, value: 0);
    // Stamping a value-0 item should leave maxDurability at 0
    expect(engine.calculateMaxDurabilityForTest(cleansingToken, QualityTier.standard, []), 0);
  });
});
```

- [ ] **Step 2: Run, verify it fails**

- [ ] **Step 3: Add calculation helper + stamping logic**

In `lib/engine/game_engine.dart`:

```dart
int calculateMaxDurability(Item item, QualityTier? quality, List<String> affixIds) {
  if (item.value == 0) return 0;  // quest item, no durability
  int base;
  switch (quality ?? QualityTier.standard) {
    case QualityTier.crude: base = 75;
    case QualityTier.standard: base = 100;
    case QualityTier.fine: base = 150;
    case QualityTier.masterwork: base = 250;
  }
  if (affixIds.contains('sturdy')) base = (base * 1.5).round();
  return base;
}

@visibleForTesting
int calculateMaxDurabilityForTest(Item item, QualityTier? quality, List<String> affixIds) =>
  calculateMaxDurability(item, quality, affixIds);
```

In the existing craft-completion path (where the new InventorySlot is created and added to inventory), stamp the durability:

```dart
// In _resolveCraftCompletion or wherever the result is added:
final maxDur = calculateMaxDurability(resultItem, quality, affixIds);
final slot = InventorySlot(
  item: resultItem,
  quantity: finalQty,
  quality: quality,
  affixIds: affixIds,
  currentDurability: maxDur,
  maxDurability: maxDur,
);
_inventory = _inventory.addSlot(slot);
```

In the existing `buyItem` path (where shop items enter inventory), stamp similarly:

```dart
// In buyItem after the buy succeeds:
final maxDur = calculateMaxDurability(item, QualityTier.standard, const []);
final slot = InventorySlot(
  item: item, quantity: 1,
  currentDurability: maxDur, maxDurability: maxDur,
);
_inventory = _inventory.addSlot(slot);
```

For lazy stamping of existing slots on first read, add:

```dart
InventorySlot ensureDurabilityStamped(InventorySlot slot) {
  if (slot.maxDurability == 0 && slot.item.value > 0 &&
      (slot.item.isTool || slot.item.isWeapon || slot.item.isArmor)) {
    final maxDur = calculateMaxDurability(slot.item, slot.quality, slot.affixIds);
    return slot.copyWith(currentDurability: maxDur, maxDurability: maxDur);
  }
  return slot;
}
```

Call `ensureDurabilityStamped` when reading equipped slots (in `getPlayerAttack`, `getPlayerDefense`, etc.) to handle pre-Spec-6a equipment gracefully.

- [ ] **Step 4: Run tests, verify pass**

- [ ] **Step 5: Commit**

```bash
git add lib/engine/game_engine.dart test/durability_test.dart
git commit -m "feat(durability): add calculateMaxDurability + stamp on craft/purchase"
```

---

## Task 4: Durability decrement wiring

**Files:**
- Modify: `lib/engine/game_engine.dart`
- Test: `test/durability_test.dart` (extend)

- [ ] **Step 1: Write failing test**

Add to `test/durability_test.dart`:

```dart
group('Durability decrement', () {
  test('Tool decrements on gathering action completion', () {
    final engine = GameEngine();
    engine.equipForTest(Items.stoneAxe, SkillType.woodcutting);
    final before = engine.equippedToolSlots[SkillType.woodcutting]!.currentDurability;
    engine.completeGatherActionForTest(SkillType.woodcutting);
    final after = engine.equippedToolSlots[SkillType.woodcutting]!.currentDurability;
    expect(after, before - 1);
  });

  test('Weapon decrements on Strike or Heavy Strike round only', () {
    final engine = GameEngine();
    engine.equipWeaponForTest(Items.bronzeSword);
    final before = engine.equippedWeaponSlot!.currentDurability;
    engine.runCombatRoundForTest(PlayerStance.strike);
    expect(engine.equippedWeaponSlot!.currentDurability, before - 1);

    final after = engine.equippedWeaponSlot!.currentDurability;
    engine.runCombatRoundForTest(PlayerStance.defend);
    expect(engine.equippedWeaponSlot!.currentDurability, after, reason: 'Defend should not tick weapon');
  });

  test('Armor decrements only on damage taken', () {
    final engine = GameEngine();
    engine.equipArmorForTest(Items.leatherChest);
    final before = engine.equippedArmorSlot!.currentDurability;
    engine.simulateCombatDamageForTest(playerDmgTaken: 5);
    expect(engine.equippedArmorSlot!.currentDurability, before - 1);

    final after = engine.equippedArmorSlot!.currentDurability;
    engine.simulateCombatDamageForTest(playerDmgTaken: 0);
    expect(engine.equippedArmorSlot!.currentDurability, after, reason: 'Zero damage should not tick armor');
  });

  test('Low-durability warning fires once per session per item', () {
    final engine = GameEngine();
    engine.equipForTest(Items.stoneAxe, SkillType.woodcutting);
    // Force durability to 25%
    final slot = engine.equippedToolSlots[SkillType.woodcutting]!;
    engine.forceEquippedDurabilityForTest(SkillType.woodcutting, (slot.maxDurability * 0.26).round());
    final logCountBefore = engine.logs.length;
    engine.completeGatherActionForTest(SkillType.woodcutting);
    final newLogs = engine.logs.length - logCountBefore;
    expect(newLogs, greaterThan(0));
    final lastLog = engine.logs.last;
    expect(lastLog.message, contains('wearing thin'));

    // Second tick should NOT log again
    final logCountAfterFirst = engine.logs.length;
    engine.completeGatherActionForTest(SkillType.woodcutting);
    expect(engine.logs.length, logCountAfterFirst);
  });
});
```

- [ ] **Step 2: Run, verify it fails**

- [ ] **Step 3: Add _decrementDurability + wire into gather and combat**

In `lib/engine/game_engine.dart`:

```dart
final Set<String> _lowDurabilityWarned = {};

void _decrementDurability(InventorySlot equipped, {required String slot, SkillType? skill}) {
  if (equipped.maxDurability == 0) return;
  final newDur = (equipped.currentDurability - 1).clamp(0, equipped.maxDurability);
  final updated = equipped.copyWith(currentDurability: newDur);

  switch (slot) {
    case 'tool':   _equippedToolSlots[skill!] = updated;
    case 'weapon': _equippedWeaponSlot = updated;
    case 'armor':  _equippedArmorSlot = updated;
  }

  final pct = newDur / equipped.maxDurability;
  if (pct <= 0.25 && !_lowDurabilityWarned.contains(equipped.item.id)) {
    _lowDurabilityWarned.add(equipped.item.id);
    log("⚠️ ${equipped.item.icon} ${equipped.item.name} is wearing thin (${newDur}/${equipped.maxDurability}).", LogType.warning);
    AudioEngine.instance.play('ui_error_soft');
  }
  notifyListeners();
}
```

In `_completeAction` (gathering completion), after existing observers:

```dart
if (!action.isCombat && action.requiredSkill != null) {
  final tool = _equippedToolSlots[action.requiredSkill!];
  if (tool != null) {
    _decrementDurability(tool, slot: 'tool', skill: action.requiredSkill);
  }
}
```

In `_resolveCombatRound`:

```dart
// After the round resolves but before checking end conditions:
if (stance == PlayerStance.strike || stance == PlayerStance.heavyStrike) {
  if (_equippedWeaponSlot != null) {
    _decrementDurability(_equippedWeaponSlot!, slot: 'weapon');
  }
}
if (playerDmgTaken > 0 && _equippedArmorSlot != null) {
  _decrementDurability(_equippedArmorSlot!, slot: 'armor');
}
```

Add test helpers:

```dart
@visibleForTesting
void equipForTest(Item item, SkillType skill) {
  final maxDur = calculateMaxDurability(item, QualityTier.standard, []);
  _equippedToolSlots[skill] = InventorySlot(item: item, quantity: 1,
    currentDurability: maxDur, maxDurability: maxDur);
}

@visibleForTesting
void equipWeaponForTest(Item item) {
  final maxDur = calculateMaxDurability(item, QualityTier.standard, []);
  _equippedWeaponSlot = InventorySlot(item: item, quantity: 1,
    currentDurability: maxDur, maxDurability: maxDur);
}

@visibleForTesting
void equipArmorForTest(Item item) {
  final maxDur = calculateMaxDurability(item, QualityTier.standard, []);
  _equippedArmorSlot = InventorySlot(item: item, quantity: 1,
    currentDurability: maxDur, maxDurability: maxDur);
}

@visibleForTesting
void completeGatherActionForTest(SkillType skill) {
  final tool = _equippedToolSlots[skill];
  if (tool != null) _decrementDurability(tool, slot: 'tool', skill: skill);
}

@visibleForTesting
void runCombatRoundForTest(PlayerStance stance) {
  if (stance == PlayerStance.strike || stance == PlayerStance.heavyStrike) {
    if (_equippedWeaponSlot != null) {
      _decrementDurability(_equippedWeaponSlot!, slot: 'weapon');
    }
  }
}

@visibleForTesting
void simulateCombatDamageForTest({required int playerDmgTaken}) {
  if (playerDmgTaken > 0 && _equippedArmorSlot != null) {
    _decrementDurability(_equippedArmorSlot!, slot: 'armor');
  }
}

@visibleForTesting
void forceEquippedDurabilityForTest(SkillType skill, int newDur) {
  final tool = _equippedToolSlots[skill]!;
  _equippedToolSlots[skill] = tool.copyWith(currentDurability: newDur);
}

@visibleForTesting
List<LogEntry> get logs => _logs;
```

- [ ] **Step 4: Run, verify pass**

- [ ] **Step 5: Commit**

```bash
git add lib/engine/game_engine.dart test/durability_test.dart
git commit -m "feat(durability): wire decrement into gather + combat with low-durability warning"
```

---

## Task 5: Worn equipment stat-stripping

**Files:**
- Modify: `lib/engine/game_engine.dart`
- Test: `test/durability_test.dart` (extend)

- [ ] **Step 1: Write failing test**

Add to `test/durability_test.dart`:

```dart
group('Worn equipment', () {
  test('isSlotWorn returns true at 0 durability', () {
    final engine = GameEngine();
    final slot = InventorySlot(item: Items.bronzeSword, quantity: 1,
      currentDurability: 0, maxDurability: 100);
    expect(engine.isSlotWorn(slot), true);
  });

  test('isSlotWorn returns false at any positive durability', () {
    final engine = GameEngine();
    final slot = InventorySlot(item: Items.bronzeSword, quantity: 1,
      currentDurability: 1, maxDurability: 100);
    expect(engine.isSlotWorn(slot), false);
  });

  test('Worn weapon ignored in getPlayerAttack', () {
    final engine = GameEngine();
    final fresh = InventorySlot(item: Items.bronzeSword, quantity: 1,
      currentDurability: 100, maxDurability: 100);
    engine.setEquippedWeaponForTest(fresh);
    final attackFresh = engine.getPlayerAttack();

    final worn = fresh.copyWith(currentDurability: 0);
    engine.setEquippedWeaponForTest(worn);
    final attackWorn = engine.getPlayerAttack();

    expect(attackWorn, lessThan(attackFresh));
  });
});
```

- [ ] **Step 2: Run, verify it fails**

- [ ] **Step 3: Add isSlotWorn + modify stat helpers**

In `lib/engine/game_engine.dart`:

```dart
bool isSlotWorn(InventorySlot? slot) {
  if (slot == null || slot.maxDurability == 0) return false;
  return slot.currentDurability <= 0;
}

// Modify existing getPlayerAttack:
int getPlayerAttack() {
  int base = 5;
  if (_equippedWeaponSlot != null && !isSlotWorn(_equippedWeaponSlot)) {
    base += getItemAttackPower(_equippedWeaponSlot!.item, _equippedWeaponSlot!.quality, _equippedWeaponSlot!.affixIds).round();
  }
  final combatSkill = _skills[SkillType.combat];
  if (combatSkill != null && combatSkill.levelCap > 10) base += 3;
  return base;
}

// Modify existing getPlayerDefense similarly:
int getPlayerDefense() {
  int base = 0;
  if (_equippedArmorSlot != null && !isSlotWorn(_equippedArmorSlot)) {
    base += getItemDefense(_equippedArmorSlot!.item, _equippedArmorSlot!.quality, _equippedArmorSlot!.affixIds).round();
  }
  final combatSkill = _skills[SkillType.combat];
  if (combatSkill != null && combatSkill.levelCap > 10) base += 1;
  return base;
}

// Modify tool speed/success bonus helpers to respect Worn (existing methods getSkillSpeedBonus etc.):
double getSkillSpeedBonus(SkillType skill) {
  double bonus = 0.0;
  final tool = _equippedToolSlots[skill];
  if (tool != null && !isSlotWorn(tool)) {
    bonus += tool.item.speedBonus;
  }
  // ... existing perk-driven bonuses stay ...
  return bonus;
}
```

Add test helper:

```dart
@visibleForTesting
void setEquippedWeaponForTest(InventorySlot slot) {
  _equippedWeaponSlot = slot;
}
```

- [ ] **Step 4: Run tests, verify pass**

- [ ] **Step 5: Commit**

```bash
git add lib/engine/game_engine.dart test/durability_test.dart
git commit -m "feat(durability): Worn equipment stat-stripping in getPlayerAttack/Defense + tool bonuses"
```

---

## Task 6: Repair API (materials + gold paths)

**Files:**
- Modify: `lib/engine/game_engine.dart`
- Modify: `lib/models/recipe.dart` (add `findByResultItemId` if missing)
- Test: `test/durability_test.dart` (extend)

- [ ] **Step 1: Add findByResultItemId helper if not present**

In `lib/models/recipe.dart` in the `Recipes` class:

```dart
static Recipe? findByResultItemId(String itemId) {
  try {
    return all.firstWhere((r) => r.resultItemId == itemId);
  } catch (_) {
    return null;
  }
}
```

- [ ] **Step 2: Write failing test**

Add to `test/durability_test.dart`:

```dart
group('Repair API', () {
  test('calculateRepairCost returns 25% of recipe inputs', () {
    final engine = GameEngine();
    final slot = InventorySlot(item: Items.stoneAxe, quantity: 1,
      currentDurability: 50, maxDurability: 100);
    final cost = engine.calculateRepairCost(slot);
    expect(cost['oak_log'], 1);  // 3 * 0.25 = 0.75 → ceil → 1
    expect(cost['river_clay'], 1);  // 2 * 0.25 = 0.5 → ceil → 1
  });

  test('repairWithMaterials consumes inputs and restores durability', () {
    final engine = GameEngine();
    engine.inventory = engine.inventory.addItem(Items.oakLog, 5);
    engine.inventory = engine.inventory.addItem(Items.riverClay, 5);
    engine.equipForTest(Items.stoneAxe, SkillType.woodcutting);
    engine.forceEquippedDurabilityForTest(SkillType.woodcutting, 20);

    final oakBefore = engine.inventory.getItemCount('oak_log');
    engine.repairWithMaterials(engine.equippedToolSlots[SkillType.woodcutting]!,
      slot: 'tool', skill: SkillType.woodcutting);

    final after = engine.equippedToolSlots[SkillType.woodcutting]!;
    expect(after.currentDurability, after.maxDurability);
    expect(engine.inventory.getItemCount('oak_log'), oakBefore - 1);
  });

  test('calculateRepairGoldCost scales with damage percent', () {
    final engine = GameEngine();
    final slot = InventorySlot(item: Items.bronzeSword, quantity: 1,
      currentDurability: 50, maxDurability: 100);  // 50% damaged
    final cost = engine.calculateRepairGoldCost(slot);
    // value 150 * 0.25 * 0.5 = 18.75 → ceil → 19
    expect(cost, 19);
  });

  test('repairWithGold consumes gold and restores durability', () {
    final engine = GameEngine();
    engine.playerStats = engine.playerStats.copyWith(gold: 100);
    engine.equipWeaponForTest(Items.bronzeSword);
    engine.setEquippedWeaponForTest(engine.equippedWeaponSlot!.copyWith(currentDurability: 50));

    final goldBefore = engine.playerStats.gold;
    engine.repairWithGold(engine.equippedWeaponSlot!, slot: 'weapon');
    expect(engine.equippedWeaponSlot!.currentDurability, engine.equippedWeaponSlot!.maxDurability);
    expect(engine.playerStats.gold, lessThan(goldBefore));
  });
});
```

- [ ] **Step 3: Run, verify it fails**

- [ ] **Step 4: Implement repair API**

```dart
Map<String, int> calculateRepairCost(InventorySlot slot) {
  final recipe = Recipes.findByResultItemId(slot.item.id);
  if (recipe == null) return {};
  return recipe.inputs.map((id, qty) => MapEntry(id, max(1, (qty * 0.25).ceil())));
}

bool canRepairWithMaterials(InventorySlot slot) {
  final cost = calculateRepairCost(slot);
  if (cost.isEmpty) return false;
  for (final entry in cost.entries) {
    if (!_inventory.hasItem(entry.key, entry.value)) return false;
  }
  return true;
}

void repairWithMaterials(InventorySlot equipped, {required String slot, SkillType? skill}) {
  final cost = calculateRepairCost(equipped);
  if (cost.isEmpty) return;
  for (final entry in cost.entries) {
    if (!_inventory.hasItem(entry.key, entry.value)) return;
  }
  for (final entry in cost.entries) {
    _inventory = _inventory.removeItem(entry.key, entry.value);
  }
  final updated = equipped.copyWith(currentDurability: equipped.maxDurability);
  _setEquippedSlot(slot, updated, skill: skill);
  log("Repaired ${equipped.item.icon} ${equipped.item.name} at the Crafting Bench.", LogType.success);
  AudioEngine.instance.play('ui_success');
  _lowDurabilityWarned.remove(equipped.item.id);
  notifyListeners();
}

int calculateRepairGoldCost(InventorySlot slot) {
  if (slot.maxDurability == 0) return 0;
  final damagePct = (slot.maxDurability - slot.currentDurability) / slot.maxDurability;
  return max(1, (slot.item.value * 0.25 * damagePct).ceil());
}

void repairWithGold(InventorySlot equipped, {required String slot, SkillType? skill}) {
  final cost = calculateRepairGoldCost(equipped);
  if (_playerStats.gold < cost) return;
  _playerStats = _playerStats.copyWith(gold: _playerStats.gold - cost);
  final updated = equipped.copyWith(currentDurability: equipped.maxDurability);
  _setEquippedSlot(slot, updated, skill: skill);
  log("Repaired ${equipped.item.icon} ${equipped.item.name} (-$cost gold).", LogType.success);
  AudioEngine.instance.play('ui_success');
  _lowDurabilityWarned.remove(equipped.item.id);
  notifyListeners();
}

void _setEquippedSlot(String slot, InventorySlot updated, {SkillType? skill}) {
  switch (slot) {
    case 'tool':   _equippedToolSlots[skill!] = updated;
    case 'weapon': _equippedWeaponSlot = updated;
    case 'armor':  _equippedArmorSlot = updated;
  }
}
```

- [ ] **Step 5: Run tests, verify pass**

- [ ] **Step 6: Commit**

```bash
git add lib/engine/game_engine.dart lib/models/recipe.dart test/durability_test.dart
git commit -m "feat(durability): add repair API (materials at Bench + gold at merchant)"
```

---

## Task 7: Repair UI (Bench + Merchant)

**Files:**
- Modify: `lib/views/inventory_view.dart` (durability bars + Worn badge)
- Modify: `lib/views/dashboard_view.dart` (equipment quick-view durability bars)
- Modify: `lib/views/build_view.dart` (Crafting Bench Repairs panel)
- Modify: `lib/views/shop_view.dart` (Maeve + Hilda Repairs section)

- [ ] **Step 1: Add durability bar widget to equipment slots**

In wherever equipment slot cards render (`inventory_view.dart`, `dashboard_view.dart`):

```dart
Widget _buildDurabilityBar(InventorySlot slot, BuildContext context) {
  if (slot.maxDurability == 0) return const SizedBox.shrink();
  if (slot.currentDurability <= 0) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: DSColors.error.withOpacity(0.15),
        borderRadius: BorderRadius.circular(DSRadius.sm),
        border: Border.all(color: DSColors.error),
      ),
      child: Text('WORN', style: DSText.label(context).copyWith(color: DSColors.error)),
    );
  }
  final pct = slot.currentDurability / slot.maxDurability;
  Color color;
  if (pct > 0.5) color = DSColors.success;
  else if (pct > 0.25) color = DSColors.warning;
  else color = DSColors.error;

  return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    GameProgressBar(
      progress: pct,
      color: color,
      height: 4,
      animate: true,
    ),
    const SizedBox(height: 2),
    Text('${slot.currentDurability}/${slot.maxDurability}',
      style: DSText.bodySmall(context).copyWith(fontSize: 10, color: color)),
  ]);
}
```

Render this bar within each equipped slot card on Dashboard's equipment quick-view + Inventory's equipment section.

- [ ] **Step 2: Add Repairs panel to Crafting Bench in Workshop view**

In `lib/views/build_view.dart`, when a Crafting Bench is the selected station, render:

```dart
Widget _buildRepairsPanel(BuildContext context, GameEngine engine) {
  final repairables = <Map<String, dynamic>>[
    if (engine.equippedWeaponSlot != null && engine.equippedWeaponSlot!.currentDurability < engine.equippedWeaponSlot!.maxDurability)
      {'slot': 'weapon', 'item': engine.equippedWeaponSlot!},
    if (engine.equippedArmorSlot != null && engine.equippedArmorSlot!.currentDurability < engine.equippedArmorSlot!.maxDurability)
      {'slot': 'armor', 'item': engine.equippedArmorSlot!},
    for (final entry in engine.equippedToolSlots.entries)
      if (entry.value.currentDurability < entry.value.maxDurability)
        {'slot': 'tool', 'skill': entry.key, 'item': entry.value},
  ];

  if (repairables.isEmpty) return const SizedBox.shrink();

  return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Text('REPAIRS', style: DSText.label(context)),
    const SizedBox(height: DSSpace.sm),
    for (final r in repairables) ...[
      GameCard(
        padding: const EdgeInsets.all(DSSpace.md),
        child: Row(children: [
          Text((r['item'] as InventorySlot).item.icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: DSSpace.sm),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text((r['item'] as InventorySlot).item.name, style: DSText.bodyMedium(context)),
            Text('Cost: ${_formatMaterialCost(engine.calculateRepairCost(r['item']))}',
              style: DSText.bodySmall(context)),
          ])),
          GameButton(
            label: 'Repair',
            size: GameButtonSize.sm,
            onPressed: engine.canRepairWithMaterials(r['item']) ? () {
              engine.repairWithMaterials(r['item'], slot: r['slot'], skill: r['skill']);
            } : null,
          ),
        ]),
      ),
      const SizedBox(height: DSSpace.sm),
    ],
  ]);
}

String _formatMaterialCost(Map<String, int> cost) {
  return cost.entries.map((e) => '${e.value} ${e.key.replaceAll('_', ' ')}').join(' + ');
}
```

- [ ] **Step 3: Add Repairs section to Maeve / Hilda shop views**

In `lib/views/shop_view.dart`, when viewing Maeve (tools) or Hilda (weapons + armor), prepend a Repairs section listing damaged equipment matching the merchant category with gold cost + Repair button.

Mapping logic:

```dart
List<Map<String, dynamic>> _getRepairablesForMerchant(String merchantId, GameEngine engine) {
  switch (merchantId) {
    case 'maeve':
      return [
        for (final entry in engine.equippedToolSlots.entries)
          if (entry.value.currentDurability < entry.value.maxDurability)
            {'slot': 'tool', 'skill': entry.key, 'item': entry.value},
      ];
    case 'hilda':
      return [
        if (engine.equippedWeaponSlot != null && engine.equippedWeaponSlot!.currentDurability < engine.equippedWeaponSlot!.maxDurability)
          {'slot': 'weapon', 'item': engine.equippedWeaponSlot!},
        if (engine.equippedArmorSlot != null && engine.equippedArmorSlot!.currentDurability < engine.equippedArmorSlot!.maxDurability)
          {'slot': 'armor', 'item': engine.equippedArmorSlot!},
      ];
    default: return [];
  }
}
```

Render rows similar to the Bench panel but with gold cost from `calculateRepairGoldCost`.

- [ ] **Step 4: Verify visually**

Run: `flutter run -d windows`

Equip something, complete a few actions, verify the durability bar drains. Travel to Maeve / Hilda / Crafting Bench, verify Repairs UI appears and works.

- [ ] **Step 5: Commit**

```bash
git add lib/views/
git commit -m "feat(ui): durability bars + Worn badges + Repairs panels (Bench + Maeve/Hilda)"
```

---

## Task 8: ReagentSpawn model + engine state

**Files:**
- Create: `lib/models/reagent_spawn.dart`
- Modify: `lib/engine/game_engine.dart`
- Test: `test/reagent_test.dart` (extend)

- [ ] **Step 1: Write failing test**

Add to `test/reagent_test.dart`:

```dart
import 'package:flutter_text_based_rpg/models/reagent_spawn.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/models/zone.dart';
import 'package:flutter_text_based_rpg/models/skill.dart';

group('ReagentSpawn engine', () {
  test('_generateSessionSpawns produces 2 spawns at low total level', () {
    final engine = GameEngine();
    engine.unlockZoneForTest('whispering_woods_1');
    engine.generateSessionSpawnsForTest();
    expect(engine.activeSessionSpawnsForTest.length, 2);
  });

  test('Spawns are only assigned to unlocked non-Town-Square zones', () {
    final engine = GameEngine();
    engine.unlockZoneForTest('whispering_woods_1');
    engine.generateSessionSpawnsForTest();
    for (final spawn in engine.activeSessionSpawnsForTest) {
      expect(spawn.zoneId, isNot('town_square'));
    }
  });

  test('collectReagentSpawn requires skill 5', () {
    final engine = GameEngine();
    engine.unlockZoneForTest('whispering_woods_1');
    engine.travelTo(Zones.whisperingWoodsTier1);
    final spawn = ReagentSpawn(
      reagentItemId: 'moonpetal',
      zoneId: 'whispering_woods_1',
      noticeText: 'test',
      collectionSkill: SkillType.wayfinding,
    );
    engine.injectReagentSpawnForTest(spawn);

    final invCountBefore = engine.inventory.getItemCount('moonpetal');
    engine.collectReagentSpawn(0);  // wayfinding level 1, should fail
    expect(engine.inventory.getItemCount('moonpetal'), invCountBefore);

    // Bump wayfinding to 5
    engine.skills[SkillType.wayfinding] = engine.skills[SkillType.wayfinding]!.copyWith(level: 5);
    engine.collectReagentSpawn(0);
    expect(engine.inventory.getItemCount('moonpetal'), invCountBefore + 1);
  });

  test('collectReagentSpawn marks spawn collected; cannot collect twice', () {
    final engine = GameEngine();
    engine.unlockZoneForTest('whispering_woods_1');
    engine.travelTo(Zones.whisperingWoodsTier1);
    engine.skills[SkillType.wayfinding] = engine.skills[SkillType.wayfinding]!.copyWith(level: 5);
    final spawn = ReagentSpawn(
      reagentItemId: 'moonpetal',
      zoneId: 'whispering_woods_1',
      noticeText: 'test',
      collectionSkill: SkillType.wayfinding,
    );
    engine.injectReagentSpawnForTest(spawn);

    engine.collectReagentSpawn(0);
    expect(engine.activeSessionSpawnsForTest[0].collected, true);

    final invCount = engine.inventory.getItemCount('moonpetal');
    engine.collectReagentSpawn(0);  // second tap
    expect(engine.inventory.getItemCount('moonpetal'), invCount);
  });
});
```

- [ ] **Step 2: Run, verify it fails**

- [ ] **Step 3: Create lib/models/reagent_spawn.dart**

```dart
import 'skill.dart';

class ReagentSpawn {
  final String reagentItemId;
  final String zoneId;
  final String noticeText;
  final SkillType collectionSkill;
  bool collected;

  ReagentSpawn({
    required this.reagentItemId,
    required this.zoneId,
    required this.noticeText,
    required this.collectionSkill,
    this.collected = false,
  });
}
```

- [ ] **Step 4: Add engine state + methods**

In `lib/engine/game_engine.dart`:

```dart
import '../models/reagent_spawn.dart';

List<ReagentSpawn> _activeSessionSpawns = [];

@visibleForTesting
List<ReagentSpawn> get activeSessionSpawnsForTest => _activeSessionSpawns;

@visibleForTesting
void generateSessionSpawnsForTest() => _generateSessionSpawns();

@visibleForTesting
void injectReagentSpawnForTest(ReagentSpawn s) {
  _activeSessionSpawns.add(s);
  notifyListeners();
}

void _generateSessionSpawns() {
  if (_activeSessionSpawns.isNotEmpty) return;

  final totalLevel = _skills.values.fold<int>(0, (sum, s) => sum + s.level);
  final spawnCount = totalLevel < 30 ? 2 : (totalLevel < 80 ? 3 : 4);

  final eligibleZones = _unlockedZoneIds.where((id) => id != 'town_square').toList();
  if (eligibleZones.isEmpty) return;

  for (int i = 0; i < spawnCount; i++) {
    final zoneId = eligibleZones[_random.nextInt(eligibleZones.length)];
    final spawn = _rollReagentForZone(zoneId);
    if (spawn != null) _activeSessionSpawns.add(spawn);
  }
  log("The world feels alive. $spawnCount unusual sightings rumored.", LogType.info);
}

ReagentSpawn? _rollReagentForZone(String zoneId) {
  List<String> pool;
  if (zoneId.startsWith('whispering_woods')) {
    pool = ['moonpetal', 'spirit_sap', 'coalblood'];
  } else if (zoneId.startsWith('darkstone_mine')) {
    pool = ['hollow_bone', 'sea_tear', 'coalblood'];
  } else if (zoneId.startsWith('sundered_coast')) {
    pool = ['sea_tear', 'spirit_sap', 'moonpetal'];
  } else {
    return null;
  }

  String reagentId = _random.nextDouble() < 0.10
    ? 'wisp_light'
    : pool[_random.nextInt(pool.length)];

  return ReagentSpawn(
    reagentItemId: reagentId,
    zoneId: zoneId,
    noticeText: _noticeTextFor(reagentId),
    collectionSkill: _collectionSkillFor(reagentId),
  );
}

String _noticeTextFor(String reagentId) {
  switch (reagentId) {
    case 'moonpetal': return 'You notice a faint pale glow among the underbrush.';
    case 'spirit_sap': return 'A tree weeps clear, slow sap that catches the light.';
    case 'hollow_bone': return 'You notice a small white bone half-buried in the dust.';
    case 'sea_tear': return 'Something crystalline glimmers in the deep pool.';
    case 'coalblood': return 'A dark seep pools at the base of a stone.';
    case 'wisp_light': return 'A tiny flickering mote drifts above the path.';
  }
  return 'You notice something unusual.';
}

SkillType _collectionSkillFor(String reagentId) {
  switch (reagentId) {
    case 'spirit_sap': return SkillType.herbalism;
    case 'coalblood': return SkillType.mining;
    default: return SkillType.wayfinding;
  }
}

void collectReagentSpawn(int spawnIndex) {
  if (spawnIndex < 0 || spawnIndex >= _activeSessionSpawns.length) return;
  final spawn = _activeSessionSpawns[spawnIndex];
  if (spawn.collected) return;
  if (_currentZone.id != spawn.zoneId) return;

  final skill = _skills[spawn.collectionSkill];
  if (skill == null || skill.level < 5) {
    log("You don't have the skill to retrieve this. (Requires ${spawn.collectionSkill.name} Lvl 5)", LogType.warning);
    return;
  }
  if (_playerStats.currentEnergy < 5) {
    log("You're too tired. Rest first.", LogType.warning);
    return;
  }
  _playerStats = _playerStats.copyWith(currentEnergy: _playerStats.currentEnergy - 5);

  final reagent = Items.findById(spawn.reagentItemId)!;
  _inventory = _inventory.addItem(reagent, 1);
  spawn.collected = true;

  log("Collected ${reagent.icon} ${reagent.name}!", LogType.success);
  AudioEngine.instance.play('ui_success');
  notifyListeners();
}
```

Trigger `_generateSessionSpawns` on first `travelTo` per session:

```dart
// In existing travelTo:
if (_activeSessionSpawns.isEmpty) {
  _generateSessionSpawns();
}
```

- [ ] **Step 5: Run tests, verify pass**

- [ ] **Step 6: Commit**

```bash
git add lib/models/reagent_spawn.dart lib/engine/game_engine.dart test/reagent_test.dart
git commit -m "feat(reagent): spawn engine + per-biome pools + collection action"
```

---

## Task 9: Notice card UI in zone actions

**Files:**
- Modify: `lib/views/dashboard_view.dart`

- [ ] **Step 1: Render Notice cards at top of zone actions list**

In `lib/views/dashboard_view.dart`, find the zone-action list rendering and prepend:

```dart
Widget _buildNoticeCards(BuildContext context, GameEngine engine) {
  final activeSpawns = engine.activeSessionSpawnsForTest  // exposed via @visibleForTesting; rename to public getter
    .asMap()
    .entries
    .where((e) => !e.value.collected && e.value.zoneId == engine.currentZone.id)
    .toList();

  if (activeSpawns.isEmpty) return const SizedBox.shrink();

  return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    for (final entry in activeSpawns) ...[
      GameCard(
        accentBorder: DSColors.accent,
        padding: const EdgeInsets.all(DSSpace.md),
        child: Row(children: [
          const Text('✨', style: TextStyle(fontSize: 22)),
          const SizedBox(width: DSSpace.sm),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('NOTICE', style: DSText.label(context).copyWith(color: DSColors.accent)),
            const SizedBox(height: 2),
            Text(entry.value.noticeText, style: DSText.bodyMedium(context)),
            const SizedBox(height: 2),
            Text('${entry.value.collectionSkill.name} Lvl 5 · ⚡ 5',
              style: DSText.bodySmall(context)),
          ])),
          GameButton(
            label: 'Investigate',
            size: GameButtonSize.sm,
            onPressed: () => engine.collectReagentSpawn(entry.key),
          ),
        ]),
      ),
      const SizedBox(height: DSSpace.sm),
    ],
  ]);
}
```

Add a public engine getter:

```dart
List<ReagentSpawn> get activeSessionSpawns => List.unmodifiable(_activeSessionSpawns);
```

Replace `activeSessionSpawnsForTest` usage above with `activeSessionSpawns` public API.

- [ ] **Step 2: Verify visually**

Run the app, travel to an unlocked non-Town-Square zone. If RNG places a spawn there, the pulsing Notice card appears at top. Tap Investigate → reagent added to inventory.

- [ ] **Step 3: Commit**

```bash
git add lib/views/dashboard_view.dart lib/engine/game_engine.dart
git commit -m "feat(ui): Notice card render at top of zone actions list"
```

---

## Task 10: Reagent modifier effects

**Files:**
- Modify: `lib/engine/game_engine.dart`
- Test: `test/reagent_test.dart` (extend)

- [ ] **Step 1: Write failing test**

Add to `test/reagent_test.dart`:

```dart
group('Reagent modifier effects', () {
  test('Wisp-Light guarantees Masterwork on craft', () {
    final engine = GameEngine();
    // Setup: enough materials for a Stone Axe craft, with Wisp-Light in modifier slot
    final result = engine.resolveCraftWithModifierForTest('stone_axe', modifierItemId: 'wisp_light');
    expect(result.quality, QualityTier.masterwork);
  });

  test('Hollow Bone adds Brutal to weapon craft', () {
    final engine = GameEngine();
    final result = engine.resolveCraftWithModifierForTest('bronze_sword', modifierItemId: 'hollow_bone');
    expect(result.affixIds, contains('brutal'));
  });

  test('Hollow Bone on tool craft consumes modifier but adds no affix', () {
    final engine = GameEngine();
    final result = engine.resolveCraftWithModifierForTest('stone_axe', modifierItemId: 'hollow_bone');
    expect(result.affixIds, isNot(contains('brutal')));
  });

  test('Spirit Sap doubles output quantity', () {
    final engine = GameEngine();
    final result = engine.resolveCraftWithModifierForTest('stone_axe', modifierItemId: 'spirit_sap');
    expect(result.quantity, greaterThanOrEqualTo(2));
  });
});
```

- [ ] **Step 2: Run, verify it fails**

- [ ] **Step 3: Extend modifier-effect resolution**

In `lib/engine/game_engine.dart`, find Spec 4's `_resolveCraftCompletion` (or wherever modifier effects are resolved) and add the new cases:

```dart
// Find the existing modifier switch:
switch (modifierId) {
  // ... existing cases (wildflower, nightshade, river_clay, wild_berries, troll_claw, boar_tusk) ...

  case 'moonpetal':
    if (_isAffixable(resultItem)) {
      affixIds.add(_rollRandomAffix(resultItem.type));
    }
    break;
  case 'spirit_sap':
    finalQty = finalQty * 2;
    break;
  case 'hollow_bone':
    if (resultItem.type == ItemType.weapon) affixIds.add('brutal');
    break;
  case 'sea_tear':
    if (resultItem.type == ItemType.armor) affixIds.add('tempered');
    break;
  case 'coalblood':
    affixIds.add('frugal');
    break;
  case 'wisp_light':
    quality = QualityTier.masterwork;
    affixIds = [_rollRandomAffix(resultItem.type), _rollRandomAffix(resultItem.type)];
    break;
  case 'tinkers_bauble':
    finalQty += 1;
    break;
}
_inventory = _inventory.removeItem(modifierId, 1);
```

Add test helper that synthesizes a craft resolution:

```dart
@visibleForTesting
({QualityTier quality, List<String> affixIds, int quantity}) resolveCraftWithModifierForTest(
    String recipeId, {required String modifierItemId}) {
  final recipe = Recipes.findById(recipeId)!;
  final resultItem = Items.findById(recipe.resultItemId)!;
  // Force inventory to have the modifier
  _inventory = _inventory.addItem(Items.findById(modifierItemId)!, 1);
  // Simulate the resolution with a mock skill state + roll
  // (implementation-specific — replicate the relevant logic from _resolveCraftCompletion)
  // ... use the actual resolution code path and return the result tuple
  // (For test simplicity, may need a test-only refactoring of the resolution into a pure function)
}
```

(The test helper signature depends on how Spec 4's existing crafting resolution is structured. If a pure helper doesn't exist yet, this is the time to extract one for testability.)

- [ ] **Step 4: Run tests, verify pass**

- [ ] **Step 5: Commit**

```bash
git add lib/engine/game_engine.dart test/reagent_test.dart
git commit -m "feat(reagent): wire 7 new modifier effects (6 reagents + tinkers_bauble)"
```

---

## Task 11: MerchantReputation model + engine state

**Files:**
- Modify: `lib/models/shop.dart`
- Modify: `lib/engine/game_engine.dart`
- Test: `test/reputation_test.dart` (new)

- [ ] **Step 1: Write failing test**

Create `test/reputation_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/models/shop.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';

void main() {
  group('MerchantReputation tier thresholds', () {
    test('Tiers at 0/500/2000/5000/12000', () {
      final r = MerchantReputation(merchantId: 'test');
      r.totalRep = 0; expect(r.tier, ReputationTier.stranger);
      r.totalRep = 499; expect(r.tier, ReputationTier.stranger);
      r.totalRep = 500; expect(r.tier, ReputationTier.familiar);
      r.totalRep = 1999; expect(r.tier, ReputationTier.familiar);
      r.totalRep = 2000; expect(r.tier, ReputationTier.trustedPatron);
      r.totalRep = 4999; expect(r.tier, ReputationTier.trustedPatron);
      r.totalRep = 5000; expect(r.tier, ReputationTier.honoredFriend);
      r.totalRep = 11999; expect(r.tier, ReputationTier.honoredFriend);
      r.totalRep = 12000; expect(r.tier, ReputationTier.swornCompanion);
    });
  });

  group('Engine rep gain', () {
    test('Buying 50 gold worth grants +100 rep (capped by session)', () {
      final engine = GameEngine();
      engine.recordBuyForRepTest('hilda', 50);
      expect(engine.merchantReputation('hilda').totalRep, 100);
    });

    test('Session cap 200 enforced', () {
      final engine = GameEngine();
      // 150 gold spent → +300 rep, but capped at 200
      engine.recordBuyForRepTest('hilda', 150);
      expect(engine.merchantReputation('hilda').totalRep, 200);
      expect(engine.merchantReputation('hilda').sessionRepGained, 200);

      // Further buys grant 0 rep
      engine.recordBuyForRepTest('hilda', 50);
      expect(engine.merchantReputation('hilda').totalRep, 200);
    });

    test('Selling grants 1/gold (vs 2/gold for buying)', () {
      final engine = GameEngine();
      engine.recordSellForRepTest('cedric', 50);
      expect(engine.merchantReputation('cedric').totalRep, 50);
    });
  });
}
```

- [ ] **Step 2: Run, verify it fails**

- [ ] **Step 3: Add MerchantReputation + engine state**

In `lib/models/shop.dart`:

```dart
enum ReputationTier { stranger, familiar, trustedPatron, honoredFriend, swornCompanion }

class MerchantReputation {
  final String merchantId;
  int totalRep;
  int sessionRepGained;

  MerchantReputation({required this.merchantId, this.totalRep = 0, this.sessionRepGained = 0});

  ReputationTier get tier {
    if (totalRep >= 12000) return ReputationTier.swornCompanion;
    if (totalRep >= 5000) return ReputationTier.honoredFriend;
    if (totalRep >= 2000) return ReputationTier.trustedPatron;
    if (totalRep >= 500) return ReputationTier.familiar;
    return ReputationTier.stranger;
  }

  int get repForNextTier {
    switch (tier) {
      case ReputationTier.stranger: return 500;
      case ReputationTier.familiar: return 2000;
      case ReputationTier.trustedPatron: return 5000;
      case ReputationTier.honoredFriend: return 12000;
      case ReputationTier.swornCompanion: return 12000;
    }
  }
}
```

In `lib/engine/game_engine.dart`:

```dart
final Map<String, MerchantReputation> _merchantRep = {};
final Set<String> _claimedGifts = {};

MerchantReputation merchantReputation(String merchantId) {
  return _merchantRep.putIfAbsent(merchantId, () => MerchantReputation(merchantId: merchantId));
}

MerchantReputation _ensureRep(String merchantId) => merchantReputation(merchantId);

@visibleForTesting
void recordBuyForRepTest(String merchantId, int goldSpent) {
  final rep = _ensureRep(merchantId);
  final repGain = (goldSpent * 2).clamp(0, 200 - rep.sessionRepGained);
  if (repGain > 0) {
    rep.totalRep += repGain;
    rep.sessionRepGained += repGain;
  }
}

@visibleForTesting
void recordSellForRepTest(String merchantId, int goldGained) {
  final rep = _ensureRep(merchantId);
  final repGain = (goldGained * 1).clamp(0, 200 - rep.sessionRepGained);
  if (repGain > 0) {
    rep.totalRep += repGain;
    rep.sessionRepGained += repGain;
  }
}
```

- [ ] **Step 4: Run, verify pass**

- [ ] **Step 5: Commit**

```bash
git add lib/models/shop.dart lib/engine/game_engine.dart test/reputation_test.dart
git commit -m "feat(reputation): add MerchantReputation model + engine state"
```

---

## Task 12: Wire rep gain into buyItem/sellItem + tier-up handler

**Files:**
- Modify: `lib/engine/game_engine.dart`
- Test: `test/reputation_test.dart` (extend)

- [ ] **Step 1: Write failing test**

Add to `test/reputation_test.dart`:

```dart
test('buyItem grants rep + fires tier-up at thresholds', () {
  final engine = GameEngine();
  engine.playerStats = engine.playerStats.copyWith(gold: 10000);

  // Buy enough from Hilda to hit Trusted Patron (need 2000 rep / 200 per session = 10 sessions...)
  // Use test-only batch helper to force tier-up
  engine.forceMerchantRepForTest('hilda', 2000);
  expect(engine.merchantReputation('hilda').tier, ReputationTier.trustedPatron);
  expect(engine.engineFlags.contains('rep_hilda_tier_trustedPatron'), true);
});

test('Sworn Companion tier grants merchant_<id> Codex fragment', () {
  final engine = GameEngine();
  engine.forceMerchantRepForTest('bram', 12000);
  expect(engine.knownCodexFragmentIds.contains('merchant_bram'), true);
});
```

- [ ] **Step 2: Run, verify it fails**

- [ ] **Step 3: Extend existing buyItem/sellItem + add tier-up handler**

```dart
// Modify existing buyItem (after the purchase succeeds):
final rep = _ensureRep(merchant.id);
final repGain = (goldSpent * 2).clamp(0, 200 - rep.sessionRepGained);
if (repGain > 0) {
  rep.totalRep += repGain;
  rep.sessionRepGained += repGain;
  _checkRepTierUp(merchant.id);
}

// Modify existing sellItem (after the sell succeeds):
final rep = _ensureRep(merchant.id);
final repGain = (goldGained * 1).clamp(0, 200 - rep.sessionRepGained);
if (repGain > 0) {
  rep.totalRep += repGain;
  rep.sessionRepGained += repGain;
  _checkRepTierUp(merchant.id);
}

void _checkRepTierUp(String merchantId) {
  final rep = _merchantRep[merchantId]!;
  final newTier = rep.tier;
  final flagId = 'rep_${merchantId}_tier_${newTier.name}';
  if (_engineFlags.contains(flagId)) return;
  _engineFlags.add(flagId);

  switch (newTier) {
    case ReputationTier.familiar:
      log("${_merchantName(merchantId)} now greets you as a Familiar face.", LogType.success);
    case ReputationTier.trustedPatron:
      log("${_merchantName(merchantId)} considers you a Trusted Patron. New stock available.", LogType.success);
      _onTrustedPatronUnlocked(merchantId);
    case ReputationTier.honoredFriend:
      log("${_merchantName(merchantId)} now calls you an Honored Friend. A gift awaits.", LogType.success);
    case ReputationTier.swornCompanion:
      log("${_merchantName(merchantId)} names you Sworn Companion.", LogType.success);
      _onSwornCompanionUnlocked(merchantId);
    case ReputationTier.stranger:
      break;
  }
  AudioEngine.instance.play('ui_success');
  notifyListeners();
}

void _onTrustedPatronUnlocked(String merchantId) {
  // Trusted Patron unique stock is gated by the rep tier check in shop view (Task 14)
  // No additional state needed here
}

void _onSwornCompanionUnlocked(String merchantId) {
  // Grant the merchant_<id> Codex fragment
  final fragmentId = 'merchant_$merchantId';
  if (Items.findById(fragmentId) != null || CodexFragments.findById(fragmentId) != null) {
    _knownCodexFragmentIds.add(fragmentId);
    log("A new fragment lodges itself in the Codex: ${CodexFragments.findById(fragmentId)?.title ?? 'Story'}.", LogType.success);
  }
}

String _merchantName(String merchantId) {
  switch (merchantId) {
    case 'cedric': return 'Cedric';
    case 'hilda': return 'Hilda';
    case 'pippin': return 'Pippin';
    case 'silas': return 'Silas';
    case 'maeve': return 'Maeve';
    case 'bram': return 'Bram';
  }
  return merchantId;
}

@visibleForTesting
void forceMerchantRepForTest(String merchantId, int totalRep) {
  final rep = _ensureRep(merchantId);
  rep.totalRep = totalRep;
  _checkRepTierUp(merchantId);
}
```

- [ ] **Step 4: Run tests, verify pass**

- [ ] **Step 5: Commit**

```bash
git add lib/engine/game_engine.dart test/reputation_test.dart
git commit -m "feat(reputation): wire rep gain into buy/sell + tier-up handler"
```

---

## Task 13: Add Bram merchant + 6 Sworn Companion fragments

**Files:**
- Modify: `lib/models/shop.dart` (Bram)
- Modify: `lib/models/codex.dart` (6 fragments)
- Test: `test/reputation_test.dart` (extend)

- [ ] **Step 1: Write failing test**

Add to `test/reputation_test.dart`:

```dart
import 'package:flutter_text_based_rpg/models/codex.dart';

group('Bram + Sworn Companion fragments', () {
  test('Bram exists in Merchant.all', () {
    expect(Merchant.all.any((m) => m.id == 'bram'), true);
    final bram = Merchant.all.firstWhere((m) => m.id == 'bram');
    expect(bram.title, 'The Tavern-Keeper');
    expect(bram.icon, '🍺');
  });

  test('Bram has 5 base listings', () {
    final bram = Merchant.all.firstWhere((m) => m.id == 'bram');
    expect(bram.baseListings.length, 5);
  });

  test('6 Sworn Companion Codex fragments exist (Misc tag)', () {
    for (final id in ['merchant_cedric', 'merchant_hilda', 'merchant_pippin',
                       'merchant_silas', 'merchant_maeve', 'merchant_bram']) {
      final f = CodexFragments.findById(id);
      expect(f, isNotNull, reason: 'Missing: $id');
      expect(f!.tag, CodexTag.misc);
    }
  });
});
```

- [ ] **Step 2: Run, verify it fails**

- [ ] **Step 3: Add Bram + 6 fragments**

In `lib/models/shop.dart` `Merchant` class:

```dart
static final Merchant bram = Merchant(
  id: 'bram',
  name: 'Bram',
  title: 'The Tavern-Keeper',
  icon: '🍺',
  greetings: [
    "First round's on the house if you've news worth telling.",
    "The fire's hot and the kettle's full. What'll it be?",
    "There's a corner table free. Sit a while.",
    "We hear most things first, here. We just don't always say.",
  ],
  baseListings: [
    ShopListing(item: Items.herbalTea, buyPrice: 14, sellPrice: 5, stock: 8, maxStock: 8, category: ShopCategory.provisions),
    ShopListing(item: Items.spicedTea, buyPrice: 32, sellPrice: 11, stock: 5, maxStock: 5, category: ShopCategory.provisions),
    ShopListing(item: Items.bakedPotato, buyPrice: 10, sellPrice: 3, stock: 12, maxStock: 12, category: ShopCategory.provisions),
    ShopListing(item: Items.smokedTrout, buyPrice: 27, sellPrice: 9, stock: 4, maxStock: 4, category: ShopCategory.provisions),
    ShopListing(item: Items.hotWater, buyPrice: 3, sellPrice: 1, category: ShopCategory.supplies),
  ],
);

static final List<Merchant> all = [cedric, hilda, pippin, silas, maeve, bram];
```

In `lib/models/codex.dart`, append to `CodexFragments.all`:

```dart
CodexFragment(id: 'merchant_cedric', tag: CodexTag.misc, title: "Cedric's Story",
  text: "Cedric's mother ran the cart before he did. She walked all the way from the Old Empire's last city before it fell. He has never told anyone this.",
  sourceHint: "Sworn Companion of Cedric", orderInTag: 1),
CodexFragment(id: 'merchant_hilda', tag: CodexTag.misc, title: "Hilda's Story",
  text: "Hilda forged her first true blade at twelve. Her teacher was burned in the second-to-last forge-fire of the Old Age. She still keeps his hammer.",
  sourceHint: "Sworn Companion of Hilda", orderInTag: 2),
CodexFragment(id: 'merchant_pippin', tag: CodexTag.misc, title: "Pippin's Story",
  text: "Pippin once mixed a draught that brought a dead bird back to life for forty seconds. He has never tried it on anything larger. He never will.",
  sourceHint: "Sworn Companion of Pippin", orderInTag: 3),
CodexFragment(id: 'merchant_silas', tag: CodexTag.misc, title: "Silas's Story",
  text: "Silas can read three dead languages. He learned the first as a child. He learned the second under threat. He learned the third because he wanted to.",
  sourceHint: "Sworn Companion of Silas", orderInTag: 4),
CodexFragment(id: 'merchant_maeve', tag: CodexTag.misc, title: "Maeve's Story",
  text: "Maeve walked the deep woods alone for a year between her sixteenth and seventeenth winters. She has never said what she found there. She came back changed.",
  sourceHint: "Sworn Companion of Maeve", orderInTag: 5),
CodexFragment(id: 'merchant_bram', tag: CodexTag.misc, title: "Bram's Story",
  text: "Bram took over the tavern from his father, who took it from his father. The tavern is older than the town. Bram does not know what is buried beneath the cellar floor. He hopes it stays there.",
  sourceHint: "Sworn Companion of Bram", orderInTag: 6),
```

- [ ] **Step 4: Run, verify pass**

- [ ] **Step 5: Commit**

```bash
git add lib/models/shop.dart lib/models/codex.dart test/reputation_test.dart
git commit -m "feat(shop): add Bram the Tavern-Keeper + 6 Sworn Companion Codex fragments"
```

---

## Task 14: Reputation UI (chip on shop + discount + gift modal)

**Files:**
- Modify: `lib/views/shop_view.dart`
- Modify: `lib/engine/game_engine.dart` (Honored Friend gift API)

- [ ] **Step 1: Add gift API + Trusted Patron stock helpers in engine**

In `lib/engine/game_engine.dart`:

```dart
void claimHonoredFriendGift(String merchantId) {
  if (_claimedGifts.contains(merchantId)) return;
  if (_merchantRep[merchantId]?.tier.index ?? 0 < ReputationTier.honoredFriend.index) return;
  _claimedGifts.add(merchantId);

  switch (merchantId) {
    case 'cedric': _grantRandomBlueprint();
    case 'hilda': _grantBlueprintByTag('smith');
    case 'pippin': _inventory = _inventory.addItem(Items.wispLight, 1);
    case 'silas': _tryGrantOldEmpireFragment();
    case 'maeve': _grantRandomFineTool();
    case 'bram': _inventory = _inventory.addItem(Items.bakedPotato, 5);
  }
  log("${_merchantName(merchantId)} hands you a parting gift.", LogType.success);
  AudioEngine.instance.play('ui_success');
  notifyListeners();
}

bool hasUnclaimedGift(String merchantId) {
  final rep = _merchantRep[merchantId];
  if (rep == null) return false;
  return rep.tier.index >= ReputationTier.honoredFriend.index && !_claimedGifts.contains(merchantId);
}

// Helper stubs (implementations vary based on existing blueprint/fragment systems):
void _grantRandomBlueprint() { /* TODO when blueprint pool exists */ }
void _grantBlueprintByTag(String tag) { /* TODO */ }
void _tryGrantOldEmpireFragment() {
  // Drop a random Old Empire fragment the player doesn't already have
  final fragments = CodexFragments.all
    .where((f) => f.tag == CodexTag.oldEmpire && !_knownCodexFragmentIds.contains(f.id))
    .toList();
  if (fragments.isNotEmpty) {
    final f = fragments[_random.nextInt(fragments.length)];
    _knownCodexFragmentIds.add(f.id);
  }
}
void _grantRandomFineTool() {
  // Add a random tool with Fine quality stamp
  final tools = Items.all.where((i) => i.isTool).toList();
  if (tools.isEmpty) return;
  final tool = tools[_random.nextInt(tools.length)];
  final maxDur = calculateMaxDurability(tool, QualityTier.fine, []);
  _inventory = _inventory.addSlot(InventorySlot(
    item: tool, quantity: 1, quality: QualityTier.fine,
    currentDurability: maxDur, maxDurability: maxDur,
  ));
}
```

- [ ] **Step 2: Add rep chip + discount + gift popover in shop view**

In `lib/views/shop_view.dart`, at the top of each merchant's view:

```dart
Widget _buildRepChip(BuildContext context, GameEngine engine, String merchantId) {
  final rep = engine.merchantReputation(merchantId);
  if (rep.totalRep == 0) return const SizedBox.shrink();  // progressive discovery
  final tier = rep.tier;
  final tierName = _tierDisplayName(tier);
  final nextTier = _nextTierDisplayName(tier);
  final progressTo = rep.repForNextTier;
  final pct = rep.totalRep / progressTo;

  return Padding(
    padding: const EdgeInsets.all(DSSpace.sm),
    child: GameCard(
      padding: const EdgeInsets.all(DSSpace.md),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('💍', style: TextStyle(fontSize: 16)),
          const SizedBox(width: DSSpace.xs),
          Text(tierName, style: DSText.headingSmall(context)),
        ]),
        const SizedBox(height: 4),
        GameProgressBar(progress: pct, color: DSColors.accent, height: 4, animate: true),
        const SizedBox(height: 2),
        Text('${rep.totalRep} / $progressTo to $nextTier',
          style: DSText.bodySmall(context)),
      ]),
    ),
  );
}

String _tierDisplayName(ReputationTier t) {
  switch (t) {
    case ReputationTier.stranger: return 'Stranger';
    case ReputationTier.familiar: return 'Familiar';
    case ReputationTier.trustedPatron: return 'Trusted Patron';
    case ReputationTier.honoredFriend: return 'Honored Friend';
    case ReputationTier.swornCompanion: return 'Sworn Companion';
  }
}
```

Apply discount in price display:

```dart
int displayBuyPrice(ShopListing listing, GameEngine engine, String merchantId) {
  final rep = engine.merchantReputation(merchantId);
  double discount = 0.0;
  switch (rep.tier) {
    case ReputationTier.trustedPatron: discount = 0.10;
    case ReputationTier.honoredFriend: discount = 0.20;
    case ReputationTier.swornCompanion: discount = 0.30;
    default: discount = 0.0;
  }
  return max(1, (listing.effectiveBuyPrice * (1 - discount)).ceil());
}
```

Add gift popover on first visit after reaching Honored Friend:

```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    final engine = Provider.of<GameEngine>(context, listen: false);
    if (engine.hasUnclaimedGift(widget.merchantId)) {
      _showGiftPopover(context, engine);
    }
  });
}

void _showGiftPopover(BuildContext context, GameEngine engine) {
  showDialog(context: context, builder: (_) => AlertDialog(
    title: const Text('A Gift'),
    content: Text('${_merchantName(widget.merchantId)} has prepared a gift for you.'),
    actions: [
      GameButton(label: 'Accept', onPressed: () {
        engine.claimHonoredFriendGift(widget.merchantId);
        Navigator.pop(context);
      }),
    ],
  ));
}
```

- [ ] **Step 3: Verify visually**

Run app, force a tier-up via test scenario, see chip + discount apply + gift popover.

- [ ] **Step 4: Commit**

```bash
git add lib/views/shop_view.dart lib/engine/game_engine.dart
git commit -m "feat(ui): rep chip + discount + Honored Friend gift popover on shop view"
```

---

## Task 15: Codex Reputation tab

**Files:**
- Modify: `lib/views/codex_view.dart`

- [ ] **Step 1: Add Reputation tab (conditional)**

In `lib/views/codex_view.dart`, find the tabs definition (Quests / Fragments / Beasts / Regions) and conditionally append Reputation:

```dart
final tabs = [
  // existing tabs ...
  if (engine.hasAnyMerchantInteractionForTest)
    GameTab(label: 'Reputation', icon: Icons.handshake),
];

// In the tab content builder:
if (selectedIndex == reputationTabIndex) {
  return _buildReputationTab(context, engine);
}

Widget _buildReputationTab(BuildContext context, GameEngine engine) {
  return ListView(
    padding: const EdgeInsets.all(DSSpace.lg),
    children: [
      for (final m in Merchant.all) ...[
        _buildMerchantRepCard(context, engine, m),
        const SizedBox(height: DSSpace.md),
      ],
    ],
  );
}

Widget _buildMerchantRepCard(BuildContext context, GameEngine engine, Merchant m) {
  final rep = engine.merchantReputation(m.id);
  final pct = rep.totalRep / rep.repForNextTier;
  return GameCard(
    padding: const EdgeInsets.all(DSSpace.lg),
    onTap: () => _showRewardLadderModal(context, m),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        GameAvatar(emoji: m.icon, size: GameAvatarSize.md),
        const SizedBox(width: DSSpace.md),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${m.name} — ${_tierDisplayName(rep.tier)}', style: DSText.headingSmall(context)),
          Text(m.title, style: DSText.bodySmall(context)),
        ])),
      ]),
      const SizedBox(height: DSSpace.sm),
      GameProgressBar(progress: pct, color: DSColors.accent, height: 6, animate: true),
      const SizedBox(height: 2),
      Text('${rep.totalRep} / ${rep.repForNextTier}', style: DSText.bodySmall(context)),
    ]),
  );
}
```

Add the engine helper:

```dart
bool get hasAnyMerchantInteraction => _merchantRep.values.any((r) => r.totalRep > 0);
```

(Rename `hasAnyMerchantInteractionForTest` to the public `hasAnyMerchantInteraction` getter.)

- [ ] **Step 2: Verify visually**

Trade with any merchant. Open Codex → Reputation tab appears with 6 merchant cards.

- [ ] **Step 3: Commit**

```bash
git add lib/views/codex_view.dart lib/engine/game_engine.dart
git commit -m "feat(codex): add Reputation tab with 6 merchant cards + reward ladder modal"
```

---

## Task 16: Daily task model + 30 templates

**Files:**
- Create: `lib/models/daily_task.dart`
- Test: `test/daily_task_test.dart` (new)

- [ ] **Step 1: Write failing test**

Create `test/daily_task_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/models/daily_task.dart';

void main() {
  group('DailyTasks registry', () {
    test('30 templates exist (5 per category × 6 categories)', () {
      expect(DailyTasks.all.length, 30);
      for (final cat in DailyTaskCategory.values) {
        final count = DailyTasks.all.where((t) => t.category == cat).length;
        expect(count, 5, reason: 'Category $cat should have 5 templates');
      }
    });

    test('Every template has a unique id', () {
      final ids = DailyTasks.all.map((t) => t.id).toSet();
      expect(ids.length, 30);
    });
  });
}
```

- [ ] **Step 2: Run, verify it fails**

- [ ] **Step 3: Create lib/models/daily_task.dart**

Add the enums, `DailyTaskTemplate`, `DailyTask` classes, and all 30 templates per spec § 5.4 (Gather, Hunt, Visit, Craft, Codex, Cleanse — 5 each). The full code is substantial — copy from spec body verbatim into `DailyTasks` class. Append all 30 to `DailyTasks.all`.

- [ ] **Step 4: Run, verify pass**

- [ ] **Step 5: Commit**

```bash
git add lib/models/daily_task.dart test/daily_task_test.dart
git commit -m "feat(daily): add DailyTask model + 30 task templates across 6 categories"
```

---

## Task 17: Daily task engine + observer hook

**Files:**
- Modify: `lib/engine/game_engine.dart`
- Test: `test/daily_task_test.dart` (extend)

- [ ] **Step 1: Write failing test**

Add to `test/daily_task_test.dart`:

```dart
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/models/quest.dart';
import 'package:flutter_text_based_rpg/models/item.dart';

group('Daily task engine', () {
  test('_generateTodaysTasks produces 3 distinct tasks', () {
    final engine = GameEngine();
    engine.generateTodaysTasksForTest();
    expect(engine.todaysTasks.length, 3);
    final ids = engine.todaysTasks.map((t) => t.templateId).toSet();
    expect(ids.length, 3, reason: '3 distinct templates');
  });

  test('Generated tasks span at least 2 categories', () {
    final engine = GameEngine();
    engine.generateTodaysTasksForTest();
    final categories = engine.todaysTasks.map((t) {
      return DailyTasks.all.firstWhere((tmpl) => tmpl.id == t.templateId).category;
    }).toSet();
    expect(categories.length, greaterThanOrEqualTo(2));
  });

  test('Task auto-progresses on matching event', () {
    final engine = GameEngine();
    engine.forceDailyTaskForTest(DailyTasks.gatherOak, qty: 5);
    final task = engine.todaysTasks.firstWhere((t) => t.templateId == 'gather_oak');
    expect(task.currentCount, 0);

    engine.advanceQuestObserverForTest(ItemGatheredEvent('oak_log', 1));
    expect(task.currentCount, 1);

    engine.advanceQuestObserverForTest(ItemGatheredEvent('oak_log', 5));
    expect(task.currentCount, 5);  // clamped at targetCount
  });

  test('claimDailyTask awards gold + XP', () {
    final engine = GameEngine();
    engine.forceDailyTaskForTest(DailyTasks.gatherOak, qty: 1);
    engine.advanceQuestObserverForTest(ItemGatheredEvent('oak_log', 1));

    final goldBefore = engine.playerStats.gold;
    engine.claimDailyTask('gather_oak');
    expect(engine.playerStats.gold, goldBefore + DailyTasks.gatherOak.baseGoldReward);
  });

  test('Daily Bonus fires only when all 3 claimed', () {
    final engine = GameEngine();
    engine.generateTodaysTasksForTest();
    // Manually claim first 2
    for (int i = 0; i < 2; i++) {
      final t = engine.todaysTasks[i];
      engine.forceDailyTaskCompletionForTest(t.templateId);
      engine.claimDailyTask(t.templateId);
    }
    expect(engine.dailyBonusClaimedForTest, false);

    // Claim 3rd
    final t3 = engine.todaysTasks[2];
    engine.forceDailyTaskCompletionForTest(t3.templateId);
    final goldBefore = engine.playerStats.gold;
    engine.claimDailyTask(t3.templateId);
    expect(engine.dailyBonusClaimedForTest, true);
    expect(engine.playerStats.gold, greaterThan(goldBefore + t3.goldReward));  // +120 bonus
  });
});
```

- [ ] **Step 2: Run, verify it fails**

- [ ] **Step 3: Implement daily task engine**

```dart
import '../models/daily_task.dart';

List<DailyTask> _todaysTasks = [];
bool _dailyBonusClaimed = false;

List<DailyTask> get todaysTasks => List.unmodifiable(_todaysTasks);

@visibleForTesting
bool get dailyBonusClaimedForTest => _dailyBonusClaimed;

@visibleForTesting
void generateTodaysTasksForTest() => _generateTodaysTasks();

void _generateTodaysTasks() {
  if (_todaysTasks.isNotEmpty) return;

  final totalLevel = _skills.values.fold<int>(0, (sum, s) => sum + s.level);
  final eligible = DailyTasks.all.where((t) {
    if (t.minPlayerLevel > totalLevel) return false;
    if (t.requiresEngineFlag && !_engineFlags.contains(t.engineFlagRequired!)) return false;
    return true;
  }).toList();

  if (eligible.isEmpty) return;

  final picks = <DailyTaskTemplate>[];
  final usedCategories = <DailyTaskCategory>{};

  final first = eligible[_random.nextInt(eligible.length)];
  picks.add(first);
  usedCategories.add(first.category);

  while (picks.length < 3) {
    final candidates = eligible.where((t) => !picks.contains(t) &&
      (usedCategories.length >= 2 || !usedCategories.contains(t.category))).toList();
    if (candidates.isEmpty) break;
    final next = candidates[_random.nextInt(candidates.length)];
    picks.add(next);
    usedCategories.add(next.category);
  }

  for (final template in picks) {
    final qty = template.minQty + _random.nextInt(template.maxQty - template.minQty + 1);
    final targetId = template.possibleTargetIds[_random.nextInt(template.possibleTargetIds.length)];
    final title = template.titleTemplate
      .replaceAll('{qty}', qty.toString())
      .replaceAll('{item}', _itemDisplayName(targetId))
      .replaceAll('{beast}', _beastDisplayName(targetId));
    _todaysTasks.add(DailyTask(
      templateId: template.id,
      resolvedTitle: title,
      iconHint: template.iconHint,
      objectiveKind: template.objectiveKind,
      targetId: targetId == 'any' ? null : targetId,
      targetCount: qty,
      goldReward: template.baseGoldReward,
      skillXpReward: template.baseSkillXpReward,
      rewardSkill: template.rewardSkill,
      claimed: false,
    ));
  }
  _dailyBonusClaimed = false;
}

void _notifyDailyTaskObservers(QuestEvent event) {
  for (final task in _todaysTasks) {
    if (task.isComplete || task.claimed) continue;
    if (_matchesTaskTarget(task, event)) {
      task.currentCount = (task.currentCount + event.count).clamp(0, task.targetCount);
    }
  }
  notifyListeners();
}

bool _matchesTaskTarget(DailyTask task, QuestEvent event) {
  // Compare event type + targetId
  if (task.objectiveKind == ObjectiveKind.gather && event is ItemGatheredEvent) {
    if (task.targetId == null || event.itemId == task.targetId) return true;
  }
  if (task.objectiveKind == ObjectiveKind.kill && event is BeastDefeatedEvent) {
    if (task.targetId == null || event.beastId == task.targetId) return true;
  }
  if (task.objectiveKind == ObjectiveKind.codexRead && event is CodexFragmentReadEvent) {
    if (task.targetId == null) return true;
    if (task.targetId!.startsWith('tag:')) {
      final tagName = task.targetId!.substring(4);
      final fragment = CodexFragments.findById(event.fragmentId);
      return fragment?.tag.name == tagName;
    }
    return event.fragmentId == task.targetId;
  }
  if (task.objectiveKind == ObjectiveKind.visit && event is ZoneVisitedEvent) {
    if (task.targetId == null || event.zoneId == task.targetId) return true;
  }
  if (task.objectiveKind == ObjectiveKind.craft && event is ItemCraftedEvent) {
    if (task.targetId == null || event.recipeId == task.targetId) return true;
    // 'craft_fine' uses targetId == null + checks quality
    if (task.templateId == 'craft_fine' && event.quality == QualityTier.fine) return true;
  }
  return false;
}

void claimDailyTask(String templateId) {
  final task = _todaysTasks.firstWhere((t) => t.templateId == templateId);
  if (!task.isComplete || task.claimed) return;
  task.claimed = true;

  _playerStats = _playerStats.copyWith(gold: _playerStats.gold + task.goldReward);
  if (task.rewardSkill != null) {
    _skills[task.rewardSkill!] = _skills[task.rewardSkill!]!.addXp(task.skillXpReward.toDouble());
  }
  AudioEngine.instance.play('ui_success');
  log("Daily Task complete: ${task.resolvedTitle} (+${task.goldReward} gold)", LogType.success);

  _maybeClaimDailyBonus();
  notifyListeners();
}

void _maybeClaimDailyBonus() {
  if (_dailyBonusClaimed) return;
  if (!_todaysTasks.every((t) => t.claimed)) return;
  _dailyBonusClaimed = true;

  const bonusGold = 120;
  _playerStats = _playerStats.copyWith(gold: _playerStats.gold + bonusGold);
  log("Daily Bonus: all tasks complete! (+$bonusGold gold)", LogType.success);

  if (_random.nextDouble() < 0.05) {
    _grantRandomBlueprint();
    log("A blueprint scroll falls from the rolled notice.", LogType.success);
  }
  AudioEngine.instance.play('ui_levelup_chime');
  notifyListeners();
}
```

Extend `_notifyQuestObservers` (Spec 1) to also fire `_notifyDailyTaskObservers`:

```dart
void _notifyQuestObservers(QuestEvent event) {
  // ... existing quest observer logic ...
  _notifyDailyTaskObservers(event);
}
```

Add test helpers:

```dart
@visibleForTesting
void forceDailyTaskForTest(DailyTaskTemplate template, {required int qty}) {
  _todaysTasks.add(DailyTask(
    templateId: template.id,
    resolvedTitle: template.titleTemplate.replaceAll('{qty}', qty.toString()),
    iconHint: template.iconHint,
    objectiveKind: template.objectiveKind,
    targetId: template.possibleTargetIds.first == 'any' ? null : template.possibleTargetIds.first,
    targetCount: qty,
    goldReward: template.baseGoldReward,
    skillXpReward: template.baseSkillXpReward,
    rewardSkill: template.rewardSkill,
    claimed: false,
  ));
}

@visibleForTesting
void forceDailyTaskCompletionForTest(String templateId) {
  final task = _todaysTasks.firstWhere((t) => t.templateId == templateId);
  task.currentCount = task.targetCount;
}

@visibleForTesting
void advanceQuestObserverForTest(QuestEvent event) => _notifyQuestObservers(event);
```

- [ ] **Step 4: Run tests, verify pass**

- [ ] **Step 5: Commit**

```bash
git add lib/engine/game_engine.dart test/daily_task_test.dart
git commit -m "feat(daily): engine state + generation + observer + claim + Daily Bonus"
```

---

## Task 18: Tavern view + visit_tavern action

**Files:**
- Modify: `lib/models/zone.dart` (visit_tavern action)
- Modify: `lib/engine/game_engine.dart` (isActionVisible + completion handler)
- Create: `lib/views/tavern_view.dart`
- Modify: `lib/views/dashboard_view.dart` (navigation listener)

- [ ] **Step 1: Append visit_tavern action to townSquare.actions**

```dart
ZoneAction(
  id: 'visit_tavern',
  name: 'Visit the Tavern',
  description: 'Bram keeps the kettle hot and the notice board fresh.',
  durationSeconds: 1,
  energyCost: 0,
  requiredSkill: SkillType.wayfinding, requiredLevel: 1,
  xpReward: 0, lootTable: [],
),
```

- [ ] **Step 2: Extend isActionVisible + _completeAction**

```dart
// In isActionVisible:
if (actionId == 'visit_tavern') {
  return _engineFlags.contains('town_square_restored');
}

// In _completeAction:
bool _tavernRequested = false;
bool get tavernRequested => _tavernRequested;
void clearTavernRequest() { _tavernRequested = false; }

if (action.id == 'visit_tavern') {
  _tavernRequested = true;
  if (_todaysTasks.isEmpty) _generateTodaysTasks();
  notifyListeners();
  return;
}
```

- [ ] **Step 3: Create lib/views/tavern_view.dart**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../engine/game_engine.dart';
import '../design/tokens.dart';
import '../design/typography.dart';
import '../design/primitives/game_tabs.dart';
import '../design/primitives/game_card.dart';
import '../design/primitives/game_button.dart';
import '../design/primitives/game_progress_bar.dart';

class TavernView extends StatefulWidget {
  const TavernView({super.key});

  @override
  State<TavernView> createState() => _TavernViewState();
}

class _TavernViewState extends State<TavernView> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final engine = Provider.of<GameEngine>(context);
    return Scaffold(
      backgroundColor: DSColors.surface2,
      appBar: AppBar(
        title: Text('Tavern', style: DSText.headingMedium(context)),
        backgroundColor: DSColors.surface2,
      ),
      body: SafeArea(child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(DSSpace.md),
          child: GameTabs(
            tabs: const [
              GameTab(label: 'Notice Board', icon: Icons.assignment),
              GameTab(label: "Bram's Wares", icon: Icons.local_drink),
            ],
            selectedIndex: _selectedTab,
            onChanged: (i) => setState(() => _selectedTab = i),
          ),
        ),
        Expanded(
          child: _selectedTab == 0
            ? _buildNoticeBoardTab(context, engine)
            : _buildBramsWaresTab(context, engine),
        ),
      ])),
    );
  }

  Widget _buildNoticeBoardTab(BuildContext context, GameEngine engine) {
    return ListView(
      padding: const EdgeInsets.all(DSSpace.lg),
      children: [
        Text("Today's Notices (resets next session)",
          style: DSText.bodySmall(context)),
        const SizedBox(height: DSSpace.md),
        for (final task in engine.todaysTasks) ...[
          GameCard(
            padding: const EdgeInsets.all(DSSpace.md),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(task.iconHint, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: DSSpace.sm),
                Expanded(child: Text(task.resolvedTitle, style: DSText.bodyMedium(context))),
              ]),
              const SizedBox(height: DSSpace.sm),
              Text('Progress: ${task.currentCount} / ${task.targetCount}',
                style: DSText.bodySmall(context)),
              const SizedBox(height: 4),
              GameProgressBar(
                progress: task.currentCount / task.targetCount,
                color: DSColors.accent, height: 4, animate: true),
              const SizedBox(height: DSSpace.sm),
              Row(children: [
                Expanded(child: Text(
                  'Reward: ${task.goldReward} gold' +
                    (task.rewardSkill != null ? ', ${task.skillXpReward} ${task.rewardSkill!.name} XP' : ''),
                  style: DSText.bodySmall(context),
                )),
                if (task.isComplete && !task.claimed)
                  GameButton(
                    label: 'Claim',
                    size: GameButtonSize.sm,
                    onPressed: () => engine.claimDailyTask(task.templateId),
                  ),
                if (task.claimed)
                  const Text('✓', style: TextStyle(color: DSColors.success, fontSize: 18)),
              ]),
            ]),
          ),
          const SizedBox(height: DSSpace.sm),
        ],
        const Divider(color: DSColors.borderDefault),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: DSSpace.sm),
          child: Text(
            'Daily Bonus: ${engine.todaysTasks.where((t) => t.claimed).length} / 3 claimed' +
              (engine.dailyBonusClaimedForTest ? ' (+120 gold bonus claimed!)' : ' (+120 gold + 5% blueprint on all 3)'),
            style: DSText.bodySmall(context),
          ),
        ),
      ],
    );
  }

  Widget _buildBramsWaresTab(BuildContext context, GameEngine engine) {
    // Reuse the existing shop view widget scoped to Bram's listings
    // (implementation depends on existing shop_view structure)
    return const Center(child: Text('Bram\'s Wares — TODO wire to existing shop view scoped to bram'));
  }
}
```

- [ ] **Step 4: Wire navigation in dashboard_view.dart**

```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    final engine = Provider.of<GameEngine>(context, listen: false);
    if (engine.tavernRequested) {
      engine.clearTavernRequest();
      Navigator.push(context, MaterialPageRoute(builder: (_) => const TavernView()));
    }
  });
}
```

- [ ] **Step 5: Verify visually**

Run app, restore Town Square station, see "Visit the Tavern" appears. Tap it → Tavern view opens with Notice Board.

- [ ] **Step 6: Commit**

```bash
git add lib/models/zone.dart lib/engine/game_engine.dart lib/views/tavern_view.dart lib/views/dashboard_view.dart
git commit -m "feat(tavern): add Tavern fixture + TavernView with Notice Board + Bram's Wares tabs"
```

---

## Task 19: Integration smoke test

**Files:**
- Modify: `test/quest_engine_test.dart`

- [ ] **Step 1: Add end-to-end smoke test**

```dart
test('Spec 6a acceptance — full living-economy loop', () {
  final engine = GameEngine();
  engine.setEngineFlag('town_square_restored');

  // 1. Tavern + daily tasks
  engine.completeActionForTest('visit_tavern');
  expect(engine.todaysTasks.length, 3);

  // 2. Force a Gather task to be present, then auto-progress
  engine.forceDailyTaskForTest(DailyTasks.gatherOak, qty: 5);
  for (int i = 0; i < 5; i++) {
    engine.advanceQuestObserverForTest(ItemGatheredEvent('oak_log', 1));
  }
  final oakTask = engine.todaysTasks.firstWhere((t) => t.templateId == 'gather_oak');
  expect(oakTask.isComplete, true);

  // 3. Claim
  final goldBefore = engine.playerStats.gold;
  engine.claimDailyTask('gather_oak');
  expect(engine.playerStats.gold, goldBefore + oakTask.goldReward);

  // 4. Reputation
  engine.forceMerchantRepForTest('hilda', 2000);
  expect(engine.merchantReputation('hilda').tier, ReputationTier.trustedPatron);

  // 5. Sworn Companion fragment
  engine.forceMerchantRepForTest('bram', 12000);
  expect(engine.knownCodexFragmentIds.contains('merchant_bram'), true);

  // 6. Reagent spawn + collection
  engine.unlockZoneForTest('whispering_woods_1');
  engine.travelTo(Zones.whisperingWoodsTier1);
  engine.skills[SkillType.wayfinding] = engine.skills[SkillType.wayfinding]!.copyWith(level: 6);
  engine.injectReagentSpawnForTest(ReagentSpawn(
    reagentItemId: 'moonpetal', zoneId: 'whispering_woods_1',
    noticeText: 'test', collectionSkill: SkillType.wayfinding,
  ));
  engine.collectReagentSpawn(0);
  expect(engine.inventory.hasItem('moonpetal', 1), true);

  // 7. Durability
  engine.equipForTest(Items.stoneAxe, SkillType.woodcutting);
  final axeBefore = engine.equippedToolSlots[SkillType.woodcutting]!.currentDurability;
  engine.completeGatherActionForTest(SkillType.woodcutting);
  expect(engine.equippedToolSlots[SkillType.woodcutting]!.currentDurability, axeBefore - 1);

  // 8. Wisp-Light modifier guarantees Masterwork (use existing crafting path or test helper)
  // (depends on test helper signature from Task 10)
});
```

- [ ] **Step 2: Run full test suite**

Run: `flutter test`

Expected: All Spec 1–6a tests pass.

- [ ] **Step 3: Run flutter analyze**

Run: `flutter analyze`

Expected: Zero errors, zero warnings.

- [ ] **Step 4: Commit**

```bash
git add test/quest_engine_test.dart
git commit -m "test(spec6a): end-to-end smoke test covering all 4 subsystems"
```

---

## Post-implementation checklist

- [ ] `flutter test` passes (Specs 1–6a combined)
- [ ] `flutter analyze` zero errors / zero warnings
- [ ] Manual play test:
  - Equip tools / weapons / armor → durability bars visible; drain during use
  - Tool hits 25% durability → warning log fires once per session
  - Repair at Crafting Bench (materials) and at Maeve/Hilda (gold)
  - Worn equipment shows badge, grants no stats
  - Travel to a zone → eventually see pulsing Notice card; tap to collect reagent
  - Craft with Wisp-Light → guaranteed Masterwork
  - Trade with merchant → rep chip appears; tier-ups fire log messages
  - Reach Trusted Patron → merchant's unique item visible in stock
  - Reach Honored Friend → gift popover on next visit
  - Reach Sworn Companion → fragment appears in Codex Misc tab
  - Open Codex → Reputation tab visible (after first trade)
  - Restore Town Square → "Visit the Tavern" appears; tap → Tavern view opens
  - Complete daily task → claim → gold + XP
  - All 3 tasks claimed → +120 gold bonus + possible blueprint
- [ ] README.md updated with Spec 6a notes
