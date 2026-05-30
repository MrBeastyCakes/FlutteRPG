import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/models/inventory.dart';
import 'package:flutter_text_based_rpg/models/item.dart';
import 'package:flutter_text_based_rpg/views/inventory/inventory_grid_cell.dart';

void main() {
  testWidgets('renders item icon and quantity badge when >1', (tester) async {
    final engine = GameEngine();
    final slot = InventorySlot(
        item: Items.findById('oak_log')!, quantity: 3, affixIds: const []);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChangeNotifierProvider<GameEngine>.value(
          value: engine,
          child: InventoryGridCell(slot: slot),
        ),
      ),
    ));
    await tester.pump();
    expect(find.text(slot.item.icon), findsOneWidget);
    expect(find.textContaining('3'), findsWidgets); // ×3 badge
  });
}
