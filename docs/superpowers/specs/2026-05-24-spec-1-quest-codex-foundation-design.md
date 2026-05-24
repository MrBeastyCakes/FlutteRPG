# Spec 1 — Quest Engine & Codex Foundation

**Date:** 2026-05-24
**Status:** Approved (pending spec review)
**Parent:** [Echoes from the Deep umbrella vision](2026-05-24-echoes-from-the-deep-vision.md)
**Scope:** First of six sub-specs from the umbrella. Foundational plumbing for all story-related content: Quest engine, Codex view shell, milestone World Event system, Cartographer's Tent in Town Square. Ships with one wired main quest (Town Square restoration) and auto-offered Masterwork side quests as demonstration content.

---

## 1. Goals & Acceptance Criteria

### 1.1 What ships

After Spec 1 lands, the game looks and plays nearly identical to today **except**:

- A new **Codex** view exists, opened from the new **Cartographer's Tent** fixture in Town Square (which appears after the restoration quest completes)
- A new **Quest Log** chip on the Dashboard, always visible while a quest is active, opens a full quest popover anywhere
- One main quest is wired: **Restore Town Square** (uses existing restoration mechanic)
- A side quest appears automatically for any Masterwork trial the player has unlocked but not completed
- The **Bestiary** auto-fills as the player defeats beasts
- The **Region Status Board** shows zones the player has discovered

### 1.2 What this spec does NOT do

- No Codex Fragments content — Spec 2
- No Codex puzzle UI (drag-to-reorder) — Spec 2
- No additional story milestones beyond `town_square_restored` — Spec 2
- No Tavern Notice Board — Spec 6 (daily/side quest source)
- No Achievement entries (the framework here is the empty shell) — Spec 6
- No Breach status indicators — Spec 5
- No new zones / beasts / Echoes / combat depth — later specs

### 1.3 Acceptance criteria (testable)

A player starting a fresh session after Spec 1 ships will:

1. See a **"Restore Town Square"** quest in their Quest Log from session start
2. See the restoration sub-objectives auto-advance as they restore the Bench/Kitchen
3. See a one-time modal World Event when the quest completes (*"Town Square's hum returns; the cartographer rolls out fresh maps"*)
4. See the **Cartographer's Tent** appear in Town Square after the World Event
5. Open the Codex → see Bestiary auto-populating as they defeat beasts, Region Status showing scouted zones, Fragments/Achievements sections hidden (no entries yet)
6. Hit level 10 in a skill → see a side quest appear: *"Skill Trial: The Ironbark Trial"* — tappable to jump to Skills view
7. Complete a Masterwork → see the side quest mark complete in the Quest Log

### 1.4 Design principles inherited from umbrella

- **No art** — emoji + text + Material Icons only
- **Progressive discovery** — never spoil scope: no "X of Y" counters, no greyed-out future content, sections appear only when populated
- **Thin story spine** — narrative carried by Codex fragments + milestone overlays + zone descriptions; no NPC dialog trees
- **Systems converse** — every new system explicitly hooks into existing ones (gathering, combat, crafting, building, masterworks)

---

## 2. Data Model

### 2.1 New file: `lib/models/quest.dart`

```dart
enum QuestType { main, side, daily }
enum QuestStatus { available, active, completed, turnedIn }

enum ObjectiveKind {
  gather,       // collect N of itemId
  kill,         // defeat N beasts of beastId (or "any")
  craft,        // craft N of recipeId (or any of category)
  visit,        // travel to zoneId at least once
  scout,        // complete an exploration action
  restore,      // restore a station instance
  upgrade,      // upgrade a station to tier N
  masterwork,   // complete a Masterwork trial of skillType
  cleanse,      // perform a Breach cleansing (Spec 5)
  codexRead,    // read N new Codex fragments (Spec 2)
  custom,       // ad-hoc, advanced via explicit engine.advanceQuestObjective(...)
}

class QuestObjective {
  final ObjectiveKind kind;
  final String? targetId;       // itemId, beastId, recipeId, zoneId, stationId, skillType.name, etc.
  final int targetCount;
  int currentCount;

  bool get isComplete => currentCount >= targetCount;
}

enum RewardKind {
  gold,
  skillXp,
  item,
  blueprint,        // a blueprint scroll (Spec 2)
  worldEvent,       // fires a milestone World Event by id
  unlock,           // generic engine-flag unlock keyed by targetId
}

class QuestReward {
  final RewardKind kind;
  final String? targetId;
  final int amount;
}

class Quest {
  final String id;
  final QuestType type;
  final String title;
  final String description;
  final List<QuestObjective> objectives;
  final List<QuestReward> rewards;
  final String? turnInLocation;  // zoneId; null = auto-turn-in on completion
  QuestStatus status;

  bool get isComplete => objectives.every((o) => o.isComplete);
}
```

