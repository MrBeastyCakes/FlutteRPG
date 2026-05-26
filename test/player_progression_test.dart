import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/models/player_progression.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/models/skill.dart';

void main() {
  group('Player Progression & XP Tests', () {
    test('Player progression boundary requirements scale as 100 * playerLevel', () {
      expect(PlayerProgression.xpToNextLevel(1), 100);
      expect(PlayerProgression.xpToNextLevel(2), 200);
      expect(PlayerProgression.xpToNextLevel(5), 500);
    });

    test('XP progression carry-over and multi-level level-up', () {
      // Level 1: needs 100 XP. Gain 50 XP -> Level 1, 50 XP.
      var res = PlayerProgression.applyXp(1, 0, 50);
      expect(res.level, 1);
      expect(res.xp, 50);
      expect(res.didLevelUp, false);

      // Level 1: needs 100 XP. Gain 120 XP -> Level 2, 20 XP.
      res = PlayerProgression.applyXp(1, 0, 120);
      expect(res.level, 2);
      expect(res.xp, 20);
      expect(res.didLevelUp, true);

      // Multi-level level-up:
      // Start Level 1, 0 XP. Gain 350 XP:
      // Level 1 needs 100 (remaining 250) -> Level 2
      // Level 2 needs 200 (remaining 50) -> Level 3
      // Ends at Level 3, 50 XP.
      res = PlayerProgression.applyXp(1, 0, 350);
      expect(res.level, 3);
      expect(res.xp, 50);
      expect(res.didLevelUp, true);
    });

    test('GameEngine woodcutting action drips 20% XP to player XP pre-clamping', () {
      final engine = GameEngine();
      engine.resetGame();

      expect(engine.playerStats.playerLevel, 1);
      expect(engine.playerStats.playerXp, 0);

      // Grant woodcutting skill 150 XP. Player gets 150 * 0.2 = 30 XP.
      engine.grantSkillXpForTesting(SkillType.woodcutting, 150);
      
      expect(engine.playerStats.playerLevel, 1);
      expect(engine.playerStats.playerXp, 30);

      // Grant another 400 XP. Player gets 400 * 0.2 = 80 XP (total 110 XP).
      // Since level 1 -> 2 requires 100 XP, player should level up to level 2 with 10 XP carry-over.
      engine.grantSkillXpForTesting(SkillType.woodcutting, 400);

      expect(engine.playerStats.playerLevel, 2);
      expect(engine.playerStats.playerXp, 10);
    });
  });
}
