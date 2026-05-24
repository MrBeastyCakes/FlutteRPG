import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/models/codex.dart';
import 'package:flutter_text_based_rpg/models/zone.dart';

void main() {
  group('Codex and Bestiary Unit Tests', () {
    late GameEngine engine;

    setUp(() {
      engine = GameEngine();
    });

    test('Initial Region Status check', () {
      expect(engine.regionStatus.containsKey('town_square'), true);
      expect(engine.regionStatus['town_square']?.status, RegionStatus.anomalous);
    });

    test('Discovery of regions', () {
      expect(engine.regionStatus.containsKey('whispering_woods_1'), false);

      engine.unlockZone('whispering_woods_1');
      engine.travelTo(Zones.whisperingWoodsTier1);

      expect(engine.regionStatus.containsKey('whispering_woods_1'), true);
      expect(engine.regionStatus['whispering_woods_1']?.status, RegionStatus.anomalous);
      expect(engine.regionStatus['whispering_woods_1']?.discoveredAt, isNotNull);
    });

    test('Bestiary entry accumulation', () {
      expect(engine.bestiary.containsKey('forest_boar'), false);

      engine.recordBestiary('forest_boar', ['boar_meat']);
      expect(engine.bestiary.containsKey('forest_boar'), true);
      expect(engine.bestiary['forest_boar']?.defeatCount, 1);
      expect(engine.bestiary['forest_boar']?.droppedItemIds.contains('boar_meat'), true);

      // Repeat defeat to accumulate counts and drops
      engine.recordBestiary('forest_boar', ['boar_tusk']);
      expect(engine.bestiary['forest_boar']?.defeatCount, 2);
      expect(engine.bestiary['forest_boar']?.droppedItemIds.contains('boar_meat'), true);
      expect(engine.bestiary['forest_boar']?.droppedItemIds.contains('boar_tusk'), true);
    });
  });
}