**Design notes:**

- **Enum-driven `ObjectiveKind`** rather than class hierarchy. Each engine observer iterates active quests and advances any matching objective via a single switch helper. Simple, easy to extend.
- **`currentCount` is mutable** — quests are stateful, mutated in place rather than copy-on-write. Quests change frequently; copying every objective tick would create churn. Engine notifies listeners after batch mutations.
- **`turnInLocation`** distinguishes auto-turn-in (main quests advance via World Events; use `null`) from explicit turn-in (side/daily — use `'town_square'` or future Tavern Board id).
- **`unlock` reward kind** is intentionally generic — its `targetId` names a key (e.g., `'cartographers_tent'`) that engine logic checks via `_engineFlags`. Avoids special-casing UI surfaces in the reward enum.

### 2.2 New file: `lib/models/codex.dart`

```dart
enum CodexTag { wilds, stone, tide, source, oldEmpire, misc }

class CodexFragment {
  final String id;
  final CodexTag tag;
  final String title;            // short title (e.g., "On Black Sap")
  final String text;             // 1–3 sentences
  final String? sourceHint;      // "Found at: Crumbling Obelisk in Whispering Woods I"
  final int orderInTag;          // puzzle ordering; Spec 2 uses, Spec 1 stores inertly
}

class CodexFragments {
  static const List<CodexFragment> all = [];  // empty in Spec 1; Spec 2 fills
  static CodexFragment? findById(String id) { /* ... */ }
}

class BestiaryEntry {
  final String beastId;
  final DateTime firstDefeated;
  int defeatCount;
  Set<String> droppedItemIds;
}

enum RegionStatus { locked, anomalous, spreading, cleansed }

class RegionStatusInfo {
  final String zoneId;
  RegionStatus status;
  DateTime? discoveredAt;
  DateTime? cleansedAt;
}

class Achievement {
  final String id;
  final String name;
  final String description;
  final String icon;             // emoji
  final bool hidden;             // hidden achievements don't appear until earned
  final String? titleUnlock;     // optional Title text granted on unlock
}

class Achievements {
  static const List<Achievement> all = [];  // empty in Spec 1; Spec 6 fills
}
```

**Design notes:**

- **`CodexTag.misc`** is a catch-all for fragments not tied to a Breach. Lets writers add bonus fragments without breaking puzzles.
- **`sourceHint`** is shown in puzzle UI as ordering context (per umbrella section 3.4).
- **`orderInTag`** is set per-fragment in Spec 2's content. In Spec 1 the field exists but is never read.
- **`BestiaryEntry`** auto-populates via engine observer; defeat count + drop history accumulate.
- **`RegionStatusInfo`** stores only timestamps; status defaults to `anomalous` in Spec 1 (no Breach data yet). Spec 5 layers in Anomalous → Spreading → Cleansed progression.

### 2.3 New file: `lib/models/milestone.dart`

