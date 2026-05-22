import 'item.dart';
import 'skill.dart';

class LootDrop {
  final Item item;
  final double chance; // 0.0 to 1.0
  final int minQuantity;
  final int maxQuantity;

  const LootDrop({
    required this.item,
    required this.chance,
    this.minQuantity = 1,
    this.maxQuantity = 1,
  });
}

class ZoneAction {
  final String id;
  final String name;
  final String description;
  final int durationSeconds;
  final int energyCost;
  final int healthCost; // Hazard damage: if negative/positive, affects health. E.g. 5 means deals 5 damage.
  final double hazardChance; // Chance of taking hazard damage (0.0 to 1.0)
  final SkillType? requiredSkill;
  final int requiredLevel;
  final double xpReward;
  final List<LootDrop> lootTable;

  const ZoneAction({
    required this.id,
    required this.name,
    required this.description,
    required this.durationSeconds,
    required this.energyCost,
    this.healthCost = 0,
    this.hazardChance = 0.0,
    this.requiredSkill,
    this.requiredLevel = 1,
    required this.xpReward,
    required this.lootTable,
  });
}

class Zone {
  final String id;
  final String name;
  final int tier;
  final String description;
  final String weather;
  final String weatherBonusDescription;
  final double speedModifier; // e.g. 1.1 = 10% faster actions
  final double successModifier; // e.g. 0.05 = +5% success rates
  final List<ZoneAction> actions;

  const Zone({
    required this.id,
    required this.name,
    required this.tier,
    required this.description,
    required this.weather,
    required this.weatherBonusDescription,
    this.speedModifier = 1.0,
    this.successModifier = 0.0,
    required this.actions,
  });
}

/// A registry of all zones in the game
class Zones {
  static const Zone townSquare = Zone(
    id: 'town_square',
    name: 'Town Square',
    tier: 0,
    description: 'The peaceful hub of the region, featuring merchants and a safe place to rest.',
    weather: 'Clear',
    weatherBonusDescription: 'No active modifiers.',
    actions: [
      ZoneAction(
        id: 'inn_rest',
        name: 'Rest at the Inn',
        description: 'Spend gold to fully restore your health and energy.',
        durationSeconds: 3,
        energyCost: -50, // negative means recovers
        healthCost: -30, // negative means recovers
        xpReward: 5,
        requiredSkill: SkillType.wayfinding,
        requiredLevel: 1,
        lootTable: [],
      ),
      ZoneAction(
        id: 'chat_townsfolk',
        name: 'Listen to Lore',
        description: 'Listen to the elders tell stories about the ancient ruins.',
        durationSeconds: 4,
        energyCost: 2,
        xpReward: 12,
        requiredSkill: SkillType.lore,
        requiredLevel: 1,
        lootTable: [],
      ),
    ],
  );

  static const Zone whisperingWoodsTier1 = Zone(
    id: 'whispering_woods_1',
    name: 'Whispering Woods (Tier 1)',
    tier: 1,
    description: 'A quiet, green forest filled with rustling trees and wild berries.',
    weather: 'Sunny',
    weatherBonusDescription: 'Sunny (+5% Foraging speed)',
    speedModifier: 1.05,
    actions: [
      ZoneAction(
        id: 'chop_oak',
        name: 'Chop Young Oak',
        description: 'Fell a young oak tree for basic building logs.',
        durationSeconds: 4,
        energyCost: 4,
        requiredSkill: SkillType.woodcutting,
        requiredLevel: 1,
        xpReward: 25,
        lootTable: [
          LootDrop(item: Items.oakLog, chance: 0.90),
        ],
      ),
      ZoneAction(
        id: 'forage_berries',
        name: 'Forage Wild Berries',
        description: 'Gather fresh berries from low bushes.',
        durationSeconds: 3,
        energyCost: 2,
        requiredSkill: SkillType.herbalism,
        requiredLevel: 1,
        xpReward: 15,
        lootTable: [
          LootDrop(item: Items.wildBerries, chance: 0.85, minQuantity: 1, maxQuantity: 2),
        ],
      ),
      ZoneAction(
        id: 'inspect_obelisk',
        name: 'Inspect Crumbling Obelisk',
        description: 'Read the weathered glyphs on a stone monument.',
        durationSeconds: 5,
        energyCost: 4,
        requiredSkill: SkillType.lore,
        requiredLevel: 1,
        xpReward: 30,
        lootTable: [
          LootDrop(item: Items.wildflower, chance: 0.20), // bluebell grows nearby
        ],
      ),
    ],
  );

