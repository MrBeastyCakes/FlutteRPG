import 'skill.dart';
import 'item.dart';

class SlotChoice {
  final String itemId;
  final double qualityBias; // e.g. +0.03 for willow_log; -0.10 for below-canonical

  const SlotChoice({
    required this.itemId,
    required this.qualityBias,
  });
}

class RecipeSlot {
  final int quantity;
  final List<SlotChoice> acceptedItems; // ordered list; index 0 = canonical (+0 bias)

  const RecipeSlot({
    required this.quantity,
    required this.acceptedItems,
  });
}

enum RecipeRarity { common, rare, legendary }

class Recipe {
  final String id;
  final String name;
  final String icon;
  final String description;
  final String resultItemId;
  final int resultQuantity;
  final SkillType requiredSkill;
  final int requiredLevel;
  final double xpReward;
  final List<RecipeSlot> slots;
  final RecipeSlot? modifierSlot;
  final String stationId;
  final int requiredStationTier;
  final RecipeRarity rarity;
  final int energyCost;
  final int durationSeconds;

  const Recipe({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.resultItemId,
    required this.resultQuantity,
    required this.requiredSkill,
    required this.requiredLevel,
    required this.xpReward,
    required this.slots,
    this.modifierSlot,
    required this.stationId,
    this.requiredStationTier = 1,
    this.rarity = RecipeRarity.common,
    required this.energyCost,
    required this.durationSeconds,
  });

  Item? get resultItem => Items.findById(resultItemId);

  // Expose a helper map for backward compatibility
  Map<String, int> get inputs {
    final result = <String, int>{};
    for (final slot in slots) {
      if (slot.acceptedItems.isNotEmpty) {
        result[slot.acceptedItems.first.itemId] = slot.quantity;
      }
    }
    return result;
  }
}

class Recipes {
  // Shared default modifier slot allowing common materials as boosters
  static const RecipeSlot defaultModifier = RecipeSlot(
    quantity: 1,
    acceptedItems: [
      SlotChoice(itemId: 'wildflower', qualityBias: 0.0),
      SlotChoice(itemId: 'nightshade', qualityBias: 0.0),
      SlotChoice(itemId: 'river_clay', qualityBias: 0.0),
      SlotChoice(itemId: 'wild_berries', qualityBias: 0.0),
      SlotChoice(itemId: 'troll_claw', qualityBias: 0.0),
      SlotChoice(itemId: 'boar_tusk', qualityBias: 0.0),
    ],
  );

  // ==========================================
  // 1. BASIC TOOLS (Bench T1)
  // ==========================================
  static const Recipe stoneAxe = Recipe(
    id: 'stone_axe',
    name: 'Stone Axe',
    icon: '🪓',
    description: 'Assemble a basic stone axe from logs and clay.',
    resultItemId: 'stone_axe',
    resultQuantity: 1,
    requiredSkill: SkillType.crafting,
    requiredLevel: 1,
    xpReward: 15.0,
    slots: [
      RecipeSlot(
        quantity: 3,
        acceptedItems: [
          SlotChoice(itemId: 'oak_log', qualityBias: 0.0),
          SlotChoice(itemId: 'willow_log', qualityBias: 0.03),
        ],
      ),
      RecipeSlot(
        quantity: 2,
        acceptedItems: [
          SlotChoice(itemId: 'river_clay', qualityBias: 0.0),
        ],
      ),
    ],
    modifierSlot: defaultModifier,
    stationId: 'crafting_bench',
    requiredStationTier: 1,
    energyCost: 3,
    durationSeconds: 3,
  );

  static const Recipe stonePickaxe = Recipe(
    id: 'stone_pickaxe',
    name: 'Stone Pickaxe',
    icon: '⛏️',
    description: 'Assemble a basic stone pickaxe from logs and clay.',
    resultItemId: 'stone_pickaxe',
    resultQuantity: 1,
    requiredSkill: SkillType.crafting,
    requiredLevel: 1,
    xpReward: 15.0,
    slots: [
      RecipeSlot(
        quantity: 3,
        acceptedItems: [
          SlotChoice(itemId: 'oak_log', qualityBias: 0.0),
          SlotChoice(itemId: 'willow_log', qualityBias: 0.03),
        ],
      ),
      RecipeSlot(
        quantity: 2,
        acceptedItems: [
          SlotChoice(itemId: 'river_clay', qualityBias: 0.0),
        ],
      ),
    ],
    modifierSlot: defaultModifier,
    stationId: 'crafting_bench',
    requiredStationTier: 1,
    energyCost: 3,
    durationSeconds: 3,
  );

  static const Recipe foragingGloves = Recipe(
    id: 'foraging_gloves',
    name: 'Foraging Gloves',
    icon: '🧤',
    description: 'Stitch basic leather gloves with river clay and wildflowers.',
    resultItemId: 'foraging_gloves',
    resultQuantity: 1,
    requiredSkill: SkillType.crafting,
    requiredLevel: 1,
    xpReward: 15.0,
    slots: [
      RecipeSlot(
        quantity: 3,
        acceptedItems: [
          SlotChoice(itemId: 'wildflower', qualityBias: 0.0),
        ],
      ),
      RecipeSlot(
        quantity: 2,
        acceptedItems: [
          SlotChoice(itemId: 'river_clay', qualityBias: 0.0),
        ],
      ),
    ],
    modifierSlot: defaultModifier,
    stationId: 'crafting_bench',
    requiredStationTier: 1,
    energyCost: 3,
    durationSeconds: 3,
  );

