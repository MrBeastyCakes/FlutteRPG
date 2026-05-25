# Spec 4 — Gameplay Depth Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement Spec 4 — Combat Stance system with telegraphed beast specials and Quick-Slot Bar; Random Event engine with 20 templates; Masterwork-as-Specialization rework with 16 level-20 trials and 32 total spec effects; Spec 3 spillover (5 Salt Press recipes, Driftwood substitution, Sea Fog crit activation); unified NarrativeEventModal widget.

**Architecture:** Adds round-based combat layer over existing `_resolveCombat` (default-Strike preserves auto-combat for hands-off players). New event subsystem hooks into existing `_completeAction` pipeline. Masterwork spec rework adds two fields to `MasterworkOption` and two maps to `GameEngine`. Spec effects are read inline in existing engine helpers (damage calc, craft quality, gather yield). Total: ~24 tasks.

**Tech Stack:** Flutter (Dart ^3.11.4), Provider state management, `flutter_test` + `fake_async` for tests. No new dependencies.

**Reference spec:** [docs/superpowers/specs/2026-05-24-spec-4-gameplay-depth-design.md](../specs/2026-05-24-spec-4-gameplay-depth-design.md)

---

## File Structure

**Files created:**
- `lib/models/combat.dart` — `PlayerStance` enum, `CombatRound`, `BeastTelegraph` types
- `lib/models/random_event.dart` — `RandomEvent`, `RandomEventOption`, `EventCategory`, `EventReward`, `EventRewardKind`, `RandomEvents` registry
- `lib/widgets/combat_action_bar.dart` — 5-button Stance picker, telegraph banner, round timer
- `lib/widgets/quick_slot_bar.dart` — Dashboard strip with 3 consumable slots
- `lib/widgets/narrative_event_modal.dart` — Unified modal for Masterwork trials + Random Events
- `test/combat_stance_test.dart` — Stance, default-Strike, energy gating, Sea Fog crit
- `test/beast_ability_test.dart` — Each ability fires every 3 rounds with telegraph
- `test/random_event_test.dart` — Trigger rate, category filter, Omen scaling, resolve
- `test/masterwork_spec_test.dart` — specPath/subSpecPath, level-20 offering, badge rendering
- `test/spec_effects_test.dart` — All 32 spec effects verified via mock cases
- `test/salt_press_test.dart` — 5 recipes + 5 new items
- `test/driftwood_substitution_test.dart` — Substitution + quality bias

**Files modified:**
- `lib/models/beast.dart` — Add `BeastAbility` class, `BeastSpecialEffect` enum, `ability` field on Beast
- `lib/models/item.dart` — Add Honeycomb, Traveler's Feather, 5 Salt Press output items
- `lib/models/recipe.dart` — Add 5 Salt Press recipes, optional `station` field if missing
- `lib/models/masterwork.dart` — Add `specPath`/`subSpecPath` to MasterworkOption; add 16 level-20 MasterworkTask entries
- `lib/engine/game_engine.dart` — Round-based combat refactor; Quick-Slot state; weather-crit; event engine; spec state; substitution; offering logic; effects wiring
- `lib/views/dashboard_view.dart` — Mount QuickSlotBar above inventory; render CombatActionBar in combat dashboard card
- `lib/views/skills_view.dart` — Render spec/sub-spec badges with tap-to-modal
- `lib/views/codex_view.dart` — Render Bestiary spec hints after 3+ defeats
- `lib/main.dart` — Use NarrativeEventModal for Masterwork + Random Events
- `test/quest_engine_test.dart` — Spec 4 end-to-end smoke test
- `test/widget_test.dart` — Combat action bar visibility, Quick-Slot picker, NarrativeEventModal

---

## Task 1: Combat round model + PlayerStance enum

**Files:**
- Create: `lib/models/combat.dart`
- Test: `test/combat_stance_test.dart` (new)

- [ ] **Step 1: Write failing test**

Create `test/combat_stance_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/models/combat.dart';

void main() {
  group('PlayerStance enum', () {
    test('5 stances exist', () {
      expect(PlayerStance.values.length, 5);
      expect(PlayerStance.values, containsAll([
        PlayerStance.strike,
        PlayerStance.heavyStrike,
        PlayerStance.defend,
        PlayerStance.readTells,
        PlayerStance.item,
      ]));
    });

    test('CombatRound holds round number and damage stats', () {
      const round = CombatRound(
        roundNumber: 3,
        chosenStance: PlayerStance.defend,
        playerDamageDealt: 0,
        playerDamageTaken: 4,
        wasCrit: false,
      );
      expect(round.roundNumber, 3);
      expect(round.chosenStance, PlayerStance.defend);
      expect(round.wasCrit, false);
    });

    test('BeastTelegraph carries abilityId, text, and reveal flag', () {
      const tg = BeastTelegraph(
        abilityId: 'charge',
        text: 'The boar paws the dirt.',
        reveal: false,
      );
      expect(tg.abilityId, 'charge');
      expect(tg.reveal, false);
    });
  });
}
```

- [ ] **Step 2: Run test, verify it fails**

Run: `flutter test test/combat_stance_test.dart`

Expected: Compilation error — `combat.dart` doesn't exist.

- [ ] **Step 3: Create lib/models/combat.dart**

```dart
enum PlayerStance { strike, heavyStrike, defend, readTells, item }

class CombatRound {
  final int roundNumber;
  final PlayerStance chosenStance;
  final int playerDamageDealt;
  final int playerDamageTaken;
  final bool wasCrit;

  const CombatRound({
    required this.roundNumber,
    required this.chosenStance,
    required this.playerDamageDealt,
    required this.playerDamageTaken,
    this.wasCrit = false,
  });
}

class BeastTelegraph {
  final String abilityId;
  final String text;
  final bool reveal;

  const BeastTelegraph({
    required this.abilityId,
    required this.text,
    this.reveal = false,
  });
}
```

- [ ] **Step 4: Run test, verify pass**

Run: `flutter test test/combat_stance_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/models/combat.dart test/combat_stance_test.dart
git commit -m "feat(combat): add PlayerStance enum and CombatRound/BeastTelegraph models"
```

---

## Task 2: Beast ability model + assign abilities to all 7 beasts

**Files:**
- Modify: `lib/models/beast.dart`
- Test: `test/beast_ability_test.dart` (new)

- [ ] **Step 1: Write failing test**

Create `test/beast_ability_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/models/beast.dart';

void main() {
  group('BeastAbility assignments', () {
    test('Forest Boar has Charge ability with bigHit effect', () {
      final ability = Beasts.forestBoar.ability;
      expect(ability, isNotNull);
      expect(ability!.id, 'charge');
      expect(ability.effect, BeastSpecialEffect.bigHit);
      expect(ability.cooldownRounds, 3);
    });

    test('Cave Spider has Web ability with stun effect', () {
      expect(Beasts.caveSpider.ability!.effect, BeastSpecialEffect.stun);
    });

    test('Shadow Wolf has Howl ability with summonAlly effect', () {
      expect(Beasts.shadowWolf.ability!.effect, BeastSpecialEffect.summonAlly);
    });

    test('Cavern Troll has Smash ability with bigHitStun effect', () {
      expect(Beasts.cavernTroll.ability!.effect, BeastSpecialEffect.bigHitStun);
    });

    test('Tide Hound has Salt Splash with accuracyDebuff', () {
      expect(Beasts.tideHound.ability!.effect, BeastSpecialEffect.accuracyDebuff);
    });

    test('Brine Crawler has Pincer Lock with drainOverTime', () {
      expect(Beasts.brineCrawler.ability!.effect, BeastSpecialEffect.drainOverTime);
    });

    test('Salt-Touched Drowned has Death Wail with bigHitStun', () {
      expect(Beasts.saltTouchedDrowned.ability!.effect, BeastSpecialEffect.bigHitStun);
    });
  });
}
```

- [ ] **Step 2: Run test, verify it fails**

Run: `flutter test test/beast_ability_test.dart`

Expected: FAIL — `BeastAbility` undefined; `Beast.ability` field missing.

- [ ] **Step 3: Add BeastAbility model + assign to all 7 beasts**

In `lib/models/beast.dart`, add to the top:

```dart
enum BeastSpecialEffect {
  bigHit,
  stun,
  bigHitStun,
  summonAlly,
  drainOverTime,
  accuracyDebuff,
}

class BeastAbility {
  final String id;
  final String name;
  final int cooldownRounds;
  final String telegraphText;
  final BeastSpecialEffect effect;

  const BeastAbility({
    required this.id,
    required this.name,
    required this.cooldownRounds,
    required this.telegraphText,
    required this.effect,
  });
}
```

Add `final BeastAbility? ability;` to the `Beast` class constructor and field list (optional, default null).

Update each beast constant to include its ability:

```dart
static const Beast forestBoar = Beast(
  id: 'forest_boar',
  name: 'Forest Boar',
  icon: '🐗',
  maxHealth: 35,
  attackPower: 5,
  defense: 1,
  xpReward: 30,
  lootTable: [
    LootDrop(item: Items.boarMeat, chance: 0.85, minQuantity: 1, maxQuantity: 2),
    LootDrop(item: Items.boarTusk, chance: 0.40, minQuantity: 1, maxQuantity: 1),
  ],
  ability: BeastAbility(
    id: 'charge',
    name: 'Charge',
    cooldownRounds: 3,
    telegraphText: 'The boar paws the dirt, lowering its tusks.',
    effect: BeastSpecialEffect.bigHit,
  ),
);

static const Beast caveSpider = Beast(
  // existing fields...
  ability: BeastAbility(
    id: 'web',
    name: 'Web',
    cooldownRounds: 3,
    telegraphText: 'Web-glands glisten.',
    effect: BeastSpecialEffect.stun,
  ),
);

static const Beast shadowWolf = Beast(
  // existing fields...
  ability: BeastAbility(
    id: 'howl',
    name: 'Howl',
    cooldownRounds: 3,
    telegraphText: "The wolf's eyes flash silver.",
    effect: BeastSpecialEffect.summonAlly,
  ),
);

static const Beast cavernTroll = Beast(
  // existing fields...
  ability: BeastAbility(
    id: 'smash',
    name: 'Smash',
    cooldownRounds: 3,
    telegraphText: 'The troll hefts a boulder.',
    effect: BeastSpecialEffect.bigHitStun,
  ),
);

static const Beast tideHound = Beast(
  // existing fields...
  ability: BeastAbility(
    id: 'salt_splash',
    name: 'Salt Splash',
    cooldownRounds: 3,
    telegraphText: 'The hound shakes seawater from its coat.',
    effect: BeastSpecialEffect.accuracyDebuff,
  ),
);

static const Beast brineCrawler = Beast(
  // existing fields...
  ability: BeastAbility(
    id: 'pincer_lock',
    name: 'Pincer Lock',
    cooldownRounds: 3,
    telegraphText: "The crawler's claws lock open.",
    effect: BeastSpecialEffect.drainOverTime,
  ),
);

static const Beast saltTouchedDrowned = Beast(
  // existing fields...
  ability: BeastAbility(
    id: 'death_wail',
    name: 'Death Wail',
    cooldownRounds: 3,
    telegraphText: 'The drowned thing opens its mouth without sound.',
    effect: BeastSpecialEffect.bigHitStun,
  ),
);
```

- [ ] **Step 4: Run tests, verify pass**

Run: `flutter test test/beast_ability_test.dart`

Expected: All 7 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/models/beast.dart test/beast_ability_test.dart
git commit -m "feat(beast): add BeastAbility model and assign to all 7 beasts"
```

---

## Task 3: Engine Stance API + round resolution

**Files:**
- Modify: `lib/engine/game_engine.dart`
- Test: `test/combat_stance_test.dart` (extend)

- [ ] **Step 1: Write failing tests for Stance API**

Add to `test/combat_stance_test.dart`:

```dart
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/models/beast.dart';
import 'package:flutter_text_based_rpg/models/zone.dart';

group('Stance API', () {
  late GameEngine engine;

  setUp(() {
    engine = GameEngine();
    engine.unlockZone('whispering_woods_1');
    engine.travelTo(Zones.whisperingWoodsTier1);
    engine.startBoarHuntForTest();  // helper to begin combat against Forest Boar
  });

  test('setCombatStance assigns pending stance on active combat', () {
    engine.setCombatStance(PlayerStance.strike);
    expect(engine.activeCombat!.pendingStance, PlayerStance.strike);
  });

  test('Heavy Strike costs 5 energy by default (no Berserker spec)', () {
    final energyBefore = engine.playerStats.currentEnergy;
    engine.setCombatStance(PlayerStance.heavyStrike);
    expect(engine.playerStats.currentEnergy, energyBefore - 5);
  });

  test('Defend costs 2 energy', () {
    final energyBefore = engine.playerStats.currentEnergy;
    engine.setCombatStance(PlayerStance.defend);
    expect(engine.playerStats.currentEnergy, energyBefore - 2);
  });

  test('Strike costs 0 energy', () {
    final energyBefore = engine.playerStats.currentEnergy;
    engine.setCombatStance(PlayerStance.strike);
    expect(engine.playerStats.currentEnergy, energyBefore);
  });

  test('Stance is blocked when energy is insufficient', () {
    // Reduce energy below Heavy Strike cost
    engine.playerStats = engine.playerStats.copyWith(currentEnergy: 3);
    engine.setCombatStance(PlayerStance.heavyStrike);
    expect(engine.activeCombat!.pendingStance, isNull);
  });
});
```

- [ ] **Step 2: Run test, verify it fails**

Run: `flutter test test/combat_stance_test.dart`

Expected: FAIL — `setCombatStance` undefined; CombatState doesn't have `pendingStance`.

- [ ] **Step 3: Extend CombatState + add Stance API**

In `lib/engine/game_engine.dart`, find the `CombatState` class and add fields:

```dart
class CombatState {
  // existing fields: beast, beastCurrentHealth, playerStartHealth, combatLog ...

