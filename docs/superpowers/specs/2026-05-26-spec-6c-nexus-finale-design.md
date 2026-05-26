# Spec 6c — Nexus Finale

**Date:** 2026-05-26
**Status:** Approved (pending spec review)
**Parent:** [Echoes from the Deep umbrella vision](2026-05-24-echoes-from-the-deep-vision.md)
**Companion specs:** [6a Living Economy](2026-05-25-spec-6a-living-economy-design.md), [6b Achievements, Titles & Player XP](2026-05-26-spec-6b-achievements-titles-player-xp-design.md)
**Depends on:** Specs 1–5 (all assumed implemented). 7a primitives (`GameCard`, `GameButton`, `FloatingNotification`) used in the You-Win modal. 6b's `Achievements.all` registry + `AchievementEngine` for the `source_cleansed` entry (6c degrades gracefully if 6b not yet shipped — see §5.3).
**Scope:** Third and final mini-spec decomposed from the umbrella's Spec 6. Ships the capstone: Nexus of Echoes zone, The Source 3-phase final boss with new combat mechanics, Source Convergence quest completion, a You-Win screen on victory (no credits sequence), and a Free Mode state with a permanent "Source Cleanser" title override + 3 endgame ambient log entries. NG+ is deferred until save persistence ships.

---

## 1. Goals & Acceptance Criteria

### 1.1 What 6c ships