  // ==========================================
  // 2. TOOL UPGRADES (Bench T1 / T2 / T3)
  // ==========================================
  static const Recipe copperAxe = Recipe(
    id: 'copper_axe',
    name: 'Copper Axe',
    icon: '🪓',
    description: 'Upgrade your Stone Axe with copper ingots.',
    resultItemId: 'copper_axe',
    resultQuantity: 1,
    requiredSkill: SkillType.crafting,
    requiredLevel: 5,
    xpReward: 30.0,
    slots: [
      RecipeSlot(
        quantity: 1,
        acceptedItems: [
          SlotChoice(itemId: 'stone_axe', qualityBias: 0.0),
        ],
      ),
      RecipeSlot(
        quantity: 2,
        acceptedItems: [
          SlotChoice(itemId: 'copper_ingot', qualityBias: 0.0),
        ],
      ),
      RecipeSlot(
        quantity: 3,
        acceptedItems: [
          SlotChoice(itemId: 'oak_log', qualityBias: 0.0),
          SlotChoice(itemId: 'willow_log', qualityBias: 0.04),
        ],
      ),
    ],
    modifierSlot: defaultModifier,
    stationId: 'crafting_bench',
    requiredStationTier: 1,
    energyCost: 6,
    durationSeconds: 4,
  );

  static const Recipe bronzeAxe = Recipe(
    id: 'bronze_axe',
    name: 'Bronze Axe',
    icon: '🪓',
    description: 'Upgrade your Copper Axe with bronze ingots.',
    resultItemId: 'bronze_axe',
    resultQuantity: 1,
    requiredSkill: SkillType.crafting,
    requiredLevel: 8,
    xpReward: 40.0,
    slots: [
      RecipeSlot(
        quantity: 1,
        acceptedItems: [
          SlotChoice(itemId: 'copper_axe', qualityBias: 0.0),
        ],
      ),
      RecipeSlot(
        quantity: 2,
        acceptedItems: [
          SlotChoice(itemId: 'bronze_ingot', qualityBias: 0.0),
        ],
      ),
      RecipeSlot(
        quantity: 3,
        acceptedItems: [
          SlotChoice(itemId: 'oak_log', qualityBias: 0.0),
          SlotChoice(itemId: 'willow_log', qualityBias: 0.04),
        ],
      ),
    ],
    modifierSlot: defaultModifier,
    stationId: 'crafting_bench',
    requiredStationTier: 2,
    energyCost: 8,
    durationSeconds: 5,
  );

  static const Recipe ironAxe = Recipe(
    id: 'iron_axe',
    name: 'Iron Axe',
    icon: '🪓',
    description: 'Upgrade your Bronze Axe with iron ingots and willow logs.',
    resultItemId: 'iron_axe',
    resultQuantity: 1,
    requiredSkill: SkillType.crafting,
    requiredLevel: 12,
    xpReward: 50.0,
    slots: [
      RecipeSlot(
        quantity: 1,
        acceptedItems: [
          SlotChoice(itemId: 'bronze_axe', qualityBias: 0.0),
        ],
      ),
      RecipeSlot(
        quantity: 3,
        acceptedItems: [
          SlotChoice(itemId: 'iron_ingot', qualityBias: 0.0),
        ],
      ),
      RecipeSlot(
        quantity: 3,
        acceptedItems: [
          SlotChoice(itemId: 'willow_log', qualityBias: 0.0),
          SlotChoice(itemId: 'oak_log', qualityBias: -0.05),
        ],
      ),
    ],
    modifierSlot: defaultModifier,
    stationId: 'crafting_bench',
    requiredStationTier: 2,
    energyCost: 10,
    durationSeconds: 6,
  );

  static const Recipe copperPickaxe = Recipe(
    id: 'copper_pickaxe',
    name: 'Copper Pickaxe',
    icon: '⛏️',
    description: 'Upgrade your Stone Pickaxe with copper ingots.',
    resultItemId: 'copper_pickaxe',
    resultQuantity: 1,
    requiredSkill: SkillType.crafting,
    requiredLevel: 5,
    xpReward: 30.0,
    slots: [
      RecipeSlot(
        quantity: 1,
        acceptedItems: [
          SlotChoice(itemId: 'stone_pickaxe', qualityBias: 0.0),
        ],
      ),
      RecipeSlot(
        quantity: 2,
        acceptedItems: [
          SlotChoice(itemId: 'copper_ingot', qualityBias: 0.0),
        ],
      ),
      RecipeSlot(
        quantity: 3,
        acceptedItems: [
          SlotChoice(itemId: 'oak_log', qualityBias: 0.0),
          SlotChoice(itemId: 'willow_log', qualityBias: 0.04),
        ],
      ),
    ],
    modifierSlot: defaultModifier,
    stationId: 'crafting_bench',
    requiredStationTier: 1,
    energyCost: 6,
    durationSeconds: 4,
  );

  static const Recipe bronzePickaxe = Recipe(
    id: 'bronze_pickaxe',
    name: 'Bronze Pickaxe',
    icon: '⛏️',
    description: 'Upgrade your Copper Pickaxe with bronze ingots.',
    resultItemId: 'bronze_pickaxe',
    resultQuantity: 1,
    requiredSkill: SkillType.crafting,
    requiredLevel: 8,
    xpReward: 40.0,
    slots: [
      RecipeSlot(
        quantity: 1,
        acceptedItems: [
          SlotChoice(itemId: 'copper_pickaxe', qualityBias: 0.0),
        ],
      ),
      RecipeSlot(
        quantity: 2,
        acceptedItems: [
          SlotChoice(itemId: 'bronze_ingot', qualityBias: 0.0),
        ],
      ),
      RecipeSlot(
        quantity: 3,
        acceptedItems: [
          SlotChoice(itemId: 'oak_log', qualityBias: 0.0),
          SlotChoice(itemId: 'willow_log', qualityBias: 0.04),
        ],
      ),
    ],
    modifierSlot: defaultModifier,
    stationId: 'crafting_bench',
    requiredStationTier: 2,
    energyCost: 8,
    durationSeconds: 5,
  );

  static const Recipe ironPickaxe = Recipe(
    id: 'iron_pickaxe',
    name: 'Iron Pickaxe',
    icon: '⛏️',
    description: 'Upgrade your Bronze Pickaxe with iron ingots and willow logs.',
    resultItemId: 'iron_pickaxe',
    resultQuantity: 1,
    requiredSkill: SkillType.crafting,
    requiredLevel: 12,
    xpReward: 50.0,
    slots: [
      RecipeSlot(
        quantity: 1,
        acceptedItems: [
          SlotChoice(itemId: 'bronze_pickaxe', qualityBias: 0.0),
        ],
      ),
      RecipeSlot(
        quantity: 3,
        acceptedItems: [
          SlotChoice(itemId: 'iron_ingot', qualityBias: 0.0),
        ],
      ),
      RecipeSlot(
        quantity: 3,
        acceptedItems: [
          SlotChoice(itemId: 'willow_log', qualityBias: 0.0),
          SlotChoice(itemId: 'oak_log', qualityBias: -0.05),
        ],
      ),
    ],
    modifierSlot: defaultModifier,
    stationId: 'crafting_bench',
    requiredStationTier: 2,
    energyCost: 10,
    durationSeconds: 6,
  );

