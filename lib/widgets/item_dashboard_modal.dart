import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../engine/game_engine.dart';
import '../models/item.dart';
import '../models/recipe.dart';
import '../models/zone.dart';
import '../models/skill.dart';
import '../models/shop.dart';
import '../models/crafted_item.dart';
import '../theme/game_theme.dart';
import 'coin_animation.dart';

enum ItemModalContext {
  inventory,
  shop,
  equipment,
}

class ItemDashboardModal extends StatefulWidget {
  final Item item;
  final int initialQuantity;
  final ItemModalContext contextType;
  final QualityTier? quality;
  final List<String> affixIds;

  const ItemDashboardModal({
    super.key,
    required this.item,
    required this.initialQuantity,
    required this.contextType,
    this.quality,
    this.affixIds = const [],
  });

  static void show(
    BuildContext context,
    GameEngine engine,
    Item item, {
    int quantity = 1,
    ItemModalContext contextType = ItemModalContext.inventory,
    QualityTier? quality,
    List<String> affixIds = const [],
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: GameTheme.cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return ItemDashboardModal(
          item: item,
          initialQuantity: quantity,
          contextType: contextType,
          quality: quality,
          affixIds: affixIds,
        );
      },
    );
  }

  @override
  State<ItemDashboardModal> createState() => _ItemDashboardModalState();
}

class _ItemDashboardModalState extends State<ItemDashboardModal> {
  int _selectedQuantity = 1;

  Item get item => widget.item;
  ItemModalContext get contextType => widget.contextType;
  int get initialQuantity => widget.initialQuantity;

  @override
  void initState() {
    super.initState();
    _selectedQuantity = widget.initialQuantity;
  }

