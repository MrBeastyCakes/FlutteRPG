import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import '../../models/skill.dart';
import '../../models/codex.dart';
import '../../models/item.dart';
import '../../models/quest.dart';
import '../../models/shop.dart';
import '../../models/crafted_item.dart';
import '_animated_pressable.dart';

enum GameChipSize { sm, md, lg }

class GameChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final GameChipSize size;
  final bool outlined;
  final VoidCallback? onTap;

  const GameChip({
    super.key,
    required this.label,
    this.icon,
    this.color = DSColors.textMuted,
    this.size = GameChipSize.md,
    this.outlined = false,
    this.onTap,
  });

  factory GameChip.skill(SkillType s, {String? label, GameChipSize size = GameChipSize.md, VoidCallback? onTap}) {
    final skillName = label ?? s.name.toUpperCase();
    return GameChip(
      label: skillName,
      color: DSColors.skill(s),
      size: size,
      onTap: onTap,
    );
  }

  factory GameChip.tag(CodexTag t, {GameChipSize size = GameChipSize.md, VoidCallback? onTap}) {
    return GameChip(
      label: t.name.toUpperCase(),
      color: DSColors.tag(t),
      size: size,
      onTap: onTap,
    );
  }

  factory GameChip.quality(QualityTier q, {GameChipSize size = GameChipSize.md, VoidCallback? onTap}) {
    return GameChip(
      label: q.name.toUpperCase(),
      color: DSColors.quality(q),
      size: size,
      onTap: onTap,
    );
  }

  factory GameChip.questStatus(QuestStatus s, {GameChipSize size = GameChipSize.md, VoidCallback? onTap}) {
    Color statusColor;
    String text;
    switch (s) {
      case QuestStatus.available:
        statusColor = DSColors.info;
        text = 'Available';
        break;
      case QuestStatus.active:
        statusColor = DSColors.warning;
        text = 'Active';
        break;
      case QuestStatus.completed:
        statusColor = DSColors.success;
        text = 'Ready';
        break;
      case QuestStatus.turnedIn:
        statusColor = DSColors.textMuted;
        text = 'Completed';
        break;
    }
    return GameChip(
      label: text.toUpperCase(),
      color: statusColor,
      size: size,
      onTap: onTap,
    );
  }

  factory GameChip.reputationTier(ReputationTier t, {GameChipSize size = GameChipSize.md, VoidCallback? onTap}) {
    Color tierColor;
    switch (t) {
      case ReputationTier.stranger:
        tierColor = const Color(0xFF90A4AE);
        break;
      case ReputationTier.familiar:
        tierColor = const Color(0xFF81D4FA);
        break;
      case ReputationTier.trustedPatron:
        tierColor = const Color(0xFF9CCC65);
        break;
      case ReputationTier.honoredFriend:
        tierColor = const Color(0xFFFFB300);
        break;
      case ReputationTier.swornCompanion:
        tierColor = const Color(0xFFFFD700);
        break;
    }
    return GameChip(
      label: t.name.toUpperCase(),
      color: tierColor,
      size: size,
      onTap: onTap,
    );
  }

  double _height() {
    switch (size) {
      case GameChipSize.sm: return 18;
      case GameChipSize.md: return 24;
      case GameChipSize.lg: return 30;
    }
  }

  double _fontSize() {
    switch (size) {
      case GameChipSize.sm: return 9;
      case GameChipSize.md: return 11;
      case GameChipSize.lg: return 12;
    }
  }

  EdgeInsets _padding() {
    switch (size) {
      case GameChipSize.sm: return const EdgeInsets.symmetric(horizontal: 6);
      case GameChipSize.md: return const EdgeInsets.symmetric(horizontal: 10);
      case GameChipSize.lg: return const EdgeInsets.symmetric(horizontal: 14);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = DSText.label(context).copyWith(
      fontSize: _fontSize(),
      color: outlined ? color : DSColors.textOnAccent,
      fontWeight: FontWeight.bold,
    );

    final chipBody = Container(
      height: _height(),
      padding: _padding(),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color,
        borderRadius: BorderRadius.circular(DSRadius.pill),
        border: outlined ? Border.all(color: color, width: 1.5) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: _fontSize() + 2, color: outlined ? color : DSColors.textOnAccent),
            const SizedBox(width: 4),
          ],
          Text(label, style: textStyle),
        ],
      ),
    );

    if (onTap != null) {
      return AnimatedPressable(
        onTap: onTap,
        child: chipBody,
      );
    }

    return chipBody;
  }
}
