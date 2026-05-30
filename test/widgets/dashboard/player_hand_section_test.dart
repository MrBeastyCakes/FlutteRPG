import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/views/dashboard/player_hand_section.dart';

void main() {
  Widget wrap(GameEngine engine) => MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<GameEngine>.value(
            value: engine,
            child: const SingleChildScrollView(child: PlayerHandSection()),
          ),
        ),
      );

  testWidgets('renders player name, level, HP and energy values', (tester) async {
    final engine = GameEngine();
    final stats = engine.playerStats;
    await tester.pumpWidget(wrap(engine));
    await tester.pump();

    expect(find.text(stats.name), findsOneWidget);
    expect(find.text('Lvl ${stats.playerLevel}'), findsOneWidget);

    final hpText = '${stats.currentHealth}/${stats.maxHealth}';
    final enText = '${stats.currentEnergy}/${stats.maxEnergy}';
    if (hpText == enText) {
      // Initial stats have identical HP/energy values, so the same string
      // is rendered by both the HP and the energy bars.
      expect(find.text(hpText), findsNWidgets(2));
    } else {
      expect(find.text(hpText), findsOneWidget);
      expect(find.text(enText), findsOneWidget);
    }
  });
}