  static const Recipe reinforcedGloves = Recipe(
    id: 'reinforced_gloves',
    name: 'Reinforced Gloves',
    icon: '🧤',
    description: 'Upgrade your Foraging Gloves with cured leather and clay.',
    resultItemId: 'reinforced_gloves',
    resultQuantity: 1,
    requiredSkill: SkillType.crafting,
    requiredLevel: 7,
    xpReward: 35.0,
    slots: [
      RecipeSlot(
        quantity: 1,
        acceptedItems: [
          SlotChoice(itemId: 'foraging_gloves', qualityBias: 0.0),
        ],
      ),
      RecipeSlot(
        quantity: 2,
        acceptedItems: [
          SlotChoice(itemId: 'cured_leather', qualityBias: 0.0),
        ],
      ),
      RecipeSlot(
        quantity: 3,
        acceptedItems: [
          SlotChoice(itemId: 'river_clay', qualityBias: 0.0),
        ],
      ),
    ],
    modifierSlot: defaultModifier,
    stationId: 'crafting_bench',
    requiredStationTier: 2,
    rarity: RecipeRarity.rare,
    energyCost: 8,
    durationSeconds: 5,
  );

  static const Recipe masterworkGloves = Recipe(
    id: 'masterwork_gloves',
    name: 'Masterwork Gloves',
    icon: '🧤',
    description: 'Upgrade your Reinforced Gloves with treated silk and nightshade.',
    resultItemId: 'masterwork_gloves',
    resultQuantity: 1,
    requiredSkill: SkillType.crafting,
    requiredLevel: 12,
    xpReward: 60.0,
    slots: [
      RecipeSlot(
        quantity: 1,
        acceptedItems: [
          SlotChoice(itemId: 'reinforced_gloves', qualityBias: 0.0),
        ],
      ),
      RecipeSlot(
        quantity: 2,
        acceptedItems: [
          SlotChoice(itemId: 'treated_silk', qualityBias: 0.0),
        ],
      ),
      RecipeSlot(
        quantity: 3,
        acceptedItems: [
          SlotChoice(itemId: 'nightshade', qualityBias: 0.0),
        ],
      ),
    ],
    modifierSlot: defaultModifier,
    stationId: 'crafting_bench',
    requiredStationTier: 3,
    rarity: RecipeRarity.rare,
    energyCost: 12,
    durationSeconds: 6,
  );

  // ==========================================
  // 3. COOKING (Kitchen T1 / T2)
  // ==========================================
  static const Recipe bakedPotato = Recipe(
    id: 'baked_potato',
    name: 'Baked Potato',
    icon: '🥔',
    description: 'Cook raw potato over oak fire.',
    resultItemId: 'baked_potato',
    resultQuantity: 1,
    requiredSkill: SkillType.cooking,
    requiredLevel: 1,
    xpReward: 20.0,
    slots: [
      RecipeSlot(
        quantity: 1,
        acceptedItems: [
          SlotChoice(itemId: 'raw_potato', qualityBias: 0.0),
        ],
      ),
      RecipeSlot(
        quantity: 1,
        acceptedItems: [
          SlotChoice(itemId: 'oak_log', qualityBias: 0.0),
          SlotChoice(itemId: 'willow_log', qualityBias: 0.05),
        ],
      ),
    ],
    modifierSlot: defaultModifier,
    stationId: 'field_kitchen',
    requiredStationTier: 1,
    energyCost: 2,
    durationSeconds: 3,
  );

  static const Recipe butteredPotato = Recipe(
    id: 'buttered_potato',
    name: 'Buttered Potato',
    icon: '🥔',
    description: 'Upgrade baked potato with wildflowers.',
    resultItemId: 'buttered_potato',
    resultQuantity: 1,
    requiredSkill: SkillType.cooking,
    requiredLevel: 6,
    xpReward: 22.0,
    slots: [
      RecipeSlot(
        quantity: 1,
        acceptedItems: [
          SlotChoice(itemId: 'baked_potato', qualityBias: 0.0),
        ],
      ),
      RecipeSlot(
        quantity: 2,
        acceptedItems: [
          SlotChoice(itemId: 'wildflower', qualityBias: 0.0),
        ],
      ),
    ],
    modifierSlot: defaultModifier,
    stationId: 'field_kitchen',
    requiredStationTier: 1,
    energyCost: 2,
    durationSeconds: 3,
  );

  static const Recipe loadedPotato = Recipe(
    id: 'loaded_potato',
    name: 'Loaded Potato',
    icon: '🥔',
    description: 'Upgrade buttered potato with cooked trout and boar meat.',
    resultItemId: 'loaded_potato',
    resultQuantity: 1,
    requiredSkill: SkillType.cooking,
    requiredLevel: 10,
    xpReward: 30.0,
    slots: [
      RecipeSlot(
        quantity: 1,
        acceptedItems: [
          SlotChoice(itemId: 'buttered_potato', qualityBias: 0.0),
        ],
      ),
      RecipeSlot(
        quantity: 1,
        acceptedItems: [
          SlotChoice(itemId: 'cooked_fish', qualityBias: 0.0),
        ],
      ),
      RecipeSlot(
        quantity: 1,
        acceptedItems: [
          SlotChoice(itemId: 'boar_meat', qualityBias: 0.0),
        ],
      ),
    ],
    modifierSlot: defaultModifier,
    stationId: 'field_kitchen',
    requiredStationTier: 2,
    rarity: RecipeRarity.rare,
    energyCost: 3,
    durationSeconds: 4,
  );

