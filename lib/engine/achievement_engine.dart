import '../models/codex.dart';
import '../models/skill.dart';
import '../models/shop.dart';
import '../models/crafted_item.dart';
import 'game_engine.dart';

class AchievementEngine {
  /// Checks achievements based on the current state of GameEngine and returns a list of newly unlocked achievement IDs.
  static List<String> checkAll(GameEngine engine) {
    final List<String> newlyUnlocked = [];
    final currentEarned = engine.earnedAchievementIds;

    for (final ach in Achievements.all) {
      if (currentEarned.contains(ach.id)) continue;

      if (evaluate(ach, engine)) {
        newlyUnlocked.add(ach.id);
      }
    }

    return newlyUnlocked;
  }

  static bool evaluate(Achievement ach, GameEngine engine) {
    switch (ach.trigger) {
      case AchievementTrigger.questComplete:
        final count = engine.completedQuests.length;
        final reqCount = ach.criteria['count'] ?? 1;
        return count >= reqCount;

      case AchievementTrigger.beastDefeated:
        final beastId = ach.criteria['beastId'] ?? '';
        final reqCount = ach.criteria['count'] ?? 1;
        if (beastId == 'any') {
          int sum = 0;
          engine.bestiary.forEach((k, v) {
            sum += v.defeatCount;
          });
          return sum >= reqCount;
        } else {
          final count = engine.bestiary[beastId]?.defeatCount ?? 0;
          return count >= reqCount;
        }

      case AchievementTrigger.fragmentCollected:
        final tagStr = ach.criteria['tag'] ?? 'any';
        final reqCount = ach.criteria['count'] ?? 1;
        if (tagStr == 'any') {
          return engine.knownCodexFragmentIds.length >= reqCount;
        } else {
          int count = 0;
          for (final id in engine.knownCodexFragmentIds) {
            final f = CodexFragments.findById(id);
            if (f != null && f.tag.name == tagStr) {
              count++;
            }
          }
          return count >= reqCount;
        }

      case AchievementTrigger.craftComplete:
        final reqCount = ach.criteria['count'] ?? 1;
        final quality = ach.criteria['quality'];
        final itemTypeStr = ach.criteria['itemType'];

        if (quality != null) {
          return engine.masterworkCrafts >= reqCount;
        } else if (itemTypeStr != null) {
          return engine.brewCrafts >= reqCount;
        } else {
          return engine.totalCrafts >= reqCount;
        }

      case AchievementTrigger.recipeUnlocked:
        final reqCount = ach.criteria['count'] ?? 1;
        return engine.knownRecipesCount >= reqCount;

      case AchievementTrigger.zoneEntered:
        final zoneId = ach.criteria['zoneId'] ?? '';
        return engine.unlockedZoneIds.contains(zoneId);

      case AchievementTrigger.zoneCleansed:
        final tag = ach.criteria['tag'] ?? '';
        if (tag == 'all') {
          return engine.engineFlags.contains('breach_wilds_cleansed') &&
                 engine.engineFlags.contains('breach_stone_cleansed') &&
                 engine.engineFlags.contains('breach_tide_cleansed');
        } else {
          return engine.engineFlags.contains('breach_wilds_cleansed') ||
                 engine.engineFlags.contains('breach_stone_cleansed') ||
                 engine.engineFlags.contains('breach_tide_cleansed');
        }

      case AchievementTrigger.merchantTier:
        final reqTier = ach.criteria['tier'] as ReputationTier;
        for (final m in Merchant.all) {
          final rep = engine.getMerchantReputation(m.id);
          if (rep.tier.index >= reqTier.index) {
            return true;
          }
        }
        return false;

      case AchievementTrigger.playerLevel:
        final reqLvl = ach.criteria['level'] ?? 1;
        return engine.playerStats.playerLevel >= reqLvl;

      case AchievementTrigger.skillLevel:
        final reqLvl = ach.criteria['level'] ?? 1;
        for (final skill in engine.skills.values) {
          if (skill.level >= reqLvl) return true;
        }
        return false;

      case AchievementTrigger.goldEarned:
        final reqGold = ach.criteria['cumulative'] ?? 0;
        return engine.lifetimeGold >= reqGold;

      case AchievementTrigger.totalLevel:
        int sum = 0;
        for (final skill in engine.skills.values) {
          sum += skill.level;
        }
        final reqSum = ach.criteria['sum'] ?? 1;
        return sum >= reqSum;

      case AchievementTrigger.custom:
        final key = ach.criteria['key'] ?? '';
        switch (key) {
          case 'first_gather':
            return engine.engineFlags.contains('ach_first_gather');
          case 'first_masterwork':
            return engine.engineFlags.contains('ach_first_masterwork');
          case 'all_skills_5':
            return engine.skills.values.every((s) => s.level >= 5);
          case 'all_skills_10':
            return engine.skills.values.every((s) => s.level >= 10);
          case 'defeat_all_echoes':
            return (engine.bestiary['echo_of_wilds']?.defeatCount ?? 0) >= 1 &&
                   (engine.bestiary['echo_of_stone']?.defeatCount ?? 0) >= 1 &&
                   (engine.bestiary['echo_of_tide']?.defeatCount ?? 0) >= 1;
          case 'first_repair':
            return engine.engineFlags.contains('ach_first_repair');
          case 'first_trade':
            return engine.engineFlags.contains('ach_first_trade');
          case 'sworn_all_six':
            return Merchant.all.every((m) => engine.getMerchantReputation(m.id).tier == ReputationTier.swornCompanion);
          case 'barehanded_kill':
            return engine.engineFlags.contains('ach_barehanded_kill');
          case 'no_repair_total_30':
            int sum = 0;
            for (final skill in engine.skills.values) {
              sum += skill.level;
            }
            return sum >= 30 && !engine.anyRepairThisRun;
          case 'consume_elixir_of_twilight':
            return engine.engineFlags.contains('ach_consume_elixir_of_twilight');
          case 'obelisk_double_drop':
            return engine.engineFlags.contains('ach_obelisk_double_drop');
          case 'source_defeated':
            return engine.engineFlags.contains('source_cleanser');
        }
        return false;
    }
  }
}
