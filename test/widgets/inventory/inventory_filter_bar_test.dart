import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/views/inventory/inventory_filter_state.dart';
import 'package:flutter_text_based_rpg/views/inventory/inventory_filter_bar.dart';

void main() {
  testWidgets('renders base filter chips and updates state on tap',
      (tester) async {
    final engine = GameEngine();
    final filterState = InventoryFilterState();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MultiProvider(
          providers: [
            ChangeNotifierProvider<GameEngine>.value(value: engine),
            ChangeNotifierProvider<InventoryFilterState>.value(
                value: filterState),
          ],
          child: const InventoryFilterBar(),
        ),
      ),
    ));
    await tester.pump();

    expect(find.text('All'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);

    await tester.tap(find.text('Food'));
    await tester.pump();
    expect(filterState.filter, InventoryFilter.food);
  });
}
