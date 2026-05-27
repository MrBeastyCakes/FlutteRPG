import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/models/codex.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/engine/achievement_engine.dart';
import 'package:flutter_text_based_rpg/models/beast.dart';
import 'package:flutter_text_based_rpg/models/shop.dart';

void main() {
  group('Achievement System Tests', () {
    test('Achievements registry has exactly 41 achievements', () {
      expect(Achievements.all.length, 41);
    });

    test('Achievements are grouped correctly into categories', () {
      final map = <AchievementCategory, int>{};
      for (final ach in Achievements.all) {
        map[ach.category] = (map[ach.category] ?? 0) + 1;
      }

      expect(map[AchievementCategory.firstSteps], 6);
      expect(map[AchievementCategory.mastery], 7);
      expect(map[AchievementCategory.combat], 6);
      expect(map[AchievementCategory.crafting], 6);
      expect(map[AchievementCategory.lore], 6);
      expect(map[AchievementCategory.economy], 6);
      expect(map[AchievementCategory.hidden], 4);
    });

    test('Achievements display: 37 visible, 4 hidden', () {
      final visible = Achievements.all.where((a) => !a.hidden).toList();
      final hidden = Achievements.all.where((a) => a.hidden).toList();

      expect(visible.length, 37);
      expect(hidden.length, 4);
      
      for (final h in hidden) {
        expect(h.category, AchievementCategory.hidden);
      }
    });

    test('Unlock triggers evaluation through GameEngine', () {
      final engine = GameEngine();
      engine.resetGame();

      // Initially, no achievements earned
      expect(engine.earnedAchievementIds.isEmpty, true);

      // Trigger first gather
      engine.addEngineFlagForTesting('ach_first_gather');
      
      // Verify that 'first_gather' achievement was automatically unlocked by the engine
      expect(engine.earnedAchievementIds.contains('first_gather'), true);
    });

    test('Unlocking combat achievements reveals beast weakness hint in Bestiary', () {
      final engine = GameEngine();
      engine.resetGame();

      // Forest Boar weakness is 'Heavy Strike during charge windows'
      final beast = Beasts.forestBoar;
      expect(beast.weaknessHint, 'Heavy Strike during charge windows');

      // The weakness is conditionally displayed in CodexView if corresponding achievement is earned.
      // Let's check the logic:
      bool hasWeaknessUnlocked(Beast b) {
        return b.weaknessHint != null &&
            Achievements.all.any((ach) =>
                ach.bestiaryHintBeastId == b.id &&
                engine.earnedAchievementIds.contains(ach.id));
      }

      // Initially locked
      expect(hasWeaknessUnlocked(beast), false);

      // Earn 'boar_hunter' achievement
      engine.earnAchievementForTesting('boar_hunter');

      // Now unlocked!
      expect(hasWeaknessUnlocked(beast), true);
    });
  });
}
