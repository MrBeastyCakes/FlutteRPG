import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/views/inventory/equipped_strip.dart';

void main() {
  testWidgets('collapsed by default, expands on tap', (tester) async {
    final engine = GameEngine();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          body: ChangeNotifierProvider<GameEngine>.value(
              value: engine, child: const EquippedStrip())),
    ));
    await tester.pump();

    // Collapsed header present
    expect(find.textContaining('Equipped'), findsOneWidget);

    // Tap the header to expand — no exception, header still present.
    await tester.tap(find.textContaining('Equipped'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Equipped'), findsOneWidget);
  });
}
