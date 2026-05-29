import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/views/combat/player_card_mini.dart';

void main() {
  testWidgets('shows player HP and energy, no XP/title', (tester) async {
    final engine = GameEngine();
    final stats = engine.playerStats;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          body: ChangeNotifierProvider<GameEngine>.value(
              value: engine, child: const PlayerCardMini())),
    ));
    await tester.pump();
    final hpLabel = '${stats.currentHealth}/${stats.maxHealth}';
    final energyLabel = '${stats.currentEnergy}/${stats.maxEnergy}';
    if (hpLabel == energyLabel) {
      // Default new-game stats render HP and energy identically (100/100);
      // both bars are present so expect two matching labels.
      expect(find.text(hpLabel), findsNWidgets(2));
    } else {
      expect(find.text(hpLabel), findsOneWidget);
      expect(find.text(energyLabel), findsOneWidget);
    }
    expect(find.textContaining('XP'), findsNothing);
  });
}
