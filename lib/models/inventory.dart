import 'item.dart';
import 'skill.dart';
import 'crafted_item.dart';

class InventoryKey {
  final String itemId;
  final QualityTier? quality;
  final List<String> affixIds; // sorted list

  const InventoryKey({
    required this.itemId,
    this.quality,
    required this.affixIds,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InventoryKey &&
          runtimeType == other.runtimeType &&
          itemId == other.itemId &&
          quality == other.quality &&
          _listEquals(affixIds, other.affixIds);

  @override
  int get hashCode =>
      itemId.hashCode ^
      (quality?.hashCode ?? 0) ^
      affixIds.fold(0, (prev, element) => prev ^ element.hashCode);

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class InventorySlot {
  final Item item;
  final int quantity;
  final QualityTier? quality;
  final List<String> affixIds;

  const InventorySlot({
    required this.item,
    required this.quantity,
    this.quality,
    required this.affixIds,
  });

  InventorySlot copyWith({
    Item? item,
    int? quantity,
    QualityTier? quality,
    List<String>? affixIds,
  }) {
    return InventorySlot(
      item: item ?? this.item,
      quantity: quantity ?? this.quantity,
      quality: quality ?? this.quality,
      affixIds: affixIds ?? this.affixIds,
    );
  }
}

class Inventory {
  final Map<InventoryKey, int> items;
  final int capacity;

  const Inventory({
    required this.items,
    this.capacity = 4,
  });

  Inventory copyWith({
    Map<InventoryKey, int>? items,
    int? capacity,
  }) {
    return Inventory(
      items: items ?? this.items,
      capacity: capacity ?? this.capacity,
    );
  }

  List<InventorySlot> get slots {
    final list = <InventorySlot>[];
    items.forEach((key, qty) {
      final item = Items.findById(key.itemId);
      if (item != null) {
        bool isStackable = item.type != ItemType.tool && item.type != ItemType.weapon && item.type != ItemType.armor;
        if (isStackable) {
          list.add(InventorySlot(
            item: item,
            quantity: qty,
            quality: key.quality,
            affixIds: key.affixIds,
          ));
        } else {
          for (int i = 0; i < qty; i++) {
            list.add(InventorySlot(
              item: item,
              quantity: 1,
              quality: key.quality,
              affixIds: key.affixIds,
            ));
          }
        }
      }
    });
    return list;
  }

  int get occupiedSlots {
    int slotsCount = 0;
    items.forEach((key, qty) {
      final item = Items.findById(key.itemId);
      if (item != null) {
        bool isStackable = item.type != ItemType.tool && item.type != ItemType.weapon && item.type != ItemType.armor;
        slotsCount += isStackable ? 1 : qty;
      }
    });
    return slotsCount;
  }

  bool get isFull => occupiedSlots >= capacity;

  Item? getBestToolFor(SkillType skill) {
    Item? bestTool;
    for (var slot in slots) {
      if (slot.item.isTool && slot.item.toolSkill == skill) {
        if (bestTool == null || slot.item.speedBonus > bestTool.speedBonus) {
          bestTool = slot.item;
        }
      }
    }
    return bestTool;
  }

  bool hasItem(String itemId, [int quantity = 1]) {
    return getItemCount(itemId) >= quantity;
  }

  int getItemCount(String itemId) {
    int count = 0;
    items.forEach((key, qty) {
      if (key.itemId == itemId) {
        count += qty;
      }
    });
    return count;
  }

  int getItemCountPrecise(String itemId, QualityTier? quality, List<String> affixIds) {
    final sortedAffixes = List<String>.from(affixIds)..sort();
    final key = InventoryKey(itemId: itemId, quality: quality, affixIds: sortedAffixes);
    return items[key] ?? 0;
  }

  Inventory addItem(Item item, int quantity, [QualityTier? quality, List<String>? affixIds]) {
    if (quantity <= 0) return this;

    final sortedAffixes = affixIds != null ? (List<String>.from(affixIds)..sort()) : <String>[];
    final key = InventoryKey(itemId: item.id, quality: quality, affixIds: sortedAffixes);
    final newItems = Map<InventoryKey, int>.from(items);

    bool isStackable = item.type != ItemType.tool && item.type != ItemType.weapon && item.type != ItemType.armor;

    if (isStackable) {
      if (newItems.containsKey(key)) {
        newItems[key] = newItems[key]! + quantity;
      } else {
        if (occupiedSlots + 1 > capacity) return this;
        newItems[key] = quantity;
      }
    } else {
      if (occupiedSlots + quantity > capacity) return this;
      newItems[key] = (newItems[key] ?? 0) + quantity;
    }

    return Inventory(items: newItems, capacity: capacity);
  }

  Inventory removeItem(String itemId, int quantity, [QualityTier? quality, List<String>? affixIds]) {
    if (quantity <= 0) return this;

    final newItems = Map<InventoryKey, int>.from(items);
    int remainingToRemove = quantity;

    if (quality != null || affixIds != null) {
      final sortedAffixes = affixIds != null ? (List<String>.from(affixIds)..sort()) : <String>[];
      final key = InventoryKey(itemId: itemId, quality: quality, affixIds: sortedAffixes);
      if (newItems.containsKey(key)) {
        int currentQty = newItems[key]!;
        if (currentQty > remainingToRemove) {
          newItems[key] = currentQty - remainingToRemove;
          remainingToRemove = 0;
        } else {
          remainingToRemove -= currentQty;
          newItems.remove(key);
        }
      }
    } else {
      final matchingKeys = newItems.keys.where((k) => k.itemId == itemId).toList();
      matchingKeys.sort((a, b) {
        int valA = a.quality == null ? -1 : a.quality!.index;
        int valB = b.quality == null ? -1 : b.quality!.index;
        return valA.compareTo(valB);
      });

      for (var key in matchingKeys) {
        if (remainingToRemove <= 0) break;
        int currentQty = newItems[key]!;
        if (currentQty > remainingToRemove) {
          newItems[key] = currentQty - remainingToRemove;
          remainingToRemove = 0;
        } else {
          remainingToRemove -= currentQty;
          newItems.remove(key);
        }
      }
    }

    return Inventory(items: newItems, capacity: capacity);
  }

  factory Inventory.initial() {
    return const Inventory(
      items: {},
    );
  }
}
