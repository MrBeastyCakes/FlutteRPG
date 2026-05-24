import 'item.dart';
import 'zone.dart';

class Beast {
  final String id;
  final String name;
  final String icon;
  final int maxHealth;
  final int attackPower;
  final int defense;
  final int xpReward;
  final List<LootDrop> lootTable;

  const Beast({
    required this.id,
    required this.name,
    required this.icon,
    required this.maxHealth,
    required this.attackPower,
    required this.defense,
    required this.xpReward,
    required this.lootTable,
  });
}

class Beasts {
  static const Beast forestBoar = Beast(
    id: 'forest_boar',
    name: 'Forest Boar',
    icon: '🐗',
    maxHealth: 35,
    attackPower: 5,
    defense: 1,
    xpReward: 30,
    lootTable: [
      LootDrop(item: Items.boarMeat, chance: 0.85, minQuantity: 1, maxQuantity: 2),
      LootDrop(item: Items.boarTusk, chance: 0.40, minQuantity: 1, maxQuantity: 1),
    ],
  );

  static const Beast caveSpider = Beast(
    id: 'cave_spider',
    name: 'Cave Spider',
    icon: '🕷️',
    maxHealth: 55,
    attackPower: 9,
    defense: 2,
    xpReward: 45,
    lootTable: [
      LootDrop(item: Items.spiderSilk, chance: 0.80, minQuantity: 1, maxQuantity: 2),
      LootDrop(item: Items.spiderFang, chance: 0.35, minQuantity: 1, maxQuantity: 1),
    ],
  );

  static const Beast shadowWolf = Beast(
    id: 'shadow_wolf',
    name: 'Shadow Wolf',
    icon: '🐺',
    maxHealth: 85,
    attackPower: 14,
    defense: 3,
    xpReward: 65,
    lootTable: [
      LootDrop(item: Items.wolfPelt, chance: 0.75, minQuantity: 1, maxQuantity: 1),
      LootDrop(item: Items.boarMeat, chance: 0.50, minQuantity: 1, maxQuantity: 2), // Wolf drops meat too
    ],
  );

  static const Beast cavernTroll = Beast(
    id: 'cavern_troll',
    name: 'Cavern Troll',
    icon: '👹',
    maxHealth: 160,
    attackPower: 22,
    defense: 6,
    xpReward: 110,
    lootTable: [
      LootDrop(item: Items.trollClaw, chance: 0.70, minQuantity: 1, maxQuantity: 1),
      LootDrop(item: Items.ironOre, chance: 0.40, minQuantity: 1, maxQuantity: 2),
    ],
  );

  static const List<Beast> all = [
    forestBoar,
    caveSpider,
    shadowWolf,
    cavernTroll,
  ];

  static Beast? findById(String id) {
    try {
      return all.firstWhere((beast) => beast.id == id);
    } catch (_) {
      return null;
    }
  }
}