  static const Recipe cookedTrout = Recipe(
    id: 'cooked_trout',
    name: 'Cooked Trout',
    icon: '🐟',
    description: 'Cook raw trout over oak fire.',
    resultItemId: 'cooked_fish',
    resultQuantity: 1,
    requiredSkill: SkillType.cooking,
    requiredLevel: 1,
    xpReward: 22.0,
    slots: [
      RecipeSlot(
        quantity: 1,
        acceptedItems: [
          SlotChoice(itemId: 'raw_trout', qualityBias: 0.0),
        ],
      ),
      RecipeSlot(
        quantity: 1,
        acceptedItems: [
          SlotChoice(itemId: 'oak_log', qualityBias: 0.0),
          SlotChoice(itemId: 'willow_log', qualityBias: 0.05),
        ],
      ),
    ],
    modifierSlot: defaultModifier,
    stationId: 'field_kitchen',
    requiredStationTier: 1,
    energyCost: 3,
    durationSeconds: 4,
  );

  static const Recipe smokedTrout = Recipe(
    id: 'smoked_trout',
    name: 'Smoked Trout',
    icon: '🐟',
    description: 'Upgrade cooked trout by smoking it over willow wood.',
    resultItemId: 'smoked_trout',
    resultQuantity: 1,
    requiredSkill: SkillType.cooking,
    requiredLevel: 6,
    xpReward: 28.0,
    slots: [
      RecipeSlot(
        quantity: 1,
        acceptedItems: [
          SlotChoice(itemId: 'cooked_fish', qualityBias: 0.0),
        ],
      ),
      RecipeSlot(
        quantity: 2,
        acceptedItems: [
          SlotChoice(itemId: 'willow_log', qualityBias: 0.0),
          SlotChoice(itemId: 'oak_log', qualityBias: -0.04),
        ],
      ),
    ],
    modifierSlot: defaultModifier,
    stationId: 'field_kitchen',
    requiredStationTier: 1,
    energyCost: 3,
    durationSeconds: 4,
  );

  static const Recipe herbalTea = Recipe(
    id: 'herbal_tea',
    name: 'Herbal Tea',
    icon: '🍵',
    description: 'Brew wildflower in hot water.',
    resultItemId: 'herbal_tea',
    resultQuantity: 1,
    requiredSkill: SkillType.cooking,
    requiredLevel: 8,
    xpReward: 25.0,
    slots: [
      RecipeSlot(
        quantity: 2,
        acceptedItems: [
          SlotChoice(itemId: 'wildflower', qualityBias: 0.0),
        ],
      ),
      RecipeSlot(
        quantity: 1,
        acceptedItems: [
          SlotChoice(itemId: 'hot_water', qualityBias: 0.0),
        ],
      ),
    ],
    modifierSlot: defaultModifier,
    stationId: 'field_kitchen',
    requiredStationTier: 1,
    energyCost: 2,
    durationSeconds: 3,
  );

  static const Recipe spicedTea = Recipe(
    id: 'spiced_tea',
    name: 'Spiced Tea',
    icon: '🍵',
    description: 'Upgrade herbal tea with a drop of nightshade essence.',
    resultItemId: 'spiced_tea',
    resultQuantity: 1,
    requiredSkill: SkillType.cooking,
    requiredLevel: 10,
    xpReward: 35.0,
    slots: [
      RecipeSlot(
        quantity: 1,
        acceptedItems: [
          SlotChoice(itemId: 'herbal_tea', qualityBias: 0.0),
        ],
      ),
      RecipeSlot(
        quantity: 1,
        acceptedItems: [
          SlotChoice(itemId: 'nightshade', qualityBias: 0.0),
        ],
      ),
    ],
    modifierSlot: defaultModifier,
    stationId: 'field_kitchen',
    requiredStationTier: 2,
    rarity: RecipeRarity.rare,
    energyCost: 3,
    durationSeconds: 3,
  );

  // ==========================================
  // 4. HERBALISM POTIONS (Kitchen T1 / Apothecary)
  // ==========================================
  static const Recipe elixirOfLife1 = Recipe(
    id: 'elixir_1',
    name: 'Elixir of Life I',
    icon: '🧪',
    description: 'A basic healing potion brewed with forest wildflowers.',
    resultItemId: 'elixir_1',
    resultQuantity: 1,
    requiredSkill: SkillType.herbalism,
    requiredLevel: 3,
    xpReward: 20.0,
    slots: [
      RecipeSlot(
        quantity: 3,
        acceptedItems: [
          SlotChoice(itemId: 'wildflower', qualityBias: 0.0),
        ],
      ),
      RecipeSlot(
        quantity: 2,
        acceptedItems: [
          SlotChoice(itemId: 'wild_berries', qualityBias: 0.0),
        ],
      ),
    ],
    modifierSlot: defaultModifier,
    stationId: 'field_kitchen',
    requiredStationTier: 1,
    energyCost: 4,
    durationSeconds: 4,
  );

  static const Recipe elixirOfLife2 = Recipe(
    id: 'elixir_2',
    name: 'Elixir of Life II',
    icon: '🧪',
    description: 'An advanced healing potion stabilized with river clay.',
    resultItemId: 'elixir_2',
    resultQuantity: 1,
    requiredSkill: SkillType.herbalism,
    requiredLevel: 7,
    xpReward: 30.0,
    slots: [
      RecipeSlot(
        quantity: 1,
        acceptedItems: [
          SlotChoice(itemId: 'elixir_1', qualityBias: 0.0),
        ],
      ),
      RecipeSlot(
        quantity: 3,
        acceptedItems: [
          SlotChoice(itemId: 'wildflower', qualityBias: 0.0),
        ],
      ),
      RecipeSlot(
        quantity: 2,
        acceptedItems: [
          SlotChoice(itemId: 'river_clay', qualityBias: 0.0),
        ],
      ),
    ],
    modifierSlot: defaultModifier,
    stationId: 'apothecary',
    requiredStationTier: 1,
    energyCost: 6,
    durationSeconds: 5,
  );

