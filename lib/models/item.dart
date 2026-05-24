import 'skill.dart';

enum ItemType {
  resource,
  food,
  tool,
  weapon,
  armor,
  blueprint,
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

  // Combat specific fields
  final int attackPower;
  final int defense;

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
    this.attackPower = 0,
    this.defense = 0,
  });

  bool get isFood => type == ItemType.food;
  bool get isTool => type == ItemType.tool;
  bool get isWeapon => type == ItemType.weapon;
  bool get isArmor => type == ItemType.armor;
  bool get isBlueprint => type == ItemType.blueprint;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Item && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class BlueprintItem extends Item {
  final String recipeId;

  const BlueprintItem({
    required String id,
    required String name,
    required String description,
    required String icon,
    required int value,
    required this.recipeId,
  }) : super(
          id: id,
          name: name,
          description: description,
          icon: icon,
          type: ItemType.blueprint,
          value: value,
        );
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

  static const Item philterOfClarity = Item(
    id: 'philter_of_clarity',
    name: 'Philter of Clarity',
    description: 'A glowing lavender potion that restores substantial energy.',
    icon: '🧪',
    type: ItemType.food,
    value: 50,
    healAmount: 0,
    energyAmount: 50,
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

  static const Item rawTrout = Item(
    id: 'raw_trout',
    name: 'Raw Trout',
    description: 'A fresh trout caught from the riverbed.',
    icon: '🐟',
    type: ItemType.resource,
    value: 5,
  );

  static const Item rawPotato = Item(
    id: 'raw_potato',
    name: 'Raw Potato',
    description: 'A freshly dug potato. Needs to be cooked to eat safely.',
    icon: '🥔',
    type: ItemType.resource,
    value: 3,
  );

  static const Item hotWater = Item(
    id: 'hot_water',
    name: 'Hot Water',
    description: 'A pot of boiling water for brewing teas.',
    icon: '🍵',
    type: ItemType.resource,
    value: 2,
  );

  static const Item leatherBackpack = Item(
    id: 'leather_backpack',
    name: 'Leather Backpack',
    description: 'A spacious backpack. Use it to permanently increase inventory capacity by 4 slots.',
    icon: '🎒',
    type: ItemType.tool,
    value: 300,
  );

  static const Item backpackUpgrade = Item(
    id: 'backpack_upgrade',
    name: 'Backpack Upgrade',
    description: 'A modular upgrade for your backpack. Use it to permanently increase inventory capacity by 1 slot.',
    icon: '🎒',
    type: ItemType.tool,
    value: 400,
  );

  // Upgraded Tools
  static const Item copperAxe = Item(
    id: 'copper_axe',
    name: 'Copper Axe',
    description: 'A refined copper axe. Better than stone.',
    icon: '🪓',
    type: ItemType.tool,
    value: 100,
    toolSkill: SkillType.woodcutting,
    speedBonus: 0.10,
    successBonus: 0.08,
  );

  static const Item copperPickaxe = Item(
    id: 'copper_pickaxe',
    name: 'Copper Pickaxe',
    description: 'A refined copper pickaxe. Better than stone.',
    icon: '⛏️',
    type: ItemType.tool,
    value: 100,
    toolSkill: SkillType.mining,
    speedBonus: 0.10,
    successBonus: 0.08,
  );

  static const Item bronzeAxe = Item(
    id: 'bronze_axe',
    name: 'Bronze Axe',
    description: 'A sharp bronze axe forged from copper and tin.',
    icon: '🪓',
    type: ItemType.tool,
    value: 150,
    toolSkill: SkillType.woodcutting,
    speedBonus: 0.14,
    successBonus: 0.10,
  );

  static const Item bronzePickaxe = Item(
    id: 'bronze_pickaxe',
    name: 'Bronze Pickaxe',
    description: 'A sturdy bronze pickaxe forged from copper and tin.',
    icon: '⛏️',
    type: ItemType.tool,
    value: 150,
    toolSkill: SkillType.mining,
    speedBonus: 0.14,
    successBonus: 0.10,
  );

  static const Item reinforcedGloves = Item(
    id: 'reinforced_gloves',
    name: 'Reinforced Gloves',
    description: 'Sturdier gloves with reinforced leather.',
    icon: '🧤',
    type: ItemType.tool,
    value: 200,
    toolSkill: SkillType.herbalism,
    speedBonus: 0.18,
    successBonus: 0.15,
  );

  static const Item masterworkGloves = Item(
    id: 'masterwork_gloves',
    name: 'Masterwork Gloves',
    description: 'The ultimate foraging gloves woven with nightshade fibers.',
    icon: '🧤',
    type: ItemType.tool,
    value: 350,
    toolSkill: SkillType.herbalism,
    speedBonus: 0.28,
    successBonus: 0.22,
  );

  // Upgraded Foods & Potions
  static const Item butteredPotato = Item(
    id: 'buttered_potato',
    name: 'Buttered Potato',
    description: 'A warm potato glazed with wildflower seasoning.',
    icon: '🥔',
    type: ItemType.food,
    value: 15,
    healAmount: 25,
    energyAmount: 10,
  );

  static const Item loadedPotato = Item(
    id: 'loaded_potato',
    name: 'Loaded Potato',
    description: 'Baked potato topped with wild trout bacon.',
    icon: '🥔',
    type: ItemType.food,
    value: 35,
    healAmount: 45,
    energyAmount: 15,
  );

  static const Item smokedTrout = Item(
    id: 'smoked_trout',
    name: 'Smoked Trout',
    description: 'Fresh trout smoked over willow wood.',
    icon: '🐟',
    type: ItemType.food,
    value: 30,
    healAmount: 50,
    energyAmount: 25,
  );

  static const Item spicedTea = Item(
    id: 'spiced_tea',
    name: 'Spiced Tea',
    description: 'Alertness-boosting tea infused with a drop of nightshade essence.',
    icon: '🍵',
    type: ItemType.food,
    value: 25,
    healAmount: 10,
    energyAmount: 50,
  );

  static const Item elixirOfLife1 = Item(
    id: 'elixir_1',
    name: 'Elixir of Life I',
    description: 'A basic healing potion brewed with forest wildflowers.',
    icon: '🧪',
    type: ItemType.food,
    value: 15,
    healAmount: 25,
    energyAmount: 0,
  );

  static const Item elixirOfLife2 = Item(
    id: 'elixir_2',
    name: 'Elixir of Life II',
    description: 'An advanced healing potion stabilized with river clay.',
    icon: '🧪',
    type: ItemType.food,
    value: 30,
    healAmount: 50,
    energyAmount: 0,
  );

  static const Item elixirOfLife3 = Item(
    id: 'elixir_3',
    name: 'Elixir of Life III',
    description: 'A powerful healing potion infused with nightshade extract.',
    icon: '🧪',
    type: ItemType.food,
    value: 60,
    healAmount: 80,
    energyAmount: 0,
  );

  // Lore Glyphs
  static const Item glyphSwiftness = Item(
    id: 'glyph_swiftness',
    name: 'Glyph of Swiftness',
    description: 'A clay tablet carved with runes of speed.',
    icon: '🪨',
    type: ItemType.food,
    value: 25,
    healAmount: 0,
    energyAmount: 30,
  );

  static const Item glyphFortitude = Item(
    id: 'glyph_fortitude',
    name: 'Glyph of Fortitude',
    description: 'A clay tablet carved with runes of protection.',
    icon: '🪨',
    type: ItemType.food,
    value: 40,
    healAmount: 40,
    energyAmount: 0,
  );

  // Weapons
  static const Item bronzeSword = Item(
    id: 'bronze_sword',
    name: 'Bronze Sword',
    description: 'A sharp bronze sword forged from copper and tin.',
    icon: '⚔️',
    type: ItemType.weapon,
    value: 150,
    attackPower: 8,
  );

  static const Item ironSword = Item(
    id: 'iron_sword',
    name: 'Iron Sword',
    description: 'A heavy iron sword that deals high damage.',
    icon: '⚔️',
    type: ItemType.weapon,
    value: 250,
    attackPower: 16,
  );

  static const Item steelGreatsword = Item(
    id: 'steel_greatsword',
    name: 'Steel Greatsword',
    description: 'A legendary greatsword of immense attack power.',
    icon: '⚔️',
    type: ItemType.weapon,
    value: 500,
    attackPower: 28,
  );

  // Armor
  static const Item leatherChest = Item(
    id: 'leather_chest',
    name: 'Leather Jerkin',
    description: 'A cured leather vest providing basic protection.',
    icon: '🛡️',
    type: ItemType.armor,
    value: 120,
    defense: 2,
  );

  static const Item bronzeChest = Item(
    id: 'bronze_chest',
    name: 'Bronze Scale',
    description: 'A chainmail scale armor made of bronze plates.',
    icon: '🛡️',
    type: ItemType.armor,
    value: 200,
    defense: 5,
  );

  static const Item steelPlate = Item(
    id: 'steel_plate',
    name: 'Steel Cuirass',
    description: 'Heavy steel plate mail offering supreme defense.',
    icon: '🛡️',
    type: ItemType.armor,
    value: 450,
    defense: 10,
  );

  // Monster Drops
  static const Item boarMeat = Item(
    id: 'boar_meat',
    name: 'Boar Meat',
    description: 'Tough wild game meat. Restores health and energy.',
    icon: '🍖',
    type: ItemType.food,
    value: 8,
    healAmount: 20,
    energyAmount: 5,
  );

  static const Item boarTusk = Item(
    id: 'boar_tusk',
    name: 'Boar Tusk',
    description: 'A sharp curved ivory tusk from a forest boar.',
    icon: '🐗',
    type: ItemType.resource,
    value: 10,
  );

  static const Item spiderSilk = Item(
    id: 'spider_silk',
    name: 'Spider Silk',
    description: 'Extraordinarily strong web thread from a cave spider.',
    icon: '🕸️',
    type: ItemType.resource,
    value: 12,
  );

  static const Item spiderFang = Item(
    id: 'spider_fang',
    name: 'Spider Fang',
    description: 'A venom-coated fang from a giant cave spider.',
    icon: '🕷️',
    type: ItemType.resource,
    value: 15,
  );

  static const Item wolfPelt = Item(
    id: 'wolf_pelt',
    name: 'Wolf Pelt',
    description: 'Thick, warm fur pelt from a shadow wolf.',
    icon: '🐺',
    type: ItemType.resource,
    value: 25,
  );

  static const Item trollClaw = Item(
    id: 'troll_claw',
    name: 'Troll Claw',
    description: 'A jagged, stone-hard claw of a cavern troll.',
    icon: '👹',
    type: ItemType.resource,
    value: 45,
  );

  static const Item copperIngot = Item(
    id: 'copper_ingot',
    name: 'Copper Ingot',
    description: 'Smelted copper ore.',
    icon: '🪙',
    type: ItemType.resource,
    value: 20,
  );

  static const Item tinIngot = Item(
    id: 'tin_ingot',
    name: 'Tin Ingot',
    description: 'Smelted tin ore.',
    icon: '🪙',
    type: ItemType.resource,
    value: 25,
  );

  static const Item bronzeIngot = Item(
    id: 'bronze_ingot',
    name: 'Bronze Ingot',
    description: 'A strong bronze alloy smelted from copper and tin.',
    icon: '🪙',
    type: ItemType.resource,
    value: 50,
  );

  static const Item ironIngot = Item(
    id: 'iron_ingot',
    name: 'Iron Ingot',
    description: 'Smelted iron ore.',
    icon: '🪙',
    type: ItemType.resource,
    value: 40,
  );

  static const Item steelIngot = Item(
    id: 'steel_ingot',
    name: 'Steel Ingot',
    description: 'Refined steel alloy.',
    icon: '🪙',
    type: ItemType.resource,
    value: 80,
  );

  static const Item curedLeather = Item(
    id: 'cured_leather',
    name: 'Cured Leather',
    description: 'Tanned and cured beast hide.',
    icon: '💼',
    type: ItemType.resource,
    value: 30,
  );

  static const Item treatedSilk = Item(
    id: 'treated_silk',
    name: 'Treated Silk',
    description: 'Woven silk treated with oils.',
    icon: '🧵',
    type: ItemType.resource,
    value: 45,
  );

  static const Item greaterSteelGreatsword = Item(
    id: 'greater_steel_greatsword',
    name: 'Greater Steel Greatsword',
    description: 'A massive blade forged of refined steel and troll claws.',
    icon: '⚔️',
    type: ItemType.weapon,
    value: 650,
    attackPower: 38,
  );

  static const Item elixirOfLife4 = Item(
    id: 'elixir_4',
    name: "Alchemist's Elixir IV",
    description: 'A supreme elixir that restores immense health and energy.',
    icon: '🧪',
    type: ItemType.food,
    value: 200,
    healAmount: 120,
    energyAmount: 120,
  );

  static const Item glyphMastery = Item(
    id: 'glyph_mastery',
    name: 'Glyph of Mastery',
    description: 'A legendary runic glyph containing pure mastery.',
    icon: '🪨',
    type: ItemType.food,
    value: 300,
    healAmount: 50,
    energyAmount: 50,
  );

  static const BlueprintItem blueprintSteelGreatsword = BlueprintItem(
    id: 'blueprint_steel_greatsword',
    name: 'Blueprint: Steel Greatsword',
    description: 'A scroll detailing how to forge a Steel Greatsword.',
    icon: '📜',
    value: 100,
    recipeId: 'steel_greatsword',
  );

  static const BlueprintItem blueprintGreaterSteelGreatsword = BlueprintItem(
    id: 'blueprint_greater_steel_greatsword',
    name: 'Blueprint: Greater Steel Greatsword',
    description: 'A scroll detailing how to forge a Greater Steel Greatsword.',
    icon: '📜',
    value: 250,
    recipeId: 'greater_steel_greatsword',
  );

  static const BlueprintItem blueprintElixir4 = BlueprintItem(
    id: 'blueprint_elixir_4',
    name: "Blueprint: Alchemist's Elixir IV",
    description: "A scroll detailing how to brew Alchemist's Elixir IV.",
    icon: '📜',
    value: 200,
    recipeId: 'elixir_4',
  );

  static const BlueprintItem blueprintGlyphMastery = BlueprintItem(
    id: 'blueprint_glyph_mastery',
    name: 'Blueprint: Glyph of Mastery',
    description: 'A scroll detailing how to carve the Glyph of Mastery.',
    icon: '📜',
    value: 200,
    recipeId: 'glyph_mastery',
  );

  static const BlueprintItem blueprintSteelPlate = BlueprintItem(
    id: 'blueprint_steel_plate',
    name: 'Blueprint: Steel Cuirass',
    description: 'A scroll detailing how to forge a Steel Cuirass.',
    icon: '📜',
    value: 120,
    recipeId: 'steel_plate',
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
    rawTrout,
    rawPotato,
    hotWater,
    leatherBackpack,
    backpackUpgrade,
    philterOfClarity,
    copperAxe,
    copperPickaxe,
    bronzeAxe,
    bronzePickaxe,
    reinforcedGloves,
    masterworkGloves,
    butteredPotato,
    loadedPotato,
    smokedTrout,
    spicedTea,
    elixirOfLife1,
    elixirOfLife2,
    elixirOfLife3,
    glyphSwiftness,
    glyphFortitude,
    bronzeSword,
    ironSword,
    steelGreatsword,
    leatherChest,
    bronzeChest,
    steelPlate,
    boarMeat,
    boarTusk,
    spiderSilk,
    spiderFang,
    wolfPelt,
    trollClaw,
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
    blueprintSteelGreatsword,
    blueprintGreaterSteelGreatsword,
    blueprintElixir4,
    blueprintGlyphMastery,
    blueprintSteelPlate,
  ];

  static Item? findById(String id) {
    try {
      return all.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }
}
