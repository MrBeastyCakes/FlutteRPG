import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../engine/game_engine.dart';
import '../models/item.dart';
import '../models/zone.dart';
import '../theme/game_theme.dart';

class InventoryView extends StatefulWidget {
  const InventoryView({super.key});

  @override
  State<InventoryView> createState() => _InventoryViewState();
}

class _InventoryViewState extends State<InventoryView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final engine = Provider.of<GameEngine>(context);
    final inventory = engine.inventory;
    final gold = engine.playerStats.gold;

    return Column(
      children: [
        // Tab Bar
        TabBar(
          controller: _tabController,
          indicatorColor: GameTheme.accentGold,
          labelColor: GameTheme.accentGold,
          unselectedLabelColor: GameTheme.textMuted,
          tabs: const [
            Tab(text: 'My Inventory', icon: Icon(Icons.backpack)),
            Tab(text: 'Merchant Shop', icon: Icon(Icons.store)),
          ],
        ),
        // Tab contents
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildInventoryTab(context, engine, inventory, gold),
              _buildShopTab(context, engine, inventory, gold),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInventoryTab(
      BuildContext context, GameEngine engine, dynamic inventory, int gold) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Slots filled & Gold display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Space: ${inventory.occupiedSlots} / ${inventory.capacity} slots filled',
                style: const TextStyle(color: GameTheme.textMuted, fontSize: 13),
              ),
              Row(
                children: [
                  const Icon(Icons.monetization_on, color: GameTheme.accentGold, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '$gold Gold',
                    style: const TextStyle(
                      color: GameTheme.accentGold,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 28 Slot Grid
          Expanded(
            child: GridView.builder(
              itemCount: inventory.capacity,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                if (index < inventory.slots.length) {
                  final slot = inventory.slots[index];
                  final item = slot.item;
                  final qty = slot.quantity;

                  return GestureDetector(
                    onTap: () => _showItemDetailsSheet(context, engine, item, qty),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2833),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: GameTheme.border, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Item Emoji
                          Text(
                            item.icon,
                            style: const TextStyle(fontSize: 32),
                          ),
                          // Quantity indicator
                          if (qty > 1)
                            Positioned(
                              right: 6,
                              bottom: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.65),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '$qty',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          // Tool type indicator badge
                          if (item.isTool)
                            const Positioned(
                              left: 6,
                              top: 6,
                              child: Icon(
                                Icons.build,
                                size: 10,
                                color: GameTheme.accentGold,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                } else {
                  // Empty slot
                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF10171E).withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: GameTheme.border.withOpacity(0.3), width: 1),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showItemDetailsSheet(BuildContext context, GameEngine engine, Item item, int quantity) {
    final inTown = engine.currentZone.id == 'town_square';

    showModalBottomSheet(
      context: context,
      backgroundColor: GameTheme.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Item Header
                Row(
                  children: [
                    Text(
                      item.icon,
                      style: const TextStyle(fontSize: 40),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.isFood
                                ? 'Consumable Food'
                                : (item.isTool ? 'Gathering Tool' : 'Raw Resource'),
                            style: const TextStyle(color: GameTheme.accentGold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: GameTheme.textMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Description
                Text(
                  item.description,
                  style: const TextStyle(color: GameTheme.textLight, fontSize: 14),
                ),
                const SizedBox(height: 16),
                // Stats attributes
                if (item.isFood) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF222C37),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: GameTheme.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text(
                          '❤️ Restores Health: +${item.healAmount}',
                          style: const TextStyle(color: GameTheme.healthRed, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '⚡ Restores Energy: +${item.energyAmount}',
                          style: const TextStyle(color: GameTheme.energyYellow, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (item.isTool) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF222C37),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: GameTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🔧 Skill Target: ${item.toolSkill!.name}',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '🏎️ Speed Bonus: +${(item.speedBonus * 100).toInt()}% speed',
                          style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
                        ),
                        Text(
                          '🎯 Success Bonus: +${(item.successBonus * 100).toInt()}% success rate',
                          style: const TextStyle(color: Colors.blueAccent, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Action buttons
                Row(
                  children: [
                    if (item.isFood)
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            engine.eatFood(item);
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.restaurant),
                          label: const Text('Eat Item', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    if (item.isFood) const SizedBox(width: 12),

                    // Sell Actions (Depends on Town location)
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: inTown ? GameTheme.accentGold : GameTheme.textMuted,
                          side: BorderSide(
                            color: inTown ? GameTheme.accentGold : GameTheme.border,
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: inTown
                            ? () {
                                engine.sellItem(item, 1);
                                Navigator.pop(context);
                              }
                            : null, // Disabled if not in Town
                        icon: const Icon(Icons.sell),
                        label: Text(
                          inTown ? 'Sell 1 (${item.value}g)' : 'Sell (Town Only)',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShopTab(BuildContext context, GameEngine engine, dynamic inventory, int gold) {
    // Items for sale
    final buyables = [
      Items.wildBerries,
      Items.bakedPotato,
      Items.herbalTea,
      Items.stoneAxe,
      Items.ironAxe,
      Items.stonePickaxe,
      Items.ironPickaxe,
      Items.foragingGloves,
    ];

    final inTown = engine.currentZone.id == 'town_square';

    if (!inTown) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.store_outlined, size: 64, color: GameTheme.textMuted),
              const SizedBox(height: 16),
              const Text(
                'Merchant Shop Locked',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'You must travel back to the Town Square in order to trade with the merchants.',
                textAlign: TextAlign.center,
                style: TextStyle(color: GameTheme.textMuted, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GameTheme.accentGold,
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  engine.travelTo(Zones.townSquare);
                },
                icon: const Icon(Icons.home),
                label: const Text('Travel to Town Square', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Gold balance
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF222C37),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: GameTheme.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Balance:',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Text(
                      '$gold',
                      style: const TextStyle(
                        color: GameTheme.accentGold,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.monetization_on, color: GameTheme.accentGold, size: 16),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Merchant inventory
          const Text(
            'BUY TOOLS & SUPPLIES',
            style: TextStyle(
              color: GameTheme.accentGold,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.builder(
              itemCount: buyables.length,
              itemBuilder: (context, index) {
                final item = buyables[index];

                return Card(
                  color: GameTheme.cardBg,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: GameTheme.border, width: 1),
                  ),
                  child: ListTile(
                    leading: Text(
                      item.icon,
                      style: const TextStyle(fontSize: 28),
                    ),
                    title: Text(
                      item.name,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      item.description,
                      style: const TextStyle(color: GameTheme.textMuted, fontSize: 11),
                    ),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gold >= item.value ? GameTheme.accentGold : const Color(0xFF2C353F),
                        foregroundColor: gold >= item.value ? Colors.black : GameTheme.textMuted,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onPressed: gold >= item.value ? () => engine.buyItem(item) : null,
                      child: Text(
                        'Buy ${item.value}g',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
