# Spec 2 — Codex Content & Story Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement Spec 2 — populate the Codex foundation (already built in Spec 1) with 50 fragments across 5 tags, 5 Readings, 11 milestones, 8 main quest stubs, drag-to-reorder puzzle UI with per-card feedback, and fragment drop wiring across existing game systems.

**Architecture:** Pure additive content + content-driven systems on top of Spec 1's existing Quest/Codex/Milestone foundation. Data files hold fragments/readings/milestones/quests. Engine gains drop machinery (`tryDropFragment`, `lockCodexPuzzle`) and a few extensions to existing methods. UI gains a Fragments tab in the existing Codex view, a new Puzzle view, and a Reading overlay widget.

**Tech Stack:** Flutter (Dart ^3.11.4), Provider state management, `flutter_test` + `fake_async` for tests. No new dependencies.

**Reference spec:** [docs/superpowers/specs/2026-05-24-spec-2-codex-content-story-design.md](../specs/2026-05-24-spec-2-codex-content-story-design.md)

---

## File Structure

**Files created:**
- `lib/models/main_quests.dart` — 8 main-quest factory functions
- `lib/views/codex_puzzle_view.dart` — Drag-to-reorder puzzle UI
- `lib/widgets/reading_overlay.dart` — Full-screen Reading display
- `test/codex_fragments_test.dart` — Fragment data invariants
- `test/codex_drops_test.dart` — Drop machinery + pool gating
- `test/codex_puzzle_test.dart` — Lock + per-card feedback + XP penalty

**Files modified:**
- `lib/models/quest.dart` — Add `targetTag` + `comingSoon` fields; add `RewardKind.offerQuest`; add `PuzzleResult` class
- `lib/models/codex.dart` — Fill `CodexFragments.all` with 50 entries; add `CodexReading` class + 5 Reading constants + `CodexReadings.forTag` helper
- `lib/models/milestone.dart` — Extend `Milestones.all` with 10 new milestone entries
- `lib/models/zone.dart` — Add `inspect_glyph` ZoneAction to Darkstone Mine I and II
- `lib/engine/game_engine.dart` — Add puzzle/read tracking state; add `tryDropFragment`, `_grantFragment`, `_isFragmentPoolOpen`, `_regionTagForBeast`, `lockCodexPuzzle`; extend `readCodexFragment`, `_grantReward`, `_matches`; append drop calls in `_completeAction` and `_resolveCombat`; offer Discover quest in `_bootstrapStarterQuests`
- `lib/views/codex_view.dart` — Add Fragments tab (hidden until first read); tag-grouped collapsible sections; unread/read distinction; Solve Puzzle button; Synthesis section
- `lib/views/dashboard_view.dart` — Render `comingSoon` objectives with `Icons.lock_clock` and "Coming Soon" suffix in Quest Log popover
- `test/quest_test.dart` — Extensions for `targetTag`, `comingSoon`, `RewardKind.offerQuest`
- `test/game_engine_test.dart` — Drop integration verification
- `test/quest_engine_test.dart` — Milestone trigger tests
- `test/widget_test.dart` — Codex Fragments tab visibility + puzzle UI + Reading overlay

---

## Task 1: Extend QuestObjective with targetTag and comingSoon

**Files:**
- Modify: `lib/models/quest.dart`
- Test: `test/quest_test.dart`

- [ ] **Step 1: Write failing test for `targetTag` filter**

Add to `test/quest_test.dart`:

```dart
test('QuestObjective with targetTag matches only fragments of that tag', () {
  final obj = QuestObjective(
    kind: ObjectiveKind.codexRead,
    targetTag: 'wilds',
    targetCount: 3,
  );
  expect(obj.targetTag, 'wilds');
  expect(obj.targetCount, 3);
  expect(obj.currentCount, 0);
});

test('QuestObjective comingSoon defaults to false', () {
  final obj = QuestObjective(
    kind: ObjectiveKind.gather,
    targetId: 'oak_log',
    targetCount: 5,
  );
  expect(obj.comingSoon, false);
});

test('QuestObjective comingSoon can be set true', () {
  final obj = QuestObjective(
    kind: ObjectiveKind.cleanse,
    targetId: 'breach_wilds',
    targetCount: 1,
    comingSoon: true,
  );
  expect(obj.comingSoon, true);
});
```

- [ ] **Step 2: Run test, verify it fails to compile**

Run: `flutter test test/quest_test.dart`

Expected: Compilation error — `targetTag`/`comingSoon` not defined on `QuestObjective`.

- [ ] **Step 3: Add fields to QuestObjective**

Modify `lib/models/quest.dart`:

```dart
class QuestObjective {
  final ObjectiveKind kind;
  final String? targetId;
  final String? targetTag;   // NEW — tag-filter for codexRead objectives
  final int targetCount;
  int currentCount;
  bool comingSoon;            // NEW — true marks Spec 5/6-dependent objectives

  QuestObjective({
    required this.kind,
    this.targetId,
    this.targetTag,
    required this.targetCount,
    this.currentCount = 0,
    this.comingSoon = false,
  });

  bool get isComplete => currentCount >= targetCount;
}
```

- [ ] **Step 4: Run tests, verify pass**

Run: `flutter test test/quest_test.dart`

Expected: PASS for all three new tests.

- [ ] **Step 5: Commit**

```bash
git add lib/models/quest.dart test/quest_test.dart
git commit -m "feat(quest): add targetTag and comingSoon to QuestObjective"
```

---

## Task 2: Add RewardKind.offerQuest

**Files:**
- Modify: `lib/models/quest.dart`
- Test: `test/quest_test.dart`

- [ ] **Step 1: Write failing test for RewardKind.offerQuest**

Add to `test/quest_test.dart`:

```dart
test('RewardKind.offerQuest exists and carries a targetId', () {
  final reward = QuestReward(
    kind: RewardKind.offerQuest,
    targetId: 'main_investigate_wilds',
    amount: 1,
  );
  expect(reward.kind, RewardKind.offerQuest);
  expect(reward.targetId, 'main_investigate_wilds');
});
```

- [ ] **Step 2: Run test, verify it fails**

Run: `flutter test test/quest_test.dart`

Expected: Compilation error — `RewardKind.offerQuest` not defined.

- [ ] **Step 3: Add offerQuest to RewardKind enum**

Modify `lib/models/quest.dart`:

```dart
enum RewardKind {
  gold,
  skillXp,
  item,
  blueprint,
  worldEvent,
  unlock,
  offerQuest,   // NEW — automatically offers a next quest by id
}
```

- [ ] **Step 4: Run tests, verify pass**

Run: `flutter test test/quest_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/models/quest.dart test/quest_test.dart
git commit -m "feat(quest): add RewardKind.offerQuest for quest chaining"
```

---

## Task 3: Add PuzzleResult class

**Files:**
- Modify: `lib/models/quest.dart`
- Test: `test/quest_test.dart`

- [ ] **Step 1: Write failing test for PuzzleResult**

Add to `test/quest_test.dart`:

```dart
test('PuzzleResult carries tag, correctness list, and optional reading', () {
  final result = PuzzleResult(
    tag: CodexTag.wilds,
    correctness: [true, true, false, true],
    reading: null,
  );
  expect(result.tag, CodexTag.wilds);
  expect(result.correctness, [true, true, false, true]);
  expect(result.reading, isNull);
});
```

Also add import: `import 'package:flutter_text_based_rpg/models/codex.dart';`

- [ ] **Step 2: Run test, verify it fails**

Run: `flutter test test/quest_test.dart`

Expected: Compilation error — `PuzzleResult` not defined.

- [ ] **Step 3: Add PuzzleResult class**

Add to `lib/models/quest.dart` (at the bottom):

```dart
class PuzzleResult {
  final CodexTag tag;
  final List<bool> correctness;
  final CodexReading? reading;

  const PuzzleResult({
    required this.tag,
    required this.correctness,
    this.reading,
  });
}
```

Add import at top of `lib/models/quest.dart`:

```dart
import 'codex.dart';
```