```dart
enum MilestoneSeverity { major, minor }

class MilestoneEvent {
  final String id;
  final MilestoneSeverity severity;
  final String title;
  final String body;
  final String icon;
  final bool Function(GameEngine engine) trigger;
  final void Function(GameEngine engine)? onFire;
}

class Milestones {
  // Spec 1 ships with exactly one milestone:
  static final MilestoneEvent townSquareRestored = MilestoneEvent(
    id: 'town_square_restored',
    severity: MilestoneSeverity.major,
    title: 'The Town Stirs',
    body: 'As you hammer the last beam into place, the town stirs. The cartographer unfurls a long-rolled map; chalk dust catches the light. "Welcome back. Bring me what you find — every fragment, every echo. The world has been speaking, and we haven\'t been listening."',
    icon: '🗺️',
    trigger: (engine) => engine.engineFlags.contains('town_square_restored'),
    onFire: null,
  );

  static final List<MilestoneEvent> all = [townSquareRestored];
}
```

Spec 2 expands `Milestones.all` with the ~12 story milestone events.

### 2.4 Engine state additions (in `GameEngine`)

```dart
final List<Quest> _activeQuests = [];
final List<Quest> _completedQuests = [];
final Set<String> _knownCodexFragmentIds = {};
final Map<String, BestiaryEntry> _bestiary = {};
final Map<String, RegionStatusInfo> _regionStatus = {};
final Set<String> _earnedAchievementIds = {};
final Set<String> _firedMilestoneIds = {};
final Set<String> _engineFlags = {};
String? _activeTitleId;

final StreamController<QuestEvent> _questController = StreamController.broadcast();
final StreamController<MilestoneEvent> _milestoneController = StreamController.broadcast();

// Public getters
List<Quest> get activeQuests => List.unmodifiable(_activeQuests);
List<Quest> get completedQuests => List.unmodifiable(_completedQuests);
Map<String, BestiaryEntry> get bestiary => Map.unmodifiable(_bestiary);
Map<String, RegionStatusInfo> get regionStatus => Map.unmodifiable(_regionStatus);
Set<String> get engineFlags => Set.unmodifiable(_engineFlags);
Stream<QuestEvent> get questEvents => _questController.stream;
Stream<MilestoneEvent> get milestoneEvents => _milestoneController.stream;
```

### 2.5 What is NOT in the data model yet

- No `Puzzle` / locked-sequence types — Spec 2
- No `Reading` content types — Spec 2
- No daily-task templates — Spec 6
- No reputation, durability, reagent types — Spec 6

---

## 3. Engine Integration

### 3.1 Observer pattern — how objectives advance

Every gameplay event that might advance a quest objective gets a dedicated engine method call. Each method does its existing work + appends one call to `_notifyQuestObservers(event)`. No global hooks, no magic — explicit dispatch.

```dart
void _notifyQuestObservers(QuestEvent event) {
  for (final quest in _activeQuests) {
    if (quest.status != QuestStatus.active) continue;
    for (final objective in quest.objectives) {
      if (objective.isComplete) continue;
      if (_matches(objective, event)) {
        objective.currentCount = (objective.currentCount + event.count)
            .clamp(0, objective.targetCount);
        _questController.add(event);
      }
    }
    _maybeCompleteQuest(quest);
  }
  notifyListeners();
}
```

`QuestEvent` is a sealed class with subtypes:

```dart
sealed class QuestEvent {
  final int count;
  const QuestEvent(this.count);
}
class ItemGatheredEvent extends QuestEvent {
  final String itemId;
  const ItemGatheredEvent(this.itemId, int count) : super(count);
}
class BeastDefeatedEvent extends QuestEvent {
  final String beastId;
  const BeastDefeatedEvent(this.beastId) : super(1);
}
class ItemCraftedEvent extends QuestEvent {
  final String recipeId;
  final QualityTier? quality;
  const ItemCraftedEvent(this.recipeId, this.quality, int count) : super(count);
}
class ZoneVisitedEvent extends QuestEvent {
  final String zoneId;
  const ZoneVisitedEvent(this.zoneId) : super(1);
}
class StationRestoredEvent extends QuestEvent {
  final String zoneId;
  final String stationId;
  const StationRestoredEvent(this.zoneId, this.stationId) : super(1);
}
class StationUpgradedEvent extends QuestEvent {
  final String zoneId;
  final String stationId;
  final int newTier;
  const StationUpgradedEvent(this.zoneId, this.stationId, this.newTier) : super(1);
}
class MasterworkCompletedEvent extends QuestEvent {
  final SkillType skill;
  const MasterworkCompletedEvent(this.skill) : super(1);
}
class CodexFragmentReadEvent extends QuestEvent {
  final String fragmentId;
  const CodexFragmentReadEvent(this.fragmentId) : super(1);
}
```

