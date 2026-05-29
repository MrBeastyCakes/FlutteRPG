# Spec 7b-1 — Dashboard / Combat HUD / Inventory Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the layout of the three highest-touch player surfaces — Dashboard, Combat HUD, Inventory — splitting the 2384-line `dashboard_view.dart` and 2871-line `inventory_view.dart` monoliths into ~13 focused sub-widget files, and replacing the dashboard with a full-screen Combat HUD during combat.

**Architecture:** Each surface becomes a thin orchestrator (`StatelessWidget`) that delegates to focused section sub-widgets under `lib/views/dashboard/`, `lib/views/combat/`, and `lib/views/inventory/`. Sub-widgets read engine state independently via `context.watch<GameEngine>()` (no prop-drilling). Inventory filter/search/sort state lives in a view-scoped `InventoryFilterState` `ChangeNotifier`. Layout-only — no game mechanic changes.

**Tech Stack:** Flutter / Dart, Provider (`ChangeNotifierProvider`, `context.watch`), the 7a design system (`DSColors`, `DSText`, `DSSpace`, `DSRadius`, `DSMotion`) and Game* primitives (`GameCard`, `GameChip`, `GameProgressBar`, `GameAvatar`, `GameButton`, `GameSheet`, `GameInput`, `GameTooltip`).

---

## CRITICAL: API Corrections (read before writing any code)

The source design doc (`docs/superpowers/specs/2026-05-26-spec-7b-1-dashboard-combat-inventory-redesign-design.md`) contains **illustrative pseudo-code using idealized APIs that DO NOT EXIST** in this codebase. Every task below uses the **real verified APIs**. When a design snippet conflicts with a task, the task wins. The corrections:

| Design doc (WRONG) | Real API (USE THIS) |
|---|---|
| `DSColors.danger` | `DSColors.error` |
| `DSText.titleMedium` / `.titleLarge` | `DSText.headingMedium(context)` / `DSText.headingLarge(context)` |
| `DSText.labelMedium` / `.labelSmall` | `DSText.label(context)` |
| `DSText.bodyMedium` / `.bodySmall` | `DSText.bodyMedium(context)` / `DSText.bodySmall(context)` |
| `DSText.numeric` | `DSText.numeric(context)` |
| `DSSpace.xxs` | `DSSpace.xs4` (the 4px token); `DSSpace.sm8`, `DSSpace.md12`, `DSSpace.lg16`, `DSSpace.xl24` |
| `DSSpace.md` / `.sm` / `.lg` as `SizedBox(height:)` | `DSSpace.md12` / `DSSpace.sm8` / `DSSpace.lg16` (they are `double` constants) |
| `DSSpace.section` / `.card` / `.dense` (as padding) | These ARE valid `EdgeInsets` constants — keep them |
| `DSRadius.all(DSRadius.sm)` | `BorderRadius.circular(DSRadius.sm)` |
| `DSMotion.quick` | `DSMotion.fast` |
| `DSMotion.bounce` | `DSMotion.spring` |
| `GameProgressBar(value: x)` | `GameProgressBar(progress: x)` |
| `GameChip(size: small)` / `medium` | `GameChip(size: GameChipSize.sm)` / `GameChipSize.md` |
| `GameAvatar(size: 48)` | `GameAvatar(size: GameAvatarSize.md)` (sm=32, md=48, lg=64, xl=80) |
| `GameButton(leadingIcon:, onTap:)` | `GameButton(icon:, onPressed:)` |
| `GameInput(label:, leadingIcon:)` | `GameInput(hintText:, prefixIcon:)` |
| `GameTooltip(content: Widget)` | `GameTooltip(message: String, child:)` |
| `engine.weather != null` / `engine.weather` | `engine.coastWeather` returns `CoastWeatherState` (enum-backed, never null) — use existing `PulsingWeatherChip` |
| `engine.equipItem(item)` | dispatch by type: `engine.equipWeapon(...)` / `equipArmor(...)` / `equipTool(...)` |
| `engine.consumeItem(item)` | `engine.useItem(item)` (or `eatFood` / `useQuickslot(index)` in combat) |
| `combat.beastId` + `Beasts.findById(...)` | `combat.beast` (the `Beast` is embedded on `CombatState`) |
| `combat.beastHp` | `combat.beastCurrentHealth` |
| `combat.activePhaseIndex` | exists; default `-1` when no phase active |
| `beast.phases![phase].name` | `EchoPhase` has **no** `name` field — use `beast.phases![phase].ability.name` |
| `combat.roundDeadline` | exists (`DateTime?`) |
| `combat.currentRoundNumber` | exists (`int`, default 1) |
| `combat.sourceSedimentStacks` | exists (`int`, default 0) |
| `combat.activePhasePassive` | exists (`BeastPassive?`) — gate the Sediment row on this |

### Verified signatures (copy exactly)

```dart
// lib/theme/design_tokens.dart
DSColors.error, .success, .warning, .info, .goldAccent,
DSColors.healthBar, .energyBar, .xpBar,
DSColors.textPrimary, .textSecondary, .textMuted, .textDisabled,
DSColors.surface0, .borderSubtle, .borderStrong,
DSColors.skill(SkillType, [int shade]), DSColors.quality(QualityTier, [int shade]), DSColors.tag(CodexTag)
// DSText: all take BuildContext → display, headingLarge, headingMedium, headingSmall,
//   bodyLarge, bodyMedium, bodySmall, label, button, numeric
// DSSpace doubles: xs4=4, sm8=8, md12=12, lg16=16, xl24=24, xxl32=32
// DSSpace EdgeInsets: card, section, dense
// DSRadius doubles: sm4=4, md8=8, lg12=12, xl16=16, xxl20=20, pill999
// DSMotion durations: fast=120ms, standard=200ms, slow=350ms, deliberate=500ms
// DSMotion curves: easeOut, easeInOut, spring, linear

// Primitives
GameCard({Widget? child, EdgeInsets padding=DSSpace.card, double elevation=1, Color? accentColor, VoidCallback? onTap, bool visible=true})
GameProgressBar({required double progress, required Color color, Color? backgroundColor, double height=6.0, bool animated=true, String? leadingLabel, String? trailingLabel})
enum GameChipSize { sm, md, lg }
GameChip({required String label, IconData? icon, Color color=DSColors.textMuted, GameChipSize size=GameChipSize.md, bool outlined=false, VoidCallback? onTap})
enum GameAvatarSize { sm, md, lg, xl }  // 32 / 48 / 64 / 80 px
GameAvatar({String? emoji, String? label, IconData? icon, Color? ringColor, GameAvatarSize size=GameAvatarSize.md, Color? backgroundColor})
enum GameButtonVariant { primary, secondary, ghost, danger }
enum GameButtonSize { sm, md, lg }
GameButton({required String label, IconData? icon, GameButtonVariant variant=primary, GameButtonSize size=md, VoidCallback? onPressed, bool isLoading=false, bool fullWidth=false})
GameSheet.show<T>({required BuildContext context, required String title, required Widget child, Widget? trailingHeader, List<GameButton>? actions})
GameInput({TextEditingController? controller, String? hintText, String? labelText, IconData? prefixIcon, IconData? suffixIcon, bool obscureText=false, TextInputType? keyboardType, ValueChanged<String>? onChanged, FormFieldValidator<String>? validator})
GameTooltip({required String message, required Widget child, bool preferBelow=false})

// Engine (lib/engine/game_engine.dart)
CombatState? get activeCombat;                       // null when not in combat
bool get shouldShowYouWinModal;
PlayerStats get playerStats;                          // name,title,currentHealth,maxHealth,currentEnergy,maxEnergy,gold,playerLevel,playerXp
Inventory get inventory;                              // .slots → List<InventorySlot>
List<String?> get quickslots;                         // length 3, food-only ids or null
CoastWeatherState get coastWeather;                   // enum-backed, never null
Zone get currentZone;
List<LogEntry> get logs;                              // newest-first or check order in source
Map<SkillType, SkillState> get skills;
void setCombatStance(PlayerStance stance, {int? quickslotIndex});
void useQuickslot(int index);                          // in combat → setCombatStance(item, quickslotIndex)
void useItem(Item item);  void eatFood(Item item);
void equipWeapon(...); void equipArmor(...); void equipTool(...);
void unequipWeapon(); void unequipArmor(); void unequipTool(SkillType);

// CombatState: beast, beastCurrentHealth, activeTelegraph (BeastTelegraph?{abilityId,text,reveal}),
//   roundDeadline (DateTime?), currentRoundNumber (int), activePhaseIndex (int, -1 default),
//   activePhasePassive (BeastPassive?), sourceSedimentStacks (int)
// Beast: id,name,icon,maxHealth,phases (List<EchoPhase>?), ...
// EchoPhase: hpThreshold, ability (BeastAbility{name,...}), entryNarration, passive  (NO name field)
// enum PlayerStance { strike, heavyStrike, defend, readTells, item }
```

### Standing constraints (MEMORY.md — non-negotiable)

- **Emoji + Material Icons only.** No hand-drawn art assets.
- **Progressive discovery.** No "X of Y" counters that spoil unseen scope, no greyed-out future content, no placeholders. Filter chips render only for item types the player actually has (the "Quest" chip appears only once a quest item exists).
- **Single-glyph icons.** One emoji per entity; distinguish via color tint or name, never dual-emoji.

### Hard constraint: preserve smoke-test strings

`test/widget_test.dart` asserts exact strings against the live layout. The redesigned dashboard MUST still render:
- `'ELARIA RPG'` (app bar title — owned by `main.dart`/scaffold, not the dashboard body; confirm it still appears)
- `'Town Square'` (current zone name on the dashboard when in town)
- A station status chip showing `'Crafting Bench'` + `'T1'` + `'Idle'`, tapping which sets `engine.activeTabIndex == 3` (navigates to Workshop)
- `'Open Codex'` button on the dashboard

Run `flutter test test/widget_test.dart` after PR1 and after PR2 to confirm these still pass.

---

## File Structure

**PR1 — Dashboard** (`lib/views/dashboard/`)
- `player_hand_section.dart` — HP/energy/XP/name/title/level (§2.2)
- `now_playing_section.dart` — context-sensitive: active action OR zone actions OR town fixtures (§2.3)
- `world_pulse_section.dart` — zone + weather + station chips (§2.4)
- `recent_log_section.dart` — last 3 log entries + expand to 12 (§2.5)
- `dashboard_view.dart` (modify) → ~120-line orchestrator; swaps to `CombatHud` when `activeCombat != null`

**PR2 — Combat HUD** (`lib/views/combat/` + `lib/views/combat_hud.dart`)
- `combat_hud.dart` — root takeover view (§3.8)
- `combat/beast_card.dart` (§3.2), `combat/telegraph_strip.dart` (§3.3), `combat/round_timer_arc.dart` (§3.4), `combat/player_card_mini.dart` (§3.5), `combat/stance_pad.dart` (§3.6), `combat/quickslot_bar.dart` (§3.7)
- `lib/widgets/combat_action_bar.dart` (modify) → `@Deprecated`

**PR3 — Inventory** (`lib/views/inventory/`)
- `inventory_filter_state.dart` — `ChangeNotifier` for filter/search/sort (§4.4/4.6)
- `inventory_header.dart` (§4.3), `inventory_filter_bar.dart` (§4.4), `equipped_strip.dart` (§4.5), `inventory_grid.dart` (§4.6/4.10/4.11), `inventory_grid_cell.dart` (§4.7)
- `inventory_view.dart` (modify) → ~120-line orchestrator
- `lib/widgets/item_dashboard_modal.dart` (modify) → internals replaced by `GameSheet` content (§4.8)

**Tests:** `test/widgets/dashboard/*` (4), `test/widgets/combat/*` (6), `test/widgets/inventory/*` (6). Extend `test/widgets/tokens_only_test.dart` once per PR.