  static const Recipe elixirOfLife3 = Recipe(
    id: 'elixir_3',
    name: 'Elixir of Life III',
    icon: '🧪',
    description: 'A powerful healing potion infused with nightshade extract.',
    resultItemId: 'elixir_3',
    resultQuantity: 1,
    requiredSkill: SkillType.herbalism,
    requiredLevel: 12,
    xpReward: 45.0,
    slots: [
      RecipeSlot(
        quantity: 1,
        acceptedItems: [
          SlotChoice(itemId: 'elixir_2', qualityBias: 0.0),
        ],
      ),
      RecipeSlot(
        quantity: 2,
        acceptedItems: [
          SlotChoice(itemId: 'nightshade', qualityBias: 0.0),
        ],
      ),
    ],
    modifierSlot: defaultModifier,
    stationId: 'apothecary',
    requiredStationTier: 2,
    energyCost: 8,
    durationSeconds: 6,
  );

  static const Recipe philterOfClarity = Recipe(
    id: 'philter_of_clarity',
    name: 'Philter of Clarity',
    icon: '🧪',
    description: 'A glowing lavender potion that restores substantial energy.',
    resultItemId: 'philter_of_clarity',
    resultQuantity: 1,
    requiredSkill: SkillType.herbalism,
    requiredLevel: 10,
    xpReward: 35.0,
    slots: [
      RecipeSlot(
        quantity: 2,
        acceptedItems: [
          SlotChoice(itemId: 'nightshade', qualityBias: 0.0),
        ],
      ),
      RecipeSlot(
        quantity: 3,
        acceptedItems: [
          SlotChoice(itemId: 'wild_berries', qualityBias: 0.0),
        ],
      ),
    ],
    modifierSlot: defaultModifier,
    stationId: 'apothecary',
    requiredStationTier: 2,
    energyCost: 5,
    durationSeconds: 4,
  );

  // ==========================================
  // 5. LORE GLYPHS (Bench T1 / T2 / T3)
  // ==========================================
  static const Recipe glyphSwiftness = Recipe(
    id: 'glyph_swiftness',
    name: 'Glyph of Swiftness',
    icon: '🪨',
    description: 'A clay tablet carved with runes of speed.',
    resultItemId: 'glyph_swiftness',
    resultQuantity: 1,
    requiredSkill: SkillType.lore,
    requiredLevel: 5,
    xpReward: 25.0,
    slots: [
      RecipeSlot(
        quantity: 2,
        acceptedItems: [
          SlotChoice(itemId: 'river_clay', qualityBias: 0.0),
        ],
      ),
      RecipeSlot(
        quantity: 2,
        acceptedItems: [
          SlotChoice(itemId: 'wildflower', qualityBias: 0.0),
        ],
      ),
    ],
    modifierSlot: defaultModifier,
    stationId: 'crafting_bench',
    requiredStationTier: 1,
    energyCost: 5,
    durationSeconds: 4,
  );

  static const Recipe glyphFortitude = Recipe(
    id: 'glyph_fortitude',
    name: 'Glyph of Fortitude',
    icon: '🪨',
    description: 'A clay tablet carved with runes of protection.',
    resultItemId: 'glyph_fortitude',
    resultQuantity: 1,
    requiredSkill: SkillType.lore,
    requiredLevel: 10,
    xpReward: 35.0,
    slots: [
      RecipeSlot(
        quantity: 3,
        acceptedItems: [
          SlotChoice(itemId: 'river_clay', qualityBias: 0.0),
        ],
      ),
      RecipeSlot(
        quantity: 1,
        acceptedItems: [
          SlotChoice(itemId: 'nightshade', qualityBias: 0.0),
        ],
      ),
    ],
    modifierSlot: defaultModifier,
    stationId: 'crafting_bench',
    requiredStationTier: 2,
    energyCost: 6,
    durationSeconds: 5,
  );

  // ==========================================
  // 6. WEAPONS & ARMOR (Bench T1 / T2 / T3)
  // ==========================================
  static const Recipe bronzeSword = Recipe(
    id: 'bronze_sword',
    name: 'Bronze Sword',
    icon: '⚔️',
    description: 'Forge a sharp bronze sword from bronze ingots.',
    resultItemId: 'bronze_sword',
    resultQuantity: 1,
    requiredSkill: SkillType.crafting,
    requiredLevel: 3,
    xpReward: 35.0,
    slots: [
      RecipeSlot(
        quantity: 3,
        acceptedItems: [
          SlotChoice(itemId: 'bronze_ingot', qualityBias: 0.0),
        ],
      ),
      RecipeSlot(
        quantity: 2,
        acceptedItems: [
          SlotChoice(itemId: 'oak_log', qualityBias: 0.0),
          SlotChoice(itemId: 'willow_log', qualityBias: 0.04),
        ],
      ),
    ],
    modifierSlot: defaultModifier,
    stationId: 'crafting_bench',
    requiredStationTier: 1,
    energyCost: 6,
    durationSeconds: 4,
  );

  static const Recipe ironSword = Recipe(
    id: 'iron_sword',
    name: 'Iron Sword',
    icon: '⚔️',
    description: 'Forge a heavy iron sword from iron ingots.',
    resultItemId: 'iron_sword',
    resultQuantity: 1,
    requiredSkill: SkillType.crafting,
    requiredLevel: 7,
    xpReward: 60.0,
    slots: [
      RecipeSlot(
        quantity: 3,
        acceptedItems: [
          SlotChoice(itemId: 'iron_ingot', qualityBias: 0.0),
        ],
      ),
      RecipeSlot(
        quantity: 2,
        acceptedItems: [
          SlotChoice(itemId: 'willow_log', qualityBias: 0.0),
          SlotChoice(itemId: 'oak_log', qualityBias: -0.05),
        ],
      ),
    ],
    modifierSlot: defaultModifier,
    stationId: 'crafting_bench',
    requiredStationTier: 2,
    energyCost: 8,
    durationSeconds: 5,
  );

