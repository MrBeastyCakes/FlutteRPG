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

enum BeastPassive {
  none,
  healOnHit,
  damageReduction,
  reducedAccuracy,
  enrage,
  sourceQuake,
  sourceSedimentStack,
  sourcePollenCloud,
}

class EchoPhase {
  final double hpThreshold;
  final BeastAbility ability;
  final String entryNarration;
  final BeastPassive passive;

  const EchoPhase({
    required this.hpThreshold,
    required this.ability,
    required this.entryNarration,
    this.passive = BeastPassive.none,
  });
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
  final List<EchoPhase>? phases; // NEW
  final String? weaknessHint; // Spec 6b

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
    this.phases, // NEW
    this.weaknessHint,
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
    weaknessHint: 'Heavy Strike during charge windows',
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
    weaknessHint: 'Strike between web-bursts',
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
    weaknessHint: 'Defend on howl, then Strike',
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
    weaknessHint: 'Heavy Strike — armor breaks under force',
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

  static const BeastAbility _strangleVines = BeastAbility(
    id: 'strangle_vines',
    name: 'Strangle Vines',
    cooldownRounds: 3,
    telegraphText: 'Roots burst around your feet.',
    effect: BeastSpecialEffect.drainOverTime,
  );

  static const Beast echoOfWilds = Beast(
    id: 'echo_of_wilds',
    name: 'Echo of the Wilds',
    icon: '👁️',
    maxHealth: 240,
    attackPower: 18,
    defense: 4,
    xpReward: 280,
    lootTable: [
      LootDrop(item: Items.wildsEchoEssence, chance: 1.0, minQuantity: 1, maxQuantity: 1),
      LootDrop(item: Items.ironbarkLog, chance: 0.50, minQuantity: 1, maxQuantity: 2),
      LootDrop(item: Items.wolfPelt, chance: 0.40, minQuantity: 1, maxQuantity: 1),
    ],
    ability: _strangleVines,
    phases: [
      EchoPhase(hpThreshold: 1.0, ability: _strangleVines, entryNarration: 'You face the Echo of the Wilds.', passive: BeastPassive.none),
      EchoPhase(hpThreshold: 0.66, ability: _strangleVines, entryNarration: 'The Echo trembles — vines knit closed its wounds. It heals as it fights.', passive: BeastPassive.healOnHit),
      EchoPhase(hpThreshold: 0.33, ability: _strangleVines, entryNarration: 'The Hollow itself rises against you. The Echo will not slow.', passive: BeastPassive.enrage),
    ],
  );

  static const BeastAbility _quake = BeastAbility(
    id: 'quake',
    name: 'Quake',
    cooldownRounds: 3,
    telegraphText: 'The cavern wall groans.',
    effect: BeastSpecialEffect.bigHitStun,
  );

  static const Beast echoOfStone = Beast(
    id: 'echo_of_stone',
    name: 'Echo of the Stone',
    icon: '👁️',
    maxHealth: 280,
    attackPower: 16,
    defense: 8,
    xpReward: 320,
    lootTable: [
      LootDrop(item: Items.stoneEchoEssence, chance: 1.0, minQuantity: 1, maxQuantity: 1),
      LootDrop(item: Items.glintingOre, chance: 0.50, minQuantity: 1, maxQuantity: 2),
      LootDrop(item: Items.trollClaw, chance: 0.40, minQuantity: 1, maxQuantity: 1),
    ],
    ability: _quake,
    phases: [
      EchoPhase(hpThreshold: 1.0, ability: _quake, entryNarration: 'You face the Echo of the Stone.', passive: BeastPassive.none),
      EchoPhase(hpThreshold: 0.66, ability: _quake, entryNarration: "The Echo's surface hardens to crystal. Your blade rings dull.", passive: BeastPassive.damageReduction),
      EchoPhase(hpThreshold: 0.33, ability: _quake, entryNarration: "The cavern wall pulses with the Echo's heartbeat. It will not be slowed.", passive: BeastPassive.enrage),
    ],
  );

  static const BeastAbility _stormShroud = BeastAbility(
    id: 'storm_shroud',
    name: 'Storm Shroud',
    cooldownRounds: 3,
    telegraphText: 'The fog thickens. You lose the lamp.',
    effect: BeastSpecialEffect.accuracyDebuff,
  );

  static const Beast echoOfTide = Beast(
    id: 'echo_of_tide',
    name: 'Echo of the Tide',
    icon: '👁️',
    maxHealth: 260,
    attackPower: 17,
    defense: 5,
    xpReward: 300,
    lootTable: [
      LootDrop(item: Items.tideEchoEssence, chance: 1.0, minQuantity: 1, maxQuantity: 1),
      LootDrop(item: Items.pearlShell, chance: 0.50, minQuantity: 1, maxQuantity: 2),
      LootDrop(item: Items.saltTouchedPelt, chance: 0.40, minQuantity: 1, maxQuantity: 1),
    ],
    ability: _stormShroud,
    phases: [
      EchoPhase(hpThreshold: 1.0, ability: _stormShroud, entryNarration: 'You face the Echo of the Tide.', passive: BeastPassive.none),
      EchoPhase(hpThreshold: 0.66, ability: _stormShroud, entryNarration: 'The fog thickens around the Echo. You can barely see your own hands.', passive: BeastPassive.reducedAccuracy),
      EchoPhase(hpThreshold: 0.33, ability: _stormShroud, entryNarration: 'The Drowned rise from the surf. The Echo summons its kin.', passive: BeastPassive.enrage),
    ],
  );

  static const Beast shoreCrab = Beast(
    id: 'shore_crab',
    name: 'Shore Crab',
    icon: '🦀',
    maxHealth: 45,
    attackPower: 7,
    defense: 4,
    xpReward: 35,
    lootTable: [
      LootDrop(item: Items.crawlerCarapace, chance: 0.50, minQuantity: 1, maxQuantity: 1),
    ],
    weaknessHint: 'Strike sides — armored front',
  );

  static const Beast theSource = Beast(
    id: 'the_source',
    name: 'The Source',
    icon: '👁️',
    maxHealth: 1100,
    attackPower: 18,
    defense: 8,
    xpReward: 1500,
    lootTable: [],
    weaknessHint: null,
    phases: [
      EchoPhase(
        hpThreshold: 1.00,
        ability: _strangleVines,
        entryNarration: "The chamber dims. Green light blooms around you. The Source wears the Wilds' face — and it remembers being broken.",
        passive: BeastPassive.sourceQuake,
      ),
      EchoPhase(
        hpThreshold: 0.66,
        ability: _quake,
        entryNarration: "The green light hardens to grey. Stone-flesh closes over the wound you dealt. The Source wears a colder face now.",
        passive: BeastPassive.sourceSedimentStack,
      ),
      EchoPhase(
        hpThreshold: 0.33,
        ability: _stormShroud,
        entryNarration: "Grey runs to blue. Salt-mist rises from the floor. The Source wears the Tide's face — and it is angry.",
        passive: BeastPassive.sourcePollenCloud,
      ),
    ],
  );

  static const List<Beast> all = [
    forestBoar,
    caveSpider,
    shadowWolf,
    cavernTroll,
    tideHound,
    brineCrawler,
    saltTouchedDrowned,
    shoreCrab,
    echoOfWilds,
    echoOfStone,
    echoOfTide,
    theSource,
  ];

  static Beast? findById(String id) {
    try {
      return all.firstWhere((beast) => beast.id == id);
    } catch (_) {
      return null;
    }
  }
}
