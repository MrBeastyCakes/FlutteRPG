import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/models/item.dart';
import 'package:flutter_text_based_rpg/models/skill.dart';
import 'package:flutter_text_based_rpg/models/masterwork.dart';

void main() {
  group('GameEngine Stats & Actions Tests', () {
    late GameEngine engine;

    setUp(() {
      engine = GameEngine();
    });

    test('Initial state values check', () {
      expect(engine.playerStats.name, 'Elara');
      expect(engine.playerStats.currentHealth, 100);
      expect(engine.playerStats.currentEnergy, 100);
      expect(engine.playerStats.gold, 500);
      expect(engine.currentZone.id, 'town_square');
      expect(engine.skills[SkillType.woodcutting]?.level, 1);
    });

    test('XP Curve Progression and Clamping Gate at Lvl 10', () {
      final skillState = engine.skills[SkillType.woodcutting]!;
      expect(skillState.level, 1);
      expect(skillState.levelCap, 10);
      expect(skillState.isGated, false);

      // Add enough XP to level up (from lvl 1 to lvl 2 requires: totalXpForLevel(2) = 100.0)
      final stateAfterLvl2 = skillState.addXp(105);
      expect(stateAfterLvl2.level, 2);
      expect(stateAfterLvl2.xp, 105.0);

      // Level 10 XP requirement
      // totalXpForLevel(10) = 100 * 9^1.6 = 100 * 33.2 = 3322.25 XP
      final capStart = SkillState.totalXpForLevel(10); // 3322.25
      
      // Let's add a massive amount of XP to exceed the level 10 cap (e.g. 5000 XP)
      final stateGated = skillState.addXp(5000);
      expect(stateGated.level, 10); // capped at 10
      expect(stateGated.xp, capStart); // clamped to exact boundary
      expect(stateGated.isGated, true);

      // Adding more XP while gated does nothing
      final stateStillGated = stateGated.addXp(1000);
      expect(stateStillGated.level, 10);
      expect(stateStillGated.xp, capStart);
    });

    test('Fainting mechanics on 0 Health', () {
      // Set gold to 100 to check penalty
      // Directly check fainting by running engine.faint()
      engine.faint();

      expect(engine.playerStats.currentHealth, 25); // 25% of 100
      expect(engine.playerStats.currentEnergy, 50); // 50% of 100
      expect(engine.playerStats.gold, 450); // 10% penalty of 500
      expect(engine.currentZone.id, 'town_square');
      expect(engine.logs.any((e) => e.message.contains('COLLAPSED')), true);
    });

    test('Inventory and Item handling', () {
      // Check initial inventory (has stone axe, stone pickaxe, 5 berries)
      expect(engine.inventory.hasItem('stone_axe'), true);
      expect(engine.inventory.hasItem('wild_berries', 5), true);

      // Add more items
      engine.buyItem(Items.wildBerries); // Costs 2 gold, adds 1 berry
      expect(engine.inventory.hasItem('wild_berries', 6), true);
      expect(engine.playerStats.gold, 498);

      // Consuming food
      engine.eatFood(Items.wildBerries);
      expect(engine.inventory.hasItem('wild_berries', 5), true);
      // Health/energy should increase
      // Since they are at 100 max, consuming berries won't exceed max, but it works.
    });

    test('Masterwork Task Scenario Flow & Cap Unlock', () {
      // 1. Force the Woodcutting skill to Level 10 (Gated)
      final capStart = SkillState.totalXpForLevel(10);
      final gatedWC = SkillState(
        type: SkillType.woodcutting,
        level: 10,
        xp: capStart,
        levelCap: 10,
      );
      engine.skills[SkillType.woodcutting] = gatedWC;
      expect(engine.skills[SkillType.woodcutting]?.isGated, true);

      // 2. Start Masterwork Task
      final task = MasterworkTasks.woodcuttingLvl10;
      engine.startMasterworkChallenge(task);
      expect(engine.activeMasterwork?.task.id, 'wc_lvl_10');
      expect(engine.activeMasterwork?.currentStepId, 'start');

      // 3. Make choice that requires Lore level 3 (should lock/fail because Lore is Lvl 1 initially)
      engine.chooseMasterworkOption(task.steps['start']!.options[0]);
      expect(engine.activeMasterwork?.currentStepId, 'start'); // choice locked, didn't move!
      expect(engine.logs.first.message.contains('locked'), true);

      // 4. Make a successful choice path
      // Choice 1: "Deliver a massive, heavy chop to the center."
      engine.chooseMasterworkOption(task.steps['start']!.options[1]);
      expect(engine.activeMasterwork?.currentStepId, 'force_strike');

      // Add 5 Iron Ores to inventory to make choice 2
      for (int i = 0; i < 5; i++) {
        engine.buyItem(Items.ironOre); // bypass normal check to get items
      }

      // Choice 2: "Submit 5 Iron Ores to reinforce your axe head."
      engine.chooseMasterworkOption(task.steps['force_strike']!.options[0]);
      expect(engine.activeMasterwork?.currentStepId, 'reinforced_axe');

      // Choice 3: "Strike the tree with the reinforced axe." (Ends trial as success)
      engine.chooseMasterworkOption(task.steps['reinforced_axe']!.options[0]);
      expect(engine.activeMasterwork, null); // Challenge ended
      
      // Cap should be unlocked to 20!
      final newWCSkill = engine.skills[SkillType.woodcutting]!;
      expect(newWCSkill.levelCap, 20);
      expect(newWCSkill.isGated, false);
    });
  });
}