  static const Recipe steelGreatsword = Recipe(
    id: 'steel_greatsword',
    name: 'Steel Greatsword',
    icon: '⚔️',
    description: 'Forge a legendary steel greatsword from steel ingots.',
    resultItemId: 'steel_greatsword',
    resultQuantity: 1,
    requiredSkill: SkillType.crafting,
    requiredLevel: 15,
    xpReward: 120.0,
    slots: [
      RecipeSlot(
        quantity: 4,
        acceptedItems: [
          SlotChoice(itemId: 'steel_ingot', qualityBias: 0.0),
        ],
      ),
      RecipeSlot(
        quantity: 3,
        acceptedItems: [
          SlotChoice(itemId: 'willow_log', qualityBias: 0.0),
        ],
      ),
      RecipeSlot(
        quantity: 1,
        acceptedItems: [
          SlotChoice(itemId: 'cured_leather', qualityBias: 0.0),
        ],
      ),
    ],
    modifierSlot: defaultModifier,
    stationId: 'crafting_bench',
    requiredStationTier: 3,
    rarity: RecipeRarity.rare,
    energyCost: 12,
    durationSeconds: 7,
  );

  static const Recipe leatherChest = Recipe(
    id: 'leather_chest',
    name: 'Leather Jerkin',
    icon: '🛡️',
    description: 'Sew a light cured leather chestpiece.',
    resultItemId: 'leather_chest',
    resultQuantity: 1,
    requiredSkill: SkillType.crafting,
    requiredLevel: 2,
    xpReward: 25.0,
    slots: [
      RecipeSlot(
        quantity: 3,
        acceptedItems: [
          SlotChoice(itemId: 'cured_leather', qualityBias: 0.0),
        ],
      ),
      RecipeSlot(
        quantity: 2,
        acceptedItems: [
          SlotChoice(itemId: 'wild_berries', qualityBias: 0.0),
        ],
      ),
    ],
    modifierSlot: defaultModifier,
    stationId: 'crafting_bench',
    requiredStationTier: 1,
    energyCost: 5,
    durationSeconds: 4,
  );

  static const Recipe bronzeChest = Recipe(
    id: 'bronze_chest',
    name: 'Bronze Scale',
    icon: '🛡️',
    description: 'Forge scales of bronze over a leather lining.',
    resultItemId: 'bronze_chest',
    resultQuantity: 1,
    requiredSkill: SkillType.crafting,
    requiredLevel: 5,
    xpReward: 45.0,
    slots: [
      RecipeSlot(
        quantity: 4,
        acceptedItems: [
          SlotChoice(itemId: 'bronze_ingot', qualityBias: 0.0),
        ],
      ),
      RecipeSlot(
        quantity: 2,
        acceptedItems: [
          SlotChoice(itemId: 'cured_leather', qualityBias: 0.0),
        ],
      ),
    ],
    modifierSlot: defaultModifier,
    stationId: 'crafting_bench',
    requiredStationTier: 1,
    energyCost: 7,
    durationSeconds: 5,
  );

  static const Recipe steelPlate = Recipe(
    id: 'steel_plate',
    name: 'Steel Cuirass',
    icon: '🛡️',
    description: 'Forge heavy steel plate armor reinforced with silk.',
    resultItemId: 'steel_plate',
    resultQuantity: 1,
    requiredSkill: SkillType.crafting,
    requiredLevel: 12,
    xpReward: 100.0,
    slots: [
      RecipeSlot(
        quantity: 5,
        acceptedItems: [
          SlotChoice(itemId: 'steel_ingot', qualityBias: 0.0),
        ],
      ),
      RecipeSlot(
        quantity: 2,
        acceptedItems: [
          SlotChoice(itemId: 'treated_silk', qualityBias: 0.0),
        ],
      ),
    ],
    modifierSlot: defaultModifier,
    stationId: 'crafting_bench',
    requiredStationTier: 2,
    rarity: RecipeRarity.rare,
    energyCost: 10,
    durationSeconds: 6,
  );

  // ==========================================
  // 7. NEW SPECIALISTS INTERMEDIATES (Smelter/Tannery)
  // ==========================================
  static const Recipe copperIngot = Recipe(
    id: 'copper_ingot',
    name: 'Copper Ingot',
    icon: '🪙',
    description: 'Smelt raw copper ore into a refined ingot.',
    resultItemId: 'copper_ingot',
    resultQuantity: 1,
    requiredSkill: SkillType.crafting,
    requiredLevel: 3,
    xpReward: 12.0,
    slots: [
      RecipeSlot(
        quantity: 3,
        acceptedItems: [
          SlotChoice(itemId: 'copper_ore', qualityBias: 0.0),
        ],
      ),
    ],
    modifierSlot: defaultModifier,
    stationId: 'smelter',
    requiredStationTier: 1,
    energyCost: 3,
    durationSeconds: 5,
  );

  static const Recipe tinIngot = Recipe(
    id: 'tin_ingot',
    name: 'Tin Ingot',
    icon: '🪙',
    description: 'Smelt raw tin ore into a refined ingot.',
    resultItemId: 'tin_ingot',
    resultQuantity: 1,
    requiredSkill: SkillType.crafting,
    requiredLevel: 5,
    xpReward: 15.0,
    slots: [
      RecipeSlot(
        quantity: 3,
        acceptedItems: [
          SlotChoice(itemId: 'tin_ore', qualityBias: 0.0),
        ],
      ),
    ],
    modifierSlot: defaultModifier,
    stationId: 'smelter',
    requiredStationTier: 1,
    energyCost: 3,
    durationSeconds: 6,
  );

  static const Recipe bronzeIngot = Recipe(
    id: 'bronze_ingot_recipe',
    name: 'Bronze Ingot',
    icon: '🪙',
    description: 'Smelt copper and tin ores into a strong bronze alloy.',
    resultItemId: 'bronze_ingot',
    resultQuantity: 1,
    requiredSkill: SkillType.crafting,
    requiredLevel: 6,
    xpReward: 20.0,
    slots: [
      RecipeSlot(
        quantity: 2,
        acceptedItems: [
          SlotChoice(itemId: 'copper_ore', qualityBias: 0.0),
        ],
      ),
      RecipeSlot(
        quantity: 1,
        acceptedItems: [
          SlotChoice(itemId: 'tin_ore', qualityBias: 0.0),
        ],
      ),
    ],
    modifierSlot: defaultModifier,
    stationId: 'smelter',
    requiredStationTier: 1,
    energyCost: 4,
    durationSeconds: 8,
  );

