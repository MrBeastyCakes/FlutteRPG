import 'skill.dart';

enum DailyTaskCategory { gather, hunt, visit, craft, codex, cleanse }

class DailyTaskTemplate {
  final String id;
  final DailyTaskCategory category;
  final String name; // e.g. "Gather 5 Oak Logs"
  final String targetId;
  final int targetCount;
  final int rewardGold;
  final SkillType? requiredSkill;
  final int requiredLevel;

  const DailyTaskTemplate({
    required this.id,
    required this.category,
    required this.name,
    required this.targetId,
    required this.targetCount,
    required this.rewardGold,
    this.requiredSkill,
    this.requiredLevel = 1,
  });
}

class DailyTask {
  final String id;
  final String name;
  final DailyTaskCategory category;
  final String targetId;
  final int targetCount;
  final int currentCount;
  final int rewardGold;
  final bool isCompleted;
  final bool isClaimed;

  const DailyTask({
    required this.id,
    required this.name,
    required this.category,
    required this.targetId,
    required this.targetCount,
    this.currentCount = 0,
    required this.rewardGold,
    this.isCompleted = false,
    this.isClaimed = false,
  });

  DailyTask copyWith({
    String? id,
    String? name,
    DailyTaskCategory? category,
    String? targetId,
    int? targetCount,
    int? currentCount,
    int? rewardGold,
    bool? isCompleted,
    bool? isClaimed,
  }) {
    return DailyTask(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      targetId: targetId ?? this.targetId,
      targetCount: targetCount ?? this.targetCount,
      currentCount: currentCount ?? this.currentCount,
      rewardGold: rewardGold ?? this.rewardGold,
      isCompleted: isCompleted ?? this.isCompleted,
      isClaimed: isClaimed ?? this.isClaimed,
    );
  }
}

