import 'item.dart';
import 'zone.dart';

enum BeastSpecialEffect {
  bigHit,
  stun,
  bigHitStun,
  summonAlly,
  drainOverTime,
  accuracyDebuff,
}

class BeastAbility {
  final String id;
  final String name;
  final int cooldownRounds;
  final String telegraphText;
  final BeastSpecialEffect effect;

  const BeastAbility({
    required this.id,
    required this.name,
    required this.cooldownRounds,
    required this.telegraphText,
    required this.effect,
  });
}

class Beast {
  final String id;
  final String name;
  final String icon;
  final int maxHealth;
  final int attackPower;
  final int defense;
  final int xpReward;
  final List<LootDrop> lootTable;
  final BeastAbility? ability; // NEW

  const Beast({
    required this.id,
    required this.name,
    required this.icon,
    required this.maxHealth,
    required this.attackPower,
    required this.defense,
    required this.xpReward,
    required this.lootTable,
    this.ability, // NEW
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
    ability: BeastAbility(
      id: 'charge',
      name: 'Charge',
      cooldownRounds: 3,
      telegraphText: 'The boar paws the dirt, lowering its tusks.',
      effect: BeastSpecialEffect.bigHit,
    ),
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
    ability: BeastAbility(
      id: 'web',
      name: 'Web',
      cooldownRounds: 3,
      telegraphText: 'Web-glands glisten.',
      effect: BeastSpecialEffect.stun,
    ),
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
      LootDrop(item: Items.boarMeat, chance: 0.50, minQuantity: 1, maxQuantity: 2),
    ],
    ability: BeastAbility(
      id: 'howl',
      name: 'Howl',
      cooldownRounds: 3,
      telegraphText: "The wolf's eyes flash silver.",
      effect: BeastSpecialEffect.summonAlly,
    ),
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
    ability: BeastAbility(
      id: 'smash',
      name: 'Smash',
      cooldownRounds: 3,
      telegraphText: 'The troll hefts a boulder.',
      effect: BeastSpecialEffect.bigHitStun,
    ),
  );

  static const Beast tideHound = Beast(
    id: 'tide_hound',
    name: 'Tide Hound',
    icon: '🐕',
    maxHealth: 40,
    attackPower: 6,
    defense: 1,
    xpReward: 32,
    lootTable: [
      LootDrop(item: Items.tideHoundPelt, chance: 0.85, minQuantity: 1, maxQuantity: 1),
      LootDrop(item: Items.houndFang, chance: 0.40, minQuantity: 1, maxQuantity: 1),
    ],
    ability: BeastAbility(
      id: 'salt_splash',
      name: 'Salt Splash',
      cooldownRounds: 3,
      telegraphText: 'The hound shakes seawater from its coat.',
      effect: BeastSpecialEffect.accuracyDebuff,
    ),
  );

  static const Beast brineCrawler = Beast(
    id: 'brine_crawler',
    name: 'Brine Crawler',
    icon: '🦞',
    maxHealth: 75,
    attackPower: 12,
    defense: 3,
    xpReward: 60,
    lootTable: [
      LootDrop(item: Items.crawlerCarapace, chance: 0.75, minQuantity: 1, maxQuantity: 1),
      LootDrop(item: Items.spiderSilk, chance: 0.50, minQuantity: 1, maxQuantity: 1),
    ],
    ability: BeastAbility(
      id: 'pincer_lock',
      name: 'Pincer Lock',
      cooldownRounds: 3,
      telegraphText: "The crawler's claws lock open.",
      effect: BeastSpecialEffect.drainOverTime,
    ),
  );

  static const Beast saltTouchedDrowned = Beast(
    id: 'salt_touched_drowned',
    name: 'Salt-Touched Drowned',
    icon: '🧟',
    maxHealth: 140,
    attackPower: 20,
    defense: 5,
    xpReward: 100,
    lootTable: [
      LootDrop(item: Items.saltTouchedPelt, chance: 0.70, minQuantity: 1, maxQuantity: 1),
      LootDrop(item: Items.crawlerCarapace, chance: 0.40, minQuantity: 1, maxQuantity: 2),
    ],
    ability: BeastAbility(
      id: 'death_wail',
      name: 'Death Wail',
      cooldownRounds: 3,
      telegraphText: 'The drowned thing opens its mouth without sound.',
      effect: BeastSpecialEffect.bigHitStun,
    ),
  );

  static const List<Beast> all = [
    forestBoar,
    caveSpider,
    shadowWolf,
    cavernTroll,
    tideHound,
    brineCrawler,
    saltTouchedDrowned,
  ];

  static Beast? findById(String id) {
    try {
      return all.firstWhere((beast) => beast.id == id);
    } catch (_) {
      return null;
    }
  }
}