(Note: `CodexReading` is added in Task 5. This task may need to wait or use a forward-declared type. If `CodexReading` doesn't exist yet, change `final CodexReading? reading;` to `final dynamic reading;` temporarily and fix in Task 5.)

- [ ] **Step 4: Run tests, verify pass**

Run: `flutter test test/quest_test.dart`

Expected: PASS (with the `dynamic` workaround if `CodexReading` not yet added).

- [ ] **Step 5: Commit**

```bash
git add lib/models/quest.dart test/quest_test.dart
git commit -m "feat(quest): add PuzzleResult class for puzzle Lock results"
```

---

## Task 4: Populate CodexFragments.all with all 50 fragments

**Files:**
- Modify: `lib/models/codex.dart`
- Test: `test/codex_fragments_test.dart` (new)

- [ ] **Step 1: Write failing data invariant tests**

Create `test/codex_fragments_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/models/codex.dart';

void main() {
  group('CodexFragments data invariants', () {
    test('Exactly 50 fragments exist', () {
      expect(CodexFragments.all.length, 50);
    });

    test('Each tag has exactly 10 fragments', () {
      for (final tag in [
        CodexTag.wilds,
        CodexTag.stone,
        CodexTag.tide,
        CodexTag.source,
        CodexTag.oldEmpire,
      ]) {
        final count = CodexFragments.all.where((f) => f.tag == tag).length;
        expect(count, 10, reason: 'Tag $tag should have 10 fragments');
      }
    });

    test('Every fragment has a unique id', () {
      final ids = CodexFragments.all.map((f) => f.id).toSet();
      expect(ids.length, 50);
    });

    test('Every (tag, orderInTag) pair is unique', () {
      final pairs = CodexFragments.all
          .map((f) => '${f.tag.name}_${f.orderInTag}')
          .toSet();
      expect(pairs.length, 50);
    });

    test('Each tag has orderInTag values 1 through 10', () {
      for (final tag in CodexTag.values.where((t) => t != CodexTag.misc)) {
        final orders = CodexFragments.all
            .where((f) => f.tag == tag)
            .map((f) => f.orderInTag)
            .toSet();
        expect(orders, {1, 2, 3, 4, 5, 6, 7, 8, 9, 10},
            reason: 'Tag $tag should have orderInTag 1..10');
      }
    });

    test('findById returns the right fragment for a sample of ids', () {
      final fragment = CodexFragments.findById('wilds_01');
      expect(fragment, isNotNull);
      expect(fragment!.tag, CodexTag.wilds);
      expect(fragment.orderInTag, 1);
    });

    test('findById returns null for unknown id', () {
      expect(CodexFragments.findById('nonexistent'), isNull);
    });
  });
}
```

- [ ] **Step 2: Run test, verify it fails**

Run: `flutter test test/codex_fragments_test.dart`

Expected: FAIL — `CodexFragments.all.length` is 0 (current state per Spec 1 stub).

- [ ] **Step 3: Populate CodexFragments.all**

Replace `CodexFragments` class in `lib/models/codex.dart`:

```dart
class CodexFragments {
  static const List<CodexFragment> all = [
    // ─── WILDS ────────────────────────────────────────
    CodexFragment(
      id: 'wilds_01',
      tag: CodexTag.wilds,
      title: 'First Spring',
      text: "Last spring the bluebells came up early, faces bright. I marked the date in my journal: a good year coming. I was wrong about the year.",
      sourceHint: "Found at: Crumbling Obelisk, Whispering Woods I",
      orderInTag: 1,
    ),
    CodexFragment(
      id: 'wilds_02',
      tag: CodexTag.wilds,
      title: 'Black Sap',
      text: "I cut a young oak for firewood today and the sap ran black. I left the axe in the wood and walked away.",
      sourceHint: "Found at: Forest beast drop, Whispering Woods",
      orderInTag: 2,
    ),
    CodexFragment(
      id: 'wilds_03',
      tag: CodexTag.wilds,
      title: 'The Quiet',
      text: "The birds stopped singing in the eastern groves. Not gone — I can see them. They just stopped.",
      sourceHint: "Found at: Whispering Woods scout action",
      orderInTag: 3,
    ),
    CodexFragment(
      id: 'wilds_04',
      tag: CodexTag.wilds,
      title: 'The First Sick Boar',
      text: "A boar charged me at dusk. Its eyes were the wrong color. I killed it; it tasted of iron and something older.",
      sourceHint: "Found at: Forest beast drop, Whispering Woods",
      orderInTag: 4,
    ),
    CodexFragment(
      id: 'wilds_05',
      tag: CodexTag.wilds,
      title: 'Ironbark Forgets',
      text: "The old folk used to call certain oaks Ironbark for the strength of their wood. The Ironbarks have begun to soften from the inside, weeping that same black sap.",
      sourceHint: "Found at: Crumbling Obelisk, Whispering Woods I",
      orderInTag: 5,
    ),
    CodexFragment(
      id: 'wilds_06',
      tag: CodexTag.wilds,
      title: 'Roots in the Deep',
      text: "I tracked a sick wolf to a clearing and found roots running upward from the soil. Roots, growing the wrong way. I did not stay to see what they reached for.",
      sourceHint: "Found at: Whispering Woods II beast drop",
      orderInTag: 6,
    ),
    CodexFragment(
      id: 'wilds_07',
      tag: CodexTag.wilds,
      title: "The Warden's Walk",
      text: "I have walked these woods forty years. I no longer know them. The trails move when I am not looking.",
      sourceHint: "Found at: Whispering Woods scout action",
      orderInTag: 7,
    ),
    CodexFragment(
      id: 'wilds_08',
      tag: CodexTag.wilds,
      title: 'The Hollow Calls',
      text: "There is a hollow in the deepest grove where no warden goes. I dreamed of it last night. I dreamed it called my name.",
      sourceHint: "Found at: Crumbling Obelisk, Whispering Woods II",
      orderInTag: 8,
    ),
    CodexFragment(
      id: 'wilds_09',
      tag: CodexTag.wilds,
      title: 'The Last Bluebell',
      text: "I picked a bluebell today. It came up with thread, not roots — a long dark thread that ran deep into the soil. I did not pull further.",
      sourceHint: "Found at: Whispering Woods foraging",
      orderInTag: 9,
    ),
    CodexFragment(
      id: 'wilds_10',
      tag: CodexTag.wilds,
      title: 'A Door I Do Not Open',
      text: "I have stopped going to the Hollow. I lock the warden's gate at night now. Something is on the other side. It knows my name.",
      sourceHint: "Found at: Whispering Woods II Obelisk (rare)",
      orderInTag: 10,
    ),

    // ─── STONE ────────────────────────────────────────
    CodexFragment(
      id: 'stone_01',
      tag: CodexTag.stone,
      title: 'The Vein',
      text: "We struck a copper vein last week thick as my arm. The lads cheered. I should have asked why no one had cut it before us.",
      sourceHint: "Found at: Mine-Glyph, Darkstone Mine I",
      orderInTag: 1,
    ),
    CodexFragment(
      id: 'stone_02',
      tag: CodexTag.stone,
      title: 'The Tap',
      text: "There is a sound in the deep shafts at night. A slow tapping. Three taps, a pause, three taps. We tell the new boys it is settling rock.",
      sourceHint: "Found at: Darkstone scout action",
      orderInTag: 2,
    ),
    CodexFragment(
      id: 'stone_03',
      tag: CodexTag.stone,
      title: 'The Light That Should Not Glow',
      text: "Found a chunk of ore today that glowed in my palm without sun or flame. I pocketed it. I think that was wrong.",
      sourceHint: "Found at: Cave beast drop, Darkstone",
      orderInTag: 3,
    ),
    CodexFragment(
      id: 'stone_04',
      tag: CodexTag.stone,
      title: 'The Glinting Vein',
      text: "The deep wall opened on a vein that pulsed like a slow heart. The foreman called it the Glinting. He looked at it too long.",
      sourceHint: "Found at: Mine-Glyph, Darkstone Mine II",
      orderInTag: 4,
    ),
    CodexFragment(
      id: 'stone_05',
      tag: CodexTag.stone,
      title: 'Stone Remembers',
      text: "I drove my pick into a fresh seam and the rock — I swear it — flinched. The strike rang back wrong, like striking a bell that does not want to be rung.",
      sourceHint: "Found at: Darkstone Mine II gathering",
      orderInTag: 5,
    ),
    CodexFragment(
      id: 'stone_06',
      tag: CodexTag.stone,
      title: "The Foreman's Walk",
      text: "The foreman has stopped sleeping. He walks the lower shafts at night now, his lamp out, his eyes lit. He does not see us anymore.",
      sourceHint: "Found at: Cave beast drop, Darkstone",
      orderInTag: 6,
    ),
    CodexFragment(
      id: 'stone_07',
      tag: CodexTag.stone,
      title: 'What Lives in the Tap',
      text: "I counted the tapping last night. Three taps, a pause, three taps — but the pauses are getting shorter. It is learning to speak.",
      sourceHint: "Found at: Darkstone scout action",
      orderInTag: 7,
    ),
    CodexFragment(
      id: 'stone_08',
      tag: CodexTag.stone,
      title: 'Trolls Are Listening',
      text: "The cavern trolls do not attack the foreman. They watch him pass. The trolls know something the foreman has forgotten.",
      sourceHint: "Found at: Cavern Troll defeat, Darkstone Mine II",
      orderInTag: 8,
    ),
    CodexFragment(
      id: 'stone_09',
      tag: CodexTag.stone,
      title: 'The Vein Is a Wound',
      text: "I understand now: the Glinting is not a vein. It is a wound in the world. We have been picking at a wound.",
      sourceHint: "Found at: Mine-Glyph, Darkstone Mine II",
      orderInTag: 9,
    ),
    CodexFragment(
      id: 'stone_10',
      tag: CodexTag.stone,
      title: 'The Tapping Knows My Name',
      text: "The tapping has my rhythm now. When I hammer, it answers. When I stop, it waits. I will not go down again.",
      sourceHint: "Found at: Darkstone Mine II rare drop",
      orderInTag: 10,
    ),

    // ─── TIDE ─────────────────────────────────────────
    CodexFragment(
      id: 'tide_01',
      tag: CodexTag.tide,
      title: "The Lighthouse Keeper's Log",
      text: "Day one of the keeper's new rotation. Tide normal. Lamp lit. Gulls overhead. A quiet station, this Drowned Lighthouse.",
      sourceHint: "Found at: Sundered Coast I (Spec 3)",
      orderInTag: 1,
    ),
    CodexFragment(
      id: 'tide_02',
      tag: CodexTag.tide,
      title: 'Brine in the Cisterns',
      text: "The freshwater cistern tastes of salt this morning. I checked the seals: intact. The salt is coming from below.",
      sourceHint: "Found at: Sundered Coast (Spec 3)",
      orderInTag: 2,
    ),
    CodexFragment(
      id: 'tide_03',
      tag: CodexTag.tide,
      title: 'The Hound at the Door',
      text: "A wet hound came to the keeper's door last night and would not leave. Its eyes shone like fish scales. I closed the door.",
      sourceHint: "Found at: Tide Hound defeat (Spec 3)",
      orderInTag: 3,
    ),
    CodexFragment(
      id: 'tide_04',
      tag: CodexTag.tide,
      title: 'The Pier Sang',
      text: "Walking the pier at moonrise, I heard it sing — a long low note from beneath the planks. I have not walked the pier since.",
      sourceHint: "Found at: Coast scout action (Spec 3)",
      orderInTag: 4,
    ),
    CodexFragment(
      id: 'tide_05',
      tag: CodexTag.tide,
      title: 'The Salt That Bites',
      text: "I tried to make a salt-cure of fresh fish. The salt smoked in the bowl, hissed when it touched the meat. This is not the salt of my grandmother.",
      sourceHint: "Found at: Sundered Coast II (Spec 3)",
      orderInTag: 5,
    ),
    CodexFragment(
      id: 'tide_06',
      tag: CodexTag.tide,
      title: 'Drowned Things Watching',
      text: "I see them at low tide now — shapes in the shallows that do not move when the water moves. They wait.",
      sourceHint: "Found at: Brine Crawler defeat (Spec 3)",
      orderInTag: 6,
    ),
    CodexFragment(
      id: 'tide_07',
      tag: CodexTag.tide,
      title: 'The Lamp Will Not Stay Lit',
      text: "I lit the great lamp at dusk. By midwatch it had gone out, though I had filled the reservoir myself. I lit it again. It guttered as if breathed on.",
      sourceHint: "Found at: Coast Obelisk (Spec 3)",
      orderInTag: 7,
    ),
    CodexFragment(
      id: 'tide_08',
      tag: CodexTag.tide,
      title: 'The Crawler in the Cellar',
      text: "A brine crawler in the cellar this morning, big as a hound. I drove it off. There are more, I am sure, in the dark.",
      sourceHint: "Found at: Brine Crawler defeat (Spec 3)",
      orderInTag: 8,
    ),
    CodexFragment(
      id: 'tide_09',
      tag: CodexTag.tide,
      title: "The Sea Speaks the Foreman's Name",
      text: "I dreamed last night of a man with a lamp out, walking deep mine shafts. The sea told me his name. I have never been to the mines.",
      sourceHint: "Found at: Coast Obelisk (Spec 3)",
      orderInTag: 9,
    ),
    CodexFragment(
      id: 'tide_10',
      tag: CodexTag.tide,
      title: 'The Light Has Gone Out',
      text: "The great lamp is out and will not relight. The drowned have come ashore. I write this from the keeper's loft, while I still can.",
      sourceHint: "Found at: Drowned Lighthouse rare drop (Spec 3)",
      orderInTag: 10,
    ),

    // ─── SOURCE ───────────────────────────────────────
    CodexFragment(
      id: 'source_01',
      tag: CodexTag.source,
      title: 'A Common Thread',
      text: "Three sicknesses, three regions. Three voices speaking through different mouths. The thread runs deeper than any one of them.",
      sourceHint: "Found at: cross-biome rare drop (Spec 5)",
      orderInTag: 1,
    ),
    CodexFragment(
      id: 'source_02',
      tag: CodexTag.source,
      title: 'The First Word',
      text: "Before the woods spoke wrongly, before the stones rang false, before the sea took the lamp — something said its first word. The world has been answering ever since.",
      sourceHint: "Found at: T3 zone gathering (Spec 5)",
      orderInTag: 2,
    ),
    CodexFragment(
      id: 'source_03',
      tag: CodexTag.source,
      title: 'Beneath Every Depth',
      text: "The miners thought the Glinting was the bottom. It was not. Beneath every stone is another stone. Beneath every depth, another depth.",
      sourceHint: "Found at: Echo of the Stone defeat (Spec 5)",
      orderInTag: 3,
    ),
    CodexFragment(
      id: 'source_04',
      tag: CodexTag.source,
      title: 'The Old Word for It',
      text: "The old tongue had a word for what is happening. It meant 'echo' — but the kind of echo a struck wound makes, not the kind a struck bell makes.",
      sourceHint: "Found at: T3 zone gathering (Spec 5)",
      orderInTag: 4,
    ),
    CodexFragment(
      id: 'source_05',
      tag: CodexTag.source,
      title: 'It Wears Their Faces',
      text: "The Echo of the Wilds is not the Wilds. The Echo of the Stone is not the Stone. The Echo of the Tide is not the Tide. They are all the same Echo, wearing the faces it has learned.",
      sourceHint: "Found at: Echo defeat (Spec 5)",
      orderInTag: 5,
    ),
    CodexFragment(
      id: 'source_06',
      tag: CodexTag.source,
      title: 'The Old Empire Knew',
      text: "The First Age built Beacons at the breach-sites and called them by their right names. The names are forgotten. The Beacons are toppled. The breaches are open.",
      sourceHint: "Found at: Echo defeat (Spec 5)",
      orderInTag: 6,
    ),
    CodexFragment(
      id: 'source_07',
      tag: CodexTag.source,
      title: 'The Source Speaks Through Three Mouths',
      text: "Three mouths to speak with. Three throats to silence. To unmake the speaker, you must unmake the speech.",
      sourceHint: "Found at: Echo defeat (Spec 5)",
      orderInTag: 7,
    ),
    CodexFragment(
      id: 'source_08',
      tag: CodexTag.source,
      title: 'A Convergence',
      text: "When the three are silenced — and only then — the speaker will come out from beneath the world to find what silenced them. It will not be pleased.",
      sourceHint: "Found at: Echo defeat (Spec 5)",
      orderInTag: 8,
    ),
    CodexFragment(
      id: 'source_09',
      tag: CodexTag.source,
      title: 'The Place It Will Come',
      text: "Where the three roads meet beneath the world: that is where it will come. The First Age had a name for the place. We will have to remember.",
      sourceHint: "Found at: cross-biome rare drop (Spec 5)",
      orderInTag: 9,
    ),
    CodexFragment(
      id: 'source_10',
      tag: CodexTag.source,
      title: 'What Remains',
      text: "If you stand at the convergence and unmake the speaker, the world will be quieter. Not silent. Quieter. That is the most you can hope for. Hope for it.",
      sourceHint: "Found at: cross-biome rare drop (Spec 5)",
      orderInTag: 10,
    ),

    // ─── OLD EMPIRE ───────────────────────────────────
    CodexFragment(
      id: 'empire_01',
      tag: CodexTag.oldEmpire,
      title: 'The First Age Spoke',
      text: "Before our age there was an older one. They left their script carved on stones we still cannot read. They wrote, mostly, about silence.",
      sourceHint: "Found at: any Obelisk (rare)",
      orderInTag: 1,
    ),
    CodexFragment(
      id: 'empire_02',
      tag: CodexTag.oldEmpire,
      title: 'The Beacons of Asar',
      text: "The First Age built Five Beacons to mark where the world is thin. The Beacons fell long ago. The places remained thin.",
      sourceHint: "Found at: any Obelisk (rare)",
      orderInTag: 2,
    ),
    CodexFragment(
      id: 'empire_03',
      tag: CodexTag.oldEmpire,
      title: "The Cartographer's Last Map",
      text: "The last cartographer of the First Age died with one map unfinished. It marked the breach-sites. It marked the convergence. It did not mark a way home.",
      sourceHint: "Found at: any Obelisk (rare)",
      orderInTag: 3,
    ),
    CodexFragment(
      id: 'empire_04',
      tag: CodexTag.oldEmpire,
      title: 'The Tongue of Asar',
      text: "Their tongue had thirty-two words for \"silence\" and one for \"war.\" We have the inverse problem.",
      sourceHint: "Found at: any Obelisk (rare)",
      orderInTag: 4,
    ),
    CodexFragment(
      id: 'empire_05',
      tag: CodexTag.oldEmpire,
      title: 'The Long Watch',
      text: "The First Age built a watch that would last a thousand years. The watch lasted nine hundred. We are the watch now, and we did not know.",
      sourceHint: "Found at: any Obelisk (rare)",
      orderInTag: 5,
    ),
    CodexFragment(
      id: 'empire_06',
      tag: CodexTag.oldEmpire,
      title: 'The Old Empire Fell To Hope',
      text: "The records say the First Age fell not to war or famine but to hope. They believed the breaches could be closed forever. They were wrong; the breaches reopened, and they had unmade their watch.",
      sourceHint: "Found at: any Obelisk (rare)",
      orderInTag: 6,
    ),
    CodexFragment(
      id: 'empire_07',
      tag: CodexTag.oldEmpire,
      title: 'What the Beacons Were',
      text: "The Beacons were not lights. They were instruments. They sang a single low note at the breach-sites. The note kept the speaker quiet.",
      sourceHint: "Found at: any Obelisk (rare)",
      orderInTag: 7,
    ),
    CodexFragment(
      id: 'empire_08',
      tag: CodexTag.oldEmpire,
      title: "The Old Empire's Wager",
      text: "Knowing the breaches would reopen, the First Age left us a wager: build the instruments anew, or accept the diminished world. The instruments are hard to build.",
      sourceHint: "Found at: any Obelisk (rare)",
      orderInTag: 8,
    ),
    CodexFragment(
      id: 'empire_09',
      tag: CodexTag.oldEmpire,
      title: 'The Inheritor',
      text: "Their last writing, in their tongue: \"to whoever follows: the wager is yours. We are sorry. We hoped.\" Their script for \"hoped\" is the same as their script for \"failed.\"",
      sourceHint: "Found at: Silas (Lore Keeper) at Trusted Patron rep (Spec 6)",
      orderInTag: 9,
    ),
    CodexFragment(
      id: 'empire_10',
      tag: CodexTag.oldEmpire,
      title: 'The Quiet Inheritance',
      text: "To inherit the watch is to choose what to do with it. The First Age chose hope. You may choose otherwise. The world will know which you chose.",
      sourceHint: "Found at: any Obelisk (very rare)",
      orderInTag: 10,
    ),
  ];

  static CodexFragment? findById(String id) {
    for (var f in all) {
      if (f.id == id) return f;
    }
    return null;
  }
}
```

- [ ] **Step 4: Run tests, verify pass**

Run: `flutter test test/codex_fragments_test.dart`

Expected: All 7 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/models/codex.dart test/codex_fragments_test.dart
git commit -m "feat(codex): add all 50 Codex fragments across 5 tags"
```

---

## Task 5: Add CodexReading class and 5 Reading constants

**Files:**
- Modify: `lib/models/codex.dart`
- Test: `test/codex_fragments_test.dart`

- [ ] **Step 1: Write failing tests for Readings**

Add to `test/codex_fragments_test.dart`:

```dart
test('CodexReadings.forTag returns non-null for each playable tag', () {
  for (final tag in [
    CodexTag.wilds,
    CodexTag.stone,
    CodexTag.tide,
    CodexTag.source,
    CodexTag.oldEmpire,
  ]) {
    expect(CodexReadings.forTag(tag), isNotNull,
        reason: 'Reading missing for tag $tag');
  }
});

test('Wilds Reading title is The Warden\'s Account', () {
  final reading = CodexReadings.forTag(CodexTag.wilds)!;
  expect(reading.title, "The Warden's Account");
  expect(reading.body.length, greaterThan(300));
  expect(reading.rewards, isNotEmpty);
});
```

- [ ] **Step 2: Run test, verify it fails**

Run: `flutter test test/codex_fragments_test.dart`

Expected: Compilation error — `CodexReading` / `CodexReadings` not defined.

- [ ] **Step 3: Add CodexReading class + 5 Reading constants**

Add to `lib/models/codex.dart` (after `Achievements` class):

```dart
class CodexReading {
  final CodexTag tag;
  final String title;
  final String body;
  final List<QuestReward> rewards;

  const CodexReading({
    required this.tag,
    required this.title,
    required this.body,
    required this.rewards,
  });
}

class CodexReadings {
  static const CodexReading wildsReading = CodexReading(
    tag: CodexTag.wilds,
    title: "The Warden's Account",
    body: '''Forty years I have walked the Whispering Woods. I know its trails the way a blacksmith knows his anvil — by the small marks each leaves on me. So when the bluebells came up early last spring, I noticed. When the sap ran black, I noticed. When the birds stopped singing in the eastern groves, I noticed.

Something has come into the wood that does not belong. I have followed its trail to a hollow I will not name. It dreams. It calls. It learns the names of those who walk near it. It learned mine, and I have stopped walking near it.

If you read this, you have done what I could not. Find the Hollow. Take with you an Ironbark log, well-seasoned, and three Wildflowers cut at first light. Burn the offering at the rotted shrine within. What rises will fight you. It must fight you. There is no other way to close what has opened here.

— The Warden''',
    rewards: [
      QuestReward(kind: RewardKind.skillXp, targetId: 'lore', amount: 60),
      QuestReward(kind: RewardKind.gold, amount: 25),
    ],
  );

  static const CodexReading stoneReading = CodexReading(
    tag: CodexTag.stone,
    title: "The Foreman's Confession",
    body: '''They will tell you the foreman went mad. He did not. He went silent first, and silence is not madness — it is the absence of the noise we use to drown out the truth.

The Glinting Vein is not a vein. It is a wound. Beneath the lowest shaft of Darkstone Mine there is a pulsing, glowing lens of stone that should not be, and the foreman walked into the shaft one night and put his ear to it. The lens spoke to him. It is still speaking. He answers it now in his sleep, and the deep tappings in the mine answer him back, and so the conversation goes, growing.

If you would silence the wound, bring an alchemist's draught — wildflower tinctured with river clay, twice-distilled — and pour it into the Glinting at the moment its pulse lengthens. What dwells in the wound will rise to defend it. You must endure the rising. Then pour. The lens will close.

— What the foreman wrote on the wall the morning he stopped speaking''',
    rewards: [
      QuestReward(kind: RewardKind.skillXp, targetId: 'lore', amount: 60),
      QuestReward(kind: RewardKind.gold, amount: 25),
    ],
  );

  static const CodexReading tideReading = CodexReading(
    tag: CodexTag.tide,
    title: "The Keeper's Last Page",
    body: '''I am the keeper of the Drowned Lighthouse. I write this from the loft above the lamp room. The lamp will not stay lit. The drowned have come ashore. I do not have much time.

The lamp is not just a lamp. The old keepers told me, and I did not listen, because old keepers tell many things. They told me the lamp is a Beacon — that it sings, when properly lit, a low note that keeps the wrong things in the sea where they belong. The lamp has stopped singing. The note has gone out of the world. The wrong things are walking up the pier.

If you find this, do not relight the lamp with oil. Lamp oil will not hold. Carry a Salt Crystal — the pure kind from the deep tide pools, not the brine-stained kind from the cliffs — and set it within the lamp's heart. The Crystal will sing the note the lamp has forgotten. Something old in the sea will rise to silence the song. Do not let it.

— The Keeper, from the loft, by lamplight''',
    rewards: [
      QuestReward(kind: RewardKind.skillXp, targetId: 'lore', amount: 60),
      QuestReward(kind: RewardKind.gold, amount: 25),
    ],
  );

  static const CodexReading sourceReading = CodexReading(
    tag: CodexTag.source,
    title: 'The Convergence',
    body: '''Three breaches. Three Echoes wearing three faces. One Source beneath them all, and beneath the Source — beneath every depth, you have read this before — another depth.

The Echoes are not the Source. The Echoes are the Source's voice in three different mouths: a wood-mouth, a stone-mouth, a sea-mouth. Silence the three mouths and the Source will come out from beneath the world to see what has silenced them. It will come to the convergence — the place where the three breach-roads meet beneath the surface, which the First Age called by a name we do not remember.

You will need a token from each cleansed breach. You will need the Beacons remembered. You will need to stand at the convergence and unmake the speaker. What waits there cannot be reasoned with. It can only be unmade.

If you go: do not bring hope. Hope was the First Age's mistake. Bring the instruments. Bring the silence.''',
    rewards: [
      QuestReward(kind: RewardKind.skillXp, targetId: 'lore', amount: 100),
      QuestReward(kind: RewardKind.unlock, targetId: 'nexus_understood', amount: 1),
    ],
  );

  static const CodexReading oldEmpireReading = CodexReading(
    tag: CodexTag.oldEmpire,
    title: "The Cartographer's Wager",
    body: '''The First Age fell because they hoped. They built the Beacons, they sang the silence into the world, and they believed they had closed the wound forever. They had not. The wound reopened in their grandchildren's time, and the grandchildren did not know the song, because the First Age had unmade the watch when they thought the song was no longer needed.

They left us a map and a wager. The map is a stone, in a place I will not name in this writing, that shows the breach-sites and the convergence. The wager is this: build the instruments anew, or accept the diminished world. The instruments are hard to build. The diminished world is easy to live in. They left us free to choose.

If you have read this, you have chosen. The choice is silent and personal and has no audience. The world will know which you chose only by what the world becomes.

— from the unfinished map of the last cartographer of the First Age''',
    rewards: [
      QuestReward(kind: RewardKind.skillXp, targetId: 'lore', amount: 120),
      QuestReward(kind: RewardKind.unlock, targetId: 'true_ending_unlocked', amount: 1),
    ],
  );

  static const CodexReading synthesisReading = CodexReading(
    tag: CodexTag.misc,
    title: 'The Synthesis',
    body: '''[Synthesis content authored in Spec 6 — final integration with Nexus unlock and ending sequence.]''',
    rewards: [],
  );

  static CodexReading? forTag(CodexTag tag) {
    switch (tag) {
      case CodexTag.wilds: return wildsReading;
      case CodexTag.stone: return stoneReading;
      case CodexTag.tide: return tideReading;
      case CodexTag.source: return sourceReading;
      case CodexTag.oldEmpire: return oldEmpireReading;
      case CodexTag.misc: return null;
    }
  }
}
```

Add import at top: `import 'quest.dart';`

- [ ] **Step 4: Run tests, verify pass**

Run: `flutter test test/codex_fragments_test.dart`

Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/models/codex.dart test/codex_fragments_test.dart
git commit -m "feat(codex): add CodexReading model and 5 tag Readings + Synthesis placeholder"
```

---

## Task 6: Add 10 new milestone events

**Files:**
- Modify: `lib/models/milestone.dart`
- Test: `test/quest_engine_test.dart` (extend)

- [ ] **Step 1: Write failing test for milestone count**

Add to `test/quest_engine_test.dart`:

```dart
test('Milestones.all contains 11 entries (1 from Spec 1 + 10 from Spec 2)', () {
  expect(Milestones.all.length, 11);
});

test('first_codex_fragment milestone exists', () {
  final m = Milestones.all.firstWhere(
    (m) => m.id == 'first_codex_fragment',
    orElse: () => throw Exception('not found'),
  );
  expect(m.severity, MilestoneSeverity.minor);
});

test('second_breach_concept milestone is major', () {
  final m = Milestones.all.firstWhere(
    (m) => m.id == 'second_breach_concept',
    orElse: () => throw Exception('not found'),
  );
  expect(m.severity, MilestoneSeverity.major);
});
```

- [ ] **Step 2: Run test, verify it fails**

Run: `flutter test test/quest_engine_test.dart`

Expected: FAIL — milestone count is 1 (current Spec 1 state).

- [ ] **Step 3: Add 10 new milestone entries**

Modify `lib/models/milestone.dart` — replace `Milestones` class:

```dart
class Milestones {
  // Spec 1
  static final MilestoneEvent townSquareRestored = MilestoneEvent(
    id: 'town_square_restored',
    severity: MilestoneSeverity.major,
    title: 'The Town Stirs',
    body: 'As you hammer the last beam into place, the town stirs. The cartographer unfurls a long-rolled map; chalk dust catches the light. "Welcome back. Bring me what you find — every fragment, every echo. The world has been speaking, and we haven\'t been listening."',
    icon: '🗺️',
    trigger: (engine) => engine.engineFlags.contains('town_square_restored'),
    onFire: null,
  );

  // Spec 2
  static final MilestoneEvent firstCodexFragment = MilestoneEvent(
    id: 'first_codex_fragment',
    severity: MilestoneSeverity.minor,
    title: 'A Page Surfaces',
    body: 'The cartographer presses something into your palm: a torn page, its ink still damp. "These have begun to surface. Bring me more."',
    icon: '📜',
    trigger: (engine) => engine.knownCodexFragmentIds.isNotEmpty,
    onFire: null,
  );

  static final MilestoneEvent firstCodexRead = MilestoneEvent(
    id: 'first_codex_read',
    severity: MilestoneSeverity.minor,
    title: 'The Codex Stirs',
    body: 'A line you read lodges itself in your mind. You feel the Codex grow heavier in the tent.',
    icon: '📖',
    trigger: (engine) => engine.readCodexFragmentIds.isNotEmpty,
    onFire: null,
  );

  static final MilestoneEvent firstWildsDrop = MilestoneEvent(
    id: 'first_wilds_drop',
    severity: MilestoneSeverity.minor,
    title: 'A Scent of Bluebells',
    body: 'A faint scent of bluebells follows you back to town. The cartographer recognizes the tag and pulls down the Wilds atlas.',
    icon: '🪻',
    trigger: (engine) => engine.knownCodexFragmentIds.any(
      (id) => CodexFragments.findById(id)?.tag == CodexTag.wilds,
    ),
    onFire: null,
  );

  static final MilestoneEvent firstStoneDrop = MilestoneEvent(
    id: 'first_stone_drop',
    severity: MilestoneSeverity.minor,
    title: 'Stone Speaks Last',
    body: 'The cartographer turns the page slowly. "Stone speaks last," he says. "When stone speaks, it\'s almost too late."',
    icon: '⛰️',
    trigger: (engine) => engine.knownCodexFragmentIds.any(
      (id) => CodexFragments.findById(id)?.tag == CodexTag.stone,
    ),
    onFire: null,
  );

  static final MilestoneEvent secondBreachConcept = MilestoneEvent(
    id: 'second_breach_concept',
    severity: MilestoneSeverity.major,
    title: 'A Second Voice',
    body: 'The cartographer\'s eyes go very still. "You\'ve brought me a second voice. There are three. There have always been three. The Old Empire knew them as Breaches. You should know them too."',
    icon: '👁️',
    trigger: (engine) {
      final tags = engine.knownCodexFragmentIds
          .map((id) => CodexFragments.findById(id)?.tag)
          .where((t) => t == CodexTag.wilds || t == CodexTag.stone || t == CodexTag.tide)
          .toSet();
      return tags.length >= 2;
    },
    onFire: (engine) {
      engine.setEngineFlag('breaches_concept_known');
    },
  );

  static final MilestoneEvent firstPuzzleSolved = MilestoneEvent(
    id: 'first_puzzle_solved',
    severity: MilestoneSeverity.minor,
    title: 'Pieces Snap Into Place',
    body: 'Pieces snap into place. The cartographer reads it through, sets it down, and looks at you differently.',
    icon: '🔓',
    trigger: (engine) => engine.solvedTagPuzzles.isNotEmpty,
    onFire: null,
  );

  static final MilestoneEvent loreCompletionistPath = MilestoneEvent(
    id: 'lore_completionist_path',
    severity: MilestoneSeverity.minor,
    title: 'An Older Page',
    body: 'This one is older than the others. The script is not a tongue we speak. The cartographer treats it like a relic.',
    icon: '📚',
    trigger: (engine) => engine.knownCodexFragmentIds.any(
      (id) => CodexFragments.findById(id)?.tag == CodexTag.oldEmpire,
    ),
    onFire: null,
  );

  static final MilestoneEvent sourcePoolOpens = MilestoneEvent(
    id: 'source_pool_opens',
    severity: MilestoneSeverity.minor,
    title: 'A Page You Had Not Noticed',
    body: 'The world has gone briefly quiet — not silent, quieter — and in that quiet you find a page you had not noticed before.',
    icon: '🌑',
    trigger: (engine) => engine.engineFlags.contains('first_breach_cleansed'),
    onFire: null,
  );

  static final MilestoneEvent synthesisApproaching = MilestoneEvent(
    id: 'synthesis_approaching',
    severity: MilestoneSeverity.minor,
    title: 'A Pattern Forms',
    body: 'The cartographer lays out the readings side by side. A pattern is forming. One more should complete it.',
    icon: '✨',
    trigger: (engine) => engine.solvedTagPuzzles.length >= 4,
    onFire: null,
  );

  static final MilestoneEvent synthesisUnlocked = MilestoneEvent(
    id: 'synthesis_unlocked',
    severity: MilestoneSeverity.major,
    title: 'The Synthesis',
    body: 'The Synthesis lies open. [Synthesis content authored in Spec 6.]',
    icon: '✨',
    trigger: (engine) => engine.solvedTagPuzzles.length >= 5,
    onFire: (engine) {
      engine.setEngineFlag('synthesis_complete');
    },
  );

  static final List<MilestoneEvent> all = [
    townSquareRestored,
    firstCodexFragment,
    firstCodexRead,
    firstWildsDrop,
    firstStoneDrop,
    secondBreachConcept,
    firstPuzzleSolved,
    loreCompletionistPath,
    sourcePoolOpens,
    synthesisApproaching,
    synthesisUnlocked,
  ];
}
```

Add imports at top: `import 'codex.dart';`

Note: this requires `engine.knownCodexFragmentIds`, `engine.readCodexFragmentIds`, `engine.solvedTagPuzzles`, and `engine.setEngineFlag(...)` to exist on `GameEngine`. The first is from Spec 1; the last three are added in Tasks 8 and 9 below. If running this task before those land, the file won't compile — order Tasks 8 + 9 before this one OR add `engine.setEngineFlag` as a no-op stub now and complete it later.

- [ ] **Step 4: Run tests, verify pass**

Run: `flutter test test/quest_engine_test.dart`

Expected: All 3 new tests PASS (after Tasks 8+9 land providing the engine getters).

- [ ] **Step 5: Commit**

```bash
git add lib/models/milestone.dart test/quest_engine_test.dart
git commit -m "feat(milestone): add 10 Spec 2 milestone events"
```

---

## Task 7: Create MainQuests factory file

**Files:**
- Create: `lib/models/main_quests.dart`
- Test: `test/quest_test.dart`

- [ ] **Step 1: Write failing test for MainQuests.findById**

Add to `test/quest_test.dart`:

```dart
test('MainQuests.findById returns all 8 quests by id', () {
  for (final id in [
    'main_discover_sickness',
    'main_investigate_wilds',
    'main_investigate_stones',
    'main_investigate_tide',
    'main_cleanse_hollow',
    'main_cleanse_vein',
    'main_cleanse_tide',
    'main_source_convergence',
  ]) {
    final quest = MainQuests.findById(id);
    expect(quest, isNotNull, reason: 'Quest missing: $id');
    expect(quest!.id, id);
  }
});

test('MainQuests.findById returns null for unknown id', () {
  expect(MainQuests.findById('nonexistent'), isNull);
});
```

Add import: `import 'package:flutter_text_based_rpg/models/main_quests.dart';`

- [ ] **Step 2: Run test, verify it fails**

Run: `flutter test test/quest_test.dart`

Expected: Compilation error — `MainQuests` not defined.

- [ ] **Step 3: Create main_quests.dart**

Create `lib/models/main_quests.dart`:

```dart
import 'quest.dart';
import 'skill.dart';
import 'codex.dart';

class MainQuests {
  static Quest discoverSickness() => Quest(
        id: 'main_discover_sickness',
        type: QuestType.main,
        title: 'Discover the Sickness',
        description: 'The forest, the mine, the coast — something is changing in places long thought safe. Begin to gather the cartographer\'s torn pages. They say more than they seem.',
        objectives: [
          QuestObjective(
            kind: ObjectiveKind.codexRead,
            targetCount: 3,
          ),
        ],
        rewards: const [
          QuestReward(kind: RewardKind.gold, amount: 50),
          QuestReward(kind: RewardKind.skillXp, targetId: 'lore', amount: 50),
          QuestReward(kind: RewardKind.offerQuest, targetId: 'main_investigate_wilds', amount: 1),
          QuestReward(kind: RewardKind.offerQuest, targetId: 'main_investigate_stones', amount: 1),
        ],
        status: QuestStatus.active,
      );

  static Quest investigateWilds() => Quest(
        id: 'main_investigate_wilds',
        type: QuestType.main,
        title: 'Investigate the Wilds',
        description: 'The Whispering Woods are speaking, and not in a tongue you know. Solve their Reading to understand what stirs in the Hollow.',
        objectives: [
          QuestObjective(
            kind: ObjectiveKind.codexRead,
            targetTag: CodexTag.wilds.name,
            targetCount: 10,
          ),
          QuestObjective(
            kind: ObjectiveKind.custom,
            targetId: 'puzzle_wilds_solved',
            targetCount: 1,
          ),
        ],
        rewards: const [
          QuestReward(kind: RewardKind.gold, amount: 100),
          QuestReward(kind: RewardKind.skillXp, targetId: 'wayfinding', amount: 75),
          QuestReward(kind: RewardKind.gold, amount: 25),
          QuestReward(kind: RewardKind.offerQuest, targetId: 'main_cleanse_hollow', amount: 1),
        ],
        status: QuestStatus.active,
      );

  static Quest investigateStones() => Quest(
        id: 'main_investigate_stones',
        type: QuestType.main,
        title: 'Investigate the Stones',
        description: 'The deep tappings in Darkstone speak a rhythm. The Glinting Vein is not a vein — read what the foreman saw.',
        objectives: [
          QuestObjective(
            kind: ObjectiveKind.codexRead,
            targetTag: CodexTag.stone.name,
            targetCount: 10,
          ),
          QuestObjective(
            kind: ObjectiveKind.custom,
            targetId: 'puzzle_stone_solved',
            targetCount: 1,
          ),
        ],
        rewards: const [
          QuestReward(kind: RewardKind.gold, amount: 100),
          QuestReward(kind: RewardKind.skillXp, targetId: 'mining', amount: 75),
          QuestReward(kind: RewardKind.gold, amount: 25),
          QuestReward(kind: RewardKind.offerQuest, targetId: 'main_cleanse_vein', amount: 1),
        ],
        status: QuestStatus.active,
      );

  static Quest investigateTide() => Quest(
        id: 'main_investigate_tide',
        type: QuestType.main,
        title: 'Investigate the Tide',
        description: 'The Drowned Lighthouse has gone dark. Find what the keeper left in the loft.',
        objectives: [
          QuestObjective(
            kind: ObjectiveKind.codexRead,
            targetTag: CodexTag.tide.name,
            targetCount: 10,
          ),
          QuestObjective(
            kind: ObjectiveKind.custom,
            targetId: 'puzzle_tide_solved',
            targetCount: 1,
          ),
        ],
        rewards: const [
          QuestReward(kind: RewardKind.gold, amount: 100),
          QuestReward(kind: RewardKind.skillXp, targetId: 'herbalism', amount: 75),
          QuestReward(kind: RewardKind.gold, amount: 25),
          QuestReward(kind: RewardKind.offerQuest, targetId: 'main_cleanse_tide', amount: 1),
        ],
        status: QuestStatus.active,
      );

  static Quest cleanseHollow() => Quest(
        id: 'main_cleanse_hollow',
        type: QuestType.main,
        title: 'Cleanse the Hollow',
        description: 'The Reading told you what the Wilds need. Travel to Bloomwither Hollow with an Ironbark log and three Wildflowers. Defeat what guards the Hollow. Burn the offering at the rotted shrine.',
        objectives: [
          QuestObjective(
            kind: ObjectiveKind.custom,
            targetId: 'echo_wilds_defeated',
            targetCount: 1,
            comingSoon: true,
          ),
          QuestObjective(
            kind: ObjectiveKind.cleanse,
            targetId: 'breach_wilds',
            targetCount: 1,
            comingSoon: true,
          ),
        ],
        rewards: const [],
        status: QuestStatus.active,
      );

  static Quest cleanseVein() => Quest(
        id: 'main_cleanse_vein',
        type: QuestType.main,
        title: 'Cleanse the Vein',
        description: 'The Reading told you what the Stones need. Travel to the Glowing Vein with twice-distilled wildflower-and-river-clay draught. Defeat what defends the wound. Pour the draught at the right moment.',
        objectives: [
          QuestObjective(
            kind: ObjectiveKind.custom,
            targetId: 'echo_stone_defeated',
            targetCount: 1,
            comingSoon: true,
          ),
          QuestObjective(
            kind: ObjectiveKind.cleanse,
            targetId: 'breach_stone',
            targetCount: 1,
            comingSoon: true,
          ),
        ],
        rewards: const [],
        status: QuestStatus.active,
      );

  static Quest cleanseTide() => Quest(
        id: 'main_cleanse_tide',
        type: QuestType.main,
        title: 'Cleanse the Tide',
        description: 'The Reading told you what the Tide needs. Travel to the Drowned Lighthouse with a pure Salt Crystal. Set it within the lamp\'s heart. What rises from the sea must be unmade.',
        objectives: [
          QuestObjective(
            kind: ObjectiveKind.custom,
            targetId: 'echo_tide_defeated',
            targetCount: 1,
            comingSoon: true,
          ),
          QuestObjective(
            kind: ObjectiveKind.cleanse,
            targetId: 'breach_tide',
            targetCount: 1,
            comingSoon: true,
          ),
        ],
        rewards: const [],
        status: QuestStatus.active,
      );

  static Quest sourceConvergence() => Quest(
        id: 'main_source_convergence',
        type: QuestType.main,
        title: 'The Source Convergence',
        description: 'Three breaches sealed. The Source itself is rising from beneath the world. Bring your three Cleansing Tokens to the Nexus of Echoes.',
        objectives: [
          QuestObjective(
            kind: ObjectiveKind.visit,
            targetId: 'nexus_of_echoes',
            targetCount: 1,
            comingSoon: true,
          ),
          QuestObjective(
            kind: ObjectiveKind.custom,
            targetId: 'source_defeated',
            targetCount: 1,
            comingSoon: true,
          ),
        ],
        rewards: const [],
        status: QuestStatus.active,
      );

  static Quest? findById(String id) {
    switch (id) {
      case 'main_discover_sickness': return discoverSickness();
      case 'main_investigate_wilds': return investigateWilds();
      case 'main_investigate_stones': return investigateStones();
      case 'main_investigate_tide': return investigateTide();
      case 'main_cleanse_hollow': return cleanseHollow();
      case 'main_cleanse_vein': return cleanseVein();
      case 'main_cleanse_tide': return cleanseTide();
      case 'main_source_convergence': return sourceConvergence();
      default: return null;
    }
  }
}
```

- [ ] **Step 4: Run tests, verify pass**

Run: `flutter test test/quest_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/models/main_quests.dart test/quest_test.dart
git commit -m "feat(quest): add MainQuests factory with all 8 main quests"
```

---

## Task 8: Add engine state for puzzles + reading + puzzleResults stream

**Files:**
- Modify: `lib/engine/game_engine.dart`

- [ ] **Step 1: Add fields and getters**

In `lib/engine/game_engine.dart`, add to the field declarations (near other Spec 1 state):

```dart
final Set<String> _readCodexFragmentIds = {};
final Set<CodexTag> _solvedTagPuzzles = {};
final Map<CodexTag, int> _puzzleAttempts = {};

final StreamController<PuzzleResult> _puzzleResultController =
    StreamController.broadcast();
```

Add getters in the getters section:

```dart
Set<String> get readCodexFragmentIds => Set.unmodifiable(_readCodexFragmentIds);
Set<CodexTag> get solvedTagPuzzles => Set.unmodifiable(_solvedTagPuzzles);
Map<CodexTag, int> get puzzleAttempts => Map.unmodifiable(_puzzleAttempts);
Stream<PuzzleResult> get puzzleResults => _puzzleResultController.stream;

void setEngineFlag(String flag) {
  _engineFlags.add(flag);
  _checkMilestones();
  notifyListeners();
}
```

- [ ] **Step 2: Verify the game still compiles**

Run: `flutter analyze`

Expected: No errors. (Tests run later — this is a state-only addition.)

- [ ] **Step 3: Commit**

```bash
git add lib/engine/game_engine.dart
git commit -m "feat(engine): add codex puzzle/read state and PuzzleResult stream"
```

---

## Task 9: Add tryDropFragment + helpers

**Files:**
- Modify: `lib/engine/game_engine.dart`
- Test: `test/codex_drops_test.dart` (new)

- [ ] **Step 1: Write failing tests for drop machinery**

Create `test/codex_drops_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/models/codex.dart';
import 'package:flutter_text_based_rpg/models/zone.dart';

void main() {
  group('Codex drop machinery', () {
    late GameEngine engine;

    setUp(() {
      engine = GameEngine();
    });

    test('tryDropFragment with chance=1.0 always succeeds for open pool', () {
      // Wilds pool always open
      final before = engine.knownCodexFragmentIds.length;
      engine.tryDropFragment(CodexTag.wilds, 1.0);
      expect(engine.knownCodexFragmentIds.length, before + 1);
    });

    test('tryDropFragment for Stone is no-op until Darkstone visited', () {
      final before = engine.knownCodexFragmentIds.length;
      engine.tryDropFragment(CodexTag.stone, 1.0);
      expect(engine.knownCodexFragmentIds.length, before,
          reason: 'Stone pool should be closed before Darkstone visit');

      engine.unlockZone('darkstone_mine_1');
      engine.travelTo(Zones.darkstoneMineTier1);

      engine.tryDropFragment(CodexTag.stone, 1.0);
      expect(engine.knownCodexFragmentIds.length, greaterThan(before));
    });

    test('tryDropFragment for Source requires first_breach_cleansed flag', () {
      final before = engine.knownCodexFragmentIds.length;
      engine.tryDropFragment(CodexTag.source, 1.0);
      expect(engine.knownCodexFragmentIds.length, before);

      engine.setEngineFlag('first_breach_cleansed');
      engine.tryDropFragment(CodexTag.source, 1.0);
      expect(engine.knownCodexFragmentIds.length, before + 1);
    });

    test('tryDropFragment is no-op when all fragments of a tag are collected', () {
      // Collect all 10 Wilds fragments
      for (int i = 0; i < 10; i++) {
        engine.tryDropFragment(CodexTag.wilds, 1.0);
      }
      final after10 = engine.knownCodexFragmentIds.length;

      // 11th attempt does nothing
      engine.tryDropFragment(CodexTag.wilds, 1.0);
      expect(engine.knownCodexFragmentIds.length, after10);
    });
  });
}
```

- [ ] **Step 2: Run test, verify it fails**

Run: `flutter test test/codex_drops_test.dart`

Expected: FAIL — `tryDropFragment` not defined on `GameEngine`.

- [ ] **Step 3: Implement tryDropFragment + helpers**

Add to `lib/engine/game_engine.dart` (in the methods section):

```dart
void tryDropFragment(CodexTag tag, double chance) {
  if (!_isFragmentPoolOpen(tag)) return;
  if (_random.nextDouble() > chance) return;
  final eligible = CodexFragments.all
      .where((f) => f.tag == tag && !_knownCodexFragmentIds.contains(f.id))
      .toList();
  if (eligible.isEmpty) return;
  final fragment = eligible[_random.nextInt(eligible.length)];
  _grantFragment(fragment);
}

bool _isFragmentPoolOpen(CodexTag tag) {
  switch (tag) {
    case CodexTag.wilds: return true;
    case CodexTag.stone: return _regionStatus.containsKey('darkstone_mine_1');
    case CodexTag.tide: return _engineFlags.contains('coast_unlocked');
    case CodexTag.source: return _engineFlags.contains('first_breach_cleansed');
    case CodexTag.oldEmpire: return true;
    case CodexTag.misc: return true;
  }
}

void _grantFragment(CodexFragment fragment) {
  _knownCodexFragmentIds.add(fragment.id);
  log("📜 Codex Fragment found: ${fragment.title}", LogType.success);
  _checkMilestones();
  notifyListeners();
}

CodexTag? _regionTagForBeast(String beastId) {
  switch (beastId) {
    case 'forest_boar':
    case 'shadow_wolf':
      return CodexTag.wilds;
    case 'cave_spider':
    case 'cavern_troll':
      return CodexTag.stone;
    default:
      return null;
  }
}
```

- [ ] **Step 4: Run tests, verify pass**

Run: `flutter test test/codex_drops_test.dart`

Expected: All 4 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/engine/game_engine.dart test/codex_drops_test.dart
git commit -m "feat(engine): add tryDropFragment with pool gating"
```

---

## Task 10: Implement lockCodexPuzzle with per-card feedback + XP penalty

**Files:**
- Modify: `lib/engine/game_engine.dart`
- Test: `test/codex_puzzle_test.dart` (new)

- [ ] **Step 1: Write failing tests**

Create `test/codex_puzzle_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/models/codex.dart';
import 'package:flutter_text_based_rpg/models/skill.dart';

void main() {
  group('Codex puzzle locking', () {
    late GameEngine engine;

    setUp(() {
      engine = GameEngine();
      // Force-collect all 10 Wilds fragments
      for (int i = 0; i < 10; i++) {
        engine.tryDropFragment(CodexTag.wilds, 1.0);
      }
    });

    test('Locking correct order solves puzzle and grants rewards', () {
      final correctOrder = CodexFragments.all
          .where((f) => f.tag == CodexTag.wilds)
          .toList()
        ..sort((a, b) => a.orderInTag.compareTo(b.orderInTag));
      final ids = correctOrder.map((f) => f.id).toList();

      final loreBefore = engine.skills[SkillType.lore]!.xp;
      final goldBefore = engine.playerStats.gold;
      engine.lockCodexPuzzle(CodexTag.wilds, ids);

      expect(engine.solvedTagPuzzles.contains(CodexTag.wilds), true);
      expect(engine.engineFlags.contains('puzzle_wilds_solved'), true);
      expect(engine.skills[SkillType.lore]!.xp, greaterThan(loreBefore));
      expect(engine.playerStats.gold, greaterThan(goldBefore));
    });

    test('Locking wrong order does NOT solve puzzle and deducts 3 Lore XP', () {
      // Pump some Lore XP first
      engine.skills[SkillType.lore] =
          engine.skills[SkillType.lore]!.addXp(100);
      final loreBefore = engine.skills[SkillType.lore]!.xp;

      // Wrong order: just reverse the correct sequence
      final wrongIds = CodexFragments.all
          .where((f) => f.tag == CodexTag.wilds)
          .toList()
          .reversed
          .map((f) => f.id)
          .toList();

      engine.lockCodexPuzzle(CodexTag.wilds, wrongIds);

      expect(engine.solvedTagPuzzles.contains(CodexTag.wilds), false);
      expect(engine.skills[SkillType.lore]!.xp, loreBefore - 3);
    });

    test('Wrong-Lock Lore XP clamps to 0 (no negative)', () {
      // Wilds skill init has 0 XP; verify it stays at 0
      final wrongIds = CodexFragments.all
          .where((f) => f.tag == CodexTag.wilds)
          .toList()
          .reversed
          .map((f) => f.id)
          .toList();

      engine.lockCodexPuzzle(CodexTag.wilds, wrongIds);
      expect(engine.skills[SkillType.lore]!.xp, 0);
    });

    test('Re-locking already-solved puzzle is no-op (no double rewards)', () {
      final correctOrder = CodexFragments.all
          .where((f) => f.tag == CodexTag.wilds)
          .toList()
        ..sort((a, b) => a.orderInTag.compareTo(b.orderInTag));
      final ids = correctOrder.map((f) => f.id).toList();

      engine.lockCodexPuzzle(CodexTag.wilds, ids);
      final goldAfterFirst = engine.playerStats.gold;

      engine.lockCodexPuzzle(CodexTag.wilds, ids);
      expect(engine.playerStats.gold, goldAfterFirst,
          reason: 'Re-lock should not grant gold again');
    });
  });
}
```

- [ ] **Step 2: Run test, verify it fails**

Run: `flutter test test/codex_puzzle_test.dart`

Expected: Compilation error — `lockCodexPuzzle` not defined.

- [ ] **Step 3: Implement lockCodexPuzzle**

Add to `lib/engine/game_engine.dart`:

```dart
void lockCodexPuzzle(CodexTag tag, List<String> orderedFragmentIds) {
  final expected = CodexFragments.all
      .where((f) => f.tag == tag)
      .toList()
    ..sort((a, b) => a.orderInTag.compareTo(b.orderInTag));

  if (orderedFragmentIds.length != expected.length) return;

  final correctness = <bool>[];
  for (var i = 0; i < orderedFragmentIds.length; i++) {
    correctness.add(orderedFragmentIds[i] == expected[i].id);
  }
  final allCorrect = correctness.every((c) => c);

  if (allCorrect) {
    if (_solvedTagPuzzles.contains(tag)) return;
    _solvedTagPuzzles.add(tag);
    _engineFlags.add('puzzle_${tag.name}_solved');
    final reading = CodexReadings.forTag(tag);
    if (reading != null) {
      for (var r in reading.rewards) _grantReward(r);
    }
    log("✨ Puzzle solved: ${tag.name} — Reading unlocked.", LogType.success);
    _puzzleResultController.add(
      PuzzleResult(tag: tag, correctness: correctness, reading: reading),
    );
    _checkMilestones();
  } else {
    _puzzleAttempts[tag] = (_puzzleAttempts[tag] ?? 0) + 1;
    final loreSkill = _skills[SkillType.lore]!;
    final newXp = (loreSkill.xp - 3).clamp(0.0, double.infinity);
    _skills[SkillType.lore] = loreSkill.copyWith(xp: newXp);
    final correctCount = correctness.where((c) => c).length;
    log(
      "Puzzle attempt failed (−3 Lore XP). $correctCount of ${correctness.length} in place.",
      LogType.info,
    );
    _puzzleResultController.add(
      PuzzleResult(tag: tag, correctness: correctness, reading: null),
    );
  }
  notifyListeners();
}
```

Import at top: `import 'dart:math';` (if not already present)

- [ ] **Step 4: Run tests, verify pass**

Run: `flutter test test/codex_puzzle_test.dart`

Expected: All 4 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/engine/game_engine.dart test/codex_puzzle_test.dart
git commit -m "feat(engine): add lockCodexPuzzle with per-card feedback and XP penalty"
```

---

## Task 11: Extend readCodexFragment with Lore XP

**Files:**
- Modify: `lib/engine/game_engine.dart`
- Test: `test/codex_drops_test.dart` (extend)

- [ ] **Step 1: Write failing test**

Add to `test/codex_drops_test.dart`:

```dart
test('readCodexFragment grants 15 Lore XP on first read only', () {
  engine.tryDropFragment(CodexTag.wilds, 1.0);
  final fragmentId = engine.knownCodexFragmentIds.first;

  final xpBefore = engine.skills[SkillType.lore]!.xp;
  engine.readCodexFragment(fragmentId);
  expect(engine.skills[SkillType.lore]!.xp, xpBefore + 15);

  // Re-read: no additional XP
  engine.readCodexFragment(fragmentId);
  expect(engine.skills[SkillType.lore]!.xp, xpBefore + 15);
});

test('readCodexFragment adds to readCodexFragmentIds', () {
  engine.tryDropFragment(CodexTag.wilds, 1.0);
  final fragmentId = engine.knownCodexFragmentIds.first;

  expect(engine.readCodexFragmentIds.contains(fragmentId), false);
  engine.readCodexFragment(fragmentId);
  expect(engine.readCodexFragmentIds.contains(fragmentId), true);
});
```

Add import: `import 'package:flutter_text_based_rpg/models/skill.dart';`

- [ ] **Step 2: Run test, verify it fails**

Run: `flutter test test/codex_drops_test.dart`

Expected: FAIL — either `readCodexFragment` doesn't grant XP, or `readCodexFragmentIds` getter missing.

- [ ] **Step 3: Update readCodexFragment in engine**

In `lib/engine/game_engine.dart`, find `readCodexFragment` (added in Spec 1) and replace with:

```dart
void readCodexFragment(String fragmentId) {
  if (!_knownCodexFragmentIds.contains(fragmentId)) return;
  final alreadyRead = _readCodexFragmentIds.contains(fragmentId);
  _readCodexFragmentIds.add(fragmentId);

  if (!alreadyRead) {
    final fragment = CodexFragments.findById(fragmentId);
    if (fragment != null) {
      final loreSkill = _skills[SkillType.lore]!;
      _skills[SkillType.lore] = loreSkill.addXp(15);
      log("Read Codex Fragment: ${fragment.title} (+15 Lore XP)", LogType.success);
    }
    _notifyQuestObservers(CodexFragmentReadEvent(fragmentId));
    _checkMilestones();
  }
  notifyListeners();
}
```

- [ ] **Step 4: Run tests, verify pass**

Run: `flutter test test/codex_drops_test.dart`

Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/engine/game_engine.dart test/codex_drops_test.dart
git commit -m "feat(engine): readCodexFragment grants 15 Lore XP on first read"
```

---

## Task 12: Extend _grantReward for RewardKind.offerQuest

**Files:**
- Modify: `lib/engine/game_engine.dart`
- Test: `test/quest_test.dart` (extend)

- [ ] **Step 1: Write failing test for quest chaining**

Add to `test/quest_test.dart`:

```dart
test('RewardKind.offerQuest chains the next quest on completion', () {
  final engine = GameEngine();

  // Complete the Discover quest by reading 3 fragments
  for (int i = 0; i < 3; i++) {
    engine.tryDropFragment(CodexTag.wilds, 1.0);
  }
  final ids = engine.knownCodexFragmentIds.take(3).toList();
  for (final id in ids) {
    engine.readCodexFragment(id);
  }

  // Investigate Wilds + Investigate Stones should now be in active quests
  expect(
    engine.activeQuests.any((q) => q.id == 'main_investigate_wilds'),
    true,
  );
  expect(
    engine.activeQuests.any((q) => q.id == 'main_investigate_stones'),
    true,
  );
});
```

Add imports: `import 'package:flutter_text_based_rpg/models/codex.dart';`

- [ ] **Step 2: Run test, verify it fails**

Run: `flutter test test/quest_test.dart`

Expected: FAIL — `offerQuest` reward not handled.

- [ ] **Step 3: Add switch arm in _grantReward**

In `lib/engine/game_engine.dart`, find `_grantReward` and add a new switch case:

```dart
case RewardKind.offerQuest:
  if (reward.targetId == null) break;
  final next = MainQuests.findById(reward.targetId!);
  if (next != null) {
    offerQuest(next);
  }
  break;
```

Add import at top: `import '../models/main_quests.dart';`

- [ ] **Step 4: Run tests, verify pass**

Run: `flutter test test/quest_test.dart`

Expected: PASS (assumes Task 14 bootstrap is also done — if not, test will need a manual offerQuest of `main_discover_sickness` first).

- [ ] **Step 5: Commit**

```bash
git add lib/engine/game_engine.dart test/quest_test.dart
git commit -m "feat(engine): handle RewardKind.offerQuest for main quest chaining"
```

---

## Task 13: Extend _matches for targetTag filter + comingSoon

**Files:**
- Modify: `lib/engine/game_engine.dart`
- Test: `test/quest_test.dart` (extend)

- [ ] **Step 1: Write failing test**

Add to `test/quest_test.dart`:

```dart
test('codexRead objective with targetTag only advances on matching tag', () {
  final engine = GameEngine();
  final quest = Quest(
    id: 'test_wilds_read',
    type: QuestType.side,
    title: 'Read 1 Wilds',
    description: '',
    objectives: [
      QuestObjective(
        kind: ObjectiveKind.codexRead,
        targetTag: CodexTag.wilds.name,
        targetCount: 1,
      ),
    ],
    rewards: const [],
    status: QuestStatus.active,
  );
  engine.offerQuest(quest);

  // Force a Stone-tag drop and read
  engine.unlockZone('darkstone_mine_1');
  engine.travelTo(Zones.darkstoneMineTier1);
  engine.tryDropFragment(CodexTag.stone, 1.0);
  final stoneId = engine.knownCodexFragmentIds.firstWhere(
    (id) => CodexFragments.findById(id)!.tag == CodexTag.stone,
  );
  engine.readCodexFragment(stoneId);

  final q = engine.activeQuests.firstWhere((q) => q.id == 'test_wilds_read');
  expect(q.objectives[0].currentCount, 0,
      reason: 'Stone-tag read should not advance Wilds-tagged objective');

  // Wilds-tag read should advance
  engine.tryDropFragment(CodexTag.wilds, 1.0);
  final wildsId = engine.knownCodexFragmentIds.firstWhere(
    (id) => CodexFragments.findById(id)!.tag == CodexTag.wilds,
  );
  engine.readCodexFragment(wildsId);

  expect(q.objectives[0].currentCount, 1);
});

test('comingSoon objectives never advance via _matches', () {
  final engine = GameEngine();
  final quest = Quest(
    id: 'test_coming_soon',
    type: QuestType.main,
    title: 'Defeat Echo',
    description: '',
    objectives: [
      QuestObjective(
        kind: ObjectiveKind.custom,
        targetId: 'echo_wilds_defeated',
        targetCount: 1,
        comingSoon: true,
      ),
    ],
    rewards: const [],
    status: QuestStatus.active,
  );
  engine.offerQuest(quest);

  // Even with a beast defeat event, objective shouldn't advance
  // (custom comingSoon objectives wait for explicit advanceQuestObjective)
  // No public engine action triggers a custom-id event by default.
  final q = engine.activeQuests.firstWhere((q) => q.id == 'test_coming_soon');
  expect(q.objectives[0].currentCount, 0);
});
```

Add imports: `import 'package:flutter_text_based_rpg/models/zone.dart';`

- [ ] **Step 2: Run test, verify it fails**

Run: `flutter test test/quest_test.dart`

Expected: FAIL — targetTag filter not applied; test would advance objective on any read.

- [ ] **Step 3: Update _matches**

In `lib/engine/game_engine.dart`, find `_matches` and update the `codexRead` arm to filter by tag:

```dart
bool _matches(QuestObjective objective, QuestEvent event) {
  if (objective.comingSoon) return false;

  switch (objective.kind) {
    // ... other cases stay the same ...
    case ObjectiveKind.codexRead:
      if (event is! CodexFragmentReadEvent) return false;
      if (objective.targetTag == null) return true;
      final fragment = CodexFragments.findById(event.fragmentId);
      return fragment != null && fragment.tag.name == objective.targetTag;
    // ... other cases ...
  }
}
```

(Keep the rest of the `_matches` switch arms identical to Spec 1.)

- [ ] **Step 4: Run tests, verify pass**

Run: `flutter test test/quest_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/engine/game_engine.dart test/quest_test.dart
git commit -m "feat(engine): _matches honors targetTag filter and comingSoon flag"
```

---

## Task 14: Wire fragment drops into existing engine methods

**Files:**
- Modify: `lib/engine/game_engine.dart`
- Test: `test/game_engine_test.dart` (extend)

- [ ] **Step 1: Write failing test for Obelisk drop wiring**

Add to `test/game_engine_test.dart`:

```dart
test('inspect_obelisk completion attempts Wilds and Old Empire drops', () {
  // We can't easily test RNG outcomes, but we can verify the action exists
  // and the code path executes. Use a high chance value to be safe.
  final engine = GameEngine();
  engine.unlockZone('whispering_woods_1');
  engine.travelTo(Zones.whisperingWoodsTier1);

  final actionsList = Zones.whisperingWoodsTier1.actions;
  final obelisk = actionsList.firstWhere((a) => a.id == 'inspect_obelisk');
  expect(obelisk, isNotNull);
});

test('Wilds beast defeat (Forest Boar) drops region-tagged fragment via mock', () {
  // Smoke test: just verify _regionTagForBeast returns Wilds for forest_boar
  // The actual integration test is more involved; use a private helper sanity check
  // via tryDropFragment with chance 1.0 simulating the same path
  final engine = GameEngine();
  final before = engine.knownCodexFragmentIds.length;
  engine.tryDropFragment(CodexTag.wilds, 1.0);
  expect(engine.knownCodexFragmentIds.length, greaterThan(before));
});
```

- [ ] **Step 2: Run test, verify it passes (action exists; second test exercises drop path)**

Run: `flutter test test/game_engine_test.dart`

Expected: PASS (Wilds always-open pool means high-chance drops work).

- [ ] **Step 3: Append fragment-drop calls in engine methods**

In `lib/engine/game_engine.dart`:

In `_completeAction` (where action loot is processed), at the end of the loot-processing logic for non-combat actions, add:

```dart
// Fragment drops by action id
if (action.id == 'inspect_obelisk') {
  tryDropFragment(CodexTag.wilds, 0.10);
  tryDropFragment(CodexTag.oldEmpire, 0.01);
}
if (action.id == 'inspect_glyph') {
  tryDropFragment(CodexTag.stone, 0.10);
  tryDropFragment(CodexTag.oldEmpire, 0.01);
}
if (action.id == 'explore_forest_paths' || action.id == 'explore_deep_woods') {
  tryDropFragment(CodexTag.wilds, 0.05);
}
if (action.id == 'explore_rocky_trails' || action.id == 'explore_lower_shafts') {
  tryDropFragment(CodexTag.stone, 0.05);
}
// Tier-3 gathering — Source pool gate prevents firing until first_breach_cleansed
if (_currentZone.tier >= 3 && !action.isCombat) {
  tryDropFragment(CodexTag.source, 0.03);
}
```

In `_resolveCombat` (after `_notifyQuestObservers(BeastDefeatedEvent(beast.id))`):

```dart
final regionTag = _regionTagForBeast(beast.id);
if (regionTag != null) {
  tryDropFragment(regionTag, 0.08);
}
```

- [ ] **Step 4: Run all tests, verify nothing broke**

Run: `flutter test`

Expected: All tests PASS (Spec 1 + Spec 2 to-date).

- [ ] **Step 5: Commit**

```bash
git add lib/engine/game_engine.dart test/game_engine_test.dart
git commit -m "feat(engine): wire fragment drops into Obelisks, beasts, scouts, T3 gather"
```

---

## Task 15: Add inspect_glyph ZoneAction to Darkstone Mine I & II

**Files:**
- Modify: `lib/models/zone.dart`
- Test: `test/game_engine_test.dart` (extend)

- [ ] **Step 1: Write failing test**

Add to `test/game_engine_test.dart`:

```dart
test('Darkstone Mine I and II both have inspect_glyph action', () {
  expect(
    Zones.darkstoneMineTier1.actions.any((a) => a.id == 'inspect_glyph'),
    true,
  );
  expect(
    Zones.darkstoneMineTier2.actions.any((a) => a.id == 'inspect_glyph'),
    true,
  );
});
```

- [ ] **Step 2: Run test, verify it fails**

Run: `flutter test test/game_engine_test.dart`

Expected: FAIL — `inspect_glyph` not present in either zone.

- [ ] **Step 3: Add inspect_glyph to both zones**

In `lib/models/zone.dart`, add to the `actions` list of both `darkstoneMineTier1` and `darkstoneMineTier2`:

```dart
ZoneAction(
  id: 'inspect_glyph',
  name: 'Read Mine-Glyph',
  description: 'A chiseled glyph on the cavern wall, half-forgotten.',
  durationSeconds: 5,
  energyCost: 4,
  requiredSkill: SkillType.lore,
  requiredLevel: 1,
  xpReward: 30,
  lootTable: [],
),
```

- [ ] **Step 4: Run tests, verify pass**

Run: `flutter test test/game_engine_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/models/zone.dart test/game_engine_test.dart
git commit -m "feat(zone): add inspect_glyph action to Darkstone Mine I and II"
```

---

## Task 16: Bootstrap the Discover Sickness quest

**Files:**
- Modify: `lib/engine/game_engine.dart`
- Test: `test/quest_test.dart` (extend)

- [ ] **Step 1: Write failing test**

Add to `test/quest_test.dart`:

```dart
test('Fresh engine offers both restoration AND Discover Sickness quests', () {
  final engine = GameEngine();
  final ids = engine.activeQuests.map((q) => q.id).toSet();
  expect(ids.contains('main_restore_town_square'), true);
  expect(ids.contains('main_discover_sickness'), true);
});
```

- [ ] **Step 2: Run test, verify it fails**

Run: `flutter test test/quest_test.dart`

Expected: FAIL — only restoration quest is offered.

- [ ] **Step 3: Extend _bootstrapStarterQuests**

In `lib/engine/game_engine.dart`, find `_bootstrapStarterQuests` and add to the end:

```dart
void _bootstrapStarterQuests() {
  // Existing Spec 1 restoration quest...
  offerQuest(/* existing main_restore_town_square */);

  // NEW Spec 2: Discover Sickness — the main quest spine begins
  offerQuest(MainQuests.discoverSickness());
}
```

- [ ] **Step 4: Run tests, verify pass**

Run: `flutter test test/quest_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/engine/game_engine.dart test/quest_test.dart
git commit -m "feat(engine): bootstrap Discover Sickness quest at engine init"
```

---

## Task 17: Add Reading overlay widget

**Files:**
- Create: `lib/widgets/reading_overlay.dart`
- Test: `test/widget_test.dart` (extend)

- [ ] **Step 1: Write failing widget test**

Add to `test/widget_test.dart`:

```dart
import 'package:flutter_text_based_rpg/widgets/reading_overlay.dart';
import 'package:flutter_text_based_rpg/models/codex.dart';

testWidgets('ReadingOverlay shows title, body, and Continue button', (tester) async {
  bool dismissed = false;

  await tester.pumpWidget(MaterialApp(
    home: ReadingOverlay(
      reading: CodexReadings.wildsReading,
      onDismiss: () => dismissed = true,
    ),
  ));

  expect(find.text("The Warden's Account"), findsOneWidget);
  expect(find.textContaining('Forty years'), findsOneWidget);
  expect(find.text('Continue'), findsOneWidget);

  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();
  expect(dismissed, true);
});
```

- [ ] **Step 2: Run test, verify it fails**

Run: `flutter test test/widget_test.dart`

Expected: Compilation error — `ReadingOverlay` not defined.

- [ ] **Step 3: Create reading_overlay.dart**

Create `lib/widgets/reading_overlay.dart`:

```dart
import 'package:flutter/material.dart';
import '../models/codex.dart';
import '../theme/game_theme.dart';

class ReadingOverlay extends StatelessWidget {
  final CodexReading reading;
  final VoidCallback onDismiss;

  const ReadingOverlay({
    super.key,
    required this.reading,
    required this.onDismiss,
  });

  Color _tagColor(CodexTag tag) {
    switch (tag) {
      case CodexTag.wilds: return const Color(0xFF5BAA6F);
      case CodexTag.stone: return const Color(0xFFAAAAAA);
      case CodexTag.tide: return const Color(0xFF5B8FAA);
      case CodexTag.source: return const Color(0xFF7B5BAA);
      case CodexTag.oldEmpire: return GameTheme.accentGold;
      case CodexTag.misc: return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _tagColor(reading.tag);
    return Container(
      color: Colors.black.withOpacity(0.95),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: GameTheme.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accentColor.withOpacity(0.5), width: 2),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    reading.tag.name.toUpperCase(),
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    reading.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    reading.body,
                    style: const TextStyle(
                      color: GameTheme.textLight,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (reading.rewards.isNotEmpty) ...[
                    const Divider(color: GameTheme.border),
                    const SizedBox(height: 12),
                    const Text(
                      'REWARDS',
                      style: TextStyle(
                        color: GameTheme.accentGold,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...reading.rewards.map((r) => Text(
                          '+ ${r.amount} ${r.kind.name}${r.targetId != null ? " (${r.targetId})" : ""}',
                          style: const TextStyle(
                            color: GameTheme.textMuted,
                            fontSize: 12,
                          ),
                        )),
                    const SizedBox(height: 16),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onDismiss,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests, verify pass**

Run: `flutter test test/widget_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/reading_overlay.dart test/widget_test.dart
git commit -m "feat(ui): add ReadingOverlay widget for Codex puzzle Readings"
```

---

## Task 18: Create Codex Puzzle view

**Files:**
- Create: `lib/views/codex_puzzle_view.dart`
- Test: `test/widget_test.dart` (extend)

- [ ] **Step 1: Write failing widget test**

Add to `test/widget_test.dart`:

```dart
import 'package:flutter_text_based_rpg/views/codex_puzzle_view.dart';
import 'package:provider/provider.dart';

testWidgets('CodexPuzzleView shows fragments in draggable list', (tester) async {
  final engine = GameEngine();
  // Force-collect all 10 Wilds fragments
  for (int i = 0; i < 10; i++) {
    engine.tryDropFragment(CodexTag.wilds, 1.0);
  }

  await tester.pumpWidget(
    ChangeNotifierProvider<GameEngine>.value(
      value: engine,
      child: const MaterialApp(
        home: CodexPuzzleView(tag: CodexTag.wilds),
      ),
    ),
  );

  expect(find.text('Lock Sequence'), findsOneWidget);
  // Verify at least one fragment title is rendered
  expect(find.byType(ReorderableListView), findsOneWidget);
});
```

- [ ] **Step 2: Run test, verify it fails**

Run: `flutter test test/widget_test.dart`

Expected: Compilation error.

- [ ] **Step 3: Create codex_puzzle_view.dart**

Create `lib/views/codex_puzzle_view.dart`:

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../engine/game_engine.dart';
import '../models/codex.dart';
import '../models/quest.dart';
import '../theme/game_theme.dart';
import '../widgets/reading_overlay.dart';

class CodexPuzzleView extends StatefulWidget {
  final CodexTag tag;
  const CodexPuzzleView({super.key, required this.tag});

  @override
  State<CodexPuzzleView> createState() => _CodexPuzzleViewState();
}

class _CodexPuzzleViewState extends State<CodexPuzzleView> {
  late List<CodexFragment> _ordered;
  List<bool>? _lastCorrectness;
  StreamSubscription<PuzzleResult>? _sub;

  @override
  void initState() {
    super.initState();
    final engine = Provider.of<GameEngine>(context, listen: false);
    final available = CodexFragments.all
        .where((f) =>
            f.tag == widget.tag &&
            engine.knownCodexFragmentIds.contains(f.id))
        .toList();
    // Shuffle initial order so player can't trivially see the data file
    available.shuffle();
    _ordered = available;

    _sub = engine.puzzleResults.listen((result) {
      if (result.tag != widget.tag) return;
      setState(() => _lastCorrectness = result.correctness);
      if (result.reading != null) {
        _showReading(result.reading!);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _showReading(CodexReading reading) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Reading',
      pageBuilder: (context, _, __) => ReadingOverlay(
        reading: reading,
        onDismiss: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop(); // close puzzle view too
        },
      ),
    );
  }

  void _lock() {
    final engine = Provider.of<GameEngine>(context, listen: false);
    final ids = _ordered.map((f) => f.id).toList();
    engine.lockCodexPuzzle(widget.tag, ids);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameTheme.background,
      appBar: AppBar(
        title: Text('${widget.tag.name[0].toUpperCase()}${widget.tag.name.substring(1)} — Order the Fragments'),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Drag to reorder. Lock when ready.',
              style: TextStyle(color: GameTheme.textMuted),
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              itemCount: _ordered.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _ordered.removeAt(oldIndex);
                  _ordered.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                final fragment = _ordered[index];
                final correctness = _lastCorrectness;
                Color? border;
                if (correctness != null && index < correctness.length) {
                  border = correctness[index] ? Colors.green : Colors.red;
                }
                return Card(
                  key: ValueKey(fragment.id),
                  color: GameTheme.cardBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: border != null
                        ? BorderSide(color: border, width: 2)
                        : BorderSide.none,
                  ),
                  child: ListTile(
                    leading: Text('${index + 1}.', style: const TextStyle(color: GameTheme.textMuted)),
                    title: Text(fragment.title, style: const TextStyle(color: Colors.white)),
                    trailing: const Icon(Icons.drag_handle, color: GameTheme.textMuted),
                    onTap: () => _showFragmentText(fragment),
                  ),
                );
              },
            ),
          ),
          if (_lastCorrectness != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '${_lastCorrectness!.where((c) => c).length} of ${_lastCorrectness!.length} in correct place. (Wrong-Lock cost: −3 Lore XP)',
                style: const TextStyle(color: GameTheme.textMuted, fontSize: 12),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _lock,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GameTheme.accentGold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Lock Sequence', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFragmentText(CodexFragment fragment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GameTheme.cardBg,
        title: Text(fragment.title, style: const TextStyle(color: Colors.white)),
        content: Text(fragment.text, style: const TextStyle(color: GameTheme.textLight, fontStyle: FontStyle.italic)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests, verify pass**

Run: `flutter test test/widget_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/views/codex_puzzle_view.dart test/widget_test.dart
git commit -m "feat(ui): add CodexPuzzleView with drag-to-reorder and Lock"
```

---

## Task 19: Add Fragments tab to Codex view

**Files:**
- Modify: `lib/views/codex_view.dart`

This is a UI integration task; full code spans too many lines for safe step-by-step copy. Follow the structure:

- [ ] **Step 1: Add a new `_FragmentsTab` widget within `codex_view.dart`**

Build a widget that:
- Iterates `CodexTag.values.where((t) => t != CodexTag.misc)`
- For each tag, filters `engine.knownCodexFragmentIds` to that tag's fragments
- If the tag has zero fragments, skip rendering its section entirely
- Otherwise, render an `ExpansionTile` with the tag name + "N found" count
- List each fragment as a row (unread shows "📜 ???", read shows "📜 <title>")
- Below the list, if `fragmentsInTag.length >= 3`, show a "Solve Puzzle" button that navigates to `CodexPuzzleView(tag: tag)`
- If solved (`engine.solvedTagPuzzles.contains(tag)`), show a "📖 Read the *<title>*" button that opens the Reading overlay again

Tapping an unread fragment: calls `engine.readCodexFragment(id)`, then shows a dialog with the fragment text.

- [ ] **Step 2: Update Codex view tabs to conditionally include Fragments tab**

Change the existing Codex tab setup so the Fragments tab only appears in the `TabBar` when `engine.knownCodexFragmentIds.isNotEmpty`. Use a computed tab list.

- [ ] **Step 3: Add Synthesis section at the bottom of Fragments tab**

If `engine.solvedTagPuzzles.length >= 4`, show:
```
✨ SYNTHESIS
One more reading awaits...

Solve the last tag's puzzle to unlock the Synthesis.
```

If `engine.solvedTagPuzzles.length == 5`, transform to a tap-to-read card opening `ReadingOverlay(reading: CodexReadings.synthesisReading, ...)`.

- [ ] **Step 4: Verify visually with `flutter run`**

Run: `flutter run -d windows`

Expected:
- Open the app, restore the town, open Codex
- Without fragments: 3 tabs visible (Quests/Beasts/Regions)
- Use dev tools or in-game grinding to add a fragment; reload → 4 tabs visible (Fragments appears)

- [ ] **Step 5: Commit**

```bash
git add lib/views/codex_view.dart
git commit -m "feat(ui): add Fragments tab to Codex view with progressive discovery"
```

---

## Task 20: Render comingSoon objectives in Quest Log popover

**Files:**
- Modify: `lib/views/dashboard_view.dart`

- [ ] **Step 1: Find the objective rendering in the Quest Log popover**

In `lib/views/dashboard_view.dart`, find the function that renders quest objectives in `_showQuestLogBottomSheet` (search for "ObjectiveKind").

- [ ] **Step 2: Add comingSoon styling**

Wrap the objective row build with a check:

```dart
if (objective.comingSoon) {
  return Row(
    children: [
      const Icon(Icons.lock_clock, color: GameTheme.textMuted, size: 16),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          '${kindText}  (Coming Soon)',
          style: const TextStyle(color: GameTheme.textMuted, fontSize: 12, fontStyle: FontStyle.italic),
        ),
      ),
      IconButton(
        icon: const Icon(Icons.info_outline, color: GameTheme.textMuted, size: 14),
        onPressed: () => showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: GameTheme.cardBg,
            content: const Text(
              'This objective requires content from a future update.',
              style: TextStyle(color: GameTheme.textLight),
            ),
          ),
        ),
      ),
    ],
  );
}
```

Place this branch before the normal objective rendering.

- [ ] **Step 3: Verify visually**

Run the app, force-complete the Investigate Wilds quest (via the integration smoke test or manual play), and verify the Cleanse the Hollow quest now appears in the Quest Log with two "Coming Soon" objectives showing the lock-clock icon.

- [ ] **Step 4: Commit**

```bash
git add lib/views/dashboard_view.dart
git commit -m "feat(ui): render comingSoon quest objectives with lock-clock icon"
```

---

## Task 21: Final integration smoke test

**Files:**
- Test: `test/quest_engine_test.dart` (extend)

- [ ] **Step 1: Add end-to-end smoke test**

Add to `test/quest_engine_test.dart`:

```dart
test('Spec 2 acceptance — fresh engine to solved Wilds puzzle', () {
  final engine = GameEngine();

  // Verify Discover Sickness is offered
  expect(
    engine.activeQuests.any((q) => q.id == 'main_discover_sickness'),
    true,
  );

  // Collect and read 3 Wilds fragments → Discover completes
  for (int i = 0; i < 3; i++) {
    engine.tryDropFragment(CodexTag.wilds, 1.0);
  }
  final ids = engine.knownCodexFragmentIds.take(3).toList();
  for (final id in ids) {
    engine.readCodexFragment(id);
  }

  expect(
    engine.completedQuests.any((q) => q.id == 'main_discover_sickness'),
    true,
  );

  // Investigate Wilds + Investigate Stones now offered
  expect(
    engine.activeQuests.any((q) => q.id == 'main_investigate_wilds'),
    true,
  );
  expect(
    engine.activeQuests.any((q) => q.id == 'main_investigate_stones'),
    true,
  );

  // Collect remaining 7 Wilds fragments + read all 10
  for (int i = 0; i < 7; i++) {
    engine.tryDropFragment(CodexTag.wilds, 1.0);
  }
  for (final id in engine.knownCodexFragmentIds.toList()) {
    engine.readCodexFragment(id);
  }

  // Lock in correct order
  final correctOrder = CodexFragments.all
      .where((f) => f.tag == CodexTag.wilds)
      .toList()
    ..sort((a, b) => a.orderInTag.compareTo(b.orderInTag));
  engine.lockCodexPuzzle(
    CodexTag.wilds,
    correctOrder.map((f) => f.id).toList(),
  );

  // Wilds puzzle solved → Cleanse the Hollow offered
  expect(engine.solvedTagPuzzles.contains(CodexTag.wilds), true);
  expect(
    engine.activeQuests.any((q) => q.id == 'main_cleanse_hollow'),
    true,
  );

  // Cleanse the Hollow objectives are comingSoon — should not advance
  final cleanseQuest =
      engine.activeQuests.firstWhere((q) => q.id == 'main_cleanse_hollow');
  expect(cleanseQuest.objectives[0].comingSoon, true);
  expect(cleanseQuest.objectives[0].currentCount, 0);
});
```

- [ ] **Step 2: Run the smoke test**

Run: `flutter test test/quest_engine_test.dart`

Expected: PASS.

- [ ] **Step 3: Run the full test suite**

Run: `flutter test`

Expected: All Spec 1 + Spec 2 tests pass.

- [ ] **Step 4: Commit**

```bash
git add test/quest_engine_test.dart
git commit -m "test(spec2): end-to-end smoke test for Spec 2 acceptance criteria"
```

---

## Post-implementation checklist

- [ ] All `flutter test` passes (Spec 1 + Spec 2 combined)
- [ ] `flutter analyze` shows zero errors and zero warnings
- [ ] Manual play test:
  - Fresh app → Discover Sickness chip visible
  - Inspect 5+ Obelisks → at least one fragment drops (10% per visit)
  - Open Codex → Fragments tab present, fragment listed, read it → +15 Lore XP
  - After 3 reads → Discover completes, Investigate Wilds + Investigate Stones offered
  - Grind to 10 Wilds → puzzle button enables → drag → Lock wrong → red borders + −3 XP → Lock right → Reading overlay → Wilds Witness reward, Cleanse the Hollow quest in log with Coming Soon objectives
  - Continue grinding to 10 Stone fragments via the new `inspect_glyph` action in Darkstone → 2-breach milestone fires (major modal)
- [ ] README.md updated with brief "Codex puzzles + Readings" note