  @override
  Widget build(BuildContext context) {
    // 3 tabs: Info/Actions, Sources, Crafting
    return DefaultTabController(
      length: 3,
      child: SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. DRAG HANDLE
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: GameTheme.border.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 2. HEADER
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
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
                            widget.quality != null && widget.quality != QualityTier.standard
                                ? "${widget.quality!.name.toUpperCase()} ${item.name}"
                                : item.name,
                            style: TextStyle(
                              color: GameTheme.getQualityColor(widget.quality),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getItemCategoryName(),
                            style: const TextStyle(
                              color: GameTheme.accentGold,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
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
              ),
              const SizedBox(height: 8),

              // 3. TAB BAR
              TabBar(
                indicatorColor: GameTheme.accentGold,
                labelColor: GameTheme.accentGold,
                unselectedLabelColor: GameTheme.textMuted,
                indicatorWeight: 3.0,
                labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: 'INFO & ACTIONS', icon: Icon(Icons.info_outline, size: 18)),
                  Tab(text: 'SOURCES', icon: Icon(Icons.explore_outlined, size: 18)),
                  Tab(text: 'CRAFTING', icon: Icon(Icons.handyman_outlined, size: 18)),
                ],
              ),

              // 4. TAB BAR VIEW
              Flexible(
                child: TabBarView(
                  children: [
                    _buildInfoActionsTab(context),
                    _buildSourcesTab(context),
                    _buildCraftingTab(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getItemCategoryName() {
    switch (item.type) {
      case ItemType.food:
        return 'Consumable Food';
      case ItemType.tool:
        return 'Gathering Tool';
      case ItemType.weapon:
        return 'Combat Weapon';
      case ItemType.armor:
        return 'Combat Armor';
      case ItemType.resource:
      default:
        return 'Raw Resource';
    }
  }

  Widget _buildInfoActionsTab(BuildContext context) {
    final engine = MapNotifierProvider.of(context);
    final liveQty = engine.inventory.getItemCountPrecise(item.id, widget.quality, widget.affixIds);

    final inTown = engine.currentZone.id == 'town_square';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Description
          Text(
            item.description,
            style: const TextStyle(color: GameTheme.textLight, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 20),

          // Active Affixes
          if (widget.affixIds.isNotEmpty) ...[
            const Text(
              'ACTIVE AFFIXES',
              style: TextStyle(
                color: GameTheme.accentGold,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            ...widget.affixIds.map((affId) {
              final affix = Affixes.findById(affId);
              if (affix == null) return const SizedBox();
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF222C37),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amberAccent.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amberAccent, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            affix.name,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            affix.description,
                            style: const TextStyle(color: GameTheme.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),
          ],

          // Stats Attributes
          if (item.isFood) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF222C37),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: GameTheme.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  if (item.healAmount > 0)
                    Text(
                      '❤️ Health: +${engine.getItemHealAmount(item, widget.quality, widget.affixIds)}',
                      style: const TextStyle(
                        color: GameTheme.healthRed,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (item.energyAmount > 0)
                    Text(
                      '⚡ Energy: +${engine.getItemEnergyAmount(item, widget.quality, widget.affixIds)}',
                      style: const TextStyle(
                        color: GameTheme.energyYellow,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          if (item.isTool && item.toolSkill != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF222C37),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: GameTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🔧 Skill Target: ${item.toolSkill!.name}',
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const Divider(color: GameTheme.border, height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '🏎️ Speed Bonus:',
                        style: TextStyle(color: Colors.greenAccent.shade100, fontSize: 13),
                      ),
                      Text(
                        '+${(engine.getItemSpeedBonus(item, widget.quality, widget.affixIds) * 100).toInt()}% speed',
                        style: const TextStyle(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '🎯 Success Bonus:',
                        style: TextStyle(color: Colors.blueAccent.shade100, fontSize: 13),
                      ),
                      Text(
                        '+${(engine.getItemSuccessBonus(item, widget.quality, widget.affixIds) * 100).toInt()}% success rate',
                        style: const TextStyle(color: Colors.blueAccent, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          if (item.isWeapon) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF222C37),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: GameTheme.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '⚔️ Attack Power:',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '+${engine.getItemAttackPower(item, widget.quality, widget.affixIds).toInt()}',
                    style: const TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          if (item.isArmor) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF222C37),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: GameTheme.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '🛡️ Defense Armor:',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '+${engine.getItemDefense(item, widget.quality, widget.affixIds).toInt()}',
                    style: const TextStyle(color: Colors.blueAccent, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ACTION BUTTONS SECTION
          const Text(
            'ACTIONS',
            style: TextStyle(
              color: GameTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),

          // Primary Actions: Use / Equip / Unequip
          if (contextType == ItemModalContext.equipment) ...[
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: GameTheme.healthRed.withOpacity(0.8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                if (item.isWeapon) {
                  engine.unequipWeapon();
                } else if (item.isArmor) {
                  engine.unequipArmor();
                } else if (item.isTool && item.toolSkill != null) {
                  engine.unequipTool(item.toolSkill!);
                }
                Navigator.pop(context);
              },
              icon: const Icon(Icons.remove_circle_outline),
              label: const Text('Unequip Item', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ] else if (contextType == ItemModalContext.shop) ...[
            _buildShopSection(engine, item),
          ] else ...[
            // Inventory Context Actions
            if (item.isFood || item.id == 'leather_backpack' || item.id == 'backpack_upgrade') ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                  item.isFood ? 'Eat / Consume' : 'Use Backpack',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ] else if (item.isTool && item.toolSkill != null) ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GameTheme.accentGold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: liveQty > 0
                    ? () {
                        engine.equipTool(item);
                        Navigator.pop(context);
                      }
                    : null,
                icon: const Icon(Icons.construction),
                label: const Text('Equip as Tool', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ] else if (item.isWeapon) ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GameTheme.accentGold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: liveQty > 0
                    ? () {
                        engine.equipWeapon(item);
                        Navigator.pop(context);
                      }
                    : null,
                icon: const Icon(Icons.gavel_rounded),
                label: const Text('Equip Weapon', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ] else if (item.isArmor) ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GameTheme.accentGold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: liveQty > 0
                    ? () {
                        engine.equipArmor(item);
                        Navigator.pop(context);
                      }
                    : null,
                icon: const Icon(Icons.shield_outlined),
                label: const Text('Equip Armor', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ] else ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    'No direct actions for this resource. Use it for crafting.',
                    style: TextStyle(color: GameTheme.textMuted, fontSize: 13, fontStyle: FontStyle.italic),
                  ),
                ),
              ),
            ],
          ],

          const SizedBox(height: 16),

          // Sell Options (Only in Town and if we have the item in inventory context)
          if (contextType == ItemModalContext.inventory && item.value > 0) ...[
            const Divider(color: GameTheme.border, height: 24),
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
                      onPressed: () {
                        engine.sellItem(item, 10);
                        if (liveQty <= 10) {
                          Navigator.pop(context);
                        }
                      },
                      child: Text(
                        'Sell 10 (${item.value * 10}g)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                ],
                if (inTown && liveQty > 0) ...[
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
                      onPressed: () {
                        engine.sellItem(item, liveQty);
                        Navigator.pop(context);
                      },
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
        ],
      ),
    );
  }

  // ================= TAB 2: SOURCES =================
  Widget _buildSourcesTab(BuildContext context) {
    final engine = MapNotifierProvider.of(context);
    final currentZoneId = engine.currentZone.id;

    // 1. Gather sources from Zone actions
    final gatheringSources = <Map<String, dynamic>>[];
    for (final zone in Zones.all) {
      for (final action in zone.actions) {
        for (final drop in action.lootTable) {
          if (drop.item.id == item.id) {
            gatheringSources.add({
              'zone': zone,
              'action': action,
              'chance': drop.chance,
            });
          }
        }
      }
    }

    // 2. Buyable check
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
    final isBuyable = buyables.any((b) => b.id == item.id);

    // 3. Recipes producing it
    final craftingSources = <Recipe>[];
    for (final recipe in engine.getAvailableRecipes()) {
      if (recipe.resultItemId == item.id) {
        craftingSources.add(recipe);
      }
    }

    final hasAnySource = gatheringSources.isNotEmpty || isBuyable || craftingSources.isNotEmpty;

    if (!hasAnySource) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'No resource activities or shops currently yield this item. It might be a starting tool or unlocked via special events.',
            textAlign: TextAlign.center,
            style: TextStyle(color: GameTheme.textMuted, fontSize: 13, height: 1.4),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Gathering
        if (gatheringSources.isNotEmpty) ...[
          const Text(
            'GATHERING SOURCES',
            style: TextStyle(
              color: GameTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
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
              tagText: isCurrent ? 'Already Here' : (!isUnlocked ? 'Locked' : null),
              tagColor: isCurrent ? Colors.green : Colors.red,
              onTravel: isUnlocked && !isCurrent
                  ? () {
                      engine.travelTo(zone);
                      Navigator.pop(context);
                    }
                  : null,
            );
          }),
          const SizedBox(height: 16),
        ],

        // Crafting / Cooking
        if (craftingSources.isNotEmpty) ...[
          const Text(
            'CRAFTING SOURCES',
            style: TextStyle(
              color: GameTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          ...craftingSources.map((recipe) {
            return _buildSourceCard(
              context: context,
              engine: engine,
              title: 'Craft: ${recipe.name}',
              subtitle: 'Requires ${recipe.requiredSkill.name} Lvl ${recipe.requiredLevel}',
              icon: '⚒️',
              tagText: 'Recipe',
              tagColor: GameTheme.craftingCyan,
              onTravel: null, // Just tells you it's craftable
            );
          }),
          const SizedBox(height: 16),
        ],

        // Shop Buyable
        if (isBuyable) ...[
          const Text(
            'SHOP VENDOR',
            style: TextStyle(
              color: GameTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          _buildSourceCard(
            context: context,
            engine: engine,
            title: 'Merchant Shop',
            subtitle: 'Sold by the Town Square Vendor for ${item.value} Gold.',
            icon: '🪙',
            tagText: currentZoneId == 'town_square' ? 'Shop Open' : 'Go to Town',
            tagColor: GameTheme.accentGold,
            onTravel: currentZoneId != 'town_square'
                ? () {
                    final townZone = Zones.findById('town_square');
                    engine.travelTo(townZone);
                    Navigator.pop(context);
                  }
                : null,
          ),
        ],
      ],
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
    VoidCallback? onTravel,
  }) {
    return Card(
      color: const Color(0xFF1E2833),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: GameTheme.border, width: 1),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFF2C3E50),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(icon, style: const TextStyle(fontSize: 20)),
        ),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: GameTheme.textMuted, fontSize: 11),
        ),
        trailing: tagText != null || onTravel != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (onTravel != null)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GameTheme.accentGold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      onPressed: onTravel,
                      child: const Text('Travel', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    )
                  else if (tagText != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: (tagColor ?? GameTheme.accentGold).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: (tagColor ?? GameTheme.accentGold).withOpacity(0.5)),
                      ),
                      child: Text(
                        tagText,
                        style: TextStyle(
                          color: tagColor ?? GameTheme.accentGold,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              )
            : null,
      ),
    );
  }

  // ================= TAB 3: CRAFTING =================
  Widget _buildCraftingTab(BuildContext context) {
    final engine = MapNotifierProvider.of(context);
    final allRecipes = engine.getAvailableRecipes();

    // Related recipes are either recipes producing this item, or recipes using it as an ingredient
    final relatedRecipes = allRecipes.where((recipe) {
      return recipe.resultItemId == item.id || recipe.inputs.containsKey(item.id);
    }).toList();

    if (relatedRecipes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'No crafting or cooking blueprints are associated with this item.',
            textAlign: TextAlign.center,
            style: TextStyle(color: GameTheme.textMuted, fontSize: 13, height: 1.4),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (!engine.currentZone.id.contains('town') &&
            relatedRecipes.any((r) => r.resultItemId == item.id)) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: GameTheme.craftingCyan.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: GameTheme.craftingCyan.withOpacity(0.3), width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: GameTheme.craftingCyan, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'You can craft recipes at the Town Square, or by building a Crafting Bench or Field Kitchen in your current location.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const Text(
          'BLUEPRINTS & INGREDIENTS',
          style: TextStyle(
            color: GameTheme.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        ...relatedRecipes.map((recipe) {
          final isTargetResult = recipe.resultItemId == item.id;
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
              Container(
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
                    fontSize: 10,
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

          return Card(
            color: const Color(0xFF1E2833),
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: isTargetResult ? GameTheme.accentGold.withOpacity(0.4) : GameTheme.border,
                width: 1,
              ),
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
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isTargetResult) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: GameTheme.accentGold.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Result',
                                style: TextStyle(color: GameTheme.accentGold, fontSize: 8, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
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
                    style: const TextStyle(color: GameTheme.textLight, fontSize: 11),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: reqItemsText,
                  ),
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
                        const Text(
                          'Active...',
                          style: TextStyle(color: GameTheme.accentGold, fontSize: 11, fontWeight: FontWeight.bold),
                        )
                      else if (isTargetResult)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GameTheme.craftingCyan,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          ),
                          onPressed: isCraftable
                              ? () {
                                  engine.startCrafting(recipe);
                                  Navigator.pop(context);
                                }
                              : null,
                          child: Text(
                            buttonLabel,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildShopSection(GameEngine engine, Item item) {
    final listings = engine.shopState.currentListings;
    ShopListing? listing;
    try {
      listing = listings.firstWhere((l) => l.item.id == item.id);
    } catch (_) {}

    if (listing == null) {
      return const Center(
        child: Text(
          'This item is not currently for sale.',
          style: TextStyle(color: GameTheme.textMuted, fontStyle: FontStyle.italic),
        ),
      );
    }

    final price = listing.effectiveBuyPrice;
    final totalCost = price * _selectedQuantity;
    final gold = engine.playerStats.gold;
    final hasEnoughGold = gold >= totalCost;

    // Max quantity calculations
    final maxByGold = price > 0 ? gold ~/ price : 99;
    final maxByStock = listing.stock ?? 99;

    int maxByInv = 99;
    if (listing.item.type == ItemType.tool) {
      maxByInv = engine.inventory.capacity - engine.inventory.slots.length;
    } else {
      final hasSlot = engine.inventory.slots.any((s) => s.item.id == item.id);
      if (!hasSlot && engine.inventory.slots.length >= engine.inventory.capacity) {
        maxByInv = 0;
      }
    }

    final maxAllowed = max(1, min(maxByGold, min(maxByStock, maxByInv)));
    final isSoldOut = listing.stock != null && listing.stock! <= 0;

    // Reset selected quantity if it exceeds maxAllowed
    if (_selectedQuantity > maxAllowed && maxAllowed > 0) {
      _selectedQuantity = maxAllowed;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Price displays
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF222C37),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: GameTheme.border),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Buy Price:', style: TextStyle(color: GameTheme.textMuted, fontSize: 13)),
                  Row(
                    children: [
                      if (listing.discountPercent > 0) ...[
                        Text(
                          '${listing.buyPrice}g',
                          style: const TextStyle(
                            color: GameTheme.textMuted,
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '-${listing.discountPercent}%',
                            style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        '$price Gold',
                        style: const TextStyle(color: GameTheme.accentGold, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Sell Value:', style: TextStyle(color: GameTheme.textMuted, fontSize: 13)),
                  Text(
                    '${listing.sellPrice} Gold',
                    style: const TextStyle(color: GameTheme.textMuted, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (listing.stock != null) ...[
                const Divider(color: GameTheme.border, height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Merchant Stock:', style: TextStyle(color: GameTheme.textMuted, fontSize: 13)),
                    Text(
                      isSoldOut ? 'SOLD OUT' : '${listing.stock} remaining',
                      style: TextStyle(
                        color: isSoldOut ? Colors.redAccent : (listing.stock! <= 2 ? Colors.orangeAccent : Colors.greenAccent),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (!isSoldOut) ...[
          // Stepper & Quick selects
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Quantity:', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: GameTheme.accentGold),
                    onPressed: _selectedQuantity > 1
                        ? () => setState(() => _selectedQuantity--)
                        : null,
                  ),
                  Container(
                    constraints: const BoxConstraints(minWidth: 40),
                    alignment: Alignment.center,
                    child: Text(
                      '$_selectedQuantity',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: GameTheme.accentGold),
                    onPressed: _selectedQuantity < maxAllowed
                        ? () => setState(() => _selectedQuantity++)
                        : null,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Quick selectors row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildQuickQtyButton(1, maxAllowed),
              _buildQuickQtyButton(5, maxAllowed),
              _buildQuickQtyButton(10, maxAllowed),
              _buildQuickQtyButton(maxAllowed, maxAllowed, label: 'MAX'),
            ],
          ),
          const SizedBox(height: 20),

          // Total cost & Action Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TOTAL COST', style: TextStyle(color: GameTheme.textMuted, fontSize: 10)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Text('🪙 ', style: TextStyle(fontSize: 14)),
                      Text(
                        '$totalCost g',
                        style: TextStyle(
                          color: hasEnoughGold ? GameTheme.accentGold : Colors.redAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasEnoughGold ? GameTheme.accentGold : Colors.grey.shade800,
                    foregroundColor: hasEnoughGold ? Colors.black : GameTheme.textMuted,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: hasEnoughGold && _selectedQuantity > 0
                      ? () {
                          // Find the global screen coordinate of the buy button to spawn coins
                          final RenderBox? box = context.findRenderObject() as RenderBox?;
                          Offset sourceOffset = Offset(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height * 0.7);
                          if (box != null) {
                            sourceOffset = box.localToGlobal(Offset.zero) + Offset(box.size.width / 2, box.size.height / 2);
                          }

                          // Target: Bottom Navigation bar, Inventory Tab (Roughly center-right, say 60% across screen width, and bottom of screen)
                          final targetOffset = Offset(
                            MediaQuery.of(context).size.width * 0.5,
                            MediaQuery.of(context).size.height - 50,
                          );

                          final overlayState = Overlay.of(context);
                          engine.buyShopItem(listing!, _selectedQuantity);
                          Navigator.pop(context);

                          // Wait a split second for modal pop then animate
                          Future.delayed(const Duration(milliseconds: 100), () {
                            // Fly coins FROM the button TO the inventory
                            CoinBurstOverlay.show(
                              overlayState: overlayState,
                              source: sourceOffset,
                              target: targetOffset,
                              isBuy: true,
                            );
                          });
                        }
                      : null,
                  icon: const Icon(Icons.shopping_cart_outlined),
                  label: Text(
                    hasEnoughGold ? 'Confirm Purchase' : 'Insufficient Gold',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          // Sold out overlay/button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade800,
              foregroundColor: GameTheme.textMuted,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: null,
            child: const Text('SOLD OUT', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ],
    );
  }

  Widget _buildQuickQtyButton(int qty, int maxAllowed, {String? label}) {
    final isSelected = _selectedQuantity == qty && qty > 0;
    final isEnabled = qty <= maxAllowed && qty > 0;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            backgroundColor: isSelected ? GameTheme.accentGold.withOpacity(0.15) : Colors.transparent,
            foregroundColor: isSelected ? GameTheme.accentGold : (isEnabled ? GameTheme.textLight : GameTheme.textMuted),
            side: BorderSide(
              color: isSelected ? GameTheme.accentGold : (isEnabled ? GameTheme.border : GameTheme.border.withOpacity(0.3)),
              width: isSelected ? 1.5 : 1.0,
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          onPressed: isEnabled ? () => setState(() => _selectedQuantity = qty) : null,
          child: Text(
            label ?? '+$qty',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

// Simple Helper to retrieve GameEngine inside the modal
class MapNotifierProvider {
  static GameEngine of(BuildContext context) {
    // Provider.of<GameEngine>(context, listen: false) doesn't listen to rebuilds.
    // However, since the modal isn't part of the main tree, we need to locate the state.
    // In Flutter, showModalBottomSheet context has access to the parent context providers.
    try {
      final engine = Provider.of<GameEngine>(context, listen: false);
      return engine;
    } catch (_) {
      // In case provider lookup fails due to context isolation
      throw FlutterError('GameEngine Provider not found in Modal context.');
    }
  }
}
