import 'skill.dart';

class Structure {
  final String id;
  final String name;
  final String description;
  final String icon;
  final SkillType requiredSkill;
  final int requiredLevel;
  final Map<String, int> cost; // itemId -> quantity
  final int durationSeconds;
  final int energyCost;
  final double xpReward;

  const Structure({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.requiredSkill,
    required this.requiredLevel,
    required this.cost,
    required this.durationSeconds,
    required this.energyCost,
    required this.xpReward,
  });
}

class StationTier {
  final int tier;
  final Map<String, int> upgradeCost;      // mats to go from prev tier → this tier
  final int upgradeDurationSeconds;
  final int upgradeEnergyCost;
  final int requiredSkillLevel;
  final double qualityBias;                // tier 1 = +0.00, tier 2 = +0.05, tier 3 = +0.12
  final int queueSlots;                    // tier 1 = 1, tier 2 = 2, tier 3 = 3
  final double speedBonus;                 // tier 1 = +0%, tier 2 = +10%, tier 3 = +20%

  const StationTier({
    required this.tier,
    required this.upgradeCost,
    required this.upgradeDurationSeconds,
    required this.upgradeEnergyCost,
    required this.requiredSkillLevel,
    required this.qualityBias,
    required this.queueSlots,
    required this.speedBonus,
  });
}

class Station {
  final String id;
  final String name, icon, description;
  final SkillType primarySkill;
  final List<SkillType> enabledSkills;     // bench enables crafting + lore
  final int maxTier;                       // typically 3
  final List<StationTier> tiers;

  const Station({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.primarySkill,
    required this.enabledSkills,
    required this.maxTier,
    required this.tiers,
  });

  StationTier getTier(int tierVal) {
    return tiers.firstWhere((t) => t.tier == tierVal, orElse: () => tiers.first);
  }
}


class Structures {
  static const Structure craftingBench = Structure(
    id: 'crafting_bench',
    name: 'Crafting Bench',
    description: 'Allows crafting and lore study in this location.',
    icon: '🛠️',
    requiredSkill: SkillType.crafting,
    requiredLevel: 4,
    cost: {'oak_log': 10, 'river_clay': 5, 'copper_ore': 2},
    durationSeconds: 15,
    energyCost: 10,
    xpReward: 50.0,
  );

  static const Structure fieldKitchen = Structure(
    id: 'field_kitchen',
    name: 'Field Kitchen',
    description: 'Allows cooking and herbalism brewing in this location.',
    icon: '🍳',
    requiredSkill: SkillType.cooking,
    requiredLevel: 4,
    cost: {'oak_log': 5, 'river_clay': 10, 'wildflower': 3},
    durationSeconds: 15,
    energyCost: 10,
    xpReward: 50.0,
  );

  static const Structure outpostShelter = Structure(
    id: 'outpost_shelter',
    name: 'Outpost Shelter',
    description: 'Allows resting in this location for free.',
    icon: '🏕️',
    requiredSkill: SkillType.wayfinding,
    requiredLevel: 5,
    cost: {'oak_log': 15, 'river_clay': 10},
    durationSeconds: 20,
    energyCost: 15,
    xpReward: 60.0,
  );

  static const Structure smelter = Structure(
    id: 'smelter',
    name: 'Smelter',
    description: 'Used to smelt raw metal ores into refined ingots.',
    icon: '🏭',
    requiredSkill: SkillType.crafting,
    requiredLevel: 5,
    cost: {'copper_ore': 10, 'river_clay': 15, 'oak_log': 10},
    durationSeconds: 20,
    energyCost: 15,
    xpReward: 60.0,
  );

  static const Structure tannery = Structure(
    id: 'tannery',
    name: 'Tannery',
    description: 'Used to tan hides into cured leather and process treated silk.',
    icon: '🛖',
    requiredSkill: SkillType.crafting,
    requiredLevel: 5,
    cost: {'wolf_pelt': 5, 'river_clay': 10, 'oak_log': 15},
    durationSeconds: 20,
    energyCost: 15,
    xpReward: 60.0,
  );

  static const Structure apothecary = Structure(
    id: 'apothecary',
    name: 'Apothecary',
    description: 'Used to brew advanced herbalism elixirs and concoctions.',
    icon: '🧪',
    requiredSkill: SkillType.herbalism,
    requiredLevel: 5,
    cost: {'wildflower': 10, 'river_clay': 10, 'oak_log': 10},
    durationSeconds: 20,
    energyCost: 15,
    xpReward: 60.0,
  );

  static const Structure saltPress = Structure(
    id: 'salt_press',
    name: 'Salt Press',
    description: 'Presses salt, cures provisions, and stabilizes brine reagents. The lighthouse keepers used these before the storm.',
    icon: '🧂',
    requiredSkill: SkillType.cooking,
    requiredLevel: 3,
    cost: {'driftwood': 4, 'oak_log': 8, 'river_clay': 6},
    durationSeconds: 12,
    energyCost: 8,
    xpReward: 40.0,
  );

