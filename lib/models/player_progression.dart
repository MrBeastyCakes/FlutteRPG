class PlayerProgression {
  static int xpToNextLevel(int currentLevel) => 100 * currentLevel;

  /// Apply XP gain; returns (newLevel, newXp, didLevelUp).
  static ({int level, int xp, bool didLevelUp}) applyXp(int level, int xp, int xpGain) {
    int newLevel = level;
    int newXp = xp + xpGain;
    bool leveledUp = false;
    while (newXp >= xpToNextLevel(newLevel)) {
      newXp -= xpToNextLevel(newLevel);
      newLevel += 1;
      leveledUp = true;
    }
    return (level: newLevel, xp: newXp, didLevelUp: leveledUp);
  }
}
