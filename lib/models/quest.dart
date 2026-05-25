import 'skill.dart';
import 'crafted_item.dart';
import 'codex.dart';

enum QuestType { main, side, daily }
enum QuestStatus { available, active, completed, turnedIn }

enum ObjectiveKind {
  gather,       // collect N of itemId
  kill,         // defeat N beasts of beastId (or "any")
  craft,        // craft N of recipeId (or any of category)
  visit,        // travel to zoneId at least once
  scout,        // complete an exploration action
  restore,      // restore a station instance
  upgrade,      // upgrade a station to tier N
  masterwork,   // complete a Masterwork trial of skillType
  cleanse,      // perform a Breach cleansing (Spec 5)
  codexRead,    // read N new Codex fragments (Spec 2)
  custom,       // ad-hoc, advanced via explicit engine.advanceQuestObjective(...)
}

class QuestObjective {
  final ObjectiveKind kind;
  final String? targetId;       // itemId, beastId, recipeId, zoneId, stationId, skillType.name, etc.
  final String? targetTag;      // tag-filter for codexRead objectives (Spec 2)
  final int targetCount;
  int currentCount;
  bool comingSoon;              // true marks Spec 5/6-dependent objectives

  QuestObjective({
    required this.kind,
    this.targetId,
    this.targetTag,
    required this.targetCount,
    this.currentCount = 0,
    this.comingSoon = false,
  });

  bool get isComplete => currentCount >= targetCount;
}

enum RewardKind {
  gold,
  skillXp,
  item,
  blueprint,        // a blueprint scroll (Spec 2)
  worldEvent,       // fires a milestone World Event by id
  unlock,           // generic engine-flag unlock keyed by targetId
  offerQuest,       // automatically offers a next quest by id (Spec 2)
}

class QuestReward {
  final RewardKind kind;
  final String? targetId;
  final int amount;

  const QuestReward({
    required this.kind,
    this.targetId,
    required this.amount,
  });
}

class Quest {
  final String id;
  final QuestType type;
  final String title;
  final String description;
  final List<QuestObjective> objectives;
  final List<QuestReward> rewards;
  final String? turnInLocation;  // zoneId; null = auto-turn-in on completion
  QuestStatus status;

  Quest({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.objectives,
    required this.rewards,
    this.turnInLocation,
    this.status = QuestStatus.available,
  });

  bool get isComplete => objectives.every((o) => o.isComplete);
}

sealed class QuestEvent {
  final int count;
  const QuestEvent(this.count);
}

class ItemGatheredEvent extends QuestEvent {
  final String itemId;
  const ItemGatheredEvent(this.itemId, int count) : super(count);
}

class BeastDefeatedEvent extends QuestEvent {
  final String beastId;
  const BeastDefeatedEvent(this.beastId) : super(1);
}

class ItemCraftedEvent extends QuestEvent {
  final String recipeId;
  final QualityTier? quality;
  const ItemCraftedEvent(this.recipeId, this.quality, int count) : super(count);
}

class ZoneVisitedEvent extends QuestEvent {
  final String zoneId;
  const ZoneVisitedEvent(this.zoneId) : super(1);
}

class StationRestoredEvent extends QuestEvent {
  final String zoneId;
  final String stationId;
  const StationRestoredEvent(this.zoneId, this.stationId) : super(1);
}

class StationUpgradedEvent extends QuestEvent {
  final String zoneId;
  final String stationId;
  final int newTier;
  const StationUpgradedEvent(this.zoneId, this.stationId, this.newTier) : super(1);
}

class MasterworkCompletedEvent extends QuestEvent {
  final SkillType skill;
  const MasterworkCompletedEvent(this.skill) : super(1);
}

class CodexFragmentReadEvent extends QuestEvent {
  final String fragmentId;
  const CodexFragmentReadEvent(this.fragmentId) : super(1);
}

class ScoutCompletedEvent extends QuestEvent {
  final String actionId;
  const ScoutCompletedEvent(this.actionId) : super(1);
}

class CustomQuestEvent extends QuestEvent {
  final String eventId;
  const CustomQuestEvent(this.eventId, [int count = 1]) : super(count);
}

class PuzzleResult {
  final CodexTag tag;
  final List<bool> correctness;
  final CodexReading? reading;

  const PuzzleResult({
    required this.tag,
    required this.correctness,
    this.reading,
  });
}