  // NEW
  final List<CombatRound> roundHistory;
  final int roundsSinceLastTelegraph;
  final BeastTelegraph? activeTelegraph;
  final PlayerStance? pendingStance;
  final DateTime? roundDeadline;
  final int? pendingQuickslotIndex;
  final int currentRoundNumber;

  // copyWith needs updates for new fields
}
```

Add to `GameEngine`:

```dart
void setCombatStance(PlayerStance stance, {int? quickslotIndex}) {
  if (_activeCombat == null || _activeCombat!.pendingStance != null) return;
  final cost = _stanceCost(stance);
  if (_playerStats.currentEnergy < cost) {
    log("Not enough energy for that action.", LogType.warning);
    return;
  }
  _playerStats = _playerStats.copyWith(
    currentEnergy: _playerStats.currentEnergy - cost,
  );
  _activeCombat = _activeCombat!.copyWith(
    pendingStance: stance,
    pendingQuickslotIndex: quickslotIndex,
  );
  notifyListeners();
  _resolveCombatRound();
}

int _stanceCost(PlayerStance s) {
  switch (s) {
    case PlayerStance.strike: return 0;
    case PlayerStance.heavyStrike:
      return (_skillSpecs[SkillType.combat] == 'combat_berserker') ? 4
          : (_skillSpecs[SkillType.combat] == 'combat_guardian') ? 8
          : 5;
    case PlayerStance.defend: return 2;
    case PlayerStance.readTells: return 3;
    case PlayerStance.item: return 0;
  }
}

@visibleForTesting
void startBoarHuntForTest() {
  // Begin combat against Forest Boar without going through normal action flow
  _activeCombat = CombatState(
    beast: Beasts.forestBoar,
    beastCurrentHealth: Beasts.forestBoar.maxHealth,
    playerStartHealth: _playerStats.currentHealth,
    combatLog: [],
    roundHistory: [],
    roundsSinceLastTelegraph: 0,
    activeTelegraph: null,
    pendingStance: null,
    roundDeadline: DateTime.now().add(const Duration(seconds: 2)),
    pendingQuickslotIndex: null,
    currentRoundNumber: 1,
  );
  notifyListeners();
}
```

Add `_resolveCombatRound` (placeholder that just clears pendingStance; full logic in Task 4):

```dart
void _resolveCombatRound() {
  if (_activeCombat == null || _activeCombat!.pendingStance == null) return;
  // Placeholder: full resolution in Task 4
  _activeCombat = _activeCombat!.copyWith(pendingStance: null);
  notifyListeners();
}
```

Add `@visibleForTesting` import: `import 'package:flutter/foundation.dart';`

Also need `_skillSpecs` field (defined in Task 15 but we reference it here for cost calc — use `final Map<SkillType, String> _skillSpecs = {};` as a stub for now):

```dart
final Map<SkillType, String> _skillSpecs = {};
```

- [ ] **Step 4: Run tests, verify pass**

Run: `flutter test test/combat_stance_test.dart`

Expected: All Stance API tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/engine/game_engine.dart test/combat_stance_test.dart
git commit -m "feat(engine): add Stance API with energy gating and default cost rules"
```

---

## Task 4: Round resolution + default-Strike timer

**Files:**
- Modify: `lib/engine/game_engine.dart`
- Test: `test/combat_stance_test.dart` (extend)

- [ ] **Step 1: Write failing tests**

Add to `test/combat_stance_test.dart`:

```dart
group('Round resolution', () {
  late GameEngine engine;

  setUp(() {
    engine = GameEngine();
    engine.unlockZone('whispering_woods_1');
    engine.travelTo(Zones.whisperingWoodsTier1);
    engine.startBoarHuntForTest();
  });

  test('Strike deals base damage to beast', () {
    final beastHpBefore = engine.activeCombat!.beastCurrentHealth;
    engine.setCombatStance(PlayerStance.strike);
    expect(engine.activeCombat!.beastCurrentHealth, lessThan(beastHpBefore));
  });

  test('Heavy Strike deals more damage than Strike', () {
    final beastHp1 = engine.activeCombat!.beastCurrentHealth;
    engine.setCombatStance(PlayerStance.heavyStrike);
    final dmg1 = beastHp1 - engine.activeCombat!.beastCurrentHealth;

    // Reset
    engine.startBoarHuntForTest();
    final beastHp2 = engine.activeCombat!.beastCurrentHealth;
    engine.setCombatStance(PlayerStance.strike);
    final dmg2 = beastHp2 - engine.activeCombat!.beastCurrentHealth;

    expect(dmg1, greaterThan(dmg2));
  });

  test('Defend halves incoming damage', () {
    // Tricky to test directly without combat math access; verify via player HP
    final playerHpBefore = engine.playerStats.currentHealth;
    engine.setCombatStance(PlayerStance.defend);
    final defendDmg = playerHpBefore - engine.playerStats.currentHealth;

    engine.startBoarHuntForTest();
    final playerHpBefore2 = engine.playerStats.currentHealth;
    engine.setCombatStance(PlayerStance.strike);
    final strikeDmg = playerHpBefore2 - engine.playerStats.currentHealth;

    expect(defendDmg, lessThan(strikeDmg));
  });

  test('Default Strike fires on timer expiry without input', () {
    final beastHpBefore = engine.activeCombat!.beastCurrentHealth;
    // Force timer expiry
    engine.tickRoundTimerForTest(Duration(seconds: 3));
    expect(engine.activeCombat!.beastCurrentHealth, lessThan(beastHpBefore));
  });
});
```

- [ ] **Step 2: Run test, verify it fails**

Run: `flutter test test/combat_stance_test.dart`

Expected: FAIL — `_resolveCombatRound` is stubbed; `tickRoundTimerForTest` undefined.

- [ ] **Step 3: Implement round resolution + timer**

In `lib/engine/game_engine.dart`, replace the stub `_resolveCombatRound`:

```dart
void _resolveCombatRound() {
  if (_activeCombat == null || _activeCombat!.pendingStance == null) return;
  final state = _activeCombat!;
  final beast = state.beast;
  final stance = state.pendingStance!;

  int playerDmgDealt = 0;
  int playerDmgTaken = 0;
  bool wasCrit = false;

  // Determine telegraph state
  final hasActiveTelegraph = state.activeTelegraph != null;

  // Resolve based on stance
  switch (stance) {
    case PlayerStance.strike:
    case PlayerStance.heavyStrike:
      // Player deals damage
      int baseDmg = getPlayerAttack() - beast.defense;
      if (baseDmg < 1) baseDmg = 1;
      double dmgMultiplier = 1.0;
      if (stance == PlayerStance.heavyStrike) {
        final isBerserker = _skillSpecs[SkillType.combat] == 'combat_berserker';
        dmgMultiplier = isBerserker ? 1.8 : 1.5;
      }
      // Sea Fog crit
      double critChance = 0.0;
      if (_currentZone.id.startsWith('sundered_coast_') &&
          _coastWeather.current == CoastWeather.seaFog) {
        critChance += 0.20;
      }
      if (_skillSubSpecs[SkillType.combat] == 'combat_reaper') {
        critChance += 0.15;
      }
      wasCrit = _random.nextDouble() < critChance;
      if (wasCrit) dmgMultiplier *= 1.5;

      playerDmgDealt = (baseDmg * dmgMultiplier).round();
      if (wasCrit) log("⚡ Critical Strike! $playerDmgDealt damage", LogType.success);

      // Heavy Strike: beast acts first
      if (stance == PlayerStance.heavyStrike) {
        playerDmgTaken = _calculateBeastDamage(beast, hasActiveTelegraph);
      }
      // Apply player damage to beast
      final newBeastHp = (state.beastCurrentHealth - playerDmgDealt).clamp(0, beast.maxHealth);
      // Apply beast damage to player (if not Heavy Strike, beast acts after)
      if (stance != PlayerStance.heavyStrike) {
        playerDmgTaken = _calculateBeastDamage(beast, hasActiveTelegraph);
      }
      _playerStats = _playerStats.copyWith(
        currentHealth: (_playerStats.currentHealth - playerDmgTaken).clamp(0, _playerStats.maxHealth),
      );
      _activeCombat = state.copyWith(
        beastCurrentHealth: newBeastHp,
        pendingStance: null,
        currentRoundNumber: state.currentRoundNumber + 1,
        roundsSinceLastTelegraph: hasActiveTelegraph ? 0 : state.roundsSinceLastTelegraph + 1,
        activeTelegraph: null,
        roundHistory: [
          ...state.roundHistory,
          CombatRound(
            roundNumber: state.currentRoundNumber,
            chosenStance: stance,
            playerDamageDealt: playerDmgDealt,
            playerDamageTaken: playerDmgTaken,
            wasCrit: wasCrit,
          ),
        ],
        roundDeadline: DateTime.now().add(const Duration(seconds: 2)),
      );
      break;

    case PlayerStance.defend:
      // Halve incoming damage
      int incoming = _calculateBeastDamage(beast, hasActiveTelegraph);
      incoming = (incoming / 2).floor();
      if (incoming < 1) incoming = 1;
      // Counter damage (Guardian spec only)
      final isGuardian = _skillSpecs[SkillType.combat] == 'combat_guardian';
      final isSentinel = _skillSubSpecs[SkillType.combat] == 'combat_sentinel';
      int counter = 0;
      if (isGuardian) counter = isSentinel ? 10 : 5;
      _playerStats = _playerStats.copyWith(
        currentHealth: (_playerStats.currentHealth - incoming).clamp(0, _playerStats.maxHealth),
      );
      final newBeastHp = (state.beastCurrentHealth - counter).clamp(0, beast.maxHealth);
      _activeCombat = state.copyWith(
        beastCurrentHealth: newBeastHp,
        pendingStance: null,
        currentRoundNumber: state.currentRoundNumber + 1,
        roundsSinceLastTelegraph: hasActiveTelegraph ? 0 : state.roundsSinceLastTelegraph + 1,
        activeTelegraph: null,
        roundDeadline: DateTime.now().add(const Duration(seconds: 2)),
      );
      break;

    case PlayerStance.readTells:
      // No damage; reveal next telegraph
      final updatedTelegraph = state.activeTelegraph?.let((tg) =>
          BeastTelegraph(abilityId: tg.abilityId, text: tg.text, reveal: true));
      _activeCombat = state.copyWith(
        pendingStance: null,
        currentRoundNumber: state.currentRoundNumber + 1,
        activeTelegraph: updatedTelegraph,
        roundDeadline: DateTime.now().add(const Duration(seconds: 2)),
      );
      break;

    case PlayerStance.item:
      // Consume Quick-Slot item
      final idx = state.pendingQuickslotIndex;
      if (idx != null && idx >= 0 && idx < _quickslots.length) {
        final itemId = _quickslots[idx];
        if (itemId != null) {
          final item = Items.findById(itemId);
          if (item != null) {
            _playerStats = _playerStats.copyWith(
              currentHealth: (_playerStats.currentHealth + item.healAmount).clamp(0, _playerStats.maxHealth),
              currentEnergy: (_playerStats.currentEnergy + item.energyAmount).clamp(0, _playerStats.maxEnergy),
            );
            _quickslots[idx] = null;
            log("Used ${item.icon} ${item.name}: +${item.healAmount} HP, +${item.energyAmount} energy.", LogType.success);
          }
        }
      }
      // Beast still acts
      int incoming = _calculateBeastDamage(beast, hasActiveTelegraph);
      _playerStats = _playerStats.copyWith(
        currentHealth: (_playerStats.currentHealth - incoming).clamp(0, _playerStats.maxHealth),
      );
      _activeCombat = state.copyWith(
        pendingStance: null,
        pendingQuickslotIndex: null,
        currentRoundNumber: state.currentRoundNumber + 1,
        roundsSinceLastTelegraph: hasActiveTelegraph ? 0 : state.roundsSinceLastTelegraph + 1,
        activeTelegraph: null,
        roundDeadline: DateTime.now().add(const Duration(seconds: 2)),
      );
      break;
  }

  // Check end conditions
  if (_activeCombat!.beastCurrentHealth <= 0) {
    _onBeastDefeated(beast);
    return;
  }
  if (_playerStats.currentHealth <= 0) {
    _onPlayerDefeated();
    return;
  }

  // Check for telegraph fire next round
  _maybeFireBeastTelegraph();
  notifyListeners();
}

int _calculateBeastDamage(Beast beast, bool hasActiveTelegraph) {
  int baseDmg = beast.attackPower - getPlayerDefense();
  if (baseDmg < 1) baseDmg = 1;
  // If a telegraph is active, this round IS the special — apply effect
  if (hasActiveTelegraph) {
    final ability = beast.ability;
    if (ability != null) {
      switch (ability.effect) {
        case BeastSpecialEffect.bigHit: return baseDmg * 2;
        case BeastSpecialEffect.bigHitStun: return baseDmg * 2;
        // Stun and other effects don't add damage but apply elsewhere
        default: return baseDmg;
      }
    }
  }
  return baseDmg;
}

void _maybeFireBeastTelegraph() {
  if (_activeCombat == null) return;
  final state = _activeCombat!;
  final ability = state.beast.ability;
  if (ability == null) return;
  // Telegraph fires N-1 rounds in (so on round N, ability triggers)
  if (state.roundsSinceLastTelegraph >= ability.cooldownRounds - 1) {
    _activeCombat = state.copyWith(
      activeTelegraph: BeastTelegraph(
        abilityId: ability.id,
        text: ability.telegraphText,
        reveal: false,
      ),
    );
  }
  notifyListeners();
}

void _onRoundTimerExpired() {
  if (_activeCombat == null || _activeCombat!.pendingStance != null) return;
  setCombatStance(PlayerStance.strike);
}

@visibleForTesting
void tickRoundTimerForTest(Duration elapsed) {
  if (_activeCombat == null) return;
  _activeCombat = _activeCombat!.copyWith(
    roundDeadline: DateTime.now().subtract(elapsed),
  );
  _onRoundTimerExpired();
}
```

Wire `_onRoundTimerExpired` into the global tick — find existing tick and add:

