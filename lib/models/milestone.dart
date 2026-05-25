import '../engine/game_engine.dart';
import 'codex.dart';

enum MilestoneSeverity { major, minor }

class MilestoneEvent {
  final String id;
  final MilestoneSeverity severity;
  final String title;
  final String body;
  final String icon;
  final bool Function(GameEngine engine) trigger;
  final void Function(GameEngine engine)? onFire;

  const MilestoneEvent({
    required this.id,
    required this.severity,
    required this.title,
    required this.body,
    required this.icon,
    required this.trigger,
    this.onFire,
  });
}

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

  static final MilestoneEvent coastUnlocked = MilestoneEvent(
    id: 'coast_unlocked',
    severity: MilestoneSeverity.major,
    title: 'A Salt-Crusted Stranger',
    body: 'A salt-crusted stranger limps into Town Square, leaning on a driftwood cane. "I came from the Coast. The lighthouse is dark. The lamp will not stay lit. The drowned are walking up the pier." She presses a tarnished key into your palm — the key to the Wharfmaster\'s old pier. "Go. Someone has to go."',
    icon: '⚓',
    trigger: (engine) => engine.engineFlags.contains('coast_unlocked'),
    onFire: null,
  );

  static final List<MilestoneEvent> all = [
    townSquareRestored,
    firstCodexFragment,
    firstCodexRead,
    firstWildsDrop,
    firstStoneDrop,
    secondBreachConcept,
    coastUnlocked,
    firstPuzzleSolved,
    loreCompletionistPath,
    sourcePoolOpens,
    synthesisApproaching,
    synthesisUnlocked,
  ];
}
