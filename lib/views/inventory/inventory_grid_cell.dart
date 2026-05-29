import 'package:flutter/material.dart';
import '../../models/inventory.dart';

/// Inventory Grid Cell — a single inventory slot tile in the grid.
class InventoryGridCell extends StatelessWidget {
  final InventorySlot slot;
  const InventoryGridCell({super.key, required this.slot});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
