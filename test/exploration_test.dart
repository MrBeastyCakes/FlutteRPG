import 'package:flutter_test/flutter_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/models/item.dart';
import 'package:flutter_text_based_rpg/models/skill.dart';
import 'package:flutter_text_based_rpg/models/zone.dart';

void main() {
  group('Exploration & Bare-Handed Gathering Tests', () {
    late GameEngine engine;

    setUp(() {
      engine = GameEngine();
    });

    test('Initial exploration progress is 0.0 for all paths', () {
      expect(engine.explorationProgress['explore_forest_paths'], 0.0);
      expect(engine.explorationProgress['explore_rocky_trails'], 0.0);
      expect(engine.explorationProgress['explore_deep_woods'], 0.0);
      expect(engine.explorationProgress['explore_lower_shafts'], 0.0);
    });

    test('Forest path exploration unlocks Whispering Woods only', () {
      fakeAsync((async) {
        final forestAction = Zones.townSquare.actions.firstWhere((a) => a.id == 'explore_forest_paths');

        // Starting state
        expect(engine.playerStats.gold, 10);
        expect(engine.unlockedZoneIds.contains('whispering_woods_1'), false);
        expect(engine.unlockedZoneIds.contains('darkstone_mine_1'), false);

        // 4 steps to 100%
        for (int i = 0; i < 4; i++) {
          engine.startAction(forestAction);
          async.elapse(const Duration(seconds: 5));
        }
        expect(engine.explorationProgress['explore_forest_paths'], 1.0);

        // Whispering Woods unlocked, Mine NOT unlocked
        expect(engine.unlockedZoneIds.contains('whispering_woods_1'), true);
        expect(engine.unlockedZoneIds.contains('darkstone_mine_1'), false);

        // Forest chest rewards: 10 Gold, 5 Wild Berries, 5 Oak Logs, 2 Wildflowers
        expect(engine.playerStats.gold >= 20, true);
        expect(engine.inventory.hasItem('wild_berries', 5), true);
        expect(engine.inventory.hasItem('oak_log', 5), true);
        expect(engine.inventory.hasItem('wildflower', 2), true);
        expect(engine.logs.any((l) => l.message.contains('Whispering Woods')), true);
      });
    });

    test('Rocky trail exploration unlocks Darkstone Mine only', () {
      fakeAsync((async) {
        final rockyAction = Zones.townSquare.actions.firstWhere((a) => a.id == 'explore_rocky_trails');

        // 4 steps to 100%
        for (int i = 0; i < 4; i++) {
          engine.startAction(rockyAction);
          async.elapse(const Duration(seconds: 5));
        }
        expect(engine.explorationProgress['explore_rocky_trails'], 1.0);

        // Darkstone Mine unlocked, Woods NOT unlocked
        expect(engine.unlockedZoneIds.contains('darkstone_mine_1'), true);
        expect(engine.unlockedZoneIds.contains('whispering_woods_1'), false);

        // Rocky chest rewards: 10 Gold, 5 Copper Ore, 3 Tin Ore, 3 Wild Berries
        expect(engine.playerStats.gold >= 20, true);
        expect(engine.inventory.hasItem('copper_ore', 5), true);
        expect(engine.inventory.hasItem('tin_ore', 3), true);
        expect(engine.inventory.hasItem('wild_berries', 3), true);
        expect(engine.logs.any((l) => l.message.contains('Darkstone Mine')), true);
      });
    });

    test('Exploration ticks increment progress by 25%', () {
      fakeAsync((async) {
        final forestAction = Zones.townSquare.actions.firstWhere((a) => a.id == 'explore_forest_paths');

        engine.startAction(forestAction);
        async.elapse(const Duration(seconds: 5));
        expect(engine.explorationProgress['explore_forest_paths'], 0.25);

        engine.startAction(forestAction);
        async.elapse(const Duration(seconds: 5));
        expect(engine.explorationProgress['explore_forest_paths'], 0.50);

        engine.startAction(forestAction);
        async.elapse(const Duration(seconds: 5));
        expect(engine.explorationProgress['explore_forest_paths'], 0.75);
      });
    });

    test('Bare-handed harvesting deals damage, logs warning, and decreases success rates', () {
      fakeAsync((async) {
        // Unlock Whispering Woods Tier 1 and Darkstone Mine Tier 1 first
        engine.unlockZone('whispering_woods_1');
        engine.unlockZone('darkstone_mine_1');

        // Verify starting health is 100, inventory has no tools
        expect(engine.playerStats.currentHealth, 100);
        expect(engine.inventory.slots.isEmpty, true);

        // 1. Bare-handed Woodcutting (Chop Oak: woodcutting)
        engine.travelTo(Zones.whisperingWoodsTier1);
        final chopOakAction = Zones.whisperingWoodsTier1.actions.firstWhere((a) => a.id == 'chop_oak');

        engine.startAction(chopOakAction);
        async.elapse(const Duration(seconds: 4));

        // Woodcutting without tool deals 5 damage
        expect(engine.playerStats.currentHealth, 95);
        expect(engine.logs.any((l) => l.message.contains('Harvesting woodcutting with your bare hands dealt 5 damage')), true);

        // 2. Bare-handed Herbalism (Forage Berries: herbalism)
        final forageBerriesAction = Zones.whisperingWoodsTier1.actions.firstWhere((a) => a.id == 'forage_berries');
        
        engine.startAction(forageBerriesAction);
        async.elapse(const Duration(seconds: 3));

        // Herbalism without tool deals 3 damage
        expect(engine.playerStats.currentHealth, 92);
        expect(engine.logs.any((l) => l.message.contains('Harvesting herbalism with your bare hands dealt 3 damage')), true);

        // 3. Bare-handed Mining (Mine Copper Ore: mining)
        engine.travelTo(Zones.darkstoneMineTier1);
        final mineCopperAction = Zones.darkstoneMineTier1.actions.firstWhere((a) => a.id == 'mine_copper');

        engine.startAction(mineCopperAction);
        async.elapse(const Duration(seconds: 5));

        // Mining without tool deals 8 damage
        expect(engine.playerStats.currentHealth, 84);
        expect(engine.logs.any((l) => l.message.contains('Harvesting mining with your bare hands dealt 8 damage')), true);
      });
    });

    test('Fainting triggers if bare-handed damage drops health to 0 or below', () {
      fakeAsync((async) {
        engine.unlockZone('whispering_woods_1');
        engine.travelTo(Zones.whisperingWoodsTier1);

        // Set player's health to 4 (woodcutting deals 5 damage bare-handed)
        engine.playerStats = engine.playerStats.copyWith(currentHealth: 4);

        final chopOakAction = Zones.whisperingWoodsTier1.actions.firstWhere((a) => a.id == 'chop_oak');
        engine.startAction(chopOakAction);
        async.elapse(const Duration(seconds: 4));

        // Should have fainted:
        // 1. health restored to 25% of max (25)
        // 2. moved back to town_square
        // 3. action cancelled (activeAction is null)
        expect(engine.playerStats.currentHealth, 25);
        expect(engine.currentZone.id, 'town_square');
        expect(engine.activeAction, isNull);
        expect(engine.logs.any((l) => l.message.contains('COLLAPSED')), true);
      });
    });
  });
}
