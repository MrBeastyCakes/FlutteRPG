import 'dart:math' show max, min;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../engine/game_engine.dart';
import '../models/item.dart';
import '../models/zone.dart';
import '../models/recipe.dart';
import '../models/skill.dart';
import '../models/shop.dart';
import '../models/inventory.dart';
import '../models/crafted_item.dart';
import '../theme/game_theme.dart';
import '../widgets/custom_progress_bar.dart';
import '../widgets/item_dashboard_modal.dart';
import '../widgets/bounce_tap.dart';
import '../widgets/coin_animation.dart';

class InventoryView extends StatefulWidget {
  const InventoryView({super.key});

  @override
  State<InventoryView> createState() => _InventoryViewState();
}

class _InventoryViewState extends State<InventoryView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ShopCategory? _selectedShopCategory;
  String _selectedQualityFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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

    final activeAction = engine.activeAction;

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
            Tab(text: 'Equipment', icon: Icon(Icons.shield_outlined)),
            Tab(text: 'Merchant Shop', icon: Icon(Icons.store)),
          ],
        ),
        if (activeAction != null) ...[
          _buildActiveActionHeader(context, engine, activeAction),
        ],
        // Tab contents
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildInventoryTab(context, engine, inventory, gold),
              _buildEquipmentTab(context, engine),
              _buildShopTab(context, engine, inventory, gold),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInventoryTab(
      BuildContext context, GameEngine engine, dynamic inventory, int gold) {
    final filteredSlots = inventory.slots.where((slot) {
      final q = slot.quality;
      if (_selectedQualityFilter == 'All') return true;
      if (_selectedQualityFilter == 'Standard+') {
        return q == null || q == QualityTier.standard || q == QualityTier.fine || q == QualityTier.masterwork;
      }
      if (_selectedQualityFilter == 'Fine+') {
        return q == QualityTier.fine || q == QualityTier.masterwork;
      }
      if (_selectedQualityFilter == 'Masterwork only') {
        return q == QualityTier.masterwork;
      }
      return true;
    }).toList();

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

          // Quality filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Standard+', 'Fine+', 'Masterwork only'].map((filter) {
                final isSelected = _selectedQualityFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(filter, style: const TextStyle(fontSize: 12)),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedQualityFilter = filter;
                        });
                      }
                    },
                    selectedColor: GameTheme.accentGold.withOpacity(0.2),
                    checkmarkColor: GameTheme.accentGold,
                    labelStyle: TextStyle(
                      color: isSelected ? GameTheme.accentGold : GameTheme.textMuted,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: const Color(0xFF1E2833),
                    side: BorderSide(
                      color: isSelected ? GameTheme.accentGold : GameTheme.border,
                      width: 1,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Grid View
          Expanded(
            child: GridView.builder(
              itemCount: inventory.capacity,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                if (index < filteredSlots.length) {
                  final slot = filteredSlots[index];
                  final item = slot.item;
                  final qty = slot.quantity;

                  return BounceTap(
                    onTap: () => ItemDashboardModal.show(
                      context,
                      engine,
                      item,
                      quantity: qty,
                      contextType: ItemModalContext.inventory,
                      quality: slot.quality,
                      affixIds: slot.affixIds,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2833),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: GameTheme.getQualityColor(slot.quality),
                          width: slot.quality != null && slot.quality != QualityTier.standard ? 2.0 : 1.5,
                        ),
                        boxShadow: [
                          if (slot.quality == QualityTier.fine)
                            BoxShadow(
                              color: Colors.blueAccent.withOpacity(0.2),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          if (slot.quality == QualityTier.masterwork)
                            BoxShadow(
                              color: GameTheme.accentGold.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
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
    final recipes = engine.getAvailableRecipes();
    final relatedRecipes = recipes.where((recipe) {
      return recipe.resultItemId == item.id || recipe.inputs.containsKey(item.id);
    }).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: GameTheme.cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return AnimatedBuilder(
          animation: engine,
          builder: (context, _) {
            final liveQty = engine.inventory.slots
                .where((slot) => slot.item.id == item.id)
                .fold<int>(0, (sum, slot) => sum + slot.quantity);

            return SafeArea(
          child: AnimatedPadding(
            padding: MediaQuery.of(context).viewInsets,
            duration: const Duration(milliseconds: 100),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: SingleChildScrollView(
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
                                    : (item.isTool
                                        ? 'Gathering Tool'
                                        : (item.isWeapon
                                            ? 'Combat Weapon'
                                            : (item.isArmor ? 'Combat Armor' : 'Raw Resource'))),
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
                    if (item.isTool && item.toolSkill != null) ...[
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
                    if (item.isWeapon) ...[
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
                            const Text(
                              '⚔️ Combat Weapon',
                              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '⚔️ Attack Power: +${item.attackPower}',
                              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (item.isArmor) ...[
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
                            const Text(
                              '🛡️ Combat Armor',
                              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '🛡️ Defense: +${item.defense}',
                              style: const TextStyle(color: Colors.blueAccent, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Action buttons
                    if (item.isFood ||
                        item.id == 'leather_backpack' ||
                        item.id == 'backpack_upgrade' ||
                        (item.isTool && item.toolSkill != null) ||
                        item.isWeapon ||
                        item.isArmor) ...[
                      Row(
                        children: [
                          if (item.isFood || item.id == 'leather_backpack' || item.id == 'backpack_upgrade')
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                onPressed: liveQty > 0
                                    ? () {
                                        engine.useItem(item);
                                        if (liveQty <= 1) {
                                          Navigator.pop(context);
                                        }
                                      }
                                    : null,
                                icon: Icon(item.isFood ? Icons.restaurant : Icons.backpack),
                                label: Text(
                                  item.isFood ? 'Eat Item' : 'Use Backpack',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          if (item.isTool && item.toolSkill != null)
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: GameTheme.accentGold,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                onPressed: liveQty > 0
                                    ? () {
                                        engine.equipTool(item);
                                        Navigator.pop(context);
                                      }
                                    : null,
                                icon: const Icon(Icons.shield_outlined),
                                label: const Text(
                                  'Equip Tool',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          if (item.isWeapon)
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: GameTheme.accentGold,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                onPressed: liveQty > 0
                                    ? () {
                                        engine.equipWeapon(item);
                                        Navigator.pop(context);
                                      }
                                    : null,
                                icon: const Icon(Icons.gavel_rounded),
                                label: const Text(
                                  'Equip Weapon',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          if (item.isArmor)
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: GameTheme.accentGold,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                onPressed: liveQty > 0
                                    ? () {
                                        engine.equipArmor(item);
                                        Navigator.pop(context);
                                      }
                                    : null,
                                icon: const Icon(Icons.shield_outlined),
                                label: const Text(
                                  'Equip Armor',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Sell Actions (Depends on Town location)
                    if (item.value > 0) ...[
                      const Text(
                        'SELL OPTIONS',
                        style: TextStyle(
                          color: GameTheme.accentGold,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: inTown ? GameTheme.accentGold : GameTheme.textMuted,
                                side: BorderSide(
                                  color: inTown ? GameTheme.accentGold : GameTheme.border,
                                  width: 1.2,
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: inTown && liveQty > 0
                                  ? () {
                                      engine.sellItem(item, 1);
                                      if (liveQty <= 1) {
                                        Navigator.pop(context);
                                      }
                                    }
                                  : null,
                              child: Text(
                                inTown ? 'Sell 1 (${item.value}g)' : 'Sell (Town Only)',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ),
                          if (inTown && liveQty >= 10) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: GameTheme.accentGold,
                                  side: const BorderSide(color: GameTheme.accentGold, width: 1.2),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: liveQty >= 10
                                    ? () {
                                        engine.sellItem(item, 10);
                                        if (liveQty <= 10) {
                                          Navigator.pop(context);
                                        }
                                      }
                                    : null,
                                child: Text(
                                  'Sell 10 (${item.value * 10}g)',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                          if (inTown) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: GameTheme.healthRed.withOpacity(0.2),
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: GameTheme.healthRed, width: 1.2),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: liveQty > 0
                                    ? () {
                                        engine.sellItem(item, liveQty);
                                        Navigator.pop(context);
                                      }
                                    : null,
                                child: Text(
                                  'Sell All (${item.value * liveQty}g)',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E2833),
                        foregroundColor: GameTheme.accentGold,
                        side: const BorderSide(color: GameTheme.border, width: 1),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => _showItemSourcesSheet(context, engine, item),
                      icon: const Icon(Icons.explore_outlined, color: GameTheme.accentGold, size: 18),
                      label: const Text(
                        'Where to Get?',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),

                    if (relatedRecipes.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Divider(color: GameTheme.border, height: 1),
                      const SizedBox(height: 16),
                      if (!inTown) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: GameTheme.craftingCyan.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: GameTheme.craftingCyan.withOpacity(0.3), width: 1),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: GameTheme.craftingCyan, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'CRAFTING LOCATIONS',
                                      style: TextStyle(
                                        color: GameTheme.craftingCyan,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'You can craft recipes at the Town Square, or by building a Crafting Bench (for crafting) or Field Kitchen (for cooking) in your current location.',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      const Text(
                        'CRAFTING BLUEPRINTS (Tap ingredient to locate)',
                        style: TextStyle(
                          color: GameTheme.accentGold,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...relatedRecipes.map((recipe) {
                        final skillState = engine.skills[recipe.requiredSkill];
                        final level = skillState?.level ?? 1;
                        final hasLevel = level >= recipe.requiredLevel;
                        final isGated = skillState?.isGated ?? false;

                        bool hasIngredients = true;
                        final reqItemsText = <Widget>[];

                        for (var entry in recipe.inputs.entries) {
                           final itemId = entry.key;
                          final qty = entry.value;
                          final currentQty = engine.inventory.slots
                              .where((slot) => slot.item.id == itemId)
                              .fold<int>(0, (sum, slot) => sum + slot.quantity);
                          final met = currentQty >= qty;
                          if (!met) hasIngredients = false;

                          final reqItem = Items.findById(itemId);
                          final icon = reqItem?.icon ?? '📦';
                          final name = reqItem?.name ?? itemId;

                          reqItemsText.add(
                            GestureDetector(
                              onTap: reqItem != null
                                  ? () => _showItemSourcesSheet(context, engine, reqItem)
                                  : null,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                decoration: BoxDecoration(
                                  color: met ? const Color(0xFF1B2E1E) : const Color(0xFF2E1B1B),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: met ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5),
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  '$icon $name: $currentQty/$qty',
                                  style: TextStyle(
                                    color: met ? Colors.greenAccent : Colors.redAccent,
                                    fontSize: 10.5,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }

                        final hasEnergy = engine.playerStats.currentEnergy >= recipe.energyCost;
                        final isActive = engine.activeAction?.recipe?.id == recipe.id;
                        final canCraftHere = engine.canCraftRecipe(recipe);
                        final isCraftable = canCraftHere && hasLevel && !isGated && hasIngredients && hasEnergy;
                        final buttonLabel = recipe.requiredSkill == SkillType.cooking ? 'Cook' : 'Craft';
                        final progressColor = recipe.requiredSkill == SkillType.cooking ? GameTheme.accentGold : GameTheme.craftingCyan;

                        return Card(
                          color: const Color(0xFF1E2833),
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: GameTheme.border, width: 1),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          recipe.icon,
                                          style: const TextStyle(fontSize: 24),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          recipe.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '${recipe.requiredSkill.name} Lvl ${recipe.requiredLevel}',
                                      style: const TextStyle(
                                        color: GameTheme.accentGold,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  recipe.description,
                                  style: const TextStyle(color: GameTheme.textLight, fontSize: 12),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: reqItemsText,
                                ),
                                if (!canCraftHere) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_off, color: GameTheme.healthRed, size: 12),
                                      const SizedBox(width: 4),
                                      Text(
                                        recipe.requiredSkill == SkillType.cooking || recipe.requiredSkill == SkillType.herbalism
                                            ? 'Requires Town Square or Field Kitchen here'
                                            : 'Requires Town Square or Crafting Bench here',
                                        style: const TextStyle(color: GameTheme.healthRed, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.flash_on, color: GameTheme.energyYellow, size: 14),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${recipe.energyCost} Energy',
                                          style: const TextStyle(color: GameTheme.textMuted, fontSize: 11),
                                        ),
                                        const SizedBox(width: 12),
                                        const Icon(Icons.timer, color: GameTheme.textMuted, size: 14),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${recipe.durationSeconds}s',
                                          style: const TextStyle(color: GameTheme.textMuted, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                    if (isActive)
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          SizedBox(
                                            width: 120,
                                            child: CustomProgressBar(
                                              progress: engine.activeAction!.progress,
                                              color: progressColor,
                                              height: 10,
                                              label: '${(engine.activeAction!.progress * 100).toInt()}%',
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          GestureDetector(
                                            onTap: () {
                                              engine.cancelAction();
                                            },
                                            child: const Text(
                                              'Cancel',
                                              style: TextStyle(
                                                color: Colors.redAccent,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    else
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isCraftable ? GameTheme.accentGold : const Color(0xFF2C353F),
                                          foregroundColor: isCraftable ? Colors.black : GameTheme.textMuted,
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                        ),
                                        onPressed: isCraftable
                                            ? () {
                                                engine.startCrafting(recipe);
                                              }
                                            : null,
                                        child: Text(
                                          buttonLabel,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
          },
        );
      },
    );
  }

  void _showItemSourcesSheet(BuildContext context, GameEngine engine, Item targetItem) {
    // 1. Gather sources from Zone actions
    final gatheringSources = <Map<String, dynamic>>[];
    for (final zone in Zones.all) {
      for (final action in zone.actions) {
        for (final drop in action.lootTable) {
          if (drop.item.id == targetItem.id) {
            gatheringSources.add({
              'zone': zone,
              'action': action,
              'chance': drop.chance,
            });
          }
        }
      }
    }

    // 2. Buyable from Merchant Shop
    final buyables = [
      Items.wildBerries,
      Items.rawPotato,
      Items.hotWater,
      Items.bakedPotato,
      Items.herbalTea,
      Items.stoneAxe,
      Items.ironAxe,
      Items.stonePickaxe,
      Items.ironPickaxe,
      Items.foragingGloves,
      Items.leatherBackpack,
    ];
    final isBuyable = buyables.any((b) => b.id == targetItem.id);

    // 3. Crafting/Cooking Recipes
    final craftingSources = <Recipe>[];
    for (final recipe in engine.getAvailableRecipes()) {
      if (recipe.resultItemId == targetItem.id) {
        craftingSources.add(recipe);
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: GameTheme.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final currentZoneId = engine.currentZone.id;
        final hasAnySource = gatheringSources.isNotEmpty || isBuyable || craftingSources.isNotEmpty;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Text(
                      targetItem.icon,
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Where to Get ${targetItem.name}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Travel to gather or buy this item',
                            style: TextStyle(color: GameTheme.textMuted, fontSize: 11),
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
                const SizedBox(height: 12),
                const Divider(color: GameTheme.border, height: 1),
                const SizedBox(height: 16),

                // Sources list
                if (!hasAnySource)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Text(
                      'No resource activities or shops currently yield this item. It might be a starting tool or unlocked via special events.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: GameTheme.textMuted, fontSize: 13),
                    ),
                  )
                else
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        // Gathering Sources
                        ...gatheringSources.map((source) {
                          final Zone zone = source['zone'];
                          final ZoneAction action = source['action'];
                          final double chance = source['chance'];

                          final isUnlocked = engine.unlockedZoneIds.contains(zone.id);
                          final isCurrent = zone.id == currentZoneId;
                          final subtitle = !isUnlocked
                              ? 'Locked • Hint: ${zone.unlockHint}'
                              : '${zone.name} • Chance: ${(chance * 100).toInt()}%';

                          return _buildSourceCard(
                            context: context,
                            engine: engine,
                            title: 'Gather: ${action.name}',
                            subtitle: subtitle,
                            icon: action.requiredSkill?.icon ?? '🌲',
                            tagText: isCurrent
                                ? 'Already Here'
                                : (!isUnlocked ? 'Locked' : null),
                            tagColor: isCurrent
                                ? Colors.green
                                : Colors.red,
                            buttonLabel: isCurrent ? null : 'Travel',
                            onPressed: isUnlocked && !isCurrent
                                ? () {
                                    // Travel to the zone
                                    engine.travelTo(zone);
                                    
                                    // Show nice confirmation SnackBar
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('🗺️ Traveled to ${zone.name}!'),
                                        duration: const Duration(seconds: 2),
                                        backgroundColor: GameTheme.accentGold,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );

                                    // Close sheets
                                    Navigator.pop(context); // Close sources sheet
                                    Navigator.pop(context); // Close item details sheet
                                  }
                                : null,
                          );
                        }),

                        // Shop Buyable Source
                        if (isBuyable)
                          _buildSourceCard(
                            context: context,
                            engine: engine,
                            title: 'Buy from Merchant Shop',
                            subtitle: 'Town Square • Price: ${targetItem.value}g',
                            icon: '🪙',
                            tagText: currentZoneId == 'town_square' ? 'Already Here' : null,
                            tagColor: Colors.green,
                            buttonLabel: currentZoneId == 'town_square' ? null : 'Travel',
                            onPressed: currentZoneId != 'town_square'
                                ? () {
                                    engine.travelTo(Zones.townSquare);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('🗺️ Traveled to Town Square!'),
                                        duration: Duration(seconds: 2),
                                        backgroundColor: GameTheme.accentGold,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                    Navigator.pop(context);
                                    Navigator.pop(context);
                                  }
                                : null,
                          ),

                        // Crafting Sources
                        ...craftingSources.map((recipe) {
                          return _buildSourceCard(
                            context: context,
                            engine: engine,
                            title: 'Craft: ${recipe.name}',
                            subtitle: '${recipe.requiredSkill.name} Lvl ${recipe.requiredLevel}',
                            icon: recipe.icon,
                            tagText: (recipe.requiredSkill == SkillType.cooking || recipe.requiredSkill == SkillType.herbalism)
                                ? 'Town or Kitchen'
                                : 'Town or Bench',
                            tagColor: GameTheme.accentGold,
                            buttonLabel: null,
                            onPressed: null,
                          );
                        }),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSourceCard({
    required BuildContext context,
    required GameEngine engine,
    required String title,
    required String subtitle,
    required String icon,
    String? tagText,
    Color? tagColor,
    String? buttonLabel,
    VoidCallback? onPressed,
  }) {
    return Card(
      color: const Color(0xFF1E2833),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: GameTheme.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: GameTheme.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (tagText != null)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tagColor?.withOpacity(0.12) ?? Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: tagColor?.withOpacity(0.5) ?? Colors.grey.withOpacity(0.5)),
                ),
                child: Text(
                  tagText,
                  style: TextStyle(
                    color: tagColor ?? Colors.grey,
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (buttonLabel != null)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: onPressed != null ? GameTheme.accentGold : const Color(0xFF2C353F),
                  foregroundColor: onPressed != null ? Colors.black : GameTheme.textMuted,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: onPressed,
                child: Text(
                  buttonLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 10.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopTab(BuildContext context, GameEngine engine, dynamic inventory, int gold) {
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

    final shopState = engine.shopState;
    final currentMerchant = shopState.currentMerchant;
    final listings = shopState.currentListings;
    final rep = engine.getMerchantReputation(currentMerchant.id);

    // Filter listings by category
    final filteredListings = listings.where((l) {
      if (_selectedShopCategory == null) return true;
      return l.category == _selectedShopCategory;
    }).toList();

    // Find the featured deal of the day
    ShopListing? featuredDeal;
    try {
      featuredDeal = listings.firstWhere((l) => l.isFeatured);
    } catch (_) {}

    final repairWidgets = <Widget>[];
    if (currentMerchant.id == 'maeve') {
      engine.equippedToolSlots.forEach((skill, slot) {
        final stamped = engine.ensureDurabilityStamped(slot);
        if (stamped.currentDurability < stamped.maxDurability) {
          repairWidgets.add(_buildRepairItemRow(context, engine, stamped, slotName: 'tool', skill: skill));
        }
      });
    } else if (currentMerchant.id == 'hilda') {
      if (engine.equippedWeaponSlot != null) {
        final stamped = engine.ensureDurabilityStamped(engine.equippedWeaponSlot!);
        if (stamped.currentDurability < stamped.maxDurability) {
          repairWidgets.add(_buildRepairItemRow(context, engine, stamped, slotName: 'weapon'));
        }
      }
      if (engine.equippedArmorSlot != null) {
        final stamped = engine.ensureDurabilityStamped(engine.equippedArmorSlot!);
        if (stamped.currentDurability < stamped.maxDurability) {
          repairWidgets.add(_buildRepairItemRow(context, engine, stamped, slotName: 'armor'));
        }
      }
    }

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. MERCHANT SELECTOR TABS
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: List.generate(shopState.activeMerchants.length, (index) {
                  final merchant = shopState.activeMerchants[index];
                  final isSelected = shopState.activeMerchantIndex == index;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: BounceTap(
                        onTap: () => engine.setActiveMerchantIndex(index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? GameTheme.cardBg : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? GameTheme.accentGold : GameTheme.border.withOpacity(0.5),
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(merchant.icon, style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      merchant.name,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : GameTheme.textMuted,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      merchant.title,
                                      style: TextStyle(
                                        color: isSelected ? GameTheme.accentGold.withOpacity(0.8) : GameTheme.textMuted,
                                        fontSize: 9,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // 2. MERCHANT DIALOG & PROFILE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Portrait
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: GameTheme.cardBg,
                      border: Border.all(color: GameTheme.accentGold, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(currentMerchant.icon, style: const TextStyle(fontSize: 32)),
                  ),
                  const SizedBox(width: 12),
                  // Chat Bubble
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: GameTheme.cardBg,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        border: Border.all(color: GameTheme.border, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${currentMerchant.name} (${currentMerchant.title})',
                            style: const TextStyle(color: GameTheme.accentGold, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            shopState.currentGreeting,
                            style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 3. DEAL OF THE DAY BANNER
            if (featuredDeal != null && (_selectedShopCategory == null || _selectedShopCategory == featuredDeal.category)) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: BounceTap(
                  onTap: () => ItemDashboardModal.show(
                    context,
                    engine,
                    featuredDeal!.item,
                    contextType: ItemModalContext.shop,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          GameTheme.accentGold.withOpacity(0.2),
                          const Color(0xFF1E2833),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: GameTheme.accentGold, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: GameTheme.accentGold.withOpacity(0.1),
                          blurRadius: 8,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Text('🌟', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'LIMITED DEAL -${featuredDeal.discountPercent}%',
                                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                featuredDeal.item.name,
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                featuredDeal.item.description,
                                style: const TextStyle(color: GameTheme.textMuted, fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${featuredDeal.buyPrice}g',
                              style: const TextStyle(
                                color: GameTheme.textMuted,
                                fontSize: 11,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            Text(
                              '${featuredDeal.getBuyPrice(rep.tier.discountPercent)}g',
                              style: const TextStyle(
                                color: GameTheme.accentGold,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            if (repairWidgets.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: GameTheme.glassCardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Row(
                        children: [
                          Text('🛠️', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 8),
                          Text(
                            'EQUIPMENT MAINTENANCE',
                            style: TextStyle(
                              color: GameTheme.accentGold,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...repairWidgets,
                    ],
                  ),
                ),
              ),
            ],

            // 4. CATEGORY SELECTOR
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildCategoryPill(null, 'All'),
                    _buildCategoryPill(ShopCategory.supplies, 'Supplies'),
                    _buildCategoryPill(ShopCategory.tools, 'Tools'),
                    _buildCategoryPill(ShopCategory.weapons, 'Weapons'),
                    _buildCategoryPill(ShopCategory.armor, 'Armor'),
                    _buildCategoryPill(ShopCategory.provisions, 'Provisions'),
                  ],
                ),
              ),
            ),

            // 5. GRID OF ITEMS
            Expanded(
              child: filteredListings.isEmpty
                  ? const Center(
                      child: Text(
                        'No items in this category.',
                        style: TextStyle(color: GameTheme.textMuted, fontStyle: FontStyle.italic),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.35,
                      ),
                      itemCount: filteredListings.length,
                      itemBuilder: (context, index) {
                        final listing = filteredListings[index];
                        final item = listing.item;
                        final price = listing.getBuyPrice(rep.tier.discountPercent);
                        final isSoldOut = listing.stock != null && listing.stock! <= 0;

                        return BounceTap(
                          onTap: () => ItemDashboardModal.show(
                            context,
                            engine,
                            item,
                            contextType: ItemModalContext.shop,
                          ),
                          child: Container(
                            decoration: GameTheme.glassCardDecoration(),
                            padding: const EdgeInsets.all(8),
                            child: Stack(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Text(item.icon, style: const TextStyle(fontSize: 28)),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  item.name,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  listing.stock == null ? 'Stock: ∞' : (isSoldOut ? 'SOLD OUT' : 'Stock: ${listing.stock}'),
                                                  style: TextStyle(
                                                    color: isSoldOut
                                                        ? Colors.redAccent
                                                        : (listing.stock != null && listing.stock! <= 2
                                                            ? Colors.orangeAccent
                                                            : GameTheme.textMuted),
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Divider(color: GameTheme.border, height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            if (listing.discountPercent > 0) ...[
                                              Text(
                                                '${listing.buyPrice}g',
                                                style: const TextStyle(
                                                  color: GameTheme.textMuted,
                                                  fontSize: 10,
                                                  decoration: TextDecoration.lineThrough,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                            ],
                                            Text(
                                              '$price g',
                                              style: const TextStyle(
                                                color: GameTheme.accentGold,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Text('🪙', style: TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                  ],
                                ),
                                if (listing.discountPercent > 0)
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '-${listing.discountPercent}%',
                                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),

        // 6. SELL SATSCHEL BUTTON
        Positioned(
          left: 16,
          right: 16,
          bottom: 12,
          child: BounceTap(
            onTap: () => _showSellSatchelBottomSheet(context, engine),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: GameTheme.accentGold,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sell_outlined, color: Colors.black),
                  SizedBox(width: 8),
                  Text(
                    '💰 Open Sell Satchel',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRepairItemRow(
    BuildContext context,
    GameEngine engine,
    InventorySlot slot, {
    required String slotName,
    SkillType? skill,
  }) {
    final cost = engine.calculateRepairGoldCost(slot);
    final hasEnoughGold = engine.playerStats.gold >= cost;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2833).withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GameTheme.border.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(slot.item.icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${slot.quality != null && slot.quality != QualityTier.standard ? "${slot.quality!.name.toUpperCase()} " : ""}${slot.item.name}',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                // Durability bar
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: slot.maxDurability > 0 ? slot.currentDurability / slot.maxDurability : 0.0,
                          backgroundColor: Colors.white.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            slot.currentDurability == 0
                                ? Colors.redAccent
                                : slot.currentDurability / slot.maxDurability < 0.25
                                    ? Colors.orangeAccent
                                    : GameTheme.accentGold,
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${slot.currentDurability}/${slot.maxDurability}',
                      style: const TextStyle(color: GameTheme.textMuted, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Cost
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${cost}g',
                style: TextStyle(
                  color: hasEnoughGold ? GameTheme.accentGold : Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasEnoughGold ? GameTheme.accentGold : Colors.white10,
                  foregroundColor: hasEnoughGold ? Colors.black : Colors.white24,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: hasEnoughGold
                    ? () => engine.repairWithGold(slot, slot: slotName, skill: skill)
                    : null,
                child: const Text('Repair', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPill(ShopCategory? category, String label) {
    final isSelected = _selectedShopCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: BounceTap(
        onTap: () => setState(() => _selectedShopCategory = category),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? GameTheme.accentGold : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? GameTheme.accentGold : GameTheme.border,
              width: 1.0,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : GameTheme.textLight,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _showSellSatchelBottomSheet(BuildContext context, GameEngine engine) {
    showModalBottomSheet(
      context: context,
      backgroundColor: GameTheme.cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final localEngine = Provider.of<GameEngine>(context);
            final slots = localEngine.inventory.slots;

            return SafeArea(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '💰 SELL SATCHEL (0.5x Value)',
                          style: TextStyle(color: GameTheme.accentGold, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: GameTheme.textMuted),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(color: GameTheme.border, height: 16),

                    Expanded(
                      child: slots.isEmpty
                          ? const Center(
                              child: Text(
                                'Your satchel is empty!',
                                style: TextStyle(color: GameTheme.textMuted, fontStyle: FontStyle.italic),
                              ),
                            )
                          : ListView.builder(
                              itemCount: slots.length,
                              itemBuilder: (context, index) {
                                final slot = slots[index];
                                final item = slot.item;
                                final qty = slot.quantity;
                                final sellPrice = max(1, (item.value * 0.5).toInt());

                                bool isEquipped = false;
                                if (item.isTool && item.toolSkill != null) {
                                  isEquipped = localEngine.equippedTools[item.toolSkill!]?.id == item.id;
                                } else if (item.isWeapon) {
                                  isEquipped = localEngine.equippedWeapon?.id == item.id;
                                } else if (item.isArmor) {
                                  isEquipped = localEngine.equippedArmor?.id == item.id;
                                }

                                return Card(
                                  color: const Color(0xFF1E2833),
                                  margin: const EdgeInsets.only(bottom: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: const BorderSide(color: GameTheme.border, width: 1),
                                  ),
                                  child: ListTile(
                                    leading: Text(item.icon, style: const TextStyle(fontSize: 24)),
                                    title: Text(
                                      item.name,
                                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                      isEquipped ? 'EQUIPPED • Cannot Sell' : 'Qty: $qty • Value: $sellPrice g',
                                      style: TextStyle(
                                        color: isEquipped ? Colors.redAccent : GameTheme.textMuted,
                                        fontSize: 11,
                                        fontWeight: isEquipped ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                    trailing: isEquipped
                                        ? null
                                        : Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              OutlinedButton(
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: GameTheme.accentGold,
                                                  side: const BorderSide(color: GameTheme.accentGold, width: 1),
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  minimumSize: Size.zero,
                                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                ),
                                                onPressed: () {
                                                  final RenderBox? box = context.findRenderObject() as RenderBox?;
                                                  Offset sourceOffset = Offset(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height * 0.5);
                                                  if (box != null) {
                                                    sourceOffset = box.localToGlobal(Offset.zero) + Offset(box.size.width / 2, box.size.height / 2);
                                                  }

                                                  final targetOffset = Offset(MediaQuery.of(context).size.width * 0.8, 50);
                                                  final overlayState = Overlay.of(context);

                                                  localEngine.sellItem(item, 1);

                                                  CoinBurstOverlay.show(
                                                    overlayState: overlayState,
                                                    source: sourceOffset,
                                                    target: targetOffset,
                                                    isBuy: false,
                                                  );
                                                },
                                                child: const Text('Sell 1', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                              ),
                                              const SizedBox(width: 6),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: GameTheme.healthRed.withOpacity(0.15),
                                                  foregroundColor: Colors.white,
                                                  side: const BorderSide(color: GameTheme.healthRed, width: 1),
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  minimumSize: Size.zero,
                                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                ),
                                                onPressed: () {
                                                  final RenderBox? box = context.findRenderObject() as RenderBox?;
                                                  Offset sourceOffset = Offset(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height * 0.5);
                                                  if (box != null) {
                                                    sourceOffset = box.localToGlobal(Offset.zero) + Offset(box.size.width / 2, box.size.height / 2);
                                                  }
                                                  final targetOffset = Offset(MediaQuery.of(context).size.width * 0.8, 50);
                                                  final overlayState = Overlay.of(context);

                                                  localEngine.sellItem(item, qty);

                                                  CoinBurstOverlay.show(
                                                    overlayState: overlayState,
                                                    source: sourceOffset,
                                                    target: targetOffset,
                                                    isBuy: false,
                                                  );
                                                },
                                                child: const Text('All', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                              ),
                                            ],
                                          ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEquipmentTab(BuildContext context, GameEngine engine) {
    final equippedTools = engine.equippedTools;
    final maxSlots = engine.maxEquipmentSlots;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. RPG Character Sheet Card
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: GameTheme.glassCardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '🛡️ CHARACTER SHEET',
                      style: TextStyle(
                        color: GameTheme.accentGold,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'Slots: ${equippedTools.length}/$maxSlots',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: List.generate(3, (index) {
                            final isUnlocked = index < maxSlots;
                            final isActive = index < equippedTools.length;
                            return Container(
                              margin: const EdgeInsets.only(left: 4),
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isActive
                                    ? GameTheme.accentGold
                                    : (isUnlocked ? Colors.transparent : Colors.black.withOpacity(0.5)),
                                border: Border.all(
                                  color: isUnlocked
                                      ? GameTheme.accentGold
                                      : GameTheme.textMuted.withOpacity(0.4),
                                  width: 1.5,
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Your active equipment gathering speed & success rate multipliers.',
                  style: TextStyle(color: GameTheme.textMuted, fontSize: 11),
                ),
                const SizedBox(height: 12),
                const Divider(color: GameTheme.border, height: 1),
                const SizedBox(height: 12),
                
                // Stat Rows
                _buildStatSheetRow(context, engine, SkillType.woodcutting, engine.equippedToolSlots[SkillType.woodcutting]),
                const SizedBox(height: 10),
                _buildStatSheetRow(context, engine, SkillType.mining, engine.equippedToolSlots[SkillType.mining]),
                const SizedBox(height: 10),
                _buildStatSheetRow(context, engine, SkillType.herbalism, engine.equippedToolSlots[SkillType.herbalism]),
                const SizedBox(height: 12),
                const Divider(color: GameTheme.border, height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text('⚔️', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Attack Power',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              engine.equippedWeaponSlot != null 
                                  ? (engine.equippedWeaponSlot!.quality != null && engine.equippedWeaponSlot!.quality != QualityTier.standard
                                      ? "${engine.equippedWeaponSlot!.quality!.name.toUpperCase()} ${engine.equippedWeapon!.name}"
                                      : engine.equippedWeapon!.name)
                                  : 'Unarmed',
                              style: const TextStyle(color: GameTheme.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      '${engine.getPlayerAttack()}',
                      style: const TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text('🛡️', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Defense',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              engine.equippedArmorSlot != null 
                                  ? (engine.equippedArmorSlot!.quality != null && engine.equippedArmorSlot!.quality != QualityTier.standard
                                      ? "${engine.equippedArmorSlot!.quality!.name.toUpperCase()} ${engine.equippedArmor!.name}"
                                      : engine.equippedArmor!.name)
                                  : 'No Armor',
                              style: const TextStyle(color: GameTheme.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      '${engine.getPlayerDefense()}',
                      style: const TextStyle(color: Colors.blueAccent, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2. Slots section header
          const Text(
            'ACTIVE TOOL SLOTS',
            style: TextStyle(
              color: GameTheme.accentGold,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),

          // 3. Woodcutting Slot Card
          _buildToolSlotCard(context, engine, SkillType.woodcutting),
          const SizedBox(height: 12),

          // 4. Mining Slot Card
          _buildToolSlotCard(context, engine, SkillType.mining),
          const SizedBox(height: 12),

          // 5. Herbalism Slot Card
          _buildToolSlotCard(context, engine, SkillType.herbalism),
          const SizedBox(height: 16),

          const Divider(color: GameTheme.border, height: 24),
          const Text(
            'COMBAT EQUIPMENT',
            style: TextStyle(
              color: GameTheme.accentGold,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),

          // Weapon Slot Card
          _buildWeaponSlotCard(context, engine),
          const SizedBox(height: 12),

          // Armor Slot Card
          _buildArmorSlotCard(context, engine),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStatSheetRow(BuildContext context, GameEngine engine, SkillType skill, InventorySlot? toolSlot) {
    final skillColor = GameTheme.getSkillColor(skill);
    final speedBonus = (engine.getSkillSpeedBonus(skill) * 100).toInt();
    final successBonus = (engine.getSkillSuccessBonus(skill) * 100).toInt();

    final String displayName = toolSlot != null 
        ? (toolSlot.quality != null && toolSlot.quality != QualityTier.standard
            ? "${toolSlot.quality!.name.toUpperCase()} ${toolSlot.item.name}"
            : toolSlot.item.name)
        : 'No tool equipped';

    return Row(
      children: [
        Text(skill.icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                skill.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                displayName,
                style: TextStyle(
                  color: toolSlot != null ? skillColor : GameTheme.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '🏎️ Speed: +$speedBonus%',
              style: const TextStyle(
                color: Colors.greenAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '🎯 Success: +$successBonus%',
              style: const TextStyle(
                color: Colors.blueAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToolSlotCard(BuildContext context, GameEngine engine, SkillType skill) {
    final toolSlot = engine.equippedToolSlots[skill];

    if (toolSlot == null) {
      return _buildEmptySlotCard(context, skill);
    }

    final tool = toolSlot.item;
    final quality = toolSlot.quality;
    final affixIds = toolSlot.affixIds;

    final String displayName = quality != null && quality != QualityTier.standard
        ? "${quality.name.toUpperCase()} ${tool.name}"
        : tool.name;

    final double displaySpeed = engine.getItemSpeedBonus(tool, quality, affixIds);
    final double displaySuccess = engine.getItemSuccessBonus(tool, quality, affixIds);

    return BounceTap(
      onTap: () => ItemDashboardModal.show(
        context,
        engine,
        tool,
        contextType: ItemModalContext.equipment,
        quality: quality,
        affixIds: affixIds,
      ),
      child: Card(
        color: const Color(0xFF1E2833),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: GameTheme.getQualityColor(quality),
            width: quality != null && quality != QualityTier.standard ? 2.0 : 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
          children: [
            Text(
              tool.icon,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${skill.name} Tool',
                    style: TextStyle(color: GameTheme.getSkillColor(skill), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  if (affixIds.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      affixIds.map((a) => Affixes.findById(a)?.name ?? a).join(', '),
                      style: const TextStyle(color: Colors.amberAccent, fontSize: 11, fontStyle: FontStyle.italic),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '🏎️ +${(displaySpeed * 100).toInt()}% Spd',
                        style: const TextStyle(color: Colors.greenAccent, fontSize: 11),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '🎯 +${(displaySuccess * 100).toInt()}% Suc',
                        style: const TextStyle(color: Colors.blueAccent, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: GameTheme.healthRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: () {
                engine.unequipTool(skill);
              },
              child: const Text(
                'Unequip',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildEmptySlotCard(BuildContext context, SkillType skill) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF10171E).withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GameTheme.border.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          // Greyed out emoji
          Opacity(
            opacity: 0.4,
            child: Text(
              skill.icon,
              style: const TextStyle(fontSize: 32),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No ${skill.name} Tool Equipped',
                  style: const TextStyle(
                    color: GameTheme.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Equip a tool for ${skill.name} from the Inventory tab.',
                  style: const TextStyle(color: GameTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeaponSlotCard(BuildContext context, GameEngine engine) {
    final weaponSlot = engine.equippedWeaponSlot;

    if (weaponSlot == null) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color(0xFF10171E).withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: GameTheme.border.withOpacity(0.3), width: 1.5),
        ),
        child: Row(
          children: [
            Opacity(
              opacity: 0.4,
              child: const Text(
                '⚔️',
                style: TextStyle(fontSize: 32),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'No Weapon Equipped',
                    style: TextStyle(
                      color: GameTheme.textMuted,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Equip a weapon from the Inventory tab.',
                    style: TextStyle(color: GameTheme.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final weapon = weaponSlot.item;
    final quality = weaponSlot.quality;
    final affixIds = weaponSlot.affixIds;

    final String displayName = quality != null && quality != QualityTier.standard
        ? "${quality.name.toUpperCase()} ${weapon.name}"
        : weapon.name;

    final double displayAttack = engine.getItemAttackPower(weapon, quality, affixIds);

    return BounceTap(
      onTap: () => ItemDashboardModal.show(
        context,
        engine,
        weapon,
        contextType: ItemModalContext.equipment,
        quality: quality,
        affixIds: affixIds,
      ),
      child: Card(
        color: const Color(0xFF1E2833),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: GameTheme.getQualityColor(quality),
            width: quality != null && quality != QualityTier.standard ? 2.0 : 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Text(
                weapon.icon,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Weapon',
                      style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    if (affixIds.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        affixIds.map((a) => Affixes.findById(a)?.name ?? a).join(', '),
                        style: const TextStyle(color: Colors.amberAccent, fontSize: 11, fontStyle: FontStyle.italic),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      '⚔️ +${displayAttack.toInt()} Attack Power',
                      style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GameTheme.healthRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: () {
                  engine.unequipWeapon();
                },
                child: const Text(
                  'Unequip',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArmorSlotCard(BuildContext context, GameEngine engine) {
    final armorSlot = engine.equippedArmorSlot;

    if (armorSlot == null) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color(0xFF10171E).withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: GameTheme.border.withOpacity(0.3), width: 1.5),
        ),
        child: Row(
          children: [
            Opacity(
              opacity: 0.4,
              child: const Text(
                '🛡️',
                style: TextStyle(fontSize: 32),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'No Armor Equipped',
                    style: TextStyle(
                      color: GameTheme.textMuted,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Equip armor from the Inventory tab.',
                    style: TextStyle(color: GameTheme.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final armor = armorSlot.item;
    final quality = armorSlot.quality;
    final affixIds = armorSlot.affixIds;

    final String displayName = quality != null && quality != QualityTier.standard
        ? "${quality.name.toUpperCase()} ${armor.name}"
        : armor.name;

    final double displayDefense = engine.getItemDefense(armor, quality, affixIds);

    return BounceTap(
      onTap: () => ItemDashboardModal.show(
        context,
        engine,
        armor,
        contextType: ItemModalContext.equipment,
        quality: quality,
        affixIds: affixIds,
      ),
      child: Card(
        color: const Color(0xFF1E2833),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: GameTheme.getQualityColor(quality),
            width: quality != null && quality != QualityTier.standard ? 2.0 : 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Text(
                armor.icon,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Armor',
                      style: TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    if (affixIds.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        affixIds.map((a) => Affixes.findById(a)?.name ?? a).join(', '),
                        style: const TextStyle(color: Colors.amberAccent, fontSize: 11, fontStyle: FontStyle.italic),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      '🛡️ +${displayDefense.toInt()} Defense',
                      style: const TextStyle(color: Colors.blueAccent, fontSize: 11),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GameTheme.healthRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: () {
                  engine.unequipArmor();
                },
                child: const Text(
                  'Unequip',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveActionHeader(BuildContext context, GameEngine engine, ActiveActionState activeAction) {
    final String name;
    final String icon;
    final Color progressColor;

    if (activeAction.recipe != null) {
      final recipe = activeAction.recipe!;
      name = recipe.requiredSkill == SkillType.cooking ? 'Cooking: ${recipe.name}' : 'Crafting: ${recipe.name}';
      icon = recipe.icon;
      progressColor = GameTheme.getSkillColor(recipe.requiredSkill);
    } else if (activeAction.structure != null) {
      final structure = activeAction.structure!;
      name = 'Building: ${structure.name}';
      icon = structure.icon;
      progressColor = GameTheme.craftingCyan;
    } else if (activeAction.action != null) {
      final action = activeAction.action!;
      name = action.name;
      icon = action.requiredSkill?.icon ?? '⚡';
      progressColor = action.requiredSkill != null ? GameTheme.getSkillColor(action.requiredSkill!) : GameTheme.accentGold;
    } else {
      return const SizedBox.shrink();
    }

    final progress = activeAction.progress;
    final percent = (progress * 100).toInt();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2833),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: progressColor.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '$percent%',
                      style: TextStyle(
                        color: progressColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                CustomProgressBar(
                  progress: progress,
                  color: progressColor,
                  height: 10,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.cancel, color: Colors.redAccent, size: 20),
            onPressed: () {
              engine.cancelAction();
            },
          ),
        ],
      ),
    );
  }
}
