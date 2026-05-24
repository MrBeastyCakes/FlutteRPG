import 'item.dart';

enum QualityTier {
  crude,
  standard,
  fine,
  masterwork;

  double get multiplier {
    switch (this) {
      case QualityTier.crude:
        return 0.75;
      case QualityTier.standard:
        return 1.00;
      case QualityTier.fine:
        return 1.25;
      case QualityTier.masterwork:
        return 1.60;
    }
  }

  int get affixCount {
    switch (this) {
      case QualityTier.crude:
      case QualityTier.standard:
        return 0;
      case QualityTier.fine:
        return 1;
      case QualityTier.masterwork:
        return 2;
    }
  }
}

enum AffixEffectType {
  attackPercent,
  attackFlat,
  defensePercent,
  defenseFlat,
  speedBonus,
  successBonus,
  energyCostReduction,
  healPercent,
  energyPercent,
  goldValuePercent,
  toolStatBoost, // Sturdy
  plentiful, // double bite
  frugal, // energy cost use reduction
}

class AffixEffect {
  final AffixEffectType type;
  final double value;
  const AffixEffect(this.type, this.value);
}

class Affix {
  final String id;
  final String name;
  final String description;
  final Set<ItemType> appliesTo;
  final AffixEffect effect;

  const Affix({
    required this.id,
    required this.name,
    required this.description,
    required this.appliesTo,
    required this.effect,
  });
}

class Affixes {
  static const Affix keen = Affix(
    id: 'keen',
    name: 'Keen',
    description: '+10% attack',
    appliesTo: {ItemType.weapon},
    effect: AffixEffect(AffixEffectType.attackPercent, 0.10),
  );
  
  static const Affix brutal = Affix(
    id: 'brutal',
    name: 'Brutal',
    description: '+1 flat attack',
    appliesTo: {ItemType.weapon},
    effect: AffixEffect(AffixEffectType.attackFlat, 1.0),
  );
  
  static const Affix tempered = Affix(
    id: 'tempered',
    name: 'Tempered',
    description: '+15% defense',
    appliesTo: {ItemType.armor},
    effect: AffixEffect(AffixEffectType.defensePercent, 0.15),
  );
  
  static const Affix reinforced = Affix(
    id: 'reinforced',
    name: 'Reinforced',
    description: '+1 flat defense',
    appliesTo: {ItemType.armor},
    effect: AffixEffect(AffixEffectType.defenseFlat, 1.0),
  );
  
  static const Affix swift = Affix(
    id: 'swift',
    name: 'Swift',
    description: '+5% speed bonus',
    appliesTo: {ItemType.tool},
    effect: AffixEffect(AffixEffectType.speedBonus, 0.05),
  );
  
  static const Affix lucky = Affix(
    id: 'lucky',
    name: 'Lucky',
    description: '+5% success bonus',
    appliesTo: {ItemType.tool},
    effect: AffixEffect(AffixEffectType.successBonus, 0.05),
  );
  
  static const Affix ergonomic = Affix(
    id: 'ergonomic',
    name: 'Ergonomic',
    description: '-1 energy when used (floor 0)',
    appliesTo: {ItemType.tool},
    effect: AffixEffect(AffixEffectType.energyCostReduction, 1.0),
  );
  
  static const Affix hearty = Affix(
    id: 'hearty',
    name: 'Hearty',
    description: '+25% heal',
    appliesTo: {ItemType.food},
    effect: AffixEffect(AffixEffectType.healPercent, 0.25),
  );
  
  static const Affix invigorating = Affix(
    id: 'invigorating',
    name: 'Invigorating',
    description: '+25% energy',
    appliesTo: {ItemType.food},
    effect: AffixEffect(AffixEffectType.energyPercent, 0.25),
  );
  
  static const Affix valued = Affix(
    id: 'valued',
    name: 'Valued',
    description: '+25% gold value',
    appliesTo: {ItemType.weapon, ItemType.armor, ItemType.tool, ItemType.food},
    effect: AffixEffect(AffixEffectType.goldValuePercent, 0.25),
  );
  
  static const Affix sturdy = Affix(
    id: 'sturdy',
    name: 'Sturdy',
    description: '+10% to both speed and success bonuses',
    appliesTo: {ItemType.tool},
    effect: AffixEffect(AffixEffectType.toolStatBoost, 0.10),
  );
  
  static const Affix plentiful = Affix(
    id: 'plentiful',
    name: 'Plentiful',
    description: '+1 to a stack consumed at once',
    appliesTo: {ItemType.food},
    effect: AffixEffect(AffixEffectType.plentiful, 1.0),
  );
  
  static const Affix frugal = Affix(
    id: 'frugal',
    name: 'Frugal',
    description: '-10% energy cost when used/consumed',
    appliesTo: {ItemType.weapon, ItemType.armor, ItemType.tool, ItemType.food},
    effect: AffixEffect(AffixEffectType.frugal, 0.10),
  );

  static const List<Affix> all = [
    keen,
    brutal,
    tempered,
    reinforced,
    swift,
    lucky,
    ergonomic,
    hearty,
    invigorating,
    valued,
    sturdy,
    plentiful,
    frugal,
  ];

  static Affix? findById(String id) {
    for (final a in all) {
      if (a.id == id) return a;
    }
    return null;
  }
}

class CraftedItem {
  final String itemId;
  final QualityTier quality;
  final List<String> affixIds; // 0..2, sorted by id for stacking

  const CraftedItem({
    required this.itemId,
    required this.quality,
    required this.affixIds,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CraftedItem &&
          runtimeType == other.runtimeType &&
          itemId == other.itemId &&
          quality == other.quality &&
          _listEquals(affixIds, other.affixIds);

  @override
  int get hashCode =>
      itemId.hashCode ^
      quality.hashCode ^
      affixIds.fold(0, (prev, element) => prev ^ element.hashCode);

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
