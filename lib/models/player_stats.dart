class PlayerStats {
  final String name;
  final String title;
  final int currentHealth;
  final int maxHealth;
  final int currentEnergy;
  final int maxEnergy;
  final int gold;

  const PlayerStats({
    required this.name,
    required this.title,
    required this.currentHealth,
    required this.maxHealth,
    required this.currentEnergy,
    required this.maxEnergy,
    required this.gold,
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
  }) {
    return PlayerStats(
      name: name ?? this.name,
      title: title ?? this.title,
      currentHealth: currentHealth ?? this.currentHealth,
      maxHealth: maxHealth ?? this.maxHealth,
      currentEnergy: currentEnergy ?? this.currentEnergy,
      maxEnergy: maxEnergy ?? this.maxEnergy,
      gold: gold ?? this.gold,
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
    );
  }
}