`_matches(objective, event)` is a single switch on `ObjectiveKind` × `QuestEvent` subtype. Adding a new objective kind is one switch arm + one event class.

### 3.2 Integration points

| Existing engine method | Add observer call |
|---|---|
| `_completeAction` (zone gather completion) | `_notifyQuestObservers(ItemGatheredEvent(itemId, qty))` per looted item |
| `_completeStationCraft` (recipe completion) | `_notifyQuestObservers(ItemCraftedEvent(recipeId, quality, qty))` |
| `_resolveCombat` (beast defeat) | `_notifyQuestObservers(BeastDefeatedEvent(beastId))` + `_recordBestiary(beastId, drops)` |
| `_completeRestoration` (station restoration) | `_notifyQuestObservers(StationRestoredEvent(zoneId, stationId))` |
| `_completeStationUpgrade` (tier up) | `_notifyQuestObservers(StationUpgradedEvent(zoneId, stationId, newTier))` |
| `travelToZone(zoneId)` | `_notifyQuestObservers(ZoneVisitedEvent(zoneId))` + `_recordRegionDiscovered(zoneId)` |
| `_completeMasterwork` (trial success) | `_notifyQuestObservers(MasterworkCompletedEvent(skill))` |
| `readCodexFragment(fragmentId)` *(new method)* | `_notifyQuestObservers(CodexFragmentReadEvent(fragmentId))` |

Each is one line appended to the existing method, after existing side effects. No restructuring required.

### 3.3 Quest lifecycle API

```dart
void offerQuest(Quest quest);
// Adds to _activeQuests. status=active for auto-accept; status=available for explicit-accept.

void acceptQuest(String questId);     // available → active
void turnInQuest(String questId);     // explicit turn-in path; checks location
void abandonQuest(String questId);    // active → removed; no rewards, no progress kept
```

`_maybeCompleteQuest(quest)`:
- If `quest.isComplete` and `turnInLocation == null` → status becomes `completed`, rewards granted, quest moved to `_completedQuests`. An `onComplete` World Event may fire via the `worldEvent` reward kind.
- If `quest.isComplete` and `turnInLocation != null` → status becomes `completed` but quest stays in `_activeQuests`. UI marks it ready-to-turn-in. Player calls `turnInQuest(id)` when at the location to claim rewards and move quest to `_completedQuests`.

`_grantReward(reward)` switches on `RewardKind`:
- `gold` → `playerStats.gold += amount`
- `skillXp` → `skills[skill] = skills[skill].addXp(amount)`
- `item` → `inventory.addItem(Items.findById(targetId)!, amount)`
- `blueprint` → adds a blueprint item to inventory (Spec 2 may rewire)
- `worldEvent` → adds `targetId` to `_engineFlags` and immediately checks `Milestones.all` for a matching trigger
- `unlock` → adds `targetId` to `_engineFlags`

### 3.4 Milestone tick-checking

The engine's existing periodic tick (already runs at ~100ms for stations/actions) also checks milestones once per tick:

```dart
void _checkMilestones() {
  for (final m in Milestones.all) {
    if (_firedMilestoneIds.contains(m.id)) continue;
    if (m.trigger(this)) {
      _firedMilestoneIds.add(m.id);
      m.onFire?.call(this);
      _milestoneController.add(m);
      log(m.body, LogType.worldEvent);
    }
  }
}
```

Dedup set short-circuits already-fired. Trigger functions are cheap boolean checks. Performance is trivial at the v1 scale (~1 milestone in Spec 1; ~12 by Spec 2).

