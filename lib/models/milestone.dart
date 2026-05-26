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


  static final MilestoneEvent bloomwitherEntered = MilestoneEvent(
    id: 'bloomwither_entered',
    severity: MilestoneSeverity.major,
    title: 'The Hollow Speaks',
    body: "The trees here stand wrong, and a deeper wrong watches from the heart of the hollow. The Warden's old advice runs through your mind — an Ironbark log, well-seasoned, and three Wildflowers cut at first light, burned at the rotted shrine within. But first: what waits in the Hollow will not let you near without a fight. Defeat it. Wrest its essence. Return to Town Square and burn the essence at the town center. That is how a Breach is sealed.",
    icon: '🌿',
    trigger: (engine) => engine.regionStatus.containsKey('whispering_woods_3'),
    onFire: null,
  );

  static final MilestoneEvent glowingVeinEntered = MilestoneEvent(
    id: 'glowing_vein_entered',
    severity: MilestoneSeverity.major,
    title: 'The Vein Pulses',
    body: "The Glinting Vein is no vein — it is a wound. The foreman's last writing speaks of an alchemist's draught — wildflower tinctured with river clay, twice-distilled — that calms the pulse. The thing inside the wound will rise to defend it. Endure the rising. Then carry the wound's essence home, and burn it at the town center.",
    icon: '💎',
    trigger: (engine) => engine.regionStatus.containsKey('darkstone_mine_3'),
    onFire: null,
  );

  static final MilestoneEvent drownedLighthouseSpoken = MilestoneEvent(
    id: 'drowned_lighthouse_spoken',
    severity: MilestoneSeverity.major,
    title: 'The Lamp Speaks',
    body: "You climb the lighthouse stairs. The lamp room is silent — but not empty. The keeper's last page warned you: do not relight the lamp with oil; carry a Salt Crystal — the pure kind from the deep tide pools — and set it within the lamp's heart. Something old in the sea will rise to silence the song. Do not let it. When you have its essence, carry it home and burn it at the town center.",
    icon: '🌊',
    trigger: (engine) => engine.engineFlags.contains('drowned_lighthouse_spoken'),
    onFire: null,
  );

  static final MilestoneEvent breachWildsCleansedMilestone = MilestoneEvent(
    id: 'breach_wilds_cleansed_milestone',
    severity: MilestoneSeverity.major,
    title: 'The Forest Returns',
    body: "The forest hush returns. Birds are singing in the eastern groves for the first time in months. The Warden's gate has opened on its own.",
    icon: '🌿',
    trigger: (engine) => engine.engineFlags.contains('breach_wilds_cleansed'),
    onFire: null,
  );

  static final MilestoneEvent breachStoneCleansedMilestone = MilestoneEvent(
    id: 'breach_stone_cleansed_milestone',
    severity: MilestoneSeverity.major,
    title: 'The Foreman Returns',
    body: "The tapping stops in your dreams. The foreman is found, alive, sitting at the lip of the deepest shaft. He does not remember the year. He cries when he sees the sun.",
    icon: '💎',
    trigger: (engine) => engine.engineFlags.contains('breach_stone_cleansed'),
    onFire: null,
  );

  static final MilestoneEvent breachTideCleansedMilestone = MilestoneEvent(
    id: 'breach_tide_cleansed_milestone',
    severity: MilestoneSeverity.major,
    title: 'The Lamp Lights Itself',
    body: "The Lighthouse lamp lights itself at dusk. The Drowned are gone from the pier. The salt smells like salt again.",
    icon: '🌊',
    trigger: (engine) => engine.engineFlags.contains('breach_tide_cleansed'),
    onFire: null,
  );

  static final MilestoneEvent allBreachesCleansedMilestone = MilestoneEvent(
    id: 'all_breaches_cleansed_milestone',
    severity: MilestoneSeverity.major,
    title: 'The Bells Ring',
    body: "Town Square's bells ring without being struck. Somewhere, a stone door opens beneath the world. The cartographer hands you a key you have never seen before.",
    icon: '🔔',
    trigger: (engine) =>
        engine.engineFlags.contains('breach_wilds_cleansed') &&
        engine.engineFlags.contains('breach_stone_cleansed') &&
        engine.engineFlags.contains('breach_tide_cleansed'),
    onFire: (engine) => engine.setEngineFlag('nexus_unlockable'),
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
    bloomwitherEntered,
    glowingVeinEntered,
    drownedLighthouseSpoken,
    breachWildsCleansedMilestone,
    breachStoneCleansedMilestone,
    breachTideCleansedMilestone,
    allBreachesCleansedMilestone,
  ];
}
