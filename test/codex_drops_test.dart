import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/models/codex.dart';

void main() {
  group('Codex Fragment Drops & Pool Gates', () {
    late GameEngine engine;

    setUp(() {
      engine = GameEngine();
    });

    test('Wilds and Old Empire pools are open by default', () {
      engine.tryDropFragment(CodexTag.wilds, 1.0);
      expect(engine.knownCodexFragmentIds.length, 1);
      final firstFragment = CodexFragments.findById(engine.knownCodexFragmentIds.first)!;
      expect(firstFragment.tag, CodexTag.wilds);

      engine.tryDropFragment(CodexTag.oldEmpire, 1.0);
      expect(engine.knownCodexFragmentIds.length, 2);
    });

    test('Stone pool is closed initially, opens on darkstone_mine_1 discovery', () {
      // Should not drop initially
      engine.tryDropFragment(CodexTag.stone, 1.0);
      expect(engine.knownCodexFragmentIds.length, 0);

      // Discover darkstone_mine_1
      engine.recordRegionDiscovered('darkstone_mine_1');
      engine.tryDropFragment(CodexTag.stone, 1.0);
      expect(engine.knownCodexFragmentIds.length, 1);
      final fragment = CodexFragments.findById(engine.knownCodexFragmentIds.first)!;
      expect(fragment.tag, CodexTag.stone);
    });

    test('Tide pool is closed initially, opens on coast_unlocked flag', () {
      engine.tryDropFragment(CodexTag.tide, 1.0);
      expect(engine.knownCodexFragmentIds.length, 0);

      engine.setEngineFlag('coast_unlocked');
      engine.tryDropFragment(CodexTag.tide, 1.0);
      expect(engine.knownCodexFragmentIds.length, 1);
      final fragment = CodexFragments.findById(engine.knownCodexFragmentIds.first)!;
      expect(fragment.tag, CodexTag.tide);
    });

    test('Source pool is closed initially, opens on first_breach_cleansed flag', () {
      engine.tryDropFragment(CodexTag.source, 1.0);
      expect(engine.knownCodexFragmentIds.length, 0);

      engine.setEngineFlag('first_breach_cleansed');
      engine.tryDropFragment(CodexTag.source, 1.0);
      expect(engine.knownCodexFragmentIds.length, 1);
      final fragment = CodexFragments.findById(engine.knownCodexFragmentIds.first)!;
      expect(fragment.tag, CodexTag.source);
    });
  });
}
