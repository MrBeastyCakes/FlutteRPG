import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../engine/game_engine.dart';
import '../models/item.dart';
import '../models/zone.dart';
import '../models/recipe.dart';
import '../models/skill.dart';
import '../theme/game_theme.dart';
import '../widgets/custom_progress_bar.dart';

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
    // Items for sale
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
                _buildStatSheetRow(context, engine, SkillType.woodcutting, equippedTools[SkillType.woodcutting]),
                const SizedBox(height: 10),
                _buildStatSheetRow(context, engine, SkillType.mining, equippedTools[SkillType.mining]),
                const SizedBox(height: 10),
                _buildStatSheetRow(context, engine, SkillType.herbalism, equippedTools[SkillType.herbalism]),
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
                              engine.equippedWeapon != null ? engine.equippedWeapon!.name : 'Unarmed',
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
                              engine.equippedArmor != null ? engine.equippedArmor!.name : 'No Armor',
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

  Widget _buildStatSheetRow(BuildContext context, GameEngine engine, SkillType skill, Item? tool) {
    final skillColor = GameTheme.getSkillColor(skill);
    final speedBonus = (engine.getSkillSpeedBonus(skill) * 100).toInt();
    final successBonus = (engine.getSkillSuccessBonus(skill) * 100).toInt();

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
                tool != null ? tool.name : 'No tool equipped',
                style: TextStyle(
                  color: tool != null ? skillColor : GameTheme.textMuted,
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
    final tool = engine.equippedTools[skill];

    if (tool == null) {
      return _buildEmptySlotCard(context, skill);
    }

    return Card(
      color: const Color(0xFF1E2833),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: GameTheme.getSkillColor(skill).withOpacity(0.5), width: 1.5),
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
                    tool.name,
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
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '🏎️ +${(tool.speedBonus * 100).toInt()}% Spd',
                        style: const TextStyle(color: Colors.greenAccent, fontSize: 11),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '🎯 +${(tool.successBonus * 100).toInt()}% Suc',
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
    final weapon = engine.equippedWeapon;

    if (weapon == null) {
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

    return Card(
      color: const Color(0xFF1E2833),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: GameTheme.getSkillColor(SkillType.combat).withOpacity(0.5), width: 1.5),
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
                    weapon.name,
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
                  const SizedBox(height: 4),
                  Text(
                    '⚔️ +${weapon.attackPower} Attack Power',
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
    );
  }

  Widget _buildArmorSlotCard(BuildContext context, GameEngine engine) {
    final armor = engine.equippedArmor;

    if (armor == null) {
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

    return Card(
      color: const Color(0xFF1E2833),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: GameTheme.getSkillColor(SkillType.combat).withOpacity(0.5), width: 1.5),
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
                    armor.name,
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
                  const SizedBox(height: 4),
                  Text(
                    '🛡️ +${armor.defense} Defense',
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