  static const List<Structure> all = [
    craftingBench,
    fieldKitchen,
    outpostShelter,
    smelter,
    tannery,
    apothecary,
    saltPress,
  ];

  static Structure? findById(String id) {
    try {
      return all.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}

class Stations {
  static const Station craftingBench = Station(
    id: 'crafting_bench',
    name: 'Crafting Bench',
    icon: '🛠️',
    description: 'Allows crafting and lore study in this location.',
    primarySkill: SkillType.crafting,
    enabledSkills: [SkillType.crafting, SkillType.lore],
    maxTier: 3,
    tiers: [
      StationTier(
        tier: 1,
        upgradeCost: {},
        upgradeDurationSeconds: 0,
        upgradeEnergyCost: 0,
        requiredSkillLevel: 1,
        qualityBias: 0.0,
        queueSlots: 1,
        speedBonus: 0.0,
      ),
      StationTier(
        tier: 2,
        upgradeCost: {'oak_log': 15, 'river_clay': 10, 'bronze_ingot': 5},
        upgradeDurationSeconds: 20,
        upgradeEnergyCost: 15,
        requiredSkillLevel: 7,
        qualityBias: 0.05,
        queueSlots: 2,
        speedBonus: 0.10,
      ),
      StationTier(
        tier: 3,
        upgradeCost: {'willow_log': 25, 'river_clay': 20, 'steel_ingot': 5},
        upgradeDurationSeconds: 30,
        upgradeEnergyCost: 20,
        requiredSkillLevel: 12,
        qualityBias: 0.12,
        queueSlots: 3,
        speedBonus: 0.20,
      ),
    ],
  );

  static const Station fieldKitchen = Station(
    id: 'field_kitchen',
    name: 'Field Kitchen',
    icon: '🍳',
    description: 'Allows cooking and basic herbalism brewing.',
    primarySkill: SkillType.cooking,
    enabledSkills: [SkillType.cooking, SkillType.herbalism],
    maxTier: 3,
    tiers: [
      StationTier(
        tier: 1,
        upgradeCost: {},
        upgradeDurationSeconds: 0,
        upgradeEnergyCost: 0,
        requiredSkillLevel: 1,
        qualityBias: 0.0,
        queueSlots: 1,
        speedBonus: 0.0,
      ),
      StationTier(
        tier: 2,
        upgradeCost: {'oak_log': 10, 'river_clay': 15, 'copper_ingot': 5},
        upgradeDurationSeconds: 20,
        upgradeEnergyCost: 15,
        requiredSkillLevel: 7,
        qualityBias: 0.05,
        queueSlots: 2,
        speedBonus: 0.10,
      ),
      StationTier(
        tier: 3,
        upgradeCost: {'willow_log': 20, 'river_clay': 25, 'iron_ingot': 5},
        upgradeDurationSeconds: 30,
        upgradeEnergyCost: 20,
        requiredSkillLevel: 12,
        qualityBias: 0.12,
        queueSlots: 3,
        speedBonus: 0.20,
      ),
    ],
  );

  static const Station outpostShelter = Station(
    id: 'outpost_shelter',
    name: 'Outpost Shelter',
    icon: '🏕️',
    description: 'Allows resting in this location for free.',
    primarySkill: SkillType.wayfinding,
    enabledSkills: [],
    maxTier: 1,
    tiers: [
      StationTier(
        tier: 1,
        upgradeCost: {},
        upgradeDurationSeconds: 0,
        upgradeEnergyCost: 0,
        requiredSkillLevel: 1,
        qualityBias: 0.0,
        queueSlots: 1,
        speedBonus: 0.0,
      ),
    ],
  );

  static const Station smelter = Station(
    id: 'smelter',
    name: 'Smelter',
    icon: '🏭',
    description: 'Used to smelt raw metal ores into refined ingots.',
    primarySkill: SkillType.crafting,
    enabledSkills: [SkillType.crafting],
    maxTier: 3,
    tiers: [
      StationTier(
        tier: 1,
        upgradeCost: {},
        upgradeDurationSeconds: 0,
        upgradeEnergyCost: 0,
        requiredSkillLevel: 1,
        qualityBias: 0.0,
        queueSlots: 1,
        speedBonus: 0.0,
      ),
      StationTier(
        tier: 2,
        upgradeCost: {'river_clay': 20, 'tin_ore': 10, 'iron_ore': 5},
        upgradeDurationSeconds: 25,
        upgradeEnergyCost: 15,
        requiredSkillLevel: 8,
        qualityBias: 0.05,
        queueSlots: 2,
        speedBonus: 0.10,
      ),
      StationTier(
        tier: 3,
        upgradeCost: {'willow_log': 30, 'iron_ore': 15, 'troll_claw': 2},
        upgradeDurationSeconds: 35,
        upgradeEnergyCost: 20,
        requiredSkillLevel: 13,
        qualityBias: 0.12,
        queueSlots: 3,
        speedBonus: 0.20,
      ),
    ],
  );

  static const Station tannery = Station(
    id: 'tannery',
    name: 'Tannery',
    icon: '🛖',
    description: 'Used to tan hides into cured leather and process treated silk.',
    primarySkill: SkillType.crafting,
    enabledSkills: [SkillType.crafting],
    maxTier: 3,
    tiers: [
      StationTier(
        tier: 1,
        upgradeCost: {},
        upgradeDurationSeconds: 0,
        upgradeEnergyCost: 0,
        requiredSkillLevel: 1,
        qualityBias: 0.0,
        queueSlots: 1,
        speedBonus: 0.0,
      ),
      StationTier(
        tier: 2,
        upgradeCost: {'oak_log': 20, 'wolf_pelt': 5, 'copper_ingot': 5},
        upgradeDurationSeconds: 25,
        upgradeEnergyCost: 15,
        requiredSkillLevel: 8,
        qualityBias: 0.05,
        queueSlots: 2,
        speedBonus: 0.10,
      ),
      StationTier(
        tier: 3,
        upgradeCost: {'willow_log': 30, 'spider_silk': 5, 'steel_ingot': 3},
        upgradeDurationSeconds: 35,
        upgradeEnergyCost: 20,
        requiredSkillLevel: 13,
        qualityBias: 0.12,
        queueSlots: 3,
        speedBonus: 0.20,
      ),
    ],
  );

  static const Station apothecary = Station(
    id: 'apothecary',
    name: 'Apothecary',
    icon: '🧪',
    description: 'Used to brew advanced herbalism elixirs and concoctions.',
    primarySkill: SkillType.herbalism,
    enabledSkills: [SkillType.herbalism],
    maxTier: 3,
    tiers: [
      StationTier(
        tier: 1,
        upgradeCost: {},
        upgradeDurationSeconds: 0,
        upgradeEnergyCost: 0,
        requiredSkillLevel: 1,
        qualityBias: 0.0,
        queueSlots: 1,
        speedBonus: 0.0,
      ),
      StationTier(
        tier: 2,
        upgradeCost: {'river_clay': 25, 'nightshade': 10, 'spider_fang': 5},
        upgradeDurationSeconds: 30,
        upgradeEnergyCost: 15,
        requiredSkillLevel: 9,
        qualityBias: 0.05,
        queueSlots: 2,
        speedBonus: 0.10,
      ),
      StationTier(
        tier: 3,
        upgradeCost: {'willow_log': 30, 'troll_claw': 3, 'iron_ingot': 5},
        upgradeDurationSeconds: 40,
        upgradeEnergyCost: 20,
        requiredSkillLevel: 14,
        qualityBias: 0.12,
        queueSlots: 3,
        speedBonus: 0.20,
      ),
    ],
  );

  static const Station saltPress = Station(
    id: 'salt_press',
    name: 'Salt Press',
    icon: '🧂',
    description: 'Presses salt, cures provisions, and stabilizes brine reagents. The lighthouse keepers used these before the storm.',
    primarySkill: SkillType.cooking,
    enabledSkills: [SkillType.cooking, SkillType.herbalism],
    maxTier: 3,
    tiers: [
      StationTier(
        tier: 1,
        upgradeCost: {'driftwood': 4, 'oak_log': 8, 'river_clay': 6},
        upgradeDurationSeconds: 12,
        upgradeEnergyCost: 8,
        requiredSkillLevel: 3,
        qualityBias: 0.0,
        queueSlots: 1,
        speedBonus: 0.0,
      ),
      StationTier(
        tier: 2,
        upgradeCost: {'driftwood': 8, 'salt_crystal': 6, 'pearl_shell': 2},
        upgradeDurationSeconds: 20,
        upgradeEnergyCost: 14,
        requiredSkillLevel: 8,
        qualityBias: 0.05,
        queueSlots: 2,
        speedBonus: 0.10,
      ),
      StationTier(
        tier: 3,
        upgradeCost: {'driftwood': 12, 'salt_crystal': 12, 'pearl_shell': 5},
        upgradeDurationSeconds: 30,
        upgradeEnergyCost: 22,
        requiredSkillLevel: 14,
        qualityBias: 0.12,
        queueSlots: 3,
        speedBonus: 0.20,
      ),
    ],
  );

  static const List<Station> all = [
    craftingBench,
    fieldKitchen,
    outpostShelter,
    smelter,
    tannery,
    apothecary,
    saltPress,
  ];

  static Station? findById(String id) {
    try {
      return all.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}