class DailyTasks {
  static const List<DailyTaskTemplate> all = [
    // --- GATHER (6) ---
    DailyTaskTemplate(
      id: 'daily_gather_oak',
      category: DailyTaskCategory.gather,
      name: 'Gather 5 Oak Logs',
      targetId: 'oak_log',
      targetCount: 5,
      rewardGold: 20,
      requiredSkill: SkillType.woodcutting,
      requiredLevel: 1,
    ),
    DailyTaskTemplate(
      id: 'daily_gather_wildflower',
      category: DailyTaskCategory.gather,
      name: 'Gather 5 Wildflowers',
      targetId: 'wildflower',
      targetCount: 5,
      rewardGold: 15,
      requiredSkill: SkillType.herbalism,
      requiredLevel: 1,
    ),
    DailyTaskTemplate(
      id: 'daily_gather_clay',
      category: DailyTaskCategory.gather,
      name: 'Gather 4 River Clay deposits',
      targetId: 'river_clay',
      targetCount: 4,
      rewardGold: 22,
      requiredSkill: SkillType.mining,
      requiredLevel: 1,
    ),
    DailyTaskTemplate(
      id: 'daily_gather_driftwood',
      category: DailyTaskCategory.gather,
      name: 'Gather 5 Driftwood pieces',
      targetId: 'driftwood',
      targetCount: 5,
      rewardGold: 25,
      requiredSkill: SkillType.woodcutting,
      requiredLevel: 5,
    ),
    DailyTaskTemplate(
      id: 'daily_gather_salt',
      category: DailyTaskCategory.gather,
      name: 'Harvest 4 Salt Crystals',
      targetId: 'salt_crystal',
      targetCount: 4,
      rewardGold: 30,
      requiredSkill: SkillType.mining,
      requiredLevel: 5,
    ),
    DailyTaskTemplate(
      id: 'daily_gather_kelp',
      category: DailyTaskCategory.gather,
      name: 'Gather 3 Kelp from tidepools',
      targetId: 'kelp',
      targetCount: 3,
      rewardGold: 20,
      requiredSkill: SkillType.herbalism,
      requiredLevel: 5,
    ),

    // --- HUNT (6) ---
    DailyTaskTemplate(
      id: 'daily_hunt_boar',
      category: DailyTaskCategory.hunt,
      name: 'Defeat 3 Forest Boars',
      targetId: 'forest_boar',
      targetCount: 3,
      rewardGold: 30,
      requiredSkill: SkillType.combat,
      requiredLevel: 1,
    ),
    DailyTaskTemplate(
      id: 'daily_hunt_spider',
      category: DailyTaskCategory.hunt,
      name: 'Defeat 3 Cave Spiders',
      targetId: 'cave_spider',
      targetCount: 3,
      rewardGold: 35,
      requiredSkill: SkillType.combat,
      requiredLevel: 3,
    ),
    DailyTaskTemplate(
      id: 'daily_hunt_wolf',
      category: DailyTaskCategory.hunt,
      name: 'Defeat 3 Shadow Wolves',
      targetId: 'shadow_wolf',
      targetCount: 3,
      rewardGold: 45,
      requiredSkill: SkillType.combat,
      requiredLevel: 6,
    ),
    DailyTaskTemplate(
      id: 'daily_hunt_troll',
      category: DailyTaskCategory.hunt,
      name: 'Defeat 2 Cavern Trolls',
      targetId: 'cavern_troll',
      targetCount: 2,
      rewardGold: 60,
      requiredSkill: SkillType.combat,
      requiredLevel: 10,
    ),
    DailyTaskTemplate(
      id: 'daily_hunt_hound',
      category: DailyTaskCategory.hunt,
      name: 'Defeat 4 Tide Hounds',
      targetId: 'tide_hound',
      targetCount: 4,
      rewardGold: 40,
      requiredSkill: SkillType.combat,
      requiredLevel: 5,
    ),
    DailyTaskTemplate(
      id: 'daily_hunt_crawler',
      category: DailyTaskCategory.hunt,
      name: 'Defeat 3 Brine Crawlers',
      targetId: 'brine_crawler',
      targetCount: 3,
      rewardGold: 50,
      requiredSkill: SkillType.combat,
      requiredLevel: 8,
    ),

    // --- VISIT (6) ---
    DailyTaskTemplate(
      id: 'daily_visit_woods_1',
      category: DailyTaskCategory.visit,
      name: 'Visit Whispering Woods I',
      targetId: 'whispering_woods_1',
      targetCount: 1,
      rewardGold: 15,
      requiredSkill: SkillType.wayfinding,
      requiredLevel: 1,
    ),
    DailyTaskTemplate(
      id: 'daily_visit_woods_2',
      category: DailyTaskCategory.visit,
      name: 'Visit Whispering Woods II',
      targetId: 'whispering_woods_2',
      targetCount: 1,
      rewardGold: 20,
      requiredSkill: SkillType.wayfinding,
      requiredLevel: 4,
    ),
    DailyTaskTemplate(
      id: 'daily_visit_mine_1',
      category: DailyTaskCategory.visit,
      name: 'Visit Darkstone Mine I',
      targetId: 'darkstone_mine_1',
      targetCount: 1,
      rewardGold: 20,
      requiredSkill: SkillType.wayfinding,
      requiredLevel: 3,
    ),
    DailyTaskTemplate(
      id: 'daily_visit_mine_2',
      category: DailyTaskCategory.visit,
      name: 'Visit Darkstone Mine II',
      targetId: 'darkstone_mine_2',
      targetCount: 1,
      rewardGold: 25,
      requiredSkill: SkillType.wayfinding,
      requiredLevel: 6,
    ),
    DailyTaskTemplate(
      id: 'daily_visit_coast_1',
      category: DailyTaskCategory.visit,
      name: 'Visit Sundered Coast I',
      targetId: 'sundered_coast_1',
      targetCount: 1,
      rewardGold: 25,
      requiredSkill: SkillType.wayfinding,
      requiredLevel: 5,
    ),
    DailyTaskTemplate(
      id: 'daily_visit_coast_2',
      category: DailyTaskCategory.visit,
      name: 'Visit Sundered Coast II',
      targetId: 'sundered_coast_2',
      targetCount: 1,
      rewardGold: 30,
      requiredSkill: SkillType.wayfinding,
      requiredLevel: 8,
    ),

    // --- CRAFT (6) ---
    DailyTaskTemplate(
      id: 'daily_craft_copper_ingot',
      category: DailyTaskCategory.craft,
      name: 'Craft 3 Copper Ingots',
      targetId: 'copper_ingot',
      targetCount: 3,
      rewardGold: 25,
      requiredSkill: SkillType.crafting,
      requiredLevel: 1,
    ),
    DailyTaskTemplate(
      id: 'daily_craft_bronze_ingot',
      category: DailyTaskCategory.craft,
      name: 'Craft 2 Bronze Ingots',
      targetId: 'bronze_ingot',
      targetCount: 2,
      rewardGold: 35,
      requiredSkill: SkillType.crafting,
      requiredLevel: 5,
    ),
    DailyTaskTemplate(
      id: 'daily_craft_leather',
      category: DailyTaskCategory.craft,
      name: 'Craft 2 Cured Leather pieces',
      targetId: 'cured_leather',
      targetCount: 2,
      rewardGold: 30,
      requiredSkill: SkillType.crafting,
      requiredLevel: 4,
    ),
    DailyTaskTemplate(
      id: 'daily_craft_baked_potato',
      category: DailyTaskCategory.craft,
      name: 'Bake 3 Baked Potatoes',
      targetId: 'baked_potato',
      targetCount: 3,
      rewardGold: 18,
      requiredSkill: SkillType.cooking,
      requiredLevel: 1,
    ),
    DailyTaskTemplate(
      id: 'daily_craft_herbal_tea',
      category: DailyTaskCategory.craft,
      name: 'Brew 2 Herbal Teas',
      targetId: 'herbal_tea',
      targetCount: 2,
      rewardGold: 20,
      requiredSkill: SkillType.cooking,
      requiredLevel: 2,
    ),
    DailyTaskTemplate(
      id: 'daily_craft_copper_axe',
      category: DailyTaskCategory.craft,
      name: 'Craft a Copper Axe',
      targetId: 'copper_axe',
      targetCount: 1,
      rewardGold: 40,
      requiredSkill: SkillType.crafting,
      requiredLevel: 3,
    ),

    // --- CODEX (3) ---
    DailyTaskTemplate(
      id: 'daily_codex_read_1',
      category: DailyTaskCategory.codex,
      name: 'Study 1 Codex Fragment',
      targetId: 'any',
      targetCount: 1,
      rewardGold: 20,
      requiredSkill: SkillType.lore,
      requiredLevel: 1,
    ),
    DailyTaskTemplate(
      id: 'daily_codex_read_2',
      category: DailyTaskCategory.codex,
      name: 'Study 2 Codex Fragments',
      targetId: 'any',
      targetCount: 2,
      rewardGold: 30,
      requiredSkill: SkillType.lore,
      requiredLevel: 4,
    ),
    DailyTaskTemplate(
      id: 'daily_codex_read_3',
      category: DailyTaskCategory.codex,
      name: 'Study 3 Codex Fragments',
      targetId: 'any',
      targetCount: 3,
      rewardGold: 45,
      requiredSkill: SkillType.lore,
      requiredLevel: 8,
    ),

    // --- CLEANSE (3) ---
    DailyTaskTemplate(
      id: 'daily_cleanse_breach',
      category: DailyTaskCategory.cleanse,
      name: 'Perform 1 Breach Cleansing Step',
      targetId: 'breach_cleansed',
      targetCount: 1,
      rewardGold: 50,
      requiredSkill: SkillType.lore,
      requiredLevel: 5,
    ),
    DailyTaskTemplate(
      id: 'daily_cleanse_breach_high',
      category: DailyTaskCategory.cleanse,
      name: 'Seal a Breach or complete Cleansing Step',
      targetId: 'breach_cleansed',
      targetCount: 1,
      rewardGold: 60,
      requiredSkill: SkillType.lore,
      requiredLevel: 9,
    ),
    DailyTaskTemplate(
      id: 'daily_cleanse_alternate',
      category: DailyTaskCategory.cleanse,
      name: 'Study or Cleanse Breach',
      targetId: 'breach_cleansed',
      targetCount: 1,
      rewardGold: 40,
      requiredSkill: SkillType.wayfinding,
      requiredLevel: 4,
    ),
  ];
}
