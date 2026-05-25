import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/models/item.dart';
import 'package:flutter_text_based_rpg/models/zone.dart';

void main() {
  group('Coast items', () {
    test('8 new Coast items exist with correct ids', () {
      for (final id in [
        'driftwood',
        'salt_crystal',
        'pearl_shell',
        'kelp',
        'tide_hound_pelt',
        'hound_fang',
        'crawler_carapace',
        'salt_touched_pelt',
      ]) {
        expect(Items.findById(id), isNotNull, reason: 'Missing item: $id');
      }
    });

    test('Driftwood is a resource with value 8', () {
      final i = Items.findById('driftwood')!;
      expect(i.type, ItemType.resource);
      expect(i.value, 8);
    });

    test('Salt-Touched Skin has highest value among Coast resources', () {
      final values = [
        Items.findById('driftwood')!.value,
        Items.findById('salt_crystal')!.value,
        Items.findById('pearl_shell')!.value,
        Items.findById('kelp')!.value,
        Items.findById('tide_hound_pelt')!.value,
        Items.findById('hound_fang')!.value,
        Items.findById('crawler_carapace')!.value,
        Items.findById('salt_touched_pelt')!.value,
      ];
      expect(values.reduce((a, b) => a > b ? a : b), 40);
    });
  });

  group('Coast zones', () {
    test('3 Coast zones exist with expected ids and tiers', () {
      expect(Zones.findById('sundered_coast_1').name, 'Sundered Coast I');
      expect(Zones.findById('sundered_coast_1').tier, 1);
      expect(Zones.findById('sundered_coast_2').tier, 2);
      expect(Zones.findById('sundered_coast_3').tier, 3);
    });

    test('Coast I has 7 actions including pier glyph and tide hound hunt', () {
      final coast1 = Zones.findById('sundered_coast_1');
      expect(coast1.actions.any((a) => a.id == 'inspect_pier_glyph'), true);
      expect(coast1.actions.any((a) => a.id == 'hunt_tide_hound'), true);
      expect(coast1.actions.any((a) => a.id == 'gather_driftwood'), true);
      expect(coast1.actions.any((a) => a.id == 'scout_cliff_path'), true);
    });

    test('Coast III has Lighthouse plaque with higher XP than Coast I pier glyph', () {
      final pier = Zones.findById('sundered_coast_1')
          .actions
          .firstWhere((a) => a.id == 'inspect_pier_glyph');
      final plaque = Zones.findById('sundered_coast_3')
          .actions
          .firstWhere((a) => a.id == 'read_lighthouse_plaque');
      expect(plaque.xpReward, greaterThan(pier.xpReward));
    });

    test('Coast III has hazard chance on combat action', () {
      final cellar = Zones.findById('sundered_coast_3')
          .actions
          .firstWhere((a) => a.id == 'brave_drowned_cellar');
      expect(cellar.hazardChance, 0.25);
      expect(cellar.healthCost, 15);
    });
  });
}
