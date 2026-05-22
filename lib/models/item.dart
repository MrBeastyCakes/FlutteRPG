import 'skill.dart';

enum ItemType {
  resource,
  food,
  tool,
}

class Item {
  final String id;
  final String name;
  final String description;
  final String icon; // Emoji icon
  final ItemType type;
  final int value; // Gold value

  // Food specific fields
  final int healAmount;
  final int energyAmount;

  // Tool specific fields
  final SkillType? toolSkill;
  final double speedBonus; // e.g. 0.15 = 15% speed increase (decreased action duration)
  final double successBonus; // e.g. 0.05 = +5% chance of success

  const Item({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.type,
    required this.value,
    this.healAmount = 0,
    this.energyAmount = 0,
    this.toolSkill,
    this.speedBonus = 0.0,
    this.successBonus = 0.0,
  });

  bool get isFood => type == ItemType.food;
  bool get isTool => type == ItemType.tool;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Item && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// A registry of all items in the game
class Items {
  // Resources
  static const Item oakLog = Item(
    id: 'oak_log',
    name: 'Oak Log',
    description: 'A sturdy log chopped from an oak tree.',
    icon: '🪵',
    type: ItemType.resource,
    value: 5,
  );

  static const Item willowLog = Item(
    id: 'willow_log',
    name: 'Willow Log',
    description: 'A supple log gathered from a willow tree.',
    icon: '🪵',
    type: ItemType.resource,
    value: 12,
  );

  static const Item copperOre = Item(
    id: 'copper_ore',
    name: 'Copper Ore',
    description: 'A heavy chunk of copper-rich stone.',
    icon: '🪨',
    type: ItemType.resource,
    value: 4,
  );

  static const Item tinOre = Item(
    id: 'tin_ore',
    name: 'Tin Ore',
    description: 'A silvery chunk of tin-rich stone.',
    icon: '🪙',
    type: ItemType.resource,
    value: 4,
  );

  static const Item ironOre = Item(
    id: 'iron_ore',
    name: 'Iron Ore',
    description: 'A dense, rusty colored chunk of ore.',
    icon: '⛰️',
    type: ItemType.resource,
    value: 10,
  );

  static const Item nightshade = Item(
    id: 'nightshade',
    name: 'Nightshade Berries',
    description: 'Highly toxic berries, but valuable to herbalists.',
    icon: '🍇',
    type: ItemType.resource,
    value: 18,
  );

  static const Item wildflower = Item(
    id: 'wildflower',
    name: 'Wild Bluebell',
    description: 'A common bluebell used in healing potions.',
    icon: '🪻',
    type: ItemType.resource,
    value: 3,
  );

  static const Item riverClay = Item(
    id: 'river_clay',
    name: 'River Clay',
    description: 'Fine clay dredged from the river bed.',
    icon: '🧱',
    type: ItemType.resource,
    value: 6,
  );

  // Foods
  static const Item wildBerries = Item(
    id: 'wild_berries',
    name: 'Wild Berries',
    description: 'Sweet, tart forest berries.',
    icon: '🫐',
    type: ItemType.food,
    value: 2,
    healAmount: 5,
    energyAmount: 10,
  );

  static const Item bakedPotato = Item(
    id: 'baked_potato',
    name: 'Baked Potato',
    description: 'Warm and comforting potato that restores health.',
    icon: '🥔',
    type: ItemType.food,
    value: 8,
    healAmount: 15,
    energyAmount: 5,
  );

  static const Item herbalTea = Item(
    id: 'herbal_tea',
    name: 'Herbal Tea',
    description: 'A warm tea that restores significant energy.',
    icon: '🍵',
    type: ItemType.food,
    value: 12,
    healAmount: 0,
    energyAmount: 30,
  );

  static const Item cookedFish = Item(
    id: 'cooked_fish',
    name: 'Cooked Trout',
    description: 'A freshly grilled trout. Restores a large amount of health and energy.',
    icon: '🐟',
    type: ItemType.food,
    value: 15,
    healAmount: 30,
    energyAmount: 15,
  );

  // Tools
  static const Item stoneAxe = Item(
    id: 'stone_axe',
    name: 'Stone Axe',
    description: 'A rudimentary axe for chopping wood.',
    icon: '🪓',
    type: ItemType.tool,
    value: 50,
    toolSkill: SkillType.woodcutting,
    speedBonus: 0.05,
    successBonus: 0.05,
  );

  static const Item ironAxe = Item(
    id: 'iron_axe',
    name: 'Iron Axe',
    description: 'A sharp, iron axe. Much better at felling trees.',
    icon: '🪓',
    type: ItemType.tool,
    value: 200,
    toolSkill: SkillType.woodcutting,
    speedBonus: 0.15,
    successBonus: 0.10,
  );

  static const Item stonePickaxe = Item(
    id: 'stone_pickaxe',
    name: 'Stone Pickaxe',
    description: 'A basic pickaxe for chipping stone.',
    icon: '⛏️',
    type: ItemType.tool,
    value: 50,
    toolSkill: SkillType.mining,
    speedBonus: 0.05,
    successBonus: 0.05,
  );

  static const Item ironPickaxe = Item(
    id: 'iron_pickaxe',
    name: 'Iron Pickaxe',
    description: 'A sturdy iron pickaxe. Able to split stones easily.',
    icon: '⛏️',
    type: ItemType.tool,
    value: 200,
    toolSkill: SkillType.mining,
    speedBonus: 0.15,
    successBonus: 0.10,
  );

  static const Item foragingGloves = Item(
    id: 'foraging_gloves',
    name: 'Foraging Gloves',
    description: 'Leather gloves that protect hands and find better herbs.',
    icon: '🧤',
    type: ItemType.tool,
    value: 120,
    toolSkill: SkillType.herbalism,
    speedBonus: 0.10,
    successBonus: 0.10,
  );

  static const List<Item> all = [
    oakLog,
    willowLog,
    copperOre,
    tinOre,
    ironOre,
    nightshade,
    wildflower,
    riverClay,
    wildBerries,
    bakedPotato,
    herbalTea,
    cookedFish,
    stoneAxe,
    ironAxe,
    stonePickaxe,
    ironPickaxe,
    foragingGloves,
  ];

  static Item? findById(String id) {
    try {
      return all.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }
}