**Test harness pattern** (from `test/views/codex/quests_tab_test.dart`): subclass `GameEngine` to override getters, wrap the widget under test in `ChangeNotifierProvider<GameEngine>.value(value: engine, child: ...)` inside a `MaterialApp(home: Scaffold(body: ...))`. For widgets that also read `InventoryFilterState`, wrap in a `MultiProvider` (or nested providers) supplying both.

---

## PR 1 — Dashboard Split & Redesign

### Task 1: Create dashboard sub-widget stub files

**Files:**
- Create: `lib/views/dashboard/player_hand_section.dart`
- Create: `lib/views/dashboard/now_playing_section.dart`
- Create: `lib/views/dashboard/world_pulse_section.dart`
- Create: `lib/views/dashboard/recent_log_section.dart`

- [ ] **Step 1: Create four stub files so imports resolve**

Each stub is a minimal `StatelessWidget` returning `SizedBox.shrink()`. Example for `player_hand_section.dart` (repeat the same shape for the other three, renaming the class):

```dart
import 'package:flutter/material.dart';

/// Player Hand section — HP, energy, player XP, name, title, level.
/// Shown at the top of the dashboard (non-combat).
class PlayerHandSection extends StatelessWidget {
  const PlayerHandSection({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
```

Stub class names: `PlayerHandSection`, `NowPlayingSection`, `WorldPulseSection`, `RecentLogSection`.

- [ ] **Step 2: Verify the project still compiles**

Run: `flutter analyze lib/views/dashboard/`
Expected: No errors (warnings about unused imports are acceptable at this stage).

- [ ] **Step 3: Commit**

```bash
git add lib/views/dashboard/
git commit -m "feat(7b-1): scaffold dashboard section stub files"
```

---

### Task 2: PlayerHandSection

**Files:**
- Modify: `lib/views/dashboard/player_hand_section.dart`
- Test: `test/widgets/dashboard/player_hand_section_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/views/dashboard/player_hand_section.dart';

void main() {
  Widget wrap(GameEngine engine) => MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<GameEngine>.value(
            value: engine,
            child: const SingleChildScrollView(child: PlayerHandSection()),
          ),
        ),
      );

  testWidgets('renders player name, level, HP and energy values', (tester) async {
    final engine = GameEngine();
    final stats = engine.playerStats;
    await tester.pumpWidget(wrap(engine));
    await tester.pump();

    expect(find.text(stats.name), findsOneWidget);
    expect(find.text('Lvl ${stats.playerLevel}'), findsOneWidget);
    // HP and energy trailing labels appear as "current/max"
    expect(find.text('${stats.currentHealth}/${stats.maxHealth}'), findsOneWidget);
    expect(find.text('${stats.currentEnergy}/${stats.maxEnergy}'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/widgets/dashboard/player_hand_section_test.dart`
Expected: FAIL — `SizedBox.shrink()` renders none of the asserted text.

- [ ] **Step 3: Implement PlayerHandSection**

Replace the stub body. The avatar ring uses the player's highest-level skill color. XP ratio = `playerXp / PlayerProgression.xpToNextLevel(playerLevel)`.

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../engine/game_engine.dart';
import '../../models/player_progression.dart';
import '../../models/skill.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/game/game_card.dart';
import '../../widgets/game/game_avatar.dart';
import '../../widgets/game/game_progress_bar.dart';

/// Player Hand section — HP, energy, player XP, name, title, level.
/// Shown at the top of the dashboard (non-combat).
class PlayerHandSection extends StatelessWidget {
  const PlayerHandSection({super.key});

  SkillType _highestSkill(GameEngine engine) {
    SkillType best = SkillType.values.first;
    int bestLevel = -1;
    engine.skills.forEach((type, state) {
      if (state.level > bestLevel) {
        bestLevel = state.level;
        best = type;
      }
    });
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<GameEngine>();
    final stats = engine.playerStats;
    final xpToNext = PlayerProgression.xpToNextLevel(stats.playerLevel);
    final xpRatio = xpToNext > 0 ? (stats.playerXp / xpToNext).clamp(0.0, 1.0) : 0.0;
    final hpRatio = stats.maxHealth > 0 ? stats.currentHealth / stats.maxHealth : 0.0;
    final enRatio = stats.maxEnergy > 0 ? stats.currentEnergy / stats.maxEnergy : 0.0;
    final ringColor = DSColors.skill(_highestSkill(engine));

    return GameCard(
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GameAvatar(emoji: '🧙', size: GameAvatarSize.md, ringColor: ringColor),
              const SizedBox(width: DSSpace.md12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(stats.name, style: DSText.headingSmall(context)),
                    Text(
                      stats.title,
                      style: DSText.label(context).copyWith(color: DSColors.goldAccent),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Lvl ${stats.playerLevel}',
                      style: DSText.numeric(context).copyWith(color: DSColors.goldAccent)),
                  const SizedBox(height: DSSpace.xs4),
                  SizedBox(
                    width: 120,
                    child: GameProgressBar(
                      progress: xpRatio,
                      color: DSColors.xpBar,
                      height: 4,
                      trailingLabel: '${stats.playerXp}/$xpToNext XP',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: DSSpace.md12),
          GameProgressBar(
            progress: hpRatio,
            color: DSColors.healthBar,
            height: 10,
            leadingLabel: '❤',
            trailingLabel: '${stats.currentHealth}/${stats.maxHealth}',
            animated: true,
          ),
          const SizedBox(height: DSSpace.sm8),
          GameProgressBar(
            progress: enRatio,
            color: DSColors.energyBar,
            height: 10,
            leadingLabel: '⚡',
            trailingLabel: '${stats.currentEnergy}/${stats.maxEnergy}',
            animated: true,
          ),
        ],
      ),
    );
  }
}
```

> NOTE: Verify `SkillState` exposes `.level` and the `skill.dart` import path. If `SkillType`/`SkillState` live in a different file (e.g. `models/skill_type.dart`), fix the import. Confirm `DSColors.skill(SkillType)` accepts a bare `SkillType`.

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/widgets/dashboard/player_hand_section_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/views/dashboard/player_hand_section.dart test/widgets/dashboard/player_hand_section_test.dart
git commit -m "feat(7b-1): implement PlayerHandSection"
```

---

### Task 3: WorldPulseSection

**Files:**
- Modify: `lib/views/dashboard/world_pulse_section.dart`
- Test: `test/widgets/dashboard/world_pulse_section_test.dart`

- [ ] **Step 1: Inspect the current weather/station rendering**

Before writing, read `lib/widgets/pulsing_weather_chip.dart` (the existing weather chip) and `dashboard_view.dart` lines ~1715–1860 (`_buildStationStatusStrip`) to learn how the station status chip is built and how its tap navigates to Workshop (`engine.activeTabIndex = 3`). The smoke test requires a chip rendering `'Crafting Bench'` + `'T1'` + `'Idle'` whose tap sets `activeTabIndex == 3`. **Reuse that exact navigation logic** in WorldPulseSection.

Run: (no command — reading step) then proceed.

- [ ] **Step 2: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/views/dashboard/world_pulse_section.dart';

void main() {
  testWidgets('renders the current zone name as a chip', (tester) async {
    final engine = GameEngine(); // starts in Town Square
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChangeNotifierProvider<GameEngine>.value(
          value: engine,
          child: const WorldPulseSection(),
        ),
      ),
    ));
    await tester.pump();

    expect(find.textContaining('Town Square'), findsAtLeastNWidgets(1));
  });
}
```

- [ ] **Step 3: Run to verify it fails**

Run: `flutter test test/widgets/dashboard/world_pulse_section_test.dart`
Expected: FAIL — stub renders nothing.

- [ ] **Step 4: Implement WorldPulseSection**

A compact `GameCard` holding a `Wrap` of chips: zone chip (always), weather chip (reuse `PulsingWeatherChip`), station chip (only when a station is accessible in the current zone — hidden otherwise per progressive discovery). Zone chip tap opens the travel sheet (call the same path the orchestrator exposes — for now wire it to a `VoidCallback? onZoneTap` parameter defaulting to null so the orchestrator can pass `_showZoneTravelSheet`). Station chip tap sets `engine.activeTabIndex = 3` and focuses the station, mirroring the existing strip.

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../engine/game_engine.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/game/game_card.dart';
import '../../widgets/game/game_chip.dart';
import '../../widgets/pulsing_weather_chip.dart';

/// World Pulse section — compact zone + weather + station status strip.
class WorldPulseSection extends StatelessWidget {
  final VoidCallback? onZoneTap;
  const WorldPulseSection({super.key, this.onZoneTap});

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<GameEngine>();
    final zone = engine.currentZone;

    return GameCard(
      elevation: 1,
      padding: DSSpace.dense,
      child: Wrap(
        spacing: DSSpace.sm8,
        runSpacing: DSSpace.sm8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          GameChip(
            label: zone.name,
            icon: Icons.place,
            color: DSColors.info,
            size: GameChipSize.sm,
            onTap: onZoneTap,
          ),
          const PulsingWeatherChip(),
          ..._buildStationChips(context, engine),
        ],
      ),
    );
  }

  List<Widget> _buildStationChips(BuildContext context, GameEngine engine) {
    // Reuse the exact accessibility + label + tap logic from the old
    // _buildStationStatusStrip in dashboard_view.dart. A station chip renders
    // ONLY when its station is accessible in the current zone (progressive
    // discovery — never greyed). Tapping sets engine.activeTabIndex = 3 and
    // focuses the station. Build one GameChip per accessible station, e.g.:
    //
    //   GameChip(label: '${station.name}',  // "Crafting Bench"
    //            icon: Icons.handyman,
    //            color: DSColors.success,
    //            size: GameChipSize.sm,
    //            onTap: () => engine.focusStationAndOpenWorkshop(stationId));
    //
    // The chip text must include the station name, its tier ("T1"), and its
    // status ("Idle"/"Active"/etc.) so the smoke test in widget_test.dart finds
    // 'Crafting Bench', 'T1', and 'Idle'. If the old strip rendered tier/status
    // as separate Text widgets, replicate that with a small Column/Row inside
    // a GameCard chip rather than a single GameChip label.
    return const [];
  }
}
```

> IMPORTANT: The smoke test (`test/widget_test.dart`) expects `find.text('Crafting Bench')`, `find.text('T1')`, `find.text('Idle')` as **separate** Text widgets, and tapping `'Crafting Bench'` must set `activeTabIndex == 3` with `focusedStationId == null` synchronously (it asserts after a single `pump()`), then settle into the Workshop view showing `'CRAFT RECIPES'`. Port the existing `_buildStationStatusStrip` rendering faithfully — do not collapse the three strings into one. If the existing strip lives better as its own widget, render it inside WorldPulseSection unchanged.

- [ ] **Step 5: Run the section test to verify it passes**

Run: `flutter test test/widgets/dashboard/world_pulse_section_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/views/dashboard/world_pulse_section.dart test/widgets/dashboard/world_pulse_section_test.dart
git commit -m "feat(7b-1): implement WorldPulseSection"
```

---

### Task 4: RecentLogSection

**Files:**
- Modify: `lib/views/dashboard/recent_log_section.dart`
- Test: `test/widgets/dashboard/recent_log_section_test.dart`

- [ ] **Step 1: Confirm log ordering and types**

Read `lib/engine/activity_log.dart` (`LogEntry{timestamp, message, type}`, `enum LogType{info,success,warning,error,levelUp,worldEvent}`) and confirm whether `engine.logs` is newest-first. Use the appropriate slice for "last 3".

- [ ] **Step 2: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/views/dashboard/recent_log_section.dart';