  static const Recipe ironIngot = Recipe(
    id: 'iron_ingot',
    name: 'Iron Ingot',
    icon: '🪙',
    description: 'Smelt raw iron ore into a heavy ingot.',
    resultItemId: 'iron_ingot',
    resultQuantity: 1,
    requiredSkill: SkillType.crafting,
    requiredLevel: 8,
    xpReward: 25.0,
    slots: [
      RecipeSlot(
        quantity: 3,
        acceptedItems: [
          SlotChoice(itemId: 'iron_ore', qualityBias: 0.0),
        ],
      ),
    ],
    modifierSlot: defaultModifier,
    stationId: 'smelter',
    requiredStationTier: 2,
    energyCost: 5,
    durationSeconds: 10,
  );

  static const Recipe steelIngot = Recipe(
    id: 'steel_ingot',
    name: 'Steel Ingot',
    icon: '🪙',
    description: 'Refine iron ore into a resilient steel ingot.',
    resultItemId: 'steel_ingot',
    resultQuantity: 1,
    requiredSkill: SkillType.crafting,
    requiredLevel: 12,
    xpReward: 40.0,
    slots: [
      RecipeSlot(
        quantity: 3,
        acceptedItems: [
          SlotChoice(itemId: 'iron_ore', qualityBias: 0.0),
        ],
      ),
      RecipeSlot(
        quantity: 1,
        acceptedItems: [
          SlotChoice(itemId: 'river_clay', qualityBias: 0.0),
        ],
      ),
    ],
    modifierSlot: defaultModifier,
    stationId: 'smelter',
    requiredStationTier: 3,
    energyCost: 6,
    durationSeconds: 15,
  );

  static const Recipe curedLeather = Recipe(
    id: 'cured_leather_recipe',
    name: 'Cured Leather',
    icon: '💼',
    description: 'Tan beast pelt into durable leather.',
    resultItemId: 'cured_leather',
    resultQuantity: 1,
    requiredSkill: SkillType.crafting,
    requiredLevel: 3,
    xpReward: 15.0,
    slots: [
      RecipeSlot(
        quantity: 1,
        acceptedItems: [
          SlotChoice(itemId: 'wolf_pelt', qualityBias: 0.0),
        ],
      ),
      RecipeSlot(
        quantity: 1,
        acceptedItems: [
          SlotChoice(itemId: 'river_clay', qualityBias: 0.0),
        ],
      ),
    ],
    modifierSlot: defaultModifier,
    stationId: 'tannery',
    requiredStationTier: 1,
    energyCost: 3,
    durationSeconds: 6,
  );

  static const Recipe treatedSilk = Recipe(
    id: 'treated_silk_recipe',
    name: 'Treated Silk',
    icon: '🧵',
    description: 'Treat spider silk with wild berries to make treated silk thread.',
    resultItemId: 'treated_silk',
    resultQuantity: 1,
    requiredSkill: SkillType.crafting,
    requiredLevel: 8,
    xpReward: 25.0,
    slots: [
      RecipeSlot(
        quantity: 2,
        acceptedItems: [
          SlotChoice(itemId: 'spider_silk', qualityBias: 0.0),
        ],
      ),
      RecipeSlot(
        quantity: 1,
        acceptedItems: [
          SlotChoice(itemId: 'wild_berries', qualityBias: 0.0),
        ],
      ),
    ],
    modifierSlot: defaultModifier,
    stationId: 'tannery',
    requiredStationTier: 2,
    energyCost: 4,
    durationSeconds: 10,
  );

  // ==========================================
  // 8. NEW LEGENDARY BLUEPRINT RECIPES (Bench T3 / Apothecary T3)
  // ==========================================
  static const Recipe greaterSteelGreatsword = Recipe(
    id: 'greater_steel_greatsword',
    name: 'Greater Steel Greatsword',
    icon: '⚔️',
    description: 'A legendary massive blade forged of steel and troll claws.',
    resultItemId: 'greater_steel_greatsword',
    resultQuantity: 1,
    requiredSkill: SkillType.crafting,
    requiredLevel: 15,
    xpReward: 250.0,
    slots: [
      RecipeSlot(
        quantity: 6,
        acceptedItems: [
          SlotChoice(itemId: 'steel_ingot', qualityBias: 0.0),
        ],
      ),
      RecipeSlot(
        quantity: 4,
        acceptedItems: [
          SlotChoice(itemId: 'willow_log', qualityBias: 0.0),
        ],
      ),
      RecipeSlot(
        quantity: 2,
        acceptedItems: [
          SlotChoice(itemId: 'cured_leather', qualityBias: 0.0),
        ],
      ),
      RecipeSlot(
        quantity: 2,
        acceptedItems: [
          SlotChoice(itemId: 'troll_claw', qualityBias: 0.0),
        ],
      ),
    ],
    modifierSlot: defaultModifier,
    stationId: 'crafting_bench',
    requiredStationTier: 3,
    rarity: RecipeRarity.legendary,
    energyCost: 15,
    durationSeconds: 10,
  );

  static const Recipe elixirOfLife4 = Recipe(
    id: 'elixir_4',
    name: "Alchemist's Elixir IV",
    icon: '🧪',
    description: 'A supreme elixir that restores immense health and energy.',
    resultItemId: 'elixir_4',
    resultQuantity: 1,
    requiredSkill: SkillType.herbalism,
    requiredLevel: 15,
    xpReward: 200.0,
    slots: [
      RecipeSlot(
        quantity: 1,
        acceptedItems: [
          SlotChoice(itemId: 'elixir_3', qualityBias: 0.0),
        ],
      ),
      RecipeSlot(
        quantity: 3,
        acceptedItems: [
          SlotChoice(itemId: 'nightshade', qualityBias: 0.0),
        ],
      ),
      RecipeSlot(
        quantity: 1,
        acceptedItems: [
          SlotChoice(itemId: 'spider_fang', qualityBias: 0.0),
        ],
      ),
    ],
    modifierSlot: defaultModifier,
    stationId: 'apothecary',
    requiredStationTier: 3,
    rarity: RecipeRarity.legendary,
    energyCost: 12,
    durationSeconds: 8,
  );

