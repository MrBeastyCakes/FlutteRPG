import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/models/beast.dart';
import 'package:flutter_text_based_rpg/views/combat_hud.dart';
import 'package:flutter_text_based_rpg/views/combat/beast_card.dart';
import 'package:flutter_text_based_rpg/views/combat/stance_pad.dart';

class _CombatEngine extends GameEngine {
  CombatState? _override;
  void setCombat(CombatState s) {
    _override = s;
    notifyListeners();
  }

  @override
  CombatState? get activeCombat => _override;
}

void main() {
  testWidgets('CombatHud composes BeastCard and StancePad', (tester) async {
    final engine = _CombatEngine();
    final beast = Beasts.findById('forest_boar')!;
    engine.setCombat(CombatState(
        beast: beast,
        beastCurrentHealth: beast.maxHealth,
        playerStartHealth: 100,
        combatLog: const []));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          body: ChangeNotifierProvider<GameEngine>.value(
              value: engine, child: const CombatHud())),
    ));
    await tester.pump();
    expect(find.byType(BeastCard), findsOneWidget);
    expect(find.byType(StancePad), findsOneWidget);
    expect(find.text(beast.name), findsOneWidget);
  });
}
