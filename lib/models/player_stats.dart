class PlayerStats {
  final String name;
  final String title;
  final int currentHealth;
  final int maxHealth;
  final int currentEnergy;
  final int maxEnergy;
  final int gold;
  final int playerLevel; // Spec 6b
  final int playerXp;    // Spec 6b

  const PlayerStats({
    required this.name,
    required this.title,
    required this.currentHealth,
    required this.maxHealth,
    required this.currentEnergy,
    required this.maxEnergy,
    required this.gold,
    required this.playerLevel,
    required this.playerXp,
  });

  bool get isDead => currentHealth <= 0;
  bool get isExhausted => currentEnergy <= 0;

  PlayerStats copyWith({
    String? name,
    String? title,
    int? currentHealth,
    int? maxHealth,
    int? currentEnergy,
    int? maxEnergy,
    int? gold,
    int? playerLevel,
    int? playerXp,
  }) {
    return PlayerStats(
      name: name ?? this.name,
      title: title ?? this.title,
      currentHealth: currentHealth ?? this.currentHealth,
      maxHealth: maxHealth ?? this.maxHealth,
      currentEnergy: currentEnergy ?? this.currentEnergy,
      maxEnergy: maxEnergy ?? this.maxEnergy,
      gold: gold ?? this.gold,
      playerLevel: playerLevel ?? this.playerLevel,
      playerXp: playerXp ?? this.playerXp,
    );
  }

  factory PlayerStats.initial() {
    return const PlayerStats(
      name: "Elara",
      title: "Wayfarer",
      currentHealth: 100,
      maxHealth: 100,
      currentEnergy: 100,
      maxEnergy: 100,
      gold: 10, // starting gold
      playerLevel: 1,
      playerXp: 0,
    );
  }
}
