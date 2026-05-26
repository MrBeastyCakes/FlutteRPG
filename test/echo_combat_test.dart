import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/models/beast.dart';
import 'package:flutter_text_based_rpg/models/skill.dart';
import 'package:flutter_text_based_rpg/models/item.dart';

void main() {
  group('Echo combat tests', () {
    test('Each Echo has phases populated', () {
      for (final id in ['echo_of_wilds', 'echo_of_stone', 'echo_of_tide']) {
        final beast = Beasts.findById(id)!;
        expect(beast.phases, isNotNull);
        expect(beast.phases!.length, 3);
      }
    });

    test('Echo phase transitions at hpThreshold', () {
      final engine = GameEngine();
      engine.startEchoFightForTest('echo_of_wilds');
      expect(engine.activeCombat!.activePhaseIndex, 0);

      // Drop beast HP to 66% of 240 = 158
      engine.setBeastHpForTest(158);
      engine.checkEchoPhaseTransitionForTest();
      expect(engine.activeCombat!.activePhaseIndex, 1);
      expect(engine.activeCombat!.activePhasePassive, BeastPassive.healOnHit);

      // Drop to 33% = 79
      engine.setBeastHpForTest(79);
      engine.checkEchoPhaseTransitionForTest();
      expect(engine.activeCombat!.activePhaseIndex, 2);
      expect(engine.activeCombat!.activePhasePassive, BeastPassive.enrage);
    });

    test('healOnHit passive heals beast 3 HP per round', () {
      final engine = GameEngine();
      engine.startEchoFightForTest('echo_of_wilds');
      engine.setBeastHpForTest(150);
      engine.checkEchoPhaseTransitionForTest();  // enter P2

      // Apply passive
      engine.applyEchoPassiveForTest();
      expect(engine.activeCombat!.beastCurrentHealth, 150 + 3);
    });
  });
}
