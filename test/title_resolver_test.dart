import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/models/title.dart';
import 'package:flutter_text_based_rpg/models/skill.dart';

void main() {
  group('TitleResolver Tests', () {
    test('All 24 titles resolve correctly per skill and level tier', () {
      final Map<SkillType, SkillState> skills = {};

      for (final type in SkillType.values) {
        skills[type] = SkillState.initial(type);
      }

      // Check tier 0 (level 1-9)
      for (final type in SkillType.values) {
        final mockSkills = Map<SkillType, SkillState>.from(skills);
        mockSkills[type] = SkillState(type: type, level: 5, xp: 100, levelCap: 10);
        final title = TitleResolver.resolve(mockSkills);
        
        String expectedTitle = '';
        if (type == SkillType.woodcutting) expectedTitle = 'Sapling';
        if (type == SkillType.mining) expectedTitle = 'Prospector';
        if (type == SkillType.herbalism) expectedTitle = 'Sprig';
        if (type == SkillType.wayfinding) expectedTitle = 'Wayfarer';
        if (type == SkillType.lore) expectedTitle = 'Reader';
        if (type == SkillType.cooking) expectedTitle = 'Hearth-Hand';
        if (type == SkillType.crafting) expectedTitle = 'Apprentice';
        if (type == SkillType.combat) expectedTitle = 'Brawler';

        expect(title, expectedTitle);
      }

      // Check tier 1 (level 10-19)
      for (final type in SkillType.values) {
        final mockSkills = Map<SkillType, SkillState>.from(skills);
        mockSkills[type] = SkillState(type: type, level: 12, xp: 5000, levelCap: 20);
        final title = TitleResolver.resolve(mockSkills);

        String expectedTitle = '';
        if (type == SkillType.woodcutting) expectedTitle = 'Woodcutter';
        if (type == SkillType.mining) expectedTitle = 'Pickbearer';
        if (type == SkillType.herbalism) expectedTitle = 'Herbalist';
        if (type == SkillType.wayfinding) expectedTitle = 'Pathfinder';
        if (type == SkillType.lore) expectedTitle = 'Scholar';
        if (type == SkillType.cooking) expectedTitle = 'Cook';
        if (type == SkillType.crafting) expectedTitle = 'Crafter';
        if (type == SkillType.combat) expectedTitle = 'Warrior';

        expect(title, expectedTitle);
      }

      // Check tier 2 (level 20+)
      for (final type in SkillType.values) {
        final mockSkills = Map<SkillType, SkillState>.from(skills);
        mockSkills[type] = SkillState(type: type, level: 25, xp: 15000, levelCap: 30);
        final title = TitleResolver.resolve(mockSkills);

        String expectedTitle = '';
        if (type == SkillType.woodcutting) expectedTitle = 'Heartwood-Reaver';
        if (type == SkillType.mining) expectedTitle = 'Vein-Master';
        if (type == SkillType.herbalism) expectedTitle = 'Greenwarden';
        if (type == SkillType.wayfinding) expectedTitle = 'Cartographer';
        if (type == SkillType.lore) expectedTitle = 'Lorekeeper';
        if (type == SkillType.cooking) expectedTitle = 'Brewmaster';
        if (type == SkillType.crafting) expectedTitle = 'Artisan';
        if (type == SkillType.combat) expectedTitle = 'Blademaster';

        expect(title, expectedTitle);
      }
    });

    test('Deterministic tie-breaking using SkillType enum order', () {
      final Map<SkillType, SkillState> skills = {};
      for (final type in SkillType.values) {
        skills[type] = SkillState.initial(type);
      }

      // If Woodcutting (index 0) and Mining (index 1) are both level 10:
      // Woodcutting wins because it appears first in the SkillType enum.
      skills[SkillType.woodcutting] = const SkillState(type: SkillType.woodcutting, level: 10, xp: 3500, levelCap: 10);
      skills[SkillType.mining] = const SkillState(type: SkillType.mining, level: 10, xp: 3500, levelCap: 10);
      
      expect(TitleResolver.resolve(skills), 'Woodcutter');

      // If Wayfinding (index 3) and cooking (index 5) are level 15:
      // Wayfinding wins.
      final Map<SkillType, SkillState> skills2 = {};
      for (final type in SkillType.values) {
        skills2[type] = SkillState.initial(type);
      }
      skills2[SkillType.wayfinding] = const SkillState(type: SkillType.wayfinding, level: 15, xp: 6000, levelCap: 20);
      skills2[SkillType.cooking] = const SkillState(type: SkillType.cooking, level: 15, xp: 6000, levelCap: 20);

      expect(TitleResolver.resolve(skills2), 'Pathfinder');
    });
  });
}