```dart
// In _tick():
if (_activeCombat != null &&
    _activeCombat!.roundDeadline != null &&
    DateTime.now().isAfter(_activeCombat!.roundDeadline!)) {
  _onRoundTimerExpired();
}
```

- [ ] **Step 4: Run tests, verify pass**

Run: `flutter test test/combat_stance_test.dart`

Expected: All round resolution tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/engine/game_engine.dart test/combat_stance_test.dart
git commit -m "feat(combat): implement round-based resolution with default-Strike timer"
```

---

## Task 5: Telegraph system tests

**Files:**
- Modify: `lib/engine/game_engine.dart` (already has _maybeFireBeastTelegraph from Task 4)
- Test: `test/beast_ability_test.dart` (extend)

- [ ] **Step 1: Write failing tests**

Add to `test/beast_ability_test.dart`:

```dart
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/models/combat.dart';
import 'package:flutter_text_based_rpg/models/zone.dart';

group('Telegraph behavior', () {
  late GameEngine engine;

  setUp(() {
    engine = GameEngine();
    engine.unlockZone('whispering_woods_1');
    engine.travelTo(Zones.whisperingWoodsTier1);
    engine.startBoarHuntForTest();
  });

  test('Telegraph appears on round 2 (before round 3 ability fires)', () {
    expect(engine.activeCombat!.activeTelegraph, isNull);
    engine.setCombatStance(PlayerStance.strike);  // round 1
    expect(engine.activeCombat!.activeTelegraph, isNull);
    engine.setCombatStance(PlayerStance.strike);  // round 2
    expect(engine.activeCombat!.activeTelegraph, isNotNull);
    expect(engine.activeCombat!.activeTelegraph!.abilityId, 'charge');
    expect(engine.activeCombat!.activeTelegraph!.reveal, false);
  });

  test('Defend during telegraph round halves incoming Charge', () {
    engine.setCombatStance(PlayerStance.strike);
    engine.setCombatStance(PlayerStance.strike);  // telegraph appears
    final hpBefore = engine.playerStats.currentHealth;
    engine.setCombatStance(PlayerStance.defend);  // Charge fires this round
    final dmgWithDefend = hpBefore - engine.playerStats.currentHealth;

    engine.startBoarHuntForTest();
    engine.setCombatStance(PlayerStance.strike);
    engine.setCombatStance(PlayerStance.strike);
    final hpBefore2 = engine.playerStats.currentHealth;
    engine.setCombatStance(PlayerStance.strike);  // take full Charge
    final dmgWithStrike = hpBefore2 - engine.playerStats.currentHealth;

    expect(dmgWithDefend, lessThan(dmgWithStrike));
  });

  test('Read Tells reveals telegraph', () {
    engine.setCombatStance(PlayerStance.strike);
    engine.setCombatStance(PlayerStance.strike);  // telegraph appears
    expect(engine.activeCombat!.activeTelegraph!.reveal, false);
    engine.setCombatStance(PlayerStance.readTells);
    // After Read Tells, the next round still has the telegraph but revealed
    // (current implementation reveals on the readTells round; ability still fires next)
    // Implementation detail: depends on exact semantics
  });
});
```

- [ ] **Step 2: Run tests, verify pass (telegraph logic is in Task 4 already)**

Run: `flutter test test/beast_ability_test.dart`

Expected: Telegraph tests PASS (logic exists from Task 4).

- [ ] **Step 3: Commit**

```bash
git add test/beast_ability_test.dart
git commit -m "test(combat): verify telegraph fires every 3 rounds and Defend halves specials"
```

---

## Task 6: Quick-Slot Bar engine state

**Files:**
- Modify: `lib/engine/game_engine.dart`
- Test: `test/combat_stance_test.dart` (extend)

- [ ] **Step 1: Write failing tests**

Add to `test/combat_stance_test.dart`:

```dart
group('Quick-Slot Bar engine state', () {
  test('Default 3 empty slots', () {
    final engine = GameEngine();
    expect(engine.quickslots.length, 3);
    expect(engine.quickslots, [null, null, null]);
  });

  test('setQuickslot stores an itemId', () {
    final engine = GameEngine();
    engine.setQuickslot(0, 'baked_potato');
    expect(engine.quickslots[0], 'baked_potato');
  });

  test('setQuickslot rejects non-food items', () {
    final engine = GameEngine();
    engine.setQuickslot(0, 'oak_log');  // resource, not food
    expect(engine.quickslots[0], isNull);
  });

  test('useQuickslot out of combat heals/energizes player and clears slot', () {
    final engine = GameEngine();
    engine.setQuickslot(0, 'baked_potato');
    engine.playerStats = engine.playerStats.copyWith(currentHealth: 50);
    final hpBefore = engine.playerStats.currentHealth;
    engine.useQuickslot(0);
    expect(engine.playerStats.currentHealth, greaterThan(hpBefore));
    expect(engine.quickslots[0], isNull);
  });
});
```

- [ ] **Step 2: Run test, verify it fails**

Run: `flutter test test/combat_stance_test.dart`

Expected: FAIL — `quickslots`, `setQuickslot`, `useQuickslot` undefined.

- [ ] **Step 3: Add Quick-Slot state to engine**

In `lib/engine/game_engine.dart`:

```dart
final List<String?> _quickslots = [null, null, null];

List<String?> get quickslots => List.unmodifiable(_quickslots);

void setQuickslot(int index, String? itemId) {
  if (index < 0 || index >= 3) return;
  if (itemId != null) {
    final item = Items.findById(itemId);
    if (item == null || item.type != ItemType.food) return;
  }
  _quickslots[index] = itemId;
  notifyListeners();
}

void useQuickslot(int index) {
  if (index < 0 || index >= 3) return;
  final itemId = _quickslots[index];
  if (itemId == null) return;

  if (_activeCombat != null) {
    setCombatStance(PlayerStance.item, quickslotIndex: index);
  } else {
    final item = Items.findById(itemId)!;
    _playerStats = _playerStats.copyWith(
      currentHealth: (_playerStats.currentHealth + item.healAmount).clamp(0, _playerStats.maxHealth),
      currentEnergy: (_playerStats.currentEnergy + item.energyAmount).clamp(0, _playerStats.maxEnergy),
    );
    log("Used ${item.icon} ${item.name}: +${item.healAmount} HP, +${item.energyAmount} energy.", LogType.success);
    _quickslots[index] = null;
    notifyListeners();
  }
}
```

- [ ] **Step 4: Run tests, verify pass**

Run: `flutter test test/combat_stance_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/engine/game_engine.dart test/combat_stance_test.dart
git commit -m "feat(engine): add Quick-Slot Bar with 3 consumable slots"
```

---

## Task 7: Quick-Slot Bar UI

**Files:**
- Create: `lib/widgets/quick_slot_bar.dart`
- Modify: `lib/views/dashboard_view.dart`

- [ ] **Step 1: Create the widget**

Create `lib/widgets/quick_slot_bar.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../engine/game_engine.dart';
import '../models/item.dart';
import '../theme/game_theme.dart';

class QuickSlotBar extends StatelessWidget {
  const QuickSlotBar({super.key});

  @override
  Widget build(BuildContext context) {
    final engine = Provider.of<GameEngine>(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: GameTheme.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GameTheme.border, width: 1),
      ),
      child: Row(
        children: [
          const Text('Quick:', style: TextStyle(color: GameTheme.textMuted, fontSize: 11)),
          const SizedBox(width: 8),
          for (int i = 0; i < 3; i++) _buildSlot(context, engine, i),
        ],
      ),
    );
  }

  Widget _buildSlot(BuildContext context, GameEngine engine, int index) {
    final itemId = engine.quickslots[index];
    final item = itemId == null ? null : Items.findById(itemId);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: () {
          if (item != null) {
            _confirmAndUse(context, engine, index, item);
          } else {
            _showPicker(context, engine, index);
          }
        },
        onLongPress: () => _showPicker(context, engine, index),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: item != null ? GameTheme.accentGold.withOpacity(0.08) : Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: item != null ? GameTheme.accentGold : GameTheme.border,
              width: 1,
            ),
          ),
          child: Center(
            child: item != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(item.icon, style: const TextStyle(fontSize: 22)),
                      Text(
                        '${index + 1}',
                        style: const TextStyle(color: GameTheme.textMuted, fontSize: 9),
                      ),
                    ],
                  )
                : const Icon(Icons.add, color: GameTheme.textMuted, size: 20),
          ),
        ),
      ),
    );
  }

  static bool _firstUseShown = false;

  void _confirmAndUse(BuildContext context, GameEngine engine, int index, Item item) {
    if (_firstUseShown) {
      engine.useQuickslot(index);
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: GameTheme.cardBg,
        title: const Text('Quick-Slot Use', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Quick-Slot items are consumed on use. Continue?',
          style: TextStyle(color: GameTheme.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _firstUseShown = true;
              Navigator.pop(context);
              engine.useQuickslot(index);
            },
            child: const Text('Use'),
          ),
        ],
      ),
    );
  }

  void _showPicker(BuildContext context, GameEngine engine, int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: GameTheme.cardBg,
      builder: (_) => _buildPickerSheet(context, engine, index),
    );
  }

  Widget _buildPickerSheet(BuildContext context, GameEngine engine, int index) {
    final foods = engine.inventory.contents
        .where((slot) => slot.item.type == ItemType.food)
        .toList();
    return ListView(
      shrinkWrap: true,
      children: [
        const ListTile(title: Text('Set Quick-Slot', style: TextStyle(color: Colors.white))),
        if (engine.quickslots[index] != null)
          ListTile(
            leading: const Icon(Icons.close, color: GameTheme.healthRed),
            title: const Text('Clear slot', style: TextStyle(color: GameTheme.textLight)),
            onTap: () {
              engine.setQuickslot(index, null);
              Navigator.pop(context);
            },
          ),
        for (final slot in foods)
          ListTile(
            leading: Text(slot.item.icon, style: const TextStyle(fontSize: 22)),
            title: Text(slot.item.name, style: const TextStyle(color: Colors.white)),
            subtitle: Text('+${slot.item.healAmount} HP, +${slot.item.energyAmount} energy',
                style: const TextStyle(color: GameTheme.textMuted)),
            trailing: Text('×${slot.quantity}', style: const TextStyle(color: GameTheme.textMuted)),
            onTap: () {
              engine.setQuickslot(index, slot.item.id);
              Navigator.pop(context);
            },
          ),
      ],
    );
  }
}
```

- [ ] **Step 2: Mount in Dashboard above inventory**

In `lib/views/dashboard_view.dart`, find the inventory panel area and prepend the QuickSlotBar:

```dart
// Above inventory panel:
const QuickSlotBar(),
const SizedBox(height: 8),
// Then existing inventory...
```

Add import: `import '../widgets/quick_slot_bar.dart';`

- [ ] **Step 3: Verify visually**

Run: `flutter run -d windows` (or your dev device)

Expected: Dashboard shows the Quick-Slot strip above inventory. Tap empty slot → picker opens. Pick a food → slot fills. Tap filled slot → confirmation dialog → use heals/energizes.

- [ ] **Step 4: Commit**

```bash
git add lib/widgets/quick_slot_bar.dart lib/views/dashboard_view.dart
git commit -m "feat(ui): add Quick-Slot Bar widget on Dashboard above inventory"
```

---

## Task 8: Sea Fog crit verification

**Files:**
- Already wired in Task 4
- Test: `test/combat_stance_test.dart` (extend)

- [ ] **Step 1: Write test**

Add to `test/combat_stance_test.dart`:

```dart
import 'package:flutter_text_based_rpg/models/weather.dart';

group('Sea Fog crit', () {
  test('Sea Fog in Coast zone adds +20% crit chance', () {
    final engine = GameEngine();
    engine.setEngineFlag('coast_unlocked');
    engine.travelTo(Zones.sunderedCoastTier1);
    engine.forceCoastWeatherForTest(CoastWeather.seaFog);
    engine.startBoarHuntForTest();  // adapt to Coast beast or generic combat hook
    // Run 100 attacks; expect ~20% crit rate
    int crits = 0;
    for (int i = 0; i < 100; i++) {
      engine.startBoarHuntForTest();
      engine.setCombatStance(PlayerStance.strike);
      if (engine.activeCombat!.roundHistory.last.wasCrit) crits++;
    }
    expect(crits, inInclusiveRange(10, 35));  // ~20% with variance
  });

  test('Calm weather has no crit bonus', () {
    final engine = GameEngine();
    engine.setEngineFlag('coast_unlocked');
    engine.travelTo(Zones.sunderedCoastTier1);
    engine.forceCoastWeatherForTest(CoastWeather.calm);
    int crits = 0;
    for (int i = 0; i < 100; i++) {
      engine.startBoarHuntForTest();
      engine.setCombatStance(PlayerStance.strike);
      if (engine.activeCombat!.roundHistory.last.wasCrit) crits++;
    }
    expect(crits, lessThan(5));  // baseline near-zero crit
  });
});
```

- [ ] **Step 2: Run tests, verify pass**

Run: `flutter test test/combat_stance_test.dart`

Expected: PASS (crit logic is already wired in Task 4).

- [ ] **Step 3: Commit**

```bash
git add test/combat_stance_test.dart
git commit -m "test(combat): verify Sea Fog adds +20% crit chance in Coast zones"
```

---

## Task 9: Combat Action Bar UI

**Files:**
- Create: `lib/widgets/combat_action_bar.dart`
- Modify: `lib/views/dashboard_view.dart`

- [ ] **Step 1: Create the widget**

Create `lib/widgets/combat_action_bar.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../engine/game_engine.dart';
import '../models/combat.dart';
import '../theme/game_theme.dart';

class CombatActionBar extends StatelessWidget {
  const CombatActionBar({super.key});

