import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/views/inventory/inventory_filter_state.dart';
import 'package:flutter_text_based_rpg/views/inventory/inventory_grid.dart';
import 'package:flutter_text_based_rpg/views/inventory/inventory_grid_cell.dart';

void main() {
  testWidgets('renders one cell per filtered item', (tester) async {
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
          child: const SingleChildScrollView(child: InventoryGrid()),
        ),
      ),
    ));
    await tester.pump();

    final nonEmpty = engine.inventory.slots.length;
    if (nonEmpty == 0) {
      expect(find.textContaining('empty'), findsOneWidget); // empty state
    } else {
      expect(find.byType(InventoryGridCell), findsNWidgets(nonEmpty));
    }
  });
}
