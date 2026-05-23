import 'package:flutter_test/flutter_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/models/item.dart';
import 'package:flutter_text_based_rpg/models/skill.dart';
import 'package:flutter_text_based_rpg/models/masterwork.dart';
import 'package:flutter_text_based_rpg/models/zone.dart';

void main() {
  group('Skills Level Progression & Perks Tests', () {
    late GameEngine engine;

    setUp(() {
      engine = GameEngine();
    });

    test('Speed & Success & Energy Cost calculation at different levels', () {
      // Level 1: no bonuses
      expect(engine.getSkillSpeedBonus(SkillType.woodcutting), 0.0);
      expect(engine.getSkillSuccessBonus(SkillType.woodcutting), 0.0);
      expect(engine.getModifiedEnergyCost(10, SkillType.woodcutting), 10);

      // Set woodcutting to Level 5
      final skillStateLvl5 = SkillState(
        type: SkillType.woodcutting,
        level: 5,
        xp: SkillState.totalXpForLevel(5),
        levelCap: 10,
      );
      engine.skills[SkillType.woodcutting] = skillStateLvl5;

      // Speed bonus: (5-1) * 0.02 = 0.08
      expect(engine.getSkillSpeedBonus(SkillType.woodcutting), closeTo(0.08, 0.0001));
      // Success bonus: (5-1) * 0.01 = 0.04
      expect(engine.getSkillSuccessBonus(SkillType.woodcutting), closeTo(0.04, 0.0001));
      // Energy saving: (5-1) * 1% = 4% reduction. 10 * 0.96 = 9.6 -> round to 10
      expect(engine.getModifiedEnergyCost(10, SkillType.woodcutting), 10);
      // For 100 energy cost, 100 * 0.96 = 96
      expect(engine.getModifiedEnergyCost(100, SkillType.woodcutting), 96);
    });

    test('Lore XP Multiplier scales correctly', () {
      // Level 1: multiplier is 1.0
      expect(engine.getXpMultiplier(), 1.0);

      // Set Lore to level 5
      final loreLvl5 = SkillState(
        type: SkillType.lore,
        level: 5,
        xp: SkillState.totalXpForLevel(5),
        levelCap: 10,
      );
      engine.skills[SkillType.lore] = loreLvl5;

      // Multiplier: 1.0 + (5-1) * 0.03 = 1.12
      expect(engine.getXpMultiplier(), closeTo(1.12, 0.0001));

      // Unlock Lore cap to 20 (Simulate Masterwork Lvl 10 completion)
      final loreLvl10Unlocked = SkillState(
        type: SkillType.lore,
        level: 10,
        xp: SkillState.totalXpForLevel(10),
        levelCap: 20,
      );
      engine.skills[SkillType.lore] = loreLvl10Unlocked;

      // Multiplier: 1.0 + (10-1) * 0.03 + 0.15 = 1.42
      expect(engine.getXpMultiplier(), closeTo(1.42, 0.0001));
    });

    test('Cooking Food consumed restoration boost', () {
      final bakedPotato = Items.bakedPotato; // 15 HP, 5 Energy
      
      // Level 1 Cooking: restores base 15 HP, 5 Energy
      engine.inventory = engine.inventory.addItem(bakedPotato, 1);
      engine.playerStats = engine.playerStats.copyWith(currentHealth: 50, currentEnergy: 50);
      engine.eatFood(bakedPotato);
      expect(engine.playerStats.currentHealth, 65);
      expect(engine.playerStats.currentEnergy, 55);

      // Level 10 Cooking + Lvl 10 Perk unlocked (levelCap = 20)
      final cookLvl10 = SkillState(
        type: SkillType.cooking,
        level: 10,
        xp: SkillState.totalXpForLevel(10),
        levelCap: 20,
      );
      engine.skills[SkillType.cooking] = cookLvl10;

      // Multiplier: 1.0 + (10-1)*0.015 + 0.15 = 1.285
      // 15 HP * 1.285 = 19.275 -> round to 19 HP
      // 5 Energy * 1.285 = 6.425 -> round to 6 Energy
      engine.inventory = engine.inventory.addItem(bakedPotato, 1);
      engine.playerStats = engine.playerStats.copyWith(currentHealth: 50, currentEnergy: 50);
      engine.eatFood(bakedPotato);
      expect(engine.playerStats.currentHealth, 69); // 50 + 19
      expect(engine.playerStats.currentEnergy, 56); // 50 + 6
    });

    test('Level 10 Masterwork Perks: Energy flat reduction and Bare-handed immunity', () {
      fakeAsync((async) {
        // Set Woodcutting to Level 10, cap 20 (Perk 10 active)
        final wcLvl10 = SkillState(
          type: SkillType.woodcutting,
          level: 10,
          xp: SkillState.totalXpForLevel(10),
          levelCap: 20,
        );
        engine.skills[SkillType.woodcutting] = wcLvl10;

        // Speed bonus: (10-1)*0.02 + 0.20 = 0.38
        expect(engine.getSkillSpeedBonus(SkillType.woodcutting), closeTo(0.38, 0.0001));

        // Energy cost: base 10 (chop_oak duration is 4 seconds, energyCost is 5, wait energyCost is 5)
        // Level reduction: (10-1)*1% = 9% reduction. 5 * 0.91 = 4.55
        // Lvl 10 Perk Woodcutting: -2 flat. 4.55 - 2 = 2.55 -> round to 3
        expect(engine.getModifiedEnergyCost(5, SkillType.woodcutting), 3);

        // Verify bare-handed damage immunity
        // We start a woodcutting action "Chop Oak Trees" bare-handed
        engine.unlockZone('whispering_woods_1');
        engine.travelTo(Zones.whisperingWoodsTier1);
        
        final chopOakAction = Zones.whisperingWoodsTier1.actions.firstWhere((a) => a.id == 'chop_oak');
        engine.playerStats = engine.playerStats.copyWith(currentHealth: 100, currentEnergy: 100);
        
        // Chop duration is modified by speed bonus: duration = 4.0 / (1.0 + 0.38) = 2.898 seconds.
        engine.startAction(chopOakAction);
        expect(engine.activeAction, isNotNull);
        
        // Elapse enough time for the action to complete
        async.elapse(const Duration(seconds: 4));

        // Since Lvl 10 Perk is active, bare-handed damage is negated!
        // Base woodcutting bare-handed damage is 5, but we expect health to remain 100.
        expect(engine.playerStats.currentHealth, 100); // no damage taken!
      });
    });

    test('New Level 10 and Level 20 Masterwork Tasks can be looked up', () {
      final wf10 = MasterworkTasks.findForSkill(SkillType.wayfinding, 10);
      expect(wf10, isNotNull);
      expect(wf10!.title, 'The Lost Outpost');

      final wc20 = MasterworkTasks.findForSkill(SkillType.woodcutting, 20);
      expect(wc20, isNotNull);
      expect(wc20!.title, 'The Whisperer\'s Heart');

      final lore20 = MasterworkTasks.findForSkill(SkillType.lore, 20);
      expect(lore20, isNotNull);
      expect(lore20!.title, 'The Codex of Ages');
    });
  });
}