void main() {
  testWidgets('shows at most 3 entries collapsed, expands on Show more', (tester) async {
    final engine = GameEngine();
    // Generate >3 log entries via a public engine method that logs.
    for (var i = 0; i < 6; i++) {
      engine.log('Test log entry $i');
    }
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChangeNotifierProvider<GameEngine>.value(
          value: engine,
          child: const SingleChildScrollView(child: RecentLogSection()),
        ),
      ),
    ));
    await tester.pump();

    // Newest 3 visible; older ones hidden until expanded.
    expect(find.textContaining('Test log entry 5'), findsOneWidget);
    expect(find.textContaining('Test log entry 0'), findsNothing);

    await tester.tap(find.text('Show more'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Test log entry 0'), findsOneWidget);
  });
}
```

> NOTE: Confirm `engine.log(String, [LogType])` is public (it is — used internally as `log(...)`). If the public signature differs, adjust the test to drive logging through a public method that appends entries.

- [ ] **Step 3: Run to verify it fails**

Run: `flutter test test/widgets/dashboard/recent_log_section_test.dart`
Expected: FAIL.

- [ ] **Step 4: Implement RecentLogSection**

Local `StatefulWidget` with an `_expanded` bool. Collapsed shows newest 3; expanded shows newest 12. Severity icon prefix + color per `LogType`.

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../engine/game_engine.dart';
import '../../engine/activity_log.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/game/game_card.dart';

/// Recent Log section — newest 3 entries; tap "Show more" to expand to 12.
class RecentLogSection extends StatefulWidget {
  const RecentLogSection({super.key});

  @override
  State<RecentLogSection> createState() => _RecentLogSectionState();
}

class _RecentLogSectionState extends State<RecentLogSection> {
  bool _expanded = false;

  ({String glyph, Color color}) _severity(LogType type) {
    switch (type) {
      case LogType.success:
      case LogType.levelUp:
        return (glyph: '✓', color: DSColors.success);
      case LogType.warning:
        return (glyph: '⚠', color: DSColors.warning);
      case LogType.error:
        return (glyph: '✗', color: DSColors.error);
      case LogType.worldEvent:
        return (glyph: '◆', color: DSColors.info);
      case LogType.info:
        return (glyph: '▸', color: DSColors.textMuted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<GameEngine>();
    // Assumes engine.logs is newest-first. If it is oldest-first, use
    // engine.logs.reversed.toList() here instead.
    final all = engine.logs;
    final limit = _expanded ? 12 : 3;
    final visible = all.take(limit).toList();

    return GameCard(
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Activity', style: DSText.label(context).copyWith(color: DSColors.textSecondary)),
              if (all.length > 3)
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Text(
                    _expanded ? 'Show less' : 'Show more',
                    style: DSText.label(context).copyWith(color: DSColors.goldAccent),
                  ),
                ),
            ],
          ),
          const SizedBox(height: DSSpace.sm8),
          if (visible.isEmpty)
            Text('No recent activity.',
                style: DSText.bodySmall(context).copyWith(color: DSColors.textMuted))
          else
            ...visible.map((e) {
              final sev = _severity(e.type);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sev.glyph, style: TextStyle(color: sev.color, fontSize: 12)),
                    const SizedBox(width: DSSpace.sm8),
                    Expanded(
                      child: Text(e.message, style: DSText.bodySmall(context)),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Run to verify it passes**

Run: `flutter test test/widgets/dashboard/recent_log_section_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/views/dashboard/recent_log_section.dart test/widgets/dashboard/recent_log_section_test.dart
git commit -m "feat(7b-1): implement RecentLogSection"
```

---

### Task 5: NowPlayingSection (3-state)

**Files:**
- Modify: `lib/views/dashboard/now_playing_section.dart`
- Test: `test/widgets/dashboard/now_playing_section_test.dart`

- [ ] **Step 1: Map the three states to engine state**

Read `dashboard_view.dart`: `_buildActiveRecipeCard` (~1046), `_buildZoneActions` (~1134), and how the view decides between an in-progress action vs. idle. Identify the engine getters for: "is an action/craft currently running" (active action state with progress + remaining time + cancel), the current zone's available actions, and town fixtures. The three states:
- **State A — Active action:** an action/craft is in progress → show its card with progress bar + remaining + Cancel.
- **State B — Idle in an action zone:** show the available-actions list for `engine.currentZone`.
- **State C — Idle in a hub/town:** show the fixtures list (Stall / Tavern / Bench — only discovered ones).

Selection precedence: A if an action is active; else C if the zone is a town/hub; else B.

- [ ] **Step 2: Write the failing test (idle-in-town shows fixtures + Travel)**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/views/dashboard/now_playing_section.dart';

void main() {
  testWidgets('idle in Town Square renders the Now Playing header', (tester) async {
    final engine = GameEngine(); // idle, in town
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChangeNotifierProvider<GameEngine>.value(
          value: engine,
          child: const SingleChildScrollView(child: NowPlayingSection()),
        ),
      ),
    ));
    await tester.pump();

    expect(find.text('Now Playing'), findsOneWidget);
  });
}
```

> Expand this test after Step 3 with state-specific assertions once the exact action/fixture labels are known from reading the engine. Keep at least: header present (above), and one fixture or action row rendered in town.

- [ ] **Step 3: Run to verify it fails**

Run: `flutter test test/widgets/dashboard/now_playing_section_test.dart`
Expected: FAIL.

- [ ] **Step 4: Implement NowPlayingSection**

Move the existing active-action card and zone-actions rendering from `dashboard_view.dart` into this widget, wrapped in a `GameCard` with a `'Now Playing'` header. Use a private state selector returning an enum (`_NowPlayingState { activeAction, zoneActions, townFixtures }`). Each branch builds its body. Preserve the existing per-action labels, energy costs, durations, and the Cancel / Travel buttons (migrated to `GameButton`). Town fixtures must render only discovered fixtures (progressive discovery — do not render locked fixtures).

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../engine/game_engine.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/game/game_card.dart';
import '../../widgets/game/game_button.dart';

enum _NowPlayingState { activeAction, zoneActions, townFixtures }

/// Now Playing section — context-sensitive: in-progress action, available
/// zone actions, or town fixtures.
class NowPlayingSection extends StatelessWidget {
  final VoidCallback? onTravel;
  const NowPlayingSection({super.key, this.onTravel});

  _NowPlayingState _select(GameEngine engine) {
    // TODO(implementer): replace with the real "is action active" getter found
    // in dashboard_view.dart (e.g. engine.activeAction != null || engine.activeCraft != null).
    final hasActiveAction = engine.hasActiveActionOrCraft;
    if (hasActiveAction) return _NowPlayingState.activeAction;
    if (engine.currentZone.isHub) return _NowPlayingState.townFixtures;
    return _NowPlayingState.zoneActions;
  }

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<GameEngine>();
    final state = _select(engine);

