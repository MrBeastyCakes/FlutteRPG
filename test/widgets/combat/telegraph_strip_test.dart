import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/models/beast.dart';
import 'package:flutter_text_based_rpg/models/combat.dart';
import 'package:flutter_text_based_rpg/views/combat/telegraph_strip.dart';

class _CombatEngine extends GameEngine {
  CombatState? _override;
  void setCombat(CombatState? s) {
    _override = s;
    notifyListeners();
  }

  @override
  CombatState? get activeCombat => _override;
}

void main() {
  testWidgets('hidden when no telegraph, shown with telegraph text',
      (tester) async {
    final engine = _CombatEngine();
    final beast = Beasts.findById('forest_boar')!;
    final base = CombatState(
        beast: beast,
        beastCurrentHealth: beast.maxHealth,
        playerStartHealth: 100,
        combatLog: const []);
    engine.setCombat(base);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          body: ChangeNotifierProvider<GameEngine>.value(
              value: engine, child: const TelegraphStrip())),
    ));
    await tester.pump();
    expect(find.textContaining('lowers its head'), findsNothing);

    engine.setCombat(base.copyWith(
      activeTelegraph: const BeastTelegraph(
          abilityId: 'gore',
          text: 'The boar lowers its head.',
          reveal: false),
    ));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.textContaining('The boar lowers its head.'), findsOneWidget);
  });
}