### 3.5 Starter quest bootstrapping

In `GameEngine` constructor, after existing init:

```dart
void _bootstrapStarterQuests() {
  offerQuest(Quest(
    id: 'main_restore_town_square',
    type: QuestType.main,
    title: 'Restore Town Square',
    description: 'The cartographer\'s tent stands abandoned, and the local crafts have crumbled. Restore them to draw the town back to life.',
    objectives: [
      QuestObjective(kind: ObjectiveKind.restore, targetId: 'crafting_bench', targetCount: 1),
      QuestObjective(kind: ObjectiveKind.restore, targetId: 'field_kitchen', targetCount: 1),
    ],
    rewards: [
      QuestReward(kind: RewardKind.gold, amount: 50),
      QuestReward(kind: RewardKind.skillXp, targetId: SkillType.wayfinding.name, amount: 100),
      QuestReward(kind: RewardKind.worldEvent, targetId: 'town_square_restored', amount: 1),
      QuestReward(kind: RewardKind.unlock, targetId: 'cartographers_tent', amount: 1),
    ],
    turnInLocation: null,
  ));
}
```

Masterwork side quests are offered when a skill hits its current cap:

```dart
void _maybeOfferMasterworkQuest(SkillType skill) {
  final questId = 'side_masterwork_${skill.name}';
  if (_activeQuests.any((q) => q.id == questId)) return;
  if (_completedQuests.any((q) => q.id == questId)) return;

  final state = _skills[skill]!;
  if (state.level < state.levelCap) return;

  final task = MasterworkTasks.findForSkill(skill, state.levelCap);
  if (task == null) return;

  offerQuest(Quest(
    id: questId,
    type: QuestType.side,
    title: 'Skill Trial: ${task.title}',
    description: task.description,
    objectives: [
      QuestObjective(kind: ObjectiveKind.masterwork, targetId: skill.name, targetCount: 1),
    ],
    rewards: [
      QuestReward(kind: RewardKind.skillXp, targetId: skill.name, amount: 50),
      QuestReward(kind: RewardKind.gold, amount: 25),
    ],
    turnInLocation: null,
  ));
}
```

Called from the existing skill-up path when a skill reaches its cap.

### 3.6 Bestiary & Region Status integration

Pure observer state — no quest objectives currently target them (but future achievements will).

```dart
void _recordBestiary(String beastId, List<String> droppedItemIds) {
  final existing = _bestiary[beastId];
  if (existing == null) {
    _bestiary[beastId] = BestiaryEntry(
      beastId: beastId,
      firstDefeated: DateTime.now(),
      defeatCount: 1,
      droppedItemIds: droppedItemIds.toSet(),
    );
  } else {
    existing.defeatCount++;
    existing.droppedItemIds.addAll(droppedItemIds);
  }
}

void _recordRegionDiscovered(String zoneId) {
  _regionStatus.putIfAbsent(zoneId, () => RegionStatusInfo(
    zoneId: zoneId,
    status: RegionStatus.anomalous,
    discoveredAt: DateTime.now(),
  ));
}
```

For Spec 1, all discovered zones show as Anomalous. Spec 5 wires the actual Anomalous → Spreading → Cleansed progression.

### 3.7 What this does NOT change

- No changes to existing combat, crafting, or building flows beyond the appended observer calls
- No changes to existing zone unlock logic
- No changes to existing Masterwork trial flow
- `_zoneStructures` and other existing state stays untouched

---

## 4. UI

### 4.1 Codex view — `lib/views/codex_view.dart`

Opens via the Cartographer's Tent — a new card in Town Square's zone actions list, visible only when `_engineFlags.contains('cartographers_tent')`. Tapping pushes a full-screen route.

Top-level structure (tabbed with Flutter `DefaultTabController`):

```
┌─ Codex ──────────────────────────────────┐
│  ╔═══════╗ ╔════════╗ ╔══════╗ ╔════════╗ │
│  ║QUESTS ║ ║FRAGMENT║ ║BEAST ║ ║REGIONS ║ │
│  ╚═══════╝ ╚════════╝ ╚══════╝ ╚════════╝ │
│                                            │
│  [active tab content]                     │
└────────────────────────────────────────────┘
```

