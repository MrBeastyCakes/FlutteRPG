import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/models/codex.dart';
import 'package:flutter_text_based_rpg/models/skill.dart';

void main() {
  group('Codex puzzle locking', () {
    late GameEngine engine;

    setUp(() {
      engine = GameEngine();
      // Force-collect all 10 Wilds fragments by repeatedly attempting drops (chance 1.0)
      for (int i = 0; i < 50; i++) {
        engine.tryDropFragment(CodexTag.wilds, 1.0);
      }
    });

    test('Locking correct order solves puzzle and grants rewards', () {
      final correctOrder = CodexFragments.all
          .where((f) => f.tag == CodexTag.wilds)
          .toList()
        ..sort((a, b) => a.orderInTag.compareTo(b.orderInTag));
      final ids = correctOrder.map((f) => f.id).toList();

      final loreBefore = engine.skills[SkillType.lore]!.xp;
      final goldBefore = engine.playerStats.gold;
      engine.lockCodexPuzzle(CodexTag.wilds, ids);

      expect(engine.solvedTagPuzzles.contains(CodexTag.wilds), true);
      expect(engine.engineFlags.contains('puzzle_wilds_solved'), true);
      expect(engine.skills[SkillType.lore]!.xp, greaterThan(loreBefore));
      expect(engine.playerStats.gold, greaterThan(goldBefore));
    });

    test('Locking wrong order does NOT solve puzzle and deducts 3 Lore XP', () {
      // Pump some Lore XP first
      engine.skills[SkillType.lore] =
          engine.skills[SkillType.lore]!.addXp(100);
      final loreBefore = engine.skills[SkillType.lore]!.xp;

      // Wrong order: just reverse the correct sequence
      final wrongIds = CodexFragments.all
          .where((f) => f.tag == CodexTag.wilds)
          .toList()
          .reversed
          .map((f) => f.id)
          .toList();

      engine.lockCodexPuzzle(CodexTag.wilds, wrongIds);

      expect(engine.solvedTagPuzzles.contains(CodexTag.wilds), false);
      expect(engine.skills[SkillType.lore]!.xp, loreBefore - 3);
    });

    test('Wrong-Lock Lore XP clamps to 0 (no negative)', () {
      // Wilds skill init has 0 XP; verify it stays at 0
      final wrongIds = CodexFragments.all
          .where((f) => f.tag == CodexTag.wilds)
          .toList()
          .reversed
          .map((f) => f.id)
          .toList();

      engine.lockCodexPuzzle(CodexTag.wilds, wrongIds);
      expect(engine.skills[SkillType.lore]!.xp, 0);
    });

    test('Re-locking already-solved puzzle is no-op (no double rewards)', () {
      final correctOrder = CodexFragments.all
          .where((f) => f.tag == CodexTag.wilds)
          .toList()
        ..sort((a, b) => a.orderInTag.compareTo(b.orderInTag));
      final ids = correctOrder.map((f) => f.id).toList();

      engine.lockCodexPuzzle(CodexTag.wilds, ids);
      final goldAfterFirst = engine.playerStats.gold;

      engine.lockCodexPuzzle(CodexTag.wilds, ids);
      expect(engine.playerStats.gold, goldAfterFirst,
          reason: 'Re-lock should not grant gold again');
    });
  });
}