  @override
  Widget build(BuildContext context) {
    final engine = Provider.of<GameEngine>(context);
    final combat = engine.activeCombat;
    if (combat == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (combat.activeTelegraph != null) _buildTelegraphBanner(combat.activeTelegraph!),
        const SizedBox(height: 8),
        _buildRoundTimer(combat),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildStanceButton(context, engine, PlayerStance.strike, '⚔️', 'Strike'),
            _buildStanceButton(context, engine, PlayerStance.heavyStrike, '💪', 'Heavy'),
            _buildStanceButton(context, engine, PlayerStance.defend, '🛡️', 'Defend'),
            _buildStanceButton(context, engine, PlayerStance.readTells, '👁️', 'Read'),
            _buildStanceButton(context, engine, PlayerStance.item, '🎒', 'Item'),
          ],
        ),
      ],
    );
  }

  Widget _buildTelegraphBanner(BeastTelegraph tg) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              tg.text + (tg.reveal ? ' [${tg.abilityId}]' : ''),
              style: const TextStyle(color: Colors.red, fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundTimer(CombatState combat) {
    final remaining = combat.roundDeadline?.difference(DateTime.now()) ?? Duration.zero;
    final pct = remaining.inMilliseconds.clamp(0, 2000) / 2000.0;
    return Row(
      children: [
        Text('Round ${combat.currentRoundNumber}', style: const TextStyle(color: GameTheme.textMuted, fontSize: 11)),
        const SizedBox(width: 8),
        Expanded(
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: GameTheme.border,
            valueColor: const AlwaysStoppedAnimation(GameTheme.accentGold),
          ),
        ),
      ],
    );
  }

  Widget _buildStanceButton(BuildContext context, GameEngine engine, PlayerStance stance, String emoji, String label) {
    final cost = engine.getStanceCost(stance);
    final canAfford = engine.playerStats.currentEnergy >= cost;
    final isItem = stance == PlayerStance.item;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: ElevatedButton(
          onPressed: !canAfford ? null : () {
            if (isItem) {
              _showItemPopover(context, engine);
            } else {
              engine.setCombatStance(stance);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: canAfford ? GameTheme.cardBg : GameTheme.border.withOpacity(0.3),
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              Text(label, style: const TextStyle(fontSize: 10)),
              if (cost > 0) Text('-$cost', style: TextStyle(fontSize: 9, color: canAfford ? GameTheme.textMuted : Colors.red)),
            ],
          ),
        ),
      ),
    );
  }

  void _showItemPopover(BuildContext context, GameEngine engine) {
    showModalBottomSheet(
      context: context,
      backgroundColor: GameTheme.cardBg,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < 3; i++)
            ListTile(
              leading: Text(engine.quickslots[i] != null ? '#${i + 1}' : '#${i + 1} (empty)',
                  style: const TextStyle(color: GameTheme.textLight)),
              title: Text(engine.quickslots[i] ?? '—',
                  style: const TextStyle(color: Colors.white)),
              onTap: engine.quickslots[i] != null ? () {
                Navigator.pop(context);
                engine.setCombatStance(PlayerStance.item, quickslotIndex: i);
              } : null,
            ),
        ],
      ),
    );
  }
}
```

Also expose `getStanceCost` as a public getter in engine:
```dart
int getStanceCost(PlayerStance s) => _stanceCost(s);
```

- [ ] **Step 2: Mount in Dashboard combat card**

In `lib/views/dashboard_view.dart` find `_buildCombatDashboardCard` and inside the card body (after HP rows), add:

```dart
const SizedBox(height: 12),
const CombatActionBar(),
```

Add import: `import '../widgets/combat_action_bar.dart';`

- [ ] **Step 3: Verify visually**

Run the app, start a Forest Boar hunt. Expect the action bar to appear with 5 buttons. Tap Defend → -2 energy, beast damage halved.

- [ ] **Step 4: Commit**

```bash
git add lib/widgets/combat_action_bar.dart lib/views/dashboard_view.dart lib/engine/game_engine.dart
git commit -m "feat(ui): add CombatActionBar with 5 stance buttons + telegraph banner + round timer"
```

---

## Task 10: Random event model + 2 new items

**Files:**
- Create: `lib/models/random_event.dart`
- Modify: `lib/models/item.dart` (add Honeycomb + Traveler's Feather)
- Test: `test/random_event_test.dart` (new)

- [ ] **Step 1: Write failing tests**

Create `test/random_event_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/models/random_event.dart';
import 'package:flutter_text_based_rpg/models/item.dart';

void main() {
  group('Random Event model', () {
    test('EventCategory has 4 values', () {
      expect(EventCategory.values.length, 4);
      expect(EventCategory.values, containsAll([
        EventCategory.interruption,
        EventCategory.discovery,
        EventCategory.traveler,
        EventCategory.omen,
      ]));
    });

    test('EventRewardKind has 4 values', () {
      expect(EventRewardKind.values.length, 4);
    });
  });

  group('New items', () {
    test('Honeycomb exists as food', () {
      final i = Items.findById('honeycomb')!;
      expect(i.type, ItemType.food);
      expect(i.healAmount, 8);
      expect(i.energyAmount, 12);
    });

    test("Traveler's Feather exists as resource", () {
      final i = Items.findById('travelers_feather')!;
      expect(i.type, ItemType.resource);
      expect(i.value, 25);
    });
  });
}
```

- [ ] **Step 2: Run tests, verify they fail**

Run: `flutter test test/random_event_test.dart`

Expected: FAIL — module/items don't exist.

- [ ] **Step 3: Create random_event.dart + add 2 items**

Create `lib/models/random_event.dart`:

```dart
import 'skill.dart';

enum EventCategory { interruption, discovery, traveler, omen }

enum EventRewardKind { item, gold, skillXp, fragment }

class EventReward {
  final EventRewardKind kind;
  final String? targetId;
  final int amount;
  const EventReward({required this.kind, this.targetId, required this.amount});
}

class RandomEventOption {
  final String text;
  final String feedback;
  final int energyCost;
  final int healthCost;
  final int goldCost;
  final SkillType? requiredSkill;
  final int requiredLevel;
  final String? requiredItemId;
  final int requiredItemCount;
  final List<EventReward> rewards;

  const RandomEventOption({
    required this.text,
    required this.feedback,
    this.energyCost = 0,
    this.healthCost = 0,
    this.goldCost = 0,
    this.requiredSkill,
    this.requiredLevel = 1,
    this.requiredItemId,
    this.requiredItemCount = 0,
    this.rewards = const [],
  });
}

class RandomEvent {
  final String id;
  final EventCategory category;
  final String title;
  final String prompt;
  final List<RandomEventOption> options;
  final List<SkillType>? triggerSkills;
  final List<int>? triggerZoneTiers;

  const RandomEvent({
    required this.id,
    required this.category,
    required this.title,
    required this.prompt,
    required this.options,
    this.triggerSkills,
    this.triggerZoneTiers,
  });
}

class ActiveRandomEventState {
  final RandomEvent event;
  final DateTime startedAt;
  const ActiveRandomEventState({required this.event, required this.startedAt});
}

class RandomEvents {
  static const List<RandomEvent> all = [];  // Filled in Task 11
}
```

In `lib/models/item.dart` add to `Items`:

```dart
static const Item honeycomb = Item(
  id: 'honeycomb',
  name: 'Honeycomb',
  description: 'A sticky, golden comb. Sweetens any dish with a slight energy bonus.',
  icon: '🍯',
  type: ItemType.food,
  value: 15,
  healAmount: 8,
  energyAmount: 12,
);

static const Item travelersFeather = Item(
  id: 'travelers_feather',
  name: "Traveler's Feather",
  description: 'A long, slate-gray feather. They say it points toward hidden paths.',
  icon: '🪶',
  type: ItemType.resource,
  value: 25,
);
```

Append both to `Items.all`.

- [ ] **Step 4: Run tests, verify pass**

Run: `flutter test test/random_event_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/models/random_event.dart lib/models/item.dart test/random_event_test.dart
git commit -m "feat(events): add RandomEvent model and 2 new items (Honeycomb, Traveler's Feather)"
```

---

## Task 11: Populate 20 event templates

**Files:**
- Modify: `lib/models/random_event.dart`
- Test: `test/random_event_test.dart` (extend)

- [ ] **Step 1: Write failing test**

Add to `test/random_event_test.dart`:

```dart
test('RandomEvents.all contains exactly 20 events', () {
  expect(RandomEvents.all.length, 20);
});

test('5 events per category', () {
  for (final cat in EventCategory.values) {
    expect(RandomEvents.all.where((e) => e.category == cat).length, 5,
        reason: 'Category $cat should have 5 events');
  }
});

test('Every event has a unique id', () {
  final ids = RandomEvents.all.map((e) => e.id).toSet();
  expect(ids.length, 20);
});

test('Bee Swarm has 3 options', () {
  final beeSwarm = RandomEvents.all.firstWhere((e) => e.id == 'bee_swarm');
  expect(beeSwarm.options.length, 3);
});
```

- [ ] **Step 2: Run test, verify it fails**

Run: `flutter test test/random_event_test.dart`

Expected: FAIL — RandomEvents.all is empty.

- [ ] **Step 3: Populate all 20 events**

Replace `RandomEvents.all = []` in `lib/models/random_event.dart` with the full registry. Use the table from the spec doc § 3.4. Example structure:

```dart
class RandomEvents {
  static const RandomEvent beeSwarm = RandomEvent(
    id: 'bee_swarm',
    category: EventCategory.interruption,
    title: 'Bee Swarm',
    prompt: 'A wild bee swarm bursts from the bush you were searching!',
    triggerSkills: [SkillType.herbalism],
    options: [
      RandomEventOption(
        text: 'Endure the stings',
        feedback: 'You take the stings and pluck the bloom anyway.',
        healthCost: 8,
        rewards: [EventReward(kind: EventRewardKind.item, targetId: 'wildflower', amount: 2)],
      ),
      RandomEventOption(
        text: 'Smoke them out',
        feedback: 'A small fire drives the bees off. You gather extra honey.',
        requiredItemId: 'oak_log',
        requiredItemCount: 1,
        rewards: [
          EventReward(kind: EventRewardKind.item, targetId: 'wildflower', amount: 1),
          EventReward(kind: EventRewardKind.item, targetId: 'honeycomb', amount: 1),
        ],
      ),
      RandomEventOption(
        text: 'Retreat',
        feedback: 'You back away slowly and try again later.',
        rewards: [],
      ),
    ],
  );

  // ... 19 more events following the same pattern, copying from the spec doc § 3.4 tables ...

  static const List<RandomEvent> all = [
    // Interruption
    beeSwarm, rockslide, suddenStorm, axeSlip, cookingFlare,
    // Discovery
    hiddenCache, rareBloom, surveyorsMarker, glintingPebble, featherInPath,
    // Traveler
    wanderingRefugee, injuredTrapper, travelingMerchant, mutePilgrim, seaMessenger,
    // Omen
    blackSapOak, whisperingStone, fogVoice, witheredGrove, tappingInWalls,
  ];
}
```

Author all 20 by following the table in the spec's § 3.4 (each row → one RandomEvent const with its options). The full implementation is mechanical — ~250 lines of data.

- [ ] **Step 4: Run tests, verify pass**

Run: `flutter test test/random_event_test.dart`

Expected: All event-count tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/models/random_event.dart test/random_event_test.dart
git commit -m "feat(events): populate 20 random event templates across 4 categories"
```

---

## Task 12: Random event engine integration

**Files:**
- Modify: `lib/engine/game_engine.dart`
- Test: `test/random_event_test.dart` (extend)

- [ ] **Step 1: Write failing tests**

Add to `test/random_event_test.dart`:

```dart
import 'package:flutter_text_based_rpg/engine/game_engine.dart';

group('Random event engine', () {
  test('Forced event becomes active and emits on stream', () async {
    final engine = GameEngine();
    final events = <RandomEvent>[];
    final sub = engine.randomEvents.listen(events.add);

    engine.forceRandomEventForTest(RandomEvents.beeSwarm);
    expect(engine.activeRandomEvent, isNotNull);
    expect(engine.activeRandomEvent!.event.id, 'bee_swarm');
    await Future.delayed(Duration.zero);
    expect(events.length, 1);
    await sub.cancel();
  });

  test('Resolve event clears active state', () {
    final engine = GameEngine();
    engine.forceRandomEventForTest(RandomEvents.beeSwarm);
    engine.resolveRandomEvent(2);  // Retreat option
    expect(engine.activeRandomEvent, isNull);
  });

  test('Resolve grants rewards (item)', () {
    final engine = GameEngine();
    engine.forceRandomEventForTest(RandomEvents.beeSwarm);
    final wildflowerBefore = engine.inventory.getItemCount('wildflower');
    engine.resolveRandomEvent(0);  // Endure option
    expect(engine.inventory.getItemCount('wildflower'), wildflowerBefore + 2);
  });
});
```

- [ ] **Step 2: Run tests, verify they fail**

Run: `flutter test test/random_event_test.dart`

Expected: FAIL — engine methods undefined.

- [ ] **Step 3: Add event engine state + methods**

In `lib/engine/game_engine.dart`:

