import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/models/milestone.dart';
import 'package:flutter_text_based_rpg/models/zone.dart';
import 'package:flutter_text_based_rpg/models/codex.dart';
import 'package:flutter_text_based_rpg/models/weather.dart';

void main() {
  group('Milestones Configuration', () {
    test('Milestones.all contains 12 entries (1 from Spec 1 + 10 from Spec 2 + 1 from Spec 3)', () {
      expect(Milestones.all.length, 12);
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
  });

  group('Spec 3 Integration Tests', () {
    test('Spec 3 acceptance — Coast unlock through scout', () {
      final engine = GameEngine();
      // Collect fragments from 2 breach tags
      engine.tryDropFragment(CodexTag.wilds, 1.0);
      engine.unlockZone('darkstone_mine_1');
      engine.travelTo(Zones.darkstoneMineTier1);
      engine.tryDropFragment(CodexTag.stone, 1.0);
      engine.travelTo(Zones.townSquare);

      expect(engine.engineFlags.contains('breaches_concept_known'), true);

      engine.completeScoutForTest('walk_eastern_coastal_path');

      expect(engine.engineFlags.contains('coast_unlocked'), true);
      expect(engine.engineFlags.contains('wharfmaster_pier_visible'), true);
      expect(engine.activeQuests.any((q) => q.id == 'main_investigate_tide'), true);

      engine.forceCoastWeatherForTest(CoastWeather.calm);
      engine.travelTo(Zones.sunderedCoastTier1);
      expect(engine.currentZone.id, 'sundered_coast_1');

      engine.tryDropFragment(CodexTag.tide, 1.0);
      expect(engine.knownCodexFragmentIds.any(
        (id) => CodexFragments.findById(id)!.tag == CodexTag.tide,
      ), true);
    });
  });
}

