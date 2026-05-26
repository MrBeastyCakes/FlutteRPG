import 'skill.dart';

class TitleResolver {
  static const Map<SkillType, List<String>> _titles = {
    SkillType.woodcutting: ['Sapling',     'Woodcutter',  'Heartwood-Reaver'],
    SkillType.mining:      ['Prospector',  'Pickbearer',  'Vein-Master'],
    SkillType.herbalism:   ['Sprig',       'Herbalist',   'Greenwarden'],
    SkillType.wayfinding:  ['Wayfarer',    'Pathfinder',  'Cartographer'],
    SkillType.lore:        ['Reader',      'Scholar',     'Lorekeeper'],
    SkillType.cooking:     ['Hearth-Hand', 'Cook',        'Brewmaster'],
    SkillType.crafting:    ['Apprentice',  'Crafter',     'Artisan'],
    SkillType.combat:      ['Brawler',     'Warrior',     'Blademaster'],
  };

  /// Returns the active title for the given skill map.
  /// Ties broken by SkillType enum order (deterministic).
  static String resolve(Map<SkillType, SkillState> skills) {
    SkillType bestSkill = SkillType.wayfinding; // fallback for all-zero state
    int bestLevel = 0;
    for (final type in SkillType.values) { // iteration = enum order
      final lvl = skills[type]?.level ?? 0;
      if (lvl > bestLevel) {
        bestLevel = lvl;
        bestSkill = type;
      }
    }
    final tierIndex = bestLevel >= 20 ? 2 : (bestLevel >= 10 ? 1 : 0);
    return _titles[bestSkill]![tierIndex];
  }
}