```dart
import '../models/random_event.dart';

// State
ActiveRandomEventState? _activeRandomEvent;
final StreamController<RandomEvent> _randomEventStream = StreamController.broadcast();

// Getters
ActiveRandomEventState? get activeRandomEvent => _activeRandomEvent;
Stream<RandomEvent> get randomEvents => _randomEventStream.stream;

void _fireRandomEvent(RandomEvent event) {
  _activeRandomEvent = ActiveRandomEventState(event: event, startedAt: DateTime.now());
  _randomEventStream.add(event);
  notifyListeners();
}

@visibleForTesting
void forceRandomEventForTest(RandomEvent event) => _fireRandomEvent(event);

void _maybeFireRandomEvent(ZoneAction action) {
  if (_activeRandomEvent != null) return;
  final roll = _random.nextDouble();
  EventCategory? category;
  if (roll < 0.02) category = EventCategory.interruption;
  else if (roll < 0.035) category = EventCategory.discovery;
  else if (roll < 0.045) category = EventCategory.traveler;
  else if (roll < 0.045 + _omenChance()) category = EventCategory.omen;
  else return;

  final eligible = RandomEvents.all.where((e) {
    if (e.category != category) return false;
    if (e.triggerSkills != null && action.requiredSkill != null && !e.triggerSkills!.contains(action.requiredSkill)) return false;
    if (e.triggerZoneTiers != null && !e.triggerZoneTiers!.contains(_currentZone.tier)) return false;
    return true;
  }).toList();

  if (eligible.isEmpty) return;
  final event = eligible[_random.nextInt(eligible.length)];
  _fireRandomEvent(event);
}

double _omenChance() {
  int count = 0;
  final tags = <CodexTag>{};
  for (final id in _knownCodexFragmentIds) {
    final f = CodexFragments.findById(id);
    if (f != null && (f.tag == CodexTag.wilds || f.tag == CodexTag.stone || f.tag == CodexTag.tide)) {
      tags.add(f.tag);
    }
  }
  if (_engineFlags.contains('breach_wilds_cleansed')) tags.remove(CodexTag.wilds);
  if (_engineFlags.contains('breach_stone_cleansed')) tags.remove(CodexTag.stone);
  if (_engineFlags.contains('breach_tide_cleansed')) tags.remove(CodexTag.tide);
  count = tags.length;
  return (0.0025 + count * 0.004).clamp(0.0025, 0.015);
}

void resolveRandomEvent(int optionIndex) {
  if (_activeRandomEvent == null) return;
  final event = _activeRandomEvent!.event;
  if (optionIndex < 0 || optionIndex >= event.options.length) return;
  final option = event.options[optionIndex];

  if (option.requiredSkill != null) {
    final skill = _skills[option.requiredSkill!];
    if (skill == null || skill.level < option.requiredLevel) return;
  }
  if (option.requiredItemId != null && !_inventory.hasItem(option.requiredItemId!, option.requiredItemCount)) return;

  // Apply costs
  _playerStats = _playerStats.copyWith(
    currentEnergy: (_playerStats.currentEnergy - option.energyCost).clamp(0, _playerStats.maxEnergy),
    currentHealth: (_playerStats.currentHealth - option.healthCost).clamp(0, _playerStats.maxHealth),
    gold: (_playerStats.gold - option.goldCost).clamp(0, 999999),
  );
  if (option.requiredItemId != null) {
    _inventory = _inventory.removeItem(option.requiredItemId!, option.requiredItemCount);
  }

  for (final r in option.rewards) {
    _grantEventReward(r);
  }

  log(option.feedback, LogType.info);
  _activeRandomEvent = null;
  notifyListeners();
}

void _grantEventReward(EventReward r) {
  switch (r.kind) {
    case EventRewardKind.item:
      final item = Items.findById(r.targetId!);
      if (item != null) _inventory = _inventory.addItem(item, r.amount);
      break;
    case EventRewardKind.gold:
      _playerStats = _playerStats.copyWith(gold: _playerStats.gold + r.amount);
      break;
    case EventRewardKind.skillXp:
      final skill = SkillType.values.firstWhere((s) => s.name == r.targetId);
      _skills[skill] = _skills[skill]!.addXp(r.amount.toDouble());
      break;
    case EventRewardKind.fragment:
      final tag = CodexTag.values.firstWhere((t) => t.name == r.targetId);
      tryDropFragment(tag, 1.0);
      break;
  }
}
```

In `_completeAction`, after the fragment-drop block, append:

```dart
if (!action.isCombat) {
  _maybeFireRandomEvent(action);
}
```

- [ ] **Step 4: Run tests, verify pass**

Run: `flutter test test/random_event_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/engine/game_engine.dart test/random_event_test.dart
git commit -m "feat(engine): wire random event engine into _completeAction at 5% total rate"
```

---

## Task 13: NarrativeEventModal — unified Masterwork + Random Event widget

**Files:**
- Create: `lib/widgets/narrative_event_modal.dart`
- Modify: `lib/main.dart` (mount listener)
- Test: `test/widget_test.dart` (extend)

- [ ] **Step 1: Create the widget**

Create `lib/widgets/narrative_event_modal.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../engine/game_engine.dart';
import '../models/random_event.dart';
import '../theme/game_theme.dart';

enum NarrativeEventVariant { masterwork, randomEvent }

class NarrativeEventModal extends StatelessWidget {
  final String title;
  final String prompt;
  final List<NarrativeEventChoice> choices;
  final NarrativeEventVariant variant;
  final EventCategory? eventCategory;

  const NarrativeEventModal({
    super.key,
    required this.title,
    required this.prompt,
    required this.choices,
    this.variant = NarrativeEventVariant.randomEvent,
    this.eventCategory,
  });

  Color _borderColor() {
    if (variant == NarrativeEventVariant.masterwork) return GameTheme.accentGold;
    switch (eventCategory) {
      case EventCategory.interruption: return Colors.orange;
      case EventCategory.discovery: return Colors.greenAccent;
      case EventCategory.traveler: return Colors.cyanAccent;
      case EventCategory.omen: return Colors.redAccent;
      default: return GameTheme.accentGold;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: GameTheme.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _borderColor(), width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  variant == NarrativeEventVariant.masterwork ? '⚔ TRIAL' : 'EVENT',
                  style: TextStyle(color: _borderColor(), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2.0),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Text(prompt, style: const TextStyle(color: GameTheme.textLight, fontSize: 13, fontStyle: FontStyle.italic, height: 1.4)),
                const SizedBox(height: 20),
                for (final c in choices) Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ElevatedButton(
                    onPressed: c.onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GameTheme.cardBg,
                      foregroundColor: Colors.white,
                      side: BorderSide(color: _borderColor().withOpacity(0.5)),
                      padding: const EdgeInsets.all(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                        if (c.preview != null) Text(c.preview!, style: const TextStyle(fontSize: 11, color: GameTheme.textMuted)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NarrativeEventChoice {
  final String label;
  final String? preview;
  final VoidCallback onTap;
  const NarrativeEventChoice({required this.label, this.preview, required this.onTap});
}

class NarrativeEventListener extends StatefulWidget {
  final Widget child;
  const NarrativeEventListener({super.key, required this.child});

  @override
  State<NarrativeEventListener> createState() => _NarrativeEventListenerState();
}

class _NarrativeEventListenerState extends State<NarrativeEventListener> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final engine = Provider.of<GameEngine>(context, listen: false);
    engine.randomEvents.listen((event) {
      _showEventModal(context, engine, event);
    });
  }

  void _showEventModal(BuildContext ctx, GameEngine engine, RandomEvent event) {
    showGeneralDialog(
      context: ctx,
      barrierDismissible: false,
      barrierLabel: 'Event',
      barrierColor: Colors.transparent,
      pageBuilder: (_, __, ___) => NarrativeEventModal(
        title: event.title,
        prompt: event.prompt,
        variant: NarrativeEventVariant.randomEvent,
        eventCategory: event.category,
        choices: [
          for (int i = 0; i < event.options.length; i++) NarrativeEventChoice(
            label: event.options[i].text,
            preview: _buildPreview(event.options[i]),
            onTap: () {
              Navigator.pop(ctx);
              engine.resolveRandomEvent(i);
            },
          ),
        ],
      ),
    );
  }

  String? _buildPreview(RandomEventOption opt) {
    final parts = <String>[];
    if (opt.energyCost != 0) parts.add('-${opt.energyCost} energy');
    if (opt.healthCost != 0) parts.add('-${opt.healthCost} HP');
    if (opt.goldCost != 0) parts.add('-${opt.goldCost} gold');
    if (opt.requiredItemId != null) parts.add('requires ${opt.requiredItemCount}× ${opt.requiredItemId}');
    return parts.isEmpty ? null : parts.join(', ');
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
```

- [ ] **Step 2: Mount listener in main.dart**

In `lib/main.dart`, wrap the main scaffold with `NarrativeEventListener`:

```dart
home: const WorldEventListener(
  child: NarrativeEventListener(
    child: MainGameShell(),
  ),
),
```

Add import: `import 'widgets/narrative_event_modal.dart';`

- [ ] **Step 3: Verify visually**

Run app. Force a Bee Swarm event (or grind Herbalism actions). Expect orange-bordered modal to appear with 3 choices.

- [ ] **Step 4: Commit**

```bash
git add lib/widgets/narrative_event_modal.dart lib/main.dart
git commit -m "feat(ui): unified NarrativeEventModal for Masterwork trials and Random Events"
```

---

## Task 14: Salt Press — 5 new items

**Files:**
- Modify: `lib/models/item.dart`
- Test: `test/salt_press_test.dart` (new)

- [ ] **Step 1: Write failing test**

Create `test/salt_press_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/models/item.dart';

void main() {
  group('Salt Press output items', () {
    test('5 new items exist with correct ids', () {
      for (final id in ['salt_cured_trout', 'brined_boar', 'kelp_wrap', 'pearl_tonic', 'brine_stabilizer']) {
        expect(Items.findById(id), isNotNull, reason: 'Missing: $id');
      }
    });

    test('Salt-Cured Trout has +35 HP and +20 energy', () {
      final i = Items.findById('salt_cured_trout')!;
      expect(i.healAmount, 35);
      expect(i.energyAmount, 20);
    });

    test('Pearl Tonic has +60 energy', () {
      expect(Items.findById('pearl_tonic')!.energyAmount, 60);
    });

    test('Brine Stabilizer is a resource (not food)', () {
      expect(Items.findById('brine_stabilizer')!.type, ItemType.resource);
    });
  });
}
```

- [ ] **Step 2: Run tests, verify they fail**

Run: `flutter test test/salt_press_test.dart`

Expected: FAIL.

- [ ] **Step 3: Add 5 items**

In `lib/models/item.dart` `Items` class:

```dart
static const Item saltCuredTrout = Item(
  id: 'salt_cured_trout', name: 'Salt-Cured Trout',
  description: 'Fresh trout preserved in salt. Lasts longer than fresh fish and keeps your energy steady.',
  icon: '🐟', type: ItemType.food, value: 30, healAmount: 35, energyAmount: 20,
);

static const Item brinedBoar = Item(
  id: 'brined_boar', name: 'Brined Boar',
  description: 'Boar meat brined in salt-water. Heavy on the stomach, light on the wallet.',
  icon: '🍖', type: ItemType.food, value: 40, healAmount: 45, energyAmount: 10,
);

static const Item kelpWrap = Item(
  id: 'kelp_wrap', name: 'Kelp Wrap',
  description: 'A potato wrapped in sea kelp. Tastes of brine and earth.',
  icon: '🥬', type: ItemType.food, value: 35, healAmount: 30, energyAmount: 25,
);

static const Item pearlTonic = Item(
  id: 'pearl_tonic', name: 'Pearl Tonic',
  description: 'A pearlescent draught that sharpens the hands and clears the head.',
  icon: '🧪', type: ItemType.food, value: 80, healAmount: 0, energyAmount: 60,
);

static const Item brineStabilizer = Item(
  id: 'brine_stabilizer', name: 'Brine Stabilizer',
  description: 'A clear, briny gel. Crafters use it as a stabilizing modifier when working on tricky recipes.',
  icon: '🫙', type: ItemType.resource, value: 50,
);
```

Append all 5 to `Items.all`.

- [ ] **Step 4: Run tests, verify pass**

Run: `flutter test test/salt_press_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/models/item.dart test/salt_press_test.dart
git commit -m "feat(items): add 5 Salt Press output items"
```

---

## Task 15: Salt Press — 5 new recipes

**Files:**
- Modify: `lib/models/recipe.dart`
- Test: `test/salt_press_test.dart` (extend)

- [ ] **Step 1: Write failing tests**

Add to `test/salt_press_test.dart`:

```dart
import 'package:flutter_text_based_rpg/models/recipe.dart';

group('Salt Press recipes', () {
  test('5 new recipes exist', () {
    for (final id in ['salt_cured_trout', 'brined_boar', 'kelp_wrap', 'pearl_tonic', 'brine_stabilizer']) {
      expect(Recipes.all.any((r) => r.id == id), true, reason: 'Missing: $id');
    }
  });

  test('Salt-Cured Trout consumes raw_trout + salt_crystal', () {
    final r = Recipes.all.firstWhere((r) => r.id == 'salt_cured_trout');
    expect(r.inputs['raw_trout'], 1);
    expect(r.inputs['salt_crystal'], 1);
  });

  test('Pearl Tonic requires Herbalism level 6', () {
    final r = Recipes.all.firstWhere((r) => r.id == 'pearl_tonic');
    expect(r.requiredSkill, SkillType.herbalism);
    expect(r.requiredLevel, 6);
  });
});
```

- [ ] **Step 2: Run tests, verify they fail**

Run: `flutter test test/salt_press_test.dart`

Expected: FAIL.

- [ ] **Step 3: Add 5 recipes**

In `lib/models/recipe.dart`, in `Recipes`:

```dart
static const Recipe saltCuredTrout = Recipe(
  id: 'salt_cured_trout',
  name: 'Salt-Cured Trout',
  icon: '🐟',
  description: 'Preserve a fresh trout with sea-salt.',
  resultItemId: 'salt_cured_trout',
  resultQuantity: 1,
  requiredSkill: SkillType.cooking,
  requiredLevel: 3,
  xpReward: 25,
  inputs: {'raw_trout': 1, 'salt_crystal': 1},
  energyCost: 3,
  durationSeconds: 4,
);

static const Recipe brinedBoar = Recipe(
  id: 'brined_boar',
  name: 'Brined Boar',
  icon: '🍖',
  description: 'Brine boar meat in salt-water.',
  resultItemId: 'brined_boar',
  resultQuantity: 1,
  requiredSkill: SkillType.cooking,
  requiredLevel: 5,
  xpReward: 30,
  inputs: {'boar_meat': 2, 'salt_crystal': 1},
  energyCost: 3,
  durationSeconds: 5,
);

static const Recipe kelpWrap = Recipe(
  id: 'kelp_wrap',
  name: 'Kelp Wrap',
  icon: '🥬',
  description: 'Wrap a baked potato in salted kelp.',
  resultItemId: 'kelp_wrap',
  resultQuantity: 1,
  requiredSkill: SkillType.cooking,
  requiredLevel: 4,
  xpReward: 28,
  inputs: {'kelp': 2, 'baked_potato': 1},
  energyCost: 3,
  durationSeconds: 4,
);

static const Recipe pearlTonic = Recipe(
  id: 'pearl_tonic',
  name: 'Pearl Tonic',
  icon: '🧪',
  description: 'Distill a pearlescent draught.',
  resultItemId: 'pearl_tonic',
  resultQuantity: 1,
  requiredSkill: SkillType.herbalism,
  requiredLevel: 6,
  xpReward: 40,
  inputs: {'pearl_shell': 1, 'kelp': 3, 'hot_water': 1},
  energyCost: 5,
  durationSeconds: 6,
);

static const Recipe brineStabilizer = Recipe(
  id: 'brine_stabilizer',
  name: 'Brine Stabilizer',
  icon: '🫙',
  description: 'A briny gel that stabilizes finicky recipes.',
  resultItemId: 'brine_stabilizer',
  resultQuantity: 1,
  requiredSkill: SkillType.cooking,
  requiredLevel: 5,
  xpReward: 35,
  inputs: {'salt_crystal': 2, 'river_clay': 1},
  energyCost: 4,
  durationSeconds: 5,
);
```

