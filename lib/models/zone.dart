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
  final bool isCombat;
  final String? beastId;

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
    this.isCombat = false,
    this.beastId,
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
  final String unlockHint;

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
    this.unlockHint = '',
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
      ZoneAction(
        id: 'visit_tavern',
        name: 'Visit the Tavern',
        description: 'Step into the Boar & Hearth. Meet Bram, check the Notice Board, and relax.',
        durationSeconds: 1,
        energyCost: 0,
        requiredSkill: SkillType.wayfinding,
        requiredLevel: 1,
        xpReward: 0,
        lootTable: [],
      ),
      ZoneAction(
        id: 'explore_forest_paths',
        name: 'Scout Forest Paths',
        description: 'Venture into the treeline to search for good woodcutting grounds.',
        durationSeconds: 5,
        energyCost: 10,
        requiredSkill: SkillType.wayfinding,
        requiredLevel: 1,
        xpReward: 20,
        lootTable: [],
      ),
      ZoneAction(
        id: 'explore_rocky_trails',
        name: 'Scout Rocky Trails',
        description: 'Follow the rocky outcrops to search for ore-rich mining deposits.',
        durationSeconds: 5,
        energyCost: 10,
        requiredSkill: SkillType.wayfinding,
        requiredLevel: 1,
        xpReward: 20,
        lootTable: [],
      ),
      ZoneAction(
        id: 'walk_eastern_coastal_path',
        name: 'Walk the Eastern Coastal Path',
        description: 'A traveler\'s tale points east along an old footpath. Set out to see where it leads.',
        durationSeconds: 8,
        energyCost: 10,
        requiredSkill: SkillType.wayfinding,
        requiredLevel: 1,
        xpReward: 40,
        lootTable: [],
      ),
      ZoneAction(
        id: 'wharfmaster_travel',
        name: 'Take the Pier to the Coast',
        description: 'Board a small craft at the Wharfmaster\'s Pier. Quick passage to the Sundered Coast.',
        durationSeconds: 3,
        energyCost: 3,
        requiredSkill: SkillType.wayfinding,
        requiredLevel: 1,
        xpReward: 5,
        lootTable: [],
      ),
      ZoneAction(
        id: 'burn_wilds_echo_essence',
        name: '🔥 Burn the Wilds Echo Essence',
        description: 'Take the Essence to the Town Center fire and let it consume itself.',
        durationSeconds: 6,
        energyCost: 8,
        requiredSkill: SkillType.lore,
        requiredLevel: 1,
        xpReward: 100,
        lootTable: [],
      ),
      ZoneAction(
        id: 'burn_stone_echo_essence',
        name: '🔥 Burn the Stone Echo Essence',
        description: 'Take the Essence to the Town Center fire and let it consume itself.',
        durationSeconds: 6,
        energyCost: 8,
        requiredSkill: SkillType.lore,
        requiredLevel: 1,
        xpReward: 100,
        lootTable: [],
      ),
      ZoneAction(
        id: 'burn_tide_echo_essence',
        name: '🔥 Burn the Tide Echo Essence',
        description: 'Take the Essence to the Town Center fire and let it consume itself.',
        durationSeconds: 6,
        energyCost: 8,
        requiredSkill: SkillType.lore,
        requiredLevel: 1,
        xpReward: 100,
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
    unlockHint: 'Explore the Wilderness from the Town Square to discover.',
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
        id: 'catch_trout',
        name: 'Catch Fresh Trout',
        description: 'Fish in the rushing stream for fresh river trout.',
        durationSeconds: 4,
        energyCost: 3,
        requiredSkill: SkillType.wayfinding,
        requiredLevel: 3,
        xpReward: 20,
        lootTable: [
          LootDrop(item: Items.rawTrout, chance: 0.85),
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
      ZoneAction(
        id: 'explore_deep_woods',
        name: 'Chart Dark Canopy Paths',
        description: 'Map out the deep, dense undergrowth to find the path to Tier 2 woods.',
        durationSeconds: 7,
        energyCost: 15,
        requiredSkill: SkillType.wayfinding,
        requiredLevel: 5,
        xpReward: 35,
        lootTable: [],
      ),
      ZoneAction(
        id: 'hunt_boar',
        name: 'Hunt Forest Boar',
        description: 'Track and battle a wild forest boar.',
        durationSeconds: 5,
        energyCost: 6,
        requiredSkill: SkillType.combat,
        requiredLevel: 1,
        xpReward: 35,
        lootTable: [
          LootDrop(item: Items.boarMeat, chance: 0.85, minQuantity: 1, maxQuantity: 2),
          LootDrop(item: Items.boarTusk, chance: 0.40, minQuantity: 1, maxQuantity: 1),
        ],
        isCombat: true,
        beastId: 'forest_boar',
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
    unlockHint: 'Chart the Dark Canopy Paths from Whispering Woods (Tier 1) to discover.',
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
      ZoneAction(
        id: 'hunt_wolf',
        name: 'Hunt Shadow Wolf',
        description: 'Track and battle a dangerous shadow wolf.',
        durationSeconds: 6,
        energyCost: 8,
        requiredSkill: SkillType.combat,
        requiredLevel: 5,
        xpReward: 55,
        lootTable: [
          LootDrop(item: Items.wolfPelt, chance: 0.75, minQuantity: 1, maxQuantity: 1),
          LootDrop(item: Items.boarMeat, chance: 0.50, minQuantity: 1, maxQuantity: 2),
        ],
        isCombat: true,
        beastId: 'shadow_wolf',
      ),
    ],
  );

  static const Zone whisperingWoodsTier3 = Zone(
    id: 'whispering_woods_3',
    name: 'Bloomwither Hollow',
    tier: 3,
    description: 'A twilight grove where corruption manifests visibly — black sap weeps from Ironbarks, and a rotted shrine at the center pulses faintly.',
    weather: 'Eerie Silence',
    weatherBonusDescription: 'Unsettling atmosphere; hazard risks increase',
    unlockHint: 'Cleanse the previous areas and follow the warden\'s trace.',
    actions: [
      ZoneAction(
        id: 'fell_ironbark',
        name: 'Fell Ironbark',
        description: 'Fell a true Ironbark, rare and impossibly hard.',
        durationSeconds: 9,
        energyCost: 12,
        healthCost: 12,
        hazardChance: 0.20,
        requiredSkill: SkillType.woodcutting,
        requiredLevel: 15,
        xpReward: 75,
        lootTable: [
          LootDrop(item: Items.ironbarkLog, chance: 0.65, minQuantity: 1, maxQuantity: 1),
          LootDrop(item: Items.oakLog, chance: 0.30, minQuantity: 1, maxQuantity: 2),
        ],
      ),
      ZoneAction(
        id: 'pluck_corrupted_bloom',
        name: 'Pluck Corrupted Wildflower',
        description: 'Gather bluebells veined with black sap.',
        durationSeconds: 7,
        energyCost: 10,
        healthCost: 8,
        hazardChance: 0.15,
        requiredSkill: SkillType.herbalism,
        requiredLevel: 15,
        xpReward: 65,
        lootTable: [
          LootDrop(item: Items.corruptedWildflower, chance: 0.70, minQuantity: 1, maxQuantity: 1),
          LootDrop(item: Items.nightshade, chance: 0.20, minQuantity: 1, maxQuantity: 1),
        ],
      ),
      ZoneAction(
        id: 'read_hollow_plaque',
        name: 'Read the Hollow Plaque',
        description: 'Inspect the ancient shrine plaque at the center of the Hollow.',
        durationSeconds: 8,
        energyCost: 8,
        requiredSkill: SkillType.lore,
        requiredLevel: 12,
        xpReward: 70,
        lootTable: [],
      ),
      ZoneAction(
        id: 'hunt_corrupted_wolf',
        name: 'Hunt the Corrupted Wolf',
        description: 'Engage a wolf turned aggressive by the black sap.',
        durationSeconds: 7,
        energyCost: 10,
        requiredSkill: SkillType.combat,
        requiredLevel: 12,
        xpReward: 75,
        lootTable: [
          LootDrop(item: Items.wolfPelt, chance: 0.70, minQuantity: 1, maxQuantity: 1),
          LootDrop(item: Items.corruptedWildflower, chance: 0.30, minQuantity: 1, maxQuantity: 1),
        ],
        isCombat: true,
        beastId: 'shadow_wolf',
      ),
      ZoneAction(
        id: 'hunt_echo_of_wilds',
        name: 'Hunt the Echo of the Wilds',
        description: 'Confront the ancient manifestation of the forest\'s corruption.',
        durationSeconds: 12,
        energyCost: 18,
        requiredSkill: SkillType.combat,
        requiredLevel: 15,
        xpReward: 200,
        lootTable: [
          LootDrop(item: Items.wildsEchoEssence, chance: 1.0, minQuantity: 1, maxQuantity: 1),
          LootDrop(item: Items.ironbarkLog, chance: 0.50, minQuantity: 1, maxQuantity: 2),
          LootDrop(item: Items.wolfPelt, chance: 0.40, minQuantity: 1, maxQuantity: 1),
        ],
        isCombat: true,
        beastId: 'echo_of_wilds',
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
    unlockHint: 'Explore the Wilderness from the Town Square to discover.',
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
      ZoneAction(
        id: 'explore_lower_shafts',
        name: 'Survey Lower Caverns',
        description: 'Blaze a safe trail into the deep, unstable lower mining shafts.',
        durationSeconds: 8,
        energyCost: 20,
        requiredSkill: SkillType.wayfinding,
        requiredLevel: 8,
        xpReward: 40,
        lootTable: [],
      ),
      ZoneAction(
        id: 'hunt_spider',
        name: 'Exterminate Cave Spider',
        description: 'Clear out a giant venomous cave spider.',
        durationSeconds: 5,
        energyCost: 7,
        requiredSkill: SkillType.combat,
        requiredLevel: 2,
        xpReward: 45,
        lootTable: [
          LootDrop(item: Items.spiderSilk, chance: 0.80, minQuantity: 1, maxQuantity: 2),
          LootDrop(item: Items.spiderFang, chance: 0.35, minQuantity: 1, maxQuantity: 1),
        ],
        isCombat: true,
        beastId: 'cave_spider',
      ),
      ZoneAction(
        id: 'inspect_glyph',
        name: 'Read Mine-Glyph',
        description: 'A chiseled glyph on the cavern wall, half-forgotten.',
        durationSeconds: 5,
        energyCost: 4,
        requiredSkill: SkillType.lore,
        requiredLevel: 1,
        xpReward: 30,
        lootTable: const [],
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
    unlockHint: 'Survey the Lower Caverns from Darkstone Mine (Tier 1) to discover.',
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
      ZoneAction(
        id: 'hunt_troll',
        name: 'Slay Cavern Troll',
        description: 'Engage a massive cavern troll in a life-or-death battle.',
        durationSeconds: 8,
        energyCost: 12,
        requiredSkill: SkillType.combat,
        requiredLevel: 10,
        xpReward: 90,
        lootTable: [
          LootDrop(item: Items.trollClaw, chance: 0.70, minQuantity: 1, maxQuantity: 1),
          LootDrop(item: Items.ironOre, chance: 0.40, minQuantity: 1, maxQuantity: 2),
        ],
        isCombat: true,
        beastId: 'cavern_troll',
      ),
      ZoneAction(
        id: 'inspect_glyph',
        name: 'Read Mine-Glyph',
        description: 'A chiseled glyph on the cavern wall, half-forgotten.',
        durationSeconds: 5,
        energyCost: 4,
        requiredSkill: SkillType.lore,
        requiredLevel: 1,
        xpReward: 30,
        lootTable: const [],
      ),
    ],
  );

  static const Zone darkstoneMineTier3 = Zone(
    id: 'darkstone_mine_3',
    name: 'The Glowing Vein',
    tier: 3,
    description: 'A deep cavern where corruption has crystallized into a pulsing lens of stone. The foreman\'s lantern still hangs unlit at the entrance.',
    weather: 'Suffocating Dust',
    weatherBonusDescription: 'Thick air; hazard risks increase',
    unlockHint: 'Survey the Lower Caverns from Darkstone Mine (Tier 2).',
    actions: [
      ZoneAction(
        id: 'mine_glinting_ore',
        name: 'Mine the Glinting Ore',
        description: 'Chisel away at a pulsing vein of Glinting Ore.',
        durationSeconds: 9,
        energyCost: 12,
        healthCost: 12,
        hazardChance: 0.20,
        requiredSkill: SkillType.mining,
        requiredLevel: 15,
        xpReward: 75,
        lootTable: [
          LootDrop(item: Items.glintingOre, chance: 0.65, minQuantity: 1, maxQuantity: 1),
          LootDrop(item: Items.ironOre, chance: 0.40, minQuantity: 1, maxQuantity: 2),
        ],
      ),
      ZoneAction(
        id: 'sift_iron_dust',
        name: 'Sift Corrupted Iron Dust',
        description: 'Sift fine glittering dust from the cavern wall.',
        durationSeconds: 7,
        energyCost: 10,
        healthCost: 8,
        hazardChance: 0.15,
        requiredSkill: SkillType.mining,
        requiredLevel: 15,
        xpReward: 65,
        lootTable: [
          LootDrop(item: Items.corruptedIronDust, chance: 0.70, minQuantity: 1, maxQuantity: 1),
          LootDrop(item: Items.ironOre, chance: 0.30, minQuantity: 1, maxQuantity: 1),
        ],
      ),
      ZoneAction(
        id: 'read_vein_glyph',
        name: 'Read the Vein Glyph',
        description: 'Inspect the ancient, glowing inscriptions chiseled in the stone.',
        durationSeconds: 8,
        energyCost: 8,
        requiredSkill: SkillType.lore,
        requiredLevel: 12,
        xpReward: 70,
        lootTable: [],
      ),
      ZoneAction(
        id: 'slay_corrupted_troll',
        name: 'Slay the Corrupted Troll',
        description: 'Confront a troll driven mad by the pulsing stone.',
        durationSeconds: 8,
        energyCost: 12,
        requiredSkill: SkillType.combat,
        requiredLevel: 12,
        xpReward: 100,
        lootTable: [
          LootDrop(item: Items.trollClaw, chance: 0.70, minQuantity: 1, maxQuantity: 1),
          LootDrop(item: Items.corruptedIronDust, chance: 0.30, minQuantity: 1, maxQuantity: 1),
        ],
        isCombat: true,
        beastId: 'cavern_troll',
      ),
      ZoneAction(
        id: 'hunt_echo_of_stone',
        name: 'Hunt the Echo of the Stone',
        description: 'Confront the ancient, heavy echo dwelling inside the cavern floor.',
        durationSeconds: 14,
        energyCost: 20,
        requiredSkill: SkillType.combat,
        requiredLevel: 15,
        xpReward: 220,
        lootTable: [
          LootDrop(item: Items.stoneEchoEssence, chance: 1.0, minQuantity: 1, maxQuantity: 1),
          LootDrop(item: Items.glintingOre, chance: 0.50, minQuantity: 1, maxQuantity: 2),
          LootDrop(item: Items.trollClaw, chance: 0.40, minQuantity: 1, maxQuantity: 1),
        ],
        isCombat: true,
        beastId: 'echo_of_stone',
      ),
    ],
  );

  // ───── Sundered Coast I ─────
  static const Zone sunderedCoastTier1 = Zone(
    id: 'sundered_coast_1',
    name: 'Sundered Coast I',
    tier: 1,
    description: 'A weathered coastal stretch with tidal pools, brine air, and the smell of old wood. Where the Coast still looks almost normal.',
    weather: 'Variable',
    weatherBonusDescription: 'Weather varies (Calm / Sea Fog / Storm Swell)',
    successModifier: 0.05,
    unlockHint: 'Walk the Eastern Coastal Path from Town Square.',
    actions: [
      ZoneAction(
        id: 'gather_driftwood',
        name: 'Gather Driftwood',
        description: 'Collect bleached driftwood washed up on the tideline.',
        durationSeconds: 4,
        energyCost: 3,
        requiredSkill: SkillType.woodcutting,
        requiredLevel: 1,
        xpReward: 22,
        lootTable: [
          LootDrop(item: Items.driftwood, chance: 0.90),
        ],
      ),
      ZoneAction(
        id: 'forage_kelp',
        name: 'Forage Tide-Pool Kelp',
        description: 'Pluck sea kelp from sun-warmed tide pools.',
        durationSeconds: 4,
        energyCost: 3,
        requiredSkill: SkillType.herbalism,
        requiredLevel: 1,
        xpReward: 22,
        lootTable: [
          LootDrop(item: Items.kelp, chance: 0.85, minQuantity: 1, maxQuantity: 2),
        ],
      ),
      ZoneAction(
        id: 'pry_salt_crystal',
        name: 'Pry Salt Crystal',
        description: 'Chip a small salt crystal loose from a tide pool rim.',
        durationSeconds: 5,
        energyCost: 4,
        requiredSkill: SkillType.mining,
        requiredLevel: 1,
        xpReward: 25,
        lootTable: [
          LootDrop(item: Items.saltCrystal, chance: 0.80),
        ],
      ),
      ZoneAction(
        id: 'dive_pearl_shell',
        name: 'Dive Pearl Shell',
        description: 'Dive into the calm pools for an iridescent pearl shell. Requires Calm seas.',
        durationSeconds: 5,
        energyCost: 5,
        requiredSkill: SkillType.wayfinding,
        requiredLevel: 3,
        xpReward: 25,
        lootTable: [
          LootDrop(item: Items.pearlShell, chance: 0.75),
        ],
      ),
      ZoneAction(
        id: 'inspect_pier_glyph',
        name: 'Read the Pier Glyph',
        description: 'A weathered inscription on a salt-eaten pier post.',
        durationSeconds: 5,
        energyCost: 4,
        requiredSkill: SkillType.lore,
        requiredLevel: 1,
        xpReward: 30,
        lootTable: [],
      ),
      ZoneAction(
        id: 'hunt_tide_hound',
        name: 'Hunt Tide Hound',
        description: 'Track and battle a salt-soaked coastal hound.',
        durationSeconds: 5,
        energyCost: 4,
        requiredSkill: SkillType.combat,
        requiredLevel: 1,
        xpReward: 35,
        lootTable: [
          LootDrop(item: Items.tideHoundPelt, chance: 0.85, minQuantity: 1, maxQuantity: 1),
          LootDrop(item: Items.houndFang, chance: 0.40, minQuantity: 1, maxQuantity: 1),
        ],
        isCombat: true,
        beastId: 'tide_hound',
      ),
      ZoneAction(
        id: 'hunt_shore_crab',
        name: 'Hunt Shore Crab',
        description: 'Pry a defensive shore crab from its tide pool nook.',
        durationSeconds: 5,
        energyCost: 4,
        requiredSkill: SkillType.combat,
        requiredLevel: 2,
        xpReward: 38,
        lootTable: [
          LootDrop(item: Items.crawlerCarapace, chance: 0.50, minQuantity: 1, maxQuantity: 1),
        ],
        isCombat: true,
        beastId: 'shore_crab',
      ),
      ZoneAction(
        id: 'scout_cliff_path',
        name: 'Scout the Cliff Path',
        description: 'Survey the cliff path leading up to Sundered Coast II.',
        durationSeconds: 7,
        energyCost: 12,
        requiredSkill: SkillType.wayfinding,
        requiredLevel: 5,
        xpReward: 35,
        lootTable: [],
      ),
    ],
  );

  // ───── Sundered Coast II ─────
  static const Zone sunderedCoastTier2 = Zone(
    id: 'sundered_coast_2',
    name: 'Sundered Coast II',
    tier: 2,
    description: 'Wind-scoured cliffs above churning surf. Salt-flats produce concentrated minerals; pearl beds lie in the deeper pools.',
    weather: 'Variable',
    weatherBonusDescription: 'Weather varies — hazardous in Storm Swell',
    successModifier: 0.10,
    unlockHint: 'Scout the Cliff Path from Sundered Coast I.',
    actions: [
      ZoneAction(
        id: 'cut_bleached_driftwood',
        name: 'Cut Salt-Bleached Driftwood',
        description: 'Bigger driftwood logs from the cliffside surf-line.',
        durationSeconds: 6,
        energyCost: 6,
        requiredSkill: SkillType.woodcutting,
        requiredLevel: 10,
        xpReward: 45,
        lootTable: [
          LootDrop(item: Items.driftwood, chance: 0.85, minQuantity: 1, maxQuantity: 2),
          LootDrop(item: Items.saltCrystal, chance: 0.20),
        ],
      ),
      ZoneAction(
        id: 'harvest_seaglass_kelp',
        name: 'Harvest Sea-Glass Kelp',
        description: 'Rare crystalline kelp clinging to cliffside rocks.',
        durationSeconds: 6,
        energyCost: 6,
        requiredSkill: SkillType.herbalism,
        requiredLevel: 10,
        xpReward: 40,
        lootTable: [
          LootDrop(item: Items.kelp, chance: 0.80, minQuantity: 1, maxQuantity: 2),
          LootDrop(item: Items.nightshade, chance: 0.15),
        ],
      ),
      ZoneAction(
        id: 'mine_pure_salt',
        name: 'Mine Pure Salt Crystal',
        description: 'Chip away at a concentrated salt-flat vein.',
        durationSeconds: 7,
        energyCost: 7,
        requiredSkill: SkillType.mining,
        requiredLevel: 10,
        xpReward: 50,
        lootTable: [
          LootDrop(item: Items.saltCrystal, chance: 0.75),
        ],
      ),
      ZoneAction(
        id: 'dredge_pearl_bed',
        name: 'Dredge Deep Pearl Bed',
        description: 'Dive into a deep pearl bed. Requires Calm seas.',
        durationSeconds: 7,
        energyCost: 8,
        requiredSkill: SkillType.wayfinding,
        requiredLevel: 10,
        xpReward: 50,
        lootTable: [
          LootDrop(item: Items.pearlShell, chance: 0.70),
        ],
      ),
      ZoneAction(
        id: 'inspect_wharf_glyph',
        name: 'Read the Wharf Glyph',
        description: 'Cliffside markings carved by long-dead lighthouse keepers.',
        durationSeconds: 6,
        energyCost: 5,
        requiredSkill: SkillType.lore,
        requiredLevel: 5,
        xpReward: 40,
        lootTable: [],
      ),
      ZoneAction(
        id: 'hunt_brine_crawler',
        name: 'Hunt Brine Crawler',
        description: 'Battle a heavily armored crawler from the salt-flats.',
        durationSeconds: 6,
        energyCost: 8,
        requiredSkill: SkillType.combat,
        requiredLevel: 5,
        xpReward: 55,
        lootTable: [
          LootDrop(item: Items.crawlerCarapace, chance: 0.75, minQuantity: 1, maxQuantity: 1),
          LootDrop(item: Items.spiderSilk, chance: 0.50, minQuantity: 1, maxQuantity: 1),
        ],
        isCombat: true,
        beastId: 'brine_crawler',
      ),
      ZoneAction(
        id: 'scout_lighthouse_path',
        name: 'Scout the Lighthouse Path',
        description: 'Blaze a trail up to the storm-lashed lighthouse atop the rocks.',
        durationSeconds: 8,
        energyCost: 18,
        requiredSkill: SkillType.wayfinding,
        requiredLevel: 10,
        xpReward: 50,
        lootTable: [],
      ),
    ],
  );

  // ───── Sundered Coast III ─────
  static const Zone sunderedCoastTier3 = Zone(
    id: 'sundered_coast_3',
    name: 'Sundered Coast III',
    tier: 3,
    description: 'A storm-lashed lighthouse on a fog-bound rock. The lamp room flickers darkly even in daylight. Things move in the shallows that aren\'t fish.',
    weather: 'Hazardous',
    weatherBonusDescription: 'Heavy storms; combat is dangerous',
    unlockHint: 'Scout the Lighthouse Path from Sundered Coast II.',
    actions: [
      ZoneAction(
        id: 'scavenge_lamp_room',
        name: 'Scavenge Lamp Room',
        description: 'Pick through the lamp room\'s wreckage for materials.',
        durationSeconds: 8,
        energyCost: 10,
        healthCost: 10,
        hazardChance: 0.15,
        requiredSkill: SkillType.wayfinding,
        requiredLevel: 15,
        xpReward: 60,
        lootTable: [
          LootDrop(item: Items.saltCrystal, chance: 0.50, minQuantity: 1, maxQuantity: 2),
          LootDrop(item: Items.pearlShell, chance: 0.30),
          LootDrop(item: Items.driftwood, chance: 0.40, minQuantity: 1, maxQuantity: 2),
        ],
      ),
      ZoneAction(
        id: 'brave_drowned_cellar',
        name: 'Brave the Drowned Cellar',
        description: 'Descend into the flooded cellar to fight what dwells there.',
        durationSeconds: 8,
        energyCost: 12,
        healthCost: 15,
        hazardChance: 0.25,
        requiredSkill: SkillType.combat,
        requiredLevel: 10,
        xpReward: 90,
        lootTable: [
          LootDrop(item: Items.saltTouchedPelt, chance: 0.70, minQuantity: 1, maxQuantity: 1),
          LootDrop(item: Items.crawlerCarapace, chance: 0.40, minQuantity: 1, maxQuantity: 2),
        ],
        isCombat: true,
        beastId: 'salt_touched_drowned',
      ),
      ZoneAction(
        id: 'read_lighthouse_plaque',
        name: 'Read the Lighthouse Plaque',
        description: 'A bronze plaque mounted at the lighthouse base. The script is old and worn.',
        durationSeconds: 7,
        energyCost: 6,
        requiredSkill: SkillType.lore,
        requiredLevel: 10,
        xpReward: 60,
        lootTable: [],
      ),
      ZoneAction(
        id: 'approach_lamp_room',
        name: 'Approach the Lamp Room',
        description: 'Climb the lighthouse stairs to the lamp room. Something stirs above.',
        durationSeconds: 5,
        energyCost: 5,
        requiredSkill: SkillType.wayfinding,
        requiredLevel: 15,
        xpReward: 30,
        lootTable: [],
      ),
      ZoneAction(
        id: 'hunt_echo_of_tide',
        name: 'Hunt the Echo of the Tide',
        description: 'Confront the ancient manifestation rising from the ocean mist.',
        durationSeconds: 14,
        energyCost: 20,
        requiredSkill: SkillType.combat,
        requiredLevel: 15,
        xpReward: 220,
        lootTable: [
          LootDrop(item: Items.tideEchoEssence, chance: 1.0, minQuantity: 1, maxQuantity: 1),
          LootDrop(item: Items.pearlShell, chance: 0.50, minQuantity: 1, maxQuantity: 2),
          LootDrop(item: Items.saltTouchedPelt, chance: 0.40, minQuantity: 1, maxQuantity: 1),
        ],
        isCombat: true,
        beastId: 'echo_of_tide',
      ),
    ],
  );

  static const Zone nexusOfEchoes = Zone(
    id: 'nexus_of_echoes',
    name: 'Nexus of Echoes',
    tier: 3,
    description: 'A still chamber beneath the world. Three lights — green, grey, blue — hang in the air, waiting to be answered. Something larger waits behind them.',
    weather: 'Still',
    weatherBonusDescription: 'No active modifiers.',
    unlockHint: 'Cleanse all breaches and gather their tokens.',
    actions: [
      ZoneAction(
        id: 'confront_the_source',
        name: 'Confront the Source',
        description: 'Step into the convergence and call the Source forth. Your three Tokens hum in answer.',
        durationSeconds: 4,
        energyCost: 15,
        requiredSkill: SkillType.combat,
        requiredLevel: 1,
        xpReward: 0,
        lootTable: [],
        isCombat: true,
        beastId: 'the_source',
      ),
    ],
  );

  static const List<Zone> all = [
    townSquare,
    whisperingWoodsTier1,
    whisperingWoodsTier2,
    whisperingWoodsTier3,
    darkstoneMineTier1,
    darkstoneMineTier2,
    darkstoneMineTier3,
    sunderedCoastTier1,
    sunderedCoastTier2,
    sunderedCoastTier3,
    nexusOfEchoes,
  ];

  static Zone findById(String id) {
    return all.firstWhere((zone) => zone.id == id, orElse: () => townSquare);
  }
}
