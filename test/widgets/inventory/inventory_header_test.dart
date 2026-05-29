import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/views/inventory/inventory_header.dart';

void main() {
  testWidgets('shows title and gold', (tester) async {
    final engine = GameEngine();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          body: ChangeNotifierProvider<GameEngine>.value(
              value: engine, child: const InventoryHeader())),
    ));
    await tester.pump();
    expect(find.text('Inventory'), findsOneWidget);
    expect(find.textContaining('${engine.playerStats.gold}'), findsOneWidget);
  });
}
