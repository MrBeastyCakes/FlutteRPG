import '../engine/game_engine.dart';

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
