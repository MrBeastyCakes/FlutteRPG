import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/views/combat/quickslot_bar.dart';

void main() {
  testWidgets('renders three cells; empty cells show Empty', (tester) async {
    final engine = GameEngine();
    for (var i = 0; i < 3; i++) {
      engine.setQuickslot(i, null); // ensure all empty
    }
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          body: ChangeNotifierProvider<GameEngine>.value(
              value: engine, child: const QuickslotBar())),
    ));
    await tester.pump();
    expect(find.text('Empty'), findsNWidgets(3));
  });
}
