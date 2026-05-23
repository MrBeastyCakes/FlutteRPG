import 'item.dart';
import 'skill.dart';

class InventorySlot {
  final Item item;
  final int quantity;

  const InventorySlot({
    required this.item,
    required this.quantity,
  });

  InventorySlot copyWith({
    Item? item,
    int? quantity,
  }) {
    return InventorySlot(
      item: item ?? this.item,
      quantity: quantity ?? this.quantity,
    );
  }
}

class Inventory {
  final List<InventorySlot> slots;
  final int capacity;

  const Inventory({
    required this.slots,
    this.capacity = 4,
  });

  Inventory copyWith({
    List<InventorySlot>? slots,
    int? capacity,
  }) {
    return Inventory(
      slots: slots ?? this.slots,
      capacity: capacity ?? this.capacity,
    );
  }

  int get occupiedSlots => slots.length;
  bool get isFull => occupiedSlots >= capacity;

  /// Find the best tool equipped/carried in inventory for a specific skill.
  /// Returns null if no tool is carried.
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

  /// Check if the inventory contains a certain quantity of an item
  bool hasItem(String itemId, [int quantity = 1]) {
    return getItemCount(itemId) >= quantity;
  }

  /// Get the total count of a specific item in the inventory
  int getItemCount(String itemId) {
    int count = 0;
    for (var slot in slots) {
      if (slot.item.id == itemId) {
        count += slot.quantity;
      }
    }
    return count;
  }

  /// Adds items to the inventory. Returns the new Inventory.
  /// If it exceeds capacity, it fails (returns same inventory or throws/handles it).
  /// We will return the new inventory and can check if it succeeds.
  Inventory addItem(Item item, int quantity) {
    if (quantity <= 0) return this;

    List<InventorySlot> newSlots = List.from(slots);

    // If item is stackable, check if we already have a slot for it
    bool isStackable = item.type != ItemType.tool;

    if (isStackable) {
      int existingIndex = newSlots.indexWhere((slot) => slot.item.id == item.id);
      if (existingIndex != -1) {
        // Increment quantity in existing slot
        newSlots[existingIndex] = newSlots[existingIndex].copyWith(
          quantity: newSlots[existingIndex].quantity + quantity,
        );
        return Inventory(slots: newSlots, capacity: capacity);
      }
    }

    // Unstackable, or item doesn't exist yet: check if we have room
    if (newSlots.length >= capacity) {
      // Inventory is full
      return this;
    }

    // Add new slot
    newSlots.add(InventorySlot(item: item, quantity: isStackable ? quantity : 1));
    
    // If quantity was > 1 for unstackable, we'd need to add multiple slots
    if (!isStackable && quantity > 1) {
      return Inventory(slots: newSlots, capacity: capacity).addItem(item, quantity - 1);
    }

    return Inventory(slots: newSlots, capacity: capacity);
  }

  /// Removes a certain quantity of an item. Returns the new Inventory.
  Inventory removeItem(String itemId, int quantity) {
    if (quantity <= 0) return this;

    List<InventorySlot> newSlots = List.from(slots);
    int remainingToRemove = quantity;

    // Start removing from slots containing the item, from back to front (or front to back)
    for (int i = 0; i < newSlots.length; i++) {
      if (newSlots[i].item.id == itemId) {
        int currentQty = newSlots[i].quantity;
        if (currentQty > remainingToRemove) {
          newSlots[i] = newSlots[i].copyWith(quantity: currentQty - remainingToRemove);
          remainingToRemove = 0;
          break;
        } else {
          remainingToRemove -= currentQty;
          newSlots.removeAt(i);
          i--; // Adjust index after removal
        }
      }
    }

    return Inventory(slots: newSlots, capacity: capacity);
  }

  factory Inventory.initial() {
    // Start empty
    return const Inventory(
      slots: [],
    );
  }
}