  static const Recipe glyphMastery = Recipe(
    id: 'glyph_mastery',
    name: 'Glyph of Mastery',
    icon: '🪨',
    description: 'A legendary runic glyph containing pure mastery.',
    resultItemId: 'glyph_mastery',
    resultQuantity: 1,
    requiredSkill: SkillType.lore,
    requiredLevel: 15,
    xpReward: 200.0,
    slots: [
      RecipeSlot(
        quantity: 5,
        acceptedItems: [
          SlotChoice(itemId: 'river_clay', qualityBias: 0.0),
        ],
      ),
      RecipeSlot(
        quantity: 3,
        acceptedItems: [
          SlotChoice(itemId: 'nightshade', qualityBias: 0.0),
        ],
      ),
      RecipeSlot(
        quantity: 1,
        acceptedItems: [
          SlotChoice(itemId: 'troll_claw', qualityBias: 0.0),
        ],
      ),
    ],
    modifierSlot: defaultModifier,
    stationId: 'crafting_bench',
    requiredStationTier: 3,
    rarity: RecipeRarity.legendary,
    energyCost: 12,
    durationSeconds: 8,
  );

  static Recipe getBackpackRecipe(int capacity) {
    if (capacity < 8) {
      return const Recipe(
        id: 'leather_backpack',
        name: 'Leather Backpack',
        icon: '🎒',
        description: 'Craft a sturdy backpack to expand inventory to 8 slots.',
        resultItemId: 'leather_backpack',
        resultQuantity: 1,
        requiredSkill: SkillType.crafting,
        requiredLevel: 5,
        xpReward: 40.0,
        slots: [
          RecipeSlot(
            quantity: 10,
            acceptedItems: [SlotChoice(itemId: 'oak_log', qualityBias: 0.0)],
          ),
          RecipeSlot(
            quantity: 5,
            acceptedItems: [SlotChoice(itemId: 'river_clay', qualityBias: 0.0)],
          ),
        ],
        stationId: 'crafting_bench',
        requiredStationTier: 1,
        energyCost: 10,
        durationSeconds: 6,
      );
    } else {
      final tier = capacity - 7;
      final requiredLevel = 5 + (capacity - 8) * 2;
      final List<RecipeSlot> slots = [];

      if (capacity == 8) {
        slots.add(const RecipeSlot(quantity: 15, acceptedItems: [SlotChoice(itemId: 'oak_log', qualityBias: 0.0)]));
        slots.add(const RecipeSlot(quantity: 10, acceptedItems: [SlotChoice(itemId: 'river_clay', qualityBias: 0.0)]));
        slots.add(const RecipeSlot(quantity: 5, acceptedItems: [SlotChoice(itemId: 'copper_ingot', qualityBias: 0.0)]));
      } else if (capacity == 9) {
        slots.add(const RecipeSlot(quantity: 20, acceptedItems: [SlotChoice(itemId: 'willow_log', qualityBias: 0.0)]));
        slots.add(const RecipeSlot(quantity: 15, acceptedItems: [SlotChoice(itemId: 'river_clay', qualityBias: 0.0)]));
        slots.add(const RecipeSlot(quantity: 5, acceptedItems: [SlotChoice(itemId: 'tin_ingot', qualityBias: 0.0)]));
      } else if (capacity == 10) {
        slots.add(const RecipeSlot(quantity: 25, acceptedItems: [SlotChoice(itemId: 'willow_log', qualityBias: 0.0)]));
        slots.add(const RecipeSlot(quantity: 10, acceptedItems: [SlotChoice(itemId: 'iron_ingot', qualityBias: 0.0)]));
      } else {
        slots.add(RecipeSlot(quantity: 25 + (capacity - 10) * 5, acceptedItems: [const SlotChoice(itemId: 'willow_log', qualityBias: 0.0)]));
        slots.add(RecipeSlot(quantity: 10 + (capacity - 10) * 5, acceptedItems: [const SlotChoice(itemId: 'iron_ingot', qualityBias: 0.0)]));
      }

      return Recipe(
        id: 'backpack_upgrade',
        name: 'Backpack Upgrade (Tier $tier)',
        icon: '🎒',
        description: 'Expand your backpack capacity by +1 slot.',
        resultItemId: 'backpack_upgrade',
        resultQuantity: 1,
        requiredSkill: SkillType.crafting,
        requiredLevel: requiredLevel,
        xpReward: 50.0 + (capacity - 8) * 10.0,
        slots: slots,
        stationId: 'crafting_bench',
        requiredStationTier: 1,
        energyCost: 10,
        durationSeconds: 6,
      );
    }
  }

  static const List<Recipe> all = [
    stoneAxe,
    stonePickaxe,
    foragingGloves,
    copperAxe,
    bronzeAxe,
    ironAxe,
    copperPickaxe,
    bronzePickaxe,
    ironPickaxe,
    reinforcedGloves,
    masterworkGloves,
    bakedPotato,
    butteredPotato,
    loadedPotato,
    cookedTrout,
    smokedTrout,
    herbalTea,
    spicedTea,
    elixirOfLife1,
    elixirOfLife2,
    elixirOfLife3,
    philterOfClarity,
    glyphSwiftness,
    glyphFortitude,
    bronzeSword,
    ironSword,
    steelGreatsword,
    leatherChest,
    bronzeChest,
    steelPlate,
    copperIngot,
    tinIngot,
    bronzeIngot,
    ironIngot,
    steelIngot,
    curedLeather,
    treatedSilk,
    greaterSteelGreatsword,
    elixirOfLife4,
    glyphMastery,
  ];

  static Recipe? findById(String id) {
    try {
      if (id == 'leather_backpack' || id == 'backpack_upgrade') {
        return getBackpackRecipe(id == 'leather_backpack' ? 4 : 8);
      }
      return all.firstWhere((recipe) => recipe.id == id);
    } catch (_) {
      return null;
    }
  }
}
