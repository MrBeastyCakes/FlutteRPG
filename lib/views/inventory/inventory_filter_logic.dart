import '../../models/inventory.dart';
import '../../models/item.dart';
import 'inventory_filter_state.dart';

/// Pure filter + sort over inventory slots. Kept top-level so it is unit-testable
/// without a widget tree.
List<InventorySlot> applyInventoryFilter(
  List<InventorySlot> slots,
  InventoryFilter filter,
  InventorySort sort,
  String query,
) {
  final q = query.trim().toLowerCase();
  Iterable<InventorySlot> out = slots;

  // Type filter
  out = out.where((s) {
    switch (filter) {
      case InventoryFilter.all:
        return true;
      case InventoryFilter.tool:
        return s.item.type == ItemType.tool;
      case InventoryFilter.weapon:
        return s.item.type == ItemType.weapon;
      case InventoryFilter.armor:
        return s.item.type == ItemType.armor;
      case InventoryFilter.food:
        return s.item.type == ItemType.food;
      case InventoryFilter.quest:
        // TODO(implementer): replace with the real quest-item predicate once
        // confirmed (id list / bool flag). For now treat nothing as quest.
        return false;
    }
  });

  // Search
  if (q.isNotEmpty) {
    out = out.where((s) => s.item.name.toLowerCase().contains(q));
  }

  final list = out.toList();

  // Sort
  switch (sort) {
    case InventorySort.name:
      list.sort((a, b) => a.item.name.compareTo(b.item.name));
      break;
    case InventorySort.quality:
      list.sort((a, b) =>
          (b.quality?.index ?? 0).compareTo(a.quality?.index ?? 0));
      break;
    case InventorySort.type:
      list.sort((a, b) => a.item.type.index.compareTo(b.item.type.index));
      break;
  }
  return list;
}
