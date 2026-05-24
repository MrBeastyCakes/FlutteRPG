import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/models/quest.dart';
import 'package:flutter_text_based_rpg/models/skill.dart';
import 'package:flutter_text_based_rpg/models/zone.dart';

void main() {
  group('Quest Engine Unit Tests', () {
    late GameEngine engine;

    setUp(() {
      engine = GameEngine();
    });

    test('Starter Quest Bootstrapping', () {
      expect(engine.activeQuests.length, 1);
      final quest = engine.activeQuests.first;
      expect(quest.id, 'main_restore_town_square');
      expect(quest.title, 'Restore Town Square');
      expect(quest.status, QuestStatus.active);
      expect(quest.objectives.length, 2);
      expect(quest.objectives[0].kind, ObjectiveKind.restore);
      expect(quest.objectives[0].targetId, 'crafting_bench');
      expect(quest.objectives[0].targetCount, 1);
      expect(quest.objectives[0].currentCount, 0);
    });

    test('Quest Completion & Rewards', () {
      final customQuest = Quest(
        id: 'manual_turn_in_quest',
        type: QuestType.side,
        title: 'Manual Turn In',
        description: 'Description',
        objectives: [
          QuestObjective(kind: ObjectiveKind.visit, targetId: 'town_square', targetCount: 1),
        ],
        rewards: [
          QuestReward(kind: RewardKind.gold, amount: 15),
        ],
        turnInLocation: 'town_square',
      );
      engine.offerQuest(customQuest);

      final q = engine.activeQuests.firstWhere((quest) => quest.id == 'manual_turn_in_quest');
      expect(q.status, QuestStatus.active);

      // Travel to another zone then travel back to trigger ZoneVisitedEvent!
      engine.unlockZone('whispering_woods_1');
      engine.travelTo(Zones.whisperingWoodsTier1);
      expect(engine.currentZone.id, 'whispering_woods_1');

      engine.travelTo(Zones.townSquare);
      expect(engine.currentZone.id, 'town_square');

      // The quest should now be complete and ready to turn in
      expect(q.isComplete, true);
      expect(q.status, QuestStatus.completed);

      // Turn in quest
      final initialGold = engine.playerStats.gold;
      engine.turnInQuest('manual_turn_in_quest');

      // It should be moved to completed quests
      expect(engine.activeQuests.any((quest) => quest.id == 'manual_turn_in_quest'), false);
      expect(engine.completedQuests.any((quest) => quest.id == 'manual_turn_in_quest'), true);
      expect(engine.playerStats.gold, initialGold + 15);
    });

    test('Masterwork cap triggers side quest', () {
      // Setup Woodcutting to level 10
      final capStart = SkillState.totalXpForLevel(10);
      engine.skills[SkillType.woodcutting] = SkillState(
        type: SkillType.woodcutting,
        level: 10,
        xp: capStart,
        levelCap: 10,
      );

      final customQuest = Quest(
        id: 'xp_grant_quest',
        type: QuestType.side,
        title: 'Grant XP',
        description: 'Description',
        objectives: [
          QuestObjective(kind: ObjectiveKind.visit, targetId: 'town_square', targetCount: 1),
        ],
        rewards: [
          QuestReward(kind: RewardKind.skillXp, targetId: SkillType.woodcutting.name, amount: 100),
        ],
      );
      engine.offerQuest(customQuest);
      customQuest.objectives[0].currentCount = 1;
      engine.turnInQuest('xp_grant_quest');

      // It should now offer the Woodcutting Level 10 trial side quest!
      expect(engine.activeQuests.any((quest) => quest.id == 'side_masterwork_woodcutting'), true);
      final sideQuest = engine.activeQuests.firstWhere((quest) => quest.id == 'side_masterwork_woodcutting');
      expect(sideQuest.title, 'Skill Trial: The Ironbark Trial');
      expect(sideQuest.objectives.first.kind, ObjectiveKind.masterwork);
    });
  });
}
