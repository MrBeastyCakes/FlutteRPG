import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/models/inventory.dart';
import 'package:flutter_text_based_rpg/models/item.dart';
import 'package:flutter_text_based_rpg/views/inventory/inventory_filter_state.dart';
import 'package:flutter_text_based_rpg/views/inventory/inventory_filter_logic.dart';

InventorySlot _slot(String id, int qty) => InventorySlot(
      item: Items.findById(id)!,
      quantity: qty,
      affixIds: const [],
    );

void main() {
  test('name search filters case-insensitively', () {
    final slots = <InventorySlot>[
      _slot('oak_log', 2), // resource — "Oak Log"
      _slot('wild_berries', 1), // food — "Wild Berries"
    ];
    final result = applyInventoryFilter(
        slots, InventoryFilter.all, InventorySort.name, 'oak');
    expect(result.length, 1);
    expect(result.first.item.id, 'oak_log');
  });

  test('type filter keeps only matching ItemType', () {
    final slots = <InventorySlot>[
      _slot('oak_log', 2), // resource
      _slot('wild_berries', 1), // food
    ];
    final result = applyInventoryFilter(
        slots, InventoryFilter.food, InventorySort.name, '');
    expect(result.every((s) => s.item.type == ItemType.food), isTrue);
    expect(result.length, 1);
    expect(result.first.item.id, 'wild_berries');
  });
}