1. **Nexus of Echoes zone** — single new zone, visibility gated on `nexus_unlockable` flag (set by Spec 5's `_onCleansingComplete` when all 3 breaches cleansed) + holding all 3 Cleansing Tokens in inventory. Zone has only one action: `confront_the_source`.

2. **The Source — 3-phase final boss** — new Beast `the_source`, ~1100 HP total split 374/363/363 across phases at HP thresholds 0.66 and 0.33. Phases share Wilds/Stone/Tide visual theming but introduce new combat mechanics never seen on the Echoes:
   - **P1 Verdant — Quake:** every 3rd round, player loses 10 energy (telegraphed 1 round prior in log)
   - **P2 Stoneflesh — Sediment Stack:** each successful player hit adds 1 sediment stack; at 3 stacks, the next player attack deals 0 damage and consumes all 3 stacks
   - **P3 Drowning — Pollen Cloud:** every other round, the player's chosen stance is randomized to one of the other 3 stances for that one round

3. **Source Convergence quest completion** — quest already exists ([main_quests.dart:172](../../lib/models/main_quests.dart#L172)) with two `comingSoon: true` objectives (visit `nexus_of_echoes`, custom `source_defeated`). 6c clears the `comingSoon` flags + advances the objectives at the right engine moments.

4. **Token consumption** — 3 Cleansing Tokens stay in inventory through every loss; consumed only on the winning attempt as part of the cleansing-the-Source narrative log beat. Fight is freely re-attemptable.

5. **You-Win screen** — full-screen modal on Source defeat. Large title "You Win", a one-sentence flavor line, single Continue button. No credits sequence. Dismiss returns to Free Mode dashboard.

6. **Free Mode** — purely an unlocked state, no mode toggle:
   - `source_cleanser` engine flag set on victory (in-session)
   - While flag is set, `PlayerStats.title` is overridden to `"Source Cleanser"` regardless of skill-derived title (6b's `TitleResolver` recompute is bypassed by a guard at the top of `_recomputeTitle`)
   - 3 new endgame ambient log entries fire post-victory: NPCs reference the victory in passing
   - Player keeps their world, can keep grinding, finishing optional achievements
   - 1 new achievement `source_cleansed` (added to 6b's Mastery category — fires on victory)

### 1.2 What 6c does NOT do

- NG+ (deferred until save persistence ships)
- Credits sequence (replaced with You-Win screen)
- Multi-screen narrative epilogue
- True Ending epilogue from Old Empire puzzle (umbrella vision mentions it; separate brainstorm)
- Audio
- Save persistence
- New zones beyond the Nexus
- New items beyond the Tokens being consumed
- New merchants, recipes, or daily-task templates

### 1.3 Acceptance criteria

A player after 6c ships:

1. After cleansing all 3 breaches and holding all 3 Cleansing Tokens, the Nexus of Echoes appears in the travel menu (was hidden before).
2. Travel to Nexus → only action visible is `confront_the_source`. First travel fires the `nexus_first_visit` major milestone and advances the Source Convergence visit objective.
3. Combat with The Source has 3 distinguishable phases with new mechanics not in the Echo fights (Quake / Sediment Stack / Pollen Cloud).
4. Losing the fight returns the player to Town Square with Tokens intact; can retry by traveling back to Nexus.
5. Winning the fight: consumes all 3 Tokens, fires You-Win modal, sets `source_cleanser` flag, completes `main_source_convergence` quest, grants `source_cleansed` achievement, fires `source_defeated` major milestone.
6. Post-victory, dashboard title shows "Source Cleanser" regardless of skill rankings.
7. Post-victory, 3 new ambient log entries fire over time (one per Town Square visit / merchant visit / first overworld action), each dedup'd to fire once per session.
8. Reset clears the You-Win modal flag, the ambient-fired set, the `source_cleanser` flag, and re-derives the auto-skill title.

### 1.4 Design principles inherited

- **No art** — single-emoji icons; UI built from Spec 7a primitives.
- **No dual-emoji icons** — The Source uses 👁️ (single glyph). The `source_cleansed` achievement also uses 👁️.
- **Progressive discovery** — Nexus zone hidden until earned; You-Win modal only fires after Source defeated; Source Cleanser title only after victory; the `source_cleansed` achievement entry is visible (Mastery category) only after unlock per 6b's locked-entry-as-`❔ ???` rule, and even then its description is itself a soft spoiler — the player has already seen You-Win by the time they read it.
- **Systems converse** — Source phases reuse Spec 5's `EchoPhase` / `BeastPassive` infrastructure with new passive enum values; quest completion reuses Spec 1's `_maybeCompleteQuest`; achievement unlock reuses Spec 6b's `AchievementEngine`; title override reuses Spec 6b's `_recomputeTitle` hook; You-Win modal reuses 7a primitives.

---

## 2. Nexus Zone & Quest Wiring

### 2.1 Nexus of Echoes zone

```dart
// lib/models/zone.dart — add to Zones.all
static final Zone nexusOfEchoes = Zone(
  id: 'nexus_of_echoes',
  name: 'Nexus of Echoes',
  description: 'A still chamber beneath the world. Three lights — green, grey, blue — hang in the air, waiting to be answered. Something larger waits behind them.',
  icon: '🌀',
  ambientColor: Colors.deepPurple,
  actions: [
    ZoneAction(
      id: 'confront_the_source',
      name: 'Confront the Source',
      description: 'Step into the convergence and call the Source forth. Your three Tokens hum in answer.',
      durationSeconds: 4,
      energyCost: 15,
      isCombat: true,
      combatBeastId: 'the_source',
      requiredSkill: SkillType.combat,
      requiredLevel: 1,
      xpReward: 0,                 // XP comes from combat resolution, not action completion
      lootTable: [],               // boss loot handled in custom victory branch
    ),
  ],
);
```

### 2.2 Zone visibility gating

Two-condition gate (both must be true):

```dart
// In GameEngine — extend the zone-visibility helper that powers the travel menu
bool isZoneUnlocked(Zone z) {
  // ... existing per-zone gating ...
  if (z.id == 'nexus_of_echoes') {
    return _engineFlags.contains('nexus_unlockable')      // Spec 5 sets this
        && _inventory.hasItem('wilds_cleansing_token', 1)
        && _inventory.hasItem('stone_cleansing_token', 1)
        && _inventory.hasItem('tide_cleansing_token', 1);
  }
  // ... rest ...
}
```

Spec 5 already grants Cleansing Tokens via `_onCleansingComplete` and sets `nexus_unlockable` only when all three breach flags are set, so in practice the two conditions reach truth at the same moment. The inventory check is defensive — guards against the impossible-in-practice state of having cleansed without holding the tokens.

### 2.3 Source Convergence quest objective advancement

The quest already exists with two `comingSoon: true` objectives:

```dart
QuestObjective(kind: ObjectiveKind.visit,   targetId: 'nexus_of_echoes', targetCount: 1, comingSoon: true),
QuestObjective(kind: ObjectiveKind.custom,  targetId: 'source_defeated', targetCount: 1, comingSoon: true),
```

Two advancement points wired in `GameEngine`:

**On first travel to Nexus** — extend `travelTo`:

```dart
void travelTo(Zone zone) {
  // ... existing logic ...
  if (zone.id == 'nexus_of_echoes') {
    _advanceQuestObjective('main_source_convergence', ObjectiveKind.visit, 'nexus_of_echoes');
  }
}

void _advanceQuestObjective(String questId, ObjectiveKind kind, String targetId) {
  for (final quest in _activeQuests) {
    if (quest.id != questId) continue;
    for (final obj in quest.objectives) {
      if (obj.kind == kind && obj.targetId == targetId && obj.comingSoon) {
        obj.currentCount = obj.targetCount;
        obj.comingSoon = false;
      }
    }
    _maybeCompleteQuest(quest);
  }
}
```

**On Source defeat** — the victory handler (§3.6) calls:

```dart
_advanceQuestObjective('main_source_convergence', ObjectiveKind.custom, 'source_defeated');
```

When both objectives complete, `_maybeCompleteQuest` fires the quest's reward pipeline. Since the quest currently has empty `rewards: const []`, the completion logs a quest-complete line and emits `AchievementEvent.questComplete('main_source_convergence')` (if 6b is shipped). The narrative payload of "winning" lives in the You-Win modal (§4), not in quest rewards.

### 2.4 Nexus arrival milestone

New milestone added to `Milestones.all`:

| Milestone id | Trigger | Severity | Body |
|---|---|---|---|
| `nexus_first_visit` | First `travelTo` with `zone.id == 'nexus_of_echoes'` | major | *"You step into the Nexus. The air is colder here, and it remembers everything. The Source is listening."* |

Fires once per session (dedup via existing `_firedMilestoneIds`).

### 2.5 Touch summary for §2

| File | Change |
|---|---|
| [lib/models/zone.dart](../../lib/models/zone.dart) | Add `nexusOfEchoes` zone + register in `Zones.all` |
| [lib/engine/game_engine.dart](../../lib/engine/game_engine.dart) | Extend `isZoneUnlocked` for Nexus; add `_advanceQuestObjective` helper; extend `travelTo` to advance visit objective + fire `nexus_first_visit` milestone |
| [lib/models/milestone.dart](../../lib/models/milestone.dart) | Add `nexus_first_visit` milestone |

---

## 3. The Source — Beast Model & Phase Mechanics

### 3.1 Beast definition

```dart
// lib/models/beast.dart — extend Beasts.all
static final Beast theSource = Beast(
  id: 'the_source',
  name: 'The Source',
  icon: '👁️',
  maxHealth: 1100,
  baseAttack: 18,
  baseDefense: 8,
  xpReward: 1500,
  goldReward: 0,
  lootTable: [],                       // no item drops — Tokens & narrative handle the payoff
  weaknessHint: null,                  // intentionally weakness-less; player can't 'cheese' the finale
  phases: [
    EchoPhase(
      index: 0,
      hpThreshold: 1.00,
      entryNarration: 'The chamber dims. Green light blooms around you. The Source wears the Wilds\' face — and it remembers being broken.',
      passive: BeastPassive.sourceQuake,
    ),
    EchoPhase(
      index: 1,
      hpThreshold: 0.66,
      entryNarration: 'The green light hardens to grey. Stone-flesh closes over the wound you dealt. The Source wears a colder face now.',
      passive: BeastPassive.sourceSedimentStack,
    ),
    EchoPhase(
      index: 2,
      hpThreshold: 0.33,
      entryNarration: 'Grey runs to blue. Salt-mist rises from the floor. The Source wears the Tide\'s face — and it is angry.',
      passive: BeastPassive.sourcePollenCloud,
    ),
  ],
);
```

Phase HP split with the threshold model: P1 covers 1100→726 HP (374 damage), P2 covers 726→363 (363 damage), P3 covers 363→0 (363 damage). Roughly even thirds.

### 3.2 New `BeastPassive` enum entries

`BeastPassive` already exists in Spec 5 with values for Echo passives (`healOnHit`, `damageReduction`, `reducedAccuracy`, `enrage`). 6c extends:

```dart
enum BeastPassive {
  // existing
  none,
  healOnHit,
  damageReduction,
  reducedAccuracy,
  enrage,
  // NEW for The Source
  sourceQuake,
  sourceSedimentStack,
  sourcePollenCloud,
}
```

### 3.3 P1 — Quake (energy drain on telegraphed cadence)

**Rule:** every 3rd combat round, the player loses 10 energy at the end of the round. The previous round (round N–1 of the cadence), a telegraph fires in the combat log: *"The chamber trembles — the Source is gathering for a Quake."*

**State:** `CombatState` gains `int sourceQuakeCounter` (resets to 0 on combat start). Incremented each round in `_resolveCombatRound`.

```dart
// In _resolveCombatRound, after damage resolution:
if (_combat?.activePhasePassive == BeastPassive.sourceQuake) {
  _combat!.sourceQuakeCounter += 1;
  if (_combat!.sourceQuakeCounter % 3 == 2) {
    log('The chamber trembles — the Source is gathering for a Quake.', LogType.warning);
  }
  if (_combat!.sourceQuakeCounter % 3 == 0) {
    final loss = math.min(10, _playerStats.currentEnergy);
    _playerStats = _playerStats.copyWith(currentEnergy: _playerStats.currentEnergy - loss);
    log('Quake! You lose $loss energy.', LogType.damage);
  }
}
```

**Counter-play:** none — accept the energy drain or burst through P1 fast.

### 3.4 P2 — Sediment Stack (offense limiter)

**Rule:** every successful player attack (Strike or Heavy Strike that lands non-zero damage) adds 1 sediment stack. At 3 stacks, the **next** player attack of any kind deals 0 damage and consumes all 3 stacks. The 0-damage hit still consumes the attack round (player's turn passes), and the Source still attacks back.

**State:** `CombatState` gains `int sourceSedimentStacks` (resets on combat start AND when P2 exits).

```dart
// In _resolveCombatRound, BEFORE the player damage formula:
if (_combat?.activePhasePassive == BeastPassive.sourceSedimentStack) {
  if (_combat!.sourceSedimentStacks >= 3) {
    log('Your strike sinks into sediment and finds nothing. (Stacks consumed.)', LogType.warning);
    playerDmgDealt = 0;
    _combat!.sourceSedimentStacks = 0;
  } else if (playerDmgDealt > 0 && (stance == PlayerStance.strike || stance == PlayerStance.heavyStrike)) {
    _combat!.sourceSedimentStacks += 1;
    if (_combat!.sourceSedimentStacks == 3) {
      log('Sediment thickens around the Source — your next strike will sink.', LogType.warning);
    }
  }
}
```

**Counter-play:** alternate attacks with Defend on the 3rd round to "waste" the consumption without losing a real attack.

### 3.5 P3 — Pollen Cloud (stance randomization)

**Rule:** every other round (counter % 2 == 0), the player's chosen stance is **randomized** for that one round to one of the three other stances. The log surfaces what was rolled: *"Pollen clouds your sight — your stance shifts to {randomStance}."*

**State:** `CombatState` gains `int sourcePollenCounter` (resets on combat start).

```dart
// In _resolveCombatRound, BEFORE stance-dependent damage formula:
if (_combat?.activePhasePassive == BeastPassive.sourcePollenCloud) {
  _combat!.sourcePollenCounter += 1;
  if (_combat!.sourcePollenCounter % 2 == 0) {
    final others = PlayerStance.values.where((s) => s != stance).toList();
    final rolled = others[_random.nextInt(others.length)];
    log('Pollen clouds your sight — your stance shifts to ${rolled.name}.', LogType.warning);
    stance = rolled;
  }
}
```

`_random` is the existing engine RNG (seedable for tests).

**Counter-play:** pre-select the stance you'd most regret rolling away from; on randomized rounds, accept the chaos. There's a 50% chance per round the stance changes — burst damage windows are critical.

### 3.6 Source victory handler

Spec 5's `_resolveCombat` victory branch already detects Echo beasts by id and grants Essence + logs post-fight narration. Extend with a Source case:

```dart
// In _resolveCombat victory branch:
if (beast.id == 'the_source') {
  _onSourceDefeated();
  return;
}
```

```dart
void _onSourceDefeated() {
  // 1. Consume the 3 Cleansing Tokens — narrative beat
  _inventory = _inventory.removeItem('wilds_cleansing_token', 1);
  _inventory = _inventory.removeItem('stone_cleansing_token', 1);
  _inventory = _inventory.removeItem('tide_cleansing_token', 1);

  // 2. Advance the quest's custom 'source_defeated' objective
  _advanceQuestObjective('main_source_convergence', ObjectiveKind.custom, 'source_defeated');

  // 3. Set the persistent-in-session flag
  setEngineFlag('source_cleanser');

  // 4. Emit achievement event (6b registry adds source_cleansed)
  _achievementEngine.onEvent(AchievementEvent.custom('source_defeated'));

  // 5. Post-fight log line (in addition to existing combat-victory line)
  log('The three lights fall silent. The Source is quieted.', LogType.success);

  // 6. Trigger the You-Win modal (§4)
  _pendingYouWinModal = true;
  notifyListeners();
}
```

### 3.7 Source defeat milestone

Added to `Milestones.all`:

| Milestone id | Trigger | Severity | Body |
|---|---|---|---|
| `source_defeated` | `source_cleanser` flag set | major | *"You have walked the world of Elaria, and quieted the Source. Nothing larger is listening now."* |

The same flag fires the milestone AND drives the You-Win modal + title override — single source of truth.

### 3.8 Touch summary for §3

| File | Change |
|---|---|
| [lib/models/beast.dart](../../lib/models/beast.dart) | Add `theSource` Beast in `Beasts.all`; extend `BeastPassive` with 3 new entries |
| [lib/engine/game_engine.dart](../../lib/engine/game_engine.dart) | Extend `CombatState` with `sourceQuakeCounter`, `sourceSedimentStacks`, `sourcePollenCounter`; extend `_resolveCombatRound` to apply the 3 new passives; extend `_resolveCombat` victory branch with `_onSourceDefeated`; add `_pendingYouWinModal` field |
| [lib/models/milestone.dart](../../lib/models/milestone.dart) | Add `source_defeated` milestone |

---

## 4. You-Win Modal, Title Override & Free Mode Ambience

### 4.1 You-Win modal

A new top-level overlay widget that the dashboard view watches for via the existing engine listener pattern. Shown exactly once per session — when `_pendingYouWinModal == true`.

```dart
// lib/widgets/you_win_modal.dart (new)
class YouWinModal extends StatelessWidget {
  final VoidCallback onContinue;
  const YouWinModal({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: GameCard(                          // 7a primitive
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('👁️', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 24),
              Text(
                'You Win',
                style: GameTheme.titleLarge.copyWith(
                  fontSize: 48,
                  color: GameTheme.goldAccent,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'The Source is quieted. The world breathes.',
                style: GameTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              GameButton(                         // 7a primitive
                label: 'Continue',
                onPressed: onContinue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### 4.2 Dashboard integration

[dashboard_view.dart](../../lib/views/dashboard_view.dart) gains a thin guard at the build root:

```dart
@override
Widget build(BuildContext context) {
  final engine = context.watch<GameEngine>();
  return Stack(
    children: [
      _buildExistingDashboard(context, engine),
      if (engine.shouldShowYouWinModal)
        YouWinModal(onContinue: () => engine.dismissYouWinModal()),
    ],
  );
}
```

Engine API:

```dart
bool get shouldShowYouWinModal => _pendingYouWinModal;

void dismissYouWinModal() {
  _pendingYouWinModal = false;
  playSfx('ui_modal_dismiss');
  notifyListeners();
}
```

The flag is **session-scoped, not persistent** — if the player wins, dismisses the modal, then resets the game, the modal won't re-fire on the next session unless they win again. Matches the no-persistence posture and "fires once per victory" semantics.

### 4.3 Title override

In Spec 6b's `_recomputeTitle`, add a single guard at the top:

```dart
void _recomputeTitle() {
  // 6c: Source Cleanser overrides the auto-derived title while flag is set
  if (_engineFlags.contains('source_cleanser')) {
    if (_playerStats.title != 'Source Cleanser') {
      _playerStats = _playerStats.copyWith(title: 'Source Cleanser');
      notifyListeners();
    }
    return;
  }

  final newTitle = TitleResolver.resolve(_skills);
  if (_playerStats.title != newTitle) {
    _playerStats = _playerStats.copyWith(title: newTitle);
    notifyListeners();
  }
}
```

The override is **permanent for the rest of the session** — there's no toggle to revert. The flag clears on `resetGame()`, which re-derives the auto title on the next `_grantSkillXp` call.

### 4.4 Free Mode ambient log entries

3 new ambient log entries fire post-victory, one per qualifying engine event. Each fires once per session, dedup'd via an `_endgameAmbientFired` set on the engine.

| Trigger condition | Log line | LogType |
|---|---|---|
| First travel to `town_square` after `source_cleanser` set | *"The cartographer raises his cup as you pass. 'You did this,' he says. He does not name what 'this' is."* | info |
| First time visiting any merchant after `source_cleanser` set | *"The shopkeeper hesitates before naming a price. 'For the one who quieted the Source,' they say. 'On the house, this time.'"* (cosmetic flavor — no actual discount; the line is the reward) | info |
| First `_completeAction` after `source_cleanser` set where action's zone is NOT `town_square` | *"The light is different now. You notice it without being able to say how. The road feels longer in a quieter way."* | info |

```dart
// New helper in GameEngine
void _maybeFireEndgameAmbient(String tag, String line) {
  if (!_engineFlags.contains('source_cleanser')) return;
  if (_endgameAmbientFired.contains(tag)) return;
  _endgameAmbientFired.add(tag);
  log(line, LogType.info);
}
```

Three calls inserted at the named sites. Quiet, sparse, never spam — matches the project's progressive-discovery sensibility.

### 4.5 `source_cleansed` achievement (extends 6b registry)

6c adds one new achievement to 6b's registry — placed in 6b's existing Mastery category (avoids expanding categories for a single entry):

```dart
const Achievement(
  id: 'source_cleansed',
  name: 'Source Cleanser',
  description: 'You walked the world and quieted the Source.',
  icon: '👁️',
  category: AchievementCategory.mastery,
  trigger: AchievementTrigger.custom,
  criteria: {'key': 'source_defeated'},
)
```

Mastery becomes 7 entries instead of 6 (the rule is "≥1 visible, ≤many"). 6b's `test/achievement_registry_test.dart` will need the `Achievements.all.length` assertion bumped to 41 when 6c lands.

The achievement only matters for completionists — by the time it earns, the player has already seen the You-Win modal, so it's a small Codex footnote, not a surprise.

### 4.6 Reset behavior

`resetGame` clears:
- `_pendingYouWinModal = false`
- `_endgameAmbientFired.clear()`
- `_engineFlags.remove('source_cleanser')` (along with all other engine flags it already clears)

Title recompute on first post-reset `_grantSkillXp` returns to "Wayfarer" automatically.

### 4.7 Touch summary for §4

| File | Change |
|---|---|
| `lib/widgets/you_win_modal.dart` (new) | New full-screen You-Win overlay widget using 7a primitives |
| [lib/views/dashboard_view.dart](../../lib/views/dashboard_view.dart) | Wrap dashboard body in `Stack` with conditional `YouWinModal` |
| [lib/engine/game_engine.dart](../../lib/engine/game_engine.dart) | Add `_pendingYouWinModal`, `_endgameAmbientFired`; add `shouldShowYouWinModal` getter + `dismissYouWinModal` setter; extend `_recomputeTitle` with `source_cleanser` guard; add `_maybeFireEndgameAmbient`; call at the 3 trigger sites; extend `resetGame` to clear all new state |
| 6b's `Achievements.all` registry | Add `source_cleansed` Mastery entry |
| 6b's `test/achievement_registry_test.dart` | Bump `Achievements.all.length` assertion from 40 → 41 |

---

## 5. Testing, Implementation Order & Rollout

### 5.1 Test strategy

**`test/nexus_zone_test.dart` (new)**
- `isZoneUnlocked(nexusOfEchoes)` returns false when `nexus_unlockable` flag absent
- Returns false when flag set but any one Token missing
- Returns true when flag set AND all 3 Tokens in inventory
- `nexusOfEchoes.actions` contains exactly `confront_the_source`
- `nexus_first_visit` milestone fires on first travel; doesn't re-fire on second travel
- Travel to Nexus advances `main_source_convergence` visit objective (was `comingSoon: true`)

**`test/source_combat_test.dart` (new)**
- `Beasts.theSource` exists with `maxHealth: 1100` and 3 phases
- Phase 2 activates at exactly `hpPct <= 0.66`, phase 3 at `hpPct <= 0.33`
- Each phase entry narration emits to combat log on transition
- The 3 new `BeastPassive` enum entries exist (sourceQuake, sourceSedimentStack, sourcePollenCloud)

**`test/source_quake_test.dart` (new)**
- `sourceQuakeCounter` starts at 0 on combat start
- Round 2 (counter==2): telegraph log line fires
- Round 3 (counter==3): player loses 10 energy
- Round 6: second drain fires; round 9: third
- Drain clamped to current energy (player at 5 energy loses only 5, not 10)
- Quake does not apply when phase passive is not `sourceQuake` (P1 only)

**`test/source_sediment_test.dart` (new)**
- `sourceSedimentStacks` starts at 0; resets on combat start
- Successful Strike adds 1 stack; successful Heavy Strike adds 1 stack
- Defend / failed attacks do NOT add stacks
- At exactly 3 stacks, next attack deals 0 damage AND consumes all 3
- After consumption, stack count is 0 (cycle resumes)
- Stacks NOT applied during P1 (phase passive guard)
- Stacks reset to 0 when P2 → P3 transition fires

**`test/source_pollen_test.dart` (new)**
- `sourcePollenCounter` starts at 0
- Counter increments per round during P3
- Even rounds (2, 4, 6) randomize stance to one of the other 3 stances (not the chosen)
- Odd rounds (1, 3, 5) use the player's chosen stance unchanged
- Stance randomization uses engine `_random` (seedable — test seeds for deterministic check)
- Pollen does NOT apply during P1/P2

**`test/source_victory_test.dart` (new)**
- `_onSourceDefeated` consumes all 3 Cleansing Tokens from inventory
- `_onSourceDefeated` sets `source_cleanser` engine flag
- Quest `main_source_convergence`'s custom objective advances; quest completes
- `AchievementEvent.custom('source_defeated')` emitted; `source_cleansed` unlocks
- `_pendingYouWinModal` becomes true
- `source_defeated` milestone fires
- `removeItem` is a no-op safety check on already-empty Token slots (defensive)

**`test/you_win_modal_test.dart` (new — widget test)**
- Modal renders with "You Win" title, 👁️ icon, "Source is quieted" flavor, Continue button
- Tapping Continue calls `dismissYouWinModal` → `shouldShowYouWinModal` becomes false
- Modal not rendered when `shouldShowYouWinModal == false`

**`test/title_override_test.dart` (new)**
- Title resolves to skill-derived value when `source_cleanser` flag absent
- Title resolves to literal "Source Cleanser" when flag set, regardless of skill levels
- `resetGame` clears flag → next `_grantSkillXp` re-derives skill title

**`test/endgame_ambient_test.dart` (new)**
- Ambient log entries do NOT fire when `source_cleanser` absent
- First `townSquare` travel post-victory fires the cartographer line; second travel does not
- First merchant visit post-victory fires the shopkeeper line; second does not
- First non-town overworld action post-victory fires the road line; second does not
- `_endgameAmbientFired` set cleared on reset

**Integration smoke (extend `test/quest_engine_test.dart`)**

```dart
test('Spec 6c acceptance — Source victory closes the convergence arc', () {
  final engine = GameEngine(seed: 42);

  // Bootstrap: cleanse all 3 breaches via test helpers (sets nexus_unlockable, grants 3 Tokens)
  engine.cleanseAllBreachesForTest();
  expect(engine.engineFlags.contains('nexus_unlockable'), true);
  expect(engine.inventory.hasItem('wilds_cleansing_token', 1), true);

  // Nexus is now unlocked
  expect(engine.isZoneUnlocked(Zones.nexusOfEchoes), true);

  // Travel to Nexus → milestone + quest visit objective advances
  engine.travelTo(Zones.nexusOfEchoes);
  expect(engine.firedMilestoneIdsForTest, contains('nexus_first_visit'));

  // Defeat Source via test helper (runs the 3-phase fight to victory)
  engine.runCombatToVictoryForTest('the_source');

  // Post-victory state
  expect(engine.engineFlags.contains('source_cleanser'), true);
  expect(engine.shouldShowYouWinModal, true);
  expect(engine.inventory.hasItem('wilds_cleansing_token', 1), false);
  expect(engine.inventory.hasItem('stone_cleansing_token', 1), false);
  expect(engine.inventory.hasItem('tide_cleansing_token', 1), false);
  expect(
    engine.completedQuests.any((q) => q.id == 'main_source_convergence'),
    true,
  );
  expect(engine.achievementEngine.earned, contains('source_cleansed'));
  expect(engine.playerStats.title, 'Source Cleanser');
  expect(engine.firedMilestoneIdsForTest, contains('source_defeated'));

  // Dismiss modal
  engine.dismissYouWinModal();
  expect(engine.shouldShowYouWinModal, false);

  // First post-victory town visit fires ambient line
  engine.travelTo(Zones.townSquare);
  expect(engine.logForTest.any((e) => e.message.contains('cartographer raises his cup')), true);
});
```

### 5.2 Implementation order

Single PR, internally staged. Each step compiles.

1. **Nexus zone + visibility gate** — add `Zones.nexusOfEchoes` to [zone.dart](../../lib/models/zone.dart); extend `isZoneUnlocked` in [game_engine.dart](../../lib/engine/game_engine.dart). Add `nexus_first_visit` milestone to [milestone.dart](../../lib/models/milestone.dart). Wire `travelTo` to advance the visit objective + fire the milestone.
2. **The Source beast** — add `Beasts.theSource` with 3 phases; extend `BeastPassive` enum with 3 new entries. No mechanic wiring yet — beast is fightable but passives are inert.
3. **`CombatState` extension** — add `sourceQuakeCounter`, `sourceSedimentStacks`, `sourcePollenCounter` int fields. Initialize on combat start; reset on combat end.
4. **Quake passive** — extend `_resolveCombatRound` with the cadence check + telegraph + energy drain. Test in `source_quake_test.dart`.
5. **Sediment Stack passive** — extend `_resolveCombatRound` with the per-stack check + consumption. Reset stacks at P2 → P3 transition. Test in `source_sediment_test.dart`.
6. **Pollen Cloud passive** — extend `_resolveCombatRound` with the every-other-round stance randomization using `_random`. Test in `source_pollen_test.dart`.
7. **Source victory handler** — implement `_onSourceDefeated` in `_resolveCombat`; consume Tokens, advance quest objective, set flag, emit achievement event, log narrative, set `_pendingYouWinModal`. Add `source_defeated` milestone. Test in `source_victory_test.dart`.
8. **`source_cleansed` achievement entry** — append to 6b's `Achievements.all`; bump `test/achievement_registry_test.dart` length assertion from 40 → 41. Skip this step if 6b hasn't shipped yet (see §5.3).
9. **You-Win modal widget** — new `lib/widgets/you_win_modal.dart` using 7a primitives. Widget test.
10. **Dashboard integration** — wrap [dashboard_view.dart](../../lib/views/dashboard_view.dart) body in `Stack`; add conditional `YouWinModal`. Engine `shouldShowYouWinModal` + `dismissYouWinModal`.
11. **Title override** — add `source_cleanser` guard at top of 6b's `_recomputeTitle`. Test in `title_override_test.dart`. (If 6b not yet shipped: store the override directly in `PlayerStats.title` via a one-shot `copyWith` from `_onSourceDefeated`; later 6b integration migrates this to the recompute guard.)
12. **Endgame ambient log entries** — implement `_maybeFireEndgameAmbient` + `_endgameAmbientFired` set. Wire 3 trigger sites (Town Square travel, merchant visit, first non-town action). Test in `endgame_ambient_test.dart`.
13. **Reset wiring** — extend `resetGame` to clear `_pendingYouWinModal`, `_endgameAmbientFired`, ensure `source_cleanser` flag clears with the rest of `_engineFlags`.
14. **Integration smoke test** in `test/quest_engine_test.dart` per §5.1.

After step 14, the player can cleanse all 3 breaches → enter Nexus → fight The Source through 3 themed phases → see You-Win → continue in Free Mode with the new title and ambient flavor.

### 5.3 Migration & compatibility

No save persistence. First launch after 6c:
- Players in a fresh world progress naturally; Nexus appears in the travel menu only after all 3 cleansings.
- Players who finished the world pre-6c (i.e., cleansed all 3 breaches under Spec 5) start a new run on update — the Source fight is content-locked behind the Nexus gate so they're not handed it cold.
- **Spec 6b dependency:** the `source_cleansed` achievement entry requires 6b's `Achievements.all` registry to exist. If 6c ships before 6b: omit step 8; the achievement entry is added when 6b lands. Step 11's title override degrades to a direct `copyWith` from `_onSourceDefeated` until 6b's `_recomputeTitle` exists.
- **Spec 6a independence:** 6c works whether 6a ships or not. None of the Source fight, Nexus zone, or You-Win flow depends on durability, reagents, merchant reputation, or daily tasks.

### 5.4 Documentation updates

- README.md — append "Spec 6c — Nexus Finale" notes (Nexus gate, Source fight, Free Mode)
- Inline `///` doc comments on `_onSourceDefeated`, the 3 new `BeastPassive` branches in `_resolveCombatRound`, `_maybeFireEndgameAmbient`

### 5.5 Risks & deferrals

- **Source HP/balance is a guess.** 1100 HP across 3 phases × the 3 new passives could be too long or too short. Single-constant retune — the `maxHealth: 1100` literal is the knob. Playtest at the moment a typical post-cleansings player enters Nexus and adjust if the fight exceeds ~20 rounds or finishes under ~10.
- **Pollen Cloud's randomness can feel unfair.** A bad roll-out (3 randomizations in a row landing on Defend when the player wanted Heavy Strike) is possible. Mitigation: cadence is every-other-round, not every-round, so the player keeps half their rounds intact. The RNG is seedable so this can be tuned if playtest shows the variance is too punishing.
- **You-Win modal session-scoped only.** If the player wins, dismisses, resets, then wins again — fine, re-fires. But if they win, dismiss, and the app crashes before reset — they don't see it again on relaunch. Acceptable because no persistence exists anywhere; matches the rest of the project.
- **Title override is hard-coded.** "Source Cleanser" is a literal string in the override branch. If a later spec wants more victory titles (e.g., from Old Empire True Ending), the override needs to become a small lookup, not a single literal. YAGNI for 6c.
- **Deferred to a later spec:** NG+ (needs persistence), credits sequence (replaced with You-Win screen per user direction), True Ending epilogue from Old Empire puzzle, multi-screen narrative epilogue, post-victory bonus zone, difficulty modifier toggle.
