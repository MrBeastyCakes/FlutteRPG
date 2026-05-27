import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/models/milestone.dart';
import 'package:flutter_text_based_rpg/models/zone.dart';
import 'package:flutter_text_based_rpg/models/codex.dart';
import 'package:flutter_text_based_rpg/models/weather.dart';
import 'package:flutter_text_based_rpg/models/main_quests.dart';

void main() {
  group('Milestones Configuration', () {
    test('Milestones.all contains 21 entries (1 from Spec 1 + 10 from Spec 2 + 1 from Spec 3 + 7 from Spec 5 + 2 from Spec 6c)', () {
      expect(Milestones.all.length, 21);
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

  group('Spec 5 Integration Tests', () {
    test('Spec 5 acceptance — full Wilds Breach arc', () {
      final engine = GameEngine();
      engine.offerQuest(MainQuests.cleanseHollow());
      engine.unlockZoneForTest('whispering_woods_3');
      engine.travelTo(Zones.whisperingWoodsTier3);
      expect(engine.firedMilestoneIdsForTest, contains('bloomwither_entered'));

      engine.runCombatToVictoryForTest('echo_of_wilds');
      expect(engine.inventory.hasItem('wilds_echo_essence', 1), true);

      engine.travelTo(Zones.townSquare);
      expect(engine.isActionVisible(Zones.townSquare.actions.firstWhere((a) => a.id == 'burn_wilds_echo_essence')), true);

      engine.completeActionForTest('burn_wilds_echo_essence');
      engine.completeMasterworkForTest('cleansing_wilds', useFirstSuccessOption: true);

      expect(engine.engineFlags.contains('breach_wilds_cleansed'), true);
      expect(engine.engineFlags.contains('first_breach_cleansed'), true);
      expect(engine.inventory.hasItem('wilds_cleansing_token', 1), true);
      expect(engine.inventory.hasItem('wilds_echo_essence', 1), false);
      expect(engine.isActionVisible(Zones.townSquare.actions.firstWhere((a) => a.id == 'burn_wilds_echo_essence')), false);
      expect(engine.completedQuests.any((q) => q.id == 'main_cleanse_hollow'), true);
      expect(engine.isFragmentPoolOpenForTest(CodexTag.source), true);
    });
  });

  group('Spec 6c Integration Tests', () {
    test('Spec 6c acceptance — Source victory closes the convergence arc', () {
      final engine = GameEngine();

      // Bootstrap: cleanse all 3 breaches via test helpers (sets nexus_unlockable, grants 3 Tokens)
      engine.cleanseAllBreachesForTest();
      expect(engine.engineFlags.contains('nexus_unlockable'), true);
      expect(engine.inventory.hasItem('wilds_cleansing_token', 1), true);
      expect(engine.inventory.hasItem('stone_cleansing_token', 1), true);
      expect(engine.inventory.hasItem('tide_cleansing_token', 1), true);

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
      expect(engine.earnedAchievementIds, contains('source_cleansed'));
      expect(engine.playerStats.title, 'Source Cleanser');
      expect(engine.firedMilestoneIdsForTest, contains('source_defeated'));

      // Dismiss modal
      engine.dismissYouWinModal();
      expect(engine.shouldShowYouWinModal, false);

      // First post-victory town visit fires ambient line
      engine.travelTo(Zones.townSquare);
      expect(engine.logs.any((e) => e.message.contains('cartographer raises his cup')), true);
    });
  });
}