  static const Zone whisperingWoodsTier2 = Zone(
    id: 'whispering_woods_2',
    name: 'Whispering Woods (Tier 2)',
    tier: 2,
    description: 'Deeper and darker parts of the forest. The flora here is more mature and valuable.',
    weather: 'Foggy',
    weatherBonusDescription: 'Foggy (+10% Foraging success)',
    successModifier: 0.10,
    actions: [
      ZoneAction(
        id: 'chop_willow',
        name: 'Chop Mature Willow',
        description: 'Cut supple willow branches. Requires high skill.',
        durationSeconds: 6,
        energyCost: 6,
        requiredSkill: SkillType.woodcutting,
        requiredLevel: 10, // Locks at 10+
        xpReward: 45,
        lootTable: [
          LootDrop(item: Items.willowLog, chance: 0.80),
        ],
      ),
      ZoneAction(
        id: 'forage_nightshade',
        name: 'Forage Nightshade',
        description: 'Pick dangerous nightshade berries. Keep your distance.',
        durationSeconds: 5,
        energyCost: 5,
        requiredSkill: SkillType.herbalism,
        requiredLevel: 10,
        xpReward: 35,
        lootTable: [
          LootDrop(item: Items.nightshade, chance: 0.75),
        ],
      ),
      ZoneAction(
        id: 'dredge_clay',
        name: 'Dredge Riverbed Clay',
        description: 'Scoop rich clay from the rushing riverbed.',
        durationSeconds: 6,
        energyCost: 8,
        requiredSkill: SkillType.wayfinding,
        requiredLevel: 10,
        xpReward: 40,
        lootTable: [
          LootDrop(item: Items.riverClay, chance: 0.85, minQuantity: 1, maxQuantity: 2),
        ],
      ),
    ],
  );

  static const Zone darkstoneMineTier1 = Zone(
    id: 'darkstone_mine_1',
    name: 'Darkstone Mine (Tier 1)',
    tier: 1,
    description: 'A rocky cavern opening containing copper and tin veins.',
    weather: 'Cool Draft',
    weatherBonusDescription: 'Comfortable air (-5% Energy consumption)',
    actions: [
      ZoneAction(
        id: 'mine_copper',
        name: 'Mine Copper Ore',
        description: 'Swing a pickaxe into a copper vein.',
        durationSeconds: 5,
        energyCost: 4,
        requiredSkill: SkillType.mining,
        requiredLevel: 1,
        xpReward: 25,
        lootTable: [
          LootDrop(item: Items.copperOre, chance: 0.85),
        ],
      ),
      ZoneAction(
        id: 'mine_tin',
        name: 'Mine Tin Ore',
        description: 'Swing a pickaxe into a tin vein.',
        durationSeconds: 5,
        energyCost: 4,
        requiredSkill: SkillType.mining,
        requiredLevel: 1,
        xpReward: 25,
        lootTable: [
          LootDrop(item: Items.tinOre, chance: 0.85),
        ],
      ),
    ],
  );

  static const Zone darkstoneMineTier2 = Zone(
    id: 'darkstone_mine_2',
    name: 'Darkstone Mine (Tier 2)',
    tier: 2,
    description: 'Unstable lower shafts that are rich in iron but hazardous.',
    weather: 'Dusty',
    weatherBonusDescription: 'Dusty (-5% Action Speed)',
    speedModifier: 0.95,
    actions: [
      ZoneAction(
        id: 'mine_iron',
        name: 'Mine Iron Ore',
        description: 'Mine hard iron ore. Beware of loose overhead rocks.',
        durationSeconds: 7,
        energyCost: 7,
        healthCost: 15,
        hazardChance: 0.10, // 10% chance to take 15 damage
        requiredSkill: SkillType.mining,
        requiredLevel: 10,
        xpReward: 50,
        lootTable: [
          LootDrop(item: Items.ironOre, chance: 0.70),
        ],
      ),
    ],
  );

  static const List<Zone> all = [
    townSquare,
    whisperingWoodsTier1,
    whisperingWoodsTier2,
    darkstoneMineTier1,
    darkstoneMineTier2,
  ];

  static Zone findById(String id) {
    return all.firstWhere((zone) => zone.id == id, orElse: () => townSquare);
  }
}