A 5th **Achievements** tab is hidden in Spec 1 (no entries) and only appears when `_earnedAchievementIds` is non-empty. Same for **Fragments** — hidden in Spec 1, unhides in Spec 2 once any fragment is read.

**Spec 1 ships the Codex view with 3 active tabs: Quests, Beasts, Regions** — plus the framework for the other two.

#### Quests tab

Full quest browser. Sections:
- **In Progress** — active quests with progress bars per objective
- **Ready to Turn In** — completed quests with `turnInLocation` set (gold badge)
- **Completed** — history, collapsed by default

Each quest expandable. Each objective shows `current / target` count + small progress bar. Rewards listed at the bottom.

#### Beasts tab

Auto-populated from `_bestiary`. Empty state: *"No beasts catalogued yet. Defeat one to record it here."*

Card layout:
```
┌──────────────────────────────────────┐
│  🐗  Forest Boar                     │
│      Defeated: 7 times               │
│      First slain: 3 days ago         │
│      Drops seen: 🍖 🐗               │
└──────────────────────────────────────┘
```

Tapping opens a modal with `Beast` stats (HP, attack, defense) from existing `Beasts.findById(id)`. Emoji + text only.

#### Regions tab

Auto-populated from `_regionStatus`. Empty state: *"You have not yet scouted beyond Town Square."*

Grouped by biome. Each zone card:
```
┌──────────────────────────────────────┐
│  🌲 Whispering Woods I    🟡 Anomalous│
│  Discovered: 2 days ago              │
│  Unlocked by: Scout Forest Paths     │
└──────────────────────────────────────┘
```

In Spec 1, all discovered zones show 🟡 Anomalous. Locked zones don't appear — pure progressive discovery.

### 4.2 Quest Log chip + popover

#### Dashboard chip

A new chip pinned to the top of the Dashboard view, above the existing station status strip:

```
┌──────────────────────────────────────┐
│  📜 Restore Town Square   1/2 ▶      │
└──────────────────────────────────────┘
```

- Shows highest-priority active quest (main > side > daily; within type, oldest first)
- Progress = `completed objectives / total objectives`
- Right icon: `▶` for in-progress, `✓` gold for ready-to-turn-in
- Background tinted by type (purple=main, blue=side, green=daily)
- Hidden entirely if `_activeQuests` is empty

#### Popover

Tap chip → `showModalBottomSheet` with full quest log. Modal sheet (not full-screen) so swiping dismisses cleanly. Contains:

- **In Progress** section, each quest a card with objectives + progress + rewards preview
- **Ready to Turn In** section, golden border
- "View Full Codex" button at bottom — pushes to full Codex view → Quests tab. Only enabled when Cartographer's Tent is unlocked
- Completed quests not shown in popover (too noisy) — full Codex only

Popover scrolls if many quests; acceptable for a transient sheet.

### 4.3 Milestone World Event overlays

#### Major milestones — modal full-screen

New widget `WorldEventModal` (`lib/widgets/world_event_modal.dart`). Triggered by listening to `engine.milestoneEvents` from a `WorldEventListener` widget mounted once at app root in `main.dart`.

Visual:
- Dim background overlay (95% opacity)
- Center card with `GameTheme.glassCardDecoration`
- Large emoji icon, bold title, narrative-italic body, "Continue" button
- Tap button OR tap-outside dismisses
- Game timer paused while modal is shown (existing pause flag, mirrors Masterwork trial behavior)

#### Minor milestones — banner

New widget `WorldEventBanner`. Slides down from top of screen over AppBar, auto-dismisses after 6 seconds. Tap-to-dismiss-early supported.

Visual:
- Thin 60px card with emoji + title only (body still goes to activity log)
- Slide-in 250ms ease-out, slide-out on dismiss
- Color tinted amber for minor severity