    return GameCard(
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Now Playing', style: DSText.label(context).copyWith(color: DSColors.textSecondary)),
          const SizedBox(height: DSSpace.sm8),
          switch (state) {
            _NowPlayingState.activeAction => _buildActiveAction(context, engine),
            _NowPlayingState.zoneActions => _buildZoneActions(context, engine),
            _NowPlayingState.townFixtures => _buildTownFixtures(context, engine),
          },
          if (state != _NowPlayingState.activeAction) ...[
            const SizedBox(height: DSSpace.md12),
            GameButton(
              label: 'Travel',
              icon: Icons.explore,
              variant: GameButtonVariant.secondary,
              onPressed: onTravel,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveAction(BuildContext context, GameEngine engine) {
    // Port _buildActiveRecipeCard / active-action rendering here:
    // icon + title, "Skill · ~Ns remaining", GameProgressBar(progress: ...),
    // and a Cancel GameButton(variant: ghost) calling the existing cancel method.
    return const SizedBox.shrink();
  }

  Widget _buildZoneActions(BuildContext context, GameEngine engine) {
    // Port _buildZoneActions list rows: each action → emoji + name + "Skill · Ns · E"
    // as a tappable GameListItem/GameCard that calls the existing start-action method.
    return const SizedBox.shrink();
  }

  Widget _buildTownFixtures(BuildContext context, GameEngine engine) {
    // Render only discovered fixtures (Stall / Tavern / Bench). Each is a row with
    // a Visit GameButton(variant: ghost) calling the existing navigation method.
    return const SizedBox.shrink();
  }
}
```

> The `engine.hasActiveActionOrCraft`, `currentZone.isHub`, and the three `_build*` bodies are placeholders for the implementer to fill from the REAL methods in `dashboard_view.dart` and the engine. Do not invent new engine APIs — reuse the existing action-start, cancel, fixture-visit, and travel methods the old dashboard already calls. Add no game logic.

- [ ] **Step 5: Run to verify it passes**

Run: `flutter test test/widgets/dashboard/now_playing_section_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/views/dashboard/now_playing_section.dart test/widgets/dashboard/now_playing_section_test.dart
git commit -m "feat(7b-1): implement NowPlayingSection (3-state)"
```

---

### Task 6: Reduce dashboard_view.dart to an orchestrator

**Files:**
- Modify: `lib/views/dashboard_view.dart`
- Test: `test/widget_test.dart` (must stay green — do not edit)

- [ ] **Step 1: Rewrite the build method as an orchestrator**

Replace the body with the section composition. Combat swap is wired in PR2 (Task 13) — for now keep whatever combat rendering currently exists OR leave a clearly-marked `// PR2: replace with `if (engine.activeCombat != null) return const CombatHud();`` so the build still compiles. Keep `_showZoneTravelSheet` and the YouWin modal handling; pass the travel callback into the sections.

```dart
@override
Widget build(BuildContext context) {
  final engine = context.watch<GameEngine>();
  // PR2 will add: if (engine.activeCombat != null) return const CombatHud();
  return Stack(
    children: [
      SingleChildScrollView(
        padding: DSSpace.section,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PlayerHandSection(),
            const SizedBox(height: DSSpace.md12),
            NowPlayingSection(onTravel: () => _showZoneTravelSheet(context, engine)),
            const SizedBox(height: DSSpace.md12),
            WorldPulseSection(onZoneTap: () => _showZoneTravelSheet(context, engine)),
            const SizedBox(height: DSSpace.md12),
            const RecentLogSection(),
          ],
        ),
      ),
      if (engine.shouldShowYouWinModal)
        // keep existing YouWin modal widget + dismiss callback
        ... ,
    ],
  );
}
```

> Add the four imports for the section widgets. Delete the now-migrated helper methods (`_buildHeader`, `_buildLocationCard`, `_buildActiveRecipeCard`, `_buildZoneActions`, `_buildStationStatusStrip`, log rendering) ONLY once their logic lives in the sub-widgets. Keep `_showZoneTravelSheet`, the quest-log chip/sheet, and `'Open Codex'` button if they were part of the dashboard — re-place the `'Open Codex'` button somewhere visible (e.g. inside or below WorldPulseSection, or a small actions row) so the smoke test still finds it. If `DashboardView` can become `StatelessWidget`, convert it; if travel-sheet plumbing needs `State`, keep it `StatefulWidget`.

- [ ] **Step 2: Run the full smoke suite**

Run: `flutter test test/widget_test.dart`
Expected: PASS — all 4 smoke tests green (`ELARIA RPG`, `Town Square`, station chip `Crafting Bench`/`T1`/`Idle` → Workshop, `Open Codex`, Skills/Workshop/Codex tab flows).

> If the station-chip test fails, the `'Crafting Bench'`/`'T1'`/`'Idle'` strings or the `activeTabIndex == 3` tap wiring did not survive the WorldPulseSection migration — fix WorldPulseSection (Task 3) before proceeding. If `'Open Codex'` is missing, add the button back to the orchestrator.

- [ ] **Step 3: Run the dashboard section tests + analyze**

Run: `flutter test test/widgets/dashboard/ && flutter analyze lib/views/dashboard_view.dart lib/views/dashboard/`
Expected: PASS, no analyzer errors.

- [ ] **Step 4: Commit**

```bash
git add lib/views/dashboard_view.dart
git commit -m "feat(7b-1): reduce dashboard_view to section orchestrator"
```

---

### Task 7: Extend the token guard for dashboard files

**Files:**
- Modify: `test/widgets/tokens_only_test.dart`

- [ ] **Step 1: Add the dashboard dir + files to the guard**

Read `test/widgets/tokens_only_test.dart`. Add `'lib/views/dashboard'` to `targetDirs` (or the four new file paths to `targetPaths`), matching the existing structure. The guard asserts no `Color(0x...)` literals and no `GameTheme` references.

- [ ] **Step 2: Run the guard**

Run: `flutter test test/widgets/tokens_only_test.dart`
Expected: PASS — the four new dashboard files use only tokens.

> If it fails, a sub-widget used a raw color or `GameTheme`. Replace with the appropriate `DSColors`/`DSText` token.

- [ ] **Step 3: Run the entire suite**

Run: `flutter test`
Expected: PASS (all green).

- [ ] **Step 4: Commit**

```bash
git add test/widgets/tokens_only_test.dart
git commit -m "test(7b-1): extend token guard to dashboard section files"
```

After PR1: the dashboard is split into 4 sectioned widgets + a thin orchestrator. Combat still uses the old action bar (replaced in PR2).

---

## PR 2 — Combat HUD Takeover

### Task 8: Create combat sub-widget stub files

**Files:**
- Create: `lib/views/combat_hud.dart`
- Create: `lib/views/combat/beast_card.dart`, `telegraph_strip.dart`, `round_timer_arc.dart`, `player_card_mini.dart`, `stance_pad.dart`, `quickslot_bar.dart`

- [ ] **Step 1: Create seven stubs**

Each is a `StatelessWidget` returning `SizedBox.shrink()`. Class names: `CombatHud`, `BeastCard`, `TelegraphStrip`, `RoundTimerArc`, `PlayerCardMini`, `StancePad`, `QuickslotBar`. Example:

```dart
import 'package:flutter/material.dart';

/// Beast Card — current combat target (icon, name, HP bar, phase indicator).
class BeastCard extends StatelessWidget {
  const BeastCard({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
```

- [ ] **Step 2: Verify compile**

Run: `flutter analyze lib/views/combat_hud.dart lib/views/combat/`
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/views/combat_hud.dart lib/views/combat/
git commit -m "feat(7b-1): scaffold combat HUD stub files"
```

---

### Task 9: BeastCard

**Files:**
- Modify: `lib/views/combat/beast_card.dart`
- Test: `test/widgets/combat/beast_card_test.dart`

- [ ] **Step 1: Establish a combat-state test harness**

Read how combat is started in tests / the engine (look for a `startCombat` / `beginCombat` test helper or a public method that sets `activeCombat`). The cleanest harness subclasses `GameEngine` and overrides `activeCombat`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/models/beast.dart';
import 'package:flutter_text_based_rpg/views/combat/beast_card.dart';

class _CombatEngine extends GameEngine {
  CombatState? _override;
  void setCombat(CombatState s) { _override = s; notifyListeners(); }
  @override
  CombatState? get activeCombat => _override;
}

void main() {
  testWidgets('renders beast name and HP values', (tester) async {
    final engine = _CombatEngine();
    final beast = Beasts.findById('forest_boar')!; // confirm a real id exists
    engine.setCombat(CombatState(
      beast: beast,
      beastCurrentHealth: beast.maxHealth,
      playerStartHealth: 100,
      combatLog: const [],
    ));

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChangeNotifierProvider<GameEngine>.value(
          value: engine,
          child: const BeastCard(),
        ),
      ),
    ));
    await tester.pump();

    expect(find.text(beast.name), findsOneWidget);
    expect(find.text('${beast.maxHealth}/${beast.maxHealth}'), findsOneWidget);
  });
}
```

> Confirm a real beast id (grep `Beasts` definitions). If `activeCombat`'s setter is private, the override approach above is required.

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/widgets/combat/beast_card_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement BeastCard**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../engine/game_engine.dart';
import '../../models/beast.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/game/game_card.dart';
import '../../widgets/game/game_avatar.dart';
import '../../widgets/game/game_chip.dart';
import '../../widgets/game/game_progress_bar.dart';

/// Beast Card — combat target: icon, name, HP bar, phase indicator,
/// and (during Source phases) a Sediment Stacks row.
class BeastCard extends StatelessWidget {
  const BeastCard({super.key});

  Color _phaseColor(Beast beast, int phaseIndex) {
    // Use the beast's themed color if available; fall back to error/red accent.
    // If Beast exposes a tag/element, map via DSColors.tag(...). Otherwise:
    return DSColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final combat = context.watch<GameEngine>().activeCombat;
    if (combat == null) return const SizedBox.shrink();
    final beast = combat.beast;
    final hpRatio = beast.maxHealth > 0 ? combat.beastCurrentHealth / beast.maxHealth : 0.0;
    final phase = combat.activePhaseIndex;
    final totalPhases = beast.phases?.length ?? 1;
    final accent = _phaseColor(beast, phase);

    return GameCard(
      elevation: 2,
      accentColor: accent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GameAvatar(emoji: beast.icon, size: GameAvatarSize.lg, ringColor: accent),
          const SizedBox(width: DSSpace.md12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(beast.name, style: DSText.headingSmall(context))),
                    if (totalPhases > 1 && phase >= 0)
                      GameChip(
                        label: 'Phase ${phase + 1}/$totalPhases',
                        size: GameChipSize.sm,
                        color: accent,
                      ),
                  ],
                ),
                if (beast.phases != null && phase >= 0 && phase < beast.phases!.length)
                  Text(beast.phases![phase].ability.name, style: DSText.label(context)),
                const SizedBox(height: DSSpace.sm8),
                GameProgressBar(
                  progress: hpRatio.clamp(0.0, 1.0),
                  color: DSColors.healthBar,
                  height: 10,
                  leadingLabel: '❤',
                  trailingLabel: '${combat.beastCurrentHealth}/${beast.maxHealth}',
                  animated: true,
                ),
                if (combat.activePhasePassive == BeastPassive.sourceSedimentStack &&
                    combat.sourceSedimentStacks > 0)
                  _sedimentRow(context, combat.sourceSedimentStacks),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sedimentRow(BuildContext context, int stacks) {
    return Padding(
      padding: const EdgeInsets.only(top: DSSpace.xs4),
      child: Row(
        children: [
          Text('⚠ Sediment: ', style: DSText.label(context).copyWith(color: DSColors.warning)),
          for (int i = 0; i < 3; i++)
            Icon(i < stacks ? Icons.circle : Icons.circle_outlined,
                size: 12, color: DSColors.warning),
        ],
      ),
    );
  }
}
```

> Confirm the exact `BeastPassive` enum value name for the Source sediment passive (grep `enum BeastPassive`). If it differs from `sourceSedimentStack`, fix the comparison. If `Beast` exposes a themed color (tag/element), wire `_phaseColor` to `DSColors.tag(...)` for Wilds/Stone/Tide.

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/widgets/combat/beast_card_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/views/combat/beast_card.dart test/widgets/combat/beast_card_test.dart
git commit -m "feat(7b-1): implement combat BeastCard"
```

---

### Task 10: TelegraphStrip

**Files:**
- Modify: `lib/views/combat/telegraph_strip.dart`
- Test: `test/widgets/combat/telegraph_strip_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/models/beast.dart';
import 'package:flutter_text_based_rpg/models/combat.dart';
import 'package:flutter_text_based_rpg/views/combat/telegraph_strip.dart';

class _CombatEngine extends GameEngine {
  CombatState? _override;
  void setCombat(CombatState? s) { _override = s; notifyListeners(); }
  @override
  CombatState? get activeCombat => _override;
}

void main() {
  testWidgets('hidden when no telegraph, shown with telegraph text', (tester) async {
    final engine = _CombatEngine();
    final beast = Beasts.findById('forest_boar')!;
    final base = CombatState(beast: beast, beastCurrentHealth: beast.maxHealth, playerStartHealth: 100, combatLog: const []);
    engine.setCombat(base);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: ChangeNotifierProvider<GameEngine>.value(value: engine, child: const TelegraphStrip())),
    ));
    await tester.pump();
    expect(find.textContaining('lowers its head'), findsNothing);

    engine.setCombat(base.copyWith(
      activeTelegraph: const BeastTelegraph(abilityId: 'gore', text: 'The boar lowers its head.', reveal: false),
    ));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.textContaining('The boar lowers its head.'), findsOneWidget);
  });
}
```

> Confirm `BeastTelegraph`'s constructor and field names (`abilityId`, `text`, `reveal`) from `lib/models/combat.dart`; adjust if it is not `const`-constructible.

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/widgets/combat/telegraph_strip_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement TelegraphStrip**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../engine/game_engine.dart';
import '../../theme/design_tokens.dart';

/// Telegraph Strip — full-width danger banner that briefly shakes on a new
/// telegraph. Hidden when no telegraph is active.
class TelegraphStrip extends StatelessWidget {
  const TelegraphStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final tg = context.watch<GameEngine>().activeCombat?.activeTelegraph;
    if (tg == null) return const SizedBox.shrink();

    return TweenAnimationBuilder<double>(
      key: ValueKey(tg.text),
      tween: Tween<double>(begin: -8, end: 0),
      duration: DSMotion.fast,
      curve: DSMotion.spring,
      builder: (_, shake, child) => Transform.translate(offset: Offset(shake, 0), child: child),
      child: Container(
        padding: DSSpace.dense,
        decoration: BoxDecoration(
          color: DSColors.error.withValues(alpha: 0.25),
          border: Border.all(color: DSColors.error),
          borderRadius: BorderRadius.circular(DSRadius.sm4),
        ),
        child: Row(
          children: [
            const Text('⚠', style: TextStyle(fontSize: 18)),
            const SizedBox(width: DSSpace.sm8),
            Expanded(
              child: Text(
                tg.reveal ? '${tg.text}  [${tg.abilityId.toUpperCase()}]' : tg.text,
                style: DSText.bodyMedium(context).copyWith(
                  color: DSColors.error,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

> `Color.withValues(alpha:)` is the current non-deprecated API. If the project's Flutter version predates it, use `.withOpacity(0.25)` and confirm the analyzer is clean.

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/widgets/combat/telegraph_strip_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/views/combat/telegraph_strip.dart test/widgets/combat/telegraph_strip_test.dart
git commit -m "feat(7b-1): implement combat TelegraphStrip"
```

---

### Task 11: RoundTimerArc

**Files:**
- Modify: `lib/views/combat/round_timer_arc.dart`
- Test: `test/widgets/combat/round_timer_arc_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/models/beast.dart';
import 'package:flutter_text_based_rpg/views/combat/round_timer_arc.dart';

class _CombatEngine extends GameEngine {
  CombatState? _override;
  void setCombat(CombatState s) { _override = s; notifyListeners(); }
  @override
  CombatState? get activeCombat => _override;
}

void main() {
  testWidgets('renders the current round number', (tester) async {
    final engine = _CombatEngine();
    final beast = Beasts.findById('forest_boar')!;
    engine.setCombat(CombatState(
      beast: beast, beastCurrentHealth: beast.maxHealth, playerStartHealth: 100,
      combatLog: const [], currentRoundNumber: 4,
      roundDeadline: DateTime.now().add(const Duration(milliseconds: 1500)),
    ));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: ChangeNotifierProvider<GameEngine>.value(value: engine, child: const Center(child: RoundTimerArc()))),
    ));
    await tester.pump();
    expect(find.text('4'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/widgets/combat/round_timer_arc_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement RoundTimerArc**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../engine/game_engine.dart';
import '../../theme/design_tokens.dart';

/// Round Timer arc — 56×56 circular countdown for the current combat round.
class RoundTimerArc extends StatelessWidget {
  const RoundTimerArc({super.key});

  @override
  Widget build(BuildContext context) {
    final combat = context.watch<GameEngine>().activeCombat;
    if (combat == null) return const SizedBox.shrink();
    final remaining = combat.roundDeadline?.difference(DateTime.now()) ?? Duration.zero;
    final ms = remaining.inMilliseconds.clamp(0, 2000);
    final pct = ms / 2000.0;
    final Color stroke = pct < 0.2
        ? DSColors.error
        : pct < 0.5
            ? DSColors.warning
            : DSColors.goldAccent;

    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: pct,
            strokeWidth: 4,
            valueColor: AlwaysStoppedAnimation(stroke),
            backgroundColor: DSColors.borderSubtle,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${combat.currentRoundNumber}', style: DSText.numeric(context)),
              Text(
                ms < 1000 ? '0.${ms ~/ 100}s' : '${(ms / 1000).floor()}s',
                style: DSText.label(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/widgets/combat/round_timer_arc_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/views/combat/round_timer_arc.dart test/widgets/combat/round_timer_arc_test.dart
git commit -m "feat(7b-1): implement combat RoundTimerArc"
```

---

### Task 12: PlayerCardMini

**Files:**
- Modify: `lib/views/combat/player_card_mini.dart`
- Test: `test/widgets/combat/player_card_mini_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/views/combat/player_card_mini.dart';

void main() {
  testWidgets('shows player HP and energy, no XP/title', (tester) async {
    final engine = GameEngine();
    final stats = engine.playerStats;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: ChangeNotifierProvider<GameEngine>.value(value: engine, child: const PlayerCardMini())),
    ));
    await tester.pump();
    expect(find.text('${stats.currentHealth}/${stats.maxHealth}'), findsOneWidget);
    expect(find.text('${stats.currentEnergy}/${stats.maxEnergy}'), findsOneWidget);
    expect(find.textContaining('XP'), findsNothing);
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/widgets/combat/player_card_mini_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement PlayerCardMini**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../engine/game_engine.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/game/game_card.dart';
import '../../widgets/game/game_avatar.dart';
import '../../widgets/game/game_progress_bar.dart';

/// Player Card (mini) — condensed HP + energy mirror for the combat HUD.
class PlayerCardMini extends StatelessWidget {
  const PlayerCardMini({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<GameEngine>().playerStats;
    final hpRatio = stats.maxHealth > 0 ? stats.currentHealth / stats.maxHealth : 0.0;
    final enRatio = stats.maxEnergy > 0 ? stats.currentEnergy / stats.maxEnergy : 0.0;
    return GameCard(
      elevation: 1,
      padding: DSSpace.dense,
      child: Row(
        children: [
          const GameAvatar(emoji: '🧙', size: GameAvatarSize.sm),
          const SizedBox(width: DSSpace.sm8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GameProgressBar(
                  progress: hpRatio.clamp(0.0, 1.0),
                  color: DSColors.healthBar,
                  height: 6,
                  leadingLabel: '❤',
                  trailingLabel: '${stats.currentHealth}/${stats.maxHealth}',
                  animated: true,
                ),
                const SizedBox(height: DSSpace.xs4),
                GameProgressBar(
                  progress: enRatio.clamp(0.0, 1.0),
                  color: DSColors.energyBar,
                  height: 6,
                  leadingLabel: '⚡',
                  trailingLabel: '${stats.currentEnergy}/${stats.maxEnergy}',
                  animated: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/widgets/combat/player_card_mini_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/views/combat/player_card_mini.dart test/widgets/combat/player_card_mini_test.dart
git commit -m "feat(7b-1): implement combat PlayerCardMini"
```

---

### Task 13: StancePad (3+2 grid)

**Files:**
- Modify: `lib/views/combat/stance_pad.dart`
- Test: `test/widgets/combat/stance_pad_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/models/beast.dart';
import 'package:flutter_text_based_rpg/views/combat/stance_pad.dart';

class _CombatEngine extends GameEngine {
  CombatState? _override;
  void setCombat(CombatState s) { _override = s; notifyListeners(); }
  @override
  CombatState? get activeCombat => _override;
}

void main() {
  testWidgets('renders all five stance labels', (tester) async {
    final engine = _CombatEngine();
    final beast = Beasts.findById('forest_boar')!;
    engine.setCombat(CombatState(beast: beast, beastCurrentHealth: beast.maxHealth, playerStartHealth: 100, combatLog: const []));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: ChangeNotifierProvider<GameEngine>.value(value: engine, child: const StancePad())),
    ));
    await tester.pump();
    for (final label in ['Strike', 'Heavy', 'Defend', 'Read', 'Item']) {
      expect(find.textContaining(label), findsWidgets);
    }
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/widgets/combat/stance_pad_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement StancePad**

5 buttons in a 3+2 grid. Selected stance (`combat.pendingStance`) uses `primary`; others `secondary`. Tapping calls `engine.setCombatStance(stance)`. Item button shows a `▾` affordance.

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../engine/game_engine.dart';
import '../../models/combat.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/game/game_button.dart';

/// Stance Pad — 5 combat stances in a 3+2 grid (thumb-zone friendly).
class StancePad extends StatelessWidget {
  const StancePad({super.key});

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<GameEngine>();
    final selected = engine.activeCombat?.pendingStance;

    Widget btn(PlayerStance stance, String emoji, String label) => _StanceButton(
          stance: stance,
          emoji: emoji,
          label: label,
          selected: selected == stance,
          onTap: () => engine.setCombatStance(stance),
        );

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: btn(PlayerStance.strike, '⚔️', 'Strike')),
            const SizedBox(width: DSSpace.sm8),
            Expanded(child: btn(PlayerStance.heavyStrike, '💪', 'Heavy')),
            const SizedBox(width: DSSpace.sm8),
            Expanded(child: btn(PlayerStance.defend, '🛡️', 'Defend')),
          ],
        ),
        const SizedBox(height: DSSpace.sm8),
        Row(
          children: [
            const Spacer(),
            Expanded(flex: 2, child: btn(PlayerStance.readTells, '👁️', 'Read')),
            const SizedBox(width: DSSpace.sm8),
            Expanded(flex: 2, child: btn(PlayerStance.item, '🎒', 'Item')),
            const Spacer(),
          ],
        ),
      ],
    );
  }
}

class _StanceButton extends StatelessWidget {
  final PlayerStance stance;
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _StanceButton({
    required this.stance,
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isItem = stance == PlayerStance.item;
    return GameButton(
      label: isItem ? '$emoji $label ▾' : '$emoji $label',
      variant: selected ? GameButtonVariant.primary : GameButtonVariant.secondary,
      size: GameButtonSize.md,
      fullWidth: true,
      onPressed: onTap,
    );
  }
}
```

> If `GameButton` cannot render emoji + label cleanly, build the cell from a `GameCard(onTap:)` with a `Column(emoji, label)` instead, applying `accentColor: DSColors.goldAccent` when selected. Keep the labels `Strike/Heavy/Defend/Read/Item` exactly (the test asserts them).

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/widgets/combat/stance_pad_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/views/combat/stance_pad.dart test/widgets/combat/stance_pad_test.dart
git commit -m "feat(7b-1): implement combat StancePad (3+2 grid)"
```

---

### Task 14: QuickslotBar (one-tap consume)

**Files:**
- Modify: `lib/views/combat/quickslot_bar.dart`
- Test: `test/widgets/combat/quickslot_bar_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/views/combat/quickslot_bar.dart';

void main() {
  testWidgets('renders three cells; empty cells show Empty', (tester) async {
    final engine = GameEngine();
    for (var i = 0; i < 3; i++) {
      engine.setQuickslot(i, null); // ensure all empty
    }
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: ChangeNotifierProvider<GameEngine>.value(value: engine, child: const QuickslotBar())),
    ));
    await tester.pump();
    expect(find.text('Empty'), findsNWidgets(3));
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/widgets/combat/quickslot_bar_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement QuickslotBar**

3 always-visible cells. Filled cell: item emoji + name + heal/energy preview; tap → `engine.useQuickslot(i)` (in combat calls `setCombatStance(item, quickslotIndex: i)`). Empty cell: dimmed "Empty" label. Selected slot (matching `combat.pendingQuickslotIndex`) gets a `borderStrong` ring.

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../engine/game_engine.dart';
import '../../models/item.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/game/game_card.dart';

/// Quickslot Bar — 3 inline food slots; one tap consumes (no popover).
class QuickslotBar extends StatelessWidget {
  const QuickslotBar({super.key});

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<GameEngine>();
    return Row(
      children: [
        for (int i = 0; i < 3; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: DSSpace.xs4),
              child: _QuickslotCell(index: i, engine: engine),
            ),
          ),
      ],
    );
  }
}

class _QuickslotCell extends StatelessWidget {
  final int index;
  final GameEngine engine;
  const _QuickslotCell({required this.index, required this.engine});

  @override
  Widget build(BuildContext context) {
    final id = engine.quickslots[index];
    final item = id == null ? null : Items.findById(id);
    final isSelected = engine.activeCombat?.pendingQuickslotIndex == index;

    if (item == null) {
      return GameCard(
        elevation: 0,
        padding: DSSpace.dense,
        child: Center(
          child: Text('Empty',
              style: DSText.label(context).copyWith(color: DSColors.textDisabled)),
        ),
      );
    }

    return GameCard(
      elevation: 1,
      padding: DSSpace.dense,
      accentColor: isSelected ? DSColors.borderStrong : null,
      onTap: () => engine.useQuickslot(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(item.icon, style: const TextStyle(fontSize: 24)),
          Text(item.name,
              style: DSText.label(context), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text('+${item.healAmount}❤ +${item.energyAmount}⚡',
              style: DSText.label(context).copyWith(color: DSColors.textMuted)),
        ],
      ),
    );
  }
}
```

> Confirm `Item` exposes `healAmount` / `energyAmount` (used by `useQuickslot` in the engine). If the preview field names differ, fix them. Confirm `Items.findById` import path (`lib/models/item.dart`).

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/widgets/combat/quickslot_bar_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/views/combat/quickslot_bar.dart test/widgets/combat/quickslot_bar_test.dart
git commit -m "feat(7b-1): implement combat QuickslotBar (one-tap consume)"
```

---

### Task 15: CombatHud root + dashboard swap

**Files:**
- Modify: `lib/views/combat_hud.dart`
- Modify: `lib/views/dashboard_view.dart`
- Modify: `lib/widgets/combat_action_bar.dart`
- Test: `test/widgets/combat/combat_hud_test.dart`

- [ ] **Step 1: Write the failing test (HUD renders during combat)**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/models/beast.dart';
import 'package:flutter_text_based_rpg/views/combat_hud.dart';
import 'package:flutter_text_based_rpg/views/combat/beast_card.dart';
import 'package:flutter_text_based_rpg/views/combat/stance_pad.dart';

class _CombatEngine extends GameEngine {
  CombatState? _override;
  void setCombat(CombatState s) { _override = s; notifyListeners(); }
  @override
  CombatState? get activeCombat => _override;
}

void main() {
  testWidgets('CombatHud composes BeastCard and StancePad', (tester) async {
    final engine = _CombatEngine();
    final beast = Beasts.findById('forest_boar')!;
    engine.setCombat(CombatState(beast: beast, beastCurrentHealth: beast.maxHealth, playerStartHealth: 100, combatLog: const []));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: ChangeNotifierProvider<GameEngine>.value(value: engine, child: const CombatHud())),
    ));
    await tester.pump();
    expect(find.byType(BeastCard), findsOneWidget);
    expect(find.byType(StancePad), findsOneWidget);
    expect(find.text(beast.name), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/widgets/combat/combat_hud_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement CombatHud root**

```dart
import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import 'combat/beast_card.dart';
import 'combat/telegraph_strip.dart';
import 'combat/round_timer_arc.dart';
import 'combat/player_card_mini.dart';
import 'combat/stance_pad.dart';
import 'combat/quickslot_bar.dart';

/// Combat HUD — full-screen takeover shown while a combat is active.
class CombatHud extends StatelessWidget {
  const CombatHud({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DSColors.surface0,
      padding: DSSpace.section,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            BeastCard(),
            SizedBox(height: DSSpace.md12),
            TelegraphStrip(),
            SizedBox(height: DSSpace.md12),
            Center(child: RoundTimerArc()),
            SizedBox(height: DSSpace.md12),
            PlayerCardMini(),
            Spacer(),
            StancePad(),
            SizedBox(height: DSSpace.sm8),
            QuickslotBar(),
          ],
        ),
      ),
    );
  }
}
```

> §3.9 mentions a `PhaseBannerOverlay` from 7a. If that widget exists, wrap the `Container` body in a `Stack` and add the overlay; if it does not yet exist, omit it (the design notes it as a reuse, not a new build) and leave a `// TODO(7a PhaseBannerOverlay)` marker.

- [ ] **Step 4: Wire the dashboard swap**

In `dashboard_view.dart`, at the top of `build`, replace the PR1 placeholder comment with:

```dart
final engine = context.watch<GameEngine>();
if (engine.activeCombat != null) return const CombatHud();
```

Add `import 'combat_hud.dart';`.

- [ ] **Step 5: Deprecate the old combat action bar**

In `lib/widgets/combat_action_bar.dart`, annotate the public class:

```dart
@Deprecated('Use CombatHud and its sub-widgets (Spec 7b-1). Delete once no references remain.')
class CombatActionBar extends StatelessWidget { /* unchanged */ }
```

> Do NOT delete the file in this PR. Find references with Grep for `CombatActionBar` across `lib` and `test`. If the only remaining reference was the dashboard combat rendering you just replaced, remove that usage so nothing imports the deprecated widget; otherwise leave references and the deprecation warning in place.

- [ ] **Step 6: Run combat tests + smoke suite**

Run: `flutter test test/widgets/combat/ test/widget_test.dart`
Expected: PASS — combat widgets green AND the 4 dashboard smoke tests still green.

- [ ] **Step 7: Commit**

```bash
git add lib/views/combat_hud.dart lib/views/dashboard_view.dart lib/widgets/combat_action_bar.dart test/widgets/combat/combat_hud_test.dart
git commit -m "feat(7b-1): wire CombatHud root + dashboard combat swap; deprecate combat_action_bar"
```

---

### Task 16: Extend the token guard for combat files

**Files:**
- Modify: `test/widgets/tokens_only_test.dart`

- [ ] **Step 1: Add the combat dir + combat_hud.dart to the guard**

Add `'lib/views/combat'` to `targetDirs` and `'lib/views/combat_hud.dart'` to `targetPaths`.

- [ ] **Step 2: Run the guard + full suite**

Run: `flutter test test/widgets/tokens_only_test.dart && flutter test`
Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add test/widgets/tokens_only_test.dart
git commit -m "test(7b-1): extend token guard to combat HUD files"
```

After PR2: combat takes over the full screen via `CombatHud`; the dashboard returns when `activeCombat` clears.

---

## PR 3 — Inventory Split & Redesign

> **Item model facts (verified):** `ItemType { resource, food, tool, weapon, armor, blueprint, brew }` — there is **no** `quest` type. The "Quest" filter chip is a special case: confirm how a quest/key item is flagged in this codebase (a dedicated id list, a bool on `Item`, or a `Quest`-linked item set) before implementing the Quest chip; render it only when ≥1 such item is in the inventory (progressive discovery). `QualityTier { crude, standard, fine, ... }`. `InventorySlot { item (Item?), quantity, quality (QualityTier), affixIds, currentDurability, maxDurability }`. `Inventory.slots → List<InventorySlot>`.

### Task 17: Create inventory sub-widget + state stub files

**Files:**
- Create: `lib/views/inventory/inventory_filter_state.dart`
- Create: `lib/views/inventory/inventory_header.dart`, `inventory_filter_bar.dart`, `equipped_strip.dart`, `inventory_grid.dart`, `inventory_grid_cell.dart`

- [ ] **Step 1: Create the filter-state class and five widget stubs**

`inventory_filter_state.dart` (real, not a stub — it has no UI to test yet but defines the enums + notifier):

```dart
import 'package:flutter/foundation.dart';

enum InventoryFilter { all, tool, weapon, armor, food, quest }
enum InventorySort { name, quality, type }

/// View-scoped filter/search/sort state for the inventory grid.
class InventoryFilterState extends ChangeNotifier {
  InventoryFilter _filter = InventoryFilter.all;
  InventorySort _sort = InventorySort.name;
  String _query = '';

  InventoryFilter get filter => _filter;
  InventorySort get sort => _sort;
  String get query => _query;

  void setFilter(InventoryFilter f) {
    if (_filter == f) return;
    _filter = f;
    notifyListeners();
  }

  void setSort(InventorySort s) {
    if (_sort == s) return;
    _sort = s;
    notifyListeners();
  }

  void setQuery(String q) {
    if (_query == q) return;
    _query = q;
    notifyListeners();
  }

  void clear() {
    _filter = InventoryFilter.all;
    _query = '';
    notifyListeners();
  }
}
```

The five widget stubs each return `SizedBox.shrink()`. Class names: `InventoryHeader`, `InventoryFilterBar`, `EquippedStrip`, `InventoryGrid`, `InventoryGridCell`. `InventoryGridCell` takes `final InventorySlot slot;` and a required constructor arg.

- [ ] **Step 2: Verify compile**

Run: `flutter analyze lib/views/inventory/`
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/views/inventory/
git commit -m "feat(7b-1): scaffold inventory state + section stub files"
```

---

### Task 18: InventoryFilterState filtering logic

**Files:**
- Create: `lib/views/inventory/inventory_filter_logic.dart` (a pure top-level function for testability)
- Test: `test/widgets/inventory/inventory_filter_state_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/models/inventory.dart';
import 'package:flutter_text_based_rpg/models/item.dart';
import 'package:flutter_text_based_rpg/views/inventory/inventory_filter_state.dart';
import 'package:flutter_text_based_rpg/views/inventory/inventory_filter_logic.dart';

void main() {
  test('name search filters case-insensitively', () {
    final slots = <InventorySlot>[
      // Build slots from two real items via Items.findById(...).
      // Replace these ids with real ones confirmed from lib/models/items*.dart
      InventorySlot(item: Items.findById('oak_log'), quantity: 2),
      InventorySlot(item: Items.findById('bread'), quantity: 1),
    ];
    final result = applyInventoryFilter(slots, InventoryFilter.all, InventorySort.name, 'oak');
    expect(result.length, 1);
    expect(result.first.item!.id, 'oak_log');
  });

  test('type filter keeps only matching ItemType', () {
    final slots = <InventorySlot>[
      InventorySlot(item: Items.findById('oak_log'), quantity: 2),   // resource
      InventorySlot(item: Items.findById('bread'), quantity: 1),     // food
    ];
    final result = applyInventoryFilter(slots, InventoryFilter.food, InventorySort.name, '');
    expect(result.every((s) => s.item!.type == ItemType.food), isTrue);
  });
}
```

> Confirm `InventorySlot`'s real constructor (it may require `quality`, `currentDurability`, `maxDurability`). Confirm two real item ids of differing `ItemType` from the items definitions. Adjust the test to the real constructor.

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/widgets/inventory/inventory_filter_state_test.dart`
Expected: FAIL — `applyInventoryFilter` undefined.

- [ ] **Step 3: Implement the pure filter function**

```dart
import '../../models/inventory.dart';
import '../../models/item.dart';
import 'inventory_filter_state.dart';

/// Pure filter + sort over inventory slots. Kept top-level so it is unit-testable
/// without a widget tree.
List<InventorySlot> applyInventoryFilter(
  List<InventorySlot> slots,
  InventoryFilter filter,
  InventorySort sort,
  String query,
) {
  final q = query.trim().toLowerCase();
  Iterable<InventorySlot> out = slots.where((s) => s.item != null);

  // Type filter
  out = out.where((s) {
    switch (filter) {
      case InventoryFilter.all:
        return true;
      case InventoryFilter.tool:
        return s.item!.type == ItemType.tool;
      case InventoryFilter.weapon:
        return s.item!.type == ItemType.weapon;
      case InventoryFilter.armor:
        return s.item!.type == ItemType.armor;
      case InventoryFilter.food:
        return s.item!.type == ItemType.food;
      case InventoryFilter.quest:
        // TODO(implementer): replace with the real quest-item predicate once
        // confirmed (id list / bool flag). For now treat nothing as quest.
        return false;
    }
  });

  // Search
  if (q.isNotEmpty) {
    out = out.where((s) => s.item!.name.toLowerCase().contains(q));
  }

  final list = out.toList();

  // Sort
  switch (sort) {
    case InventorySort.name:
      list.sort((a, b) => a.item!.name.compareTo(b.item!.name));
      break;
    case InventorySort.quality:
      list.sort((a, b) => b.quality.index.compareTo(a.quality.index));
      break;
    case InventorySort.type:
      list.sort((a, b) => a.item!.type.index.compareTo(b.item!.type.index));
      break;
  }
  return list;
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/widgets/inventory/inventory_filter_state_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/views/inventory/inventory_filter_logic.dart test/widgets/inventory/inventory_filter_state_test.dart
git commit -m "feat(7b-1): add pure inventory filter/sort logic"
```

---

### Task 19: InventoryHeader

**Files:**
- Modify: `lib/views/inventory/inventory_header.dart`
- Test: `test/widgets/inventory/inventory_header_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/views/inventory/inventory_header.dart';

void main() {
  testWidgets('shows title and gold', (tester) async {
    final engine = GameEngine();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: ChangeNotifierProvider<GameEngine>.value(value: engine, child: const InventoryHeader())),
    ));
    await tester.pump();
    expect(find.text('Inventory'), findsOneWidget);
    expect(find.textContaining('${engine.playerStats.gold}'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/widgets/inventory/inventory_header_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement InventoryHeader**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../engine/game_engine.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/game/game_chip.dart';

/// Inventory header — title + gold chip.
class InventoryHeader extends StatelessWidget {
  const InventoryHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<GameEngine>().playerStats;
    return Row(
      children: [
        Text('Inventory', style: DSText.headingLarge(context)),
        const Spacer(),
        GameChip(
          label: '${stats.gold} gold',
          icon: Icons.attach_money,
          color: DSColors.goldAccent,
          size: GameChipSize.md,
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/widgets/inventory/inventory_header_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/views/inventory/inventory_header.dart test/widgets/inventory/inventory_header_test.dart
git commit -m "feat(7b-1): implement InventoryHeader"
```

---

### Task 20: InventoryFilterBar

**Files:**
- Modify: `lib/views/inventory/inventory_filter_bar.dart`
- Test: `test/widgets/inventory/inventory_filter_bar_test.dart`

- [ ] **Step 1: Write the failing test**

The bar reads + writes `InventoryFilterState` and reads `GameEngine` (to decide which chips to show). Provide both providers.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/views/inventory/inventory_filter_state.dart';
import 'package:flutter_text_based_rpg/views/inventory/inventory_filter_bar.dart';

void main() {
  testWidgets('renders base filter chips and updates state on tap', (tester) async {
    final engine = GameEngine();
    final filterState = InventoryFilterState();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MultiProvider(
          providers: [
            ChangeNotifierProvider<GameEngine>.value(value: engine),
            ChangeNotifierProvider<InventoryFilterState>.value(value: filterState),
          ],
          child: const InventoryFilterBar(),
        ),
      ),
    ));
    await tester.pump();

    expect(find.text('All'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);

    await tester.tap(find.text('Food'));
    await tester.pump();
    expect(filterState.filter, InventoryFilter.food);
  });
}
```

> The Quest chip is asserted in a follow-up: it must be ABSENT when the inventory has no quest items. Add that assertion once the quest-item predicate is confirmed (Task 18). Import `package:provider/provider.dart` for `MultiProvider`.

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/widgets/inventory/inventory_filter_bar_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement InventoryFilterBar**

`GameInput` for search (debounce via `InventoryFilterState.setQuery`), a `Wrap` of filter chips (selected → `outlined: false`, unselected → `outlined: true`), and a sort `GameButton(variant: ghost)` opening a small menu. The Quest chip renders only when the engine has ≥1 quest item.

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../engine/game_engine.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/game/game_input.dart';
import '../../widgets/game/game_chip.dart';
import '../../widgets/game/game_button.dart';
import 'inventory_filter_state.dart';

/// Inventory filter bar — search + filter chips + sort.
class InventoryFilterBar extends StatelessWidget {
  const InventoryFilterBar({super.key});

  String _label(InventoryFilter f) => switch (f) {
        InventoryFilter.all => 'All',
        InventoryFilter.tool => 'Tools',
        InventoryFilter.weapon => 'Weapons',
        InventoryFilter.armor => 'Armor',
        InventoryFilter.food => 'Food',
        InventoryFilter.quest => 'Quest',
      };

  String _sortLabel(InventorySort s) => switch (s) {
        InventorySort.name => 'Name',
        InventorySort.quality => 'Quality',
        InventorySort.type => 'Type',
      };

  bool _hasQuestItems(GameEngine engine) {
    // TODO(implementer): real quest-item predicate. Until confirmed, false.
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<GameEngine>();
    final state = context.watch<InventoryFilterState>();

    final filters = <InventoryFilter>[
      InventoryFilter.all,
      InventoryFilter.tool,
      InventoryFilter.weapon,
      InventoryFilter.armor,
      InventoryFilter.food,
      if (_hasQuestItems(engine)) InventoryFilter.quest,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GameInput(
          hintText: 'Search items...',
          prefixIcon: Icons.search,
          onChanged: state.setQuery,
        ),
        const SizedBox(height: DSSpace.sm8),
        Wrap(
          spacing: DSSpace.sm8,
          runSpacing: DSSpace.sm8,
          children: [
            for (final f in filters)
              GameChip(
                label: _label(f),
                size: GameChipSize.sm,
                color: state.filter == f ? DSColors.goldAccent : DSColors.textMuted,
                outlined: state.filter != f,
                onTap: () => state.setFilter(f),
              ),
          ],
        ),
        const SizedBox(height: DSSpace.sm8),
        Align(
          alignment: Alignment.centerRight,
          child: GameButton(
            label: 'Sort: ${_sortLabel(state.sort)}',
            icon: Icons.sort,
            variant: GameButtonVariant.ghost,
            size: GameButtonSize.sm,
            onPressed: () => _showSortMenu(context, state),
          ),
        ),
      ],
    );
  }

  void _showSortMenu(BuildContext context, InventoryFilterState state) async {
    final selected = await showModalBottomSheet<InventorySort>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final s in InventorySort.values)
              ListTile(
                title: Text(_sortLabel(s)),
                onTap: () => Navigator.pop(ctx, s),
              ),
          ],
        ),
      ),
    );
    if (selected != null) state.setSort(selected);
  }
}
```

> `GameInput.onChanged` fires per keystroke. The design's 100ms debounce is a deferral noted in §5.5 — acceptable to skip for this layout pass. Confirm `GameInput` exposes `onChanged`.

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/widgets/inventory/inventory_filter_bar_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/views/inventory/inventory_filter_bar.dart test/widgets/inventory/inventory_filter_bar_test.dart
git commit -m "feat(7b-1): implement InventoryFilterBar"
```

---

### Task 21: EquippedStrip (collapsible)

**Files:**
- Modify: `lib/views/inventory/equipped_strip.dart`
- Test: `test/widgets/inventory/equipped_strip_test.dart`

- [ ] **Step 1: Identify equipped getters**

Read the engine equip getters (`equippedWeapon`, `equippedArmor`, equipped tools per skill — confirm exact names ~lines 463–691 of `game_engine.dart`). The collapsed chip shows the count of equipped items; expanded shows one card per equipped slot. Tapping a slot opens a `GameSheet` with Unequip / Inspect.

- [ ] **Step 2: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/views/inventory/equipped_strip.dart';

void main() {
  testWidgets('collapsed by default, expands on tap', (tester) async {
    final engine = GameEngine();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: ChangeNotifierProvider<GameEngine>.value(value: engine, child: const EquippedStrip())),
    ));
    await tester.pump();

    // Collapsed header present
    expect(find.textContaining('Equipped'), findsOneWidget);

    // Tap the header to expand — no exception, header still present.
    await tester.tap(find.textContaining('Equipped'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Equipped'), findsOneWidget);
  });
}
```

> If the engine starts with equipment, refine to assert the expanded slot cards appear. Keep the collapsed-header assertion regardless.

- [ ] **Step 3: Run to verify it fails**

Run: `flutter test test/widgets/inventory/equipped_strip_test.dart`
Expected: FAIL.

- [ ] **Step 4: Implement EquippedStrip**

`StatefulWidget` with `_expanded`. Header row: `Text('Equipped (N/3)')` + chevron, tappable to toggle. Expanded: a `Row`/`Wrap` of equipped slot cards (`GameCard(elevation: 2, padding: dense, accentColor: DSColors.skill(...))`). Worn (0 durability) shows a `GameChip(label: 'Worn', size: sm, color: warning, outlined: true)`. Render only filled slots (progressive discovery — empty slots are not shown as greyed placeholders; if all empty, show "Equipped (0/3)" and no cards). Count `N` = number of equipped items (not a "of total possible" spoiler — `/3` is the fixed slot model, acceptable since all three slot kinds are always available to the player).

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../engine/game_engine.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/game/game_card.dart';
import '../../widgets/game/game_chip.dart';

/// Equipped strip — collapsed equipment count; expands to show slot cards.
class EquippedStrip extends StatefulWidget {
  const EquippedStrip({super.key});

  @override
  State<EquippedStrip> createState() => _EquippedStripState();
}

class _EquippedStripState extends State<EquippedStrip> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<GameEngine>();
    // TODO(implementer): build the list of equipped items from the real getters.
    // e.g. [engine.equippedWeapon, engine.equippedArmor, ...tools]; filter nulls.
    final equipped = _collectEquipped(engine);

    return GameCard(
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Equipped (${equipped.length}/3)',
                    style: DSText.label(context).copyWith(color: DSColors.textSecondary)),
                Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                    color: DSColors.textMuted),
              ],
            ),
          ),
          if (_expanded && equipped.isNotEmpty) ...[
            const SizedBox(height: DSSpace.sm8),
            Row(
              children: [
                for (final e in equipped)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: DSSpace.xs4),
                      child: _slotCard(context, engine, e),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Replace _EquippedEntry/_collectEquipped/_slotCard with the real equipped
  // getters + a GameSheet (Unequip / Inspect) opened on tap. Keep the 'Worn'
  // GameChip when durability is 0.
  List<_EquippedEntry> _collectEquipped(GameEngine engine) => const [];

  Widget _slotCard(BuildContext context, GameEngine engine, _EquippedEntry e) {
    return GameCard(
      elevation: 2,
      padding: DSSpace.dense,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(e.icon, style: const TextStyle(fontSize: 28)),
          Text(e.name, style: DSText.label(context), maxLines: 2, textAlign: TextAlign.center),
          if (e.durability == 0)
            GameChip(label: 'Worn', size: GameChipSize.sm, color: DSColors.warning, outlined: true),
        ],
      ),
    );
  }
}

class _EquippedEntry {
  final String icon;
  final String name;
  final int durability;
  const _EquippedEntry({required this.icon, required this.name, required this.durability});
}
```

> `_collectEquipped` is a placeholder — wire it to the real equipped getters. Do not invent engine APIs. The `/3` denominator is the fixed equip-slot model (weapon/armor/tool), not a content spoiler.

- [ ] **Step 5: Run to verify it passes**

Run: `flutter test test/widgets/inventory/equipped_strip_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/views/inventory/equipped_strip.dart test/widgets/inventory/equipped_strip_test.dart
git commit -m "feat(7b-1): implement collapsible EquippedStrip"
```

---

### Task 22: InventoryGridCell

**Files:**
- Modify: `lib/views/inventory/inventory_grid_cell.dart`
- Test: `test/widgets/inventory/inventory_grid_cell_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/models/inventory.dart';
import 'package:flutter_text_based_rpg/models/item.dart';
import 'package:flutter_text_based_rpg/views/inventory/inventory_grid_cell.dart';

void main() {
  testWidgets('renders item icon and quantity badge when >1', (tester) async {
    final engine = GameEngine();
    final slot = InventorySlot(item: Items.findById('oak_log'), quantity: 3); // confirm ctor + id
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChangeNotifierProvider<GameEngine>.value(
          value: engine,
          child: InventoryGridCell(slot: slot),
        ),
      ),
    ));
    await tester.pump();
    expect(find.text(slot.item!.icon), findsOneWidget);
    expect(find.textContaining('3'), findsWidgets); // ×3 badge
  });
}
```

> Confirm `InventorySlot`'s constructor args. Confirm a real stackable item id with `quantity > 1` support.

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/widgets/inventory/inventory_grid_cell_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement InventoryGridCell**

`GameTooltip(message:)` wrapping a `GameCard(accentColor: DSColors.quality(slot.quality), onTap: detailSheet)` with an inner `GestureDetector(onLongPress: actionMenu)`. Renders icon, quantity badge (`×N` when `quantity > 1`), durability bar (when `maxDurability > 0`). Tap opens the detail `GameSheet`; longpress opens a quick-action menu (`showModalBottomSheet` of `ListTile`s: Equip / Use / Inspect / Sell-in-town). Equip dispatches by `item.type` to the correct engine method; Use calls `engine.useItem(item)`.

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../engine/game_engine.dart';
import '../../models/inventory.dart';
import '../../models/item.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/game/game_card.dart';
import '../../widgets/game/game_chip.dart';
import '../../widgets/game/game_progress_bar.dart';
import '../../widgets/game/game_tooltip.dart';

/// Inventory grid cell — icon, quantity badge, durability bar; tap → detail
/// sheet, longpress → quick-action menu.
class InventoryGridCell extends StatelessWidget {
  final InventorySlot slot;
  const InventoryGridCell({super.key, required this.slot});

  @override
  Widget build(BuildContext context) {
    final item = slot.item;
    if (item == null) {
      return const GameCard(elevation: 0, child: SizedBox.shrink());
    }
    final engine = context.read<GameEngine>();
    final hasDur = slot.maxDurability > 0;
    final durRatio = hasDur ? slot.currentDurability / slot.maxDurability : 0.0;

    return GameTooltip(
      message: '${item.name}\n${item.description}',
      child: GameCard(
        elevation: 1,
        padding: DSSpace.dense,
        accentColor: DSColors.quality(slot.quality),
        onTap: () => _showDetailSheet(context, engine, item),
        child: GestureDetector(
          onLongPress: () => _showActionMenu(context, engine, item),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(item.icon, style: const TextStyle(fontSize: 32)),
              if (slot.quantity > 1)
                GameChip(label: '×${slot.quantity}', size: GameChipSize.sm, color: DSColors.textMuted),
              if (hasDur)
                Padding(
                  padding: const EdgeInsets.only(top: DSSpace.xs4),
                  child: GameProgressBar(
                    progress: durRatio.clamp(0.0, 1.0),
                    color: durRatio < 0.25 ? DSColors.warning : DSColors.success,
                    height: 3,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailSheet(BuildContext context, GameEngine engine, Item item) {
    // Implemented in Task 24 (shared with item_dashboard_modal replacement).
    // For now open a minimal GameSheet so the tap is observable.
  }

  void _showActionMenu(BuildContext context, GameEngine engine, Item item) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isEquippable(item))
              ListTile(
                leading: const Text('⚒'),
                title: const Text('Equip'),
                onTap: () {
                  Navigator.pop(ctx);
                  _equip(engine, item);
                },
              ),
            if (item.type == ItemType.food)
              ListTile(
                leading: const Text('🍴'),
                title: const Text('Use'),
                onTap: () {
                  Navigator.pop(ctx);
                  engine.useItem(item);
                },
              ),
            ListTile(
              leading: const Text('🔍'),
              title: const Text('Inspect'),
              onTap: () {
                Navigator.pop(ctx);
                _showDetailSheet(context, engine, item);
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _isEquippable(Item item) =>
      item.type == ItemType.tool || item.type == ItemType.weapon || item.type == ItemType.armor;

  void _equip(GameEngine engine, Item item) {
    // Dispatch by type to the REAL engine equip methods. Confirm signatures:
    //   weapon → engine.equipWeapon(...); armor → engine.equipArmor(...);
    //   tool   → engine.equipTool(...). Pass whatever arg they require (Item/id).
  }
}
```

> Fill `_equip` and `_showDetailSheet` with the real engine equip calls and the Task-24 sheet. Do not add game logic — only dispatch to existing methods.

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/widgets/inventory/inventory_grid_cell_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/views/inventory/inventory_grid_cell.dart test/widgets/inventory/inventory_grid_cell_test.dart
git commit -m "feat(7b-1): implement InventoryGridCell (tap + longpress)"
```

---

### Task 23: InventoryGrid (with empty + no-results states)

**Files:**
- Modify: `lib/views/inventory/inventory_grid.dart`
- Test: `test/widgets/inventory/inventory_grid_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/views/inventory/inventory_filter_state.dart';
import 'package:flutter_text_based_rpg/views/inventory/inventory_grid.dart';
import 'package:flutter_text_based_rpg/views/inventory/inventory_grid_cell.dart';

void main() {
  testWidgets('renders one cell per filtered item', (tester) async {
    final engine = GameEngine(); // confirm engine starts with ≥1 item, else add some
    final filterState = InventoryFilterState();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MultiProvider(
          providers: [
            ChangeNotifierProvider<GameEngine>.value(value: engine),
            ChangeNotifierProvider<InventoryFilterState>.value(value: filterState),
          ],
          child: const SingleChildScrollView(child: InventoryGrid()),
        ),
      ),
    ));
    await tester.pump();

    final nonEmpty = engine.inventory.slots.where((s) => s.item != null).length;
    if (nonEmpty == 0) {
      expect(find.textContaining('empty'), findsOneWidget); // empty state
    } else {
      expect(find.byType(InventoryGridCell), findsNWidgets(nonEmpty));
    }
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/widgets/inventory/inventory_grid_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement InventoryGrid**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../engine/game_engine.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/game/game_card.dart';
import '../../widgets/game/game_avatar.dart';
import '../../widgets/game/game_button.dart';
import 'inventory_filter_state.dart';
import 'inventory_filter_logic.dart';
import 'inventory_grid_cell.dart';

/// Inventory grid — 4-column grid of cells, with empty + no-results states.
class InventoryGrid extends StatelessWidget {
  const InventoryGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<GameEngine>();
    final state = context.watch<InventoryFilterState>();
    final allSlots = engine.inventory.slots.where((s) => s.item != null).toList();

    if (allSlots.isEmpty) {
      return GameCard(
        elevation: 0,
        padding: DSSpace.section,
        child: Column(
          children: [
            const GameAvatar(emoji: '🎒', size: GameAvatarSize.lg),
            const SizedBox(height: DSSpace.sm8),
            Text('Your pack is empty.', style: DSText.headingSmall(context)),
            const SizedBox(height: DSSpace.xs4),
            Text('Gather, craft, or buy something to fill it up.',
                style: DSText.bodySmall(context).copyWith(color: DSColors.textMuted),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    final visible = applyInventoryFilter(allSlots, state.filter, state.sort, state.query);

    if (visible.isEmpty) {
      return GameCard(
        elevation: 0,
        padding: DSSpace.section,
        child: Column(
          children: [
            Text(
              state.query.isNotEmpty
                  ? 'No items match "${state.query}". Try a different filter or clear search.'
                  : 'No items match this filter.',
              style: DSText.bodySmall(context).copyWith(color: DSColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DSSpace.sm8),
            GameButton(
              label: 'Clear filters',
              variant: GameButtonVariant.ghost,
              size: GameButtonSize.sm,
              onPressed: state.clear,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: DSSpace.sm8,
        crossAxisSpacing: DSSpace.sm8,
        childAspectRatio: 0.85,
      ),
      itemCount: visible.length,
      itemBuilder: (_, i) => InventoryGridCell(slot: visible[i]),
    );
  }
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/widgets/inventory/inventory_grid_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/views/inventory/inventory_grid.dart test/widgets/inventory/inventory_grid_test.dart
git commit -m "feat(7b-1): implement InventoryGrid (empty + no-results states)"
```

---

### Task 24: Orchestrator + item_dashboard_modal detail sheet

**Files:**
- Modify: `lib/views/inventory_view.dart`
- Modify: `lib/views/inventory/inventory_grid_cell.dart` (fill `_showDetailSheet`)
- Modify: `lib/widgets/item_dashboard_modal.dart`
- Test: `test/widget_test.dart` (must stay green)

- [ ] **Step 1: Implement the shared detail sheet**

Replace `item_dashboard_modal.dart` internals with a `GameSheet`-based detail view per §4.8: title (icon + name), quality/skill subtitle, description, durability bar, stat lines, and inline action `GameButton`s (Equip / Repair / Inspect — Sell only when in town). Expose it as a top-level helper so `InventoryGridCell._showDetailSheet` can call it:

```dart
// in item_dashboard_modal.dart (or a shared helper it exports)
Future<void> showItemDetailSheet(BuildContext context, GameEngine engine, Item item) {
  return GameSheet.show<void>(
    context: context,
    title: '${item.icon} ${item.name}',
    child: /* description + durability + stats column */,
    actions: [
      // Equip / Repair / Inspect GameButtons dispatching to real engine methods.
    ],
  );
}
```

Then in `inventory_grid_cell.dart`, set `_showDetailSheet` to call `showItemDetailSheet(context, engine, item)`.

> Preserve every existing capability the old modal had (repair, inspect, equip, sell). This is a chrome/layout replacement, not a feature removal. Confirm `GameSheet.show` signature and that `actions` accepts `List<GameButton>`.

- [ ] **Step 2: Reduce inventory_view.dart to an orchestrator**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/design_tokens.dart';
import 'inventory/inventory_filter_state.dart';
import 'inventory/inventory_header.dart';
import 'inventory/inventory_filter_bar.dart';
import 'inventory/equipped_strip.dart';
import 'inventory/inventory_grid.dart';

/// Inventory view — orchestrates header, filter bar, equipped strip, and grid.
class InventoryView extends StatelessWidget {
  const InventoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<InventoryFilterState>(
      create: (_) => InventoryFilterState(),
      child: SingleChildScrollView(
        padding: DSSpace.section,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            InventoryHeader(),
            SizedBox(height: DSSpace.md12),
            InventoryFilterBar(),
            SizedBox(height: DSSpace.md12),
            EquippedStrip(),
            SizedBox(height: DSSpace.md12),
            InventoryGrid(),
          ],
        ),
      ),
    );
  }
}
```

> If the previous `InventoryView` had tabs (Inventory / Shop / Equipment) — the grep showed `_buildShopTab`, `_buildEquipmentTab` — confirm whether 7b-1 keeps those tabs. The spec scopes 7b-1 to the **inventory** surface; the Shop and Equipment tabs are out of scope. If they share the same `InventoryView`, preserve the tab scaffold and only replace the **Inventory tab** body with the new orchestrator column. Do NOT delete Shop/Equipment. Adjust the orchestrator to slot into the existing tab structure rather than replacing the whole view if tabs exist.

- [ ] **Step 3: Run the full smoke suite + inventory tests**

Run: `flutter test test/widget_test.dart test/widgets/inventory/`
Expected: PASS — smoke tests still green, inventory section tests green.

- [ ] **Step 4: Commit**

```bash
git add lib/views/inventory_view.dart lib/views/inventory/inventory_grid_cell.dart lib/widgets/item_dashboard_modal.dart
git commit -m "feat(7b-1): inventory orchestrator + GameSheet detail sheet"
```

---

### Task 25: Extend the token guard for inventory files + full suite

**Files:**
- Modify: `test/widgets/tokens_only_test.dart`

- [ ] **Step 1: Add the inventory dir to the guard**

Add `'lib/views/inventory'` to `targetDirs`. (The `inventory_filter_state.dart` / `inventory_filter_logic.dart` files have no colors but are harmless to include.)

- [ ] **Step 2: Run the guard + entire suite + analyze**

Run: `flutter test && flutter analyze`
Expected: PASS — all tests green, analyzer clean (no errors).

> Resolve any leftover `@Deprecated` usage warnings for `CombatActionBar` and confirm no raw `Color(0x...)` or `GameTheme` slipped into the new files.

- [ ] **Step 3: Commit**

```bash
git add test/widgets/tokens_only_test.dart
git commit -m "test(7b-1): extend token guard to inventory files"
```

After PR3: all three surfaces are redesigned; ~5200 lines of view code condensed into ~13 focused files.

---

## Self-Review (completed during plan authoring)

**Spec coverage:**
- §2 Dashboard → Tasks 1–7 (4 sections + orchestrator + guard). ✓
- §3 Combat HUD → Tasks 8–16 (6 sub-widgets + root + dashboard swap + deprecation + guard). ✓
- §4 Inventory → Tasks 17–25 (filter state + logic + 5 widgets + orchestrator + detail sheet + guard). ✓
- §5 Testing/order → 3 PRs, per-section TDD commits, guard extended once per PR. ✓
- Acceptance criteria 1–10 all map to tasks; smoke-test preservation is an explicit gate in Tasks 6, 15, 24.

**Known open items the implementer MUST resolve (flagged inline, not placeholders in shipped code):**
1. The exact "is an action/craft active" getter and `currentZone.isHub` predicate for `NowPlayingSection` (Task 5) — read from `dashboard_view.dart`.
2. The station-chip rendering must reproduce `'Crafting Bench'` / `'T1'` / `'Idle'` as separate Text nodes and the `activeTabIndex == 3` tap (Task 3) — port `_buildStationStatusStrip`.
3. The `'Open Codex'` button must survive into the new orchestrator (Task 6).
4. `BeastPassive.sourceSedimentStack` enum value name (Task 9) — grep to confirm.
5. The quest-item predicate for the progressive-discovery Quest chip (Tasks 18, 20) — confirm how quest/key items are flagged (no `ItemType.quest` exists).
6. Equipped getters + equip-dispatch-by-type (Tasks 21, 22, 24) — use real `equipWeapon/equipArmor/equipTool`.
7. Whether `InventoryView` has Shop/Equipment tabs to preserve (Task 24).
8. `InventorySlot` constructor args for tests (Tasks 18, 22).

These are codebase-lookup confirmations, not design gaps — the surrounding code is fully specified. Each is a 1–2 minute grep/read the implementer does before writing the corresponding task.

**Type consistency:** All widget class names, the `InventoryFilter`/`InventorySort` enums, `applyInventoryFilter` signature, and `showItemDetailSheet` helper are used consistently across tasks. All token/primitive/engine APIs match the verified signatures in the API Corrections section.

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-05-29-spec-7b-1-dashboard-combat-inventory-redesign.md`.

Per the user's earlier "Plan then build" choice, execution proceeds via **superpowers:subagent-driven-development** on an isolated branch/worktree (implementing on `main` requires explicit consent — set up a worktree/branch first). One PR per major surface, fresh implementer subagent per task, two-stage review (spec compliance → code quality) after each.
