import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';

enum GameAvatarSize { sm, md, lg, xl }

class GameAvatar extends StatelessWidget {
  final String? emoji;
  final String? label;
  final IconData? icon;
  final Color? ringColor;
  final GameAvatarSize size;
  final Color? backgroundColor;

  const GameAvatar({
    super.key,
    this.emoji,
    this.label,
    this.icon,
    this.ringColor,
    this.size = GameAvatarSize.md,
    this.backgroundColor,
  });

  double _dimension() {
    switch (size) {
      case GameAvatarSize.sm: return 32;
      case GameAvatarSize.md: return 48;
      case GameAvatarSize.lg: return 64;
      case GameAvatarSize.xl: return 80;
    }
  }

  double _fontSize() {
    switch (size) {
      case GameAvatarSize.sm: return 14;
      case GameAvatarSize.md: return 20;
      case GameAvatarSize.lg: return 28;
      case GameAvatarSize.xl: return 36;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dim = _dimension();
    final fSize = _fontSize();

    Widget content;
    if (emoji != null) {
      content = Text(
        emoji!,
        style: TextStyle(fontSize: fSize),
      );
    } else if (label != null) {
      content = Text(
        label!.substring(0, label!.length >= 2 ? 2 : 1).toUpperCase(),
        style: DSText.headingSmall(context).copyWith(
          fontSize: fSize * 0.7,
          color: DSColors.textPrimary,
        ),
      );
    } else if (icon != null) {
      content = Icon(
        icon,
        size: fSize,
        color: DSColors.textSecondary,
      );
    } else {
      content = const SizedBox.shrink();
    }

    return Container(
      width: dim,
      height: dim,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? DSColors.surface3,
        border: ringColor != null
            ? Border.all(color: ringColor!, width: 2)
            : Border.all(color: DSColors.borderDefault, width: 1.5),
        boxShadow: DSShadow.sm,
      ),
      alignment: Alignment.center,
      child: content,
    );
  }
}
