import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/models/item.dart';
import 'package:flutter_text_based_rpg/models/recipe.dart';
import 'package:flutter_text_based_rpg/models/skill.dart';

void main() {
  group('Salt Press output items', () {
    test('5 new items exist with correct ids', () {
      for (final id in ['salt_cured_trout', 'brined_boar', 'kelp_wrap', 'pearl_tonic', 'brine_stabilizer']) {
        expect(Items.findById(id), isNotNull, reason: 'Missing: $id');
      }
    });

    test('Salt-Cured Trout has +35 HP and +20 energy', () {
      final i = Items.findById('salt_cured_trout')!;
      expect(i.healAmount, 35);
      expect(i.energyAmount, 20);
    });

    test('Pearl Tonic has +60 energy', () {
      expect(Items.findById('pearl_tonic')!.energyAmount, 60);
    });

    test('Brine Stabilizer is a resource (not food)', () {
      expect(Items.findById('brine_stabilizer')!.type, ItemType.resource);
    });
  });

  group('Salt Press recipes', () {
    test('5 new recipes exist', () {
      for (final id in ['salt_cured_trout', 'brined_boar', 'kelp_wrap', 'pearl_tonic', 'brine_stabilizer']) {
        expect(Recipes.all.any((r) => r.id == id), true, reason: 'Missing: $id');
      }
    });

    test('Salt-Cured Trout consumes raw_trout + salt_crystal', () {
      final r = Recipes.all.firstWhere((r) => r.id == 'salt_cured_trout');
      expect(r.inputs['raw_trout'], 1);
      expect(r.inputs['salt_crystal'], 1);
    });

    test('Pearl Tonic requires Herbalism level 6', () {
      final r = Recipes.all.firstWhere((r) => r.id == 'pearl_tonic');
      expect(r.requiredSkill, SkillType.herbalism);
      expect(r.requiredLevel, 6);
    });
  });
}