#### Activity log integration

Every World Event also produces an activity log entry styled `LogType.worldEvent` (new type added to existing `LogType` enum), cyan + bold. Players who missed the overlay can scroll back.

### 4.4 Cartographer's Tent in Town Square

A new entry in Town Square's zone actions list, added programmatically when `_engineFlags.contains('cartographers_tent')`:

```
┌──────────────────────────────────────┐
│  🗺️ Cartographer's Tent             │
│  Review your maps, notes, and trials.│
│                          [Open Codex]│
└──────────────────────────────────────┘
```

Tap `[Open Codex]` pushes the Codex view route. The tent appears the moment the Town Square restoration quest completes.

The tent is NOT a buildable station — it's a free fixture distinct from Workshop tab stations.

### 4.5 Existing UI touch-points

| File | Change |
|---|---|
| `lib/views/dashboard_view.dart` | Add Quest Log chip above station status strip; append Cartographer's Tent entry to Town Square actions when flag set |
| `lib/main.dart` | Mount a `WorldEventListener` widget at app root |
| `lib/engine/activity_log.dart` | Add `LogType.worldEvent` |

No changes to Workshop, Skills, or Inventory views.

### 4.6 What this UI does NOT include

- No puzzle UI — Spec 2
- No Fragments tab content — Spec 2
- No Achievements tab content — Spec 6
- No Tavern Notice Board — Spec 6
- No Breach Status indicators — Spec 5

---

## 5. Testing & Rollout

### 5.1 Test strategy

#### Unit tests — model layer

**New `test/quest_test.dart`:**
- `QuestObjective` count clamps to `targetCount`
- `Quest.isComplete` correctly reflects all-objectives-done
- `_matches(objective, event)` truth table — every (`ObjectiveKind`, `QuestEvent` subtype) combination including non-matches
- `Quest` lifecycle: `available → active → completed → turnedIn`
- Rewards granted on completion match declared rewards (mocked engine spy)

**New `test/codex_test.dart`:**
- `BestiaryEntry` accumulates `defeatCount` + drop history across multiple defeats
- `RegionStatusInfo` records `discoveredAt` only on first visit
- `CodexFragments.findById` returns `null` for unknown ids

#### Unit tests — engine integration

**Add to `test/engine_test.dart` (or new `test/quest_engine_test.dart`):**
- Town Square restoration quest is offered at engine init
- Restoring `crafting_bench` advances only the first objective
- Restoring both stations completes the quest, grants rewards, fires `town_square_restored` milestone, sets `cartographers_tent` flag
- Milestone events fire at most once even if `notifyListeners` is called repeatedly with the trigger still true
- Hitting a skill cap auto-offers the matching Masterwork side quest
- Completing the Masterwork closes the side quest and grants rewards
- Bestiary auto-populates on `_resolveCombat`
- Region status auto-populates on `travelToZone`

#### Widget tests — UI

**Add to `test/widget_test.dart`:**
- Quest Log chip hidden when `_activeQuests` is empty
- Tapping chip shows popover with quest cards
- Cartographer's Tent appears in Town Square actions only when flag set
- Opening Codex shows Quests/Beasts/Regions tabs (Fragments/Achievements hidden)
- World Event modal shows on stream emit; tap-outside dismisses
- World Event banner auto-dismisses after 6 seconds (use `fake_async`)
- Game tick paused while major milestone modal is open

#### Integration smoke test

A single end-to-end test through the Spec 1 acceptance criteria:
1. Fresh engine → restoration quest offered
2. Restore both stations → quest completes → milestone fires → Cartographer's Tent appears
3. Open Codex → expected tabs visible
4. Simulate a beast defeat → Beasts tab shows entry
5. Simulate level-up to cap on Woodcutting → side quest appears
6. Simulate Masterwork completion → side quest marks complete

This is the canonical "Spec 1 ships green" check.

#### Tests NOT added in Spec 1

- No puzzle solving tests (Spec 2)
- No daily/side-quest accept/turn-in tests (Spec 6)
- No achievement trigger tests (Spec 6)

