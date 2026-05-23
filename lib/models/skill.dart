import 'dart:math';

enum SkillType {
  woodcutting,
  mining,
  herbalism,
  wayfinding,
  lore,
  cooking,
  crafting,
}

extension SkillTypeExtension on SkillType {
  String get name {
    switch (this) {
      case SkillType.woodcutting:
        return 'Woodcutting';
      case SkillType.mining:
        return 'Mining';
      case SkillType.herbalism:
        return 'Herbalism';
      case SkillType.wayfinding:
        return 'Wayfinding';
      case SkillType.lore:
        return 'Lore';
      case SkillType.cooking:
        return 'Cooking';
      case SkillType.crafting:
        return 'Crafting';
    }
  }

  String get icon {
    switch (this) {
      case SkillType.woodcutting:
        return '🪓';
      case SkillType.mining:
        return '⛏️';
      case SkillType.herbalism:
        return '🌿';
      case SkillType.wayfinding:
        return '🗺️';
      case SkillType.lore:
        return '📜';
      case SkillType.cooking:
        return '🍳';
      case SkillType.crafting:
        return '🛠️';
    }
  }
}

class SkillState {
  final SkillType type;
  final int level;
  final double xp;
  final int levelCap; // Starts at 10, increments by 10 (10, 20, 30...) after Masterwork

  const SkillState({
    required this.type,
    required this.level,
    required this.xp,
    required this.levelCap,
  });

  /// Check if the player is currently blocked from gaining XP because they reached the cap
  bool get isGated => level >= levelCap;

  /// Calculate the TOTAL XP required to reach a specific level.
  /// Standard RPG curve: XP = 100 * (level - 1)^1.6
  static double totalXpForLevel(int lvl) {
    if (lvl <= 1) return 0.0;
    return 100.0 * pow(lvl - 1, 1.6);
  }

  /// Calculate the XP needed to go from [lvl] to [lvl + 1]
  static double xpForNextLevel(int lvl) {
    return totalXpForLevel(lvl + 1) - totalXpForLevel(lvl);
  }

  /// Calculates the progress percentage (0.0 to 1.0) towards the next level
  double get progress {
    double currentLevelXpStart = totalXpForLevel(level);
    double nextLevelXpStart = totalXpForLevel(level + 1);
    double xpInCurrentLevel = xp - currentLevelXpStart;
    double totalXpNeededForLevel = nextLevelXpStart - currentLevelXpStart;
    if (totalXpNeededForLevel <= 0) return 0.0;
    return (xpInCurrentLevel / totalXpNeededForLevel).clamp(0.0, 1.0);
  }

  /// Gaining XP method. Returns the new SkillState.
  /// If the player hits the cap, their level remains at [levelCap] and XP clamps to the cap start.
  SkillState addXp(double amount) {
    if (isGated) {
      // Gated at the cap: cannot gain more XP
      return this;
    }

    double newXp = xp + amount;
    int newLevel = level;

    // Check level ups
    while (true) {
      double nextLvlXp = totalXpForLevel(newLevel + 1);
      if (newXp >= nextLvlXp) {
        // Check if this level up hits or exceeds the level cap
        if (newLevel + 1 > levelCap) {
          // Gated! Lock level to levelCap, clamp XP to the exact boundary of the next level
          newLevel = levelCap;
          newXp = totalXpForLevel(levelCap);
          break;
        } else {
          newLevel++;
        }
      } else {
        break;
      }
    }

    return SkillState(
      type: type,
      level: newLevel,
      xp: newXp,
      levelCap: levelCap,
    );
  }

  bool get isPerk10Unlocked => levelCap > 10;
  bool get isPerk20Unlocked => levelCap > 20;

  String get perk10Name {
    switch (type) {
      case SkillType.woodcutting: return 'Ironbark Feller';
      case SkillType.mining: return 'Glinting Miner';
      case SkillType.herbalism: return 'Philter Specialist';
      case SkillType.wayfinding: return 'Outpost Pathfinder';
      case SkillType.lore: return 'Obelisk Interpreter';
      case SkillType.cooking: return 'Inn Sous-Chef';
      case SkillType.crafting: return 'Journeyman Smith';
    }
  }

  String get perk10Desc {
    switch (type) {
      case SkillType.woodcutting: return 'Woodcutting speed +20%, woodcutting energy cost -2, and immune to bare-handed woodcutting damage.';
      case SkillType.mining: return 'Mining speed +20%, mining energy cost -3, and immune to bare-handed mining damage.';
      case SkillType.herbalism: return 'Herbalism speed +20%, foraging energy cost -1, and immune to bare-handed foraging damage.';
      case SkillType.wayfinding: return 'Wayfinding actions speed +20% and exploration energy cost -2.';
      case SkillType.lore: return 'Lore actions speed +20% and +15% XP bonus to ALL skills.';
      case SkillType.cooking: return 'Cooking speed +20% and all consumed food restores +15% health & energy.';
      case SkillType.crafting: return 'Crafting speed +20% and crafting energy cost -1.';
    }
  }

  String get perk20Name {
    switch (type) {
      case SkillType.woodcutting: return 'Timber Lord';
      case SkillType.mining: return 'Deep Core Quarryman';
      case SkillType.herbalism: return 'Bloom Whisperer';
      case SkillType.wayfinding: return 'Void Wanderer';
      case SkillType.lore: return 'Sage of Ages';
      case SkillType.cooking: return 'Master Culinarian';
      case SkillType.crafting: return 'Star Forge Artisan';
    }
  }

  String get perk20Desc {
    switch (type) {
      case SkillType.woodcutting: return 'Woodcutting speed +30% and a 15% chance to double woodcutting loot yields.';
      case SkillType.mining: return 'Mining speed +30% and a 15% chance to double mining loot yields.';
      case SkillType.herbalism: return 'Herbalism speed +30% and a 15% chance to double foraging loot yields.';
      case SkillType.wayfinding: return 'Wayfinding actions speed +30% and a 15% chance to double exploration progress.';
      case SkillType.lore: return 'Lore actions speed +30% and +25% XP bonus to ALL skills.';
      case SkillType.cooking: return 'Cooking speed +30%, food eaten restores +30% health & energy, and +20% chance to double cooking output.';
      case SkillType.crafting: return 'Crafting speed +30% and a 15% chance to save all inputs when crafting.';
    }
  }

  /// Unlock the level cap by 10 levels
  SkillState unlockCap() {
    return SkillState(
      type: type,
      level: level,
      xp: xp,
      levelCap: levelCap + 10,
    );
  }


  SkillState copyWith({
    SkillType? type,
    int? level,
    double? xp,
    int? levelCap,
  }) {
    return SkillState(
      type: type ?? this.type,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      levelCap: levelCap ?? this.levelCap,
    );
  }

  factory SkillState.initial(SkillType type) {
    return SkillState(
      type: type,
      level: 1,
      xp: 0.0,
      levelCap: 10, // Gates at 10
    );
  }
}
