import 'skill.dart';
import 'item.dart';

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
  final Map<String, int> inputs; // itemId -> quantity
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
    required this.inputs,
    required this.energyCost,
    required this.durationSeconds,
  });

  Item? get resultItem => Items.findById(resultItemId);
}

class Recipes {
  // Basic Tools
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
    inputs: {'oak_log': 3, 'river_clay': 2},
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
    inputs: {'oak_log': 3, 'river_clay': 2},
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
    inputs: {'wildflower': 3, 'river_clay': 2},
    energyCost: 3,
    durationSeconds: 3,
  );

  // Woodcutting Tools
  static const Recipe copperAxe = Recipe(
    id: 'copper_axe',
    name: 'Copper Axe',
    icon: '🪓',
    description: 'Upgrade your Stone Axe with copper ore.',
    resultItemId: 'copper_axe',
    resultQuantity: 1,
    requiredSkill: SkillType.crafting,
    requiredLevel: 5,
    xpReward: 30.0,
    inputs: {'stone_axe': 1, 'copper_ore': 5, 'oak_log': 5},
    energyCost: 6,
    durationSeconds: 4,
  );

  static const Recipe bronzeAxe = Recipe(
    id: 'bronze_axe',
    name: 'Bronze Axe',
    icon: '🪓',
    description: 'Upgrade your Copper Axe with copper and tin ore.',
    resultItemId: 'bronze_axe',
    resultQuantity: 1,
    requiredSkill: SkillType.crafting,
    requiredLevel: 8,
    xpReward: 40.0,
    inputs: {'copper_axe': 1, 'tin_ore': 5, 'oak_log': 5},
    energyCost: 8,
    durationSeconds: 5,
  );

  static const Recipe ironAxe = Recipe(
    id: 'iron_axe',
    name: 'Iron Axe',
    icon: '🪓',
    description: 'Upgrade your Bronze Axe with iron ore and willow logs.',
    resultItemId: 'iron_axe',
    resultQuantity: 1,
    requiredSkill: SkillType.crafting,
    requiredLevel: 12,
    xpReward: 50.0,
    inputs: {'bronze_axe': 1, 'iron_ore': 5, 'willow_log': 5},
    energyCost: 10,
    durationSeconds: 6,
  );

  // Mining Tools
  static const Recipe copperPickaxe = Recipe(
    id: 'copper_pickaxe',
    name: 'Copper Pickaxe',
    icon: '⛏️',
    description: 'Upgrade your Stone Pickaxe with copper ore.',
    resultItemId: 'copper_pickaxe',
    resultQuantity: 1,
    requiredSkill: SkillType.crafting,
    requiredLevel: 5,
    xpReward: 30.0,
    inputs: {'stone_pickaxe': 1, 'copper_ore': 5, 'oak_log': 5},
    energyCost: 6,
    durationSeconds: 4,
  );

  static const Recipe bronzePickaxe = Recipe(
    id: 'bronze_pickaxe',
    name: 'Bronze Pickaxe',
    icon: '⛏️',
    description: 'Upgrade your Copper Pickaxe with copper and tin ore.',
    resultItemId: 'bronze_pickaxe',
    resultQuantity: 1,
    requiredSkill: SkillType.crafting,
    requiredLevel: 8,
    xpReward: 40.0,
    inputs: {'copper_pickaxe': 1, 'tin_ore': 5, 'oak_log': 5},
    energyCost: 8,
    durationSeconds: 5,
  );

  static const Recipe ironPickaxe = Recipe(
    id: 'iron_pickaxe',
    name: 'Iron Pickaxe',
    icon: '⛏️',
    description: 'Upgrade your Bronze Pickaxe with iron ore and willow logs.',
    resultItemId: 'iron_pickaxe',
    resultQuantity: 1,
    requiredSkill: SkillType.crafting,
    requiredLevel: 12,
    xpReward: 50.0,
    inputs: {'bronze_pickaxe': 1, 'iron_ore': 5, 'willow_log': 5},
    energyCost: 10,
    durationSeconds: 6,
  );

  // Foraging Gloves
  static const Recipe reinforcedGloves = Recipe(
    id: 'reinforced_gloves',
    name: 'Reinforced Gloves',
    icon: '🧤',
    description: 'Upgrade your Foraging Gloves with clay and wildflowers.',
    resultItemId: 'reinforced_gloves',
    resultQuantity: 1,
    requiredSkill: SkillType.crafting,
    requiredLevel: 7,
    xpReward: 35.0,
    inputs: {'foraging_gloves': 1, 'river_clay': 5, 'wildflower': 3},
    energyCost: 8,
    durationSeconds: 5,
  );

  static const Recipe masterworkGloves = Recipe(
    id: 'masterwork_gloves',
    name: 'Masterwork Gloves',
    icon: '🧤',
    description: 'Upgrade your Reinforced Gloves with nightshade and willow.',
    resultItemId: 'masterwork_gloves',
    resultQuantity: 1,
    requiredSkill: SkillType.crafting,
    requiredLevel: 12,
    xpReward: 60.0,
    inputs: {'reinforced_gloves': 1, 'nightshade': 3, 'willow_log': 5},
    energyCost: 12,
    durationSeconds: 6,
  );

  // Cooking (Potatoes)
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
    inputs: {'raw_potato': 1, 'oak_log': 1},
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
    inputs: {'baked_potato': 1, 'wildflower': 2},
    energyCost: 2,
    durationSeconds: 3,
  );

  static const Recipe loadedPotato = Recipe(
    id: 'loaded_potato',
    name: 'Loaded Potato',
    icon: '🥔',
    description: 'Upgrade buttered potato with cooked trout bacon.',
    resultItemId: 'loaded_potato',
    resultQuantity: 1,
    requiredSkill: SkillType.cooking,
    requiredLevel: 10,
    xpReward: 30.0,
    inputs: {'buttered_potato': 1, 'cooked_fish': 1},
    energyCost: 3,
    durationSeconds: 4,
  );

  // Cooking (Trout)
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
    inputs: {'raw_trout': 1, 'oak_log': 1},
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
    inputs: {'cooked_fish': 1, 'willow_log': 2},
    energyCost: 3,
    durationSeconds: 4,
  );

  // Cooking (Tea)
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
    inputs: {'wildflower': 2, 'hot_water': 1},
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
    inputs: {'herbal_tea': 1, 'nightshade': 1},
    energyCost: 3,
    durationSeconds: 3,
  );

  // Herbalism Potions
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
    inputs: {'wildflower': 3, 'wild_berries': 2},
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
    inputs: {'elixir_1': 1, 'wildflower': 3, 'river_clay': 2},
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
    inputs: {'elixir_2': 1, 'nightshade': 2},
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
    inputs: {'nightshade': 2, 'wild_berries': 3},
    energyCost: 5,
    durationSeconds: 4,
  );

  // Lore Glyphs
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
    inputs: {'river_clay': 2, 'wildflower': 2},
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
    inputs: {'river_clay': 3, 'nightshade': 1},
    energyCost: 6,
    durationSeconds: 5,
  );

  // Weapons
  static const Recipe bronzeSword = Recipe(
    id: 'bronze_sword',
    name: 'Bronze Sword',
    icon: '⚔️',
    description: 'Forge a sharp bronze sword from copper and tin.',
    resultItemId: 'bronze_sword',
    resultQuantity: 1,
    requiredSkill: SkillType.crafting,
    requiredLevel: 3,
    xpReward: 35.0,
    inputs: {'copper_ore': 5, 'tin_ore': 3, 'oak_log': 2},
    energyCost: 6,
    durationSeconds: 4,
  );

  static const Recipe ironSword = Recipe(
    id: 'iron_sword',
    name: 'Iron Sword',
    icon: '⚔️',
    description: 'Forge a heavy iron sword.',
    resultItemId: 'iron_sword',
    resultQuantity: 1,
    requiredSkill: SkillType.crafting,
    requiredLevel: 7,
    xpReward: 60.0,
    inputs: {'iron_ore': 6, 'willow_log': 3, 'river_clay': 1},
    energyCost: 8,
    durationSeconds: 5,
  );

  static const Recipe steelGreatsword = Recipe(
    id: 'steel_greatsword',
    name: 'Steel Greatsword',
    icon: '⚔️',
    description: 'Forge a legendary greatsword.',
    resultItemId: 'steel_greatsword',
    resultQuantity: 1,
    requiredSkill: SkillType.crafting,
    requiredLevel: 15,
    xpReward: 120.0,
    inputs: {'iron_ore': 12, 'willow_log': 4, 'river_clay': 3, 'troll_claw': 1},
    energyCost: 12,
    durationSeconds: 7,
  );

  // Armor
  static const Recipe leatherChest = Recipe(
    id: 'leather_chest',
    name: 'Leather Jerkin',
    icon: '🛡️',
    description: 'Sew a light leather vest.',
    resultItemId: 'leather_chest',
    resultQuantity: 1,
    requiredSkill: SkillType.crafting,
    requiredLevel: 2,
    xpReward: 25.0,
    inputs: {'wild_berries': 4, 'wolf_pelt': 2},
    energyCost: 5,
    durationSeconds: 4,
  );

  static const Recipe bronzeChest = Recipe(
    id: 'bronze_chest',
    name: 'Bronze Scale',
    icon: '🛡️',
    description: 'Forge bronze plate mail.',
    resultItemId: 'bronze_chest',
    resultQuantity: 1,
    requiredSkill: SkillType.crafting,
    requiredLevel: 5,
    xpReward: 45.0,
    inputs: {'copper_ore': 8, 'tin_ore': 4, 'river_clay': 2},
    energyCost: 7,
    durationSeconds: 5,
  );

  static const Recipe steelPlate = Recipe(
    id: 'steel_plate',
    name: 'Steel Cuirass',
    icon: '🛡️',
    description: 'Forge heavy steel plate armor.',
    resultItemId: 'steel_plate',
    resultQuantity: 1,
    requiredSkill: SkillType.crafting,
    requiredLevel: 12,
    xpReward: 100.0,
    inputs: {'iron_ore': 12, 'river_clay': 4, 'spider_silk': 2},
    energyCost: 10,
    durationSeconds: 6,
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
        inputs: {'oak_log': 10, 'river_clay': 5},
        energyCost: 8,
        durationSeconds: 6,
      );
    } else {
      final tier = capacity - 7;
      final requiredLevel = 5 + (capacity - 8) * 2;
      final Map<String, int> inputs = {};

      if (capacity == 8) {
        inputs['oak_log'] = 15;
        inputs['river_clay'] = 10;
        inputs['copper_ore'] = 5;
      } else if (capacity == 9) {
        inputs['willow_log'] = 20;
        inputs['river_clay'] = 15;
        inputs['tin_ore'] = 5;
      } else if (capacity == 10) {
        inputs['willow_log'] = 25;
        inputs['iron_ore'] = 10;
      } else {
        inputs['willow_log'] = 25 + (capacity - 10) * 5;
        inputs['iron_ore'] = 10 + (capacity - 10) * 5;
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
        inputs: inputs,
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
  ];

  static Recipe? findById(String id) {
    try {
      if (id == 'leather_backpack' || id == 'backpack_upgrade') {
        // Return a dynamic backpack recipe matching some standard capacity
        // e.g. starting capacity 4 or 8.
        return getBackpackRecipe(id == 'leather_backpack' ? 4 : 8);
      }
      return all.firstWhere((recipe) => recipe.id == id);
    } catch (_) {
      return null;
    }
  }
}
