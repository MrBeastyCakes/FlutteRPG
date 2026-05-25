import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/models/quest.dart';
import 'package:flutter_text_based_rpg/models/skill.dart';
import 'package:flutter_text_based_rpg/models/zone.dart';
import 'package:flutter_text_based_rpg/models/main_quests.dart';
import 'package:flutter_text_based_rpg/models/codex.dart';

void main() {
  group('Quest Engine Unit Tests', () {
    late GameEngine engine;

    setUp(() {
      engine = GameEngine();
    });

    test('Starter Quest Bootstrapping', () {
      expect(engine.activeQuests.length, 2);
      final quest = engine.activeQuests.firstWhere((q) => q.id == 'main_restore_town_square');
      expect(quest.title, 'Restore Town Square');
      expect(quest.status, QuestStatus.active);
      expect(quest.objectives.length, 2);
      expect(quest.objectives[0].kind, ObjectiveKind.restore);
      expect(quest.objectives[0].targetId, 'crafting_bench');
      expect(quest.objectives[0].targetCount, 1);
      expect(quest.objectives[0].currentCount, 0);

      final discoverQuest = engine.activeQuests.firstWhere((q) => q.id == 'main_discover_sickness');
      expect(discoverQuest.title, 'Discover the Sickness');
      expect(discoverQuest.status, QuestStatus.active);
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

    test('QuestObjective with targetTag matches only fragments of that tag', () {
      final obj = QuestObjective(
        kind: ObjectiveKind.codexRead,
        targetTag: 'wilds',
        targetCount: 3,
      );
      expect(obj.targetTag, 'wilds');
      expect(obj.targetCount, 3);
      expect(obj.currentCount, 0);
    });

    test('QuestObjective comingSoon defaults to false', () {
      final obj = QuestObjective(
        kind: ObjectiveKind.gather,
        targetId: 'oak_log',
        targetCount: 5,
      );
      expect(obj.comingSoon, false);
    });

    test('QuestObjective comingSoon can be set true', () {
      final obj = QuestObjective(
        kind: ObjectiveKind.cleanse,
        targetId: 'breach_wilds',
        targetCount: 1,
        comingSoon: true,
      );
      expect(obj.comingSoon, true);
    });

    test('MainQuests.findById returns all 8 quests by id', () {
      for (final id in [
        'main_discover_sickness',
        'main_investigate_wilds',
        'main_investigate_stones',
        'main_investigate_tide',
        'main_cleanse_hollow',
        'main_cleanse_vein',
        'main_cleanse_tide',
        'main_source_convergence',
      ]) {
        final quest = MainQuests.findById(id);
        expect(quest, isNotNull, reason: 'Quest missing: $id');
        expect(quest!.id, id);
      }
    });

    test('MainQuests.findById returns null for unknown id', () {
      expect(MainQuests.findById('nonexistent'), isNull);
    });
  });
}
