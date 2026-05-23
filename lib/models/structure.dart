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

  static const List<Structure> all = [
    craftingBench,
    fieldKitchen,
    outpostShelter,
  ];

  static Structure? findById(String id) {
    try {
      return all.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}