### 5.2 Implementation order

Single PR, internally staged so each commit compiles and behaves correctly:

1. **Model layer** — create `quest.dart`, `codex.dart`, `milestone.dart` with all new types. Empty static registries. Game still compiles and behaves identically.
2. **Engine state** — add new fields and getters to `GameEngine`. No observers wired yet.
3. **Observer plumbing** — add `_notifyQuestObservers` + `QuestEvent` classes. Wire all existing engine method appends.
4. **Quest lifecycle methods** — `offerQuest`, `acceptQuest`, `turnInQuest`, `abandonQuest`, `_maybeCompleteQuest`, `_grantReward`. Stream broadcasting.
5. **Milestone engine** — `Milestones.all`, tick-side check, dedup set, `milestoneEvents` stream. Add `town_square_restored`.
6. **Starter quest bootstrapping** — `_bootstrapStarterQuests` in constructor + `_maybeOfferMasterworkQuest` on skill-up.
7. **Quest Log chip + popover** — Dashboard widget + bottom sheet.
8. **Codex view** — new file, tabbed shell, Quests/Beasts/Regions content panes.
9. **Cartographer's Tent** — Town Square action list integration + Codex navigation.
10. **World Event UI** — `WorldEventModal`, `WorldEventBanner`, `WorldEventListener`, activity log style.
11. **Tests** — written alongside each step, not bundled at end.

### 5.3 Migration & backward compatibility

The game has no persistence; no save-file migration needed. New engine state initializes empty/defaulted.

Player-facing first-launch change after Spec 1 ships:
- Restore Town Square quest appears in Quest Log chip immediately
- Restoring stations (which the player would do anyway) advances the quest organically
- After both restored, the milestone modal fires — a *new moment* that didn't exist before

The bootstrap puts the quest in `_activeQuests` at engine construction (before any restoration could happen), so timing is safe.

### 5.4 Documentation updates

- `README.md` — add a brief "Codex & Quests" section noting the new Town Square fixture
- Inline `///` doc comments on new public engine methods (Dart convention)

### 5.5 Risks & deferrals

- **Quest UI feels empty in Spec 1.** Only one main quest + occasional side quests. Mitigation: the restoration is genuinely engaging early game; side quests appear naturally on skill-ups. Spec 2 + Spec 6 fill the gaps soon.
- **Observer dispatch overhead.** `_notifyQuestObservers` iterates active quests on every gameplay event. With ~3–8 active quests typical, microsecond cost. Not a concern.
- **Milestone tick-checking inefficiency.** Checking `Milestones.all.trigger(engine)` on every tick could become slow if Spec 2/4/5 push the milestone count high (~50+). Mitigation: dedup set short-circuits already-fired; trigger functions must be cheap. If perf becomes an issue, batch to once per second.
- **Deferred to Spec 2:** Codex Fragments content, puzzle UI, additional milestones
- **Deferred to Spec 6:** Achievement tracking, Tavern Notice Board, daily tasks

### 5.6 Player walkthrough — what shipping looks like

A player starting a fresh app after Spec 1:

1. Sees a new **📜 Restore Town Square 0/2** chip on the Dashboard
2. Restores the bench (chip updates to **1/2**)
3. Restores the kitchen (chip becomes **✓ Ready** briefly, then the screen dims and a modal appears — *"As you hammer the last beam into place, the town stirs..."*)
4. Dismisses the modal. The chip is gone. A new card appears in Town Square's actions: **🗺️ Cartographer's Tent**
5. Taps the tent → Codex opens with Quests / Beasts / Regions tabs
6. Beasts tab empty; Regions shows scouted zones; Quests shows the completed restoration in history
7. Hunts a boar — opens Codex → Beasts tab now shows Forest Boar with defeat count and drop history
8. Hits level 10 in Woodcutting → a chip pops up: **📜 Skill Trial: The Ironbark Trial 0/1**
9. Completes the trial → chip clears, side quest appears in completed history

The game is visibly better. Nothing else changed.