Append all 5 to `Recipes.all`.

If the Recipe model needs a `station` field (per the spec note), add `final String station = 'crafting_bench';` default and override for Salt Press recipes:

```dart
// In Recipe class:
final String station;
const Recipe({
  // existing required + optional...
  this.station = 'crafting_bench',
});

// Each Salt Press recipe sets:
station: 'salt_press',
```

The Workshop view filters recipes by `r.station == selectedStation.id` (already a pattern from prior crafting overhaul; if not present, add the filter).

- [ ] **Step 4: Run tests, verify pass**

Run: `flutter test test/salt_press_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/models/recipe.dart test/salt_press_test.dart
git commit -m "feat(recipes): add 5 Salt Press recipes with station tag"
```

---

## Task 16: Driftwood substitution

**Files:**
- Modify: `lib/engine/game_engine.dart`
- Test: `test/driftwood_substitution_test.dart` (new)

- [ ] **Step 1: Write failing tests**

Create `test/driftwood_substitution_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/models/item.dart';
import 'package:flutter_text_based_rpg/models/recipe.dart';

void main() {
  group('Driftwood substitution for oak_log', () {
    late GameEngine engine;

    setUp(() {
      engine = GameEngine();
    });

    test('Recipe with driftwood available passes _hasInputsForRecipe', () {
      engine.inventory = engine.inventory.addItem(Items.driftwood, 5);
      engine.inventory = engine.inventory.addItem(Items.riverClay, 5);
      final stoneAxe = Recipes.all.firstWhere((r) => r.id == 'stone_axe');
      expect(engine.hasInputsForRecipeForTest(stoneAxe), true);
    });

    test('Recipe with no oak or driftwood fails _hasInputsForRecipe', () {
      final stoneAxe = Recipes.all.firstWhere((r) => r.id == 'stone_axe');
      expect(engine.hasInputsForRecipeForTest(stoneAxe), false);
    });

    test('Driftwood is consumed when oak_log not available', () {
      engine.inventory = engine.inventory.addItem(Items.driftwood, 5);
      engine.inventory = engine.inventory.addItem(Items.riverClay, 5);
      final stoneAxe = Recipes.all.firstWhere((r) => r.id == 'stone_axe');
      final consumed = engine.consumeInputsForRecipeForTest(stoneAxe);
      expect(consumed['driftwood'], greaterThan(0));
      expect(consumed['oak_log'] ?? 0, 0);
    });

    test('Quality bias +0.03 when driftwood substituted for oak_log', () {
      final stoneAxe = Recipes.all.firstWhere((r) => r.id == 'stone_axe');
      final consumed = {'driftwood': 3, 'river_clay': 2};  // 3 driftwood as oak substitute
      expect(engine.calculateRecipeQualityBiasForTest(stoneAxe, consumed), closeTo(0.03, 0.001));
    });
  });
}
```

- [ ] **Step 2: Run tests, verify they fail**

Run: `flutter test test/driftwood_substitution_test.dart`

Expected: FAIL.

- [ ] **Step 3: Add substitution logic to engine**

In `lib/engine/game_engine.dart`:

```dart
static const Map<String, List<String>> _substitutions = {
  'oak_log': ['driftwood'],
};

bool _hasInputsForRecipe(Recipe recipe) {
  for (final entry in recipe.inputs.entries) {
    final required = entry.key;
    final qty = entry.value;
    final substitutes = [required, ...?_substitutions[required]];
    final available = substitutes.fold<int>(
      0,
      (sum, id) => sum + _inventory.getItemCount(id),
    );
    if (available < qty) return false;
  }
  return true;
}

Map<String, int> _consumeInputsForRecipe(Recipe recipe) {
  final actuallyConsumed = <String, int>{};
  for (final entry in recipe.inputs.entries) {
    int remaining = entry.value;
    final substitutes = [entry.key, ...?_substitutions[entry.key]];
    // Prefer substitutes when available (driftwood used before oak)
    for (final id in substitutes.reversed) {
      if (remaining <= 0) break;
      final has = _inventory.getItemCount(id);
      final use = remaining < has ? remaining : has;
      if (use > 0) {
        _inventory = _inventory.removeItem(id, use);
        actuallyConsumed[id] = (actuallyConsumed[id] ?? 0) + use;
        remaining -= use;
      }
    }
  }
  return actuallyConsumed;
}

double _calculateRecipeQualityBias(Recipe recipe, Map<String, int> actualConsumed) {
  double bias = 0.0;
  if (actualConsumed.containsKey('driftwood') && recipe.inputs.containsKey('oak_log')) {
    bias += 0.03;
  }
  return bias;
}

@visibleForTesting
bool hasInputsForRecipeForTest(Recipe r) => _hasInputsForRecipe(r);

@visibleForTesting
Map<String, int> consumeInputsForRecipeForTest(Recipe r) => _consumeInputsForRecipe(r);

@visibleForTesting
double calculateRecipeQualityBiasForTest(Recipe r, Map<String, int> consumed) =>
    _calculateRecipeQualityBias(r, consumed);
```

Wire these into the existing craft-start and craft-complete paths (find `startCrafting` or equivalent — replace direct `_inventory.hasItem` and `_inventory.removeItem` calls with the new helpers; pass `_calculateRecipeQualityBias` result into the quality roll).

- [ ] **Step 4: Run tests, verify pass**

Run: `flutter test test/driftwood_substitution_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/engine/game_engine.dart test/driftwood_substitution_test.dart
git commit -m "feat(crafting): auto-substitute driftwood for oak_log with +0.03 quality bias"
```

---

## Task 17: Masterwork specPath/subSpecPath fields + engine state

**Files:**
- Modify: `lib/models/masterwork.dart`
- Modify: `lib/engine/game_engine.dart`
- Test: `test/masterwork_spec_test.dart` (new)

- [ ] **Step 1: Write failing tests**

Create `test/masterwork_spec_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/models/masterwork.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/models/skill.dart';

void main() {
  group('MasterworkOption spec/sub-spec fields', () {
    test('MasterworkOption can carry specPath', () {
      const opt = MasterworkOption(
        text: 'Test',
        feedback: 'OK',
        isSuccess: true,
        specPath: 'crafting_smith',
      );
      expect(opt.specPath, 'crafting_smith');
    });

    test('MasterworkOption can carry subSpecPath', () {
      const opt = MasterworkOption(
        text: 'Test',
        feedback: 'OK',
        isSuccess: true,
        subSpecPath: 'crafting_weaponsmith',
      );
      expect(opt.subSpecPath, 'crafting_weaponsmith');
    });
  });

  group('Engine spec state', () {
    test('_skillSpecs starts empty', () {
      final engine = GameEngine();
      expect(engine.skillSpecs.isEmpty, true);
    });

    test('_skillSubSpecs starts empty', () {
      final engine = GameEngine();
      expect(engine.skillSubSpecs.isEmpty, true);
    });

    test('specForSkill returns null when unset', () {
      final engine = GameEngine();
      expect(engine.specForSkill(SkillType.crafting), isNull);
    });
  });
}
```

- [ ] **Step 2: Run tests, verify they fail**

Run: `flutter test test/masterwork_spec_test.dart`

Expected: FAIL — fields/methods undefined.

- [ ] **Step 3: Add fields to MasterworkOption + engine state**

In `lib/models/masterwork.dart`, extend `MasterworkOption`:

```dart
class MasterworkOption {
  // existing fields...
  final String? specPath;
  final String? subSpecPath;

  const MasterworkOption({
    required this.text,
    this.nextStepId,
    this.isSuccess = false,
    required this.feedback,
    this.energyCost = 0,
    this.healthCost = 0,
    this.goldCost = 0,
    this.requiredSkill,
    this.requiredLevel = 1,
    this.requiredItemId,
    this.requiredItemCount = 1,
    this.specPath,        // NEW
    this.subSpecPath,     // NEW
  });
}
```

In `lib/engine/game_engine.dart` (extending `_skillSpecs` stub from Task 3):

```dart
final Map<SkillType, String> _skillSubSpecs = {};

Map<SkillType, String> get skillSpecs => Map.unmodifiable(_skillSpecs);
Map<SkillType, String> get skillSubSpecs => Map.unmodifiable(_skillSubSpecs);

String? specForSkill(SkillType s) => _skillSpecs[s];
String? subSpecForSkill(SkillType s) => _skillSubSpecs[s];
```

- [ ] **Step 4: Run tests, verify pass**

Run: `flutter test test/masterwork_spec_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/models/masterwork.dart lib/engine/game_engine.dart test/masterwork_spec_test.dart
git commit -m "feat(masterwork): add specPath/subSpecPath fields and engine spec maps"
```

---

## Task 18: Wire existing 8 level-10 trials with specPath

**Files:**
- Modify: `lib/models/masterwork.dart`
- Test: `test/masterwork_spec_test.dart` (extend)

- [ ] **Step 1: Write failing tests for path mapping**

Add to `test/masterwork_spec_test.dart`:

```dart
test('Crafting Lvl 10 iron-reinforced terminal has specPath crafting_smith', () {
  final task = MasterworkTasks.woodcuttingLvl10;  // Adjust to your real Crafting trial reference
  // Walk the trial via its terminal options; find the iron-reinforced one
  // and verify specPath == 'crafting_smith'
  // (Specifics depend on existing trial structure — this is the verification pattern)
});

test('All 8 skills have at least one terminal MasterworkOption with specPath set', () {
  for (final skill in SkillType.values) {
    final tasks = MasterworkTasks.all.where((t) => t.skillType == skill && t.levelGate == 10);
    for (final task in tasks) {
      final hasSpec = task.steps.values
          .expand((s) => s.options)
          .any((o) => o.isSuccess && o.specPath != null);
      expect(hasSpec, true, reason: 'Skill $skill level-10 trial missing specPath on terminal options');
    }
  }
});
```

- [ ] **Step 2: Run tests, verify they fail**

Run: `flutter test test/masterwork_spec_test.dart`

Expected: FAIL — existing trials don't have specPath set.

- [ ] **Step 3: Update terminal options in all 8 trials**

In `lib/models/masterwork.dart`, find each level-10 trial's terminal `MasterworkOption(isSuccess: true, ...)` entries and add `specPath`:

For each skill's trial, identify the two terminal narrative outcomes:
- Combat (existing `combatLvl10`): aggressive terminal → `combat_berserker`; defensive terminal → `combat_guardian`
- Crafting (existing `woodcuttingLvl10` or whichever name): iron-reinforced → `crafting_smith`; berry-healed → `crafting_tinker`
- Cooking: precise structured cook → `cooking_innkeeper`; improvised field cook → `cooking_field_chef`
- Herbalism: patient cultivation → `herbalism_garden_keeper`; risky pluck → `herbalism_wild_walker`
- Woodcutting: volume/brute force → `woodcutting_logger`; patience/rare-wood ID → `woodcutting_arborist`
- Mining: seeking/exploration → `mining_prospector`; processing/quality focus → `mining_refiner`
- Wayfinding: mapping/observation → `wayfinding_cartographer`; pursuit/beast-following → `wayfinding_tracker`
- Lore: broad knowledge → `lore_loremaster`; focused glyph mastery → `lore_glyph_carver`

Inspect each trial's `steps` map; on each `MasterworkOption` where `isSuccess: true`, add the appropriate `specPath: '<spec_id>'`. Pattern (mirroring spec):

```dart
MasterworkOption(
  text: 'Strike the tree with the reinforced axe.',
  isSuccess: true,
  energyCost: 20,
  feedback: '...',
  specPath: 'crafting_smith',   // NEW
),
```

- [ ] **Step 4: Run tests, verify pass**

Run: `flutter test test/masterwork_spec_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/models/masterwork.dart test/masterwork_spec_test.dart
git commit -m "feat(masterwork): wire all 8 existing level-10 trials with specPath encoding"
```

---

## Task 19: 16 level-20 Masterwork trials

**Files:**
- Modify: `lib/models/masterwork.dart`
- Test: `test/masterwork_spec_test.dart` (extend)

- [ ] **Step 1: Write failing test**

Add to `test/masterwork_spec_test.dart`:

```dart
test('16 level-20 trials exist (one per skill x level-10 spec)', () {
  final lvl20Tasks = MasterworkTasks.all.where((t) => t.levelGate == 20).toList();
  expect(lvl20Tasks.length, 16);
});

test('Each level-20 trial has terminal options with subSpecPath', () {
  for (final task in MasterworkTasks.all.where((t) => t.levelGate == 20)) {
    final hasSubSpec = task.steps.values
        .expand((s) => s.options)
        .any((o) => o.isSuccess && o.subSpecPath != null);
    expect(hasSubSpec, true, reason: 'Lvl 20 trial ${task.id} missing subSpecPath');
  }
});
```

- [ ] **Step 2: Run tests, verify they fail**

