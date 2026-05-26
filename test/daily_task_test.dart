import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/models/daily_task.dart';
import 'package:flutter_text_based_rpg/models/skill.dart';
import 'package:flutter_text_based_rpg/models/zone.dart';

void main() {
  group('Daily Task System Tests', () {
    late GameEngine engine;

    setUp(() {
      engine = GameEngine();
      engine.resetGame();
    });

    test('30 daily task templates exist in registry', () {
      expect(DailyTasks.all.length, 30);
      final categories = DailyTasks.all.map((t) => t.category).toSet();
      expect(categories.length, equals(6)); // gather, hunt, visit, craft, codex, cleanse
    });

    test('Tavern visit triggers 3 daily task generations', () {
      expect(engine.todaysTasks.isEmpty, true);

      // Travel to tavern
      engine.tavernRequested = true;
      engine.forceGenerateDailyTasksForTesting();

      expect(engine.todaysTasks.length, 3);
      expect(engine.dailyBonusClaimed, false);
    });

    test('Daily task generation filters by player skill level', () {
      // Set woodcutting skill level to 1
      expect(engine.skills[SkillType.woodcutting]!.level, 1);

      // All generated tasks should satisfy requiredLevel <= 1
      engine.forceGenerateDailyTasksForTesting();
      for (final task in engine.todaysTasks) {
        final template = DailyTasks.all.firstWhere((t) => t.id == task.id);
        if (template.requiredSkill == SkillType.woodcutting) {
          expect(template.requiredLevel, lessThanOrEqualTo(1));
        }
      }
    });

    test('Completing a visit task updates progress', () {
      engine.forceGenerateDailyTasksForTesting();
      
      // Let's replace the generated daily tasks with a specific visit task
      final visitTask = DailyTask(
        id: 'daily_visit_woods',
        name: 'Visit Whispering Woods',
        category: DailyTaskCategory.visit,
        targetId: 'whispering_woods_1',
        targetCount: 1,
        rewardGold: 15,
      );
      engine.todaysTasks[0] = visitTask;

      // Make sure whispering_woods_1 is unlocked and travel there
      engine.unlockZone('whispering_woods_1');
      engine.travelTo(Zones.whisperingWoodsTier1);

      // Verify that the task count updated to 1 and is completed
      expect(engine.todaysTasks[0].currentCount, 1);
      expect(engine.todaysTasks[0].isCompleted, true);
    });

    test('Completing all daily tasks allows claiming Daily Bonus', () {
      engine.forceGenerateDailyTasksForTesting();
      
      // Manually set all tasks to completed
      for (int i = 0; i < engine.todaysTasks.length; i++) {
        final t = engine.todaysTasks[i];
        engine.todaysTasks[i] = t.copyWith(
          currentCount: t.targetCount,
          isCompleted: true,
        );
      }

      // Claim rewards for each task
      final goldBefore = engine.playerStats.gold;
      for (final t in engine.todaysTasks) {
        engine.claimDailyTaskReward(t.id);
        expect(engine.todaysTasks.firstWhere((task) => task.id == t.id).isClaimed, true);
      }
      
      // Gold should have increased by sum of rewards
      final totalTaskRewards = engine.todaysTasks.fold<int>(0, (sum, t) => sum + t.rewardGold);
      expect(engine.playerStats.gold, goldBefore + totalTaskRewards);

      // Claim Daily Bonus
      expect(engine.dailyBonusClaimed, false);
      engine.claimDailyBonus();
      expect(engine.dailyBonusClaimed, true);
      expect(engine.playerStats.gold, goldBefore + totalTaskRewards + 120);
    });
  });
}
