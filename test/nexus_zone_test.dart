import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/models/zone.dart';
import 'package:flutter_text_based_rpg/models/item.dart';
import 'package:flutter_text_based_rpg/models/quest.dart';

void main() {
  group('Nexus Zone Tests', () {
    test('Nexus of Echoes visibility gates', () {
      final engine = GameEngine();
      engine.resetGame();

      // 1. Initially hidden
      expect(engine.isZoneUnlocked(Zones.nexusOfEchoes), false);

      // 2. Unlocked flag set, but no tokens
      engine.setEngineFlag('nexus_unlockable');
      expect(engine.isZoneUnlocked(Zones.nexusOfEchoes), false);

      // 3. Add only 1 token
      final wildsToken = Items.findById('wilds_cleansing_token')!;
      engine.inventory = engine.inventory.addItem(wildsToken, 1);
      expect(engine.isZoneUnlocked(Zones.nexusOfEchoes), false);

      // 4. Add 2nd token
      final stoneToken = Items.findById('stone_cleansing_token')!;
      engine.inventory = engine.inventory.addItem(stoneToken, 1);
      expect(engine.isZoneUnlocked(Zones.nexusOfEchoes), false);

      // 5. Add 3rd token -> Now unlocked!
      final tideToken = Items.findById('tide_cleansing_token')!;
      engine.inventory = engine.inventory.addItem(tideToken, 1);
      expect(engine.isZoneUnlocked(Zones.nexusOfEchoes), true);
    });

    test('Nexus actions are correct', () {
      expect(Zones.nexusOfEchoes.actions.length, 1);
      expect(Zones.nexusOfEchoes.actions.first.id, 'confront_the_source');
      expect(Zones.nexusOfEchoes.actions.first.isCombat, true);
      expect(Zones.nexusOfEchoes.actions.first.beastId, 'the_source');
    });

    test('First travel fires milestone and advances quest visit objective', () {
      final engine = GameEngine();
      engine.resetGame();

      // Add tokens and unlock
      engine.cleanseAllBreachesForTest();

      expect(engine.firedMilestoneIdsForTest.contains('nexus_first_visit'), false);

      // Travel
      engine.travelTo(Zones.nexusOfEchoes);

      // Fires milestone
      expect(engine.firedMilestoneIdsForTest.contains('nexus_first_visit'), true);

      // Advances visit objective
      final quest = engine.activeQuests.firstWhere((q) => q.id == 'main_source_convergence');
      final obj = quest.objectives.firstWhere((o) => o.targetId == 'nexus_of_echoes');
      expect(obj.currentCount, 1);
      expect(obj.comingSoon, false);

      // Travel again -> milestone count does not increment in fired Set
      engine.travelTo(Zones.townSquare);
      engine.travelTo(Zones.nexusOfEchoes);
      // Still contains and was fired once
      expect(engine.firedMilestoneIdsForTest.contains('nexus_first_visit'), true);
    });
  });
}
