import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/models/beast.dart';
import 'package:flutter_text_based_rpg/views/combat/beast_card.dart';

class _CombatEngine extends GameEngine {
  CombatState? _override;
  void setCombat(CombatState s) { _override = s; notifyListeners(); }
  @override
  CombatState? get activeCombat => _override;
}

void main() {
  testWidgets('renders beast name and HP values', (tester) async {
    final engine = _CombatEngine();
    final beast = Beasts.findById('forest_boar')!;
    engine.setCombat(CombatState(
      beast: beast,
      beastCurrentHealth: beast.maxHealth,
      playerStartHealth: 100,
      combatLog: const [],
    ));

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChangeNotifierProvider<GameEngine>.value(
          value: engine,
          child: const BeastCard(),
        ),
      ),
    ));
    await tester.pump();

    expect(find.text(beast.name), findsOneWidget);
    expect(find.text('${beast.maxHealth}/${beast.maxHealth}'), findsOneWidget);
  });
}