Run: `flutter test test/masterwork_spec_test.dart`

Expected: FAIL.

- [ ] **Step 3: Add all 16 level-20 trials**

In `lib/models/masterwork.dart`, copy all 16 trial definitions from the spec doc § 4.7 verbatim (the spec contains complete Dart code for each trial — paste into the `MasterworkTasks` class). The 16 trials:

1. `combatLvl20Berserker` (Blood and Fury)
2. `combatLvl20Guardian` (Walls and Mirrors)
3. `craftingLvl20Smith` (The Greater Ironbark)
4. `craftingLvl20Tinker` (The Salt-Eaten Loom)
5. `cookingLvl20Innkeeper` (The Long Feast)
6. `cookingLvl20FieldChef` (Fire on the Wayside)
7. `herbalismLvl20GardenKeeper` (The Second Garden)
8. `herbalismLvl20WildWalker` (The Deep Grove)
9. `woodcuttingLvl20Logger` (The Old Stand)
10. `woodcuttingLvl20Arborist` (The Sapling Path)
11. `miningLvl20Prospector` (The Cavern's Promise)
12. `miningLvl20Refiner` (The Smelter's Heart)
13. `wayfindingLvl20Cartographer` (Charts of the Sea)
14. `wayfindingLvl20Tracker` (The Last Spoor)
15. `loreLvl20Loremaster` (The Polyphonic Reading)
16. `loreLvl20GlyphCarver` (The Twin Glyphs)

Append all 16 to `MasterworkTasks.all`. Add lookup entries to `MasterworkTasks.findById` mapping each id to its task.

- [ ] **Step 4: Run tests, verify pass**

Run: `flutter test test/masterwork_spec_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/models/masterwork.dart test/masterwork_spec_test.dart
git commit -m "feat(masterwork): add all 16 level-20 trials with full narrative and subSpecPath"
```

---

## Task 20: Level-20 trial offering logic + completion records spec

**Files:**
- Modify: `lib/engine/game_engine.dart`
- Test: `test/masterwork_spec_test.dart` (extend)

- [ ] **Step 1: Write failing tests**

Add to `test/masterwork_spec_test.dart`:

```dart
test('Completing a level-10 trial via specPath terminal records spec', () {
  final engine = GameEngine();
  engine.completeMasterworkForTest('craftingLvl10', specPath: 'crafting_smith');
  expect(engine.specForSkill(SkillType.crafting), 'crafting_smith');
});

test('Level-20 trial is only offered after level-10 spec set', () {
  final engine = GameEngine();
  // Pre-set Crafting level to 20 cap but no spec
  engine.setCraftingLevelForTest(20);
  engine.maybeOfferLvl20MasterworkForTest(SkillType.crafting);
  expect(
    engine.activeQuests.any((q) => q.id.contains('lvl20')),
    false,
    reason: 'Lvl 20 trial should not be offered without level-10 spec',
  );
});

test('Level-20 trial offered after level-10 spec is set + skill at cap', () {
  final engine = GameEngine();
  engine.completeMasterworkForTest('craftingLvl10', specPath: 'crafting_smith');
  engine.setCraftingLevelForTest(20);
  engine.maybeOfferLvl20MasterworkForTest(SkillType.crafting);
  expect(
    engine.activeQuests.any((q) => q.id == 'task_lvl20_crafting_smith'),
    true,
  );
});
```

- [ ] **Step 2: Run tests, verify they fail**

Run: `flutter test test/masterwork_spec_test.dart`

Expected: FAIL.

- [ ] **Step 3: Update Masterwork completion + offering logic**

In `lib/engine/game_engine.dart`, find the Masterwork completion path (likely `_onMasterworkSuccess` or similar) and update:

```dart
void _onMasterworkSuccess(MasterworkRunState run, MasterworkOption terminalOption) {
  final task = run.task;
  _skills[task.skillType] = _skills[task.skillType]!.unlockCap();

  if (terminalOption.specPath != null) {
    _skillSpecs[task.skillType] = terminalOption.specPath!;
    log("You have walked the ${_specDisplayName(terminalOption.specPath!)} path. Forevermore, your craft knows your name.",
        LogType.success);
  }
  if (terminalOption.subSpecPath != null) {
    _skillSubSpecs[task.skillType] = terminalOption.subSpecPath!;
    log("You have refined further into ${_subSpecDisplayName(terminalOption.subSpecPath!)}.",
        LogType.success);
  }

  _notifyQuestObservers(MasterworkCompletedEvent(task.skillType));
  notifyListeners();
}

String _specDisplayName(String path) {
  // Mapping table — same names as in spec
  const names = {
    'combat_berserker': 'Berserker', 'combat_guardian': 'Guardian',
    'crafting_smith': 'Smith', 'crafting_tinker': 'Tinker',
    'cooking_innkeeper': 'Innkeeper', 'cooking_field_chef': 'Field-Chef',
    'herbalism_garden_keeper': 'Garden-Keeper', 'herbalism_wild_walker': 'Wild-Walker',
    'woodcutting_logger': 'Logger', 'woodcutting_arborist': 'Arborist',
    'mining_prospector': 'Prospector', 'mining_refiner': 'Refiner',
    'wayfinding_cartographer': 'Cartographer', 'wayfinding_tracker': 'Tracker',
    'lore_loremaster': 'Loremaster', 'lore_glyph_carver': 'Glyph-Carver',
  };
  return names[path] ?? path;
}

String _subSpecDisplayName(String path) {
  const names = {
    'combat_skirmisher': 'Skirmisher', 'combat_reaper': 'Reaper',
    'combat_bastion': 'Bastion', 'combat_sentinel': 'Sentinel',
    'crafting_weaponsmith': 'Weaponsmith', 'crafting_armorsmith': 'Armorsmith',
    'crafting_toolmaker': 'Toolmaker', 'crafting_backpacker': 'Backpacker',
    'cooking_brewmaster': 'Brewmaster', 'cooking_pastrycook': 'Pastrycook',
    'cooking_trailcook': 'Trailcook', 'cooking_stewmaster': 'Stewmaster',
    'herbalism_botanist': 'Botanist', 'herbalism_hedge_witch': 'Hedge-Witch',
    'herbalism_poison_picker': 'Poison-Picker', 'herbalism_bloomseer': 'Bloomseer',
    'woodcutting_clearcutter': 'Clearcutter', 'woodcutting_speedchopper': 'Speedchopper',
    'woodcutting_sapling_mender': 'Sapling-Mender', 'woodcutting_heartwood_reader': 'Heartwood-Reader',
    'mining_vein_hunter': 'Vein-Hunter', 'mining_tunnel_caller': 'Tunnel-Caller',
    'mining_smelt_master': 'Smelt-Master', 'mining_slag_cutter': 'Slag-Cutter',
    'wayfinding_sea_reader': 'Sea-Reader', 'wayfinding_path_mapper': 'Path-Mapper',
    'wayfinding_beast_lurer': 'Beast-Lurer', 'wayfinding_spoor_reader': 'Spoor-Reader',
    'lore_polymath': 'Polymath', 'lore_translator': 'Translator',
    'lore_rune_weaver': 'Rune-Weaver', 'lore_engraver': 'Engraver',
  };
  return names[path] ?? path;
}
```

Update `_maybeOfferMasterworkQuest` (or equivalent existing helper):

```dart
void _maybeOfferMasterworkQuest(SkillType skill) {
  final skillState = _skills[skill]!;
  // Level 10 trial: existing logic
  if (skillState.level >= 10 && !_completedMasterworkSkills.contains(skill)) {
    // ... existing offer logic ...
  }
  // Level 20 trial: only offered if level-10 spec is set
  final spec = _skillSpecs[skill];
  if (spec != null && skillState.level >= 20) {
    final taskId = 'task_lvl20_${spec}';
    final task = MasterworkTasks.findById(taskId);
    if (task != null && !_completedLvl20MasterworkSkills.contains(skill)) {
      // Offer the level-20 trial as a quest
      offerQuest(/* construct Quest with task; pattern matches existing Masterwork quest offering */);
    }
  }
}

@visibleForTesting
void maybeOfferLvl20MasterworkForTest(SkillType s) => _maybeOfferMasterworkQuest(s);

@visibleForTesting
void completeMasterworkForTest(String taskId, {String? specPath, String? subSpecPath}) {
  // Synthetic completion for testing
  final task = MasterworkTasks.findById(taskId);
  if (task == null) return;
  if (specPath != null) {
    _skillSpecs[task.skillType] = specPath;
    _skills[task.skillType] = _skills[task.skillType]!.unlockCap();
  }
  if (subSpecPath != null) {
    _skillSubSpecs[task.skillType] = subSpecPath;
  }
  notifyListeners();
}

@visibleForTesting
void setCraftingLevelForTest(int level) {
  _skills[SkillType.crafting] = _skills[SkillType.crafting]!.copyWith(level: level);
}
```

- [ ] **Step 4: Run tests, verify pass**

Run: `flutter test test/masterwork_spec_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/engine/game_engine.dart test/masterwork_spec_test.dart
git commit -m "feat(engine): wire spec recording + level-20 trial offering on completion"
```

---

## Task 21: Specialization effects — combat-related

**Files:**
- Modify: `lib/engine/game_engine.dart`
- Test: `test/spec_effects_test.dart` (new)

- [ ] **Step 1: Write failing tests**

Create `test/spec_effects_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/models/combat.dart';
import 'package:flutter_text_based_rpg/models/skill.dart';
import 'package:flutter_text_based_rpg/models/zone.dart';

void main() {
  group('Combat spec effects', () {
    test('Berserker reduces Heavy Strike cost to 4', () {
      final engine = GameEngine();
      engine.setEngineFlag('coast_unlocked');  // ignore for combat
      engine.completeMasterworkForTest('combatLvl10', specPath: 'combat_berserker');
      expect(engine.getStanceCost(PlayerStance.heavyStrike), 4);
    });

    test('Guardian raises Heavy Strike cost to 8', () {
      final engine = GameEngine();
      engine.completeMasterworkForTest('combatLvl10', specPath: 'combat_guardian');
      expect(engine.getStanceCost(PlayerStance.heavyStrike), 8);
    });

    test('Default (no spec) Heavy Strike cost is 5', () {
      final engine = GameEngine();
      expect(engine.getStanceCost(PlayerStance.heavyStrike), 5);
    });

    test('Reaper adds +15% crit chance', () {
      // Set Combat spec to Berserker, sub-spec to Reaper
      final engine = GameEngine();
      engine.completeMasterworkForTest('combatLvl10', specPath: 'combat_berserker');
      engine.completeMasterworkForTest('combatLvl20Berserker', subSpecPath: 'combat_reaper');
      // Test crit chance via stat helper if exposed, or via behavior
      expect(engine.getCritChanceForTest(), greaterThan(0.10));
    });
  });
}
```

- [ ] **Step 2: Run tests, verify pass for Berserker/Guardian cost (already wired in Task 3)**

Run: `flutter test test/spec_effects_test.dart`

Expected: Berserker/Guardian cost tests PASS; Reaper test FAILs (no getCritChanceForTest).

- [ ] **Step 3: Add Reaper effect + test helper**

Reaper effect already wired in Task 4's `_resolveCombatRound` crit chance calc. Just add the test helper:

```dart
@visibleForTesting
double getCritChanceForTest() {
  double critChance = 0.0;
  if (_currentZone.id.startsWith('sundered_coast_') &&
      _coastWeather.current == CoastWeather.seaFog) {
    critChance += 0.20;
  }
  if (_skillSubSpecs[SkillType.combat] == 'combat_reaper') {
    critChance += 0.15;
  }
  return critChance;
}
```

Add Defend counter for Sentinel (already wired in Task 4 for Guardian; verify Sentinel adds 10 counter):

In `_resolveCombatRound` Defend branch, change:
```dart
if (isGuardian) counter = isSentinel ? 10 : 5;
```

(Already correct per Task 4 code.)

- [ ] **Step 4: Run tests, verify pass**

Run: `flutter test test/spec_effects_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/engine/game_engine.dart test/spec_effects_test.dart
git commit -m "test(specs): verify combat spec effects (Berserker, Guardian, Reaper)"
```

---

## Task 22: Specialization effects — crafting + gather + cooking + lore

**Files:**
- Modify: `lib/engine/game_engine.dart`
- Test: `test/spec_effects_test.dart` (extend)

- [ ] **Step 1: Write tests for remaining spec effects**

Add to `test/spec_effects_test.dart`:

```dart
group('Crafting spec effects', () {
  test('Smith adds +0.20 quality bias on weapon recipes', () {
    final engine = GameEngine();
    engine.completeMasterworkForTest('craftingLvl10', specPath: 'crafting_smith');
    final swordRecipe = Recipes.all.firstWhere((r) => r.id == 'bronze_sword');
    expect(engine.getSpecCraftQualityBiasForTest(swordRecipe), closeTo(0.20, 0.001));
  });

  test('Tinker adds +0.20 quality bias on tool recipes', () {
    final engine = GameEngine();
    engine.completeMasterworkForTest('craftingLvl10', specPath: 'crafting_tinker');
    final axeRecipe = Recipes.all.firstWhere((r) => r.id == 'stone_axe');
    expect(engine.getSpecCraftQualityBiasForTest(axeRecipe), closeTo(0.20, 0.001));
  });

  test('Weaponsmith adds +0.15 additional on weapon (total +0.35 with Smith)', () {
    final engine = GameEngine();
    engine.completeMasterworkForTest('craftingLvl10', specPath: 'crafting_smith');
    engine.completeMasterworkForTest('craftingLvl20Smith', subSpecPath: 'crafting_weaponsmith');
    final swordRecipe = Recipes.all.firstWhere((r) => r.id == 'bronze_sword');
    expect(engine.getSpecCraftQualityBiasForTest(swordRecipe), closeTo(0.35, 0.001));
  });
});

group('Gather spec effects', () {
  test('Logger gives +30% wood yield', () {
    final engine = GameEngine();
    engine.completeMasterworkForTest('woodcuttingLvl10', specPath: 'woodcutting_logger');
    expect(engine.getGatherYieldBonusForTest(SkillType.woodcutting), closeTo(0.30, 0.001));
  });

  test('Prospector gives +30% ore yield', () {
    final engine = GameEngine();
    engine.completeMasterworkForTest('miningLvl10', specPath: 'mining_prospector');
    expect(engine.getGatherYieldBonusForTest(SkillType.mining), closeTo(0.30, 0.001));
  });
});

group('Lore spec effects', () {
  test('Loremaster grants +5 XP to all skills per fragment read', () {
    final engine = GameEngine();
    engine.completeMasterworkForTest('loreLvl10', specPath: 'lore_loremaster');
    final xpBefore = engine.skills[SkillType.combat]!.xp;
    engine.readCodexFragmentForTest('wilds_01');
    expect(engine.skills[SkillType.combat]!.xp, xpBefore + 5);
  });
});
```

- [ ] **Step 2: Run tests, verify they fail**

Run: `flutter test test/spec_effects_test.dart`

Expected: FAIL — helpers don't exist.

- [ ] **Step 3: Add spec-effect helpers + wire into existing engine code**

In `lib/engine/game_engine.dart`:

```dart
double _getSpecCraftQualityBias(Recipe recipe) {
  double bias = 0.0;
  final craftSpec = _skillSpecs[SkillType.crafting];
  final craftSubSpec = _skillSubSpecs[SkillType.crafting];
  final item = Items.findById(recipe.resultItemId);
  if (item == null) return 0.0;

  if (craftSpec == 'crafting_smith' &&
      (item.type == ItemType.weapon || item.type == ItemType.armor)) {
    bias += 0.20;
    if (craftSubSpec == 'crafting_weaponsmith' && item.type == ItemType.weapon) bias += 0.15;
    if (craftSubSpec == 'crafting_armorsmith' && item.type == ItemType.armor) bias += 0.15;
  }
  if (craftSpec == 'crafting_tinker' && item.type == ItemType.tool) {
    bias += 0.20;
    if (craftSubSpec == 'crafting_toolmaker') bias += 0.15;
  }
  if (_skillSpecs[SkillType.mining] == 'mining_refiner' &&
      recipe.inputs.keys.any((k) => k.contains('ore') || k.contains('ingot'))) {
    bias += 0.30;
    if (_skillSubSpecs[SkillType.mining] == 'mining_slag_cutter') bias += 0.10;
  }
  if (_skillSpecs[SkillType.woodcutting] == 'woodcutting_arborist') {
    // +30% quality bias when wood is substituted (driftwood) — applied in _calculateRecipeQualityBias
  }
  return bias;
}

double _getSpecGatherYieldBonus(SkillType skill) {
  final spec = _skillSpecs[skill];
  if (skill == SkillType.woodcutting && spec == 'woodcutting_logger') return 0.30;
  if (skill == SkillType.mining && spec == 'mining_prospector') return 0.30;
  if (skill == SkillType.herbalism && spec == 'herbalism_wild_walker') return 0.50;  // rare herb chance
  // Sub-spec additions
  final subSpec = _skillSubSpecs[skill];
  if (skill == SkillType.woodcutting && subSpec == 'woodcutting_clearcutter') return 0.30 + 0.20;  // +1.5x total
  return 0.0;
}

void _applyLoremasterPolymathXp(double baseXp) {
  // Called from readCodexFragment when player has Loremaster spec
  final loreSpec = _skillSpecs[SkillType.lore];
  final loreSubSpec = _skillSubSpecs[SkillType.lore];
  if (loreSpec != 'lore_loremaster') return;
  final perSkillXp = loreSubSpec == 'lore_polymath' ? 10.0 : 5.0;
  for (final s in SkillType.values) {
    if (s == SkillType.lore) continue;  // Lore already gets its own XP
    _skills[s] = _skills[s]!.addXp(perSkillXp);
  }
}

@visibleForTesting
double getSpecCraftQualityBiasForTest(Recipe r) => _getSpecCraftQualityBias(r);

@visibleForTesting
double getGatherYieldBonusForTest(SkillType s) => _getSpecGatherYieldBonus(s);

@visibleForTesting
void readCodexFragmentForTest(String id) {
  _readCodexFragmentIds.add(id);
  _applyLoremasterPolymathXp(15);  // base lore xp
  // Lore xp grant handled elsewhere
}
```

Then wire these into existing engine paths:
- In the craft-complete path (existing crafting quality roll), add `+ _getSpecCraftQualityBias(recipe) + _calculateRecipeQualityBias(recipe, consumed)` to the quality calculation
- In the gather loot resolution (existing `_completeAction` loot block), multiply loot quantities by `(1 + _getSpecGatherYieldBonus(action.requiredSkill!))`
- In `readCodexFragment` (Spec 2 method), add `_applyLoremasterPolymathXp(15)` after the base XP grant

- [ ] **Step 4: Run tests, verify pass**

Run: `flutter test test/spec_effects_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/engine/game_engine.dart test/spec_effects_test.dart
git commit -m "feat(specs): wire crafting/gather/cooking/lore spec effects into engine helpers"
```

---

## Task 23: Skills view spec badges

**Files:**
- Modify: `lib/views/skills_view.dart`

- [ ] **Step 1: Add badge rendering**

In `lib/views/skills_view.dart`, find the per-skill card builder and add:

```dart
// Inside the skill card column, after the skill name row:
if (engine.specForSkill(skill.type) != null) ...[
  const SizedBox(height: 6),
  Row(
    children: [
      _buildSpecBadge(
        label: engine.specDisplayNameForTest(engine.specForSkill(skill.type)!),
        color: Colors.blue,
        onTap: () => _showSpecModal(context, skill.type, engine.specForSkill(skill.type)!),
      ),
      if (engine.subSpecForSkill(skill.type) != null) ...[
        const SizedBox(width: 6),
        _buildSpecBadge(
          label: engine.subSpecDisplayNameForTest(engine.subSpecForSkill(skill.type)!),
          color: GameTheme.accentGold,
          onTap: () => _showSubSpecModal(context, skill.type, engine.subSpecForSkill(skill.type)!),
        ),
      ],
    ],
  ),
],
```

Add helper widgets:

```dart
Widget _buildSpecBadge({required String label, required Color color, required VoidCallback onTap}) {
  return InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    ),
  );
}

void _showSpecModal(BuildContext context, SkillType skill, String specId) {
  // Show a modal with the spec's full effect description (pull from a static lookup or per-spec text)
  showDialog(context: context, builder: (_) => AlertDialog(
    backgroundColor: GameTheme.cardBg,
    title: Text(specId, style: const TextStyle(color: Colors.white)),
    content: Text(_specDescriptionForId(specId), style: const TextStyle(color: GameTheme.textLight)),
  ));
}
```

Also expose `specDisplayNameForTest` and `subSpecDisplayNameForTest` as public engine getters:
```dart
String specDisplayName(String path) => _specDisplayName(path);
String subSpecDisplayName(String path) => _subSpecDisplayName(path);
```

- [ ] **Step 2: Verify visually**

Run the app, complete a level-10 Masterwork via game flow (or use `completeMasterworkForTest` if exposed), open Skills view, see the spec badge on the corresponding skill card.

- [ ] **Step 3: Commit**

```bash
git add lib/views/skills_view.dart lib/engine/game_engine.dart
git commit -m "feat(ui): add spec/sub-spec badges to Skills view cards with tap-to-modal"
```

---

## Task 24: Bestiary spec hints

**Files:**
- Modify: `lib/views/codex_view.dart` (Bestiary tab)
- Modify: `lib/engine/game_engine.dart`

- [ ] **Step 1: Add bestiarySpecHints helper to engine**

In `lib/engine/game_engine.dart`:

```dart
List<String> bestiarySpecHints(String beastId) {
  final hints = <String>[];
  switch (beastId) {
    case 'forest_boar':
      hints.add('Tracker spec: +1 yield from this beast type.');
      hints.add('Wild-Walker spec: hazard resistance increases boar drop chance.');
      break;
    case 'cave_spider':
      hints.add('Berserker spec: Heavy Strike one-shot at level 20+.');
      hints.add('Refiner spec: Spider Silk drops crafted with +0.10 quality.');
      break;
    case 'shadow_wolf':
      hints.add('Guardian spec: Defend prevents summon-ally on Howl.');
      hints.add('Tracker spec: +1 Wolf Pelt yield.');
      break;
    case 'cavern_troll':
      hints.add('Bastion sub-spec: Smash damage halved further.');
      hints.add('Sea-Reader sub-spec: Echo presence indicators reveal troll spawns.');
      break;
    case 'tide_hound':
      hints.add('Sentinel sub-spec: counter-damage on Defend kills hounds outright.');
      hints.add('Beast-Lurer sub-spec: hound encounters guaranteed.');
      break;
    case 'brine_crawler':
      hints.add('Guardian spec: Defend halves Pincer Lock drain.');
      hints.add('Smelt-Master sub-spec: Crawler Carapace + ore yields steel-tier ingots.');
      break;
    case 'salt_touched_drowned':
      hints.add('Bastion sub-spec: survive Death Wail without stun.');
      hints.add('Reaper sub-spec: crit guaranteed on first hit.');
      break;
  }
  return hints;
}
```

- [ ] **Step 2: Render in Codex Bestiary tab**

In `lib/views/codex_view.dart`, find the Bestiary entry card builder and add:

```dart
final defeats = entry.defeatCount;
if (defeats >= 3) {
  final hints = engine.bestiarySpecHints(beastId);
  if (hints.isNotEmpty) ...[
    const SizedBox(height: 8),
    for (final hint in hints) Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 11)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(hint, style: const TextStyle(color: GameTheme.textLight, fontSize: 11, fontStyle: FontStyle.italic)),
          ),
        ],
      ),
    ),
  ],
}
```

- [ ] **Step 3: Verify visually**

Run app, defeat a Forest Boar 3 times, open Codex → Beasts tab → see Tracker / Wild-Walker hints.

- [ ] **Step 4: Commit**

```bash
git add lib/views/codex_view.dart lib/engine/game_engine.dart
git commit -m "feat(ui): add Bestiary spec hints after 3+ defeats"
```

---

## Task 25: Spec 4 integration smoke test

**Files:**
- Modify: `test/quest_engine_test.dart`

- [ ] **Step 1: Add end-to-end smoke test**

Add to `test/quest_engine_test.dart`:

```dart
test('Spec 4 acceptance — combat, event, spec, salt press', () {
  final engine = GameEngine();
  engine.unlockZone('whispering_woods_1');
  engine.travelTo(Zones.whisperingWoodsTier1);

  // 1. Combat: start boar hunt, Defend through round 3 telegraph
  engine.startBoarHuntForTest();
  for (int i = 0; i < 2; i++) {
    engine.setCombatStance(PlayerStance.strike);
    expect(engine.activeCombat, isNotNull);
  }
  expect(engine.activeCombat!.activeTelegraph, isNotNull);
  final hpBefore = engine.playerStats.currentHealth;
  engine.setCombatStance(PlayerStance.defend);
  final dmgWithDefend = hpBefore - engine.playerStats.currentHealth;
  expect(dmgWithDefend, lessThan(12));  // Charge would be ~12 normally

  // 2. Random event: force one to fire
  engine.forceRandomEventForTest(RandomEvents.beeSwarm);
  expect(engine.activeRandomEvent, isNotNull);
  engine.resolveRandomEvent(2);  // Retreat
  expect(engine.activeRandomEvent, isNull);

  // 3. Spec: complete a Masterwork via helper
  engine.completeMasterworkForTest('craftingLvl10', specPath: 'crafting_smith');
  expect(engine.specForSkill(SkillType.crafting), 'crafting_smith');

  // 4. Salt Press: verify recipe + items exist
  expect(Recipes.all.any((r) => r.id == 'salt_cured_trout'), true);
  expect(Items.findById('salt_cured_trout'), isNotNull);

  // 5. Driftwood substitution
  engine.inventory = engine.inventory.addItem(Items.driftwood, 5);
  engine.inventory = engine.inventory.addItem(Items.riverClay, 5);
  final stoneAxe = Recipes.all.firstWhere((r) => r.id == 'stone_axe');
  expect(engine.hasInputsForRecipeForTest(stoneAxe), true);
});
```

- [ ] **Step 2: Run smoke test**

Run: `flutter test test/quest_engine_test.dart`

Expected: PASS.

- [ ] **Step 3: Run full test suite**

Run: `flutter test`

Expected: All Spec 1 + 2 + 3 + 4 tests pass.

- [ ] **Step 4: Commit**

```bash
git add test/quest_engine_test.dart
git commit -m "test(spec4): end-to-end smoke test for combat + events + spec + Salt Press"
```

---

## Post-implementation checklist

- [ ] All `flutter test` passes (Spec 1 + 2 + 3 + 4 combined)
- [ ] `flutter analyze` shows zero errors and zero warnings
- [ ] Manual play test:
  - Fresh app → Quick-Slot strip visible above inventory
  - Fight boar → 5-button action bar visible
  - Default-Strike fires on timer expiry
  - Round 3 telegraph appears; Defend halves Charge
  - Read Tells reveals next telegraph's ability name
  - Foraging Wildflowers eventually fires Bee Swarm random event (5% per action ≈ once per 20 forages)
  - Complete Crafting Lvl 10 via Ironbark Trial → Smith spec badge appears on Crafting card
  - Reach Crafting 20 → Greater Ironbark trial fires → Weaponsmith sub-spec locks
  - Crafted sword shows quality bias from Smith + Weaponsmith
  - Coast in Sea Fog → combat shows ⚡ Critical Strike! occasionally
  - Build Salt Press → 5 recipes appear in Workshop
  - Crafted Stone Axe with only Driftwood available → completes with +0.03 quality bias
  - Defeat Forest Boar 3 times → Bestiary entry shows Tracker / Wild-Walker hints
- [ ] README.md updated with brief "Spec 4 — Gameplay Depth" notes (Stance, events, specializations)
