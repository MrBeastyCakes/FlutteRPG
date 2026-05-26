import 'skill.dart';

class ReagentSpawn {
  final String itemId;
  final String zoneId;
  final String noticeText;
  final SkillType requiredSkill;
  final int requiredLevel;
  final int energyCost;
  final bool isCollected;

  const ReagentSpawn({
    required this.itemId,
    required this.zoneId,
    required this.noticeText,
    required this.requiredSkill,
    this.requiredLevel = 5,
    this.energyCost = 5,
    this.isCollected = false,
  });

  ReagentSpawn copyWith({
    String? itemId,
    String? zoneId,
    String? noticeText,
    SkillType? requiredSkill,
    int? requiredLevel,
    int? energyCost,
    bool? isCollected,
  }) {
    return ReagentSpawn(
      itemId: itemId ?? this.itemId,
      zoneId: zoneId ?? this.zoneId,
      noticeText: noticeText ?? this.noticeText,
      requiredSkill: requiredSkill ?? this.requiredSkill,
      requiredLevel: requiredLevel ?? this.requiredLevel,
      energyCost: energyCost ?? this.energyCost,
      isCollected: isCollected ?? this.isCollected,
    );
  }
}
